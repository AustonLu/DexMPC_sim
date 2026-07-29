"""Validate the M8.1 transfer-free engine-cycle counters on real DexSim."""

import json

import dexsim


def main():
    program = dexsim.Program("m81_cycle_counter_smoke")
    source = program.input("source", (1, 8))
    weight = program.constant("weight", [
        [1.0 if row == column else 0.0 for column in range(8)]
        for row in range(8)
    ])
    value = program.gemm(source, weight)
    value = program.sin(value)
    program.output(value)

    with program.compile(
        execution_policy="single",
        residency_policy="on",
        dot_execution_policy="single",
    ) as compiled:
        result = compiled.run(source=[[0.0, 0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7]])

    metrics = dict(result.trace.kernel_metrics)
    assert metrics["engine_compute_cycles"] > 0
    assert metrics["linear_engine_compute_cycles"] > 0
    assert metrics["shared_engine_compute_cycles"] > 0
    assert metrics["engine_compute_cycles"] == (
        metrics["linear_engine_compute_cycles"]
        + metrics["shared_engine_compute_cycles"]
    )
    assert metrics["data_layout_engine_compute_cycles"] == 0
    assert metrics["arithmetic_engine_compute_cycles"] == metrics[
        "engine_compute_cycles"
    ]
    assert metrics["total_cycles"] >= metrics["engine_compute_cycles"]
    print(json.dumps({
        "dexsim_version": dexsim.__version__,
        "metrics": metrics,
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
