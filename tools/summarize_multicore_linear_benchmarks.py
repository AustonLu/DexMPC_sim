#!/usr/bin/env python3
"""Create a compact benefit table from the raw M6.1 benchmark JSON."""

from __future__ import annotations

import argparse
from collections import defaultdict
import json
from pathlib import Path


def summarize(raw):
    grouped = defaultdict(list)
    for record in raw["records"]:
        grouped[(record["operator"], tuple(record["shape"]))].append(record)

    cases = []
    operator_summary = defaultdict(lambda: {
        "case_count": 0,
        "profitable_case_count": 0,
        "best_total_speedup": 1.0,
        "best_run_speedup": 1.0,
    })
    for (operation, shape), records in grouped.items():
        records.sort(key=lambda value: value["selected_cores"])
        best = min(records, key=lambda value: value["metrics"]["total_cycles"])
        baseline = next(value for value in records if value["requested_policy"] == "single")
        maximum_run = max(records, key=lambda value: value["speedup"]["run_cycles"])
        profitable = best["selected_cores"] > 1 and best["speedup"]["total_operator_cycles"] >= 1.05
        cases.append({
            "operator": operation,
            "shape": list(shape),
            "best_core_count": best["selected_cores"],
            "profitable_at_5_percent_gate": profitable,
            "best_total_speedup": best["speedup"]["total_operator_cycles"],
            "best_run_speedup": maximum_run["speedup"]["run_cycles"],
            "best_run_core_count": maximum_run["selected_cores"],
            "best_wall_speedup": best["speedup"]["operator_wall"],
            "baseline_total_cycles": baseline["metrics"]["total_cycles"],
            "best_total_cycles": best["metrics"]["total_cycles"],
            "variants": [{
                "requested_policy": value["requested_policy"],
                "selected_cores": value["selected_cores"],
                "total_cycles": value["metrics"]["total_cycles"],
                "run_cycles": value["metrics"]["run_cycles"],
                "stage_cycles": value["metrics"]["stage_cycles"],
                "gather_cycles": value["metrics"]["gather_cycles"],
                "read_bytes": value["metrics"]["total_read_bytes"],
                "write_bytes": value["metrics"]["total_write_bytes"],
                "wall_seconds": value["metrics"]["wall_seconds"],
                "total_speedup": value["speedup"]["total_operator_cycles"],
            } for value in records],
        })
        item = operator_summary[operation]
        item["case_count"] += 1
        item["profitable_case_count"] += int(profitable)
        item["best_total_speedup"] = max(
            item["best_total_speedup"], best["speedup"]["total_operator_cycles"]
        )
        item["best_run_speedup"] = max(
            item["best_run_speedup"], maximum_run["speedup"]["run_cycles"]
        )

    return {
        "schema_version": 1,
        "source_schema_version": raw["schema_version"],
        "passed": raw["passed"],
        "benefit_gate": "best total operator cycles speedup >= 1.05",
        "operator_summary": dict(sorted(operator_summary.items())),
        "cases": sorted(cases, key=lambda value: (value["operator"], value["shape"])),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = summarize(json.loads(args.input.read_text(encoding="utf-8")))
    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
