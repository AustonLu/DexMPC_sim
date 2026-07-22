#!/usr/bin/env python3
"""Compare deterministic hardware and host merge trees for DOT partials."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
sys.path.insert(0, str(ROOT / "tests" / "python"))

import dexsim  # noqa: E402
import reference_fp16 as ref  # noqa: E402


def host_tree(values):
    current = list(values)
    levels = []
    while len(current) > 1:
        next_values = []
        pairs = []
        for index in range(0, len(current), 2):
            value = ref.add_bits(current[index], current[index + 1])
            next_values.append(value)
            pairs.append([index, index + 1, value])
        levels.append(pairs)
        current = next_values
    return current[0], levels


def run_hardware_reduce(session, partials, command_id):
    base = 300
    before = session._counters()
    session.write_tensor_bits(
        memory="local", offset=base * 8, value=partials
    )
    after_stage = session._counters()
    command = dexsim.add_reduce(
        command_id,
        src_memory="local",
        src_word_offset=base,
        element_count=len(partials),
    )
    run = session.run([command])
    after = session._counters()
    result = run.command_results[0]
    return {
        "result_bits": result.reduce_value_bits,
        "expected_bits": ref.add_reduce(partials),
        "exact": result.reduce_value_bits == ref.add_reduce(partials),
        "stage_cycles": after_stage.cycle - before.cycle,
        "scheduled_run_cycles": run.total_cycles,
        "engine_cycles": result.done_cycle,
        "total_cycles": after.cycle - before.cycle,
        "host_ops": [],
    }


def run_hardware_add(session, partials, command_id):
    input_base = 320
    scratch_base = 336
    before = session._counters()
    for index, value in enumerate(partials):
        session.write_tensor_bits(
            memory="local", offset=(input_base + index) * 8, value=[value]
        )
    after_stage = session._counters()
    commands = []
    if len(partials) == 2:
        commands.append(dexsim.add(
            command_id,
            a_memory="local", a_word_offset=input_base,
            b_memory="local", b_word_offset=input_base + 1,
            out_memory="local", out_word_offset=scratch_base,
            rows=1, cols=1,
        ))
        output_word = scratch_base
    else:
        commands.extend([
            dexsim.add(
                command_id,
                a_memory="local", a_word_offset=input_base,
                b_memory="local", b_word_offset=input_base + 1,
                out_memory="local", out_word_offset=scratch_base,
                rows=1, cols=1,
            ),
            dexsim.add(
                command_id + 1,
                a_memory="local", a_word_offset=input_base + 2,
                b_memory="local", b_word_offset=input_base + 3,
                out_memory="local", out_word_offset=scratch_base + 1,
                rows=1, cols=1,
            ),
            dexsim.add(
                command_id + 2,
                a_memory="local", a_word_offset=scratch_base,
                b_memory="local", b_word_offset=scratch_base + 1,
                out_memory="local", out_word_offset=scratch_base + 2,
                rows=1, cols=1,
            ),
        ])
        output_word = scratch_base + 2
    run = session.run(commands)
    after_run = session._counters()
    actual = session.read_tensor_bits(
        memory="local", offset=output_word * 8, shape=(1,)
    )[0]
    after = session._counters()
    expected, levels = host_tree(partials)
    return {
        "result_bits": actual,
        "expected_bits": expected,
        "exact": actual == expected,
        "stage_cycles": after_stage.cycle - before.cycle,
        "scheduled_run_cycles": run.total_cycles,
        "engine_cycles": sum(value.done_cycle for value in run.command_results),
        "result_read_cycles": after.cycle - after_run.cycle,
        "total_cycles": after.cycle - before.cycle,
        "tree": levels,
        "host_ops": [],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    patterns = {
        "finite_two": [ref.bits(1.25), ref.bits(-0.375)],
        "finite_four": [
            ref.bits(1.25), ref.bits(-0.375), ref.bits(0.5), ref.bits(2.0)
        ],
        "signed_zero_four": [0x8000, 0x0000, 0x8000, 0x0000],
        "inf_four": [0x7C00, ref.bits(1.0), ref.bits(-2.0), ref.bits(0.5)],
        "nan_four": [0x7E00, ref.bits(1.0), ref.bits(-2.0), ref.bits(0.5)],
    }
    records = []
    with dexsim.Session(cores=(0, 1, 2, 3), timeout_cycles=2_000_000) as session:
        command_id = 0x500
        for name, partials in patterns.items():
            host_result, host_levels = host_tree(partials)
            reduce_record = run_hardware_reduce(session, partials, command_id)
            command_id += 4
            add_record = run_hardware_add(session, partials, command_id)
            command_id += 4
            records.append({
                "name": name,
                "partial_bits": partials,
                "host_fixed_tree": {
                    "result_bits": host_result,
                    "tree": host_levels,
                    "host_ops": [{
                        "operation": "debug_fp16_fixed_tree_merge",
                        "input_count": len(partials),
                    }],
                },
                "hardware_add_tree": add_record,
                "hardware_add_reduce": reduce_record,
            })

    payload = {
        "schema_version": 1,
        "dexsim_version": dexsim.__version__,
        "selected_production_merge": "hardware_add_reduce",
        "selection_reason": (
            "one deterministic hardware command; fixed input order; no host arithmetic"
        ),
        "all_hardware_exact": all(
            item["hardware_add_tree"]["exact"]
            and item["hardware_add_reduce"]["exact"]
            for item in records
        ),
        "records": records,
    }
    Path(args.output).write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
