from dataclasses import dataclass


OP_REDUCE = 0b010
OP_LA = 0b011
OP_LUT = 0b100

SUB_ADD_REDUCE = 0x1
SUB_GEMM = 0x0
SUB_SOFTPLUS = 0x2

_COMMAND_MEMORY = {"global": 0, "local": 1, "temp": 2}
_WORD_DEPTH = {"global": 2048, "local": 512, "temp": 896}


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


def _field(value, width, name):
    if not isinstance(value, int):
        raise TypeError(f"{name} must be an integer")
    if value < 0 or value >= (1 << width):
        raise ValueError(f"{name}={value} does not fit in {width} bits")
    return value


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
    return make_command(
        command_id,
        OP_LA,
        SUB_GEMM,
        group_end=group_end,
        addr0=_address(a_memory, a_word_offset),
        addr1=_address(b_memory, b_word_offset),
        addr2=_address(out_memory, out_word_offset),
        dim0=m_cols,
        dim1=n_rows,
        dim2=k_dim,
    )


def softplus(
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
    return make_command(
        command_id,
        OP_LUT,
        SUB_SOFTPLUS,
        group_end=group_end,
        addr0=_address(src_memory, src_word_offset),
        addr1=_address(out_memory, out_word_offset),
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
    return make_command(
        command_id,
        OP_REDUCE,
        SUB_ADD_REDUCE,
        group_end=group_end,
        addr0=_address(src_memory, src_word_offset),
        dim0=element_count,
    )
