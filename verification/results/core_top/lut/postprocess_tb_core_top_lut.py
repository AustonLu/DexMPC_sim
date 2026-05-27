from __future__ import annotations

import csv
import math
import struct
from dataclasses import dataclass
from pathlib import Path


OP_TRIG_SIN = 0
OP_TRIG_COS = 1
OP_SOFTPLUS = 2

BASE_CASES = 12
OP_COUNT = 3
COMBO_COUNT = 9
WORDS_PER_ROW = 8
FPW = 16
LANES = 8

BASE_ROWS = [1, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5]
BASE_COLS = [1, 2, 3, 2, 3, 1, 3, 1, 2, 4, 1, 2]

PI_HALF_BITS = 0x3E48
PI_BITS = 0x4248
PI_3H_BITS = 0x44B6
TWO_PI_BITS = 0x4648
FP16_EXP_ALL_ONES = 0x1F
TRIG_BANK_DEPTH = 128


@dataclass(frozen=True)
class CaseRecord:
    case_id: int
    src: int
    dst: int
    op: int
    rows: int
    cols: int
    src_base: int
    dst_base: int
    done: int | None
    bits_rows: list[list[str]]


def half_bits_to_float(bits: int) -> float:
    return struct.unpack(">e", bits.to_bytes(2, byteorder="big", signed=False))[0]


def float_to_half_bits(value: float) -> int:
    return int.from_bytes(struct.pack(">e", value), byteorder="big", signed=False)


def format_half(bits: int | None) -> str:
    if bits is None:
        return "unknown"
    value = half_bits_to_float(bits)
    if math.isnan(value):
        return "nan"
    if math.isinf(value):
        return "inf" if value > 0 else "-inf"
    return format(value, ".10g")


def bits_from_text(bits_text: str) -> int | None:
    if any(ch not in "01" for ch in bits_text):
        return None
    return int(bits_text, 2)


def shift_right_sticky(value: int, shift: int, width: int) -> int:
    if shift <= 0:
        return value & ((1 << width) - 1)
    if shift >= width:
        return 1 if value != 0 else 0
    shifted = value >> shift
    sticky = 1 if (value & ((1 << shift) - 1)) != 0 else 0
    return shifted | sticky


def fp16_sub_nonneg(lhs: int, rhs: int) -> int:
    lhs_exp = (lhs >> 10) & FP16_EXP_ALL_ONES
    lhs_frac = lhs & 0x3FF
    rhs_exp = (rhs >> 10) & FP16_EXP_ALL_ONES
    rhs_frac = rhs & 0x3FF

    lhs_is_zero = lhs_exp == 0 and lhs_frac == 0
    rhs_is_zero = rhs_exp == 0 and rhs_frac == 0
    lhs_is_special = lhs_exp == FP16_EXP_ALL_ONES
    rhs_is_special = rhs_exp == FP16_EXP_ALL_ONES
    lhs_mag = lhs & 0x7FFF
    rhs_mag = rhs & 0x7FFF

    lhs_exp_eff = 1 if lhs_exp == 0 else lhs_exp
    rhs_exp_eff = 1 if rhs_exp == 0 else rhs_exp
    lhs_sig = lhs_frac if lhs_exp == 0 else (1 << 10) | lhs_frac
    rhs_sig = rhs_frac if rhs_exp == 0 else (1 << 10) | rhs_frac

    lhs_ext = lhs_sig << 3
    rhs_ext = rhs_sig << 3
    rhs_aligned = shift_right_sticky(rhs_ext, lhs_exp_eff - rhs_exp_eff, 14)
    raw_diff = (lhs_ext - rhs_aligned) & 0x3FFF

    norm_ext = raw_diff
    norm_exp = lhs_exp_eff
    for _ in range(13):
        need_shift = norm_ext != 0 and norm_exp > 1 and ((norm_ext >> 13) & 0x1) == 0
        if need_shift:
            norm_ext = (norm_ext << 1) & 0x3FFF
            norm_exp -= 1

    if lhs_is_special and lhs_frac == 0:
        return lhs
    if lhs_is_special or rhs_is_special:
        return 0
    if lhs_is_zero or lhs_mag <= rhs_mag:
        return 0
    if rhs_is_zero:
        return lhs

    if ((norm_ext >> 13) & 0x1) == 1:
        mant_pre = (norm_ext >> 3) & 0x7FF
        guard_bit = (norm_ext >> 2) & 0x1
        round_bit = (norm_ext >> 1) & 0x1
        sticky_bit = norm_ext & 0x1
        inc = 1 if guard_bit and (round_bit or sticky_bit or (mant_pre & 0x1)) else 0
        mant_rounded = mant_pre + inc
        if mant_rounded == 2048:
            exp_rounded = norm_exp + 1
            mant_final = 1024
        else:
            exp_rounded = norm_exp
            mant_final = mant_rounded & 0x7FF
        if exp_rounded >= 31:
            return 0x7BFF
        return ((exp_rounded & 0x1F) << 10) | (mant_final & 0x3FF)

    frac_pre = (norm_ext >> 3) & 0x7FF
    guard_bit = (norm_ext >> 2) & 0x1
    round_bit = (norm_ext >> 1) & 0x1
    sticky_bit = norm_ext & 0x1
    inc = 1 if guard_bit and (round_bit or sticky_bit or (frac_pre & 0x1)) else 0
    frac_rounded = frac_pre + inc
    if frac_rounded >= 1024:
        return 0x0400
    return frac_rounded & 0x3FF


def apply_negate(bits: int, negate: bool) -> int:
    return bits ^ 0x8000 if negate else bits


def reduce_trig_abs(abs_bits: int) -> int:
    reduced = abs_bits & 0x7FFF
    if ((reduced >> 10) & FP16_EXP_ALL_ONES) == FP16_EXP_ALL_ONES:
        return reduced
    for _ in range(20000):
        if reduced <= TWO_PI_BITS:
            return reduced
        reduced = fp16_sub_nonneg(reduced, TWO_PI_BITS)
    raise ValueError(f"trig reduction did not converge for 0x{abs_bits:04X}")


def quadrant_code(abs_bits: int) -> int:
    if abs_bits <= PI_HALF_BITS:
        return 1
    if abs_bits <= PI_BITS:
        return 2
    if abs_bits <= PI_3H_BITS:
        return 3
    return 4


def quadrant_name(abs_bits: int) -> str:
    return f"Q{quadrant_code(abs_bits)}"


def lookup_bank(words: list[int], addr: int) -> int:
    bank_sel = (addr >> 7) & 0x1
    row_addr = addr & 0x7F
    return words[bank_sel * TRIG_BANK_DEPTH + row_addr]


def trig_spec_model(input_bits: int, trig_words: list[int]) -> tuple[int, int]:
    input_negative = ((input_bits >> 15) & 0x1) == 1 and (input_bits & 0x7FFF) != 0
    abs_bits = reduce_trig_abs(input_bits & 0x7FFF)
    quadrant = quadrant_code(abs_bits)

    if quadrant == 1:
        theta_sin = abs_bits
        theta_cos = fp16_sub_nonneg(PI_HALF_BITS, abs_bits)
    elif quadrant == 2:
        theta_sin = fp16_sub_nonneg(PI_BITS, abs_bits)
        theta_cos = fp16_sub_nonneg(abs_bits, PI_HALF_BITS)
    elif quadrant == 3:
        theta_sin = fp16_sub_nonneg(abs_bits, PI_BITS)
        theta_cos = fp16_sub_nonneg(PI_3H_BITS, abs_bits)
    else:
        theta_sin = fp16_sub_nonneg(TWO_PI_BITS, abs_bits)
        theta_cos = fp16_sub_nonneg(abs_bits, PI_3H_BITS)

    sin_addr = (theta_sin & 0x7FFF) >> 6
    cos_addr = (theta_cos & 0x7FFF) >> 6

    sin_words = trig_words[: 2 * TRIG_BANK_DEPTH]
    cos_words = trig_words[2 * TRIG_BANK_DEPTH :]
    sin_lut = lookup_bank(sin_words, sin_addr)
    cos_lut = lookup_bank(cos_words, cos_addr)

    sin_negate = ((quadrant == 3) or (quadrant == 4)) ^ input_negative
    cos_negate = (quadrant == 2) or (quadrant == 3)

    return apply_negate(sin_lut, sin_negate), apply_negate(cos_lut, cos_negate)


def trig_math_model(input_bits: int) -> tuple[int, int]:
    x = half_bits_to_float(input_bits)
    if math.isnan(x):
        return input_bits, input_bits
    if math.isinf(x):
        nan_bits = 0x7E00
        return nan_bits, nan_bits
    return float_to_half_bits(math.sin(x)), float_to_half_bits(math.cos(x))


def softplus_region_name(input_bits: int) -> str:
    sign = (input_bits >> 15) & 0x1
    abs_bits = input_bits & 0x7FFF
    addr = abs_bits >> 5
    if addr > 536:
        return "far_neg" if sign else "far_pos"
    if sign and abs_bits != 0:
        return "neg_lut"
    return "pos_lut"


def softplus_spec_model(input_bits: int, lut_words: list[int]) -> int:
    sign = (input_bits >> 15) & 0x1
    abs_bits = input_bits & 0x7FFF
    addr = abs_bits >> 5
    if addr > 536:
        return 0 if sign else input_bits

    bank_sel = (addr >> 9) & 0x1
    row_addr = (addr >> 1) & 0xFF
    word_sel = addr & 0x1

    word = lut_words[row_addr] if bank_sel == 0 else lut_words[256 + row_addr]
    lut_bits = (word >> 16) & 0xFFFF if word_sel else word & 0xFFFF

    if sign == 0 or abs_bits == 0:
        return lut_bits

    result = half_bits_to_float(lut_bits) - half_bits_to_float(abs_bits)
    return float_to_half_bits(result)


def softplus_math_model(input_bits: int) -> int:
    x = half_bits_to_float(input_bits)
    if math.isnan(x):
        return input_bits
    if math.isinf(x):
        return float_to_half_bits(float("inf")) if x > 0 else float_to_half_bits(0.0)
    if x > 20.0:
        y = x
    elif x < -20.0:
        y = math.exp(x)
    else:
        y = math.log1p(math.exp(x))
    return float_to_half_bits(y)


def same_value(lhs: float, rhs: float) -> bool:
    if math.isnan(lhs) and math.isnan(rhs):
        return True
    return lhs == rhs


def op_name(op: int) -> str:
    if op == OP_TRIG_SIN:
        return "trig_sin"
    if op == OP_TRIG_COS:
        return "trig_cos"
    if op == OP_SOFTPLUS:
        return "softplus"
    raise ValueError(f"Unsupported op {op}")


def classify_input(op: int, input_bits: int) -> str:
    if op in (OP_TRIG_SIN, OP_TRIG_COS):
        return quadrant_name(reduce_trig_abs(input_bits & 0x7FFF))
    return softplus_region_name(input_bits)


def spec_and_math_bits(op: int, input_bits: int, trig_words: list[int], soft_words: list[int]) -> tuple[int, int]:
    if op == OP_TRIG_SIN:
        spec_sin, _ = trig_spec_model(input_bits, trig_words)
        math_sin, _ = trig_math_model(input_bits)
        return spec_sin, math_sin
    if op == OP_TRIG_COS:
        _, spec_cos = trig_spec_model(input_bits, trig_words)
        _, math_cos = trig_math_model(input_bits)
        return spec_cos, math_cos
    if op == OP_SOFTPLUS:
        return softplus_spec_model(input_bits, soft_words), softplus_math_model(input_bits)
    raise ValueError(f"Unsupported op {op}")


def decode_case_meta(case_id: int) -> tuple[int, int, int, int, int]:
    case_idx = case_id % BASE_CASES
    op = (case_id // BASE_CASES) % OP_COUNT
    dst = (case_id // (BASE_CASES * OP_COUNT)) % 3
    src = (case_id // (BASE_CASES * OP_COUNT * 3)) % 3
    rows = BASE_ROWS[case_idx]
    cols = BASE_COLS[case_idx]
    return src, dst, op, rows, cols


def lane_bits_from_word_text(word_text: str, lane: int) -> str:
    if len(word_text) != 128:
        raise ValueError(f"Expected 128-bit word text, got {len(word_text)} chars")
    start = 128 - (lane + 1) * FPW
    end = 128 - lane * FPW
    return word_text[start:end]


def parse_case_csv(path: Path, is_output: bool) -> list[CaseRecord]:
    with path.open(encoding="utf-8", newline="") as file_obj:
        rows = list(csv.DictReader(file_obj))

    records: list[CaseRecord] = []
    for row in rows:
        case_id = int(row["case_id"])
        src, dst, op, expect_rows, expect_cols = decode_case_meta(case_id)
        rows_val = int(row["rows_bin"], 2)
        cols_val = int(row["cols_bin"], 2)
        word_count = int(row["word_count_bin"], 2)
        if rows_val != expect_rows or cols_val != expect_cols:
            raise ValueError(
                f"Case {case_id} rows/cols mismatch: csv={rows_val}x{cols_val}, expected={expect_rows}x{expect_cols}"
            )

        prefix = "post_word_" if is_output else "pre_word_"
        total_elems = rows_val * cols_val
        bits_rows: list[list[str]] = []
        for row_idx in range(rows_val):
            bits_row: list[str] = []
            for col_idx in range(cols_val):
                elem_idx = row_idx * cols_val + col_idx
                word_idx = elem_idx // LANES
                lane = elem_idx % LANES
                if word_idx >= word_count:
                    raise ValueError(f"Case {case_id} element index exceeds word_count")
                word_text = row[f"{prefix}{word_idx}_bin"].strip()
                bits_row.append(lane_bits_from_word_text(word_text, lane))
            bits_rows.append(bits_row)

        base_field = "base_addr_bin"
        base_addr = int(row[base_field], 2)
        done = int(row["done_bin"], 2) if is_output else None
        records.append(
            CaseRecord(
                case_id=case_id,
                src=src,
                dst=dst,
                op=op,
                rows=rows_val,
                cols=cols_val,
                src_base=base_addr if not is_output else -1,
                dst_base=base_addr if is_output else -1,
                done=done,
                bits_rows=bits_rows,
            )
        )

    records.sort(key=lambda record: record.case_id)
    return records


def load_trig_words(path: Path) -> list[int]:
    words: list[int] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line:
            words.append(int(line, 16))
    if len(words) != 512:
        raise ValueError(f"Expected 512 trig words in {path}, got {len(words)}")
    return words


def load_softplus_words(path: Path) -> list[int]:
    words: list[int] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line:
            words.append(int(line, 16))
    if len(words) != 512:
        raise ValueError(f"Expected 512 softplus words in {path}, got {len(words)}")
    return words


def case_header(case: CaseRecord) -> str:
    return (
        f"# case={case.case_id} src={case.src} dst={case.dst} "
        f"op={case.op} rows={case.rows} cols={case.cols}"
    )


def write_matrix_export(path: Path, cases: list[CaseRecord], matrices: list[list[list[str]]]) -> None:
    with path.open("w", encoding="utf-8") as file_obj:
        for case, matrix in zip(cases, matrices):
            file_obj.write(case_header(case) + "\n")
            for row in matrix:
                file_obj.write(",".join(row) + "\n")
            file_obj.write("\n")


def new_stats() -> dict[str, object]:
    return {
        "cases": 0,
        "elements": 0,
        "unknown_hw": 0,
        "spec_bit_match": 0,
        "spec_value_match": 0,
        "math_bit_match": 0,
        "math_value_match": 0,
        "math_abs_err_sum": 0.0,
        "math_abs_err_count": 0,
        "math_abs_err_max": 0.0,
    }


def update_abs_err(stats: dict[str, object], hw_bits: int | None, abs_err: object) -> None:
    if hw_bits is None or not isinstance(abs_err, float):
        return
    stats["math_abs_err_sum"] = float(stats["math_abs_err_sum"]) + abs_err
    stats["math_abs_err_count"] = int(stats["math_abs_err_count"]) + 1
    stats["math_abs_err_max"] = max(float(stats["math_abs_err_max"]), abs_err)


def format_avg(stats: dict[str, object]) -> str:
    count = int(stats["math_abs_err_count"])
    if count == 0:
        return "nan"
    return format(float(stats["math_abs_err_sum"]) / count, ".12g")


def main() -> None:
    base_dir = Path(__file__).resolve().parent
    inputs_path = base_dir / "tb_core_top_lut_input.csv"
    outputs_path = base_dir / "tb_core_top_lut_output.csv"
    project_root = base_dir.parents[3]
    trig_hex_path = project_root / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools" / "trig_data.hex"
    softplus_hex_path = project_root / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools" / "softplus_data.hex"
    if not trig_hex_path.exists():
        raise FileNotFoundError(trig_hex_path)
    if not softplus_hex_path.exists():
        raise FileNotFoundError(softplus_hex_path)

    input_records = parse_case_csv(inputs_path, is_output=False)
    output_records = parse_case_csv(outputs_path, is_output=True)
    if len(input_records) != len(output_records):
        raise ValueError(f"Input/output case count mismatch: {len(input_records)} vs {len(output_records)}")

    trig_words = load_trig_words(trig_hex_path)
    soft_words = load_softplus_words(softplus_hex_path)

    overall_stats = new_stats()
    op_stats: dict[str, dict[str, object]] = {}
    route_stats: dict[str, dict[str, object]] = {}

    compare_rows: list[dict[str, object]] = []
    input_dec_mats: list[list[list[str]]] = []
    hw_dec_mats: list[list[list[str]]] = []
    spec_dec_mats: list[list[list[str]]] = []
    math_dec_mats: list[list[list[str]]] = []
    all_done = 0

    for in_case, out_case in zip(input_records, output_records):
        if (
            in_case.case_id != out_case.case_id
            or in_case.src != out_case.src
            or in_case.dst != out_case.dst
            or in_case.op != out_case.op
            or in_case.rows != out_case.rows
            or in_case.cols != out_case.cols
        ):
            raise ValueError(f"Case metadata mismatch: {in_case} vs {out_case}")

        if out_case.done == 1:
            all_done += 1

        current_input_dec: list[list[str]] = []
        current_hw_dec: list[list[str]] = []
        current_spec_dec: list[list[str]] = []
        current_math_dec: list[list[str]] = []

        op_label = op_name(in_case.op)
        route_label = f"src{in_case.src}_dst{in_case.dst}"
        if op_label not in op_stats:
            op_stats[op_label] = new_stats()
        if route_label not in route_stats:
            route_stats[route_label] = new_stats()

        overall_stats["cases"] = int(overall_stats["cases"]) + 1
        op_stats[op_label]["cases"] = int(op_stats[op_label]["cases"]) + 1
        route_stats[route_label]["cases"] = int(route_stats[route_label]["cases"]) + 1

        for row_idx in range(in_case.rows):
            input_dec_row: list[str] = []
            hw_dec_row: list[str] = []
            spec_dec_row: list[str] = []
            math_dec_row: list[str] = []

            for col_idx in range(in_case.cols):
                input_text = in_case.bits_rows[row_idx][col_idx]
                output_text = out_case.bits_rows[row_idx][col_idx]

                input_bits = bits_from_text(input_text)
                if input_bits is None:
                    raise ValueError(f"Non-binary input bits in case {in_case.case_id} ({row_idx}, {col_idx})")

                hw_bits = bits_from_text(output_text)
                spec_bits, math_bits = spec_and_math_bits(in_case.op, input_bits, trig_words, soft_words)

                category = classify_input(in_case.op, input_bits)
                hw_value = None if hw_bits is None else half_bits_to_float(hw_bits)
                spec_value = half_bits_to_float(spec_bits)
                math_value = half_bits_to_float(math_bits)

                spec_bit_match = 0 if hw_bits is None else int(hw_bits == spec_bits)
                spec_value_match = 0 if hw_bits is None else int(same_value(hw_value, spec_value))
                math_bit_match = 0 if hw_bits is None else int(hw_bits == math_bits)
                math_value_match = 0 if hw_bits is None else int(same_value(hw_value, math_value))
                abs_err = "unknown" if hw_bits is None else abs(hw_value - math_value)

                for stats in (overall_stats, op_stats[op_label], route_stats[route_label]):
                    stats["elements"] = int(stats["elements"]) + 1
                    if hw_bits is None:
                        stats["unknown_hw"] = int(stats["unknown_hw"]) + 1
                    else:
                        stats["spec_bit_match"] = int(stats["spec_bit_match"]) + spec_bit_match
                        stats["spec_value_match"] = int(stats["spec_value_match"]) + spec_value_match
                        stats["math_bit_match"] = int(stats["math_bit_match"]) + math_bit_match
                        stats["math_value_match"] = int(stats["math_value_match"]) + math_value_match
                    update_abs_err(stats, hw_bits, abs_err)

                compare_rows.append(
                    {
                        "case_id": in_case.case_id,
                        "src": in_case.src,
                        "dst": in_case.dst,
                        "op": in_case.op,
                        "op_name": op_label,
                        "row": row_idx,
                        "col": col_idx,
                        "category": category,
                        "input_bits": f"{input_bits:016b}",
                        "input_hex": f"0x{input_bits:04X}",
                        "input_dec": format_half(input_bits),
                        "hw_bits": "" if hw_bits is None else f"{hw_bits:016b}",
                        "hw_hex": "" if hw_bits is None else f"0x{hw_bits:04X}",
                        "hw_dec": format_half(hw_bits),
                        "spec_bits": f"{spec_bits:016b}",
                        "spec_hex": f"0x{spec_bits:04X}",
                        "spec_dec": format_half(spec_bits),
                        "spec_bit_match": spec_bit_match,
                        "spec_value_match": spec_value_match,
                        "math_bits": f"{math_bits:016b}",
                        "math_hex": f"0x{math_bits:04X}",
                        "math_dec": format_half(math_bits),
                        "math_bit_match": math_bit_match,
                        "math_value_match": math_value_match,
                        "math_abs_err": abs_err,
                    }
                )

                input_dec_row.append(format_half(input_bits))
                hw_dec_row.append(format_half(hw_bits))
                spec_dec_row.append(format_half(spec_bits))
                math_dec_row.append(format_half(math_bits))

            current_input_dec.append(input_dec_row)
            current_hw_dec.append(hw_dec_row)
            current_spec_dec.append(spec_dec_row)
            current_math_dec.append(math_dec_row)

        input_dec_mats.append(current_input_dec)
        hw_dec_mats.append(current_hw_dec)
        spec_dec_mats.append(current_spec_dec)
        math_dec_mats.append(current_math_dec)

    compare_path = base_dir / "tb_core_top_lut_compare.csv"
    with compare_path.open("w", newline="", encoding="utf-8") as file_obj:
        writer = csv.DictWriter(file_obj, fieldnames=list(compare_rows[0].keys()))
        writer.writeheader()
        writer.writerows(compare_rows)

    write_matrix_export(base_dir / "tb_core_top_lut_inputs_dec.csv", input_records, input_dec_mats)
    write_matrix_export(base_dir / "tb_core_top_lut_outputs_hw_dec.csv", input_records, hw_dec_mats)
    write_matrix_export(base_dir / "tb_core_top_lut_outputs_spec_dec.csv", input_records, spec_dec_mats)
    write_matrix_export(base_dir / "tb_core_top_lut_outputs_math_dec.csv", input_records, math_dec_mats)

    summary_path = base_dir / "tb_core_top_lut_summary.txt"
    with summary_path.open("w", encoding="utf-8") as file_obj:
        file_obj.write(f"total_cases={overall_stats['cases']}\n")
        file_obj.write(f"total_elements={overall_stats['elements']}\n")
        file_obj.write(f"done_cases={all_done}\n")
        file_obj.write(f"unknown_hw_outputs={overall_stats['unknown_hw']}\n")
        file_obj.write(f"spec_bit_match={overall_stats['spec_bit_match']}\n")
        file_obj.write(
            f"spec_bit_mismatch={int(overall_stats['elements']) - int(overall_stats['unknown_hw']) - int(overall_stats['spec_bit_match'])}\n"
        )
        file_obj.write(f"spec_value_match={overall_stats['spec_value_match']}\n")
        file_obj.write(f"math_bit_match={overall_stats['math_bit_match']}\n")
        file_obj.write(
            f"math_bit_mismatch={int(overall_stats['elements']) - int(overall_stats['unknown_hw']) - int(overall_stats['math_bit_match'])}\n"
        )
        file_obj.write(f"math_value_match={overall_stats['math_value_match']}\n")
        file_obj.write(f"math_avg_abs_err={format_avg(overall_stats)}\n")
        file_obj.write(f"math_max_abs_err={format(float(overall_stats['math_abs_err_max']), '.12g')}\n")

        for op_label in ("trig_sin", "trig_cos", "softplus"):
            stats = op_stats.get(op_label, new_stats())
            file_obj.write(
                f"{op_label}: cases={stats['cases']} elements={stats['elements']} "
                f"unknown_hw={stats['unknown_hw']} spec_bit_match={stats['spec_bit_match']} "
                f"spec_value_match={stats['spec_value_match']} math_bit_match={stats['math_bit_match']} "
                f"math_value_match={stats['math_value_match']} math_avg_abs_err={format_avg(stats)} "
                f"math_max_abs_err={format(float(stats['math_abs_err_max']), '.12g')}\n"
            )

        for route_label in sorted(route_stats.keys()):
            stats = route_stats[route_label]
            file_obj.write(
                f"{route_label}: cases={stats['cases']} elements={stats['elements']} "
                f"unknown_hw={stats['unknown_hw']} spec_bit_match={stats['spec_bit_match']} "
                f"math_bit_match={stats['math_bit_match']}\n"
            )


if __name__ == "__main__":
    main()
