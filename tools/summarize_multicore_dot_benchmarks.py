#!/usr/bin/env python3
"""Summarize M6.3 DOT benchmark speedups and production gates."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    source = json.loads(Path(args.input).read_text(encoding="utf-8"))

    by_length = {}
    for record in source["records"]:
        by_length.setdefault(record["length"], {})[
            record["requested_policy"]
        ] = record

    rows = []
    for length, policies in sorted(by_length.items()):
        baseline = policies["single"]
        for policy, record in sorted(policies.items()):
            rows.append({
                "length": length,
                "policy": policy,
                "selected_cores": record["plan"]["core_count"],
                "engine_speedup": (
                    baseline["metrics"]["engine_compute_cycles"]
                    / record["metrics"]["engine_compute_cycles"]
                ),
                "scheduled_run_speedup": (
                    baseline["metrics"]["scheduled_run_cycles"]
                    / record["metrics"]["scheduled_run_cycles"]
                ),
                "operator_speedup": (
                    baseline["metrics"]["total_cycles"]
                    / record["metrics"]["total_cycles"]
                ),
                "end_to_end_speedup": (
                    baseline["end_to_end_cycles"] / record["end_to_end_cycles"]
                ),
                "ulp_from_single": record["ulp_from_single"],
                "fixed_reference_exact": record["fixed_reference_exact"],
            })

    groups = {}
    for policy in ("dual", "quad", "auto"):
        values = [row for row in rows if row["policy"] == policy]
        groups[policy] = {
            "case_count": len(values),
            "engine_profitable_cases": sum(
                row["engine_speedup"] >= 1.05 for row in values
            ),
            "operator_profitable_cases": sum(
                row["operator_speedup"] >= 1.05 for row in values
            ),
            "end_to_end_profitable_cases": sum(
                row["end_to_end_speedup"] >= 1.05 for row in values
            ),
            "max_engine_speedup": max(row["engine_speedup"] for row in values),
            "max_operator_speedup": max(row["operator_speedup"] for row in values),
            "max_end_to_end_speedup": max(
                row["end_to_end_speedup"] for row in values
            ),
        }

    payload = {
        "schema_version": 1,
        "all_correct": source["all_fixed_reference_exact"]
        and source["all_special_exact"],
        "all_finite_error_accepted": source["all_finite_error_accepted"],
        "production_auto_policy": "single",
        "production_reason": (
            "multicore DOT remains diagnostic unless complete operator cycles pass 1.05x"
        ),
        "groups": groups,
        "rows": rows,
        "source": str(args.input),
    }
    Path(args.output).write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
