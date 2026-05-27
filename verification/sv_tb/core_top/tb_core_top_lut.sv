`timescale 1ns/1ps

module tb_core_top_lut;
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
  localparam integer OP_COUNT = 3;
  localparam integer COMBOS = 9;
  localparam integer CASES = BASE_CASES * OP_COUNT * COMBOS;
  localparam integer MAX_WORDS = 8;
  localparam integer TIMEOUT_CYCLES = 400000;
  localparam integer TRIG_BANK_DEPTH = 128;
  localparam integer TRIG_TOTAL_WORDS = 4 * TRIG_BANK_DEPTH;
  localparam integer SOFTPLUS_BANK_DEPTH = 256;
  localparam integer SOFTPLUS_TOTAL_WORDS = 2 * SOFTPLUS_BANK_DEPTH;
  localparam logic [14:0] EIGHT_PI_BITS = 15'h4E48;

  localparam integer BASE_ROWS [0:BASE_CASES-1] = '{
    1, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5
  };
  localparam integer BASE_COLS [0:BASE_CASES-1] = '{
    1, 2, 3, 2, 3, 1, 3, 1, 2, 4, 1, 2
  };

  localparam logic [2:0] OP_LUT = 3'b100;
  localparam logic [3:0] SUB_SIN = 4'h0;
  localparam logic [3:0] SUB_COS = 4'h1;
  localparam logic [3:0] SUB_SOFTPLUS = 4'h2;

  localparam integer MEM_GLOBAL = 0;
  localparam integer MEM_LOCAL0 = 1;
  localparam integer MEM_TEMP0 = 2;
  localparam integer MEM_TRIG_SIN_EVEN = 9;
  localparam integer MEM_TRIG_SIN_ODD = 10;
  localparam integer MEM_TRIG_COS_EVEN = 11;
  localparam integer MEM_TRIG_COS_ODD = 12;
  localparam integer MEM_SOFT_EVEN = 13;
  localparam integer MEM_SOFT_ODD = 14;

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

  integer case_rows [0:CASES-1];
  integer case_cols [0:CASES-1];
  integer case_elem_count [0:CASES-1];
  integer case_word_count [0:CASES-1];
  integer case_seq [0:CASES-1];
  integer case_src_id [0:CASES-1];
  integer case_dst_id [0:CASES-1];
  integer case_op [0:CASES-1];
  logic   case_loaded [0:CASES-1];
  logic [11:0] case_cmd_id [0:CASES-1];
  logic [ADDR_W-1:0] case_src_base [0:CASES-1];
  logic [ADDR_W-1:0] case_dst_base [0:CASES-1];
  logic [95:0] case_cmd [0:CASES-1];

  logic [SRAM_W-1:0] pre_words [0:CASES-1][0:MAX_WORDS-1];
  logic [SRAM_W-1:0] post_words [0:CASES-1][0:MAX_WORDS-1];
  logic             done_seen [0:CASES-1];

  logic [15:0] trig_mem [0:TRIG_TOTAL_WORDS-1];
  logic [31:0] soft_mem [0:SOFTPLUS_TOTAL_WORDS-1];

  integer done_count;
  integer expected_done;
  integer cycles;
  logic [31:0] last_done_count;

  integer in_csv_fd;
  integer out_csv_fd;
  integer mkdir_ret;
  semaphore csv_lock;

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
    $fsdbDumpfile("tb_core_top_lut.fsdb");
    $fsdbDumpvars(0, tb_core_top_lut);
  end

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
    input logic       group_end,
    input logic [12:0] addr0,
    input logic [12:0] addr1,
    input logic [12:0] addr2,
    input logic [11:0] dim0,
    input logic [11:0] dim1,
    input logic [11:0] dim2
  );
    make_cmd = {cmd_id, opcode, subop, group_end, 1'b0, addr0, addr1, addr2, dim0, dim1, dim2};
  endfunction

  function automatic logic [14:0] pack_buf_addr(
    input integer mem_id,
    input logic [10:0] word_idx
  );
    logic [3:0] mem_sel;
    logic [10:0] word_sel;
    begin
      case (mem_id)
        MEM_GLOBAL: begin
          mem_sel = 4'h0;
          word_sel = word_idx;
        end
        MEM_LOCAL0: begin
          mem_sel = 4'h1;
          word_sel = {2'b0, word_idx[8:0]};
        end
        MEM_TEMP0: begin
          mem_sel = 4'h5;
          word_sel = {1'b0, word_idx[9:0]};
        end
        MEM_TRIG_SIN_EVEN,
        MEM_TRIG_SIN_ODD,
        MEM_TRIG_COS_EVEN,
        MEM_TRIG_COS_ODD: begin
          mem_sel = mem_id[3:0];
          word_sel = {4'b0, word_idx[6:0]};
        end
        MEM_SOFT_EVEN,
        MEM_SOFT_ODD: begin
          mem_sel = mem_id[3:0];
          word_sel = {3'b0, word_idx[7:0]};
        end
        default: begin
          mem_sel = 4'hf;
          word_sel = 11'h0;
        end
      endcase
      pack_buf_addr = {mem_sel, word_sel};
    end
  endfunction

  integer next_base_global;
  integer next_base_local;
  integer next_base_temp;

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

  function automatic [15:0] rand_fp16();
    reg [15:0] v;
    int tries;
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

  function automatic [15:0] rand_fp16_trig_range();
    reg [15:0] v;
    int tries;
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

  task automatic load_inputs_from_csv;
    integer fd;
    string line;
    integer got;
    integer cid;
    integer src_id;
    integer dst_id;
    integer op_id;
    integer rows;
    integer cols;
    integer idx;
    integer r;
    integer c;
    integer word_idx;
    integer lane;
    logic [15:0] val;
    begin
      for (cid = 0; cid < CASES; cid = cid + 1) begin
        case_loaded[cid] = 1'b0;
      end

      fd = $fopen("verification/results/core_top/lut/all_inputs.csv", "r");
      if (fd == 0) begin
        $fatal(1, "failed to open verification/results/core_top/lut/all_inputs.csv");
      end

      while (!$feof(fd)) begin
        line = "";
        if ($fgets(line, fd) == 0) begin
          break;
        end
        got = $sscanf(line, "# case=%d src=%d dst=%d op=%d rows=%d cols=%d",
                      cid, src_id, dst_id, op_id, rows, cols);
        if (got != 6) begin
          continue;
        end
        if (cid < 0 || cid >= CASES) begin
          $fatal(1, "case id out of range in input file: %0d", cid);
        end
        if (case_loaded[cid]) begin
          $fatal(1, "duplicate case id in input file: %0d", cid);
        end
        if (src_id < 0 || src_id > 2 || dst_id < 0 || dst_id > 2 || op_id < 0 || op_id > 2) begin
          $fatal(1, "case %0d has invalid src/dst/op in input file", cid);
        end
        if (rows > 255 || cols > 255) begin
          $fatal(1, "case %0d rows/cols exceed 8-bit range: %0d x %0d", cid, rows, cols);
        end
        if ((rows != BASE_ROWS[cid % BASE_CASES]) || (cols != BASE_COLS[cid % BASE_CASES])) begin
          $fatal(1, "case %0d rows/cols mismatch with base list (file %0d x %0d)", cid, rows, cols);
        end
        case_loaded[cid] = 1'b1;
        case_src_id[cid] = src_id;
        case_dst_id[cid] = dst_id;
        case_op[cid] = op_id;
        case_rows[cid] = rows;
        case_cols[cid] = cols;
        case_seq[cid] = 0;
        case_cmd_id[cid] = cid[11:0];
        case_elem_count[cid] = rows * cols;
        case_word_count[cid] = ceil_div(case_elem_count[cid], FP16_PER_WORD);
        if (case_word_count[cid] > MAX_WORDS) begin
          $fatal(1, "case %0d exceeds MAX_WORDS", cid);
        end

        for (idx = 0; idx < MAX_WORDS; idx = idx + 1) begin
          pre_words[cid][idx] = '0;
          post_words[cid][idx] = '0;
        end

        idx = 0;
        for (r = 0; r < rows; r = r + 1) begin
          for (c = 0; c < cols; c = c + 1) begin
            if (c < cols - 1) begin
              got = $fscanf(fd, "%b,", val);
            end else begin
              got = $fscanf(fd, "%b", val);
            end
            if (got != 1) begin
              $fatal(1, "failed to read data for case %0d (r=%0d c=%0d)", cid, r, c);
            end
            word_idx = idx / FP16_PER_WORD;
            lane = idx % FP16_PER_WORD;
            pre_words[cid][word_idx][lane * FPW +: FPW] = val;
            idx = idx + 1;
          end
        end
      end

      $fclose(fd);

      for (cid = 0; cid < CASES; cid = cid + 1) begin
        if (!case_loaded[cid]) begin
          $fatal(1, "missing case %0d in input file", cid);
        end
      end
    end
  endtask

  task automatic build_cases;
    integer cid;
    integer src_id;
    integer dst_id;
    integer op_id;
    integer case_idx;
    integer base_int;
    integer subop;
    integer idx;
    integer word_idx;
    integer lane;
    logic [15:0] val;
    begin
      cid = 0;
      next_base_global = 0;
      next_base_local = 0;
      next_base_temp = 0;

      for (src_id = 0; src_id < 3; src_id = src_id + 1) begin
        for (dst_id = 0; dst_id < 3; dst_id = dst_id + 1) begin
          for (op_id = 0; op_id < OP_COUNT; op_id = op_id + 1) begin
            for (case_idx = 0; case_idx < BASE_CASES; case_idx = case_idx + 1) begin
              if (cid >= CASES) begin
                $fatal(1, "case table overflow while building random LUT cases");
              end

              case_src_id[cid] = src_id;
              case_dst_id[cid] = dst_id;
              case_op[cid] = op_id;
              case_rows[cid] = BASE_ROWS[case_idx];
              case_cols[cid] = BASE_COLS[case_idx];
              case_seq[cid] = 0;
              case_cmd_id[cid] = cid[11:0];
              case_elem_count[cid] = case_rows[cid] * case_cols[cid];
              case_word_count[cid] = ceil_div(case_elem_count[cid], FP16_PER_WORD);
              if (case_word_count[cid] > MAX_WORDS) begin
                $fatal(1, "case %0d exceeds MAX_WORDS", cid);
              end

              for (idx = 0; idx < MAX_WORDS; idx = idx + 1) begin
                pre_words[cid][idx] = '0;
                post_words[cid][idx] = '0;
              end

              for (idx = 0; idx < case_elem_count[cid]; idx = idx + 1) begin
                if (op_id == 2) begin
                  val = rand_fp16();
                end else begin
                  val = rand_fp16_trig_range();
                end
                word_idx = idx / FP16_PER_WORD;
                lane = idx % FP16_PER_WORD;
                pre_words[cid][word_idx][lane * FPW +: FPW] = val;
              end

              reserve_base(case_src_id[cid], case_word_count[cid], base_int);
              case_src_base[cid] = base_int[ADDR_W-1:0];
              reserve_base(case_dst_id[cid], case_word_count[cid], base_int);
              case_dst_base[cid] = base_int[ADDR_W-1:0];

              done_seen[cid] = 1'b0;

              if (case_op[cid] == 0) begin
                subop = SUB_SIN;
              end else if (case_op[cid] == 1) begin
                subop = SUB_COS;
              end else begin
                subop = SUB_SOFTPLUS;
              end

              case_cmd[cid] = make_cmd(
                case_cmd_id[cid],
                OP_LUT,
                subop[3:0],
                (cid == CASES - 1),
                pack_addr(case_src_id[cid][1:0], case_src_base[cid]),
                pack_addr(case_dst_id[cid][1:0], case_dst_base[cid]),
                13'h0,
                case_rows[cid][11:0],
                case_cols[cid][11:0],
                12'h0
              );

              cid = cid + 1;
            end
          end
        end
      end

      if (cid != CASES) begin
        $fatal(1, "built %0d cases, expected %0d", cid, CASES);
      end
    end
  endtask

  task automatic mem_write_word(
    input integer mem_id,
    input logic [ADDR_W-1:0] addr,
    input logic [SRAM_W-1:0] data
  );
    logic [14:0] local_addr;
    begin
      if (mem_id == MEM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
      if (mem_id == MEM_LOCAL0 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
      if (mem_id == MEM_TEMP0 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
      if ((mem_id == MEM_TRIG_SIN_EVEN || mem_id == MEM_TRIG_SIN_ODD ||
           mem_id == MEM_TRIG_COS_EVEN || mem_id == MEM_TRIG_COS_ODD) && addr >= 128)
        $fatal(1, "Trig LUT addr overflow");
      if ((mem_id == MEM_SOFT_EVEN || mem_id == MEM_SOFT_ODD) && addr >= 256)
        $fatal(1, "Softplus LUT addr overflow");
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
      if (mem_id == MEM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
      if (mem_id == MEM_LOCAL0 && addr >= LOCAL_DEPTH) $fatal(1, "Local SRAM addr overflow");
      if (mem_id == MEM_TEMP0 && addr >= TEMP_DEPTH) $fatal(1, "Temp SRAM addr overflow");
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

  task automatic init_trig_lut;
    integer idx;
    logic [SRAM_W-1:0] word;
    begin
      for (idx = 0; idx < TRIG_TOTAL_WORDS; idx = idx + 1) begin
        word = '0;
        word[15:0] = trig_mem[idx];
        if (idx < TRIG_BANK_DEPTH) begin
          mem_write_word(MEM_TRIG_SIN_EVEN, idx, word);
        end else if (idx < (2 * TRIG_BANK_DEPTH)) begin
          mem_write_word(MEM_TRIG_SIN_ODD, idx - TRIG_BANK_DEPTH, word);
        end else if (idx < (3 * TRIG_BANK_DEPTH)) begin
          mem_write_word(MEM_TRIG_COS_EVEN, idx - (2 * TRIG_BANK_DEPTH), word);
        end else begin
          mem_write_word(MEM_TRIG_COS_ODD, idx - (3 * TRIG_BANK_DEPTH), word);
        end
      end
    end
  endtask

  task automatic init_softplus_lut;
    integer idx;
    logic [SRAM_W-1:0] word;
    begin
      for (idx = 0; idx < SOFTPLUS_TOTAL_WORDS; idx = idx + 1) begin
        word = '0;
        word[31:0] = soft_mem[idx];
        if (idx < SOFTPLUS_BANK_DEPTH) begin
          mem_write_word(MEM_SOFT_EVEN, idx, word);
        end else begin
          mem_write_word(MEM_SOFT_ODD, idx - SOFTPLUS_BANK_DEPTH, word);
        end
      end
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
            mem_write_word(case_dst_id[cid], case_dst_base[cid] + w, {SRAM_W{1'b0}});
          end
        end
        for (w = 0; w < case_word_count[cid]; w = w + 1) begin
          mem_write_word(case_src_id[cid], case_src_base[cid] + w, pre_words[cid][w]);
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
    input integer      cid,
    input integer      seq_id,
    input logic [7:0]  req_id,
    input logic [ADDR_W-1:0] base_addr,
    input logic [15:0] rows,
    input logic [15:0] cols,
    input logic [15:0] words,
    input logic        done
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
        mem_read_word_1cycle(case_dst_id[cid], case_dst_base[cid] + w, rd_word);
        post_words[cid][w] = rd_word;
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

  task automatic push_cmd(input logic [95:0] cmd);
    begin
      wait_fifo_space();
      @(negedge clock);
      cmdWord_0_0 <= cmd[31:0];
      cmdWord_0_1 <= cmd[63:32];
      cmdWord_0_2 <= cmd[95:64];
      cmdCtrl_0   <= 32'h1;
      @(negedge clock);
      cmdCtrl_0   <= 32'h0;
    end
  endtask

  task automatic push_all_cmds;
    integer cid;
    begin
      for (cid = 0; cid < CASES; cid = cid + 1) begin
        push_cmd(case_cmd[cid]);
      end
    end
  endtask

  always @(posedge clock) begin
    logic [11:0] done_cmd_id;
    logic [2:0]  done_opcode;
    logic [3:0]  done_subop;
    logic        done_group_end;
    logic        done_illegal;
    integer      expect_subop;
    integer      done_cid;
    if (reset) begin
      done_count <= 0;
      expected_done <= 0;
      last_done_count <= 0;
    end else begin
      if (cmdStatus_0[5] === 1'b1) begin
        $fatal(1, "cmdStatus overflow set (fifo push while full)");
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
        done_cid = done_cmd_id;

        if (done_illegal) begin
          $fatal(1, "illegal command reported in lastDone");
        end
        if (done_cmd_id !== expected_done[11:0]) begin
          $fatal(1, "doneCmdId out of order: got %0d expected %0d", done_cmd_id, expected_done);
        end
        if (done_opcode !== OP_LUT) begin
          $fatal(1, "done opcode mismatch: opcode=%0b", done_opcode);
        end
        if (case_op[done_cid] == 0) begin
          expect_subop = SUB_SIN;
        end else if (case_op[done_cid] == 1) begin
          expect_subop = SUB_COS;
        end else begin
          expect_subop = SUB_SOFTPLUS;
        end
        if (done_subop !== expect_subop[3:0]) begin
          $fatal(1, "done subop mismatch for case %0d: got %0h expected %0h",
                 done_cid, done_subop, expect_subop[3:0]);
        end
        if (done_group_end !== (expected_done == CASES - 1)) begin
          $fatal(1, "done group_end mismatch for cmd_id=%0d", done_cmd_id);
        end
        done_seen[done_cmd_id] <= 1'b1;
        done_count <= done_count + 1;
        expected_done <= expected_done + 1;
        last_done_count <= doneCount_0;
      end
    end
  end

  initial begin
    integer cid;
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

    csv_lock = new(1);

    mkdir_ret = $system("mkdir -p verification/results/core_top/lut");
    in_csv_fd = $fopen("verification/results/core_top/lut/tb_core_top_lut_input.csv", "w");
    if (in_csv_fd == 0) begin
      $fatal(1, "failed to open verification/results/core_top/lut/tb_core_top_lut_input.csv");
    end
    out_csv_fd = $fopen("verification/results/core_top/lut/tb_core_top_lut_output.csv", "w");
    if (out_csv_fd == 0) begin
      $fatal(1, "failed to open verification/results/core_top/lut/tb_core_top_lut_output.csv");
    end

    write_input_header();
    write_output_header();

    $readmemh("rtl/chisel/top_connect/src/lut/tools/trig_data.hex", trig_mem);
    $readmemh("rtl/chisel/top_connect/src/lut/tools/softplus_data.hex", soft_mem);

    build_cases();
    for (cid = 0; cid < CASES; cid = cid + 1) begin
      write_input_line(cid);
    end

    repeat (4) @(posedge clock);
    preload_cases_to_sram();

    repeat (4) @(posedge clock);
    init_trig_lut();
    init_softplus_lut();

    repeat (4) @(posedge clock);
    reset = 1'b0;
    repeat (2) @(posedge clock);

    push_all_cmds();

    cycles = 0;
    while ((done_count < CASES) && (cycles < TIMEOUT_CYCLES)) begin
      @(posedge clock);
      cycles = cycles + 1;
    end
    if (done_count < CASES) begin
      $fatal(1, "timeout waiting for done_count=%0d (got %0d)", CASES, done_count);
    end

    repeat (4) @(posedge clock);
    for (cid = 0; cid < CASES; cid = cid + 1) begin
      if (!done_seen[cid]) begin
        $fatal(1, "Missing done for case %0d", cid);
      end
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
        done_seen[cid]
      );
      csv_lock.put(1);
    end

    $fclose(in_csv_fd);
    $fclose(out_csv_fd);
    repeat (5) @(posedge clock);
    $finish;
  end

  initial begin
    #5000000000;
    $fatal(1, "simulation timeout");
  end
endmodule
