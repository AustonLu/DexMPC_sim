# DexSim single-core Python SDK

## Supported scope

Version `0.1.0` is the M2 runtime baseline:

- TopChip D2D cycle-accurate Verilator model;
- one persistent model per `Session`;
- command context/core0 only;
- Global0, Local0 and Temp0 FP16 tensor access;
- raw command batches with FIFO, doneCount, timeout and illegal-command checks;
- command builders for GEMM, Softplus and Add-Reduce;
- logical D2D payload byte counters and simulated core cycles.

SPI and multi-core scheduling are intentionally rejected by this version.

## Installation

The package has no Python build dependencies. Its in-tree PEP 517 backend invokes the installed Verilator, CMake, Make and C++ compiler, then packages the generated model in a platform wheel.

```sh
python -m pip install --no-deps --no-build-isolation .
```

For an isolated test install:

```sh
python -m pip install --no-deps --no-build-isolation \
  --target /tmp/dexsim-sdk-install .
```

The first build Verilates the complete TopChip model and can take several minutes. The resulting Linux x86-64 wheel is about 7.5 MB compressed; the installed shared library is about 44 MB.

## Minimal use

```python
import dexsim

with dexsim.Session(transport="d2d", cores=[0]) as sim:
    sim.write_tensor(memory="local", offset=0, value=[1.0, 2.0, 3.0, 4.0])
    sim.write_tensor(memory="local", offset=8, value=[5.0, 6.0, 7.0, 8.0])

    trace = sim.run([
        dexsim.gemm(
            1,
            a_memory="local", a_word_offset=0,
            b_memory="local", b_word_offset=1,
            out_memory="local", out_word_offset=2,
            n_rows=2, m_cols=2, k_dim=2,
        )
    ])
    output = sim.read_tensor(memory="local", offset=16, shape=(2, 2))
```

Tensor `offset` is measured in FP16 elements. Command-builder offsets are explicitly named `word_offset` and are measured in 128-bit SRAM words.

`RunResult` contains:

- `cycles`: simulated core cycles consumed by the call;
- `command_count`;
- `done_count_before` and `done_count_after`;
- `last_done` raw register value;
- logical D2D `read_bytes` and `write_bytes` generated during command submission/polling;
- `reset_count`, which remains one for the lifetime of a normal session.

The byte counters describe logical payload transferred through the driver API, not encoded wire-level framing overhead.

## Softplus LUT

The first Softplus command in a session lazily loads the packaged 512-word LUT into the two physical Softplus SRAM banks. The load happens once per session and is not repeated for later Softplus commands.

## Validation

```sh
python -m unittest discover -s tests/python -p test_session.py -v
python tools/run_sdk_smoke.py --output /tmp/dexsim_sdk_smoke.json
```

The tests cover unaligned FP16 SRAM round-trip, GEMM, Softplus, Add-Reduce, 100 consecutive commands without reset, timeout handling, illegal-command detection and rejection of unsupported cores/transports.
