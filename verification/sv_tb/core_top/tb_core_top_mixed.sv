`timescale 1ns/1ps

module tb_core_top_mixed;
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

  localparam integer MAX_CASES = 40;
  localparam integer MAX_WORDS = 64;
  localparam integer MAX_DIM = 16;
  localparam integer MAX_REDUCE_ELEMS = 32;
  localparam integer FIFO_DEPTH = 32;
  localparam integer BURST_FILL_CMDS = FIFO_DEPTH + 1;
  localparam integer TIMEOUT_CYCLES = 1200000;

  localparam integer KIND_ABS = 0;
  localparam integer KIND_LAYOUT_TRANSPOSE = 1;
  localparam integer KIND_LAYOUT_ASSEMBLE = 2;
  localparam integer KIND_REDUCE_ADD = 3;
  localparam integer KIND_REDUCE_CMP = 4;
  localparam integer KIND_GEMM = 5;
  localparam integer KIND_MUL = 6;
  localparam integer KIND_ADD = 7;

  localparam logic [2:0] OP_ABS = 3'b001;
  localparam logic [2:0] OP_REDUCE = 3'b010;
  localparam logic [2:0] OP_LA = 3'b011;
  localparam logic [2:0] OP_DATALAYOUT = 3'b101;

  localparam logic [3:0] SUB_ABS = 4'h0;
  localparam logic [3:0] SUB_CMP_REDUCE = 4'h0;
  localparam logic [3:0] SUB_ADD_TREE = 4'h1;
  localparam logic [3:0] SUB_GEMM = 4'h0;
  localparam logic [3:0] SUB_MUL = 4'h1;
  localparam logic [3:0] SUB_ADD = 4'h2;
  localparam logic [3:0] SUB_ASSEMBLE = 4'h0;
  localparam logic [3:0] SUB_TRANSPOSE = 4'h1;

  localparam logic [15:0] FP16_ZERO = 16'h0000;
  localparam logic [15:0] FP16_HALF = 16'h3800;
  localparam logic [15:0] FP16_ONE  = 16'h3C00;
  localparam logic [15:0] FP16_TWO  = 16'h4000;
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

  typedef logic [SRAM_W-1:0] word_vec_t [0:MAX_WORDS-1];
  typedef logic [15:0] matrix_t [0:MAX_DIM-1][0:MAX_DIM-1];
  typedef logic [15:0] vector_t [0:MAX_REDUCE_ELEMS-1];

  logic clock;
  logic reset;

  logic [31:0] cmdWord_0_0;
  logic [31:0] cmdWord_0_1;
  logic [31:0] cmdWord_0_2;
  logic [31:0] cmdWord_1_0;
  logic [31:0] cmdWord_1_1;
  logic [31:0] cmdWord_1_2;
  logic [31:0] cmdWord_2_0;
  logic [31:0] cmdWord_2_1;
  logic [31:0] cmdWord_2_2;
  logic [31:0] cmdWord_3_0;
  logic [31:0] cmdWord_3_1;
  logic [31:0] cmdWord_3_2;
  logic [31:0] cmdCtrl_0;
  logic [31:0] cmdCtrl_1;
  logic [31:0] cmdCtrl_2;
  logic [31:0] cmdCtrl_3;
  logic [31:0] cycleRdAddr_0;
  logic [31:0] cycleRdAddr_1;
  logic [31:0] cycleRdAddr_2;
  logic [31:0] cycleRdAddr_3;
  logic [31:0] spareIn0;
  logic [31:0] spareIn1;

  logic [31:0] cmdStatus_0;
  logic [31:0] cmdStatus_1;
  logic [31:0] cmdStatus_2;
  logic [31:0] cmdStatus_3;
  logic [31:0] doneCount_0;
  logic [31:0] doneCount_1;
  logic [31:0] doneCount_2;
  logic [31:0] doneCount_3;
  logic [31:0] lastDone_0;
  logic [31:0] lastDone_1;
  logic [31:0] lastDone_2;
  logic [31:0] lastDone_3;
  logic [31:0] lastDoneCycle_0;
  logic [31:0] lastDoneCycle_1;
  logic [31:0] lastDoneCycle_2;
  logic [31:0] lastDoneCycle_3;
  logic [31:0] cycleRdData_0;
  logic [31:0] cycleRdData_1;
  logic [31:0] cycleRdData_2;
  logic [31:0] cycleRdData_3;
  logic [31:0] addReduceReg_0;
  logic [31:0] addReduceReg_1;
  logic [31:0] addReduceReg_2;
  logic [31:0] addReduceReg_3;
  logic [31:0] cmpReduceReg0_0;
  logic [31:0] cmpReduceReg0_1;
  logic [31:0] cmpReduceReg0_2;
  logic [31:0] cmpReduceReg0_3;
  logic [31:0] cmpReduceReg1_0;
  logic [31:0] cmpReduceReg1_1;
  logic [31:0] cmpReduceReg1_2;
  logic [31:0] cmpReduceReg1_3;
  logic [31:0] engineStatus;
  logic [31:0] allDoneReg;
  logic [31:0] done_signal;
  logic [31:0] spareOut1;

  logic [14:0] buf_addr;
  logic        buf_enable;
  logic        buf_isWrite;
  logic [127:0] buf_readData;
  logic [127:0] buf_writeData;
  logic [127:0] buf_bweb;

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
  logic        reduce_result_seen [0:MAX_CASES-1];
  logic        done_seen [0:MAX_CASES-1];

  integer next_base_global;
  integer next_base_local;
  integer next_base_temp;

  integer done_count;
  integer expected_done;
  integer cycles;
  logic [31:0] last_done_count;
  logic saw_fifo_full;
  integer max_fifo_count;

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
  integer mkdir_ret;

  DexMPCCoreTop dut (
    .clock                  (clock),
    .reset                  (reset),
    .io_cmdWord_0_0         (cmdWord_0_0),
    .io_cmdWord_0_1         (cmdWord_0_1),
    .io_cmdWord_0_2         (cmdWord_0_2),
    .io_cmdWord_1_0         (cmdWord_1_0),
    .io_cmdWord_1_1         (cmdWord_1_1),
    .io_cmdWord_1_2         (cmdWord_1_2),
    .io_cmdWord_2_0         (cmdWord_2_0),
    .io_cmdWord_2_1         (cmdWord_2_1),
    .io_cmdWord_2_2         (cmdWord_2_2),
    .io_cmdWord_3_0         (cmdWord_3_0),
    .io_cmdWord_3_1         (cmdWord_3_1),
    .io_cmdWord_3_2         (cmdWord_3_2),
    .io_cmdCtrl_0           (cmdCtrl_0),
    .io_cmdCtrl_1           (cmdCtrl_1),
    .io_cmdCtrl_2           (cmdCtrl_2),
    .io_cmdCtrl_3           (cmdCtrl_3),
    .io_cycleRdAddr_0       (cycleRdAddr_0),
    .io_cycleRdAddr_1       (cycleRdAddr_1),
    .io_cycleRdAddr_2       (cycleRdAddr_2),
    .io_cycleRdAddr_3       (cycleRdAddr_3),
    .io_spareIn0            (spareIn0),
    .io_spareIn1            (spareIn1),
    .io_cmdStatus_0         (cmdStatus_0),
    .io_cmdStatus_1         (cmdStatus_1),
    .io_cmdStatus_2         (cmdStatus_2),
    .io_cmdStatus_3         (cmdStatus_3),
    .io_doneCount_0         (doneCount_0),
    .io_doneCount_1         (doneCount_1),
    .io_doneCount_2         (doneCount_2),
    .io_doneCount_3         (doneCount_3),
    .io_lastDone_0          (lastDone_0),
    .io_lastDone_1          (lastDone_1),
    .io_lastDone_2          (lastDone_2),
    .io_lastDone_3          (lastDone_3),
    .io_lastDoneCycle_0     (lastDoneCycle_0),
    .io_lastDoneCycle_1     (lastDoneCycle_1),
    .io_lastDoneCycle_2     (lastDoneCycle_2),
    .io_lastDoneCycle_3     (lastDoneCycle_3),
    .io_cycleRdData_0       (cycleRdData_0),
    .io_cycleRdData_1       (cycleRdData_1),
    .io_cycleRdData_2       (cycleRdData_2),
    .io_cycleRdData_3       (cycleRdData_3),
    .io_addReduceReg_0      (addReduceReg_0),
    .io_addReduceReg_1      (addReduceReg_1),
    .io_addReduceReg_2      (addReduceReg_2),
    .io_addReduceReg_3      (addReduceReg_3),
    .io_cmpReduceReg0_0     (cmpReduceReg0_0),
    .io_cmpReduceReg0_1     (cmpReduceReg0_1),
    .io_cmpReduceReg0_2     (cmpReduceReg0_2),
    .io_cmpReduceReg0_3     (cmpReduceReg0_3),
    .io_cmpReduceReg1_0     (cmpReduceReg1_0),
    .io_cmpReduceReg1_1     (cmpReduceReg1_1),
    .io_cmpReduceReg1_2     (cmpReduceReg1_2),
    .io_cmpReduceReg1_3     (cmpReduceReg1_3),
    .io_engineStatus        (engineStatus),
    .io_allDoneReg          (allDoneReg),
    .io_done_signal         (done_signal),
    .io_spareOut1           (spareOut1),
    .io_Buffer_exts_address (buf_addr),
    .io_Buffer_exts_enable  (buf_enable),
    .io_Buffer_exts_isWrite (buf_isWrite),
    .io_Buffer_exts_readData(buf_readData),
    .io_Buffer_exts_writeData(buf_writeData),
    .io_Buffer_exts_bweb    (buf_bweb)
  );

  initial begin
    clock = 1'b0;
  end
  always #5 clock = ~clock;

  initial begin
    $fsdbDumpfile("tb_core_top_mixed.fsdb");
    $fsdbDumpvars(0, tb_core_top_mixed);
  end

  function automatic integer ceil_div(input integer num, input integer den);
    begin
      if (den == 0) begin
        ceil_div = 0;
      end else begin
        ceil_div = (num + den - 1) / den;
      end
    end
  endfunction

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

  function automatic logic [12:0] pack_addr(
    input integer mem_id,
    input logic [10:0] word_idx
  );
    begin
      pack_addr = {mem_id_bits(mem_id), word_idx};
    end
  endfunction

  function automatic logic [95:0] make_cmd(
    input logic [11:0] cmd_id,
    input logic [2:0] opcode,
    input logic [3:0] subop,
    input logic       group_end,
    input logic [12:0] addr0,
    input logic [12:0] addr1,
    input logic [12:0] addr2,
    input logic [11:0] dim0,
    input logic [11:0] dim1,
    input logic [11:0] dim2
  );
    begin
      make_cmd = {cmd_id, opcode, subop, group_end, 1'b0, addr0, addr1, addr2, dim0, dim1, dim2};
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

      if (num_cases < BURST_FILL_CMDS) begin
        $fatal(1, "Need at least %0d commands to validate FIFO full, only built %0d", BURST_FILL_CMDS, num_cases);
      end
      case_cmd[num_cases - 1][76] = 1'b1;
    end
  endtask

  task automatic mem_write_word(
    input integer mem_id,
    input logic [ADDR_W-1:0] addr,
    input logic [SRAM_W-1:0] data
  );
    logic [14:0] local_addr;
    begin
      if (addr >= sram_depth(mem_id)) $fatal(1, "SRAM %0d addr overflow on write addr=%0d", mem_id, addr);
      local_addr = pack_buf_addr(mem_id, addr);

      @(negedge clock);
      buf_enable    <= 1'b1;
      buf_isWrite   <= 1'b1;
      buf_addr      <= local_addr;
      buf_writeData <= data;
      buf_bweb      <= {SRAM_W{1'b0}};

      @(negedge clock);
      buf_enable    <= 1'b0;
      buf_isWrite   <= 1'b0;
      buf_addr      <= '0;
      buf_writeData <= '0;
      buf_bweb      <= {SRAM_W{1'b1}};
    end
  endtask

  task automatic mem_read_word_1cycle(
    input integer mem_id,
    input logic [ADDR_W-1:0] addr,
    output logic [SRAM_W-1:0] data
  );
    logic [14:0] local_addr;
    begin
      if (addr >= sram_depth(mem_id)) $fatal(1, "SRAM %0d addr overflow on read addr=%0d", mem_id, addr);
      local_addr = pack_buf_addr(mem_id, addr);

      @(negedge clock);
      buf_enable    <= 1'b1;
      buf_isWrite   <= 1'b0;
      buf_addr      <= local_addr;
      buf_writeData <= '0;
      buf_bweb      <= {SRAM_W{1'b1}};

      @(negedge clock);
      data = buf_readData;
      buf_enable    <= 1'b0;
      buf_addr      <= '0;
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
    begin
      while (cmdStatus_0[0] === 1'b1) begin
        @(posedge clock);
      end
    end
  endtask

  task automatic push_cmd_raw(input logic [95:0] cmd);
    begin
      @(negedge clock);
      cmdWord_0_0 <= cmd[31:0];
      cmdWord_0_1 <= cmd[63:32];
      cmdWord_0_2 <= cmd[95:64];
      cmdCtrl_0   <= 32'h1;
      @(negedge clock);
      cmdCtrl_0   <= 32'h0;
    end
  endtask

  task automatic push_cmd_checked(input logic [95:0] cmd);
    begin
      wait_fifo_space();
      push_cmd_raw(cmd);
    end
  endtask

  task automatic push_initial_burst(input integer burst_count);
    integer cid;
    begin
      for (cid = 0; cid < burst_count; cid = cid + 1) begin
        push_cmd_raw(case_cmd[cid]);
      end
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
        default: $fatal(1, "Unknown case kind on output log for case %0d", cid);
      endcase
    end
  endtask

  always @(posedge clock) begin
    integer done_idx;
    logic [11:0] done_cmd_id;
    logic [2:0]  done_opcode;
    logic [3:0]  done_subop;
    logic        done_group_end;
    logic        done_illegal;
    logic [15:0] add_val;
    logic [11:0] add_cmd;
    logic        add_valid;
    logic [15:0] cmp_val;
    logic [11:0] cmp_cmd;
    logic        cmp_valid;
    logic [11:0] cmp_idx;
    if (reset) begin
      done_count <= 0;
      expected_done <= 0;
      last_done_count <= 0;
      saw_fifo_full <= 1'b0;
      max_fifo_count <= 0;
    end else begin
      if (cmdStatus_0[0]) begin
        saw_fifo_full <= 1'b1;
      end
      if (cmdStatus_0[15:8] > max_fifo_count) begin
        max_fifo_count <= cmdStatus_0[15:8];
      end
      if (cmdStatus_0[5] === 1'b1) begin
        $fatal(1, "cmdStatus overflow set unexpectedly");
      end
      if (doneCount_0 != last_done_count) begin
        if (doneCount_0 != (last_done_count + 1)) begin
          $fatal(1, "doneCount jump: last=%0d now=%0d", last_done_count, doneCount_0);
        end
        done_cmd_id = lastDone_0[11:0];
        done_opcode = lastDone_0[14:12];
        done_subop = lastDone_0[18:15];
        done_group_end = lastDone_0[19];
        done_illegal = lastDone_0[20];
        done_idx = done_cmd_id;

        if (done_illegal) begin
          $fatal(1, "illegal command reported in lastDone for cmd %0d", done_cmd_id);
        end
        if (done_idx < 0 || done_idx >= num_cases) begin
          $fatal(1, "done cmd id %0d out of range", done_cmd_id);
        end
        if (done_cmd_id !== expected_done[11:0]) begin
          $fatal(1, "doneCmdId out of order: got %0d expected %0d", done_cmd_id, expected_done);
        end
        if (done_opcode !== case_opcode[done_idx]) begin
          $fatal(1, "done opcode mismatch for cmd %0d: got %0b expected %0b", done_idx, done_opcode, case_opcode[done_idx]);
        end
        if (done_subop !== case_subop[done_idx]) begin
          $fatal(1, "done subop mismatch for cmd %0d: got %0h expected %0h", done_idx, done_subop, case_subop[done_idx]);
        end
        if (done_group_end !== (done_idx == (num_cases - 1))) begin
          $fatal(1, "done group_end mismatch for cmd %0d", done_idx);
        end

        if (case_kind[done_idx] == KIND_REDUCE_ADD) begin
          add_val = addReduceReg_0[15:0];
          add_cmd = addReduceReg_0[27:16];
          add_valid = addReduceReg_0[28];
          if (add_valid !== 1'b1) begin
            $fatal(1, "addReduce valid not set for cmd %0d", done_idx);
          end
          if (add_cmd !== done_cmd_id) begin
            $fatal(1, "addReduce cmd id mismatch for cmd %0d got %0d", done_idx, add_cmd);
          end
          got_reduce_value[done_idx] <= add_val;
          got_reduce_index[done_idx] <= 12'h000;
          reduce_result_seen[done_idx] <= 1'b1;
        end else if (case_kind[done_idx] == KIND_REDUCE_CMP) begin
          cmp_val = cmpReduceReg0_0[15:0];
          cmp_cmd = cmpReduceReg0_0[27:16];
          cmp_valid = cmpReduceReg0_0[28];
          cmp_idx = cmpReduceReg1_0[11:0];
          if (cmp_valid !== 1'b1) begin
            $fatal(1, "cmpReduce valid not set for cmd %0d", done_idx);
          end
          if (cmp_cmd !== done_cmd_id) begin
            $fatal(1, "cmpReduce cmd id mismatch for cmd %0d got %0d", done_idx, cmp_cmd);
          end
          got_reduce_value[done_idx] <= cmp_val;
          got_reduce_index[done_idx] <= cmp_idx;
          reduce_result_seen[done_idx] <= 1'b1;
        end

        done_seen[done_idx] <= 1'b1;
        done_count <= done_count + 1;
        expected_done <= expected_done + 1;
        last_done_count <= doneCount_0;
      end
    end
  end

  initial begin
    integer cid;
    integer burst_count;

    cmdWord_0_0 = '0;
    cmdWord_0_1 = '0;
    cmdWord_0_2 = '0;
    cmdWord_1_0 = '0;
    cmdWord_1_1 = '0;
    cmdWord_1_2 = '0;
    cmdWord_2_0 = '0;
    cmdWord_2_1 = '0;
    cmdWord_2_2 = '0;
    cmdWord_3_0 = '0;
    cmdWord_3_1 = '0;
    cmdWord_3_2 = '0;
    cmdCtrl_0 = 32'h0;
    cmdCtrl_1 = 32'h0;
    cmdCtrl_2 = 32'h0;
    cmdCtrl_3 = 32'h0;
    cycleRdAddr_0 = '0;
    cycleRdAddr_1 = '0;
    cycleRdAddr_2 = '0;
    cycleRdAddr_3 = '0;
    spareIn0 = '0;
    spareIn1 = '0;

    buf_addr = '0;
    buf_enable = 1'b0;
    buf_isWrite = 1'b0;
    buf_writeData = '0;
    buf_bweb = {SRAM_W{1'b1}};

    reset = 1'b1;
    done_count = 0;
    expected_done = 0;
    last_done_count = 0;
    saw_fifo_full = 1'b0;
    max_fifo_count = 0;

    build_cases();

    mkdir_ret = $system("mkdir -p verification/results/core_top/mixed");
    fd_abs_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_abs_input.csv", "w");
    fd_abs_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_abs_output.csv", "w");
    fd_trans_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_layout_transpose_input.csv", "w");
    fd_trans_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_layout_transpose_output.csv", "w");
    fd_assem_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_layout_assemble_input.csv", "w");
    fd_assem_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_layout_assemble_output.csv", "w");
    fd_reduce_add_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_reduce_add_input.csv", "w");
    fd_reduce_add_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_reduce_add_output.csv", "w");
    fd_reduce_cmp_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_reduce_cmp_input.csv", "w");
    fd_reduce_cmp_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_reduce_cmp_output.csv", "w");
    fd_gemm_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_gemm_input.csv", "w");
    fd_gemm_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_gemm_output.csv", "w");
    fd_mul_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_mul_input.csv", "w");
    fd_mul_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_mul_output.csv", "w");
    fd_add_in = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_add_input.csv", "w");
    fd_add_out = $fopen("verification/results/core_top/mixed/tb_core_top_mixed_add_output.csv", "w");

    if (fd_abs_in == 0 || fd_abs_out == 0 ||
        fd_trans_in == 0 || fd_trans_out == 0 ||
        fd_assem_in == 0 || fd_assem_out == 0 ||
        fd_reduce_add_in == 0 || fd_reduce_add_out == 0 ||
        fd_reduce_cmp_in == 0 || fd_reduce_cmp_out == 0 ||
        fd_gemm_in == 0 || fd_gemm_out == 0 ||
        fd_mul_in == 0 || fd_mul_out == 0 ||
        fd_add_in == 0 || fd_add_out == 0) begin
      $fatal(1, "failed to open mixed result csv files");
    end

    write_csv_headers();
    for (cid = 0; cid < num_cases; cid = cid + 1) begin
      log_case_input(cid);
    end

    repeat (4) @(posedge clock);
    preload_cases_to_sram();

    repeat (4) @(posedge clock);
    reset = 1'b0;
    repeat (2) @(posedge clock);

    burst_count = BURST_FILL_CMDS;
    push_initial_burst(burst_count);

    cycles = 0;
    while (!saw_fifo_full && (cycles < 400)) begin
      @(posedge clock);
      cycles = cycles + 1;
    end
    if (!saw_fifo_full) begin
      $fatal(1, "FIFO full was never observed, max fifo count=%0d", max_fifo_count);
    end

    for (cid = burst_count; cid < num_cases; cid = cid + 1) begin
      push_cmd_checked(case_cmd[cid]);
    end

    cycles = 0;
    while ((done_count < num_cases) && (cycles < TIMEOUT_CYCLES)) begin
      @(posedge clock);
      cycles = cycles + 1;
    end
    if (done_count < num_cases) begin
      $fatal(1, "timeout waiting for done_count=%0d got=%0d", num_cases, done_count);
    end

    repeat (8) @(posedge clock);
    if (cmdStatus_0[4] !== 1'b1) begin
      $fatal(1, "core0 all_done bit not set after completion");
    end
    if (allDoneReg[0] !== 1'b1) begin
      $fatal(1, "allDoneReg bit0 not set after completion");
    end
    if (engineStatus[3:0] !== 4'b0000) begin
      $fatal(1, "engineStatus still busy after completion: %0b", engineStatus[3:0]);
    end

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

    repeat (5) @(posedge clock);
    $finish;
  end

  initial begin
    #100000000;
    $fatal(1, "simulation timeout");
  end
endmodule
