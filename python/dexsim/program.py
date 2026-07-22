"""Static fixed-operator Program capture and scheduling for dexmpc-sim."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
import math
import time
from typing import Mapping

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
from .operator_runtime import (
    BufferRef,
    UnsupportedShapeError,
    VariableAllocator,
    _flatten,
    _flatten_bits,
    _normalize_shape,
    _reshape,
    _storage_shape,
)
from .session import DexSimError, Session, fp16_bits, fp16_value
from .parallel import LINEAR_OPERATORS, execute_linear, plan_linear
from .resident import (
    ResidentKernelExecutor,
    choose_resident_decision,
    normalize_residency_policy,
)


@dataclass(frozen=True)
class TensorSpec:
    name: str
    shape: tuple[int, ...]
    dtype: str = "float16"
    role: str = "intermediate"

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class Op:
    kind: str
    inputs: tuple[str, ...]
    output: str
    attrs: Mapping[str, object]

    def to_dict(self):
        return {
            "kind": self.kind,
            "inputs": list(self.inputs),
            "output": self.output,
            "attrs": dict(self.attrs),
        }


class ProgramTensor:
    def __init__(self, program: "Program", name: str):
        self._program = program
        self.name = name

    @property
    def shape(self):
        return self._program._specs[self.name].shape

    @property
    def dtype(self):
        return "float16"

    def __repr__(self):
        return f"dexsim.ProgramTensor(name={self.name!r}, shape={self.shape})"


class ProgramScalar:
    def __init__(self, program: "Program", name: str, operation: str):
        self._program = program
        self.name = name
        self.operation = operation

    def __repr__(self):
        return f"dexsim.ProgramScalar(name={self.name!r}, operation={self.operation!r})"


@dataclass(frozen=True)
class ExecutionTrace:
    commands: tuple[Mapping[str, object], ...]
    buffers: Mapping[str, Mapping[str, object]]
    runs: tuple[Mapping[str, object], ...]
    cycles: int
    read_bytes: int
    write_bytes: int
    transfers: Mapping[str, int]
    host_ops: tuple[Mapping[str, object], ...] = ()
    residency: Mapping[str, object] = field(default_factory=dict)
    kernel_metrics: Mapping[str, object] = field(default_factory=dict)

    def to_dict(self):
        return {
            "commands": [dict(value) for value in self.commands],
            "buffers": {name: dict(value) for name, value in self.buffers.items()},
            "runs": [dict(value) for value in self.runs],
            "cycles": self.cycles,
            "read_bytes": self.read_bytes,
            "write_bytes": self.write_bytes,
            "transfers": dict(self.transfers),
            "host_ops": [dict(value) for value in self.host_ops],
            "residency": dict(self.residency),
            "kernel_metrics": dict(self.kernel_metrics),
        }


@dataclass(frozen=True)
class ProgramResult:
    outputs: Mapping[str, object]
    output_bits: Mapping[str, object]
    scalars: Mapping[str, Mapping[str, object]]
    trace: ExecutionTrace

    def to_dict(self):
        return {
            "outputs": dict(self.outputs),
            "output_bits": dict(self.output_bits),
            "scalars": {name: dict(value) for name, value in self.scalars.items()},
            "trace": self.trace.to_dict(),
        }


class Program:
    """A fixed graph whose operator composition is explicitly written by software."""

    def __init__(self, name="program"):
        self.name = str(name)
        self._specs: dict[str, TensorSpec] = {}
        self._constants: dict[str, object] = {}
        self._constant_bits: set[str] = set()
        self._ops: list[Op] = []
        self._scalars: dict[str, str] = {}
        self._outputs: tuple[str, ...] = ()
        self._next_id = 0

    def input(self, name, shape):
        name = self._new_name(str(name))
        self._specs[name] = TensorSpec(name, _normalize_shape(shape), role="input")
        return ProgramTensor(self, name)

    def constant(self, name, value):
        flat, shape = _flatten(value)
        if not flat:
            raise ValueError("Program constant cannot be empty")
        shape = (1,) if shape == () else _normalize_shape(shape)
        name = self._new_name(str(name))
        self._specs[name] = TensorSpec(name, shape, role="constant")
        self._constants[name] = _reshape(flat, shape)
        return ProgramTensor(self, name)

    def constant_bits(self, name, value, *, shape=None):
        flat, inferred_shape = _flatten_bits(value)
        if not flat:
            raise ValueError("Program constant cannot be empty")
        inferred_shape = (1,) if inferred_shape == () else inferred_shape
        final_shape = _normalize_shape(shape if shape is not None else inferred_shape)
        if math.prod(final_shape) != len(flat):
            raise ValueError("Program constant bit shape does not match element count")
        name = self._new_name(str(name))
        self._specs[name] = TensorSpec(name, final_shape, role="constant")
        self._constants[name] = _reshape(flat, final_shape)
        self._constant_bits.add(name)
        return ProgramTensor(self, name)

    def output(self, *values):
        if not values:
            raise ValueError("Program.output requires at least one value")
        names = []
        for value in values:
            self._require_value(value)
            names.append(value.name)
        self._outputs = tuple(names)
        return values[0] if len(values) == 1 else values

    def abs(self, source):
        return self._unary("abs", source)

    def scale(self, source, alpha):
        return self._unary("scale", source, alpha=float(alpha))

    mul = scale

    def add(self, left, right):
        self._require_tensor(left)
        self._require_tensor(right)
        if left.shape != right.shape:
            raise ValueError(f"ADD shape mismatch: {left.shape} vs {right.shape}")
        return self._record("add", (left, right), left.shape)

    def gemm(self, left, right):
        self._require_tensor(left)
        self._require_tensor(right)
        if len(left.shape) != 2 or len(right.shape) != 2:
            raise ValueError("GEMM requires two rank-2 ProgramTensors")
        n_rows, k_dim = left.shape
        right_k, m_cols = right.shape
        if k_dim != right_k:
            raise ValueError(f"GEMM shape mismatch: {left.shape} @ {right.shape}")
        return self._record("gemm", (left, right), (n_rows, m_cols))

    def gemv(self, matrix, vector):
        self._require_tensor(matrix)
        self._require_tensor(vector)
        if len(matrix.shape) != 2 or len(vector.shape) not in (1, 2):
            raise ValueError("GEMV requires a matrix and a vector")
        n_rows, k_dim = matrix.shape
        vector_length = vector.shape[0] if len(vector.shape) == 1 else (
            vector.shape[0] if vector.shape[1] == 1 else -1
        )
        if vector_length != k_dim:
            raise ValueError(f"GEMV shape mismatch: {matrix.shape} @ {vector.shape}")
        return self._record("gemv", (matrix, vector), (n_rows,))

    def dot(self, left, right):
        self._require_tensor(left)
        self._require_tensor(right)
        if len(left.shape) != 1 or left.shape != right.shape:
            raise ValueError("DOT requires equal rank-1 ProgramTensors")
        return self._record("dot", (left, right), (1,))

    def outer(self, left, right):
        self._require_tensor(left)
        self._require_tensor(right)
        if len(left.shape) != 1 or len(right.shape) != 1:
            raise ValueError("OUTER requires rank-1 ProgramTensors")
        return self._record("outer", (left, right), (left.shape[0], right.shape[0]))

    def sin(self, source):
        return self._unary("sin", source)

    def cos(self, source):
        return self._unary("cos", source)

    def softplus(self, source):
        return self._unary("softplus", source)

    def softplus_beta(self, source, beta):
        beta = float(beta)
        if beta <= 0:
            raise ValueError("softplus_beta beta must be positive")
        return self.scale(self.softplus(self.scale(source, beta)), 1.0 / beta)

    def transpose(self, source):
        self._require_tensor(source)
        if len(source.shape) != 2:
            raise ValueError("TRANSPOSE requires a rank-2 ProgramTensor")
        return self._record("transpose", (source,), (source.shape[1], source.shape[0]))

    def assemble(self, source, *, offset_row, offset_col):
        self._require_tensor(source)
        if len(source.shape) != 2:
            raise ValueError("ASSEMBLE requires a rank-2 ProgramTensor")
        offset_row = int(offset_row)
        offset_col = int(offset_col)
        if offset_row < 0 or offset_col < 0:
            raise ValueError("ASSEMBLE offsets must be non-negative")
        shape = (source.shape[0] + offset_row, source.shape[1] + offset_col)
        return self._record(
            "assemble",
            (source,),
            shape,
            offset_row=offset_row,
            offset_col=offset_col,
        )

    def add_reduce(self, source):
        return self._reduce("add_reduce", source)

    reduce_add = add_reduce

    def compare_reduce(self, source):
        return self._reduce("compare_reduce", source)

    reduce_cmp = compare_reduce

    def compile(
        self,
        *,
        session=None,
        timeout_cycles=400_000,
        execution_policy="auto",
        residency_policy="auto",
    ):
        if not self._outputs:
            raise ValueError("Program.output(...) must select at least one result before compile")
        return CompiledProgram(
            self,
            session=session,
            timeout_cycles=timeout_cycles,
            execution_policy=execution_policy,
            residency_policy=residency_policy,
        )

    def to_dict(self):
        return {
            "name": self.name,
            "specs": {name: spec.to_dict() for name, spec in self._specs.items()},
            "ops": [op.to_dict() for op in self._ops],
            "outputs": list(self._outputs),
        }

    def _new_name(self, requested=None):
        if requested:
            if requested in self._specs or requested in self._scalars:
                raise ValueError(f"duplicate Program value name {requested!r}")
            return requested
        while True:
            self._next_id += 1
            candidate = f"value_{self._next_id}"
            if candidate not in self._specs and candidate not in self._scalars:
                return candidate

    def _unary(self, kind, source, **attrs):
        self._require_tensor(source)
        return self._record(kind, (source,), source.shape, **attrs)

    def _record(self, kind, inputs, shape, **attrs):
        name = self._new_name()
        self._specs[name] = TensorSpec(name, _normalize_shape(shape))
        self._ops.append(Op(kind, tuple(value.name for value in inputs), name, attrs))
        return ProgramTensor(self, name)

    def _reduce(self, kind, source):
        self._require_tensor(source)
        name = self._new_name()
        self._scalars[name] = kind
        self._ops.append(Op(kind, (source.name,), name, {}))
        return ProgramScalar(self, name, kind)

    def _require_tensor(self, value):
        if not isinstance(value, ProgramTensor) or value._program is not self:
            raise TypeError("Program operators require ProgramTensor values from this Program")

    def _require_value(self, value):
        if isinstance(value, ProgramTensor) and value._program is self:
            return
        if isinstance(value, ProgramScalar) and value._program is self:
            return
        raise TypeError("Program output must belong to this Program")


class CompiledProgram:
    """Deterministically allocated command program for repeated execution."""

    def __init__(
        self,
        program: Program,
        *,
        session=None,
        timeout_cycles=400_000,
        execution_policy="auto",
        residency_policy="auto",
    ):
        if execution_policy not in ("single", "auto", "dual", "quad"):
            raise ValueError(
                "execution_policy must be 'single', 'auto', 'dual', or 'quad'"
            )
        residency_policy = normalize_residency_policy(residency_policy)
        self.name = program.name
        self._program = program
        self._session = session if session is not None else Session(
            cores=(0, 1, 2, 3), timeout_cycles=timeout_cycles
        )
        if 0 not in self._session.cores:
            raise ValueError("CompiledProgram Session must enable core0")
        self._owns_session = session is None
        self._execution_policy = execution_policy
        self._residency_policy = residency_policy
        self._resident_decision = choose_resident_decision(
            program,
            execution_policy=execution_policy,
            residency_policy=self._residency_policy,
        )
        self._persistent_constant_coverage = {}
        self._closed = False
        self._buffers: dict[str, BufferRef] = {}
        self._commands = []
        self._command_ops: list[Op] = []
        self._input_names = tuple(
            name for name, spec in program._specs.items() if spec.role == "input"
        )
        self._constant_names = tuple(program._constants)
        self._output_names = program._outputs
        self._scalar_names = set(program._scalars)
        self._assemble_outputs: set[str] = set()
        self._last_use = {}
        self._compile()
        self._upload_constants()

    @property
    def address_plan(self):
        return {name: ref.to_dict() for name, ref in self._buffers.items()}

    @property
    def command_count(self):
        return len(self._commands)

    @property
    def execution_config(self):
        return {
            "execution_policy": self._execution_policy,
            "residency_policy": self._residency_policy,
            "resident_decision": self._resident_decision.to_dict(),
        }

    def close(self):
        if self._closed:
            return
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

    def run(self, **inputs):
        self._require_open()
        if set(inputs) != set(self._input_names):
            missing = sorted(set(self._input_names) - set(inputs))
            extra = sorted(set(inputs) - set(self._input_names))
            raise ValueError(f"Program inputs mismatch; missing={missing}, extra={extra}")
        kernel_before = self._session._counters()
        wall_start = time.perf_counter()
        transfer_write_elements = 0
        for name in self._input_names:
            ref = self._buffers[name]
            flat, shape = _flatten(inputs[name])
            shape = (1,) if shape == () else shape
            if tuple(shape) != ref.shape:
                raise ValueError(
                    f"Program input {name!r} shape={shape}, expected {ref.shape}"
                )
            self._session.write_tensor(
                memory=ref.memory,
                offset=ref.element_offset,
                value=_reshape(flat, ref.shape),
            )
            transfer_write_elements += ref.element_count
        after_input_upload = self._session._counters()

        resident = ResidentKernelExecutor(
            self._session,
            self._buffers,
            self._program._specs,
            self._constant_names,
            decision=self._resident_decision,
            persistent_constant_coverage=self._persistent_constant_coverage,
        )
        resident.begin_run(self._input_names)

        # Execute at operator boundaries so output-space tiles form one scheduled
        # wave.  ASSEMBLE is zeroed immediately before its command because its
        # destination-preservation semantics can share a statically reused range.
        run_results = []
        operation_results = []
        parallel_records = []
        operation_metrics = []
        for op, command in zip(self._command_ops, self._commands):
            if op.kind == "assemble":
                ref = self._buffers[op.output]
                self._session.write_tensor_bits(
                    memory=ref.memory,
                    offset=ref.element_offset,
                    value=_reshape([0] * ref.element_count, ref.shape),
                )
                transfer_write_elements += ref.element_count
            if self._resident_decision.enabled:
                run, parallel, metrics = resident.execute(op, command)
                parallel_records.append(parallel)
                operation_metrics.append(metrics)
            elif op.kind in LINEAR_OPERATORS:
                attrs = dict(op.attrs)
                if op.kind == "scale":
                    attrs["alpha_bits"] = fp16_bits(op.attrs["alpha"])
                run, parallel = execute_linear(
                    self._session,
                    op.kind,
                    tuple(self._buffers[name] for name in op.inputs),
                    self._buffers[op.output],
                    command_id=command.command_id,
                    policy=self._execution_policy,
                    attrs=attrs,
                    group_end=command.group_end,
                )
                parallel_records.append(parallel)
                operation_metrics.append(parallel["metrics"])
            else:
                run = self._session.run([command])
                parallel_records.append(None)
                operation_metrics.append({
                    "total_cycles": run.total_cycles,
                    "total_read_bytes": run.total_read_bytes,
                    "total_write_bytes": run.total_write_bytes,
                })
            run_results.append(run)
            operation_results.append(tuple(run.command_results))
        after_operations = self._session._counters()

        outputs = {}
        output_bits = {}
        scalars = {}
        transfer_read_elements = 0
        command_index = {op.output: index for index, op in enumerate(self._command_ops)}
        if self._resident_decision.enabled:
            for name in self._output_names:
                if name not in self._scalar_names:
                    resident.materialize(name, reason="program_output")
        after_output_materialize = self._session._counters()
        for name in self._output_names:
            if name in self._scalar_names:
                result = operation_results[command_index[name]][0]
                if not result.reduce_valid or result.reduce_value_bits is None:
                    raise DexSimError(f"Program scalar output {name!r} is not valid")
                scalars[name] = {
                    "value": float(result.reduce_value),
                    "value_bits": int(result.reduce_value_bits),
                    "index": int(result.reduce_index) if result.reduce_index is not None else None,
                    "operation": self._program._scalars[name],
                }
                continue
            ref = self._buffers[name]
            bits = self._session.read_tensor_bits(
                memory=ref.memory,
                offset=ref.element_offset,
                shape=ref.shape,
            )
            output_bits[name] = bits
            flat_bits, _ = _flatten_bits(bits)
            outputs[name] = _reshape([fp16_value(value) for value in flat_bits], ref.shape)
            transfer_read_elements += ref.element_count
        after_output_read = self._session._counters()

        command_trace = []
        for op, command, results, parallel in zip(
            self._command_ops,
            self._commands,
            operation_results,
            parallel_records,
        ):
            commands = parallel["commands"] if parallel is not None else ({
                "core": 0,
                "id": command.command_id,
                "opcode": command.opcode,
                "subop": command.subop,
                "group_end": command.group_end,
                "words": list(command.words),
            },)
            for lowered, result in zip(commands, results):
                command_trace.append({
                    "operation": op.kind,
                    "inputs": list(op.inputs),
                    "output": op.output,
                    "attrs": dict(op.attrs),
                    **dict(lowered),
                    "result": result.to_dict(),
                    "parallel_plan": parallel["plan"] if parallel is not None else None,
                })
        resident_summary = resident.summary()
        kernel_metrics = {
            "total_cycles": int(after_output_read.cycle - kernel_before.cycle),
            "total_read_bytes": int(after_output_read.read_bytes - kernel_before.read_bytes),
            "total_write_bytes": int(after_output_read.write_bytes - kernel_before.write_bytes),
            "input_upload_cycles": int(after_input_upload.cycle - kernel_before.cycle),
            "operator_region_cycles": int(after_operations.cycle - after_input_upload.cycle),
            "output_materialize_cycles": int(
                after_output_materialize.cycle - after_operations.cycle
            ),
            "output_download_cycles": int(
                after_output_read.cycle - after_output_materialize.cycle
            ),
            "compute_only_cycles": int(resident_summary["metrics"]["compute_cycles"])
            if self._resident_decision.enabled
            else int(sum(
                value.get("run_cycles", value["total_cycles"])
                for value in operation_metrics
            )),
            "internal_transfer_cycles": int(
                resident_summary["metrics"]["resident_stage_cycles"]
                + resident_summary["metrics"]["materialize_cycles"]
            ) if self._resident_decision.enabled else int(sum(
                value.get("stage_cycles", 0) + value.get("gather_cycles", 0)
                for value in operation_metrics
            )),
            "wall_seconds": time.perf_counter() - wall_start,
        }
        trace = ExecutionTrace(
            commands=tuple(command_trace),
            buffers=self.address_plan,
            runs=tuple(run.to_dict() for run in run_results),
            cycles=sum(value["total_cycles"] for value in operation_metrics),
            read_bytes=sum(value["total_read_bytes"] for value in operation_metrics),
            write_bytes=sum(value["total_write_bytes"] for value in operation_metrics),
            transfers={
                "input_write_elements": transfer_write_elements,
                "output_read_elements": transfer_read_elements,
                "constant_write_elements_per_compile": sum(
                    self._buffers[name].element_count for name in self._constant_names
                ),
            },
            host_ops=(),
            residency=resident_summary,
            kernel_metrics=kernel_metrics,
        )
        return ProgramResult(outputs, output_bits, scalars, trace)

    def _compile(self):
        if len(self._program._ops) > 0xFFF:
            raise UnsupportedShapeError("Program exceeds the 12-bit command ID space")
        allocator = VariableAllocator()
        last_use = {}
        for index, op in enumerate(self._program._ops):
            for name in op.inputs:
                last_use[name] = index
        final_index = len(self._program._ops)
        for name in self._output_names:
            last_use[name] = final_index
        self._last_use = dict(last_use)

        try:
            for name, spec in self._program._specs.items():
                if spec.role not in ("input", "constant"):
                    continue
                preferred = (
                    ("local", "temp", "global")
                    if self._resident_decision.enabled
                    else ("global", "local", "temp")
                )
                self._buffers[name] = allocator.allocate(
                    name,
                    spec.shape,
                    constant=spec.role == "constant",
                    preferred_memories=preferred,
                )

            for index, op in enumerate(self._program._ops):
                if op.output in self._program._specs:
                    spec = self._program._specs[op.output]
                    self._buffers[op.output] = allocator.allocate(
                        op.output,
                        spec.shape,
                        preferred_memories=("local", "temp", "global"),
                    )
                command = self._build_command(op, index + 1, index == len(self._program._ops) - 1)
                self._commands.append(command)
                self._command_ops.append(op)
                if op.kind == "assemble":
                    self._assemble_outputs.add(op.output)
                for name in op.inputs:
                    spec = self._program._specs[name]
                    if (
                        last_use.get(name) == index
                        and spec.role != "constant"
                        and name not in self._output_names
                        and allocator.contains(name)
                    ):
                        allocator.release(name)
                if (
                    op.output in self._program._specs
                    and op.output not in last_use
                    and op.output not in self._output_names
                    and allocator.contains(op.output)
                ):
                    allocator.release(op.output)
        except UnsupportedShapeError:
            raise
        except Exception as error:
            raise UnsupportedShapeError(
                "fixed Program cannot be placed in validated SRAM; "
                "an automatic storage tiling path is not available in v0.4.1"
            ) from error

    def _build_command(self, op, command_id, group_end):
        refs = [self._buffers[name] for name in op.inputs]
        output = self._buffers.get(op.output)
        if op.kind == "abs":
            rows, cols = _storage_shape(refs[0].shape)
            return build_abs(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                             out_memory=output.memory, out_word_offset=output.word_offset,
                             rows=rows, cols=cols, group_end=group_end)
        if op.kind == "scale":
            rows, cols = _storage_shape(refs[0].shape)
            return build_scale(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                               out_memory=output.memory, out_word_offset=output.word_offset,
                               rows=rows, cols=cols, alpha_bits=fp16_bits(op.attrs["alpha"]), group_end=group_end)
        if op.kind == "add":
            rows, cols = _storage_shape(refs[0].shape)
            return build_add(command_id, a_memory=refs[0].memory, a_word_offset=refs[0].word_offset,
                             b_memory=refs[1].memory, b_word_offset=refs[1].word_offset,
                             out_memory=output.memory, out_word_offset=output.word_offset,
                             rows=rows, cols=cols, group_end=group_end)
        if op.kind == "gemm":
            n_rows, k_dim = refs[0].shape
            m_cols = refs[1].shape[1]
            return build_gemm(command_id, a_memory=refs[0].memory, a_word_offset=refs[0].word_offset,
                              b_memory=refs[1].memory, b_word_offset=refs[1].word_offset,
                              out_memory=output.memory, out_word_offset=output.word_offset,
                              n_rows=n_rows, m_cols=m_cols, k_dim=k_dim, group_end=group_end)
        if op.kind == "gemv":
            n_rows, k_dim = refs[0].shape
            return build_gemv(command_id, a_memory=refs[0].memory, a_word_offset=refs[0].word_offset,
                              x_memory=refs[1].memory, x_word_offset=refs[1].word_offset,
                              out_memory=output.memory, out_word_offset=output.word_offset,
                              n_rows=n_rows, k_dim=k_dim, group_end=group_end)
        if op.kind == "dot":
            return build_dot(command_id, a_memory=refs[0].memory, a_word_offset=refs[0].word_offset,
                             b_memory=refs[1].memory, b_word_offset=refs[1].word_offset,
                             out_memory=output.memory, out_word_offset=output.word_offset,
                             element_count=refs[0].element_count, group_end=group_end)
        if op.kind == "outer":
            return build_outer(command_id, a_memory=refs[0].memory, a_word_offset=refs[0].word_offset,
                               b_memory=refs[1].memory, b_word_offset=refs[1].word_offset,
                               out_memory=output.memory, out_word_offset=output.word_offset,
                               n_rows=refs[0].element_count, m_cols=refs[1].element_count, group_end=group_end)
        if op.kind in ("sin", "cos", "softplus"):
            rows, cols = _storage_shape(refs[0].shape)
            builder = {"sin": build_sin, "cos": build_cos, "softplus": build_softplus}[op.kind]
            return builder(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                           out_memory=output.memory, out_word_offset=output.word_offset,
                           rows=rows, cols=cols, group_end=group_end)
        if op.kind == "transpose":
            rows, cols = refs[0].shape
            return build_transpose(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                                   out_memory=output.memory, out_word_offset=output.word_offset,
                                   rows=rows, cols=cols, group_end=group_end)
        if op.kind == "assemble":
            rows, cols = refs[0].shape
            return build_assemble(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                                  out_memory=output.memory, out_word_offset=output.word_offset,
                                  rows=rows, cols=cols, offset_row=int(op.attrs["offset_row"]),
                                  offset_col=int(op.attrs["offset_col"]), group_end=group_end)
        if op.kind in ("add_reduce", "compare_reduce"):
            builder = build_add_reduce if op.kind == "add_reduce" else build_compare_reduce
            return builder(command_id, src_memory=refs[0].memory, src_word_offset=refs[0].word_offset,
                           element_count=refs[0].element_count, group_end=group_end)
        raise DexSimError(f"unsupported fixed Program op {op.kind!r}")

    def _upload_constants(self):
        for name in self._constant_names:
            ref = self._buffers[name]
            if name in self._program._constant_bits:
                self._session.write_tensor_bits(memory=ref.memory, offset=ref.element_offset,
                                                value=self._program._constants[name])
            else:
                self._session.write_tensor(memory=ref.memory, offset=ref.element_offset,
                                           value=self._program._constants[name])

    def _require_open(self):
        if self._closed:
            raise DexSimError("CompiledProgram is closed")
