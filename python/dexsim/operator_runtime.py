"""High-level, address-free Tensor and Operator API for DexMPC TopChip.

The allocator, tensor lifetime and eager-operator model are migrated from the
historical ``origin/compiler-stack-dev`` VariableAllocator/OperatorRuntime.
Command encoding and device execution intentionally reuse the verified v0.2
``commands`` and persistent ``Session`` implementations rather than creating a
second backend.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
import math
import numbers
from typing import Mapping, Optional, Sequence

from .commands import (
    abs as build_abs,
    add as build_add,
    add_reduce as build_add_reduce,
    assemble as build_assemble,
    compare_reduce as build_compare_reduce,
    cos as build_cos,
    dot as build_dot,
    gemm as build_gemm,
    gemv as build_gemv,
    outer as build_outer,
    scale as build_scale,
    sin as build_sin,
    softplus as build_softplus,
    transpose as build_transpose,
)
from .session import DexSimError, RunResult, Session, fp16_bits, fp16_value


FP16_PER_WORD = 8
MEMORY_WORD_CAPACITY = {"global": 2048, "local": 512, "temp": 896}


class AllocationError(DexSimError):
    """No legal automatic SRAM placement is available."""


class UnsupportedShapeError(DexSimError):
    """The mathematical shape needs an unimplemented/unsafe tiling path."""


class ReleasedTensorError(DexSimError):
    """A Tensor handle no longer owns a live device allocation."""


def _as_python(value):
    if hasattr(value, "tolist"):
        value = value.tolist()
    return value


def _flatten(value):
    value = _as_python(value)
    if isinstance(value, numbers.Real):
        return [float(value)], ()
    if not isinstance(value, (list, tuple)):
        raise TypeError("tensor value must be numeric or a nested sequence")
    if not value:
        return [], (0,)
    flat = []
    child_shape = None
    for child in value:
        child_flat, current_shape = _flatten(child)
        if child_shape is None:
            child_shape = current_shape
        elif child_shape != current_shape:
            raise ValueError("ragged tensor values are not supported")
        flat.extend(child_flat)
    return flat, (len(value),) + child_shape


def _flatten_bits(value):
    value = _as_python(value)
    if isinstance(value, numbers.Integral):
        value = int(value)
        if value < 0 or value > 0xFFFF:
            raise ValueError("FP16 bit values must fit in 16 bits")
        return [value], ()
    if not isinstance(value, (list, tuple)):
        raise TypeError("tensor bits must be integers or a nested sequence")
    if not value:
        return [], (0,)
    flat = []
    child_shape = None
    for child in value:
        child_flat, current_shape = _flatten_bits(child)
        if child_shape is None:
            child_shape = current_shape
        elif child_shape != current_shape:
            raise ValueError("ragged tensor bit values are not supported")
        flat.extend(child_flat)
    return flat, (len(value),) + child_shape


def _normalize_shape(shape):
    if isinstance(shape, int):
        shape = (shape,)
    else:
        shape = tuple(int(value) for value in shape)
    if not shape or len(shape) > 2 or any(value <= 0 for value in shape):
        raise ValueError("hardware Tensor shape must contain one or two positive dimensions")
    return shape


def _storage_shape(shape):
    shape = _normalize_shape(shape)
    return (1, shape[0]) if len(shape) == 1 else shape


def _reshape(flat, shape):
    if len(shape) == 1:
        return list(flat[: shape[0]])
    stride = math.prod(shape[1:])
    return [
        _reshape(flat[index * stride : (index + 1) * stride], shape[1:])
        for index in range(shape[0])
    ]


@dataclass(frozen=True)
class BufferRef:
    name: str
    memory: str
    word_offset: int
    shape: tuple[int, ...]
    generation: int
    constant: bool = False

    @property
    def element_count(self):
        return math.prod(self.shape)

    @property
    def word_count(self):
        return math.ceil(self.element_count / FP16_PER_WORD)

    @property
    def element_offset(self):
        return self.word_offset * FP16_PER_WORD

    def to_dict(self):
        value = asdict(self)
        value.update(
            element_count=self.element_count,
            word_count=self.word_count,
            element_offset=self.element_offset,
        )
        return value


@dataclass(frozen=True)
class _FreeRange:
    word_offset: int
    word_count: int


class VariableAllocator:
    """Word-aligned high-water/free-list allocator migrated from the old stack."""

    def __init__(self):
        self._generation = 0
        self._variables: dict[str, BufferRef] = {}
        self._next_word = {memory: 0 for memory in MEMORY_WORD_CAPACITY}
        self._free_ranges: dict[str, list[_FreeRange]] = {
            memory: [] for memory in MEMORY_WORD_CAPACITY
        }

    @property
    def generation(self):
        return self._generation

    def reset(self):
        self._generation += 1
        self._variables.clear()
        self._next_word = {memory: 0 for memory in MEMORY_WORD_CAPACITY}
        self._free_ranges = {memory: [] for memory in MEMORY_WORD_CAPACITY}

    def contains(self, name, generation=None):
        ref = self._variables.get(str(name))
        return ref is not None and (generation is None or ref.generation == generation)

    def get(self, name):
        try:
            return self._variables[str(name)]
        except KeyError as error:
            raise ReleasedTensorError(f"unknown or released DexSim Tensor {name!r}") from error

    def allocate(self, name, shape, *, constant=False, preferred_memories=None):
        name = str(name)
        shape = _normalize_shape(shape)
        if not name:
            raise ValueError("Tensor name must not be empty")
        if name in self._variables:
            raise ValueError(f"duplicate live Tensor name {name!r}")
        memories = tuple(preferred_memories or ("local", "temp", "global"))
        unknown = [memory for memory in memories if memory not in MEMORY_WORD_CAPACITY]
        if unknown:
            raise ValueError(f"unsupported automatic memory choices: {unknown}")
        words = math.ceil(math.prod(shape) / FP16_PER_WORD)
        errors = []
        for memory in memories:
            try:
                base = self._allocate_words(memory, words)
            except AllocationError as error:
                errors.append(str(error))
                continue
            ref = BufferRef(
                name=name,
                memory=memory,
                word_offset=base,
                shape=shape,
                generation=self._generation,
                constant=bool(constant),
            )
            self._variables[name] = ref
            return ref
        raise AllocationError(
            f"cannot place Tensor {name!r} shape={shape}, words={words}; "
            + "; ".join(errors)
        )

    def release(self, name, generation=None):
        name = str(name)
        ref = self._variables.get(name)
        if ref is None:
            raise ReleasedTensorError(f"cannot release unknown Tensor {name!r}")
        if generation is not None and ref.generation != generation:
            raise ReleasedTensorError(f"stale Tensor generation for {name!r}")
        del self._variables[name]
        self._add_free_range(ref.memory, ref.word_offset, ref.word_count)

    def snapshot(self):
        return {
            "generation": self._generation,
            "live": {
                name: ref.to_dict() for name, ref in sorted(self._variables.items())
            },
            "next_word": dict(self._next_word),
            "free_ranges": {
                memory: [asdict(value) for value in ranges]
                for memory, ranges in self._free_ranges.items()
            },
            "capacity_words": dict(MEMORY_WORD_CAPACITY),
        }

    def _allocate_words(self, memory, word_count):
        ranges = self._free_ranges[memory]
        for index, current in enumerate(ranges):
            if current.word_count < word_count:
                continue
            base = current.word_offset
            if current.word_count == word_count:
                del ranges[index]
            else:
                ranges[index] = _FreeRange(
                    current.word_offset + word_count,
                    current.word_count - word_count,
                )
            return base

        base = self._next_word[memory]
        depth = MEMORY_WORD_CAPACITY[memory]
        if base + word_count > depth:
            raise AllocationError(
                f"{memory} SRAM needs [{base},{base + word_count}), depth={depth}"
            )
        # Preserve the historical allocator's one-word high-water guard gap.
        self._next_word[memory] = base + word_count + 1
        return base

    def _add_free_range(self, memory, word_offset, word_count):
        pending_start = word_offset
        pending_end = word_offset + word_count
        merged = []
        inserted = False
        for current in self._free_ranges[memory]:
            current_start = current.word_offset
            current_end = current.word_offset + current.word_count
            if current_end < pending_start:
                merged.append(current)
            elif pending_end < current_start:
                if not inserted:
                    merged.append(_FreeRange(pending_start, pending_end - pending_start))
                    inserted = True
                merged.append(current)
            else:
                pending_start = min(pending_start, current_start)
                pending_end = max(pending_end, current_end)
        if not inserted:
            merged.append(_FreeRange(pending_start, pending_end - pending_start))
        self._free_ranges[memory] = merged


@dataclass(frozen=True)
class ScalarResult:
    value: float
    value_bits: int
    index: Optional[int]
    operation: str
    trace: Mapping[str, object]

    def to_dict(self):
        return {
            "value": self.value,
            "value_bits": self.value_bits,
            "index": self.index,
            "operation": self.operation,
            "trace": dict(self.trace),
        }


class Tensor:
    """A live FP16 Tensor allocated automatically inside one Device."""

    def __init__(self, device: "Device", ref: BufferRef):
        self._device = device
        self._ref = ref
        self._released = False

    @property
    def name(self):
        return self._ref.name

    @property
    def shape(self):
        return self._ref.shape

    @property
    def dtype(self):
        return "float16"

    @property
    def size(self):
        return self._ref.element_count

    @property
    def constant(self):
        return self._ref.constant

    def valid(self):
        return (
            not self._released
            and not self._device.closed
            and self._device._allocator.contains(self.name, self._ref.generation)
        )

    def _require_live(self):
        if not self.valid():
            raise ReleasedTensorError(f"Tensor {self.name!r} is released or stale")

    def release(self):
        if self._released:
            return
        self._released = True
        if not self._device.closed and self._device._allocator.contains(
            self.name, self._ref.generation
        ):
            self._device._allocator.release(self.name, self._ref.generation)

    def bits(self):
        self._require_live()
        return self._device._session.read_tensor_bits(
            memory=self._ref.memory,
            offset=self._ref.element_offset,
            shape=self.shape,
        )

    def tolist(self):
        self._require_live()
        return self._device._session.read_tensor(
            memory=self._ref.memory,
            offset=self._ref.element_offset,
            shape=self.shape,
        )

    def numpy(self):
        try:
            import numpy as np
        except ImportError as error:
            raise ImportError("Tensor.numpy() requires NumPy in the application environment") from error
        return np.asarray(self.tolist(), dtype=np.float16)

    def item(self):
        if self.size != 1:
            raise ValueError("Tensor.item() requires exactly one element")
        value = self.tolist()
        while isinstance(value, list):
            value = value[0]
        return value

    def info(self):
        self._require_live()
        return {
            "name": self.name,
            "shape": self.shape,
            "dtype": self.dtype,
            "constant": self.constant,
        }

    def _internal_ref(self):
        self._require_live()
        return self._ref

    def __del__(self):
        try:
            self.release()
        except Exception:
            pass

    def __repr__(self):
        state = "live" if self.valid() else "released"
        return f"dexsim.Tensor(name={self.name!r}, shape={self.shape}, {state})"


class Device:
    """Address-free high-level interface backed by one persistent Session."""

    def __init__(self, session: Optional[Session] = None, *, timeout_cycles=400_000):
        self._session = session if session is not None else Session(timeout_cycles=timeout_cycles)
        self._owns_session = session is None
        self._allocator = VariableAllocator()
        self._closed = False
        self._next_tensor_id = 0
        self._next_command_id = 1
        self._trace: list[dict] = []

    @property
    def closed(self):
        return self._closed

    @property
    def session(self):
        self._require_open()
        return self._session

    def close(self):
        if self._closed:
            return
        self._allocator.reset()
        self._closed = True
        if self._owns_session:
            self._session.close()

    def __enter__(self):
        self._require_open()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
        return False

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass

    def _require_open(self):
        if self._closed:
            raise DexSimError("DexSim Device is closed")

    def _name(self, prefix):
        self._next_tensor_id += 1
        return f"{prefix}_{self._next_tensor_id}"

    def _command_id(self):
        value = self._next_command_id
        self._next_command_id = 1 if value == 0xFFF else value + 1
        return value

    def tensor(self, value, *, constant=False, name=None):
        self._require_open()
        flat, shape = _flatten(value)
        if not flat:
            raise ValueError("hardware Tensor cannot be empty")
        shape = (1,) if shape == () else _normalize_shape(shape)
        normalized = flat[0] if shape == (1,) and len(flat) == 1 else _reshape(flat, shape)
        ref = self._allocate(
            shape,
            name or self._name("const" if constant else "tensor"),
            constant=constant,
            preferred=("global", "local", "temp"),
        )
        try:
            self._session.write_tensor(
                memory=ref.memory,
                offset=ref.element_offset,
                value=normalized,
            )
        except Exception:
            self._allocator.release(ref.name, ref.generation)
            raise
        return Tensor(self, ref)

    def constant(self, value, *, name=None):
        return self.tensor(value, constant=True, name=name)

    def tensor_bits(self, value, *, shape=None, constant=False, name=None):
        self._require_open()
        flat, inferred_shape = _flatten_bits(value)
        if not flat:
            raise ValueError("hardware Tensor cannot be empty")
        inferred_shape = (1,) if inferred_shape == () else inferred_shape
        final_shape = _normalize_shape(shape if shape is not None else inferred_shape)
        if math.prod(final_shape) != len(flat):
            raise ValueError("explicit Tensor bit shape does not match element count")
        normalized = _reshape(flat, final_shape)
        ref = self._allocate(
            final_shape,
            name or self._name("const_bits" if constant else "tensor_bits"),
            constant=constant,
            preferred=("global", "local", "temp"),
        )
        try:
            self._session.write_tensor_bits(
                memory=ref.memory,
                offset=ref.element_offset,
                value=normalized,
            )
        except Exception:
            self._allocator.release(ref.name, ref.generation)
            raise
        return Tensor(self, ref)

    def empty(self, shape, *, name=None):
        self._require_open()
        ref = self._allocate(
            shape,
            name or self._name("empty"),
            constant=False,
            preferred=("local", "temp", "global"),
        )
        return Tensor(self, ref)

    def allocator_snapshot(self):
        return self._allocator.snapshot()

    def trace(self):
        return tuple(self._trace)

    def clear_trace(self):
        self._trace.clear()

    @staticmethod
    def capabilities():
        value = dict(Session.capabilities())
        value.update(
            high_level_operator_api=True,
            automatic_sram=True,
            public_memory_arguments=False,
            high_level_version="0.3.0",
        )
        return value

    def abs(self, source: Tensor):
        source_ref = self._ref(source)
        output = self.empty(source.shape, name=self._name("abs"))
        out_ref = output._internal_ref()
        command = build_abs(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=_storage_shape(source.shape)[0],
            cols=_storage_shape(source.shape)[1],
        )
        self._run("abs", command, [source_ref], out_ref)
        return output

    def scale(self, source: Tensor, alpha):
        source_ref = self._ref(source)
        output = self.empty(source.shape, name=self._name("scale"))
        out_ref = output._internal_ref()
        rows, cols = _storage_shape(source.shape)
        command = build_scale(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=rows,
            cols=cols,
            alpha_bits=fp16_bits(alpha),
        )
        self._run("scale", command, [source_ref], out_ref, attrs={"alpha": float(alpha)})
        return output

    mul = scale

    def add(self, left: Tensor, right: Tensor):
        left_ref = self._ref(left)
        right_ref = self._ref(right)
        if left.shape != right.shape:
            raise ValueError(f"ADD shape mismatch: {left.shape} vs {right.shape}")
        output = self.empty(left.shape, name=self._name("add"))
        out_ref = output._internal_ref()
        rows, cols = _storage_shape(left.shape)
        command = build_add(
            self._command_id(),
            a_memory=left_ref.memory,
            a_word_offset=left_ref.word_offset,
            b_memory=right_ref.memory,
            b_word_offset=right_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=rows,
            cols=cols,
        )
        self._run("add", command, [left_ref, right_ref], out_ref)
        return output

    def gemm(self, left: Tensor, right: Tensor):
        left_ref = self._ref(left)
        right_ref = self._ref(right)
        if len(left.shape) != 2 or len(right.shape) != 2:
            raise ValueError("GEMM requires two rank-2 Tensors")
        n_rows, k_dim = left.shape
        right_k, m_cols = right.shape
        if k_dim != right_k:
            raise ValueError(f"GEMM shape mismatch: {left.shape} @ {right.shape}")
        output = self.empty((n_rows, m_cols), name=self._name("gemm"))
        out_ref = output._internal_ref()
        command = build_gemm(
            self._command_id(),
            a_memory=left_ref.memory,
            a_word_offset=left_ref.word_offset,
            b_memory=right_ref.memory,
            b_word_offset=right_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            n_rows=n_rows,
            m_cols=m_cols,
            k_dim=k_dim,
        )
        self._run("gemm", command, [left_ref, right_ref], out_ref)
        return output

    def gemv(self, matrix: Tensor, vector: Tensor):
        matrix_ref = self._ref(matrix)
        vector_ref = self._ref(vector)
        if len(matrix.shape) != 2 or len(vector.shape) not in (1, 2):
            raise ValueError("GEMV requires a matrix and a vector")
        n_rows, k_dim = matrix.shape
        vector_length = vector.shape[0] if len(vector.shape) == 1 else (
            vector.shape[0] if vector.shape[1] == 1 else -1
        )
        if vector_length != k_dim:
            raise ValueError(f"GEMV shape mismatch: {matrix.shape} @ {vector.shape}")
        output = self.empty((n_rows,), name=self._name("gemv"))
        out_ref = output._internal_ref()
        command = build_gemv(
            self._command_id(),
            a_memory=matrix_ref.memory,
            a_word_offset=matrix_ref.word_offset,
            x_memory=vector_ref.memory,
            x_word_offset=vector_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            n_rows=n_rows,
            k_dim=k_dim,
        )
        self._run("gemv", command, [matrix_ref, vector_ref], out_ref)
        return output

    def dot(self, left: Tensor, right: Tensor):
        left_ref = self._ref(left)
        right_ref = self._ref(right)
        if len(left.shape) != 1 or left.shape != right.shape:
            raise ValueError("DOT requires equal rank-1 Tensors")
        output = self.empty((1,), name=self._name("dot"))
        out_ref = output._internal_ref()
        command = build_dot(
            self._command_id(),
            a_memory=left_ref.memory,
            a_word_offset=left_ref.word_offset,
            b_memory=right_ref.memory,
            b_word_offset=right_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            element_count=left.size,
        )
        self._run("dot", command, [left_ref, right_ref], out_ref)
        return output

    def outer(self, left: Tensor, right: Tensor):
        left_ref = self._ref(left)
        right_ref = self._ref(right)
        if len(left.shape) != 1 or len(right.shape) != 1:
            raise ValueError("OUTER requires two rank-1 Tensors")
        output = self.empty((left.size, right.size), name=self._name("outer"))
        out_ref = output._internal_ref()
        command = build_outer(
            self._command_id(),
            a_memory=left_ref.memory,
            a_word_offset=left_ref.word_offset,
            b_memory=right_ref.memory,
            b_word_offset=right_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            n_rows=left.size,
            m_cols=right.size,
        )
        self._run("outer", command, [left_ref, right_ref], out_ref)
        return output

    def sin(self, source: Tensor):
        return self._lut("sin", build_sin, source)

    def cos(self, source: Tensor):
        return self._lut("cos", build_cos, source)

    def softplus(self, source: Tensor):
        return self._lut("softplus", build_softplus, source)

    def softplus_beta(self, source: Tensor, beta):
        beta = float(beta)
        if beta <= 0:
            raise ValueError("softplus_beta beta must be positive")
        scaled = self.scale(source, beta)
        lut_value = self.softplus(scaled)
        output = self.scale(lut_value, 1.0 / beta)
        scaled.release()
        lut_value.release()
        return output

    def transpose(self, source: Tensor):
        source_ref = self._ref(source)
        if len(source.shape) != 2:
            raise ValueError("TRANSPOSE requires a rank-2 Tensor")
        rows, cols = source.shape
        output = self.empty((cols, rows), name=self._name("transpose"))
        out_ref = output._internal_ref()
        command = build_transpose(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=rows,
            cols=cols,
        )
        self._run("transpose", command, [source_ref], out_ref)
        return output

    def assemble(self, source: Tensor, *, offset_row, offset_col):
        source_ref = self._ref(source)
        if len(source.shape) != 2:
            raise ValueError("ASSEMBLE requires a rank-2 Tensor")
        offset_row = int(offset_row)
        offset_col = int(offset_col)
        if offset_row < 0 or offset_col < 0:
            raise ValueError("ASSEMBLE offsets must be non-negative")
        rows, cols = source.shape
        output_shape = (rows + offset_row, cols + offset_col)
        output = self.empty(output_shape, name=self._name("assemble"))
        out_ref = output._internal_ref()
        self._session.write_tensor_bits(
            memory=out_ref.memory,
            offset=out_ref.element_offset,
            value=_reshape([0] * math.prod(output_shape), output_shape),
        )
        command = build_assemble(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=rows,
            cols=cols,
            offset_row=offset_row,
            offset_col=offset_col,
        )
        self._run(
            "assemble",
            command,
            [source_ref],
            out_ref,
            attrs={"offset_row": offset_row, "offset_col": offset_col},
        )
        return output

    def add_reduce(self, source: Tensor):
        return self._reduce("add_reduce", build_add_reduce, source)

    reduce_add = add_reduce

    def compare_reduce(self, source: Tensor):
        return self._reduce("compare_reduce", build_compare_reduce, source)

    reduce_cmp = compare_reduce

    def _lut(self, name, builder, source):
        source_ref = self._ref(source)
        output = self.empty(source.shape, name=self._name(name))
        out_ref = output._internal_ref()
        rows, cols = _storage_shape(source.shape)
        command = builder(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            out_memory=out_ref.memory,
            out_word_offset=out_ref.word_offset,
            rows=rows,
            cols=cols,
        )
        self._run(name, command, [source_ref], out_ref)
        return output

    def _reduce(self, name, builder, source):
        source_ref = self._ref(source)
        command = builder(
            self._command_id(),
            src_memory=source_ref.memory,
            src_word_offset=source_ref.word_offset,
            element_count=source.size,
        )
        run, entry = self._run(name, command, [source_ref], None)
        result = run.command_results[0]
        if not result.reduce_valid or result.reduce_value_bits is None:
            raise DexSimError(f"{name} did not return a valid reduce result")
        return ScalarResult(
            value=float(result.reduce_value),
            value_bits=int(result.reduce_value_bits),
            index=int(result.reduce_index) if result.reduce_index is not None else None,
            operation=name,
            trace=entry,
        )

    def _ref(self, tensor):
        if not isinstance(tensor, Tensor):
            raise TypeError("high-level operators require dexsim.Tensor inputs")
        if tensor._device is not self:
            raise ValueError("Tensor belongs to a different DexSim Device")
        return tensor._internal_ref()

    def _allocate(self, shape, name, *, constant, preferred):
        shape = _normalize_shape(shape)
        try:
            return self._allocator.allocate(
                name,
                shape,
                constant=constant,
                preferred_memories=preferred,
            )
        except AllocationError as error:
            raise UnsupportedShapeError(
                f"automatic single-core placement failed for shape={tuple(shape)}; "
                "a validated tiling path is not available in v0.3.0"
            ) from error

    def _run(self, operation, command, inputs, output, attrs=None):
        run = self._session.run([command])
        entry = {
            "operation": operation,
            "inputs": [value.to_dict() for value in inputs],
            "output": output.to_dict() if output is not None else None,
            "attrs": dict(attrs or {}),
            "command": {
                "id": command.command_id,
                "opcode": command.opcode,
                "subop": command.subop,
                "group_end": command.group_end,
                "words": list(command.words),
            },
            "run": run.to_dict(),
        }
        self._trace.append(entry)
        return run, entry
