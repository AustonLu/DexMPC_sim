#!/usr/bin/env python3
"""Measure complete high-level 1/2/4-core linear operator execution."""

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
    return [(((index * 17 + salt * 7) % 29) - 14) / 16.0 for index in range(count)]


def matrix(rows, cols, salt):
    data = values(rows * cols, salt)
    return [data[row * cols : (row + 1) * cols] for row in range(rows)]


CASES = (
    ("gemm", (8, 8, 8)),
    ("gemm", (16, 16, 16)),
    ("gemm", (32, 16, 32)),
    ("gemm", (64, 32, 32)),
    ("gemv", (8, 8)),
    ("gemv", (32, 16)),
    ("gemv", (128, 32)),
    ("gemv", (256, 32)),
    ("outer", (8, 8)),
    ("outer", (32, 16)),
    ("outer", (64, 32)),
    ("outer", (128, 32)),
    ("scale", (64,)),
    ("scale", (512,)),
    ("scale", (2048,)),
    ("scale", (4096,)),
    ("add", (64,)),
    ("add", (512,)),
    ("add", (2048,)),
    ("add", (4096,)),
)


def run_case(operation, shape, policy):
    wall_start = time.perf_counter()
    with dexsim.Device(execution_policy=policy, timeout_cycles=2_000_000) as device:
        upload_before = device.session._counters()
        if operation == "gemm":
            n_rows, m_cols, k_dim = shape
            left = device.tensor(matrix(n_rows, k_dim, 1))
            right = device.tensor(matrix(k_dim, m_cols, 2))
            upload_after = device.session._counters()
            output = device.gemm(left, right)
        elif operation == "gemv":
            n_rows, k_dim = shape
            left = device.tensor(matrix(n_rows, k_dim, 3))
            right = device.tensor(values(k_dim, 4))
            upload_after = device.session._counters()
            output = device.gemv(left, right)
        elif operation == "outer":
            n_rows, m_cols = shape
            left = device.tensor(values(n_rows, 5))
            right = device.tensor(values(m_cols, 6))
            upload_after = device.session._counters()
            output = device.outer(left, right)
        elif operation == "scale":
            source = device.tensor(values(shape[0], 7))
            upload_after = device.session._counters()
            output = device.scale(source, -0.375)
        elif operation == "add":
            left = device.tensor(values(shape[0], 8))
            right = device.tensor(values(shape[0], 9))
            upload_after = device.session._counters()
            output = device.add(left, right)
        else:
            raise AssertionError(operation)

        output_read_before = device.session._counters()
        output_bits = flatten(output.bits())
        output_read_after = device.session._counters()
        trace = device.trace()[-1]
        parallel = trace["parallel"]
        return {
            "operator": operation,
            "shape": list(shape),
            "requested_policy": policy,
            "selected_cores": parallel["plan"]["core_count"],
            "plan": parallel["plan"],
            "metrics": parallel["metrics"],
            "command_count": len(parallel["commands"]),
            "command_engine_cycles": [
                value["done_cycle"] for value in parallel["run"]["command_results"]
            ],
            "input_upload": {
                "cycles": int(upload_after.cycle - upload_before.cycle),
                "read_bytes": int(upload_after.read_bytes - upload_before.read_bytes),
                "write_bytes": int(upload_after.write_bytes - upload_before.write_bytes),
            },
            "logical_output_read": {
                "cycles": int(output_read_after.cycle - output_read_before.cycle),
                "read_bytes": int(output_read_after.read_bytes - output_read_before.read_bytes),
                "write_bytes": int(output_read_after.write_bytes - output_read_before.write_bytes),
            },
            "output_bits": output_bits,
            "total_wall_seconds": time.perf_counter() - wall_start,
        }


def _result(records, started, *, passed):
    return {
        "schema_version": 1,
        "passed": passed,
        "placement": "inputs prefer Global; logical outputs prefer Local then Temp",
        "policies": ["single", "dual", "quad"],
        "case_count": len(CASES),
        "record_count": len(records),
        "wall_seconds": time.perf_counter() - started,
        "records": records,
    }


def run_benchmarks(checkpoint_path=None, start_index=0):
    records = []
    total_start = time.perf_counter()
    for operation, shape in CASES[start_index:]:
        baseline_bits = None
        baseline_metrics = None
        for policy in ("single", "dual", "quad"):
            record = run_case(operation, shape, policy)
            if baseline_bits is None:
                baseline_bits = record["output_bits"]
                baseline_metrics = record["metrics"]
            elif record["output_bits"] != baseline_bits:
                raise AssertionError(
                    f"{operation} shape={shape} policy={policy} is not bit-exact"
                )
            record["speedup"] = {
                "run_cycles": baseline_metrics["run_cycles"] / record["metrics"]["run_cycles"],
                "total_operator_cycles": baseline_metrics["total_cycles"] / record["metrics"]["total_cycles"],
                "operator_wall": baseline_metrics["wall_seconds"] / record["metrics"]["wall_seconds"],
            }
            del record["output_bits"]
            records.append(record)
            print(
                f"completed {operation} shape={shape} policy={policy} "
                f"selected={record['selected_cores']} "
                f"total_speedup={record['speedup']['total_operator_cycles']:.4f}",
                flush=True,
            )
            if checkpoint_path is not None:
                checkpoint_path.write_text(
                    json.dumps(
                        _result(records, total_start, passed=False),
                        indent=2,
                        sort_keys=True,
                    ) + "\n",
                    encoding="utf-8",
                )
    return _result(records, total_start, passed=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    parser.add_argument("--start-index", type=int, default=0)
    args = parser.parse_args()
    result = run_benchmarks(args.output, args.start_index)
    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(json.dumps({
        "passed": result["passed"],
        "case_count": result["case_count"],
        "record_count": result["record_count"],
        "wall_seconds": result["wall_seconds"],
    }, indent=2))


if __name__ == "__main__":
    main()
