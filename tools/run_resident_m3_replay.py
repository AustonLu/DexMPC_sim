#!/usr/bin/env python3
"""Replay the M3 forward candidate through Program residency policies."""

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
from pathlib import Path
import time

import numpy as np

import dexsim
from dexsim.kernels import reference_forward_stage


POLICIES = (
    ("single", "off"),
    ("dual", "off"),
    ("dual", "on"),
    ("quad", "off"),
    ("quad", "on"),
)


def _digest(bits):
    data = bytearray()
    for value in bits:
        data.extend(int(value).to_bytes(2, "little"))
    return hashlib.sha256(data).hexdigest()


def _sum_metrics(results):
    keys = (
        "total_cycles",
        "compute_only_cycles",
        "internal_transfer_cycles",
        "input_upload_cycles",
        "operator_region_cycles",
        "output_materialize_cycles",
        "output_download_cycles",
    )
    return {
        key: sum(int(result.trace.kernel_metrics[key]) for result in results)
        for key in keys
    }


def _build_program(*, q_inv, jac, phi, h, sigma, beta):
    program = dexsim.Program("m3_forward_from_b")
    b = program.input("b", (q_inv.shape[0],))
    q_inv_tensor = program.constant("q_inv", q_inv)
    jac_tensor = program.constant("jac", jac)
    jac_t_tensor = program.constant("jac_t", jac.T)
    phi_tensor = program.constant("phi", phi)

    x = program.gemv(q_inv_tensor, b)
    t = program.gemv(jac_tensor, x)
    t_plus_phi = program.add(t, phi_tensor)
    neg_sigma_sum = program.scale(t_plus_phi, -float(sigma))
    neg_damping_t = program.scale(t, -0.1 * float(sigma) / float(h))
    z = program.add(neg_sigma_sum, neg_damping_t)
    beta_z = program.scale(z, float(beta))
    softplus = program.softplus(beta_z)
    s = program.scale(softplus, 1.0 / float(beta))
    jac_t_s = program.gemv(jac_t_tensor, s)
    q_inv_jac_t_s = program.gemv(q_inv_tensor, jac_t_s)
    x_plus_contact = program.add(x, q_inv_jac_t_s)
    velocity = program.scale(x_plus_contact, 1.0 / float(h))
    program.output(velocity)
    return program, velocity


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--params-module",
        default="examples.mpc.allegro.airplane.params",
    )
    parser.add_argument("--params-class", default="ExplicitMPCParams")
    args = parser.parse_args()

    fixture_path = Path(args.fixture).resolve()
    metadata_path = fixture_path.with_suffix(".json")
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    params_module = importlib.import_module(args.params_module)
    params_type = getattr(params_module, args.params_class)
    param = params_type(rand_seed=int(metadata["seed"]), target_type="rotation")

    with np.load(fixture_path) as fixture:
        q_inv = np.linalg.inv(np.asarray(param.Q, dtype=np.float64))
        robot_stiff = np.asarray(param.robot_stiff_, dtype=np.float64)
        object_force = np.asarray(
            param.obj_mass_ * np.asarray(param.gravity_, dtype=np.float64),
            dtype=np.float64,
        )
        jac = np.asarray(fixture["jac_mat"], dtype=np.float64)
        phi = np.asarray(fixture["phi_vec"], dtype=np.float64)
        sigma = float(fixture["sigma"])
        h = float(param.h_)
        beta = 100.0
        commands = np.asarray(fixture["stage_u_k"], dtype=np.float64)

        expected = []
        b_values = []
        for command in commands:
            reference = reference_forward_stage(
                command=command,
                object_force=object_force,
                q_inv=q_inv,
                robot_stiff=robot_stiff,
                jac=jac,
                phi=phi,
                h=h,
                sigma=sigma,
                beta=beta,
            )
            expected.append(tuple(reference["velocity"]))
            b_values.append([
                dexsim.fp16_value(value) for value in reference["b"]
            ])

    program, velocity = _build_program(
        q_inv=q_inv,
        jac=jac,
        phi=phi,
        h=h,
        sigma=sigma,
        beta=beta,
    )
    records = []
    started = time.perf_counter()
    for execution_policy, residency_policy in POLICIES:
        stage_results = []
        with program.compile(
            execution_policy=execution_policy,
            residency_policy=residency_policy,
            timeout_cycles=4_000_000,
        ) as compiled:
            for b in b_values:
                stage_results.append(compiled.run(b=b))
        observed = [
            tuple(result.output_bits[velocity.name]) for result in stage_results
        ]
        records.append({
            "execution_policy": execution_policy,
            "residency_policy": residency_policy,
            "bit_exact_to_m3_reference": observed == expected,
            "stage_output_sha256": [_digest(value) for value in observed],
            "metrics": _sum_metrics(stage_results),
            "stage_metrics": [
                dict(result.trace.kernel_metrics) for result in stage_results
            ],
            "residency_metrics": [
                dict(result.trace.residency["metrics"])
                for result in stage_results
            ],
            "selected_cores": sorted({
                command["core"]
                for result in stage_results
                for command in result.trace.commands
            }),
        })

    baseline = next(
        record for record in records
        if record["execution_policy"] == "single"
        and record["residency_policy"] == "off"
    )
    per_op = {
        record["execution_policy"]: record
        for record in records if record["residency_policy"] == "off"
    }
    for record in records:
        metrics = record["metrics"]
        record["speedup_vs_single"] = {
            "end_to_end": (
                baseline["metrics"]["total_cycles"] / metrics["total_cycles"]
            ),
            "compute_only": (
                baseline["metrics"]["compute_only_cycles"]
                / metrics["compute_only_cycles"]
            ),
        }
        same_policy = per_op.get(record["execution_policy"])
        record["residency_speedup_vs_same_core_off"] = (
            same_policy["metrics"]["total_cycles"] / metrics["total_cycles"]
            if record["residency_policy"] == "on" else None
        )

    payload = {
        "schema_version": 1,
        "milestone": "M6.2-real-M3-candidate-replay",
        "dexsim_version": dexsim.__version__,
        "fixture": str(fixture_path),
        "scope": (
            "M3 forward Program from the existing bit-preserving host concat "
            "boundary (b) through FP16 velocity"
        ),
        "stage_count": len(b_values),
        "operator_count_per_stage": 13,
        "all_bit_exact_to_m3_reference": all(
            record["bit_exact_to_m3_reference"] for record in records
        ),
        "records": records,
        "wall_seconds": time.perf_counter() - started,
    }
    Path(args.output).write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
