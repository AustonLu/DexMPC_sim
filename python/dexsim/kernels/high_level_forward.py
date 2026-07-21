"""M3 velocity lowering rewritten against the v0.3 address-free Operator API."""

from __future__ import annotations

from typing import Mapping

from ..operator_runtime import Device
from ..session import DexSimError, fp16_value
from .forward import (
    ForwardStageResult,
    _bits,
    _matrix,
    _transpose_bits,
    _vector,
    reference_forward_stage,
)


def _snapshot_dict(snapshot):
    return {
        "cycle": int(snapshot.cycle),
        "read_bytes": int(snapshot.read_bytes),
        "write_bytes": int(snapshot.write_bytes),
        "done_count": int(snapshot.done_count),
        "reset_count": int(snapshot.reset_count),
    }


def _snapshot_delta(before, after):
    return {
        "cycles": int(after.cycle - before.cycle),
        "read_bytes": int(after.read_bytes - before.read_bytes),
        "write_bytes": int(after.write_bytes - before.write_bytes),
        "done_count": int(after.done_count - before.done_count),
        "reset_count_before": int(before.reset_count),
        "reset_count_after": int(after.reset_count),
    }


class _AutomaticLayout:
    def __init__(self, device):
        self.device = device

    def to_dict(self):
        return {
            "mode": "v0.3 automatic VariableAllocator",
            "allocator": self.device.allocator_snapshot(),
        }


class HighLevelDexMPCForwardKernel:
    """Audited velocity kernel without public SRAM or command arguments."""

    def __init__(
        self,
        device: Device,
        *,
        object_force,
        q_inv,
        robot_stiff,
        jac,
        phi,
        h: float,
        sigma: float,
        beta: float = 100.0,
    ):
        self.device = device
        self.object_force = _vector(object_force, "object_force")
        q_inv_flat, self.n_qvel, q_inv_cols = _matrix(q_inv, "q_inv")
        robot_flat, self.n_cmd, robot_cols = _matrix(robot_stiff, "robot_stiff")
        jac_flat, self.contact_rows, jac_cols = _matrix(jac, "jac")
        phi_flat = _vector(phi, "phi")
        self.h = float(h)
        self.sigma = float(sigma)
        self.beta = float(beta)
        if self.n_qvel != q_inv_cols:
            raise ValueError("q_inv must be square")
        if self.n_cmd != robot_cols:
            raise ValueError("robot_stiff must be square")
        if len(self.object_force) + self.n_cmd != self.n_qvel:
            raise ValueError("object_force and robot command do not form n_qvel")
        if jac_cols != self.n_qvel or len(phi_flat) != self.contact_rows:
            raise ValueError("jac/phi shape mismatch")
        if self.h <= 0 or self.beta <= 0:
            raise ValueError("h and beta must be positive")

        self._q_inv_values = [
            q_inv_flat[index : index + self.n_qvel]
            for index in range(0, len(q_inv_flat), self.n_qvel)
        ]
        self._robot_values = [
            robot_flat[index : index + self.n_cmd]
            for index in range(0, len(robot_flat), self.n_cmd)
        ]
        self._jac_values = [
            jac_flat[index : index + self.n_qvel]
            for index in range(0, len(jac_flat), self.n_qvel)
        ]
        self._phi_values = phi_flat
        jac_t_bits = _transpose_bits(_bits(jac_flat), self.contact_rows, self.n_qvel)
        jac_t_values = [fp16_value(value) for value in jac_t_bits]
        jac_t_values = [
            jac_t_values[index : index + self.contact_rows]
            for index in range(0, len(jac_t_values), self.contact_rows)
        ]
        constant_before = self.device.session.snapshot()
        self._constants = {
            "q_inv": device.constant(self._q_inv_values),
            "robot_stiff": device.constant(self._robot_values),
            "jac": device.constant(self._jac_values),
            "jac_t": device.constant(jac_t_values),
            "phi": device.constant(phi_flat),
        }
        constant_after = self.device.session.snapshot()
        self.layout = _AutomaticLayout(device)
        self.constant_upload_trace = {
            "before": _snapshot_dict(constant_before),
            "after": _snapshot_dict(constant_after),
            "delta": _snapshot_delta(constant_before, constant_after),
            "placement": "automatic and address-free at the public API",
        }
        self._object_force_bits = _bits(self.object_force)

    def close(self):
        for tensor in self._constants.values():
            tensor.release()

    def run_stage(self, command, *, capture_intermediates=True) -> ForwardStageResult:
        command = _vector(command, "command")
        if len(command) != self.n_cmd:
            raise ValueError(f"command length is {len(command)}, expected {self.n_cmd}")
        trace_start = len(self.device.trace())
        stage_before = self.device.session.snapshot()
        tensors = {}
        try:
            tensors["u"] = self.device.tensor(command)
            tensors["b_r"] = self.device.gemv(
                self._constants["robot_stiff"], tensors["u"]
            )
            b_r_bits = list(tensors["b_r"].bits())
            b_bits = self._object_force_bits + b_r_bits
            tensors["b"] = self.device.tensor_bits(b_bits, shape=(self.n_qvel,))
            tensors["x"] = self.device.gemv(self._constants["q_inv"], tensors["b"])
            tensors["t"] = self.device.gemv(self._constants["jac"], tensors["x"])
            tensors["t_plus_phi"] = self.device.add(tensors["t"], self._constants["phi"])
            tensors["neg_sigma_sum"] = self.device.scale(
                tensors["t_plus_phi"], -self.sigma
            )
            tensors["neg_damping_t"] = self.device.scale(
                tensors["t"], -0.1 * self.sigma / self.h
            )
            tensors["z"] = self.device.add(
                tensors["neg_sigma_sum"], tensors["neg_damping_t"]
            )
            tensors["beta_z"] = self.device.scale(tensors["z"], self.beta)
            tensors["softplus"] = self.device.softplus(tensors["beta_z"])
            tensors["s"] = self.device.scale(tensors["softplus"], 1.0 / self.beta)
            tensors["jac_t_s"] = self.device.gemv(
                self._constants["jac_t"], tensors["s"]
            )
            tensors["q_inv_jac_t_s"] = self.device.gemv(
                self._constants["q_inv"], tensors["jac_t_s"]
            )
            tensors["x_plus_contact"] = self.device.add(
                tensors["x"], tensors["q_inv_jac_t_s"]
            )
            tensors["velocity"] = self.device.scale(
                tensors["x_plus_contact"], 1.0 / self.h
            )
            compute_end = self.device.session.snapshot()

            capture_names = (
                "b_r", "b", "x", "t", "t_plus_phi", "neg_sigma_sum",
                "neg_damping_t", "z", "beta_z", "softplus", "s", "jac_t_s",
                "q_inv_jac_t_s", "x_plus_contact", "velocity",
            )
            selected = capture_names if capture_intermediates else ("b_r", "b", "velocity")
            hardware_bits = {name: list(tensors[name].bits()) for name in selected}
            capture_end = self.device.session.snapshot()
            reference_bits = reference_forward_stage(
                command=command,
                object_force=self.object_force,
                q_inv=self._q_inv_values,
                robot_stiff=self._robot_values,
                jac=self._jac_values,
                phi=self._phi_values,
                h=self.h,
                sigma=self.sigma,
                beta=self.beta,
            )
            mismatch = {}
            for name, actual in hardware_bits.items():
                expected = list(reference_bits[name])
                positions = [
                    index for index, (left, right) in enumerate(zip(actual, expected))
                    if left != right
                ]
                if positions:
                    mismatch[name] = {"count": len(positions), "first_indices": positions[:8]}
            if mismatch:
                raise DexSimError(f"high-level forward differs from FP16 reference: {mismatch}")

            velocity_bits = tuple(hardware_bits["velocity"])
            intermediate_bits = {name: tuple(values) for name, values in hardware_bits.items()}
            intermediates = {
                name: tuple(fp16_value(value) for value in values)
                for name, values in intermediate_bits.items()
            }
            operation_trace = self.device.trace()[trace_start:]
            trace = {
                "implementation": "dexsim v0.3 high-level Operator API",
                "operator_counts": {"gemv": 5, "add": 3, "scale": 5, "softplus": 1},
                "command_count": len(operation_trace),
                "commands": list(operation_trace),
                "host_operations": [
                    {
                        "name": "concat_object_and_robot_force",
                        "reason": "current Assemble primitive cannot express packed 1-D concat without padding",
                    }
                ],
                "transport": {
                    "compute_and_required_io": _snapshot_delta(stage_before, compute_end),
                    "diagnostic_capture": _snapshot_delta(compute_end, capture_end),
                    "total": _snapshot_delta(stage_before, capture_end),
                },
                "reference": {
                    "bit_exact": True,
                    "captured_intermediates": bool(capture_intermediates),
                    "mismatches": mismatch,
                },
                "fallbacks": [],
            }
            return ForwardStageResult(
                velocity=tuple(fp16_value(value) for value in velocity_bits),
                velocity_bits=velocity_bits,
                intermediates=intermediates,
                intermediate_bits=intermediate_bits,
                trace=trace,
            )
        finally:
            for tensor in reversed(list(tensors.values())):
                tensor.release()
