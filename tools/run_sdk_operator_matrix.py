#!/usr/bin/env python3
import argparse
import io
import json
import sys
import unittest
from pathlib import Path

import dexsim


ROOT = Path(__file__).resolve().parents[1]
TEST_DIR = ROOT / "tests" / "python"


def run_operator_suite():
    sys.path.insert(0, str(TEST_DIR))
    try:
        suite = unittest.defaultTestLoader.discover(
            str(TEST_DIR), pattern="test_all_operators.py"
        )
        stream = io.StringIO()
        result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
        return result.wasSuccessful(), result.testsRun, stream.getvalue()
    finally:
        sys.path.remove(str(TEST_DIR))


def run_memory_and_persistence_matrix(iterations):
    memories = ("global", "local", "temp")
    memory_cases = []
    with dexsim.Session() as session:
        source_bits = [dexsim.fp16_bits(value) for value in (-2.0, 1.0, -0.0, 3.5)]
        expected_abs = [item & 0x7FFF for item in source_bits]
        command_id = 100
        for source_memory in memories:
            for destination_memory in memories:
                session.write_tensor_bits(memory=source_memory, offset=0, value=source_bits)
                trace = session.run([
                    dexsim.abs(
                        command_id,
                        src_memory=source_memory,
                        src_word_offset=0,
                        out_memory=destination_memory,
                        out_word_offset=4,
                        rows=1,
                        cols=len(source_bits),
                    )
                ])
                actual = session.read_tensor_bits(
                    memory=destination_memory, offset=32, shape=(len(source_bits),)
                )
                memory_cases.append({
                    "source": source_memory,
                    "destination": destination_memory,
                    "passed": actual == expected_abs,
                    "cycles": trace.cycles,
                })
                command_id += 1

        session.write_tensor(memory="global", offset=8, value=[1.0, -2.0, 3.0, -4.0])
        session.write_tensor(memory="global", offset=16, value=[1.0, 2.0, 3.0, 4.0])
        session.write_tensor(memory="local", offset=16, value=[4.0, 3.0, 2.0, 1.0])
        session.write_tensor(memory="global", offset=24, value=[1.0, 2.0, 3.0, 4.0])
        before = session.snapshot()
        cycle_sum = 0
        for index in range(iterations):
            kind = index % 4
            if kind == 0:
                command = dexsim.abs(1000 + index, src_memory="global", src_word_offset=1, out_memory="local", out_word_offset=8, rows=2, cols=2)
            elif kind == 1:
                command = dexsim.scale(1000 + index, src_memory="global", src_word_offset=1, out_memory="local", out_word_offset=9, rows=2, cols=2, alpha_bits=dexsim.fp16_bits(0.5))
            elif kind == 2:
                command = dexsim.add(1000 + index, a_memory="global", a_word_offset=2, b_memory="local", b_word_offset=2, out_memory="temp", out_word_offset=8, rows=2, cols=2)
            else:
                command = dexsim.transpose(1000 + index, src_memory="global", src_word_offset=3, out_memory="temp", out_word_offset=9, rows=2, cols=2)
            cycle_sum += session.run([command]).cycles
        after = session.snapshot()
        persistence = {
            "iterations": iterations,
            "done_delta": after.done_count - before.done_count,
            "reset_count_before": before.reset_count,
            "reset_count_after": after.reset_count,
            "cycle_sum": cycle_sum,
            "passed": (
                after.done_count - before.done_count == iterations
                and before.reset_count == 1
                and after.reset_count == 1
            ),
        }
    return memory_cases, persistence


def main():
    parser = argparse.ArgumentParser(description="Validate DexSim SDK operator coverage.")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--persistence-commands", type=int, default=256)
    args = parser.parse_args()
    if args.persistence_commands <= 0 or args.persistence_commands > 3000:
        parser.error("--persistence-commands must be in 1..3000")

    suite_passed, tests_run, suite_log = run_operator_suite()
    memory_cases, persistence = run_memory_and_persistence_matrix(
        args.persistence_commands
    )
    capabilities = dexsim.Session.capabilities()
    payload = {
        "schema_version": 1,
        "sdk_version": dexsim.__version__,
        "operator_suite": {
            "passed": suite_passed,
            "tests_run": tests_run,
            "log": suite_log,
        },
        "primitive_operators": capabilities["primitive_operators"],
        "derived_operators": capabilities["derived_operators"],
        "memory_abs_matrix": memory_cases,
        "persistence": persistence,
    }
    payload["passed"] = (
        suite_passed
        and len(payload["primitive_operators"]) == 11
        and len(payload["derived_operators"]) == 3
        and all(case["passed"] for case in memory_cases)
        and persistence["passed"]
    )
    text = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0 if payload["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
