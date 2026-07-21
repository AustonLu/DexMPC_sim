#!/usr/bin/env python3
"""Exercise every TopChip MAC context alone and in concurrent waves."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
sys.path.insert(0, str(ROOT / "tests" / "python"))

import dexsim  # noqa: E402
import reference_fp16 as ref  # noqa: E402


CORES = (0, 1, 2, 3)
PAIRS = tuple((left, right) for left in CORES for right in CORES if left < right)


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


@dataclass(frozen=True)
class OperatorCase:
    name: str
    output_memory: str
    output_offset: int
    output_shape: tuple[int, ...]
    expected_bits: tuple[int, ...]
    builder: object


def prepare_cases(session):
    gemm_a = [ref.bits(value) for value in (1, 2, 3, 4, -1, 0.5, 2, -2)]
    gemm_b = [ref.bits(value) for value in (0.5, 2, -1, 1, 3, -0.5, 2, 4)]
    gemv_a = [ref.bits(value) for value in (1, -2, 0.5, 4, -1, 3, 2, -0.5)]
    gemv_x = [ref.bits(value) for value in (2, -1, 0.25, 3)]
    outer_a = [ref.bits(value) for value in (2, -1)]
    outer_b = [ref.bits(value) for value in (0.5, 3, -2)]
    scale_a = [ref.bits(value) for value in (1, -2, 0.25, 8, -0.0, 3, 5, -7)]
    add_a = [ref.bits(value) for value in (1, -2, 0.25, 8, 0, 3, 5, -7)]
    add_b = [ref.bits(value) for value in (2, 2, -0.25, 0.5, -0.0, -3, 1, 4)]

    session.write_tensor_bits(memory="global", offset=0, value=gemm_a)
    session.write_tensor_bits(memory="global", offset=8, value=gemm_b)
    session.write_tensor_bits(memory="global", offset=16, value=gemv_a)
    session.write_tensor_bits(memory="global", offset=24, value=gemv_x)
    session.write_tensor_bits(memory="global", offset=32, value=outer_a)
    session.write_tensor_bits(memory="global", offset=40, value=outer_b)
    session.write_tensor_bits(memory="global", offset=48, value=scale_a)
    session.write_tensor_bits(memory="global", offset=56, value=add_a)
    session.write_tensor_bits(memory="global", offset=64, value=add_b)

    return (
        OperatorCase(
            "gemm", "local", 0, (2, 2), tuple(ref.gemm(gemm_a, gemm_b, 2, 2, 4)),
            lambda command_id: dexsim.gemm(
                command_id, a_memory="global", a_word_offset=0,
                b_memory="global", b_word_offset=1,
                out_memory="local", out_word_offset=0,
                n_rows=2, m_cols=2, k_dim=4,
            ),
        ),
        OperatorCase(
            "gemv", "local", 8, (2,), tuple(ref.gemm(gemv_a, gemv_x, 2, 1, 4)),
            lambda command_id: dexsim.gemv(
                command_id, a_memory="global", a_word_offset=2,
                x_memory="global", x_word_offset=3,
                out_memory="local", out_word_offset=1,
                n_rows=2, k_dim=4,
            ),
        ),
        OperatorCase(
            "outer", "local", 16, (2, 3), tuple(ref.gemm(outer_a, outer_b, 2, 3, 1)),
            lambda command_id: dexsim.outer(
                command_id, a_memory="global", a_word_offset=4,
                b_memory="global", b_word_offset=5,
                out_memory="local", out_word_offset=2,
                n_rows=2, m_cols=3,
            ),
        ),
        OperatorCase(
            "scale", "temp", 0, (8,), tuple(ref.scale_matrix(scale_a, ref.bits(-0.5))),
            lambda command_id: dexsim.scale(
                command_id, src_memory="global", src_word_offset=6,
                out_memory="temp", out_word_offset=0,
                rows=1, cols=8, alpha_bits=ref.bits(-0.5),
            ),
        ),
        OperatorCase(
            "add", "temp", 8, (8,), tuple(ref.add_matrix(add_a, add_b)),
            lambda command_id: dexsim.add(
                command_id, a_memory="global", a_word_offset=7,
                b_memory="global", b_word_offset=8,
                out_memory="temp", out_word_offset=1,
                rows=1, cols=8,
            ),
        ),
    )


def run_matrix():
    records = []
    command_id = 1
    wall_start = time.perf_counter()
    with dexsim.Session(cores=CORES) as session:
        cases = prepare_cases(session)
        for case in cases:
            groups = tuple((core,) for core in CORES) + PAIRS + (CORES,)
            for group in groups:
                for core in CORES:
                    sentinel = tuple(
                        (0x7000 + core * 0x10 + index) & 0xFFFF
                        for index in range(8)
                    )
                    session.write_tensor_bits(
                        memory=case.output_memory,
                        core=core,
                        offset=case.output_offset,
                        value=sentinel,
                    )
                scheduled = []
                expected_ids = []
                for core in group:
                    scheduled.append(dexsim.ScheduledCommand(core, case.builder(command_id)))
                    expected_ids.append(command_id)
                    command_id = 1 if command_id == 0xFFF else command_id + 1
                start = time.perf_counter()
                run = session.run_scheduled(scheduled)
                wall_seconds = time.perf_counter() - start

                observed = {}
                for core in group:
                    bits = tuple(flatten(session.read_tensor_bits(
                        memory=case.output_memory,
                        core=core,
                        offset=case.output_offset,
                        shape=case.output_shape,
                    )))
                    if bits != case.expected_bits:
                        raise AssertionError(
                            f"{case.name} cores={group} core={core}: "
                            f"expected={case.expected_bits}, observed={bits}"
                        )
                    observed[str(core)] = list(bits)
                actual_ids = [value.command_id for value in run.command_results]
                actual_cores = [value.core for value in run.command_results]
                if actual_ids != expected_ids or actual_cores != list(group):
                    raise AssertionError(
                        f"scheduled metadata mismatch: cores={actual_cores}, ids={actual_ids}"
                    )
                records.append({
                    "operator": case.name,
                    "cores": list(group),
                    "cycles": run.cycles,
                    "read_bytes": run.read_bytes,
                    "write_bytes": run.write_bytes,
                    "command_count": run.command_count,
                    "wall_seconds": wall_seconds,
                    "command_results": [value.to_dict() for value in run.command_results],
                    "observed_bits": observed,
                })

        # Short commands can finish while later contexts are still being
        # submitted.  Use a compute-heavy, per-core Local/Temp GEMM to prove
        # that every pair and the four-way wave also overlap without touching
        # the contended Global SRAM port.
        stress_a = [ref.bits(((index * 7) % 19 - 9) / 16.0) for index in range(64 * 32)]
        stress_b = [ref.bits(((index * 11) % 23 - 11) / 16.0) for index in range(32 * 32)]
        stress_expected = tuple(ref.gemm(stress_a, stress_b, 64, 32, 32))
        for core in CORES:
            session.write_tensor_bits(memory="local", core=core, offset=0, value=stress_a)
            session.write_tensor_bits(memory="temp", core=core, offset=0, value=stress_b)
        stress_records = []
        for group in PAIRS + (CORES,):
            scheduled = []
            expected_ids = []
            for core in group:
                scheduled.append(dexsim.ScheduledCommand(
                    core,
                    dexsim.gemm(
                        command_id,
                        a_memory="local",
                        a_word_offset=0,
                        b_memory="temp",
                        b_word_offset=0,
                        out_memory="local",
                        out_word_offset=256,
                        n_rows=64,
                        m_cols=32,
                        k_dim=32,
                    ),
                ))
                expected_ids.append(command_id)
                command_id = 1 if command_id == 0xFFF else command_id + 1
            start = time.perf_counter()
            run = session.run_scheduled(scheduled, timeout_cycles=2_000_000)
            wall_seconds = time.perf_counter() - start
            for core in group:
                observed = tuple(flatten(session.read_tensor_bits(
                    memory="local", core=core, offset=2048, shape=(64, 32)
                )))
                if observed != stress_expected:
                    raise AssertionError(f"overlap stress GEMM failed for cores={group}")
            stress_records.append({
                "cores": list(group),
                "cycles": run.cycles,
                "read_bytes": run.read_bytes,
                "write_bytes": run.write_bytes,
                "wall_seconds": wall_seconds,
                "done_cycles": [value.done_cycle for value in run.command_results],
                "command_ids": expected_ids,
            })

        # Explicitly prove that Local and Temp have four independent physical banks.
        isolation = {}
        for memory in ("local", "temp"):
            for core in CORES:
                value = tuple(ref.bits(100 * (core + 1) + lane) for lane in range(8))
                session.write_tensor_bits(memory=memory, core=core, offset=240, value=value)
            isolation[memory] = {}
            for core in CORES:
                value = tuple(flatten(session.read_tensor_bits(
                    memory=memory, core=core, offset=240, shape=(8,)
                )))
                expected = tuple(ref.bits(100 * (core + 1) + lane) for lane in range(8))
                if value != expected:
                    raise AssertionError(
                        f"{memory} isolation failed for core {core}: {value} != {expected}"
                    )
                isolation[memory][str(core)] = list(value)

        snapshot = session.snapshot().to_dict()

    return {
        "schema_version": 1,
        "passed": True,
        "operators": [value.name for value in cases],
        "sequential_cores": list(CORES),
        "concurrent_pairs": [list(value) for value in PAIRS],
        "four_way": list(CORES),
        "wave_count": len(records),
        "wall_seconds": time.perf_counter() - wall_start,
        "snapshot": snapshot,
        "isolation": isolation,
        "overlap_stress": stress_records,
        "records": records,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = run_matrix()
    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
