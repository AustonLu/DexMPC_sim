"""High-level Python wrapper around the DexMPC C++ operator runtime."""

from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from typing import Iterable, Literal, Sequence

Transport = Literal["d2d", "spi"]
Matrix = Sequence[Sequence[int]]
Vector = Sequence[int]
Word = tuple[int, int, int, int]

MEM_GLOBAL = 0
MEM_LOCAL0 = 1
MEM_TEMP0 = 2


def _load_native(transport: Transport):
    if transport == "d2d":
        return import_module("dexmpc._native_d2d")
    if transport == "spi":
        return import_module("dexmpc._native_spi")
    raise ValueError(f"unsupported DexMPC transport: {transport!r}")


@dataclass(frozen=True)
class Tensor:
    """Python handle for a C++ OperatorTensor."""

    _native: object

    @property
    def info(self) -> dict:
        return self._native.info()

    @property
    def word_addr(self) -> int:
        return self._native.word_addr()

    def valid(self) -> bool:
        return self._native.valid()


class Device:
    """Python-facing DexMPC device using the C++ operator runtime."""

    def __init__(self, transport: Transport = "d2d", timeout_cycles: int = 1_200_000):
        self.transport = transport
        self._native_module = _load_native(transport)
        self._native = self._native_module.open_sim(timeout_cycles=timeout_cycles)

    @property
    def mem_global(self) -> int:
        return self._native_module.MEM_GLOBAL

    @property
    def mem_local0(self) -> int:
        return self._native_module.MEM_LOCAL0

    @property
    def mem_temp0(self) -> int:
        return self._native_module.MEM_TEMP0

    def reset_program(self, first_cmd_id: int = 0) -> None:
        self._native.reset_program(first_cmd_id)

    def reset_device(self) -> None:
        self._native.reset_device()

    def cycle(self) -> int:
        return self._native.cycle()

    def backend_kind(self) -> str:
        return self._native.backend_kind()

    def backend_transport(self) -> str:
        return self._native.transport()

    def read_status(self) -> dict:
        return self._native.read_status()

    def upload_matrix(self, matrix: Matrix, mem_id: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.upload_matrix(matrix, mem_id, name=name))

    def upload_vector(self, values: Vector, mem_id: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.upload_vector(values, mem_id, name=name))

    def upload_words(self, words: Iterable[Word], mem_id: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.upload_words(list(words), mem_id, name=name))

    def empty_matrix(self, mem_id: int, rows: int, cols: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.empty_matrix(mem_id, rows, cols, name=name))

    def empty_vector(self, mem_id: int, elem_count: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.empty_vector(mem_id, elem_count, name=name))

    def empty_words(self, mem_id: int, word_count: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.empty_words(mem_id, word_count, name=name))

    def download_matrix(self, tensor: Tensor) -> list[list[int]]:
        return self._native.download_matrix(tensor._native)

    def download_vector(self, tensor: Tensor) -> list[int]:
        return self._native.download_vector(tensor._native)

    def download_words(self, tensor: Tensor) -> list[Word]:
        return self._native.download_words(tensor._native)

    def write_words(self, tensor: Tensor, words: Iterable[Word]) -> None:
        self._native.write_words(tensor._native, list(words))

    def write_register(self, reg_idx: int, value: int) -> None:
        self._native.write_register(reg_idx, value)

    def read_register(self, reg_idx: int) -> int:
        return self._native.read_register(reg_idx)

    def write_memory(self, mem_id: int, word_addr: int, words: Iterable[Word]) -> None:
        self._native.write_memory(mem_id, word_addr, list(words))

    def read_memory(self, mem_id: int, word_addr: int, word_count: int) -> list[Word]:
        return self._native.read_memory(mem_id, word_addr, word_count)

    def bind_existing_matrix(
        self,
        mem_id: int,
        word_addr: int,
        rows: int,
        cols: int,
        name: str | None = None,
    ) -> Tensor:
        return Tensor(self._native.bind_existing_matrix(mem_id, word_addr, rows, cols, name=name))

    def bind_existing_vector(
        self,
        mem_id: int,
        word_addr: int,
        elem_count: int,
        name: str | None = None,
    ) -> Tensor:
        return Tensor(self._native.bind_existing_vector(mem_id, word_addr, elem_count, name=name))

    def bind_existing_words(
        self,
        mem_id: int,
        word_addr: int,
        word_count: int,
        name: str | None = None,
    ) -> Tensor:
        return Tensor(self._native.bind_existing_words(mem_id, word_addr, word_count, name=name))

    def abs(self, src: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.abs(src._native, dst_mem, name=name))

    def transpose(self, src: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.transpose(src._native, dst_mem, name=name))

    def layout_assemble(
        self,
        src: Tensor,
        dst_mem: int,
        dst_rows: int,
        dst_cols: int,
        offset_row: int,
        offset_col: int,
        name: str | None = None,
    ) -> Tensor:
        return Tensor(
            self._native.layout_assemble(
                src._native, dst_mem, dst_rows, dst_cols, offset_row, offset_col, name=name
            )
        )

    def layout_assemble_into(
        self,
        src: Tensor,
        dst: Tensor,
        offset_row: int,
        offset_col: int,
    ) -> None:
        self._native.layout_assemble_into(src._native, dst._native, offset_row, offset_col)

    def gemm(self, a: Tensor, b: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.gemm(a._native, b._native, dst_mem, name=name))

    def add(self, a: Tensor, b: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.add(a._native, b._native, dst_mem, name=name))

    def mul(self, a: Tensor, alpha: int, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.mul(a._native, alpha, dst_mem, name=name))

    def lut_sin(self, src: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.lut_sin(src._native, dst_mem, name=name))

    def lut_cos(self, src: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.lut_cos(src._native, dst_mem, name=name))

    def lut_softplus(self, src: Tensor, dst_mem: int, name: str | None = None) -> Tensor:
        return Tensor(self._native.lut_softplus(src._native, dst_mem, name=name))

    def reduce_add(self, src: Tensor) -> dict:
        return self._native.reduce_add(src._native)

    def reduce_cmp(self, src: Tensor) -> dict:
        return self._native.reduce_cmp(src._native)


def open_sim(transport: Transport = "d2d", timeout_cycles: int = 1_200_000) -> Device:
    return Device(transport=transport, timeout_cycles=timeout_cycles)
