module JayLinkSlaveBbox (
    input  tri logic        clock,
    input  tri logic        reset,

    input  tri logic        txClock,

    input  tri logic        axiData_ar_ready,
    output tri logic        axiData_ar_valid,
    output tri logic [31:0] axiData_ar_bits_addr,
    output tri logic [4:0]  axiData_ar_bits_id,
    output tri logic [2:0]  axiData_ar_bits_size,
    output tri logic [7:0]  axiData_ar_bits_len,
    output tri logic [1:0]  axiData_ar_bits_burst,
    output tri logic [3:0]  axiData_ar_bits_cache,
    output tri logic        axiData_ar_bits_lock,
    output tri logic [2:0]  axiData_ar_bits_prot,
    //output tri logic [3:0]  axiData_ar_bits_qos,
    //output tri logic [3:0]  axiData_ar_bits_region,

    output tri logic        axiData_r_ready,
    input  tri logic        axiData_r_valid,
    input  tri logic [63:0] axiData_r_bits_data,
    input  tri logic        axiData_r_bits_last,
    input  tri logic [4:0]  axiData_r_bits_id,
    input  tri logic [1:0]  axiData_r_bits_resp,

    input  tri logic        axiData_aw_ready,
    output tri logic        axiData_aw_valid,
    output tri logic [31:0] axiData_aw_bits_addr,
    output tri logic [4:0]  axiData_aw_bits_id,
    output tri logic [2:0]  axiData_aw_bits_size,
    output tri logic [7:0]  axiData_aw_bits_len,
    output tri logic [1:0]  axiData_aw_bits_burst,
    output tri logic [3:0]  axiData_aw_bits_cache,
    output tri logic        axiData_aw_bits_lock,
    output tri logic [2:0]  axiData_aw_bits_prot,
    //output tri logic [3:0]  axiData_aw_bits_qos,
    //output tri logic [3:0]  axiData_aw_bits_region,

    input  tri logic        axiData_w_ready,
    output tri logic        axiData_w_valid,
    output tri logic [63:0] axiData_w_bits_data,
    output tri logic        axiData_w_bits_last,
    output tri logic [7:0]  axiData_w_bits_strb,

    output tri logic        axiData_b_ready,
    input  tri logic        axiData_b_valid,
    input  tri logic [4:0]  axiData_b_bits_id,
    input  tri logic [1:0]  axiData_b_bits_resp,

    output tri logic        jaylink_tx_clock,
    output tri logic        jaylink_tx_flit_valid,
    output tri logic [7:0]  jaylink_tx_flit_bits,
    output tri logic        jaylink_tx_creditARW_free,
    output tri logic        jaylink_tx_replayPkgID,

    input  tri logic        jaylink_rx_clock,
    input  tri logic        jaylink_rx_flit_valid,
    input  tri logic [15:0] jaylink_rx_flit_bits,
    input  tri logic        jaylink_rx_creditRB_free,
    input  tri logic        jaylink_rx_replayPkgID
);

    Sd2dSlave uD2dSlave(
        .clock                                      (clock),
        .reset                                      (reset),

        .io_txClock                                 (txClock),

        .io_AXI4MasterPorts_readAddr_ready          (axiData_ar_ready),
        .io_AXI4MasterPorts_readAddr_valid          (axiData_ar_valid),
        .io_AXI4MasterPorts_readAddr_bits_addr      (axiData_ar_bits_addr),
        .io_AXI4MasterPorts_readAddr_bits_id        (axiData_ar_bits_id),
        .io_AXI4MasterPorts_readAddr_bits_size      (axiData_ar_bits_size),
        .io_AXI4MasterPorts_readAddr_bits_len       (axiData_ar_bits_len),
        .io_AXI4MasterPorts_readAddr_bits_burst     (axiData_ar_bits_burst),
        .io_AXI4MasterPorts_readAddr_bits_cache     (axiData_ar_bits_cache),
        .io_AXI4MasterPorts_readAddr_bits_lock      (axiData_ar_bits_lock),
        .io_AXI4MasterPorts_readAddr_bits_prot      (axiData_ar_bits_prot),
        .io_AXI4MasterPorts_readAddr_bits_qos       (),
        .io_AXI4MasterPorts_readAddr_bits_region    (),

        .io_AXI4MasterPorts_readData_ready          (axiData_r_ready),
        .io_AXI4MasterPorts_readData_valid          (axiData_r_valid),
        .io_AXI4MasterPorts_readData_bits_data      (axiData_r_bits_data),
        .io_AXI4MasterPorts_readData_bits_last      (axiData_r_bits_last),
        .io_AXI4MasterPorts_readData_bits_id        (axiData_r_bits_id),
        .io_AXI4MasterPorts_readData_bits_resp      (axiData_r_bits_resp),

        .io_AXI4MasterPorts_writeAddr_ready         (axiData_aw_ready),
        .io_AXI4MasterPorts_writeAddr_valid         (axiData_aw_valid),
        .io_AXI4MasterPorts_writeAddr_bits_addr     (axiData_aw_bits_addr),
        .io_AXI4MasterPorts_writeAddr_bits_id       (axiData_aw_bits_id),
        .io_AXI4MasterPorts_writeAddr_bits_size     (axiData_aw_bits_size),
        .io_AXI4MasterPorts_writeAddr_bits_len      (axiData_aw_bits_len),
        .io_AXI4MasterPorts_writeAddr_bits_burst    (axiData_aw_bits_burst),
        .io_AXI4MasterPorts_writeAddr_bits_cache    (axiData_aw_bits_cache),
        .io_AXI4MasterPorts_writeAddr_bits_lock     (axiData_aw_bits_lock),
        .io_AXI4MasterPorts_writeAddr_bits_prot     (axiData_aw_bits_prot),
        .io_AXI4MasterPorts_writeAddr_bits_qos      (),
        .io_AXI4MasterPorts_writeAddr_bits_region   (),

        .io_AXI4MasterPorts_writeData_ready         (axiData_w_ready),
        .io_AXI4MasterPorts_writeData_valid         (axiData_w_valid),
        .io_AXI4MasterPorts_writeData_bits_data     (axiData_w_bits_data),
        .io_AXI4MasterPorts_writeData_bits_last     (axiData_w_bits_last),
        .io_AXI4MasterPorts_writeData_bits_strb     (axiData_w_bits_strb),

        .io_AXI4MasterPorts_writeResp_ready         (axiData_b_ready),
        .io_AXI4MasterPorts_writeResp_valid         (axiData_b_valid),
        .io_AXI4MasterPorts_writeResp_bits_id       (axiData_b_bits_id),
        .io_AXI4MasterPorts_writeResp_bits_resp     (axiData_b_bits_resp),

        .io_ctrlBusPorts_readAddr_ready             (),     // output
        .io_ctrlBusPorts_readAddr_valid             (1'b0), // input
        .io_ctrlBusPorts_readAddr_bits_addr         ('0),   // input  [31:0]
        .io_ctrlBusPorts_readAddr_bits_prot         ('0),   // input  [2:0]
        .io_ctrlBusPorts_readData_ready             (1'b0), // input
        .io_ctrlBusPorts_readData_valid             (),     // output
        .io_ctrlBusPorts_readData_bits_data         (),     // output [63:0]
        .io_ctrlBusPorts_readData_bits_resp         (),     // output [1:0]
        .io_ctrlBusPorts_writeAddr_ready            (),     // output
        .io_ctrlBusPorts_writeAddr_valid            (1'b0), // input
        .io_ctrlBusPorts_writeAddr_bits_addr        ('0),   // input  [31:0]
        .io_ctrlBusPorts_writeAddr_bits_prot        ('0),   // input  [2:0]
        .io_ctrlBusPorts_writeData_ready            (),     // output
        .io_ctrlBusPorts_writeData_valid            (1'b0), // input
        .io_ctrlBusPorts_writeData_bits_data        ('0),   // input  [63:0]
        .io_ctrlBusPorts_writeData_bits_strb        ('0),   // input  [7:0]
        .io_ctrlBusPorts_writeResp_ready            (1'b0), // input
        .io_ctrlBusPorts_writeResp_valid            (),     // output
        .io_ctrlBusPorts_writeResp_bits             (),     // output [1:0]

        .io_ARId                                    ('0),
        .io_AWId                                    ('0),
        .io_RId                                     (),
        .io_BId                                     (),

        .io_tx_clock                                (jaylink_tx_clock),
        .io_tx_flit_valid                           (jaylink_tx_flit_valid),
        .io_tx_flit_bits                            (jaylink_tx_flit_bits),
        .io_tx_creditARW_free                       (jaylink_tx_creditARW_free),
        .io_tx_replayPkgID                          (jaylink_tx_replayPkgID),
        .io_rx_clock                                (jaylink_rx_clock),
        .io_rx_flit_valid                           (jaylink_rx_flit_valid),
        .io_rx_flit_bits                            (jaylink_rx_flit_bits),
        .io_rx_creditRB_free                        (jaylink_rx_creditRB_free),
        .io_rx_replayPkgID                          (jaylink_rx_replayPkgID)
    );

endmodule : JayLinkSlaveBbox
