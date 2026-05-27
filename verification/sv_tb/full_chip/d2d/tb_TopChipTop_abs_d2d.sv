`timescale 1ns/1ps

module tb_TopChipTop_abs_d2d #(parameter int Burst = 3) ();

    parameter CLK_PERIOD = 4;

    localparam integer FPW = 16;
    localparam integer SRAM_W = 128;
    localparam integer FP16_PER_WORD = SRAM_W / FPW;

    localparam integer GLOBAL_DEPTH = 2048;
    localparam integer LOCAL_DEPTH = 512;
    localparam integer TEMP_DEPTH = 896;
    localparam integer GLOBAL_ADDR_W = 11;
    localparam integer LOCAL_ADDR_W = 9;
    localparam integer TEMP_ADDR_W = 10;
    localparam integer ADDR_W = GLOBAL_ADDR_W;

    localparam integer BASE_CASES = 12;
    localparam integer COMBOS = 9;
    localparam integer INPLACE_COMBOS = 3;
    localparam integer CASES = (BASE_CASES * COMBOS) + (BASE_CASES * INPLACE_COMBOS);
    localparam integer MAX_WORDS = 8;
    localparam integer TIMEOUT_CYCLES = 400000;

    localparam integer BASE_ROWS [0:BASE_CASES-1] = '{
        1, 3, 4, 1, 3, 4, 1, 3, 1, 4, 3, 5
    };
    localparam integer BASE_COLS [0:BASE_CASES-1] = '{
        5, 4, 4, 17, 11, 5, 31, 16, 9, 6, 5, 8
    };

    localparam logic [2:0] OP_ABS = 3'b001;
    localparam logic [3:0] SUB_ABS = 4'h0;

    localparam [31:0] BASE_DEXMPC_ADDR = 32'h0000_0000;
    localparam int unsigned CFG_CMDWORD_0_0 = 0;
    localparam int unsigned CFG_CMDWORD_0_1 = 1;
    localparam int unsigned CFG_CMDWORD_0_2 = 2;
    localparam int unsigned CFG_CMDCTRL_0 = 12;
    localparam int unsigned CFG_CMDSTATUS_0 = 22;
    localparam int unsigned CFG_DONECOUNT_0 = 26;
    localparam int unsigned CFG_LASTDONE_0 = 30;
    localparam int unsigned CFG_ENGINE_STATUS = 54;
    localparam int unsigned CFG_IS_LOOP = 63;

    localparam logic [6:0] D2D_WR_ID_LO = 7'h0C;
    localparam logic [6:0] D2D_WR_ID_HI = 7'h0D;
    localparam logic [6:0] D2D_RD_ID_LO = 7'h2A;
    localparam logic [6:0] D2D_RD_ID_HI = 7'h2B;

    logic clock = 1'b1;
    logic reset = 1'b0;
    logic d2d_mux_signal = 1'b0;
    logic clock_sel = 1'b1;

    tri top_clock = clock;
    tri top_reset = reset;
    tri top_clock_sel = clock_sel;
    tri top_clock_debug;

    tri d2d_rx_clock;
    tri d2d_rx_flit_valid;
    tri [15:0] d2d_rx_flit_bits;
    tri d2d_rx_creditRB_free;
    tri d2d_rx_replayPkgID;
    tri spi_ssn;
    tri spi_sck;
    tri spi_mosi;

    tri d2d_tx_clock;
    tri d2d_tx_flit_valid;
    tri [7:0] d2d_tx_flit_bits;
    tri d2d_tx_creditARW_free;
    tri d2d_tx_replayPkgID;
    tri d2d_mux = d2d_mux_signal;
    tri spi_miso;
    tri gaux_complete;
    tri dexmpc_complete;

    logic [64*Burst-1:0] wrcmd_data = '0;
    logic wrcmd_valid = 1'b0;
    logic [20:0] wrcmd_addr = '0;
    logic [6:0] wrcmd_id = '0;
    logic [7:0] wrcmd_len = '0;
    logic wrcmd_complete;

    logic [64*Burst-1:0] rdcmd_data;
    logic rdcmd_valid = 1'b0;
    logic [20:0] rdcmd_addr = '0;
    logic [6:0] rdcmd_id = '0;
    logic [7:0] rdcmd_len = '0;
    logic rdcmd_complete;

    logic d2dm_ar_ready;
    logic d2dm_ar_valid;
    logic [20:0] d2dm_ar_addr;
    logic [6:0] d2dm_ar_id;
    logic [7:0] d2dm_ar_len;
    logic d2dm_r_ready;
    logic d2dm_r_valid;
    logic [63:0] d2dm_r_data;
    logic d2dm_r_last;
    logic [6:0] d2dm_r_id;
    logic [1:0] d2dm_r_resp;

    logic d2dm_aw_ready;
    logic d2dm_aw_valid;
    logic [20:0] d2dm_aw_addr;
    logic [6:0] d2dm_aw_id;
    logic [7:0] d2dm_aw_len;
    logic d2dm_w_ready;
    logic d2dm_w_valid;
    logic [63:0] d2dm_w_data;
    logic d2dm_w_last;
    logic d2dm_b_ready;
    logic d2dm_b_valid;
    logic [6:0] d2dm_b_id;
    logic [1:0] d2dm_b_resp;

    logic d2d_clock = 1'b1;

    integer case_rows [0:CASES-1];
    integer case_cols [0:CASES-1];
    integer case_elem_count [0:CASES-1];
    integer case_word_count [0:CASES-1];
    integer case_seq [0:CASES-1];
    integer case_src_id [0:CASES-1];
    integer case_dst_id [0:CASES-1];
    logic [11:0] case_cmd_id [0:CASES-1];
    logic [ADDR_W-1:0] case_src_base [0:CASES-1];
    logic [ADDR_W-1:0] case_dst_base [0:CASES-1];
    logic [95:0] case_cmd [0:CASES-1];

    logic [SRAM_W-1:0] pre_words [0:CASES-1][0:MAX_WORDS-1];
    logic [SRAM_W-1:0] post_words [0:CASES-1][0:MAX_WORDS-1];

    integer next_base_global;
    integer next_base_local;
    integer next_base_temp;

    integer pad_done_pulse_count;
    integer issued_cmd_count;

    integer in_csv_fd;
    integer out_csv_fd;
    integer mkdir_ret;
    semaphore csv_lock;

    assign spi_ssn = 1'b1;
    assign spi_sck = 1'b0;
    assign spi_mosi = 1'b0;

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

    initial begin
        forever #1ns d2d_clock = ~clock;
    end

    d2dm_burst_writer #(
        .Burst(Burst)
    ) ud2dm_burst_writer (
        .clock(clock),
        .reset(reset),
        .cmd_valid(wrcmd_valid),
        .cmd_addr(wrcmd_addr),
        .cmd_id(wrcmd_id),
        .cmd_len(wrcmd_len),
        .cmd_data(wrcmd_data),
        .cmd_complete(wrcmd_complete),
        .d2dm_aw_ready(d2dm_aw_ready),
        .d2dm_aw_valid(d2dm_aw_valid),
        .d2dm_aw_addr(d2dm_aw_addr),
        .d2dm_aw_id(d2dm_aw_id),
        .d2dm_aw_len(d2dm_aw_len),
        .d2dm_w_ready(d2dm_w_ready),
        .d2dm_w_valid(d2dm_w_valid),
        .d2dm_w_data(d2dm_w_data),
        .d2dm_w_last(d2dm_w_last),
        .d2dm_b_ready(d2dm_b_ready),
        .d2dm_b_valid(d2dm_b_valid),
        .d2dm_b_id(d2dm_b_id),
        .d2dm_b_resp(d2dm_b_resp)
    );

    d2dm_burst_reader #(
        .Burst(Burst)
    ) ud2dm_burst_reader (
        .clock(clock),
        .reset(reset),
        .cmd_valid(rdcmd_valid),
        .cmd_addr(rdcmd_addr),
        .cmd_id(rdcmd_id),
        .cmd_len(rdcmd_len),
        .cmd_data(rdcmd_data),
        .cmd_complete(rdcmd_complete),
        .d2dm_ar_ready(d2dm_ar_ready),
        .d2dm_ar_valid(d2dm_ar_valid),
        .d2dm_ar_addr(d2dm_ar_addr),
        .d2dm_ar_id(d2dm_ar_id),
        .d2dm_ar_len(d2dm_ar_len),
        .d2dm_r_ready(d2dm_r_ready),
        .d2dm_r_valid(d2dm_r_valid),
        .d2dm_r_data(d2dm_r_data),
        .d2dm_r_last(d2dm_r_last),
        .d2dm_r_id(d2dm_r_id),
        .d2dm_r_resp(d2dm_r_resp)
    );

    Md2dMaster uD2dMaster (
        .clock(clock),
        .reset(reset),
        .io_txClock(d2d_clock),

        .io_AXI4SlavePorts_readAddr_ready(d2dm_ar_ready),
        .io_AXI4SlavePorts_readAddr_valid(d2dm_ar_valid),
        .io_AXI4SlavePorts_readAddr_bits_addr(d2dm_ar_addr),
        .io_AXI4SlavePorts_readAddr_bits_id(d2dm_ar_id),
        .io_AXI4SlavePorts_readAddr_bits_size(3'd3),
        .io_AXI4SlavePorts_readAddr_bits_len(d2dm_ar_len),
        .io_AXI4SlavePorts_readAddr_bits_burst(2'd1),
        .io_AXI4SlavePorts_readAddr_bits_cache('0),
        .io_AXI4SlavePorts_readAddr_bits_lock('0),
        .io_AXI4SlavePorts_readAddr_bits_prot('0),
        .io_AXI4SlavePorts_readAddr_bits_qos('0),
        .io_AXI4SlavePorts_readAddr_bits_region('0),
        .io_AXI4SlavePorts_readData_ready(d2dm_r_ready),
        .io_AXI4SlavePorts_readData_valid(d2dm_r_valid),
        .io_AXI4SlavePorts_readData_bits_data(d2dm_r_data),
        .io_AXI4SlavePorts_readData_bits_last(d2dm_r_last),
        .io_AXI4SlavePorts_readData_bits_id(d2dm_r_id),
        .io_AXI4SlavePorts_readData_bits_resp(d2dm_r_resp),
        .io_AXI4SlavePorts_writeAddr_ready(d2dm_aw_ready),
        .io_AXI4SlavePorts_writeAddr_valid(d2dm_aw_valid),
        .io_AXI4SlavePorts_writeAddr_bits_addr(d2dm_aw_addr),
        .io_AXI4SlavePorts_writeAddr_bits_id(d2dm_aw_id),
        .io_AXI4SlavePorts_writeAddr_bits_size(3'd3),
        .io_AXI4SlavePorts_writeAddr_bits_len(d2dm_aw_len),
        .io_AXI4SlavePorts_writeAddr_bits_burst(2'd1),
        .io_AXI4SlavePorts_writeAddr_bits_cache('0),
        .io_AXI4SlavePorts_writeAddr_bits_lock('0),
        .io_AXI4SlavePorts_writeAddr_bits_prot('0),
        .io_AXI4SlavePorts_writeAddr_bits_qos('0),
        .io_AXI4SlavePorts_writeAddr_bits_region('0),
        .io_AXI4SlavePorts_writeData_ready(d2dm_w_ready),
        .io_AXI4SlavePorts_writeData_valid(d2dm_w_valid),
        .io_AXI4SlavePorts_writeData_bits_data(d2dm_w_data),
        .io_AXI4SlavePorts_writeData_bits_last(d2dm_w_last),
        .io_AXI4SlavePorts_writeData_bits_strb(8'hff),
        .io_AXI4SlavePorts_writeResp_ready(d2dm_b_ready),
        .io_AXI4SlavePorts_writeResp_valid(d2dm_b_valid),
        .io_AXI4SlavePorts_writeResp_bits_id(d2dm_b_id),
        .io_AXI4SlavePorts_writeResp_bits_resp(d2dm_b_resp),

        .io_ctrlBusPorts_readAddr_ready(),
        .io_ctrlBusPorts_readAddr_valid(1'b0),
        .io_ctrlBusPorts_readAddr_bits_addr('0),
        .io_ctrlBusPorts_readAddr_bits_prot('0),
        .io_ctrlBusPorts_readData_ready(1'b0),
        .io_ctrlBusPorts_readData_valid(),
        .io_ctrlBusPorts_readData_bits_data(),
        .io_ctrlBusPorts_readData_bits_resp(),
        .io_ctrlBusPorts_writeAddr_ready(),
        .io_ctrlBusPorts_writeAddr_valid(1'b0),
        .io_ctrlBusPorts_writeAddr_bits_addr('0),
        .io_ctrlBusPorts_writeData_ready(),
        .io_ctrlBusPorts_writeData_valid(1'b0),
        .io_ctrlBusPorts_writeData_bits_data('0),
        .io_ctrlBusPorts_writeData_bits_strb('0),
        .io_ctrlBusPorts_writeResp_ready(1'b0),
        .io_ctrlBusPorts_writeResp_valid(),
        .io_ctrlBusPorts_writeResp_bits(),

        .io_ARId('0),
        .io_AWId('0),
        .io_RId(),
        .io_BId(),

        .io_tx_clock(d2d_rx_clock),
        .io_tx_flit_valid(d2d_rx_flit_valid),
        .io_tx_flit_bits(d2d_rx_flit_bits),
        .io_tx_creditRB_free(d2d_rx_creditRB_free),
        .io_tx_replayPkgID(d2d_rx_replayPkgID),
        .io_rx_clock(d2d_tx_clock),
        .io_rx_flit_valid(d2d_tx_flit_valid),
        .io_rx_flit_bits(d2d_tx_flit_bits),
        .io_rx_creditARW_free(d2d_tx_creditARW_free),
        .io_rx_replayPkgID(d2d_tx_replayPkgID)
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

    function automatic logic [FPW-1:0] rand_fp16_non_extreme;
        integer sign_bit;
        integer exp_part;
        integer frac_part;
    begin
        sign_bit = $urandom_range(0, 1);
        exp_part = $urandom_range(1, 30);
        frac_part = $urandom_range(0, 1023);
        rand_fp16_non_extreme = {sign_bit[0], exp_part[4:0], frac_part[9:0]};
    end
    endfunction

    function automatic integer ceil_div(input integer num, input integer den);
        if (den == 0) begin
            ceil_div = 0;
        end else begin
            ceil_div = (num + den - 1) / den;
        end
    endfunction

    function automatic logic [12:0] pack_addr(
        input logic [1:0] sram_id,
        input logic [10:0] word_idx
    );
        pack_addr = {sram_id, word_idx};
    endfunction

    function automatic logic [95:0] make_cmd(
        input logic [11:0] cmd_id,
        input logic [2:0] opcode,
        input logic [3:0] subop,
        input logic group_end,
        input logic [12:0] addr0,
        input logic [12:0] addr1,
        input logic [12:0] addr2,
        input logic [11:0] dim0,
        input logic [11:0] dim1,
        input logic [11:0] dim2
    );
        make_cmd = {cmd_id, opcode, subop, group_end, 1'b0, addr0, addr1, addr2, dim0, dim1, dim2};
    endfunction

    function automatic [31:0] mpc_cfg_addr(input int unsigned reg_idx);
        mpc_cfg_addr = BASE_DEXMPC_ADDR + (reg_idx[31:0] << 3);
    endfunction

    function automatic [31:0] mpc_sram_addr(input int unsigned mem_id, input int unsigned word_addr);
        mpc_sram_addr = BASE_DEXMPC_ADDR + ((32'h0000_8000 + (mem_id << 11) + word_addr) << 3);
    endfunction

    function automatic int unsigned core_mem_to_mpc_mem(input int unsigned core_mem_id);
    begin
        case (core_mem_id)
            0: core_mem_to_mpc_mem = 4'h0;
            1: core_mem_to_mpc_mem = 4'h1;
            2: core_mem_to_mpc_mem = 4'h5;
            default: core_mem_to_mpc_mem = 4'hF;
        endcase
    end
    endfunction

    function automatic [31:0] core_sram_addr(input int unsigned core_mem_id, input int unsigned word_addr);
        core_sram_addr = mpc_sram_addr(core_mem_to_mpc_mem(core_mem_id), word_addr);
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
            16: sram_valid_mask = {{112{1'b0}}, 16'hFFFF};
            32: sram_valid_mask = {{96{1'b0}}, 32'hFFFF_FFFF};
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

    task d2d_write(
        input logic [31:0] cmd_addr,
        input logic [6:0] cmd_id,
        input logic [7:0] cmd_len,
        input logic [64*Burst-1:0] cmd_data
    );
    begin
        @(negedge clock);
        wrcmd_valid = 1'b1;
        wrcmd_addr = cmd_addr[20:0];
        wrcmd_id = cmd_id;
        wrcmd_len = cmd_len;
        wrcmd_data = cmd_data;
        @(negedge clock);
        wrcmd_valid = 1'b0;
        @(negedge clock iff (wrcmd_complete));
    end
    endtask

    task d2d_read(
        input logic [31:0] cmd_addr,
        input logic [6:0] cmd_id,
        input logic [7:0] cmd_len,
        output logic [64*Burst-1:0] cmd_data
    );
    begin
        @(negedge clock);
        rdcmd_valid = 1'b1;
        rdcmd_addr = cmd_addr[20:0];
        rdcmd_id = cmd_id;
        rdcmd_len = cmd_len;
        @(negedge clock);
        rdcmd_valid = 1'b0;
        @(negedge clock iff (rdcmd_complete));
        cmd_data = rdcmd_data;
    end
    endtask

    task automatic d2d_cfg_write(
        input int unsigned reg_idx,
        input logic [31:0] wdata
    );
    begin
        d2d_write(mpc_cfg_addr(reg_idx), D2D_WR_ID_LO, 8'd0, {{(64*Burst-64){1'b0}}, 32'h0, wdata});
    end
    endtask

    task automatic d2d_cfg_read(
        input int unsigned reg_idx,
        output logic [31:0] rdata
    );
        logic [64*Burst-1:0] rtmp;
    begin
        d2d_read(mpc_cfg_addr(reg_idx), D2D_RD_ID_LO, 8'd0, rtmp);
        rdata = rtmp[31:0];
    end
    endtask

    task automatic d2d_cfg_write_read_check(
        input int unsigned reg_idx,
        input logic [31:0] wdata,
        input logic [6:0] wr_id,
        input logic [6:0] rd_id,
        output logic match
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

    task automatic d2d_read_128(
        input logic [31:0] addr,
        output logic [127:0] rdata
    );
        logic [64*Burst-1:0] rtmp;
    begin
        d2d_read(addr, D2D_RD_ID_LO, 8'd0, rtmp);
        rdata[63:0] = rtmp[63:0];
        d2d_read(addr, D2D_RD_ID_HI, 8'd0, rtmp);
        rdata[127:64] = rtmp[63:0];
    end
    endtask

    task automatic d2d_write_128(
        input logic [31:0] addr,
        input logic [127:0] wdata
    );
    begin
        d2d_write(addr, D2D_WR_ID_LO, 8'd0, {{(64*Burst-64){1'b0}}, wdata[63:0]});
        d2d_write(addr, D2D_WR_ID_HI, 8'd0, {{(64*Burst-64){1'b0}}, wdata[127:64]});
    end
    endtask

    task automatic d2d_sram_write_read_check(
        input int unsigned mem_id,
        input int unsigned word_addr,
        input logic [31:0] addr,
        input logic [127:0] wdata,
        input logic [127:0] valid_mask,
        input logic verbose,
        output logic match
    );
        logic [127:0] rdata;
        logic [127:0] exp_masked;
        logic [127:0] got_masked;
    begin
        d2d_write_128(addr, wdata);
        d2d_read_128(addr, rdata);

        exp_masked = wdata & valid_mask;
        got_masked = rdata & valid_mask;
        match = (got_masked === exp_masked);

        if (!match) begin
            $display("%t ******* D2D SRAM FAIL! mem=%0h word=%0d addr=%h exp=%h got=%h mask=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked, got_masked, valid_mask);
        end else if (verbose) begin
            $display("%t: D2D SRAM PASS mem=%0h word=%0d addr=%h exp=%h",
                     $time, mem_id[3:0], word_addr, addr, exp_masked);
        end
    end
    endtask

    task automatic smoke_test_sram_d2d;
        integer mem_id;
        integer slot;
        integer pass_count;
        int unsigned word_addr;
        logic [31:0] addr;
        logic [127:0] wdata;
        logic [127:0] valid_mask;
        logic ok;
    begin
        pass_count = 0;
        for (mem_id = 0; mem_id < 15; mem_id = mem_id + 1) begin
            valid_mask = sram_valid_mask(mem_id);
            for (slot = 0; slot < 3; slot = slot + 1) begin
                word_addr = sram_test_addr(mem_id, slot);
                addr = mpc_sram_addr(mem_id[3:0], word_addr);
                wdata = sram_test_pattern(mem_id, word_addr, slot + 2);
                d2d_sram_write_read_check(mem_id, word_addr, addr, wdata, valid_mask, 1'b0, ok);
                if (!ok) begin
                    $fatal(1, "D2D SRAM smoke test failed on mem=%0h word=%0d", mem_id[3:0], word_addr);
                end
                pass_count = pass_count + 1;
            end
        end
        $display("%t: D2D SRAM smoke test passed, total checks=%0d", $time, pass_count);
    end
    endtask

    task automatic reserve_base(
        input integer mem_id,
        input integer words,
        output integer base
    );
        integer delta;
    begin
        delta = (words == 0) ? 1 : words;
        case (mem_id)
            0: begin
                base = next_base_global;
                next_base_global = next_base_global + delta + 1;
                if (next_base_global >= GLOBAL_DEPTH) $fatal(1, "Global SRAM overflow");
            end
            1: begin
                base = next_base_local;
                next_base_local = next_base_local + delta + 1;
                if (next_base_local >= LOCAL_DEPTH) $fatal(1, "Local SRAM overflow");
            end
            2: begin
                base = next_base_temp;
                next_base_temp = next_base_temp + delta + 1;
                if (next_base_temp >= TEMP_DEPTH) $fatal(1, "Temp SRAM overflow");
            end
            default: $fatal(1, "Unknown SRAM id %0d", mem_id);
        endcase
    end
    endtask

    task automatic build_cases;
        integer src_id;
        integer dst_id;
        integer b;
        integer cid;
        integer words;
        integer seed;
        integer base_int;
        integer w;
        integer lane;
        logic [SRAM_W-1:0] word;
    begin
        seed = 32'h20260306;
        void'($urandom(seed));

        next_base_global = 1024;
        next_base_local = 0;
        next_base_temp = 0;

        for (src_id = 0; src_id < 3; src_id = src_id + 1) begin
            for (dst_id = 0; dst_id < 3; dst_id = dst_id + 1) begin
                for (b = 0; b < BASE_CASES; b = b + 1) begin
                    cid = (src_id * 3 + dst_id) * BASE_CASES + b;
                    case_rows[cid] = BASE_ROWS[b];
                    case_cols[cid] = BASE_COLS[b];
                    case_seq[cid] = 0;
                    case_src_id[cid] = src_id;
                    case_dst_id[cid] = dst_id;
                    case_cmd_id[cid] = cid[11:0];
                    case_elem_count[cid] = case_rows[cid] * case_cols[cid];
                    words = ceil_div(case_elem_count[cid], FP16_PER_WORD);
                    case_word_count[cid] = words;
                    if (words > MAX_WORDS) begin
                        $fatal(1, "case %0d exceeds MAX_WORDS", cid);
                    end

                    reserve_base(case_src_id[cid], words, base_int);
                    case_src_base[cid] = base_int[ADDR_W-1:0];
                    reserve_base(case_dst_id[cid], words, base_int);
                    case_dst_base[cid] = base_int[ADDR_W-1:0];

                    for (w = 0; w < MAX_WORDS; w = w + 1) begin
                        pre_words[cid][w] = '0;
                        post_words[cid][w] = '0;
                    end

                    for (w = 0; w < words; w = w + 1) begin
                        word = '0;
                        for (lane = 0; lane < FP16_PER_WORD; lane = lane + 1) begin
                            word[lane * FPW +: FPW] = rand_fp16_non_extreme();
                        end
                        pre_words[cid][w] = word;
                    end

                    case_cmd[cid] = make_cmd(
                        case_cmd_id[cid],
                        OP_ABS,
                        SUB_ABS,
                        (cid == CASES - 1),
                        pack_addr(case_src_id[cid][1:0], case_src_base[cid]),
                        pack_addr(case_dst_id[cid][1:0], case_dst_base[cid]),
                        13'h0,
                        case_rows[cid][11:0],
                        case_cols[cid][11:0],
                        12'h0
                    );
                end
            end
        end

        for (src_id = 0; src_id < 3; src_id = src_id + 1) begin
            for (b = 0; b < BASE_CASES; b = b + 1) begin
                cid = (BASE_CASES * COMBOS) + (src_id * BASE_CASES) + b;
                case_rows[cid] = BASE_ROWS[b];
                case_cols[cid] = BASE_COLS[b];
                case_seq[cid] = 0;
                case_src_id[cid] = src_id;
                case_dst_id[cid] = src_id;
                case_cmd_id[cid] = cid[11:0];
                case_elem_count[cid] = case_rows[cid] * case_cols[cid];
                words = ceil_div(case_elem_count[cid], FP16_PER_WORD);
                case_word_count[cid] = words;
                if (words > MAX_WORDS) begin
                    $fatal(1, "case %0d exceeds MAX_WORDS", cid);
                end

                reserve_base(case_src_id[cid], words, base_int);
                case_src_base[cid] = base_int[ADDR_W-1:0];
                case_dst_base[cid] = case_src_base[cid];

                for (w = 0; w < MAX_WORDS; w = w + 1) begin
                    pre_words[cid][w] = '0;
                    post_words[cid][w] = '0;
                end

                for (w = 0; w < words; w = w + 1) begin
                    word = '0;
                    for (lane = 0; lane < FP16_PER_WORD; lane = lane + 1) begin
                        word[lane * FPW +: FPW] = rand_fp16_non_extreme();
                    end
                    pre_words[cid][w] = word;
                end

                case_cmd[cid] = make_cmd(
                    case_cmd_id[cid],
                    OP_ABS,
                    SUB_ABS,
                    (cid == CASES - 1),
                    pack_addr(case_src_id[cid][1:0], case_src_base[cid]),
                    pack_addr(case_dst_id[cid][1:0], case_dst_base[cid]),
                    13'h0,
                    case_rows[cid][11:0],
                    case_cols[cid][11:0],
                    12'h0
                );
            end
        end
    end
    endtask

    task automatic d2d_mem_write_word(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        input logic [SRAM_W-1:0] data
    );
    begin
        if (mem_id == 0 && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (mem_id == 1 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
        if (mem_id == 2 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
        d2d_write_128(core_sram_addr(mem_id, addr), data);
    end
    endtask

    task automatic d2d_mem_read_word(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        output logic [SRAM_W-1:0] data
    );
    begin
        if (mem_id == 0 && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (mem_id == 1 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
        if (mem_id == 2 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
        d2d_read_128(core_sram_addr(mem_id, addr), data);
    end
    endtask

    task automatic preload_cases_to_sram;
        integer cid;
        integer w;
    begin
        for (cid = 0; cid < CASES; cid = cid + 1) begin
            if (!((case_dst_id[cid] == case_src_id[cid]) &&
                  (case_dst_base[cid] == case_src_base[cid]))) begin
                for (w = 0; w < case_word_count[cid]; w = w + 1) begin
                    d2d_mem_write_word(case_dst_id[cid], case_dst_base[cid] + w, {SRAM_W{1'b0}});
                end
            end
            for (w = 0; w < case_word_count[cid]; w = w + 1) begin
                d2d_mem_write_word(case_src_id[cid], case_src_base[cid] + w, pre_words[cid][w]);
            end
        end
    end
    endtask

    task automatic write_input_header;
        integer col;
    begin
        $fwrite(in_csv_fd, "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin");
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
            $fwrite(in_csv_fd, ",pre_word_%0d_bin", col);
        end
        $fwrite(in_csv_fd, "\n");
    end
    endtask

    task automatic write_input_line(input integer cid);
        integer col;
        logic [15:0] rows_bin;
        logic [15:0] cols_bin;
        logic [ADDR_W-1:0] base_bin;
        logic [15:0] words_bin;
    begin
        rows_bin = case_rows[cid][15:0];
        cols_bin = case_cols[cid][15:0];
        base_bin = case_src_base[cid][ADDR_W-1:0];
        words_bin = case_word_count[cid][15:0];
        $fwrite(
            in_csv_fd,
            "%0d,%02b,%08b,%011b,%016b,%016b,%016b",
            cid,
            case_seq[cid][1:0],
            case_cmd_id[cid][7:0],
            base_bin,
            rows_bin,
            cols_bin,
            words_bin
        );
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
            $fwrite(in_csv_fd, ",%0128b", pre_words[cid][col]);
        end
        $fwrite(in_csv_fd, "\n");
    end
    endtask

    task automatic write_output_header;
        integer col;
    begin
        $fwrite(out_csv_fd, "case_id,seq_id_bin,req_id_bin,base_addr_bin,rows_bin,cols_bin,word_count_bin,done_bin");
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
            $fwrite(out_csv_fd, ",post_word_%0d_bin", col);
        end
        $fwrite(out_csv_fd, "\n");
    end
    endtask

    task automatic write_output_line(
        input integer cid,
        input integer seq_id,
        input logic [7:0] req_id,
        input logic [ADDR_W-1:0] base_addr,
        input logic [15:0] rows,
        input logic [15:0] cols,
        input logic [15:0] words,
        input logic done
    );
        integer col;
    begin
        $fwrite(
            out_csv_fd,
            "%0d,%02b,%08b,%011b,%016b,%016b,%016b,%01b",
            cid,
            seq_id[1:0],
            req_id,
            base_addr,
            rows,
            cols,
            words,
            done
        );
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
            $fwrite(out_csv_fd, ",%0128b", post_words[cid][col]);
        end
        $fwrite(out_csv_fd, "\n");
    end
    endtask

    task automatic capture_post_words(input integer cid);
        integer w;
        logic [SRAM_W-1:0] rd_word;
    begin
        for (w = 0; w < case_word_count[cid]; w = w + 1) begin
            d2d_mem_read_word(case_dst_id[cid], case_dst_base[cid] + w, rd_word);
            post_words[cid][w] = rd_word;
        end
    end
    endtask

    task automatic wait_fifo_space;
        logic [31:0] status_reg;
        integer guard_cycles;
    begin
        guard_cycles = 0;
        d2d_cfg_read(CFG_CMDSTATUS_0, status_reg);
        while (status_reg[0] === 1'b1) begin
            @(posedge clock);
            guard_cycles = guard_cycles + 1;
            if (guard_cycles > 10000) begin
                $fatal(1, "timeout waiting for cmd fifo space");
            end
            d2d_cfg_read(CFG_CMDSTATUS_0, status_reg);
        end
    end
    endtask

    task automatic push_cmd(input logic [95:0] cmd);
    begin
        wait_fifo_space();
        d2d_cfg_write(CFG_CMDWORD_0_0, cmd[31:0]);
        d2d_cfg_write(CFG_CMDWORD_0_1, cmd[63:32]);
        d2d_cfg_write(CFG_CMDWORD_0_2, cmd[95:64]);
        d2d_cfg_write(CFG_CMDCTRL_0, 32'h1);
        d2d_cfg_write(CFG_CMDCTRL_0, 32'h0);
    end
    endtask

    task automatic push_all_cmds;
        integer cid;
    begin
        issued_cmd_count = 0;
        for (cid = 0; cid < CASES; cid = cid + 1) begin
            push_cmd(case_cmd[cid]);
            issued_cmd_count = issued_cmd_count + 1;
        end
    end
    endtask

    task automatic wait_for_all_completions;
        integer cycles;
        integer settle_cycles;
        logic [31:0] cmd_status_reg;
        logic [31:0] done_count_reg;
        logic [31:0] last_done_reg;
        logic [31:0] engine_status_reg;
        logic [11:0] done_cmd_id;
        logic [2:0] done_opcode;
        logic [3:0] done_subop;
        logic done_group_end;
        logic done_illegal;
    begin
        cycles = 0;
        while ((pad_done_pulse_count < issued_cmd_count) && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge clock);
            cycles = cycles + 1;
        end

        if (pad_done_pulse_count != issued_cmd_count) begin
            $fatal(1, "timeout waiting for pad_dexmpc_complete count=%0d (got %0d)",
                   issued_cmd_count, pad_done_pulse_count);
        end
        d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        settle_cycles = 0;
        while (((cmd_status_reg[1] !== 1'b1) ||
                (cmd_status_reg[2] !== 1'b0) ||
                (cmd_status_reg[3] !== 1'b1) ||
                (cmd_status_reg[4] !== 1'b1) ||
                (cmd_status_reg[5] !== 1'b0)) &&
               (settle_cycles < 10000)) begin
            @(posedge clock);
            settle_cycles = settle_cycles + 1;
            d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        end

        if (cmd_status_reg[1] !== 1'b1) begin
            $fatal(1, "cmd sequencer empty bit is not set, cmdStatus_0=%h", cmd_status_reg);
        end
        if (cmd_status_reg[2] !== 1'b0) begin
            $fatal(1, "cmd sequencer busy bit is still set, cmdStatus_0=%h", cmd_status_reg);
        end
        if (cmd_status_reg[3] !== 1'b1) begin
            $fatal(1, "cmd sequencer idle bit is not set, cmdStatus_0=%h", cmd_status_reg);
        end
        if (cmd_status_reg[4] !== 1'b1) begin
            $fatal(1, "cmd sequencer allDone bit is not set, cmdStatus_0=%h", cmd_status_reg);
        end
        if (cmd_status_reg[5] !== 1'b0) begin
            $fatal(1, "cmd sequencer overflow bit is set, cmdStatus_0=%h", cmd_status_reg);
        end

        d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        if (done_count_reg != issued_cmd_count) begin
            $fatal(1, "doneCount_0 mismatch: expected %0d got %0d", issued_cmd_count, done_count_reg);
        end

        d2d_cfg_read(CFG_LASTDONE_0, last_done_reg);
        done_cmd_id = last_done_reg[11:0];
        done_opcode = last_done_reg[14:12];
        done_subop = last_done_reg[18:15];
        done_group_end = last_done_reg[19];
        done_illegal = last_done_reg[20];

        if (done_illegal) begin
            $fatal(1, "illegal command reported in lastDone_0=%h", last_done_reg);
        end
        if (done_cmd_id != (issued_cmd_count - 1)) begin
            $fatal(1, "lastDone cmd id mismatch: expected %0d got %0d", issued_cmd_count - 1, done_cmd_id);
        end
        if (done_opcode != OP_ABS || done_subop != SUB_ABS) begin
            $fatal(1, "lastDone opcode/subop mismatch: opcode=%0b subop=%0h", done_opcode, done_subop);
        end
        if (done_group_end !== 1'b1) begin
            $fatal(1, "lastDone group_end bit is not set, lastDone_0=%h", last_done_reg);
        end

        d2d_cfg_read(CFG_ENGINE_STATUS, engine_status_reg);
        if (engine_status_reg[3:0] != 4'b0000) begin
            $fatal(1, "engineStatus still busy after completion, engineStatus=%h", engine_status_reg);
        end
    end
    endtask

    always @(posedge clock) begin
        if (reset) begin
            pad_done_pulse_count <= 0;
        end else if (dexmpc_complete === 1'b1) begin
            pad_done_pulse_count <= pad_done_pulse_count + 1;
        end
    end

    initial begin
        $fsdbDumpfile("tb_TopChipTop_abs_d2d.fsdb");
        $fsdbDumpvars(0, tb_TopChipTop_abs_d2d, "+all");
    end

    initial begin
        integer cid;

        pad_done_pulse_count = 0;
        issued_cmd_count = 0;
        csv_lock = new(1);

        #100ns;
        @(negedge clock);

        // Frontend-only mode select: default to non-loop mode.
        // Change 32'h0 to 32'h1 here if loop mode is needed.
        d2d_cfg_write(CFG_IS_LOOP, 32'h0000_0000);

        smoke_test_sram_d2d();

        mkdir_ret = $system("mkdir -p verification/results/full_chip/d2d");
        in_csv_fd = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_abs_d2d_input.csv", "w");
        if (in_csv_fd == 0) begin
            $fatal(1, "failed to open verification/results/full_chip/d2d/tb_TopChipTop_abs_d2d_input.csv");
        end
        out_csv_fd = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_abs_d2d_output.csv", "w");
        if (out_csv_fd == 0) begin
            $fatal(1, "failed to open verification/results/full_chip/d2d/tb_TopChipTop_abs_d2d_output.csv");
        end

        write_input_header();
        write_output_header();

        build_cases();
        for (cid = 0; cid < CASES; cid = cid + 1) begin
            write_input_line(cid);
        end

        preload_cases_to_sram();
        push_all_cmds();
        wait_for_all_completions();

        repeat (4) @(posedge clock);
        for (cid = 0; cid < CASES; cid = cid + 1) begin
            capture_post_words(cid);
            csv_lock.get(1);
            write_output_line(
                cid,
                case_seq[cid],
                case_cmd_id[cid][7:0],
                case_dst_base[cid],
                case_rows[cid][15:0],
                case_cols[cid][15:0],
                case_word_count[cid][15:0],
                1'b1
            );
            csv_lock.put(1);
        end

        $fclose(in_csv_fd);
        $fclose(out_csv_fd);

        repeat (20) @(posedge clock);
        $display("tb_TopChipTop_abs_d2d completes at %t.", $time);
        $finish;
    end

    initial begin
        #50000000;
        $fatal(1, "simulation timeout");
    end

endmodule

module d2dm_burst_writer #(
    parameter int Burst = 16
)(
    input logic clock,
    input logic reset,

    input logic cmd_valid,
    input logic [20:0] cmd_addr,
    input logic [6:0] cmd_id,
    input logic [7:0] cmd_len,
    input logic [64*Burst-1:0] cmd_data,
    output logic cmd_complete,

    input logic d2dm_aw_ready,
    output logic d2dm_aw_valid,
    output logic [20:0] d2dm_aw_addr,
    output logic [6:0] d2dm_aw_id,
    output logic [7:0] d2dm_aw_len,
    input logic d2dm_w_ready,
    output logic d2dm_w_valid,
    output logic [63:0] d2dm_w_data,
    output logic d2dm_w_last,
    output logic d2dm_b_ready,
    input logic d2dm_b_valid,
    input logic [6:0] d2dm_b_id,
    input logic [1:0] d2dm_b_resp
);

    logic [7:0] w_count;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_aw_valid <= '0;
            d2dm_aw_addr <= '0;
            d2dm_aw_id <= '0;
            d2dm_aw_len <= '0;
        end else if (cmd_valid) begin
            d2dm_aw_valid <= 1'd1;
            d2dm_aw_addr <= cmd_addr;
            d2dm_aw_id <= cmd_id;
            d2dm_aw_len <= cmd_len;
        end else if (d2dm_aw_valid && d2dm_aw_ready) begin
            d2dm_aw_valid <= 1'd0;
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_w_valid <= '0;
            d2dm_w_data <= '0;
            d2dm_w_last <= '0;
            w_count <= '0;
        end else begin
            if (cmd_valid) begin
                d2dm_w_valid <= 1'd1;
                d2dm_w_data <= cmd_data[0 +: 64];
                d2dm_w_last <= w_count == cmd_len;
                w_count <= '0;
            end else if (d2dm_w_valid && d2dm_w_ready) begin
                if (w_count < cmd_len) begin
                    d2dm_w_valid <= 1'd1;
                    d2dm_w_data <= cmd_data[(w_count + 1) * 64 +: 64];
                    d2dm_w_last <= w_count == (cmd_len - 1);
                    w_count <= w_count + 1;
                end else begin
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
            cmd_complete <= '0;
        end else if (d2dm_b_valid && d2dm_b_ready) begin
            cmd_complete <= '1;
        end else begin
            cmd_complete <= '0;
        end
    end

endmodule : d2dm_burst_writer

module d2dm_burst_reader #(
    parameter int Burst = 16
)(
    input logic clock,
    input logic reset,

    input logic cmd_valid,
    input logic [20:0] cmd_addr,
    input logic [6:0] cmd_id,
    input logic [7:0] cmd_len,
    output logic [64*Burst-1:0] cmd_data,
    output logic cmd_complete,

    input logic d2dm_ar_ready,
    output logic d2dm_ar_valid,
    output logic [20:0] d2dm_ar_addr,
    output logic [6:0] d2dm_ar_id,
    output logic [7:0] d2dm_ar_len,
    output logic d2dm_r_ready,
    input logic d2dm_r_valid,
    input logic [63:0] d2dm_r_data,
    input logic d2dm_r_last,
    input logic [6:0] d2dm_r_id,
    input logic [1:0] d2dm_r_resp
);

    logic [7:0] r_count;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            d2dm_ar_valid <= '0;
            d2dm_ar_addr <= '0;
            d2dm_ar_id <= '0;
            d2dm_ar_len <= '0;
        end else if (cmd_valid) begin
            d2dm_ar_valid <= 1'd1;
            d2dm_ar_addr <= cmd_addr;
            d2dm_ar_id <= cmd_id;
            d2dm_ar_len <= cmd_len;
        end else if (d2dm_ar_valid && d2dm_ar_ready) begin
            d2dm_ar_valid <= 1'd0;
        end
    end

    assign d2dm_r_ready = 1'b1;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            r_count <= '0;
            cmd_data <= '0;
        end else if (d2dm_r_valid && d2dm_r_ready && d2dm_r_id == d2dm_ar_id) begin
            r_count <= r_count + 1;
            cmd_data[r_count*64 +: 64] <= d2dm_r_data;
        end else if (cmd_complete == '1) begin
            r_count <= '0;
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            cmd_complete <= '0;
        end else if (d2dm_r_valid && d2dm_r_ready && (r_count == cmd_len)) begin
            cmd_complete <= '1;
        end else begin
            cmd_complete <= '0;
        end
    end

endmodule : d2dm_burst_reader
