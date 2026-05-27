`timescale 1ns/1ps

module tb_core_top_macarray;

  localparam int CLK_PERIOD_NS = 10;
  localparam int GLOBAL_DEPTH = 2048;
  localparam int LOCAL_DEPTH = 512;
  localparam int TEMP_DEPTH = 896;
  localparam int ADDR_W = 11;
  localparam int GLOBAL_ADDR_W = 11;
  localparam int LOCAL_ADDR_W = 9;
  localparam int TEMP_ADDR_W = 10;
  localparam int DATA_W = 128;
  localparam int FPW = 16;
  localparam int LANES = DATA_W / FPW;
  localparam int MAX_DIM = 32;
  localparam int CASES = 10;
  localparam int COMBOS = 9;
  localparam int POOL_SIZE = 96;

  localparam int SRAM_GLOBAL = 0;
  localparam int SRAM_LOCAL  = 1;
  localparam int SRAM_TEMP   = 2;

  localparam int OP_GEMM = 0;
  localparam int OP_MUL  = 1;
  localparam int OP_ADD  = 2;
  localparam int OPS = 6;
  localparam int MAX_CMDS = CASES * COMBOS * OPS;
  localparam int TIMEOUT_CYCLES = 400000;

  localparam logic [2:0] OP_LA = 3'b011;
  localparam logic [3:0] SUB_GEMM = 4'h0;
  localparam logic [3:0] SUB_MUL  = 4'h1;
  localparam logic [3:0] SUB_ADD  = 4'h2;

  logic clock;
  logic reset;
  logic use_dut_port;

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

  logic [14:0]  buf_addr;
  logic         buf_enable;
  logic         buf_isWrite;
  logic [127:0] buf_readData;
  logic [127:0] buf_writeData;
  logic [127:0] buf_bweb;

  logic        cmdIn_valid;
  logic        cmdIn_ready;
  logic [95:0] cmdIn_bits;

  logic        fifoFull;
  logic        fifoEmpty;
  logic [5:0]  fifoCount;

  logic        cmdSeq_busy;
  logic        cmdSeq_idle;
  logic        activeValid;
  logic [11:0] activeCmdId;
  logic [2:0]  activeOpcode;
  logic [3:0]  activeSubop;
  logic        activeGroupEnd;
  logic [1:0]  activeAddr0SramId;
  logic [1:0]  activeAddr1SramId;
  logic [1:0]  activeAddr2SramId;
  logic [10:0] activeAddr0Word;
  logic [10:0] activeAddr1Word;
  logic [10:0] activeAddr2Word;

  logic        doneValid;
  logic [11:0] doneCmdId;
  logic [2:0]  doneOpcode;
  logic [3:0]  doneSubop;
  logic        doneGroupEnd;

  logic        illegalCmd;
  logic [11:0] illegalCmdId;

  logic [15:0] addReduceValue;
  logic [11:0] addReduceCmdId;
  logic        addReduceValid;
  logic [15:0] cmpReduceValue;
  logic [11:0] cmpReduceIndex;
  logic [11:0] cmpReduceCmdId;
  logic        cmpReduceValid;

  logic        absCmdReq_valid;
  logic        absCmdReq_ready;
  logic [1:0]  absCmdReq_srcSramId;
  logic [1:0]  absCmdReq_dstSramId;
  logic [10:0] absCmdReq_srcBase;
  logic [10:0] absCmdReq_dstBase;
  logic [11:0] absCmdReq_rows;
  logic [11:0] absCmdReq_cols;
  logic [11:0] absCmdReq_reqId;

  logic        absCmdRsp_valid;
  logic        absCmdRsp_ready;
  logic [11:0] absCmdRsp_reqId;
  logic [1:0]  absCmdRsp_srcSramId;
  logic [1:0]  absCmdRsp_dstSramId;
  logic [10:0] absCmdRsp_srcBase;
  logic [10:0] absCmdRsp_dstBase;
  logic [11:0] absCmdRsp_rows;
  logic [11:0] absCmdRsp_cols;
  logic        absCmdRsp_done;

  logic        reduceCmdReq_valid;
  logic        reduceCmdReq_ready;
  logic        reduceCmdReq_mode;
  logic [1:0]  reduceCmdReq_srcSramId;
  logic [10:0] reduceCmdReq_baseAddr;
  logic [11:0] reduceCmdReq_elemCount;
  logic [11:0] reduceCmdReq_reqId;

  logic        reduceCmdRsp_ready;
  logic        reduceCmdRsp_valid;
  logic [11:0] reduceCmdRsp_reqId;
  logic        reduceCmdRsp_mode;
  logic [1:0]  reduceCmdRsp_srcSramId;
  logic [10:0] reduceCmdRsp_baseAddr;
  logic [11:0] reduceCmdRsp_elemCount;
  logic [15:0] reduceCmdRsp_resultValue;
  logic [11:0] reduceCmdRsp_resultIndex;

  logic        lutCmdReq_valid;
  logic        lutCmdReq_ready;
  logic [1:0]  lutCmdReq_funcSel;
  logic [1:0]  lutCmdReq_trigSel;
  logic [1:0]  lutCmdReq_srcSramId;
  logic [1:0]  lutCmdReq_dstSramId;
  logic [10:0] lutCmdReq_srcBase;
  logic [10:0] lutCmdReq_dstBase;
  logic [11:0] lutCmdReq_rows;
  logic [11:0] lutCmdReq_cols;

  logic        lutCmdRsp_ready;
  logic        lutCmdRsp_valid;
  logic        lutCmdRsp_done;

  logic        dataLayoutCmdReq_valid;
  logic        dataLayoutCmdReq_ready;
  logic        dataLayoutCmdReq_mode;
  logic [1:0]  dataLayoutCmdReq_srcSramId;
  logic [1:0]  dataLayoutCmdReq_dstSramId;
  logic [10:0] dataLayoutCmdReq_srcBase;
  logic [11:0] dataLayoutCmdReq_srcRows;
  logic [11:0] dataLayoutCmdReq_srcCols;
  logic [10:0] dataLayoutCmdReq_dstBase;
  logic [11:0] dataLayoutCmdReq_dstRows;
  logic [11:0] dataLayoutCmdReq_dstCols;
  logic [11:0] dataLayoutCmdReq_offsetRow;
  logic [11:0] dataLayoutCmdReq_offsetCol;
  logic [11:0] dataLayoutCmdReq_reqId;

  logic        dataLayoutCmdRsp_ready;
  logic        dataLayoutCmdRsp_valid;
  logic        dataLayoutCmdRsp_mode;
  logic [1:0]  dataLayoutCmdRsp_srcSramId;
  logic [1:0]  dataLayoutCmdRsp_dstSramId;
  logic [10:0] dataLayoutCmdRsp_srcBase;
  logic [11:0] dataLayoutCmdRsp_srcRows;
  logic [11:0] dataLayoutCmdRsp_srcCols;
  logic [10:0] dataLayoutCmdRsp_dstBase;
  logic [11:0] dataLayoutCmdRsp_dstRows;
  logic [11:0] dataLayoutCmdRsp_dstCols;
  logic [11:0] dataLayoutCmdRsp_offsetRow;
  logic [11:0] dataLayoutCmdRsp_offsetCol;
  logic [11:0] dataLayoutCmdRsp_reqId;
  logic        dataLayoutCmdRsp_done;

  logic [1:0]  mac_opSel;
  logic        mac_start;
  logic [11:0] mac_nRows;
  logic [11:0] mac_mCols;
  logic [11:0] mac_kDim;
  logic [15:0] mac_alpha;
  logic [10:0] mac_baseA;
  logic [10:0] mac_baseB;
  logic [10:0] mac_baseC;
  logic [1:0]  mac_baseASramId;
  logic [1:0]  mac_baseBSramId;
  logic [1:0]  mac_baseCSramId;
  logic        mac_busy;
  logic        mac_done;

  logic                   dut_global_enable;
  logic [GLOBAL_ADDR_W-1:0] dut_global_addr;
  logic                   dut_global_write;
  logic [DATA_W-1:0]      dut_global_dataIn;
  logic [DATA_W-1:0]      dut_global_dataOut;
  logic [DATA_W-1:0]      dut_global_bweb;

  logic                   dut_local_enable;
  logic [LOCAL_ADDR_W-1:0] dut_local_addr;
  logic                   dut_local_write;
  logic [DATA_W-1:0]      dut_local_dataIn;
  logic [DATA_W-1:0]      dut_local_dataOut;
  logic [DATA_W-1:0]      dut_local_bweb;

  logic                   dut_temp_enable;
  logic [TEMP_ADDR_W-1:0] dut_temp_addr;
  logic                   dut_temp_write;
  logic [DATA_W-1:0]      dut_temp_dataIn;
  logic [DATA_W-1:0]      dut_temp_dataOut;
  logic [DATA_W-1:0]      dut_temp_bweb;

  logic                   tb_global_enable;
  logic [GLOBAL_ADDR_W-1:0] tb_global_addr;
  logic                   tb_global_write;
  logic [DATA_W-1:0]      tb_global_dataIn;
  logic [DATA_W-1:0]      tb_global_dataOut;
  logic [DATA_W-1:0]      tb_global_bweb;

  logic                   tb_local_enable;
  logic [LOCAL_ADDR_W-1:0] tb_local_addr;
  logic                   tb_local_write;
  logic [DATA_W-1:0]      tb_local_dataIn;
  logic [DATA_W-1:0]      tb_local_dataOut;
  logic [DATA_W-1:0]      tb_local_bweb;

  logic                   tb_temp_enable;
  logic [TEMP_ADDR_W-1:0] tb_temp_addr;
  logic                   tb_temp_write;
  logic [DATA_W-1:0]      tb_temp_dataIn;
  logic [DATA_W-1:0]      tb_temp_dataOut;
  logic [DATA_W-1:0]      tb_temp_bweb;

  logic                   global_mem_enable;
  logic [GLOBAL_ADDR_W-1:0] global_mem_addr;
  logic                   global_mem_write;
  logic [DATA_W-1:0]      global_mem_dataIn;
  logic [DATA_W-1:0]      global_mem_dataOut;
  logic [DATA_W-1:0]      global_mem_bweb;

  logic                   local_mem_enable;
  logic [LOCAL_ADDR_W-1:0] local_mem_addr;
  logic                   local_mem_write;
  logic [DATA_W-1:0]      local_mem_dataIn;
  logic [DATA_W-1:0]      local_mem_dataOut;
  logic [DATA_W-1:0]      local_mem_bweb;

  logic                   temp_mem_enable;
  logic [TEMP_ADDR_W-1:0] temp_mem_addr;
  logic                   temp_mem_write;
  logic [DATA_W-1:0]      temp_mem_dataIn;
  logic [DATA_W-1:0]      temp_mem_dataOut;
  logic [DATA_W-1:0]      temp_mem_bweb;

  logic [15:0] matA [0:MAX_DIM-1][0:MAX_DIM-1];
  logic [15:0] matB [0:MAX_DIM-1][0:MAX_DIM-1];
  logic [15:0] matC [0:MAX_DIM-1][0:MAX_DIM-1];
  logic [15:0] vecA [0:MAX_DIM-1];
  logic [15:0] vecB [0:MAX_DIM-1];
  logic [15:0] vecC [0:MAX_DIM-1];
  logic [15:0] fp_pool [0:POOL_SIZE-1];

  int fd_gemm_in;
  int fd_gemm_out;
  int fd_gemv_in;
  int fd_gemv_out;
  int fd_dot_in;
  int fd_dot_out;
  int fd_outer_in;
  int fd_outer_out;
  int fd_mul_in;
  int fd_mul_out;
  int fd_add_in;
  int fd_add_out;

  int case_id;
  string out_dir;
  logic [3:0] exp_subop [0:MAX_CMDS-1];
  integer next_cmd_id;
  integer expected_done;
  integer done_count;
  logic [31:0] last_done_count;

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

  GlobalSram u_global_mem (
    .clock     (clock),
    .io_enable (global_mem_enable),
    .io_addr   (global_mem_addr),
    .io_write  (global_mem_write),
    .io_dataIn (global_mem_dataIn),
    .io_dataOut(global_mem_dataOut),
    .io_bweb   (global_mem_bweb)
  );

  LocalSram u_local_mem (
    .clock     (clock),
    .io_enable (local_mem_enable),
    .io_addr   (local_mem_addr),
    .io_write  (local_mem_write),
    .io_dataIn (local_mem_dataIn),
    .io_dataOut(local_mem_dataOut),
    .io_bweb   (local_mem_bweb)
  );

  TempBuffer u_temp_mem (
    .clock     (clock),
    .io_enable (temp_mem_enable),
    .io_addr   (temp_mem_addr),
    .io_write  (temp_mem_write),
    .io_dataIn (temp_mem_dataIn),
    .io_dataOut(temp_mem_dataOut),
    .io_bweb   (temp_mem_bweb)
  );

  assign global_mem_enable = use_dut_port ? dut_global_enable : tb_global_enable;
  assign global_mem_addr   = use_dut_port ? dut_global_addr   : tb_global_addr;
  assign global_mem_write  = use_dut_port ? dut_global_write  : tb_global_write;
  assign global_mem_dataIn = use_dut_port ? dut_global_dataIn : tb_global_dataIn;
  assign global_mem_bweb   = use_dut_port ? dut_global_bweb   : tb_global_bweb;
  assign dut_global_dataOut = global_mem_dataOut;
  assign tb_global_dataOut  = global_mem_dataOut;

  assign local_mem_enable = use_dut_port ? dut_local_enable : tb_local_enable;
  assign local_mem_addr   = use_dut_port ? dut_local_addr   : tb_local_addr;
  assign local_mem_write  = use_dut_port ? dut_local_write  : tb_local_write;
  assign local_mem_dataIn = use_dut_port ? dut_local_dataIn : tb_local_dataIn;
  assign local_mem_bweb   = use_dut_port ? dut_local_bweb   : tb_local_bweb;
  assign dut_local_dataOut = local_mem_dataOut;
  assign tb_local_dataOut  = local_mem_dataOut;

  assign temp_mem_enable = use_dut_port ? dut_temp_enable : tb_temp_enable;
  assign temp_mem_addr   = use_dut_port ? dut_temp_addr   : tb_temp_addr;
  assign temp_mem_write  = use_dut_port ? dut_temp_write  : tb_temp_write;
  assign temp_mem_dataIn = use_dut_port ? dut_temp_dataIn : tb_temp_dataIn;
  assign temp_mem_bweb   = use_dut_port ? dut_temp_bweb   : tb_temp_bweb;
  assign dut_temp_dataOut = temp_mem_dataOut;
  assign tb_temp_dataOut  = temp_mem_dataOut;

  assign absCmdReq_ready = 1'b1;
  assign absCmdRsp_valid = 1'b0;
  assign absCmdRsp_reqId = '0;
  assign absCmdRsp_srcSramId = 2'b0;
  assign absCmdRsp_dstSramId = 2'b0;
  assign absCmdRsp_srcBase = '0;
  assign absCmdRsp_dstBase = '0;
  assign absCmdRsp_rows = '0;
  assign absCmdRsp_cols = '0;
  assign absCmdRsp_done = 1'b0;

  assign reduceCmdReq_ready = 1'b1;
  assign reduceCmdRsp_valid = 1'b0;
  assign reduceCmdRsp_reqId = '0;
  assign reduceCmdRsp_mode = 1'b0;
  assign reduceCmdRsp_srcSramId = 2'b0;
  assign reduceCmdRsp_baseAddr = '0;
  assign reduceCmdRsp_elemCount = '0;
  assign reduceCmdRsp_resultValue = '0;
  assign reduceCmdRsp_resultIndex = '0;

  assign lutCmdReq_ready = 1'b1;
  assign lutCmdRsp_valid = 1'b0;
  assign lutCmdRsp_done = 1'b0;

  assign dataLayoutCmdReq_ready = 1'b1;
  assign dataLayoutCmdRsp_valid = 1'b0;
  assign dataLayoutCmdRsp_mode = 1'b0;
  assign dataLayoutCmdRsp_srcSramId = 2'b0;
  assign dataLayoutCmdRsp_dstSramId = 2'b0;
  assign dataLayoutCmdRsp_srcBase = '0;
  assign dataLayoutCmdRsp_srcRows = '0;
  assign dataLayoutCmdRsp_srcCols = '0;
  assign dataLayoutCmdRsp_dstBase = '0;
  assign dataLayoutCmdRsp_dstRows = '0;
  assign dataLayoutCmdRsp_dstCols = '0;
  assign dataLayoutCmdRsp_offsetRow = '0;
  assign dataLayoutCmdRsp_offsetCol = '0;
  assign dataLayoutCmdRsp_reqId = '0;
  assign dataLayoutCmdRsp_done = 1'b0;

  always #(CLK_PERIOD_NS/2) clock = ~clock;

  function automatic logic [15:0] pick_fp(input integer seed);
    integer idx;
    begin
      idx = seed % POOL_SIZE;
      if (idx < 0) idx = idx + POOL_SIZE;
      pick_fp = fp_pool[idx];
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
    input int mem_id,
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
        SRAM_LOCAL: begin
          mem_sel = 4'h1;
          word_sel = {2'b0, word_idx[8:0]};
        end
        SRAM_TEMP: begin
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

  task automatic tb_idle_ports;
    begin
      tb_global_enable <= 1'b0;
      tb_global_write  <= 1'b0;
      tb_global_addr   <= '0;
      tb_global_dataIn <= '0;
      tb_global_bweb   <= {DATA_W{1'b1}};

      tb_local_enable <= 1'b0;
      tb_local_write  <= 1'b0;
      tb_local_addr   <= '0;
      tb_local_dataIn <= '0;
      tb_local_bweb   <= {DATA_W{1'b1}};

      tb_temp_enable <= 1'b0;
      tb_temp_write  <= 1'b0;
      tb_temp_addr   <= '0;
      tb_temp_dataIn <= '0;
      tb_temp_bweb   <= {DATA_W{1'b1}};

      buf_addr      <= '0;
      buf_enable    <= 1'b0;
      buf_isWrite   <= 1'b0;
      buf_writeData <= '0;
      buf_bweb      <= {DATA_W{1'b1}};
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

  task automatic mem_write_global(
    input logic [GLOBAL_ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_global_enable <= 1'b1;
      tb_global_write  <= 1'b1;
      tb_global_addr   <= addr;
      tb_global_dataIn <= data;
      tb_global_bweb   <= {DATA_W{1'b0}};
      @(negedge clock);
      tb_global_enable <= 1'b0;
      tb_global_write  <= 1'b0;
      tb_global_addr   <= '0;
      tb_global_dataIn <= '0;
      tb_global_bweb   <= {DATA_W{1'b1}};
    end
  endtask

  task automatic mem_write_local(
    input logic [LOCAL_ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_local_enable <= 1'b1;
      tb_local_write  <= 1'b1;
      tb_local_addr   <= addr;
      tb_local_dataIn <= data;
      tb_local_bweb   <= {DATA_W{1'b0}};
      @(negedge clock);
      tb_local_enable <= 1'b0;
      tb_local_write  <= 1'b0;
      tb_local_addr   <= '0;
      tb_local_dataIn <= '0;
      tb_local_bweb   <= {DATA_W{1'b1}};
    end
  endtask

  task automatic mem_write_temp(
    input logic [TEMP_ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_temp_enable <= 1'b1;
      tb_temp_write  <= 1'b1;
      tb_temp_addr   <= addr;
      tb_temp_dataIn <= data;
      tb_temp_bweb   <= {DATA_W{1'b0}};
      @(negedge clock);
      tb_temp_enable <= 1'b0;
      tb_temp_write  <= 1'b0;
      tb_temp_addr   <= '0;
      tb_temp_dataIn <= '0;
      tb_temp_bweb   <= {DATA_W{1'b1}};
    end
  endtask

  task automatic mem_read_global_1cycle(
    input  logic [GLOBAL_ADDR_W-1:0] addr,
    output logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_global_enable <= 1'b1;
      tb_global_write  <= 1'b0;
      tb_global_addr   <= addr;
      tb_global_dataIn <= '0;
      tb_global_bweb   <= {DATA_W{1'b1}};
      @(negedge clock);
      data = tb_global_dataOut;
      tb_global_enable <= 1'b0;
      tb_global_addr   <= '0;
    end
  endtask

  task automatic mem_read_local_1cycle(
    input  logic [LOCAL_ADDR_W-1:0] addr,
    output logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_local_enable <= 1'b1;
      tb_local_write  <= 1'b0;
      tb_local_addr   <= addr;
      tb_local_dataIn <= '0;
      tb_local_bweb   <= {DATA_W{1'b1}};
      @(negedge clock);
      data = tb_local_dataOut;
      tb_local_enable <= 1'b0;
      tb_local_addr   <= '0;
    end
  endtask

  task automatic mem_read_temp_1cycle(
    input  logic [TEMP_ADDR_W-1:0] addr,
    output logic [DATA_W-1:0] data
  );
    begin
      @(negedge clock);
      tb_temp_enable <= 1'b1;
      tb_temp_write  <= 1'b0;
      tb_temp_addr   <= addr;
      tb_temp_dataIn <= '0;
      tb_temp_bweb   <= {DATA_W{1'b1}};
      @(negedge clock);
      data = tb_temp_dataOut;
      tb_temp_enable <= 1'b0;
      tb_temp_addr   <= '0;
    end
  endtask

  task automatic mem_write_fullword(
    input int sram_id,
    input int addr,
    input logic [DATA_W-1:0] data
  );
    begin
      if (sram_id == SRAM_GLOBAL && addr >= GLOBAL_DEPTH) $fatal(1, "Global SRAM addr overflow");
      if (sram_id == SRAM_LOCAL  && addr >= LOCAL_DEPTH)  $fatal(1, "Local SRAM addr overflow");
      if (sram_id == SRAM_TEMP   && addr >= TEMP_DEPTH)   $fatal(1, "Temp SRAM addr overflow");

      @(negedge clock);
      buf_enable    <= 1'b1;
      buf_isWrite   <= 1'b1;
      buf_addr      <= pack_buf_addr(sram_id, addr[ADDR_W-1:0]);
      buf_writeData <= data;
      buf_bweb      <= {DATA_W{1'b0}};

      @(negedge clock);
      buf_enable    <= 1'b0;
      buf_isWrite   <= 1'b0;
      buf_addr      <= '0;
      buf_writeData <= '0;
      buf_bweb      <= {DATA_W{1'b1}};
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

      @(negedge clock);
      buf_enable    <= 1'b1;
      buf_isWrite   <= 1'b0;
      buf_addr      <= pack_buf_addr(sram_id, addr[ADDR_W-1:0]);
      buf_writeData <= '0;
      buf_bweb      <= {DATA_W{1'b1}};

      @(negedge clock);
      data = buf_readData;
      buf_enable    <= 1'b0;
      buf_addr      <= '0;
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

  task automatic wait_for_done_count(input integer target);
    integer cycles;
    begin
      cycles = 0;
      while (done_count < target) begin
        @(posedge clock);
        cycles = cycles + 1;
        if (cycles > TIMEOUT_CYCLES) begin
          $fatal(1, "Timeout waiting for done_count %0d (now %0d)", target, done_count);
        end
      end
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

  always @(posedge clock) begin
    logic [11:0] done_cmd_id;
    logic [2:0]  done_opcode;
    logic [3:0]  done_subop;
    logic        done_group_end;
    logic        done_illegal;
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

        if (done_illegal) begin
          $fatal(1, "illegal command reported in lastDone");
        end
        if (done_cmd_id !== expected_done[11:0]) begin
          $fatal(1, "doneCmdId out of order: got %0d expected %0d", done_cmd_id, expected_done);
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
        done_count <= done_count + 1;
        expected_done <= expected_done + 1;
        last_done_count <= doneCount_0;
      end
    end
  end

  initial begin
    clock = 1'b0;
    reset = 1'b1;
    use_dut_port = 1'b0;
    cmdIn_valid = 1'b0;
    cmdIn_bits = '0;
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
    next_cmd_id = 0;
    expected_done = 0;
    done_count = 0;
    last_done_count = 0;
    tb_idle_ports();
    init_pool();

    $fsdbDumpfile("tb_core_top_macarray.fsdb");
    $fsdbDumpvars(0, tb_core_top_macarray);

    out_dir = "verification/results/core_top/macarray";
    $system("mkdir -p verification/results/core_top/macarray");

    fd_gemm_in   = $fopen({out_dir, "/tb_core_top_macarray_gemm_input.csv"}, "w");
    fd_gemm_out  = $fopen({out_dir, "/tb_core_top_macarray_gemm_output.csv"}, "w");
    fd_gemv_in   = $fopen({out_dir, "/tb_core_top_macarray_gemv_input.csv"}, "w");
    fd_gemv_out  = $fopen({out_dir, "/tb_core_top_macarray_gemv_output.csv"}, "w");
    fd_dot_in    = $fopen({out_dir, "/tb_core_top_macarray_gevv_dot_input.csv"}, "w");
    fd_dot_out   = $fopen({out_dir, "/tb_core_top_macarray_gevv_dot_output.csv"}, "w");
    fd_outer_in  = $fopen({out_dir, "/tb_core_top_macarray_gevv_outer_input.csv"}, "w");
    fd_outer_out = $fopen({out_dir, "/tb_core_top_macarray_gevv_outer_output.csv"}, "w");
    fd_mul_in    = $fopen({out_dir, "/tb_core_top_macarray_mul_input.csv"}, "w");
    fd_mul_out   = $fopen({out_dir, "/tb_core_top_macarray_mul_output.csv"}, "w");
    fd_add_in    = $fopen({out_dir, "/tb_core_top_macarray_add_input.csv"}, "w");
    fd_add_out   = $fopen({out_dir, "/tb_core_top_macarray_add_output.csv"}, "w");

    if (fd_gemm_in == 0 || fd_gemm_out == 0 ||
        fd_gemv_in == 0 || fd_gemv_out == 0 ||
        fd_dot_in == 0 || fd_dot_out == 0 ||
        fd_outer_in == 0 || fd_outer_out == 0 ||
        fd_mul_in == 0 || fd_mul_out == 0 ||
        fd_add_in == 0 || fd_add_out == 0) begin
      $fatal(1, "failed to open result csv files");
    end

    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (2) @(posedge clock);

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
          issue_gemm_cmd(N, M, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
          issue_gemm_cmd(N, 1, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
          issue_gemm_cmd(1, 1, K, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
          issue_gemm_cmd(N, M, 1, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? wordsA : 0;
          issue_mul_cmd(N, M, alpha, baseA, baseC, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

        use_dut_port = 1'b0;
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
        use_dut_port = 1'b1;
        done_target = done_count + 3;
        for (out_id = 0; out_id < 3; out_id++) begin
          baseC = (in_id == out_id) ? (baseB + wordsB) : 0;
          issue_add_cmd(N, M, baseA, baseB, baseC, in_id, in_id, out_id, (out_id == 2));
        end
        wait_for_done_count(done_target);
        @(posedge clock);
        use_dut_port = 1'b0;

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

    repeat (6) @(posedge clock);
    $finish;
  end

endmodule

