#!/usr/bin/env python3
"""Summarize M6.2 resident-kernel benchmark JSON."""

from __future__ import annotations

import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import statistics


def key(record):
    return tuple(record["shape"]), int(record["depth"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    payload = json.loads(Path(args.input).read_text())
    records = payload["records"]
    baseline = {
        key(record): record
        for record in records
        if record["execution_policy"] == "single"
        and record["residency_policy"] == "off"
    }
    per_op = {
        (key(record), record["execution_policy"]): record
        for record in records
        if record["residency_policy"] == "off"
    }
    rows = []
    groups = defaultdict(list)
    for record in records:
        case = key(record)
        base = baseline[case]
        warm = record["warm"]["kernel_metrics"]
        cold = record["cold"]["kernel_metrics"]
        base_warm = base["warm"]["kernel_metrics"]
        base_cold = base["cold"]["kernel_metrics"]
        total_speedup = base_warm["total_cycles"] / warm["total_cycles"]
        compute_speedup = (
            base_warm["compute_only_cycles"] / warm["compute_only_cycles"]
        )
        base_on_chip_cycles = (
            base_warm["operator_region_cycles"]
            + base_warm["output_materialize_cycles"]
        )
        on_chip_cycles = (
            warm["operator_region_cycles"] + warm["output_materialize_cycles"]
        )
        on_chip_speedup = base_on_chip_cycles / on_chip_cycles
        cold_total_speedup = base_cold["total_cycles"] / cold["total_cycles"]
        same_core = per_op.get((case, record["execution_policy"]))
        residency_speedup = None
        if same_core is not None and record["residency_policy"] == "on":
            residency_speedup = (
                same_core["warm"]["kernel_metrics"]["total_cycles"]
                / warm["total_cycles"]
            )
        row = {
            "shape": list(case[0]),
            "depth": case[1],
            "execution_policy": record["execution_policy"],
            "residency_policy": record["residency_policy"],
            "warm_total_cycles": warm["total_cycles"],
            "warm_compute_cycles": warm["compute_only_cycles"],
            "warm_internal_transfer_cycles": warm["internal_transfer_cycles"],
            "warm_on_chip_cycles": on_chip_cycles,
            "warm_input_upload_cycles": warm["input_upload_cycles"],
            "warm_output_materialize_cycles": warm["output_materialize_cycles"],
            "warm_output_download_cycles": warm["output_download_cycles"],
            "cold_total_cycles": cold["total_cycles"],
            "cold_compute_cycles": cold["compute_only_cycles"],
            "avoided_stage_bytes": record["warm"]["residency"]["metrics"][
                "avoided_stage_bytes"
            ],
            "deferred_gather_bytes": record["warm"]["residency"]["metrics"][
                "deferred_gather_bytes"
            ],
            "total_speedup_vs_single": total_speedup,
            "compute_speedup_vs_single": compute_speedup,
            "on_chip_speedup_vs_single": on_chip_speedup,
            "cold_total_speedup_vs_single": cold_total_speedup,
            "residency_speedup_vs_same_core_off": residency_speedup,
            "profitable_end_to_end_1_05": total_speedup >= 1.05,
            "cold_profitable_end_to_end_1_05": cold_total_speedup >= 1.05,
            "profitable_compute_1_05": compute_speedup >= 1.05,
            "profitable_on_chip_1_05": on_chip_speedup >= 1.05,
            "residency_improved_same_core": (
                residency_speedup is not None and residency_speedup > 1.0
            ),
            "correct": record["correct"],
        }
        rows.append(row)
        groups[(record["execution_policy"], record["residency_policy"])].append(row)

    group_summary = {}
    for group, values in sorted(groups.items()):
        name = "/".join(group)
        total_speedups = [value["total_speedup_vs_single"] for value in values]
        cold_total_speedups = [
            value["cold_total_speedup_vs_single"] for value in values
        ]
        compute_speedups = [value["compute_speedup_vs_single"] for value in values]
        on_chip_speedups = [value["on_chip_speedup_vs_single"] for value in values]
        residency_speedups = [
            value["residency_speedup_vs_same_core_off"] for value in values
            if value["residency_speedup_vs_same_core_off"] is not None
        ]
        group_summary[name] = {
            "case_count": len(values),
            "end_to_end_profitable_cases": sum(
                value["profitable_end_to_end_1_05"] for value in values
            ),
            "cold_end_to_end_profitable_cases": sum(
                value["cold_profitable_end_to_end_1_05"] for value in values
            ),
            "compute_profitable_cases": sum(
                value["profitable_compute_1_05"] for value in values
            ),
            "on_chip_profitable_cases": sum(
                value["profitable_on_chip_1_05"] for value in values
            ),
            "residency_improved_same_core_cases": sum(
                value["residency_improved_same_core"] for value in values
            ),
            "min_end_to_end_speedup": min(total_speedups),
            "median_end_to_end_speedup": statistics.median(total_speedups),
            "geomean_end_to_end_speedup": math.exp(
                statistics.fmean(math.log(value) for value in total_speedups)
            ),
            "max_end_to_end_speedup": max(total_speedups),
            "min_cold_end_to_end_speedup": min(cold_total_speedups),
            "median_cold_end_to_end_speedup": statistics.median(
                cold_total_speedups
            ),
            "geomean_cold_end_to_end_speedup": math.exp(
                statistics.fmean(
                    math.log(value) for value in cold_total_speedups
                )
            ),
            "max_cold_end_to_end_speedup": max(cold_total_speedups),
            "min_compute_speedup": min(compute_speedups),
            "median_compute_speedup": statistics.median(compute_speedups),
            "geomean_compute_speedup": math.exp(
                statistics.fmean(math.log(value) for value in compute_speedups)
            ),
            "max_compute_speedup": max(compute_speedups),
            "min_on_chip_speedup": min(on_chip_speedups),
            "median_on_chip_speedup": statistics.median(on_chip_speedups),
            "geomean_on_chip_speedup": math.exp(
                statistics.fmean(math.log(value) for value in on_chip_speedups)
            ),
            "max_on_chip_speedup": max(on_chip_speedups),
            "min_residency_speedup_vs_same_core_off": (
                min(residency_speedups) if residency_speedups else None
            ),
            "median_residency_speedup_vs_same_core_off": (
                statistics.median(residency_speedups) if residency_speedups else None
            ),
            "geomean_residency_speedup_vs_same_core_off": (
                math.exp(statistics.fmean(
                    math.log(value) for value in residency_speedups
                )) if residency_speedups else None
            ),
            "max_residency_speedup_vs_same_core_off": (
                max(residency_speedups) if residency_speedups else None
            ),
        }

    summary = {
        "schema_version": 1,
        "source": str(args.input),
        "all_correct": payload["all_correct"],
        "case_count": payload["case_count"],
        "record_count": payload["record_count"],
        "groups": group_summary,
        "rows": rows,
    }
    Path(args.output).write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(group_summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
