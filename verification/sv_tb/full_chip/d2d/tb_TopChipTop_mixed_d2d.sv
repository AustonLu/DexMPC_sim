`timescale 1ns/1ps

module tb_TopChipTop_mixed_d2d #(parameter int Burst = 3) ();

    parameter CLK_PERIOD = 4;

    localparam integer FPW = 16;
    localparam integer SRAM_W = 128;
    localparam integer FP16_PER_WORD = SRAM_W / FPW;

    localparam integer GLOBAL_DEPTH = 2048;
    localparam integer LOCAL_DEPTH = 512;
    localparam integer TEMP_DEPTH = 896;
    localparam integer ADDR_W = 11;

    localparam integer SRAM_GLOBAL = 0;
    localparam integer SRAM_LOCAL0 = 1;
    localparam integer SRAM_TEMP0 = 2;

    localparam integer MEM_TRIG_SIN_EVEN = 9;
    localparam integer MEM_TRIG_SIN_ODD = 10;
    localparam integer MEM_TRIG_COS_EVEN = 11;
    localparam integer MEM_TRIG_COS_ODD = 12;
    localparam integer MEM_SOFT_EVEN = 13;
    localparam integer MEM_SOFT_ODD = 14;

    localparam integer MAX_CASES = 40;
    localparam integer MAX_WORDS = 64;
    localparam integer MAX_DIM = 16;
    localparam integer MAX_REDUCE_ELEMS = 32;
    localparam integer FIFO_DEPTH = 32;
    localparam integer BURST_FILL_CMDS = FIFO_DEPTH + 1;
    localparam integer TIMEOUT_CYCLES = 1200000;
    localparam integer TRIG_BANK_DEPTH = 128;
    localparam integer TRIG_TOTAL_WORDS = 4 * TRIG_BANK_DEPTH;
    localparam integer SOFTPLUS_BANK_DEPTH = 256;
    localparam integer SOFTPLUS_TOTAL_WORDS = 2 * SOFTPLUS_BANK_DEPTH;

    localparam integer KIND_ABS = 0;
    localparam integer KIND_LAYOUT_TRANSPOSE = 1;
    localparam integer KIND_LAYOUT_ASSEMBLE = 2;
    localparam integer KIND_REDUCE_ADD = 3;
    localparam integer KIND_REDUCE_CMP = 4;
    localparam integer KIND_GEMM = 5;
    localparam integer KIND_MUL = 6;
    localparam integer KIND_ADD = 7;
    localparam integer KIND_LUT = 8;

    localparam logic [2:0] OP_ABS = 3'b001;
    localparam logic [2:0] OP_REDUCE = 3'b010;
    localparam logic [2:0] OP_LA = 3'b011;
    localparam logic [2:0] OP_LUT = 3'b100;
    localparam logic [2:0] OP_DATALAYOUT = 3'b101;

    localparam logic [3:0] SUB_ABS = 4'h0;
    localparam logic [3:0] SUB_SIN = 4'h0;
    localparam logic [3:0] SUB_COS = 4'h1;
    localparam logic [3:0] SUB_SOFTPLUS = 4'h2;
    localparam logic [3:0] SUB_CMP_REDUCE = 4'h0;
    localparam logic [3:0] SUB_ADD_TREE = 4'h1;
    localparam logic [3:0] SUB_GEMM = 4'h0;
    localparam logic [3:0] SUB_MUL = 4'h1;
    localparam logic [3:0] SUB_ADD = 4'h2;
    localparam logic [3:0] SUB_ASSEMBLE = 4'h0;
    localparam logic [3:0] SUB_TRANSPOSE = 4'h1;

    localparam logic [15:0] FP16_ZERO = 16'h0000;
    localparam logic [15:0] FP16_HALF = 16'h3800;
    localparam logic [15:0] FP16_ONE = 16'h3C00;
    localparam logic [15:0] FP16_TWO = 16'h4000;
    localparam logic [15:0] FP16_THREE = 16'h4200;
    localparam logic [15:0] FP16_FOUR = 16'h4400;
    localparam logic [15:0] FP16_FIVE = 16'h4500;
    localparam logic [15:0] FP16_SIX = 16'h4600;
    localparam logic [15:0] FP16_SEVEN = 16'h4700;
    localparam logic [15:0] FP16_EIGHT = 16'h4800;
    localparam logic [15:0] FP16_SIXTEEN = 16'h4C00;
    localparam logic [15:0] FP16_NEG_HALF = 16'hB800;
    localparam logic [15:0] FP16_NEG_ONE = 16'hBC00;
    localparam logic [15:0] FP16_NEG_TWO = 16'hC000;
    localparam logic [15:0] FP16_NEG_THREE = 16'hC200;
    localparam logic [15:0] FP16_NEG_FOUR = 16'hC400;
    localparam logic [15:0] FP16_NEG_FIVE = 16'hC500;
    localparam logic [14:0] EIGHT_PI_BITS = 15'h4E48;

    localparam [31:0] BASE_DEXMPC_ADDR = 32'h0000_0000;
    localparam int unsigned CFG_CMDWORD_0_0 = 0;
    localparam int unsigned CFG_CMDWORD_0_1 = 1;
    localparam int unsigned CFG_CMDWORD_0_2 = 2;
    localparam int unsigned CFG_CMDCTRL_0 = 12;
    localparam int unsigned CFG_CMDSTATUS_0 = 22;
    localparam int unsigned CFG_DONECOUNT_0 = 26;
    localparam int unsigned CFG_LASTDONE_0 = 30;
    localparam int unsigned CFG_ADD_REDUCE_REG_0 = 42;
    localparam int unsigned CFG_CMP_REDUCE_REG0_0 = 46;
    localparam int unsigned CFG_CMP_REDUCE_REG1_0 = 50;
    localparam int unsigned CFG_ENGINE_STATUS = 54;
    localparam int unsigned CFG_ALLDONE_REG = 55;
    localparam int unsigned CFG_IS_LOOP = 63;

    localparam logic [6:0] D2D_WR_ID_LO = 7'h0C;
    localparam logic [6:0] D2D_WR_ID_HI = 7'h0D;
    localparam logic [6:0] D2D_RD_ID_LO = 7'h2A;
    localparam logic [6:0] D2D_RD_ID_HI = 7'h2B;

    typedef logic [SRAM_W-1:0] word_vec_t [0:MAX_WORDS-1];
    typedef logic [15:0] matrix_t [0:MAX_DIM-1][0:MAX_DIM-1];
    typedef logic [15:0] vector_t [0:MAX_REDUCE_ELEMS-1];

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

    integer num_cases;
    integer case_kind [0:MAX_CASES-1];
    logic [2:0] case_opcode [0:MAX_CASES-1];
    logic [3:0] case_subop [0:MAX_CASES-1];
    logic [11:0] case_cmd_id [0:MAX_CASES-1];
    logic [95:0] case_cmd [0:MAX_CASES-1];

    integer case_src_mem [0:MAX_CASES-1];
    integer case_aux_mem [0:MAX_CASES-1];
    integer case_dst_mem [0:MAX_CASES-1];
    integer case_src_base [0:MAX_CASES-1];
    integer case_aux_base [0:MAX_CASES-1];
    integer case_dst_base [0:MAX_CASES-1];
    integer case_rows [0:MAX_CASES-1];
    integer case_cols [0:MAX_CASES-1];
    integer case_kdim [0:MAX_CASES-1];
    integer case_dst_rows [0:MAX_CASES-1];
    integer case_dst_cols [0:MAX_CASES-1];
    integer case_len [0:MAX_CASES-1];
    integer case_off_r [0:MAX_CASES-1];
    integer case_off_c [0:MAX_CASES-1];
    logic [15:0] case_alpha [0:MAX_CASES-1];

    integer case_src_elems [0:MAX_CASES-1];
    integer case_aux_elems [0:MAX_CASES-1];
    integer case_dst_elems [0:MAX_CASES-1];
    integer case_src_words [0:MAX_CASES-1];
    integer case_aux_words [0:MAX_CASES-1];
    integer case_dst_words [0:MAX_CASES-1];

    word_vec_t pre_src_words [0:MAX_CASES-1];
    word_vec_t pre_aux_words [0:MAX_CASES-1];
    word_vec_t pre_dst_words [0:MAX_CASES-1];
    word_vec_t post_dst_words [0:MAX_CASES-1];

    logic [15:0] got_reduce_value [0:MAX_CASES-1];
    logic [11:0] got_reduce_index [0:MAX_CASES-1];
    logic reduce_result_seen [0:MAX_CASES-1];
    logic done_seen [0:MAX_CASES-1];

    integer next_base_global;
    integer next_base_local;
    integer next_base_temp;

    integer done_count;
    integer expected_done;
    logic [31:0] last_done_count;
    logic saw_fifo_full;
    integer max_fifo_count;

    integer pad_done_pulse_count;
    integer observed_done_count;
    integer issued_cmd_count;
    integer issue_order [0:MAX_CASES-1];
    integer reduce_case_ids [0:MAX_CASES-1];
    integer non_reduce_case_ids [0:MAX_CASES-1];
    integer num_reduce_cases;
    integer num_non_reduce_cases;

    logic [15:0] trig_mem [0:TRIG_TOTAL_WORDS-1];
    logic [31:0] soft_mem [0:SOFTPLUS_TOTAL_WORDS-1];

    integer fd_abs_in;
    integer fd_abs_out;
    integer fd_trans_in;
    integer fd_trans_out;
    integer fd_assem_in;
    integer fd_assem_out;
    integer fd_reduce_add_in;
    integer fd_reduce_add_out;
    integer fd_reduce_cmp_in;
    integer fd_reduce_cmp_out;
    integer fd_gemm_in;
    integer fd_gemm_out;
    integer fd_mul_in;
    integer fd_mul_out;
    integer fd_add_in;
    integer fd_add_out;
    integer fd_lut_in;
    integer fd_lut_out;
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
        .io_ctrlBusPorts_writeAddr_bits_prot('0),
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

    function automatic logic [15:0] rand_fp16();
        reg [15:0] v;
        integer tries;
        bit found;
    begin
        found = 1'b0;
        v = 16'h3C00;
        for (tries = 0; tries < 1000; tries = tries + 1) begin
            v = $urandom;
            if (v[14:10] != 5'h1F) begin
                found = 1'b1;
                break;
            end
        end
        if (!found) begin
            v = 16'h3C00;
        end
        rand_fp16 = v;
    end
    endfunction

    function automatic logic [15:0] rand_fp16_trig_range();
        reg [15:0] v;
        integer tries;
        bit found;
    begin
        found = 1'b0;
        v = 16'h0000;
        for (tries = 0; tries < 2000; tries = tries + 1) begin
            v = $urandom;
            if ((v[14:10] != 5'h1F) && (v[14:0] <= EIGHT_PI_BITS)) begin
                found = 1'b1;
                break;
            end
        end
        if (!found) begin
            v = 16'h0000;
        end
        rand_fp16_trig_range = v;
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

    function automatic integer sram_depth(input integer mem_id);
      begin
        case (mem_id)
          SRAM_GLOBAL: sram_depth = GLOBAL_DEPTH;
          SRAM_LOCAL0: sram_depth = LOCAL_DEPTH;
          SRAM_TEMP0:  sram_depth = TEMP_DEPTH;
          default:     sram_depth = 0;
        endcase
      end
    endfunction

    function automatic logic [1:0] mem_id_bits(input integer mem_id);
      begin
        case (mem_id)
          SRAM_GLOBAL: mem_id_bits = 2'b00;
          SRAM_LOCAL0: mem_id_bits = 2'b01;
          SRAM_TEMP0:  mem_id_bits = 2'b10;
          default:     mem_id_bits = 2'b11;
        endcase
      end
    endfunction

    function automatic logic [14:0] pack_buf_addr(
      input integer mem_id,
      input logic [10:0] word_idx
    );
      logic [3:0] mem_sel;
      logic [10:0] word_sel;
      begin
        case (mem_id)
          SRAM_GLOBAL: begin
            mem_sel = 4'h0;
            word_sel = word_idx;
          end
          SRAM_LOCAL0: begin
            mem_sel = 4'h1;
            word_sel = {2'b0, word_idx[8:0]};
          end
          SRAM_TEMP0: begin
            mem_sel = 4'h5;
            word_sel = {1'b0, word_idx[9:0]};
          end
          default: begin
            mem_sel = 4'hf;
            word_sel = 11'h0;
          end
        endcase
        pack_buf_addr = {mem_sel, word_sel};
      end
    endfunction

    function automatic logic [15:0] pick_pos_fp(input integer idx);
      begin
        case (idx % 9)
          0: pick_pos_fp = FP16_HALF;
          1: pick_pos_fp = FP16_ONE;
          2: pick_pos_fp = FP16_TWO;
          3: pick_pos_fp = FP16_THREE;
          4: pick_pos_fp = FP16_FOUR;
          5: pick_pos_fp = FP16_FIVE;
          6: pick_pos_fp = FP16_SIX;
          7: pick_pos_fp = FP16_SEVEN;
          default: pick_pos_fp = FP16_EIGHT;
        endcase
      end
    endfunction

    function automatic logic [15:0] pick_abs_fp(input integer idx);
      begin
        case (idx % 10)
          0: pick_abs_fp = FP16_NEG_ONE;
          1: pick_abs_fp = FP16_TWO;
          2: pick_abs_fp = FP16_NEG_THREE;
          3: pick_abs_fp = FP16_FOUR;
          4: pick_abs_fp = FP16_NEG_FIVE;
          5: pick_abs_fp = FP16_HALF;
          6: pick_abs_fp = FP16_NEG_HALF;
          7: pick_abs_fp = FP16_EIGHT;
          8: pick_abs_fp = FP16_NEG_TWO;
          default: pick_abs_fp = FP16_ONE;
        endcase
      end
    endfunction

    function automatic logic [15:0] get_word_vec_elem(
      input word_vec_t words,
      input integer elem_idx
    );
      integer word_idx;
      integer lane_idx;
      begin
        word_idx = elem_idx / FP16_PER_WORD;
        lane_idx = elem_idx % FP16_PER_WORD;
        if (elem_idx < 0 || word_idx >= MAX_WORDS) begin
          get_word_vec_elem = FP16_ZERO;
        end else begin
          get_word_vec_elem = words[word_idx][lane_idx * FPW +: FPW];
        end
      end
    endfunction

    task automatic clear_word_vec(output word_vec_t words);
      integer w;
      begin
        for (w = 0; w < MAX_WORDS; w = w + 1) begin
          words[w] = '0;
        end
      end
    endtask

    task automatic init_matrix_zero(output matrix_t mat);
      integer r;
      integer c;
      begin
        for (r = 0; r < MAX_DIM; r = r + 1) begin
          for (c = 0; c < MAX_DIM; c = c + 1) begin
            mat[r][c] = FP16_ZERO;
          end
        end
      end
    endtask

    task automatic init_vector_zero(output vector_t vec);
      integer i;
      begin
        for (i = 0; i < MAX_REDUCE_ELEMS; i = i + 1) begin
          vec[i] = FP16_ZERO;
        end
      end
    endtask

    task automatic fill_pattern_matrix(
      output matrix_t mat,
      input integer rows,
      input integer cols,
      input integer seed,
      input bit use_abs_pattern
    );
      integer r;
      integer c;
      begin
        init_matrix_zero(mat);
        for (r = 0; r < rows; r = r + 1) begin
          for (c = 0; c < cols; c = c + 1) begin
            if (use_abs_pattern) begin
              mat[r][c] = pick_abs_fp(seed + (r * cols) + c);
            end else begin
              mat[r][c] = pick_pos_fp(seed + (r * cols) + c);
            end
          end
        end
      end
    endtask

    task automatic pack_matrix_words(
      input integer rows,
      input integer cols,
      input matrix_t mat,
      output word_vec_t words,
      output integer word_count
    );
      integer total_elems;
      integer w;
      integer lane;
      integer idx;
      integer r;
      integer c;
      logic [SRAM_W-1:0] wr_word;
      begin
        clear_word_vec(words);
        total_elems = rows * cols;
        word_count = ceil_div(total_elems, FP16_PER_WORD);
        for (w = 0; w < word_count; w = w + 1) begin
          wr_word = '0;
          for (lane = 0; lane < FP16_PER_WORD; lane = lane + 1) begin
            idx = (w * FP16_PER_WORD) + lane;
            if (idx < total_elems) begin
              r = idx / cols;
              c = idx % cols;
              wr_word[lane * FPW +: FPW] = mat[r][c];
            end else begin
              wr_word[lane * FPW +: FPW] = FP16_ZERO;
            end
          end
          words[w] = wr_word;
        end
      end
    endtask

    task automatic pack_vector_words(
      input integer len,
      input vector_t vec,
      output word_vec_t words,
      output integer word_count
    );
      integer w;
      integer lane;
      integer idx;
      logic [SRAM_W-1:0] wr_word;
      begin
        clear_word_vec(words);
        word_count = ceil_div(len, FP16_PER_WORD);
        for (w = 0; w < word_count; w = w + 1) begin
          wr_word = '0;
          for (lane = 0; lane < FP16_PER_WORD; lane = lane + 1) begin
            idx = (w * FP16_PER_WORD) + lane;
            if (idx < len) begin
              wr_word[lane * FPW +: FPW] = vec[idx];
            end else begin
              wr_word[lane * FPW +: FPW] = FP16_ZERO;
            end
          end
          words[w] = wr_word;
        end
      end
    endtask

    task automatic reserve_base(
      input integer mem_id,
      input integer words,
      output integer base
    );
      integer delta;
      begin
        delta = (words <= 0) ? 1 : words;
        case (mem_id)
          SRAM_GLOBAL: begin
            base = next_base_global;
            next_base_global = next_base_global + delta + 1;
            if (next_base_global >= GLOBAL_DEPTH) $fatal(1, "Global SRAM overflow");
          end
          SRAM_LOCAL0: begin
            base = next_base_local;
            next_base_local = next_base_local + delta + 1;
            if (next_base_local >= LOCAL_DEPTH) $fatal(1, "Local SRAM overflow");
          end
          SRAM_TEMP0: begin
            base = next_base_temp;
            next_base_temp = next_base_temp + delta + 1;
            if (next_base_temp >= TEMP_DEPTH) $fatal(1, "Temp SRAM overflow");
          end
          default: $fatal(1, "Unknown SRAM id %0d", mem_id);
        endcase
      end
    endtask

    task automatic init_case_defaults(input integer cid);
      begin
        clear_word_vec(pre_src_words[cid]);
        clear_word_vec(pre_aux_words[cid]);
        clear_word_vec(pre_dst_words[cid]);
        clear_word_vec(post_dst_words[cid]);
        got_reduce_value[cid] = FP16_ZERO;
        got_reduce_index[cid] = 12'h000;
        reduce_result_seen[cid] = 1'b0;
        done_seen[cid] = 1'b0;
        case_alpha[cid] = FP16_ZERO;
        case_rows[cid] = 0;
        case_cols[cid] = 0;
        case_kdim[cid] = 0;
        case_dst_rows[cid] = 0;
        case_dst_cols[cid] = 0;
        case_len[cid] = 0;
        case_off_r[cid] = 0;
        case_off_c[cid] = 0;
        case_src_mem[cid] = SRAM_GLOBAL;
        case_aux_mem[cid] = SRAM_GLOBAL;
        case_dst_mem[cid] = SRAM_GLOBAL;
        case_src_base[cid] = 0;
        case_aux_base[cid] = 0;
        case_dst_base[cid] = 0;
        case_src_elems[cid] = 0;
        case_aux_elems[cid] = 0;
        case_dst_elems[cid] = 0;
        case_src_words[cid] = 0;
        case_aux_words[cid] = 0;
        case_dst_words[cid] = 0;
        case_cmd[cid] = '0;
      end
    endtask

    task automatic add_abs_case(
      input integer src_mem,
      input integer dst_mem,
      input integer rows,
      input integer cols,
      input integer seed
    );
      integer cid;
      integer word_count;
      matrix_t src_mat;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(src_mat);

        case_kind[cid] = KIND_ABS;
        case_opcode[cid] = OP_ABS;
        case_subop[cid] = SUB_ABS;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_dst_mem[cid] = dst_mem;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_dst_rows[cid] = rows;
        case_dst_cols[cid] = cols;
        case_src_elems[cid] = rows * cols;
        case_dst_elems[cid] = rows * cols;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "ABS case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(dst_mem, case_dst_words[cid], case_dst_base[cid]);

        fill_pattern_matrix(src_mat, rows, cols, seed, 1'b1);

        pack_matrix_words(rows, cols, src_mat, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "ABS src word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_ABS,
          SUB_ABS,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          13'h0000,
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          12'h000
        );
      end
    endtask

    task automatic add_layout_transpose_case(
      input integer src_mem,
      input integer dst_mem,
      input integer rows,
      input integer cols,
      input integer seed
    );
      integer cid;
      integer word_count;
      matrix_t src_mat;
      matrix_t dst_init_mat;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(src_mat);
        init_matrix_zero(dst_init_mat);

        case_kind[cid] = KIND_LAYOUT_TRANSPOSE;
        case_opcode[cid] = OP_DATALAYOUT;
        case_subop[cid] = SUB_TRANSPOSE;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_dst_mem[cid] = dst_mem;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_dst_rows[cid] = cols;
        case_dst_cols[cid] = rows;
        case_src_elems[cid] = rows * cols;
        case_dst_elems[cid] = cols * rows;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "TRANSPOSE case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(dst_mem, case_dst_words[cid], case_dst_base[cid]);

        fill_pattern_matrix(src_mat, rows, cols, seed, 1'b0);
        fill_pattern_matrix(dst_init_mat, cols, rows, seed + 77, 1'b0);

        pack_matrix_words(rows, cols, src_mat, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "TRANSPOSE src word_count mismatch");
        pack_matrix_words(case_dst_rows[cid], case_dst_cols[cid], dst_init_mat, pre_dst_words[cid], word_count);
        if (word_count != case_dst_words[cid]) $fatal(1, "TRANSPOSE pre dst word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_DATALAYOUT,
          SUB_TRANSPOSE,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          13'h0000,
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          12'h000
        );
      end
    endtask

    task automatic add_layout_assemble_case(
      input integer src_mem,
      input integer dst_mem,
      input integer src_rows,
      input integer src_cols,
      input integer off_r,
      input integer off_c,
      input integer seed
    );
      integer cid;
      integer word_count;
      matrix_t src_mat;
      matrix_t dst_init_mat;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(src_mat);
        init_matrix_zero(dst_init_mat);

        case_kind[cid] = KIND_LAYOUT_ASSEMBLE;
        case_opcode[cid] = OP_DATALAYOUT;
        case_subop[cid] = SUB_ASSEMBLE;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_dst_mem[cid] = dst_mem;
        case_rows[cid] = src_rows;
        case_cols[cid] = src_cols;
        case_off_r[cid] = off_r;
        case_off_c[cid] = off_c;
        case_dst_rows[cid] = src_rows + off_r;
        case_dst_cols[cid] = src_cols + off_c;
        case_src_elems[cid] = src_rows * src_cols;
        case_dst_elems[cid] = case_dst_rows[cid] * case_dst_cols[cid];
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "ASSEMBLE case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(dst_mem, case_dst_words[cid], case_dst_base[cid]);

        fill_pattern_matrix(src_mat, src_rows, src_cols, seed, 1'b0);
        fill_pattern_matrix(dst_init_mat, case_dst_rows[cid], case_dst_cols[cid], seed + 131, 1'b0);

        pack_matrix_words(src_rows, src_cols, src_mat, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "ASSEMBLE src word_count mismatch");
        pack_matrix_words(case_dst_rows[cid], case_dst_cols[cid], dst_init_mat, pre_dst_words[cid], word_count);
        if (word_count != case_dst_words[cid]) $fatal(1, "ASSEMBLE pre dst word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_DATALAYOUT,
          SUB_ASSEMBLE,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          {2'b00, case_off_c[cid][10:0]},
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          case_off_r[cid][11:0]
        );
      end
    endtask

    task automatic add_reduce_add_case(
      input integer src_mem,
      input integer len
    );
      integer cid;
      integer word_count;
      vector_t vec;
      integer i;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_vector_zero(vec);

        case_kind[cid] = KIND_REDUCE_ADD;
        case_opcode[cid] = OP_REDUCE;
        case_subop[cid] = SUB_ADD_TREE;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_len[cid] = len;
        case_src_elems[cid] = len;
        case_src_words[cid] = ceil_div(len, FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS) $fatal(1, "REDUCE_ADD case %0d exceeds MAX_WORDS", cid);
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);

        for (i = 0; i < len; i = i + 1) begin
          vec[i] = FP16_ONE;
        end
        pack_vector_words(len, vec, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "REDUCE_ADD word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_REDUCE,
          SUB_ADD_TREE,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          13'h0000,
          13'h0000,
          case_len[cid][11:0],
          12'h000,
          12'h000
        );
      end
    endtask

    task automatic add_reduce_cmp_case(
      input integer src_mem,
      input integer len,
      input integer min_idx,
      input integer seed
    );
      integer cid;
      integer word_count;
      vector_t vec;
      integer i;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        if (len > MAX_REDUCE_ELEMS) $fatal(1, "REDUCE_CMP len too large");
        if (min_idx < 0 || min_idx >= len) $fatal(1, "REDUCE_CMP min_idx out of range");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_vector_zero(vec);

        case_kind[cid] = KIND_REDUCE_CMP;
        case_opcode[cid] = OP_REDUCE;
        case_subop[cid] = SUB_CMP_REDUCE;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_len[cid] = len;
        case_src_elems[cid] = len;
        case_src_words[cid] = ceil_div(len, FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS) $fatal(1, "REDUCE_CMP case %0d exceeds MAX_WORDS", cid);
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);

        for (i = 0; i < len; i = i + 1) begin
          vec[i] = pick_pos_fp(seed + i + 2);
          if (vec[i] == FP16_HALF) vec[i] = FP16_THREE;
        end
        vec[min_idx] = FP16_HALF;
        pack_vector_words(len, vec, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "REDUCE_CMP word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_REDUCE,
          SUB_CMP_REDUCE,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          13'h0000,
          13'h0000,
          case_len[cid][11:0],
          12'h000,
          12'h000
        );
      end
    endtask

    task automatic add_gemm_identity_case(
      input integer a_mem,
      input integer b_mem,
      input integer c_mem,
      input integer n_rows,
      input integer m_cols,
      input integer seed
    );
      integer cid;
      integer word_count;
      integer k_dim;
      matrix_t mat_a;
      matrix_t mat_b;
      integer r;
      integer c;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(mat_a);
        init_matrix_zero(mat_b);

        k_dim = n_rows;
        case_kind[cid] = KIND_GEMM;
        case_opcode[cid] = OP_LA;
        case_subop[cid] = SUB_GEMM;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = a_mem;
        case_aux_mem[cid] = b_mem;
        case_dst_mem[cid] = c_mem;
        case_rows[cid] = n_rows;
        case_cols[cid] = m_cols;
        case_kdim[cid] = k_dim;
        case_dst_rows[cid] = n_rows;
        case_dst_cols[cid] = m_cols;
        case_src_elems[cid] = n_rows * k_dim;
        case_aux_elems[cid] = k_dim * m_cols;
        case_dst_elems[cid] = n_rows * m_cols;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_aux_words[cid] = ceil_div(case_aux_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_aux_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "GEMM case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(a_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(b_mem, case_aux_words[cid], case_aux_base[cid]);
        reserve_base(c_mem, case_dst_words[cid], case_dst_base[cid]);

        for (r = 0; r < n_rows; r = r + 1) begin
          for (c = 0; c < k_dim; c = c + 1) begin
            mat_a[r][c] = (r == c) ? FP16_ONE : FP16_ZERO;
          end
        end
        fill_pattern_matrix(mat_b, k_dim, m_cols, seed, 1'b0);

        pack_matrix_words(n_rows, k_dim, mat_a, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "GEMM A word_count mismatch");
        pack_matrix_words(k_dim, m_cols, mat_b, pre_aux_words[cid], word_count);
        if (word_count != case_aux_words[cid]) $fatal(1, "GEMM B word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_LA,
          SUB_GEMM,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_aux_mem[cid], case_aux_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          case_cols[cid][11:0],
          case_rows[cid][11:0],
          case_kdim[cid][11:0]
        );
      end
    endtask

    task automatic add_mul_copy_case(
      input integer a_mem,
      input integer c_mem,
      input integer rows,
      input integer cols,
      input integer seed
    );
      integer cid;
      integer word_count;
      matrix_t mat_a;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(mat_a);

        case_kind[cid] = KIND_MUL;
        case_opcode[cid] = OP_LA;
        case_subop[cid] = SUB_MUL;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = a_mem;
        case_dst_mem[cid] = c_mem;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_dst_rows[cid] = rows;
        case_dst_cols[cid] = cols;
        case_alpha[cid] = FP16_ONE;
        case_src_elems[cid] = rows * cols;
        case_dst_elems[cid] = rows * cols;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "MUL case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(a_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(c_mem, case_dst_words[cid], case_dst_base[cid]);

        fill_pattern_matrix(mat_a, rows, cols, seed, 1'b0);
        pack_matrix_words(rows, cols, mat_a, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "MUL src word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_LA,
          SUB_MUL,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          case_alpha[cid][12:0],
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          {9'b0, case_alpha[cid][15:13]}
        );
      end
    endtask

    task automatic add_add_zero_case(
      input integer a_mem,
      input integer b_mem,
      input integer c_mem,
      input integer rows,
      input integer cols,
      input integer seed
    );
      integer cid;
      integer word_count;
      matrix_t mat_a;
      matrix_t mat_b;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);
        init_matrix_zero(mat_a);
        init_matrix_zero(mat_b);

        case_kind[cid] = KIND_ADD;
        case_opcode[cid] = OP_LA;
        case_subop[cid] = SUB_ADD;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = a_mem;
        case_aux_mem[cid] = b_mem;
        case_dst_mem[cid] = c_mem;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_dst_rows[cid] = rows;
        case_dst_cols[cid] = cols;
        case_src_elems[cid] = rows * cols;
        case_aux_elems[cid] = rows * cols;
        case_dst_elems[cid] = rows * cols;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_aux_words[cid] = ceil_div(case_aux_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_aux_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "ADD case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(a_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(b_mem, case_aux_words[cid], case_aux_base[cid]);
        reserve_base(c_mem, case_dst_words[cid], case_dst_base[cid]);

        fill_pattern_matrix(mat_a, rows, cols, seed, 1'b0);
        pack_matrix_words(rows, cols, mat_a, pre_src_words[cid], word_count);
        if (word_count != case_src_words[cid]) $fatal(1, "ADD A word_count mismatch");
        pack_matrix_words(rows, cols, mat_b, pre_aux_words[cid], word_count);
        if (word_count != case_aux_words[cid]) $fatal(1, "ADD B word_count mismatch");

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_LA,
          SUB_ADD,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_aux_mem[cid], case_aux_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          12'h000
        );
      end
    endtask

    task automatic add_lut_case(
      input integer src_mem,
      input integer dst_mem,
      input integer rows,
      input integer cols,
      input logic [3:0] lut_subop
    );
      integer cid;
      integer idx;
      integer word_idx;
      integer lane;
      logic [15:0] val;
      begin
        if (num_cases >= MAX_CASES) $fatal(1, "MAX_CASES overflow");
        cid = num_cases;
        num_cases = num_cases + 1;
        init_case_defaults(cid);

        case_kind[cid] = KIND_LUT;
        case_opcode[cid] = OP_LUT;
        case_subop[cid] = lut_subop;
        case_cmd_id[cid] = cid[11:0];
        case_src_mem[cid] = src_mem;
        case_dst_mem[cid] = dst_mem;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_dst_rows[cid] = rows;
        case_dst_cols[cid] = cols;
        case_src_elems[cid] = rows * cols;
        case_dst_elems[cid] = rows * cols;
        case_src_words[cid] = ceil_div(case_src_elems[cid], FP16_PER_WORD);
        case_dst_words[cid] = ceil_div(case_dst_elems[cid], FP16_PER_WORD);
        if (case_src_words[cid] > MAX_WORDS || case_dst_words[cid] > MAX_WORDS) begin
          $fatal(1, "LUT case %0d exceeds MAX_WORDS", cid);
        end
        reserve_base(src_mem, case_src_words[cid], case_src_base[cid]);
        reserve_base(dst_mem, case_dst_words[cid], case_dst_base[cid]);

        for (idx = 0; idx < case_src_elems[cid]; idx = idx + 1) begin
          if (lut_subop == SUB_SOFTPLUS) begin
            val = rand_fp16();
          end else begin
            val = rand_fp16_trig_range();
          end
          word_idx = idx / FP16_PER_WORD;
          lane = idx % FP16_PER_WORD;
          pre_src_words[cid][word_idx][lane * FPW +: FPW] = val;
        end

        case_cmd[cid] = make_cmd(
          case_cmd_id[cid],
          OP_LUT,
          lut_subop,
          1'b0,
          pack_addr(case_src_mem[cid], case_src_base[cid][ADDR_W-1:0]),
          pack_addr(case_dst_mem[cid], case_dst_base[cid][ADDR_W-1:0]),
          13'h0000,
          case_rows[cid][11:0],
          case_cols[cid][11:0],
          12'h000
        );
      end
    endtask

    task automatic build_cases;
      begin
        num_cases = 0;
        next_base_global = 0;
        next_base_local = 0;
        next_base_temp = 0;

        add_gemm_identity_case(SRAM_GLOBAL, SRAM_LOCAL0, SRAM_TEMP0, 16, 16, 1000);
        add_abs_case(SRAM_GLOBAL, SRAM_LOCAL0, 3, 5, 1100);
        add_reduce_add_case(SRAM_TEMP0, 8);
        add_layout_transpose_case(SRAM_LOCAL0, SRAM_GLOBAL, 3, 4, 1200);
        add_mul_copy_case(SRAM_GLOBAL, SRAM_TEMP0, 3, 6, 1300);
        add_reduce_cmp_case(SRAM_LOCAL0, 7, 3, 1400);
        add_layout_assemble_case(SRAM_TEMP0, SRAM_GLOBAL, 2, 3, 1, 2, 1500);
        add_add_zero_case(SRAM_GLOBAL, SRAM_LOCAL0, SRAM_TEMP0, 4, 4, 1600);
        add_abs_case(SRAM_TEMP0, SRAM_GLOBAL, 2, 7, 1700);
        add_reduce_add_case(SRAM_GLOBAL, 4);
        add_gemm_identity_case(SRAM_LOCAL0, SRAM_TEMP0, SRAM_GLOBAL, 8, 6, 1800);
        add_layout_transpose_case(SRAM_GLOBAL, SRAM_TEMP0, 2, 6, 1900);
        add_abs_case(SRAM_LOCAL0, SRAM_TEMP0, 4, 3, 2000);
        add_reduce_cmp_case(SRAM_GLOBAL, 8, 5, 2100);
        add_mul_copy_case(SRAM_TEMP0, SRAM_LOCAL0, 5, 3, 2200);
        add_layout_assemble_case(SRAM_GLOBAL, SRAM_LOCAL0, 3, 2, 2, 1, 2300);
        add_abs_case(SRAM_GLOBAL, SRAM_GLOBAL, 1, 8, 2400);
        add_add_zero_case(SRAM_LOCAL0, SRAM_TEMP0, SRAM_GLOBAL, 3, 5, 2500);
        add_reduce_add_case(SRAM_LOCAL0, 16);
        add_layout_transpose_case(SRAM_TEMP0, SRAM_LOCAL0, 4, 2, 2600);
        add_gemm_identity_case(SRAM_GLOBAL, SRAM_TEMP0, SRAM_LOCAL0, 4, 7, 2700);
        add_reduce_cmp_case(SRAM_TEMP0, 5, 1, 2800);
        add_abs_case(SRAM_TEMP0, SRAM_LOCAL0, 5, 2, 2900);
        add_layout_assemble_case(SRAM_LOCAL0, SRAM_TEMP0, 2, 4, 1, 1, 3000);
        add_mul_copy_case(SRAM_LOCAL0, SRAM_GLOBAL, 2, 8, 3100);
        add_reduce_add_case(SRAM_TEMP0, 8);
        add_add_zero_case(SRAM_GLOBAL, SRAM_TEMP0, SRAM_LOCAL0, 2, 6, 3200);
        add_layout_transpose_case(SRAM_LOCAL0, SRAM_GLOBAL, 3, 3, 3300);
        add_abs_case(SRAM_GLOBAL, SRAM_TEMP0, 6, 2, 3400);
        add_reduce_cmp_case(SRAM_LOCAL0, 9, 7, 3500);
        add_layout_assemble_case(SRAM_TEMP0, SRAM_GLOBAL, 3, 3, 1, 3, 3600);
        add_abs_case(SRAM_LOCAL0, SRAM_GLOBAL, 2, 5, 3700);
        add_add_zero_case(SRAM_TEMP0, SRAM_GLOBAL, SRAM_LOCAL0, 4, 3, 3800);
        add_reduce_cmp_case(SRAM_GLOBAL, 6, 2, 3900);
        add_lut_case(SRAM_GLOBAL, SRAM_LOCAL0, 1, 1, SUB_SIN);
        add_lut_case(SRAM_LOCAL0, SRAM_TEMP0, 2, 3, SUB_COS);
        add_lut_case(SRAM_TEMP0, SRAM_GLOBAL, 4, 2, SUB_SOFTPLUS);
        add_lut_case(SRAM_GLOBAL, SRAM_TEMP0, 3, 2, SUB_SIN);
        add_lut_case(SRAM_TEMP0, SRAM_LOCAL0, 1, 4, SUB_COS);
        add_lut_case(SRAM_LOCAL0, SRAM_GLOBAL, 5, 2, SUB_SOFTPLUS);

        if (num_cases < BURST_FILL_CMDS) begin
          $fatal(1, "Need at least %0d commands to validate FIFO full, only built %0d", BURST_FILL_CMDS, num_cases);
        end
        case_cmd[num_cases - 1][76] = 1'b1;
      end
    endtask

task automatic d2d_mem_write_word(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        input logic [SRAM_W-1:0] data
    );
    begin
        if (mem_id == SRAM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (mem_id == SRAM_LOCAL0 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
        if (mem_id == SRAM_TEMP0 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
        d2d_write_128(core_sram_addr(mem_id, addr), data);
    end
    endtask

    task automatic d2d_mem_read_word(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        output logic [SRAM_W-1:0] data
    );
    begin
        if (mem_id == SRAM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
        if (mem_id == SRAM_LOCAL0 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
        if (mem_id == SRAM_TEMP0 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
        d2d_read_128(core_sram_addr(mem_id, addr), data);
    end
    endtask

    function automatic bit has_unknown(input logic [31:0] value);
    begin
        has_unknown = (^value === 1'bx);
    end
    endfunction

    function automatic logic [95:0] cmd_with_group_end(
        input logic [95:0] cmd,
        input logic group_end
    );
    begin
        cmd_with_group_end = cmd;
        cmd_with_group_end[76] = group_end;
    end
    endfunction

    task automatic ext_mem_write_word(
        input integer mem_id,
        input integer addr,
        input logic [SRAM_W-1:0] data
    );
    begin
        if ((mem_id < 0) || (mem_id > MEM_SOFT_ODD)) begin
            $fatal(1, "Unsupported external mem id %0d", mem_id);
        end
        if (addr >= mpc_sram_depth(mem_id)) begin
            $fatal(1, "External SRAM addr overflow: mem=%0d addr=%0d depth=%0d",
                   mem_id, addr, mpc_sram_depth(mem_id));
        end
        d2d_write_128(mpc_sram_addr(mem_id[3:0], addr), data);
    end
    endtask

    task automatic mem_write_word(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        input logic [SRAM_W-1:0] data
    );
    begin
        d2d_mem_write_word(mem_id, addr, data);
    end
    endtask

    task automatic mem_read_word_1cycle(
        input integer mem_id,
        input logic [ADDR_W-1:0] addr,
        output logic [SRAM_W-1:0] data
    );
    begin
        d2d_mem_read_word(mem_id, addr, data);
    end
    endtask

    task automatic preload_cases_to_sram;
        integer cid;
        integer w;
    begin
        for (cid = 0; cid < num_cases; cid = cid + 1) begin
            for (w = 0; w < case_dst_words[cid]; w = w + 1) begin
                mem_write_word(case_dst_mem[cid], case_dst_base[cid] + w, pre_dst_words[cid][w]);
            end
            for (w = 0; w < case_src_words[cid]; w = w + 1) begin
                mem_write_word(case_src_mem[cid], case_src_base[cid] + w, pre_src_words[cid][w]);
            end
            for (w = 0; w < case_aux_words[cid]; w = w + 1) begin
                mem_write_word(case_aux_mem[cid], case_aux_base[cid] + w, pre_aux_words[cid][w]);
            end
        end
    end
    endtask

    task automatic wait_fifo_space;
        logic [31:0] cmd_status_reg;
    begin
        d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        while (cmd_status_reg[0] === 1'b1) begin
            @(posedge clock);
            d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        end
    end
    endtask

    task automatic push_cmd_raw(input logic [95:0] cmd);
    begin
        d2d_cfg_write(CFG_CMDWORD_0_0, cmd[31:0]);
        d2d_cfg_write(CFG_CMDWORD_0_1, cmd[63:32]);
        d2d_cfg_write(CFG_CMDWORD_0_2, cmd[95:64]);
        d2d_cfg_write(CFG_CMDCTRL_0, 32'h1);
        d2d_cfg_write(CFG_CMDCTRL_0, 32'h0);
    end
    endtask

    task automatic push_cmd_checked(input logic [95:0] cmd);
    begin
        wait_fifo_space();
        push_cmd_raw(cmd);
    end
    endtask

    task automatic build_issue_order;
        integer cid;
    begin
        num_reduce_cases = 0;
        num_non_reduce_cases = 0;
        for (cid = 0; cid < num_cases; cid = cid + 1) begin
            if ((case_kind[cid] == KIND_REDUCE_ADD) || (case_kind[cid] == KIND_REDUCE_CMP)) begin
                reduce_case_ids[num_reduce_cases] = cid;
                issue_order[num_reduce_cases] = cid;
                num_reduce_cases = num_reduce_cases + 1;
            end else begin
                non_reduce_case_ids[num_non_reduce_cases] = cid;
                num_non_reduce_cases = num_non_reduce_cases + 1;
            end
        end
        for (cid = 0; cid < num_non_reduce_cases; cid = cid + 1) begin
            issue_order[num_reduce_cases + cid] = non_reduce_case_ids[cid];
        end
        if ((num_reduce_cases + num_non_reduce_cases) != num_cases) begin
            $fatal(1, "Issue-order bookkeeping mismatch: reduce=%0d non_reduce=%0d total=%0d",
                   num_reduce_cases, num_non_reduce_cases, num_cases);
        end
    end
    endtask

    task automatic push_issue_cmd_raw(input integer issue_idx);
        integer cid;
        logic [95:0] cmd;
    begin
        if ((issue_idx < 0) || (issue_idx >= num_cases)) begin
            $fatal(1, "issue_idx out of range: %0d", issue_idx);
        end
        cid = issue_order[issue_idx];
        cmd = cmd_with_group_end(case_cmd[cid], (issue_idx == (num_cases - 1)));
        push_cmd_raw(cmd);
        issued_cmd_count = issue_idx + 1;
    end
    endtask

    task automatic push_issue_cmd_checked(input integer issue_idx);
        integer cid;
        logic [95:0] cmd;
    begin
        if ((issue_idx < 0) || (issue_idx >= num_cases)) begin
            $fatal(1, "issue_idx out of range: %0d", issue_idx);
        end
        cid = issue_order[issue_idx];
        cmd = cmd_with_group_end(case_cmd[cid], (issue_idx == (num_cases - 1)));
        push_cmd_checked(cmd);
        issued_cmd_count = issue_idx + 1;
    end
    endtask

    task automatic push_issue_burst(
        input integer start_issue_idx,
        input integer burst_count
    );
        integer issue_idx;
    begin
        for (issue_idx = start_issue_idx;
             issue_idx < (start_issue_idx + burst_count);
             issue_idx = issue_idx + 1) begin
            push_issue_cmd_raw(issue_idx);
        end
    end
    endtask

    task automatic wait_for_fifo_full_observation;
        integer poll_cycles;
        logic [31:0] cmd_status_reg;
    begin
        saw_fifo_full = 1'b0;
        max_fifo_count = 0;
        poll_cycles = 0;
        while (!saw_fifo_full && (poll_cycles < 400)) begin
            d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
            if (cmd_status_reg[15:8] > max_fifo_count) begin
                max_fifo_count = cmd_status_reg[15:8];
            end
            if ((cmd_status_reg[0] === 1'b1) || (cmd_status_reg[15:8] >= FIFO_DEPTH)) begin
                saw_fifo_full = 1'b1;
            end
            if (!saw_fifo_full) begin
                @(posedge clock);
                poll_cycles = poll_cycles + 1;
            end
        end
        if (!saw_fifo_full) begin
            $fatal(1, "FIFO full was never observed, max fifo count=%0d", max_fifo_count);
        end
    end
    endtask

    task automatic load_trig_lut_tables;
        integer idx;
        logic [SRAM_W-1:0] word;
    begin
        for (idx = 0; idx < TRIG_TOTAL_WORDS; idx = idx + 1) begin
            word = '0;
            word[15:0] = trig_mem[idx];
            if (idx < TRIG_BANK_DEPTH) begin
                ext_mem_write_word(MEM_TRIG_SIN_EVEN, idx, word);
            end else if (idx < (2 * TRIG_BANK_DEPTH)) begin
                ext_mem_write_word(MEM_TRIG_SIN_ODD, idx - TRIG_BANK_DEPTH, word);
            end else if (idx < (3 * TRIG_BANK_DEPTH)) begin
                ext_mem_write_word(MEM_TRIG_COS_EVEN, idx - (2 * TRIG_BANK_DEPTH), word);
            end else begin
                ext_mem_write_word(MEM_TRIG_COS_ODD, idx - (3 * TRIG_BANK_DEPTH), word);
            end
        end
    end
    endtask

    task automatic load_softplus_lut_tables;
        integer idx;
        logic [SRAM_W-1:0] word;
    begin
        for (idx = 0; idx < SOFTPLUS_TOTAL_WORDS; idx = idx + 1) begin
            word = '0;
            word[31:0] = soft_mem[idx];
            if (idx < SOFTPLUS_BANK_DEPTH) begin
                ext_mem_write_word(MEM_SOFT_EVEN, idx, word);
            end else begin
                ext_mem_write_word(MEM_SOFT_ODD, idx - SOFTPLUS_BANK_DEPTH, word);
            end
        end
    end
    endtask

    task automatic load_lut_tables;
    begin
        load_trig_lut_tables();
        load_softplus_lut_tables();
    end
    endtask

    task automatic wait_for_reduce_case_completion(
        input integer cid,
        input integer issue_idx,
        input integer start_pulse_count
    );
        integer cycles;
        integer settle_cycles;
        integer expected_done_count;
        logic [31:0] cmd_status_reg;
        logic [31:0] done_count_reg;
        logic [31:0] last_done_reg;
        logic [31:0] engine_status_reg;
        logic [31:0] add_reduce_reg;
        logic [31:0] cmp_reduce_reg0;
        logic [31:0] cmp_reduce_reg1;
        logic [11:0] done_cmd_id;
        logic [2:0] done_opcode;
        logic [3:0] done_subop;
        logic done_group_end;
        logic done_illegal;
        logic [15:0] cmp_val;
        logic [11:0] cmp_cmd;
        logic cmp_valid;
        logic [11:0] cmp_idx;
        logic [15:0] add_val;
        logic [11:0] add_cmd;
        logic add_valid;
    begin
        cycles = 0;
        while ((pad_done_pulse_count < (start_pulse_count + 1)) && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge clock);
            cycles = cycles + 1;
        end
        if (pad_done_pulse_count < (start_pulse_count + 1)) begin
            $fatal(1, "timeout waiting for pad_dexmpc_complete on reduce case %0d", cid);
        end

        expected_done_count = observed_done_count + 1;
        d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        settle_cycles = 0;
        while ((done_count_reg != expected_done_count) && (settle_cycles < 10000)) begin
            @(posedge clock);
            settle_cycles = settle_cycles + 1;
            d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        end
        if (done_count_reg != expected_done_count) begin
            $fatal(1, "doneCount_0 mismatch on reduce case %0d: expected %0d got %0d",
                   cid, expected_done_count, done_count_reg);
        end

        d2d_cfg_read(CFG_LASTDONE_0, last_done_reg);
        done_cmd_id = last_done_reg[11:0];
        done_opcode = last_done_reg[14:12];
        done_subop = last_done_reg[18:15];
        done_group_end = last_done_reg[19];
        done_illegal = last_done_reg[20];

        if (done_illegal) begin
            $fatal(1, "illegal command reported in lastDone_0=%h for reduce case %0d", last_done_reg, cid);
        end
        if (done_cmd_id !== case_cmd_id[cid]) begin
            $fatal(1, "doneCmdId mismatch for reduce case %0d: got %0d expected %0d",
                   cid, done_cmd_id, case_cmd_id[cid]);
        end
        if (done_opcode !== OP_REDUCE) begin
            $fatal(1, "done opcode mismatch for reduce case %0d: opcode=%0b", cid, done_opcode);
        end
        if ((case_kind[cid] == KIND_REDUCE_CMP) && (done_subop !== SUB_CMP_REDUCE)) begin
            $fatal(1, "done subop mismatch for reduce cmp case %0d", cid);
        end
        if ((case_kind[cid] == KIND_REDUCE_ADD) && (done_subop !== SUB_ADD_TREE)) begin
            $fatal(1, "done subop mismatch for reduce add case %0d", cid);
        end
        if (done_group_end !== (issue_idx == (num_cases - 1))) begin
            $fatal(1, "done group_end mismatch for reduce case %0d", cid);
        end
        if (reduce_result_seen[cid]) begin
            $fatal(1, "duplicate reduce result for case %0d", cid);
        end

        if (case_kind[cid] == KIND_REDUCE_CMP) begin
            d2d_cfg_read(CFG_CMP_REDUCE_REG0_0, cmp_reduce_reg0);
            d2d_cfg_read(CFG_CMP_REDUCE_REG1_0, cmp_reduce_reg1);
            cmp_val = cmp_reduce_reg0[15:0];
            cmp_cmd = cmp_reduce_reg0[27:16];
            cmp_valid = cmp_reduce_reg0[28];
            cmp_idx = cmp_reduce_reg1[11:0];
            if (!cmp_valid) begin
                $fatal(1, "cmpReduce valid not set for case %0d", cid);
            end
            if (cmp_cmd !== case_cmd_id[cid]) begin
                $fatal(1, "cmpReduce cmdId mismatch for case %0d", cid);
            end
            if (has_unknown({16'b0, cmp_val}) || has_unknown({20'b0, cmp_idx})) begin
                $fatal(1, "cmpReduce result contains X/Z for case %0d", cid);
            end
            got_reduce_value[cid] = cmp_val;
            got_reduce_index[cid] = cmp_idx;
        end else begin
            d2d_cfg_read(CFG_ADD_REDUCE_REG_0, add_reduce_reg);
            add_val = add_reduce_reg[15:0];
            add_cmd = add_reduce_reg[27:16];
            add_valid = add_reduce_reg[28];
            if (!add_valid) begin
                $fatal(1, "addReduce valid not set for case %0d", cid);
            end
            if (add_cmd !== case_cmd_id[cid]) begin
                $fatal(1, "addReduce cmdId mismatch for case %0d", cid);
            end
            if (has_unknown({16'b0, add_val})) begin
                $fatal(1, "addReduce result contains X/Z for case %0d", cid);
            end
            got_reduce_value[cid] = add_val;
            got_reduce_index[cid] = 12'h000;
        end

        d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        settle_cycles = 0;
        while (((cmd_status_reg[1] !== 1'b1) ||
                (cmd_status_reg[2] !== 1'b0) ||
                (cmd_status_reg[3] !== 1'b1) ||
                (cmd_status_reg[5] !== 1'b0)) &&
               (settle_cycles < 10000)) begin
            @(posedge clock);
            settle_cycles = settle_cycles + 1;
            d2d_cfg_read(CFG_CMDSTATUS_0, cmd_status_reg);
        end
        if (cmd_status_reg[1] !== 1'b1) begin
            $fatal(1, "cmd sequencer empty bit is not set after reduce case %0d, cmdStatus_0=%h", cid, cmd_status_reg);
        end
        if (cmd_status_reg[2] !== 1'b0) begin
            $fatal(1, "cmd sequencer busy bit is still set after reduce case %0d, cmdStatus_0=%h", cid, cmd_status_reg);
        end
        if (cmd_status_reg[3] !== 1'b1) begin
            $fatal(1, "cmd sequencer idle bit is not set after reduce case %0d, cmdStatus_0=%h", cid, cmd_status_reg);
        end
        if (cmd_status_reg[5] !== 1'b0) begin
            $fatal(1, "cmd sequencer overflow bit is set after reduce case %0d, cmdStatus_0=%h", cid, cmd_status_reg);
        end

        d2d_cfg_read(CFG_ENGINE_STATUS, engine_status_reg);
        if (engine_status_reg[1] !== 1'b0) begin
            $fatal(1, "reduce engine still busy after case %0d, engineStatus=%h", cid, engine_status_reg);
        end

        reduce_result_seen[cid] = 1'b1;
        done_seen[cid] = 1'b1;
        observed_done_count = expected_done_count;
        issued_cmd_count = expected_done_count;
        last_done_count = done_count_reg;
        done_count = expected_done_count;
        expected_done = expected_done_count;
    end
    endtask

    task automatic wait_for_remaining_completions(input integer target_done_count);
        integer cycles;
        integer settle_cycles;
        integer issue_idx;
        integer last_cid;
        logic [31:0] cmd_status_reg;
        logic [31:0] done_count_reg;
        logic [31:0] last_done_reg;
        logic [31:0] engine_status_reg;
        logic [31:0] all_done_reg;
        logic [11:0] done_cmd_id;
        logic [2:0] done_opcode;
        logic [3:0] done_subop;
        logic done_group_end;
        logic done_illegal;
    begin
        cycles = 0;
        while ((pad_done_pulse_count < target_done_count) && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge clock);
            cycles = cycles + 1;
        end
        if (pad_done_pulse_count < target_done_count) begin
            $fatal(1, "timeout waiting for pad_dexmpc_complete count=%0d (got %0d)",
                   target_done_count, pad_done_pulse_count);
        end

        d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        settle_cycles = 0;
        while ((done_count_reg != target_done_count) && (settle_cycles < 10000)) begin
            @(posedge clock);
            settle_cycles = settle_cycles + 1;
            d2d_cfg_read(CFG_DONECOUNT_0, done_count_reg);
        end
        if (done_count_reg != target_done_count) begin
            $fatal(1, "doneCount_0 mismatch: expected %0d got %0d", target_done_count, done_count_reg);
        end
        if (done_count_reg < observed_done_count) begin
            $fatal(1, "doneCount_0 regressed: last=%0d now=%0d", observed_done_count, done_count_reg);
        end

        d2d_cfg_read(CFG_LASTDONE_0, last_done_reg);
        done_cmd_id = last_done_reg[11:0];
        done_opcode = last_done_reg[14:12];
        done_subop = last_done_reg[18:15];
        done_group_end = last_done_reg[19];
        done_illegal = last_done_reg[20];
        last_cid = issue_order[target_done_count - 1];

        if (done_illegal) begin
            $fatal(1, "illegal command reported in lastDone_0=%h", last_done_reg);
        end
        if (done_cmd_id !== case_cmd_id[last_cid]) begin
            $fatal(1, "lastDone cmd id mismatch: expected %0d got %0d",
                   case_cmd_id[last_cid], done_cmd_id);
        end
        if (done_opcode !== case_opcode[last_cid]) begin
            $fatal(1, "lastDone opcode mismatch: got %0b expected %0b",
                   done_opcode, case_opcode[last_cid]);
        end
        if (done_subop !== case_subop[last_cid]) begin
            $fatal(1, "lastDone subop mismatch for case %0d: got %0h expected %0h",
                   last_cid, done_subop, case_subop[last_cid]);
        end
        if (done_group_end !== 1'b1) begin
            $fatal(1, "lastDone group_end bit is not set, lastDone_0=%h", last_done_reg);
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

        d2d_cfg_read(CFG_ALLDONE_REG, all_done_reg);
        if (all_done_reg[0] !== 1'b1) begin
            $fatal(1, "allDoneReg bit0 not set after completion: %h", all_done_reg);
        end

        d2d_cfg_read(CFG_ENGINE_STATUS, engine_status_reg);
        if (engine_status_reg[3:0] != 4'b0000) begin
            $fatal(1, "engineStatus still busy after completion, engineStatus=%h", engine_status_reg);
        end

        for (issue_idx = observed_done_count; issue_idx < target_done_count; issue_idx = issue_idx + 1) begin
            done_seen[issue_order[issue_idx]] = 1'b1;
        end
        observed_done_count = target_done_count;
        issued_cmd_count = target_done_count;
        last_done_count = done_count_reg;
        done_count = target_done_count;
        expected_done = target_done_count;
    end
    endtask


    task automatic read_words_from_mem(
      input integer mem_id,
      input integer base_addr,
      input integer word_count,
      output word_vec_t words
    );
      integer w;
      logic [SRAM_W-1:0] rd_word;
      begin
        clear_word_vec(words);
        for (w = 0; w < word_count; w = w + 1) begin
          mem_read_word_1cycle(mem_id, base_addr + w, rd_word);
          words[w] = rd_word;
        end
      end
    endtask

    task automatic capture_case_output(input integer cid);
      word_vec_t actual_dst;
      begin
        if (!done_seen[cid]) begin
          $fatal(1, "Missing done for case %0d", cid);
        end

        if (case_kind[cid] == KIND_REDUCE_ADD || case_kind[cid] == KIND_REDUCE_CMP) begin
          if (!reduce_result_seen[cid]) begin
            $fatal(1, "Missing reduce result for case %0d", cid);
          end
        end else begin
          read_words_from_mem(case_dst_mem[cid], case_dst_base[cid], case_dst_words[cid], actual_dst);
          post_dst_words[cid] = actual_dst;
        end
      end
    endtask

    task automatic append_word_headers(input integer fd, input string prefix);
      integer col;
      begin
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
          $fwrite(fd, ",%s_%0d_bin", prefix, col);
        end
      end
    endtask

    task automatic append_word_vec(input integer fd, input word_vec_t words);
      integer col;
      begin
        for (col = 0; col < MAX_WORDS; col = col + 1) begin
          $fwrite(fd, ",%0128b", words[col]);
        end
      end
    endtask

    task automatic append_elem_headers(input integer fd, input string prefix);
      integer col;
      begin
        for (col = 0; col < MAX_REDUCE_ELEMS; col = col + 1) begin
          $fwrite(fd, ",%s_%0d_bin", prefix, col);
        end
      end
    endtask

    task automatic append_reduce_elems(input integer fd, input integer cid);
      integer col;
      begin
        for (col = 0; col < MAX_REDUCE_ELEMS; col = col + 1) begin
          $fwrite(fd, ",%016b", get_word_vec_elem(pre_src_words[cid], col));
        end
      end
    endtask

    task automatic write_csv_headers;
      begin
        $fwrite(fd_abs_in, "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,rows_bin,cols_bin,src_words_bin,dst_words_bin");
        append_word_headers(fd_abs_in, "pre_src_word");
        append_word_headers(fd_abs_in, "pre_dst_word");
        $fwrite(fd_abs_in, "\n");

        $fwrite(fd_abs_out, "cmd_id,case_id,dst_mem,dst_base_bin,rows_bin,cols_bin,dst_words_bin");
        append_word_headers(fd_abs_out, "post_dst_word");
        $fwrite(fd_abs_out, "\n");

        $fwrite(fd_trans_in, "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,src_words_bin,dst_words_bin");
        append_word_headers(fd_trans_in, "pre_src_word");
        append_word_headers(fd_trans_in, "pre_dst_word");
        $fwrite(fd_trans_in, "\n");

        $fwrite(fd_trans_out, "cmd_id,case_id,dst_mem,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,dst_words_bin");
        append_word_headers(fd_trans_out, "post_dst_word");
        $fwrite(fd_trans_out, "\n");

        $fwrite(fd_assem_in, "cmd_id,case_id,src_mem,dst_mem,src_base_bin,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,src_words_bin,dst_words_bin");
        append_word_headers(fd_assem_in, "pre_src_word");
        append_word_headers(fd_assem_in, "pre_dst_word");
        $fwrite(fd_assem_in, "\n");

        $fwrite(fd_assem_out, "cmd_id,case_id,dst_mem,dst_base_bin,src_rows_bin,src_cols_bin,dst_rows_bin,dst_cols_bin,offset_row_bin,offset_col_bin,dst_words_bin");
        append_word_headers(fd_assem_out, "post_dst_word");
        $fwrite(fd_assem_out, "\n");

        $fwrite(fd_reduce_add_in, "cmd_id,case_id,src_mem,src_base_bin,len_bin,src_words_bin");
        append_elem_headers(fd_reduce_add_in, "in_elem");
        $fwrite(fd_reduce_add_in, "\n");

        $fwrite(fd_reduce_add_out, "cmd_id,case_id,result_value_bin,result_index_bin\n");

        $fwrite(fd_reduce_cmp_in, "cmd_id,case_id,src_mem,src_base_bin,len_bin,src_words_bin");
        append_elem_headers(fd_reduce_cmp_in, "in_elem");
        $fwrite(fd_reduce_cmp_in, "\n");

        $fwrite(fd_reduce_cmp_out, "cmd_id,case_id,result_value_bin,result_index_bin\n");

        $fwrite(fd_gemm_in, "cmd_id,case_id,a_mem,b_mem,c_mem,a_base_bin,b_base_bin,c_base_bin,n_rows_bin,m_cols_bin,k_dim_bin,a_words_bin,b_words_bin,c_words_bin");
        append_word_headers(fd_gemm_in, "pre_a_word");
        append_word_headers(fd_gemm_in, "pre_b_word");
        $fwrite(fd_gemm_in, "\n");

        $fwrite(fd_gemm_out, "cmd_id,case_id,c_mem,c_base_bin,n_rows_bin,m_cols_bin,k_dim_bin,c_words_bin");
        append_word_headers(fd_gemm_out, "post_c_word");
        $fwrite(fd_gemm_out, "\n");

        $fwrite(fd_mul_in, "cmd_id,case_id,a_mem,c_mem,a_base_bin,c_base_bin,rows_bin,cols_bin,alpha_bin,a_words_bin,c_words_bin");
        append_word_headers(fd_mul_in, "pre_a_word");
        $fwrite(fd_mul_in, "\n");

        $fwrite(fd_mul_out, "cmd_id,case_id,c_mem,c_base_bin,rows_bin,cols_bin,alpha_bin,c_words_bin");
        append_word_headers(fd_mul_out, "post_c_word");
        $fwrite(fd_mul_out, "\n");

        $fwrite(fd_add_in, "cmd_id,case_id,a_mem,b_mem,c_mem,a_base_bin,b_base_bin,c_base_bin,rows_bin,cols_bin,a_words_bin,b_words_bin,c_words_bin");
        append_word_headers(fd_add_in, "pre_a_word");
        append_word_headers(fd_add_in, "pre_b_word");
        $fwrite(fd_add_in, "\n");

        $fwrite(fd_add_out, "cmd_id,case_id,c_mem,c_base_bin,rows_bin,cols_bin,c_words_bin");
        append_word_headers(fd_add_out, "post_c_word");
        $fwrite(fd_add_out, "\n");

        $fwrite(fd_lut_in, "cmd_id,case_id,subop_bin,src_mem,dst_mem,src_base_bin,dst_base_bin,rows_bin,cols_bin,src_words_bin,dst_words_bin");
        append_word_headers(fd_lut_in, "pre_src_word");
        append_word_headers(fd_lut_in, "pre_dst_word");
        $fwrite(fd_lut_in, "\n");

        $fwrite(fd_lut_out, "cmd_id,case_id,subop_bin,dst_mem,dst_base_bin,rows_bin,cols_bin,dst_words_bin");
        append_word_headers(fd_lut_out, "post_dst_word");
        $fwrite(fd_lut_out, "\n");
      end
    endtask

    task automatic log_case_input(input integer cid);
      begin
        case (case_kind[cid])
          KIND_ABS: begin
            $fwrite(
              fd_abs_in,
              "%0d,%0d,%0d,%0d,%011b,%011b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_src_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_abs_in, pre_src_words[cid]);
            append_word_vec(fd_abs_in, pre_dst_words[cid]);
            $fwrite(fd_abs_in, "\n");
          end
          KIND_LAYOUT_TRANSPOSE: begin
            $fwrite(
              fd_trans_in,
              "%0d,%0d,%0d,%0d,%011b,%011b,%012b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_rows[cid][11:0],
              case_dst_cols[cid][11:0],
              case_src_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_trans_in, pre_src_words[cid]);
            append_word_vec(fd_trans_in, pre_dst_words[cid]);
            $fwrite(fd_trans_in, "\n");
          end
          KIND_LAYOUT_ASSEMBLE: begin
            $fwrite(
              fd_assem_in,
              "%0d,%0d,%0d,%0d,%011b,%011b,%012b,%012b,%012b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_rows[cid][11:0],
              case_dst_cols[cid][11:0],
              case_off_r[cid][11:0],
              case_off_c[cid][11:0],
              case_src_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_assem_in, pre_src_words[cid]);
            append_word_vec(fd_assem_in, pre_dst_words[cid]);
            $fwrite(fd_assem_in, "\n");
          end
          KIND_REDUCE_ADD: begin
            $fwrite(
              fd_reduce_add_in,
              "%0d,%0d,%0d,%011b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_len[cid][11:0],
              case_src_words[cid][11:0]
            );
            append_reduce_elems(fd_reduce_add_in, cid);
            $fwrite(fd_reduce_add_in, "\n");
          end
          KIND_REDUCE_CMP: begin
            $fwrite(
              fd_reduce_cmp_in,
              "%0d,%0d,%0d,%011b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_len[cid][11:0],
              case_src_words[cid][11:0]
            );
            append_reduce_elems(fd_reduce_cmp_in, cid);
            $fwrite(fd_reduce_cmp_in, "\n");
          end
          KIND_GEMM: begin
            $fwrite(
              fd_gemm_in,
              "%0d,%0d,%0d,%0d,%0d,%011b,%011b,%011b,%012b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_aux_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_aux_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_kdim[cid][11:0],
              case_src_words[cid][11:0],
              case_aux_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_gemm_in, pre_src_words[cid]);
            append_word_vec(fd_gemm_in, pre_aux_words[cid]);
            $fwrite(fd_gemm_in, "\n");
          end
          KIND_MUL: begin
            $fwrite(
              fd_mul_in,
              "%0d,%0d,%0d,%0d,%011b,%011b,%012b,%012b,%016b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_alpha[cid],
              case_src_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_mul_in, pre_src_words[cid]);
            $fwrite(fd_mul_in, "\n");
          end
          KIND_ADD: begin
            $fwrite(
              fd_add_in,
              "%0d,%0d,%0d,%0d,%0d,%011b,%011b,%011b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_src_mem[cid],
              case_aux_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_aux_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_src_words[cid][11:0],
              case_aux_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_add_in, pre_src_words[cid]);
            append_word_vec(fd_add_in, pre_aux_words[cid]);
            $fwrite(fd_add_in, "\n");
          end
          KIND_LUT: begin
            $fwrite(
              fd_lut_in,
              "%0d,%0d,%04b,%0d,%0d,%011b,%011b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_subop[cid],
              case_src_mem[cid],
              case_dst_mem[cid],
              case_src_base[cid][ADDR_W-1:0],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_src_words[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_lut_in, pre_src_words[cid]);
            append_word_vec(fd_lut_in, pre_dst_words[cid]);
            $fwrite(fd_lut_in, "\n");
          end
          default: $fatal(1, "Unknown case kind on input log for case %0d", cid);
        endcase
      end
    endtask

    task automatic log_case_output(input integer cid);
      begin
        case (case_kind[cid])
          KIND_ABS: begin
            $fwrite(
              fd_abs_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_abs_out, post_dst_words[cid]);
            $fwrite(fd_abs_out, "\n");
          end
          KIND_LAYOUT_TRANSPOSE: begin
            $fwrite(
              fd_trans_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_rows[cid][11:0],
              case_dst_cols[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_trans_out, post_dst_words[cid]);
            $fwrite(fd_trans_out, "\n");
          end
          KIND_LAYOUT_ASSEMBLE: begin
            $fwrite(
              fd_assem_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%012b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_rows[cid][11:0],
              case_dst_cols[cid][11:0],
              case_off_r[cid][11:0],
              case_off_c[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_assem_out, post_dst_words[cid]);
            $fwrite(fd_assem_out, "\n");
          end
          KIND_REDUCE_ADD: begin
            $fwrite(
              fd_reduce_add_out,
              "%0d,%0d,%016b,%012b\n",
              case_cmd_id[cid],
              cid,
              got_reduce_value[cid],
              got_reduce_index[cid]
            );
          end
          KIND_REDUCE_CMP: begin
            $fwrite(
              fd_reduce_cmp_out,
              "%0d,%0d,%016b,%012b\n",
              case_cmd_id[cid],
              cid,
              got_reduce_value[cid],
              got_reduce_index[cid]
            );
          end
          KIND_GEMM: begin
            $fwrite(
              fd_gemm_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_kdim[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_gemm_out, post_dst_words[cid]);
            $fwrite(fd_gemm_out, "\n");
          end
          KIND_MUL: begin
            $fwrite(
              fd_mul_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%016b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_alpha[cid],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_mul_out, post_dst_words[cid]);
            $fwrite(fd_mul_out, "\n");
          end
          KIND_ADD: begin
            $fwrite(
              fd_add_out,
              "%0d,%0d,%0d,%011b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_add_out, post_dst_words[cid]);
            $fwrite(fd_add_out, "\n");
          end
          KIND_LUT: begin
            $fwrite(
              fd_lut_out,
              "%0d,%0d,%04b,%0d,%011b,%012b,%012b,%012b",
              case_cmd_id[cid],
              cid,
              case_subop[cid],
              case_dst_mem[cid],
              case_dst_base[cid][ADDR_W-1:0],
              case_rows[cid][11:0],
              case_cols[cid][11:0],
              case_dst_words[cid][11:0]
            );
            append_word_vec(fd_lut_out, post_dst_words[cid]);
            $fwrite(fd_lut_out, "\n");
          end
          default: $fatal(1, "Unknown case kind on output log for case %0d", cid);
        endcase
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
        $fsdbDumpfile("tb_TopChipTop_mixed_d2d.fsdb");
        $fsdbDumpvars(0, tb_TopChipTop_mixed_d2d, "+all");
    end

    initial begin
        integer cid;
        integer issue_idx;
        integer burst_count;
        integer start_pulse_count;

        pad_done_pulse_count = 0;
        observed_done_count = 0;
        issued_cmd_count = 0;
        done_count = 0;
        expected_done = 0;
        last_done_count = 0;
        saw_fifo_full = 1'b0;
        max_fifo_count = 0;

        #100ns;
        @(negedge clock);

        d2d_cfg_write(CFG_IS_LOOP, 32'h0000_0000);
        smoke_test_sram_d2d();

        mkdir_ret = $system("mkdir -p verification/results/full_chip/d2d");
        fd_abs_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_abs_input.csv", "w");
        fd_abs_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_abs_output.csv", "w");
        fd_trans_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_layout_transpose_input.csv", "w");
        fd_trans_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_layout_transpose_output.csv", "w");
        fd_assem_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_layout_assemble_input.csv", "w");
        fd_assem_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_layout_assemble_output.csv", "w");
        fd_reduce_add_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_reduce_add_input.csv", "w");
        fd_reduce_add_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_reduce_add_output.csv", "w");
        fd_reduce_cmp_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_reduce_cmp_input.csv", "w");
        fd_reduce_cmp_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_reduce_cmp_output.csv", "w");
        fd_gemm_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_gemm_input.csv", "w");
        fd_gemm_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_gemm_output.csv", "w");
        fd_mul_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_mul_input.csv", "w");
        fd_mul_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_mul_output.csv", "w");
        fd_add_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_add_input.csv", "w");
        fd_add_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_add_output.csv", "w");
        fd_lut_in = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_lut_input.csv", "w");
        fd_lut_out = $fopen("verification/results/full_chip/d2d/tb_TopChipTop_mixed_d2d_lut_output.csv", "w");

        if (fd_abs_in == 0 || fd_abs_out == 0 ||
            fd_trans_in == 0 || fd_trans_out == 0 ||
            fd_assem_in == 0 || fd_assem_out == 0 ||
            fd_reduce_add_in == 0 || fd_reduce_add_out == 0 ||
            fd_reduce_cmp_in == 0 || fd_reduce_cmp_out == 0 ||
            fd_gemm_in == 0 || fd_gemm_out == 0 ||
            fd_mul_in == 0 || fd_mul_out == 0 ||
            fd_add_in == 0 || fd_add_out == 0 ||
            fd_lut_in == 0 || fd_lut_out == 0) begin
            $fatal(1, "failed to open mixed result csv files");
        end

        write_csv_headers();
        $readmemh("verification/data/full_chip/trig_data.hex", trig_mem);
        $readmemh("verification/data/full_chip/softplus_data.hex", soft_mem);

        build_cases();
        build_issue_order();
        for (cid = 0; cid < num_cases; cid = cid + 1) begin
            log_case_input(cid);
        end

        load_lut_tables();
        preload_cases_to_sram();

        for (issue_idx = 0; issue_idx < num_reduce_cases; issue_idx = issue_idx + 1) begin
            cid = reduce_case_ids[issue_idx];
            start_pulse_count = pad_done_pulse_count;
            push_issue_cmd_checked(issue_idx);
            wait_for_reduce_case_completion(cid, issue_idx, start_pulse_count);
        end

        if (num_non_reduce_cases > 0) begin
            burst_count = (num_non_reduce_cases < BURST_FILL_CMDS) ? num_non_reduce_cases : BURST_FILL_CMDS;
            push_issue_burst(num_reduce_cases, burst_count);
            if (burst_count == BURST_FILL_CMDS) begin
                wait_for_fifo_full_observation();
            end
            for (issue_idx = num_reduce_cases + burst_count; issue_idx < num_cases; issue_idx = issue_idx + 1) begin
                push_issue_cmd_checked(issue_idx);
            end
            wait_for_remaining_completions(num_cases);
        end

        repeat (8) @(posedge clock);
        for (cid = 0; cid < num_cases; cid = cid + 1) begin
            capture_case_output(cid);
            log_case_output(cid);
        end

        $fclose(fd_abs_in);
        $fclose(fd_abs_out);
        $fclose(fd_trans_in);
        $fclose(fd_trans_out);
        $fclose(fd_assem_in);
        $fclose(fd_assem_out);
        $fclose(fd_reduce_add_in);
        $fclose(fd_reduce_add_out);
        $fclose(fd_reduce_cmp_in);
        $fclose(fd_reduce_cmp_out);
        $fclose(fd_gemm_in);
        $fclose(fd_gemm_out);
        $fclose(fd_mul_in);
        $fclose(fd_mul_out);
        $fclose(fd_add_in);
        $fclose(fd_add_out);
        $fclose(fd_lut_in);
        $fclose(fd_lut_out);

        repeat (20) @(posedge clock);
        $display("tb_TopChipTop_mixed_d2d completes at %t.", $time);
        $finish;
    end

    initial begin
        #100000000;
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
