#!/usr/bin/env python3
"""Benchmark M6.2 resident Programs against single and per-op baselines."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import time

import dexsim


def values(count, salt):
    return [(((index * 19 + salt * 11) % 37) - 18) / 32.0 for index in range(count)]


def matrix(rows, cols, salt):
    flat = values(rows * cols, salt)
    return [flat[row * cols:(row + 1) * cols] for row in range(rows)]


def flatten(value):
    if not isinstance(value, (list, tuple)):
        return [value]
    result = []
    for child in value:
        result.extend(flatten(child))
    return result


def build_chain(rows, inner, cols, depth):
    program = dexsim.Program(f"resident_{rows}_{inner}_{cols}_{depth}")
    source = program.input("source", (rows, inner))
    weight = program.constant("weight", matrix(inner, cols, 2))
    bias = program.constant("bias", matrix(rows, cols, 3))
    value = program.gemm(source, weight)
    for index in range(1, depth):
        if index % 2:
            value = program.scale(value, 0.875)
        else:
            value = program.add(value, bias)
    program.output(value)
    return program, value


def digest(bits):
    data = bytearray()
    for value in flatten(bits):
        data.extend(int(value).to_bytes(2, "little"))
    return hashlib.sha256(data).hexdigest()


def run_once(compiled, source):
    start = time.perf_counter()
    result = compiled.run(source=source)
    wall = time.perf_counter() - start
    output_name = next(iter(result.output_bits))
    return {
        "output_sha256": digest(result.output_bits[output_name]),
        "kernel_metrics": dict(result.trace.kernel_metrics),
        "residency": dict(result.trace.residency),
        "command_count": len(result.trace.commands),
        "selected_cores": sorted({entry["core"] for entry in result.trace.commands}),
        "wall_seconds": wall,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()

    shapes = [
        (16, 8, 8),
        (32, 8, 8),
        (64, 16, 16),
        (64, 32, 32),
    ]
    depths = (2, 4, 8, 16)
    if args.quick:
        shapes = shapes[:2]
        depths = (2, 4)
    policies = [
        ("single", "off"),
        ("dual", "off"),
        ("dual", "on"),
        ("quad", "off"),
        ("quad", "on"),
    ]
    records = []
    started = time.perf_counter()
    for case_index, (rows, inner, cols) in enumerate(shapes):
        source = matrix(rows, inner, 10 + case_index)
        for depth in depths:
            program, _ = build_chain(rows, inner, cols, depth)
            expected = None
            for execution_policy, residency_policy in policies:
                with program.compile(
                    execution_policy=execution_policy,
                    residency_policy=residency_policy,
                    timeout_cycles=4_000_000,
                ) as compiled:
                    cold = run_once(compiled, source)
                    warm = run_once(compiled, source)
                if expected is None:
                    expected = warm["output_sha256"]
                record = {
                    "shape": [rows, inner, cols],
                    "depth": depth,
                    "execution_policy": execution_policy,
                    "residency_policy": residency_policy,
                    "correct": cold["output_sha256"] == expected
                    and warm["output_sha256"] == expected,
                    "cold": cold,
                    "warm": warm,
                }
                records.append(record)
                print(json.dumps({
                    "shape": record["shape"],
                    "depth": depth,
                    "execution_policy": execution_policy,
                    "residency_policy": residency_policy,
                    "correct": record["correct"],
                    "cold_cycles": cold["kernel_metrics"]["total_cycles"],
                    "warm_cycles": warm["kernel_metrics"]["total_cycles"],
                }, sort_keys=True), flush=True)

    payload = {
        "schema_version": 1,
        "dexsim_version": dexsim.__version__,
        "case_count": len(shapes) * len(depths),
        "record_count": len(records),
        "all_correct": all(record["correct"] for record in records),
        "records": records,
        "wall_seconds": time.perf_counter() - started,
    }
    Path(args.output).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    main()
