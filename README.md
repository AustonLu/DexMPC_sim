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
