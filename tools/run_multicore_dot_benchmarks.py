#!/usr/bin/env python3
"""Run M6.3 DOT correctness, numeric-error and cycle benchmarks."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
sys.path.insert(0, str(ROOT / "tests" / "python"))

import dexsim  # noqa: E402
from dexsim.dot_parallel import plan_dot  # noqa: E402
import reference_fp16 as ref  # noqa: E402


def values(count, salt):
    return [
        ref.bits((((index * 29 + salt * 11) % 61) - 30) / 32.0)
        for index in range(count)
    ]


def fixed_reference(left, right, policy):
    plan = plan_dot(len(left), policy=policy)
    partials = []
    for partition in plan.partitions:
        start = partition.start
        end = start + partition.size
        partials.append(ref.gemm(
            left[start:end], right[start:end], 1, 1, partition.size
        )[0])
    output = partials[0] if len(partials) == 1 else ref.add_reduce(partials)
    return plan, partials, output


def order_distance(left, right):
    return abs(ref.order_key(left) - ref.order_key(right))


def fp64_stats(left, right, output_bits):
    products = [ref.value(a) * ref.value(b) for a, b in zip(left, right)]
    mathematical = math.fsum(products)
    l1 = math.fsum(abs(value) for value in products)
    actual = ref.value(output_bits)
    if not math.isfinite(mathematical) or not math.isfinite(actual):
        return {
            "fp64": mathematical,
            "fp16": actual,
            "absolute_error": None,
            "relative_error": None,
            "normalized_l1_error": None,
            "finite": False,
            "accepted": True,
        }
    absolute = abs(actual - mathematical)
    relative = absolute / abs(mathematical) if mathematical else absolute
    normalized = absolute / l1 if l1 else absolute
    return {
        "fp64": mathematical,
        "fp16": actual,
        "absolute_error": absolute,
        "relative_error": relative,
        "normalized_l1_error": normalized,
        "finite": True,
        "accepted": normalized <= 0.02,
    }


def run_case(length, policy, salt):
    left = values(length, salt)
    right = values(length, salt + 1)
    plan, partials, expected = fixed_reference(left, right, policy)
    single_bits = ref.gemm(left, right, 1, 1, length)[0]
    wall_start = time.perf_counter()
    with dexsim.Device(
        dot_execution_policy=policy, timeout_cycles=4_000_000
    ) as device:
        before_upload = device.session._counters()
        a = device.tensor_bits(left, shape=(length,))
        b = device.tensor_bits(right, shape=(length,))
        after_upload = device.session._counters()
        output = device.dot(a, b)
        before_download = device.session._counters()
        actual = output.bits()[0]
        after_download = device.session._counters()
        trace = device.trace()[-1]["parallel"]
    metrics = dict(trace["metrics"])
    upload_cycles = after_upload.cycle - before_upload.cycle
    download_cycles = after_download.cycle - before_download.cycle
    return {
        "length": length,
        "requested_policy": policy,
        "plan": trace["plan"],
        "expected_plan": plan.to_dict(),
        "partial_bits": trace["partial_bits"],
        "expected_partial_bits": partials if plan.core_count > 1 else [],
        "output_bits": actual,
        "expected_bits": expected,
        "single_core_bits": single_bits,
        "fixed_reference_exact": actual == expected,
        "partial_reference_exact": trace["partial_bits"] == (
            partials if plan.core_count > 1 else []
        ),
        "ulp_from_single": order_distance(actual, single_bits),
        "fp64_error": fp64_stats(left, right, actual),
        "metrics": metrics,
        "input_upload_cycles": upload_cycles,
        "output_download_cycles": download_cycles,
        "end_to_end_cycles": upload_cycles + metrics["total_cycles"] + download_cycles,
        "host_ops": trace["host_ops"],
        "wall_seconds": time.perf_counter() - wall_start,
    }


def run_special_case(name, left, right, policy="quad"):
    plan, partials, expected = fixed_reference(left, right, policy)
    with dexsim.Device(dot_execution_policy=policy) as device:
        a = device.tensor_bits(left, shape=(len(left),))
        b = device.tensor_bits(right, shape=(len(right),))
        output = device.dot(a, b)
        actual = output.bits()[0]
        trace = device.trace()[-1]["parallel"]
    return {
        "name": name,
        "length": len(left),
        "plan": plan.to_dict(),
        "expected_partial_bits": partials,
        "actual_partial_bits": trace["partial_bits"],
        "expected_bits": expected,
        "actual_bits": actual,
        "exact": actual == expected and trace["partial_bits"] == partials,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()

    lengths = [8, 16, 31, 64, 127, 256, 511, 1024, 2048, 4095]
    if args.quick:
        lengths = [16, 31, 127]
    policies = ("single", "dual", "quad", "auto")
    records = []
    started = time.perf_counter()
    for index, length in enumerate(lengths):
        for policy in policies:
            record = run_case(length, policy, 20 + index)
            records.append(record)
            print(json.dumps({
                "length": length,
                "policy": policy,
                "cores": record["plan"]["core_count"],
                "exact": record["fixed_reference_exact"],
                "total_cycles": record["metrics"]["total_cycles"],
                "engine_cycles": record["metrics"]["engine_compute_cycles"],
            }, sort_keys=True), flush=True)

    one = ref.bits(1.0)
    special_inputs = {
        "odd_tail": (values(31, 71), values(31, 72)),
        "positive_inf": ([0x7C00] + [one] * 30, [one] * 31),
        "nan": ([0x7E00] + [one] * 30, [one] * 31),
        "mixed_inf": ([0x7C00, 0xFC00] + [one] * 29, [one] * 31),
        "signed_zero": ([0x8000] * 31, [one] * 31),
        "subnormal_ftz": ([0x0001] * 31, [one] * 31),
    }
    special_records = [
        run_special_case(name, *values_pair)
        for name, values_pair in special_inputs.items()
    ]
    payload = {
        "schema_version": 1,
        "dexsim_version": dexsim.__version__,
        "acceptance": {
            "fixed_tree_ulp": 0,
            "finite_normalized_l1_error_max": 0.02,
            "production_host_merge_allowed": False,
        },
        "length_count": len(lengths),
        "record_count": len(records),
        "all_fixed_reference_exact": all(
            item["fixed_reference_exact"] and item["partial_reference_exact"]
            for item in records
        ),
        "all_finite_error_accepted": all(
            item["fp64_error"]["accepted"] for item in records
        ),
        "all_special_exact": all(item["exact"] for item in special_records),
        "records": records,
        "special_records": special_records,
        "wall_seconds": time.perf_counter() - started,
    }
    Path(args.output).write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
