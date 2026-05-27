# Verilator file list for the pad-level full-chip top.
#
# This uses rtl/sim_models/IoPadModel.sv instead of the foundry IO pad
# primitive library, which contains transistor primitives unsupported by
# Verilator.
#
# Example:
#   verilator --lint-only -sv --top-module TopChipTop \
#     -f verification/verilator/filelists/topchip_top.f

-f verification/verilator/filelists/topchip.f

rtl/sim_models/IoPadModel.sv
rtl/full_chip/src/stubs/EmptyCKBUFF.sv
rtl/full_chip/src/pad_wrapper/TopChipTop.sv
