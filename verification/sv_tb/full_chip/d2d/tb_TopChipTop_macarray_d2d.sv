`timescale 1ns/1ps

module tb_TopChipTop_macarray_d2d #(parameter int Burst = 3) ();

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

    localparam integer DATA_W = SRAM_W;
    localparam integer LANES = FP16_PER_WORD;
    localparam integer MAX_DIM = 32;
    localparam integer CASES = 10;
    localparam integer COMBOS = 9;
    localparam integer POOL_SIZE = 96;

    localparam integer SRAM_GLOBAL = 0;
    localparam integer SRAM_LOCAL = 1;
    localparam integer SRAM_TEMP = 2;

    localparam integer OP_GEMM = 0;
    localparam integer OP_MUL = 1;
    localparam integer OP_ADD = 2;
    localparam integer OPS = 6;
    localparam integer MAX_CMDS = CASES * COMBOS * OPS;
    localparam integer TIMEOUT_CYCLES = 400000;

    localparam logic [2:0] OP_LA = 3'b011;
    localparam logic [3:0] SUB_GEMM = 4'h0;
    localparam logic [3:0] SUB_MUL = 4'h1;
    localparam logic [3:0] SUB_ADD = 4'h2;

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

    logic [15:0] matA [0:MAX_DIM-1][0:MAX_DIM-1];
    logic [15:0] matB [0:MAX_DIM-1][0:MAX_DIM-1];
    logic [15:0] matC [0:MAX_DIM-1][0:MAX_DIM-1];
    logic [15:0] vecA [0:MAX_DIM-1];
    logic [15:0] vecB [0:MAX_DIM-1];
    logic [15:0] vecC [0:MAX_DIM-1];
    logic [15:0] fp_pool [0:POOL_SIZE-1];

    integer fd_gemm_in;
    integer fd_gemm_out;
    integer fd_gemv_in;
    integer fd_gemv_out;
    integer fd_dot_in;
    integer fd_dot_out;
    integer fd_outer_in;
    integer fd_outer_out;
    integer fd_mul_in;
    integer fd_mul_out;
    integer fd_add_in;
    integer fd_add_out;

    integer case_id;
    string out_dir;
    logic [3:0] exp_subop [0:MAX_CMDS-1];
    integer next_cmd_id;
    integer expected_done;
    integer done_count;
    logic [31:0] last_done_count;
    integer pad_done_pulse_count;
    integer mkdir_ret;

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

      function automatic logic [15:0] pick_fp(input integer seed);
        integer idx;
        begin
          idx = seed % POOL_SIZE;
          if (idx < 0) idx = idx + POOL_SIZE;
          pick_fp = fp_pool[idx];
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

    function automatic int unsigned mpc_sram_depth(input int unsigned mem_id);
    begin
        case (mem_id)
            4'h0: mpc_sram_depth = 2048;
            4'h1, 4'h2, 4'h3, 4'h4: mpc_sram_depth = 512;
            4'h5, 4'h6, 4'h7, 4'h8: mpc_sram_depth = 896;
            4'h9, 4'hA, 4'hB, 4'hC: mpc_sram_depth = 128;
            4'hD, 4'hE: mpc_sram_depth = 256;
            default: mpc_sram_depth = 1;
        endcase
    end
    endfunction

    function automatic int unsigned mpc_sram_data_width(input int unsigned mem_id);
    begin
        case (mem_id)
            4'h9, 4'hA, 4'hB, 4'hC: mpc_sram_data_width = 16;
            4'hD, 4'hE: mpc_sram_data_width = 32;
            default: mpc_sram_data_width = 128;
        endcase
    end
    endfunction

    function automatic int unsigned mpc_sram_test_addr(input int unsigned mem_id, input int unsigned slot);
        int unsigned depth;
    begin
        depth = mpc_sram_depth(mem_id);
        case (slot)
            0: mpc_sram_test_addr = 0;
            1: mpc_sram_test_addr = (depth > 1) ? (depth - 1) : 0;
            default: mpc_sram_test_addr = (depth > 2) ? (depth >> 1) : 0;
        endcase
    end
    endfunction

    function automatic [127:0] mpc_sram_valid_mask(input int unsigned mem_id);
        int unsigned width;
    begin
        width = mpc_sram_data_width(mem_id);
        case (width)
            16: mpc_sram_valid_mask = {{112{1'b0}}, 16'hFFFF};
            32: mpc_sram_valid_mask = {{96{1'b0}}, 32'hFFFF_FFFF};
            default: mpc_sram_valid_mask = {128{1'b1}};
        endcase
    end
    endfunction

    function automatic [127:0] mpc_sram_test_pattern(
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
        mpc_sram_test_pattern = {lane3, lane2, lane1, lane0};
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
            valid_mask = mpc_sram_valid_mask(mem_id);
            for (slot = 0; slot < 3; slot = slot + 1) begin
                word_addr = mpc_sram_test_addr(mem_id, slot);
                addr = mpc_sram_addr(mem_id[3:0], word_addr);
                wdata = mpc_sram_test_pattern(mem_id, word_addr, slot + 2);
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

      task automatic init_pool;
        integer idx;
        begin
          for (idx = 0; idx < POOL_SIZE; idx = idx + 1) begin
            unique case (idx % 32)
              0:  fp_pool[idx] = 16'h3C00;
              1:  fp_pool[idx] = 16'hBC00;
              2:  fp_pool[idx] = 16'h4000;
              3:  fp_pool[idx] = 16'hC000;
              4:  fp_pool[idx] = 16'h4200;
              5:  fp_pool[idx] = 16'hC200;
              6:  fp_pool[idx] = 16'h3E00;
              7:  fp_pool[idx] = 16'hBE00;
              8:  fp_pool[idx] = 16'h3800;
              9:  fp_pool[idx] = 16'hB800;
              10: fp_pool[idx] = 16'h3400;
              11: fp_pool[idx] = 16'hB400;
              12: fp_pool[idx] = 16'h3555;
              13: fp_pool[idx] = 16'hB555;
              14: fp_pool[idx] = 16'h39AB;
              15: fp_pool[idx] = 16'hB9AB;
              16: fp_pool[idx] = 16'h3D55;
              17: fp_pool[idx] = 16'hBD55;
              18: fp_pool[idx] = 16'h3A80;
              19: fp_pool[idx] = 16'hBA80;
              20: fp_pool[idx] = 16'h3D99;
              21: fp_pool[idx] = 16'hBD99;
              22: fp_pool[idx] = 16'h4123;
              23: fp_pool[idx] = 16'hC123;
              24: fp_pool[idx] = 16'h3C00;
              25: fp_pool[idx] = 16'hBC00;
              26: fp_pool[idx] = 16'h2C00;
              27: fp_pool[idx] = 16'hAC00;
              28: fp_pool[idx] = 16'h1C00;
              29: fp_pool[idx] = 16'h9C00;
              30: fp_pool[idx] = 16'h0400;
              31: fp_pool[idx] = 16'h8400;
              default: fp_pool[idx] = 16'h0000;
            endcase
          end
        end
      endtask

      task automatic clear_matrices;
        int r;
        int c;
        begin
          for (r = 0; r < MAX_DIM; r++) begin
            for (c = 0; c < MAX_DIM; c++) begin
              matA[r][c] = 16'h0000;
              matB[r][c] = 16'h0000;
              matC[r][c] = 16'h0000;
            end
            vecA[r] = 16'h0000;
            vecB[r] = 16'h0000;
            vecC[r] = 16'h0000;
          end
        end
      endtask

    function automatic int sram_depth(input int sram_id);
    begin
        case (sram_id)
            SRAM_GLOBAL: sram_depth = GLOBAL_DEPTH;
            SRAM_LOCAL:  sram_depth = LOCAL_DEPTH;
            SRAM_TEMP:   sram_depth = TEMP_DEPTH;
            default:     sram_depth = 0;
        endcase
    end
    endfunction

    task automatic mem_write_fullword(
        input int sram_id,
        input int addr,
        input logic [DATA_W-1:0] data
    );
    begin
        if (sram_id == SRAM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (sram_id == SRAM_LOCAL  && addr >= LOCAL_DEPTH)  $fatal(1, "Local SRAM addr overflow");
        if (sram_id == SRAM_TEMP   && addr >= TEMP_DEPTH)   $fatal(1, "Temp SRAM addr overflow");
        d2d_write_128(core_sram_addr(sram_id, addr), data);
    end
    endtask

    task automatic mem_read_word_1cycle(
        input int sram_id,
        input int addr,
        output logic [DATA_W-1:0] data
    );
    begin
        if (sram_id == SRAM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (sram_id == SRAM_LOCAL  && addr >= LOCAL_DEPTH)  $fatal(1, "Local SRAM addr overflow");
        if (sram_id == SRAM_TEMP   && addr >= TEMP_DEPTH)   $fatal(1, "Temp SRAM addr overflow");
        d2d_read_128(core_sram_addr(sram_id, addr), data);
    end
    endtask

      task automatic write_matrix_to_mem(
        input int sram_id,
        input int base_addr,
        input int rows,
        input int cols,
        input logic [15:0] mat [0:MAX_DIM-1][0:MAX_DIM-1]
      );
        int total;
        int words;
        int w;
        int lane;
        int idx;
        int r;
        int c;
        logic [DATA_W-1:0] wr_word;
        begin
          total = rows * cols;
          words = (total + LANES - 1) / LANES;
          for (w = 0; w < words; w++) begin
            wr_word = '0;
            for (lane = 0; lane < LANES; lane++) begin
              idx = w * LANES + lane;
              if (idx < total) begin
                r = idx / cols;
                c = idx % cols;
                wr_word[lane * FPW +: FPW] = mat[r][c];
              end else begin
                wr_word[lane * FPW +: FPW] = 16'h0000;
              end
            end
            mem_write_fullword(sram_id, base_addr + w, wr_word);
          end
        end
      endtask

      task automatic read_matrix_from_mem(
        input int sram_id,
        input int base_addr,
        input int rows,
        input int cols,
        output logic [15:0] mat [0:MAX_DIM-1][0:MAX_DIM-1]
      );
        int total;
        int words;
        int w;
        int lane;
        int idx;
        int r;
        int c;
        logic [DATA_W-1:0] rd_word;
        begin
          total = rows * cols;
          words = (total + LANES - 1) / LANES;
          for (w = 0; w < words; w++) begin
            mem_read_word_1cycle(sram_id, base_addr + w, rd_word);
            for (lane = 0; lane < LANES; lane++) begin
              idx = w * LANES + lane;
              if (idx < total) begin
                r = idx / cols;
                c = idx % cols;
                mat[r][c] = rd_word[lane * FPW +: FPW];
              end
            end
          end
        end
      endtask

      task automatic clear_mem_range(
        input int sram_id,
        input int base_addr,
        input int total_elems
      );
        int words;
        int w;
        logic [DATA_W-1:0] zero_word;
        begin
          zero_word = '0;
          words = (total_elems + LANES - 1) / LANES;
          for (w = 0; w < words; w++) begin
            mem_write_fullword(sram_id, base_addr + w, zero_word);
          end
        end
      endtask

      task automatic write_matrix_csv(
        input int fd,
        input int case_id,
        input string name,
        input int rows,
        input int cols,
        input logic [15:0] mat [0:MAX_DIM-1][0:MAX_DIM-1]
      );
        int r;
        int c;
        begin
          $fdisplay(fd, "case,%0d,%s,rows,%0d,cols,%0d", case_id, name, rows, cols);
          for (r = 0; r < rows; r++) begin
            $fwrite(fd, "row%0d", r);
            for (c = 0; c < cols; c++) begin
              $fwrite(fd, ",%016b", mat[r][c]);
            end
            $fwrite(fd, "\n");
          end
          $fwrite(fd, "\n");
        end
      endtask

      task automatic write_vector_csv_col(
        input int fd,
        input int case_id,
        input string name,
        input int len,
        input logic [15:0] vec [0:MAX_DIM-1]
      );
        int i;
        begin
          $fdisplay(fd, "case,%0d,%s,rows,%0d,cols,1", case_id, name, len);
          for (i = 0; i < len; i++) begin
            $fwrite(fd, "row%0d,%016b\n", i, vec[i]);
          end
          $fwrite(fd, "\n");
        end
      endtask

      task automatic write_vector_csv_row(
        input int fd,
        input int case_id,
        input string name,
        input int len,
        input logic [15:0] vec [0:MAX_DIM-1]
      );
        int i;
        begin
          $fdisplay(fd, "case,%0d,%s,rows,1,cols,%0d", case_id, name, len);
          $fwrite(fd, "row0");
          for (i = 0; i < len; i++) begin
            $fwrite(fd, ",%016b", vec[i]);
          end
          $fwrite(fd, "\n\n");
        end
      endtask

      task automatic write_scalar_csv(
        input int fd,
        input int case_id,
        input logic [15:0] alpha
      );
        begin
          $fdisplay(fd, "case,%0d,scalar,alpha,%016b", case_id, alpha);
        end
      endtask

      task automatic gen_dims_gemm(
        input int case_id,
        output int nRows,
        output int mCols,
        output int kDim
      );
        int nSel;
        int mSel;
        int kSel;
        begin
          if (case_id < 10) begin
            nSel = $urandom_range(1, 16);
            mSel = $urandom_range(1, 16);
            kSel = $urandom_range(1, 16);
          end else if (case_id < 20) begin
            nSel = $urandom_range(17, MAX_DIM);
            mSel = $urandom_range(1, 16);
            kSel = $urandom_range(1, MAX_DIM);
          end else if (case_id < 30) begin
            nSel = $urandom_range(1, 16);
            mSel = $urandom_range(17, MAX_DIM);
            kSel = $urandom_range(1, MAX_DIM);
          end else begin
            nSel = $urandom_range(17, MAX_DIM);
            mSel = $urandom_range(17, MAX_DIM);
            kSel = $urandom_range(8, MAX_DIM);
          end
          nRows = nSel;
          mCols = mSel;
          kDim  = kSel;
        end
      endtask

      task automatic gen_dims_gemv(
        input int case_id,
        output int nRows,
        output int kDim
      );
        int nSel;
        int kSel;
        begin
          if (case_id < 10) begin
            nSel = $urandom_range(1, 16);
            kSel = $urandom_range(1, 16);
          end else if (case_id < 20) begin
            nSel = $urandom_range(17, MAX_DIM);
            kSel = $urandom_range(1, MAX_DIM);
          end else if (case_id < 30) begin
            nSel = $urandom_range(1, 16);
            kSel = $urandom_range(17, MAX_DIM);
          end else begin
            nSel = $urandom_range(17, MAX_DIM);
            kSel = $urandom_range(8, MAX_DIM);
          end
          nRows = nSel;
          kDim  = kSel;
        end
      endtask

      task automatic gen_dims_dot(
        input int case_id,
        output int kDim
      );
        int kSel;
        begin
          if (case_id < 10) begin
            kSel = $urandom_range(1, 16);
          end else if (case_id < 30) begin
            kSel = $urandom_range(17, MAX_DIM);
          end else begin
            kSel = $urandom_range(8, MAX_DIM);
          end
          kDim = kSel;
        end
      endtask

      task automatic gen_dims_nm(
        input int case_id,
        output int nRows,
        output int mCols
      );
        int nSel;
        int mSel;
        begin
          if (case_id < 10) begin
            nSel = $urandom_range(1, 16);
            mSel = $urandom_range(1, 16);
          end else if (case_id < 20) begin
            nSel = $urandom_range(17, MAX_DIM);
            mSel = $urandom_range(1, 16);
          end else if (case_id < 30) begin
            nSel = $urandom_range(1, 16);
            mSel = $urandom_range(17, MAX_DIM);
          end else begin
            nSel = $urandom_range(17, MAX_DIM);
            mSel = $urandom_range(17, MAX_DIM);
          end
          nRows = nSel;
          mCols = mSel;
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

    task automatic wait_for_done_count(input integer target);
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
        while ((pad_done_pulse_count < target) && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge clock);
            cycles = cycles + 1;
        end
        if (pad_done_pulse_count < target) begin
            $fatal(1, "Timeout waiting for pad_dexmpc_complete %0d (got %0d)", target, pad_done_pulse_count);
        end

        d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        settle_cycles = 0;
        while ((done_count_reg != target) && (settle_cycles < 10000)) begin
            @(posedge clock);
            settle_cycles = settle_cycles + 1;
            d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        end
        if (done_count_reg != target) begin
            $fatal(1, "doneCount_0 mismatch: expected %0d got %0d", target, done_count_reg);
        end
        if (done_count_reg < last_done_count) begin
            $fatal(1, "doneCount_0 regressed: last=%0d now=%0d", last_done_count, done_count_reg);
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
        if (done_cmd_id !== (target - 1)) begin
            $fatal(1, "doneCmdId mismatch: got %0d expected %0d", done_cmd_id, target - 1);
        end
        if (done_opcode !== OP_LA) begin
            $fatal(1, "doneOpcode mismatch: got %0b expected %0b", done_opcode, OP_LA);
        end
        if (done_cmd_id >= MAX_CMDS) begin
            $fatal(1, "doneCmdId out of range: %0d", done_cmd_id);
        end
        if (done_subop !== exp_subop[done_cmd_id]) begin
            $fatal(1, "doneSubop mismatch for cmd %0d: got %0h expected %0h",
                   done_cmd_id, done_subop, exp_subop[done_cmd_id]);
        end
        if (done_group_end !== 1'b1) begin
            $fatal(1, "done group_end bit is not set for cmd %0d", done_cmd_id);
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

        d2d_cfg_read(CFG_ENGINE_STATUS, engine_status_reg);
        if (engine_status_reg[3:0] != 4'b0000) begin
            $fatal(1, "engineStatus still busy after completion, engineStatus=%h", engine_status_reg);
        end

        last_done_count = done_count_reg;
        expected_done = target;
        done_count = target;
    end
    endtask

      task automatic issue_gemm_cmd(
        input integer nRows,
        input integer mCols,
        input integer kDim,
        input integer baseA,
        input integer baseB,
        input integer baseC,
        input integer baseASramId,
        input integer baseBSramId,
        input integer baseCSramId,
        input logic   group_end
      );
        logic [95:0] cmd;
        begin
          if (next_cmd_id >= MAX_CMDS) begin
            $fatal(1, "Command id overflow: %0d", next_cmd_id);
          end
          cmd = make_cmd(
            next_cmd_id[11:0],
            OP_LA,
            SUB_GEMM,
            group_end,
            pack_addr(baseASramId[1:0], baseA[10:0]),
            pack_addr(baseBSramId[1:0], baseB[10:0]),
            pack_addr(baseCSramId[1:0], baseC[10:0]),
            mCols[11:0],
            nRows[11:0],
            kDim[11:0]
          );
          exp_subop[next_cmd_id] = SUB_GEMM;
          push_cmd(cmd);
          next_cmd_id = next_cmd_id + 1;
        end
      endtask

      task automatic issue_mul_cmd(
        input integer rows,
        input integer cols,
        input logic [15:0] alpha,
        input integer baseA,
        input integer baseC,
        input integer baseASramId,
        input integer baseCSramId,
        input logic   group_end
      );
        logic [12:0] addr2;
        logic [11:0] dim2;
        logic [95:0] cmd;
        begin
          if (next_cmd_id >= MAX_CMDS) begin
            $fatal(1, "Command id overflow: %0d", next_cmd_id);
          end
          addr2 = alpha[12:0];
          dim2 = {9'b0, alpha[15:13]};
          cmd = make_cmd(
            next_cmd_id[11:0],
            OP_LA,
            SUB_MUL,
            group_end,
            pack_addr(baseASramId[1:0], baseA[10:0]),
            pack_addr(baseCSramId[1:0], baseC[10:0]),
            addr2,
            rows[11:0],
            cols[11:0],
            dim2
          );
          exp_subop[next_cmd_id] = SUB_MUL;
          push_cmd(cmd);
          next_cmd_id = next_cmd_id + 1;
        end
      endtask

      task automatic issue_add_cmd(
        input integer rows,
        input integer cols,
        input integer baseA,
        input integer baseB,
        input integer baseC,
        input integer baseASramId,
        input integer baseBSramId,
        input integer baseCSramId,
        input logic   group_end
      );
        logic [95:0] cmd;
        begin
          if (next_cmd_id >= MAX_CMDS) begin
            $fatal(1, "Command id overflow: %0d", next_cmd_id);
          end
          cmd = make_cmd(
            next_cmd_id[11:0],
            OP_LA,
            SUB_ADD,
            group_end,
            pack_addr(baseASramId[1:0], baseA[10:0]),
            pack_addr(baseBSramId[1:0], baseB[10:0]),
            pack_addr(baseCSramId[1:0], baseC[10:0]),
            rows[11:0],
            cols[11:0],
            12'h000
          );
          exp_subop[next_cmd_id] = SUB_ADD;
          push_cmd(cmd);
          next_cmd_id = next_cmd_id + 1;
        end
      endtask

    always @(posedge dexmpc_complete or posedge reset) begin
        if (reset) begin
            pad_done_pulse_count <= 0;
        end else begin
            pad_done_pulse_count <= pad_done_pulse_count + 1;
        end
    end

    initial begin
        $fsdbDumpfile("tb_TopChipTop_macarray_d2d.fsdb");
        $fsdbDumpvars(0, tb_TopChipTop_macarray_d2d, "+all");
    end

    initial begin
        pad_done_pulse_count = 0;
        next_cmd_id = 0;
        expected_done = 0;
        done_count = 0;
        last_done_count = 0;
        init_pool();
        clear_matrices();

        #100ns;
        @(negedge clock);

        d2d_cfg_write(CFG_IS_LOOP, 32'h0000_0000);
        smoke_test_sram_d2d();

        out_dir = "verification/results/full_chip/d2d";
        mkdir_ret = $system("mkdir -p verification/results/full_chip/d2d");

        fd_gemm_in   = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gemm_input.csv"}, "w");
        fd_gemm_out  = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gemm_output.csv"}, "w");
        fd_gemv_in   = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gemv_input.csv"}, "w");
        fd_gemv_out  = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gemv_output.csv"}, "w");
        fd_dot_in    = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gevv_dot_input.csv"}, "w");
        fd_dot_out   = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gevv_dot_output.csv"}, "w");
        fd_outer_in  = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gevv_outer_input.csv"}, "w");
        fd_outer_out = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_gevv_outer_output.csv"}, "w");
        fd_mul_in    = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_mul_input.csv"}, "w");
        fd_mul_out   = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_mul_output.csv"}, "w");
        fd_add_in    = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_add_input.csv"}, "w");
        fd_add_out   = $fopen({out_dir, "/tb_TopChipTop_macarray_d2d_add_output.csv"}, "w");

        if (fd_gemm_in == 0 || fd_gemm_out == 0 ||
            fd_gemv_in == 0 || fd_gemv_out == 0 ||
            fd_dot_in == 0 || fd_dot_out == 0 ||
            fd_outer_in == 0 || fd_outer_out == 0 ||
            fd_mul_in == 0 || fd_mul_out == 0 ||
            fd_add_in == 0 || fd_add_out == 0) begin
          $fatal(1, "failed to open result csv files");
        end
            // GEMM
            for (case_id = 0; case_id < CASES; case_id++) begin
              int N;
              int M;
              int K;
              int elemsA;
              int elemsB;
              int elemsC;
              int wordsA;
              int wordsB;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int r;
              int c;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_gemm(case_id, N, M, K);
              elemsA = N * K;
              elemsB = K * M;
              elemsC = N * M;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsB = (elemsB + LANES - 1) / LANES;
              wordsC = (elemsC + LANES - 1) / LANES;

              clear_matrices();
              for (r = 0; r < N; r++) begin
                for (c = 0; c < K; c++) begin
                  matA[r][c] = pick_fp(case_id * 131 + r * 17 + c * 7);
                end
              end
              for (r = 0; r < K; r++) begin
                for (c = 0; c < M; c++) begin
                  matB[r][c] = pick_fp(case_id * 197 + r * 11 + c * 13 + 5);
                end
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;
                baseB = wordsA;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "GEMM case %0d SRAM %0d A overflow", case_id, in_id);
                end
                if ((baseB + wordsB) > sram_depth(in_id)) begin
                  $fatal(1, "GEMM case %0d SRAM %0d B overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, N, K, matA);
                write_matrix_to_mem(in_id, baseB, K, M, matB);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "GEMM case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_matrix_csv(fd_gemm_in, case_tag, "A", N, K, matA);
                  write_matrix_csv(fd_gemm_in, case_tag, "B", K, M, matB);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  issue_gemm_cmd(N, M, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  read_matrix_from_mem(out_id, baseC, N, M, matC);
                  write_matrix_csv(fd_gemm_out, case_tag, "C", N, M, matC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
                clear_mem_range(in_id, baseB, elemsB);
              end
            end

            // GEMV (GEMM with M=1)
            for (case_id = 0; case_id < CASES; case_id++) begin
              int N;
              int K;
              int elemsA;
              int elemsB;
              int elemsC;
              int wordsA;
              int wordsB;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int r;
              int c;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_gemv(case_id, N, K);
              elemsA = N * K;
              elemsB = K;
              elemsC = N;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsB = (elemsB + LANES - 1) / LANES;
              wordsC = (elemsC + LANES - 1) / LANES;

              clear_matrices();
              for (r = 0; r < N; r++) begin
                for (c = 0; c < K; c++) begin
                  matA[r][c] = pick_fp(case_id * 131 + r * 17 + c * 7);
                end
              end
              for (r = 0; r < K; r++) begin
                vecB[r] = pick_fp(case_id * 197 + r * 11 + 5);
                matB[r][0] = vecB[r];
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;
                baseB = wordsA;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "GEMV case %0d SRAM %0d A overflow", case_id, in_id);
                end
                if ((baseB + wordsB) > sram_depth(in_id)) begin
                  $fatal(1, "GEMV case %0d SRAM %0d B overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, N, K, matA);
                write_matrix_to_mem(in_id, baseB, K, 1, matB);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "GEMV case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_matrix_csv(fd_gemv_in, case_tag, "A", N, K, matA);
                  write_vector_csv_col(fd_gemv_in, case_tag, "B", K, vecB);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  issue_gemm_cmd(N, 1, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  read_matrix_from_mem(out_id, baseC, N, 1, matC);
                  for (r = 0; r < N; r++) begin
                    vecC[r] = matC[r][0];
                  end
                  write_vector_csv_col(fd_gemv_out, case_tag, "C", N, vecC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
                clear_mem_range(in_id, baseB, elemsB);
              end
            end

            // GEVV-dot (GEMM with N=1, M=1)
            for (case_id = 0; case_id < CASES; case_id++) begin
              int K;
              int elemsA;
              int elemsB;
              int elemsC;
              int wordsA;
              int wordsB;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int i;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_dot(case_id, K);
              elemsA = K;
              elemsB = K;
              elemsC = 1;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsB = (elemsB + LANES - 1) / LANES;
              wordsC = 1;

              clear_matrices();
              for (i = 0; i < K; i++) begin
                vecA[i] = pick_fp(case_id * 131 + i * 17);
                vecB[i] = pick_fp(case_id * 197 + i * 13 + 5);
                matA[0][i] = vecA[i];
                matB[i][0] = vecB[i];
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;
                baseB = wordsA;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "DOT case %0d SRAM %0d A overflow", case_id, in_id);
                end
                if ((baseB + wordsB) > sram_depth(in_id)) begin
                  $fatal(1, "DOT case %0d SRAM %0d B overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, 1, K, matA);
                write_matrix_to_mem(in_id, baseB, K, 1, matB);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "DOT case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_vector_csv_row(fd_dot_in, case_tag, "A", K, vecA);
                  write_vector_csv_col(fd_dot_in, case_tag, "B", K, vecB);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  issue_gemm_cmd(1, 1, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  read_matrix_from_mem(out_id, baseC, 1, 1, matC);
                  write_matrix_csv(fd_dot_out, case_tag, "C", 1, 1, matC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
                clear_mem_range(in_id, baseB, elemsB);
              end
            end

            // GEVV-outer (GEMM with K=1)
            for (case_id = 0; case_id < CASES; case_id++) begin
              int N;
              int M;
              int elemsA;
              int elemsB;
              int elemsC;
              int wordsA;
              int wordsB;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int i;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_nm(case_id, N, M);
              elemsA = N;
              elemsB = M;
              elemsC = N * M;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsB = (elemsB + LANES - 1) / LANES;
              wordsC = (elemsC + LANES - 1) / LANES;

              clear_matrices();
              for (i = 0; i < N; i++) begin
                vecA[i] = pick_fp(case_id * 131 + i * 17);
                matA[i][0] = vecA[i];
              end
              for (i = 0; i < M; i++) begin
                vecB[i] = pick_fp(case_id * 197 + i * 13 + 5);
                matB[0][i] = vecB[i];
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;
                baseB = wordsA;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "OUTER case %0d SRAM %0d A overflow", case_id, in_id);
                end
                if ((baseB + wordsB) > sram_depth(in_id)) begin
                  $fatal(1, "OUTER case %0d SRAM %0d B overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, N, 1, matA);
                write_matrix_to_mem(in_id, baseB, 1, M, matB);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "OUTER case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_vector_csv_col(fd_outer_in, case_tag, "A", N, vecA);
                  write_vector_csv_row(fd_outer_in, case_tag, "B", M, vecB);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  issue_gemm_cmd(N, M, 1, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  read_matrix_from_mem(out_id, baseC, N, M, matC);
                  write_matrix_csv(fd_outer_out, case_tag, "C", N, M, matC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
                clear_mem_range(in_id, baseB, elemsB);
              end
            end

            // MUL
            for (case_id = 0; case_id < CASES; case_id++) begin
              int N;
              int M;
              int elemsA;
              int elemsC;
              int wordsA;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int r;
              int c;
              logic [15:0] alpha;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_nm(case_id, N, M);
              elemsA = N * M;
              elemsC = N * M;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsC = (elemsC + LANES - 1) / LANES;

              alpha = pick_fp(case_id * 193 + 17);

              clear_matrices();
              for (r = 0; r < N; r++) begin
                for (c = 0; c < M; c++) begin
                  matA[r][c] = pick_fp(case_id * 131 + r * 17 + c * 29 + 7);
                end
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "MUL case %0d SRAM %0d A overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, N, M, matA);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? wordsA : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "MUL case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_scalar_csv(fd_mul_in, case_tag, alpha);
                  write_matrix_csv(fd_mul_in, case_tag, "A", N, M, matA);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? wordsA : 0;
                  issue_mul_cmd(N, M, alpha, baseA, baseC, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? wordsA : 0;
                  read_matrix_from_mem(out_id, baseC, N, M, matC);
                  write_matrix_csv(fd_mul_out, case_tag, "C", N, M, matC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
              end
            end

            // ADD
            for (case_id = 0; case_id < CASES; case_id++) begin
              int N;
              int M;
              int elemsA;
              int elemsB;
              int elemsC;
              int wordsA;
              int wordsB;
              int wordsC;
              int baseA;
              int baseB;
              int baseC;
              int r;
              int c;
              int in_id;
              int out_id;
              int combo;
              int case_tag;

              gen_dims_nm(case_id, N, M);
              elemsA = N * M;
              elemsB = N * M;
              elemsC = N * M;
              wordsA = (elemsA + LANES - 1) / LANES;
              wordsB = (elemsB + LANES - 1) / LANES;
              wordsC = (elemsC + LANES - 1) / LANES;

              clear_matrices();
              for (r = 0; r < N; r++) begin
                for (c = 0; c < M; c++) begin
                  matA[r][c] = pick_fp(case_id * 131 + r * 17 + c * 29 + 7);
                  matB[r][c] = pick_fp(case_id * 173 + r * 23 + c * 31 + 11);
                end
              end

              for (in_id = 0; in_id < 3; in_id++) begin
                int done_target;
                baseA = 0;
                baseB = wordsA;

                if ((baseA + wordsA) > sram_depth(in_id)) begin
                  $fatal(1, "ADD case %0d SRAM %0d A overflow", case_id, in_id);
                end
                if ((baseB + wordsB) > sram_depth(in_id)) begin
                  $fatal(1, "ADD case %0d SRAM %0d B overflow", case_id, in_id);
                end

                write_matrix_to_mem(in_id, baseA, N, M, matA);
                write_matrix_to_mem(in_id, baseB, N, M, matB);

                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;

                  if ((baseC + wordsC) > sram_depth(out_id)) begin
                    $fatal(1, "ADD case %0d SRAM %0d C overflow", case_tag, out_id);
                  end

                  write_matrix_csv(fd_add_in, case_tag, "A", N, M, matA);
                  write_matrix_csv(fd_add_in, case_tag, "B", N, M, matB);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                repeat (2) @(posedge clock);
                done_target = done_count + 3;
                for (out_id = 0; out_id < 3; out_id++) begin
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  issue_add_cmd(N, M, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
                end
                wait_for_done_count(done_target);
                @(posedge clock);

                repeat (2) @(posedge clock);
                for (out_id = 0; out_id < 3; out_id++) begin
                  combo = in_id * 3 + out_id;
                  case_tag = case_id * COMBOS + combo;
                  baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
                  read_matrix_from_mem(out_id, baseC, N, M, matC);
                  write_matrix_csv(fd_add_out, case_tag, "C", N, M, matC);
                  clear_mem_range(out_id, baseC, elemsC);
                end

                clear_mem_range(in_id, baseA, elemsA);
                clear_mem_range(in_id, baseB, elemsB);
              end
            end

        if (next_cmd_id != MAX_CMDS) begin
            $fatal(1, "issued command count mismatch: expected %0d got %0d", MAX_CMDS, next_cmd_id);
        end
        if (pad_done_pulse_count != MAX_CMDS) begin
            $fatal(1, "pad done pulse mismatch: expected %0d got %0d", MAX_CMDS, pad_done_pulse_count);
        end

        $fclose(fd_gemm_in);
        $fclose(fd_gemm_out);
        $fclose(fd_gemv_in);
        $fclose(fd_gemv_out);
        $fclose(fd_dot_in);
        $fclose(fd_dot_out);
        $fclose(fd_outer_in);
        $fclose(fd_outer_out);
        $fclose(fd_mul_in);
        $fclose(fd_mul_out);
        $fclose(fd_add_in);
        $fclose(fd_add_out);

        repeat (20) @(posedge clock);
        $display("tb_TopChipTop_macarray_d2d completes at %t.", $time);
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
