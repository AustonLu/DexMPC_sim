#!/usr/bin/env python3
"""Python-interface tests ported from the DexMPC C++ runtime tests."""

from __future__ import annotations

import argparse
import gc
import unittest
from dataclasses import dataclass
from typing import Iterable

import dexmpc


FP16_ZERO = 0x0000
FP16_HALF = 0x3800
FP16_ONE = 0x3C00
FP16_TWO = 0x4000
FP16_THREE = 0x4200
FP16_FOUR = 0x4400
FP16_FIVE = 0x4500
FP16_SIX = 0x4600
FP16_SEVEN = 0x4700
FP16_EIGHT = 0x4800
FP16_SIXTEEN = 0x4C00
FP16_NEG_HALF = 0xB800
FP16_NEG_ONE = 0xBC00
FP16_NEG_TWO = 0xC000
FP16_NEG_THREE = 0xC200
FP16_NEG_FIVE = 0xC500

CFG_CMD_WORD00 = 0

Word = tuple[int, int, int, int]
Matrix = list[list[int]]


def make_matrix(rows: int, cols: int, fill: int = 0) -> Matrix:
    return [[fill for _ in range(cols)] for _ in range(rows)]


def pick_pos_fp(idx: int) -> int:
    return [
        FP16_HALF,
        FP16_ONE,
        FP16_TWO,
        FP16_THREE,
        FP16_FOUR,
        FP16_FIVE,
        FP16_SIX,
        FP16_SEVEN,
        FP16_EIGHT,
    ][idx % 9]


def pick_abs_fp(idx: int) -> int:
    return [
        FP16_NEG_ONE,
        FP16_TWO,
        FP16_NEG_THREE,
        FP16_FOUR,
        FP16_NEG_FIVE,
        FP16_HALF,
        FP16_NEG_HALF,
        FP16_EIGHT,
        FP16_NEG_TWO,
        FP16_ONE,
    ][idx % 10]


def fill_pattern_matrix(rows: int, cols: int, seed: int, use_abs_pattern: bool) -> Matrix:
    pick = pick_abs_fp if use_abs_pattern else pick_pos_fp
    return [[pick(seed + r * cols + c) for c in range(cols)] for r in range(rows)]


def abs_expected(src: Matrix) -> Matrix:
    return [[value & 0x7FFF for value in row] for row in src]


def transpose_expected(src: Matrix) -> Matrix:
    return [list(row) for row in zip(*src)]


def assemble_expected(src: Matrix, dst_pre: Matrix, offset_row: int, offset_col: int) -> Matrix:
    out = [row[:] for row in dst_pre]
    for r, row in enumerate(src):
        for c, value in enumerate(row):
            out[offset_row + r][offset_col + c] = value
    return out


def identity_matrix(rows: int) -> Matrix:
    return [[FP16_ONE if r == c else FP16_ZERO for c in range(rows)] for r in range(rows)]


def reduce_add_expected(length: int) -> int:
    mapping = {4: FP16_FOUR, 8: FP16_EIGHT, 16: FP16_SIXTEEN}
    return mapping[length]


def open_test_device(transport: str) -> dexmpc.Device:
    dev = dexmpc.open_sim(transport)
    dev.reset_program()
    dev.reset_device()
    return dev


@dataclass(frozen=True)
class OperatorCase:
    kind: str
    args: tuple[int, ...]


MIXED_CASES: tuple[OperatorCase, ...] = (
    OperatorCase("gemm_identity", (dexmpc.MEM_GLOBAL, dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, 16, 16, 1000)),
    OperatorCase("abs", (dexmpc.MEM_GLOBAL, dexmpc.MEM_LOCAL0, 3, 5, 1100)),
    OperatorCase("reduce_add", (dexmpc.MEM_TEMP0, 8)),
    OperatorCase("transpose", (dexmpc.MEM_LOCAL0, dexmpc.MEM_GLOBAL, 3, 4, 1200)),
    OperatorCase("mul_copy", (dexmpc.MEM_GLOBAL, dexmpc.MEM_TEMP0, 3, 6, 1300)),
    OperatorCase("reduce_cmp", (dexmpc.MEM_LOCAL0, 7, 3, 1400)),
    OperatorCase("assemble", (dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, 2, 3, 1, 2, 1500)),
    OperatorCase("add_zero", (dexmpc.MEM_GLOBAL, dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, 4, 4, 1600)),
    OperatorCase("abs", (dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, 2, 7, 1700)),
    OperatorCase("reduce_add", (dexmpc.MEM_GLOBAL, 4)),
    OperatorCase("gemm_identity", (dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, 8, 6, 1800)),
    OperatorCase("transpose", (dexmpc.MEM_GLOBAL, dexmpc.MEM_TEMP0, 2, 6, 1900)),
    OperatorCase("abs", (dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, 4, 3, 2000)),
    OperatorCase("reduce_cmp", (dexmpc.MEM_GLOBAL, 8, 5, 2100)),
    OperatorCase("mul_copy", (dexmpc.MEM_TEMP0, dexmpc.MEM_LOCAL0, 5, 3, 2200)),
    OperatorCase("assemble", (dexmpc.MEM_GLOBAL, dexmpc.MEM_LOCAL0, 3, 2, 2, 1, 2300)),
    OperatorCase("abs", (dexmpc.MEM_GLOBAL, dexmpc.MEM_GLOBAL, 1, 8, 2400)),
    OperatorCase("add_zero", (dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, 3, 5, 2500)),
    OperatorCase("reduce_add", (dexmpc.MEM_LOCAL0, 16)),
    OperatorCase("transpose", (dexmpc.MEM_TEMP0, dexmpc.MEM_LOCAL0, 4, 2, 2600)),
    OperatorCase("gemm_identity", (dexmpc.MEM_GLOBAL, dexmpc.MEM_TEMP0, dexmpc.MEM_LOCAL0, 4, 7, 2700)),
    OperatorCase("reduce_cmp", (dexmpc.MEM_TEMP0, 5, 1, 2800)),
    OperatorCase("abs", (dexmpc.MEM_TEMP0, dexmpc.MEM_LOCAL0, 5, 2, 2900)),
    OperatorCase("assemble", (dexmpc.MEM_LOCAL0, dexmpc.MEM_TEMP0, 2, 4, 1, 1, 3000)),
    OperatorCase("mul_copy", (dexmpc.MEM_LOCAL0, dexmpc.MEM_GLOBAL, 2, 8, 3100)),
    OperatorCase("reduce_add", (dexmpc.MEM_TEMP0, 8)),
    OperatorCase("add_zero", (dexmpc.MEM_GLOBAL, dexmpc.MEM_TEMP0, dexmpc.MEM_LOCAL0, 2, 6, 3200)),
    OperatorCase("transpose", (dexmpc.MEM_LOCAL0, dexmpc.MEM_GLOBAL, 3, 3, 3300)),
    OperatorCase("abs", (dexmpc.MEM_GLOBAL, dexmpc.MEM_TEMP0, 6, 2, 3400)),
    OperatorCase("reduce_cmp", (dexmpc.MEM_LOCAL0, 9, 7, 3500)),
    OperatorCase("assemble", (dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, 3, 3, 1, 3, 3600)),
    OperatorCase("abs", (dexmpc.MEM_LOCAL0, dexmpc.MEM_GLOBAL, 2, 5, 3700)),
    OperatorCase("add_zero", (dexmpc.MEM_TEMP0, dexmpc.MEM_GLOBAL, dexmpc.MEM_LOCAL0, 4, 3, 3800)),
    OperatorCase("reduce_cmp", (dexmpc.MEM_GLOBAL, 6, 2, 3900)),
)


class PythonInterfaceLayerTest(unittest.TestCase):
    transport = "d2d"
    mixed_case_limit = 0

    def setUp(self) -> None:
        self.dev = open_test_device(self.transport)

    def case_name(self, idx: int, role: str) -> str:
        return f"py_{self.transport}_case_{idx}_{role}"

    def assert_matrix_equal(self, got: Matrix, expected: Matrix, label: str) -> None:
        self.assertEqual(len(got), len(expected), f"{label} row count")
        for r, expected_row in enumerate(expected):
            self.assertEqual(len(got[r]), len(expected_row), f"{label} col count row {r}")
            self.assertEqual(got[r], expected_row, f"{label} row {r}")

    def test_backend_smoke_via_python(self) -> None:
        self.assertEqual(self.dev.backend_kind(), "sim_model")
        self.assertEqual(self.dev.backend_transport(), self.transport)

        reg_pattern = 0x12345678 if self.transport == "d2d" else 0x5AA55AA5
        self.dev.write_register(CFG_CMD_WORD00, reg_pattern)
        self.assertEqual(self.dev.read_register(CFG_CMD_WORD00), reg_pattern)

        words: Iterable[tuple[int, int, Word]] = (
            (self.dev.mem_global, 0, (0x01234567, 0x89ABCDEF, 0x13579BDF, 0xFEDCBA98)),
            (self.dev.mem_local0, 3, (0x10203040, 0x50607080, 0x90A0B0C0, 0xD0E0F001)),
            (self.dev.mem_temp0, 5, (0x0BADCAFE, 0x55AA55AA, 0xA5A5F00D, 0x11223344)),
        )
        for mem_id, word_addr, word in words:
            with self.subTest(mem_id=mem_id):
                self.dev.write_memory(mem_id, word_addr, [word])
                self.assertEqual(self.dev.read_memory(mem_id, word_addr, 1), [word])

        status = self.dev.read_status()
        self.assertIn("done_count", status)
        self.assertGreaterEqual(self.dev.cycle(), 0)

    def test_tensor_lifecycle_and_allocator_reuse(self) -> None:
        raw_word: Word = (1, 2, 3, 4)
        self.dev.write_memory(self.dev.mem_temp0, 0, [raw_word])
        self.assertEqual(self.dev.read_memory(self.dev.mem_temp0, 0, 1), [raw_word])

        tensor = self.dev.empty_words(self.dev.mem_global, 2, "py_scoped_words")
        self.assertEqual(tensor.word_addr, 0)
        self.assertTrue(tensor.valid())
        del tensor
        gc.collect()

        reused = self.dev.empty_words(self.dev.mem_global, 2, "py_reused_words")
        self.assertEqual(reused.word_addr, 0)
        del reused
        gc.collect()

        bound = self.dev.bind_existing_words(self.dev.mem_temp0, 4, 2, "py_bound_words")
        self.assertEqual(bound.word_addr, 4)
        del bound
        gc.collect()

        rebound = self.dev.empty_words(self.dev.mem_temp0, 2, "py_rebound_words")
        self.assertEqual(rebound.word_addr, 4)

        before_reset = self.dev.empty_words(self.dev.mem_global, 1, "py_before_reset")
        self.assertTrue(before_reset.valid())
        self.dev.reset_program()
        self.assertFalse(before_reset.valid())

    def test_upload_download_and_error_paths(self) -> None:
        matrix = [[FP16_ONE, FP16_TWO], [FP16_THREE, FP16_FOUR]]
        tensor = self.dev.upload_matrix(matrix, self.dev.mem_global, "py_matrix")
        self.assertEqual(tensor.info["rows"], 2)
        self.assertEqual(tensor.info["cols"], 2)
        self.assert_matrix_equal(self.dev.download_matrix(tensor), matrix, "matrix round trip")

        vector = [FP16_ONE, FP16_TWO, FP16_THREE]
        vector_tensor = self.dev.upload_vector(vector, self.dev.mem_temp0, "py_vector")
        self.assertEqual(self.dev.download_vector(vector_tensor), vector)

        with self.assertRaises(RuntimeError):
            self.dev.upload_matrix([[FP16_ONE], [FP16_TWO, FP16_THREE]], self.dev.mem_global)
        with self.assertRaises(RuntimeError):
            self.dev.upload_vector([], self.dev.mem_global)
        with self.assertRaises(RuntimeError):
            self.dev.empty_matrix(self.dev.mem_global, 0, 1)

    def test_operator_runtime_abs_smoke_and_release_reuse(self) -> None:
        src = [
            [FP16_ONE, FP16_TWO, FP16_NEG_THREE, FP16_FOUR],
            [FP16_FIVE, 0xC600, FP16_SEVEN, FP16_NEG_ONE],
        ]
        expected = [
            [FP16_ONE, FP16_TWO, 0x4200, FP16_FOUR],
            [FP16_FIVE, 0x4600, FP16_SEVEN, FP16_ONE],
        ]
        input_tensor = self.dev.upload_matrix(src, self.dev.mem_global, "py_abs_input")
        output = self.dev.abs(input_tensor, self.dev.mem_local0, "py_abs_output")
        released_base = output.word_addr
        self.assert_matrix_equal(self.dev.download_matrix(output), expected, "abs smoke")
        del output
        gc.collect()

        reused = self.dev.empty_matrix(self.dev.mem_local0, 2, 4, "py_abs_reused")
        self.assertEqual(reused.word_addr, released_base)

    def test_operator_mixed_cases(self) -> None:
        cases = MIXED_CASES
        if self.mixed_case_limit > 0:
            cases = cases[: self.mixed_case_limit]

        for idx, case in enumerate(cases):
            with self.subTest(transport=self.transport, case=idx, kind=case.kind):
                self.dev.reset_program(idx)
                self.run_operator_case(idx, case)

    def run_operator_case(self, idx: int, case: OperatorCase) -> None:
        if case.kind == "abs":
            src_mem, dst_mem, rows, cols, seed = case.args
            src_matrix = fill_pattern_matrix(rows, cols, seed, True)
            src = self.dev.upload_matrix(src_matrix, src_mem, self.case_name(idx, "src"))
            dst = self.dev.abs(src, dst_mem, self.case_name(idx, "dst"))
            self.assert_matrix_equal(self.dev.download_matrix(dst), abs_expected(src_matrix), self.case_name(idx, "abs"))
            return

        if case.kind == "transpose":
            src_mem, dst_mem, rows, cols, seed = case.args
            src_matrix = fill_pattern_matrix(rows, cols, seed, False)
            src = self.dev.upload_matrix(src_matrix, src_mem, self.case_name(idx, "src"))
            dst = self.dev.transpose(src, dst_mem, self.case_name(idx, "dst"))
            self.assert_matrix_equal(self.dev.download_matrix(dst), transpose_expected(src_matrix), self.case_name(idx, "transpose"))
            return

        if case.kind == "assemble":
            src_mem, dst_mem, src_rows, src_cols, off_r, off_c, seed = case.args
            dst_rows = src_rows + off_r
            dst_cols = src_cols + off_c
            src_matrix = fill_pattern_matrix(src_rows, src_cols, seed, False)
            dst_pre = fill_pattern_matrix(dst_rows, dst_cols, seed + 131, False)
            src = self.dev.upload_matrix(src_matrix, src_mem, self.case_name(idx, "src"))
            dst = self.dev.upload_matrix(dst_pre, dst_mem, self.case_name(idx, "dst"))
            self.dev.layout_assemble_into(src, dst, off_r, off_c)
            expected = assemble_expected(src_matrix, dst_pre, off_r, off_c)
            self.assert_matrix_equal(self.dev.download_matrix(dst), expected, self.case_name(idx, "assemble"))
            return

        if case.kind == "reduce_add":
            src_mem, length = case.args
            src = self.dev.upload_vector([FP16_ONE] * length, src_mem, self.case_name(idx, "src"))
            result = self.dev.reduce_add(src)
            self.assertEqual(result, {"value": reduce_add_expected(length), "index": 0})
            return

        if case.kind == "reduce_cmp":
            src_mem, length, min_idx, seed = case.args
            vec = []
            for i in range(length):
                value = pick_pos_fp(seed + i + 2)
                vec.append(FP16_THREE if value == FP16_HALF else value)
            vec[min_idx] = FP16_HALF
            src = self.dev.upload_vector(vec, src_mem, self.case_name(idx, "src"))
            result = self.dev.reduce_cmp(src)
            self.assertEqual(result, {"value": FP16_HALF, "index": min_idx})
            return

        if case.kind == "gemm_identity":
            a_mem, b_mem, c_mem, n_rows, m_cols, seed = case.args
            a_matrix = identity_matrix(n_rows)
            b_matrix = fill_pattern_matrix(n_rows, m_cols, seed, False)
            a = self.dev.upload_matrix(a_matrix, a_mem, self.case_name(idx, "a"))
            b = self.dev.upload_matrix(b_matrix, b_mem, self.case_name(idx, "b"))
            c = self.dev.gemm(a, b, c_mem, self.case_name(idx, "c"))
            self.assert_matrix_equal(self.dev.download_matrix(c), b_matrix, self.case_name(idx, "gemm"))
            return

        if case.kind == "mul_copy":
            a_mem, c_mem, rows, cols, seed = case.args
            a_matrix = fill_pattern_matrix(rows, cols, seed, False)
            a = self.dev.upload_matrix(a_matrix, a_mem, self.case_name(idx, "a"))
            c = self.dev.mul(a, FP16_ONE, c_mem, self.case_name(idx, "c"))
            self.assert_matrix_equal(self.dev.download_matrix(c), a_matrix, self.case_name(idx, "mul"))
            return

        if case.kind == "add_zero":
            a_mem, b_mem, c_mem, rows, cols, seed = case.args
            a_matrix = fill_pattern_matrix(rows, cols, seed, False)
            b_matrix = make_matrix(rows, cols)
            a = self.dev.upload_matrix(a_matrix, a_mem, self.case_name(idx, "a"))
            b = self.dev.upload_matrix(b_matrix, b_mem, self.case_name(idx, "b"))
            c = self.dev.add(a, b, c_mem, self.case_name(idx, "c"))
            self.assert_matrix_equal(self.dev.download_matrix(c), a_matrix, self.case_name(idx, "add"))
            return

        raise AssertionError(f"unknown operator case kind: {case.kind}")


def suite_for_transport(transport: str, mixed_case_limit: int) -> unittest.TestSuite:
    class TransportSuite(PythonInterfaceLayerTest):
        pass

    TransportSuite.__name__ = f"PythonInterfaceLayer_{transport.upper()}"
    TransportSuite.transport = transport
    TransportSuite.mixed_case_limit = mixed_case_limit
    return unittest.defaultTestLoader.loadTestsFromTestCase(TransportSuite)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--transport", choices=("d2d", "spi", "all"), default="d2d")
    parser.add_argument("--mixed-case-limit", type=int, default=0)
    args = parser.parse_args()

    transports = ("d2d", "spi") if args.transport == "all" else (args.transport,)
    suite = unittest.TestSuite()
    for transport in transports:
        suite.addTests(suite_for_transport(transport, args.mixed_case_limit))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
