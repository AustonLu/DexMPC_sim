# Verilator file list for the SRAM model self-check.
#
# Example:
#   verilator -Wall -sv --binary -f verification/verilator/filelists/sram_model.f \
#     --Mdir build/verilator/sram_model_tb
#   ./build/verilator/sram_model_tb/Vtb_sram_fpga_model
#
# To compare against the TSMC macro path, compile this same testbench with
# FLOW_ASIC defined and add the TSMC SRAM simulation libraries.

--top-module
tb_sram_fpga_model

-Wno-DECLFILENAME
-Wno-UNUSEDSIGNAL
-Wno-UNUSEDPARAM

verification/sv_tb/sram/tb_sram_fpga_model.sv
rtl/sim_models/SramWrapperSP.sv
rtl/sim_models/SramWrapperDp.sv
rtl/sim_models/SramFpgaModel.sv
