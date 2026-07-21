"""M3 fixed forward kernel for the explicit DexMPC model.

This module is intentionally a fixed lowering rather than a general compiler.
It translates one audited explicit-model stage into the public FP16 primitive
API.  Concatenating the object and robot force vectors remains a recorded host
operation because the current Assemble primitive cannot express this 1-D
layout without padding.  State/quaternion integration belongs to the caller.
"""

from dataclasses import asdict, dataclass
import math
from pathlib import Path
from typing import Dict, Iterable, List, Mapping, Sequence, Tuple

from ..commands import add, gemv, scale, softplus
from ..session import DexSimError, Session, fp16_bits, fp16_value


FP16_PER_WORD = 8
MEMORY_WORD_CAPACITY = {"global": 2048, "local": 512, "temp": 896}


@dataclass(frozen=True)
class SramRegion:
    memory: str
    word_offset: int
    elements: int

    @property
    def element_offset(self) -> int:
        return self.word_offset * FP16_PER_WORD

    @property
    def words(self) -> int:
        return math.ceil(self.elements / FP16_PER_WORD)

    def to_dict(self) -> dict:
        value = asdict(self)
        value.update(element_offset=self.element_offset, words=self.words)
        return value


@dataclass(frozen=True)
class SramLayout:
    global_regions: Mapping[str, SramRegion]
    local_regions: Mapping[str, SramRegion]

    def region(self, name: str) -> SramRegion:
        if name in self.global_regions:
            return self.global_regions[name]
        if name in self.local_regions:
            return self.local_regions[name]
        raise KeyError(name)

    def to_dict(self) -> dict:
        return {
            "global": {name: region.to_dict() for name, region in self.global_regions.items()},
            "local": {name: region.to_dict() for name, region in self.local_regions.items()},
            "capacity_words": dict(MEMORY_WORD_CAPACITY),
        }


@dataclass(frozen=True)
class ForwardStageResult:
    velocity: Tuple[float, ...]
    velocity_bits: Tuple[int, ...]
    intermediates: Mapping[str, Tuple[float, ...]]
    intermediate_bits: Mapping[str, Tuple[int, ...]]
    trace: Mapping[str, object]

    def to_dict(self) -> dict:
        return {
            "velocity": list(self.velocity),
            "velocity_bits": list(self.velocity_bits),
            "intermediates": {name: list(value) for name, value in self.intermediates.items()},
            "intermediate_bits": {
                name: list(value) for name, value in self.intermediate_bits.items()
            },
            "trace": dict(self.trace),
        }


def _word_aligned_regions(memory: str, specs: Iterable[Tuple[str, int]]) -> Dict[str, SramRegion]:
    regions: Dict[str, SramRegion] = {}
    cursor = 0
    for name, elements in specs:
        if elements <= 0:
            raise ValueError(f"region {name!r} must contain at least one element")
        region = SramRegion(memory=memory, word_offset=cursor, elements=int(elements))
        regions[name] = region
        cursor += region.words
    if cursor > MEMORY_WORD_CAPACITY[memory]:
        raise ValueError(
            f"forward kernel needs {cursor} {memory} words, capacity is "
            f"{MEMORY_WORD_CAPACITY[memory]}"
        )
    return regions


def build_forward_sram_layout(n_qvel: int, n_cmd: int, contact_rows: int) -> SramLayout:
    """Build the deterministic, word-aligned lifetime layout used by M3."""
    n_qvel = int(n_qvel)
    n_cmd = int(n_cmd)
    contact_rows = int(contact_rows)
    if min(n_qvel, n_cmd, contact_rows) <= 0:
        raise ValueError("forward dimensions must be positive")

    global_regions = _word_aligned_regions(
        "global",
        (
            ("q_inv", n_qvel * n_qvel),
            ("robot_stiff", n_cmd * n_cmd),
            ("jac", contact_rows * n_qvel),
            ("jac_t", n_qvel * contact_rows),
            ("phi", contact_rows),
        ),
    )
    local_regions = _word_aligned_regions(
        "local",
        (
            ("u", n_cmd),
            ("b_r", n_cmd),
            ("b", n_qvel),
            ("x", n_qvel),
            ("t", contact_rows),
            ("t_plus_phi", contact_rows),
            ("neg_sigma_sum", contact_rows),
            ("neg_damping_t", contact_rows),
            ("z", contact_rows),
            ("beta_z", contact_rows),
            ("softplus", contact_rows),
            ("s", contact_rows),
            ("jac_t_s", n_qvel),
            ("q_inv_jac_t_s", n_qvel),
            ("x_plus_contact", n_qvel),
            ("velocity", n_qvel),
        ),
    )
    return SramLayout(global_regions=global_regions, local_regions=local_regions)


def _as_python(value):
    return value.tolist() if hasattr(value, "tolist") else value


def _vector(value, name: str) -> List[float]:
    value = _as_python(value)
    if not isinstance(value, (list, tuple)):
        raise TypeError(f"{name} must be a one-dimensional sequence")
    result = []
    for item in value:
        item = _as_python(item)
        if isinstance(item, (list, tuple)):
            raise ValueError(f"{name} must be one-dimensional")
        result.append(float(item))
    return result


def _matrix(value, name: str) -> Tuple[List[float], int, int]:
    value = _as_python(value)
    if not isinstance(value, (list, tuple)) or not value:
        raise TypeError(f"{name} must be a non-empty two-dimensional sequence")
    rows = []
    width = None
    for row in value:
        row = _as_python(row)
        if not isinstance(row, (list, tuple)) or not row:
            raise ValueError(f"{name} must contain non-empty rows")
        current = [float(item) for item in row]
        if width is None:
            width = len(current)
        elif len(current) != width:
            raise ValueError(f"{name} has ragged rows")
        rows.append(current)
    return [item for row in rows for item in row], len(rows), int(width)


def _bits(values: Sequence[float]) -> List[int]:
    return [fp16_bits(value) for value in values]


def _flush_subnormal(raw: int) -> int:
    """DW ieee_compliance=0 treats every exponent-zero operand as signed zero."""
    exponent = (raw >> 10) & 0x1F
    fraction = raw & 0x3FF
    return (raw & 0x8000) if exponent == 0 and fraction != 0 else raw


def _arithmetic_bits(value: float) -> int:
    """Round to FP16 and flush an underflowed result like DW compliance mode 0."""
    return _flush_subnormal(fp16_bits(value))


def _add_bits(left: int, right: int) -> int:
    left = _flush_subnormal(left)
    right = _flush_subnormal(right)
    return _arithmetic_bits(fp16_value(left) + fp16_value(right))


def _mul_bits(left: int, right: int) -> int:
    left = _flush_subnormal(left)
    right = _flush_subnormal(right)
    return _arithmetic_bits(fp16_value(left) * fp16_value(right))


def _add_vectors(left: Sequence[int], right: Sequence[int]) -> List[int]:
    if len(left) != len(right):
        raise ValueError("FP16 add operands have different lengths")
    # The elementwise ADD command is implemented by MacArrayADDCtrl in ACC
    # mode: clear(+0), accumulate A, accumulate B, then drain with +0.  With
    # round-to-nearest the final drain canonicalizes every signed zero to +0.
    # A direct DW_fp_add(a, b) reference is therefore wrong for -0 + -0.
    result = [_add_bits(a, b) for a, b in zip(left, right)]
    return [0 if (item & 0x7FFF) == 0 else item for item in result]


def _scale_vector(source: Sequence[int], alpha: int) -> List[int]:
    return [_mul_bits(alpha, item) for item in source]


def _gemv(matrix: Sequence[int], vector: Sequence[int], rows: int, cols: int) -> List[int]:
    if len(matrix) != rows * cols or len(vector) != cols:
        raise ValueError("FP16 GEMV shape mismatch")
    output = []
    for row in range(rows):
        accumulator = 0
        for inner in range(cols):
            product = _mul_bits(matrix[row * cols + inner], vector[inner])
            accumulator = _add_bits(accumulator, product)
        output.append(accumulator)
    return output


def _softplus_lut_words() -> List[int]:
    packaged = Path(__file__).resolve().parents[1] / "_data" / "softplus_data.hex"
    source_tree = (
        Path(__file__).resolve().parents[3]
        / "rtl"
        / "chisel"
        / "top_connect"
        / "src"
        / "lut"
        / "tools"
        / "softplus_data.hex"
    )
    path = packaged if packaged.is_file() else source_tree
    values = [int(line, 16) for line in path.read_text().splitlines() if line]
    if len(values) != 512:
        raise DexSimError(f"softplus LUT must contain 512 words, got {len(values)}")
    return values


def _softplus_one(input_bits: int, lut_words: Sequence[int]) -> int:
    sign = (input_bits >> 15) & 1
    magnitude = input_bits & 0x7FFF
    address = magnitude >> 5
    if address > 536:
        return 0 if sign else input_bits
    bank = (address >> 9) & 1
    row = (address >> 1) & 0xFF
    word_select = address & 1
    packed = lut_words[bank * 256 + row]
    lut_bits = (packed >> 16) & 0xFFFF if word_select else packed & 0xFFFF
    if not sign or magnitude == 0:
        return lut_bits
    return fp16_bits(fp16_value(lut_bits) - fp16_value(magnitude))


def _transpose_bits(source: Sequence[int], rows: int, cols: int) -> List[int]:
    return [source[row * cols + col] for col in range(cols) for row in range(rows)]


def reference_forward_stage(
    *,
    command,
    object_force,
    q_inv,
    robot_stiff,
    jac,
    phi,
    h: float,
    sigma: float,
    beta: float = 100.0,
) -> Mapping[str, Tuple[int, ...]]:
    """Return the bit-accurate FP16 intermediates for one lowered stage."""
    u = _vector(command, "command")
    b_o = _vector(object_force, "object_force")
    q_inv_flat, n_qvel, q_inv_cols = _matrix(q_inv, "q_inv")
    robot_flat, n_cmd, robot_cols = _matrix(robot_stiff, "robot_stiff")
    jac_flat, contact_rows, jac_cols = _matrix(jac, "jac")
    phi_flat = _vector(phi, "phi")
    if n_qvel != q_inv_cols:
        raise ValueError("q_inv must be square")
    if n_cmd != robot_cols or len(u) != n_cmd:
        raise ValueError("robot_stiff/command shape mismatch")
    if len(b_o) + n_cmd != n_qvel:
        raise ValueError("object_force and robot command do not form n_qvel")
    if jac_cols != n_qvel or len(phi_flat) != contact_rows:
        raise ValueError("jac/phi shape mismatch")
    if h <= 0 or beta <= 0:
        raise ValueError("h and beta must be positive")

    q_inv_bits = _bits(q_inv_flat)
    robot_bits = _bits(robot_flat)
    jac_bits = _bits(jac_flat)
    phi_bits = _bits(phi_flat)
    u_bits = _bits(u)
    b_r = _gemv(robot_bits, u_bits, n_cmd, n_cmd)
    b = _bits(b_o) + b_r
    x = _gemv(q_inv_bits, b, n_qvel, n_qvel)
    t = _gemv(jac_bits, x, contact_rows, n_qvel)
    t_plus_phi = _add_vectors(t, phi_bits)
    neg_sigma_sum = _scale_vector(t_plus_phi, fp16_bits(-float(sigma)))
    neg_damping_t = _scale_vector(
        t, fp16_bits(-0.1 * float(sigma) / float(h))
    )
    z = _add_vectors(neg_sigma_sum, neg_damping_t)
    beta_z = _scale_vector(z, fp16_bits(beta))
    lut_words = _softplus_lut_words()
    softplus_value = [_softplus_one(item, lut_words) for item in beta_z]
    s = _scale_vector(softplus_value, fp16_bits(1.0 / beta))
    jac_t_s = _gemv(
        _transpose_bits(jac_bits, contact_rows, n_qvel),
        s,
        n_qvel,
        contact_rows,
    )
    q_inv_jac_t_s = _gemv(q_inv_bits, jac_t_s, n_qvel, n_qvel)
    x_plus_contact = _add_vectors(x, q_inv_jac_t_s)
    velocity = _scale_vector(x_plus_contact, fp16_bits(1.0 / float(h)))
    return {
        name: tuple(value)
        for name, value in (
            ("u", u_bits),
            ("b_r", b_r),
            ("b", b),
            ("x", x),
            ("t", t),
            ("t_plus_phi", t_plus_phi),
            ("neg_sigma_sum", neg_sigma_sum),
            ("neg_damping_t", neg_damping_t),
            ("z", z),
            ("beta_z", beta_z),
            ("softplus", softplus_value),
            ("s", s),
            ("jac_t_s", jac_t_s),
            ("q_inv_jac_t_s", q_inv_jac_t_s),
            ("x_plus_contact", x_plus_contact),
            ("velocity", velocity),
        )
    }


def _snapshot_dict(snapshot) -> dict:
    return {
        "cycle": int(snapshot.cycle),
        "read_bytes": int(snapshot.read_bytes),
        "write_bytes": int(snapshot.write_bytes),
        "done_count": int(snapshot.done_count),
        "reset_count": int(snapshot.reset_count),
    }


def _snapshot_delta(before, after) -> dict:
    return {
        "cycles": int(after.cycle - before.cycle),
        "read_bytes": int(after.read_bytes - before.read_bytes),
        "write_bytes": int(after.write_bytes - before.write_bytes),
        "done_count": int(after.done_count - before.done_count),
        "reset_count_before": int(before.reset_count),
        "reset_count_after": int(after.reset_count),
    }


class DexMPCForwardKernel:
    """Persistent-session lowering of the explicit-model velocity equations."""

    def __init__(
        self,
        session: Session,
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
        self.session = session
        self.object_force = _vector(object_force, "object_force")
        self.q_inv, self.n_qvel, q_inv_cols = _matrix(q_inv, "q_inv")
        self.robot_stiff, self.n_cmd, robot_cols = _matrix(
            robot_stiff, "robot_stiff"
        )
        self.jac, self.contact_rows, jac_cols = _matrix(jac, "jac")
        self.phi = _vector(phi, "phi")
        self.h = float(h)
        self.sigma = float(sigma)
        self.beta = float(beta)
        if self.n_qvel != q_inv_cols:
            raise ValueError("q_inv must be square")
        if self.n_cmd != robot_cols:
            raise ValueError("robot_stiff must be square")
        if len(self.object_force) + self.n_cmd != self.n_qvel:
            raise ValueError("object_force and robot command do not form n_qvel")
        if jac_cols != self.n_qvel or len(self.phi) != self.contact_rows:
            raise ValueError("jac/phi shape mismatch")
        if self.h <= 0 or self.beta <= 0:
            raise ValueError("h and beta must be positive")

        self.layout = build_forward_sram_layout(
            self.n_qvel, self.n_cmd, self.contact_rows
        )
        self._next_command_id = 1
        self._constant_bits = {
            "q_inv": _bits(self.q_inv),
            "robot_stiff": _bits(self.robot_stiff),
            "jac": _bits(self.jac),
            "phi": _bits(self.phi),
        }
        self._constant_bits["jac_t"] = _transpose_bits(
            self._constant_bits["jac"], self.contact_rows, self.n_qvel
        )
        self._object_force_bits = _bits(self.object_force)

        before = self.session.snapshot()
        for name in ("q_inv", "robot_stiff", "jac", "jac_t", "phi"):
            self._write_bits(name, self._constant_bits[name])
        after = self.session.snapshot()
        self.constant_upload_trace = {
            "before": _snapshot_dict(before),
            "after": _snapshot_dict(after),
            "delta": _snapshot_delta(before, after),
            "quantization": "FP64/Python constants converted once to IEEE FP16 bits",
        }

    def _write_bits(self, region_name: str, values: Sequence[int]) -> None:
        region = self.layout.region(region_name)
        if len(values) != region.elements:
            raise ValueError(
                f"region {region_name!r} expects {region.elements} elements, got {len(values)}"
            )
        self.session.write_tensor_bits(
            memory=region.memory,
            offset=region.element_offset,
            value=list(values),
        )

    def _read_bits(self, region_name: str) -> List[int]:
        region = self.layout.region(region_name)
        return list(
            self.session.read_tensor_bits(
                memory=region.memory,
                offset=region.element_offset,
                shape=(region.elements,),
            )
        )

    def _id(self) -> int:
        if self._next_command_id > 0xFFF:
            raise DexSimError("M3 forward kernel exhausted 12-bit command IDs")
        value = self._next_command_id
        self._next_command_id += 1
        return value

    def _gemv(self, a: str, x: str, out: str, rows: int, cols: int, group_end=False):
        a_region = self.layout.region(a)
        x_region = self.layout.region(x)
        out_region = self.layout.region(out)
        return gemv(
            self._id(),
            a_memory=a_region.memory,
            a_word_offset=a_region.word_offset,
            x_memory=x_region.memory,
            x_word_offset=x_region.word_offset,
            out_memory=out_region.memory,
            out_word_offset=out_region.word_offset,
            n_rows=rows,
            k_dim=cols,
            group_end=group_end,
        )

    def _add(self, left: str, right: str, out: str, count: int, group_end=False):
        a_region = self.layout.region(left)
        b_region = self.layout.region(right)
        out_region = self.layout.region(out)
        return add(
            self._id(),
            a_memory=a_region.memory,
            a_word_offset=a_region.word_offset,
            b_memory=b_region.memory,
            b_word_offset=b_region.word_offset,
            out_memory=out_region.memory,
            out_word_offset=out_region.word_offset,
            rows=1,
            cols=count,
            group_end=group_end,
        )

    def _scale(self, source: str, out: str, count: int, alpha: float, group_end=False):
        src_region = self.layout.region(source)
        out_region = self.layout.region(out)
        return scale(
            self._id(),
            src_memory=src_region.memory,
            src_word_offset=src_region.word_offset,
            out_memory=out_region.memory,
            out_word_offset=out_region.word_offset,
            rows=1,
            cols=count,
            alpha_bits=fp16_bits(alpha),
            group_end=group_end,
        )

    def _softplus(self, source: str, out: str, count: int, group_end=False):
        src_region = self.layout.region(source)
        out_region = self.layout.region(out)
        return softplus(
            self._id(),
            src_memory=src_region.memory,
            src_word_offset=src_region.word_offset,
            out_memory=out_region.memory,
            out_word_offset=out_region.word_offset,
            rows=1,
            cols=count,
            group_end=group_end,
        )

    def run_stage(self, command, *, capture_intermediates=True) -> ForwardStageResult:
        u = _vector(command, "command")
        if len(u) != self.n_cmd:
            raise ValueError(f"command length is {len(u)}, expected {self.n_cmd}")
        u_bits = _bits(u)
        stage_before = self.session.snapshot()
        self._write_bits("u", u_bits)

        first_command = self._gemv(
            "robot_stiff", "u", "b_r", self.n_cmd, self.n_cmd, group_end=True
        )
        first_run = self.session.run([first_command])
        b_r_bits = self._read_bits("b_r")

        b_bits = self._object_force_bits + b_r_bits
        self._write_bits("b", b_bits)
        commands = [
            self._gemv("q_inv", "b", "x", self.n_qvel, self.n_qvel),
            self._gemv("jac", "x", "t", self.contact_rows, self.n_qvel),
            self._add("t", "phi", "t_plus_phi", self.contact_rows),
            self._scale(
                "t_plus_phi", "neg_sigma_sum", self.contact_rows, -self.sigma
            ),
            self._scale(
                "t",
                "neg_damping_t",
                self.contact_rows,
                -0.1 * self.sigma / self.h,
            ),
            self._add(
                "neg_sigma_sum", "neg_damping_t", "z", self.contact_rows
            ),
            self._scale("z", "beta_z", self.contact_rows, self.beta),
            self._softplus("beta_z", "softplus", self.contact_rows),
            self._scale("softplus", "s", self.contact_rows, 1.0 / self.beta),
            self._gemv(
                "jac_t", "s", "jac_t_s", self.n_qvel, self.contact_rows
            ),
            self._gemv(
                "q_inv",
                "jac_t_s",
                "q_inv_jac_t_s",
                self.n_qvel,
                self.n_qvel,
            ),
            self._add(
                "x", "q_inv_jac_t_s", "x_plus_contact", self.n_qvel
            ),
            self._scale(
                "x_plus_contact",
                "velocity",
                self.n_qvel,
                1.0 / self.h,
                group_end=True,
            ),
        ]
        second_run = self.session.run(commands)
        compute_end = self.session.snapshot()

        capture_names = (
            "x",
            "t",
            "t_plus_phi",
            "neg_sigma_sum",
            "neg_damping_t",
            "z",
            "beta_z",
            "softplus",
            "s",
            "jac_t_s",
            "q_inv_jac_t_s",
            "x_plus_contact",
            "velocity",
        )
        if capture_intermediates:
            hardware_bits = {"b_r": b_r_bits, "b": b_bits}
            for name in capture_names:
                hardware_bits[name] = self._read_bits(name)
        else:
            hardware_bits = {
                "b_r": b_r_bits,
                "b": b_bits,
                "velocity": self._read_bits("velocity"),
            }
        stage_after = self.session.snapshot()

        reference_bits = reference_forward_stage(
            command=u,
            object_force=self.object_force,
            q_inv=[
                self.q_inv[index : index + self.n_qvel]
                for index in range(0, len(self.q_inv), self.n_qvel)
            ],
            robot_stiff=[
                self.robot_stiff[index : index + self.n_cmd]
                for index in range(0, len(self.robot_stiff), self.n_cmd)
            ],
            jac=[
                self.jac[index : index + self.n_qvel]
                for index in range(0, len(self.jac), self.n_qvel)
            ],
            phi=self.phi,
            h=self.h,
            sigma=self.sigma,
            beta=self.beta,
        )
        mismatch = {}
        for name, actual in hardware_bits.items():
            expected = list(reference_bits[name])
            positions = [index for index, pair in enumerate(zip(actual, expected)) if pair[0] != pair[1]]
            if positions:
                mismatch[name] = {
                    "count": len(positions),
                    "first_indices": positions[:8],
                    "first_pairs": [
                        {
                            "index": index,
                            "actual_bits": int(actual[index]),
                            "expected_bits": int(expected[index]),
                            "actual": fp16_value(actual[index]),
                            "expected": fp16_value(expected[index]),
                        }
                        for index in positions[:8]
                    ],
                }
        if mismatch:
            raise DexSimError(f"M3 forward kernel differs from FP16 reference: {mismatch}")

        velocity_bits = tuple(hardware_bits["velocity"])
        intermediate_bits = {
            name: tuple(values) for name, values in hardware_bits.items()
        }
        intermediates = {
            name: tuple(fp16_value(item) for item in values)
            for name, values in intermediate_bits.items()
        }
        command_names = [
            "gemv_robot_stiff_u",
            "gemv_q_inv_b",
            "gemv_jac_x",
            "add_t_phi",
            "scale_neg_sigma",
            "scale_neg_damping",
            "add_contact_terms",
            "scale_beta",
            "softplus",
            "scale_inv_beta",
            "gemv_jac_t_s",
            "gemv_q_inv_jac_t_s",
            "add_velocity_terms",
            "scale_inv_h",
        ]
        command_results = list(first_run.command_results) + list(second_run.command_results)
        command_trace = []
        for name, result in zip(command_names, command_results):
            entry = result.to_dict()
            entry["name"] = name
            command_trace.append(entry)
        trace = {
            "formula": {
                "b_r": "robot_stiff @ u",
                "b": "host_concat(object_force, b_r)",
                "x": "q_inv @ b",
                "t": "jac @ x",
                "z": "-sigma * (t + phi) - 0.1 * sigma / h * t",
                "s": "scale(softplus(scale(z, beta)), 1 / beta)",
                "velocity": "scale(x + q_inv @ (jac.T @ s), 1 / h)",
            },
            "operator_counts": {"gemv": 5, "add": 3, "scale": 5, "softplus": 1},
            "command_count": len(command_results),
            "commands": command_trace,
            "runs": [first_run.to_dict(), second_run.to_dict()],
            "host_operations": [
                {
                    "name": "concat_object_and_robot_force",
                    "reason": "current Assemble primitive cannot express packed 1-D concat without padding",
                    "inputs": ["quantized object_force", "hardware b_r"],
                    "output": "FP16 b written back to Local SRAM",
                },
                {
                    "name": "bit_exact_reference_replay",
                    "reason": "M3 shadow validation guard; not a solver fallback",
                    "precision": "integer FP16 bit model with DW IEEE_COMPLIANCE=0 FTZ and exact Softplus LUT",
                }
            ],
            "snapshots": {
                "before": _snapshot_dict(stage_before),
                "compute_end": _snapshot_dict(compute_end),
                "after_capture": _snapshot_dict(stage_after),
            },
            "transport": {
                "compute_and_required_io": _snapshot_delta(stage_before, compute_end),
                "diagnostic_capture": _snapshot_delta(compute_end, stage_after),
                "total": _snapshot_delta(stage_before, stage_after),
            },
            "reference": {
                "model": "FP16 round after every hardware add/mul/MAC, DW IEEE_COMPLIANCE=0 FTZ, exact Softplus LUT",
                "captured_intermediates": bool(capture_intermediates),
                "bit_exact": True,
                "mismatches": mismatch,
            },
            "fallbacks": [],
        }
        return ForwardStageResult(
            velocity=tuple(fp16_value(item) for item in velocity_bits),
            velocity_bits=velocity_bits,
            intermediates=intermediates,
            intermediate_bits=intermediate_bits,
            trace=trace,
        )
