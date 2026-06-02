# Verilator file list for the full-chip digital top.
#
# This targets TopChip, not TopChipTop. TopChipTop is the pad wrapper and
# depends on foundry IO-pad transistor primitives that Verilator does not
# support directly. Keep pad-wrapper simulation behind a separate pad model.
#
# Example:
#   verilator --lint-only -sv --top-module TopChip \
#     -f verification/verilator/filelists/topchip.f

-Wno-WIDTHEXPAND
-Wno-WIDTHTRUNC
-Wno-DECLFILENAME
-Wno-TIMESCALEMOD
-Wno-UNSIGNED
-Wno-LATCH

+incdir+rtl/full_chip/third_party/nic400_1/nic400/verilog/Axi
+incdir+rtl/full_chip/third_party/nic400_1/nic400/verilog/Axi4PC
+incdir+rtl/full_chip/third_party/nic400_1/amib_mDexmpcCore/verilog
+incdir+rtl/full_chip/third_party/nic400_1/amib_mGauxCore/verilog
+incdir+rtl/full_chip/third_party/nic400_1/asib_sD2dData/verilog
+incdir+rtl/full_chip/third_party/nic400_1/asib_sIrisBridge/verilog
+incdir+rtl/full_chip/third_party/nic400_1/asib_sSpi/verilog
+incdir+rtl/full_chip/third_party/nic400_1/busmatrix_bm0/verilog
+incdir+rtl/full_chip/third_party/nic400_1/cdc_blocks/verilog
+incdir+rtl/full_chip/third_party/nic400_1/default_slave_ds_1/verilog
+incdir+rtl/full_chip/third_party/nic400_1/ib_sSpi_ib/verilog
+incdir+rtl/full_chip/third_party/nic400_1/reg_slice/verilog

-y rtl/full_chip/third_party/nic400_1/nic400/verilog
-y rtl/full_chip/third_party/nic400_1/nic400/verilog/Axi
-y rtl/full_chip/third_party/nic400_1/nic400/verilog/Axi4PC
-y rtl/full_chip/third_party/nic400_1/amib_mDexmpcCore/verilog
-y rtl/full_chip/third_party/nic400_1/amib_mGauxCore/verilog
-y rtl/full_chip/third_party/nic400_1/asib_sD2dData/verilog
-y rtl/full_chip/third_party/nic400_1/asib_sIrisBridge/verilog
-y rtl/full_chip/third_party/nic400_1/asib_sSpi/verilog
-y rtl/full_chip/third_party/nic400_1/busmatrix_bm0/verilog
-y rtl/full_chip/third_party/nic400_1/cdc_blocks/verilog
-y rtl/full_chip/third_party/nic400_1/default_slave_ds_1/verilog
-y rtl/full_chip/third_party/nic400_1/ib_sSpi_ib/verilog
-y rtl/full_chip/third_party/nic400_1/reg_slice/verilog

# Keep this before TopChip.sv. TopChip.sv contains an embedded generated
# SramWrapperSp fallback whose simulation mask connection uses scalar
# logical negation; this standalone wrapper uses the required bitwise mask.
rtl/sim_models/SramWrapperSP.sv

rtl/full_chip/src/top/TopChip.sv
rtl/full_chip/src/gaux/GauxCoreBackend.sv
rtl/full_chip/src/gaux/PixelUpdateCoreWrapper.sv
rtl/full_chip/src/iris/IrisTopTmpTemplate.sv

rtl/full_chip/third_party/d2d_spi/JayLinkSlaveBbox.sv
rtl/full_chip/third_party/d2d_spi/d2dSlave.v
rtl/full_chip/third_party/d2d_spi/d2dSync.v

rtl/sim_models/SramFpgaModel.sv
rtl/sim_models/DW_fp_addsub.v
rtl/sim_models/DW_fp_add.v
rtl/sim_models/DW_fp_mult.v
