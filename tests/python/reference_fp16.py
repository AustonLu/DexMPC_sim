"""Dependency-free bit-accurate references used by the installed SDK tests.

The reduction and LUT models mirror the repository's established CoreTop
post-processing scripts.  Arithmetic is rounded back to FP16 after every
hardware FP16 operation.  The DW arithmetic instances use
``ieee_compliance=0``, so exponent-zero subnormal operands and underflowed
arithmetic results are flushed to signed zero.  LUT operators retain their
independently verified bit-level behavior.
"""

import struct


PI_HALF_BITS = 0x3E48
PI_BITS = 0x4248
PI_3H_BITS = 0x44B6
TWO_PI_BITS = 0x4648


def bits(value):
    return struct.unpack("<H", struct.pack("<e", float(value)))[0]


def value(raw):
    return struct.unpack("<e", struct.pack("<H", raw & 0xFFFF))[0]


def flush_subnormal(raw):
    exponent = (raw >> 10) & 0x1F
    fraction = raw & 0x3FF
    return (raw & 0x8000) if exponent == 0 and fraction else raw


def arithmetic_bits(result):
    return flush_subnormal(bits(result))


def add_bits(left, right):
    left = flush_subnormal(left)
    right = flush_subnormal(right)
    return arithmetic_bits(value(left) + value(right))


def mul_bits(left, right):
    left = flush_subnormal(left)
    right = flush_subnormal(right)
    return arithmetic_bits(value(left) * value(right))


def add_matrix(left, right):
    return [add_bits(a, b) for a, b in zip(left, right)]


def scale_matrix(source, alpha):
    return [mul_bits(alpha, item) for item in source]


def gemm(a, b, n_rows, m_cols, k_dim):
    output = []
    for row in range(n_rows):
        for col in range(m_cols):
            accumulator = 0
            for inner in range(k_dim):
                product = mul_bits(a[row * k_dim + inner], b[inner * m_cols + col])
                accumulator = add_bits(accumulator, product)
            output.append(accumulator)
    return output


def order_key(raw):
    return ((~raw) & 0xFFFF) if raw & 0x8000 else raw ^ 0x8000


def _tree_add(tile):
    current = list(tile)
    while len(current) > 1:
        current = [
            add_bits(current[index], current[index + 1])
            for index in range(0, len(current), 2)
        ]
    return current[0]


def _tree_min(tile):
    current = list(tile)
    indices = list(range(len(tile)))
    while len(current) > 1:
        next_values = []
        next_indices = []
        for index in range(0, len(current), 2):
            if order_key(current[index]) < order_key(current[index + 1]):
                selected = index
            else:
                selected = index + 1
            next_values.append(current[selected])
            next_indices.append(indices[selected])
        current = next_values
        indices = next_indices
    return current[0], indices[0]


def add_reduce(source):
    accumulator = None
    for base in range(0, len(source), 16):
        tile = list(source[base : base + 16])
        tile.extend([0] * (16 - len(tile)))
        tile_sum = _tree_add(tile)
        accumulator = tile_sum if accumulator is None else add_bits(accumulator, tile_sum)
    return 0 if accumulator is None else accumulator


def compare_reduce(source):
    best_value = None
    best_index = 0
    for base in range(0, len(source), 16):
        tile = list(source[base : base + 16])
        tile.extend([0x7C00] * (16 - len(tile)))
        tile_value, tile_index = _tree_min(tile)
        global_index = base + tile_index
        if best_value is None or order_key(tile_value) < order_key(best_value):
            best_value = tile_value
            best_index = global_index
    return (0 if best_value is None else best_value), best_index


def _shift_right_sticky(raw, shift, width):
    if shift <= 0:
        return raw & ((1 << width) - 1)
    if shift >= width:
        return 1 if raw else 0
    shifted = raw >> shift
    return shifted | (1 if raw & ((1 << shift) - 1) else 0)


def _sub_nonnegative(left, right):
    left_exp = (left >> 10) & 0x1F
    left_frac = left & 0x3FF
    right_exp = (right >> 10) & 0x1F
    right_frac = right & 0x3FF
    left_zero = left_exp == 0 and left_frac == 0
    right_zero = right_exp == 0 and right_frac == 0
    left_special = left_exp == 0x1F
    right_special = right_exp == 0x1F
    left_eff = 1 if left_exp == 0 else left_exp
    right_eff = 1 if right_exp == 0 else right_exp
    left_sig = left_frac if left_exp == 0 else 0x400 | left_frac
    right_sig = right_frac if right_exp == 0 else 0x400 | right_frac
    raw_diff = ((left_sig << 3) - _shift_right_sticky(right_sig << 3, left_eff - right_eff, 14)) & 0x3FFF
    normalized = raw_diff
    normalized_exp = left_eff
    for _ in range(13):
        if normalized and normalized_exp > 1 and not (normalized & 0x2000):
            normalized = (normalized << 1) & 0x3FFF
            normalized_exp -= 1
    if left_special and left_frac == 0:
        return left
    if left_special or right_special or left_zero or (left & 0x7FFF) <= (right & 0x7FFF):
        return 0
    if right_zero:
        return left
    pre = (normalized >> 3) & 0x7FF
    guard = (normalized >> 2) & 1
    round_bit = (normalized >> 1) & 1
    sticky = normalized & 1
    rounded = pre + (1 if guard and (round_bit or sticky or (pre & 1)) else 0)
    if normalized & 0x2000:
        if rounded == 2048:
            normalized_exp += 1
            rounded = 1024
        if normalized_exp >= 31:
            return 0x7BFF
        return ((normalized_exp & 0x1F) << 10) | (rounded & 0x3FF)
    if rounded >= 1024:
        return 0x0400
    return rounded & 0x3FF


def trig_pair(input_bits, trig_words):
    input_negative = bool(input_bits & 0x8000) and bool(input_bits & 0x7FFF)
    reduced = input_bits & 0x7FFF
    if ((reduced >> 10) & 0x1F) != 0x1F:
        for _ in range(20000):
            if reduced <= TWO_PI_BITS:
                break
            reduced = _sub_nonnegative(reduced, TWO_PI_BITS)
        else:
            raise AssertionError("trig reduction did not converge")
    if reduced <= PI_HALF_BITS:
        quadrant = 1
        theta_sin = reduced
        theta_cos = _sub_nonnegative(PI_HALF_BITS, reduced)
    elif reduced <= PI_BITS:
        quadrant = 2
        theta_sin = _sub_nonnegative(PI_BITS, reduced)
        theta_cos = _sub_nonnegative(reduced, PI_HALF_BITS)
    elif reduced <= PI_3H_BITS:
        quadrant = 3
        theta_sin = _sub_nonnegative(reduced, PI_BITS)
        theta_cos = _sub_nonnegative(PI_3H_BITS, reduced)
    else:
        quadrant = 4
        theta_sin = _sub_nonnegative(TWO_PI_BITS, reduced)
        theta_cos = _sub_nonnegative(reduced, PI_3H_BITS)
    sin_addr = (theta_sin & 0x7FFF) >> 6
    cos_addr = (theta_cos & 0x7FFF) >> 6
    sin_bits = trig_words[sin_addr]
    cos_bits = trig_words[256 + cos_addr]
    if ((quadrant in (3, 4)) ^ input_negative):
        sin_bits ^= 0x8000
    if quadrant in (2, 3):
        cos_bits ^= 0x8000
    return sin_bits, cos_bits


def softplus(input_bits, lut_words):
    sign = (input_bits >> 15) & 1
    magnitude = input_bits & 0x7FFF
    address = magnitude >> 5
    if address > 536:
        return 0 if sign else input_bits
    bank = (address >> 9) & 1
    row = (address >> 1) & 0xFF
    word_select = address & 1
    packed = lut_words[bank * 256 + row]
    lut_bits = (packed >> 16) & 0xFFFF if word_select else packed & 0xFFFF
    if not sign or magnitude == 0:
        return lut_bits
    return bits(value(lut_bits) - value(magnitude))


def transpose(source, rows, cols):
    return [source[row * cols + col] for col in range(cols) for row in range(rows)]


def assemble(source, destination, rows, cols, offset_row, offset_col):
    dst_rows = rows + offset_row
    dst_cols = cols + offset_col
    output = list(destination)
    for row in range(rows):
        for col in range(cols):
            output[(row + offset_row) * dst_cols + col + offset_col] = source[row * cols + col]
    return output
