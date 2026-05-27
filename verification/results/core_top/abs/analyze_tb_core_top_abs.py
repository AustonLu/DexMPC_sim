#!/usr/bin/env python3
import argparse
import csv
import os
import sys

try:
    import numpy as np
    _HAS_NUMPY = True
except Exception:
    _HAS_NUMPY = False


def fp16_bits_to_float(bits: int) -> float:
    if _HAS_NUMPY:
        return np.frombuffer(np.uint16(bits).tobytes(), dtype=np.float16)[0].item()
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


def parse_bin(s: str) -> int:
    txt = s.strip()
    if txt == "":
        return 0
    txt = txt.replace("x", "0").replace("X", "0").replace("z", "0").replace("Z", "0")
    return int(txt, 2)


def lane_has_unknown(word_str: str, lane: int, lanes: int) -> bool:
    txt = word_str.strip()
    if txt == "":
        return False
    txt = txt.lower()
    if len(txt) < lanes * 16:
        txt = txt.rjust(lanes * 16, "0")
    rev = txt[::-1]
    start = lane * 16
    end = start + 16
    chunk = rev[start:end]
    return ("x" in chunk) or ("z" in chunk)


def word_has_unknown_in_valid(word_str: str, valid: int, lanes: int) -> bool:
    for lane in range(valid):
        if lane_has_unknown(word_str, lane, lanes):
            return True
    return False


def clear_sign_bits(word: int, valid_elems: int, lanes: int) -> int:
    if valid_elems <= 0:
        return word
    result = word
    for lane in range(lanes):
        if lane < valid_elems:
            sign_bit = 1 << (lane * 16 + 15)
            result &= ~sign_bit
    return result


def word_to_fp16_list(word: int, lanes: int) -> list[int]:
    vals = []
    for lane in range(lanes):
        vals.append((word >> (lane * 16)) & 0xFFFF)
    return vals


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze tb_core_top_abs CSVs and verify abs results.")
    parser.add_argument("--input", default="tb_core_top_abs_input.csv", help="input CSV (binary)")
    parser.add_argument("--output", default="tb_core_top_abs_output.csv", help="output CSV (binary)")
    parser.add_argument("--report", default="analyze_tb_core_top_abs_report.csv", help="summary report CSV path")
    parser.add_argument("--decimal", default="analyze_tb_core_top_abs_decimal.csv", help="decimal element report CSV path")
    parser.add_argument("--max-mismatch", type=int, default=10, help="max mismatches to print")
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.abspath(__file__))
    input_path = args.input if os.path.isabs(args.input) else os.path.join(base_dir, args.input)
    output_path = args.output if os.path.isabs(args.output) else os.path.join(base_dir, args.output)
    report_path = args.report if os.path.isabs(args.report) else os.path.join(base_dir, args.report)
    decimal_path = args.decimal if os.path.isabs(args.decimal) else os.path.join(base_dir, args.decimal)

    if not os.path.exists(input_path):
        print(f"Input CSV not found: {input_path}", file=sys.stderr)
        return 1
    if not os.path.exists(output_path):
        print(f"Output CSV not found: {output_path}", file=sys.stderr)
        return 1

    inputs = {}
    word_width = None
    with open(input_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            base_addr = parse_bin(row["base_addr_bin"])
            rows = parse_bin(row["rows_bin"])
            cols = parse_bin(row["cols_bin"])
            words = parse_bin(row["word_count_bin"])
            seq_id = parse_bin(row["seq_id_bin"])
            req_id = parse_bin(row["req_id_bin"])
            pre_words = []
            idx = 0
            while True:
                key = f"pre_word_{idx}_bin"
                if key not in row:
                    break
                if word_width is None and row[key].strip() != "":
                    word_width = len(row[key].strip())
                pre_words.append(parse_bin(row[key]))
                idx += 1
            inputs[case_id] = {
                "seq_id": seq_id,
                "req_id": req_id,
                "base_addr": base_addr,
                "rows": rows,
                "cols": cols,
                "word_count": words,
                "pre_words": pre_words,
            }

    outputs = {}
    with open(output_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            post_words = []
            post_words_raw = []
            idx = 0
            while True:
                key = f"post_word_{idx}_bin"
                if key not in row:
                    break
                if word_width is None and row[key].strip() != "":
                    word_width = len(row[key].strip())
                post_words.append(parse_bin(row[key]))
                post_words_raw.append(row[key].strip())
                idx += 1
            outputs[case_id] = {
                "seq_id": parse_bin(row["seq_id_bin"]),
                "req_id": parse_bin(row["req_id_bin"]),
                "base_addr": parse_bin(row["base_addr_bin"]),
                "rows": parse_bin(row["rows_bin"]),
                "cols": parse_bin(row["cols_bin"]),
                "word_count": parse_bin(row["word_count_bin"]),
                "done": parse_bin(row["done_bin"]),
                "post_words": post_words,
                "post_words_raw": post_words_raw,
            }

    if word_width is None:
        print("Failed to detect word width from CSV.", file=sys.stderr)
        return 1
    if word_width % 16 != 0:
        print(f"Word width {word_width} is not a multiple of 16.", file=sys.stderr)
        return 1
    lanes = word_width // 16

    total = 0
    pass_count = 0
    fail_count = 0
    mismatches = []

    with open(report_path, "w", newline="") as f_sum, open(decimal_path, "w", newline="") as f_dec:
        sum_writer = csv.writer(f_sum)
        dec_writer = csv.writer(f_dec)
        sum_writer.writerow([
            "case_id",
            "seq_id",
            "req_id",
            "src_base_bin",
            "dst_base_bin",
            "rows",
            "cols",
            "word_count",
            "done",
            "pass"
        ])
        dec_writer.writerow([
            "case_id",
            "elem_idx",
            "row",
            "col",
            "pre_bits_hex",
            "pre_float",
            "exp_bits_hex",
            "exp_float",
            "out_bits_hex",
            "out_float",
            "pass"
        ])

        for case_id, in_row in sorted(inputs.items()):
            total += 1
            if case_id not in outputs:
                fail_count += 1
                mismatches.append((case_id, "missing_output"))
                sum_writer.writerow([
                    case_id,
                    in_row["seq_id"],
                    in_row["req_id"],
                    format(in_row["base_addr"], "b"),
                    "",
                    in_row["rows"],
                    in_row["cols"],
                    in_row["word_count"],
                    0,
                    0
                ])
                continue

            out_row = outputs[case_id]
            rows = in_row["rows"]
            cols = in_row["cols"]
            total_elems = rows * cols
            word_count = in_row["word_count"]

            ok = True
            if out_row["done"] != 1:
                ok = False

            if (out_row["req_id"] != in_row["req_id"] or
                out_row["rows"] != in_row["rows"] or
                out_row["cols"] != in_row["cols"]):
                ok = False

            for w in range(word_count):
                valid = total_elems - w * lanes
                if valid > lanes:
                    valid = lanes
                if valid < 0:
                    valid = 0
                post_raw = ""
                if w < len(out_row["post_words_raw"]):
                    post_raw = out_row["post_words_raw"][w]
                if word_has_unknown_in_valid(post_raw, valid, lanes):
                    ok = False
                    if len(mismatches) < args.max_mismatch:
                        mismatches.append((case_id, f"word_{w}_valid_lane_has_x"))
                exp_word = clear_sign_bits(in_row["pre_words"][w], valid, lanes)
                dut_word = out_row["post_words"][w]

                pre_list = word_to_fp16_list(in_row["pre_words"][w], lanes)
                exp_list = word_to_fp16_list(exp_word, lanes)
                dut_list = word_to_fp16_list(dut_word, lanes)
                for lane in range(valid):
                    if lane_has_unknown(post_raw, lane, lanes):
                        ok = False
                        if len(mismatches) < args.max_mismatch:
                            mismatches.append((case_id, f"word_{w}_lane_{lane}_has_x"))
                        continue
                    elem_idx = w * lanes + lane
                    row_idx = elem_idx // cols if cols != 0 else 0
                    col_idx = elem_idx % cols if cols != 0 else 0
                    pre_bits = pre_list[lane]
                    exp_bits = exp_list[lane]
                    dut_bits = dut_list[lane]
                    pre_f = fp16_bits_to_float(pre_bits)
                    exp_f = fp16_bits_to_float(exp_bits)
                    dut_f = fp16_bits_to_float(dut_bits)
                    if exp_bits != dut_bits:
                        ok = False
                        if len(mismatches) < args.max_mismatch:
                            mismatches.append((case_id, f"word_{w}_lane_{lane}_mismatch"))
                    dec_writer.writerow([
                        case_id,
                        elem_idx,
                        row_idx,
                        col_idx,
                        f"0x{pre_bits:04x}",
                        pre_f,
                        f"0x{exp_bits:04x}",
                        exp_f,
                        f"0x{dut_bits:04x}",
                        dut_f,
                        1 if exp_bits == dut_bits else 0
                    ])

            if ok:
                pass_count += 1
            else:
                fail_count += 1

            sum_writer.writerow([
                case_id,
                in_row["seq_id"],
                in_row["req_id"],
                format(in_row["base_addr"], "b"),
                format(out_row["base_addr"], "b"),
                in_row["rows"],
                in_row["cols"],
                in_row["word_count"],
                out_row["done"],
                1 if ok else 0
            ])

    print("=== Analyze tb_core_top_abs ===")
    print(f"Input:   {input_path}")
    print(f"Output:  {output_path}")
    print(f"Report:  {report_path}")
    print(f"Decimal: {decimal_path}")
    print(f"Word width: {word_width} bits, lanes: {lanes}")
    print(f"Total cases: {total}")
    print(f"Pass: {pass_count}")
    print(f"Fail: {fail_count}")

    if mismatches:
        print("Mismatches (first {0}):".format(min(len(mismatches), args.max_mismatch)))
        for cid, reason in mismatches[: args.max_mismatch]:
            print(f"  case {cid}: {reason}")

    if _HAS_NUMPY:
        _ = fp16_bits_to_float(0x3C00)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
