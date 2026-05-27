// `default_nettype none

module TopChipTop(
    inout  wire         pad_clock,
    inout  wire         pad_reset,

    inout  wire         pad_clock_sel,
    inout  wire         pad_clock_debug,

    inout  wire         pad_spi_sck,
    inout  wire         pad_spi_ssn,
    inout  wire         pad_spi_miso,
    inout  wire         pad_spi_mosi,

    inout  wire         pad_d2d_tx_clock,
    inout  wire         pad_d2d_tx_flit_valid,
    inout  wire         pad_d2d_tx_flit_0,
    inout  wire         pad_d2d_tx_flit_1,
    inout  wire         pad_d2d_tx_flit_2,
    inout  wire         pad_d2d_tx_flit_3,
    inout  wire         pad_d2d_tx_flit_4,
    inout  wire         pad_d2d_tx_flit_5,
    inout  wire         pad_d2d_tx_flit_6,
    inout  wire         pad_d2d_tx_flit_7,
    inout  wire         pad_d2d_tx_creditFree,
    inout  wire         pad_d2d_tx_replayPkgID,
    inout  wire         pad_d2d_rx_clock,
    inout  wire         pad_d2d_rx_flit_valid,
    inout  wire         pad_d2d_rx_flit_0,
    inout  wire         pad_d2d_rx_flit_1,
    inout  wire         pad_d2d_rx_flit_2,
    inout  wire         pad_d2d_rx_flit_3,
    inout  wire         pad_d2d_rx_flit_4,
    inout  wire         pad_d2d_rx_flit_5,
    inout  wire         pad_d2d_rx_flit_6,
    inout  wire         pad_d2d_rx_flit_7,
    inout  wire         pad_d2d_rx_flit_8,
    inout  wire         pad_d2d_rx_flit_9,
    inout  wire         pad_d2d_rx_flit_10,
    inout  wire         pad_d2d_rx_flit_11,
    inout  wire         pad_d2d_rx_flit_12,
    inout  wire         pad_d2d_rx_flit_13,
    inout  wire         pad_d2d_rx_flit_14,
    inout  wire         pad_d2d_rx_flit_15,
    inout  wire         pad_d2d_rx_creditFree,
    inout  wire         pad_d2d_rx_replayPkgID,
    inout  wire         pad_d2d_mux,

    inout  wire         pad_gaux_complete,
    // inout  wire         pad_tackle_complete,
    inout  wire         pad_dexmpc_complete
);

    wire clkgen_ckbuff_high_en;
    wire clkgen_current_in;
    wire clkgen_half_vdd;
    wire clkgen_vin;
    wire clkgen_vip;
    // wire clkgen_vss;
    // wire clkgen_vdd;
    wire core_clock_F;

    logic core_clock;
    logic core_reset;
    logic core_clock_sel;
    logic core_clock_debug;
    logic core_spi_sck;
    logic core_spi_ssn;
    logic core_spi_mosi;
    logic core_spi_miso;
    logic core_spi_misoValid;
    logic core_d2d_tx_clock;
    logic core_d2d_tx_flit_valid;
    logic [7:0] core_d2d_tx_flit;
    logic core_d2d_tx_creditFree;
    logic core_d2d_tx_replayPkgID;
    logic core_d2d_rx_clock;
    logic core_d2d_rx_flit_valid;
    logic [15:0] core_d2d_rx_flit;
    logic core_d2d_rx_creditFree;
    logic core_d2d_rx_replayPkgID;
    logic core_d2d_mux;
    logic gaux_core_state;
    // logic tackle_core_state;
    logic dexmpc_core_state;
    
    // clock
    InputCell #( .DIRECTION_V(1) ) uInputCell_clock ( .pad(pad_clock), .core_i(core_clock), .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(1) ) uInputCell_reset ( .pad(pad_reset), .core_i(core_reset), .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(1) ) uInputCell_clock_sel ( .pad(pad_clock_sel), .core_i(core_clock_sel), .input_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_clock_debug ( .pad(pad_clock_debug), .core_o(core_clock_debug), .output_enable(1'b1) );

    // SPI
    InputCell #( .DIRECTION_V(1) ) uInputCell_spi_sck    ( .pad(pad_spi_sck),  .core_i(core_spi_sck),  .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(1) ) uInputCell_spi_ssn    ( .pad(pad_spi_ssn),  .core_i(core_spi_ssn),  .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(1) ) uInputCell_spi_mosi   ( .pad(pad_spi_mosi), .core_i(core_spi_mosi), .input_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_spi_miso ( .pad(pad_spi_miso), .core_o(core_spi_miso), .output_enable(core_spi_misoValid) );

    // D2D TX
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_clock       ( .pad(pad_d2d_tx_clock),       .core_o(core_d2d_tx_clock),       .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_valid  ( .pad(pad_d2d_tx_flit_valid),  .core_o(core_d2d_tx_flit_valid),  .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_0      ( .pad(pad_d2d_tx_flit_0),      .core_o(core_d2d_tx_flit[0]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_1      ( .pad(pad_d2d_tx_flit_1),      .core_o(core_d2d_tx_flit[1]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_2      ( .pad(pad_d2d_tx_flit_2),      .core_o(core_d2d_tx_flit[2]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_3      ( .pad(pad_d2d_tx_flit_3),      .core_o(core_d2d_tx_flit[3]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_4      ( .pad(pad_d2d_tx_flit_4),      .core_o(core_d2d_tx_flit[4]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_5      ( .pad(pad_d2d_tx_flit_5),      .core_o(core_d2d_tx_flit[5]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_6      ( .pad(pad_d2d_tx_flit_6),      .core_o(core_d2d_tx_flit[6]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_flit_7      ( .pad(pad_d2d_tx_flit_7),      .core_o(core_d2d_tx_flit[7]),     .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_creditFree  ( .pad(pad_d2d_tx_creditFree),  .core_o(core_d2d_tx_creditFree),  .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_d2d_tx_replayPkgID ( .pad(pad_d2d_tx_replayPkgID), .core_o(core_d2d_tx_replayPkgID), .output_enable(1'b1) );

    // D2D RX
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_clock       ( .pad(pad_d2d_rx_clock),       .core_i(core_d2d_rx_clock),       .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_valid  ( .pad(pad_d2d_rx_flit_valid),  .core_i(core_d2d_rx_flit_valid),  .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_0      ( .pad(pad_d2d_rx_flit_0),      .core_i(core_d2d_rx_flit[0]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_1      ( .pad(pad_d2d_rx_flit_1),      .core_i(core_d2d_rx_flit[1]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_2      ( .pad(pad_d2d_rx_flit_2),      .core_i(core_d2d_rx_flit[2]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_3      ( .pad(pad_d2d_rx_flit_3),      .core_i(core_d2d_rx_flit[3]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_4      ( .pad(pad_d2d_rx_flit_4),      .core_i(core_d2d_rx_flit[4]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_5      ( .pad(pad_d2d_rx_flit_5),      .core_i(core_d2d_rx_flit[5]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_6      ( .pad(pad_d2d_rx_flit_6),      .core_i(core_d2d_rx_flit[6]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_7      ( .pad(pad_d2d_rx_flit_7),      .core_i(core_d2d_rx_flit[7]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_8      ( .pad(pad_d2d_rx_flit_8),      .core_i(core_d2d_rx_flit[8]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_9      ( .pad(pad_d2d_rx_flit_9),      .core_i(core_d2d_rx_flit[9]),     .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_10     ( .pad(pad_d2d_rx_flit_10),     .core_i(core_d2d_rx_flit[10]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_11     ( .pad(pad_d2d_rx_flit_11),     .core_i(core_d2d_rx_flit[11]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_12     ( .pad(pad_d2d_rx_flit_12),     .core_i(core_d2d_rx_flit[12]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_13     ( .pad(pad_d2d_rx_flit_13),     .core_i(core_d2d_rx_flit[13]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_14     ( .pad(pad_d2d_rx_flit_14),     .core_i(core_d2d_rx_flit[14]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_flit_15     ( .pad(pad_d2d_rx_flit_15),     .core_i(core_d2d_rx_flit[15]),    .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_creditFree  ( .pad(pad_d2d_rx_creditFree),  .core_i(core_d2d_rx_creditFree),  .input_enable(1'b1) );
    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_rx_replayPkgID ( .pad(pad_d2d_rx_replayPkgID), .core_i(core_d2d_rx_replayPkgID), .input_enable(1'b1) );

    InputCell #( .DIRECTION_V(0) ) uInputCell_d2d_mux            ( .pad(pad_d2d_mux),            .core_i(core_d2d_mux), .input_enable(1'b1) );

    OutputCell #( .DIRECTION_V(1) ) uOutputCell_gaux_complete  ( .pad(pad_gaux_complete),  .core_o(gaux_core_state),  .output_enable(1'b1) );
    // OutputCell #( .DIRECTION_V(1) ) uOutputCell_tackle_complete ( .pad(pad_tackle_complete), .core_o(tackle_core_state), .output_enable(1'b1) );
    OutputCell #( .DIRECTION_V(1) ) uOutputCell_dexmpc_complete ( .pad(pad_dexmpc_complete), .core_o(dexmpc_core_state), .output_enable(1'b1) );

    // Analog module by CZX
    PDB3AC_H pad_ckg_ckbuff_high_en (.AIO(clkgen_ckbuff_high_en ));
    PDB3AC_H pad_ckg_half_vdd       (.AIO(clkgen_half_vdd       ));
    PDB3AC_H pad_ckg_vin            (.AIO(clkgen_vin            ));
    // PVDD3ACM_H pad_ckg_vdd (); // backend 
    // PVDD3ACM_H pad_ckg_vss (); // backend 
    PDB3AC_H pad_ckg_vip            (.AIO(clkgen_vip            ));
    PDB3AC_H pad_ckg_current_in     (.AIO(clkgen_current_in     ));
    CKBUFF uCKBUFF (
        .ckbuff_high_en (clkgen_ckbuff_high_en  ),
        .current_in     (clkgen_current_in      ),
        .half_vdd       (clkgen_half_vdd        ),
        .vin            (clkgen_vin             ),
        .vip            (clkgen_vip             ),
        .ck_out         (core_clock_F                ),
        .ckb_out        (/*clock_b_F*/          )
    );

    TopChip uChip (
        .clock                  (core_clock),       // input digital clock
        .clock_F                (core_clock_F),          // input analog clock
        .clock_sel              (core_clock_sel),   // select clock in SysClockGen
        .reset                  (core_reset),       // input
	    .clock_debug		    (core_clock_debug),

        .spi_sck                (core_spi_sck), // input
        .spi_ssn                (core_spi_ssn), // input
        .spi_mosi               (core_spi_mosi), // input
        .spi_miso               (core_spi_miso), // output
        .spi_misoValid          (core_spi_misoValid), // output

        .d2d_tx_clock           (core_d2d_tx_clock), // output
        .d2d_tx_flit_valid      (core_d2d_tx_flit_valid), // output
        .d2d_tx_flit_bits       (core_d2d_tx_flit), // output 7:0
        .d2d_tx_creditARW_free  (core_d2d_tx_creditFree), // output
        .d2d_tx_replayPkgID     (core_d2d_tx_replayPkgID), // output

        .d2d_rx_clock           (core_d2d_rx_clock), // input
        .d2d_rx_flit_valid      (core_d2d_rx_flit_valid), // input
        .d2d_rx_flit_bits       (core_d2d_rx_flit), // input 15:0
        .d2d_rx_creditRB_free   (core_d2d_rx_creditFree), // input
        .d2d_rx_replayPkgID     (core_d2d_rx_replayPkgID), // input

        .d2d_mux                (core_d2d_mux),

        .gaux_core_state             (gaux_core_state), // output
        // .tackleState            (tackle_core_state), // output
        .dexmpc_core_state            (dexmpc_core_state) // output
    );

endmodule: TopChipTop
