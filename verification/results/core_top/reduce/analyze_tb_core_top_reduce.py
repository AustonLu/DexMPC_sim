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


def float_to_fp16_bits(value: float) -> int:
    if _HAS_NUMPY:
        return np.frombuffer(np.float16(value).tobytes(), dtype=np.uint16)[0].item()
    import struct
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
            return (sign << 15)
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


def order_key(bits: int) -> int:
    if bits & 0x8000:
        return (~bits) & 0xFFFF
    return bits ^ 0x8000


def reduce_tile_add(tile_bits):
    vals = list(tile_bits)
    while len(vals) > 1:
        nxt = []
        for i in range(0, len(vals), 2):
            nxt.append(add_fp16_bits(vals[i], vals[i + 1]))
        vals = nxt
    return vals[0]


def reduce_tile_min(tile_bits):
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


def compute_expected(case_mode, elem_count, data_bits):
    tile_size = 16
    pad = 0x0000 if case_mode == 0 else 0x7C00
    tile_cnt = (elem_count + tile_size - 1) // tile_size
    if tile_cnt == 0:
        return 0, 0

    if case_mode == 0:
        acc = None
        for t in range(tile_cnt):
            tile = []
            for i in range(tile_size):
                idx = t * tile_size + i
                if idx < elem_count:
                    tile.append(data_bits[idx])
                else:
                    tile.append(pad)
            tile_sum = reduce_tile_add(tile)
            if acc is None:
                acc = tile_sum
            else:
                acc = add_fp16_bits(acc, tile_sum)
        return acc if acc is not None else 0, 0
    else:
        best_val = None
        best_idx = 0
        for t in range(tile_cnt):
            tile = []
            for i in range(tile_size):
                idx = t * tile_size + i
                if idx < elem_count:
                    tile.append(data_bits[idx])
                else:
                    tile.append(pad)
            tile_min, tile_idx = reduce_tile_min(tile)
            global_idx = t * tile_size + tile_idx
            if best_val is None:
                best_val = tile_min
                best_idx = global_idx
            else:
                if order_key(best_val) <= order_key(tile_min):
                    pass
                else:
                    best_val = tile_min
                    best_idx = global_idx
        return best_val if best_val is not None else 0, best_idx


def has_unknown(s: str) -> bool:
    txt = s.strip().lower()
    return ("x" in txt) or ("z" in txt)


def parse_bin(s: str) -> int:
    txt = s.strip()
    if txt == "":
        return 0
    txt = txt.replace("x", "0").replace("X", "0").replace("z", "0").replace("Z", "0")
    return int(txt, 2)


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze tb_core_top_reduce CSVs and compare in software.")
    parser.add_argument("--input", default="tb_core_top_reduce_input.csv", help="input CSV (binary)")
    parser.add_argument("--output", default="tb_core_top_reduce_output.csv", help="output CSV (binary)")
    parser.add_argument("--report", default="analyze_tb_core_top_reduce_report.csv", help="report CSV path")
    parser.add_argument("--decimal", default="analyze_tb_core_top_reduce_decimal.csv", help="decimal CSV path")
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
    max_elems = 0
    with open(input_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            elem_count = parse_bin(row["elem_count_bin"])
            mode = parse_bin(row["mode_bin"])
            seq_id = parse_bin(row["seq_id_bin"])
            req_id = parse_bin(row["req_id_bin"])
            base_addr = parse_bin(row["base_addr_bin"])
            data_bits = []
            idx = 0
            while True:
                key = f"in_{idx}_bin"
                if key not in row:
                    break
                data_bits.append(parse_bin(row[key]))
                idx += 1
            max_elems = max(max_elems, len(data_bits))
            inputs[case_id] = {
                "seq_id": seq_id,
                "req_id": req_id,
                "mode": mode,
                "elem_count": elem_count,
                "base_addr": base_addr,
                "data_bits": data_bits,
            }

    outputs = {}
    with open(output_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            case_id = int(row["case_id"])
            outputs[case_id] = {
                "seq_id": parse_bin(row["seq_id_bin"]),
                "req_id": parse_bin(row["req_id_bin"]),
                "mode": parse_bin(row["mode_bin"]),
                "elem_count": parse_bin(row["elem_count_bin"]),
                "base_addr": parse_bin(row["base_addr_bin"]),
                "result_val": parse_bin(row["result_value_bin"]),
                "result_idx": parse_bin(row["result_index_bin"]),
                "has_x": has_unknown(row["result_value_bin"]) or has_unknown(row["result_index_bin"]),
            }

    total = 0
    pass_count = 0
    fail_count = 0
    mismatches = []

    with open(report_path, "w", newline="") as f_report, open(decimal_path, "w", newline="") as f_dec:
        report_writer = csv.writer(f_report)
        dec_writer = csv.writer(f_dec)

        report_writer.writerow([
            "case_id",
            "seq_id",
            "req_id",
            "mode",
            "elem_count",
            "base_addr",
            "dut_value_bin",
            "dut_value_dec",
            "dut_index_bin",
            "dut_index_dec",
            "exp_value_bin",
            "exp_value_dec",
            "exp_index_bin",
            "exp_index_dec",
            "pass"
        ])

        dec_header = [
            "case_id",
            "seq_id",
            "req_id",
            "mode",
            "elem_count",
            "base_addr",
            "dut_value_dec",
            "dut_index_dec",
            "exp_value_dec",
            "exp_index_dec",
            "pass"
        ]
        for i in range(max_elems):
            dec_header.append(f"in_{i}_dec")
        dec_writer.writerow(dec_header)

        for case_id, in_row in sorted(inputs.items()):
            total += 1
            if case_id not in outputs:
                fail_count += 1
                mismatches.append((case_id, "missing_output"))
                continue

            out_row = outputs[case_id]

            exp_val, exp_idx = compute_expected(
                in_row["mode"],
                in_row["elem_count"],
                in_row["data_bits"]
            )

            dut_val = out_row["result_val"]
            dut_idx = out_row["result_idx"]

            pass_ok = (dut_val == exp_val) and (dut_idx == exp_idx) and (not out_row["has_x"])

            if pass_ok:
                pass_count += 1
            else:
                fail_count += 1
                mismatches.append((case_id, "mismatch"))

            report_writer.writerow([
                case_id,
                in_row["seq_id"],
                in_row["req_id"],
                in_row["mode"],
                in_row["elem_count"],
                in_row["base_addr"],
                format(dut_val, "016b"),
                fp16_bits_to_float(dut_val),
                format(dut_idx, "016b"),
                dut_idx,
                format(exp_val, "016b"),
                fp16_bits_to_float(exp_val),
                format(exp_idx, "016b"),
                exp_idx,
                1 if pass_ok else 0,
            ])

            dec_row = [
                case_id,
                in_row["seq_id"],
                in_row["req_id"],
                in_row["mode"],
                in_row["elem_count"],
                in_row["base_addr"],
                fp16_bits_to_float(dut_val),
                dut_idx,
                fp16_bits_to_float(exp_val),
                exp_idx,
                1 if pass_ok else 0,
            ]
            data_bits = in_row["data_bits"]
            for i in range(max_elems):
                if i < len(data_bits):
                    dec_row.append(fp16_bits_to_float(data_bits[i]))
                else:
                    dec_row.append(0.0)
            dec_writer.writerow(dec_row)

    print("=== Analyze tb_core_top_reduce ===")
    print(f"Input:   {input_path}")
    print(f"Output:  {output_path}")
    print(f"Report:  {report_path}")
    print(f"Decimal: {decimal_path}")
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
