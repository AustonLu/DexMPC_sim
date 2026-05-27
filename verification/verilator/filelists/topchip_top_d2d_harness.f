# Verilator file list for the pad-level full-chip top with a D2D host harness.
#
# The harness instantiates TopChipTop and the legacy Md2dMaster model used by
# verification/sv_tb/full_chip/legacy/TopChipTop_tb.sv. C++ tests drive the
# harness AXI-like D2D master-side command ports.

-f verification/verilator/filelists/topchip_top.f

rtl/full_chip/third_party/d2d_spi/d2dMaster.v
verification/verilator/sv_harness/TopChipTopD2dHarness.sv
