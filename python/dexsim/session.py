import ctypes
import math
import numbers
import struct
from dataclasses import asdict, dataclass
from pathlib import Path

from .commands import Command, OP_LUT, SUB_SOFTPLUS


_PHYSICAL_MEMORY = {"global": 0, "local": 1, "temp": 5}
_MEMORY_DEPTH_WORDS = {"global": 2048, "local": 512, "temp": 896}
_FP16_PER_WORD = 8


class DexSimError(RuntimeError):
    pass


class _NativeCommand(ctypes.Structure):
    _fields_ = [("words", ctypes.c_uint32 * 3)]


class _NativeRunStats(ctypes.Structure):
    _fields_ = [
        ("cycles", ctypes.c_uint64),
        ("read_bytes", ctypes.c_uint64),
        ("write_bytes", ctypes.c_uint64),
        ("command_count", ctypes.c_uint32),
        ("done_count_before", ctypes.c_uint32),
        ("done_count_after", ctypes.c_uint32),
        ("last_done", ctypes.c_uint32),
        ("reset_count", ctypes.c_uint32),
    ]


class _NativeSnapshot(ctypes.Structure):
    _fields_ = [
        ("cycle", ctypes.c_uint64),
        ("read_bytes", ctypes.c_uint64),
        ("write_bytes", ctypes.c_uint64),
        ("done_count", ctypes.c_uint32),
        ("reset_count", ctypes.c_uint32),
    ]


@dataclass(frozen=True)
class RunResult:
    cycles: int
    read_bytes: int
    write_bytes: int
    command_count: int
    done_count_before: int
    done_count_after: int
    last_done: int
    reset_count: int

    def to_dict(self):
        return asdict(self)


@dataclass(frozen=True)
class SessionSnapshot:
    cycle: int
    read_bytes: int
    write_bytes: int
    done_count: int
    reset_count: int

    def to_dict(self):
        return asdict(self)


def _load_library():
    library_path = Path(__file__).resolve().parent / "_native" / "libdexsim_runtime.so"
    if not library_path.is_file():
        raise ImportError(f"DexSim native runtime not found at {library_path}")
    library = ctypes.CDLL(str(library_path))
    library.dexsim_session_create.restype = ctypes.c_void_p
    library.dexsim_session_destroy.argtypes = [ctypes.c_void_p]
    library.dexsim_last_error.restype = ctypes.c_char_p
    library.dexsim_write_words.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.POINTER(ctypes.c_uint32),
        ctypes.c_size_t,
    ]
    library.dexsim_read_words.argtypes = list(library.dexsim_write_words.argtypes)
    library.dexsim_run.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(_NativeCommand),
        ctypes.c_size_t,
        ctypes.c_int,
        ctypes.POINTER(_NativeRunStats),
    ]
    library.dexsim_read_register.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.POINTER(ctypes.c_uint32),
    ]
    library.dexsim_get_snapshot.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(_NativeSnapshot),
    ]
    return library


_LIBRARY = None


def _library():
    global _LIBRARY
    if _LIBRARY is None:
        _LIBRARY = _load_library()
    return _LIBRARY


def _native_error():
    message = _library().dexsim_last_error()
    return message.decode("utf-8", errors="replace") if message else "unknown DexSim error"


def _check(status):
    if status != 0:
        raise DexSimError(_native_error())


def _flatten(value):
    if isinstance(value, numbers.Real):
        return [float(value)], ()
    if not isinstance(value, (list, tuple)):
        raise TypeError("tensor value must be a number or a nested list/tuple")
    if not value:
        return [], (0,)
    flat = []
    child_shape = None
    for child in value:
        child_flat, shape = _flatten(child)
        if child_shape is None:
            child_shape = shape
        elif shape != child_shape:
            raise ValueError("ragged tensor values are not supported")
        flat.extend(child_flat)
    return flat, (len(value),) + child_shape


def _reshape(flat, shape):
    if not shape:
        return flat[0]
    if len(shape) == 1:
        return list(flat[: shape[0]])
    stride = math.prod(shape[1:])
    return [
        _reshape(flat[index * stride : (index + 1) * stride], shape[1:])
        for index in range(shape[0])
    ]


def _fp16_bits(value):
    return struct.unpack("<H", struct.pack("<e", float(value)))[0]


def _fp16_value(bits):
    return struct.unpack("<e", struct.pack("<H", bits))[0]


def _pack_lanes(lanes):
    words = []
    for base in range(0, len(lanes), _FP16_PER_WORD):
        chunk = list(lanes[base : base + _FP16_PER_WORD])
        chunk.extend([0] * (_FP16_PER_WORD - len(chunk)))
        words.append(
            tuple(chunk[2 * index] | (chunk[2 * index + 1] << 16) for index in range(4))
        )
    return words


def _unpack_words(words):
    values = []
    for word in words:
        for value in word:
            values.append(value & 0xFFFF)
            values.append((value >> 16) & 0xFFFF)
    return values


class Session:
    def __init__(self, transport="d2d", cores=(0,), timeout_cycles=400_000):
        if transport != "d2d":
            raise ValueError("M2 runtime supports only transport='d2d'")
        if list(cores) != [0]:
            raise ValueError("M2 runtime supports only cores=[0]")
        if timeout_cycles <= 0:
            raise ValueError("timeout_cycles must be positive")
        self.transport = transport
        self.cores = (0,)
        self.timeout_cycles = int(timeout_cycles)
        self._handle = _library().dexsim_session_create()
        if not self._handle:
            raise DexSimError(_native_error())
        self._softplus_loaded = False

    def close(self):
        if self._handle:
            _library().dexsim_session_destroy(self._handle)
            self._handle = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
        return False

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass

    def _require_open(self):
        if not self._handle:
            raise DexSimError("DexSim session is closed")

    def _write_physical_words(self, memory_id, word_offset, words):
        self._require_open()
        flat = [part for word in words for part in word]
        data = (ctypes.c_uint32 * len(flat))(*flat)
        _check(
            _library().dexsim_write_words(
                self._handle, memory_id, word_offset, data, len(words)
            )
        )

    def _read_physical_words(self, memory_id, word_offset, word_count):
        self._require_open()
        data = (ctypes.c_uint32 * (word_count * 4))()
        _check(
            _library().dexsim_read_words(
                self._handle, memory_id, word_offset, data, word_count
            )
        )
        return [tuple(data[index * 4 : index * 4 + 4]) for index in range(word_count)]

    def write_tensor(self, *, memory, core=0, offset=0, value=None):
        if core != 0:
            raise ValueError("M2 runtime supports only core=0")
        if memory not in _PHYSICAL_MEMORY:
            raise ValueError(f"unsupported tensor memory {memory!r}")
        flat, shape = _flatten(value)
        if offset < 0:
            raise ValueError("offset must be non-negative")
        if offset + len(flat) > _MEMORY_DEPTH_WORDS[memory] * _FP16_PER_WORD:
            raise ValueError(f"tensor exceeds {memory} capacity")
        if not flat:
            return {"shape": shape, "elements": 0, "word_offset": offset // 8}

        first_word = offset // _FP16_PER_WORD
        lane_offset = offset % _FP16_PER_WORD
        word_count = math.ceil((lane_offset + len(flat)) / _FP16_PER_WORD)
        if lane_offset == 0 and len(flat) % _FP16_PER_WORD == 0:
            lanes = [0] * (word_count * _FP16_PER_WORD)
        else:
            existing = self._read_physical_words(
                _PHYSICAL_MEMORY[memory], first_word, word_count
            )
            lanes = _unpack_words(existing)
        for index, item in enumerate(flat):
            lanes[lane_offset + index] = _fp16_bits(item)
        self._write_physical_words(
            _PHYSICAL_MEMORY[memory], first_word, _pack_lanes(lanes)
        )
        return {"shape": shape, "elements": len(flat), "word_offset": first_word}

    def read_tensor(self, *, memory, core=0, offset=0, shape=None):
        if core != 0:
            raise ValueError("M2 runtime supports only core=0")
        if memory not in _PHYSICAL_MEMORY:
            raise ValueError(f"unsupported tensor memory {memory!r}")
        if isinstance(shape, int):
            shape = (shape,)
        elif shape is not None:
            shape = tuple(shape)
        if shape is None or not shape or any(dim < 0 for dim in shape):
            raise ValueError("shape must contain one or more non-negative dimensions")
        element_count = math.prod(shape)
        if offset < 0 or offset + element_count > _MEMORY_DEPTH_WORDS[memory] * 8:
            raise ValueError(f"tensor exceeds {memory} capacity")
        first_word = offset // 8
        lane_offset = offset % 8
        word_count = math.ceil((lane_offset + element_count) / 8)
        words = self._read_physical_words(
            _PHYSICAL_MEMORY[memory], first_word, word_count
        )
        lanes = _unpack_words(words)[lane_offset : lane_offset + element_count]
        return _reshape([_fp16_value(value) for value in lanes], shape)

    def _ensure_softplus_lut(self):
        if self._softplus_loaded:
            return
        data_path = Path(__file__).resolve().parent / "_data" / "softplus_data.hex"
        values = [int(line, 16) for line in data_path.read_text().splitlines() if line]
        if len(values) != 512:
            raise DexSimError(f"softplus LUT has {len(values)} words, expected 512")
        self._write_physical_words(13, 0, [(value, 0, 0, 0) for value in values[:256]])
        self._write_physical_words(14, 0, [(value, 0, 0, 0) for value in values[256:]])
        self._softplus_loaded = True

    def run(self, commands, timeout_cycles=None):
        self._require_open()
        commands = list(commands)
        if not all(isinstance(command, Command) for command in commands):
            raise TypeError("commands must contain dexsim.Command values")
        if any(
            command.opcode == OP_LUT and command.subop == SUB_SOFTPLUS
            for command in commands
        ):
            self._ensure_softplus_lut()
        native = (_NativeCommand * len(commands))()
        for index, command in enumerate(commands):
            native[index].words[:] = command.words
        stats = _NativeRunStats()
        _check(
            _library().dexsim_run(
                self._handle,
                native,
                len(commands),
                int(timeout_cycles or self.timeout_cycles),
                ctypes.byref(stats),
            )
        )
        return RunResult(**{name: int(getattr(stats, name)) for name, _ in stats._fields_})

    def read_add_reduce(self):
        raw = ctypes.c_uint32()
        _check(_library().dexsim_read_register(self._handle, 42, ctypes.byref(raw)))
        return {
            "value": _fp16_value(raw.value & 0xFFFF),
            "value_bits": raw.value & 0xFFFF,
            "command_id": (raw.value >> 16) & 0xFFF,
            "valid": bool((raw.value >> 28) & 1),
        }

    def snapshot(self):
        value = _NativeSnapshot()
        _check(_library().dexsim_get_snapshot(self._handle, ctypes.byref(value)))
        return SessionSnapshot(
            **{name: int(getattr(value, name)) for name, _ in value._fields_}
        )

    @staticmethod
    def capabilities():
        return {
            "transport": "d2d",
            "runtime_enabled_cores": [0],
            "tensor_memories": ["global", "local", "temp"],
            "persistent_session": True,
            "fp16": True,
        }
