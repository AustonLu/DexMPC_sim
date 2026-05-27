-timescale=1ns/10ps

// DW
+incdir+/capsule/home/jszhang/Software/icc2020/icc-2020.09-SP3/dw/sim_ver
-y /capsule/home/jszhang/Software/icc2020/icc-2020.09-SP3/dw/sim_ver

// IO pad
-v /basket/techlib/tn12ffc/io/TSMCHOME/digital/Front_End/verilog/tphn12ffcllgv18e_140a/tphn12ffcllgv18e.v
/capsule/home/linyuzheng/workspace/GauX-Chip/src/IO/InputCell.sv
/capsule/home/linyuzheng/workspace/GauX-Chip/src/IO/OutputCell.sv

// TopChipTop
./src/TopChipTop.sv

// TopChip
./src/TopChip.sv

// testbench
// ./tb_TopChipTop_Gaura.sv
./tb/tb_TopChipTop_macarray_d2d.sv


// nic
// // Define the include directory paths for the Auxiliary IP
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mD2dCtrl/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mDexmpcCore/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mGauxCore/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sD2dData/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sIrisBridge/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sSpi/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/busmatrix_bm0/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/cdc_blocks/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/default_slave_ds_1/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/ib_sSpi_ib/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/nic400/verilog
-y /capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/reg_slice/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/nic400/verilog/Axi
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/nic400/verilog/Axi4PC
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mD2dCtrl/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mDexmpcCore/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/amib_mGauxCore/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sD2dData/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sIrisBridge/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/asib_sSpi/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/busmatrix_bm0/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/cdc_blocks/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/default_slave_ds_1/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/ib_sSpi_ib/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/nic400/verilog
+incdir+/capsule/home/linyuzheng/yujiema-miaomiaomiao/arm-socrates/workspace/cihto2026mar/logical/nic400_1/reg_slice/verilog


// d2d
/capsule/home/linyuzheng/workspace/GauX-Chip/src/d2d/d2dMaster.v
/capsule/home/linyuzheng/workspace/GauX-Chip/src/d2d/d2dSlave.v
/capsule/home/linyuzheng/workspace/GauX-Chip/src/d2d/d2dSync.v
/capsule/home/linyuzheng/workspace/GauX-Chip/src/JayLinkSlaveBbox.sv

// SPI
/capsule/home/linyuzheng/workspace/GauX-Chip/src/SpiHost/SpiHost.v

// IrisCore (CTL)
./src/IrisTopTmpTemplate.sv

// DexmpcCore
// ./src/DexMPCCore.sv

// TackleCore
// ./src/TackleCoreTemplate.sv

// GauxCore
// ./src/GauxCore.sv
./src/GauxCoreBackend.sv
./src/PixelUpdateCoreWrapper.sv

// sram
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc1024x128m4sw_130c/VERILOG/ts1n12ffcllsbsvtc1024x128m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc128x16m4sw_130c/VERILOG/ts1n12ffcllsbsvtc128x16m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc128x96m4sw_130c/VERILOG/ts1n12ffcllsbsvtc128x96m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc2048x64m8sw_130c/VERILOG/ts1n12ffcllsbsvtc2048x64m8sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc224x128m4sw_130c/VERILOG/ts1n12ffcllsbsvtc224x128m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc256x32m8sw_130c/VERILOG/ts1n12ffcllsbsvtc256x32m8sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc256x64m4sw_130c/VERILOG/ts1n12ffcllsbsvtc256x64m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc32x128m4sw_130c/VERILOG/ts1n12ffcllsbsvtc32x128m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc512x128m4sw_130c/VERILOG/ts1n12ffcllsbsvtc512x128m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc512x64m4sw_130c/VERILOG/ts1n12ffcllsbsvtc512x64m4sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/ts1n12ffcllsbsvtc64x16m8sw_130c/VERILOG/ts1n12ffcllsbsvtc64x16m8sw_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta1024x64m4w_130c/VERILOG/tsdn12ffcllsvta1024x64m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta128x16m4w_130c/VERILOG/tsdn12ffcllsvta128x16m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta2048x16m4w_130c/VERILOG/tsdn12ffcllsvta2048x16m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta2048x72m4w_130c/VERILOG/tsdn12ffcllsvta2048x72m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta2048x8m4w_130c/VERILOG/tsdn12ffcllsvta2048x8m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta256x32m4w_130c/VERILOG/tsdn12ffcllsvta256x32m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta256x64m4w_130c/VERILOG/tsdn12ffcllsvta256x64m4w_130c.v
/capsule/home/linyuzheng/tech/t12_memory/tsdn12ffcllsvta448x64m4w_130c/VERILOG/tsdn12ffcllsvta448x64m4w_130c.v
// /capsule/home/linyuzheng/workspace/gaura-chip/hw/vsrc/SramFpga_simple.v

// stdcell
// /capsule/home/hzzhu/techlib/tn12ffc/stdcell/TSMCHOME/digital/Front_End/verilog/tcbn12ffcllbwp6t20p96cpd_120a/tcbn12ffcllbwp6t20p96cpd.v
/basket/techlib/tn12ffc/stdcell/TSMCHOME/digital/Front_End/verilog/tcbn12ffcllbwp6t20p96cpd_120a/tcbn12ffcllbwp6t20p96cpd.v

// CKBUFF behavior
./src/EmptyCKBUFF.sv

