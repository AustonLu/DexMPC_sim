# DexMPC_sim

Cycle-Accurate C++ Model of DexMPC Chip, Generated and Verified via Verilator

## Directory Layout

- `rtl/core/`: active synthesizable/core RTL used by the current Verilator flow.
- `rtl/full_chip/`: full-chip digital RTL, pad-wrapper reference, and external-interconnect dependencies.
- `rtl/sim_models/`: simulation replacements and third-party/library models, including SRAM and DW floating-point models.
- `rtl/chisel/`: archived/reference Chisel sources and generated collateral.
- `verification/sv_tb/`: SystemVerilog testbenches kept for reference and simulator comparison.
- `verification/data/`: tracked input/reference data used by testbenches.
- `verification/verilator/filelists/`: Verilator filelists.
- `verification/verilator/cpp/`: C++ testbenches, shared simulation helpers, and templates.
- `verification/results/`: generated CSVs and post-processing scripts.
- `build/verilator/`: all Verilator generated C++ and build outputs.

## Common Commands

Build and run a core C++ testbench:

```sh
CCACHE_DISABLE=1 verilator -sv --cc --top-module DexMPCCoreTop \
  -f verification/verilator/filelists/dexmpc_core_top.f \
  --exe verification/verilator/cpp/tests/tb_reduce.cpp \
  --Mdir build/verilator/reduce_tb --build -j 1

./build/verilator/reduce_tb/VDexMPCCoreTop
```

Build and run the SRAM model self-check:

```sh
CCACHE_DISABLE=1 verilator -Wall -sv --binary \
  -f verification/verilator/filelists/sram_model.f \
  --Mdir build/verilator/sram_model_tb

./build/verilator/sram_model_tb/Vtb_sram_fpga_model
```

Lint the full-chip digital top:

```sh
verilator --lint-only -sv --top-module TopChip \
  -f verification/verilator/filelists/topchip.f
```

Run post-processing scripts from the project root:

```sh
python3 verification/results/core_top/reduce/analyze_tb_core_top_reduce.py
python3 verification/results/core_top/lut/postprocess_tb_core_top_lut.py
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py
```

## TopChip Verilator Model

The full-chip C++ driver is implemented in `verification/verilator/cpp/common/topchip_sim.hpp`.

## Installable Python SDK

`dexmpc-sim v0.4.2` packages the D2D TopChip Verilator model behind a persistent runtime and an address-free high-level Operator API:

```sh
python -m pip install --no-deps --no-build-isolation .
```

```python
import dexsim

with dexsim.Device() as dev:
    a = dev.tensor([[1.0, 2.0], [3.0, 4.0]])
    b = dev.tensor([[5.0, 6.0], [7.0, 8.0]])
    c = dev.gemm(a, b)
    print(c.tolist())
```

The public `Device` API automatically manages FP16 packing, Tensor lifetime, Global/Local/Temp SRAM placement, 96-bit commands, LUT setup and simulator execution. Linear operators have explicit 1/2/4-core policies, continuous Programs can reuse resident shards, and DOT has an independent K-split policy. Measured-benefit `auto` policies remain single-core where the complete operator or kernel path has not passed its performance gate.

- `docs/v0.3_high_level_operator_sdk.md`: v0.3 design, installation, all high-level operators, Program API and kernel-development workflow.
- `docs/v0.4_multicore_operator_sdk.md`: v0.4.0 linear-operator multi-core policies and benchmark boundary.
- `docs/v0.4.1_resident_kernel_sdk.md`: v0.4.1 resident Program execution and transfer avoidance.
- `docs/v0.4.2_multicore_dot_sdk.md`: v0.4.2 DOT K-split, deterministic hardware reduction and independent policy switch.
- `docs/python_sdk.md`: retained v0.2 low-level `Session`/command reference for hardware verification and compatibility.

It wraps the Verilated TopChip model behind a small register/SRAM/instruction API:

- Define `DEX_TOPCHIP_TRANSPORT_D2D` to use `VTopChipTopD2dHarness`.
- Define `DEX_TOPCHIP_TRANSPORT_SPI` to use pad-level `VTopChipTop`.
- Use `Sim::reset()`, `write_reg()`, `read_reg()`, `write_mem_word()`, `read_mem_word()`, `write_mem_words()`, and `read_mem_words()` for external access.
- Use `TestBase::push_cmd()`, `topchip_wait_for_next_done()`, and `topchip_wait_for_done_count()` for command delivery and completion polling.

Address mapping follows the tapeout full-chip testbench:

- Config register address: `BASE + (reg_idx << 3)`.
- SRAM word address: `BASE + ((0x8000 + (mpc_mem_id << 11) + word_addr) << 3)`.
- Core memory ID mapping: global `0 -> 0`, local0 `1 -> 1`, temp0 `2 -> 5`, LUT banks `9..14 -> 9..14`.
- D2D low/high-half IDs: write `0x0c/0x0d`, read `0x2a/0x2b`.
- D2D SRAM word access is split into one AXI beat per 64-bit half-word, matching the existing SV `d2d_write_128`/`d2d_read_128` behavior.

## Full-Chip D2D Mixed Test

Generate, build, and run the D2D harness model:

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp \
  --Mdir build/verilator/full_chip/topchip_d2d_mixed_tb \
  --output-groups 0

make -C build/verilator/full_chip/topchip_d2d_mixed_tb \
  -f VTopChipTopD2dHarness.mk -j 8 OBJCACHE=

./build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness
```

Post-process the generated CSVs:

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/full_chip/d2d/mixed \
  --out-dir verification/results/full_chip/d2d/mixed
```

The same D2D flow can be reused for the standalone wrappers under
`verification/verilator/cpp/tests/full_chip/` by changing `--exe` and `--Mdir`.

## Full-Chip SPI Mixed Test

Generate, build, and run the pad-level SPI model:

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTop \
  -f verification/verilator/filelists/topchip_top.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_spi_mixed.cpp \
  --Mdir build/verilator/full_chip/topchip_spi_mixed_tb \
  --output-groups 0

make -C build/verilator/full_chip/topchip_spi_mixed_tb \
  -f VTopChipTop.mk -j 8 OBJCACHE=

./build/verilator/full_chip/topchip_spi_mixed_tb/VTopChipTop
```

Post-process the SPI mixed results:

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/full_chip/spi/mixed \
  --out-dir verification/results/full_chip/spi/mixed
```

Current full-chip mixed regression status:

- D2D mixed: `34/34` cases passed, `641/641` exact elements.
- SPI mixed: `34/34` cases passed, `641/641` exact elements.
