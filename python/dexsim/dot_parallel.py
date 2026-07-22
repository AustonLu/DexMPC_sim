"""Capability-gated K-split DOT execution with deterministic FP16 merge."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import math
from typing import Mapping

from .commands import add_reduce as build_add_reduce, dot as build_dot
from .parallel import (
    FP16_PER_WORD,
    _allocate_scratch,
    _partitions,
    _reserve,
)
from .session import ScheduledCommand, fp16_value


DOT_EXECUTION_POLICIES = ("single", "auto", "dual", "quad")
PRIVATE_MEMORIES = ("local", "temp")

# Production remains single-core until an end-to-end DOT path passes the
# measured benefit gate. Explicit dual/quad policies remain available.
DOT_AUTO_THRESHOLD = math.inf


def normalize_dot_execution_policy(value):
    value = str(value).lower()
    if value not in DOT_EXECUTION_POLICIES:
        raise ValueError(
            "dot_execution_policy must be 'single', 'auto', 'dual', or 'quad'"
        )
    return value


@dataclass(frozen=True)
class DotPartition:
    core: int
    start: int
    size: int

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class DotPlan:
    requested_policy: str
    core_count: int
    partitions: tuple[DotPartition, ...]
    element_count: int
    merge: str
    reason: str

    def to_dict(self):
        value = asdict(self)
        value["partitions"] = [item.to_dict() for item in self.partitions]
        return value


@dataclass(frozen=True)
class DotRunResult:
    cycles: int
    read_bytes: int
    write_bytes: int
    command_count: int
    done_count_before: int
    done_count_after: int
    last_done: int
    reset_count: int
    command_results: tuple[object, ...]
    phases: Mapping[str, object]
    setup_cycles: int = 0
    setup_read_bytes: int = 0
    setup_write_bytes: int = 0

    @property
    def total_cycles(self):
        return self.setup_cycles + self.cycles

    @property
    def total_read_bytes(self):
        return self.setup_read_bytes + self.read_bytes

    @property
    def total_write_bytes(self):
        return self.setup_write_bytes + self.write_bytes

    def to_dict(self):
        return {
            "cycles": self.cycles,
            "read_bytes": self.read_bytes,
            "write_bytes": self.write_bytes,
            "command_count": self.command_count,
            "done_count_before": self.done_count_before,
            "done_count_after": self.done_count_after,
            "last_done": self.last_done,
            "reset_count": self.reset_count,
            "command_results": [value.to_dict() for value in self.command_results],
            "phases": dict(self.phases),
            "setup_cycles": self.setup_cycles,
            "setup_read_bytes": self.setup_read_bytes,
            "setup_write_bytes": self.setup_write_bytes,
        }


def plan_dot(element_count, *, policy="auto", available_cores=(0, 1, 2, 3)):
    policy = normalize_dot_execution_policy(policy)
    element_count = int(element_count)
    if element_count <= 0:
        raise ValueError("DOT element_count must be positive")
    available_cores = tuple(sorted(set(int(core) for core in available_cores)))
    if not available_cores or available_cores[0] != 0:
        raise ValueError("parallel DOT requires core0")

    max_cores = min(4, len(available_cores))
    if policy == "single":
        requested = 1
        reason = "explicit_single_policy"
    elif policy == "dual":
        requested = 2
        reason = "diagnostic_dual_policy"
    elif policy == "quad":
        requested = 4
        reason = "diagnostic_quad_policy"
    else:
        requested = 4 if element_count >= DOT_AUTO_THRESHOLD else 1
        reason = (
            "measured_parallel_threshold"
            if requested > 1
            else "below_measured_parallel_threshold"
        )

    requested = min(requested, max_cores)
    for candidate in (requested, 2, 1):
        if candidate > requested or candidate > max_cores:
            continue
        values = _partitions(element_count, candidate)
        if values is None:
            continue
        cores = available_cores[:candidate]
        partitions = tuple(
            DotPartition(core, start, size)
            for core, (start, size) in zip(cores, values)
        )
        selected_reason = reason
        if candidate != requested:
            selected_reason = "word_aligned_partition_unavailable"
        return DotPlan(
            requested_policy=policy,
            core_count=candidate,
            partitions=partitions,
            element_count=element_count,
            merge=(
                "none"
                if candidate == 1
                else "core0_add_reduce_fixed_tree"
            ),
            reason=selected_reason,
        )
    raise AssertionError("single-core DOT partition must always be available")


def _command_dict(core, command):
    return {
        "core": int(core),
        "id": command.command_id,
        "opcode": command.opcode,
        "subop": command.subop,
        "group_end": command.group_end,
        "words": list(command.words),
    }


def _counter_delta(before, after):
    return {
        "cycles": int(after.cycle - before.cycle),
        "read_bytes": int(after.read_bytes - before.read_bytes),
        "write_bytes": int(after.write_bytes - before.write_bytes),
    }


def _private_layout(refs, output, partition):
    occupied = {memory: [] for memory in PRIVATE_MEMORIES}
    if output.memory in occupied:
        _reserve(occupied, output.memory, output.word_offset, output.word_count)
    for ref in refs:
        if ref.memory in occupied:
            _reserve(
                occupied,
                ref.memory,
                ref.word_offset + partition.start // FP16_PER_WORD,
                math.ceil(partition.size / FP16_PER_WORD),
            )

    result = []
    for ref in refs:
        if ref.memory in PRIVATE_MEMORIES:
            result.append((
                ref.memory,
                ref.word_offset + partition.start // FP16_PER_WORD,
            ))
        else:
            result.append(_allocate_scratch(
                occupied, math.ceil(partition.size / FP16_PER_WORD)
            ))
    return tuple(result)


def _merge_tree(core_count):
    if core_count == 2:
        return {
            "levels": [[[0, 1]]],
            "hardware_padding": "zero_to_16_lanes",
        }
    if core_count == 4:
        return {
            "levels": [[[0, 1], [2, 3]], [[0, 2]]],
            "hardware_padding": "zero_to_16_lanes",
        }
    return {"levels": [], "hardware_padding": "none"}


def execute_dot(
    session,
    left,
    right,
    output,
    *,
    command_id,
    policy="auto",
    group_end=True,
    coverage_checker=None,
    materialize_callback=None,
):
    """Execute one logical DOT using real MAC contexts and hardware merge.

    ``coverage_checker`` and ``materialize_callback`` are optional hooks used
    by the resident Program executor. They keep address and core ownership
    decisions inside the SDK while allowing an already-resident producer shard
    to feed the matching DOT partition without a redundant copy.
    """
    if left.element_count != right.element_count:
        raise ValueError("DOT inputs must contain the same number of elements")
    if output.element_count != 1:
        raise ValueError("DOT output must contain one element")

    plan = plan_dot(
        left.element_count, policy=policy, available_cores=session.cores
    )
    if plan.core_count > 1 and output.memory not in PRIVATE_MEMORIES:
        plan = plan_dot(
            left.element_count, policy="single", available_cores=session.cores
        )
        plan = DotPlan(
            requested_policy=normalize_dot_execution_policy(policy),
            core_count=plan.core_count,
            partitions=plan.partitions,
            element_count=plan.element_count,
            merge=plan.merge,
            reason="shared_global_output_requires_single_core",
        )

    before = session._counters()
    if plan.core_count == 1:
        command = build_dot(
            command_id,
            a_memory=left.memory,
            a_word_offset=left.word_offset,
            b_memory=right.memory,
            b_word_offset=right.word_offset,
            out_memory=output.memory,
            out_word_offset=output.word_offset,
            element_count=left.element_count,
            group_end=group_end,
        )
        run = session.run([command])
        after = session._counters()
        engine_cycles = max(
            (value.done_cycle for value in run.command_results), default=0
        )
        metrics = {
            "total_cycles": int(after.cycle - before.cycle),
            "total_read_bytes": int(after.read_bytes - before.read_bytes),
            "total_write_bytes": int(after.write_bytes - before.write_bytes),
            "materialize_cycles": 0,
            "materialize_read_bytes": 0,
            "materialize_write_bytes": 0,
            "stage_cycles": 0,
            "partial_run_cycles": run.total_cycles,
            "partial_gather_cycles": 0,
            "merge_input_cycles": 0,
            "merge_run_cycles": 0,
            "output_commit_cycles": 0,
            "run_cycles": run.total_cycles,
            "scheduled_run_cycles": run.total_cycles,
            "engine_compute_cycles": int(engine_cycles),
            "partial_engine_cycles": int(engine_cycles),
            "merge_engine_cycles": 0,
            "gather_cycles": 0,
        }
        record = {
            "plan": plan.to_dict(),
            "commands": [_command_dict(0, command)],
            "run": run.to_dict(),
            "partial_bits": [],
            "merge_tree": _merge_tree(1),
            "transfers": [],
            "resident_reuse": [],
            "host_ops": [],
            "metrics": metrics,
        }
        return run, record

    refs = (left, right)
    layouts = {}
    reused = []
    needs_materialize = set()
    for partition in plan.partitions:
        if partition.start % FP16_PER_WORD:
            raise ValueError("DOT partition start is not word aligned")
        if partition.core == 0:
            layouts[partition.core] = tuple(
                (ref.memory, ref.word_offset + partition.start // FP16_PER_WORD)
                for ref in refs
            )
            for ref in refs:
                if coverage_checker is not None and coverage_checker(
                    ref.name, partition.core, partition.start, partition.size
                ):
                    reused.append({
                        "tensor": ref.name,
                        "core": partition.core,
                        "start_element": partition.start,
                        "element_count": partition.size,
                    })
                elif materialize_callback is not None:
                    needs_materialize.add(ref.name)
            continue
        layouts[partition.core] = _private_layout(refs, output, partition)
        for ref in refs:
            if (
                ref.memory in PRIVATE_MEMORIES
                and coverage_checker is not None
                and coverage_checker(
                    ref.name, partition.core, partition.start, partition.size
                )
            ):
                reused.append({
                    "tensor": ref.name,
                    "core": partition.core,
                    "start_element": partition.start,
                    "element_count": partition.size,
                })
            elif materialize_callback is not None:
                needs_materialize.add(ref.name)

    for name in sorted(needs_materialize):
        materialize_callback(name, reason="dot_partition_source")
    after_materialize = session._counters()

    transfers = []
    for partition in plan.partitions:
        if partition.core == 0:
            continue
        for ref, (memory, word_offset) in zip(refs, layouts[partition.core]):
            if any(
                item["tensor"] == ref.name
                and item["core"] == partition.core
                and item["start_element"] == partition.start
                and item["element_count"] == partition.size
                for item in reused
            ):
                continue
            transfer_before = session._counters()
            bits = session.read_tensor_bits(
                memory=ref.memory,
                core=0,
                offset=ref.element_offset + partition.start,
                shape=(partition.size,),
            )
            session.write_tensor_bits(
                memory=memory,
                core=partition.core,
                offset=word_offset * FP16_PER_WORD,
                value=bits,
            )
            transfer_after = session._counters()
            transfers.append({
                "kind": "dot_stage_input",
                "tensor": ref.name,
                "source_core": 0,
                "destination_core": partition.core,
                "source_memory": ref.memory,
                "destination_memory": memory,
                "start_element": partition.start,
                "element_count": partition.size,
                **_counter_delta(transfer_before, transfer_after),
            })
    after_stage = session._counters()

    partial_commands = []
    for partition in plan.partitions:
        addresses = layouts[partition.core]
        partial_commands.append(build_dot(
            command_id,
            a_memory=addresses[0][0],
            a_word_offset=addresses[0][1],
            b_memory=addresses[1][0],
            b_word_offset=addresses[1][1],
            out_memory=output.memory,
            out_word_offset=output.word_offset,
            element_count=partition.size,
            group_end=False,
        ))

    partial_run = session.run_scheduled([
        ScheduledCommand(partition.core, command)
        for partition, command in zip(plan.partitions, partial_commands)
    ])
    after_partial = session._counters()

    partial_bits = []
    for partition in plan.partitions:
        value = session.read_tensor_bits(
            memory=output.memory,
            core=partition.core,
            offset=output.element_offset,
            shape=(1,),
        )
        partial_bits.append(int(value[0]))
    after_gather = session._counters()

    session.write_tensor_bits(
        memory=output.memory,
        core=0,
        offset=output.element_offset,
        value=partial_bits,
    )
    after_merge_input = session._counters()
    merge_command = build_add_reduce(
        command_id,
        src_memory=output.memory,
        src_word_offset=output.word_offset,
        element_count=plan.core_count,
        group_end=group_end,
    )
    merge_run = session.run([merge_command])
    merge_result = merge_run.command_results[0]
    if not merge_result.reduce_valid or merge_result.reduce_value_bits is None:
        raise RuntimeError("DOT hardware merge did not produce a valid FP16 result")
    after_merge = session._counters()
    session.write_tensor_bits(
        memory=output.memory,
        core=0,
        offset=output.element_offset,
        value=[int(merge_result.reduce_value_bits)],
    )
    after_commit = session._counters()

    partial_engine = max(
        (value.done_cycle for value in partial_run.command_results), default=0
    )
    merge_engine = max(
        (value.done_cycle for value in merge_run.command_results), default=0
    )
    scheduled_cycles = partial_run.total_cycles + merge_run.total_cycles
    commands = [
        _command_dict(partition.core, command)
        for partition, command in zip(plan.partitions, partial_commands)
    ] + [_command_dict(0, merge_command)]
    results = tuple(partial_run.command_results) + tuple(merge_run.command_results)
    combined = DotRunResult(
        cycles=int(after_commit.cycle - before.cycle),
        read_bytes=int(after_commit.read_bytes - before.read_bytes),
        write_bytes=int(after_commit.write_bytes - before.write_bytes),
        command_count=len(commands),
        done_count_before=(
            partial_run.done_count_before + merge_run.done_count_before
        ),
        done_count_after=partial_run.done_count_after + merge_run.done_count_after,
        last_done=merge_run.last_done,
        reset_count=merge_run.reset_count,
        command_results=results,
        phases={
            "partial_run": partial_run.to_dict(),
            "merge_run": merge_run.to_dict(),
        },
    )
    metrics = {
        "total_cycles": int(after_commit.cycle - before.cycle),
        "total_read_bytes": int(after_commit.read_bytes - before.read_bytes),
        "total_write_bytes": int(after_commit.write_bytes - before.write_bytes),
        "materialize_cycles": int(after_materialize.cycle - before.cycle),
        "materialize_read_bytes": int(
            after_materialize.read_bytes - before.read_bytes
        ),
        "materialize_write_bytes": int(
            after_materialize.write_bytes - before.write_bytes
        ),
        "stage_cycles": int(after_stage.cycle - after_materialize.cycle),
        "partial_run_cycles": int(after_partial.cycle - after_stage.cycle),
        "partial_gather_cycles": int(after_gather.cycle - after_partial.cycle),
        "merge_input_cycles": int(after_merge_input.cycle - after_gather.cycle),
        "merge_run_cycles": int(after_merge.cycle - after_merge_input.cycle),
        "output_commit_cycles": int(after_commit.cycle - after_merge.cycle),
        "run_cycles": int(scheduled_cycles),
        "scheduled_run_cycles": int(scheduled_cycles),
        "engine_compute_cycles": int(partial_engine + merge_engine),
        "partial_engine_cycles": int(partial_engine),
        "merge_engine_cycles": int(merge_engine),
        "gather_cycles": int(
            after_commit.cycle - after_partial.cycle
        ),
    }
    record = {
        "plan": plan.to_dict(),
        "commands": commands,
        "run": combined.to_dict(),
        "partial_bits": partial_bits,
        "partial_values": [fp16_value(value) for value in partial_bits],
        "merge_tree": _merge_tree(plan.core_count),
        "transfers": transfers,
        "resident_reuse": reused,
        "host_ops": [],
        "metrics": metrics,
    }
    return combined, record
