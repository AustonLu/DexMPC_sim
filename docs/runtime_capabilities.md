# DexMPC runtime capabilities

This document records the M0 full-chip capability audit performed on 2026-07-20. The machine-readable source is `runtime_capabilities.json`.

## Result

The chip exposes one external DexMPC device interface, but that interface can address four command contexts, four Local SRAMs, four Temp buffers, and four MAC instances. Therefore, “only core0 can receive commands” is not true for the audited RTL and TopChip simulator.

The four contexts are not four identical general-purpose processors. LUT, Reduce, ABS, and DataLayout are single shared engines, and their Local/Temp data ports are connected only to core0 storage.

## Dynamically validated behavior

| Capability | D2D | SPI | Meaning |
|---|---:|---:|---|
| Local0-3 and Temp0-3 external isolation | PASS | not repeated | Same word address holds distinct values in all eight memories. |
| Command contexts 0-3 reachable | PASS | PASS | Each context accepts a command and increments only its own `doneCount`. |
| Local GEMM on cores 0-3 | PASS | PASS | Each MAC produced an exact FP16 result from its own Local SRAM. |
| Concurrent core0/core1 GEMM | PASS | not repeated | Both busy windows overlapped and both 16x16x16 results were exact. |
| Reduce submitted on context 1 | PASS | not repeated | Local and Temp operands were read from core0 storage. |
| Softplus submitted on context 1 | PASS | not repeated | The output was written to Local0; Local1 was unchanged. |

Both D2D and SPI probes were run twice with identical results. The audited probe commit is `3e67226b053c9bbebb94b259fa3742889683ce5d` on `feature/core-probe`.

## Runtime and compiler policy

The M0 change adds low-level per-core register access and physical SRAM access to `topchip_sim.hpp`. The legacy `TestBase` convenience methods still default to core0, and no Python multi-core runtime exists yet.

Use the following conservative scheduling policy until a later milestone adds more concurrency and interference tests:

- Sequential GEMM may target cores 0-3.
- Only concurrent pair `[0, 1]` is currently validated.
- LUT, Reduce, ABS, and DataLayout must be scheduled through command context 0.
- Shared-engine Local/Temp operands and destinations must be allocated in core0 storage.
- Do not assume that cores 1-3 can execute a complete mixed-operator program independently.

Not yet validated: arbitrary concurrent pairs involving cores 2/3, four-way GEMM, shared-engine requests from contexts 2/3, and shared-engine/MAC interference under load.

## Reproduction

Build and run:

```sh
mkdir -p build/verilator/full_chip/topchip_d2d_core_probe_tb
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_core_probe.cpp \
  --Mdir build/verilator/full_chip/topchip_d2d_core_probe_tb \
  --output-groups 0
make -C build/verilator/full_chip/topchip_d2d_core_probe_tb \
  -f VTopChipTopD2dHarness.mk -j 8 OBJCACHE=
./build/verilator/full_chip/topchip_d2d_core_probe_tb/VTopChipTopD2dHarness
```

The SPI wrapper is `verification/verilator/cpp/tests/full_chip/tb_topchip_spi_core_probe.cpp` and uses `TopChipTop` with `verification/verilator/filelists/topchip_top.f`.
