from dataclasses import dataclass


OP_ABS = 0b001
OP_REDUCE = 0b010
OP_LA = 0b011
OP_LUT = 0b100
OP_DATALAYOUT = 0b101

SUB_ABS = 0x0
SUB_COMPARE_REDUCE = 0x0
SUB_ADD_REDUCE = 0x1
SUB_GEMM = 0x0
SUB_SCALE = 0x1
SUB_ADD = 0x2
SUB_SIN = 0x0
SUB_COS = 0x1
SUB_SOFTPLUS = 0x2
SUB_ASSEMBLE = 0x0
SUB_TRANSPOSE = 0x1

_COMMAND_MEMORY = {"global": 0, "local": 1, "temp": 2}
_WORD_DEPTH = {"global": 2048, "local": 512, "temp": 896}
_FP16_PER_WORD = 8


@dataclass(frozen=True)
class Command:
    words: tuple[int, int, int]

    @property
    def command_id(self):
        return (self.words[2] >> 20) & 0xFFF

    @property
    def opcode(self):
        return (self.words[2] >> 17) & 0x7

    @property
    def subop(self):
        return (self.words[2] >> 13) & 0xF

    @property
    def group_end(self):
        return bool((self.words[2] >> 12) & 1)


def _field(value, width, name):
    if not isinstance(value, int):
        raise TypeError(f"{name} must be an integer")
    if value < 0 or value >= (1 << width):
        raise ValueError(f"{name}={value} does not fit in {width} bits")
    return value


def _positive_dimension(value, name):
    value = _field(value, 12, name)
    if value == 0:
        raise ValueError(f"{name} must be positive")
    return value


def _element_count(rows, cols, name):
    rows = _positive_dimension(rows, f"{name}_rows")
    cols = _positive_dimension(cols, f"{name}_cols")
    return rows, cols, rows * cols


def _address(memory, word_offset):
    if memory not in _COMMAND_MEMORY:
        raise ValueError(f"unsupported command memory {memory!r}")
    if not isinstance(word_offset, int):
        raise TypeError("word_offset must be an integer")
    if word_offset < 0 or word_offset >= _WORD_DEPTH[memory]:
        raise ValueError(
            f"word_offset={word_offset} is outside {memory} depth {_WORD_DEPTH[memory]}"
        )
    return (_COMMAND_MEMORY[memory] << 11) | word_offset


def _region(memory, word_offset, element_count, name):
    address = _address(memory, word_offset)
    if not isinstance(element_count, int):
        raise TypeError(f"{name} element_count must be an integer")
    if element_count <= 0:
        raise ValueError(f"{name} element_count must be positive")
    word_count = (element_count + _FP16_PER_WORD - 1) // _FP16_PER_WORD
    if word_offset + word_count > _WORD_DEPTH[memory]:
        raise ValueError(
            f"{name} exceeds {memory} SRAM: base={word_offset}, words={word_count}, "
            f"depth={_WORD_DEPTH[memory]}"
        )
    return address


def _word_range(word_offset, element_count):
    word_count = (element_count + _FP16_PER_WORD - 1) // _FP16_PER_WORD
    return word_offset, word_offset + word_count


def _reject_overlap(
    left_memory,
    left_word_offset,
    left_element_count,
    right_memory,
    right_word_offset,
    right_element_count,
    name,
):
    if left_memory != right_memory:
        return
    left_start, left_end = _word_range(left_word_offset, left_element_count)
    right_start, right_end = _word_range(right_word_offset, right_element_count)
    if left_start < right_end and right_start < left_end:
        raise ValueError(f"{name} does not support overlapping SRAM regions")


def make_command(
    command_id,
    opcode,
    subop,
    *,
    group_end=True,
    addr0=0,
    addr1=0,
    addr2=0,
    dim0=0,
    dim1=0,
    dim2=0,
):
    fields = (
        (_field(command_id, 12, "command_id"), 12),
        (_field(opcode, 3, "opcode"), 3),
        (_field(subop, 4, "subop"), 4),
        (1 if group_end else 0, 1),
        (0, 1),
        (_field(addr0, 13, "addr0"), 13),
        (_field(addr1, 13, "addr1"), 13),
        (_field(addr2, 13, "addr2"), 13),
        (_field(dim0, 12, "dim0"), 12),
        (_field(dim1, 12, "dim1"), 12),
        (_field(dim2, 12, "dim2"), 12),
    )
    value = 0
    for field, width in fields:
        value = (value << width) | field
    return Command(
        (
            value & 0xFFFFFFFF,
            (value >> 32) & 0xFFFFFFFF,
            (value >> 64) & 0xFFFFFFFF,
        )
    )


def abs(
    command_id,
    *,
    src_memory,
    src_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, "abs")
    _reject_overlap(
        src_memory,
        src_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        "abs",
    )
    return make_command(
        command_id,
        OP_ABS,
        SUB_ABS,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, count, "abs source"),
        addr1=_region(out_memory, out_word_offset, count, "abs output"),
        dim0=rows,
        dim1=cols,
    )


def add_reduce(
    command_id,
    *,
    src_memory,
    src_word_offset,
    element_count,
    group_end=True,
):
    element_count = _positive_dimension(element_count, "element_count")
    return make_command(
        command_id,
        OP_REDUCE,
        SUB_ADD_REDUCE,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, element_count, "add_reduce source"),
        dim0=element_count,
    )


def compare_reduce(
    command_id,
    *,
    src_memory,
    src_word_offset,
    element_count,
    group_end=True,
):
    element_count = _positive_dimension(element_count, "element_count")
    return make_command(
        command_id,
        OP_REDUCE,
        SUB_COMPARE_REDUCE,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, element_count, "compare_reduce source"),
        dim0=element_count,
    )


def gemm(
    command_id,
    *,
    a_memory,
    a_word_offset,
    b_memory,
    b_word_offset,
    out_memory,
    out_word_offset,
    n_rows,
    m_cols,
    k_dim,
    group_end=True,
):
    n_rows = _positive_dimension(n_rows, "n_rows")
    m_cols = _positive_dimension(m_cols, "m_cols")
    k_dim = _positive_dimension(k_dim, "k_dim")
    a_count = n_rows * k_dim
    b_count = k_dim * m_cols
    out_count = n_rows * m_cols
    _reject_overlap(
        a_memory,
        a_word_offset,
        a_count,
        out_memory,
        out_word_offset,
        out_count,
        "GEMM A/output",
    )
    _reject_overlap(
        b_memory,
        b_word_offset,
        b_count,
        out_memory,
        out_word_offset,
        out_count,
        "GEMM B/output",
    )
    return make_command(
        command_id,
        OP_LA,
        SUB_GEMM,
        group_end=group_end,
        addr0=_region(a_memory, a_word_offset, a_count, "GEMM A"),
        addr1=_region(b_memory, b_word_offset, b_count, "GEMM B"),
        addr2=_region(out_memory, out_word_offset, out_count, "GEMM output"),
        dim0=m_cols,
        dim1=n_rows,
        dim2=k_dim,
    )


def gemv(
    command_id,
    *,
    a_memory,
    a_word_offset,
    x_memory,
    x_word_offset,
    out_memory,
    out_word_offset,
    n_rows,
    k_dim,
    group_end=True,
):
    return gemm(
        command_id,
        a_memory=a_memory,
        a_word_offset=a_word_offset,
        b_memory=x_memory,
        b_word_offset=x_word_offset,
        out_memory=out_memory,
        out_word_offset=out_word_offset,
        n_rows=n_rows,
        m_cols=1,
        k_dim=k_dim,
        group_end=group_end,
    )


def dot(
    command_id,
    *,
    a_memory,
    a_word_offset,
    b_memory,
    b_word_offset,
    out_memory,
    out_word_offset,
    element_count,
    group_end=True,
):
    return gemm(
        command_id,
        a_memory=a_memory,
        a_word_offset=a_word_offset,
        b_memory=b_memory,
        b_word_offset=b_word_offset,
        out_memory=out_memory,
        out_word_offset=out_word_offset,
        n_rows=1,
        m_cols=1,
        k_dim=element_count,
        group_end=group_end,
    )


def outer(
    command_id,
    *,
    a_memory,
    a_word_offset,
    b_memory,
    b_word_offset,
    out_memory,
    out_word_offset,
    n_rows,
    m_cols,
    group_end=True,
):
    return gemm(
        command_id,
        a_memory=a_memory,
        a_word_offset=a_word_offset,
        b_memory=b_memory,
        b_word_offset=b_word_offset,
        out_memory=out_memory,
        out_word_offset=out_word_offset,
        n_rows=n_rows,
        m_cols=m_cols,
        k_dim=1,
        group_end=group_end,
    )


def scale(
    command_id,
    *,
    src_memory,
    src_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    alpha_bits,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, "scale")
    alpha_bits = _field(alpha_bits, 16, "alpha_bits")
    _reject_overlap(
        src_memory,
        src_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        "scale",
    )
    return make_command(
        command_id,
        OP_LA,
        SUB_SCALE,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, count, "scale source"),
        addr1=_region(out_memory, out_word_offset, count, "scale output"),
        addr2=alpha_bits & 0x1FFF,
        dim0=rows,
        dim1=cols,
        dim2=(alpha_bits >> 13) & 0x7,
    )


def add(
    command_id,
    *,
    a_memory,
    a_word_offset,
    b_memory,
    b_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, "add")
    _reject_overlap(
        a_memory,
        a_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        "add A/output",
    )
    _reject_overlap(
        b_memory,
        b_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        "add B/output",
    )
    return make_command(
        command_id,
        OP_LA,
        SUB_ADD,
        group_end=group_end,
        addr0=_region(a_memory, a_word_offset, count, "add A"),
        addr1=_region(b_memory, b_word_offset, count, "add B"),
        addr2=_region(out_memory, out_word_offset, count, "add output"),
        dim0=rows,
        dim1=cols,
    )


def _lut(
    command_id,
    subop,
    name,
    *,
    src_memory,
    src_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, name)
    _reject_overlap(
        src_memory,
        src_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        name,
    )
    return make_command(
        command_id,
        OP_LUT,
        subop,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, count, f"{name} source"),
        addr1=_region(out_memory, out_word_offset, count, f"{name} output"),
        dim0=rows,
        dim1=cols,
    )


def sin(command_id, **kwargs):
    return _lut(command_id, SUB_SIN, "sin", **kwargs)


def cos(command_id, **kwargs):
    return _lut(command_id, SUB_COS, "cos", **kwargs)


def softplus(command_id, **kwargs):
    return _lut(command_id, SUB_SOFTPLUS, "softplus", **kwargs)


def assemble(
    command_id,
    *,
    src_memory,
    src_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    offset_row,
    offset_col,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, "assemble")
    offset_row = _field(offset_row, 12, "offset_row")
    offset_col = _field(offset_col, 11, "offset_col")
    dst_rows = rows + offset_row
    dst_cols = cols + offset_col
    _field(dst_rows, 12, "assemble dst_rows")
    _field(dst_cols, 12, "assemble dst_cols")
    dst_count = dst_rows * dst_cols
    _reject_overlap(
        src_memory,
        src_word_offset,
        count,
        out_memory,
        out_word_offset,
        dst_count,
        "assemble",
    )
    return make_command(
        command_id,
        OP_DATALAYOUT,
        SUB_ASSEMBLE,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, count, "assemble source"),
        addr1=_region(
            out_memory,
            out_word_offset,
            dst_count,
            "assemble output",
        ),
        addr2=offset_col,
        dim0=rows,
        dim1=cols,
        dim2=offset_row,
    )


def transpose(
    command_id,
    *,
    src_memory,
    src_word_offset,
    out_memory,
    out_word_offset,
    rows,
    cols,
    group_end=True,
):
    rows, cols, count = _element_count(rows, cols, "transpose")
    _reject_overlap(
        src_memory,
        src_word_offset,
        count,
        out_memory,
        out_word_offset,
        count,
        "transpose",
    )
    return make_command(
        command_id,
        OP_DATALAYOUT,
        SUB_TRANSPOSE,
        group_end=group_end,
        addr0=_region(src_memory, src_word_offset, count, "transpose source"),
        addr1=_region(out_memory, out_word_offset, count, "transpose output"),
        dim0=rows,
        dim1=cols,
    )


reduce_add = add_reduce
reduce_cmp = compare_reduce
mul = scale
lut_sin = sin
lut_cos = cos
lut_softplus = softplus
layout_assemble = assemble
layout_transpose = transpose
