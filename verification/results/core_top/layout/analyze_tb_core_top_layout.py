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


LANES_PER_WORD = 8  # 128-bit word / 16-bit FP16


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


def unpack_words(word_list, total_elems, lanes_per_word=LANES_PER_WORD):
    elems = []
    for word in word_list:
        for lane in range(lanes_per_word):
            if len(elems) >= total_elems:
                return elems
            elems.append((word >> (lane * 16)) & 0xFFFF)
    return elems


def build_expected_dst(mode, src_rows, src_cols, dst_rows, dst_cols, off_r, off_c, src_elems, dst_pre):
    total_dst = dst_rows * dst_cols
    exp = list(dst_pre)
    if len(exp) < total_dst:
        exp += [0] * (total_dst - len(exp))

    if mode == 0:
        for sr in range(src_rows):
            for sc in range(src_cols):
                dst_r = sc
                dst_c = sr
                if dst_r < dst_rows and dst_c < dst_cols:
                    exp[dst_r * dst_cols + dst_c] = src_elems[sr * src_cols + sc]
    else:
        for sr in range(src_rows):
            for sc in range(src_cols):
                dst_r = off_r + sr
                dst_c = off_c + sc
                if dst_r < dst_rows and dst_c < dst_cols:
                    exp[dst_r * dst_cols + dst_c] = src_elems[sr * src_cols + sc]
    return exp


def write_matrix(f, name, rows, cols, elems):
    f.write(f"# {name} ({rows}x{cols})\n")
    for r in range(rows):
        row = []
        for c in range(cols):
            idx = r * cols + c
            row.append(repr(fp16_bits_to_float(elems[idx])))
        f.write(",".join(row) + "\n")


def write_decimal_csv(bin_path: str, dec_path: str):
    with open(bin_path, "r", newline="") as f_in, open(dec_path, "w", newline="") as f_out:
        reader = csv.reader(f_in)
        writer = csv.writer(f_out)
        header = next(reader, None)
        if header is None:
            return
        dec_header = []
        for h in header:
            if h.endswith("_bin"):
                dec_header.append(h[:-4] + "_dec")
            else:
                dec_header.append(h)
        writer.writerow(dec_header)
        for row in reader:
            if not row:
                continue
            dec_row = []
            for idx, val in enumerate(row):
                if idx == 0:
                    dec_row.append(val)
                else:
                    dec_row.append(str(parse_bin(val)))
            writer.writerow(dec_row)


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze tb_core_top_layout CSVs and compare in software.")
    parser.add_argument("--input", default="tb_core_top_layout_input.csv", help="input CSV (binary)")
    parser.add_argument("--output", default="tb_core_top_layout_output.csv", help="output CSV (binary)")
    parser.add_argument("--report", default="analyze_tb_core_top_layout_report.csv", help="report CSV path")
    parser.add_argument("--decimal", default="analyze_tb_core_top_layout_matrices_decimal.csv", help="decimal matrix dump")
    parser.add_argument("--input-dec", default="tb_core_top_layout_input_dec.csv", help="input CSV (decimal)")
    parser.add_argument("--output-dec", default="tb_core_top_layout_output_dec.csv", help="output CSV (decimal)")
    parser.add_argument("--max-mismatch", type=int, default=10, help="max mismatches to print")
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.abspath(__file__))
    input_path = args.input if os.path.isabs(args.input) else os.path.join(base_dir, args.input)
    output_path = args.output if os.path.isabs(args.output) else os.path.join(base_dir, args.output)
    report_path = args.report if os.path.isabs(args.report) else os.path.join(base_dir, args.report)
    decimal_path = args.decimal if os.path.isabs(args.decimal) else os.path.join(base_dir, args.decimal)
    input_dec_path = args.input_dec if os.path.isabs(args.input_dec) else os.path.join(base_dir, args.input_dec)
    output_dec_path = args.output_dec if os.path.isabs(args.output_dec) else os.path.join(base_dir, args.output_dec)

    if not os.path.exists(input_path):
        print(f"Input CSV not found: {input_path}", file=sys.stderr)
        return 1
    if not os.path.exists(output_path):
        print(f"Output CSV not found: {output_path}", file=sys.stderr)
        return 1

    write_decimal_csv(input_path, input_dec_path)
    write_decimal_csv(output_path, output_dec_path)

    inputs = {}
    with open(input_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            in_row = {
                "seq_id": parse_bin(row["seq_id_bin"]),
                "req_id": parse_bin(row["req_id_bin"]),
                "mode": parse_bin(row["mode_bin"]),
                "src_base": parse_bin(row["src_base_bin"]),
                "src_rows": parse_bin(row["src_rows_bin"]),
                "src_cols": parse_bin(row["src_cols_bin"]),
                "dst_base": parse_bin(row["dst_base_bin"]),
                "dst_rows": parse_bin(row["dst_rows_bin"]),
                "dst_cols": parse_bin(row["dst_cols_bin"]),
                "off_r": parse_bin(row["offset_row_bin"]),
                "off_c": parse_bin(row["offset_col_bin"]),
                "src_word_count": parse_bin(row["src_word_count_bin"]),
                "dst_word_count": parse_bin(row["dst_word_count_bin"]),
            }
            pre_src_words = []
            idx = 0
            while True:
                key = f"pre_src_word_{idx}_bin"
                if key not in row:
                    break
                pre_src_words.append(parse_bin(row[key]))
                idx += 1
            pre_dst_words = []
            idx = 0
            while True:
                key = f"pre_dst_word_{idx}_bin"
                if key not in row:
                    break
                pre_dst_words.append(parse_bin(row[key]))
                idx += 1
            in_row["pre_src_words"] = pre_src_words
            in_row["pre_dst_words"] = pre_dst_words
            inputs[case_id] = in_row

    outputs = {}
    with open(output_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            out_row = {
                "seq_id": parse_bin(row["seq_id_bin"]),
                "req_id": parse_bin(row["req_id_bin"]),
                "mode": parse_bin(row["mode_bin"]),
                "src_base": parse_bin(row["src_base_bin"]),
                "src_rows": parse_bin(row["src_rows_bin"]),
                "src_cols": parse_bin(row["src_cols_bin"]),
                "dst_base": parse_bin(row["dst_base_bin"]),
                "dst_rows": parse_bin(row["dst_rows_bin"]),
                "dst_cols": parse_bin(row["dst_cols_bin"]),
                "off_r": parse_bin(row["offset_row_bin"]),
                "off_c": parse_bin(row["offset_col_bin"]),
                "src_word_count": parse_bin(row["src_word_count_bin"]),
                "dst_word_count": parse_bin(row["dst_word_count_bin"]),
                "done": parse_bin(row["done_bin"]),
            }
            post_src_words = []
            idx = 0
            while True:
                key = f"post_src_word_{idx}_bin"
                if key not in row:
                    break
                post_src_words.append(parse_bin(row[key]))
                idx += 1
            post_dst_words = []
            idx = 0
            while True:
                key = f"post_dst_word_{idx}_bin"
                if key not in row:
                    break
                post_dst_words.append(parse_bin(row[key]))
                idx += 1
            out_row["post_src_words"] = post_src_words
            out_row["post_dst_words"] = post_dst_words
            outputs[case_id] = out_row

    total = 0
    pass_count = 0
    fail_count = 0
    mismatches = []

    with open(report_path, "w", newline="") as f_report, open(decimal_path, "w", newline="") as f_dec:
        writer = csv.writer(f_report)
        writer.writerow([
            "case_id",
            "mode",
            "seq_id",
            "req_id",
            "src_base",
            "dst_base",
            "src_rows",
            "src_cols",
            "dst_rows",
            "dst_cols",
            "off_r",
            "off_c",
            "done",
            "src_pass",
            "dst_pass",
            "pass",
            "first_mismatch_idx",
            "exp_dec",
            "act_dec"
        ])

        for case_id, in_row in sorted(inputs.items()):
            total += 1
            if case_id not in outputs:
                fail_count += 1
                mismatches.append((case_id, "missing_output"))
                writer.writerow([case_id, in_row["mode"], in_row["seq_id"], in_row["req_id"],
                                 in_row["src_base"], in_row["dst_base"], in_row["src_rows"],
                                 in_row["src_cols"], in_row["dst_rows"], in_row["dst_cols"],
                                 in_row["off_r"], in_row["off_c"], 0, 0, 0, 0, "", "", ""])
                continue

            out_row = outputs[case_id]
            src_rows = in_row["src_rows"]
            src_cols = in_row["src_cols"]
            dst_rows = in_row["dst_rows"]
            dst_cols = in_row["dst_cols"]
            src_elems = src_rows * src_cols
            dst_elems = dst_rows * dst_cols

            pre_src = unpack_words(in_row["pre_src_words"], src_elems)
            pre_dst = unpack_words(in_row["pre_dst_words"], dst_elems)
            post_src = unpack_words(out_row["post_src_words"], src_elems)
            post_dst = unpack_words(out_row["post_dst_words"], dst_elems)

            exp_dst = build_expected_dst(
                in_row["mode"],
                src_rows,
                src_cols,
                dst_rows,
                dst_cols,
                in_row["off_r"],
                in_row["off_c"],
                pre_src,
                pre_dst
            )

            meta_ok = (
                out_row["seq_id"] == in_row["seq_id"] and
                out_row["req_id"] == in_row["req_id"] and
                out_row["mode"] == in_row["mode"] and
                out_row["src_base"] == in_row["src_base"] and
                out_row["src_rows"] == in_row["src_rows"] and
                out_row["src_cols"] == in_row["src_cols"] and
                out_row["dst_base"] == in_row["dst_base"] and
                out_row["dst_rows"] == in_row["dst_rows"] and
                out_row["dst_cols"] == in_row["dst_cols"] and
                out_row["off_r"] == in_row["off_r"] and
                out_row["off_c"] == in_row["off_c"] and
                out_row["done"] == 1
            )

            src_pass = (pre_src == post_src)
            dst_pass = True
            first_mismatch_idx = ""
            exp_dec = ""
            act_dec = ""
            for idx, (e, a) in enumerate(zip(exp_dst, post_dst)):
                if e != a:
                    dst_pass = False
                    if first_mismatch_idx == "":
                        first_mismatch_idx = str(idx)
                        exp_dec = repr(fp16_bits_to_float(e))
                        act_dec = repr(fp16_bits_to_float(a))
                    if len(mismatches) < args.max_mismatch:
                        mismatches.append((case_id, f"dst_mismatch_idx_{idx}"))
            if len(post_dst) < len(exp_dst):
                dst_pass = False
                if first_mismatch_idx == "":
                    first_mismatch_idx = "len"
                    exp_dec = "missing"
                    act_dec = "missing"

            ok = meta_ok and src_pass and dst_pass
            if ok:
                pass_count += 1
            else:
                fail_count += 1

            writer.writerow([
                case_id,
                in_row["mode"],
                in_row["seq_id"],
                in_row["req_id"],
                in_row["src_base"],
                in_row["dst_base"],
                src_rows,
                src_cols,
                dst_rows,
                dst_cols,
                in_row["off_r"],
                in_row["off_c"],
                out_row["done"],
                1 if src_pass else 0,
                1 if dst_pass else 0,
                1 if ok else 0,
                first_mismatch_idx,
                exp_dec,
                act_dec
            ])

            f_dec.write(f"# case_id={case_id} mode={in_row['mode']} src={src_rows}x{src_cols} dst={dst_rows}x{dst_cols} off=({in_row['off_r']},{in_row['off_c']})\n")
            write_matrix(f_dec, "src_pre", src_rows, src_cols, pre_src)
            write_matrix(f_dec, "src_post", src_rows, src_cols, post_src)
            write_matrix(f_dec, "dst_pre", dst_rows, dst_cols, pre_dst)
            write_matrix(f_dec, "dst_exp", dst_rows, dst_cols, exp_dst)
            write_matrix(f_dec, "dst_post", dst_rows, dst_cols, post_dst)
            f_dec.write("\n")

    print("=== Analyze tb_core_top_layout ===")
    print(f"Input:     {input_path}")
    print(f"Output:    {output_path}")
    print(f"Report:    {report_path}")
    print(f"Decimal:   {decimal_path}")
    print(f"InputDec:  {input_dec_path}")
    print(f"OutputDec: {output_dec_path}")
    print(f"Total cases: {total}")
    print(f"Pass: {pass_count}")
    print(f"Fail: {fail_count}")

    if mismatches:
        print("Mismatches (first {0}):".format(min(len(mismatches), args.max_mismatch)))
        for cid, reason in mismatches[: args.max_mismatch]:
            print(f"  case {cid}: {reason}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
