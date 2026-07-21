#!/usr/bin/env python3
"""Installed-package smoke for dexmpc-sim v0.3 high-level APIs."""

import argparse
import inspect
import json
from pathlib import Path

import dexsim


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=100)
    args = parser.parse_args()
    if args.iterations <= 0:
        parser.error("--iterations must be positive")

    forbidden = {
        "memory", "mem_id", "word_offset", "command_id", "opcode", "subop",
        "group_end", "core", "context", "src_memory", "out_memory",
    }
    signatures = {}
    no_hardware_arguments = True
    for name in (
        "tensor", "constant", "abs", "scale", "add", "gemm", "gemv", "dot",
        "outer", "sin", "cos", "softplus", "transpose", "assemble",
        "add_reduce", "compare_reduce",
    ):
        signature = inspect.signature(getattr(dexsim.Device, name))
        signatures[name] = str(signature)
        no_hardware_arguments &= not bool(set(signature.parameters) & forbidden)

    with dexsim.Device() as device:
        left = device.constant([[1.0, 0.0], [0.0, 1.0]])
        right = device.constant([[2.0, 3.0], [4.0, 5.0]])
        reset_before = device.session.snapshot().reset_count
        last = None
        for _ in range(args.iterations):
            product = device.gemm(left, right)
            shifted = device.add(product, right)
            last = device.scale(shifted, 0.5)
            if last.tolist() != [[2.0, 3.0], [4.0, 5.0]]:
                raise RuntimeError("eager high-level result mismatch")
            product.release()
            shifted.release()
            if _ + 1 != args.iterations:
                last.release()
        reset_after = device.session.snapshot().reset_count
        eager = {
            "iterations": args.iterations,
            "last": last.tolist(),
            "trace_entries": len(device.trace()),
            "reset_count_before": reset_before,
            "reset_count_after": reset_after,
            "allocator": device.allocator_snapshot(),
        }

    program = dexsim.Program("v03_smoke")
    x = program.input("x", (2,))
    matrix = program.constant("matrix", [[1.0, 2.0], [3.0, 4.0]])
    bias = program.constant("bias", [0.5, -0.5])
    output = program.scale(program.add(program.gemv(matrix, x), bias), 0.5)
    reduced = program.add_reduce(output)
    program.output(output, reduced)
    with program.compile() as compiled:
        first = compiled.run(x=[1.0, 2.0])
        second = compiled.run(x=[1.0, 2.0])
        output_name, scalar_name = program.to_dict()["outputs"]
        program_summary = {
            "command_count": compiled.command_count,
            "address_plan": compiled.address_plan,
            "first_output": first.outputs[output_name],
            "second_output": second.outputs[output_name],
            "scalar": first.scalars[scalar_name],
            "trace": first.trace.to_dict(),
            "repeated_match": first.output_bits == second.output_bits,
        }

    report = {
        "status": "passed",
        "version": dexsim.__version__,
        "capabilities": dexsim.Device.capabilities(),
        "no_public_hardware_arguments": no_hardware_arguments,
        "signatures": signatures,
        "eager": eager,
        "program": program_summary,
    }
    checks = {
        "version_0_3_0": report["version"] == "0.3.0",
        "no_public_hardware_arguments": no_hardware_arguments,
        "persistent_single_reset": reset_before == reset_after == 1,
        "eager_result": eager["last"] == [[2.0, 3.0], [4.0, 5.0]],
        "program_repeated_match": program_summary["repeated_match"],
        "program_command_count": program_summary["command_count"] == 4,
    }
    report["checks"] = checks
    report["status"] = "passed" if all(checks.values()) else "failed"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps({"status": report["status"], "checks": checks}, indent=2, sort_keys=True))
    if report["status"] != "passed":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
