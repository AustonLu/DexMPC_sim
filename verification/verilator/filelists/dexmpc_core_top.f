# Verilator file list for the direct-control backend top.
#
# Example:
#   verilator -Wall -sv --cc --top-module DexMPCCoreTop \
#     -f verification/verilator/filelists/dexmpc_core_top.f \
#     --exe verification/verilator/cpp/tests/tb_reduce.cpp \
#     --Mdir build/verilator/reduce_tb --build
#
# If your DesignWare package keeps DW_fp_addsub in a separate file/library,
# add that library file list to the Verilator command line as well.

-Wno-WIDTHEXPAND
-Wno-WIDTHTRUNC

rtl/core/DexMPCCoreTop.sv
rtl/sim_models/SramFpgaModel.sv
rtl/sim_models/DW_fp_addsub.v
rtl/sim_models/DW_fp_add.v
rtl/sim_models/DW_fp_mult.v
