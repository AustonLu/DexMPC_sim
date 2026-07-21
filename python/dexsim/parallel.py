"""Capability-gated output-space partitioning for TopChip MAC contexts."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import math
import time

from .commands import (
    add as build_add,
    gemm as build_gemm,
    gemv as build_gemv,
    outer as build_outer,
    scale as build_scale,
)
from .session import ScheduledCommand


FP16_PER_WORD = 8
MEMORY_WORD_CAPACITY = {"local": 512, "temp": 896}
LINEAR_OPERATORS = ("gemm", "gemv", "outer", "scale", "add")

# Filled from tools/run_multicore_linear_benchmarks.py.  A threshold is the
# minimum scalar FP16 work for the corresponding core count.  Conservative
# defaults keep production on the v0.3 single-core path until the benchmark
# artifact is regenerated and reviewed.
AUTO_THRESHOLDS = {
    "gemm": {2: math.inf, 4: math.inf},
    "gemv": {2: math.inf, 4: math.inf},
    "outer": {2: math.inf, 4: math.inf},
    "scale": {2: math.inf, 4: math.inf},
    "add": {2: math.inf, 4: math.inf},
}


@dataclass(frozen=True)
class Partition:
    core: int
    start: int
    size: int

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class LinearPlan:
    operation: str
    requested_policy: str
    core_count: int
    partition_unit: str
    partitions: tuple[Partition, ...]
    scalar_work: int
    reason: str

    def to_dict(self):
        value = asdict(self)
        value["partitions"] = [item.to_dict() for item in self.partitions]
        return value


def _work_and_units(operation, inputs):
    if operation == "gemm":
        n_rows, k_dim = inputs[0].shape
        m_cols = inputs[1].shape[1]
        return n_rows * m_cols * k_dim, n_rows, "output_rows"
    if operation == "gemv":
        n_rows, k_dim = inputs[0].shape
        return n_rows * k_dim, n_rows, "output_rows"
    if operation == "outer":
        return inputs[0].element_count * inputs[1].element_count, inputs[0].element_count, "output_rows"
    if operation in ("scale", "add"):
        return inputs[0].element_count, inputs[0].element_count, "output_elements"
    raise ValueError(f"unsupported parallel linear operator {operation!r}")


def _partitions(total, cores):
    if cores == 1:
        # LA dimensions are 12-bit fields.  Keep the single-core fallback a
        # real hardware path by emitting sequential word-aligned tiles when a
        # 1-D elementwise op exceeds the field width.
        if total <= 4095:
            return ((0, total),)
        result = []
        start = 0
        while total - start > 4095:
            size = (4095 // FP16_PER_WORD) * FP16_PER_WORD
            result.append((start, size))
            start += size
        result.append((start, total - start))
        return tuple(result)
    block_count = math.ceil(total / FP16_PER_WORD)
    if block_count < cores:
        return None
    base, extra = divmod(block_count, cores)
    result = []
    start = 0
    for index in range(cores):
        blocks = base + (1 if index < extra else 0)
        end = total if index == cores - 1 else min(total, start + blocks * FP16_PER_WORD)
        result.append((start, end - start))
        start = end
    if start != total or any(size <= 0 for _, size in result):
        return None
    return tuple(result)


def plan_linear(operation, inputs, *, policy="auto", available_cores=(0, 1, 2, 3)):
    if operation not in LINEAR_OPERATORS:
        raise ValueError(f"unsupported parallel linear operator {operation!r}")
    if policy not in ("single", "auto", "dual", "quad"):
        raise ValueError("execution_policy must be 'single', 'auto', 'dual', or 'quad'")
    available_cores = tuple(sorted(set(int(core) for core in available_cores)))
    if not available_cores or available_cores[0] != 0:
        raise ValueError("parallel linear execution requires core0")

    work, units, unit_name = _work_and_units(operation, inputs)
    max_cores = min(4, len(available_cores))
    if policy == "single":
        requested = 1
        policy_reason = "explicit_single_policy"
    elif policy == "dual":
        requested = 2
        policy_reason = "diagnostic_dual_policy"
    elif policy == "quad":
        requested = 4
        policy_reason = "diagnostic_quad_policy"
    else:
        requested = 1
        policy_reason = "below_measured_parallel_threshold"
        for candidate in (4, 2):
            if candidate <= max_cores and work >= AUTO_THRESHOLDS[operation][candidate]:
                requested = candidate
                policy_reason = "measured_parallel_threshold"
                break

    requested = min(requested, max_cores)
    for candidate in (requested, 2, 1):
        if candidate > requested or candidate > max_cores:
            continue
        values = _partitions(units, candidate)
        if values is None:
            continue
        cores = available_cores[:candidate]
        reason = policy_reason
        if candidate != requested:
            reason = "word_aligned_partition_unavailable"
        if candidate == 1:
            assigned = tuple(Partition(0, start, size) for start, size in values)
        else:
            assigned = tuple(
                Partition(core, start, size)
                for core, (start, size) in zip(cores, values)
            )
        return LinearPlan(
            operation=operation,
            requested_policy=policy,
            core_count=candidate,
            partition_unit=unit_name,
            partitions=assigned,
            scalar_work=work,
            reason=reason,
        )
    raise AssertionError("single-core partition must always be available")


def _read_flat_bits(session, ref, *, core, start, count):
    value = session.read_tensor_bits(
        memory=ref.memory,
        core=core,
        offset=ref.element_offset + start,
        shape=(count,),
    )
    return list(value)


def _stage_region(
    session,
    ref,
    *,
    core,
    start,
    count,
    destination_memory,
    destination_word_offset,
    transfers,
):
    bits = _read_flat_bits(session, ref, core=0, start=start, count=count)
    session.write_tensor_bits(
        memory=destination_memory,
        core=core,
        offset=destination_word_offset * FP16_PER_WORD,
        value=bits,
    )
    transfers.append({
        "kind": "stage_input",
        "tensor": ref.name,
        "source_memory": ref.memory,
        "destination_memory": destination_memory,
        "source_core": 0,
        "destination_core": core,
        "start_element": start,
        "element_count": count,
        "word_count": math.ceil(count / FP16_PER_WORD),
        "destination_word_offset": destination_word_offset,
    })


def _tile_regions(operation, inputs, partition):
    start, size = partition.start, partition.size
    if operation == "gemm":
        k_dim = inputs[0].shape[1]
        return ((inputs[0], start * k_dim, size * k_dim), (inputs[1], 0, inputs[1].element_count))
    if operation == "gemv":
        k_dim = inputs[0].shape[1]
        return ((inputs[0], start * k_dim, size * k_dim), (inputs[1], 0, inputs[1].element_count))
    if operation == "outer":
        return ((inputs[0], start, size), (inputs[1], 0, inputs[1].element_count))
    if operation == "scale":
        return ((inputs[0], start, size),)
    if operation == "add":
        return ((inputs[0], start, size), (inputs[1], start, size))
    raise AssertionError(operation)


def _output_region(operation, inputs, partition):
    if operation == "gemm":
        width = inputs[1].shape[1]
        return partition.start * width, partition.size * width
    if operation == "gemv":
        return partition.start, partition.size
    if operation == "outer":
        width = inputs[1].element_count
        return partition.start * width, partition.size * width
    return partition.start, partition.size


def _reserve(occupied, memory, word_offset, word_count):
    if memory not in occupied:
        return
    occupied[memory].append((word_offset, word_offset + word_count))


def _allocate_scratch(occupied, word_count):
    for memory in ("temp", "local"):
        cursor = 0
        for start, end in sorted(occupied[memory]):
            if cursor + word_count <= start:
                break
            cursor = max(cursor, end)
        if cursor + word_count <= MEMORY_WORD_CAPACITY[memory]:
            _reserve(occupied, memory, cursor, word_count)
            return memory, cursor
    raise ValueError(
        f"per-core staging needs {word_count} contiguous words but Local/Temp are full"
    )


def _prepare_input_addresses(operation, inputs, output, partition):
    regions = _tile_regions(operation, inputs, partition)
    if partition.core == 0:
        addresses = []
        for ref, start, _ in regions:
            if start % FP16_PER_WORD:
                raise ValueError("linear input partition is not word aligned")
            addresses.append((ref.memory, ref.word_offset + start // FP16_PER_WORD))
        return tuple(addresses), ()

    occupied = {"local": [], "temp": []}
    if output.memory in occupied:
        _reserve(occupied, output.memory, output.word_offset, output.word_count)
    for ref, start, count in regions:
        if start % FP16_PER_WORD:
            raise ValueError("linear input partition is not word aligned")
        if ref.memory in occupied:
            _reserve(
                occupied,
                ref.memory,
                ref.word_offset + start // FP16_PER_WORD,
                math.ceil(count / FP16_PER_WORD),
            )

    addresses = []
    stages = []
    for ref, start, count in regions:
        if ref.memory == "global":
            memory, word_offset = _allocate_scratch(
                occupied, math.ceil(count / FP16_PER_WORD)
            )
        else:
            memory = ref.memory
            word_offset = ref.word_offset + start // FP16_PER_WORD
        addresses.append((memory, word_offset))
        stages.append((ref, start, count, memory, word_offset))
    return tuple(addresses), tuple(stages)


def _build_tile(
    operation,
    inputs,
    input_addresses,
    output,
    partition,
    *,
    command_id,
    attrs,
    group_end,
):
    start, size = partition.start, partition.size
    out_start, _ = _output_region(operation, inputs, partition)
    if any(value % FP16_PER_WORD for value in (out_start,)):
        raise ValueError("parallel output partition is not word aligned")

    if operation == "gemm":
        k_dim = inputs[0].shape[1]
        m_cols = inputs[1].shape[1]
        a_start = start * k_dim
        if a_start % FP16_PER_WORD:
            raise ValueError("parallel GEMM A partition is not word aligned")
        return build_gemm(
            command_id,
            a_memory=input_addresses[0][0],
            a_word_offset=input_addresses[0][1],
            b_memory=input_addresses[1][0],
            b_word_offset=input_addresses[1][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset + out_start // FP16_PER_WORD,
            n_rows=size,
            m_cols=m_cols,
            k_dim=k_dim,
            group_end=group_end,
        )
    if operation == "gemv":
        k_dim = inputs[0].shape[1]
        a_start = start * k_dim
        if a_start % FP16_PER_WORD:
            raise ValueError("parallel GEMV matrix partition is not word aligned")
        return build_gemv(
            command_id,
            a_memory=input_addresses[0][0],
            a_word_offset=input_addresses[0][1],
            x_memory=input_addresses[1][0],
            x_word_offset=input_addresses[1][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset + out_start // FP16_PER_WORD,
            n_rows=size,
            k_dim=k_dim,
            group_end=group_end,
        )
    if operation == "outer":
        if start % FP16_PER_WORD:
            raise ValueError("parallel OUTER input partition is not word aligned")
        return build_outer(
            command_id,
            a_memory=input_addresses[0][0],
            a_word_offset=input_addresses[0][1],
            b_memory=input_addresses[1][0],
            b_word_offset=input_addresses[1][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset + out_start // FP16_PER_WORD,
            n_rows=size,
            m_cols=inputs[1].element_count,
            group_end=group_end,
        )
    if operation == "scale":
        return build_scale(
            command_id,
            src_memory=input_addresses[0][0],
            src_word_offset=input_addresses[0][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset + out_start // FP16_PER_WORD,
            rows=1,
            cols=size,
            alpha_bits=attrs["alpha_bits"],
            group_end=group_end,
        )
    if operation == "add":
        return build_add(
            command_id,
            a_memory=input_addresses[0][0],
            a_word_offset=input_addresses[0][1],
            b_memory=input_addresses[1][0],
            b_word_offset=input_addresses[1][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset + out_start // FP16_PER_WORD,
            rows=1,
            cols=size,
            group_end=group_end,
        )
    raise AssertionError(operation)


def execute_linear(
    session,
    operation,
    inputs,
    output,
    *,
    command_id,
    policy="auto",
    attrs=None,
    group_end=True,
):
    """Plan, stage, execute and gather one logical linear operator."""
    attrs = dict(attrs or {})
    plan = plan_linear(operation, inputs, policy=policy, available_cores=session.cores)
    if plan.core_count > 1 and output.memory == "global":
        if policy != "auto":
            raise ValueError("multicore output cannot use shared Global SRAM")
        single = plan_linear(
            operation, inputs, policy="single", available_cores=session.cores
        )
        plan = LinearPlan(
            operation=single.operation,
            requested_policy=policy,
            core_count=1,
            partition_unit=single.partition_unit,
            partitions=single.partitions,
            scalar_work=single.scalar_work,
            reason="shared_global_output_contention",
        )
    transfers = []
    before = session._counters()
    wall_start = time.perf_counter()

    try:
        prepared = tuple(
            _prepare_input_addresses(operation, inputs, output, partition)
            for partition in plan.partitions
        )
    except ValueError:
        if policy != "auto" or plan.core_count == 1:
            raise
        single = plan_linear(
            operation, inputs, policy="single", available_cores=session.cores
        )
        plan = LinearPlan(
            operation=single.operation,
            requested_policy=policy,
            core_count=1,
            partition_unit=single.partition_unit,
            partitions=single.partitions,
            scalar_work=single.scalar_work,
            reason="per_core_sram_staging_unavailable",
        )
        prepared = tuple(
            _prepare_input_addresses(operation, inputs, output, partition)
            for partition in plan.partitions
        )

    commands = []
    for partition, (input_addresses, stages) in zip(plan.partitions, prepared):
        for ref, start, count, memory, word_offset in stages:
            _stage_region(
                session,
                ref,
                core=partition.core,
                start=start,
                count=count,
                destination_memory=memory,
                destination_word_offset=word_offset,
                transfers=transfers,
            )
        commands.append(_build_tile(
            operation,
            inputs,
            input_addresses,
            output,
            partition,
            command_id=command_id,
            attrs=attrs,
            group_end=group_end,
        ))

    after_stage = session._counters()
    if plan.core_count == 1:
        run = session.run(commands)
    else:
        run = session.run_scheduled([
            ScheduledCommand(partition.core, command)
            for partition, command in zip(plan.partitions, commands)
        ])
    after_run = session._counters()

    if output.memory != "global":
        for partition in plan.partitions:
            if partition.core == 0:
                continue
            start, count = _output_region(operation, inputs, partition)
            bits = _read_flat_bits(
                session, output, core=partition.core, start=start, count=count
            )
            session.write_tensor_bits(
                memory=output.memory,
                core=0,
                offset=output.element_offset + start,
                value=bits,
            )
            transfers.append({
                "kind": "gather_output",
                "tensor": output.name,
                "memory": output.memory,
                "source_core": partition.core,
                "destination_core": 0,
                "start_element": start,
                "element_count": count,
                "word_count": math.ceil(count / FP16_PER_WORD),
            })

    after = session._counters()
    result = {
        "plan": plan.to_dict(),
        "commands": [
            {
                "core": partition.core,
                "id": command.command_id,
                "opcode": command.opcode,
                "subop": command.subop,
                "group_end": command.group_end,
                "words": list(command.words),
            }
            for partition, command in zip(plan.partitions, commands)
        ],
        "run": run.to_dict(),
        "transfers": transfers,
        "metrics": {
            "total_cycles": int(after.cycle - before.cycle),
            "total_read_bytes": int(after.read_bytes - before.read_bytes),
            "total_write_bytes": int(after.write_bytes - before.write_bytes),
            "stage_cycles": int(after_stage.cycle - before.cycle),
            "stage_read_bytes": int(after_stage.read_bytes - before.read_bytes),
            "stage_write_bytes": int(after_stage.write_bytes - before.write_bytes),
            "run_cycles": int(after_run.cycle - after_stage.cycle),
            "run_read_bytes": int(after_run.read_bytes - after_stage.read_bytes),
            "run_write_bytes": int(after_run.write_bytes - after_stage.write_bytes),
            "gather_cycles": int(after.cycle - after_run.cycle),
            "gather_read_bytes": int(after.read_bytes - after_run.read_bytes),
            "gather_write_bytes": int(after.write_bytes - after_run.write_bytes),
            "wall_seconds": time.perf_counter() - wall_start,
        },
    }
    return run, result
