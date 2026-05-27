module TopChipTop_tb #(parameter int Burst = 3) ();

    parameter CLK_PERIOD = 4;

    logic clock = 1'b1; // 500 MHz
    logic reset = 1'b0;
    logic d2d_mux_signal = 1'b0;
    logic clock_sel = 1'b1;
    initial begin
        forever #(CLK_PERIOD/2) clock = ~clock;
    end
    initial begin
        clock_sel = 1'b1;
        reset = 1'b0;
        @(negedge clock);
        reset = 1'b1;
        clock_sel = 1'b0;
        repeat (3) @(negedge clock);
        reset = 1'b0;
        $display("System reset completed at %t.", $time);
    end

// =============================================================================
//  Instantiations
    // ArcherChip Inputs
    tri           top_clock = clock;
    tri           top_reset = reset;
    tri           top_clock_sel = clock_sel;
    tri           top_clock_debug;

    tri           d2d_rx_clock;
    tri           d2d_rx_flit_valid;
    tri   [15:0]  d2d_rx_flit_bits;
    tri           d2d_rx_creditRB_free;
    tri           d2d_rx_replayPkgID;
    tri           spi_ssn;
    tri           spi_sck;
    tri           spi_mosi;

    // ArcherChip Outputs
    tri           d2d_tx_clock;
    tri           d2d_tx_flit_valid;
    tri    [7:0]  d2d_tx_flit_bits;
    tri           d2d_tx_creditARW_free;
    tri           d2d_tx_replayPkgID;
    tri           d2d_mux = d2d_mux_signal;
    tri           spi_miso;
    tri           spi_misoValid;
    tri           gaux_complete;
    tri           dexmpc_complete;

    logic [64*Burst-1:0] wrcmd_data = 0;
    logic           wrcmd_valid = 0;
    logic [20:0]    wrcmd_addr;
    logic [6:0]     wrcmd_id;
    logic [7:0]     wrcmd_len;
    logic           wrcmd_complete;
    logic [64*Burst-1:0] rdcmd_data;
    logic           rdcmd_valid = 0;
    logic [20:0]    rdcmd_addr;
    logic [6:0]     rdcmd_id;
    logic [7:0]     rdcmd_len;
    logic           rdcmd_complete;
    logic           d2dm_ar_ready;
    logic           d2dm_ar_valid;
    logic [20:0]    d2dm_ar_addr;
    logic [6:0]     d2dm_ar_id;
    logic [7:0]     d2dm_ar_len;
    logic           d2dm_r_ready;
    logic           d2dm_r_valid;
    logic [63:0]    d2dm_r_data;
    logic           d2dm_r_last;
    logic [6:0]     d2dm_r_id;
    logic [1:0]     d2dm_r_resp;
    logic           d2dm_aw_ready;
    logic           d2dm_aw_valid;
    logic [20:0]    d2dm_aw_addr;
    logic [6:0]     d2dm_aw_id;
    logic [7:0]     d2dm_aw_len;
    logic           d2dm_w_ready;
    logic           d2dm_w_valid;
    logic [63:0]    d2dm_w_data;
    logic           d2dm_w_last;
    logic           d2dm_b_ready;
    logic           d2dm_b_valid;
    logic [6:0]     d2dm_b_id;
    logic [1:0]     d2dm_b_resp;

    logic spi_start;
    logic spi_complete;
    logic [79:0]  spi_tx_data;
    logic [31:0]  spi_rx_data;
    logic spi_rx_valid;
    logic spi_clock = 1'b1;
    initial begin
        forever #8ns spi_clock = ~spi_clock;
    end
    logic d2d_clock = 1'b1;
    initial begin
        forever #1ns d2d_clock = ~clock; // 100 MHz
    end

    SpiHost #(
        .DW        (80),
        .RX        (32)
    ) uSpiHost(
        .clk           (spi_clock),
        .rst           (reset),
        .spi_start     (spi_start),
        .spi_complete  (spi_complete),
        .spi_tx_data   (spi_tx_data),
        .spi_rx_data   (spi_rx_data),
        .spi_rx_valid  (spi_rx_valid),
        .spi_sck       (spi_sck),
        .spi_csn       (spi_ssn),
        .spi_mosi      (spi_mosi),
        .spi_miso      (spi_miso)
    );

    d2dm_burst_writer #(
        .Burst (3)
    ) ud2dm_burst_writer(
        .clock            (clock),
        .reset            (reset),
        .cmd_valid        (wrcmd_valid),
        .cmd_addr         (wrcmd_addr),
        .cmd_id           (wrcmd_id),
        .cmd_len          (wrcmd_len),
        .cmd_data         (wrcmd_data),
        .cmd_complete     (wrcmd_complete),
        .d2dm_aw_ready    (d2dm_aw_ready),
        .d2dm_aw_valid    (d2dm_aw_valid),
        .d2dm_aw_addr     (d2dm_aw_addr),
        .d2dm_aw_id       (d2dm_aw_id),
        .d2dm_aw_len      (d2dm_aw_len),
        .d2dm_w_ready     (d2dm_w_ready),
        .d2dm_w_valid     (d2dm_w_valid),
        .d2dm_w_data      (d2dm_w_data),
        .d2dm_w_last      (d2dm_w_last),
        .d2dm_b_ready     (d2dm_b_ready),
        .d2dm_b_valid     (d2dm_b_valid),
        .d2dm_b_id        (d2dm_b_id),
        .d2dm_b_resp      (d2dm_b_resp)
    );

    d2dm_burst_reader #(
        .Burst (3)
    ) ud2dm_burst_reader(
        .clock            (clock),
        .reset            (reset),
        .cmd_valid        (rdcmd_valid),
        .cmd_addr         (rdcmd_addr),
        .cmd_id           (rdcmd_id),
        .cmd_len          (rdcmd_len),
        .cmd_data         (rdcmd_data),
        .cmd_complete     (rdcmd_complete),
        .d2dm_ar_ready    (d2dm_ar_ready),
        .d2dm_ar_valid    (d2dm_ar_valid),
        .d2dm_ar_addr     (d2dm_ar_addr),
        .d2dm_ar_id       (d2dm_ar_id),
        .d2dm_ar_len      (d2dm_ar_len),
        .d2dm_r_ready     (d2dm_r_ready),
        .d2dm_r_valid     (d2dm_r_valid),
        .d2dm_r_data      (d2dm_r_data),
        .d2dm_r_last      (d2dm_r_last),
        .d2dm_r_id        (d2dm_r_id),
        .d2dm_r_resp      (d2dm_r_resp)
    );

    Md2dMaster uD2dMaster (
        .clock,
        .reset,
        .io_txClock     (d2d_clock),

        .io_AXI4SlavePorts_readAddr_ready       (d2dm_ar_ready),
        .io_AXI4SlavePorts_readAddr_valid       (d2dm_ar_valid),
        .io_AXI4SlavePorts_readAddr_bits_addr   (d2dm_ar_addr),
        .io_AXI4SlavePorts_readAddr_bits_id     (d2dm_ar_id),
        .io_AXI4SlavePorts_readAddr_bits_size   (3'd3),
        .io_AXI4SlavePorts_readAddr_bits_len    (d2dm_ar_len),
        .io_AXI4SlavePorts_readAddr_bits_burst  (2'd1),
        .io_AXI4SlavePorts_readAddr_bits_cache  ('0),
        .io_AXI4SlavePorts_readAddr_bits_lock   ('0),
        .io_AXI4SlavePorts_readAddr_bits_prot   ('0),
        .io_AXI4SlavePorts_readAddr_bits_qos    ('0),
        .io_AXI4SlavePorts_readAddr_bits_region ('0),
        .io_AXI4SlavePorts_readData_ready       (d2dm_r_ready),
        .io_AXI4SlavePorts_readData_valid       (d2dm_r_valid),
        .io_AXI4SlavePorts_readData_bits_data   (d2dm_r_data),
        .io_AXI4SlavePorts_readData_bits_last   (d2dm_r_last),
        .io_AXI4SlavePorts_readData_bits_id     (d2dm_r_id),
        .io_AXI4SlavePorts_readData_bits_resp   (d2dm_r_resp),
        .io_AXI4SlavePorts_writeAddr_ready      (d2dm_aw_ready),
        .io_AXI4SlavePorts_writeAddr_valid      (d2dm_aw_valid),
        .io_AXI4SlavePorts_writeAddr_bits_addr  (d2dm_aw_addr),
        .io_AXI4SlavePorts_writeAddr_bits_id    (d2dm_aw_id),
        .io_AXI4SlavePorts_writeAddr_bits_size  (3'd3),
        .io_AXI4SlavePorts_writeAddr_bits_len   (d2dm_aw_len),
        .io_AXI4SlavePorts_writeAddr_bits_burst (2'd1),
        .io_AXI4SlavePorts_writeAddr_bits_cache ('0),
        .io_AXI4SlavePorts_writeAddr_bits_lock  ('0),
        .io_AXI4SlavePorts_writeAddr_bits_prot  ('0),
        .io_AXI4SlavePorts_writeAddr_bits_qos   ('0),
        .io_AXI4SlavePorts_writeAddr_bits_region('0),
        .io_AXI4SlavePorts_writeData_ready      (d2dm_w_ready),
        .io_AXI4SlavePorts_writeData_valid      (d2dm_w_valid),
        .io_AXI4SlavePorts_writeData_bits_data  (d2dm_w_data),
        .io_AXI4SlavePorts_writeData_bits_last  (d2dm_w_last),
        .io_AXI4SlavePorts_writeData_bits_strb  (8'hff),
        .io_AXI4SlavePorts_writeResp_ready      (d2dm_b_ready),
        .io_AXI4SlavePorts_writeResp_valid      (d2dm_b_valid),
        .io_AXI4SlavePorts_writeResp_bits_id    (d2dm_b_id),
        .io_AXI4SlavePorts_writeResp_bits_resp  (d2dm_b_resp),

        .io_ctrlBusPorts_readAddr_ready      (),
        .io_ctrlBusPorts_readAddr_valid      (1'b0),
        .io_ctrlBusPorts_readAddr_bits_addr  ('0),
        .io_ctrlBusPorts_readAddr_bits_prot  ('0),
        .io_ctrlBusPorts_readData_ready      (1'b0),
        .io_ctrlBusPorts_readData_valid      (),
        .io_ctrlBusPorts_readData_bits_data  (),
        .io_ctrlBusPorts_readData_bits_resp  (),
        .io_ctrlBusPorts_writeAddr_ready     (),
        .io_ctrlBusPorts_writeAddr_valid     (1'b0),
        .io_ctrlBusPorts_writeAddr_bits_addr ('0),
        .io_ctrlBusPorts_writeData_ready     (),
        .io_ctrlBusPorts_writeData_valid     (1'b0),
        .io_ctrlBusPorts_writeData_bits_data ('0),
        .io_ctrlBusPorts_writeData_bits_strb ('0),
        .io_ctrlBusPorts_writeResp_ready     (1'b0),
        .io_ctrlBusPorts_writeResp_valid     (),
        .io_ctrlBusPorts_writeResp_bits      (),

        .io_ARId ('0),
        .io_AWId ('0),
        .io_RId  (),
        .io_BId  (),

        .io_tx_clock            (d2d_rx_clock),
        .io_tx_flit_valid       (d2d_rx_flit_valid),
        .io_tx_flit_bits        (d2d_rx_flit_bits),
        .io_tx_creditRB_free    (d2d_rx_creditRB_free),
        .io_tx_replayPkgID      (d2d_rx_replayPkgID),
        .io_rx_clock            (d2d_tx_clock),
        .io_rx_flit_valid       (d2d_tx_flit_valid),
        .io_rx_flit_bits        (d2d_tx_flit_bits),
        .io_rx_creditARW_free   (d2d_tx_creditARW_free),
        .io_rx_replayPkgID      (d2d_tx_replayPkgID)
    );

    TopChipTop dut (
        .pad_clock(top_clock),
        .pad_reset(top_reset),
        .pad_clock_sel(top_clock_sel),
        .pad_clock_debug(top_clock_debug),
        .pad_spi_sck(spi_sck),
        .pad_spi_ssn(spi_ssn),
        .pad_spi_miso(spi_miso),
        .pad_spi_mosi(spi_mosi),
        .pad_d2d_tx_clock(d2d_tx_clock),
        .pad_d2d_tx_flit_valid(d2d_tx_flit_valid),
        .pad_d2d_tx_flit_0(d2d_tx_flit_bits[0]),
        .pad_d2d_tx_flit_1(d2d_tx_flit_bits[1]),
        .pad_d2d_tx_flit_2(d2d_tx_flit_bits[2]),
        .pad_d2d_tx_flit_3(d2d_tx_flit_bits[3]),
        .pad_d2d_tx_flit_4(d2d_tx_flit_bits[4]),
        .pad_d2d_tx_flit_5(d2d_tx_flit_bits[5]),
        .pad_d2d_tx_flit_6(d2d_tx_flit_bits[6]),
        .pad_d2d_tx_flit_7(d2d_tx_flit_bits[7]),
        .pad_d2d_tx_creditFree(d2d_tx_creditARW_free),
        .pad_d2d_tx_replayPkgID(d2d_tx_replayPkgID),
        .pad_d2d_rx_clock(d2d_rx_clock),
        .pad_d2d_rx_flit_valid(d2d_rx_flit_valid),
        .pad_d2d_rx_flit_0(d2d_rx_flit_bits[0]),
        .pad_d2d_rx_flit_1(d2d_rx_flit_bits[1]),
        .pad_d2d_rx_flit_2(d2d_rx_flit_bits[2]),
        .pad_d2d_rx_flit_3(d2d_rx_flit_bits[3]),
        .pad_d2d_rx_flit_4(d2d_rx_flit_bits[4]),
        .pad_d2d_rx_flit_5(d2d_rx_flit_bits[5]),
        .pad_d2d_rx_flit_6(d2d_rx_flit_bits[6]),
        .pad_d2d_rx_flit_7(d2d_rx_flit_bits[7]),
        .pad_d2d_rx_flit_8(d2d_rx_flit_bits[8]),
        .pad_d2d_rx_flit_9(d2d_rx_flit_bits[9]),
        .pad_d2d_rx_flit_10(d2d_rx_flit_bits[10]),
        .pad_d2d_rx_flit_11(d2d_rx_flit_bits[11]),
        .pad_d2d_rx_flit_12(d2d_rx_flit_bits[12]),
        .pad_d2d_rx_flit_13(d2d_rx_flit_bits[13]),
        .pad_d2d_rx_flit_14(d2d_rx_flit_bits[14]),
        .pad_d2d_rx_flit_15(d2d_rx_flit_bits[15]),
        .pad_d2d_rx_creditFree(d2d_rx_creditRB_free),
        .pad_d2d_rx_replayPkgID(d2d_rx_replayPkgID),
        .pad_d2d_mux(d2d_mux),
        .pad_gaux_complete(gaux_complete),
        .pad_dexmpc_complete(dexmpc_complete)
    );

// =============================================================================
//  DexMPC Address Map Helpers
    localparam [31:0] BASE_DEXMPC_ADDR = 32'h0000_0000; // 0x00000
    localparam int unsigned MPC_CFG_TOTAL_REG_COUNT = 58;
    localparam int unsigned MPC_CFG_RW_TEST_REG_COUNT = 22;

    function automatic [31:0] mpc_cfg_addr(input int unsigned reg_idx);
        mpc_cfg_addr = BASE_DEXMPC_ADDR + (reg_idx[31:0] << 3);
    endfunction

    function automatic [31:0] mpc_sram_addr(input int unsigned mem_id, input int unsigned word_addr);
        mpc_sram_addr = BASE_DEXMPC_ADDR + ((32'h0000_8000 + (mem_id << 11) + word_addr) << 3);
    endfunction

    function automatic [31:0] cfg_test_pattern(input int unsigned reg_idx, input int unsigned phase);
        logic [31:0] reg_idx_word;
    begin
        reg_idx_word = reg_idx[31:0];
        case (phase[1:0])
            2'd0: cfg_test_pattern = 32'hA5A5_5A5A ^ (reg_idx_word * 32'h0101_0001);
            2'd1: cfg_test_pattern = 32'h3C3C_C3C3 ^ {reg_idx_word[7:0], ~reg_idx_word[7:0], 8'h96, 8'h69};
            2'd2: cfg_test_pattern = 32'h1357_9BDF ^ {8'h5A, reg_idx_word[7:0], 8'hA5, ~reg_idx_word[7:0]};
            default: cfg_test_pattern = 32'hFEED_1234 ^ (reg_idx_word * 32'h1021_0011);
        endcase
        if (cfg_test_pattern == 32'h0000_0000) begin
            cfg_test_pattern = 32'h0000_0001;
        end
    end
    endfunction

    function automatic int unsigned sram_depth(input int unsigned mem_id);
    begin
        case (mem_id)
            4'h0: sram_depth = 2048;
            4'h1, 4'h2, 4'h3, 4'h4: sram_depth = 512;
            4'h5, 4'h6, 4'h7, 4'h8: sram_depth = 896;
            4'h9, 4'hA, 4'hB, 4'hC: sram_depth = 128;
            4'hD, 4'hE: sram_depth = 256;
            default: sram_depth = 1;
        endcase
    end
    endfunction

    function automatic int unsigned sram_data_width(input int unsigned mem_id);
    begin
        case (mem_id)
            4'h9, 4'hA, 4'hB, 4'hC: sram_data_width = 16;
            4'hD, 4'hE: sram_data_width = 32;
            default: sram_data_width = 128;
        endcase
    end
    endfunction

    function automatic int unsigned sram_test_addr(input int unsigned mem_id, input int unsigned slot);
        int unsigned depth;
    begin
        depth = sram_depth(mem_id);
        case (slot)
            0: sram_test_addr = 0;
            1: sram_test_addr = (depth > 1) ? (depth - 1) : 0;
            default: sram_test_addr = (depth > 2) ? (depth >> 1) : 0;
        endcase
    end
    endfunction

    function automatic [127:0] sram_valid_mask(input int unsigned mem_id);
        int unsigned width;
    begin
        width = sram_data_width(mem_id);
        case (width)
            16:  sram_valid_mask = {{112{1'b0}}, 16'hFFFF};
            32:  sram_valid_mask = {{96{1'b0}}, 32'hFFFF_FFFF};
            default: sram_valid_mask = {128{1'b1}};
        endcase
    end
    endfunction

    function automatic [127:0] sram_test_pattern(
        input int unsigned mem_id,
        input int unsigned word_addr,
        input int unsigned phase
    );
        logic [31:0] lane0;
        logic [31:0] lane1;
        logic [31:0] lane2;
        logic [31:0] lane3;
        logic [31:0] mix;
    begin
        mix = (mem_id[31:0] * 32'h0101_0011) ^ (word_addr[31:0] * 32'h0010_1101) ^ (phase[31:0] * 32'h1021_0001);
        lane0 = 32'h0123_4567 ^ mix;
        lane1 = 32'h89AB_CDEF ^ {mix[15:0], mix[31:16]};
        lane2 = 32'h1357_9BDF ^ {~mix[7:0], mix[31:8]};
        lane3 = 32'hFEDC_BA98 ^ {mix[23:0], mix[31:24]};
        sram_test_pattern = {lane3, lane2, lane1, lane0};
    end
    endfunction

// =============================================================================
//  Testbench tasks
    integer i;
    task spi_write(
        input [31:0] waddr,
        input [31:0] wdata
    );
    begin
        repeat(4) @(posedge spi_clock);
        spi_start     = 1'b1;
        spi_tx_data   = (80'b1000_0000 << 72) + ({waddr, 40'b0}) + ({wdata,8'b0});
        repeat(161) @(posedge spi_clock);
        spi_start = 1'b0;
    end
    endtask

    task spi_read(
        input  [31:0] raddr,
        output logic [31:0] rdata
    );
    begin
        repeat(4) @(posedge spi_clock);
        spi_start     = 1'b1;
        spi_tx_data   = (80'b1100_0000 << 72) + ({raddr, 40'b0});
        repeat(161) @(posedge spi_clock);
        spi_start = 1'b0;
        rdata     = spi_rx_data;
    end
    endtask

    task spi_write_read(
        input [31:0] addr,
        input [31:0] wdata
    );
    begin
        logic [31:0] rdata;
        spi_write(.wdata(wdata), .waddr(addr));
        spi_read (.raddr(addr),  .rdata(rdata));
        if (!(wdata === rdata)) begin
            $display("%t ******* SPI WR FAIL! write %h to %h, read %h", $time, wdata, addr, rdata);
        end else begin
            $display("%t: SPI WR PASS addr=%h", $time, addr);
        end
    end
    endtask

    task spi_write_64(
        input [31:0] addr,
        input [63:0] wdata
    );
    begin
        spi_write(.wdata(wdata[31:0]),  .waddr(addr));
        spi_write(.wdata(wdata[63:32]), .waddr(addr+4));
    end
    endtask

    task spi_read_64(
        input  [31:0] addr,
        output [63:0] rdata
    );
    begin
        spi_read(.rdata(rdata[31:0]),  .raddr(addr));
        spi_read(.rdata(rdata[63:32]), .raddr(addr+4));
    end
    endtask

    task spi_write_read_128_sameaddr(
        input [31:0]  addr,
        input [127:0] wdata
    );
    begin
        logic [127:0] rdata;
        spi_write_64(addr, wdata[63:0]);
        spi_write_64(addr, wdata[127:64]);
        spi_read_64(addr, rdata[63:0]);
        spi_read_64(addr, rdata[127:64]);
        if (!(wdata === rdata)) begin
            $display("%t ******* SPI 128 WR FAIL! addr=%h w=%h r=%h", $time, addr, wdata, rdata);
        end else begin
            $display("%t: SPI 128 WR PASS addr=%h", $time, addr);
        end
    end
    endtask

    task d2d_write(
        input  logic [21:0]        cmd_addr,
        input  logic [6:0]         cmd_id,
        input  logic [7:0]         cmd_len,
        input  logic [64*Burst-1:0] cmd_data
    );
        @(negedge clock);
        wrcmd_valid = 1'b1;
        wrcmd_addr = cmd_addr[20:0];
        wrcmd_id = cmd_id;
        wrcmd_len = cmd_len;
        wrcmd_data = cmd_data;
        @(negedge clock);
        wrcmd_valid = 1'b0;
        @(negedge clock iff(wrcmd_complete));
    endtask

    task d2d_read(
        input  logic [21:0]         cmd_addr,
        input  logic [6:0]          cmd_id,
        input  logic [7:0]          cmd_len,
        output logic [64*Burst-1:0] cmd_data
    );
        @(negedge clock);
        rdcmd_valid = 1'b1;
        rdcmd_addr = cmd_addr[20:0];
        rdcmd_id = cmd_id;
        rdcmd_len = cmd_len;
        @(negedge clock);
        rdcmd_valid = 1'b0;
        @(negedge clock iff(rdcmd_complete));
        cmd_data = rdcmd_data;
    endtask

    task d2d_write_read_128_sameaddr(
        input [31:0]  addr,
        input [127:0] wdata
    );
    begin
        logic [64*Burst-1:0] rtmp;
        logic [127:0] rdata;
        d2d_write(addr, 7'b0001100, 8'd0, {{(64*Burst-64){1'b0}}, wdata[63:0]});
        d2d_write(addr, 7'b0001101, 8'd0, {{(64*Burst-64){1'b0}}, wdata[127:64]});

        d2d_read(addr, 7'b0101010, 8'd0, rtmp);
        rdata[63:0] = rtmp[63:0];
        d2d_read(addr, 7'b0101011, 8'd0, rtmp);
        rdata[127:64] = rtmp[63:0];

        if (!(wdata === rdata)) begin
            $display("%t ******* D2D 128 WR FAIL! addr=%h w=%h r=%h", $time, addr, wdata, rdata);
        end else begin
            $display("%t: D2D 128 WR PASS addr=%h", $time, addr);
        end
    end
    endtask

    task automatic spi_sram_write_read_check(
        input int unsigned mem_id,
        input int unsigned word_addr,
        input [31:0]  addr,
        input [127:0] wdata,
        input [127:0] valid_mask,
        output logic  match
    );
        logic [127:0] rdata;
        logic [127:0] exp_masked;
        logic [127:0] got_masked;
    begin
        spi_write_64(addr, wdata[63:0]);
        spi_write_64(addr, wdata[127:64]);
        spi_read_64(addr, rdata[63:0]);
        spi_read_64(addr, rdata[127:64]);

        exp_masked = wdata & valid_mask;
        got_masked = rdata & valid_mask;
        match = (got_masked === exp_masked);

        if (!match) begin
            $display("%t ******* SPI SRAM FAIL! mem=%0h word=%0d addr=%h exp=%h got=%h mask=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked, got_masked, valid_mask);
        end else begin
            $display("%t: SPI SRAM PASS mem=%0h word=%0d addr=%h exp=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked);
        end
    end
    endtask

    task automatic d2d_sram_write_read_check(
        input int unsigned mem_id,
        input int unsigned word_addr,
        input [31:0]  addr,
        input [127:0] wdata,
        input [127:0] valid_mask,
        input [6:0]   wr_id_lo,
        input [6:0]   wr_id_hi,
        input [6:0]   rd_id_lo,
        input [6:0]   rd_id_hi,
        output logic  match
    );
        logic [64*Burst-1:0] rtmp;
        logic [127:0] rdata;
        logic [127:0] exp_masked;
        logic [127:0] got_masked;
    begin
        d2d_write(addr, wr_id_lo, 8'd0, {{(64*Burst-64){1'b0}}, wdata[63:0]});
        d2d_write(addr, wr_id_hi, 8'd0, {{(64*Burst-64){1'b0}}, wdata[127:64]});

        d2d_read(addr, rd_id_lo, 8'd0, rtmp);
        rdata[63:0] = rtmp[63:0];
        d2d_read(addr, rd_id_hi, 8'd0, rtmp);
        rdata[127:64] = rtmp[63:0];

        exp_masked = wdata & valid_mask;
        got_masked = rdata & valid_mask;
        match = (got_masked === exp_masked);

        if (!match) begin
            $display("%t ******* D2D SRAM FAIL! mem=%0h word=%0d addr=%h exp=%h got=%h mask=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked, got_masked, valid_mask);
        end else begin
            $display("%t: D2D SRAM PASS mem=%0h word=%0d addr=%h exp=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked);
        end
    end
    endtask

    task automatic spi_cfg_write_read_check(
        input int unsigned reg_idx,
        input [31:0]  wdata,
        output logic  match
    );
        logic [31:0] addr;
        logic [31:0] rdata;
    begin
        addr = mpc_cfg_addr(reg_idx);
        spi_write(.wdata(wdata), .waddr(addr));
        spi_read (.raddr(addr), .rdata(rdata));
        match = (rdata === wdata);
        if (!match) begin
            $display("%t ******* SPI CFG WR FAIL! reg[%0d] addr=%h w=%h r=%h", $time, reg_idx, addr, wdata, rdata);
        end else begin
            $display("%t: SPI CFG WR PASS reg[%0d] addr=%h data=%h", $time, reg_idx, addr, wdata);
        end
    end
    endtask

    task automatic d2d_cfg_write_read_check(
        input int unsigned reg_idx,
        input [31:0]  wdata,
        input [6:0]   wr_id,
        input [6:0]   rd_id,
        output logic  match
    );
        logic [31:0] addr;
        logic [31:0] rdata;
        logic [64*Burst-1:0] rtmp;
    begin
        addr = mpc_cfg_addr(reg_idx);
        d2d_write(addr, wr_id, 8'd0, {{(64*Burst-64){1'b0}}, 32'h0000_0000, wdata});
        d2d_read(addr, rd_id, 8'd0, rtmp);
        rdata = rtmp[31:0];
        match = (rdata === wdata);
        if (!match) begin
            $display("%t ******* D2D CFG WR FAIL! reg[%0d] addr=%h w=%h r=%h", $time, reg_idx, addr, wdata, rdata);
        end else begin
            $display("%t: D2D CFG WR PASS reg[%0d] addr=%h data=%h", $time, reg_idx, addr, wdata);
        end
    end
    endtask

    task test_config_spi;
        integer reg_idx;
        integer phase;
        integer pass_count;
        integer fail_count;
        logic ok;
        logic [31:0] wdata;
    begin
        pass_count = 0;
        fail_count = 0;
        $display("%t: SPI config reg test begin", $time);
        for (phase = 0; phase < 2; phase = phase + 1) begin
            $display("%t: SPI config reg phase %0d begin", $time, phase);
            if (phase == 0) begin
                for (reg_idx = 0; reg_idx < MPC_CFG_RW_TEST_REG_COUNT; reg_idx = reg_idx + 1) begin
                    wdata = cfg_test_pattern(reg_idx, phase);
                    spi_cfg_write_read_check(reg_idx, wdata, ok);
                    if (ok) begin
                        pass_count = pass_count + 1;
                    end else begin
                        fail_count = fail_count + 1;
                    end
                end
            end else begin
                for (reg_idx = MPC_CFG_RW_TEST_REG_COUNT - 1; reg_idx >= 0; reg_idx = reg_idx - 1) begin
                    wdata = cfg_test_pattern(reg_idx, phase);
                    spi_cfg_write_read_check(reg_idx, wdata, ok);
                    if (ok) begin
                        pass_count = pass_count + 1;
                    end else begin
                        fail_count = fail_count + 1;
                    end
                end
            end
        end
        $display("%t: SPI config reg test end pass=%0d fail=%0d", $time, pass_count, fail_count);
    end
    endtask

    task test_config_d2d;
        integer reg_idx;
        integer phase;
        integer pass_count;
        integer fail_count;
        logic ok;
        logic [31:0] wdata;
    begin
        pass_count = 0;
        fail_count = 0;
        $display("%t: D2D config reg test begin", $time);
        for (phase = 0; phase < 2; phase = phase + 1) begin
            $display("%t: D2D config reg phase %0d begin", $time, phase);
            if (phase == 0) begin
                for (reg_idx = 0; reg_idx < MPC_CFG_RW_TEST_REG_COUNT; reg_idx = reg_idx + 1) begin
                    wdata = cfg_test_pattern(reg_idx, phase + 2);
                    d2d_cfg_write_read_check(reg_idx, wdata, 7'h0C, 7'h2A, ok);
                    if (ok) begin
                        pass_count = pass_count + 1;
                    end else begin
                        fail_count = fail_count + 1;
                    end
                end
            end else begin
                for (reg_idx = MPC_CFG_RW_TEST_REG_COUNT - 1; reg_idx >= 0; reg_idx = reg_idx - 1) begin
                    wdata = cfg_test_pattern(reg_idx, phase + 2);
                    d2d_cfg_write_read_check(reg_idx, wdata, 7'h0D, 7'h2B, ok);
                    if (ok) begin
                        pass_count = pass_count + 1;
                    end else begin
                        fail_count = fail_count + 1;
                    end
                end
            end
        end
        $display("%t: D2D config reg test end pass=%0d fail=%0d", $time, pass_count, fail_count);
    end
    endtask

    task test_sram_spi;
        integer mem_id;
        integer slot;
        integer pass_count;
        integer fail_count;
        int unsigned word_addr;
        int unsigned depth;
        int unsigned width;
        logic [31:0] addr;
        logic [127:0] wdata;
        logic [127:0] valid_mask;
        logic ok;
    begin
        pass_count = 0;
        fail_count = 0;
        $display("%t: SPI SRAM test begin", $time);
        for (mem_id = 0; mem_id < 15; mem_id = mem_id + 1) begin
            depth = sram_depth(mem_id);
            width = sram_data_width(mem_id);
            valid_mask = sram_valid_mask(mem_id);
            $display("%t: SPI SRAM mem=%0h depth=%0d width=%0d begin", $time, mem_id[3:0], depth, width);
            for (slot = 0; slot < 3; slot = slot + 1) begin
                word_addr = sram_test_addr(mem_id, slot);
                addr = mpc_sram_addr(mem_id[3:0], word_addr);
                wdata = sram_test_pattern(mem_id, word_addr, slot);
                spi_sram_write_read_check(mem_id, word_addr, addr, wdata, valid_mask, ok);
                if (ok) begin
                    pass_count = pass_count + 1;
                end else begin
                    fail_count = fail_count + 1;
                end
            end
        end
        $display("%t: SPI SRAM test end pass=%0d fail=%0d", $time, pass_count, fail_count);
    end
    endtask

    task test_sram_d2d;
        integer mem_id;
        integer slot;
        integer pass_count;
        integer fail_count;
        int unsigned word_addr;
        int unsigned depth;
        int unsigned width;
        logic [31:0] addr;
        logic [127:0] wdata;
        logic [127:0] valid_mask;
        logic ok;
    begin
        pass_count = 0;
        fail_count = 0;
        $display("%t: D2D SRAM test begin", $time);
        for (mem_id = 0; mem_id < 15; mem_id = mem_id + 1) begin
            depth = sram_depth(mem_id);
            width = sram_data_width(mem_id);
            valid_mask = sram_valid_mask(mem_id);
            $display("%t: D2D SRAM mem=%0h depth=%0d width=%0d begin", $time, mem_id[3:0], depth, width);
            for (slot = 0; slot < 3; slot = slot + 1) begin
                word_addr = sram_test_addr(mem_id, slot);
                addr = mpc_sram_addr(mem_id[3:0], word_addr);
                wdata = sram_test_pattern(mem_id, word_addr, slot + 2);
                d2d_sram_write_read_check(mem_id, word_addr, addr, wdata, valid_mask, 7'h0C, 7'h0D, 7'h2A, 7'h2B, ok);
                if (ok) begin
                    pass_count = pass_count + 1;
                end else begin
                    fail_count = fail_count + 1;
                end
            end
        end
        $display("%t: D2D SRAM test end pass=%0d fail=%0d", $time, pass_count, fail_count);
    end
    endtask

// =============================================================================
//  Kick off the simulation
    initial begin
        $display("DexMPC TB started.");
        $fsdbDumpfile("wave_mpc.fsdb");
        $fsdbDumpvars(0, TopChipTop_tb, "+all");
        $fsdbDumpon;
        #1_000_000;
        $display("Timeout at %t, exit.", $time);
        $fsdbDumpoff;
        $finish;
    end

    initial begin
        #100ns;
        @(negedge clock);

        // test_config_spi();
        // test_config_d2d();
        test_sram_spi();
        test_sram_d2d();

        repeat (50) @(negedge clock);
        $display("DexMPC TB completes at %t.", $time);
        $fsdbDumpoff;
        $finish;
    end

endmodule: TopChipTop_tb

// ==============================================================================
// Pseudo D2D Host
// ==============================================================================
module d2dm_burst_writer #(
    parameter int Burst = 16
)(
    input  logic                clock,
    input  logic                reset,

    input  logic                cmd_valid,
    input  logic [20:0]         cmd_addr,
    input  logic [6:0]          cmd_id,
    input  logic [7:0]          cmd_len,
    input  logic [64*Burst-1:0] cmd_data,
    output logic                cmd_complete,

    input  logic                d2dm_aw_ready,
    output logic                d2dm_aw_valid,
    output logic [20:0]         d2dm_aw_addr,
    output logic [6:0]          d2dm_aw_id,
    output logic [7:0]          d2dm_aw_len,
    input  logic                d2dm_w_ready,
    output logic                d2dm_w_valid,
    output logic [63:0]         d2dm_w_data,
    output logic                d2dm_w_last,
    output logic                d2dm_b_ready,
    input  logic                d2dm_b_valid,
    input  logic [6:0]          d2dm_b_id,
    input  logic [1:0]          d2dm_b_resp
);

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_aw_valid <= '0;
            d2dm_aw_addr  <= '0;
            d2dm_aw_id    <= '0;
            d2dm_aw_len   <= '0;
        end
        else if (cmd_valid) begin
            d2dm_aw_valid <= 1'd1;
            d2dm_aw_addr  <= cmd_addr;
            d2dm_aw_id    <= cmd_id;
            d2dm_aw_len   <= cmd_len;
        end
        else if (d2dm_aw_valid && d2dm_aw_ready) begin
            d2dm_aw_valid <= 1'd0;
        end
    end

    logic [7:0] w_count;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_w_valid <= '0;
            d2dm_w_data  <= '0;
            d2dm_w_last  <= '0;
            w_count      <= '0;
        end
        else begin
            if (cmd_valid) begin
                d2dm_w_valid <= 1'd1;
                d2dm_w_data  <= cmd_data[0 +: 64];
                d2dm_w_last  <= w_count == cmd_len;
                w_count      <= '0;
            end
            else if (d2dm_w_valid && d2dm_w_ready) begin
                if (w_count < cmd_len) begin
                    d2dm_w_valid <= 1'd1;
                    d2dm_w_data  <= cmd_data[(w_count + 1) * 64 +: 64];
                    d2dm_w_last  <= w_count == (cmd_len - 1);
                    w_count      <= w_count + 1;
                end
                else begin
                    d2dm_w_valid <= 1'd0;
                    d2dm_w_last <= 1'd0;
                    w_count <= '0;
                end
            end
        end
    end

    assign d2dm_b_ready = 1'b1;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            cmd_complete  <= '0;
        end
        else if (d2dm_b_valid && d2dm_b_ready) begin
            cmd_complete <= '1;
        end
        else begin
            cmd_complete <= '0;
        end
    end

endmodule: d2dm_burst_writer

module d2dm_burst_reader#(
    parameter int Burst = 16
)(
    input  logic                clock,
    input  logic                reset,

    input  logic                cmd_valid,
    input  logic [20:0]         cmd_addr,
    input  logic [6:0]          cmd_id,
    input  logic [7:0]          cmd_len,
    output logic [64*Burst-1:0] cmd_data,
    output logic                cmd_complete,

    input  logic                d2dm_ar_ready,
    output logic                d2dm_ar_valid,
    output logic [20:0]         d2dm_ar_addr,
    output logic [6:0]          d2dm_ar_id,
    output logic [7:0]          d2dm_ar_len,
    output logic                d2dm_r_ready,
    input  logic                d2dm_r_valid,
    input  logic [63:0]         d2dm_r_data,
    input  logic                d2dm_r_last,
    input  logic [6:0]          d2dm_r_id,
    input  logic [1:0]          d2dm_r_resp
);

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_ar_valid <= '0;
            d2dm_ar_addr  <= '0;
            d2dm_ar_id    <= '0;
            d2dm_ar_len   <= '0;
        end
        else if (cmd_valid) begin
            d2dm_ar_valid <= 1'd1;
            d2dm_ar_addr  <= cmd_addr;
            d2dm_ar_id    <= cmd_id;
            d2dm_ar_len   <= cmd_len;
        end
        else if (d2dm_ar_valid && d2dm_ar_ready) begin
            d2dm_ar_valid <= 1'd0;
        end
    end

    assign d2dm_r_ready = 1'b1;

    logic [7:0] r_count;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            r_count  <= '0;
            cmd_data <= '0;
        end
        else if (d2dm_r_valid && d2dm_r_ready && d2dm_r_id == d2dm_ar_id) begin
            r_count <= r_count + 1;
            cmd_data[r_count*64 +: 64] <= d2dm_r_data;
        end
        else if (cmd_complete == '1) begin
            r_count <= '0;
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            cmd_complete  <= '0;
        end
        else if (d2dm_r_valid && d2dm_r_ready && (r_count == cmd_len)) begin
            cmd_complete <= '1;
        end
        else begin
            cmd_complete <= '0;
        end
    end

endmodule: d2dm_burst_reader
