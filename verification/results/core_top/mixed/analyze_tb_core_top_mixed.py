#!/usr/bin/env python3
import argparse
import csv
import math
import struct
import sys
from pathlib import Path

try:
    import numpy as np
    _HAS_NUMPY = True
except Exception:
    _HAS_NUMPY = False


LANES_PER_WORD = 8
MAX_REDUCE_ELEMS = 32


def parse_bin(text: str) -> int:
    txt = text.strip()
    if txt == "":
        return 0
    txt = txt.replace("x", "0").replace("X", "0").replace("z", "0").replace("Z", "0")
    return int(txt, 2)


def has_unknown(text: str) -> bool:
    txt = text.strip().lower()
    return ("x" in txt) or ("z" in txt)


def bin16(value: int) -> str:
    return f"{value & 0xFFFF:016b}"


def bin12(value: int) -> str:
    return f"{value & 0xFFF:012b}"


def fmt_float(value: float) -> str:
    if math.isnan(value):
        return "nan"
    if math.isinf(value):
        return "inf" if value > 0 else "-inf"
    return f"{value:.10g}"


def fp16_bits_to_float(bits: int) -> float:
    if _HAS_NUMPY:
        return np.frombuffer(np.uint16(bits & 0xFFFF).tobytes(), dtype=np.float16)[0].item()
    s = (bits >> 15) & 0x1
    e = (bits >> 10) & 0x1F
    f = bits & 0x3FF
    if e == 0:
        if f == 0:
            return -0.0 if s else 0.0
        return (-1.0 if s else 1.0) * (2.0 ** -14) * (f / 1024.0)
    if e == 31:
        if f == 0:
            return float("-inf") if s else float("inf")
        return float("nan")
    return (-1.0 if s else 1.0) * (2.0 ** (e - 15)) * (1.0 + f / 1024.0)


def float_to_fp16_bits(value: float) -> int:
    if _HAS_NUMPY:
        return np.frombuffer(np.float16(value).tobytes(), dtype=np.uint16)[0].item()

    f32 = struct.unpack(">I", struct.pack(">f", float(value)))[0]
    sign = (f32 >> 31) & 0x1
    exp = (f32 >> 23) & 0xFF
    frac = f32 & 0x7FFFFF

    if exp == 0xFF:
        if frac == 0:
            return (sign << 15) | 0x7C00
        return (sign << 15) | 0x7E00

    exp16 = exp - 127 + 15
    if exp16 >= 31:
        return (sign << 15) | 0x7C00
    if exp16 <= 0:
        if exp16 < -10:
            return sign << 15
        mant = frac | 0x800000
        shift = 1 - exp16
        total_shift = 13 + shift
        mant16 = mant >> total_shift
        round_bit = (mant >> (total_shift - 1)) & 0x1
        sticky = mant & ((1 << (total_shift - 1)) - 1)
        if round_bit and (sticky or (mant16 & 0x1)):
            mant16 += 1
        return (sign << 15) | (mant16 & 0x3FF)

    mant16 = frac >> 13
    round_bit = (frac >> 12) & 0x1
    sticky = frac & 0xFFF
    if round_bit and (sticky or (mant16 & 0x1)):
        mant16 += 1
        if mant16 == 0x400:
            mant16 = 0
            exp16 += 1
            if exp16 >= 31:
                return (sign << 15) | 0x7C00
    return (sign << 15) | (exp16 << 10) | (mant16 & 0x3FF)


def add_fp16_bits(a_bits: int, b_bits: int) -> int:
    return float_to_fp16_bits(fp16_bits_to_float(a_bits) + fp16_bits_to_float(b_bits))


def mul_fp16_bits(a_bits: int, b_bits: int) -> int:
    return float_to_fp16_bits(fp16_bits_to_float(a_bits) * fp16_bits_to_float(b_bits))


def mac_fp16_bits(acc_bits: int, a_bits: int, b_bits: int) -> int:
    prod_bits = mul_fp16_bits(a_bits, b_bits)
    return add_fp16_bits(acc_bits, prod_bits)


def order_key(bits: int) -> int:
    bits &= 0xFFFF
    if bits & 0x8000:
        return (~bits) & 0xFFFF
    return bits ^ 0x8000


def collect_prefixed_bits(row: dict[str, str], prefix: str) -> list[int]:
    values = []
    idx = 0
    while True:
        key = f"{prefix}_{idx}_bin"
        if key not in row:
            break
        values.append(parse_bin(row[key]))
        idx += 1
    return values


def unpack_words(word_list: list[int], total_elems: int) -> list[int]:
    elems = []
    for word in word_list:
        for lane in range(LANES_PER_WORD):
            if len(elems) >= total_elems:
                return elems
            elems.append((word >> (lane * 16)) & 0xFFFF)
    if len(elems) < total_elems:
        elems += [0] * (total_elems - len(elems))
    return elems


def words_to_matrix(word_list: list[int], rows: int, cols: int) -> list[list[int]]:
    elems = unpack_words(word_list, rows * cols)
    return [elems[r * cols:(r + 1) * cols] for r in range(rows)]


def abs_expected(src: list[list[int]]) -> list[list[int]]:
    return [[value & 0x7FFF for value in row] for row in src]


def transpose_expected(src: list[list[int]], dst_pre: list[list[int]]) -> list[list[int]]:
    dst_rows = len(dst_pre)
    dst_cols = len(dst_pre[0]) if dst_rows else 0
    out = [row[:] for row in dst_pre]
    src_rows = len(src)
    src_cols = len(src[0]) if src_rows else 0
    for sr in range(src_rows):
        for sc in range(src_cols):
            dr = sc
            dc = sr
            if dr < dst_rows and dc < dst_cols:
                out[dr][dc] = src[sr][sc]
    return out


def assemble_expected(
    src: list[list[int]],
    dst_pre: list[list[int]],
    offset_row: int,
    offset_col: int,
) -> list[list[int]]:
    out = [row[:] for row in dst_pre]
    src_rows = len(src)
    src_cols = len(src[0]) if src_rows else 0
    dst_rows = len(out)
    dst_cols = len(out[0]) if dst_rows else 0
    for sr in range(src_rows):
        for sc in range(src_cols):
            dr = offset_row + sr
            dc = offset_col + sc
            if dr < dst_rows and dc < dst_cols:
                out[dr][dc] = src[sr][sc]
    return out


def compute_expected_gemm(a: list[list[int]], b: list[list[int]]) -> list[list[int]]:
    n_rows = len(a)
    k_dim = len(a[0]) if n_rows else 0
    k_b = len(b)
    m_cols = len(b[0]) if k_b else 0
    if k_dim != k_b:
        raise ValueError(f"GEMM shape mismatch: A={n_rows}x{k_dim}, B={k_b}x{m_cols}")
    out = [[0 for _ in range(m_cols)] for _ in range(n_rows)]
    for i in range(n_rows):
        for j in range(m_cols):
            acc = 0
            for kk in range(k_dim):
                acc = mac_fp16_bits(acc, a[i][kk], b[kk][j])
            out[i][j] = acc
    return out


def compute_expected_mul(a: list[list[int]], alpha: int) -> list[list[int]]:
    return [[mul_fp16_bits(value, alpha) for value in row] for row in a]


def compute_expected_add(a: list[list[int]], b: list[list[int]]) -> list[list[int]]:
    rows = len(a)
    cols = len(a[0]) if rows else 0
    if rows != len(b) or (cols and cols != len(b[0])):
        raise ValueError(f"ADD shape mismatch: A={rows}x{cols}, B={len(b)}x{len(b[0]) if b else 0}")
    return [[add_fp16_bits(a[r][c], b[r][c]) for c in range(cols)] for r in range(rows)]


def reduce_tile_add(tile_bits: list[int]) -> int:
    vals = list(tile_bits)
    while len(vals) > 1:
        nxt = []
        for i in range(0, len(vals), 2):
            nxt.append(add_fp16_bits(vals[i], vals[i + 1]))
        vals = nxt
    return vals[0]


def reduce_tile_min(tile_bits: list[int]) -> tuple[int, int]:
    vals = list(tile_bits)
    idxs = list(range(len(tile_bits)))
    while len(vals) > 1:
        nxt_vals = []
        nxt_idxs = []
        for i in range(0, len(vals), 2):
            left = vals[i]
            right = vals[i + 1]
            if order_key(left) < order_key(right):
                nxt_vals.append(left)
                nxt_idxs.append(idxs[i])
            else:
                nxt_vals.append(right)
                nxt_idxs.append(idxs[i + 1])
        vals = nxt_vals
        idxs = nxt_idxs
    return vals[0], idxs[0]


def compute_expected_reduce(mode: int, data_bits: list[int]) -> tuple[int, int]:
    tile_size = 16
    elem_count = len(data_bits)
    pad = 0x0000 if mode == 0 else 0x7C00
    tile_cnt = (elem_count + tile_size - 1) // tile_size
    if tile_cnt == 0:
        return 0, 0

    if mode == 0:
        acc = None
        for tile_idx in range(tile_cnt):
            tile = []
            for i in range(tile_size):
                idx = tile_idx * tile_size + i
                tile.append(data_bits[idx] if idx < elem_count else pad)
            tile_sum = reduce_tile_add(tile)
            acc = tile_sum if acc is None else add_fp16_bits(acc, tile_sum)
        return acc if acc is not None else 0, 0

    best_val = None
    best_idx = 0
    for tile_idx in range(tile_cnt):
        tile = []
        for i in range(tile_size):
            idx = tile_idx * tile_size + i
            tile.append(data_bits[idx] if idx < elem_count else pad)
        tile_min, tile_rel_idx = reduce_tile_min(tile)
        global_idx = tile_idx * tile_size + tile_rel_idx
        if best_val is None or order_key(tile_min) < order_key(best_val):
            best_val = tile_min
            best_idx = global_idx
    return best_val if best_val is not None else 0, best_idx


def append_matrix_decimal_rows(
    rows_out: list[list[str]],
    operator: str,
    case_id: int,
    cmd_id: int,
    tensor: str,
    matrix: list[list[int]],
) -> None:
    for r, row in enumerate(matrix):
        for c, value in enumerate(row):
            rows_out.append([
                operator,
                case_id,
                cmd_id,
                tensor,
                r,
                c,
                "",
                bin16(value),
                fmt_float(fp16_bits_to_float(value)),
            ])


def append_vector_decimal_rows(
    rows_out: list[list[str]],
    operator: str,
    case_id: int,
    cmd_id: int,
    tensor: str,
    vector: list[int],
    treat_as_fp16: bool = True,
) -> None:
    for idx, value in enumerate(vector):
        rows_out.append([
            operator,
            case_id,
            cmd_id,
            tensor,
            "",
            "",
            idx,
            bin16(value) if treat_as_fp16 else str(value),
            fmt_float(fp16_bits_to_float(value)) if treat_as_fp16 else str(value),
        ])


def append_scalar_decimal_row(
    rows_out: list[list[str]],
    operator: str,
    case_id: int,
    cmd_id: int,
    tensor: str,
    value: int,
    treat_as_fp16: bool = True,
) -> None:
    rows_out.append([
        operator,
        case_id,
        cmd_id,
        tensor,
        "",
        "",
        "",
        bin16(value) if treat_as_fp16 else str(value),
        fmt_float(fp16_bits_to_float(value)) if treat_as_fp16 else str(value),
    ])


def compare_matrix(
    operator: str,
    case_id: int,
    cmd_id: int,
    tensor: str,
    expected: list[list[int]],
    hw: list[list[int]],
    element_rows: list[list[str]],
) -> tuple[int, int, int, float]:
    rows = len(expected)
    cols = len(expected[0]) if rows else 0
    exact = 0
    total = rows * cols
    mismatches = 0
    max_abs_error = 0.0
    for r in range(rows):
        for c in range(cols):
            exp_bits = expected[r][c]
            hw_bits = hw[r][c]
            exp_f = fp16_bits_to_float(exp_bits)
            hw_f = fp16_bits_to_float(hw_bits)
            err = hw_f - exp_f
            abs_err = abs(err) if not math.isnan(err) else float("nan")
            if not math.isnan(abs_err):
                max_abs_error = max(max_abs_error, abs_err)
            is_exact = int(exp_bits == hw_bits)
            exact += is_exact
            mismatches += 0 if is_exact else 1
            element_rows.append([
                operator,
                case_id,
                cmd_id,
                tensor,
                r,
                c,
                "",
                bin16(exp_bits),
                fmt_float(exp_f),
                bin16(hw_bits),
                fmt_float(hw_f),
                fmt_float(err),
                fmt_float(abs_err),
                is_exact,
            ])
    return exact, total, mismatches, max_abs_error


def compare_reduce(
    operator: str,
    case_id: int,
    cmd_id: int,
    exp_value: int,
    exp_index: int,
    hw_value: int,
    hw_index: int,
    compare_index: bool,
    element_rows: list[list[str]],
) -> tuple[int, int, int, float]:
    exact = 0
    total = 1 + (1 if compare_index else 0)
    mismatches = 0
    value_exact = int(exp_value == hw_value)
    exact += value_exact
    mismatches += 0 if value_exact else 1
    exp_f = fp16_bits_to_float(exp_value)
    hw_f = fp16_bits_to_float(hw_value)
    err = hw_f - exp_f
    abs_err = abs(err) if not math.isnan(err) else float("nan")
    max_abs_error = 0.0 if math.isnan(abs_err) else abs_err
    element_rows.append([
        operator,
        case_id,
        cmd_id,
        "result_value",
        "",
        "",
        "",
        bin16(exp_value),
        fmt_float(exp_f),
        bin16(hw_value),
        fmt_float(hw_f),
        fmt_float(err),
        fmt_float(abs_err),
        value_exact,
    ])
    if compare_index:
        idx_exact = int(exp_index == hw_index)
        exact += idx_exact
        mismatches += 0 if idx_exact else 1
        element_rows.append([
            operator,
            case_id,
            cmd_id,
            "result_index",
            "",
            "",
            "",
            bin12(exp_index),
            str(exp_index),
            bin12(hw_index),
            str(hw_index),
            str(hw_index - exp_index),
            str(abs(hw_index - exp_index)),
            idx_exact,
        ])
    return exact, total, mismatches, max_abs_error


def init_stat() -> dict[str, float | int]:
    return {
        "cases": 0,
        "pass_cases": 0,
        "fail_cases": 0,
        "total_values": 0,
        "exact_values": 0,
        "max_abs_error": 0.0,
    }


def update_stat(stat: dict[str, float | int], passed: bool, exact: int, total: int, max_abs_error: float) -> None:
    stat["cases"] += 1
    stat["pass_cases"] += 1 if passed else 0
    stat["fail_cases"] += 0 if passed else 1
    stat["total_values"] += total
    stat["exact_values"] += exact
    stat["max_abs_error"] = max(float(stat["max_abs_error"]), float(max_abs_error))


def analyze_abs(result_root: Path, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    operator = "abs"
    inputs = {}
    with (result_root / "tb_core_top_mixed_abs_input.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / "tb_core_top_mixed_abs_output.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        rows = parse_bin(row["rows_bin"])
        cols = parse_bin(row["cols_bin"])
        src = words_to_matrix(collect_prefixed_bits(row, "pre_src_word"), rows, cols)
        exp = abs_expected(src)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "src_pre", src)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "dst_expected", exp)

        if case_id not in outputs:
            total = rows * cols
            case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", 0, 0, total, total, "", "", "", "", "", "", "missing output"])
            update_stat(stats[operator], False, 0, total, 0.0)
            continue

        hw = words_to_matrix(collect_prefixed_bits(outputs[case_id], "post_dst_word"), rows, cols)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "dst_hw", hw)
        exact, total, mismatches, max_abs_error = compare_matrix(operator, case_id, cmd_id, "dst", exp, hw, element_rows)
        passed = mismatches == 0
        case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", int(passed), exact, total, mismatches, fmt_float(max_abs_error), "", "", "", "", "", "", ""])
        update_stat(stats[operator], passed, exact, total, max_abs_error)


def analyze_layout(result_root: Path, mode_name: str, input_name: str, output_name: str, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    inputs = {}
    with (result_root / input_name).open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / output_name).open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        src_rows = parse_bin(row["src_rows_bin"])
        src_cols = parse_bin(row["src_cols_bin"])
        dst_rows = parse_bin(row["dst_rows_bin"])
        dst_cols = parse_bin(row["dst_cols_bin"])
        off_r = parse_bin(row["offset_row_bin"]) if "offset_row_bin" in row else 0
        off_c = parse_bin(row["offset_col_bin"]) if "offset_col_bin" in row else 0

        src = words_to_matrix(collect_prefixed_bits(row, "pre_src_word"), src_rows, src_cols)
        dst_pre = words_to_matrix(collect_prefixed_bits(row, "pre_dst_word"), dst_rows, dst_cols)
        exp = transpose_expected(src, dst_pre) if mode_name == "layout_transpose" else assemble_expected(src, dst_pre, off_r, off_c)

        append_matrix_decimal_rows(decimal_rows, mode_name, case_id, cmd_id, "src_pre", src)
        append_matrix_decimal_rows(decimal_rows, mode_name, case_id, cmd_id, "dst_pre", dst_pre)
        append_matrix_decimal_rows(decimal_rows, mode_name, case_id, cmd_id, "dst_expected", exp)

        if case_id not in outputs:
            total = dst_rows * dst_cols
            case_rows.append([mode_name, case_id, cmd_id, src_rows, src_cols, "", dst_rows, dst_cols, "", off_r, off_c, 0, 0, total, total, "", "", "", "", "", "", "missing output"])
            update_stat(stats[mode_name], False, 0, total, 0.0)
            continue

        hw = words_to_matrix(collect_prefixed_bits(outputs[case_id], "post_dst_word"), dst_rows, dst_cols)
        append_matrix_decimal_rows(decimal_rows, mode_name, case_id, cmd_id, "dst_hw", hw)
        exact, total, mismatches, max_abs_error = compare_matrix(mode_name, case_id, cmd_id, "dst", exp, hw, element_rows)
        passed = mismatches == 0
        case_rows.append([mode_name, case_id, cmd_id, src_rows, src_cols, "", dst_rows, dst_cols, "", off_r, off_c, int(passed), exact, total, mismatches, fmt_float(max_abs_error), "", "", "", "", "", "", ""])
        update_stat(stats[mode_name], passed, exact, total, max_abs_error)


def analyze_reduce(result_root: Path, mode_name: str, input_name: str, output_name: str, mode: int, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    inputs = {}
    with (result_root / input_name).open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / output_name).open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        length = parse_bin(row["len_bin"])
        data_bits = [parse_bin(row[f"in_elem_{idx}_bin"]) for idx in range(MAX_REDUCE_ELEMS) if f"in_elem_{idx}_bin" in row][:length]
        exp_value, exp_index = compute_expected_reduce(mode, data_bits)

        append_vector_decimal_rows(decimal_rows, mode_name, case_id, cmd_id, "input", data_bits)
        append_scalar_decimal_row(decimal_rows, mode_name, case_id, cmd_id, "expected_result_value", exp_value, True)
        if mode == 1:
            append_scalar_decimal_row(decimal_rows, mode_name, case_id, cmd_id, "expected_result_index", exp_index, False)

        if case_id not in outputs:
            total = 2 if mode == 1 else 1
            case_rows.append([mode_name, case_id, cmd_id, "", "", "", "", "", length, "", "", 0, 0, total, total, "", bin16(exp_value), fmt_float(fp16_bits_to_float(exp_value)), "", "", exp_index if mode == 1 else "", "", "missing output"])
            update_stat(stats[mode_name], False, 0, total, 0.0)
            continue

        out_row = outputs[case_id]
        hw_value = parse_bin(out_row["result_value_bin"])
        hw_index = parse_bin(out_row["result_index_bin"])
        append_scalar_decimal_row(decimal_rows, mode_name, case_id, cmd_id, "hw_result_value", hw_value, True)
        if mode == 1:
            append_scalar_decimal_row(decimal_rows, mode_name, case_id, cmd_id, "hw_result_index", hw_index, False)

        exact, total, mismatches, max_abs_error = compare_reduce(mode_name, case_id, cmd_id, exp_value, exp_index, hw_value, hw_index, mode == 1, element_rows)
        passed = mismatches == 0
        case_rows.append([
            mode_name,
            case_id,
            cmd_id,
            "",
            "",
            "",
            "",
            "",
            length,
            "",
            "",
            int(passed),
            exact,
            total,
            mismatches,
            fmt_float(max_abs_error),
            bin16(exp_value),
            fmt_float(fp16_bits_to_float(exp_value)),
            bin16(hw_value),
            fmt_float(fp16_bits_to_float(hw_value)),
            exp_index if mode == 1 else "",
            hw_index if mode == 1 else "",
            "",
        ])
        update_stat(stats[mode_name], passed, exact, total, max_abs_error)


def analyze_gemm(result_root: Path, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    operator = "gemm"
    inputs = {}
    with (result_root / "tb_core_top_mixed_gemm_input.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / "tb_core_top_mixed_gemm_output.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        n_rows = parse_bin(row["n_rows_bin"])
        m_cols = parse_bin(row["m_cols_bin"])
        k_dim = parse_bin(row["k_dim_bin"])
        a = words_to_matrix(collect_prefixed_bits(row, "pre_a_word"), n_rows, k_dim)
        b = words_to_matrix(collect_prefixed_bits(row, "pre_b_word"), k_dim, m_cols)
        exp = compute_expected_gemm(a, b)

        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "A", a)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "B", b)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_expected", exp)

        if case_id not in outputs:
            total = n_rows * m_cols
            case_rows.append([operator, case_id, cmd_id, n_rows, m_cols, k_dim, "", "", "", "", "", 0, 0, total, total, "", "", "", "", "", "", "missing output"])
            update_stat(stats[operator], False, 0, total, 0.0)
            continue

        hw = words_to_matrix(collect_prefixed_bits(outputs[case_id], "post_c_word"), n_rows, m_cols)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_hw", hw)
        exact, total, mismatches, max_abs_error = compare_matrix(operator, case_id, cmd_id, "C", exp, hw, element_rows)
        passed = mismatches == 0
        case_rows.append([operator, case_id, cmd_id, n_rows, m_cols, k_dim, "", "", "", "", "", int(passed), exact, total, mismatches, fmt_float(max_abs_error), "", "", "", "", "", "", ""])
        update_stat(stats[operator], passed, exact, total, max_abs_error)


def analyze_mul(result_root: Path, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    operator = "mul"
    inputs = {}
    with (result_root / "tb_core_top_mixed_mul_input.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / "tb_core_top_mixed_mul_output.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        rows = parse_bin(row["rows_bin"])
        cols = parse_bin(row["cols_bin"])
        alpha = parse_bin(row["alpha_bin"])
        a = words_to_matrix(collect_prefixed_bits(row, "pre_a_word"), rows, cols)
        exp = compute_expected_mul(a, alpha)

        append_scalar_decimal_row(decimal_rows, operator, case_id, cmd_id, "alpha", alpha, True)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "A", a)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_expected", exp)

        if case_id not in outputs:
            total = rows * cols
            case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", 0, 0, total, total, "", "", "", "", "", "", "missing output"])
            update_stat(stats[operator], False, 0, total, 0.0)
            continue

        hw = words_to_matrix(collect_prefixed_bits(outputs[case_id], "post_c_word"), rows, cols)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_hw", hw)
        exact, total, mismatches, max_abs_error = compare_matrix(operator, case_id, cmd_id, "C", exp, hw, element_rows)
        passed = mismatches == 0
        case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", int(passed), exact, total, mismatches, fmt_float(max_abs_error), "", "", "", "", "", "", ""])
        update_stat(stats[operator], passed, exact, total, max_abs_error)


def analyze_add(result_root: Path, case_rows: list[list[str]], element_rows: list[list[str]], decimal_rows: list[list[str]], stats: dict[str, dict[str, float | int]]) -> None:
    operator = "add"
    inputs = {}
    with (result_root / "tb_core_top_mixed_add_input.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            inputs[int(row["case_id"])] = row

    outputs = {}
    with (result_root / "tb_core_top_mixed_add_output.csv").open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outputs[int(row["case_id"])] = row

    for case_id in sorted(inputs.keys()):
        row = inputs[case_id]
        cmd_id = int(row["cmd_id"])
        rows = parse_bin(row["rows_bin"])
        cols = parse_bin(row["cols_bin"])
        a = words_to_matrix(collect_prefixed_bits(row, "pre_a_word"), rows, cols)
        b = words_to_matrix(collect_prefixed_bits(row, "pre_b_word"), rows, cols)
        exp = compute_expected_add(a, b)

        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "A", a)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "B", b)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_expected", exp)

        if case_id not in outputs:
            total = rows * cols
            case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", 0, 0, total, total, "", "", "", "", "", "", "missing output"])
            update_stat(stats[operator], False, 0, total, 0.0)
            continue

        hw = words_to_matrix(collect_prefixed_bits(outputs[case_id], "post_c_word"), rows, cols)
        append_matrix_decimal_rows(decimal_rows, operator, case_id, cmd_id, "C_hw", hw)
        exact, total, mismatches, max_abs_error = compare_matrix(operator, case_id, cmd_id, "C", exp, hw, element_rows)
        passed = mismatches == 0
        case_rows.append([operator, case_id, cmd_id, rows, cols, "", "", "", "", "", "", int(passed), exact, total, mismatches, fmt_float(max_abs_error), "", "", "", "", "", "", ""])
        update_stat(stats[operator], passed, exact, total, max_abs_error)


def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze tb_core_top_mixed CSVs and validate all mixed operators in software.")
    parser.add_argument("--result-root", default=None, help="directory containing tb_core_top_mixed_*.csv")
    parser.add_argument("--out-dir", default=None, help="directory for analysis outputs")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    result_root = Path(args.result_root).resolve() if args.result_root else script_dir
    out_dir = Path(args.out_dir).resolve() if args.out_dir else script_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    required = [
        "tb_core_top_mixed_abs_input.csv",
        "tb_core_top_mixed_abs_output.csv",
        "tb_core_top_mixed_layout_transpose_input.csv",
        "tb_core_top_mixed_layout_transpose_output.csv",
        "tb_core_top_mixed_layout_assemble_input.csv",
        "tb_core_top_mixed_layout_assemble_output.csv",
        "tb_core_top_mixed_reduce_add_input.csv",
        "tb_core_top_mixed_reduce_add_output.csv",
        "tb_core_top_mixed_reduce_cmp_input.csv",
        "tb_core_top_mixed_reduce_cmp_output.csv",
        "tb_core_top_mixed_gemm_input.csv",
        "tb_core_top_mixed_gemm_output.csv",
        "tb_core_top_mixed_mul_input.csv",
        "tb_core_top_mixed_mul_output.csv",
        "tb_core_top_mixed_add_input.csv",
        "tb_core_top_mixed_add_output.csv",
    ]
    missing = [name for name in required if not (result_root / name).exists()]
    if missing:
        print("Missing mixed CSV files:", file=sys.stderr)
        for name in missing:
            print(f"  - {result_root / name}", file=sys.stderr)
        return 1

    case_rows: list[list[str]] = []
    element_rows: list[list[str]] = []
    decimal_rows: list[list[str]] = []
    stats = {
        "abs": init_stat(),
        "layout_transpose": init_stat(),
        "layout_assemble": init_stat(),
        "reduce_add": init_stat(),
        "reduce_cmp": init_stat(),
        "gemm": init_stat(),
        "mul": init_stat(),
        "add": init_stat(),
    }

    analyze_abs(result_root, case_rows, element_rows, decimal_rows, stats)
    analyze_layout(result_root, "layout_transpose", "tb_core_top_mixed_layout_transpose_input.csv", "tb_core_top_mixed_layout_transpose_output.csv", case_rows, element_rows, decimal_rows, stats)
    analyze_layout(result_root, "layout_assemble", "tb_core_top_mixed_layout_assemble_input.csv", "tb_core_top_mixed_layout_assemble_output.csv", case_rows, element_rows, decimal_rows, stats)
    analyze_reduce(result_root, "reduce_add", "tb_core_top_mixed_reduce_add_input.csv", "tb_core_top_mixed_reduce_add_output.csv", 0, case_rows, element_rows, decimal_rows, stats)
    analyze_reduce(result_root, "reduce_cmp", "tb_core_top_mixed_reduce_cmp_input.csv", "tb_core_top_mixed_reduce_cmp_output.csv", 1, case_rows, element_rows, decimal_rows, stats)
    analyze_gemm(result_root, case_rows, element_rows, decimal_rows, stats)
    analyze_mul(result_root, case_rows, element_rows, decimal_rows, stats)
    analyze_add(result_root, case_rows, element_rows, decimal_rows, stats)

    summary_rows = []
    overall = init_stat()
    for operator in ["abs", "layout_transpose", "layout_assemble", "reduce_add", "reduce_cmp", "gemm", "mul", "add"]:
        stat = stats[operator]
        summary_rows.append([
            operator,
            stat["cases"],
            stat["pass_cases"],
            stat["fail_cases"],
            stat["exact_values"],
            stat["total_values"],
            fmt_float(float(stat["max_abs_error"])),
        ])
        overall["cases"] += int(stat["cases"])
        overall["pass_cases"] += int(stat["pass_cases"])
        overall["fail_cases"] += int(stat["fail_cases"])
        overall["exact_values"] += int(stat["exact_values"])
        overall["total_values"] += int(stat["total_values"])
        overall["max_abs_error"] = max(float(overall["max_abs_error"]), float(stat["max_abs_error"]))
    summary_rows.append([
        "overall",
        overall["cases"],
        overall["pass_cases"],
        overall["fail_cases"],
        overall["exact_values"],
        overall["total_values"],
        fmt_float(float(overall["max_abs_error"])),
    ])

    write_csv(
        out_dir / "analyze_tb_core_top_mixed_summary.csv",
        ["operator", "cases", "pass_cases", "fail_cases", "exact_values", "total_values", "max_abs_error_decimal"],
        summary_rows,
    )
    write_csv(
        out_dir / "analyze_tb_core_top_mixed_case_report.csv",
        [
            "operator",
            "case_id",
            "cmd_id",
            "rows",
            "cols",
            "k_dim",
            "dst_rows",
            "dst_cols",
            "length",
            "offset_row",
            "offset_col",
            "pass",
            "exact_values",
            "total_values",
            "mismatch_values",
            "max_abs_error_decimal",
            "expected_value_bin",
            "expected_value_decimal",
            "hw_value_bin",
            "hw_value_decimal",
            "expected_index",
            "hw_index",
            "notes",
        ],
        case_rows,
    )
    write_csv(
        out_dir / "analyze_tb_core_top_mixed_element_report.csv",
        [
            "operator",
            "case_id",
            "cmd_id",
            "tensor",
            "row",
            "col",
            "index",
            "expected_bin",
            "expected_decimal",
            "hw_bin",
            "hw_decimal",
            "error_decimal",
            "abs_error_decimal",
            "exact_match",
        ],
        element_rows,
    )
    write_csv(
        out_dir / "analyze_tb_core_top_mixed_decimal.csv",
        ["operator", "case_id", "cmd_id", "tensor", "row", "col", "index", "bits_bin", "decimal"],
        decimal_rows,
    )

    print("=== Analyze tb_core_top_mixed ===")
    print(f"Result root: {result_root}")
    print(f"Output dir : {out_dir}")
    for row in summary_rows:
        print(
            f"{row[0]:>16}: cases={row[1]}, pass={row[2]}, fail={row[3]}, "
            f"exact={row[4]}/{row[5]}, max_abs_err={row[6]}"
        )

    return 0 if int(overall["fail_cases"]) == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
