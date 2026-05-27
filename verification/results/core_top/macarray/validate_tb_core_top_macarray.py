import csv
import math
from pathlib import Path

import numpy as np


def u16_from_bin(bin_str: str) -> int:
    return int(bin_str.strip(), 2) & 0xFFFF


def bin_from_u16(value: int) -> str:
    return f"{value & 0xFFFF:016b}"


def f16_from_u16(u16_val: int) -> np.float16:
    return np.array([u16_val], dtype=np.uint16).view(np.float16)[0]


def u16_from_f16(f16_val: np.float16) -> int:
    return int(np.array([f16_val], dtype=np.float16).view(np.uint16)[0])


def fmt_float(v: float) -> str:
    if math.isnan(v):
        return "nan"
    if math.isinf(v):
        return "inf" if v > 0 else "-inf"
    return f"{v:.10g}"


def fp16_mac(acc: np.float16, a: np.float16, b: np.float16) -> np.float16:
    return np.float16(np.float16(acc) + np.float16(np.float16(a) * np.float16(b)))


def fp16_mul(a: np.float16, b: np.float16) -> np.float16:
    return np.float16(np.float16(a) * np.float16(b))


def fp16_add(a: np.float16, b: np.float16) -> np.float16:
    return np.float16(np.float16(a) + np.float16(b))


def parse_case_matrices(csv_path: Path):
    rows = list(csv.reader(csv_path.open("r", newline="", encoding="utf-8")))
    cases = {}

    cur_case = None
    cur_matrix = None
    exp_rows = 0
    exp_cols = 0
    row_buf = []

    def finalize_matrix():
        nonlocal row_buf, cur_case, cur_matrix, exp_rows, exp_cols
        if cur_case is None or cur_matrix is None:
            row_buf = []
            return
        if len(row_buf) != exp_rows:
            raise ValueError(
                f"case {cur_case} matrix {cur_matrix} rows mismatch: expected {exp_rows}, got {len(row_buf)}"
            )
        cases.setdefault(cur_case, {})[cur_matrix] = {
            "rows": exp_rows,
            "cols": exp_cols,
            "data": np.array(row_buf, dtype=np.uint16),
        }
        row_buf = []

    for row in rows:
        if not row or all(c.strip() == "" for c in row):
            continue
        tag = row[0].strip()
        if tag == "case":
            finalize_matrix()
            cur_case = int(row[1])
            cur_matrix = row[2].strip()
            exp_rows = int(row[4])
            exp_cols = int(row[6])
            row_buf = []
            continue
        if tag.startswith("row"):
            values = [u16_from_bin(v) for v in row[1:] if v.strip() != ""]
            if len(values) < exp_cols:
                values += [0] * (exp_cols - len(values))
            if len(values) > exp_cols:
                values = values[:exp_cols]
            row_buf.append(values)
            if len(row_buf) == exp_rows:
                finalize_matrix()
                cur_matrix = None
            continue

    finalize_matrix()
    return cases


def parse_mul_input(csv_path: Path):
    rows = list(csv.reader(csv_path.open("r", newline="", encoding="utf-8")))
    cases = {}

    cur_case = None
    cur_matrix = None
    exp_rows = 0
    exp_cols = 0
    row_buf = []

    def finalize_matrix():
        nonlocal row_buf, cur_case, cur_matrix, exp_rows, exp_cols
        if cur_case is None or cur_matrix is None:
            row_buf = []
            return
        if len(row_buf) != exp_rows:
            raise ValueError(
                f"case {cur_case} matrix {cur_matrix} rows mismatch: expected {exp_rows}, got {len(row_buf)}"
            )
        cases.setdefault(cur_case, {"alpha": None})[cur_matrix] = {
            "rows": exp_rows,
            "cols": exp_cols,
            "data": np.array(row_buf, dtype=np.uint16),
        }
        row_buf = []

    for row in rows:
        if not row or all(c.strip() == "" for c in row):
            continue
        tag = row[0].strip()
        if tag == "case":
            finalize_matrix()
            cur_case = int(row[1])
            kind = row[2].strip()
            if kind == "scalar":
                if len(row) < 5 or row[3].strip() != "alpha":
                    raise ValueError(f"case {cur_case} scalar row format invalid: {row}")
                cases.setdefault(cur_case, {"alpha": None})["alpha"] = u16_from_bin(row[4])
                cur_matrix = None
                row_buf = []
            else:
                cur_matrix = kind
                exp_rows = int(row[4])
                exp_cols = int(row[6])
                row_buf = []
            continue
        if tag.startswith("row"):
            if cur_matrix is None:
                continue
            values = [u16_from_bin(v) for v in row[1:] if v.strip() != ""]
            if len(values) < exp_cols:
                values += [0] * (exp_cols - len(values))
            if len(values) > exp_cols:
                values = values[:exp_cols]
            row_buf.append(values)
            if len(row_buf) == exp_rows:
                finalize_matrix()
                cur_matrix = None
            continue

    finalize_matrix()
    return cases


def compute_expected_gemm(a_u16: np.ndarray, b_u16: np.ndarray) -> np.ndarray:
    n_rows, k_dim = a_u16.shape
    k_b, m_cols = b_u16.shape
    if k_dim != k_b:
        raise ValueError(f"shape mismatch: A is {a_u16.shape}, B is {b_u16.shape}")
    exp = np.zeros((n_rows, m_cols), dtype=np.uint16)
    for i in range(n_rows):
        for j in range(m_cols):
            acc = np.float16(0.0)
            for kk in range(k_dim):
                a_f16 = f16_from_u16(int(a_u16[i, kk]))
                b_f16 = f16_from_u16(int(b_u16[kk, j]))
                acc = fp16_mac(acc, a_f16, b_f16)
            exp[i, j] = u16_from_f16(acc)
    return exp


def write_gemm_validation(prefix: str, input_csv: Path, output_csv: Path):
    input_cases = parse_case_matrices(input_csv)
    output_cases = parse_case_matrices(output_csv)

    summary_rows = []
    case_rows = []
    matrix_rows = []

    total_exact = 0
    total_elems = 0
    global_max_abs_err = 0.0

    for case_id in sorted(input_cases.keys()):
        if case_id not in output_cases:
            raise ValueError(f"{prefix}: missing output for case {case_id}")
        if "A" not in input_cases[case_id] or "B" not in input_cases[case_id]:
            raise ValueError(f"{prefix}: missing A/B in input for case {case_id}")
        if "C" not in output_cases[case_id]:
            raise ValueError(f"{prefix}: missing C in output for case {case_id}")

        a = input_cases[case_id]["A"]["data"]
        b = input_cases[case_id]["B"]["data"]
        c_hw = output_cases[case_id]["C"]["data"]

        n_rows, k_dim = a.shape
        k_b, m_cols = b.shape
        if k_dim != k_b:
            raise ValueError(f"{prefix}: case {case_id} shape mismatch: A {a.shape}, B {b.shape}")
        if c_hw.shape != (n_rows, m_cols):
            raise ValueError(f"{prefix}: case {case_id} C shape mismatch: expected {(n_rows, m_cols)}, got {c_hw.shape}")

        c_exp = compute_expected_gemm(a, b)

        exact_count = 0
        max_abs_err = 0.0
        total = n_rows * m_cols

        for i in range(n_rows):
            for j in range(m_cols):
                exp_u16 = int(c_exp[i, j])
                hw_u16 = int(c_hw[i, j])
                exp_f16 = f16_from_u16(exp_u16)
                hw_f16 = f16_from_u16(hw_u16)
                err = float(np.float32(hw_f16) - np.float32(exp_f16))
                abs_err = abs(err) if not math.isnan(err) else float("nan")
                if not math.isnan(abs_err):
                    max_abs_err = max(max_abs_err, abs_err)
                    global_max_abs_err = max(global_max_abs_err, abs_err)
                exact = int(exp_u16 == hw_u16)
                if exact:
                    exact_count += 1

                summary_rows.append(
                    [
                        case_id,
                        i,
                        j,
                        bin_from_u16(exp_u16),
                        fmt_float(float(np.float32(exp_f16))),
                        bin_from_u16(hw_u16),
                        fmt_float(float(np.float32(hw_f16))),
                        fmt_float(err),
                        fmt_float(abs_err),
                        exact,
                    ]
                )

        total_exact += exact_count
        total_elems += total

        case_rows.append(
            [
                case_id,
                n_rows,
                m_cols,
                k_dim,
                exact_count,
                total,
                fmt_float(max_abs_err),
            ]
        )

        matrix_rows.append([f"case_{case_id}", "matrix", "A_decimal", "rows", n_rows, "cols", k_dim])
        for i in range(n_rows):
            matrix_rows.append([f"row{i}"] + [fmt_float(float(np.float32(f16_from_u16(int(a[i, kk]))))) for kk in range(k_dim)])
        matrix_rows.append([])

        matrix_rows.append([f"case_{case_id}", "matrix", "B_decimal", "rows", k_dim, "cols", m_cols])
        for kk in range(k_dim):
            matrix_rows.append([f"row{kk}"] + [fmt_float(float(np.float32(f16_from_u16(int(b[kk, j]))))) for j in range(m_cols)])
        matrix_rows.append([])

        matrix_rows.append([f"case_{case_id}", "matrix", "C_expected_decimal", "rows", n_rows, "cols", m_cols])
        for i in range(n_rows):
            matrix_rows.append([f"row{i}"] + [fmt_float(float(np.float32(f16_from_u16(int(c_exp[i, j]))))) for j in range(m_cols)])
        matrix_rows.append([])

        matrix_rows.append([f"case_{case_id}", "matrix", "C_hw_decimal", "rows", n_rows, "cols", m_cols])
        for i in range(n_rows):
            matrix_rows.append([f"row{i}"] + [fmt_float(float(np.float32(f16_from_u16(int(c_hw[i, j]))))) for j in range(m_cols)])
        matrix_rows.append([])

    summary_csv = input_csv.parent / f"{prefix}_validation_summary.csv"
    cases_csv = input_csv.parent / f"{prefix}_validation_cases.csv"
    matrices_csv = input_csv.parent / f"{prefix}_validation_matrices_decimal.csv"

    with summary_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "case",
                "row",
                "col",
                "expected_bin",
                "expected_decimal",
                "hw_bin",
                "hw_decimal",
                "error_decimal",
                "abs_error_decimal",
                "exact_match",
            ]
        )
        writer.writerows(summary_rows)

    with cases_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["case", "N", "M", "K", "exact_match", "total", "max_abs_error_decimal"])
        writer.writerows(case_rows)

    with matrices_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in matrix_rows:
            writer.writerow(row)

    return {
        "cases": len(case_rows),
        "exact_elements": total_exact,
        "total_elements": total_elems,
        "max_abs_error": global_max_abs_err,
        "exact_cases": sum(1 for row in case_rows if row[4] == row[5]),
    }


def write_add_validation(prefix: str, input_csv: Path, output_csv: Path):
    input_cases = parse_case_matrices(input_csv)
    output_cases = parse_case_matrices(output_csv)

    detail_rows = []
    summary_rows = []
    matrix_rows = []

    total_elements = 0
    exact_elements = 0
    total_cases = 0
    exact_cases = 0
    global_max_abs_err = 0.0

    for case_id in sorted(input_cases.keys()):
        if case_id not in output_cases:
            raise ValueError(f"{prefix}: missing output for case {case_id}")
        if "A" not in input_cases[case_id] or "B" not in input_cases[case_id]:
            raise ValueError(f"{prefix}: missing A/B in input for case {case_id}")
        if "C" not in output_cases[case_id]:
            raise ValueError(f"{prefix}: missing C in output for case {case_id}")

        a = input_cases[case_id]["A"]["data"]
        b = input_cases[case_id]["B"]["data"]
        c_hw = output_cases[case_id]["C"]["data"]

        n_rows, m_cols = a.shape
        if b.shape != (n_rows, m_cols):
            raise ValueError(f"{prefix}: case {case_id} B shape mismatch: expected {(n_rows, m_cols)}, got {b.shape}")
        if c_hw.shape != (n_rows, m_cols):
            raise ValueError(f"{prefix}: case {case_id} C shape mismatch: expected {(n_rows, m_cols)}, got {c_hw.shape}")

        exp_c = np.zeros((n_rows, m_cols), dtype=np.uint16)
        case_exact = True
        case_exact_count = 0
        case_abs_err_sum = 0.0
        case_max_abs_err = 0.0

        for r in range(n_rows):
            for c in range(m_cols):
                a_u16 = int(a[r, c])
                b_u16 = int(b[r, c])
                a_f16 = f16_from_u16(a_u16)
                b_f16 = f16_from_u16(b_u16)
                exp_f16 = fp16_add(a_f16, b_f16)
                exp_u16 = u16_from_f16(exp_f16)
                exp_c[r, c] = exp_u16

                hw_u16 = int(c_hw[r, c])
                exp_f32 = float(np.float32(f16_from_u16(exp_u16)))
                hw_f32 = float(np.float32(f16_from_u16(hw_u16)))
                err = hw_f32 - exp_f32
                abs_err = abs(err) if not math.isnan(err) else float("nan")

                total_elements += 1
                exact = int(exp_u16 == hw_u16)
                if exact:
                    exact_elements += 1
                    case_exact_count += 1
                else:
                    case_exact = False

                if not math.isnan(abs_err):
                    case_abs_err_sum += abs_err
                    case_max_abs_err = max(case_max_abs_err, abs_err)
                    global_max_abs_err = max(global_max_abs_err, abs_err)

                detail_rows.append(
                    [
                        case_id,
                        n_rows,
                        m_cols,
                        r,
                        c,
                        bin_from_u16(a_u16),
                        fmt_float(float(np.float32(a_f16))),
                        bin_from_u16(b_u16),
                        fmt_float(float(np.float32(b_f16))),
                        bin_from_u16(exp_u16),
                        fmt_float(exp_f32),
                        bin_from_u16(hw_u16),
                        fmt_float(hw_f32),
                        fmt_float(err),
                        fmt_float(abs_err),
                        exact,
                    ]
                )

        total_cases += 1
        if case_exact:
            exact_cases += 1

        mean_abs_err = case_abs_err_sum / float(n_rows * m_cols) if (n_rows * m_cols) > 0 else 0.0
        summary_rows.append(
            [
                case_id,
                n_rows,
                m_cols,
                n_rows * m_cols,
                int(case_exact),
                case_exact_count,
                fmt_float(case_max_abs_err),
                fmt_float(mean_abs_err),
            ]
        )

        matrix_rows.append([f"case_{case_id}", "matrix", "A_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(v))))) for v in a[rr]])
        matrix_rows.append([f"case_{case_id}", "matrix", "B_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(v))))) for v in b[rr]])
        matrix_rows.append([f"case_{case_id}", "matrix", "C_expected_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(exp_c[rr, cc]))))) for cc in range(m_cols)])
        matrix_rows.append([f"case_{case_id}", "matrix", "C_hw_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(c_hw[rr, cc]))))) for cc in range(m_cols)])
        matrix_rows.append([])

    summary_csv = input_csv.parent / f"{prefix}_validation_summary.csv"
    detail_csv = input_csv.parent / f"{prefix}_validation_details.csv"
    matrix_csv = input_csv.parent / f"{prefix}_validation_matrices_decimal.csv"

    with summary_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "case_id",
                "N",
                "M",
                "element_count",
                "case_all_exact",
                "exact_element_count",
                "max_abs_error_decimal",
                "mean_abs_error_decimal",
            ]
        )
        writer.writerows(summary_rows)

    with detail_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "case_id",
                "N",
                "M",
                "row",
                "col",
                "a_bin",
                "a_decimal",
                "b_bin",
                "b_decimal",
                "expected_bin",
                "expected_decimal",
                "hw_bin",
                "hw_decimal",
                "error_decimal",
                "abs_error_decimal",
                "exact_match",
            ]
        )
        writer.writerows(detail_rows)

    with matrix_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(matrix_rows)

    return {
        "cases": total_cases,
        "exact_cases": exact_cases,
        "exact_elements": exact_elements,
        "total_elements": total_elements,
        "max_abs_error": global_max_abs_err,
    }


def write_mul_validation(prefix: str, input_csv: Path, output_csv: Path):
    input_cases = parse_mul_input(input_csv)
    output_cases = parse_case_matrices(output_csv)

    summary_rows = []
    detail_rows = []
    matrix_rows = []

    total_cases = 0
    exact_cases = 0
    total_elements = 0
    exact_elements = 0
    global_max_abs_err = 0.0

    for case_id in sorted(input_cases.keys()):
        if case_id not in output_cases:
            raise ValueError(f"{prefix}: missing output for case {case_id}")
        if "A" not in input_cases[case_id]:
            raise ValueError(f"{prefix}: missing A in input for case {case_id}")
        if "C" not in output_cases[case_id]:
            raise ValueError(f"{prefix}: missing C in output for case {case_id}")
        alpha_u16 = input_cases[case_id].get("alpha")
        if alpha_u16 is None:
            raise ValueError(f"{prefix}: case {case_id} missing scalar alpha")

        a = input_cases[case_id]["A"]["data"]
        c_hw = output_cases[case_id]["C"]["data"]
        n_rows, m_cols = a.shape
        if c_hw.shape != (n_rows, m_cols):
            raise ValueError(f"{prefix}: case {case_id} C shape mismatch: expected {(n_rows, m_cols)}, got {c_hw.shape}")

        alpha_f16 = f16_from_u16(alpha_u16)
        expected = np.zeros((n_rows, m_cols), dtype=np.uint16)

        case_exact = True
        case_exact_count = 0
        case_abs_err_sum = 0.0
        case_max_abs_err = 0.0

        for r in range(n_rows):
            for c in range(m_cols):
                a_u16 = int(a[r, c])
                a_f16 = f16_from_u16(a_u16)
                exp_f16 = fp16_mul(alpha_f16, a_f16)
                exp_u16 = u16_from_f16(exp_f16)
                expected[r, c] = exp_u16

                hw_u16 = int(c_hw[r, c])
                exp_f32 = float(np.float32(f16_from_u16(exp_u16)))
                hw_f32 = float(np.float32(f16_from_u16(hw_u16)))
                err = hw_f32 - exp_f32
                abs_err = abs(err) if not math.isnan(err) else float("nan")

                total_elements += 1
                exact = int(exp_u16 == hw_u16)
                if exact:
                    exact_elements += 1
                    case_exact_count += 1
                else:
                    case_exact = False

                if not math.isnan(abs_err):
                    case_abs_err_sum += abs_err
                    case_max_abs_err = max(case_max_abs_err, abs_err)
                    global_max_abs_err = max(global_max_abs_err, abs_err)

                detail_rows.append(
                    [
                        case_id,
                        n_rows,
                        m_cols,
                        r,
                        c,
                        bin_from_u16(alpha_u16),
                        fmt_float(float(np.float32(alpha_f16))),
                        bin_from_u16(a_u16),
                        fmt_float(float(np.float32(a_f16))),
                        bin_from_u16(exp_u16),
                        fmt_float(exp_f32),
                        bin_from_u16(hw_u16),
                        fmt_float(hw_f32),
                        fmt_float(err),
                        fmt_float(abs_err),
                        exact,
                    ]
                )

        total_cases += 1
        if case_exact:
            exact_cases += 1

        elem_count = n_rows * m_cols
        mean_abs_err = case_abs_err_sum / float(elem_count) if elem_count > 0 else 0.0
        summary_rows.append(
            [
                case_id,
                n_rows,
                m_cols,
                elem_count,
                int(case_exact),
                case_exact_count,
                fmt_float(case_max_abs_err),
                fmt_float(mean_abs_err),
            ]
        )

        matrix_rows.append([f"case_{case_id}", "scalar", "alpha_decimal", fmt_float(float(np.float32(alpha_f16)))])
        matrix_rows.append([f"case_{case_id}", "matrix", "A_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(v))))) for v in a[rr]])
        matrix_rows.append([f"case_{case_id}", "matrix", "C_expected_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(expected[rr, cc]))))) for cc in range(m_cols)])
        matrix_rows.append([f"case_{case_id}", "matrix", "C_hw_decimal", "rows", n_rows, "cols", m_cols])
        for rr in range(n_rows):
            matrix_rows.append([f"row{rr}"] + [fmt_float(float(np.float32(f16_from_u16(int(c_hw[rr, cc]))))) for cc in range(m_cols)])
        matrix_rows.append([])

    summary_csv = input_csv.parent / f"{prefix}_validation_summary.csv"
    detail_csv = input_csv.parent / f"{prefix}_validation_details.csv"
    matrix_csv = input_csv.parent / f"{prefix}_validation_matrices_decimal.csv"

    with summary_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "case_id",
                "N",
                "M",
                "element_count",
                "case_all_exact",
                "exact_element_count",
                "max_abs_error_decimal",
                "mean_abs_error_decimal",
            ]
        )
        writer.writerows(summary_rows)

    with detail_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "case_id",
                "N",
                "M",
                "row",
                "col",
                "alpha_bin",
                "alpha_decimal",
                "A_bin",
                "A_decimal",
                "expected_bin",
                "expected_decimal",
                "hw_bin",
                "hw_decimal",
                "error_decimal",
                "abs_error_decimal",
                "exact_match",
            ]
        )
        writer.writerows(detail_rows)

    with matrix_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(matrix_rows)

    return {
        "cases": total_cases,
        "exact_cases": exact_cases,
        "exact_elements": exact_elements,
        "total_elements": total_elements,
        "max_abs_error": global_max_abs_err,
    }


def main():
    base_dir = Path(__file__).resolve().parent

    results = {}

    for op in ["gemm", "gemv", "gevv_dot", "gevv_outer"]:
        in_csv = base_dir / f"tb_core_top_macarray_{op}_input.csv"
        out_csv = base_dir / f"tb_core_top_macarray_{op}_output.csv"
        if not in_csv.exists():
            raise FileNotFoundError(f"missing input csv: {in_csv}")
        if not out_csv.exists():
            raise FileNotFoundError(f"missing output csv: {out_csv}")
        prefix = f"tb_core_top_macarray_{op}"
        results[op] = write_gemm_validation(prefix, in_csv, out_csv)

    in_csv = base_dir / "tb_core_top_macarray_mul_input.csv"
    out_csv = base_dir / "tb_core_top_macarray_mul_output.csv"
    if not in_csv.exists():
        raise FileNotFoundError(f"missing input csv: {in_csv}")
    if not out_csv.exists():
        raise FileNotFoundError(f"missing output csv: {out_csv}")
    results["mul"] = write_mul_validation("tb_core_top_macarray_mul", in_csv, out_csv)

    in_csv = base_dir / "tb_core_top_macarray_add_input.csv"
    out_csv = base_dir / "tb_core_top_macarray_add_output.csv"
    if not in_csv.exists():
        raise FileNotFoundError(f"missing input csv: {in_csv}")
    if not out_csv.exists():
        raise FileNotFoundError(f"missing output csv: {out_csv}")
    results["add"] = write_add_validation("tb_core_top_macarray_add", in_csv, out_csv)

    print("Validation summary (CoreTopMacArray):")
    for op, info in results.items():
        cases = info.get("cases", 0)
        exact_cases = info.get("exact_cases", 0)
        total_elems = info.get("total_elements", 0)
        exact_elems = info.get("exact_elements", 0)
        max_err = fmt_float(info.get("max_abs_error", 0.0))
        case_ratio = (exact_cases / cases) if cases else 0.0
        elem_ratio = (exact_elems / total_elems) if total_elems else 0.0
        print(
            f"- {op}: cases {exact_cases}/{cases} ({case_ratio:.2%}), "
            f"elements {exact_elems}/{total_elems} ({elem_ratio:.2%}), "
            f"max_abs_error {max_err}"
        )


if __name__ == "__main__":
    main()
