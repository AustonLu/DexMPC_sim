"""Kernel-level tensor residency for multi-core fixed Programs."""

from __future__ import annotations

from dataclasses import dataclass

from .parallel import (
    LINEAR_OPERATORS,
    _build_tile,
    _output_region,
    _tile_regions,
    plan_linear,
)
from .session import ScheduledCommand


FP16_PER_WORD = 8
PRIVATE_MEMORIES = ("local", "temp")
RESIDENCY_POLICIES = ("off", "auto", "on")


def normalize_residency_policy(value):
    value = str(value).lower()
    if value not in RESIDENCY_POLICIES:
        raise ValueError("residency_policy must be 'off', 'auto', or 'on'")
    return value


@dataclass(frozen=True)
class ResidentDecision:
    enabled: bool
    requested_policy: str
    execution_policy: str
    effective_execution_policy: str
    reason: str

    def to_dict(self):
        return {
            "enabled": self.enabled,
            "requested_policy": self.requested_policy,
            "execution_policy": self.execution_policy,
            "effective_execution_policy": self.effective_execution_policy,
            "reason": self.reason,
        }


def choose_resident_decision(program, *, execution_policy, residency_policy):
    residency_policy = normalize_residency_policy(residency_policy)
    if execution_policy == "single":
        return ResidentDecision(
            False, residency_policy, execution_policy, "single", "single_core_requested"
        )
    linear_ops = [op for op in program._ops if op.kind in LINEAR_OPERATORS]
    produced = {op.output for op in linear_ops}
    forwarded_edges = sum(
        1 for op in linear_ops for name in op.inputs if name in produced
    )
    if residency_policy == "off":
        return ResidentDecision(
            False, residency_policy, execution_policy, execution_policy,
            "residency_explicitly_disabled",
        )
    if residency_policy == "on":
        if execution_policy == "auto":
            return ResidentDecision(
                False, residency_policy, execution_policy, "single",
                "no_validated_auto_execution_threshold",
            )
        return ResidentDecision(
            True, residency_policy, execution_policy, execution_policy,
            "residency_explicitly_enabled",
        )
    if execution_policy in ("dual", "quad") and forwarded_edges > 0:
        return ResidentDecision(
            True, residency_policy, execution_policy, execution_policy,
            "explicit_multicore_with_reusable_edge",
        )
    # Production auto stays conservative until the benchmark calibration is
    # frozen.  M6.2 tools can force on + dual/quad without changing this gate.
    return ResidentDecision(
        False, residency_policy, execution_policy, "single",
        "no_validated_auto_resident_threshold",
    )


class ResidentKernelExecutor:
    """Executes linear Program ops without per-op gather/stage round trips."""

    def __init__(
        self,
        session,
        buffers,
        specs,
        constant_names,
        *,
        decision,
        persistent_constant_coverage=None,
    ):
        self.session = session
        self.buffers = buffers
        self.specs = specs
        self.constant_names = set(constant_names)
        self.decision = decision
        self.persistent_constant_coverage = (
            persistent_constant_coverage
            if persistent_constant_coverage is not None
            else {}
        )
        self.coverage = {
            name: {core: list(intervals) for core, intervals in cores.items()}
            for name, cores in self.persistent_constant_coverage.items()
        }
        self.materialized = set()
        self.transfers = []
        self.events = []
        self.compute_cycles = 0
        self.compute_read_bytes = 0
        self.compute_write_bytes = 0
        self.stage_cycles = 0
        self.stage_read_bytes = 0
        self.stage_write_bytes = 0
        self.materialize_cycles = 0
        self.materialize_read_bytes = 0
        self.materialize_write_bytes = 0
        self.avoided_stage_regions = 0
        self.avoided_stage_bytes = 0
        self.deferred_gather_regions = 0
        self.deferred_gather_bytes = 0
        self.persistent_replica_hits = 0

    def begin_run(self, input_names):
        self.materialized = set(input_names) | self.constant_names

    def can_reside(self, op, plan):
        if not self.decision.enabled or plan.core_count <= 1:
            return False, "resident_multicore_not_selected"
        refs = [self.buffers[name] for name in op.inputs]
        output = self.buffers[op.output]
        if any(ref.memory not in PRIVATE_MEMORIES for ref in refs + [output]):
            return False, "resident_requires_private_local_or_temp"
        try:
            for partition in plan.partitions:
                for _, start, _ in _tile_regions(op.kind, refs, partition):
                    if start % FP16_PER_WORD:
                        return False, "resident_input_not_word_aligned"
                out_start, _ = _output_region(op.kind, refs, partition)
                if out_start % FP16_PER_WORD:
                    return False, "resident_output_not_word_aligned"
        except (TypeError, ValueError):
            return False, "resident_layout_not_supported"
        return True, "resident_layout_supported"

    def execute(self, op, command):
        before = self.session._counters()
        if op.kind not in LINEAR_OPERATORS or not self.decision.enabled:
            return self._execute_materialized(op, command, before)

        refs = tuple(self.buffers[name] for name in op.inputs)
        plan, reason = self._select_plan(op, refs)
        supported = plan is not None
        if not supported:
            return self._execute_materialized(op, command, before, fallback_reason=reason)

        transfer_start = len(self.transfers)
        reused = []
        for partition in plan.partitions:
            for ref, start, count in _tile_regions(op.kind, refs, partition):
                if partition.core == 0:
                    continue
                if self._covers(ref.name, partition.core, start, count):
                    self.avoided_stage_regions += 1
                    self.avoided_stage_bytes += count * 2
                    if ref.name in self.constant_names:
                        self.persistent_replica_hits += 1
                    reused.append({
                        "tensor": ref.name,
                        "core": partition.core,
                        "start_element": start,
                        "element_count": count,
                    })
                    continue
                if ref.name not in self.materialized:
                    self.materialize(ref.name, reason="layout_change")
                self._stage(ref, partition.core, start, count)

        after_stage = self.session._counters()
        commands = []
        attrs = dict(op.attrs)
        if op.kind == "scale":
            from .session import fp16_bits
            attrs["alpha_bits"] = fp16_bits(op.attrs["alpha"])
        for partition in plan.partitions:
            input_addresses = tuple(
                (ref.memory, ref.word_offset + start // FP16_PER_WORD)
                for ref, start, _ in _tile_regions(op.kind, refs, partition)
            )
            commands.append(_build_tile(
                op.kind, refs, input_addresses, self.buffers[op.output], partition,
                command_id=command.command_id, attrs=attrs,
                group_end=command.group_end,
            ))

        run = self.session.run_scheduled([
            ScheduledCommand(partition.core, lowered)
            for partition, lowered in zip(plan.partitions, commands)
        ])
        after_run = self.session._counters()
        self.compute_cycles += after_run.cycle - after_stage.cycle
        self.compute_read_bytes += after_run.read_bytes - after_stage.read_bytes
        self.compute_write_bytes += after_run.write_bytes - after_stage.write_bytes

        output_ref = self.buffers[op.output]
        self.coverage[op.output] = {}
        output_regions = []
        for partition in plan.partitions:
            start, count = _output_region(op.kind, refs, partition)
            self._add_coverage(op.output, partition.core, start, count)
            output_regions.append({
                "core": partition.core,
                "start_element": start,
                "element_count": count,
            })
        self.materialized.discard(op.output)
        deferred = sum(count * 2 for _, count in (
            _output_region(op.kind, refs, partition)
            for partition in plan.partitions if partition.core != 0
        ))
        self.deferred_gather_regions += max(0, plan.core_count - 1)
        self.deferred_gather_bytes += deferred

        after = self.session._counters()
        metrics = self._metrics(before, after_stage, after_run, after)
        record = {
            "plan": {**plan.to_dict(), "reason": reason, "resident": True},
            "commands": [
                {
                    "core": partition.core,
                    "id": lowered.command_id,
                    "opcode": lowered.opcode,
                    "subop": lowered.subop,
                    "group_end": lowered.group_end,
                    "words": list(lowered.words),
                }
                for partition, lowered in zip(plan.partitions, commands)
            ],
            "run": run.to_dict(),
            "transfers": self.transfers[transfer_start:],
            "metrics": metrics,
            "residency": {
                "reused_inputs": reused,
                "output_regions": output_regions,
                "materialized_after": False,
            },
        }
        self.events.append({
            "kind": "resident_linear_op",
            "operation": op.kind,
            "output": op.output,
            "core_count": plan.core_count,
            "reused_input_regions": len(reused),
        })
        return run, record, metrics

    def _select_plan(self, op, refs):
        requested = self.decision.effective_execution_policy
        policies = {
            "dual": ("dual",),
            "quad": ("quad", "dual"),
            "auto": ("quad", "dual"),
        }.get(requested, (requested,))
        candidates = []
        rejected_reasons = []
        seen = set()
        for policy in policies:
            plan = plan_linear(
                op.kind, refs, policy=policy, available_cores=self.session.cores
            )
            key = tuple((item.core, item.start, item.size) for item in plan.partitions)
            if key in seen:
                continue
            seen.add(key)
            supported, reason = self.can_reside(op, plan)
            if not supported:
                rejected_reasons.append(reason)
                continue
            reused_bytes = 0
            reused_regions = 0
            for partition in plan.partitions:
                if partition.core == 0:
                    continue
                for ref, start, count in _tile_regions(op.kind, refs, partition):
                    if self._covers(ref.name, partition.core, start, count):
                        reused_bytes += count * 2
                        reused_regions += 1
            candidates.append((reused_bytes, reused_regions, plan.core_count, plan))
        if not candidates:
            reason = (
                rejected_reasons[0]
                if rejected_reasons
                else "resident_layout_not_supported"
            )
            return None, reason
        # Reuse dominates core count: changing a producer's layout can cost far
        # more than one additional MAC lane saves for the next short command.
        _, _, _, selected = max(candidates, key=lambda value: value[:3])
        reason = (
            "consumer_compatible_partition"
            if any(value[0] > 0 for value in candidates)
            else "resident_layout_supported"
        )
        return selected, reason

    def _execute_materialized(self, op, command, before, fallback_reason=None):
        for name in op.inputs:
            self.materialize(name, reason="barrier_or_fallback")
        after_materialize = self.session._counters()
        if op.kind in LINEAR_OPERATORS:
            from .parallel import execute_linear
            attrs = dict(op.attrs)
            if op.kind == "scale":
                from .session import fp16_bits
                attrs["alpha_bits"] = fp16_bits(op.attrs["alpha"])
            policy = self.decision.execution_policy
            if self.decision.requested_policy == "on" and policy == "auto":
                policy = self.decision.effective_execution_policy
            # A shared Global output cannot be written concurrently by the
            # private MAC contexts.  This is the expected capacity-pressure
            # fallback when the fixed Program allocator exhausts Local/Temp.
            if fallback_reason and self.buffers[op.output].memory == "global":
                policy = "single"
            run, record = execute_linear(
                self.session, op.kind, tuple(self.buffers[name] for name in op.inputs),
                self.buffers[op.output], command_id=command.command_id,
                policy=policy, attrs=attrs, group_end=command.group_end,
            )
            if fallback_reason:
                record["plan"] = {
                    **record["plan"],
                    "resident": False,
                    "resident_fallback_reason": fallback_reason,
                    "resident_requested_execution_policy": (
                        self.decision.execution_policy
                    ),
                }
            after = self.session._counters()
            metrics = {
                **record["metrics"],
                "total_cycles": after.cycle - before.cycle,
                "total_read_bytes": after.read_bytes - before.read_bytes,
                "total_write_bytes": after.write_bytes - before.write_bytes,
                "materialize_cycles": after_materialize.cycle - before.cycle,
            }
            self.compute_cycles += record["metrics"]["run_cycles"]
            self.compute_read_bytes += record["metrics"]["run_read_bytes"]
            self.compute_write_bytes += record["metrics"]["run_write_bytes"]
        else:
            run = self.session.run([command])
            after = self.session._counters()
            metrics = {
                "total_cycles": after.cycle - before.cycle,
                "total_read_bytes": after.read_bytes - before.read_bytes,
                "total_write_bytes": after.write_bytes - before.write_bytes,
                "stage_cycles": 0,
                "run_cycles": after.cycle - after_materialize.cycle,
                "gather_cycles": 0,
                "materialize_cycles": after_materialize.cycle - before.cycle,
                "wall_seconds": 0.0,
            }
            self.compute_cycles += after.cycle - after_materialize.cycle
            self.compute_read_bytes += after.read_bytes - after_materialize.read_bytes
            self.compute_write_bytes += after.write_bytes - after_materialize.write_bytes
            record = None

        if op.output in self.buffers:
            self.materialized.add(op.output)
            self.coverage.pop(op.output, None)
        self.events.append({
            "kind": "materialized_op",
            "operation": op.kind,
            "output": op.output,
            "fallback_reason": fallback_reason,
        })
        return run, record, metrics

    def materialize(self, name, *, reason):
        if name in self.materialized or name not in self.coverage:
            return
        ref = self.buffers[name]
        before = self.session._counters()
        copied_regions = []
        for core, intervals in sorted(self.coverage[name].items()):
            if core == 0:
                continue
            for start, count in intervals:
                bits = self.session.read_tensor_bits(
                    memory=ref.memory, core=core,
                    offset=ref.element_offset + start, shape=(count,),
                )
                self.session.write_tensor_bits(
                    memory=ref.memory, core=0,
                    offset=ref.element_offset + start, value=bits,
                )
                copied_regions.append({
                    "core": core,
                    "start_element": start,
                    "element_count": count,
                })
        after = self.session._counters()
        self.materialize_cycles += after.cycle - before.cycle
        self.materialize_read_bytes += after.read_bytes - before.read_bytes
        self.materialize_write_bytes += after.write_bytes - before.write_bytes
        if copied_regions:
            self.transfers.append({
                "kind": "materialize",
                "tensor": name,
                "reason": reason,
                "regions": copied_regions,
                "cycles": after.cycle - before.cycle,
                "read_bytes": after.read_bytes - before.read_bytes,
                "write_bytes": after.write_bytes - before.write_bytes,
            })
        self.materialized.add(name)
        self.events.append({
            "kind": "materialize",
            "tensor": name,
            "reason": reason,
            "region_count": len(copied_regions),
        })

    def summary(self):
        return {
            "decision": self.decision.to_dict(),
            "events": list(self.events),
            "transfers": list(self.transfers),
            "metrics": {
                "compute_cycles": int(self.compute_cycles),
                "compute_read_bytes": int(self.compute_read_bytes),
                "compute_write_bytes": int(self.compute_write_bytes),
                "resident_stage_cycles": int(self.stage_cycles),
                "resident_stage_read_bytes": int(self.stage_read_bytes),
                "resident_stage_write_bytes": int(self.stage_write_bytes),
                "materialize_cycles": int(self.materialize_cycles),
                "materialize_read_bytes": int(self.materialize_read_bytes),
                "materialize_write_bytes": int(self.materialize_write_bytes),
                "avoided_stage_regions": int(self.avoided_stage_regions),
                "avoided_stage_bytes": int(self.avoided_stage_bytes),
                "deferred_gather_regions": int(self.deferred_gather_regions),
                "deferred_gather_bytes": int(self.deferred_gather_bytes),
                "persistent_replica_hits": int(self.persistent_replica_hits),
            },
        }

    def _stage(self, ref, core, start, count):
        before = self.session._counters()
        bits = self.session.read_tensor_bits(
            memory=ref.memory, core=0,
            offset=ref.element_offset + start, shape=(count,),
        )
        self.session.write_tensor_bits(
            memory=ref.memory, core=core,
            offset=ref.element_offset + start, value=bits,
        )
        after = self.session._counters()
        self.stage_cycles += after.cycle - before.cycle
        self.stage_read_bytes += after.read_bytes - before.read_bytes
        self.stage_write_bytes += after.write_bytes - before.write_bytes
        self._add_coverage(ref.name, core, start, count)
        if ref.name in self.constant_names:
            self._add_persistent_coverage(ref.name, core, start, count)
        self.transfers.append({
            "kind": "resident_stage",
            "tensor": ref.name,
            "source_core": 0,
            "destination_core": core,
            "memory": ref.memory,
            "start_element": start,
            "element_count": count,
            "cycles": after.cycle - before.cycle,
            "read_bytes": after.read_bytes - before.read_bytes,
            "write_bytes": after.write_bytes - before.write_bytes,
        })

    def _covers(self, name, core, start, count):
        end = start + count
        for current_start, current_count in self.coverage.get(name, {}).get(core, ()):
            if current_start <= start and current_start + current_count >= end:
                return True
        return False

    def _add_coverage(self, name, core, start, count):
        values = self.coverage.setdefault(name, {}).setdefault(core, [])
        values.append((int(start), int(count)))
        values.sort()
        merged = []
        for current_start, current_count in values:
            current_end = current_start + current_count
            if not merged or merged[-1][0] + merged[-1][1] < current_start:
                merged.append([current_start, current_count])
            else:
                merged[-1][1] = max(
                    merged[-1][0] + merged[-1][1], current_end
                ) - merged[-1][0]
        self.coverage[name][core] = [tuple(value) for value in merged]

    def _add_persistent_coverage(self, name, core, start, count):
        values = self.persistent_constant_coverage.setdefault(name, {}).setdefault(core, [])
        end = start + count
        for current_start, current_count in values:
            if current_start <= start and current_start + current_count >= end:
                return
        values.append((int(start), int(count)))

    @staticmethod
    def _metrics(before, after_stage, after_run, after):
        return {
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
            "wall_seconds": 0.0,
        }
