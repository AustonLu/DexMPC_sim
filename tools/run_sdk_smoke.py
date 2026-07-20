#!/usr/bin/env python3
import argparse
import json
import math
from pathlib import Path

import dexsim


def main():
    parser = argparse.ArgumentParser(description="Run the installed DexSim M2 SDK smoke flow.")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--persistence-runs", type=int, default=100)
    args = parser.parse_args()

    result = {
        "schema_version": 1,
        "sdk_version": dexsim.__version__,
        "capabilities": dexsim.Session.capabilities(),
        "persistence_runs": args.persistence_runs,
    }

    with dexsim.Session() as session:
        roundtrip_input = [[1.0, -2.0, 3.5], [0.25, -0.5, 8.0]]
        session.write_tensor(memory="temp", offset=3, value=roundtrip_input)
        roundtrip_output = session.read_tensor(memory="temp", offset=3, shape=(2, 3))

        session.write_tensor(memory="local", offset=0, value=[1.0, 2.0, 3.0, 4.0])
        session.write_tensor(memory="local", offset=8, value=[5.0, 6.0, 7.0, 8.0])
        gemm_trace = session.run([
            dexsim.gemm(
                1,
                a_memory="local",
                a_word_offset=0,
                b_memory="local",
                b_word_offset=1,
                out_memory="local",
                out_word_offset=2,
                n_rows=2,
                m_cols=2,
                k_dim=2,
            )
        ])
        gemm_output = session.read_tensor(memory="local", offset=16, shape=(2, 2))

        softplus_input = [-4.0, -1.0, 0.0, 1.0, 4.0]
        session.write_tensor(memory="local", offset=24, value=softplus_input)
        softplus_trace = session.run([
            dexsim.softplus(
                2,
                src_memory="local",
                src_word_offset=3,
                out_memory="local",
                out_word_offset=4,
                rows=1,
                cols=len(softplus_input),
            )
        ])
        softplus_output = session.read_tensor(
            memory="local", offset=32, shape=(len(softplus_input),)
        )
        softplus_reference = [math.log1p(math.exp(value)) for value in softplus_input]
        softplus_max_abs_error = max(
            abs(actual - expected)
            for actual, expected in zip(softplus_output, softplus_reference)
        )

        session.write_tensor(memory="local", offset=40, value=[1.0, 2.0, 3.0, 4.0])
        reduce_trace = session.run([
            dexsim.add_reduce(
                3,
                src_memory="local",
                src_word_offset=5,
                element_count=4,
            )
        ])
        reduce_output = session.read_add_reduce()

        before = session.snapshot()
        persistence_cycles = []
        for index in range(args.persistence_runs):
            trace = session.run([
                dexsim.gemm(
                    100 + index,
                    a_memory="local",
                    a_word_offset=0,
                    b_memory="local",
                    b_word_offset=1,
                    out_memory="local",
                    out_word_offset=2,
                    n_rows=2,
                    m_cols=2,
                    k_dim=2,
                )
            ])
            persistence_cycles.append(trace.cycles)
        after = session.snapshot()

        result.update({
            "roundtrip": {
                "passed": roundtrip_output == roundtrip_input,
                "input": roundtrip_input,
                "output": roundtrip_output,
            },
            "gemm": {
                "passed": gemm_output == [[19.0, 22.0], [43.0, 50.0]],
                "output": gemm_output,
                "trace": gemm_trace.to_dict(),
            },
            "softplus": {
                "passed": softplus_max_abs_error <= 0.032,
                "input": softplus_input,
                "output": softplus_output,
                "reference": softplus_reference,
                "max_abs_error": softplus_max_abs_error,
                "trace": softplus_trace.to_dict(),
            },
            "add_reduce": {
                "passed": reduce_output["valid"] and reduce_output["value"] == 10.0,
                "output": reduce_output,
                "trace": reduce_trace.to_dict(),
            },
            "persistence": {
                "passed": (
                    before.reset_count == 1
                    and after.reset_count == 1
                    and after.done_count - before.done_count == args.persistence_runs
                ),
                "before": before.to_dict(),
                "after": after.to_dict(),
                "cycle_sum": sum(persistence_cycles),
                "cycle_min": min(persistence_cycles) if persistence_cycles else 0,
                "cycle_max": max(persistence_cycles) if persistence_cycles else 0,
            },
        })

    with dexsim.Session() as timeout_session:
        timeout_command = dexsim.gemm(
            399,
            a_memory="local",
            a_word_offset=0,
            b_memory="local",
            b_word_offset=32,
            out_memory="local",
            out_word_offset=64,
            n_rows=16,
            m_cols=16,
            k_dim=16,
        )
        try:
            timeout_session.run([timeout_command], timeout_cycles=1)
            timeout_error = None
        except dexsim.DexSimError as error:
            timeout_error = str(error)

    with dexsim.Session() as illegal_session:
        try:
            illegal_session.run([dexsim.make_command(400, 0, 0)])
            illegal_error = None
        except dexsim.DexSimError as error:
            illegal_error = str(error)

    result["errors"] = {
        "timeout_detected": timeout_error is not None and "timeout" in timeout_error,
        "timeout_message": timeout_error,
        "illegal_command_detected": illegal_error is not None and "illegal command" in illegal_error,
        "illegal_command_message": illegal_error,
    }
    result["passed"] = all(
        result[name]["passed"]
        for name in ("roundtrip", "gemm", "softplus", "add_reduce", "persistence")
    ) and result["errors"]["timeout_detected"] and result["errors"]["illegal_command_detected"]

    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding="utf-8")
    print(payload, end="")
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
