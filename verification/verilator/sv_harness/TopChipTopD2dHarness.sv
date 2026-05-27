module TopChipTopD2dHarness (
    input  logic        clock,
    input  logic        reset,
    input  logic        clock_sel,
    input  logic        d2d_ref_clock,

    output logic        d2dm_ar_ready,
    input  logic        d2dm_ar_valid,
    input  logic [20:0] d2dm_ar_addr,
    input  logic [6:0]  d2dm_ar_id,
    input  logic [7:0]  d2dm_ar_len,
    input  logic        d2dm_r_ready,
    output logic        d2dm_r_valid,
    output logic [63:0] d2dm_r_data,
    output logic        d2dm_r_last,
    output logic [6:0]  d2dm_r_id,
    output logic [1:0]  d2dm_r_resp,

    output logic        d2dm_aw_ready,
    input  logic        d2dm_aw_valid,
    input  logic [20:0] d2dm_aw_addr,
    input  logic [6:0]  d2dm_aw_id,
    input  logic [7:0]  d2dm_aw_len,
    output logic        d2dm_w_ready,
    input  logic        d2dm_w_valid,
    input  logic [63:0] d2dm_w_data,
    input  logic        d2dm_w_last,
    input  logic [7:0]  d2dm_w_strb,
    input  logic        d2dm_b_ready,
    output logic        d2dm_b_valid,
    output logic [6:0]  d2dm_b_id,
    output logic [1:0]  d2dm_b_resp
);

    tri           pad_clock;
    tri           pad_reset;
    tri           pad_clock_sel;
    tri           pad_clock_debug;
    tri           pad_spi_sck;
    tri           pad_spi_ssn;
    tri           pad_spi_mosi;
    tri           pad_spi_miso;
    tri           pad_d2d_tx_clock;
    tri           pad_d2d_tx_flit_valid;
    tri    [7:0]  pad_d2d_tx_flit;
    tri           pad_d2d_tx_creditFree;
    tri           pad_d2d_tx_replayPkgID;
    tri           pad_d2d_rx_clock;
    tri           pad_d2d_rx_flit_valid;
    tri   [15:0]  pad_d2d_rx_flit;
    tri           pad_d2d_rx_creditFree;
    tri           pad_d2d_rx_replayPkgID;
    tri           pad_d2d_mux;
    tri           pad_gaux_complete;
    tri           pad_dexmpc_complete;

    assign pad_clock = clock;
    assign pad_reset = reset;
    assign pad_clock_sel = clock_sel;
    assign pad_spi_sck = 1'b0;
    assign pad_spi_ssn = 1'b1;
    assign pad_spi_mosi = 1'b0;
    assign pad_d2d_mux = 1'b0;

    TopChipTop u_dut (
        .pad_clock              (pad_clock),
        .pad_reset              (pad_reset),
        .pad_clock_sel          (pad_clock_sel),
        .pad_clock_debug        (pad_clock_debug),
        .pad_spi_sck            (pad_spi_sck),
        .pad_spi_ssn            (pad_spi_ssn),
        .pad_spi_miso           (pad_spi_miso),
        .pad_spi_mosi           (pad_spi_mosi),
        .pad_d2d_tx_clock       (pad_d2d_tx_clock),
        .pad_d2d_tx_flit_valid  (pad_d2d_tx_flit_valid),
        .pad_d2d_tx_flit_0      (pad_d2d_tx_flit[0]),
        .pad_d2d_tx_flit_1      (pad_d2d_tx_flit[1]),
        .pad_d2d_tx_flit_2      (pad_d2d_tx_flit[2]),
        .pad_d2d_tx_flit_3      (pad_d2d_tx_flit[3]),
        .pad_d2d_tx_flit_4      (pad_d2d_tx_flit[4]),
        .pad_d2d_tx_flit_5      (pad_d2d_tx_flit[5]),
        .pad_d2d_tx_flit_6      (pad_d2d_tx_flit[6]),
        .pad_d2d_tx_flit_7      (pad_d2d_tx_flit[7]),
        .pad_d2d_tx_creditFree  (pad_d2d_tx_creditFree),
        .pad_d2d_tx_replayPkgID (pad_d2d_tx_replayPkgID),
        .pad_d2d_rx_clock       (pad_d2d_rx_clock),
        .pad_d2d_rx_flit_valid  (pad_d2d_rx_flit_valid),
        .pad_d2d_rx_flit_0      (pad_d2d_rx_flit[0]),
        .pad_d2d_rx_flit_1      (pad_d2d_rx_flit[1]),
        .pad_d2d_rx_flit_2      (pad_d2d_rx_flit[2]),
        .pad_d2d_rx_flit_3      (pad_d2d_rx_flit[3]),
        .pad_d2d_rx_flit_4      (pad_d2d_rx_flit[4]),
        .pad_d2d_rx_flit_5      (pad_d2d_rx_flit[5]),
        .pad_d2d_rx_flit_6      (pad_d2d_rx_flit[6]),
        .pad_d2d_rx_flit_7      (pad_d2d_rx_flit[7]),
        .pad_d2d_rx_flit_8      (pad_d2d_rx_flit[8]),
        .pad_d2d_rx_flit_9      (pad_d2d_rx_flit[9]),
        .pad_d2d_rx_flit_10     (pad_d2d_rx_flit[10]),
        .pad_d2d_rx_flit_11     (pad_d2d_rx_flit[11]),
        .pad_d2d_rx_flit_12     (pad_d2d_rx_flit[12]),
        .pad_d2d_rx_flit_13     (pad_d2d_rx_flit[13]),
        .pad_d2d_rx_flit_14     (pad_d2d_rx_flit[14]),
        .pad_d2d_rx_flit_15     (pad_d2d_rx_flit[15]),
        .pad_d2d_rx_creditFree  (pad_d2d_rx_creditFree),
        .pad_d2d_rx_replayPkgID (pad_d2d_rx_replayPkgID),
        .pad_d2d_mux            (pad_d2d_mux),
        .pad_gaux_complete      (pad_gaux_complete),
        .pad_dexmpc_complete    (pad_dexmpc_complete)
    );

    Md2dMaster u_d2d_master (
        .clock                                      (clock),
        .reset                                      (reset),
        .io_txClock                                 (d2d_ref_clock),
        .io_AXI4SlavePorts_readAddr_ready           (d2dm_ar_ready),
        .io_AXI4SlavePorts_readAddr_valid           (d2dm_ar_valid),
        .io_AXI4SlavePorts_readAddr_bits_addr       (d2dm_ar_addr),
        .io_AXI4SlavePorts_readAddr_bits_id         (d2dm_ar_id),
        .io_AXI4SlavePorts_readAddr_bits_size       (3'd3),
        .io_AXI4SlavePorts_readAddr_bits_len        (d2dm_ar_len),
        .io_AXI4SlavePorts_readAddr_bits_burst      (2'd1),
        .io_AXI4SlavePorts_readAddr_bits_cache      (4'd0),
        .io_AXI4SlavePorts_readAddr_bits_lock       (1'b0),
        .io_AXI4SlavePorts_readAddr_bits_prot       (3'd0),
        .io_AXI4SlavePorts_readAddr_bits_qos        (4'd0),
        .io_AXI4SlavePorts_readAddr_bits_region     (4'd0),
        .io_AXI4SlavePorts_readData_ready           (d2dm_r_ready),
        .io_AXI4SlavePorts_readData_valid           (d2dm_r_valid),
        .io_AXI4SlavePorts_readData_bits_data       (d2dm_r_data),
        .io_AXI4SlavePorts_readData_bits_last       (d2dm_r_last),
        .io_AXI4SlavePorts_readData_bits_id         (d2dm_r_id),
        .io_AXI4SlavePorts_readData_bits_resp       (d2dm_r_resp),
        .io_AXI4SlavePorts_writeAddr_ready          (d2dm_aw_ready),
        .io_AXI4SlavePorts_writeAddr_valid          (d2dm_aw_valid),
        .io_AXI4SlavePorts_writeAddr_bits_addr      (d2dm_aw_addr),
        .io_AXI4SlavePorts_writeAddr_bits_id        (d2dm_aw_id),
        .io_AXI4SlavePorts_writeAddr_bits_size      (3'd3),
        .io_AXI4SlavePorts_writeAddr_bits_len       (d2dm_aw_len),
        .io_AXI4SlavePorts_writeAddr_bits_burst     (2'd1),
        .io_AXI4SlavePorts_writeAddr_bits_cache     (4'd0),
        .io_AXI4SlavePorts_writeAddr_bits_lock      (1'b0),
        .io_AXI4SlavePorts_writeAddr_bits_prot      (3'd0),
        .io_AXI4SlavePorts_writeAddr_bits_qos       (4'd0),
        .io_AXI4SlavePorts_writeAddr_bits_region    (4'd0),
        .io_AXI4SlavePorts_writeData_ready          (d2dm_w_ready),
        .io_AXI4SlavePorts_writeData_valid          (d2dm_w_valid),
        .io_AXI4SlavePorts_writeData_bits_data      (d2dm_w_data),
        .io_AXI4SlavePorts_writeData_bits_last      (d2dm_w_last),
        .io_AXI4SlavePorts_writeData_bits_strb      (d2dm_w_strb),
        .io_AXI4SlavePorts_writeResp_ready          (d2dm_b_ready),
        .io_AXI4SlavePorts_writeResp_valid          (d2dm_b_valid),
        .io_AXI4SlavePorts_writeResp_bits_id        (d2dm_b_id),
        .io_AXI4SlavePorts_writeResp_bits_resp      (d2dm_b_resp),
        .io_ctrlBusPorts_readAddr_ready             (),
        .io_ctrlBusPorts_readAddr_valid             (1'b0),
        .io_ctrlBusPorts_readAddr_bits_addr         (8'd0),
        .io_ctrlBusPorts_readAddr_bits_prot         (3'd0),
        .io_ctrlBusPorts_readData_ready             (1'b0),
        .io_ctrlBusPorts_readData_valid             (),
        .io_ctrlBusPorts_readData_bits_data         (),
        .io_ctrlBusPorts_readData_bits_resp         (),
        .io_ctrlBusPorts_writeAddr_ready            (),
        .io_ctrlBusPorts_writeAddr_valid            (1'b0),
        .io_ctrlBusPorts_writeAddr_bits_addr        (8'd0),
        .io_ctrlBusPorts_writeAddr_bits_prot        (3'd0),
        .io_ctrlBusPorts_writeData_ready            (),
        .io_ctrlBusPorts_writeData_valid            (1'b0),
        .io_ctrlBusPorts_writeData_bits_data        (32'd0),
        .io_ctrlBusPorts_writeData_bits_strb        (4'd0),
        .io_ctrlBusPorts_writeResp_ready            (1'b0),
        .io_ctrlBusPorts_writeResp_valid            (),
        .io_ctrlBusPorts_writeResp_bits             (),
        .io_ARId                                    (7'd0),
        .io_AWId                                    (7'd0),
        .io_RId                                     (),
        .io_BId                                     (),
        .io_tx_clock                                (pad_d2d_rx_clock),
        .io_tx_flit_valid                           (pad_d2d_rx_flit_valid),
        .io_tx_flit_bits                            (pad_d2d_rx_flit),
        .io_tx_creditRB_free                        (pad_d2d_rx_creditFree),
        .io_tx_replayPkgID                          (pad_d2d_rx_replayPkgID),
        .io_rx_clock                                (pad_d2d_tx_clock),
        .io_rx_flit_valid                           (pad_d2d_tx_flit_valid),
        .io_rx_flit_bits                            (pad_d2d_tx_flit),
        .io_rx_creditARW_free                       (pad_d2d_tx_creditFree),
        .io_rx_replayPkgID                          (pad_d2d_tx_replayPkgID)
    );

endmodule
