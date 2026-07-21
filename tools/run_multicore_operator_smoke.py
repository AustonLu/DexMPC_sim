#!/usr/bin/env python3
"""Run 100 mixed multicore operators in one persistent Session."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))

import dexsim  # noqa: E402


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


def values(count, salt):
    return [(((index * 13 + salt * 5) % 23) - 11) / 16.0 for index in range(count)]


def matrix(rows, cols, salt):
    data = values(rows * cols, salt)
    return [data[row * cols : (row + 1) * cols] for row in range(rows)]


def run_smoke(rounds=20):
    started = time.perf_counter()
    with dexsim.Device(execution_policy="quad", timeout_cycles=2_000_000) as device:
        a = device.constant(matrix(32, 8, 1))
        b = device.constant(matrix(8, 8, 2))
        x = device.constant(values(8, 3))
        u = device.constant(values(32, 4))
        v = device.constant(values(8, 5))
        p = device.constant(values(64, 6))
        q = device.constant(values(64, 7))
        reset_before = device.session.snapshot().reset_count
        expected = None
        operation_count = 0
        selected_core_counts = []
        for _ in range(rounds):
            outputs = (
                device.gemm(a, b),
                device.gemv(a, x),
                device.outer(u, v),
                device.scale(p, -0.375),
                device.add(p, q),
            )
            bits = tuple(tuple(flatten(output.bits())) for output in outputs)
            if expected is None:
                expected = bits
            elif bits != expected:
                raise AssertionError("persistent multicore output changed between rounds")
            selected_core_counts.extend(
                entry["parallel"]["plan"]["core_count"]
                for entry in device.trace()[-5:]
            )
            operation_count += len(outputs)
            for output in outputs:
                output.release()
        reset_after = device.session.snapshot().reset_count
        if reset_before != reset_after:
            raise AssertionError("persistent Session was reset during multicore smoke")
        if any(value != 4 for value in selected_core_counts):
            raise AssertionError("diagnostic quad policy did not use four cores")
        return {
            "schema_version": 1,
            "passed": True,
            "rounds": rounds,
            "operation_count": operation_count,
            "selected_core_counts": sorted(set(selected_core_counts)),
            "reset_before": reset_before,
            "reset_after": reset_after,
            "trace_entries": len(device.trace()),
            "wall_seconds": time.perf_counter() - started,
        }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rounds", type=int, default=20)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = run_smoke(args.rounds)
    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
