module SSlaveTxAppLayer(
  output        io_appInAXI4R_ready,
  input         io_appInAXI4R_valid,
  input  [63:0] io_appInAXI4R_bits_data,
  input         io_appInAXI4R_bits_last,
  input  [4:0]  io_appInAXI4R_bits_id,
  input  [1:0]  io_appInAXI4R_bits_resp,
  output        io_appInAXI4B_ready,
  input         io_appInAXI4B_valid,
  input  [4:0]  io_appInAXI4B_bits_id,
  input  [1:0]  io_appInAXI4B_bits_resp,
  input         io_appOutAXI4R_ready,
  output        io_appOutAXI4R_valid,
  output [71:0] io_appOutAXI4R_bits,
  input         io_appOutAXI4B_ready,
  output        io_appOutAXI4B_valid,
  output [6:0]  io_appOutAXI4B_bits
);
  wire [64:0] readData_bits_lo = {io_appInAXI4R_bits_last,io_appInAXI4R_bits_data}; // @[Cat.scala 33:92]
  wire [6:0] readData_bits_hi = {io_appInAXI4R_bits_id,io_appInAXI4R_bits_resp}; // @[Cat.scala 33:92]
  assign io_appInAXI4R_ready = io_appOutAXI4R_ready; // @[AppLayer.scala 15:22 24:18]
  assign io_appInAXI4B_ready = io_appOutAXI4B_ready; // @[AppLayer.scala 26:23 33:18]
  assign io_appOutAXI4R_valid = io_appInAXI4R_valid; // @[AppLayer.scala 15:22 16:18]
  assign io_appOutAXI4R_bits = {readData_bits_hi,readData_bits_lo}; // @[Cat.scala 33:92]
  assign io_appOutAXI4B_valid = io_appInAXI4B_ready & io_appInAXI4B_valid; // @[Decoupled.scala 52:35]
  assign io_appOutAXI4B_bits = {io_appInAXI4B_bits_id,io_appInAXI4B_bits_resp}; // @[Cat.scala 33:92]
endmodule
module SAsyncFifoMemory(
  input         wr_clock,
  input         wr_en,
  input  [3:0]  wr_addr,
  input  [71:0] wr_data,
  input         rd_clock,
  input         rd_en,
  input  [3:0]  rd_addr,
  output [71:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [95:0] _RAND_2;
  reg [95:0] _RAND_3;
  reg [95:0] _RAND_4;
  reg [95:0] _RAND_5;
  reg [95:0] _RAND_6;
  reg [95:0] _RAND_7;
  reg [95:0] _RAND_8;
  reg [95:0] _RAND_9;
  reg [95:0] _RAND_10;
  reg [95:0] _RAND_11;
  reg [95:0] _RAND_12;
  reg [95:0] _RAND_13;
  reg [95:0] _RAND_14;
  reg [95:0] _RAND_15;
  reg [95:0] _RAND_16;
`endif // RANDOMIZE_REG_INIT
  reg [71:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_4; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_5; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_6; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_7; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_8; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_9; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_10; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_11; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_12; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_13; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_14; // @[AsyncFifo.scala 43:18]
  reg [71:0] mem_15; // @[AsyncFifo.scala 43:18]
  reg [71:0] rd_data_r; // @[Reg.scala 19:16]
  wire [71:0] _GEN_33 = 4'h1 == rd_addr ? mem_1 : mem_0; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_34 = 4'h2 == rd_addr ? mem_2 : _GEN_33; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_35 = 4'h3 == rd_addr ? mem_3 : _GEN_34; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_36 = 4'h4 == rd_addr ? mem_4 : _GEN_35; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_37 = 4'h5 == rd_addr ? mem_5 : _GEN_36; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_38 = 4'h6 == rd_addr ? mem_6 : _GEN_37; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_39 = 4'h7 == rd_addr ? mem_7 : _GEN_38; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_40 = 4'h8 == rd_addr ? mem_8 : _GEN_39; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_41 = 4'h9 == rd_addr ? mem_9 : _GEN_40; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_42 = 4'ha == rd_addr ? mem_10 : _GEN_41; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_43 = 4'hb == rd_addr ? mem_11 : _GEN_42; // @[Reg.scala 20:{22,22}]
  wire [71:0] _GEN_44 = 4'hc == rd_addr ? mem_12 : _GEN_43; // @[Reg.scala 20:{22,22}]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h4 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_4 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h5 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_5 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h6 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_6 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h7 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_7 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h8 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_8 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h9 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_9 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'ha == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_10 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hb == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_11 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hc == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_12 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hd == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_13 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'he == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_14 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hf == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_15 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (4'hf == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_15; // @[Reg.scala 20:22]
      end else if (4'he == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_14; // @[Reg.scala 20:22]
      end else if (4'hd == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_13; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= _GEN_44;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  mem_0 = _RAND_0[71:0];
  _RAND_1 = {3{`RANDOM}};
  mem_1 = _RAND_1[71:0];
  _RAND_2 = {3{`RANDOM}};
  mem_2 = _RAND_2[71:0];
  _RAND_3 = {3{`RANDOM}};
  mem_3 = _RAND_3[71:0];
  _RAND_4 = {3{`RANDOM}};
  mem_4 = _RAND_4[71:0];
  _RAND_5 = {3{`RANDOM}};
  mem_5 = _RAND_5[71:0];
  _RAND_6 = {3{`RANDOM}};
  mem_6 = _RAND_6[71:0];
  _RAND_7 = {3{`RANDOM}};
  mem_7 = _RAND_7[71:0];
  _RAND_8 = {3{`RANDOM}};
  mem_8 = _RAND_8[71:0];
  _RAND_9 = {3{`RANDOM}};
  mem_9 = _RAND_9[71:0];
  _RAND_10 = {3{`RANDOM}};
  mem_10 = _RAND_10[71:0];
  _RAND_11 = {3{`RANDOM}};
  mem_11 = _RAND_11[71:0];
  _RAND_12 = {3{`RANDOM}};
  mem_12 = _RAND_12[71:0];
  _RAND_13 = {3{`RANDOM}};
  mem_13 = _RAND_13[71:0];
  _RAND_14 = {3{`RANDOM}};
  mem_14 = _RAND_14[71:0];
  _RAND_15 = {3{`RANDOM}};
  mem_15 = _RAND_15[71:0];
  _RAND_16 = {3{`RANDOM}};
  rd_data_r = _RAND_16[71:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo(
  input         wr_clock,
  input         wr_reset,
  input  [71:0] wr_data,
  input         wr_push,
  output        wr_full,
  input         rd_clock,
  input         rd_reset,
  output [71:0] rd_data,
  input         rd_pop,
  output        rd_empty,
  output        rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [71:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [71:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [4:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [4:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [4:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [4:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [4:0] _GEN_4 = {{4'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [4:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [4:0] _GEN_5 = {{1'd0}, wrAddrBinNext[4:1]}; // @[AsyncFifo.scala 85:49]
  wire [4:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [4:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[4:3]; // @[AsyncFifo.scala 101:27]
  wire [4:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[2:0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [4:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [4:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [4:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [4:0] _GEN_6 = {{4'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [4:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [4:0] _GEN_7 = {{1'd0}, rdAddrBinNext[4:1]}; // @[AsyncFifo.scala 85:49]
  wire [4:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[3:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[3:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 5'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 5'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 5'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 5'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[4:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[4:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[4:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[4:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[4:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[4:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[4:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[4:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 5'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 5'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 5'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 5'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 5'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 5'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 5'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 5'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue(
  input         wr_clock,
  input         wr_reset,
  output        wr_ready,
  input         wr_valid,
  input  [71:0] wr_bits,
  input         rd_clock,
  input         rd_reset,
  input         rd_ready,
  output        rd_valid,
  output [71:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [71:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [71:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [71:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign wr_ready = ~fifo_wr_full; // @[AsyncFifo.scala 183:15]
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  outReg = _RAND_0[71:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifoMemory_1(
  input        wr_clock,
  input        wr_en,
  input  [1:0] wr_addr,
  input  [6:0] wr_data,
  input        rd_clock,
  input        rd_en,
  input  [1:0] rd_addr,
  output [6:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  reg [6:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [6:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [6:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [6:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [6:0] rd_data_r; // @[Reg.scala 19:16]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (2'h3 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_3; // @[Reg.scala 20:22]
      end else if (2'h2 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_2; // @[Reg.scala 20:22]
      end else if (2'h1 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_1; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= mem_0;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  mem_0 = _RAND_0[6:0];
  _RAND_1 = {1{`RANDOM}};
  mem_1 = _RAND_1[6:0];
  _RAND_2 = {1{`RANDOM}};
  mem_2 = _RAND_2[6:0];
  _RAND_3 = {1{`RANDOM}};
  mem_3 = _RAND_3[6:0];
  _RAND_4 = {1{`RANDOM}};
  rd_data_r = _RAND_4[6:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_1(
  input        wr_clock,
  input        wr_reset,
  input  [6:0] wr_data,
  input        wr_push,
  output       wr_full,
  input        rd_clock,
  input        rd_reset,
  output [6:0] rd_data,
  input        rd_pop,
  output       rd_empty,
  output       rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [6:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [6:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [2:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [2:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [2:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [2:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [2:0] _GEN_4 = {{2'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [2:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [2:0] _GEN_5 = {{1'd0}, wrAddrBinNext[2:1]}; // @[AsyncFifo.scala 85:49]
  wire [2:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [2:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[2:1]; // @[AsyncFifo.scala 101:27]
  wire [2:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [2:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [2:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [2:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [2:0] _GEN_6 = {{2'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [2:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [2:0] _GEN_7 = {{1'd0}, rdAddrBinNext[2:1]}; // @[AsyncFifo.scala 85:49]
  wire [2:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_1 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[1:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[1:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 3'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 3'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 3'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 3'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[2:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[2:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[2:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[2:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[2:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 3'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 3'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 3'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 3'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 3'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 3'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 3'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 3'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_1(
  input        wr_clock,
  input        wr_reset,
  output       wr_ready,
  input        wr_valid,
  input  [6:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
  input        rd_ready,
  output       rd_valid,
  output [6:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [6:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [6:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [6:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_1 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign wr_ready = ~fifo_wr_full; // @[AsyncFifo.scala 183:15]
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  outReg = _RAND_0[6:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SQueue(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [93:0] io_enq_bits,
  input         io_deq_ready,
  output        io_deq_valid,
  output [93:0] io_deq_bits
);
`ifdef RANDOMIZE_MEM_INIT
  reg [95:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg [93:0] ram [0:15]; // @[Decoupled.scala 275:95]
  wire  ram_io_deq_bits_MPORT_en; // @[Decoupled.scala 275:95]
  wire [3:0] ram_io_deq_bits_MPORT_addr; // @[Decoupled.scala 275:95]
  wire [93:0] ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 275:95]
  wire [93:0] ram_MPORT_data; // @[Decoupled.scala 275:95]
  wire [3:0] ram_MPORT_addr; // @[Decoupled.scala 275:95]
  wire  ram_MPORT_mask; // @[Decoupled.scala 275:95]
  wire  ram_MPORT_en; // @[Decoupled.scala 275:95]
  reg [3:0] enq_ptr_value; // @[Counter.scala 61:40]
  reg [3:0] deq_ptr_value; // @[Counter.scala 61:40]
  reg  maybe_full; // @[Decoupled.scala 278:27]
  wire  ptr_match = enq_ptr_value == deq_ptr_value; // @[Decoupled.scala 279:33]
  wire  empty = ptr_match & ~maybe_full; // @[Decoupled.scala 280:25]
  wire  full = ptr_match & maybe_full; // @[Decoupled.scala 281:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 52:35]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 52:35]
  wire [3:0] _value_T_1 = enq_ptr_value + 4'h1; // @[Counter.scala 77:24]
  wire [3:0] _value_T_3 = deq_ptr_value + 4'h1; // @[Counter.scala 77:24]
  assign ram_io_deq_bits_MPORT_en = 1'h1;
  assign ram_io_deq_bits_MPORT_addr = deq_ptr_value;
  assign ram_io_deq_bits_MPORT_data = ram[ram_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 275:95]
  assign ram_MPORT_data = io_enq_bits;
  assign ram_MPORT_addr = enq_ptr_value;
  assign ram_MPORT_mask = 1'h1;
  assign ram_MPORT_en = io_enq_ready & io_enq_valid;
  assign io_enq_ready = ~full; // @[Decoupled.scala 305:19]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 304:19]
  assign io_deq_bits = ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 312:17]
  always @(posedge clock) begin
    if (ram_MPORT_en & ram_MPORT_mask) begin
      ram[ram_MPORT_addr] <= ram_MPORT_data; // @[Decoupled.scala 275:95]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Decoupled.scala 288:16]
      enq_ptr_value <= 4'h0; // @[Counter.scala 77:15]
    end else if (do_enq) begin // @[Counter.scala 61:40]
      enq_ptr_value <= _value_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Decoupled.scala 292:16]
      deq_ptr_value <= 4'h0; // @[Counter.scala 77:15]
    end else if (do_deq) begin // @[Counter.scala 61:40]
      deq_ptr_value <= _value_T_3;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Decoupled.scala 295:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 296:16]
    end else if (do_enq != do_deq) begin // @[Decoupled.scala 278:27]
      maybe_full <= do_enq;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {3{`RANDOM}};
  for (initvar = 0; initvar < 16; initvar = initvar+1)
    ram[initvar] = _RAND_0[93:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  enq_ptr_value = _RAND_1[3:0];
  _RAND_2 = {1{`RANDOM}};
  deq_ptr_value = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  maybe_full = _RAND_3[0:0];
`endif // RANDOMIZE_REG_INIT
  if (reset) begin
    enq_ptr_value = 4'h0;
  end
  if (reset) begin
    deq_ptr_value = 4'h0;
  end
  if (reset) begin
    maybe_full = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module ScrcGen(
  input  [83:0] io_in,
  output [15:0] io_out
);
  wire [87:0] paddedData = {4'h0,io_in}; // @[Cat.scala 33:92]
  wire  xorList_0_0 = paddedData[56]; // @[crcGen.scala 80:41]
  wire  xorList_0_1 = paddedData[14]; // @[crcGen.scala 80:41]
  wire  xorList_0_2 = paddedData[46]; // @[crcGen.scala 80:41]
  wire  xorList_0_3 = paddedData[84]; // @[crcGen.scala 80:41]
  wire  xorList_0_4 = paddedData[61]; // @[crcGen.scala 80:41]
  wire  xorList_0_5 = paddedData[53]; // @[crcGen.scala 80:41]
  wire  xorList_0_6 = paddedData[77]; // @[crcGen.scala 80:41]
  wire  xorList_0_7 = paddedData[13]; // @[crcGen.scala 80:41]
  wire  xorList_0_8 = paddedData[2]; // @[crcGen.scala 80:41]
  wire  xorList_0_9 = paddedData[32]; // @[crcGen.scala 80:41]
  wire  xorList_0_10 = paddedData[22]; // @[crcGen.scala 80:41]
  wire  xorList_0_11 = paddedData[66]; // @[crcGen.scala 80:41]
  wire  xorList_0_12 = paddedData[80]; // @[crcGen.scala 80:41]
  wire  xorList_0_13 = paddedData[16]; // @[crcGen.scala 80:41]
  wire  xorList_0_14 = paddedData[11]; // @[crcGen.scala 80:41]
  wire  xorList_0_15 = paddedData[8]; // @[crcGen.scala 80:41]
  wire  xorList_0_16 = paddedData[4]; // @[crcGen.scala 80:41]
  wire  xorList_0_17 = paddedData[69]; // @[crcGen.scala 80:41]
  wire  xorList_0_18 = paddedData[0]; // @[crcGen.scala 80:41]
  wire  xorList_0_19 = paddedData[24]; // @[crcGen.scala 80:41]
  wire  xorList_0_20 = paddedData[37]; // @[crcGen.scala 80:41]
  wire  xorList_0_21 = paddedData[25]; // @[crcGen.scala 80:41]
  wire  xorList_0_22 = paddedData[6]; // @[crcGen.scala 80:41]
  wire  xorList_0_23 = paddedData[60]; // @[crcGen.scala 80:41]
  wire  xorList_0_24 = paddedData[21]; // @[crcGen.scala 80:41]
  wire  xorList_0_25 = paddedData[33]; // @[crcGen.scala 80:41]
  wire  xorList_0_26 = paddedData[76]; // @[crcGen.scala 80:41]
  wire  xorList_0_27 = paddedData[7]; // @[crcGen.scala 80:41]
  wire  xorList_0_28 = paddedData[39]; // @[crcGen.scala 80:41]
  wire  xorList_0_29 = paddedData[18]; // @[crcGen.scala 80:41]
  wire  xorList_0_31 = paddedData[40]; // @[crcGen.scala 80:41]
  wire  xorList_0_32 = paddedData[55]; // @[crcGen.scala 80:41]
  wire  xorList_0_33 = paddedData[23]; // @[crcGen.scala 80:41]
  wire  xorList_0_34 = paddedData[36]; // @[crcGen.scala 80:41]
  wire  xorList_0_35 = paddedData[30]; // @[crcGen.scala 80:41]
  wire  xorList_0_36 = paddedData[68]; // @[crcGen.scala 80:41]
  wire  xorList_0_37 = paddedData[62]; // @[crcGen.scala 80:41]
  wire  _crcCalc_0_T_29 = xorList_0_0 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_0_3 ^ xorList_0_4 ^ xorList_0_5 ^
    xorList_0_6 ^ xorList_0_7 ^ xorList_0_8 ^ xorList_0_9 ^ xorList_0_10 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_0_13 ^
    xorList_0_14 ^ xorList_0_15 ^ xorList_0_16 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^
    xorList_0_21 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_0_28 ^ xorList_0_29 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  crcCalc_0 = _crcCalc_0_T_29 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_0_33 ^ xorList_0_34 ^ xorList_0_35 ^
    xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_1_1 = paddedData[5]; // @[crcGen.scala 80:41]
  wire  xorList_1_4 = paddedData[85]; // @[crcGen.scala 80:41]
  wire  xorList_1_5 = paddedData[9]; // @[crcGen.scala 80:41]
  wire  xorList_1_7 = paddedData[41]; // @[crcGen.scala 80:41]
  wire  xorList_1_9 = paddedData[3]; // @[crcGen.scala 80:41]
  wire  xorList_1_11 = paddedData[19]; // @[crcGen.scala 80:41]
  wire  xorList_1_15 = paddedData[57]; // @[crcGen.scala 80:41]
  wire  xorList_1_16 = paddedData[78]; // @[crcGen.scala 80:41]
  wire  xorList_1_18 = paddedData[1]; // @[crcGen.scala 80:41]
  wire  xorList_1_19 = paddedData[38]; // @[crcGen.scala 80:41]
  wire  xorList_1_20 = paddedData[70]; // @[crcGen.scala 80:41]
  wire  xorList_1_22 = paddedData[34]; // @[crcGen.scala 80:41]
  wire  xorList_1_23 = paddedData[17]; // @[crcGen.scala 80:41]
  wire  xorList_1_24 = paddedData[12]; // @[crcGen.scala 80:41]
  wire  xorList_1_25 = paddedData[54]; // @[crcGen.scala 80:41]
  wire  xorList_1_26 = paddedData[81]; // @[crcGen.scala 80:41]
  wire  xorList_1_28 = paddedData[63]; // @[crcGen.scala 80:41]
  wire  xorList_1_30 = paddedData[67]; // @[crcGen.scala 80:41]
  wire  xorList_1_31 = paddedData[31]; // @[crcGen.scala 80:41]
  wire  xorList_1_33 = paddedData[26]; // @[crcGen.scala 80:41]
  wire  xorList_1_35 = paddedData[47]; // @[crcGen.scala 80:41]
  wire  xorList_1_36 = paddedData[15]; // @[crcGen.scala 80:41]
  wire  _crcCalc_1_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_0 ^ xorList_0_1 ^ xorList_1_4 ^ xorList_1_5 ^
    xorList_0_6 ^ xorList_1_7 ^ xorList_0_10 ^ xorList_1_9 ^ xorList_0_15 ^ xorList_1_11 ^ xorList_0_19 ^ xorList_0_20
     ^ xorList_0_21 ^ xorList_1_15 ^ xorList_1_16 ^ xorList_0_4 ^ xorList_1_18 ^ xorList_1_19 ^ xorList_1_20 ^
    xorList_0_25 ^ xorList_1_22 ^ xorList_1_23 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_1_26 ^ xorList_0_27 ^
    xorList_1_28 ^ 1'h1 ^ xorList_1_30; // @[crcGen.scala 87:38]
  wire  crcCalc_1 = _crcCalc_1_T_29 ^ xorList_1_31 ^ xorList_0_31 ^ xorList_1_33 ^ xorList_0_33 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_2_0 = paddedData[10]; // @[crcGen.scala 80:41]
  wire  xorList_2_4 = paddedData[27]; // @[crcGen.scala 80:41]
  wire  xorList_2_6 = paddedData[35]; // @[crcGen.scala 80:41]
  wire  xorList_2_8 = paddedData[42]; // @[crcGen.scala 80:41]
  wire  xorList_2_11 = paddedData[20]; // @[crcGen.scala 80:41]
  wire  xorList_2_18 = paddedData[64]; // @[crcGen.scala 80:41]
  wire  xorList_2_21 = paddedData[71]; // @[crcGen.scala 80:41]
  wire  xorList_2_22 = paddedData[86]; // @[crcGen.scala 80:41]
  wire  xorList_2_23 = paddedData[48]; // @[crcGen.scala 80:41]
  wire  xorList_2_30 = paddedData[58]; // @[crcGen.scala 80:41]
  wire  xorList_2_31 = paddedData[82]; // @[crcGen.scala 80:41]
  wire  xorList_2_33 = paddedData[79]; // @[crcGen.scala 80:41]
  wire  _crcCalc_2_T_29 = xorList_2_0 ^ xorList_0_22 ^ xorList_1_5 ^ xorList_0_8 ^ xorList_2_4 ^ xorList_0_28 ^
    xorList_2_6 ^ xorList_0_13 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_21 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_1_16
     ^ xorList_1_19 ^ xorList_1_20 ^ xorList_0_7 ^ xorList_1_7 ^ xorList_2_18 ^ xorList_0_9 ^ xorList_1_22 ^
    xorList_2_21 ^ xorList_2_22 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_1_33 ^ xorList_0_32 ^
    xorList_0_33 ^ xorList_0_15 ^ xorList_2_30; // @[crcGen.scala 87:38]
  wire  crcCalc_2 = _crcCalc_2_T_29 ^ xorList_2_31 ^ xorList_0_16 ^ xorList_2_33 ^ xorList_1_36 ^ xorList_0_36 ^
    xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_3_3 = paddedData[65]; // @[crcGen.scala 80:41]
  wire  xorList_3_6 = paddedData[87]; // @[crcGen.scala 80:41]
  wire  xorList_3_9 = paddedData[83]; // @[crcGen.scala 80:41]
  wire  xorList_3_15 = paddedData[28]; // @[crcGen.scala 80:41]
  wire  xorList_3_20 = paddedData[59]; // @[crcGen.scala 80:41]
  wire  xorList_3_23 = paddedData[49]; // @[crcGen.scala 80:41]
  wire  xorList_3_32 = paddedData[72]; // @[crcGen.scala 80:41]
  wire  xorList_3_33 = paddedData[43]; // @[crcGen.scala 80:41]
  wire  _crcCalc_3_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_1 ^ xorList_3_3 ^ xorList_1_5 ^ xorList_0_13 ^
    xorList_3_6 ^ xorList_2_30 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_2_8 ^ xorList_0_19 ^
    xorList_0_21 ^ xorList_3_15 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_3_20 ^ xorList_2_4
     ^ xorList_2_21 ^ xorList_3_23 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_1_9 ^ xorList_0_12 ^ xorList_2_6 ^
    xorList_1_28 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  crcCalc_3 = _crcCalc_3_T_29 ^ xorList_0_14 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_0_31 ^ xorList_1_33 ^
    xorList_0_34 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  xorList_4_15 = paddedData[29]; // @[crcGen.scala 80:41]
  wire  xorList_4_22 = paddedData[73]; // @[crcGen.scala 80:41]
  wire  xorList_4_28 = paddedData[44]; // @[crcGen.scala 80:41]
  wire  xorList_4_35 = paddedData[50]; // @[crcGen.scala 80:41]
  wire  _crcCalc_4_T_29 = xorList_0_19 ^ xorList_0_1 ^ xorList_0_4 ^ xorList_3_3 ^ xorList_0_5 ^ xorList_0_6 ^
    xorList_1_24 ^ xorList_0_35 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_2_11 ^ xorList_0_2
     ^ xorList_1_15 ^ xorList_4_15 ^ xorList_3_15 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_7 ^
    xorList_1_7 ^ xorList_4_22 ^ xorList_0_8 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_4_28
     ^ xorList_3_20 ^ xorList_2_4; // @[crcGen.scala 87:38]
  wire  crcCalc_4 = _crcCalc_4_T_29 ^ xorList_1_26 ^ xorList_0_26 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_4_35 ^
    xorList_0_13 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_1_33 ^ xorList_0_32 ^ xorList_0_33 ^ xorList_1_36 ^
    xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_5_18 = paddedData[74]; // @[crcGen.scala 80:41]
  wire  xorList_5_24 = paddedData[45]; // @[crcGen.scala 80:41]
  wire  xorList_5_42 = paddedData[51]; // @[crcGen.scala 80:41]
  wire  _crcCalc_5_T_29 = xorList_0_17 ^ xorList_0_0 ^ xorList_0_1 ^ xorList_0_23 ^ xorList_3_3 ^ xorList_0_6 ^
    xorList_0_7 ^ xorList_4_22 ^ xorList_0_11 ^ xorList_0_14 ^ xorList_0_31 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_21
     ^ xorList_1_15 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_1_18 ^ xorList_5_18 ^ xorList_3_15 ^ xorList_1_20 ^
    xorList_0_24 ^ xorList_0_25 ^ xorList_1_22 ^ xorList_5_24 ^ xorList_1_23 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_2_4
     ^ xorList_2_21 ^ xorList_1_25; // @[crcGen.scala 87:38]
  wire  crcCalc_5 = _crcCalc_5_T_29 ^ xorList_1_9 ^ xorList_2_6 ^ xorList_1_28 ^ xorList_0_29 ^ 1'h1 ^ xorList_0_13 ^
    xorList_1_31 ^ xorList_0_15 ^ xorList_2_30 ^ xorList_2_31 ^ xorList_0_35 ^ xorList_5_42 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_6_8 = paddedData[52]; // @[crcGen.scala 80:41]
  wire  xorList_6_38 = paddedData[75]; // @[crcGen.scala 80:41]
  wire  _crcCalc_6_T_29 = xorList_0_21 ^ xorList_1_5 ^ xorList_1_7 ^ xorList_0_8 ^ xorList_0_11 ^ xorList_2_6 ^
    xorList_1_36 ^ xorList_3_9 ^ xorList_6_8 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_1_15 ^ xorList_1_16 ^ xorList_4_15 ^
    xorList_0_4 ^ xorList_5_18 ^ xorList_3_15 ^ xorList_1_20 ^ xorList_5_24 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9
     ^ xorList_1_22 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_21 ^ xorList_1_24 ^ xorList_2_23 ^ xorList_1_28 ^
    xorList_0_29 ^ xorList_1_30; // @[crcGen.scala 87:38]
  wire  crcCalc_6 = _crcCalc_6_T_29 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_1_33 ^
    xorList_0_32 ^ xorList_0_33 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^ xorList_1_11 ^
    xorList_0_16 ^ xorList_2_33; // @[crcGen.scala 87:38]
  wire  _crcCalc_7_T_29 = xorList_0_18 ^ xorList_1_1 ^ xorList_0_3 ^ xorList_0_23 ^ xorList_0_25 ^ xorList_3_3 ^
    xorList_0_5 ^ xorList_0_7 ^ xorList_4_22 ^ xorList_0_26 ^ xorList_0_29 ^ xorList_3_32 ^ xorList_2_33 ^ xorList_2_0
     ^ xorList_0_0 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_2_11 ^ xorList_0_2 ^ xorList_4_15 ^ xorList_0_9
     ^ xorList_2_18 ^ xorList_1_23 ^ xorList_4_28 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_2_21 ^ xorList_3_23 ^
    xorList_1_9 ^ xorList_0_12; // @[crcGen.scala 87:38]
  wire  crcCalc_7 = _crcCalc_7_T_29 ^ xorList_2_6 ^ xorList_1_30 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_1_33 ^
    xorList_0_33 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_8_T_29 = xorList_0_1 ^ xorList_3_3 ^ xorList_0_6 ^ xorList_4_22 ^ xorList_1_25 ^ xorList_0_11 ^
    xorList_0_12 ^ xorList_0_16 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_0_21 ^
    xorList_2_11 ^ xorList_1_15 ^ xorList_0_4 ^ xorList_1_18 ^ xorList_5_18 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_1_4
     ^ xorList_0_24 ^ xorList_0_25 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_5_24 ^ xorList_1_23 ^ xorList_0_9 ^
    xorList_1_22 ^ xorList_3_20 ^ xorList_2_4; // @[crcGen.scala 87:38]
  wire  crcCalc_8 = _crcCalc_8_T_29 ^ xorList_1_26 ^ xorList_0_26 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^
    xorList_4_35 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_0_14 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_0_34 ^
    xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire  _crcCalc_9_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_23 ^ xorList_0_6 ^ xorList_0_11 ^ xorList_2_6 ^
    xorList_0_20 ^ xorList_0_21 ^ xorList_2_11 ^ xorList_0_2 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_0_4 ^ xorList_1_18
     ^ xorList_5_18 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_4_22 ^
    xorList_0_8 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_1_24
     ^ xorList_3_23 ^ xorList_2_22; // @[crcGen.scala 87:38]
  wire  crcCalc_9 = _crcCalc_9_T_29 ^ xorList_1_26 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_2_23 ^ xorList_0_29 ^
    xorList_1_30 ^ xorList_1_31 ^ xorList_1_33 ^ xorList_0_32 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_2_31 ^
    xorList_5_42 ^ xorList_1_11 ^ xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_10_T_29 = xorList_0_18 ^ xorList_0_0 ^ xorList_6_8 ^ xorList_0_22 ^ xorList_3_3 ^ xorList_0_7 ^
    xorList_0_8 ^ xorList_3_6 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_0_4 ^
    xorList_5_18 ^ xorList_1_19 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_5_24 ^ xorList_0_9 ^ xorList_1_22
     ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_2_21 ^ xorList_3_23 ^ xorList_0_26 ^ xorList_0_28 ^
    xorList_1_9 ^ xorList_2_6; // @[crcGen.scala 87:38]
  wire  crcCalc_10 = _crcCalc_10_T_29 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_4_35 ^ xorList_1_30 ^ xorList_0_13 ^
    xorList_0_31 ^ xorList_1_33 ^ xorList_0_33 ^ xorList_0_15 ^ xorList_6_38 ^ xorList_2_31 ^ xorList_0_34 ^
    xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^ xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_11_T_29 = xorList_0_0 ^ xorList_0_21 ^ xorList_0_22 ^ xorList_3_15 ^ xorList_1_5 ^ xorList_0_8 ^
    xorList_2_4 ^ xorList_2_21 ^ xorList_0_32 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_0_4
     ^ xorList_1_18 ^ xorList_0_7 ^ xorList_1_7 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_1_9
     ^ xorList_2_6 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_4_35 ^ xorList_0_13 ^ xorList_1_31 ^
    xorList_0_14 ^ xorList_3_32; // @[crcGen.scala 87:38]
  wire  crcCalc_11 = _crcCalc_11_T_29 ^ xorList_0_15 ^ xorList_6_38 ^ xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_12_T_29 = xorList_0_18 ^ xorList_2_8 ^ xorList_0_3 ^ xorList_3_3 ^ xorList_1_5 ^ xorList_3_32 ^
    xorList_1_33 ^ xorList_2_30 ^ xorList_0_16 ^ xorList_0_37 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_6_8 ^ xorList_0_1 ^
    xorList_2_11 ^ xorList_1_15 ^ xorList_4_15 ^ xorList_3_15 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_4_22 ^ xorList_0_8
     ^ xorList_0_9 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_1_24 ^ xorList_3_23 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_1_9 ^ xorList_0_12; // @[crcGen.scala 87:38]
  wire  crcCalc_12 = _crcCalc_12_T_29 ^ xorList_2_6 ^ xorList_0_29 ^ 1'h1 ^ xorList_0_34 ^ xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_13_T_29 = xorList_1_1 ^ xorList_2_0 ^ xorList_0_20 ^ xorList_6_8 ^ xorList_1_4 ^ xorList_3_3 ^
    xorList_0_5 ^ xorList_0_6 ^ xorList_0_7 ^ xorList_4_22 ^ xorList_1_22 ^ xorList_1_26 ^ xorList_0_11 ^ xorList_1_9 ^
    xorList_4_35 ^ xorList_0_16 ^ xorList_1_36 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_4_15 ^ xorList_1_18 ^
    xorList_5_18 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_1_28 ^ xorList_0_29
     ^ 1'h1 ^ xorList_0_14; // @[crcGen.scala 87:38]
  wire  crcCalc_13 = _crcCalc_13_T_29 ^ xorList_3_33 ^ xorList_0_15 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^
    xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_14_T_29 = xorList_0_18 ^ xorList_1_1 ^ xorList_0_20 ^ xorList_0_1 ^ xorList_5_18 ^ xorList_0_8 ^
    xorList_0_11 ^ xorList_2_6 ^ 1'h1 ^ xorList_0_14 ^ xorList_0_33 ^ xorList_0_16 ^ xorList_2_11 ^ xorList_1_16 ^
    xorList_0_22 ^ xorList_0_23 ^ xorList_0_24 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_1_5 ^ xorList_0_5 ^ xorList_1_22
     ^ xorList_2_18 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_3_20 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_2_22 ^
    xorList_1_30 ^ xorList_0_13; // @[crcGen.scala 87:38]
  wire  crcCalc_14 = _crcCalc_14_T_29 ^ xorList_1_31 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_2_31 ^ xorList_0_35 ^
    xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_15_T_29 = xorList_1_1 ^ xorList_2_0 ^ xorList_0_19 ^ xorList_6_8 ^ xorList_3_3 ^ xorList_0_7 ^ 1'h1 ^
    xorList_3_6 ^ xorList_6_38 ^ xorList_0_34 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_4_15 ^ xorList_0_4
     ^ xorList_1_18 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_1_19 ^ xorList_0_24 ^ xorList_0_9 ^ xorList_5_24 ^
    xorList_1_23 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_0_28 ^ xorList_1_9; // @[crcGen.scala 87:38]
  wire  crcCalc_15 = _crcCalc_15_T_29 ^ xorList_2_6 ^ xorList_1_30 ^ xorList_1_31 ^ xorList_0_32 ^ xorList_0_33 ^
    xorList_1_36 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire [7:0] io_out_lo = {crcCalc_7,crcCalc_6,crcCalc_5,crcCalc_4,crcCalc_3,crcCalc_2,crcCalc_1,crcCalc_0}; // @[crcGen.scala 91:21]
  wire [7:0] io_out_hi = {crcCalc_15,crcCalc_14,crcCalc_13,crcCalc_12,crcCalc_11,crcCalc_10,crcCalc_9,crcCalc_8}; // @[crcGen.scala 91:21]
  assign io_out = {io_out_hi,io_out_lo}; // @[crcGen.scala 91:21]
endmodule
module ScrcGen_1(
  input  [18:0] io_in,
  output [15:0] io_out
);
  wire [23:0] paddedData = {5'h0,io_in}; // @[Cat.scala 33:92]
  wire  xorList_0_0 = paddedData[5]; // @[crcGen.scala 80:41]
  wire  xorList_0_1 = paddedData[20]; // @[crcGen.scala 80:41]
  wire  xorList_0_2 = paddedData[13]; // @[crcGen.scala 80:41]
  wire  xorList_0_3 = paddedData[2]; // @[crcGen.scala 80:41]
  wire  xorList_0_4 = paddedData[12]; // @[crcGen.scala 80:41]
  wire  xorList_0_6 = paddedData[16]; // @[crcGen.scala 80:41]
  wire  xorList_0_7 = paddedData[4]; // @[crcGen.scala 80:41]
  wire  crcCalc_0 = xorList_0_0 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_0_3 ^ xorList_0_4 ^ 1'h1 ^ xorList_0_6 ^
    xorList_0_7; // @[crcGen.scala 87:38]
  wire  xorList_1_1 = paddedData[14]; // @[crcGen.scala 80:41]
  wire  xorList_1_2 = paddedData[6]; // @[crcGen.scala 80:41]
  wire  xorList_1_3 = paddedData[21]; // @[crcGen.scala 80:41]
  wire  xorList_1_5 = paddedData[17]; // @[crcGen.scala 80:41]
  wire  xorList_1_6 = paddedData[3]; // @[crcGen.scala 80:41]
  wire  crcCalc_1 = xorList_0_0 ^ xorList_1_1 ^ xorList_1_2 ^ xorList_1_3 ^ xorList_0_2 ^ xorList_1_5 ^ xorList_1_6 ^ 1'h1
    ; // @[crcGen.scala 87:38]
  wire  xorList_2_0 = paddedData[0]; // @[crcGen.scala 80:41]
  wire  xorList_2_3 = paddedData[22]; // @[crcGen.scala 80:41]
  wire  xorList_2_4 = paddedData[7]; // @[crcGen.scala 80:41]
  wire  xorList_2_5 = paddedData[18]; // @[crcGen.scala 80:41]
  wire  xorList_2_7 = paddedData[15]; // @[crcGen.scala 80:41]
  wire  crcCalc_2 = xorList_2_0 ^ xorList_1_1 ^ xorList_1_2 ^ xorList_2_3 ^ xorList_2_4 ^ xorList_2_5 ^ xorList_0_7 ^
    xorList_2_7; // @[crcGen.scala 87:38]
  wire  xorList_3_2 = paddedData[1]; // @[crcGen.scala 80:41]
  wire  xorList_3_5 = paddedData[23]; // @[crcGen.scala 80:41]
  wire  xorList_3_6 = paddedData[8]; // @[crcGen.scala 80:41]
  wire  xorList_3_7 = paddedData[19]; // @[crcGen.scala 80:41]
  wire  crcCalc_3 = xorList_2_0 ^ xorList_0_0 ^ xorList_3_2 ^ xorList_2_4 ^ xorList_0_6 ^ xorList_3_5 ^ xorList_3_6 ^
    xorList_3_7 ^ xorList_2_7; // @[crcGen.scala 87:38]
  wire  xorList_4_4 = paddedData[9]; // @[crcGen.scala 80:41]
  wire  crcCalc_4 = xorList_2_0 ^ xorList_0_0 ^ xorList_3_2 ^ xorList_1_2 ^ xorList_4_4 ^ xorList_0_2 ^ xorList_1_5 ^
    xorList_0_4 ^ 1'h1 ^ xorList_3_6 ^ xorList_0_7; // @[crcGen.scala 87:38]
  wire  xorList_5_1 = paddedData[10]; // @[crcGen.scala 80:41]
  wire  crcCalc_5 = xorList_0_0 ^ xorList_5_1 ^ xorList_1_1 ^ xorList_3_2 ^ xorList_1_2 ^ xorList_4_4 ^ xorList_0_2 ^
    xorList_0_3 ^ xorList_2_4 ^ xorList_2_5 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  xorList_6_7 = paddedData[11]; // @[crcGen.scala 80:41]
  wire  crcCalc_6 = xorList_2_0 ^ xorList_5_1 ^ xorList_1_1 ^ xorList_1_2 ^ xorList_0_3 ^ xorList_2_4 ^ xorList_1_6 ^
    xorList_6_7 ^ xorList_3_6 ^ xorList_3_7 ^ xorList_2_7; // @[crcGen.scala 87:38]
  wire  crcCalc_7 = xorList_2_0 ^ xorList_0_1 ^ xorList_3_2 ^ xorList_4_4 ^ xorList_0_4 ^ xorList_2_4 ^ xorList_1_6 ^
    xorList_0_6 ^ xorList_6_7 ^ xorList_3_6 ^ xorList_0_7 ^ xorList_2_7; // @[crcGen.scala 87:38]
  wire  crcCalc_8 = xorList_0_0 ^ xorList_5_1 ^ xorList_3_2 ^ xorList_1_3 ^ xorList_4_4 ^ xorList_0_2 ^ xorList_0_3 ^
    xorList_1_5 ^ xorList_0_4 ^ 1'h1 ^ xorList_0_6 ^ xorList_3_6 ^ xorList_0_7; // @[crcGen.scala 87:38]
  wire  crcCalc_9 = xorList_2_0 ^ xorList_0_0 ^ xorList_5_1 ^ xorList_1_1 ^ xorList_1_2 ^ xorList_4_4 ^ xorList_0_2 ^
    xorList_0_3 ^ xorList_1_5 ^ xorList_2_3 ^ xorList_1_6 ^ xorList_2_5 ^ xorList_6_7; // @[crcGen.scala 87:38]
  wire  crcCalc_10 = xorList_5_1 ^ xorList_1_1 ^ xorList_3_2 ^ xorList_1_2 ^ xorList_0_4 ^ xorList_2_4 ^ xorList_1_6 ^
    xorList_2_5 ^ xorList_6_7 ^ xorList_3_5 ^ xorList_3_7 ^ xorList_0_7 ^ xorList_2_7; // @[crcGen.scala 87:38]
  wire  crcCalc_11 = xorList_2_0 ^ xorList_2_4 ^ 1'h1 ^ xorList_6_7 ^ xorList_3_6 ^ xorList_3_7 ^ xorList_2_7; // @[crcGen.scala 87:38]
  wire  crcCalc_12 = xorList_2_0 ^ xorList_0_1 ^ xorList_3_2 ^ xorList_4_4 ^ xorList_0_4 ^ 1'h1 ^ xorList_0_6 ^
    xorList_3_6; // @[crcGen.scala 87:38]
  wire  crcCalc_13 = xorList_5_1 ^ xorList_3_2 ^ xorList_1_3 ^ xorList_4_4 ^ xorList_0_2 ^ xorList_0_3 ^ xorList_1_5 ^ 1'h1
    ; // @[crcGen.scala 87:38]
  wire  crcCalc_14 = xorList_2_0 ^ xorList_5_1 ^ xorList_1_1 ^ xorList_0_3 ^ xorList_2_3 ^ xorList_1_6 ^ xorList_2_5 ^
    xorList_6_7; // @[crcGen.scala 87:38]
  wire  crcCalc_15 = xorList_3_2 ^ xorList_0_4 ^ xorList_1_6 ^ xorList_6_7 ^ xorList_3_5 ^ xorList_3_7 ^ xorList_0_7 ^
    xorList_2_7; // @[crcGen.scala 87:38]
  wire [7:0] io_out_lo = {crcCalc_7,crcCalc_6,crcCalc_5,crcCalc_4,crcCalc_3,crcCalc_2,crcCalc_1,crcCalc_0}; // @[crcGen.scala 91:21]
  wire [7:0] io_out_hi = {crcCalc_15,crcCalc_14,crcCalc_13,crcCalc_12,crcCalc_11,crcCalc_10,crcCalc_9,crcCalc_8}; // @[crcGen.scala 91:21]
  assign io_out = {io_out_hi,io_out_lo}; // @[crcGen.scala 91:21]
endmodule
module SSlaveTxLinkLayer(
  input         clock,
  input         reset,
  output        io_txLL2PhyIO_clock,
  output        io_txLL2PhyIO_flit_valid,
  output [7:0]  io_txLL2PhyIO_flit_bits,
  output        io_txLL2PhyIO_creditARW_free,
  output        io_txLL2PhyIO_replayPkgID,
  output        io_inAXI4R_ready,
  input         io_inAXI4R_valid,
  input  [71:0] io_inAXI4R_bits,
  output        io_inAXI4B_ready,
  input         io_inAXI4B_valid,
  input  [6:0]  io_inAXI4B_bits,
  output [31:0] io_txDebugReplayState,
  output [31:0] io_txDebugReplayQueue,
  output [31:0] io_txDebugReplayCnt,
  output [2:0]  io_txDebugState,
  input  [11:0] io_inSlaveReplayLatency,
  output        io_rx2TxCreditARWFree_ready,
  input         io_rx2TxCreditARWFree_valid,
  input  [2:0]  io_rx2TxCreditARWFree_bits,
  output        io_rx2TxPackageIDUsed_ready,
  input         io_rx2TxPackageIDUsed_valid,
  input  [3:0]  io_rx2TxPackageIDUsed_bits,
  output        io_rx2TxCreditRBFree_ready,
  input         io_rx2TxCreditRBFree_valid,
  input  [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDOut_ready,
  input         io_rx2TxPackageIDOut_valid,
  input  [3:0]  io_rx2TxPackageIDOut_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
  reg [31:0] _RAND_19;
  reg [31:0] _RAND_20;
  reg [31:0] _RAND_21;
  reg [31:0] _RAND_22;
  reg [31:0] _RAND_23;
  reg [31:0] _RAND_24;
  reg [31:0] _RAND_25;
  reg [31:0] _RAND_26;
  reg [31:0] _RAND_27;
  reg [31:0] _RAND_28;
`endif // RANDOMIZE_REG_INIT
  wire  replayQueueFirst_clock; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueFirst_reset; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueFirst_io_enq_valid; // @[DataLinkLayer.scala 62:32]
  wire [93:0] replayQueueFirst_io_enq_bits; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueFirst_io_deq_ready; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueFirst_io_deq_valid; // @[DataLinkLayer.scala 62:32]
  wire [93:0] replayQueueFirst_io_deq_bits; // @[DataLinkLayer.scala 62:32]
  wire  replayQueueSecond_clock; // @[DataLinkLayer.scala 66:33]
  wire  replayQueueSecond_reset; // @[DataLinkLayer.scala 66:33]
  wire  replayQueueSecond_io_enq_ready; // @[DataLinkLayer.scala 66:33]
  wire  replayQueueSecond_io_enq_valid; // @[DataLinkLayer.scala 66:33]
  wire [93:0] replayQueueSecond_io_enq_bits; // @[DataLinkLayer.scala 66:33]
  wire  replayQueueSecond_io_deq_ready; // @[DataLinkLayer.scala 66:33]
  wire  replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 66:33]
  wire [93:0] replayQueueSecond_io_deq_bits; // @[DataLinkLayer.scala 66:33]
  wire [83:0] tmpRData_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] tmpRData_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [18:0] tmpBData_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] tmpBData_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [83:0] replayQueueFirst_io_enq_bits_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] replayQueueFirst_io_enq_bits_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [18:0] replayQueueFirst_io_enq_bits_crcgen_1_io_in; // @[crcGen.scala 99:24]
  wire [15:0] replayQueueFirst_io_enq_bits_crcgen_1_io_out; // @[crcGen.scala 99:24]
  reg [1:0] state; // @[DataLinkLayer.scala 30:22]
  reg [95:0] tmpRData; // @[DataLinkLayer.scala 34:25]
  reg [31:0] tmpBData; // @[DataLinkLayer.scala 35:25]
  reg [3:0] axi4RTCCnt; // @[DataLinkLayer.scala 37:28]
  reg [2:0] axi4BTCCnt; // @[DataLinkLayer.scala 38:28]
  reg [4:0] creditRCnt; // @[DataLinkLayer.scala 41:27]
  reg [2:0] creditBCnt; // @[DataLinkLayer.scala 43:27]
  reg [3:0] pkgID; // @[DataLinkLayer.scala 47:22]
  reg [7:0] txData; // @[DataLinkLayer.scala 49:23]
  reg  txDataValid; // @[DataLinkLayer.scala 50:28]
  reg  replayState; // @[DataLinkLayer.scala 53:28]
  reg [3:0] packageTmpId; // @[DataLinkLayer.scala 55:29]
  reg [7:0] replayPkgCnt; // @[DataLinkLayer.scala 68:29]
  reg  secondToFirst; // @[DataLinkLayer.scala 70:30]
  reg [7:0] replayCnt; // @[DataLinkLayer.scala 72:26]
  reg [7:0] replayCntAllTime; // @[DataLinkLayer.scala 73:33]
  reg  replayStateDelay; // @[DataLinkLayer.scala 74:33]
  reg  secondToFirstDelay; // @[DataLinkLayer.scala 75:35]
  reg [11:0] slaveReplayLatency; // @[DataLinkLayer.scala 76:35]
  reg [11:0] replayCheckCnt; // @[DataLinkLayer.scala 79:31]
  wire  _T_3 = io_inAXI4R_ready & io_inAXI4R_valid; // @[Decoupled.scala 52:35]
  wire [3:0] _pkgID_T_1 = pkgID + 4'h1; // @[DataLinkLayer.scala 90:24]
  wire [11:0] tmpRData_hi = {8'h12,pkgID}; // @[Cat.scala 33:92]
  wire [95:0] _tmpRData_T_1 = {4'h0,pkgID,tmpRData_crcgen_io_out,io_inAXI4R_bits}; // @[Cat.scala 33:92]
  wire  _T_4 = replayQueueFirst_io_deq_ready & replayQueueFirst_io_deq_valid; // @[Decoupled.scala 52:35]
  wire  _T_5 = replayState & _T_4; // @[DataLinkLayer.scala 99:30]
  wire  _T_7 = replayQueueFirst_io_deq_bits[93:92] == 2'h1; // @[DataLinkLayer.scala 99:133]
  wire  _T_9 = io_inAXI4B_ready & io_inAXI4B_valid; // @[Decoupled.scala 52:35]
  wire [11:0] tmpBData_hi = {8'hcd,pkgID}; // @[Cat.scala 33:92]
  wire [31:0] _tmpBData_T_1 = {5'h0,pkgID,tmpBData_crcgen_io_out,io_inAXI4B_bits}; // @[Cat.scala 33:92]
  wire  _T_13 = replayQueueFirst_io_deq_bits[93:92] == 2'h2; // @[DataLinkLayer.scala 123:133]
  wire  _T_14 = _T_5 & replayQueueFirst_io_deq_bits[93:92] == 2'h2; // @[DataLinkLayer.scala 123:62]
  wire [7:0] _GEN_1 = _T_5 & replayQueueFirst_io_deq_bits[93:92] == 2'h2 ? 8'hcd : 8'h0; // @[DataLinkLayer.scala 123:143 127:16 133:16]
  wire [2:0] _GEN_2 = _T_5 & replayQueueFirst_io_deq_bits[93:92] == 2'h2 ? 3'h0 : axi4BTCCnt; // @[DataLinkLayer.scala 123:143 129:20 38:28]
  wire [31:0] _GEN_3 = _T_5 & replayQueueFirst_io_deq_bits[93:92] == 2'h2 ? {{5'd0}, replayQueueFirst_io_deq_bits[26:0]}
     : tmpBData; // @[DataLinkLayer.scala 123:143 130:18 35:25]
  wire  _GEN_4 = _T_9 | _T_14; // @[DataLinkLayer.scala 107:34 108:15]
  wire  _GEN_11 = replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1 | _GEN_4; // @[DataLinkLayer.scala 99:143 104:21]
  wire  _GEN_19 = _T_3 | _GEN_11; // @[DataLinkLayer.scala 83:29 88:21]
  wire [2:0] _axi4BTCCnt_T_1 = axi4BTCCnt + 3'h1; // @[DataLinkLayer.scala 138:32]
  wire [2:0] _state_T_1 = 3'h4 - 3'h1; // @[DataLinkLayer.scala 139:62]
  wire [5:0] _txData_T = {axi4BTCCnt, 3'h0}; // @[DataLinkLayer.scala 140:42]
  wire [31:0] _txData_T_1 = tmpBData >> _txData_T; // @[DataLinkLayer.scala 140:27]
  wire [3:0] _axi4RTCCnt_T_1 = axi4RTCCnt + 4'h1; // @[DataLinkLayer.scala 144:32]
  wire [3:0] _state_T_5 = 4'hc - 4'h1; // @[DataLinkLayer.scala 145:62]
  wire [6:0] _txData_T_3 = {axi4RTCCnt, 3'h0}; // @[DataLinkLayer.scala 146:42]
  wire [95:0] _txData_T_4 = tmpRData >> _txData_T_3; // @[DataLinkLayer.scala 146:27]
  wire  _GEN_28 = 2'h2 == state | txDataValid; // @[DataLinkLayer.scala 81:17 147:19 50:28]
  wire  _GEN_32 = 2'h1 == state | _GEN_28; // @[DataLinkLayer.scala 81:17 141:19]
  wire  _io_inAXI4B_ready_T = state == 2'h0; // @[DataLinkLayer.scala 155:30]
  wire  _io_inAXI4B_ready_T_3 = ~replayState; // @[DataLinkLayer.scala 155:67]
  wire  _io_inAXI4R_ready_T_7 = ~_T_9; // @[DataLinkLayer.scala 156:118]
  reg [2:0] creditARW_freeReg; // @[DataLinkLayer.scala 159:34]
  reg [1:0] creditARW_freeCnt; // @[DataLinkLayer.scala 161:34]
  reg  creditARW_freeOutReg; // @[DataLinkLayer.scala 163:37]
  wire  _T_21 = io_rx2TxCreditARWFree_ready & io_rx2TxCreditARWFree_valid; // @[Decoupled.scala 52:35]
  wire  _T_26 = ~_T_21; // @[DataLinkLayer.scala 178:14]
  wire  _GEN_43 = _T_26 & creditARW_freeCnt == 2'h3 & creditARW_freeReg[2]; // @[DataLinkLayer.scala 184:71 185:26 188:26]
  wire  _GEN_45 = _T_26 & creditARW_freeCnt == 2'h2 ? creditARW_freeReg[1] : _GEN_43; // @[DataLinkLayer.scala 181:71 182:26]
  wire  _GEN_47 = ~_T_21 & creditARW_freeCnt == 2'h1 ? creditARW_freeReg[0] : _GEN_45; // @[DataLinkLayer.scala 178:71 179:26]
  reg [3:0] replayPkgIDReg; // @[DataLinkLayer.scala 194:31]
  reg [2:0] replayPkgIDCnt; // @[DataLinkLayer.scala 196:31]
  reg  replayPkgIDOutReg; // @[DataLinkLayer.scala 198:34]
  wire  _T_37 = io_rx2TxPackageIDOut_ready & io_rx2TxPackageIDOut_valid; // @[Decoupled.scala 52:35]
  wire [2:0] _replayPkgIDCnt_T_1 = replayPkgIDCnt + 3'h1; // @[DataLinkLayer.scala 207:38]
  wire  _T_42 = ~_T_37; // @[DataLinkLayer.scala 208:14]
  wire [2:0] _replayPkgIDOutReg_T_1 = replayPkgIDCnt - 3'h1; // @[DataLinkLayer.scala 209:56]
  wire [3:0] _replayPkgIDOutReg_T_2 = replayPkgIDReg >> _replayPkgIDOutReg_T_1; // @[DataLinkLayer.scala 209:40]
  wire  _GEN_52 = _T_42 & replayPkgIDCnt == 3'h4 & _replayPkgIDOutReg_T_2[0]; // @[DataLinkLayer.scala 211:89 212:23 215:23]
  wire  _GEN_54 = ~_T_37 & replayPkgIDCnt > 3'h0 & replayPkgIDCnt < 3'h4 ? _replayPkgIDOutReg_T_2[0] : _GEN_52; // @[DataLinkLayer.scala 208:113 209:23]
  wire  _T_51 = io_rx2TxCreditRBFree_ready & io_rx2TxCreditRBFree_valid; // @[Decoupled.scala 52:35]
  wire  _T_52 = ~_T_51; // @[DataLinkLayer.scala 229:23]
  wire [4:0] _creditRCnt_T_1 = creditRCnt - 5'h1; // @[DataLinkLayer.scala 230:30]
  wire [4:0] _creditRCnt_T_5 = creditRCnt + 5'h1; // @[DataLinkLayer.scala 234:30]
  wire [2:0] _creditBCnt_T_1 = creditBCnt - 3'h1; // @[DataLinkLayer.scala 240:30]
  wire [2:0] _creditBCnt_T_5 = creditBCnt + 3'h1; // @[DataLinkLayer.scala 244:30]
  wire  _T_77 = io_rx2TxPackageIDUsed_ready & io_rx2TxPackageIDUsed_valid; // @[Decoupled.scala 52:35]
  wire [3:0] _T_79 = packageTmpId + 4'h1; // @[DataLinkLayer.scala 251:83]
  wire  _T_80 = io_rx2TxPackageIDUsed_bits == _T_79; // @[DataLinkLayer.scala 251:65]
  wire  _T_85 = io_rx2TxPackageIDUsed_bits != _T_79; // @[DataLinkLayer.scala 253:72]
  wire  _T_94 = ~replayQueueFirst_io_deq_valid; // @[DataLinkLayer.scala 264:30]
  wire  _T_96 = ~replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 264:64]
  wire  _T_97 = replayState & ~replayQueueFirst_io_deq_valid & ~replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 264:61]
  wire  _GEN_66 = replayState & ~replayQueueFirst_io_deq_valid & ~replayQueueSecond_io_deq_valid ? 1'h0 : replayState; // @[DataLinkLayer.scala 264:96 265:17 267:17]
  wire [93:0] _replayQueueFirst_io_enq_bits_T_1 = {2'h1,pkgID,replayQueueFirst_io_enq_bits_crcgen_io_out,io_inAXI4R_bits
    }; // @[Cat.scala 33:92]
  wire [93:0] _replayQueueFirst_io_enq_bits_T_3 = {67'h40000000000000000,pkgID,
    replayQueueFirst_io_enq_bits_crcgen_1_io_out,io_inAXI4B_bits}; // @[Cat.scala 33:92]
  wire  _T_100 = replayState & secondToFirst; // @[DataLinkLayer.scala 295:25]
  wire  _GEN_68 = replayState & secondToFirst & replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 295:42 296:35 300:35]
  wire [93:0] _GEN_69 = replayState & secondToFirst ? replayQueueSecond_io_deq_bits : 94'h0; // @[DataLinkLayer.scala 295:42 297:34 301:34]
  wire  _GEN_70 = _T_9 | _GEN_68; // @[DataLinkLayer.scala 282:30 283:35]
  wire [93:0] _GEN_71 = _T_9 ? _replayQueueFirst_io_enq_bits_T_3 : _GEN_69; // @[DataLinkLayer.scala 282:30 289:36]
  wire  _T_114 = _T_13 & io_rx2TxPackageIDUsed_bits == replayQueueFirst_io_deq_bits[26:23]; // @[DataLinkLayer.scala 307:83]
  wire  _T_115 = _T_7 & io_rx2TxPackageIDUsed_bits == replayQueueFirst_io_deq_bits[91:88] | _T_114; // @[DataLinkLayer.scala 306:227]
  wire  _T_116 = _T_77 & replayQueueFirst_io_deq_valid & _io_inAXI4B_ready_T_3 & _T_115; // @[DataLinkLayer.scala 305:84]
  wire  _T_124 = _io_inAXI4B_ready_T & _T_13; // @[DataLinkLayer.scala 311:24]
  wire  _T_125 = _io_inAXI4B_ready_T & _T_7 | _T_124; // @[DataLinkLayer.scala 310:115]
  wire  _T_129 = _T_125 & replayState & replayQueueFirst_io_deq_valid & ~secondToFirst; // @[DataLinkLayer.scala 311:154]
  wire  _GEN_78 = _T_100 & replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 330:43 331:36 333:36]
  wire [7:0] _replayPkgCnt_T_1 = replayPkgCnt + 8'h1; // @[DataLinkLayer.scala 344:34]
  wire  _T_142 = _io_inAXI4B_ready_T_3 & replayStateDelay; // @[DataLinkLayer.scala 345:27]
  wire [11:0] _replayCheckCnt_T_1 = replayCheckCnt + 12'h1; // @[DataLinkLayer.scala 354:38]
  wire  _T_153 = replayState & replayCheckCnt == slaveReplayLatency; // @[DataLinkLayer.scala 355:26]
  wire  _T_154 = replayState & replayCheckCnt == slaveReplayLatency & replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 355:67]
  wire  _T_158 = _T_153 & _T_96; // @[DataLinkLayer.scala 357:67]
  wire  _GEN_86 = _T_158 ? 1'h0 : secondToFirst; // @[DataLinkLayer.scala 365:102 366:19 368:19]
  wire  _T_167 = replayState & ~replayStateDelay; // @[DataLinkLayer.scala 371:20]
  wire [7:0] _replayCnt_T_1 = replayCnt + 8'h1; // @[DataLinkLayer.scala 376:28]
  wire [7:0] _replayCntAllTime_T_1 = replayCntAllTime + 8'h1; // @[DataLinkLayer.scala 382:42]
  reg [31:0] rTxDebugReplayState; // @[DataLinkLayer.scala 389:36]
  reg [31:0] rTxDebugReplayQueue; // @[DataLinkLayer.scala 390:36]
  reg [31:0] rTxDebugReplayCnt; // @[DataLinkLayer.scala 391:34]
  wire [8:0] rTxDebugReplayState_lo = {secondToFirst,pkgID,packageTmpId}; // @[Cat.scala 33:92]
  wire [22:0] rTxDebugReplayState_hi = {14'h0,replayCntAllTime,replayState}; // @[Cat.scala 33:92]
  wire [1:0] rTxDebugReplayQueue_lo = {replayQueueSecond_io_enq_ready,replayQueueSecond_io_deq_valid}; // @[Cat.scala 33:92]
  wire [29:0] rTxDebugReplayQueue_hi = {28'h0,replayQueueFirst_io_enq_ready,replayQueueFirst_io_deq_valid}; // @[Cat.scala 33:92]
  wire [19:0] rTxDebugReplayCnt_lo = {replayCnt,replayCheckCnt}; // @[Cat.scala 33:92]
  wire [11:0] rTxDebugReplayCnt_hi = {4'h0,replayPkgCnt}; // @[Cat.scala 33:92]
  SQueue replayQueueFirst ( // @[DataLinkLayer.scala 62:32]
    .clock(replayQueueFirst_clock),
    .reset(replayQueueFirst_reset),
    .io_enq_ready(replayQueueFirst_io_enq_ready),
    .io_enq_valid(replayQueueFirst_io_enq_valid),
    .io_enq_bits(replayQueueFirst_io_enq_bits),
    .io_deq_ready(replayQueueFirst_io_deq_ready),
    .io_deq_valid(replayQueueFirst_io_deq_valid),
    .io_deq_bits(replayQueueFirst_io_deq_bits)
  );
  SQueue replayQueueSecond ( // @[DataLinkLayer.scala 66:33]
    .clock(replayQueueSecond_clock),
    .reset(replayQueueSecond_reset),
    .io_enq_ready(replayQueueSecond_io_enq_ready),
    .io_enq_valid(replayQueueSecond_io_enq_valid),
    .io_enq_bits(replayQueueSecond_io_enq_bits),
    .io_deq_ready(replayQueueSecond_io_deq_ready),
    .io_deq_valid(replayQueueSecond_io_deq_valid),
    .io_deq_bits(replayQueueSecond_io_deq_bits)
  );
  ScrcGen tmpRData_crcgen ( // @[crcGen.scala 99:24]
    .io_in(tmpRData_crcgen_io_in),
    .io_out(tmpRData_crcgen_io_out)
  );
  ScrcGen_1 tmpBData_crcgen ( // @[crcGen.scala 99:24]
    .io_in(tmpBData_crcgen_io_in),
    .io_out(tmpBData_crcgen_io_out)
  );
  ScrcGen replayQueueFirst_io_enq_bits_crcgen ( // @[crcGen.scala 99:24]
    .io_in(replayQueueFirst_io_enq_bits_crcgen_io_in),
    .io_out(replayQueueFirst_io_enq_bits_crcgen_io_out)
  );
  ScrcGen_1 replayQueueFirst_io_enq_bits_crcgen_1 ( // @[crcGen.scala 99:24]
    .io_in(replayQueueFirst_io_enq_bits_crcgen_1_io_in),
    .io_out(replayQueueFirst_io_enq_bits_crcgen_1_io_out)
  );
  assign io_txLL2PhyIO_clock = clock; // @[DataLinkLayer.scala 222:23]
  assign io_txLL2PhyIO_flit_valid = txDataValid; // @[DataLinkLayer.scala 221:28]
  assign io_txLL2PhyIO_flit_bits = txData; // @[DataLinkLayer.scala 220:27]
  assign io_txLL2PhyIO_creditARW_free = creditARW_freeOutReg; // @[DataLinkLayer.scala 191:32]
  assign io_txLL2PhyIO_replayPkgID = replayPkgIDOutReg; // @[DataLinkLayer.scala 218:29]
  assign io_inAXI4R_ready = _io_inAXI4B_ready_T & creditRCnt > 5'h1 & _io_inAXI4B_ready_T_3 &
    replayQueueFirst_io_enq_ready & ~_T_9; // @[DataLinkLayer.scala 156:114]
  assign io_inAXI4B_ready = state == 2'h0 & creditBCnt > 3'h1 & ~replayState & replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 155:81]
  assign io_txDebugReplayState = rTxDebugReplayState; // @[DataLinkLayer.scala 397:25]
  assign io_txDebugReplayQueue = rTxDebugReplayQueue; // @[DataLinkLayer.scala 398:25]
  assign io_txDebugReplayCnt = rTxDebugReplayCnt; // @[DataLinkLayer.scala 399:23]
  assign io_txDebugState = {{1'd0}, state}; // @[DataLinkLayer.scala 400:19]
  assign io_rx2TxCreditARWFree_ready = creditARW_freeCnt == 2'h0; // @[DataLinkLayer.scala 190:53]
  assign io_rx2TxPackageIDUsed_ready = 1'h1; // @[DataLinkLayer.scala 249:31]
  assign io_rx2TxCreditRBFree_ready = 1'h1; // @[DataLinkLayer.scala 227:30]
  assign io_rx2TxPackageIDOut_ready = replayPkgIDCnt == 3'h0; // @[DataLinkLayer.scala 217:49]
  assign replayQueueFirst_clock = clock;
  assign replayQueueFirst_reset = reset;
  assign replayQueueFirst_io_enq_valid = _T_3 | _GEN_70; // @[DataLinkLayer.scala 271:24 272:35]
  assign replayQueueFirst_io_enq_bits = _T_3 ? _replayQueueFirst_io_enq_bits_T_1 : _GEN_71; // @[DataLinkLayer.scala 271:24 274:36]
  assign replayQueueFirst_io_deq_ready = _T_116 | _T_129; // @[DataLinkLayer.scala 308:5 309:35]
  assign replayQueueSecond_clock = clock;
  assign replayQueueSecond_reset = reset;
  assign replayQueueSecond_io_enq_valid = replayState & _T_4; // @[DataLinkLayer.scala 319:20]
  assign replayQueueSecond_io_enq_bits = _T_5 ? replayQueueFirst_io_deq_bits : 94'h0; // @[DataLinkLayer.scala 319:52 321:35 324:35]
  assign replayQueueSecond_io_deq_ready = replayState & _T_77 & _T_80 | _GEN_78; // @[DataLinkLayer.scala 328:107 329:36]
  assign tmpRData_crcgen_io_in = {tmpRData_hi,io_inAXI4R_bits}; // @[Cat.scala 33:92]
  assign tmpBData_crcgen_io_in = {tmpBData_hi,io_inAXI4B_bits}; // @[Cat.scala 33:92]
  assign replayQueueFirst_io_enq_bits_crcgen_io_in = {tmpRData_hi,io_inAXI4R_bits}; // @[Cat.scala 33:92]
  assign replayQueueFirst_io_enq_bits_crcgen_1_io_in = {tmpBData_hi,io_inAXI4B_bits}; // @[Cat.scala 33:92]
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      state <= 2'h0; // @[DataLinkLayer.scala 83:29 84:15 99:143 100:15]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 81:17]
      if (_T_3) begin // @[DataLinkLayer.scala 139:13]
        state <= 2'h2;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1) begin
        state <= 2'h2;
      end else begin
        state <= {{1'd0}, _GEN_4};
      end
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 81:17]
      state <= {{1'd0}, axi4BTCCnt < _state_T_1}; // @[DataLinkLayer.scala 145:19]
    end else if (2'h2 == state) begin // @[DataLinkLayer.scala 30:22]
      if (axi4RTCCnt < _state_T_5) begin
        state <= 2'h2;
      end else begin
        state <= 2'h0;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      tmpRData <= 96'h0; // @[DataLinkLayer.scala 83:29 92:20 99:143 106:18 34:25]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 34:25]
      if (_T_3) begin
        tmpRData <= _tmpRData_T_1;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1) begin
        tmpRData <= {{4'd0}, replayQueueFirst_io_deq_bits[91:0]};
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      tmpBData <= 32'h0; // @[DataLinkLayer.scala 116:20 35:{25,25} 83:29 99:143 107:34]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 35:25]
      if (!(_T_3)) begin
        if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1)) begin
          if (_T_9) begin
            tmpBData <= _tmpBData_T_1;
          end else begin
            tmpBData <= _GEN_3;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      axi4RTCCnt <= 4'h0; // @[DataLinkLayer.scala 83:29 89:20 99:143 105:20 37:28]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 81:17]
      if (_T_3) begin // @[DataLinkLayer.scala 37:28]
        axi4RTCCnt <= 4'h0;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1) begin
        axi4RTCCnt <= 4'h0;
      end
    end else if (!(2'h1 == state)) begin // @[DataLinkLayer.scala 81:17]
      if (2'h2 == state) begin // @[DataLinkLayer.scala 37:28]
        axi4RTCCnt <= _axi4RTCCnt_T_1;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      axi4BTCCnt <= 3'h0; // @[DataLinkLayer.scala 113:20 38:{28,28} 83:29 99:143 107:34]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 81:17]
      if (!(_T_3)) begin // @[DataLinkLayer.scala 138:18]
        if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1)) begin
          if (_T_9) begin
            axi4BTCCnt <= 3'h0;
          end else begin
            axi4BTCCnt <= _GEN_2;
          end
        end
      end
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 38:28]
      axi4BTCCnt <= _axi4BTCCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 229:50]
      creditRCnt <= 5'h10; // @[DataLinkLayer.scala 230:16]
    end else if (_T_3 & ~_T_51) begin // @[DataLinkLayer.scala 231:88]
      creditRCnt <= _creditRCnt_T_1; // @[DataLinkLayer.scala 232:16]
    end else if (_T_3 & _T_51 & ~io_rx2TxCreditRBFree_bits[1]) begin // @[DataLinkLayer.scala 233:88]
      creditRCnt <= _creditRCnt_T_1; // @[DataLinkLayer.scala 234:16]
    end else if (~_T_3 & _T_51 & io_rx2TxCreditRBFree_bits[1]) begin // @[DataLinkLayer.scala 236:16]
      creditRCnt <= _creditRCnt_T_5;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 239:50]
      creditBCnt <= 3'h4; // @[DataLinkLayer.scala 240:16]
    end else if (_T_9 & _T_52) begin // @[DataLinkLayer.scala 241:88]
      creditBCnt <= _creditBCnt_T_1; // @[DataLinkLayer.scala 242:16]
    end else if (_T_9 & _T_51 & ~io_rx2TxCreditRBFree_bits[0]) begin // @[DataLinkLayer.scala 243:88]
      creditBCnt <= _creditBCnt_T_1; // @[DataLinkLayer.scala 244:16]
    end else if (_io_inAXI4R_ready_T_7 & _T_51 & io_rx2TxCreditRBFree_bits[0]) begin // @[DataLinkLayer.scala 246:16]
      creditBCnt <= _creditBCnt_T_5;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      pkgID <= 4'h0; // @[DataLinkLayer.scala 83:29 90:15 99:143 47:22 107:34 114:15 47:22]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 47:22]
      if (_T_3) begin
        pkgID <= _pkgID_T_1;
      end else if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1)) begin
        if (_T_9) begin
          pkgID <= _pkgID_T_1;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      txData <= 8'h0; // @[DataLinkLayer.scala 83:29 87:16 99:143 103:16 107:34 111:16]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 81:17]
      if (_T_3) begin // @[DataLinkLayer.scala 140:14]
        txData <= 8'h12;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[93:92] == 2'h1) begin
        txData <= 8'h12;
      end else if (_T_9) begin
        txData <= 8'hcd;
      end else begin
        txData <= _GEN_1;
      end
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 81:17]
      txData <= _txData_T_1[7:0]; // @[DataLinkLayer.scala 146:14]
    end else if (2'h2 == state) begin // @[DataLinkLayer.scala 49:23]
      txData <= _txData_T_4[7:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:17]
      txDataValid <= 1'h0;
    end else if (2'h0 == state) begin
      txDataValid <= _GEN_19;
    end else begin
      txDataValid <= _GEN_32;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 260:108]
      replayState <= 1'h0; // @[DataLinkLayer.scala 261:17]
    end else begin
      replayState <= _io_inAXI4B_ready_T_3 & _T_77 & _T_85 | _GEN_66;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 251:90]
      packageTmpId <= 4'hf; // @[DataLinkLayer.scala 252:18]
    end else if (_T_77 & io_rx2TxPackageIDUsed_bits == _T_79) begin
      packageTmpId <= io_rx2TxPackageIDUsed_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 343:52]
      replayPkgCnt <= 8'h0; // @[DataLinkLayer.scala 344:18]
    end else if (_T_5) begin // @[DataLinkLayer.scala 345:47]
      replayPkgCnt <= _replayPkgCnt_T_1; // @[DataLinkLayer.scala 346:18]
    end else if (_io_inAXI4B_ready_T_3 & replayStateDelay) begin // @[DataLinkLayer.scala 348:18]
      replayPkgCnt <= 8'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 363:95]
      secondToFirst <= 1'h0; // @[DataLinkLayer.scala 364:19]
    end else begin
      secondToFirst <= _T_154 | _GEN_86;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 371:41]
      replayCnt <= 8'h0; // @[DataLinkLayer.scala 372:15]
    end else if (replayState & ~replayStateDelay) begin // @[DataLinkLayer.scala 373:47]
      replayCnt <= 8'h1; // @[DataLinkLayer.scala 374:15]
    end else if (_T_142) begin // @[DataLinkLayer.scala 375:66]
      replayCnt <= 8'h0; // @[DataLinkLayer.scala 376:15]
    end else if (_T_100 & ~secondToFirstDelay) begin // @[DataLinkLayer.scala 378:15]
      replayCnt <= _replayCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 381:41]
      replayCntAllTime <= 8'h0; // @[DataLinkLayer.scala 382:22]
    end else if (_T_167) begin // @[DataLinkLayer.scala 384:22]
      replayCntAllTime <= _replayCntAllTime_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 74:33]
      replayStateDelay <= 1'h0; // @[DataLinkLayer.scala 74:33]
    end else begin
      replayStateDelay <= replayState; // @[DataLinkLayer.scala 74:33]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 75:35]
      secondToFirstDelay <= 1'h0; // @[DataLinkLayer.scala 75:35]
    end else begin
      secondToFirstDelay <= secondToFirst; // @[DataLinkLayer.scala 75:35]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 76:35]
      slaveReplayLatency <= 12'h400; // @[DataLinkLayer.scala 76:35]
    end else begin
      slaveReplayLatency <= io_inSlaveReplayLatency; // @[DataLinkLayer.scala 77:22]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 351:89]
      replayCheckCnt <= 12'h0; // @[DataLinkLayer.scala 352:20]
    end else if (_T_97) begin // @[DataLinkLayer.scala 353:135]
      replayCheckCnt <= 12'h0; // @[DataLinkLayer.scala 354:20]
    end else if (replayState & replayCheckCnt != slaveReplayLatency & _T_94 & replayQueueSecond_io_deq_valid) begin // @[DataLinkLayer.scala 355:101]
      replayCheckCnt <= _replayCheckCnt_T_1; // @[DataLinkLayer.scala 356:20]
    end else if (!(replayState & replayCheckCnt == slaveReplayLatency & replayQueueSecond_io_deq_valid)) begin // @[DataLinkLayer.scala 357:102]
      if (_T_153 & _T_96) begin // @[DataLinkLayer.scala 360:20]
        replayCheckCnt <= 12'h0;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 164:35]
      creditARW_freeReg <= 3'h0; // @[DataLinkLayer.scala 165:23]
    end else if (_T_21) begin // @[DataLinkLayer.scala 167:23]
      creditARW_freeReg <= io_rx2TxCreditARWFree_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 175:64]
      creditARW_freeCnt <= 2'h0; // @[DataLinkLayer.scala 177:23]
    end else if (_T_21 & creditARW_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 178:71]
      creditARW_freeCnt <= 2'h1; // @[DataLinkLayer.scala 180:23]
    end else if (~_T_21 & creditARW_freeCnt == 2'h1) begin // @[DataLinkLayer.scala 181:71]
      creditARW_freeCnt <= 2'h2; // @[DataLinkLayer.scala 183:23]
    end else if (_T_26 & creditARW_freeCnt == 2'h2) begin // @[DataLinkLayer.scala 184:71]
      creditARW_freeCnt <= 2'h3; // @[DataLinkLayer.scala 186:23]
    end else if (_T_26 & creditARW_freeCnt == 2'h3) begin // @[DataLinkLayer.scala 161:34]
      creditARW_freeCnt <= 2'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 175:64]
      creditARW_freeOutReg <= 1'h0; // @[DataLinkLayer.scala 176:26]
    end else begin
      creditARW_freeOutReg <= _T_21 & creditARW_freeCnt == 2'h0 | _GEN_47;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 199:34]
      replayPkgIDReg <= 4'h0; // @[DataLinkLayer.scala 200:20]
    end else if (_T_37) begin // @[DataLinkLayer.scala 202:20]
      replayPkgIDReg <= io_rx2TxPackageIDOut_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 205:60]
      replayPkgIDCnt <= 3'h0; // @[DataLinkLayer.scala 207:20]
    end else if (_T_37 & replayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 208:113]
      replayPkgIDCnt <= _replayPkgIDCnt_T_1; // @[DataLinkLayer.scala 210:20]
    end else if (~_T_37 & replayPkgIDCnt > 3'h0 & replayPkgIDCnt < 3'h4) begin // @[DataLinkLayer.scala 211:89]
      replayPkgIDCnt <= _replayPkgIDCnt_T_1; // @[DataLinkLayer.scala 213:20]
    end else if (_T_42 & replayPkgIDCnt == 3'h4) begin // @[DataLinkLayer.scala 196:31]
      replayPkgIDCnt <= 3'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 205:60]
      replayPkgIDOutReg <= 1'h0; // @[DataLinkLayer.scala 206:23]
    end else begin
      replayPkgIDOutReg <= _T_37 & replayPkgIDCnt == 3'h0 | _GEN_54;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Cat.scala 33:92]
      rTxDebugReplayState <= 32'h0;
    end else begin
      rTxDebugReplayState <= {rTxDebugReplayState_hi,rTxDebugReplayState_lo};
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Cat.scala 33:92]
      rTxDebugReplayQueue <= 32'h0;
    end else begin
      rTxDebugReplayQueue <= {rTxDebugReplayQueue_hi,rTxDebugReplayQueue_lo};
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[Cat.scala 33:92]
      rTxDebugReplayCnt <= 32'h0;
    end else begin
      rTxDebugReplayCnt <= {rTxDebugReplayCnt_hi,rTxDebugReplayCnt_lo};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  state = _RAND_0[1:0];
  _RAND_1 = {3{`RANDOM}};
  tmpRData = _RAND_1[95:0];
  _RAND_2 = {1{`RANDOM}};
  tmpBData = _RAND_2[31:0];
  _RAND_3 = {1{`RANDOM}};
  axi4RTCCnt = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  axi4BTCCnt = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  creditRCnt = _RAND_5[4:0];
  _RAND_6 = {1{`RANDOM}};
  creditBCnt = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  pkgID = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  txData = _RAND_8[7:0];
  _RAND_9 = {1{`RANDOM}};
  txDataValid = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  replayState = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  packageTmpId = _RAND_11[3:0];
  _RAND_12 = {1{`RANDOM}};
  replayPkgCnt = _RAND_12[7:0];
  _RAND_13 = {1{`RANDOM}};
  secondToFirst = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  replayCnt = _RAND_14[7:0];
  _RAND_15 = {1{`RANDOM}};
  replayCntAllTime = _RAND_15[7:0];
  _RAND_16 = {1{`RANDOM}};
  replayStateDelay = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  secondToFirstDelay = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  slaveReplayLatency = _RAND_18[11:0];
  _RAND_19 = {1{`RANDOM}};
  replayCheckCnt = _RAND_19[11:0];
  _RAND_20 = {1{`RANDOM}};
  creditARW_freeReg = _RAND_20[2:0];
  _RAND_21 = {1{`RANDOM}};
  creditARW_freeCnt = _RAND_21[1:0];
  _RAND_22 = {1{`RANDOM}};
  creditARW_freeOutReg = _RAND_22[0:0];
  _RAND_23 = {1{`RANDOM}};
  replayPkgIDReg = _RAND_23[3:0];
  _RAND_24 = {1{`RANDOM}};
  replayPkgIDCnt = _RAND_24[2:0];
  _RAND_25 = {1{`RANDOM}};
  replayPkgIDOutReg = _RAND_25[0:0];
  _RAND_26 = {1{`RANDOM}};
  rTxDebugReplayState = _RAND_26[31:0];
  _RAND_27 = {1{`RANDOM}};
  rTxDebugReplayQueue = _RAND_27[31:0];
  _RAND_28 = {1{`RANDOM}};
  rTxDebugReplayCnt = _RAND_28[31:0];
`endif // RANDOMIZE_REG_INIT
  if (reset) begin
    state = 2'h0;
  end
  if (reset) begin
    tmpRData = 96'h0;
  end
  if (reset) begin
    tmpBData = 32'h0;
  end
  if (reset) begin
    axi4RTCCnt = 4'h0;
  end
  if (reset) begin
    axi4BTCCnt = 3'h0;
  end
  if (reset) begin
    creditRCnt = 5'h10;
  end
  if (reset) begin
    creditBCnt = 3'h4;
  end
  if (reset) begin
    pkgID = 4'h0;
  end
  if (reset) begin
    txData = 8'h0;
  end
  if (reset) begin
    txDataValid = 1'h0;
  end
  if (reset) begin
    replayState = 1'h0;
  end
  if (reset) begin
    packageTmpId = 4'hf;
  end
  if (reset) begin
    replayPkgCnt = 8'h0;
  end
  if (reset) begin
    secondToFirst = 1'h0;
  end
  if (reset) begin
    replayCnt = 8'h0;
  end
  if (reset) begin
    replayCntAllTime = 8'h0;
  end
  if (reset) begin
    replayStateDelay = 1'h0;
  end
  if (reset) begin
    secondToFirstDelay = 1'h0;
  end
  if (reset) begin
    slaveReplayLatency = 12'h400;
  end
  if (reset) begin
    replayCheckCnt = 12'h0;
  end
  if (reset) begin
    creditARW_freeReg = 3'h0;
  end
  if (reset) begin
    creditARW_freeCnt = 2'h0;
  end
  if (reset) begin
    creditARW_freeOutReg = 1'h0;
  end
  if (reset) begin
    replayPkgIDReg = 4'h0;
  end
  if (reset) begin
    replayPkgIDCnt = 3'h0;
  end
  if (reset) begin
    replayPkgIDOutReg = 1'h0;
  end
  if (reset) begin
    rTxDebugReplayState = 32'h0;
  end
  if (reset) begin
    rTxDebugReplayQueue = 32'h0;
  end
  if (reset) begin
    rTxDebugReplayCnt = 32'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SSlaveTxPhy(
  input        io_txLL2PhyIO_clock,
  input        io_txLL2PhyIO_flit_valid,
  input  [7:0] io_txLL2PhyIO_flit_bits,
  input        io_txLL2PhyIO_creditARW_free,
  input        io_txLL2PhyIO_replayPkgID,
  output       io_txPhyIO_clock,
  output       io_txPhyIO_flit_valid,
  output [7:0] io_txPhyIO_flit_bits,
  output       io_txPhyIO_creditARW_free,
  output       io_txPhyIO_replayPkgID
);
  assign io_txPhyIO_clock = io_txLL2PhyIO_clock; // @[Phy.scala 12:20]
  assign io_txPhyIO_flit_valid = io_txLL2PhyIO_flit_valid; // @[Phy.scala 11:19]
  assign io_txPhyIO_flit_bits = io_txLL2PhyIO_flit_bits; // @[Phy.scala 11:19]
  assign io_txPhyIO_creditARW_free = io_txLL2PhyIO_creditARW_free; // @[Phy.scala 13:29]
  assign io_txPhyIO_replayPkgID = io_txLL2PhyIO_replayPkgID; // @[Phy.scala 14:26]
endmodule
module Sd2dSlaveTx(
  input         clock,
  input         reset,
  input         io_txClock,
  output        io_inAXI4R_ready,
  input         io_inAXI4R_valid,
  input  [63:0] io_inAXI4R_bits_data,
  input         io_inAXI4R_bits_last,
  input  [4:0]  io_inAXI4R_bits_id,
  input  [1:0]  io_inAXI4R_bits_resp,
  output        io_inAXI4B_ready,
  input         io_inAXI4B_valid,
  input  [4:0]  io_inAXI4B_bits_id,
  input  [1:0]  io_inAXI4B_bits_resp,
  output        io_tx_clock,
  output        io_tx_flit_valid,
  output [7:0]  io_tx_flit_bits,
  output        io_tx_creditARW_free,
  output        io_tx_replayPkgID,
  output [31:0] io_txDebugReplayState,
  output [31:0] io_txDebugReplayQueue,
  output [31:0] io_txDebugReplayCnt,
  output [2:0]  io_txDebugState,
  input  [11:0] io_inSlaveReplayLatency,
  output        io_rx2TxCreditARWFree_ready,
  input         io_rx2TxCreditARWFree_valid,
  input  [2:0]  io_rx2TxCreditARWFree_bits,
  input         io_rx2TxPackageIDUsed_valid,
  input  [3:0]  io_rx2TxPackageIDUsed_bits,
  input         io_rx2TxCreditRBFree_valid,
  input  [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDOut_ready,
  input         io_rx2TxPackageIDOut_valid,
  input  [3:0]  io_rx2TxPackageIDOut_bits
);
  wire  rstTxSync_clock; // @[D2dSlaveTx.scala 24:25]
  wire  rstTxSync_reset_in; // @[D2dSlaveTx.scala 24:25]
  wire  rstTxSync_reset_out; // @[D2dSlaveTx.scala 24:25]
  wire  SlaveTxAppLayer_io_appInAXI4R_ready; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appInAXI4R_valid; // @[D2dSlaveTx.scala 29:31]
  wire [63:0] SlaveTxAppLayer_io_appInAXI4R_bits_data; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appInAXI4R_bits_last; // @[D2dSlaveTx.scala 29:31]
  wire [4:0] SlaveTxAppLayer_io_appInAXI4R_bits_id; // @[D2dSlaveTx.scala 29:31]
  wire [1:0] SlaveTxAppLayer_io_appInAXI4R_bits_resp; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appInAXI4B_ready; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appInAXI4B_valid; // @[D2dSlaveTx.scala 29:31]
  wire [4:0] SlaveTxAppLayer_io_appInAXI4B_bits_id; // @[D2dSlaveTx.scala 29:31]
  wire [1:0] SlaveTxAppLayer_io_appInAXI4B_bits_resp; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appOutAXI4R_ready; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appOutAXI4R_valid; // @[D2dSlaveTx.scala 29:31]
  wire [71:0] SlaveTxAppLayer_io_appOutAXI4R_bits; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appOutAXI4B_ready; // @[D2dSlaveTx.scala 29:31]
  wire  SlaveTxAppLayer_io_appOutAXI4B_valid; // @[D2dSlaveTx.scala 29:31]
  wire [6:0] SlaveTxAppLayer_io_appOutAXI4B_bits; // @[D2dSlaveTx.scala 29:31]
  wire  asyncQR_wr_clock; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_wr_reset; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_wr_ready; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_wr_valid; // @[D2dSlaveTx.scala 34:23]
  wire [71:0] asyncQR_wr_bits; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_rd_clock; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_rd_reset; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_rd_ready; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQR_rd_valid; // @[D2dSlaveTx.scala 34:23]
  wire [71:0] asyncQR_rd_bits; // @[D2dSlaveTx.scala 34:23]
  wire  asyncQB_wr_clock; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_wr_reset; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_wr_ready; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_wr_valid; // @[D2dSlaveTx.scala 42:23]
  wire [6:0] asyncQB_wr_bits; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_rd_clock; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_rd_reset; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_rd_ready; // @[D2dSlaveTx.scala 42:23]
  wire  asyncQB_rd_valid; // @[D2dSlaveTx.scala 42:23]
  wire [6:0] asyncQB_rd_bits; // @[D2dSlaveTx.scala 42:23]
  wire  slaveTxLinkLayer_clock; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_reset; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_txLL2PhyIO_clock; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_txLL2PhyIO_flit_valid; // @[D2dSlaveTx.scala 50:34]
  wire [7:0] slaveTxLinkLayer_io_txLL2PhyIO_flit_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_txLL2PhyIO_creditARW_free; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_txLL2PhyIO_replayPkgID; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_inAXI4R_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_inAXI4R_valid; // @[D2dSlaveTx.scala 50:34]
  wire [71:0] slaveTxLinkLayer_io_inAXI4R_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_inAXI4B_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_inAXI4B_valid; // @[D2dSlaveTx.scala 50:34]
  wire [6:0] slaveTxLinkLayer_io_inAXI4B_bits; // @[D2dSlaveTx.scala 50:34]
  wire [31:0] slaveTxLinkLayer_io_txDebugReplayState; // @[D2dSlaveTx.scala 50:34]
  wire [31:0] slaveTxLinkLayer_io_txDebugReplayQueue; // @[D2dSlaveTx.scala 50:34]
  wire [31:0] slaveTxLinkLayer_io_txDebugReplayCnt; // @[D2dSlaveTx.scala 50:34]
  wire [2:0] slaveTxLinkLayer_io_txDebugState; // @[D2dSlaveTx.scala 50:34]
  wire [11:0] slaveTxLinkLayer_io_inSlaveReplayLatency; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxCreditARWFree_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxCreditARWFree_valid; // @[D2dSlaveTx.scala 50:34]
  wire [2:0] slaveTxLinkLayer_io_rx2TxCreditARWFree_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxPackageIDUsed_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dSlaveTx.scala 50:34]
  wire [3:0] slaveTxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxCreditRBFree_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxCreditRBFree_valid; // @[D2dSlaveTx.scala 50:34]
  wire [1:0] slaveTxLinkLayer_io_rx2TxCreditRBFree_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxPackageIDOut_ready; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dSlaveTx.scala 50:34]
  wire [3:0] slaveTxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dSlaveTx.scala 50:34]
  wire  slaveTxPhy_io_txLL2PhyIO_clock; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txLL2PhyIO_flit_valid; // @[D2dSlaveTx.scala 51:28]
  wire [7:0] slaveTxPhy_io_txLL2PhyIO_flit_bits; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txLL2PhyIO_creditARW_free; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txLL2PhyIO_replayPkgID; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txPhyIO_clock; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txPhyIO_flit_valid; // @[D2dSlaveTx.scala 51:28]
  wire [7:0] slaveTxPhy_io_txPhyIO_flit_bits; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txPhyIO_creditARW_free; // @[D2dSlaveTx.scala 51:28]
  wire  slaveTxPhy_io_txPhyIO_replayPkgID; // @[D2dSlaveTx.scala 51:28]
  ResetSync_d2d rstTxSync ( // @[D2dSlaveTx.scala 24:25]
    .clock(rstTxSync_clock),
    .reset_in(rstTxSync_reset_in),
    .reset_out(rstTxSync_reset_out)
  );
  SSlaveTxAppLayer SlaveTxAppLayer ( // @[D2dSlaveTx.scala 29:31]
    .io_appInAXI4R_ready(SlaveTxAppLayer_io_appInAXI4R_ready),
    .io_appInAXI4R_valid(SlaveTxAppLayer_io_appInAXI4R_valid),
    .io_appInAXI4R_bits_data(SlaveTxAppLayer_io_appInAXI4R_bits_data),
    .io_appInAXI4R_bits_last(SlaveTxAppLayer_io_appInAXI4R_bits_last),
    .io_appInAXI4R_bits_id(SlaveTxAppLayer_io_appInAXI4R_bits_id),
    .io_appInAXI4R_bits_resp(SlaveTxAppLayer_io_appInAXI4R_bits_resp),
    .io_appInAXI4B_ready(SlaveTxAppLayer_io_appInAXI4B_ready),
    .io_appInAXI4B_valid(SlaveTxAppLayer_io_appInAXI4B_valid),
    .io_appInAXI4B_bits_id(SlaveTxAppLayer_io_appInAXI4B_bits_id),
    .io_appInAXI4B_bits_resp(SlaveTxAppLayer_io_appInAXI4B_bits_resp),
    .io_appOutAXI4R_ready(SlaveTxAppLayer_io_appOutAXI4R_ready),
    .io_appOutAXI4R_valid(SlaveTxAppLayer_io_appOutAXI4R_valid),
    .io_appOutAXI4R_bits(SlaveTxAppLayer_io_appOutAXI4R_bits),
    .io_appOutAXI4B_ready(SlaveTxAppLayer_io_appOutAXI4B_ready),
    .io_appOutAXI4B_valid(SlaveTxAppLayer_io_appOutAXI4B_valid),
    .io_appOutAXI4B_bits(SlaveTxAppLayer_io_appOutAXI4B_bits)
  );
  SAsyncQueue asyncQR ( // @[D2dSlaveTx.scala 34:23]
    .wr_clock(asyncQR_wr_clock),
    .wr_reset(asyncQR_wr_reset),
    .wr_ready(asyncQR_wr_ready),
    .wr_valid(asyncQR_wr_valid),
    .wr_bits(asyncQR_wr_bits),
    .rd_clock(asyncQR_rd_clock),
    .rd_reset(asyncQR_rd_reset),
    .rd_ready(asyncQR_rd_ready),
    .rd_valid(asyncQR_rd_valid),
    .rd_bits(asyncQR_rd_bits)
  );
  SAsyncQueue_1 asyncQB ( // @[D2dSlaveTx.scala 42:23]
    .wr_clock(asyncQB_wr_clock),
    .wr_reset(asyncQB_wr_reset),
    .wr_ready(asyncQB_wr_ready),
    .wr_valid(asyncQB_wr_valid),
    .wr_bits(asyncQB_wr_bits),
    .rd_clock(asyncQB_rd_clock),
    .rd_reset(asyncQB_rd_reset),
    .rd_ready(asyncQB_rd_ready),
    .rd_valid(asyncQB_rd_valid),
    .rd_bits(asyncQB_rd_bits)
  );
  SSlaveTxLinkLayer slaveTxLinkLayer ( // @[D2dSlaveTx.scala 50:34]
    .clock(slaveTxLinkLayer_clock),
    .reset(slaveTxLinkLayer_reset),
    .io_txLL2PhyIO_clock(slaveTxLinkLayer_io_txLL2PhyIO_clock),
    .io_txLL2PhyIO_flit_valid(slaveTxLinkLayer_io_txLL2PhyIO_flit_valid),
    .io_txLL2PhyIO_flit_bits(slaveTxLinkLayer_io_txLL2PhyIO_flit_bits),
    .io_txLL2PhyIO_creditARW_free(slaveTxLinkLayer_io_txLL2PhyIO_creditARW_free),
    .io_txLL2PhyIO_replayPkgID(slaveTxLinkLayer_io_txLL2PhyIO_replayPkgID),
    .io_inAXI4R_ready(slaveTxLinkLayer_io_inAXI4R_ready),
    .io_inAXI4R_valid(slaveTxLinkLayer_io_inAXI4R_valid),
    .io_inAXI4R_bits(slaveTxLinkLayer_io_inAXI4R_bits),
    .io_inAXI4B_ready(slaveTxLinkLayer_io_inAXI4B_ready),
    .io_inAXI4B_valid(slaveTxLinkLayer_io_inAXI4B_valid),
    .io_inAXI4B_bits(slaveTxLinkLayer_io_inAXI4B_bits),
    .io_txDebugReplayState(slaveTxLinkLayer_io_txDebugReplayState),
    .io_txDebugReplayQueue(slaveTxLinkLayer_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(slaveTxLinkLayer_io_txDebugReplayCnt),
    .io_txDebugState(slaveTxLinkLayer_io_txDebugState),
    .io_inSlaveReplayLatency(slaveTxLinkLayer_io_inSlaveReplayLatency),
    .io_rx2TxCreditARWFree_ready(slaveTxLinkLayer_io_rx2TxCreditARWFree_ready),
    .io_rx2TxCreditARWFree_valid(slaveTxLinkLayer_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(slaveTxLinkLayer_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_ready(slaveTxLinkLayer_io_rx2TxPackageIDUsed_ready),
    .io_rx2TxPackageIDUsed_valid(slaveTxLinkLayer_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(slaveTxLinkLayer_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_ready(slaveTxLinkLayer_io_rx2TxCreditRBFree_ready),
    .io_rx2TxCreditRBFree_valid(slaveTxLinkLayer_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(slaveTxLinkLayer_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_ready(slaveTxLinkLayer_io_rx2TxPackageIDOut_ready),
    .io_rx2TxPackageIDOut_valid(slaveTxLinkLayer_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(slaveTxLinkLayer_io_rx2TxPackageIDOut_bits)
  );
  SSlaveTxPhy slaveTxPhy ( // @[D2dSlaveTx.scala 51:28]
    .io_txLL2PhyIO_clock(slaveTxPhy_io_txLL2PhyIO_clock),
    .io_txLL2PhyIO_flit_valid(slaveTxPhy_io_txLL2PhyIO_flit_valid),
    .io_txLL2PhyIO_flit_bits(slaveTxPhy_io_txLL2PhyIO_flit_bits),
    .io_txLL2PhyIO_creditARW_free(slaveTxPhy_io_txLL2PhyIO_creditARW_free),
    .io_txLL2PhyIO_replayPkgID(slaveTxPhy_io_txLL2PhyIO_replayPkgID),
    .io_txPhyIO_clock(slaveTxPhy_io_txPhyIO_clock),
    .io_txPhyIO_flit_valid(slaveTxPhy_io_txPhyIO_flit_valid),
    .io_txPhyIO_flit_bits(slaveTxPhy_io_txPhyIO_flit_bits),
    .io_txPhyIO_creditARW_free(slaveTxPhy_io_txPhyIO_creditARW_free),
    .io_txPhyIO_replayPkgID(slaveTxPhy_io_txPhyIO_replayPkgID)
  );
  assign io_inAXI4R_ready = SlaveTxAppLayer_io_appInAXI4R_ready; // @[D2dSlaveTx.scala 30:33]
  assign io_inAXI4B_ready = SlaveTxAppLayer_io_appInAXI4B_ready; // @[D2dSlaveTx.scala 31:33]
  assign io_tx_clock = slaveTxPhy_io_txPhyIO_clock; // @[D2dSlaveTx.scala 56:11]
  assign io_tx_flit_valid = slaveTxPhy_io_txPhyIO_flit_valid; // @[D2dSlaveTx.scala 56:11]
  assign io_tx_flit_bits = slaveTxPhy_io_txPhyIO_flit_bits; // @[D2dSlaveTx.scala 56:11]
  assign io_tx_creditARW_free = slaveTxPhy_io_txPhyIO_creditARW_free; // @[D2dSlaveTx.scala 56:11]
  assign io_tx_replayPkgID = slaveTxPhy_io_txPhyIO_replayPkgID; // @[D2dSlaveTx.scala 56:11]
  assign io_txDebugReplayState = slaveTxLinkLayer_io_txDebugReplayState; // @[D2dSlaveTx.scala 59:27]
  assign io_txDebugReplayQueue = slaveTxLinkLayer_io_txDebugReplayQueue; // @[D2dSlaveTx.scala 58:27]
  assign io_txDebugReplayCnt = slaveTxLinkLayer_io_txDebugReplayCnt; // @[D2dSlaveTx.scala 60:25]
  assign io_txDebugState = slaveTxLinkLayer_io_txDebugState; // @[D2dSlaveTx.scala 61:21]
  assign io_rx2TxCreditARWFree_ready = slaveTxLinkLayer_io_rx2TxCreditARWFree_ready; // @[D2dSlaveTx.scala 64:27]
  assign io_rx2TxPackageIDOut_ready = slaveTxLinkLayer_io_rx2TxPackageIDOut_ready; // @[D2dSlaveTx.scala 67:26]
  assign rstTxSync_clock = io_txClock; // @[D2dSlaveTx.scala 25:22]
  assign rstTxSync_reset_in = reset; // @[D2dSlaveTx.scala 26:46]
  assign SlaveTxAppLayer_io_appInAXI4R_valid = io_inAXI4R_valid; // @[D2dSlaveTx.scala 30:33]
  assign SlaveTxAppLayer_io_appInAXI4R_bits_data = io_inAXI4R_bits_data; // @[D2dSlaveTx.scala 30:33]
  assign SlaveTxAppLayer_io_appInAXI4R_bits_last = io_inAXI4R_bits_last; // @[D2dSlaveTx.scala 30:33]
  assign SlaveTxAppLayer_io_appInAXI4R_bits_id = io_inAXI4R_bits_id; // @[D2dSlaveTx.scala 30:33]
  assign SlaveTxAppLayer_io_appInAXI4R_bits_resp = io_inAXI4R_bits_resp; // @[D2dSlaveTx.scala 30:33]
  assign SlaveTxAppLayer_io_appInAXI4B_valid = io_inAXI4B_valid; // @[D2dSlaveTx.scala 31:33]
  assign SlaveTxAppLayer_io_appInAXI4B_bits_id = io_inAXI4B_bits_id; // @[D2dSlaveTx.scala 31:33]
  assign SlaveTxAppLayer_io_appInAXI4B_bits_resp = io_inAXI4B_bits_resp; // @[D2dSlaveTx.scala 31:33]
  assign SlaveTxAppLayer_io_appOutAXI4R_ready = asyncQR_wr_ready; // @[D2dSlaveTx.scala 39:34]
  assign SlaveTxAppLayer_io_appOutAXI4B_ready = asyncQB_wr_ready; // @[D2dSlaveTx.scala 47:34]
  assign asyncQR_wr_clock = clock; // @[D2dSlaveTx.scala 35:20]
  assign asyncQR_wr_reset = reset; // @[D2dSlaveTx.scala 36:41]
  assign asyncQR_wr_valid = SlaveTxAppLayer_io_appOutAXI4R_valid; // @[D2dSlaveTx.scala 39:34]
  assign asyncQR_wr_bits = SlaveTxAppLayer_io_appOutAXI4R_bits; // @[D2dSlaveTx.scala 39:34]
  assign asyncQR_rd_clock = io_txClock; // @[D2dSlaveTx.scala 37:20]
  assign asyncQR_rd_reset = rstTxSync_reset_out; // @[D2dSlaveTx.scala 38:20]
  assign asyncQR_rd_ready = slaveTxLinkLayer_io_inAXI4R_ready; // @[D2dSlaveTx.scala 52:33]
  assign asyncQB_wr_clock = clock; // @[D2dSlaveTx.scala 43:20]
  assign asyncQB_wr_reset = reset; // @[D2dSlaveTx.scala 44:41]
  assign asyncQB_wr_valid = SlaveTxAppLayer_io_appOutAXI4B_valid; // @[D2dSlaveTx.scala 47:34]
  assign asyncQB_wr_bits = SlaveTxAppLayer_io_appOutAXI4B_bits; // @[D2dSlaveTx.scala 47:34]
  assign asyncQB_rd_clock = io_txClock; // @[D2dSlaveTx.scala 45:20]
  assign asyncQB_rd_reset = rstTxSync_reset_out; // @[D2dSlaveTx.scala 46:20]
  assign asyncQB_rd_ready = slaveTxLinkLayer_io_inAXI4B_ready; // @[D2dSlaveTx.scala 53:33]
  assign slaveTxLinkLayer_clock = io_txClock;
  assign slaveTxLinkLayer_reset = rstTxSync_reset_out;
  assign slaveTxLinkLayer_io_inAXI4R_valid = asyncQR_rd_valid; // @[D2dSlaveTx.scala 52:33]
  assign slaveTxLinkLayer_io_inAXI4R_bits = asyncQR_rd_bits; // @[D2dSlaveTx.scala 52:33]
  assign slaveTxLinkLayer_io_inAXI4B_valid = asyncQB_rd_valid; // @[D2dSlaveTx.scala 53:33]
  assign slaveTxLinkLayer_io_inAXI4B_bits = asyncQB_rd_bits; // @[D2dSlaveTx.scala 53:33]
  assign slaveTxLinkLayer_io_inSlaveReplayLatency = io_inSlaveReplayLatency; // @[D2dSlaveTx.scala 62:46]
  assign slaveTxLinkLayer_io_rx2TxCreditARWFree_valid = io_rx2TxCreditARWFree_valid; // @[D2dSlaveTx.scala 64:27]
  assign slaveTxLinkLayer_io_rx2TxCreditARWFree_bits = io_rx2TxCreditARWFree_bits; // @[D2dSlaveTx.scala 64:27]
  assign slaveTxLinkLayer_io_rx2TxPackageIDUsed_valid = io_rx2TxPackageIDUsed_valid; // @[D2dSlaveTx.scala 65:27]
  assign slaveTxLinkLayer_io_rx2TxPackageIDUsed_bits = io_rx2TxPackageIDUsed_bits; // @[D2dSlaveTx.scala 65:27]
  assign slaveTxLinkLayer_io_rx2TxCreditRBFree_valid = io_rx2TxCreditRBFree_valid; // @[D2dSlaveTx.scala 66:26]
  assign slaveTxLinkLayer_io_rx2TxCreditRBFree_bits = io_rx2TxCreditRBFree_bits; // @[D2dSlaveTx.scala 66:26]
  assign slaveTxLinkLayer_io_rx2TxPackageIDOut_valid = io_rx2TxPackageIDOut_valid; // @[D2dSlaveTx.scala 67:26]
  assign slaveTxLinkLayer_io_rx2TxPackageIDOut_bits = io_rx2TxPackageIDOut_bits; // @[D2dSlaveTx.scala 67:26]
  assign slaveTxPhy_io_txLL2PhyIO_clock = slaveTxLinkLayer_io_txLL2PhyIO_clock; // @[D2dSlaveTx.scala 54:36]
  assign slaveTxPhy_io_txLL2PhyIO_flit_valid = slaveTxLinkLayer_io_txLL2PhyIO_flit_valid; // @[D2dSlaveTx.scala 54:36]
  assign slaveTxPhy_io_txLL2PhyIO_flit_bits = slaveTxLinkLayer_io_txLL2PhyIO_flit_bits; // @[D2dSlaveTx.scala 54:36]
  assign slaveTxPhy_io_txLL2PhyIO_creditARW_free = slaveTxLinkLayer_io_txLL2PhyIO_creditARW_free; // @[D2dSlaveTx.scala 54:36]
  assign slaveTxPhy_io_txLL2PhyIO_replayPkgID = slaveTxLinkLayer_io_txLL2PhyIO_replayPkgID; // @[D2dSlaveTx.scala 54:36]
endmodule
module SAsyncFifoMemory_2(
  input         wr_clock,
  input         wr_en,
  input  [3:0]  wr_addr,
  input  [72:0] wr_data,
  input         rd_clock,
  input         rd_en,
  input  [3:0]  rd_addr,
  output [72:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [95:0] _RAND_2;
  reg [95:0] _RAND_3;
  reg [95:0] _RAND_4;
  reg [95:0] _RAND_5;
  reg [95:0] _RAND_6;
  reg [95:0] _RAND_7;
  reg [95:0] _RAND_8;
  reg [95:0] _RAND_9;
  reg [95:0] _RAND_10;
  reg [95:0] _RAND_11;
  reg [95:0] _RAND_12;
  reg [95:0] _RAND_13;
  reg [95:0] _RAND_14;
  reg [95:0] _RAND_15;
  reg [95:0] _RAND_16;
`endif // RANDOMIZE_REG_INIT
  reg [72:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_4; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_5; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_6; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_7; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_8; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_9; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_10; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_11; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_12; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_13; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_14; // @[AsyncFifo.scala 43:18]
  reg [72:0] mem_15; // @[AsyncFifo.scala 43:18]
  reg [72:0] rd_data_r; // @[Reg.scala 19:16]
  wire [72:0] _GEN_33 = 4'h1 == rd_addr ? mem_1 : mem_0; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_34 = 4'h2 == rd_addr ? mem_2 : _GEN_33; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_35 = 4'h3 == rd_addr ? mem_3 : _GEN_34; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_36 = 4'h4 == rd_addr ? mem_4 : _GEN_35; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_37 = 4'h5 == rd_addr ? mem_5 : _GEN_36; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_38 = 4'h6 == rd_addr ? mem_6 : _GEN_37; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_39 = 4'h7 == rd_addr ? mem_7 : _GEN_38; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_40 = 4'h8 == rd_addr ? mem_8 : _GEN_39; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_41 = 4'h9 == rd_addr ? mem_9 : _GEN_40; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_42 = 4'ha == rd_addr ? mem_10 : _GEN_41; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_43 = 4'hb == rd_addr ? mem_11 : _GEN_42; // @[Reg.scala 20:{22,22}]
  wire [72:0] _GEN_44 = 4'hc == rd_addr ? mem_12 : _GEN_43; // @[Reg.scala 20:{22,22}]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h4 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_4 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h5 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_5 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h6 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_6 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h7 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_7 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h8 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_8 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'h9 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_9 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'ha == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_10 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hb == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_11 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hc == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_12 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hd == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_13 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'he == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_14 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (4'hf == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_15 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (4'hf == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_15; // @[Reg.scala 20:22]
      end else if (4'he == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_14; // @[Reg.scala 20:22]
      end else if (4'hd == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_13; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= _GEN_44;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  mem_0 = _RAND_0[72:0];
  _RAND_1 = {3{`RANDOM}};
  mem_1 = _RAND_1[72:0];
  _RAND_2 = {3{`RANDOM}};
  mem_2 = _RAND_2[72:0];
  _RAND_3 = {3{`RANDOM}};
  mem_3 = _RAND_3[72:0];
  _RAND_4 = {3{`RANDOM}};
  mem_4 = _RAND_4[72:0];
  _RAND_5 = {3{`RANDOM}};
  mem_5 = _RAND_5[72:0];
  _RAND_6 = {3{`RANDOM}};
  mem_6 = _RAND_6[72:0];
  _RAND_7 = {3{`RANDOM}};
  mem_7 = _RAND_7[72:0];
  _RAND_8 = {3{`RANDOM}};
  mem_8 = _RAND_8[72:0];
  _RAND_9 = {3{`RANDOM}};
  mem_9 = _RAND_9[72:0];
  _RAND_10 = {3{`RANDOM}};
  mem_10 = _RAND_10[72:0];
  _RAND_11 = {3{`RANDOM}};
  mem_11 = _RAND_11[72:0];
  _RAND_12 = {3{`RANDOM}};
  mem_12 = _RAND_12[72:0];
  _RAND_13 = {3{`RANDOM}};
  mem_13 = _RAND_13[72:0];
  _RAND_14 = {3{`RANDOM}};
  mem_14 = _RAND_14[72:0];
  _RAND_15 = {3{`RANDOM}};
  mem_15 = _RAND_15[72:0];
  _RAND_16 = {3{`RANDOM}};
  rd_data_r = _RAND_16[72:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_2(
  input         wr_clock,
  input         wr_reset,
  input  [72:0] wr_data,
  input         wr_push,
  output        wr_full,
  input         rd_clock,
  input         rd_reset,
  output [72:0] rd_data,
  input         rd_pop,
  output        rd_empty,
  output        rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [72:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [72:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [4:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [4:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [4:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [4:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [4:0] _GEN_4 = {{4'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [4:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [4:0] _GEN_5 = {{1'd0}, wrAddrBinNext[4:1]}; // @[AsyncFifo.scala 85:49]
  wire [4:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [4:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[4:3]; // @[AsyncFifo.scala 101:27]
  wire [4:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[2:0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [4:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [4:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [4:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [4:0] _GEN_6 = {{4'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [4:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [4:0] _GEN_7 = {{1'd0}, rdAddrBinNext[4:1]}; // @[AsyncFifo.scala 85:49]
  wire [4:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_2 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[3:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[3:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 5'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 5'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 5'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 5'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 5'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[4:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[4:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[4:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[4:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[4:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[4:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[4:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[4:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 5'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 5'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 5'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 5'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 5'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 5'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 5'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 5'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_2(
  input         wr_clock,
  input         wr_reset,
  input         wr_valid,
  input  [72:0] wr_bits,
  input         rd_clock,
  input         rd_reset,
  input         rd_ready,
  output        rd_valid,
  output [72:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [72:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [72:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [72:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_2 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  outReg = _RAND_0[72:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifoMemory_3(
  input         wr_clock,
  input         wr_en,
  input  [1:0]  wr_addr,
  input  [65:0] wr_data,
  input         rd_clock,
  input         rd_en,
  input  [1:0]  rd_addr,
  output [65:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [95:0] _RAND_2;
  reg [95:0] _RAND_3;
  reg [95:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  reg [65:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [65:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [65:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [65:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [65:0] rd_data_r; // @[Reg.scala 19:16]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (2'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (2'h3 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_3; // @[Reg.scala 20:22]
      end else if (2'h2 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_2; // @[Reg.scala 20:22]
      end else if (2'h1 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_1; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= mem_0;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  mem_0 = _RAND_0[65:0];
  _RAND_1 = {3{`RANDOM}};
  mem_1 = _RAND_1[65:0];
  _RAND_2 = {3{`RANDOM}};
  mem_2 = _RAND_2[65:0];
  _RAND_3 = {3{`RANDOM}};
  mem_3 = _RAND_3[65:0];
  _RAND_4 = {3{`RANDOM}};
  rd_data_r = _RAND_4[65:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_3(
  input         wr_clock,
  input         wr_reset,
  input  [65:0] wr_data,
  input         wr_push,
  output        wr_full,
  input         rd_clock,
  input         rd_reset,
  output [65:0] rd_data,
  input         rd_pop,
  output        rd_empty,
  output        rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [65:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [65:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [2:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [2:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [2:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [2:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [2:0] _GEN_4 = {{2'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [2:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [2:0] _GEN_5 = {{1'd0}, wrAddrBinNext[2:1]}; // @[AsyncFifo.scala 85:49]
  wire [2:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [2:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[2:1]; // @[AsyncFifo.scala 101:27]
  wire [2:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [2:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [2:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [2:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [2:0] _GEN_6 = {{2'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [2:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [2:0] _GEN_7 = {{1'd0}, rdAddrBinNext[2:1]}; // @[AsyncFifo.scala 85:49]
  wire [2:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_3 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[1:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[1:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 3'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 3'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 3'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 3'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 3'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[2:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[2:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[2:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[2:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[2:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 3'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 3'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 3'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 3'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 3'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 3'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 3'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 3'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_3(
  input         wr_clock,
  input         wr_reset,
  input         wr_valid,
  input  [65:0] wr_bits,
  input         rd_clock,
  input         rd_reset,
  input         rd_ready,
  output        rd_valid,
  output [65:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [95:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [65:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [65:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [65:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_3 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {3{`RANDOM}};
  outReg = _RAND_0[65:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module ScrcGen_4(
  input  [85:0] io_in,
  output [15:0] io_out
);
  wire [87:0] paddedData = {2'h0,io_in}; // @[Cat.scala 33:92]
  wire  xorList_0_0 = paddedData[56]; // @[crcGen.scala 80:41]
  wire  xorList_0_1 = paddedData[14]; // @[crcGen.scala 80:41]
  wire  xorList_0_2 = paddedData[46]; // @[crcGen.scala 80:41]
  wire  xorList_0_3 = paddedData[84]; // @[crcGen.scala 80:41]
  wire  xorList_0_4 = paddedData[61]; // @[crcGen.scala 80:41]
  wire  xorList_0_5 = paddedData[53]; // @[crcGen.scala 80:41]
  wire  xorList_0_6 = paddedData[77]; // @[crcGen.scala 80:41]
  wire  xorList_0_7 = paddedData[13]; // @[crcGen.scala 80:41]
  wire  xorList_0_8 = paddedData[2]; // @[crcGen.scala 80:41]
  wire  xorList_0_9 = paddedData[32]; // @[crcGen.scala 80:41]
  wire  xorList_0_10 = paddedData[22]; // @[crcGen.scala 80:41]
  wire  xorList_0_11 = paddedData[66]; // @[crcGen.scala 80:41]
  wire  xorList_0_12 = paddedData[80]; // @[crcGen.scala 80:41]
  wire  xorList_0_13 = paddedData[16]; // @[crcGen.scala 80:41]
  wire  xorList_0_14 = paddedData[11]; // @[crcGen.scala 80:41]
  wire  xorList_0_15 = paddedData[8]; // @[crcGen.scala 80:41]
  wire  xorList_0_16 = paddedData[4]; // @[crcGen.scala 80:41]
  wire  xorList_0_17 = paddedData[69]; // @[crcGen.scala 80:41]
  wire  xorList_0_18 = paddedData[0]; // @[crcGen.scala 80:41]
  wire  xorList_0_19 = paddedData[24]; // @[crcGen.scala 80:41]
  wire  xorList_0_20 = paddedData[37]; // @[crcGen.scala 80:41]
  wire  xorList_0_21 = paddedData[25]; // @[crcGen.scala 80:41]
  wire  xorList_0_22 = paddedData[6]; // @[crcGen.scala 80:41]
  wire  xorList_0_23 = paddedData[60]; // @[crcGen.scala 80:41]
  wire  xorList_0_24 = paddedData[21]; // @[crcGen.scala 80:41]
  wire  xorList_0_25 = paddedData[33]; // @[crcGen.scala 80:41]
  wire  xorList_0_26 = paddedData[76]; // @[crcGen.scala 80:41]
  wire  xorList_0_27 = paddedData[7]; // @[crcGen.scala 80:41]
  wire  xorList_0_28 = paddedData[39]; // @[crcGen.scala 80:41]
  wire  xorList_0_29 = paddedData[18]; // @[crcGen.scala 80:41]
  wire  xorList_0_31 = paddedData[40]; // @[crcGen.scala 80:41]
  wire  xorList_0_32 = paddedData[55]; // @[crcGen.scala 80:41]
  wire  xorList_0_33 = paddedData[23]; // @[crcGen.scala 80:41]
  wire  xorList_0_34 = paddedData[36]; // @[crcGen.scala 80:41]
  wire  xorList_0_35 = paddedData[30]; // @[crcGen.scala 80:41]
  wire  xorList_0_36 = paddedData[68]; // @[crcGen.scala 80:41]
  wire  xorList_0_37 = paddedData[62]; // @[crcGen.scala 80:41]
  wire  _crcCalc_0_T_29 = xorList_0_0 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_0_3 ^ xorList_0_4 ^ xorList_0_5 ^
    xorList_0_6 ^ xorList_0_7 ^ xorList_0_8 ^ xorList_0_9 ^ xorList_0_10 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_0_13 ^
    xorList_0_14 ^ xorList_0_15 ^ xorList_0_16 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^
    xorList_0_21 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_0_28 ^ xorList_0_29 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  crcCalc_0 = _crcCalc_0_T_29 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_0_33 ^ xorList_0_34 ^ xorList_0_35 ^
    xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_1_1 = paddedData[5]; // @[crcGen.scala 80:41]
  wire  xorList_1_4 = paddedData[85]; // @[crcGen.scala 80:41]
  wire  xorList_1_5 = paddedData[9]; // @[crcGen.scala 80:41]
  wire  xorList_1_7 = paddedData[41]; // @[crcGen.scala 80:41]
  wire  xorList_1_9 = paddedData[3]; // @[crcGen.scala 80:41]
  wire  xorList_1_11 = paddedData[19]; // @[crcGen.scala 80:41]
  wire  xorList_1_15 = paddedData[57]; // @[crcGen.scala 80:41]
  wire  xorList_1_16 = paddedData[78]; // @[crcGen.scala 80:41]
  wire  xorList_1_18 = paddedData[1]; // @[crcGen.scala 80:41]
  wire  xorList_1_19 = paddedData[38]; // @[crcGen.scala 80:41]
  wire  xorList_1_20 = paddedData[70]; // @[crcGen.scala 80:41]
  wire  xorList_1_22 = paddedData[34]; // @[crcGen.scala 80:41]
  wire  xorList_1_23 = paddedData[17]; // @[crcGen.scala 80:41]
  wire  xorList_1_24 = paddedData[12]; // @[crcGen.scala 80:41]
  wire  xorList_1_25 = paddedData[54]; // @[crcGen.scala 80:41]
  wire  xorList_1_26 = paddedData[81]; // @[crcGen.scala 80:41]
  wire  xorList_1_28 = paddedData[63]; // @[crcGen.scala 80:41]
  wire  xorList_1_30 = paddedData[67]; // @[crcGen.scala 80:41]
  wire  xorList_1_31 = paddedData[31]; // @[crcGen.scala 80:41]
  wire  xorList_1_33 = paddedData[26]; // @[crcGen.scala 80:41]
  wire  xorList_1_35 = paddedData[47]; // @[crcGen.scala 80:41]
  wire  xorList_1_36 = paddedData[15]; // @[crcGen.scala 80:41]
  wire  _crcCalc_1_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_0 ^ xorList_0_1 ^ xorList_1_4 ^ xorList_1_5 ^
    xorList_0_6 ^ xorList_1_7 ^ xorList_0_10 ^ xorList_1_9 ^ xorList_0_15 ^ xorList_1_11 ^ xorList_0_19 ^ xorList_0_20
     ^ xorList_0_21 ^ xorList_1_15 ^ xorList_1_16 ^ xorList_0_4 ^ xorList_1_18 ^ xorList_1_19 ^ xorList_1_20 ^
    xorList_0_25 ^ xorList_1_22 ^ xorList_1_23 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_1_26 ^ xorList_0_27 ^
    xorList_1_28 ^ 1'h1 ^ xorList_1_30; // @[crcGen.scala 87:38]
  wire  crcCalc_1 = _crcCalc_1_T_29 ^ xorList_1_31 ^ xorList_0_31 ^ xorList_1_33 ^ xorList_0_33 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_2_0 = paddedData[10]; // @[crcGen.scala 80:41]
  wire  xorList_2_4 = paddedData[27]; // @[crcGen.scala 80:41]
  wire  xorList_2_6 = paddedData[35]; // @[crcGen.scala 80:41]
  wire  xorList_2_8 = paddedData[42]; // @[crcGen.scala 80:41]
  wire  xorList_2_11 = paddedData[20]; // @[crcGen.scala 80:41]
  wire  xorList_2_18 = paddedData[64]; // @[crcGen.scala 80:41]
  wire  xorList_2_21 = paddedData[71]; // @[crcGen.scala 80:41]
  wire  xorList_2_22 = paddedData[86]; // @[crcGen.scala 80:41]
  wire  xorList_2_23 = paddedData[48]; // @[crcGen.scala 80:41]
  wire  xorList_2_30 = paddedData[58]; // @[crcGen.scala 80:41]
  wire  xorList_2_31 = paddedData[82]; // @[crcGen.scala 80:41]
  wire  xorList_2_33 = paddedData[79]; // @[crcGen.scala 80:41]
  wire  _crcCalc_2_T_29 = xorList_2_0 ^ xorList_0_22 ^ xorList_1_5 ^ xorList_0_8 ^ xorList_2_4 ^ xorList_0_28 ^
    xorList_2_6 ^ xorList_0_13 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_21 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_1_16
     ^ xorList_1_19 ^ xorList_1_20 ^ xorList_0_7 ^ xorList_1_7 ^ xorList_2_18 ^ xorList_0_9 ^ xorList_1_22 ^
    xorList_2_21 ^ xorList_2_22 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_1_33 ^ xorList_0_32 ^
    xorList_0_33 ^ xorList_0_15 ^ xorList_2_30; // @[crcGen.scala 87:38]
  wire  crcCalc_2 = _crcCalc_2_T_29 ^ xorList_2_31 ^ xorList_0_16 ^ xorList_2_33 ^ xorList_1_36 ^ xorList_0_36 ^
    xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_3_3 = paddedData[65]; // @[crcGen.scala 80:41]
  wire  xorList_3_6 = paddedData[87]; // @[crcGen.scala 80:41]
  wire  xorList_3_9 = paddedData[83]; // @[crcGen.scala 80:41]
  wire  xorList_3_15 = paddedData[28]; // @[crcGen.scala 80:41]
  wire  xorList_3_20 = paddedData[59]; // @[crcGen.scala 80:41]
  wire  xorList_3_23 = paddedData[49]; // @[crcGen.scala 80:41]
  wire  xorList_3_32 = paddedData[72]; // @[crcGen.scala 80:41]
  wire  xorList_3_33 = paddedData[43]; // @[crcGen.scala 80:41]
  wire  _crcCalc_3_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_1 ^ xorList_3_3 ^ xorList_1_5 ^ xorList_0_13 ^
    xorList_3_6 ^ xorList_2_30 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_2_8 ^ xorList_0_19 ^
    xorList_0_21 ^ xorList_3_15 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_3_20 ^ xorList_2_4
     ^ xorList_2_21 ^ xorList_3_23 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_1_9 ^ xorList_0_12 ^ xorList_2_6 ^
    xorList_1_28 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  crcCalc_3 = _crcCalc_3_T_29 ^ xorList_0_14 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_0_31 ^ xorList_1_33 ^
    xorList_0_34 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  xorList_4_15 = paddedData[29]; // @[crcGen.scala 80:41]
  wire  xorList_4_22 = paddedData[73]; // @[crcGen.scala 80:41]
  wire  xorList_4_28 = paddedData[44]; // @[crcGen.scala 80:41]
  wire  xorList_4_35 = paddedData[50]; // @[crcGen.scala 80:41]
  wire  _crcCalc_4_T_29 = xorList_0_19 ^ xorList_0_1 ^ xorList_0_4 ^ xorList_3_3 ^ xorList_0_5 ^ xorList_0_6 ^
    xorList_1_24 ^ xorList_0_35 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_2_11 ^ xorList_0_2
     ^ xorList_1_15 ^ xorList_4_15 ^ xorList_3_15 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_7 ^
    xorList_1_7 ^ xorList_4_22 ^ xorList_0_8 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_4_28
     ^ xorList_3_20 ^ xorList_2_4; // @[crcGen.scala 87:38]
  wire  crcCalc_4 = _crcCalc_4_T_29 ^ xorList_1_26 ^ xorList_0_26 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_4_35 ^
    xorList_0_13 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_1_33 ^ xorList_0_32 ^ xorList_0_33 ^ xorList_1_36 ^
    xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_5_18 = paddedData[74]; // @[crcGen.scala 80:41]
  wire  xorList_5_24 = paddedData[45]; // @[crcGen.scala 80:41]
  wire  xorList_5_42 = paddedData[51]; // @[crcGen.scala 80:41]
  wire  _crcCalc_5_T_29 = xorList_0_17 ^ xorList_0_0 ^ xorList_0_1 ^ xorList_0_23 ^ xorList_3_3 ^ xorList_0_6 ^
    xorList_0_7 ^ xorList_4_22 ^ xorList_0_11 ^ xorList_0_14 ^ xorList_0_31 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_21
     ^ xorList_1_15 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_1_18 ^ xorList_5_18 ^ xorList_3_15 ^ xorList_1_20 ^
    xorList_0_24 ^ xorList_0_25 ^ xorList_1_22 ^ xorList_5_24 ^ xorList_1_23 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_2_4
     ^ xorList_2_21 ^ xorList_1_25; // @[crcGen.scala 87:38]
  wire  crcCalc_5 = _crcCalc_5_T_29 ^ xorList_1_9 ^ xorList_2_6 ^ xorList_1_28 ^ xorList_0_29 ^ 1'h1 ^ xorList_0_13 ^
    xorList_1_31 ^ xorList_0_15 ^ xorList_2_30 ^ xorList_2_31 ^ xorList_0_35 ^ xorList_5_42 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  xorList_6_8 = paddedData[52]; // @[crcGen.scala 80:41]
  wire  xorList_6_38 = paddedData[75]; // @[crcGen.scala 80:41]
  wire  _crcCalc_6_T_29 = xorList_0_21 ^ xorList_1_5 ^ xorList_1_7 ^ xorList_0_8 ^ xorList_0_11 ^ xorList_2_6 ^
    xorList_1_36 ^ xorList_3_9 ^ xorList_6_8 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_1_15 ^ xorList_1_16 ^ xorList_4_15 ^
    xorList_0_4 ^ xorList_5_18 ^ xorList_3_15 ^ xorList_1_20 ^ xorList_5_24 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9
     ^ xorList_1_22 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_21 ^ xorList_1_24 ^ xorList_2_23 ^ xorList_1_28 ^
    xorList_0_29 ^ xorList_1_30; // @[crcGen.scala 87:38]
  wire  crcCalc_6 = _crcCalc_6_T_29 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_1_33 ^
    xorList_0_32 ^ xorList_0_33 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^ xorList_1_11 ^
    xorList_0_16 ^ xorList_2_33; // @[crcGen.scala 87:38]
  wire  _crcCalc_7_T_29 = xorList_0_18 ^ xorList_1_1 ^ xorList_0_3 ^ xorList_0_23 ^ xorList_0_25 ^ xorList_3_3 ^
    xorList_0_5 ^ xorList_0_7 ^ xorList_4_22 ^ xorList_0_26 ^ xorList_0_29 ^ xorList_3_32 ^ xorList_2_33 ^ xorList_2_0
     ^ xorList_0_0 ^ xorList_2_8 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_2_11 ^ xorList_0_2 ^ xorList_4_15 ^ xorList_0_9
     ^ xorList_2_18 ^ xorList_1_23 ^ xorList_4_28 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_2_21 ^ xorList_3_23 ^
    xorList_1_9 ^ xorList_0_12; // @[crcGen.scala 87:38]
  wire  crcCalc_7 = _crcCalc_7_T_29 ^ xorList_2_6 ^ xorList_1_30 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_1_33 ^
    xorList_0_33 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_8_T_29 = xorList_0_1 ^ xorList_3_3 ^ xorList_0_6 ^ xorList_4_22 ^ xorList_1_25 ^ xorList_0_11 ^
    xorList_0_12 ^ xorList_0_16 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_0_21 ^
    xorList_2_11 ^ xorList_1_15 ^ xorList_0_4 ^ xorList_1_18 ^ xorList_5_18 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_1_4
     ^ xorList_0_24 ^ xorList_0_25 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_5_24 ^ xorList_1_23 ^ xorList_0_9 ^
    xorList_1_22 ^ xorList_3_20 ^ xorList_2_4; // @[crcGen.scala 87:38]
  wire  crcCalc_8 = _crcCalc_8_T_29 ^ xorList_1_26 ^ xorList_0_26 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^
    xorList_4_35 ^ xorList_0_13 ^ xorList_1_31 ^ xorList_0_14 ^ xorList_3_32 ^ xorList_3_33 ^ xorList_0_34 ^
    xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire  _crcCalc_9_T_29 = xorList_0_17 ^ xorList_1_1 ^ xorList_0_23 ^ xorList_0_6 ^ xorList_0_11 ^ xorList_2_6 ^
    xorList_0_20 ^ xorList_0_21 ^ xorList_2_11 ^ xorList_0_2 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_0_4 ^ xorList_1_18
     ^ xorList_5_18 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_4_22 ^
    xorList_0_8 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_1_24
     ^ xorList_3_23 ^ xorList_2_22; // @[crcGen.scala 87:38]
  wire  crcCalc_9 = _crcCalc_9_T_29 ^ xorList_1_26 ^ xorList_0_27 ^ xorList_0_28 ^ xorList_2_23 ^ xorList_0_29 ^
    xorList_1_30 ^ xorList_1_31 ^ xorList_1_33 ^ xorList_0_32 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_2_31 ^
    xorList_5_42 ^ xorList_1_11 ^ xorList_1_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_10_T_29 = xorList_0_18 ^ xorList_0_0 ^ xorList_6_8 ^ xorList_0_22 ^ xorList_3_3 ^ xorList_0_7 ^
    xorList_0_8 ^ xorList_3_6 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_1_16 ^ xorList_4_15 ^ xorList_0_4 ^
    xorList_5_18 ^ xorList_1_19 ^ xorList_1_20 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_5_24 ^ xorList_0_9 ^ xorList_1_22
     ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_2_21 ^ xorList_3_23 ^ xorList_0_26 ^ xorList_0_28 ^
    xorList_1_9 ^ xorList_2_6; // @[crcGen.scala 87:38]
  wire  crcCalc_10 = _crcCalc_10_T_29 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_4_35 ^ xorList_1_30 ^ xorList_0_13 ^
    xorList_0_31 ^ xorList_1_33 ^ xorList_0_33 ^ xorList_0_15 ^ xorList_6_38 ^ xorList_2_31 ^ xorList_0_34 ^
    xorList_0_35 ^ xorList_1_11 ^ xorList_1_35 ^ xorList_0_36 ^ xorList_0_37; // @[crcGen.scala 87:38]
  wire  _crcCalc_11_T_29 = xorList_0_0 ^ xorList_0_21 ^ xorList_0_22 ^ xorList_3_15 ^ xorList_1_5 ^ xorList_0_8 ^
    xorList_2_4 ^ xorList_2_21 ^ xorList_0_32 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_0_4
     ^ xorList_1_18 ^ xorList_0_7 ^ xorList_1_7 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_0_9 ^ xorList_1_22 ^ xorList_1_9
     ^ xorList_2_6 ^ xorList_2_23 ^ xorList_1_28 ^ xorList_0_29 ^ xorList_4_35 ^ xorList_0_13 ^ xorList_1_31 ^
    xorList_0_14 ^ xorList_3_32; // @[crcGen.scala 87:38]
  wire  crcCalc_11 = _crcCalc_11_T_29 ^ xorList_0_15 ^ xorList_6_38 ^ xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_12_T_29 = xorList_0_18 ^ xorList_2_8 ^ xorList_0_3 ^ xorList_3_3 ^ xorList_1_5 ^ xorList_3_32 ^
    xorList_1_33 ^ xorList_2_30 ^ xorList_0_16 ^ xorList_0_37 ^ xorList_2_0 ^ xorList_0_0 ^ xorList_6_8 ^ xorList_0_1 ^
    xorList_2_11 ^ xorList_1_15 ^ xorList_4_15 ^ xorList_3_15 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_4_22 ^ xorList_0_8
     ^ xorList_0_9 ^ xorList_2_18 ^ xorList_1_23 ^ xorList_1_24 ^ xorList_3_23 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_1_9 ^ xorList_0_12; // @[crcGen.scala 87:38]
  wire  crcCalc_12 = _crcCalc_12_T_29 ^ xorList_2_6 ^ xorList_0_29 ^ 1'h1 ^ xorList_0_34 ^ xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_13_T_29 = xorList_1_1 ^ xorList_2_0 ^ xorList_0_20 ^ xorList_6_8 ^ xorList_1_4 ^ xorList_3_3 ^
    xorList_0_5 ^ xorList_0_6 ^ xorList_0_7 ^ xorList_4_22 ^ xorList_1_22 ^ xorList_1_26 ^ xorList_0_11 ^ xorList_1_9 ^
    xorList_4_35 ^ xorList_0_16 ^ xorList_1_36 ^ xorList_2_11 ^ xorList_1_15 ^ xorList_4_15 ^ xorList_1_18 ^
    xorList_5_18 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_2_4 ^ xorList_1_28 ^ xorList_0_29
     ^ 1'h1 ^ xorList_0_14; // @[crcGen.scala 87:38]
  wire  crcCalc_13 = _crcCalc_13_T_29 ^ xorList_3_33 ^ xorList_0_15 ^ xorList_2_30 ^ xorList_0_34 ^ xorList_0_35 ^
    xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_14_T_29 = xorList_0_18 ^ xorList_1_1 ^ xorList_0_20 ^ xorList_0_1 ^ xorList_5_18 ^ xorList_0_8 ^
    xorList_0_11 ^ xorList_2_6 ^ 1'h1 ^ xorList_0_14 ^ xorList_0_33 ^ xorList_0_16 ^ xorList_2_11 ^ xorList_1_16 ^
    xorList_0_22 ^ xorList_0_23 ^ xorList_0_24 ^ xorList_3_15 ^ xorList_1_19 ^ xorList_1_5 ^ xorList_0_5 ^ xorList_1_22
     ^ xorList_2_18 ^ xorList_0_10 ^ xorList_4_28 ^ xorList_3_20 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_2_22 ^
    xorList_1_30 ^ xorList_0_13; // @[crcGen.scala 87:38]
  wire  crcCalc_14 = _crcCalc_14_T_29 ^ xorList_1_31 ^ xorList_6_38 ^ xorList_2_30 ^ xorList_2_31 ^ xorList_0_35 ^
    xorList_5_42 ^ xorList_1_11; // @[crcGen.scala 87:38]
  wire  _crcCalc_15_T_29 = xorList_1_1 ^ xorList_2_0 ^ xorList_0_19 ^ xorList_6_8 ^ xorList_3_3 ^ xorList_0_7 ^ 1'h1 ^
    xorList_3_6 ^ xorList_6_38 ^ xorList_0_34 ^ xorList_2_33 ^ xorList_3_9 ^ xorList_2_11 ^ xorList_4_15 ^ xorList_0_4
     ^ xorList_1_18 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_1_19 ^ xorList_0_24 ^ xorList_0_9 ^ xorList_5_24 ^
    xorList_1_23 ^ xorList_0_10 ^ xorList_3_20 ^ xorList_1_24 ^ xorList_1_25 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_0_28 ^ xorList_1_9; // @[crcGen.scala 87:38]
  wire  crcCalc_15 = _crcCalc_15_T_29 ^ xorList_2_6 ^ xorList_1_30 ^ xorList_1_31 ^ xorList_0_32 ^ xorList_0_33 ^
    xorList_1_36 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire [7:0] io_out_lo = {crcCalc_7,crcCalc_6,crcCalc_5,crcCalc_4,crcCalc_3,crcCalc_2,crcCalc_1,crcCalc_0}; // @[crcGen.scala 91:21]
  wire [7:0] io_out_hi = {crcCalc_15,crcCalc_14,crcCalc_13,crcCalc_12,crcCalc_11,crcCalc_10,crcCalc_9,crcCalc_8}; // @[crcGen.scala 91:21]
  assign io_out = {io_out_hi,io_out_lo}; // @[crcGen.scala 91:21]
endmodule
module ScrcGen_6(
  input  [92:0] io_in,
  output [15:0] io_out
);
  wire [95:0] paddedData = {3'h0,io_in}; // @[Cat.scala 33:92]
  wire  xorList_0_0 = paddedData[10]; // @[crcGen.scala 80:41]
  wire  xorList_0_1 = paddedData[24]; // @[crcGen.scala 80:41]
  wire  xorList_0_2 = paddedData[14]; // @[crcGen.scala 80:41]
  wire  xorList_0_3 = paddedData[29]; // @[crcGen.scala 80:41]
  wire  xorList_0_4 = paddedData[84]; // @[crcGen.scala 80:41]
  wire  xorList_0_5 = paddedData[85]; // @[crcGen.scala 80:41]
  wire  xorList_0_6 = paddedData[92]; // @[crcGen.scala 80:41]
  wire  xorList_0_7 = paddedData[77]; // @[crcGen.scala 80:41]
  wire  xorList_0_8 = paddedData[41]; // @[crcGen.scala 80:41]
  wire  xorList_0_9 = paddedData[76]; // @[crcGen.scala 80:41]
  wire  xorList_0_10 = paddedData[8]; // @[crcGen.scala 80:41]
  wire  xorList_0_11 = paddedData[69]; // @[crcGen.scala 80:41]
  wire  xorList_0_12 = paddedData[0]; // @[crcGen.scala 80:41]
  wire  xorList_0_13 = paddedData[88]; // @[crcGen.scala 80:41]
  wire  xorList_0_14 = paddedData[61]; // @[crcGen.scala 80:41]
  wire  xorList_0_15 = paddedData[1]; // @[crcGen.scala 80:41]
  wire  xorList_0_16 = paddedData[74]; // @[crcGen.scala 80:41]
  wire  xorList_0_17 = paddedData[38]; // @[crcGen.scala 80:41]
  wire  xorList_0_18 = paddedData[70]; // @[crcGen.scala 80:41]
  wire  xorList_0_19 = paddedData[21]; // @[crcGen.scala 80:41]
  wire  xorList_0_20 = paddedData[33]; // @[crcGen.scala 80:41]
  wire  xorList_0_21 = paddedData[32]; // @[crcGen.scala 80:41]
  wire  xorList_0_22 = paddedData[45]; // @[crcGen.scala 80:41]
  wire  xorList_0_23 = paddedData[64]; // @[crcGen.scala 80:41]
  wire  xorList_0_24 = paddedData[22]; // @[crcGen.scala 80:41]
  wire  xorList_0_25 = paddedData[44]; // @[crcGen.scala 80:41]
  wire  xorList_0_26 = paddedData[12]; // @[crcGen.scala 80:41]
  wire  xorList_0_27 = paddedData[54]; // @[crcGen.scala 80:41]
  wire  xorList_0_28 = paddedData[48]; // @[crcGen.scala 80:41]
  wire  xorList_0_29 = paddedData[63]; // @[crcGen.scala 80:41]
  wire  xorList_0_31 = paddedData[16]; // @[crcGen.scala 80:41]
  wire  xorList_0_32 = paddedData[31]; // @[crcGen.scala 80:41]
  wire  xorList_0_33 = paddedData[40]; // @[crcGen.scala 80:41]
  wire  xorList_0_34 = paddedData[26]; // @[crcGen.scala 80:41]
  wire  xorList_0_35 = paddedData[30]; // @[crcGen.scala 80:41]
  wire  xorList_0_36 = paddedData[19]; // @[crcGen.scala 80:41]
  wire  xorList_0_37 = paddedData[47]; // @[crcGen.scala 80:41]
  wire  xorList_0_38 = paddedData[15]; // @[crcGen.scala 80:41]
  wire  xorList_0_39 = paddedData[68]; // @[crcGen.scala 80:41]
  wire  _crcCalc_0_T_29 = xorList_0_0 ^ xorList_0_1 ^ xorList_0_2 ^ xorList_0_3 ^ xorList_0_4 ^ xorList_0_5 ^
    xorList_0_6 ^ xorList_0_7 ^ xorList_0_8 ^ xorList_0_9 ^ xorList_0_10 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_0_13 ^
    xorList_0_14 ^ xorList_0_15 ^ xorList_0_16 ^ xorList_0_17 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^
    xorList_0_21 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_0_26 ^ xorList_0_27 ^
    xorList_0_28 ^ xorList_0_29 ^ 1'h1; // @[crcGen.scala 87:38]
  wire  crcCalc_0 = _crcCalc_0_T_29 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_0_33 ^ xorList_0_34 ^ xorList_0_35 ^
    xorList_0_36 ^ xorList_0_37 ^ xorList_0_38 ^ xorList_0_39; // @[crcGen.scala 87:38]
  wire  xorList_1_2 = paddedData[65]; // @[crcGen.scala 80:41]
  wire  xorList_1_3 = paddedData[9]; // @[crcGen.scala 80:41]
  wire  xorList_1_5 = paddedData[2]; // @[crcGen.scala 80:41]
  wire  xorList_1_6 = paddedData[39]; // @[crcGen.scala 80:41]
  wire  xorList_1_8 = paddedData[11]; // @[crcGen.scala 80:41]
  wire  xorList_1_9 = paddedData[75]; // @[crcGen.scala 80:41]
  wire  xorList_1_11 = paddedData[42]; // @[crcGen.scala 80:41]
  wire  xorList_1_12 = paddedData[25]; // @[crcGen.scala 80:41]
  wire  xorList_1_13 = paddedData[20]; // @[crcGen.scala 80:41]
  wire  xorList_1_14 = paddedData[46]; // @[crcGen.scala 80:41]
  wire  xorList_1_15 = paddedData[93]; // @[crcGen.scala 80:41]
  wire  xorList_1_16 = paddedData[78]; // @[crcGen.scala 80:41]
  wire  xorList_1_17 = paddedData[89]; // @[crcGen.scala 80:41]
  wire  xorList_1_21 = paddedData[13]; // @[crcGen.scala 80:41]
  wire  xorList_1_25 = paddedData[17]; // @[crcGen.scala 80:41]
  wire  xorList_1_27 = paddedData[34]; // @[crcGen.scala 80:41]
  wire  xorList_1_29 = paddedData[27]; // @[crcGen.scala 80:41]
  wire  xorList_1_30 = paddedData[71]; // @[crcGen.scala 80:41]
  wire  xorList_1_31 = paddedData[49]; // @[crcGen.scala 80:41]
  wire  xorList_1_32 = paddedData[86]; // @[crcGen.scala 80:41]
  wire  xorList_1_35 = paddedData[55]; // @[crcGen.scala 80:41]
  wire  xorList_1_36 = paddedData[23]; // @[crcGen.scala 80:41]
  wire  xorList_1_38 = paddedData[62]; // @[crcGen.scala 80:41]
  wire  _crcCalc_1_T_29 = xorList_0_11 ^ xorList_0_5 ^ xorList_1_2 ^ xorList_1_3 ^ xorList_0_7 ^ xorList_1_5 ^
    xorList_1_6 ^ xorList_0_28 ^ xorList_1_8 ^ xorList_1_9 ^ xorList_0_35 ^ xorList_1_11 ^ xorList_1_12 ^ xorList_1_13
     ^ xorList_1_14 ^ xorList_1_15 ^ xorList_1_16 ^ xorList_1_17 ^ xorList_0_15 ^ xorList_0_18 ^ xorList_0_20 ^
    xorList_1_21 ^ xorList_0_8 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_1_25 ^ xorList_0_21 ^ xorList_1_27 ^ xorList_0_24
     ^ xorList_1_29 ^ xorList_1_30; // @[crcGen.scala 87:38]
  wire  crcCalc_1 = _crcCalc_1_T_29 ^ xorList_1_31 ^ xorList_1_32 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_1_35 ^
    xorList_1_36 ^ xorList_0_38 ^ xorList_1_38; // @[crcGen.scala 87:38]
  wire  xorList_2_5 = paddedData[66]; // @[crcGen.scala 80:41]
  wire  xorList_2_6 = paddedData[87]; // @[crcGen.scala 80:41]
  wire  xorList_2_8 = paddedData[90]; // @[crcGen.scala 80:41]
  wire  xorList_2_10 = paddedData[56]; // @[crcGen.scala 80:41]
  wire  xorList_2_15 = paddedData[28]; // @[crcGen.scala 80:41]
  wire  xorList_2_26 = paddedData[3]; // @[crcGen.scala 80:41]
  wire  xorList_2_27 = paddedData[35]; // @[crcGen.scala 80:41]
  wire  xorList_2_29 = paddedData[18]; // @[crcGen.scala 80:41]
  wire  xorList_2_30 = paddedData[50]; // @[crcGen.scala 80:41]
  wire  xorList_2_33 = paddedData[72]; // @[crcGen.scala 80:41]
  wire  xorList_2_34 = paddedData[43]; // @[crcGen.scala 80:41]
  wire  xorList_2_38 = paddedData[79]; // @[crcGen.scala 80:41]
  wire  xorList_2_39 = paddedData[94]; // @[crcGen.scala 80:41]
  wire  _crcCalc_2_T_29 = xorList_0_12 ^ xorList_0_2 ^ xorList_1_2 ^ xorList_1_5 ^ xorList_0_9 ^ xorList_2_5 ^
    xorList_2_6 ^ xorList_0_37 ^ xorList_2_8 ^ xorList_0_0 ^ xorList_2_10 ^ xorList_1_11 ^ xorList_0_1 ^ xorList_1_14 ^
    xorList_1_16 ^ xorList_2_15 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_1_25 ^ xorList_0_21 ^
    xorList_1_27 ^ xorList_1_30 ^ xorList_0_26 ^ xorList_1_31 ^ xorList_1_32 ^ xorList_2_26 ^ xorList_2_27 ^
    xorList_0_29 ^ xorList_2_29 ^ xorList_2_30; // @[crcGen.scala 87:38]
  wire  crcCalc_2 = _crcCalc_2_T_29 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_0_33 ^
    xorList_0_34 ^ xorList_1_36 ^ xorList_2_38 ^ xorList_2_39; // @[crcGen.scala 87:38]
  wire  xorList_3_4 = paddedData[73]; // @[crcGen.scala 80:41]
  wire  xorList_3_9 = paddedData[57]; // @[crcGen.scala 80:41]
  wire  xorList_3_20 = paddedData[91]; // @[crcGen.scala 80:41]
  wire  xorList_3_23 = paddedData[80]; // @[crcGen.scala 80:41]
  wire  xorList_3_27 = paddedData[95]; // @[crcGen.scala 80:41]
  wire  xorList_3_29 = paddedData[67]; // @[crcGen.scala 80:41]
  wire  xorList_3_33 = paddedData[36]; // @[crcGen.scala 80:41]
  wire  xorList_3_34 = paddedData[51]; // @[crcGen.scala 80:41]
  wire  xorList_3_36 = paddedData[4]; // @[crcGen.scala 80:41]
  wire  _crcCalc_3_T_29 = xorList_0_13 ^ xorList_0_15 ^ xorList_0_20 ^ xorList_0_7 ^ xorList_3_4 ^ xorList_1_30 ^
    xorList_2_6 ^ xorList_0_1 ^ xorList_1_12 ^ xorList_3_9 ^ xorList_0_3 ^ xorList_1_21 ^ xorList_0_8 ^ xorList_0_23 ^
    xorList_1_25 ^ xorList_0_21 ^ xorList_1_27 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_1_29 ^ xorList_3_20 ^ xorList_2_5
     ^ xorList_2_26 ^ xorList_3_23 ^ xorList_2_27 ^ xorList_0_28 ^ xorList_2_29 ^ xorList_3_27 ^ xorList_2_30 ^
    xorList_3_29 ^ xorList_1_8; // @[crcGen.scala 87:38]
  wire  crcCalc_3 = _crcCalc_3_T_29 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_3_33 ^ xorList_3_34 ^ xorList_0_36 ^
    xorList_3_36 ^ xorList_2_38 ^ xorList_0_37 ^ xorList_0_38; // @[crcGen.scala 87:38]
  wire  xorList_4_0 = paddedData[5]; // @[crcGen.scala 80:41]
  wire  xorList_4_2 = paddedData[52]; // @[crcGen.scala 80:41]
  wire  xorList_4_15 = paddedData[37]; // @[crcGen.scala 80:41]
  wire  xorList_4_34 = paddedData[81]; // @[crcGen.scala 80:41]
  wire  xorList_4_45 = paddedData[58]; // @[crcGen.scala 80:41]
  wire  _crcCalc_4_T_29 = xorList_4_0 ^ xorList_0_0 ^ xorList_4_2 ^ xorList_0_4 ^ xorList_0_5 ^ xorList_1_2 ^
    xorList_0_7 ^ xorList_0_8 ^ xorList_0_24 ^ xorList_2_33 ^ xorList_3_36 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_1_11
     ^ xorList_0_1 ^ xorList_4_15 ^ xorList_1_12 ^ xorList_1_13 ^ xorList_1_16 ^ xorList_0_3 ^ xorList_0_14 ^
    xorList_1_17 ^ xorList_0_15 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_2_15 ^ xorList_0_17 ^ xorList_3_4 ^ xorList_1_5
     ^ xorList_0_23 ^ xorList_0_21; // @[crcGen.scala 87:38]
  wire  crcCalc_4 = _crcCalc_4_T_29 ^ xorList_1_27 ^ xorList_0_27 ^ xorList_1_31 ^ xorList_4_34 ^ xorList_0_9 ^
    xorList_3_23 ^ xorList_2_27 ^ xorList_0_29 ^ xorList_2_29 ^ xorList_3_29 ^ xorList_0_32 ^ xorList_0_33 ^
    xorList_1_36 ^ xorList_0_10 ^ xorList_4_45 ^ xorList_3_33 ^ xorList_3_34 ^ xorList_0_37 ^ xorList_0_38; // @[crcGen.scala 87:38]
  wire  xorList_5_6 = paddedData[82]; // @[crcGen.scala 80:41]
  wire  xorList_5_17 = paddedData[6]; // @[crcGen.scala 80:41]
  wire  xorList_5_24 = paddedData[53]; // @[crcGen.scala 80:41]
  wire  xorList_5_30 = paddedData[59]; // @[crcGen.scala 80:41]
  wire  _crcCalc_5_T_29 = xorList_4_0 ^ xorList_4_2 ^ xorList_1_2 ^ xorList_0_7 ^ xorList_0_8 ^ xorList_2_5 ^
    xorList_5_6 ^ xorList_2_38 ^ xorList_2_8 ^ xorList_1_11 ^ xorList_0_1 ^ xorList_4_15 ^ xorList_1_12 ^ xorList_1_16
     ^ xorList_0_3 ^ xorList_0_15 ^ xorList_0_16 ^ xorList_5_17 ^ xorList_0_5 ^ xorList_0_17 ^ xorList_0_18 ^
    xorList_0_19 ^ xorList_0_20 ^ xorList_1_3 ^ xorList_5_24 ^ xorList_3_4 ^ xorList_1_5 ^ xorList_0_21 ^ xorList_0_23
     ^ xorList_0_24 ^ xorList_5_30; // @[crcGen.scala 87:38]
  wire  crcCalc_5 = _crcCalc_5_T_29 ^ xorList_1_30 ^ xorList_1_32 ^ xorList_4_34 ^ xorList_1_6 ^ xorList_2_26 ^
    xorList_2_27 ^ xorList_0_28 ^ 1'h1 ^ xorList_2_30 ^ xorList_0_31 ^ xorList_1_8 ^ xorList_2_34 ^ xorList_0_34 ^
    xorList_1_35 ^ xorList_1_36 ^ xorList_3_33 ^ xorList_0_35 ^ xorList_0_36 ^ xorList_0_39 ^ xorList_1_38; // @[crcGen.scala 87:38]
  wire  xorList_6_6 = paddedData[83]; // @[crcGen.scala 80:41]
  wire  xorList_6_18 = paddedData[60]; // @[crcGen.scala 80:41]
  wire  xorList_6_31 = paddedData[7]; // @[crcGen.scala 80:41]
  wire  _crcCalc_6_T_29 = xorList_0_16 ^ xorList_1_2 ^ xorList_5_24 ^ xorList_1_5 ^ xorList_0_29 ^ xorList_2_6 ^
    xorList_6_6 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_0_0 ^ xorList_2_10 ^ xorList_1_11 ^ xorList_0_1 ^ xorList_4_15
     ^ xorList_1_12 ^ xorList_1_13 ^ xorList_1_16 ^ xorList_5_17 ^ xorList_6_18 ^ xorList_0_17 ^ xorList_0_20 ^
    xorList_1_27 ^ xorList_1_25 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_1_29 ^ xorList_1_30 ^ xorList_0_26 ^
    xorList_0_27 ^ xorList_1_31 ^ xorList_1_32; // @[crcGen.scala 87:38]
  wire  crcCalc_6 = _crcCalc_6_T_29 ^ xorList_6_31 ^ xorList_1_6 ^ xorList_3_20 ^ xorList_2_5 ^ xorList_2_26 ^
    xorList_3_23 ^ xorList_3_29 ^ xorList_0_32 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_0_33 ^ xorList_0_34 ^
    xorList_1_36 ^ xorList_1_9 ^ xorList_5_6 ^ xorList_3_33 ^ xorList_0_35 ^ xorList_3_34 ^ xorList_3_36 ^ xorList_2_38; // @[crcGen.scala 87:38]
  wire  _crcCalc_7_T_29 = xorList_0_13 ^ xorList_4_0 ^ xorList_4_2 ^ xorList_3_9 ^ xorList_0_4 ^ xorList_0_6 ^
    xorList_3_4 ^ xorList_0_27 ^ xorList_2_5 ^ xorList_2_29 ^ xorList_2_6 ^ xorList_0_39 ^ xorList_6_6 ^ xorList_0_1 ^
    xorList_4_15 ^ xorList_1_12 ^ xorList_0_14 ^ xorList_0_15 ^ xorList_0_18 ^ xorList_0_19 ^ xorList_2_15 ^
    xorList_0_17 ^ xorList_1_21 ^ xorList_0_8 ^ xorList_0_22 ^ xorList_0_23 ^ xorList_0_21 ^ xorList_1_27 ^ xorList_0_25
     ^ xorList_1_29 ^ xorList_4_34; // @[crcGen.scala 87:38]
  wire  crcCalc_7 = _crcCalc_7_T_29 ^ xorList_0_9 ^ xorList_6_31 ^ xorList_1_6 ^ xorList_2_26 ^ xorList_3_23 ^
    xorList_2_27 ^ xorList_2_30 ^ xorList_3_29 ^ xorList_0_32 ^ xorList_1_8 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_0_33
     ^ xorList_0_34 ^ xorList_1_35 ^ xorList_1_36 ^ xorList_0_10 ^ xorList_1_9 ^ xorList_3_36 ^ xorList_2_38; // @[crcGen.scala 87:38]
  wire  _crcCalc_8_T_29 = xorList_4_0 ^ xorList_2_10 ^ xorList_0_2 ^ xorList_0_4 ^ xorList_1_2 ^ xorList_0_7 ^
    xorList_0_8 ^ 1'h1 ^ xorList_3_29 ^ xorList_3_36 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_0_13 ^ xorList_1_11 ^
    xorList_0_1 ^ xorList_1_12 ^ xorList_1_14 ^ xorList_1_15 ^ xorList_0_3 ^ xorList_1_17 ^ xorList_0_16 ^ xorList_5_17
     ^ xorList_0_5 ^ xorList_0_20 ^ xorList_2_15 ^ xorList_0_17 ^ xorList_1_3 ^ xorList_5_24 ^ xorList_3_4 ^ xorList_1_5
     ^ xorList_0_21; // @[crcGen.scala 87:38]
  wire  crcCalc_8 = _crcCalc_8_T_29 ^ xorList_0_22 ^ xorList_0_24 ^ xorList_0_25 ^ xorList_1_29 ^ xorList_1_30 ^
    xorList_0_26 ^ xorList_4_34 ^ xorList_0_9 ^ xorList_1_6 ^ xorList_3_23 ^ xorList_2_27 ^ xorList_0_33 ^ xorList_0_34
     ^ xorList_1_35 ^ xorList_0_10 ^ xorList_4_45 ^ xorList_5_6 ^ xorList_3_33 ^ xorList_3_34 ^ xorList_0_36 ^
    xorList_0_39 ^ xorList_1_38; // @[crcGen.scala 87:38]
  wire  _crcCalc_9_T_29 = xorList_0_11 ^ xorList_4_0 ^ xorList_4_2 ^ xorList_1_3 ^ xorList_0_7 ^ xorList_2_5 ^
    xorList_2_26 ^ xorList_2_39 ^ xorList_0_0 ^ xorList_2_10 ^ xorList_1_11 ^ xorList_4_15 ^ xorList_1_12 ^ xorList_1_13
     ^ xorList_1_14 ^ xorList_3_9 ^ xorList_1_16 ^ xorList_0_3 ^ xorList_1_17 ^ xorList_0_15 ^ xorList_0_16 ^
    xorList_5_17 ^ xorList_0_5 ^ xorList_2_15 ^ xorList_0_18 ^ xorList_0_20 ^ xorList_1_21 ^ xorList_0_8 ^ xorList_1_27
     ^ xorList_0_22 ^ xorList_5_30; // @[crcGen.scala 87:38]
  wire  crcCalc_9 = _crcCalc_9_T_29 ^ xorList_1_29 ^ xorList_0_27 ^ xorList_1_32 ^ xorList_4_34 ^ xorList_6_31 ^
    xorList_1_6 ^ xorList_0_29 ^ 1'h1 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_0_33 ^ xorList_0_34 ^ xorList_1_36 ^
    xorList_1_9 ^ xorList_5_6 ^ xorList_3_33 ^ xorList_0_35 ^ xorList_0_37 ^ xorList_0_38 ^ xorList_0_39 ^ xorList_2_8
     ^ xorList_6_6; // @[crcGen.scala 87:38]
  wire  _crcCalc_10_T_29 = xorList_0_0 ^ xorList_0_2 ^ xorList_0_4 ^ xorList_5_24 ^ xorList_0_8 ^ xorList_3_20 ^
    xorList_2_27 ^ xorList_2_6 ^ xorList_0_35 ^ xorList_0_37 ^ xorList_0_11 ^ xorList_0_12 ^ xorList_1_11 ^ xorList_0_1
     ^ xorList_4_15 ^ xorList_1_14 ^ xorList_3_9 ^ xorList_1_16 ^ xorList_0_3 ^ xorList_5_17 ^ xorList_6_18 ^
    xorList_0_18 ^ xorList_0_19 ^ xorList_2_15 ^ xorList_0_17 ^ xorList_3_4 ^ xorList_1_5 ^ xorList_1_27 ^ xorList_0_23
     ^ xorList_0_25 ^ xorList_1_29; // @[crcGen.scala 87:38]
  wire  crcCalc_10 = _crcCalc_10_T_29 ^ xorList_1_30 ^ xorList_1_32 ^ xorList_0_9 ^ xorList_6_31 ^ xorList_0_28 ^ 1'h1
     ^ xorList_3_27 ^ xorList_3_29 ^ xorList_0_31 ^ xorList_0_32 ^ xorList_1_8 ^ xorList_2_34 ^ xorList_0_33 ^
    xorList_0_34 ^ xorList_1_35 ^ xorList_0_10 ^ xorList_1_9 ^ xorList_4_45 ^ xorList_5_6 ^ xorList_3_36 ^ xorList_2_38
     ^ xorList_2_8 ^ xorList_6_6; // @[crcGen.scala 87:38]
  wire  _crcCalc_11_T_29 = xorList_0_11 ^ xorList_4_0 ^ xorList_0_2 ^ xorList_1_2 ^ xorList_1_3 ^ xorList_3_20 ^
    xorList_0_31 ^ xorList_2_6 ^ xorList_4_45 ^ xorList_2_38 ^ xorList_6_6 ^ xorList_0_0 ^ xorList_2_10 ^ xorList_1_11
     ^ xorList_0_1 ^ xorList_1_12 ^ xorList_2_15 ^ xorList_0_19 ^ xorList_0_20 ^ xorList_0_23 ^ xorList_1_25 ^
    xorList_5_30 ^ xorList_1_29 ^ xorList_1_30 ^ xorList_1_31 ^ xorList_6_31 ^ xorList_1_6 ^ xorList_2_26 ^ xorList_3_23
     ^ xorList_2_27 ^ xorList_0_29; // @[crcGen.scala 87:38]
  wire  crcCalc_11 = _crcCalc_11_T_29 ^ 1'h1 ^ xorList_1_8 ^ xorList_2_33 ^ xorList_2_34 ^ xorList_0_33 ^ xorList_0_34
     ^ xorList_3_33 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire  _crcCalc_12_T_29 = xorList_0_13 ^ xorList_0_0 ^ xorList_0_4 ^ xorList_0_8 ^ xorList_3_4 ^ xorList_0_26 ^
    xorList_4_34 ^ xorList_2_5 ^ xorList_3_23 ^ xorList_2_30 ^ xorList_0_10 ^ xorList_3_33 ^ xorList_3_36 ^ xorList_0_38
     ^ xorList_4_15 ^ xorList_1_12 ^ xorList_1_13 ^ xorList_3_9 ^ xorList_0_3 ^ xorList_5_17 ^ xorList_6_18 ^
    xorList_2_15 ^ xorList_0_18 ^ xorList_0_6 ^ xorList_1_2 ^ xorList_1_27 ^ xorList_0_23 ^ xorList_1_25 ^ xorList_0_24
     ^ xorList_0_25 ^ xorList_5_30; // @[crcGen.scala 87:38]
  wire  crcCalc_12 = _crcCalc_12_T_29 ^ xorList_1_29 ^ xorList_2_29 ^ 1'h1 ^ xorList_1_8 ^ xorList_2_33 ^ xorList_2_34
     ^ xorList_0_33 ^ xorList_0_34; // @[crcGen.scala 87:38]
  wire  _crcCalc_13_T_29 = xorList_4_0 ^ xorList_1_2 ^ xorList_1_3 ^ xorList_3_4 ^ xorList_0_22 ^ xorList_2_5 ^
    xorList_2_27 ^ xorList_2_29 ^ xorList_1_8 ^ xorList_1_11 ^ xorList_4_15 ^ xorList_1_15 ^ xorList_0_3 ^ xorList_0_14
     ^ xorList_1_17 ^ xorList_0_16 ^ xorList_6_18 ^ xorList_0_5 ^ xorList_0_19 ^ xorList_2_15 ^ xorList_0_17 ^
    xorList_1_21 ^ xorList_0_8 ^ xorList_0_25 ^ xorList_1_29 ^ xorList_1_30 ^ xorList_0_26 ^ xorList_4_34 ^ xorList_6_31
     ^ xorList_3_29 ^ xorList_0_31; // @[crcGen.scala 87:38]
  wire  crcCalc_13 = _crcCalc_13_T_29 ^ xorList_0_34 ^ xorList_1_36 ^ xorList_4_45 ^ xorList_5_6 ^ xorList_0_35 ^
    xorList_3_34 ^ xorList_0_36; // @[crcGen.scala 87:38]
  wire  _crcCalc_14_T_29 = xorList_0_0 ^ xorList_5_17 ^ xorList_1_21 ^ xorList_1_6 ^ xorList_2_5 ^ xorList_2_39 ^
    xorList_1_11 ^ xorList_0_1 ^ xorList_4_2 ^ xorList_0_2 ^ xorList_1_13 ^ xorList_1_14 ^ xorList_0_3 ^ xorList_0_14 ^
    xorList_0_16 ^ xorList_2_15 ^ xorList_0_17 ^ xorList_0_22 ^ xorList_1_25 ^ xorList_0_24 ^ xorList_5_30 ^
    xorList_1_29 ^ xorList_0_26 ^ xorList_1_32 ^ xorList_3_29 ^ xorList_0_32 ^ xorList_2_33 ^ xorList_2_34 ^
    xorList_0_10 ^ xorList_1_9 ^ xorList_5_6; // @[crcGen.scala 87:38]
  wire  crcCalc_14 = _crcCalc_14_T_29 ^ xorList_3_33 ^ xorList_0_35 ^ xorList_0_36 ^ xorList_0_39 ^ xorList_1_38 ^
    xorList_2_8 ^ xorList_6_6; // @[crcGen.scala 87:38]
  wire  _crcCalc_15_T_29 = xorList_0_2 ^ xorList_0_4 ^ xorList_6_18 ^ xorList_1_21 ^ xorList_3_4 ^ xorList_0_21 ^
    xorList_0_25 ^ xorList_3_20 ^ xorList_2_6 ^ xorList_1_9 ^ xorList_0_35 ^ xorList_6_6 ^ xorList_0_11 ^ xorList_0_12
     ^ xorList_4_15 ^ xorList_1_12 ^ xorList_1_13 ^ xorList_1_14 ^ xorList_0_3 ^ xorList_2_15 ^ xorList_0_19 ^
    xorList_1_3 ^ xorList_5_24 ^ xorList_0_9 ^ xorList_6_31 ^ xorList_1_6 ^ xorList_0_29 ^ xorList_2_29 ^ 1'h1 ^
    xorList_3_27 ^ xorList_3_29; // @[crcGen.scala 87:38]
  wire  crcCalc_15 = _crcCalc_15_T_29 ^ xorList_0_32 ^ xorList_1_8 ^ xorList_2_34 ^ xorList_0_33 ^ xorList_1_36 ^
    xorList_0_37 ^ xorList_0_38 ^ xorList_0_39 ^ xorList_1_38; // @[crcGen.scala 87:38]
  wire [7:0] io_out_lo = {crcCalc_7,crcCalc_6,crcCalc_5,crcCalc_4,crcCalc_3,crcCalc_2,crcCalc_1,crcCalc_0}; // @[crcGen.scala 91:21]
  wire [7:0] io_out_hi = {crcCalc_15,crcCalc_14,crcCalc_13,crcCalc_12,crcCalc_11,crcCalc_10,crcCalc_9,crcCalc_8}; // @[crcGen.scala 91:21]
  assign io_out = {io_out_hi,io_out_lo}; // @[crcGen.scala 91:21]
endmodule
module SSlaveRxLinkLayer(
  input         clock,
  input         reset,
  input         io_rxPhy2LLIO_flit_valid,
  input  [15:0] io_rxPhy2LLIO_flit_bits,
  input         io_rxPhy2LLIO_creditRB_free,
  input         io_rxPhy2LLIO_replayPkgID,
  output        io_outAXI4AW_valid,
  output [65:0] io_outAXI4AW_bits,
  output        io_outAXI4AR_valid,
  output [65:0] io_outAXI4AR_bits,
  output        io_outAXI4W_valid,
  output [72:0] io_outAXI4W_bits,
  output [2:0]  io_rxDebugState,
  output [3:0]  io_rxDebugLastCorrectPkgID,
  output        io_rx2TxCreditRBFree_valid,
  output [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDUsed_valid,
  output [3:0]  io_rx2TxPackageIDUsed_bits,
  output        io_rx2TxPackageIDOut_valid,
  output [3:0]  io_rx2TxPackageIDOut_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [95:0] _RAND_3;
  reg [95:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [127:0] _RAND_6;
  reg [127:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [127:0] _RAND_9;
  reg [127:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
  reg [31:0] _RAND_19;
  reg [31:0] _RAND_20;
  reg [31:0] _RAND_21;
  reg [31:0] _RAND_22;
  reg [31:0] _RAND_23;
  reg [31:0] _RAND_24;
`endif // RANDOMIZE_REG_INIT
  wire [85:0] crcGene_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] crcGene_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [85:0] crcGene_crcgen_1_io_in; // @[crcGen.scala 99:24]
  wire [15:0] crcGene_crcgen_1_io_out; // @[crcGen.scala 99:24]
  wire [92:0] crcGene_crcgen_2_io_in; // @[crcGen.scala 99:24]
  wire [15:0] crcGene_crcgen_2_io_out; // @[crcGen.scala 99:24]
  reg [15:0] rxFlitBitReg; // @[DataLinkLayer.scala 416:29]
  reg  rxFlitValidReg; // @[DataLinkLayer.scala 418:31]
  reg  outWValid; // @[DataLinkLayer.scala 421:26]
  reg [95:0] outWData; // @[DataLinkLayer.scala 422:25]
  reg [95:0] outWDataShift; // @[DataLinkLayer.scala 423:30]
  reg  outAWValid; // @[DataLinkLayer.scala 425:27]
  reg [111:0] outAWData; // @[DataLinkLayer.scala 426:27]
  reg [111:0] outAWDataShift; // @[DataLinkLayer.scala 427:32]
  reg  outARValid; // @[DataLinkLayer.scala 429:27]
  reg [111:0] outARData; // @[DataLinkLayer.scala 430:27]
  reg [111:0] outARDataShift; // @[DataLinkLayer.scala 431:32]
  reg [2:0] axi4AWTCCnt; // @[DataLinkLayer.scala 434:29]
  reg [2:0] axi4ARTCCnt; // @[DataLinkLayer.scala 435:29]
  reg [2:0] axi4WTCCnt; // @[DataLinkLayer.scala 436:29]
  reg [2:0] errorTCCnt; // @[DataLinkLayer.scala 443:29]
  reg [2:0] state; // @[DataLinkLayer.scala 449:22]
  wire [1:0] _GEN_2 = rxFlitBitReg == 16'h5678 ? 2'h2 : 2'h3; // @[DataLinkLayer.scala 473:88 476:17]
  wire [1:0] _GEN_5 = rxFlitBitReg == 16'h1234 ? 2'h1 : _GEN_2; // @[DataLinkLayer.scala 468:82 471:17]
  wire [1:0] _GEN_9 = rxFlitValidReg ? _GEN_5 : 2'h0; // @[DataLinkLayer.scala 467:27 495:15]
  wire [2:0] _axi4AWTCCnt_T_1 = axi4AWTCCnt + 3'h1; // @[DataLinkLayer.scala 501:36]
  wire [2:0] _state_T_1 = 3'h7 - 3'h1; // @[DataLinkLayer.scala 502:66]
  wire  _state_T_2 = axi4AWTCCnt < _state_T_1; // @[DataLinkLayer.scala 502:34]
  wire [111:0] _outAWData_T = outAWData & outAWDataShift; // @[DataLinkLayer.scala 504:32]
  wire [6:0] _outAWData_T_1 = {axi4AWTCCnt, 4'h0}; // @[DataLinkLayer.scala 504:81]
  wire [142:0] _GEN_85 = {{127'd0}, rxFlitBitReg}; // @[DataLinkLayer.scala 504:65]
  wire [142:0] _outAWData_T_2 = _GEN_85 << _outAWData_T_1; // @[DataLinkLayer.scala 504:65]
  wire [142:0] _GEN_82 = {{31'd0}, _outAWData_T}; // @[DataLinkLayer.scala 504:49]
  wire [142:0] _outAWData_T_3 = _GEN_82 | _outAWData_T_2; // @[DataLinkLayer.scala 504:49]
  wire [111:0] _outAWDataShift_T_4 = {outAWDataShift[95:0],outAWDataShift[111:96]}; // @[Cat.scala 33:92]
  wire [2:0] _axi4ARTCCnt_T_1 = axi4ARTCCnt + 3'h1; // @[DataLinkLayer.scala 510:36]
  wire  _state_T_6 = axi4ARTCCnt < _state_T_1; // @[DataLinkLayer.scala 511:34]
  wire [1:0] _state_T_7 = axi4ARTCCnt < _state_T_1 ? 2'h2 : 2'h0; // @[DataLinkLayer.scala 511:21]
  wire [111:0] _outARData_T = outARData & outARDataShift; // @[DataLinkLayer.scala 513:32]
  wire [6:0] _outARData_T_1 = {axi4ARTCCnt, 4'h0}; // @[DataLinkLayer.scala 513:81]
  wire [142:0] _GEN_86 = {{127'd0}, rxFlitBitReg}; // @[DataLinkLayer.scala 513:65]
  wire [142:0] _outARData_T_2 = _GEN_86 << _outARData_T_1; // @[DataLinkLayer.scala 513:65]
  wire [142:0] _GEN_83 = {{31'd0}, _outARData_T}; // @[DataLinkLayer.scala 513:49]
  wire [142:0] _outARData_T_3 = _GEN_83 | _outARData_T_2; // @[DataLinkLayer.scala 513:49]
  wire [111:0] _outARDataShift_T_4 = {outARDataShift[95:0],outARDataShift[111:96]}; // @[Cat.scala 33:92]
  wire [2:0] _axi4WTCCnt_T_1 = axi4WTCCnt + 3'h1; // @[DataLinkLayer.scala 519:34]
  wire [2:0] _state_T_9 = 3'h6 - 3'h1; // @[DataLinkLayer.scala 520:64]
  wire  _state_T_10 = axi4WTCCnt < _state_T_9; // @[DataLinkLayer.scala 520:33]
  wire [1:0] _state_T_11 = axi4WTCCnt < _state_T_9 ? 2'h3 : 2'h0; // @[DataLinkLayer.scala 520:21]
  wire  _outWValid_T_3 = _state_T_10 ? 1'h0 : 1'h1; // @[DataLinkLayer.scala 521:25]
  wire [95:0] _outWData_T = outWData & outWDataShift; // @[DataLinkLayer.scala 522:30]
  wire [6:0] _outWData_T_1 = {axi4WTCCnt, 4'h0}; // @[DataLinkLayer.scala 522:77]
  wire [142:0] _GEN_87 = {{127'd0}, rxFlitBitReg}; // @[DataLinkLayer.scala 522:62]
  wire [142:0] _outWData_T_2 = _GEN_87 << _outWData_T_1; // @[DataLinkLayer.scala 522:62]
  wire [142:0] _GEN_84 = {{47'd0}, _outWData_T}; // @[DataLinkLayer.scala 522:46]
  wire [142:0] _outWData_T_3 = _GEN_84 | _outWData_T_2; // @[DataLinkLayer.scala 522:46]
  wire [95:0] _outWDataShift_T_4 = {outWDataShift[79:0],outWDataShift[95:80]}; // @[Cat.scala 33:92]
  wire [2:0] _errorTCCnt_T_1 = errorTCCnt + 3'h1; // @[DataLinkLayer.scala 528:32]
  wire  _state_T_14 = errorTCCnt < _state_T_1; // @[DataLinkLayer.scala 529:31]
  wire [2:0] _state_T_15 = errorTCCnt < _state_T_1 ? 3'h4 : 3'h0; // @[DataLinkLayer.scala 529:19]
  wire  _outAWValid_T_7 = _state_T_14 ? 1'h0 : 1'h1; // @[DataLinkLayer.scala 531:26]
  wire [2:0] _GEN_13 = 3'h4 == state ? _errorTCCnt_T_1 : errorTCCnt; // @[DataLinkLayer.scala 451:17 528:18 443:29]
  wire [2:0] _GEN_14 = 3'h4 == state ? _state_T_15 : state; // @[DataLinkLayer.scala 451:17 529:13 449:22]
  wire  _GEN_15 = 3'h4 == state ? _outAWValid_T_7 : outAWValid; // @[DataLinkLayer.scala 451:17 531:20 425:27]
  wire [142:0] _GEN_19 = 3'h3 == state ? _outWData_T_3 : {{47'd0}, outWData}; // @[DataLinkLayer.scala 451:17 522:18 422:25]
  wire [142:0] _GEN_26 = 3'h2 == state ? _outARData_T_3 : {{31'd0}, outARData}; // @[DataLinkLayer.scala 451:17 513:19 430:27]
  wire [142:0] _GEN_30 = 3'h2 == state ? {{47'd0}, outWData} : _GEN_19; // @[DataLinkLayer.scala 451:17 422:25]
  wire [142:0] _GEN_37 = 3'h1 == state ? _outAWData_T_3 : {{31'd0}, outAWData}; // @[DataLinkLayer.scala 451:17 504:19 426:27]
  wire [142:0] _GEN_41 = 3'h1 == state ? {{31'd0}, outARData} : _GEN_26; // @[DataLinkLayer.scala 451:17 430:27]
  wire [142:0] _GEN_45 = 3'h1 == state ? {{47'd0}, outWData} : _GEN_30; // @[DataLinkLayer.scala 451:17 422:25]
  wire [142:0] _GEN_48 = 3'h0 == state ? 143'h0 : _GEN_45; // @[DataLinkLayer.scala 451:17 453:16]
  wire [142:0] _GEN_51 = 3'h0 == state ? 143'h0 : _GEN_37; // @[DataLinkLayer.scala 451:17 456:17]
  wire [142:0] _GEN_53 = 3'h0 == state ? 143'h0 : _GEN_41; // @[DataLinkLayer.scala 451:17 458:17]
  reg [3:0] lastCorrectPkgID; // @[DataLinkLayer.scala 539:33]
  wire [15:0] _crcOut_T_3 = outWValid ? outWData[88:73] : 16'h0; // @[DataLinkLayer.scala 568:10]
  wire [15:0] _crcOut_T_4 = outARValid ? outARData[81:66] : _crcOut_T_3; // @[DataLinkLayer.scala 567:8]
  wire [15:0] crcOut = outAWValid ? outAWData[81:66] : _crcOut_T_4; // @[DataLinkLayer.scala 566:16]
  wire [15:0] _crcGene_T_6 = outWValid ? crcGene_crcgen_2_io_out : 16'h0; // @[DataLinkLayer.scala 572:10]
  wire [15:0] _crcGene_T_7 = outARValid ? crcGene_crcgen_1_io_out : _crcGene_T_6; // @[DataLinkLayer.scala 571:8]
  wire [15:0] crcGene = outAWValid ? crcGene_crcgen_io_out : _crcGene_T_7; // @[DataLinkLayer.scala 570:17]
  wire  _crcCorrect_T = crcOut == crcGene; // @[DataLinkLayer.scala 574:40]
  wire  _crcCorrect_T_3 = outWValid & _crcCorrect_T; // @[DataLinkLayer.scala 576:10]
  wire  _crcCorrect_T_4 = outARValid ? _crcCorrect_T : _crcCorrect_T_3; // @[DataLinkLayer.scala 575:8]
  wire  crcCorrect = outAWValid ? crcOut == crcGene : _crcCorrect_T_4; // @[DataLinkLayer.scala 574:20]
  wire  dataOutValid = outAWValid | outARValid | outWValid; // @[DataLinkLayer.scala 564:44]
  wire [3:0] _pkgIdOut_T_3 = outWValid ? outWData[92:89] : lastCorrectPkgID; // @[DataLinkLayer.scala 580:10]
  wire [3:0] _pkgIdOut_T_4 = outARValid ? outARData[85:82] : _pkgIdOut_T_3; // @[DataLinkLayer.scala 579:8]
  wire [3:0] pkgIdOut = outAWValid ? outAWData[85:82] : _pkgIdOut_T_4; // @[DataLinkLayer.scala 578:18]
  wire [3:0] _pkgIdCorrect_T_1 = lastCorrectPkgID + 4'h1; // @[DataLinkLayer.scala 582:67]
  wire  pkgIdCorrect = dataOutValid & pkgIdOut == _pkgIdCorrect_T_1; // @[DataLinkLayer.scala 582:33]
  wire  dataCorrect = crcCorrect & pkgIdCorrect; // @[DataLinkLayer.scala 584:30]
  wire [19:0] crcGene_hi = {16'h1234,pkgIdOut}; // @[Cat.scala 33:92]
  wire [19:0] crcGene_hi_1 = {16'h5678,pkgIdOut}; // @[Cat.scala 33:92]
  wire [19:0] crcGene_hi_2 = {16'h9abc,pkgIdOut}; // @[Cat.scala 33:92]
  wire  _T_20 = dataOutValid & ~dataCorrect; // @[DataLinkLayer.scala 590:27]
  wire [3:0] _GEN_64 = dataOutValid & ~dataCorrect ? lastCorrectPkgID : 4'h0; // @[DataLinkLayer.scala 590:43 593:31 597:31]
  reg  txReplayPkgIdReg; // @[DataLinkLayer.scala 601:33]
  reg  txCreditRB_freeReg; // @[DataLinkLayer.scala 603:35]
  reg [1:0] rx2TxCreditRB_freeReg; // @[DataLinkLayer.scala 607:38]
  reg  rx2TxCreditRB_freeValid; // @[DataLinkLayer.scala 608:40]
  reg [1:0] rx2TxCreditRB_freeCnt; // @[DataLinkLayer.scala 610:38]
  wire  _T_21 = rx2TxCreditRB_freeCnt == 2'h0; // @[DataLinkLayer.scala 612:52]
  wire  _T_24 = rx2TxCreditRB_freeCnt == 2'h2; // @[DataLinkLayer.scala 618:36]
  wire [1:0] _rx2TxCreditRB_freeReg_T_1 = {txCreditRB_freeReg,rx2TxCreditRB_freeReg[1]}; // @[Cat.scala 33:92]
  reg [3:0] rx2TxReplayPkgIDReg; // @[DataLinkLayer.scala 635:37]
  reg  rx2TxReplayPkgIDRegValid; // @[DataLinkLayer.scala 637:42]
  reg [2:0] rx2TxReplayPkgIDCnt; // @[DataLinkLayer.scala 639:36]
  wire  _T_26 = rx2TxReplayPkgIDCnt == 3'h0; // @[DataLinkLayer.scala 641:48]
  wire [2:0] _rx2TxReplayPkgIDCnt_T_1 = rx2TxReplayPkgIDCnt + 3'h1; // @[DataLinkLayer.scala 642:48]
  wire  _T_31 = rx2TxReplayPkgIDCnt == 3'h4; // @[DataLinkLayer.scala 647:34]
  wire [3:0] _rx2TxReplayPkgIDReg_T_1 = {txReplayPkgIdReg,rx2TxReplayPkgIDReg[3:1]}; // @[Cat.scala 33:92]
  ScrcGen_4 crcGene_crcgen ( // @[crcGen.scala 99:24]
    .io_in(crcGene_crcgen_io_in),
    .io_out(crcGene_crcgen_io_out)
  );
  ScrcGen_4 crcGene_crcgen_1 ( // @[crcGen.scala 99:24]
    .io_in(crcGene_crcgen_1_io_in),
    .io_out(crcGene_crcgen_1_io_out)
  );
  ScrcGen_6 crcGene_crcgen_2 ( // @[crcGen.scala 99:24]
    .io_in(crcGene_crcgen_2_io_in),
    .io_out(crcGene_crcgen_2_io_out)
  );
  assign io_outAXI4AW_valid = outAWValid & dataCorrect; // @[DataLinkLayer.scala 555:36]
  assign io_outAXI4AW_bits = outAWData[65:0]; // @[DataLinkLayer.scala 556:33]
  assign io_outAXI4AR_valid = outARValid & dataCorrect; // @[DataLinkLayer.scala 558:36]
  assign io_outAXI4AR_bits = outARData[65:0]; // @[DataLinkLayer.scala 559:33]
  assign io_outAXI4W_valid = outWValid & dataCorrect; // @[DataLinkLayer.scala 561:34]
  assign io_outAXI4W_bits = outWData[72:0]; // @[DataLinkLayer.scala 562:31]
  assign io_rxDebugState = state; // @[DataLinkLayer.scala 664:28]
  assign io_rxDebugLastCorrectPkgID = lastCorrectPkgID; // @[DataLinkLayer.scala 665:30]
  assign io_rx2TxCreditRBFree_valid = rx2TxCreditRB_freeValid; // @[DataLinkLayer.scala 632:30]
  assign io_rx2TxCreditRBFree_bits = rx2TxCreditRB_freeReg; // @[DataLinkLayer.scala 631:29]
  assign io_rx2TxPackageIDUsed_valid = rx2TxReplayPkgIDRegValid; // @[DataLinkLayer.scala 661:31]
  assign io_rx2TxPackageIDUsed_bits = rx2TxReplayPkgIDReg; // @[DataLinkLayer.scala 660:30]
  assign io_rx2TxPackageIDOut_valid = dataOutValid & dataCorrect | _T_20; // @[DataLinkLayer.scala 586:36 588:32]
  assign io_rx2TxPackageIDOut_bits = dataOutValid & dataCorrect ? pkgIdOut : _GEN_64; // @[DataLinkLayer.scala 586:36 589:31]
  assign crcGene_crcgen_io_in = {crcGene_hi,outAWData[65:0]}; // @[Cat.scala 33:92]
  assign crcGene_crcgen_1_io_in = {crcGene_hi_1,outARData[65:0]}; // @[Cat.scala 33:92]
  assign crcGene_crcgen_2_io_in = {crcGene_hi_2,outWData[72:0]}; // @[Cat.scala 33:92]
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 416:29]
      rxFlitBitReg <= 16'h0; // @[DataLinkLayer.scala 416:29]
    end else begin
      rxFlitBitReg <= io_rxPhy2LLIO_flit_bits; // @[DataLinkLayer.scala 417:16]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 418:31]
      rxFlitValidReg <= 1'h0; // @[DataLinkLayer.scala 418:31]
    end else begin
      rxFlitValidReg <= io_rxPhy2LLIO_flit_valid; // @[DataLinkLayer.scala 419:18]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outWValid <= 1'h0; // @[DataLinkLayer.scala 454:17]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outWValid <= 1'h0; // @[DataLinkLayer.scala 421:26]
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 451:17]
        if (3'h3 == state) begin // @[DataLinkLayer.scala 421:26]
          outWValid <= _outWValid_T_3;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 422:25]
      outWData <= 96'h0; // @[DataLinkLayer.scala 422:25]
    end else begin
      outWData <= _GEN_48[95:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outWDataShift <= 96'h0; // @[DataLinkLayer.scala 455:21]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outWDataShift <= 96'hffffffffffffffffffff0000; // @[DataLinkLayer.scala 423:30]
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 451:17]
        if (3'h3 == state) begin // @[DataLinkLayer.scala 423:30]
          outWDataShift <= _outWDataShift_T_4;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outAWValid <= 1'h0; // @[DataLinkLayer.scala 457:18]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outAWValid <= 1'h0; // @[DataLinkLayer.scala 503:26]
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 451:17]
      if (_state_T_2) begin // @[DataLinkLayer.scala 425:27]
        outAWValid <= 1'h0;
      end else begin
        outAWValid <= 1'h1;
      end
    end else if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (!(3'h3 == state)) begin
        outAWValid <= _GEN_15;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 426:27]
      outAWData <= 112'h0; // @[DataLinkLayer.scala 426:27]
    end else begin
      outAWData <= _GEN_51[111:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outAWDataShift <= 112'h0; // @[DataLinkLayer.scala 461:24]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outAWDataShift <= 112'hffffffffffffffffffffffff0000; // @[DataLinkLayer.scala 505:24]
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 427:32]
      outAWDataShift <= _outAWDataShift_T_4;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outARValid <= 1'h0; // @[DataLinkLayer.scala 459:18]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outARValid <= 1'h0; // @[DataLinkLayer.scala 429:27]
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (3'h2 == state) begin // @[DataLinkLayer.scala 429:27]
        if (_state_T_6) begin
          outARValid <= 1'h0;
        end else begin
          outARValid <= 1'h1;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 430:27]
      outARData <= 112'h0; // @[DataLinkLayer.scala 430:27]
    end else begin
      outARData <= _GEN_53[111:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      outARDataShift <= 112'h0; // @[DataLinkLayer.scala 462:24]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      outARDataShift <= 112'hffffffffffffffffffffffff0000; // @[DataLinkLayer.scala 431:32]
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (3'h2 == state) begin // @[DataLinkLayer.scala 431:32]
        outARDataShift <= _outARDataShift_T_4;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      axi4AWTCCnt <= 3'h0; // @[DataLinkLayer.scala 467:27 468:82 472:23 434:{29,29}]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 501:21]
        if (rxFlitBitReg == 16'h1234) begin
          axi4AWTCCnt <= 3'h0;
        end
      end
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 434:29]
      axi4AWTCCnt <= _axi4AWTCCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      axi4ARTCCnt <= 3'h0; // @[DataLinkLayer.scala 467:27 435:{29,29,29} 468:82 473:88 477:23]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 435:29]
        if (!(rxFlitBitReg == 16'h1234)) begin
          if (rxFlitBitReg == 16'h5678) begin
            axi4ARTCCnt <= 3'h0;
          end
        end
      end
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (3'h2 == state) begin // @[DataLinkLayer.scala 435:29]
        axi4ARTCCnt <= _axi4ARTCCnt_T_1;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      axi4WTCCnt <= 3'h0; // @[DataLinkLayer.scala 467:27 436:{29,29,29} 468:82 473:88]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 436:29]
        if (!(rxFlitBitReg == 16'h1234)) begin
          if (!(rxFlitBitReg == 16'h5678)) begin
            axi4WTCCnt <= 3'h0;
          end
        end
      end
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 451:17]
        if (3'h3 == state) begin // @[DataLinkLayer.scala 436:29]
          axi4WTCCnt <= _axi4WTCCnt_T_1;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      errorTCCnt <= 3'h0; // @[DataLinkLayer.scala 443:29]
    end else if (!(3'h0 == state)) begin // @[DataLinkLayer.scala 451:17]
      if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 451:17]
        if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 451:17]
          if (!(3'h3 == state)) begin
            errorTCCnt <= _GEN_13;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 451:17]
      state <= 3'h0;
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 451:17]
      state <= {{1'd0}, _GEN_9}; // @[DataLinkLayer.scala 502:15]
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 451:17]
      state <= {{2'd0}, axi4AWTCCnt < _state_T_1}; // @[DataLinkLayer.scala 511:15]
    end else if (3'h2 == state) begin // @[DataLinkLayer.scala 451:17]
      state <= {{1'd0}, _state_T_7}; // @[DataLinkLayer.scala 520:15]
    end else if (3'h3 == state) begin
      state <= {{1'd0}, _state_T_11};
    end else begin
      state <= _GEN_14;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 586:36]
      lastCorrectPkgID <= 4'hf; // @[DataLinkLayer.scala 587:22]
    end else if (dataOutValid & dataCorrect) begin
      lastCorrectPkgID <= _pkgIdCorrect_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 601:33]
      txReplayPkgIdReg <= 1'h0; // @[DataLinkLayer.scala 601:33]
    end else begin
      txReplayPkgIdReg <= io_rxPhy2LLIO_replayPkgID; // @[DataLinkLayer.scala 602:20]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 603:35]
      txCreditRB_freeReg <= 1'h0; // @[DataLinkLayer.scala 603:35]
    end else begin
      txCreditRB_freeReg <= io_rxPhy2LLIO_creditRB_free; // @[DataLinkLayer.scala 604:22]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 626:38]
      rx2TxCreditRB_freeReg <= 2'h0; // @[DataLinkLayer.scala 627:27]
    end else if (_T_21) begin // @[DataLinkLayer.scala 629:27]
      rx2TxCreditRB_freeReg <= 2'h0;
    end else begin
      rx2TxCreditRB_freeReg <= _rx2TxCreditRB_freeReg_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 612:60]
      rx2TxCreditRB_freeValid <= 1'h0; // @[DataLinkLayer.scala 614:29]
    end else if (txCreditRB_freeReg & rx2TxCreditRB_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 615:44]
      rx2TxCreditRB_freeValid <= 1'h0; // @[DataLinkLayer.scala 617:29]
    end else if (rx2TxCreditRB_freeCnt == 2'h1) begin
      rx2TxCreditRB_freeValid <= 1'h0;
    end else begin
      rx2TxCreditRB_freeValid <= _T_24;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 612:60]
      rx2TxCreditRB_freeCnt <= 2'h0; // @[DataLinkLayer.scala 613:27]
    end else if (txCreditRB_freeReg & rx2TxCreditRB_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 615:44]
      rx2TxCreditRB_freeCnt <= 2'h1; // @[DataLinkLayer.scala 616:27]
    end else if (rx2TxCreditRB_freeCnt == 2'h1) begin
      rx2TxCreditRB_freeCnt <= 2'h2;
    end else begin
      rx2TxCreditRB_freeCnt <= 2'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 655:36]
      rx2TxReplayPkgIDReg <= 4'h0; // @[DataLinkLayer.scala 656:25]
    end else if (_T_26) begin // @[DataLinkLayer.scala 658:25]
      rx2TxReplayPkgIDReg <= 4'h0;
    end else begin
      rx2TxReplayPkgIDReg <= _rx2TxReplayPkgIDReg_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 641:56]
      rx2TxReplayPkgIDRegValid <= 1'h0; // @[DataLinkLayer.scala 643:30]
    end else if (txReplayPkgIdReg & rx2TxReplayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 644:93]
      rx2TxReplayPkgIDRegValid <= 1'h0; // @[DataLinkLayer.scala 646:30]
    end else if (rx2TxReplayPkgIDCnt > 3'h0 & rx2TxReplayPkgIDCnt < 3'h4) begin
      rx2TxReplayPkgIDRegValid <= 1'h0;
    end else begin
      rx2TxReplayPkgIDRegValid <= _T_31;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 641:56]
      rx2TxReplayPkgIDCnt <= 3'h0; // @[DataLinkLayer.scala 642:25]
    end else if (txReplayPkgIdReg & rx2TxReplayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 644:93]
      rx2TxReplayPkgIDCnt <= _rx2TxReplayPkgIDCnt_T_1; // @[DataLinkLayer.scala 645:25]
    end else if (rx2TxReplayPkgIDCnt > 3'h0 & rx2TxReplayPkgIDCnt < 3'h4) begin
      rx2TxReplayPkgIDCnt <= _rx2TxReplayPkgIDCnt_T_1;
    end else begin
      rx2TxReplayPkgIDCnt <= 3'h0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rxFlitBitReg = _RAND_0[15:0];
  _RAND_1 = {1{`RANDOM}};
  rxFlitValidReg = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  outWValid = _RAND_2[0:0];
  _RAND_3 = {3{`RANDOM}};
  outWData = _RAND_3[95:0];
  _RAND_4 = {3{`RANDOM}};
  outWDataShift = _RAND_4[95:0];
  _RAND_5 = {1{`RANDOM}};
  outAWValid = _RAND_5[0:0];
  _RAND_6 = {4{`RANDOM}};
  outAWData = _RAND_6[111:0];
  _RAND_7 = {4{`RANDOM}};
  outAWDataShift = _RAND_7[111:0];
  _RAND_8 = {1{`RANDOM}};
  outARValid = _RAND_8[0:0];
  _RAND_9 = {4{`RANDOM}};
  outARData = _RAND_9[111:0];
  _RAND_10 = {4{`RANDOM}};
  outARDataShift = _RAND_10[111:0];
  _RAND_11 = {1{`RANDOM}};
  axi4AWTCCnt = _RAND_11[2:0];
  _RAND_12 = {1{`RANDOM}};
  axi4ARTCCnt = _RAND_12[2:0];
  _RAND_13 = {1{`RANDOM}};
  axi4WTCCnt = _RAND_13[2:0];
  _RAND_14 = {1{`RANDOM}};
  errorTCCnt = _RAND_14[2:0];
  _RAND_15 = {1{`RANDOM}};
  state = _RAND_15[2:0];
  _RAND_16 = {1{`RANDOM}};
  lastCorrectPkgID = _RAND_16[3:0];
  _RAND_17 = {1{`RANDOM}};
  txReplayPkgIdReg = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  txCreditRB_freeReg = _RAND_18[0:0];
  _RAND_19 = {1{`RANDOM}};
  rx2TxCreditRB_freeReg = _RAND_19[1:0];
  _RAND_20 = {1{`RANDOM}};
  rx2TxCreditRB_freeValid = _RAND_20[0:0];
  _RAND_21 = {1{`RANDOM}};
  rx2TxCreditRB_freeCnt = _RAND_21[1:0];
  _RAND_22 = {1{`RANDOM}};
  rx2TxReplayPkgIDReg = _RAND_22[3:0];
  _RAND_23 = {1{`RANDOM}};
  rx2TxReplayPkgIDRegValid = _RAND_23[0:0];
  _RAND_24 = {1{`RANDOM}};
  rx2TxReplayPkgIDCnt = _RAND_24[2:0];
`endif // RANDOMIZE_REG_INIT
  if (reset) begin
    rxFlitBitReg = 16'h0;
  end
  if (reset) begin
    rxFlitValidReg = 1'h0;
  end
  if (reset) begin
    outWValid = 1'h0;
  end
  if (reset) begin
    outWData = 96'h0;
  end
  if (reset) begin
    outWDataShift = 96'h0;
  end
  if (reset) begin
    outAWValid = 1'h0;
  end
  if (reset) begin
    outAWData = 112'h0;
  end
  if (reset) begin
    outAWDataShift = 112'h0;
  end
  if (reset) begin
    outARValid = 1'h0;
  end
  if (reset) begin
    outARData = 112'h0;
  end
  if (reset) begin
    outARDataShift = 112'h0;
  end
  if (reset) begin
    axi4AWTCCnt = 3'h0;
  end
  if (reset) begin
    axi4ARTCCnt = 3'h0;
  end
  if (reset) begin
    axi4WTCCnt = 3'h0;
  end
  if (reset) begin
    errorTCCnt = 3'h0;
  end
  if (reset) begin
    state = 3'h0;
  end
  if (reset) begin
    lastCorrectPkgID = 4'hf;
  end
  if (reset) begin
    txReplayPkgIdReg = 1'h0;
  end
  if (reset) begin
    txCreditRB_freeReg = 1'h0;
  end
  if (reset) begin
    rx2TxCreditRB_freeReg = 2'h0;
  end
  if (reset) begin
    rx2TxCreditRB_freeValid = 1'h0;
  end
  if (reset) begin
    rx2TxCreditRB_freeCnt = 2'h0;
  end
  if (reset) begin
    rx2TxReplayPkgIDReg = 4'h0;
  end
  if (reset) begin
    rx2TxReplayPkgIDRegValid = 1'h0;
  end
  if (reset) begin
    rx2TxReplayPkgIDCnt = 3'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SSlaveRxPhy(
  output        io_rxPhy2LLIO_flit_valid,
  output [15:0] io_rxPhy2LLIO_flit_bits,
  output        io_rxPhy2LLIO_creditRB_free,
  output        io_rxPhy2LLIO_replayPkgID,
  input         io_rxPhyIO_flit_valid,
  input  [15:0] io_rxPhyIO_flit_bits,
  input         io_rxPhyIO_creditRB_free,
  input         io_rxPhyIO_replayPkgID
);
  assign io_rxPhy2LLIO_flit_valid = io_rxPhyIO_flit_valid; // @[Phy.scala 22:22]
  assign io_rxPhy2LLIO_flit_bits = io_rxPhyIO_flit_bits; // @[Phy.scala 22:22]
  assign io_rxPhy2LLIO_creditRB_free = io_rxPhyIO_creditRB_free; // @[Phy.scala 24:31]
  assign io_rxPhy2LLIO_replayPkgID = io_rxPhyIO_replayPkgID; // @[Phy.scala 25:29]
endmodule
module SskidBuffer(
  input         clock,
  input         reset,
  output        io_i_data_ready,
  input         io_i_data_valid,
  input  [72:0] io_i_data_bits,
  input         io_o_data_ready,
  output        io_o_data_valid,
  output [72:0] io_o_data_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [95:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg  r_valid; // @[skidBuffer.scala 15:24]
  reg [72:0] r_data; // @[skidBuffer.scala 16:23]
  wire  _T = io_i_data_ready & io_i_data_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = io_o_data_ready ? 1'h0 : r_valid; // @[skidBuffer.scala 20:30 21:13 23:13]
  wire  _GEN_1 = _T & (io_o_data_valid & ~io_o_data_ready) | _GEN_0; // @[skidBuffer.scala 18:64 19:13]
  wire  _T_5 = ~io_o_data_valid | io_o_data_ready; // @[skidBuffer.scala 26:45]
  reg  ro_valid; // @[skidBuffer.scala 47:27]
  reg [72:0] ro_data; // @[skidBuffer.scala 48:26]
  assign io_i_data_ready = ~r_valid; // @[skidBuffer.scala 31:22]
  assign io_o_data_valid = ro_valid; // @[skidBuffer.scala 52:21]
  assign io_o_data_bits = ro_data; // @[skidBuffer.scala 64:20]
  always @(posedge clock) begin
    if (reset) begin // @[skidBuffer.scala 15:24]
      r_valid <= 1'h0; // @[skidBuffer.scala 15:24]
    end else begin
      r_valid <= _GEN_1;
    end
    if (reset) begin // @[skidBuffer.scala 16:23]
      r_data <= 73'h0; // @[skidBuffer.scala 16:23]
    end else if (~io_o_data_valid | io_o_data_ready) begin // @[skidBuffer.scala 26:65]
      r_data <= 73'h0; // @[skidBuffer.scala 27:12]
    end else if (io_i_data_valid & io_i_data_ready) begin // @[skidBuffer.scala 28:89]
      r_data <= io_i_data_bits; // @[skidBuffer.scala 29:12]
    end
    if (reset) begin // @[skidBuffer.scala 47:27]
      ro_valid <= 1'h0; // @[skidBuffer.scala 47:27]
    end else if (_T_5) begin // @[skidBuffer.scala 49:46]
      ro_valid <= io_i_data_valid | r_valid; // @[skidBuffer.scala 50:16]
    end
    if (reset) begin // @[skidBuffer.scala 48:26]
      ro_data <= 73'h0; // @[skidBuffer.scala 48:26]
    end else if (_T_5) begin // @[skidBuffer.scala 55:46]
      if (r_valid) begin // @[skidBuffer.scala 56:21]
        ro_data <= r_data; // @[skidBuffer.scala 57:17]
      end else if (io_i_data_valid) begin // @[skidBuffer.scala 58:55]
        ro_data <= io_i_data_bits; // @[skidBuffer.scala 59:17]
      end else begin
        ro_data <= 73'h0; // @[skidBuffer.scala 61:17]
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  r_valid = _RAND_0[0:0];
  _RAND_1 = {3{`RANDOM}};
  r_data = _RAND_1[72:0];
  _RAND_2 = {1{`RANDOM}};
  ro_valid = _RAND_2[0:0];
  _RAND_3 = {3{`RANDOM}};
  ro_data = _RAND_3[72:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SskidBuffer_1(
  input         clock,
  input         reset,
  output        io_i_data_ready,
  input         io_i_data_valid,
  input  [65:0] io_i_data_bits,
  input         io_o_data_ready,
  output        io_o_data_valid,
  output [65:0] io_o_data_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [95:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg  r_valid; // @[skidBuffer.scala 15:24]
  reg [65:0] r_data; // @[skidBuffer.scala 16:23]
  wire  _T = io_i_data_ready & io_i_data_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = io_o_data_ready ? 1'h0 : r_valid; // @[skidBuffer.scala 20:30 21:13 23:13]
  wire  _GEN_1 = _T & (io_o_data_valid & ~io_o_data_ready) | _GEN_0; // @[skidBuffer.scala 18:64 19:13]
  wire  _T_5 = ~io_o_data_valid | io_o_data_ready; // @[skidBuffer.scala 26:45]
  reg  ro_valid; // @[skidBuffer.scala 47:27]
  reg [65:0] ro_data; // @[skidBuffer.scala 48:26]
  assign io_i_data_ready = ~r_valid; // @[skidBuffer.scala 31:22]
  assign io_o_data_valid = ro_valid; // @[skidBuffer.scala 52:21]
  assign io_o_data_bits = ro_data; // @[skidBuffer.scala 64:20]
  always @(posedge clock) begin
    if (reset) begin // @[skidBuffer.scala 15:24]
      r_valid <= 1'h0; // @[skidBuffer.scala 15:24]
    end else begin
      r_valid <= _GEN_1;
    end
    if (reset) begin // @[skidBuffer.scala 16:23]
      r_data <= 66'h0; // @[skidBuffer.scala 16:23]
    end else if (~io_o_data_valid | io_o_data_ready) begin // @[skidBuffer.scala 26:65]
      r_data <= 66'h0; // @[skidBuffer.scala 27:12]
    end else if (io_i_data_valid & io_i_data_ready) begin // @[skidBuffer.scala 28:89]
      r_data <= io_i_data_bits; // @[skidBuffer.scala 29:12]
    end
    if (reset) begin // @[skidBuffer.scala 47:27]
      ro_valid <= 1'h0; // @[skidBuffer.scala 47:27]
    end else if (_T_5) begin // @[skidBuffer.scala 49:46]
      ro_valid <= io_i_data_valid | r_valid; // @[skidBuffer.scala 50:16]
    end
    if (reset) begin // @[skidBuffer.scala 48:26]
      ro_data <= 66'h0; // @[skidBuffer.scala 48:26]
    end else if (_T_5) begin // @[skidBuffer.scala 55:46]
      if (r_valid) begin // @[skidBuffer.scala 56:21]
        ro_data <= r_data; // @[skidBuffer.scala 57:17]
      end else if (io_i_data_valid) begin // @[skidBuffer.scala 58:55]
        ro_data <= io_i_data_bits; // @[skidBuffer.scala 59:17]
      end else begin
        ro_data <= 66'h0; // @[skidBuffer.scala 61:17]
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  r_valid = _RAND_0[0:0];
  _RAND_1 = {3{`RANDOM}};
  r_data = _RAND_1[65:0];
  _RAND_2 = {1{`RANDOM}};
  ro_valid = _RAND_2[0:0];
  _RAND_3 = {3{`RANDOM}};
  ro_data = _RAND_3[65:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SSlaveRxAppLayer(
  input         clock,
  input         reset,
  output        io_appInAXI4AW_ready,
  input         io_appInAXI4AW_valid,
  input  [65:0] io_appInAXI4AW_bits,
  output        io_appInAXI4AR_ready,
  input         io_appInAXI4AR_valid,
  input  [65:0] io_appInAXI4AR_bits,
  output        io_appInAXI4W_ready,
  input         io_appInAXI4W_valid,
  input  [72:0] io_appInAXI4W_bits,
  input         io_appOutAXI4W_ready,
  output        io_appOutAXI4W_valid,
  output [63:0] io_appOutAXI4W_bits_data,
  output        io_appOutAXI4W_bits_last,
  output [7:0]  io_appOutAXI4W_bits_strb,
  input         io_appOutAXI4AW_ready,
  output        io_appOutAXI4AW_valid,
  output [31:0] io_appOutAXI4AW_bits_addr,
  output [4:0]  io_appOutAXI4AW_bits_id,
  output [2:0]  io_appOutAXI4AW_bits_size,
  output [7:0]  io_appOutAXI4AW_bits_len,
  output [1:0]  io_appOutAXI4AW_bits_burst,
  output [3:0]  io_appOutAXI4AW_bits_cache,
  output        io_appOutAXI4AW_bits_lock,
  output [2:0]  io_appOutAXI4AW_bits_prot,
  output [3:0]  io_appOutAXI4AW_bits_qos,
  output [3:0]  io_appOutAXI4AW_bits_region,
  input         io_appOutAXI4AR_ready,
  output        io_appOutAXI4AR_valid,
  output [31:0] io_appOutAXI4AR_bits_addr,
  output [4:0]  io_appOutAXI4AR_bits_id,
  output [2:0]  io_appOutAXI4AR_bits_size,
  output [7:0]  io_appOutAXI4AR_bits_len,
  output [1:0]  io_appOutAXI4AR_bits_burst,
  output [3:0]  io_appOutAXI4AR_bits_cache,
  output        io_appOutAXI4AR_bits_lock,
  output [2:0]  io_appOutAXI4AR_bits_prot,
  output [3:0]  io_appOutAXI4AR_bits_qos,
  output [3:0]  io_appOutAXI4AR_bits_region
);
  wire  skidBufferW_clock; // @[AppLayer.scala 45:27]
  wire  skidBufferW_reset; // @[AppLayer.scala 45:27]
  wire  skidBufferW_io_i_data_ready; // @[AppLayer.scala 45:27]
  wire  skidBufferW_io_i_data_valid; // @[AppLayer.scala 45:27]
  wire [72:0] skidBufferW_io_i_data_bits; // @[AppLayer.scala 45:27]
  wire  skidBufferW_io_o_data_ready; // @[AppLayer.scala 45:27]
  wire  skidBufferW_io_o_data_valid; // @[AppLayer.scala 45:27]
  wire [72:0] skidBufferW_io_o_data_bits; // @[AppLayer.scala 45:27]
  wire  skidBufferAR_clock; // @[AppLayer.scala 62:28]
  wire  skidBufferAR_reset; // @[AppLayer.scala 62:28]
  wire  skidBufferAR_io_i_data_ready; // @[AppLayer.scala 62:28]
  wire  skidBufferAR_io_i_data_valid; // @[AppLayer.scala 62:28]
  wire [65:0] skidBufferAR_io_i_data_bits; // @[AppLayer.scala 62:28]
  wire  skidBufferAR_io_o_data_ready; // @[AppLayer.scala 62:28]
  wire  skidBufferAR_io_o_data_valid; // @[AppLayer.scala 62:28]
  wire [65:0] skidBufferAR_io_o_data_bits; // @[AppLayer.scala 62:28]
  wire  skidBufferAW_clock; // @[AppLayer.scala 82:28]
  wire  skidBufferAW_reset; // @[AppLayer.scala 82:28]
  wire  skidBufferAW_io_i_data_ready; // @[AppLayer.scala 82:28]
  wire  skidBufferAW_io_i_data_valid; // @[AppLayer.scala 82:28]
  wire [65:0] skidBufferAW_io_i_data_bits; // @[AppLayer.scala 82:28]
  wire  skidBufferAW_io_o_data_ready; // @[AppLayer.scala 82:28]
  wire  skidBufferAW_io_o_data_valid; // @[AppLayer.scala 82:28]
  wire [65:0] skidBufferAW_io_o_data_bits; // @[AppLayer.scala 82:28]
  wire  _skidBufferW_io_i_data_bits_T_2 = io_appInAXI4W_valid & io_appInAXI4W_bits[64]; // @[AppLayer.scala 48:8]
  wire [8:0] skidBufferW_io_i_data_bits_hi = {io_appInAXI4W_bits[72:65],_skidBufferW_io_i_data_bits_T_2}; // @[Cat.scala 33:92]
  SskidBuffer skidBufferW ( // @[AppLayer.scala 45:27]
    .clock(skidBufferW_clock),
    .reset(skidBufferW_reset),
    .io_i_data_ready(skidBufferW_io_i_data_ready),
    .io_i_data_valid(skidBufferW_io_i_data_valid),
    .io_i_data_bits(skidBufferW_io_i_data_bits),
    .io_o_data_ready(skidBufferW_io_o_data_ready),
    .io_o_data_valid(skidBufferW_io_o_data_valid),
    .io_o_data_bits(skidBufferW_io_o_data_bits)
  );
  SskidBuffer_1 skidBufferAR ( // @[AppLayer.scala 62:28]
    .clock(skidBufferAR_clock),
    .reset(skidBufferAR_reset),
    .io_i_data_ready(skidBufferAR_io_i_data_ready),
    .io_i_data_valid(skidBufferAR_io_i_data_valid),
    .io_i_data_bits(skidBufferAR_io_i_data_bits),
    .io_o_data_ready(skidBufferAR_io_o_data_ready),
    .io_o_data_valid(skidBufferAR_io_o_data_valid),
    .io_o_data_bits(skidBufferAR_io_o_data_bits)
  );
  SskidBuffer_1 skidBufferAW ( // @[AppLayer.scala 82:28]
    .clock(skidBufferAW_clock),
    .reset(skidBufferAW_reset),
    .io_i_data_ready(skidBufferAW_io_i_data_ready),
    .io_i_data_valid(skidBufferAW_io_i_data_valid),
    .io_i_data_bits(skidBufferAW_io_i_data_bits),
    .io_o_data_ready(skidBufferAW_io_o_data_ready),
    .io_o_data_valid(skidBufferAW_io_o_data_valid),
    .io_o_data_bits(skidBufferAW_io_o_data_bits)
  );
  assign io_appInAXI4AW_ready = skidBufferAW_io_i_data_ready; // @[AppLayer.scala 85:24]
  assign io_appInAXI4AR_ready = skidBufferAR_io_i_data_ready; // @[AppLayer.scala 65:24]
  assign io_appInAXI4W_ready = skidBufferW_io_i_data_ready; // @[AppLayer.scala 52:23]
  assign io_appOutAXI4W_valid = skidBufferW_io_o_data_valid; // @[AppLayer.scala 54:24]
  assign io_appOutAXI4W_bits_data = skidBufferW_io_o_data_bits[63:0]; // @[AppLayer.scala 56:57]
  assign io_appOutAXI4W_bits_last = skidBufferW_io_o_data_bits[64]; // @[AppLayer.scala 57:57]
  assign io_appOutAXI4W_bits_strb = skidBufferW_io_o_data_bits[72:65]; // @[AppLayer.scala 58:57]
  assign io_appOutAXI4AW_valid = skidBufferAW_io_o_data_valid; // @[AppLayer.scala 87:25]
  assign io_appOutAXI4AW_bits_addr = skidBufferAW_io_o_data_bits[60:29]; // @[AppLayer.scala 90:61]
  assign io_appOutAXI4AW_bits_id = skidBufferAW_io_o_data_bits[65:61]; // @[AppLayer.scala 89:61]
  assign io_appOutAXI4AW_bits_size = skidBufferAW_io_o_data_bits[20:18]; // @[AppLayer.scala 92:61]
  assign io_appOutAXI4AW_bits_len = skidBufferAW_io_o_data_bits[28:21]; // @[AppLayer.scala 91:61]
  assign io_appOutAXI4AW_bits_burst = skidBufferAW_io_o_data_bits[17:16]; // @[AppLayer.scala 93:61]
  assign io_appOutAXI4AW_bits_cache = skidBufferAW_io_o_data_bits[14:11]; // @[AppLayer.scala 95:61]
  assign io_appOutAXI4AW_bits_lock = skidBufferAW_io_o_data_bits[15]; // @[AppLayer.scala 94:61]
  assign io_appOutAXI4AW_bits_prot = skidBufferAW_io_o_data_bits[10:8]; // @[AppLayer.scala 96:61]
  assign io_appOutAXI4AW_bits_qos = skidBufferAW_io_o_data_bits[7:4]; // @[AppLayer.scala 97:61]
  assign io_appOutAXI4AW_bits_region = skidBufferAW_io_o_data_bits[3:0]; // @[AppLayer.scala 98:61]
  assign io_appOutAXI4AR_valid = skidBufferAR_io_o_data_valid; // @[AppLayer.scala 67:25]
  assign io_appOutAXI4AR_bits_addr = skidBufferAR_io_o_data_bits[60:29]; // @[AppLayer.scala 70:61]
  assign io_appOutAXI4AR_bits_id = skidBufferAR_io_o_data_bits[65:61]; // @[AppLayer.scala 69:61]
  assign io_appOutAXI4AR_bits_size = skidBufferAR_io_o_data_bits[20:18]; // @[AppLayer.scala 72:61]
  assign io_appOutAXI4AR_bits_len = skidBufferAR_io_o_data_bits[28:21]; // @[AppLayer.scala 71:61]
  assign io_appOutAXI4AR_bits_burst = skidBufferAR_io_o_data_bits[17:16]; // @[AppLayer.scala 73:61]
  assign io_appOutAXI4AR_bits_cache = skidBufferAR_io_o_data_bits[14:11]; // @[AppLayer.scala 75:61]
  assign io_appOutAXI4AR_bits_lock = skidBufferAR_io_o_data_bits[15]; // @[AppLayer.scala 74:61]
  assign io_appOutAXI4AR_bits_prot = skidBufferAR_io_o_data_bits[10:8]; // @[AppLayer.scala 76:61]
  assign io_appOutAXI4AR_bits_qos = skidBufferAR_io_o_data_bits[7:4]; // @[AppLayer.scala 77:61]
  assign io_appOutAXI4AR_bits_region = skidBufferAR_io_o_data_bits[3:0]; // @[AppLayer.scala 78:61]
  assign skidBufferW_clock = clock;
  assign skidBufferW_reset = reset;
  assign skidBufferW_io_i_data_valid = io_appInAXI4W_valid; // @[AppLayer.scala 51:31]
  assign skidBufferW_io_i_data_bits = {skidBufferW_io_i_data_bits_hi,io_appInAXI4W_bits[63:0]}; // @[Cat.scala 33:92]
  assign skidBufferW_io_o_data_ready = io_appOutAXI4W_ready; // @[AppLayer.scala 55:31]
  assign skidBufferAR_clock = clock;
  assign skidBufferAR_reset = reset;
  assign skidBufferAR_io_i_data_valid = io_appInAXI4AR_valid; // @[AppLayer.scala 64:32]
  assign skidBufferAR_io_i_data_bits = io_appInAXI4AR_bits; // @[AppLayer.scala 63:31]
  assign skidBufferAR_io_o_data_ready = io_appOutAXI4AR_ready; // @[AppLayer.scala 68:32]
  assign skidBufferAW_clock = clock;
  assign skidBufferAW_reset = reset;
  assign skidBufferAW_io_i_data_valid = io_appInAXI4AW_valid; // @[AppLayer.scala 84:32]
  assign skidBufferAW_io_i_data_bits = io_appInAXI4AW_bits; // @[AppLayer.scala 83:31]
  assign skidBufferAW_io_o_data_ready = io_appOutAXI4AW_ready; // @[AppLayer.scala 88:32]
endmodule
module Sd2dSlaveRx(
  input         clock,
  input         reset,
  input         io_outAXI4W_ready,
  output        io_outAXI4W_valid,
  output [63:0] io_outAXI4W_bits_data,
  output        io_outAXI4W_bits_last,
  output [7:0]  io_outAXI4W_bits_strb,
  input         io_outAXI4AW_ready,
  output        io_outAXI4AW_valid,
  output [31:0] io_outAXI4AW_bits_addr,
  output [4:0]  io_outAXI4AW_bits_id,
  output [2:0]  io_outAXI4AW_bits_size,
  output [7:0]  io_outAXI4AW_bits_len,
  output [1:0]  io_outAXI4AW_bits_burst,
  output [3:0]  io_outAXI4AW_bits_cache,
  output        io_outAXI4AW_bits_lock,
  output [2:0]  io_outAXI4AW_bits_prot,
  output [3:0]  io_outAXI4AW_bits_qos,
  output [3:0]  io_outAXI4AW_bits_region,
  input         io_outAXI4AR_ready,
  output        io_outAXI4AR_valid,
  output [31:0] io_outAXI4AR_bits_addr,
  output [4:0]  io_outAXI4AR_bits_id,
  output [2:0]  io_outAXI4AR_bits_size,
  output [7:0]  io_outAXI4AR_bits_len,
  output [1:0]  io_outAXI4AR_bits_burst,
  output [3:0]  io_outAXI4AR_bits_cache,
  output        io_outAXI4AR_bits_lock,
  output [2:0]  io_outAXI4AR_bits_prot,
  output [3:0]  io_outAXI4AR_bits_qos,
  output [3:0]  io_outAXI4AR_bits_region,
  input         io_rx_clock,
  input         io_rx_flit_valid,
  input  [15:0] io_rx_flit_bits,
  input         io_rx_creditRB_free,
  input         io_rx_replayPkgID,
  output [2:0]  io_rxDebugState,
  output [3:0]  io_rxDebugLastCorrectPkgID,
  output [10:0] io_preAddrIn,
  output        io_rx2TxCreditARWFree_valid,
  output [2:0]  io_rx2TxCreditARWFree_bits,
  output        io_rx2TxPackageIDUsed_valid,
  output [3:0]  io_rx2TxPackageIDUsed_bits,
  output        io_rx2TxCreditRBFree_valid,
  output [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDOut_valid,
  output [3:0]  io_rx2TxPackageIDOut_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  wire  rstRxSync_clock; // @[D2dSlaveRx.scala 22:25]
  wire  rstRxSync_reset_in; // @[D2dSlaveRx.scala 22:25]
  wire  rstRxSync_reset_out; // @[D2dSlaveRx.scala 22:25]
  wire  asyncQW_wr_clock; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_wr_reset; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_wr_valid; // @[D2dSlaveRx.scala 27:23]
  wire [72:0] asyncQW_wr_bits; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_rd_clock; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_rd_reset; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_rd_ready; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQW_rd_valid; // @[D2dSlaveRx.scala 27:23]
  wire [72:0] asyncQW_rd_bits; // @[D2dSlaveRx.scala 27:23]
  wire  asyncQAR_wr_clock; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_wr_reset; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_wr_valid; // @[D2dSlaveRx.scala 33:24]
  wire [65:0] asyncQAR_wr_bits; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_rd_clock; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_rd_reset; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_rd_ready; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAR_rd_valid; // @[D2dSlaveRx.scala 33:24]
  wire [65:0] asyncQAR_rd_bits; // @[D2dSlaveRx.scala 33:24]
  wire  asyncQAW_wr_clock; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_wr_reset; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_wr_valid; // @[D2dSlaveRx.scala 39:24]
  wire [65:0] asyncQAW_wr_bits; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_rd_clock; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_rd_reset; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_rd_ready; // @[D2dSlaveRx.scala 39:24]
  wire  asyncQAW_rd_valid; // @[D2dSlaveRx.scala 39:24]
  wire [65:0] asyncQAW_rd_bits; // @[D2dSlaveRx.scala 39:24]
  wire  slaveRxLinkLayer_clock; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_reset; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rxPhy2LLIO_flit_valid; // @[D2dSlaveRx.scala 50:34]
  wire [15:0] slaveRxLinkLayer_io_rxPhy2LLIO_flit_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rxPhy2LLIO_creditRB_free; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rxPhy2LLIO_replayPkgID; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_outAXI4AW_valid; // @[D2dSlaveRx.scala 50:34]
  wire [65:0] slaveRxLinkLayer_io_outAXI4AW_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_outAXI4AR_valid; // @[D2dSlaveRx.scala 50:34]
  wire [65:0] slaveRxLinkLayer_io_outAXI4AR_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_outAXI4W_valid; // @[D2dSlaveRx.scala 50:34]
  wire [72:0] slaveRxLinkLayer_io_outAXI4W_bits; // @[D2dSlaveRx.scala 50:34]
  wire [2:0] slaveRxLinkLayer_io_rxDebugState; // @[D2dSlaveRx.scala 50:34]
  wire [3:0] slaveRxLinkLayer_io_rxDebugLastCorrectPkgID; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rx2TxCreditRBFree_valid; // @[D2dSlaveRx.scala 50:34]
  wire [1:0] slaveRxLinkLayer_io_rx2TxCreditRBFree_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dSlaveRx.scala 50:34]
  wire [3:0] slaveRxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dSlaveRx.scala 50:34]
  wire [3:0] slaveRxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dSlaveRx.scala 50:34]
  wire  slaveRxPhy_io_rxPhy2LLIO_flit_valid; // @[D2dSlaveRx.scala 51:28]
  wire [15:0] slaveRxPhy_io_rxPhy2LLIO_flit_bits; // @[D2dSlaveRx.scala 51:28]
  wire  slaveRxPhy_io_rxPhy2LLIO_creditRB_free; // @[D2dSlaveRx.scala 51:28]
  wire  slaveRxPhy_io_rxPhy2LLIO_replayPkgID; // @[D2dSlaveRx.scala 51:28]
  wire  slaveRxPhy_io_rxPhyIO_flit_valid; // @[D2dSlaveRx.scala 51:28]
  wire [15:0] slaveRxPhy_io_rxPhyIO_flit_bits; // @[D2dSlaveRx.scala 51:28]
  wire  slaveRxPhy_io_rxPhyIO_creditRB_free; // @[D2dSlaveRx.scala 51:28]
  wire  slaveRxPhy_io_rxPhyIO_replayPkgID; // @[D2dSlaveRx.scala 51:28]
  wire  SlaveRxNegSync_clock; // @[D2dSlaveRx.scala 54:32]
  wire  SlaveRxNegSync_reset; // @[D2dSlaveRx.scala 54:32]
  wire [18:0] SlaveRxNegSync_x; // @[D2dSlaveRx.scala 54:32]
  wire [18:0] SlaveRxNegSync_y; // @[D2dSlaveRx.scala 54:32]
  wire  SlaveRxAppLayer_clock; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_reset; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4AW_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4AW_valid; // @[D2dSlaveRx.scala 78:31]
  wire [65:0] SlaveRxAppLayer_io_appInAXI4AW_bits; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4AR_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4AR_valid; // @[D2dSlaveRx.scala 78:31]
  wire [65:0] SlaveRxAppLayer_io_appInAXI4AR_bits; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4W_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appInAXI4W_valid; // @[D2dSlaveRx.scala 78:31]
  wire [72:0] SlaveRxAppLayer_io_appInAXI4W_bits; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4W_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4W_valid; // @[D2dSlaveRx.scala 78:31]
  wire [63:0] SlaveRxAppLayer_io_appOutAXI4W_bits_data; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4W_bits_last; // @[D2dSlaveRx.scala 78:31]
  wire [7:0] SlaveRxAppLayer_io_appOutAXI4W_bits_strb; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AW_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AW_valid; // @[D2dSlaveRx.scala 78:31]
  wire [31:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_addr; // @[D2dSlaveRx.scala 78:31]
  wire [4:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_id; // @[D2dSlaveRx.scala 78:31]
  wire [2:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_size; // @[D2dSlaveRx.scala 78:31]
  wire [7:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_len; // @[D2dSlaveRx.scala 78:31]
  wire [1:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_burst; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_cache; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AW_bits_lock; // @[D2dSlaveRx.scala 78:31]
  wire [2:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_prot; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_qos; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AW_bits_region; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AR_ready; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AR_valid; // @[D2dSlaveRx.scala 78:31]
  wire [31:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_addr; // @[D2dSlaveRx.scala 78:31]
  wire [4:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_id; // @[D2dSlaveRx.scala 78:31]
  wire [2:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_size; // @[D2dSlaveRx.scala 78:31]
  wire [7:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_len; // @[D2dSlaveRx.scala 78:31]
  wire [1:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_burst; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_cache; // @[D2dSlaveRx.scala 78:31]
  wire  SlaveRxAppLayer_io_appOutAXI4AR_bits_lock; // @[D2dSlaveRx.scala 78:31]
  wire [2:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_prot; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_qos; // @[D2dSlaveRx.scala 78:31]
  wire [3:0] SlaveRxAppLayer_io_appOutAXI4AR_bits_region; // @[D2dSlaveRx.scala 78:31]
  wire  _io_rx2TxCreditARWFree_valid_T = asyncQW_rd_ready & asyncQW_rd_valid; // @[Decoupled.scala 52:35]
  wire  _io_rx2TxCreditARWFree_valid_T_1 = asyncQAW_rd_ready & asyncQAW_rd_valid; // @[Decoupled.scala 52:35]
  wire  _io_rx2TxCreditARWFree_valid_T_2 = asyncQAR_rd_ready & asyncQAR_rd_valid; // @[Decoupled.scala 52:35]
  wire [1:0] io_rx2TxCreditARWFree_valid_hi = {_io_rx2TxCreditARWFree_valid_T,_io_rx2TxCreditARWFree_valid_T_1}; // @[Cat.scala 33:92]
  wire [2:0] _io_rx2TxCreditARWFree_valid_T_3 = {_io_rx2TxCreditARWFree_valid_T,_io_rx2TxCreditARWFree_valid_T_1,
    _io_rx2TxCreditARWFree_valid_T_2}; // @[Cat.scala 33:92]
  wire [1:0] SlaveRxNegSync_io_x_lo = {io_rx_creditRB_free,io_rx_replayPkgID}; // @[Cat.scala 33:92]
  wire [16:0] SlaveRxNegSync_io_x_hi = {io_rx_flit_valid,io_rx_flit_bits}; // @[Cat.scala 33:92]
  reg [10:0] rPreAddrIn; // @[D2dSlaveRx.scala 91:27]
  wire  _T = SlaveRxAppLayer_io_appInAXI4AR_ready & SlaveRxAppLayer_io_appInAXI4AR_valid; // @[Decoupled.scala 52:35]
  wire  _T_1 = SlaveRxAppLayer_io_appInAXI4AW_ready & SlaveRxAppLayer_io_appInAXI4AW_valid; // @[Decoupled.scala 52:35]
  ResetSync_d2d rstRxSync ( // @[D2dSlaveRx.scala 22:25]
    .clock(rstRxSync_clock),
    .reset_in(rstRxSync_reset_in),
    .reset_out(rstRxSync_reset_out)
  );
  SAsyncQueue_2 asyncQW ( // @[D2dSlaveRx.scala 27:23]
    .wr_clock(asyncQW_wr_clock),
    .wr_reset(asyncQW_wr_reset),
    .wr_valid(asyncQW_wr_valid),
    .wr_bits(asyncQW_wr_bits),
    .rd_clock(asyncQW_rd_clock),
    .rd_reset(asyncQW_rd_reset),
    .rd_ready(asyncQW_rd_ready),
    .rd_valid(asyncQW_rd_valid),
    .rd_bits(asyncQW_rd_bits)
  );
  SAsyncQueue_3 asyncQAR ( // @[D2dSlaveRx.scala 33:24]
    .wr_clock(asyncQAR_wr_clock),
    .wr_reset(asyncQAR_wr_reset),
    .wr_valid(asyncQAR_wr_valid),
    .wr_bits(asyncQAR_wr_bits),
    .rd_clock(asyncQAR_rd_clock),
    .rd_reset(asyncQAR_rd_reset),
    .rd_ready(asyncQAR_rd_ready),
    .rd_valid(asyncQAR_rd_valid),
    .rd_bits(asyncQAR_rd_bits)
  );
  SAsyncQueue_3 asyncQAW ( // @[D2dSlaveRx.scala 39:24]
    .wr_clock(asyncQAW_wr_clock),
    .wr_reset(asyncQAW_wr_reset),
    .wr_valid(asyncQAW_wr_valid),
    .wr_bits(asyncQAW_wr_bits),
    .rd_clock(asyncQAW_rd_clock),
    .rd_reset(asyncQAW_rd_reset),
    .rd_ready(asyncQAW_rd_ready),
    .rd_valid(asyncQAW_rd_valid),
    .rd_bits(asyncQAW_rd_bits)
  );
  SSlaveRxLinkLayer slaveRxLinkLayer ( // @[D2dSlaveRx.scala 50:34]
    .clock(slaveRxLinkLayer_clock),
    .reset(slaveRxLinkLayer_reset),
    .io_rxPhy2LLIO_flit_valid(slaveRxLinkLayer_io_rxPhy2LLIO_flit_valid),
    .io_rxPhy2LLIO_flit_bits(slaveRxLinkLayer_io_rxPhy2LLIO_flit_bits),
    .io_rxPhy2LLIO_creditRB_free(slaveRxLinkLayer_io_rxPhy2LLIO_creditRB_free),
    .io_rxPhy2LLIO_replayPkgID(slaveRxLinkLayer_io_rxPhy2LLIO_replayPkgID),
    .io_outAXI4AW_valid(slaveRxLinkLayer_io_outAXI4AW_valid),
    .io_outAXI4AW_bits(slaveRxLinkLayer_io_outAXI4AW_bits),
    .io_outAXI4AR_valid(slaveRxLinkLayer_io_outAXI4AR_valid),
    .io_outAXI4AR_bits(slaveRxLinkLayer_io_outAXI4AR_bits),
    .io_outAXI4W_valid(slaveRxLinkLayer_io_outAXI4W_valid),
    .io_outAXI4W_bits(slaveRxLinkLayer_io_outAXI4W_bits),
    .io_rxDebugState(slaveRxLinkLayer_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(slaveRxLinkLayer_io_rxDebugLastCorrectPkgID),
    .io_rx2TxCreditRBFree_valid(slaveRxLinkLayer_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(slaveRxLinkLayer_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDUsed_valid(slaveRxLinkLayer_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(slaveRxLinkLayer_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxPackageIDOut_valid(slaveRxLinkLayer_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(slaveRxLinkLayer_io_rx2TxPackageIDOut_bits)
  );
  SSlaveRxPhy slaveRxPhy ( // @[D2dSlaveRx.scala 51:28]
    .io_rxPhy2LLIO_flit_valid(slaveRxPhy_io_rxPhy2LLIO_flit_valid),
    .io_rxPhy2LLIO_flit_bits(slaveRxPhy_io_rxPhy2LLIO_flit_bits),
    .io_rxPhy2LLIO_creditRB_free(slaveRxPhy_io_rxPhy2LLIO_creditRB_free),
    .io_rxPhy2LLIO_replayPkgID(slaveRxPhy_io_rxPhy2LLIO_replayPkgID),
    .io_rxPhyIO_flit_valid(slaveRxPhy_io_rxPhyIO_flit_valid),
    .io_rxPhyIO_flit_bits(slaveRxPhy_io_rxPhyIO_flit_bits),
    .io_rxPhyIO_creditRB_free(slaveRxPhy_io_rxPhyIO_creditRB_free),
    .io_rxPhyIO_replayPkgID(slaveRxPhy_io_rxPhyIO_replayPkgID)
  );
  NegSync #(.DW(19)) SlaveRxNegSync ( // @[D2dSlaveRx.scala 54:32]
    .clock(SlaveRxNegSync_clock),
    .reset(SlaveRxNegSync_reset),
    .x(SlaveRxNegSync_x),
    .y(SlaveRxNegSync_y)
  );
  SSlaveRxAppLayer SlaveRxAppLayer ( // @[D2dSlaveRx.scala 78:31]
    .clock(SlaveRxAppLayer_clock),
    .reset(SlaveRxAppLayer_reset),
    .io_appInAXI4AW_ready(SlaveRxAppLayer_io_appInAXI4AW_ready),
    .io_appInAXI4AW_valid(SlaveRxAppLayer_io_appInAXI4AW_valid),
    .io_appInAXI4AW_bits(SlaveRxAppLayer_io_appInAXI4AW_bits),
    .io_appInAXI4AR_ready(SlaveRxAppLayer_io_appInAXI4AR_ready),
    .io_appInAXI4AR_valid(SlaveRxAppLayer_io_appInAXI4AR_valid),
    .io_appInAXI4AR_bits(SlaveRxAppLayer_io_appInAXI4AR_bits),
    .io_appInAXI4W_ready(SlaveRxAppLayer_io_appInAXI4W_ready),
    .io_appInAXI4W_valid(SlaveRxAppLayer_io_appInAXI4W_valid),
    .io_appInAXI4W_bits(SlaveRxAppLayer_io_appInAXI4W_bits),
    .io_appOutAXI4W_ready(SlaveRxAppLayer_io_appOutAXI4W_ready),
    .io_appOutAXI4W_valid(SlaveRxAppLayer_io_appOutAXI4W_valid),
    .io_appOutAXI4W_bits_data(SlaveRxAppLayer_io_appOutAXI4W_bits_data),
    .io_appOutAXI4W_bits_last(SlaveRxAppLayer_io_appOutAXI4W_bits_last),
    .io_appOutAXI4W_bits_strb(SlaveRxAppLayer_io_appOutAXI4W_bits_strb),
    .io_appOutAXI4AW_ready(SlaveRxAppLayer_io_appOutAXI4AW_ready),
    .io_appOutAXI4AW_valid(SlaveRxAppLayer_io_appOutAXI4AW_valid),
    .io_appOutAXI4AW_bits_addr(SlaveRxAppLayer_io_appOutAXI4AW_bits_addr),
    .io_appOutAXI4AW_bits_id(SlaveRxAppLayer_io_appOutAXI4AW_bits_id),
    .io_appOutAXI4AW_bits_size(SlaveRxAppLayer_io_appOutAXI4AW_bits_size),
    .io_appOutAXI4AW_bits_len(SlaveRxAppLayer_io_appOutAXI4AW_bits_len),
    .io_appOutAXI4AW_bits_burst(SlaveRxAppLayer_io_appOutAXI4AW_bits_burst),
    .io_appOutAXI4AW_bits_cache(SlaveRxAppLayer_io_appOutAXI4AW_bits_cache),
    .io_appOutAXI4AW_bits_lock(SlaveRxAppLayer_io_appOutAXI4AW_bits_lock),
    .io_appOutAXI4AW_bits_prot(SlaveRxAppLayer_io_appOutAXI4AW_bits_prot),
    .io_appOutAXI4AW_bits_qos(SlaveRxAppLayer_io_appOutAXI4AW_bits_qos),
    .io_appOutAXI4AW_bits_region(SlaveRxAppLayer_io_appOutAXI4AW_bits_region),
    .io_appOutAXI4AR_ready(SlaveRxAppLayer_io_appOutAXI4AR_ready),
    .io_appOutAXI4AR_valid(SlaveRxAppLayer_io_appOutAXI4AR_valid),
    .io_appOutAXI4AR_bits_addr(SlaveRxAppLayer_io_appOutAXI4AR_bits_addr),
    .io_appOutAXI4AR_bits_id(SlaveRxAppLayer_io_appOutAXI4AR_bits_id),
    .io_appOutAXI4AR_bits_size(SlaveRxAppLayer_io_appOutAXI4AR_bits_size),
    .io_appOutAXI4AR_bits_len(SlaveRxAppLayer_io_appOutAXI4AR_bits_len),
    .io_appOutAXI4AR_bits_burst(SlaveRxAppLayer_io_appOutAXI4AR_bits_burst),
    .io_appOutAXI4AR_bits_cache(SlaveRxAppLayer_io_appOutAXI4AR_bits_cache),
    .io_appOutAXI4AR_bits_lock(SlaveRxAppLayer_io_appOutAXI4AR_bits_lock),
    .io_appOutAXI4AR_bits_prot(SlaveRxAppLayer_io_appOutAXI4AR_bits_prot),
    .io_appOutAXI4AR_bits_qos(SlaveRxAppLayer_io_appOutAXI4AR_bits_qos),
    .io_appOutAXI4AR_bits_region(SlaveRxAppLayer_io_appOutAXI4AR_bits_region)
  );
  assign io_outAXI4W_valid = SlaveRxAppLayer_io_appOutAXI4W_valid; // @[D2dSlaveRx.scala 87:15]
  assign io_outAXI4W_bits_data = SlaveRxAppLayer_io_appOutAXI4W_bits_data; // @[D2dSlaveRx.scala 87:15]
  assign io_outAXI4W_bits_last = SlaveRxAppLayer_io_appOutAXI4W_bits_last; // @[D2dSlaveRx.scala 87:15]
  assign io_outAXI4W_bits_strb = SlaveRxAppLayer_io_appOutAXI4W_bits_strb; // @[D2dSlaveRx.scala 87:15]
  assign io_outAXI4AW_valid = SlaveRxAppLayer_io_appOutAXI4AW_valid; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_addr = SlaveRxAppLayer_io_appOutAXI4AW_bits_addr; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_id = SlaveRxAppLayer_io_appOutAXI4AW_bits_id; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_size = SlaveRxAppLayer_io_appOutAXI4AW_bits_size; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_len = SlaveRxAppLayer_io_appOutAXI4AW_bits_len; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_burst = SlaveRxAppLayer_io_appOutAXI4AW_bits_burst; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_cache = SlaveRxAppLayer_io_appOutAXI4AW_bits_cache; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_lock = SlaveRxAppLayer_io_appOutAXI4AW_bits_lock; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_prot = SlaveRxAppLayer_io_appOutAXI4AW_bits_prot; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_qos = SlaveRxAppLayer_io_appOutAXI4AW_bits_qos; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AW_bits_region = SlaveRxAppLayer_io_appOutAXI4AW_bits_region; // @[D2dSlaveRx.scala 88:16]
  assign io_outAXI4AR_valid = SlaveRxAppLayer_io_appOutAXI4AR_valid; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_addr = SlaveRxAppLayer_io_appOutAXI4AR_bits_addr; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_id = SlaveRxAppLayer_io_appOutAXI4AR_bits_id; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_size = SlaveRxAppLayer_io_appOutAXI4AR_bits_size; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_len = SlaveRxAppLayer_io_appOutAXI4AR_bits_len; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_burst = SlaveRxAppLayer_io_appOutAXI4AR_bits_burst; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_cache = SlaveRxAppLayer_io_appOutAXI4AR_bits_cache; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_lock = SlaveRxAppLayer_io_appOutAXI4AR_bits_lock; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_prot = SlaveRxAppLayer_io_appOutAXI4AR_bits_prot; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_qos = SlaveRxAppLayer_io_appOutAXI4AR_bits_qos; // @[D2dSlaveRx.scala 89:16]
  assign io_outAXI4AR_bits_region = SlaveRxAppLayer_io_appOutAXI4AR_bits_region; // @[D2dSlaveRx.scala 89:16]
  assign io_rxDebugState = slaveRxLinkLayer_io_rxDebugState; // @[D2dSlaveRx.scala 74:21]
  assign io_rxDebugLastCorrectPkgID = slaveRxLinkLayer_io_rxDebugLastCorrectPkgID; // @[D2dSlaveRx.scala 75:32]
  assign io_preAddrIn = rPreAddrIn; // @[D2dSlaveRx.scala 100:16]
  assign io_rx2TxCreditARWFree_valid = _io_rx2TxCreditARWFree_valid_T_3 != 3'h0; // @[D2dSlaveRx.scala 46:99]
  assign io_rx2TxCreditARWFree_bits = {io_rx2TxCreditARWFree_valid_hi,_io_rx2TxCreditARWFree_valid_T_2}; // @[Cat.scala 33:92]
  assign io_rx2TxPackageIDUsed_valid = slaveRxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dSlaveRx.scala 71:27]
  assign io_rx2TxPackageIDUsed_bits = slaveRxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dSlaveRx.scala 71:27]
  assign io_rx2TxCreditRBFree_valid = slaveRxLinkLayer_io_rx2TxCreditRBFree_valid; // @[D2dSlaveRx.scala 72:26]
  assign io_rx2TxCreditRBFree_bits = slaveRxLinkLayer_io_rx2TxCreditRBFree_bits; // @[D2dSlaveRx.scala 72:26]
  assign io_rx2TxPackageIDOut_valid = slaveRxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dSlaveRx.scala 73:26]
  assign io_rx2TxPackageIDOut_bits = slaveRxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dSlaveRx.scala 73:26]
  assign rstRxSync_clock = io_rx_clock; // @[D2dSlaveRx.scala 23:22]
  assign rstRxSync_reset_in = reset; // @[D2dSlaveRx.scala 24:46]
  assign asyncQW_wr_clock = io_rx_clock; // @[D2dSlaveRx.scala 28:20]
  assign asyncQW_wr_reset = rstRxSync_reset_out; // @[D2dSlaveRx.scala 29:20]
  assign asyncQW_wr_valid = slaveRxLinkLayer_io_outAXI4W_valid; // @[D2dSlaveRx.scala 66:16]
  assign asyncQW_wr_bits = slaveRxLinkLayer_io_outAXI4W_bits; // @[D2dSlaveRx.scala 66:16]
  assign asyncQW_rd_clock = clock; // @[D2dSlaveRx.scala 30:20]
  assign asyncQW_rd_reset = reset; // @[D2dSlaveRx.scala 31:41]
  assign asyncQW_rd_ready = SlaveRxAppLayer_io_appInAXI4W_ready; // @[D2dSlaveRx.scala 81:14]
  assign asyncQAR_wr_clock = io_rx_clock; // @[D2dSlaveRx.scala 34:21]
  assign asyncQAR_wr_reset = rstRxSync_reset_out; // @[D2dSlaveRx.scala 35:21]
  assign asyncQAR_wr_valid = slaveRxLinkLayer_io_outAXI4AR_valid; // @[D2dSlaveRx.scala 67:17]
  assign asyncQAR_wr_bits = slaveRxLinkLayer_io_outAXI4AR_bits; // @[D2dSlaveRx.scala 67:17]
  assign asyncQAR_rd_clock = clock; // @[D2dSlaveRx.scala 36:21]
  assign asyncQAR_rd_reset = reset; // @[D2dSlaveRx.scala 37:42]
  assign asyncQAR_rd_ready = SlaveRxAppLayer_io_appInAXI4AR_ready; // @[D2dSlaveRx.scala 83:15]
  assign asyncQAW_wr_clock = io_rx_clock; // @[D2dSlaveRx.scala 40:21]
  assign asyncQAW_wr_reset = rstRxSync_reset_out; // @[D2dSlaveRx.scala 41:21]
  assign asyncQAW_wr_valid = slaveRxLinkLayer_io_outAXI4AW_valid; // @[D2dSlaveRx.scala 68:17]
  assign asyncQAW_wr_bits = slaveRxLinkLayer_io_outAXI4AW_bits; // @[D2dSlaveRx.scala 68:17]
  assign asyncQAW_rd_clock = clock; // @[D2dSlaveRx.scala 42:21]
  assign asyncQAW_rd_reset = reset; // @[D2dSlaveRx.scala 43:42]
  assign asyncQAW_rd_ready = SlaveRxAppLayer_io_appInAXI4AW_ready; // @[D2dSlaveRx.scala 85:15]
  assign slaveRxLinkLayer_clock = io_rx_clock;
  assign slaveRxLinkLayer_reset = rstRxSync_reset_out;
  assign slaveRxLinkLayer_io_rxPhy2LLIO_flit_valid = slaveRxPhy_io_rxPhy2LLIO_flit_valid; // @[D2dSlaveRx.scala 64:36]
  assign slaveRxLinkLayer_io_rxPhy2LLIO_flit_bits = slaveRxPhy_io_rxPhy2LLIO_flit_bits; // @[D2dSlaveRx.scala 64:36]
  assign slaveRxLinkLayer_io_rxPhy2LLIO_creditRB_free = slaveRxPhy_io_rxPhy2LLIO_creditRB_free; // @[D2dSlaveRx.scala 64:36]
  assign slaveRxLinkLayer_io_rxPhy2LLIO_replayPkgID = slaveRxPhy_io_rxPhy2LLIO_replayPkgID; // @[D2dSlaveRx.scala 64:36]
  assign slaveRxPhy_io_rxPhyIO_flit_valid = SlaveRxNegSync_y[18]; // @[D2dSlaveRx.scala 58:60]
  assign slaveRxPhy_io_rxPhyIO_flit_bits = SlaveRxNegSync_y[17:2]; // @[D2dSlaveRx.scala 59:60]
  assign slaveRxPhy_io_rxPhyIO_creditRB_free = SlaveRxNegSync_y[1]; // @[D2dSlaveRx.scala 60:63]
  assign slaveRxPhy_io_rxPhyIO_replayPkgID = SlaveRxNegSync_y[0]; // @[D2dSlaveRx.scala 61:62]
  assign SlaveRxNegSync_clock = io_rx_clock; // @[D2dSlaveRx.scala 55:29]
  assign SlaveRxNegSync_reset = rstRxSync_reset_out; // @[D2dSlaveRx.scala 56:29]
  assign SlaveRxNegSync_x = {SlaveRxNegSync_io_x_hi,SlaveRxNegSync_io_x_lo}; // @[Cat.scala 33:92]
  assign SlaveRxAppLayer_clock = clock;
  assign SlaveRxAppLayer_reset = reset;
  assign SlaveRxAppLayer_io_appInAXI4AW_valid = asyncQAW_rd_valid; // @[D2dSlaveRx.scala 85:15]
  assign SlaveRxAppLayer_io_appInAXI4AW_bits = asyncQAW_rd_bits; // @[D2dSlaveRx.scala 85:15]
  assign SlaveRxAppLayer_io_appInAXI4AR_valid = asyncQAR_rd_valid; // @[D2dSlaveRx.scala 83:15]
  assign SlaveRxAppLayer_io_appInAXI4AR_bits = asyncQAR_rd_bits; // @[D2dSlaveRx.scala 83:15]
  assign SlaveRxAppLayer_io_appInAXI4W_valid = asyncQW_rd_valid; // @[D2dSlaveRx.scala 81:14]
  assign SlaveRxAppLayer_io_appInAXI4W_bits = asyncQW_rd_bits; // @[D2dSlaveRx.scala 81:14]
  assign SlaveRxAppLayer_io_appOutAXI4W_ready = io_outAXI4W_ready; // @[D2dSlaveRx.scala 87:15]
  assign SlaveRxAppLayer_io_appOutAXI4AW_ready = io_outAXI4AW_ready; // @[D2dSlaveRx.scala 88:16]
  assign SlaveRxAppLayer_io_appOutAXI4AR_ready = io_outAXI4AR_ready; // @[D2dSlaveRx.scala 89:16]
  always @(posedge clock) begin
    if (reset) begin // @[D2dSlaveRx.scala 91:27]
      rPreAddrIn <= 11'h0; // @[D2dSlaveRx.scala 91:27]
    end else if (_T) begin // @[D2dSlaveRx.scala 93:3]
      rPreAddrIn <= SlaveRxAppLayer_io_appInAXI4AR_bits[60:50]; // @[D2dSlaveRx.scala 94:16]
    end else if (_T_1) begin // @[D2dSlaveRx.scala 95:50]
      rPreAddrIn <= SlaveRxAppLayer_io_appInAXI4AW_bits[60:50]; // @[D2dSlaveRx.scala 96:16]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rPreAddrIn = _RAND_0[10:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifoMemory_5(
  input        wr_clock,
  input        wr_en,
  input  [2:0] wr_addr,
  input  [3:0] wr_data,
  input        rd_clock,
  input        rd_en,
  input  [2:0] rd_addr,
  output [3:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_4; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_5; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_6; // @[AsyncFifo.scala 43:18]
  reg [3:0] mem_7; // @[AsyncFifo.scala 43:18]
  reg [3:0] rd_data_r; // @[Reg.scala 19:16]
  wire [3:0] _GEN_17 = 3'h1 == rd_addr ? mem_1 : mem_0; // @[Reg.scala 20:{22,22}]
  wire [3:0] _GEN_18 = 3'h2 == rd_addr ? mem_2 : _GEN_17; // @[Reg.scala 20:{22,22}]
  wire [3:0] _GEN_19 = 3'h3 == rd_addr ? mem_3 : _GEN_18; // @[Reg.scala 20:{22,22}]
  wire [3:0] _GEN_20 = 3'h4 == rd_addr ? mem_4 : _GEN_19; // @[Reg.scala 20:{22,22}]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h4 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_4 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h5 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_5 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h6 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_6 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h7 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_7 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (3'h7 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_7; // @[Reg.scala 20:22]
      end else if (3'h6 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_6; // @[Reg.scala 20:22]
      end else if (3'h5 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_5; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= _GEN_20;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  mem_0 = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  mem_1 = _RAND_1[3:0];
  _RAND_2 = {1{`RANDOM}};
  mem_2 = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  mem_3 = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  mem_4 = _RAND_4[3:0];
  _RAND_5 = {1{`RANDOM}};
  mem_5 = _RAND_5[3:0];
  _RAND_6 = {1{`RANDOM}};
  mem_6 = _RAND_6[3:0];
  _RAND_7 = {1{`RANDOM}};
  mem_7 = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  rd_data_r = _RAND_8[3:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_5(
  input        wr_clock,
  input        wr_reset,
  input  [3:0] wr_data,
  input        wr_push,
  output       wr_full,
  input        rd_clock,
  input        rd_reset,
  output [3:0] rd_data,
  input        rd_pop,
  output       rd_empty,
  output       rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [3:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [3:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [3:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [3:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [3:0] _GEN_4 = {{3'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [3:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [3:0] _GEN_5 = {{1'd0}, wrAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [3:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[3:2]; // @[AsyncFifo.scala 101:27]
  wire [3:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[1:0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [3:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [3:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [3:0] _GEN_6 = {{3'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [3:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [3:0] _GEN_7 = {{1'd0}, rdAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_5 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[2:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[2:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 4'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 4'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 4'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 4'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[3:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[3:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[3:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[3:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 4'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 4'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 4'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 4'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 4'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 4'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_5(
  input        wr_clock,
  input        wr_reset,
  input        wr_valid,
  input  [3:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
  input        rd_ready,
  output       rd_valid,
  output [3:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [3:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [3:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [3:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_5 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  outReg = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifoMemory_6(
  input        wr_clock,
  input        wr_en,
  input  [2:0] wr_addr,
  input  [2:0] wr_data,
  input        rd_clock,
  input        rd_en,
  input  [2:0] rd_addr,
  output [2:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
`endif // RANDOMIZE_REG_INIT
  reg [2:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_4; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_5; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_6; // @[AsyncFifo.scala 43:18]
  reg [2:0] mem_7; // @[AsyncFifo.scala 43:18]
  reg [2:0] rd_data_r; // @[Reg.scala 19:16]
  wire [2:0] _GEN_17 = 3'h1 == rd_addr ? mem_1 : mem_0; // @[Reg.scala 20:{22,22}]
  wire [2:0] _GEN_18 = 3'h2 == rd_addr ? mem_2 : _GEN_17; // @[Reg.scala 20:{22,22}]
  wire [2:0] _GEN_19 = 3'h3 == rd_addr ? mem_3 : _GEN_18; // @[Reg.scala 20:{22,22}]
  wire [2:0] _GEN_20 = 3'h4 == rd_addr ? mem_4 : _GEN_19; // @[Reg.scala 20:{22,22}]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h4 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_4 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h5 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_5 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h6 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_6 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h7 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_7 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (3'h7 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_7; // @[Reg.scala 20:22]
      end else if (3'h6 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_6; // @[Reg.scala 20:22]
      end else if (3'h5 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_5; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= _GEN_20;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  mem_0 = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  mem_1 = _RAND_1[2:0];
  _RAND_2 = {1{`RANDOM}};
  mem_2 = _RAND_2[2:0];
  _RAND_3 = {1{`RANDOM}};
  mem_3 = _RAND_3[2:0];
  _RAND_4 = {1{`RANDOM}};
  mem_4 = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  mem_5 = _RAND_5[2:0];
  _RAND_6 = {1{`RANDOM}};
  mem_6 = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  mem_7 = _RAND_7[2:0];
  _RAND_8 = {1{`RANDOM}};
  rd_data_r = _RAND_8[2:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_6(
  input        wr_clock,
  input        wr_reset,
  input  [2:0] wr_data,
  input        wr_push,
  output       wr_full,
  input        rd_clock,
  input        rd_reset,
  output [2:0] rd_data,
  input        rd_pop,
  output       rd_empty,
  output       rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [3:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [3:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [3:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [3:0] _GEN_4 = {{3'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [3:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [3:0] _GEN_5 = {{1'd0}, wrAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [3:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[3:2]; // @[AsyncFifo.scala 101:27]
  wire [3:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[1:0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [3:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [3:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [3:0] _GEN_6 = {{3'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [3:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [3:0] _GEN_7 = {{1'd0}, rdAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_6 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[2:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[2:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 4'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 4'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 4'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 4'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[3:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[3:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[3:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[3:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 4'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 4'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 4'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 4'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 4'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 4'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_6(
  input        wr_clock,
  input        wr_reset,
  input        wr_valid,
  input  [2:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
  input        rd_ready,
  output       rd_valid,
  output [2:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [2:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [2:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [2:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_6 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | _fifo_rd_pop_T_4); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (_fifo_rd_pop_T_4) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  outReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifoMemory_7(
  input        wr_clock,
  input        wr_en,
  input  [2:0] wr_addr,
  input  [1:0] wr_data,
  input        rd_clock,
  input        rd_en,
  input  [2:0] rd_addr,
  output [1:0] rd_data
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
`endif // RANDOMIZE_REG_INIT
  reg [1:0] mem_0; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_1; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_2; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_3; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_4; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_5; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_6; // @[AsyncFifo.scala 43:18]
  reg [1:0] mem_7; // @[AsyncFifo.scala 43:18]
  reg [1:0] rd_data_r; // @[Reg.scala 19:16]
  wire [1:0] _GEN_17 = 3'h1 == rd_addr ? mem_1 : mem_0; // @[Reg.scala 20:{22,22}]
  wire [1:0] _GEN_18 = 3'h2 == rd_addr ? mem_2 : _GEN_17; // @[Reg.scala 20:{22,22}]
  wire [1:0] _GEN_19 = 3'h3 == rd_addr ? mem_3 : _GEN_18; // @[Reg.scala 20:{22,22}]
  wire [1:0] _GEN_20 = 3'h4 == rd_addr ? mem_4 : _GEN_19; // @[Reg.scala 20:{22,22}]
  assign rd_data = rd_data_r; // @[AsyncFifo.scala 50:13]
  always @(posedge wr_clock) begin
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h0 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_0 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h1 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_1 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h2 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_2 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h3 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_3 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h4 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_4 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h5 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_5 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h6 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_6 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
    if (wr_en) begin // @[AsyncFifo.scala 44:17]
      if (3'h7 == wr_addr) begin // @[AsyncFifo.scala 45:20]
        mem_7 <= wr_data; // @[AsyncFifo.scala 45:20]
      end
    end
  end
  always @(posedge rd_clock) begin
    if (rd_en) begin // @[Reg.scala 20:18]
      if (3'h7 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_7; // @[Reg.scala 20:22]
      end else if (3'h6 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_6; // @[Reg.scala 20:22]
      end else if (3'h5 == rd_addr) begin // @[Reg.scala 20:22]
        rd_data_r <= mem_5; // @[Reg.scala 20:22]
      end else begin
        rd_data_r <= _GEN_20;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  mem_0 = _RAND_0[1:0];
  _RAND_1 = {1{`RANDOM}};
  mem_1 = _RAND_1[1:0];
  _RAND_2 = {1{`RANDOM}};
  mem_2 = _RAND_2[1:0];
  _RAND_3 = {1{`RANDOM}};
  mem_3 = _RAND_3[1:0];
  _RAND_4 = {1{`RANDOM}};
  mem_4 = _RAND_4[1:0];
  _RAND_5 = {1{`RANDOM}};
  mem_5 = _RAND_5[1:0];
  _RAND_6 = {1{`RANDOM}};
  mem_6 = _RAND_6[1:0];
  _RAND_7 = {1{`RANDOM}};
  mem_7 = _RAND_7[1:0];
  _RAND_8 = {1{`RANDOM}};
  rd_data_r = _RAND_8[1:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncFifo_7(
  input        wr_clock,
  input        wr_reset,
  input  [1:0] wr_data,
  input        wr_push,
  output       wr_full,
  input        rd_clock,
  input        rd_reset,
  output [1:0] rd_data,
  input        rd_pop,
  output       rd_empty,
  output       rd_valid
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
`endif // RANDOMIZE_REG_INIT
  wire  mem_wr_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_wr_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_wr_addr; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_wr_data; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_clock; // @[AsyncFifo.scala 79:19]
  wire  mem_rd_en; // @[AsyncFifo.scala 79:19]
  wire [2:0] mem_rd_addr; // @[AsyncFifo.scala 79:19]
  wire [1:0] mem_rd_data; // @[AsyncFifo.scala 79:19]
  reg [3:0] rdPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] rdAddrGray; // @[AsyncFifo.scala 136:29]
  reg [3:0] rdPtrSync; // @[Reg.scala 35:20]
  wire  wrNotFull = ~wr_full; // @[AsyncFifo.scala 90:21]
  wire  wrEn = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  reg [3:0] wrAddrBin; // @[AsyncFifo.scala 93:28]
  wire [3:0] _GEN_4 = {{3'd0}, wrEn}; // @[AsyncFifo.scala 94:32]
  wire [3:0] wrAddrBinNext = wrAddrBin + _GEN_4; // @[AsyncFifo.scala 94:32]
  wire [3:0] _GEN_5 = {{1'd0}, wrAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] wrAddrGrayNext = _GEN_5 ^ wrAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg [3:0] wrAddrGray; // @[AsyncFifo.scala 98:29]
  wire [1:0] _wrFull_T_1 = ~rdPtrSync[3:2]; // @[AsyncFifo.scala 101:27]
  wire [3:0] _wrFull_T_3 = {_wrFull_T_1,rdPtrSync[1:0]}; // @[AsyncFifo.scala 101:64]
  reg  wrFull; // @[AsyncFifo.scala 100:25]
  reg [3:0] wrPtrSync_r; // @[Reg.scala 35:20]
  reg [3:0] wrPtrSync; // @[Reg.scala 35:20]
  wire  rdNotEmpty = ~rd_empty; // @[AsyncFifo.scala 128:22]
  wire  rdEn = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  reg [3:0] rdAddrBin; // @[AsyncFifo.scala 131:28]
  wire [3:0] _GEN_6 = {{3'd0}, rdEn}; // @[AsyncFifo.scala 132:32]
  wire [3:0] rdAddrBinNext = rdAddrBin + _GEN_6; // @[AsyncFifo.scala 132:32]
  wire [3:0] _GEN_7 = {{1'd0}, rdAddrBinNext[3:1]}; // @[AsyncFifo.scala 85:49]
  wire [3:0] rdAddrGrayNext = _GEN_7 ^ rdAddrBinNext; // @[AsyncFifo.scala 85:49]
  reg  rdEmpty; // @[AsyncFifo.scala 138:26]
  reg  rdValid; // @[AsyncFifo.scala 148:30]
  SAsyncFifoMemory_7 mem ( // @[AsyncFifo.scala 79:19]
    .wr_clock(mem_wr_clock),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),
    .rd_clock(mem_rd_clock),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
  );
  assign wr_full = wrFull; // @[AsyncFifo.scala 105:13]
  assign rd_data = mem_rd_data; // @[AsyncFifo.scala 83:{34,34}]
  assign rd_empty = rdEmpty; // @[AsyncFifo.scala 140:14]
  assign rd_valid = rdValid; // @[AsyncFifo.scala 149:11]
  assign mem_wr_clock = wr_clock; // @[AsyncFifo.scala 80:16]
  assign mem_wr_en = wr_push & wrNotFull; // @[AsyncFifo.scala 91:24]
  assign mem_wr_addr = wrAddrBin[2:0]; // @[AsyncFifo.scala 109:29]
  assign mem_wr_data = wr_data; // @[AsyncFifo.scala 82:15]
  assign mem_rd_clock = rd_clock; // @[AsyncFifo.scala 81:16]
  assign mem_rd_en = rd_pop & rdNotEmpty; // @[AsyncFifo.scala 129:23]
  assign mem_rd_addr = rdAddrBin[2:0]; // @[AsyncFifo.scala 144:29]
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync_r <= rdAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 85:49]
      rdAddrGray <= 4'h0;
    end else begin
      rdAddrGray <= _GEN_7 ^ rdAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[Reg.scala 36:18]
      rdPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      rdPtrSync <= rdPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 94:32]
      wrAddrBin <= 4'h0;
    end else begin
      wrAddrBin <= wrAddrBin + _GEN_4;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 85:49]
      wrAddrGray <= 4'h0;
    end else begin
      wrAddrGray <= _GEN_5 ^ wrAddrBinNext;
    end
  end
  always @(posedge wr_clock or posedge wr_reset) begin
    if (wr_reset) begin // @[AsyncFifo.scala 101:22]
      wrFull <= 1'h0;
    end else begin
      wrFull <= wrAddrGrayNext == _wrFull_T_3;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync_r <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync_r <= wrAddrGray; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[Reg.scala 36:18]
      wrPtrSync <= 4'h0; // @[Reg.scala 36:22]
    end else begin
      wrPtrSync <= wrPtrSync_r; // @[Reg.scala 35:20]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 132:32]
      rdAddrBin <= 4'h0;
    end else begin
      rdAddrBin <= rdAddrBin + _GEN_6;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 138:42]
      rdEmpty <= 1'h1;
    end else begin
      rdEmpty <= rdAddrGrayNext == wrPtrSync;
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 129:23]
      rdValid <= 1'h0;
    end else begin
      rdValid <= rd_pop & rdNotEmpty;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rdPtrSync_r = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  rdAddrGray = _RAND_1[3:0];
  _RAND_2 = {1{`RANDOM}};
  rdPtrSync = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  wrAddrBin = _RAND_3[3:0];
  _RAND_4 = {1{`RANDOM}};
  wrAddrGray = _RAND_4[3:0];
  _RAND_5 = {1{`RANDOM}};
  wrFull = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  wrPtrSync_r = _RAND_6[3:0];
  _RAND_7 = {1{`RANDOM}};
  wrPtrSync = _RAND_7[3:0];
  _RAND_8 = {1{`RANDOM}};
  rdAddrBin = _RAND_8[3:0];
  _RAND_9 = {1{`RANDOM}};
  rdEmpty = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  rdValid = _RAND_10[0:0];
`endif // RANDOMIZE_REG_INIT
  if (wr_reset) begin
    rdPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    rdAddrGray = 4'h0;
  end
  if (wr_reset) begin
    rdPtrSync = 4'h0;
  end
  if (wr_reset) begin
    wrAddrBin = 4'h0;
  end
  if (wr_reset) begin
    wrAddrGray = 4'h0;
  end
  if (wr_reset) begin
    wrFull = 1'h0;
  end
  if (rd_reset) begin
    wrPtrSync_r = 4'h0;
  end
  if (rd_reset) begin
    wrPtrSync = 4'h0;
  end
  if (rd_reset) begin
    rdAddrBin = 4'h0;
  end
  if (rd_reset) begin
    rdEmpty = 1'h1;
  end
  if (rd_reset) begin
    rdValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SAsyncQueue_7(
  input        wr_clock,
  input        wr_reset,
  input        wr_valid,
  input  [1:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
  output       rd_valid,
  output [1:0] rd_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  fifo_wr_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_reset; // @[AsyncFifo.scala 169:20]
  wire [1:0] fifo_wr_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_push; // @[AsyncFifo.scala 169:20]
  wire  fifo_wr_full; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_clock; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_reset; // @[AsyncFifo.scala 169:20]
  wire [1:0] fifo_rd_data; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_pop; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_empty; // @[AsyncFifo.scala 169:20]
  wire  fifo_rd_valid; // @[AsyncFifo.scala 169:20]
  reg [1:0] outReg; // @[AsyncFifo.scala 192:21]
  reg  outValid; // @[AsyncFifo.scala 193:27]
  wire  fifoRdValid = fifo_rd_valid; // @[AsyncFifo.scala 186:27 188:41]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  SAsyncFifo_7 fifo ( // @[AsyncFifo.scala 169:20]
    .wr_clock(fifo_wr_clock),
    .wr_reset(fifo_wr_reset),
    .wr_data(fifo_wr_data),
    .wr_push(fifo_wr_push),
    .wr_full(fifo_wr_full),
    .rd_clock(fifo_rd_clock),
    .rd_reset(fifo_rd_reset),
    .rd_data(fifo_rd_data),
    .rd_pop(fifo_rd_pop),
    .rd_empty(fifo_rd_empty),
    .rd_valid(fifo_rd_valid)
  );
  assign rd_valid = fifoRdValid | outValid; // @[AsyncFifo.scala 208:29]
  assign rd_bits = outValid ? outReg : fifo_rd_data; // @[AsyncFifo.scala 207:19]
  assign fifo_wr_clock = wr_clock; // @[AsyncFifo.scala 175:17]
  assign fifo_wr_reset = wr_reset; // @[AsyncFifo.scala 177:17]
  assign fifo_wr_data = wr_bits; // @[AsyncFifo.scala 180:16]
  assign fifo_wr_push = wr_valid & ~fifo_wr_full; // @[AsyncFifo.scala 181:28]
  assign fifo_rd_clock = rd_clock; // @[AsyncFifo.scala 176:17]
  assign fifo_rd_reset = rd_reset; // @[AsyncFifo.scala 178:17]
  assign fifo_rd_pop = ~fifo_rd_empty & (~outValid & ~fifoRdValid | rd_valid); // @[AsyncFifo.scala 195:35]
  always @(posedge rd_clock) begin
    if (fifoRdValid) begin // @[AsyncFifo.scala 203:23]
      outReg <= fifo_rd_data; // @[AsyncFifo.scala 204:14]
    end
  end
  always @(posedge rd_clock or posedge rd_reset) begin
    if (rd_reset) begin // @[AsyncFifo.scala 197:19]
      outValid <= 1'h0; // @[AsyncFifo.scala 198:16]
    end else if (rd_valid) begin
      outValid <= 1'h0;
    end else begin
      outValid <= _GEN_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  outReg = _RAND_0[1:0];
  _RAND_1 = {1{`RANDOM}};
  outValid = _RAND_1[0:0];
`endif // RANDOMIZE_REG_INIT
  if (rd_reset) begin
    outValid = 1'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module SD2dSlaveCtrlRegIf(
  input         clock,
  input         reset,
  output        io_ctrlBusPorts_readAddr_ready,
  input         io_ctrlBusPorts_readAddr_valid,
  input  [7:0]  io_ctrlBusPorts_readAddr_bits_addr,
  input         io_ctrlBusPorts_readData_ready,
  output        io_ctrlBusPorts_readData_valid,
  output [31:0] io_ctrlBusPorts_readData_bits_data,
  output        io_ctrlBusPorts_writeAddr_ready,
  input         io_ctrlBusPorts_writeAddr_valid,
  input  [7:0]  io_ctrlBusPorts_writeAddr_bits_addr,
  output        io_ctrlBusPorts_writeData_ready,
  input         io_ctrlBusPorts_writeData_valid,
  input  [31:0] io_ctrlBusPorts_writeData_bits_data,
  input         io_ctrlBusPorts_writeResp_ready,
  output        io_ctrlBusPorts_writeResp_valid,
  output [11:0] io_inSlaveReplayLatency,
  input  [31:0] io_txDebugReplayState,
  input  [31:0] io_txDebugReplayQueue,
  input  [31:0] io_txDebugReplayCnt,
  input  [2:0]  io_txDebugState,
  input  [2:0]  io_rxDebugState,
  input  [3:0]  io_rxDebugLastCorrectPkgID,
  input  [10:0] io_preAddrIn
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
`endif // RANDOMIZE_REG_INIT
  reg  ctrl_reg_WrEn; // @[D2dSlaveRegIf.scala 19:30]
  reg [31:0] ctrl_reg_Wrdata; // @[D2dSlaveRegIf.scala 20:32]
  reg  ctrl_aw_en; // @[D2dSlaveRegIf.scala 21:27]
  reg [7:0] ctrl_awaddr; // @[D2dSlaveRegIf.scala 23:29]
  reg  ctrl_awready; // @[D2dSlaveRegIf.scala 24:29]
  reg  ctrl_wready; // @[D2dSlaveRegIf.scala 25:29]
  reg  ctrl_bvalid; // @[D2dSlaveRegIf.scala 27:29]
  reg [7:0] ctrl_araddr; // @[D2dSlaveRegIf.scala 28:29]
  reg  ctrl_arready; // @[D2dSlaveRegIf.scala 29:29]
  reg [31:0] ctrl_rdata; // @[D2dSlaveRegIf.scala 30:29]
  reg  ctrl_rvalid; // @[D2dSlaveRegIf.scala 32:28]
  wire  _T_3 = ~ctrl_awready & io_ctrlBusPorts_writeAddr_valid & io_ctrlBusPorts_writeData_valid & ctrl_aw_en; // @[D2dSlaveRegIf.scala 47:92]
  wire  _T_4 = io_ctrlBusPorts_writeResp_ready & ctrl_bvalid; // @[D2dSlaveRegIf.scala 51:46]
  wire  _GEN_1 = io_ctrlBusPorts_writeResp_ready & ctrl_bvalid | ctrl_aw_en; // @[D2dSlaveRegIf.scala 51:61 53:16 21:27]
  wire  _GEN_3 = ~ctrl_awready & io_ctrlBusPorts_writeAddr_valid & io_ctrlBusPorts_writeData_valid & ctrl_aw_en ? 1'h0
     : _GEN_1; // @[D2dSlaveRegIf.scala 47:106 50:16]
  wire  _T_12 = ~ctrl_wready & io_ctrlBusPorts_writeData_valid & io_ctrlBusPorts_writeAddr_valid & ctrl_aw_en; // @[D2dSlaveRegIf.scala 63:91]
  wire  _T_15 = ctrl_wready & io_ctrlBusPorts_writeData_valid & ctrl_awready & io_ctrlBusPorts_writeAddr_valid; // @[D2dSlaveRegIf.scala 69:71]
  wire  _GEN_7 = _T_4 ? 1'h0 : ctrl_bvalid; // @[D2dSlaveRegIf.scala 81:61 82:17 27:29]
  wire  _GEN_8 = ctrl_awready & io_ctrlBusPorts_writeAddr_valid & ctrl_wready & io_ctrlBusPorts_writeData_valid | _GEN_7
    ; // @[D2dSlaveRegIf.scala 77:106 78:17]
  wire  _T_21 = ~ctrl_arready & io_ctrlBusPorts_readAddr_valid; // @[D2dSlaveRegIf.scala 91:22]
  wire  _T_24 = ctrl_arready & io_ctrlBusPorts_readAddr_valid & ~ctrl_rvalid; // @[D2dSlaveRegIf.scala 100:55]
  wire  _GEN_12 = ctrl_rvalid & io_ctrlBusPorts_readData_ready ? 1'h0 : ctrl_rvalid; // @[D2dSlaveRegIf.scala 105:60 107:17 32:28]
  wire  _GEN_13 = ctrl_arready & io_ctrlBusPorts_readAddr_valid & ~ctrl_rvalid | _GEN_12; // @[D2dSlaveRegIf.scala 100:71 102:17]
  reg [10:0] rPreAddrIn; // @[D2dSlaveRegIf.scala 114:27]
  wire [31:0] _ctrl_rdata_T = {21'h0,rPreAddrIn}; // @[Cat.scala 33:92]
  wire [31:0] _GEN_15 = _T_24 & ctrl_araddr == 8'h0 ? _ctrl_rdata_T : ctrl_rdata; // @[D2dSlaveRegIf.scala 117:50 118:16 30:29]
  reg [11:0] rSlaveReplayLatency; // @[D2dSlaveRegIf.scala 122:36]
  wire [31:0] _ctrl_rdata_T_1 = {20'h0,rSlaveReplayLatency}; // @[Cat.scala 33:92]
  wire [31:0] _GEN_17 = _T_24 & ctrl_araddr == 8'h4 ? _ctrl_rdata_T_1 : _GEN_15; // @[D2dSlaveRegIf.scala 128:50 129:16]
  reg [31:0] rTxDebugReplayState; // @[D2dSlaveRegIf.scala 133:36]
  reg [31:0] rTxDebugReplayQueue; // @[D2dSlaveRegIf.scala 134:36]
  reg [31:0] rTxDebugReplayCnt; // @[D2dSlaveRegIf.scala 135:34]
  wire [31:0] _GEN_18 = _T_24 & ctrl_araddr == 8'h8 ? rTxDebugReplayState : _GEN_17; // @[D2dSlaveRegIf.scala 148:50 149:16]
  wire [31:0] _GEN_19 = _T_24 & ctrl_araddr == 8'hc ? rTxDebugReplayQueue : _GEN_18; // @[D2dSlaveRegIf.scala 160:50 161:16]
  wire [5:0] _rDebugState_T = {io_txDebugState,io_rxDebugState}; // @[Cat.scala 33:92]
  reg [5:0] rDebugState; // @[D2dSlaveRegIf.scala 168:28]
  wire [31:0] _ctrl_rdata_T_2 = {26'h0,rDebugState}; // @[Cat.scala 33:92]
  reg [3:0] rRxDebugLastCorrectPkgID; // @[D2dSlaveRegIf.scala 175:41]
  wire [31:0] _ctrl_rdata_T_3 = {28'h0,rRxDebugLastCorrectPkgID}; // @[Cat.scala 33:92]
  assign io_ctrlBusPorts_readAddr_ready = ctrl_arready; // @[D2dSlaveRegIf.scala 38:38]
  assign io_ctrlBusPorts_readData_valid = ctrl_rvalid; // @[D2dSlaveRegIf.scala 41:38]
  assign io_ctrlBusPorts_readData_bits_data = ctrl_rdata; // @[D2dSlaveRegIf.scala 39:38]
  assign io_ctrlBusPorts_writeAddr_ready = ctrl_awready; // @[D2dSlaveRegIf.scala 34:38]
  assign io_ctrlBusPorts_writeData_ready = ctrl_wready; // @[D2dSlaveRegIf.scala 35:38]
  assign io_ctrlBusPorts_writeResp_valid = ctrl_bvalid; // @[D2dSlaveRegIf.scala 37:38]
  assign io_inSlaveReplayLatency = rSlaveReplayLatency; // @[D2dSlaveRegIf.scala 131:27]
  always @(posedge clock) begin
    if (reset) begin // @[D2dSlaveRegIf.scala 19:30]
      ctrl_reg_WrEn <= 1'h0; // @[D2dSlaveRegIf.scala 19:30]
    end else begin
      ctrl_reg_WrEn <= _T_15;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 20:32]
      ctrl_reg_Wrdata <= 32'h0; // @[D2dSlaveRegIf.scala 20:32]
    end else begin
      ctrl_reg_Wrdata <= io_ctrlBusPorts_writeData_bits_data; // @[D2dSlaveRegIf.scala 75:19]
    end
    ctrl_aw_en <= reset | _GEN_3; // @[D2dSlaveRegIf.scala 21:{27,27}]
    if (reset) begin // @[D2dSlaveRegIf.scala 23:29]
      ctrl_awaddr <= 8'h0; // @[D2dSlaveRegIf.scala 23:29]
    end else if (_T_3) begin // @[D2dSlaveRegIf.scala 58:107]
      ctrl_awaddr <= io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dSlaveRegIf.scala 60:17]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 24:29]
      ctrl_awready <= 1'h0; // @[D2dSlaveRegIf.scala 24:29]
    end else begin
      ctrl_awready <= _T_3;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 25:29]
      ctrl_wready <= 1'h0; // @[D2dSlaveRegIf.scala 25:29]
    end else begin
      ctrl_wready <= _T_12;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 27:29]
      ctrl_bvalid <= 1'h0; // @[D2dSlaveRegIf.scala 27:29]
    end else begin
      ctrl_bvalid <= _GEN_8;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 28:29]
      ctrl_araddr <= 8'h0; // @[D2dSlaveRegIf.scala 28:29]
    end else if (~ctrl_arready & io_ctrlBusPorts_readAddr_valid) begin // @[D2dSlaveRegIf.scala 91:56]
      ctrl_araddr <= io_ctrlBusPorts_readAddr_bits_addr; // @[D2dSlaveRegIf.scala 95:17]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 29:29]
      ctrl_arready <= 1'h0; // @[D2dSlaveRegIf.scala 29:29]
    end else begin
      ctrl_arready <= _T_21;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 30:29]
      ctrl_rdata <= 32'h0; // @[D2dSlaveRegIf.scala 30:29]
    end else if (_T_24 & ctrl_araddr == 8'h18) begin // @[D2dSlaveRegIf.scala 177:50]
      ctrl_rdata <= _ctrl_rdata_T_3; // @[D2dSlaveRegIf.scala 178:16]
    end else if (_T_24 & ctrl_araddr == 8'h14) begin // @[D2dSlaveRegIf.scala 171:50]
      ctrl_rdata <= _ctrl_rdata_T_2; // @[D2dSlaveRegIf.scala 172:16]
    end else if (_T_24 & ctrl_araddr == 8'h10) begin // @[D2dSlaveRegIf.scala 164:50]
      ctrl_rdata <= rTxDebugReplayCnt; // @[D2dSlaveRegIf.scala 165:16]
    end else begin
      ctrl_rdata <= _GEN_19;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 32:28]
      ctrl_rvalid <= 1'h0; // @[D2dSlaveRegIf.scala 32:28]
    end else begin
      ctrl_rvalid <= _GEN_13;
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 114:27]
      rPreAddrIn <= 11'h0; // @[D2dSlaveRegIf.scala 114:27]
    end else begin
      rPreAddrIn <= io_preAddrIn; // @[D2dSlaveRegIf.scala 120:14]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 122:36]
      rSlaveReplayLatency <= 12'h400; // @[D2dSlaveRegIf.scala 122:36]
    end else if (ctrl_reg_WrEn & ctrl_awaddr == 8'h4) begin // @[D2dSlaveRegIf.scala 125:50]
      rSlaveReplayLatency <= ctrl_reg_Wrdata[11:0]; // @[D2dSlaveRegIf.scala 126:25]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 133:36]
      rTxDebugReplayState <= 32'h0; // @[D2dSlaveRegIf.scala 133:36]
    end else begin
      rTxDebugReplayState <= io_txDebugReplayState; // @[D2dSlaveRegIf.scala 133:36]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 134:36]
      rTxDebugReplayQueue <= 32'h0; // @[D2dSlaveRegIf.scala 134:36]
    end else begin
      rTxDebugReplayQueue <= io_txDebugReplayQueue; // @[D2dSlaveRegIf.scala 134:36]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 135:34]
      rTxDebugReplayCnt <= 32'h0; // @[D2dSlaveRegIf.scala 135:34]
    end else begin
      rTxDebugReplayCnt <= io_txDebugReplayCnt; // @[D2dSlaveRegIf.scala 135:34]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 168:28]
      rDebugState <= 6'h0; // @[D2dSlaveRegIf.scala 168:28]
    end else begin
      rDebugState <= _rDebugState_T; // @[D2dSlaveRegIf.scala 168:28]
    end
    if (reset) begin // @[D2dSlaveRegIf.scala 175:41]
      rRxDebugLastCorrectPkgID <= 4'h0; // @[D2dSlaveRegIf.scala 175:41]
    end else begin
      rRxDebugLastCorrectPkgID <= io_rxDebugLastCorrectPkgID; // @[D2dSlaveRegIf.scala 175:41]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  ctrl_reg_WrEn = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  ctrl_reg_Wrdata = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  ctrl_aw_en = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  ctrl_awaddr = _RAND_3[7:0];
  _RAND_4 = {1{`RANDOM}};
  ctrl_awready = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  ctrl_wready = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  ctrl_bvalid = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  ctrl_araddr = _RAND_7[7:0];
  _RAND_8 = {1{`RANDOM}};
  ctrl_arready = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  ctrl_rdata = _RAND_9[31:0];
  _RAND_10 = {1{`RANDOM}};
  ctrl_rvalid = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  rPreAddrIn = _RAND_11[10:0];
  _RAND_12 = {1{`RANDOM}};
  rSlaveReplayLatency = _RAND_12[11:0];
  _RAND_13 = {1{`RANDOM}};
  rTxDebugReplayState = _RAND_13[31:0];
  _RAND_14 = {1{`RANDOM}};
  rTxDebugReplayQueue = _RAND_14[31:0];
  _RAND_15 = {1{`RANDOM}};
  rTxDebugReplayCnt = _RAND_15[31:0];
  _RAND_16 = {1{`RANDOM}};
  rDebugState = _RAND_16[5:0];
  _RAND_17 = {1{`RANDOM}};
  rRxDebugLastCorrectPkgID = _RAND_17[3:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Sd2dSlave(
  input         clock,
  input         reset,
  input         io_txClock,
  input         io_AXI4MasterPorts_readAddr_ready,
  output        io_AXI4MasterPorts_readAddr_valid,
  output [31:0] io_AXI4MasterPorts_readAddr_bits_addr,
  output [4:0]  io_AXI4MasterPorts_readAddr_bits_id,
  output [2:0]  io_AXI4MasterPorts_readAddr_bits_size,
  output [7:0]  io_AXI4MasterPorts_readAddr_bits_len,
  output [1:0]  io_AXI4MasterPorts_readAddr_bits_burst,
  output [3:0]  io_AXI4MasterPorts_readAddr_bits_cache,
  output        io_AXI4MasterPorts_readAddr_bits_lock,
  output [2:0]  io_AXI4MasterPorts_readAddr_bits_prot,
  output [3:0]  io_AXI4MasterPorts_readAddr_bits_qos,
  output [3:0]  io_AXI4MasterPorts_readAddr_bits_region,
  output        io_AXI4MasterPorts_readData_ready,
  input         io_AXI4MasterPorts_readData_valid,
  input  [63:0] io_AXI4MasterPorts_readData_bits_data,
  input         io_AXI4MasterPorts_readData_bits_last,
  input  [4:0]  io_AXI4MasterPorts_readData_bits_id,
  input  [1:0]  io_AXI4MasterPorts_readData_bits_resp,
  input         io_AXI4MasterPorts_writeAddr_ready,
  output        io_AXI4MasterPorts_writeAddr_valid,
  output [31:0] io_AXI4MasterPorts_writeAddr_bits_addr,
  output [4:0]  io_AXI4MasterPorts_writeAddr_bits_id,
  output [2:0]  io_AXI4MasterPorts_writeAddr_bits_size,
  output [7:0]  io_AXI4MasterPorts_writeAddr_bits_len,
  output [1:0]  io_AXI4MasterPorts_writeAddr_bits_burst,
  output [3:0]  io_AXI4MasterPorts_writeAddr_bits_cache,
  output        io_AXI4MasterPorts_writeAddr_bits_lock,
  output [2:0]  io_AXI4MasterPorts_writeAddr_bits_prot,
  output [3:0]  io_AXI4MasterPorts_writeAddr_bits_qos,
  output [3:0]  io_AXI4MasterPorts_writeAddr_bits_region,
  input         io_AXI4MasterPorts_writeData_ready,
  output        io_AXI4MasterPorts_writeData_valid,
  output [63:0] io_AXI4MasterPorts_writeData_bits_data,
  output        io_AXI4MasterPorts_writeData_bits_last,
  output [7:0]  io_AXI4MasterPorts_writeData_bits_strb,
  output        io_AXI4MasterPorts_writeResp_ready,
  input         io_AXI4MasterPorts_writeResp_valid,
  input  [4:0]  io_AXI4MasterPorts_writeResp_bits_id,
  input  [1:0]  io_AXI4MasterPorts_writeResp_bits_resp,
  output        io_ctrlBusPorts_readAddr_ready,
  input         io_ctrlBusPorts_readAddr_valid,
  input  [7:0]  io_ctrlBusPorts_readAddr_bits_addr,
  input  [2:0]  io_ctrlBusPorts_readAddr_bits_prot,
  input         io_ctrlBusPorts_readData_ready,
  output        io_ctrlBusPorts_readData_valid,
  output [31:0] io_ctrlBusPorts_readData_bits_data,
  output [1:0]  io_ctrlBusPorts_readData_bits_resp,
  output        io_ctrlBusPorts_writeAddr_ready,
  input         io_ctrlBusPorts_writeAddr_valid,
  input  [7:0]  io_ctrlBusPorts_writeAddr_bits_addr,
  input  [2:0]  io_ctrlBusPorts_writeAddr_bits_prot,
  output        io_ctrlBusPorts_writeData_ready,
  input         io_ctrlBusPorts_writeData_valid,
  input  [31:0] io_ctrlBusPorts_writeData_bits_data,
  input  [3:0]  io_ctrlBusPorts_writeData_bits_strb,
  input         io_ctrlBusPorts_writeResp_ready,
  output        io_ctrlBusPorts_writeResp_valid,
  output [1:0]  io_ctrlBusPorts_writeResp_bits,
  input  [6:0]  io_ARId,
  input  [6:0]  io_AWId,
  output [6:0]  io_RId,
  output [6:0]  io_BId,
  output        io_tx_clock,
  output        io_tx_flit_valid,
  output [7:0]  io_tx_flit_bits,
  output        io_tx_creditARW_free,
  output        io_tx_replayPkgID,
  input         io_rx_clock,
  input         io_rx_flit_valid,
  input  [15:0] io_rx_flit_bits,
  input         io_rx_creditRB_free,
  input         io_rx_replayPkgID
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  Tx_clock; // @[D2dSlave.scala 23:18]
  wire  Tx_reset; // @[D2dSlave.scala 23:18]
  wire  Tx_io_txClock; // @[D2dSlave.scala 23:18]
  wire  Tx_io_inAXI4R_ready; // @[D2dSlave.scala 23:18]
  wire  Tx_io_inAXI4R_valid; // @[D2dSlave.scala 23:18]
  wire [63:0] Tx_io_inAXI4R_bits_data; // @[D2dSlave.scala 23:18]
  wire  Tx_io_inAXI4R_bits_last; // @[D2dSlave.scala 23:18]
  wire [4:0] Tx_io_inAXI4R_bits_id; // @[D2dSlave.scala 23:18]
  wire [1:0] Tx_io_inAXI4R_bits_resp; // @[D2dSlave.scala 23:18]
  wire  Tx_io_inAXI4B_ready; // @[D2dSlave.scala 23:18]
  wire  Tx_io_inAXI4B_valid; // @[D2dSlave.scala 23:18]
  wire [4:0] Tx_io_inAXI4B_bits_id; // @[D2dSlave.scala 23:18]
  wire [1:0] Tx_io_inAXI4B_bits_resp; // @[D2dSlave.scala 23:18]
  wire  Tx_io_tx_clock; // @[D2dSlave.scala 23:18]
  wire  Tx_io_tx_flit_valid; // @[D2dSlave.scala 23:18]
  wire [7:0] Tx_io_tx_flit_bits; // @[D2dSlave.scala 23:18]
  wire  Tx_io_tx_creditARW_free; // @[D2dSlave.scala 23:18]
  wire  Tx_io_tx_replayPkgID; // @[D2dSlave.scala 23:18]
  wire [31:0] Tx_io_txDebugReplayState; // @[D2dSlave.scala 23:18]
  wire [31:0] Tx_io_txDebugReplayQueue; // @[D2dSlave.scala 23:18]
  wire [31:0] Tx_io_txDebugReplayCnt; // @[D2dSlave.scala 23:18]
  wire [2:0] Tx_io_txDebugState; // @[D2dSlave.scala 23:18]
  wire [11:0] Tx_io_inSlaveReplayLatency; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxCreditARWFree_ready; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxCreditARWFree_valid; // @[D2dSlave.scala 23:18]
  wire [2:0] Tx_io_rx2TxCreditARWFree_bits; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxPackageIDUsed_valid; // @[D2dSlave.scala 23:18]
  wire [3:0] Tx_io_rx2TxPackageIDUsed_bits; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxCreditRBFree_valid; // @[D2dSlave.scala 23:18]
  wire [1:0] Tx_io_rx2TxCreditRBFree_bits; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxPackageIDOut_ready; // @[D2dSlave.scala 23:18]
  wire  Tx_io_rx2TxPackageIDOut_valid; // @[D2dSlave.scala 23:18]
  wire [3:0] Tx_io_rx2TxPackageIDOut_bits; // @[D2dSlave.scala 23:18]
  wire  Rx_clock; // @[D2dSlave.scala 29:18]
  wire  Rx_reset; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4W_ready; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4W_valid; // @[D2dSlave.scala 29:18]
  wire [63:0] Rx_io_outAXI4W_bits_data; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4W_bits_last; // @[D2dSlave.scala 29:18]
  wire [7:0] Rx_io_outAXI4W_bits_strb; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AW_ready; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AW_valid; // @[D2dSlave.scala 29:18]
  wire [31:0] Rx_io_outAXI4AW_bits_addr; // @[D2dSlave.scala 29:18]
  wire [4:0] Rx_io_outAXI4AW_bits_id; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_outAXI4AW_bits_size; // @[D2dSlave.scala 29:18]
  wire [7:0] Rx_io_outAXI4AW_bits_len; // @[D2dSlave.scala 29:18]
  wire [1:0] Rx_io_outAXI4AW_bits_burst; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AW_bits_cache; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AW_bits_lock; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_outAXI4AW_bits_prot; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AW_bits_qos; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AW_bits_region; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AR_ready; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AR_valid; // @[D2dSlave.scala 29:18]
  wire [31:0] Rx_io_outAXI4AR_bits_addr; // @[D2dSlave.scala 29:18]
  wire [4:0] Rx_io_outAXI4AR_bits_id; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_outAXI4AR_bits_size; // @[D2dSlave.scala 29:18]
  wire [7:0] Rx_io_outAXI4AR_bits_len; // @[D2dSlave.scala 29:18]
  wire [1:0] Rx_io_outAXI4AR_bits_burst; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AR_bits_cache; // @[D2dSlave.scala 29:18]
  wire  Rx_io_outAXI4AR_bits_lock; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_outAXI4AR_bits_prot; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AR_bits_qos; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_outAXI4AR_bits_region; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx_clock; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx_flit_valid; // @[D2dSlave.scala 29:18]
  wire [15:0] Rx_io_rx_flit_bits; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx_creditRB_free; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx_replayPkgID; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_rxDebugState; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_rxDebugLastCorrectPkgID; // @[D2dSlave.scala 29:18]
  wire [10:0] Rx_io_preAddrIn; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx2TxCreditARWFree_valid; // @[D2dSlave.scala 29:18]
  wire [2:0] Rx_io_rx2TxCreditARWFree_bits; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx2TxPackageIDUsed_valid; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_rx2TxPackageIDUsed_bits; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx2TxCreditRBFree_valid; // @[D2dSlave.scala 29:18]
  wire [1:0] Rx_io_rx2TxCreditRBFree_bits; // @[D2dSlave.scala 29:18]
  wire  Rx_io_rx2TxPackageIDOut_valid; // @[D2dSlave.scala 29:18]
  wire [3:0] Rx_io_rx2TxPackageIDOut_bits; // @[D2dSlave.scala 29:18]
  wire  rstTxSync_clock; // @[D2dSlave.scala 35:25]
  wire  rstTxSync_reset_in; // @[D2dSlave.scala 35:25]
  wire  rstTxSync_reset_out; // @[D2dSlave.scala 35:25]
  wire  rstRxSync_clock; // @[D2dSlave.scala 40:25]
  wire  rstRxSync_reset_in; // @[D2dSlave.scala 40:25]
  wire  rstRxSync_reset_out; // @[D2dSlave.scala 40:25]
  wire  asyncQPackageIDUsed_wr_clock; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_wr_reset; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_wr_valid; // @[D2dSlave.scala 49:35]
  wire [3:0] asyncQPackageIDUsed_wr_bits; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_rd_clock; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_rd_reset; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_rd_ready; // @[D2dSlave.scala 49:35]
  wire  asyncQPackageIDUsed_rd_valid; // @[D2dSlave.scala 49:35]
  wire [3:0] asyncQPackageIDUsed_rd_bits; // @[D2dSlave.scala 49:35]
  wire  asyncQCreditARWFree_wr_clock; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_wr_reset; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_wr_valid; // @[D2dSlave.scala 62:35]
  wire [2:0] asyncQCreditARWFree_wr_bits; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_rd_clock; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_rd_reset; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_rd_ready; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditARWFree_rd_valid; // @[D2dSlave.scala 62:35]
  wire [2:0] asyncQCreditARWFree_rd_bits; // @[D2dSlave.scala 62:35]
  wire  asyncQCreditRBFree_wr_clock; // @[D2dSlave.scala 75:34]
  wire  asyncQCreditRBFree_wr_reset; // @[D2dSlave.scala 75:34]
  wire  asyncQCreditRBFree_wr_valid; // @[D2dSlave.scala 75:34]
  wire [1:0] asyncQCreditRBFree_wr_bits; // @[D2dSlave.scala 75:34]
  wire  asyncQCreditRBFree_rd_clock; // @[D2dSlave.scala 75:34]
  wire  asyncQCreditRBFree_rd_reset; // @[D2dSlave.scala 75:34]
  wire  asyncQCreditRBFree_rd_valid; // @[D2dSlave.scala 75:34]
  wire [1:0] asyncQCreditRBFree_rd_bits; // @[D2dSlave.scala 75:34]
  wire  asyncQPackageIDOut_wr_clock; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_wr_reset; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_wr_valid; // @[D2dSlave.scala 88:34]
  wire [3:0] asyncQPackageIDOut_wr_bits; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_rd_clock; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_rd_reset; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_rd_ready; // @[D2dSlave.scala 88:34]
  wire  asyncQPackageIDOut_rd_valid; // @[D2dSlave.scala 88:34]
  wire [3:0] asyncQPackageIDOut_rd_bits; // @[D2dSlave.scala 88:34]
  wire  D2dSlaveCtrlRegIf_clock; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_reset; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_ready; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_valid; // @[D2dSlave.scala 97:33]
  wire [7:0] D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_ready; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_valid; // @[D2dSlave.scala 97:33]
  wire [31:0] D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_bits_data; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_ready; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_valid; // @[D2dSlave.scala 97:33]
  wire [7:0] D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_ready; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_valid; // @[D2dSlave.scala 97:33]
  wire [31:0] D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_bits_data; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_ready; // @[D2dSlave.scala 97:33]
  wire  D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_valid; // @[D2dSlave.scala 97:33]
  wire [11:0] D2dSlaveCtrlRegIf_io_inSlaveReplayLatency; // @[D2dSlave.scala 97:33]
  wire [31:0] D2dSlaveCtrlRegIf_io_txDebugReplayState; // @[D2dSlave.scala 97:33]
  wire [31:0] D2dSlaveCtrlRegIf_io_txDebugReplayQueue; // @[D2dSlave.scala 97:33]
  wire [31:0] D2dSlaveCtrlRegIf_io_txDebugReplayCnt; // @[D2dSlave.scala 97:33]
  wire [2:0] D2dSlaveCtrlRegIf_io_txDebugState; // @[D2dSlave.scala 97:33]
  wire [2:0] D2dSlaveCtrlRegIf_io_rxDebugState; // @[D2dSlave.scala 97:33]
  wire [3:0] D2dSlaveCtrlRegIf_io_rxDebugLastCorrectPkgID; // @[D2dSlave.scala 97:33]
  wire [10:0] D2dSlaveCtrlRegIf_io_preAddrIn; // @[D2dSlave.scala 97:33]
  wire  rIDReg0_x2 = io_ctrlBusPorts_readAddr_ready & io_ctrlBusPorts_readAddr_valid; // @[Decoupled.scala 52:35]
  reg [6:0] rIDReg0; // @[Reg.scala 35:20]
  wire  wIDReg0_x5 = io_ctrlBusPorts_writeAddr_ready & io_ctrlBusPorts_writeAddr_valid; // @[Decoupled.scala 52:35]
  reg [6:0] wIDReg0; // @[Reg.scala 35:20]
  Sd2dSlaveTx Tx ( // @[D2dSlave.scala 23:18]
    .clock(Tx_clock),
    .reset(Tx_reset),
    .io_txClock(Tx_io_txClock),
    .io_inAXI4R_ready(Tx_io_inAXI4R_ready),
    .io_inAXI4R_valid(Tx_io_inAXI4R_valid),
    .io_inAXI4R_bits_data(Tx_io_inAXI4R_bits_data),
    .io_inAXI4R_bits_last(Tx_io_inAXI4R_bits_last),
    .io_inAXI4R_bits_id(Tx_io_inAXI4R_bits_id),
    .io_inAXI4R_bits_resp(Tx_io_inAXI4R_bits_resp),
    .io_inAXI4B_ready(Tx_io_inAXI4B_ready),
    .io_inAXI4B_valid(Tx_io_inAXI4B_valid),
    .io_inAXI4B_bits_id(Tx_io_inAXI4B_bits_id),
    .io_inAXI4B_bits_resp(Tx_io_inAXI4B_bits_resp),
    .io_tx_clock(Tx_io_tx_clock),
    .io_tx_flit_valid(Tx_io_tx_flit_valid),
    .io_tx_flit_bits(Tx_io_tx_flit_bits),
    .io_tx_creditARW_free(Tx_io_tx_creditARW_free),
    .io_tx_replayPkgID(Tx_io_tx_replayPkgID),
    .io_txDebugReplayState(Tx_io_txDebugReplayState),
    .io_txDebugReplayQueue(Tx_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(Tx_io_txDebugReplayCnt),
    .io_txDebugState(Tx_io_txDebugState),
    .io_inSlaveReplayLatency(Tx_io_inSlaveReplayLatency),
    .io_rx2TxCreditARWFree_ready(Tx_io_rx2TxCreditARWFree_ready),
    .io_rx2TxCreditARWFree_valid(Tx_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(Tx_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_valid(Tx_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(Tx_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_valid(Tx_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(Tx_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_ready(Tx_io_rx2TxPackageIDOut_ready),
    .io_rx2TxPackageIDOut_valid(Tx_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(Tx_io_rx2TxPackageIDOut_bits)
  );
  Sd2dSlaveRx Rx ( // @[D2dSlave.scala 29:18]
    .clock(Rx_clock),
    .reset(Rx_reset),
    .io_outAXI4W_ready(Rx_io_outAXI4W_ready),
    .io_outAXI4W_valid(Rx_io_outAXI4W_valid),
    .io_outAXI4W_bits_data(Rx_io_outAXI4W_bits_data),
    .io_outAXI4W_bits_last(Rx_io_outAXI4W_bits_last),
    .io_outAXI4W_bits_strb(Rx_io_outAXI4W_bits_strb),
    .io_outAXI4AW_ready(Rx_io_outAXI4AW_ready),
    .io_outAXI4AW_valid(Rx_io_outAXI4AW_valid),
    .io_outAXI4AW_bits_addr(Rx_io_outAXI4AW_bits_addr),
    .io_outAXI4AW_bits_id(Rx_io_outAXI4AW_bits_id),
    .io_outAXI4AW_bits_size(Rx_io_outAXI4AW_bits_size),
    .io_outAXI4AW_bits_len(Rx_io_outAXI4AW_bits_len),
    .io_outAXI4AW_bits_burst(Rx_io_outAXI4AW_bits_burst),
    .io_outAXI4AW_bits_cache(Rx_io_outAXI4AW_bits_cache),
    .io_outAXI4AW_bits_lock(Rx_io_outAXI4AW_bits_lock),
    .io_outAXI4AW_bits_prot(Rx_io_outAXI4AW_bits_prot),
    .io_outAXI4AW_bits_qos(Rx_io_outAXI4AW_bits_qos),
    .io_outAXI4AW_bits_region(Rx_io_outAXI4AW_bits_region),
    .io_outAXI4AR_ready(Rx_io_outAXI4AR_ready),
    .io_outAXI4AR_valid(Rx_io_outAXI4AR_valid),
    .io_outAXI4AR_bits_addr(Rx_io_outAXI4AR_bits_addr),
    .io_outAXI4AR_bits_id(Rx_io_outAXI4AR_bits_id),
    .io_outAXI4AR_bits_size(Rx_io_outAXI4AR_bits_size),
    .io_outAXI4AR_bits_len(Rx_io_outAXI4AR_bits_len),
    .io_outAXI4AR_bits_burst(Rx_io_outAXI4AR_bits_burst),
    .io_outAXI4AR_bits_cache(Rx_io_outAXI4AR_bits_cache),
    .io_outAXI4AR_bits_lock(Rx_io_outAXI4AR_bits_lock),
    .io_outAXI4AR_bits_prot(Rx_io_outAXI4AR_bits_prot),
    .io_outAXI4AR_bits_qos(Rx_io_outAXI4AR_bits_qos),
    .io_outAXI4AR_bits_region(Rx_io_outAXI4AR_bits_region),
    .io_rx_clock(Rx_io_rx_clock),
    .io_rx_flit_valid(Rx_io_rx_flit_valid),
    .io_rx_flit_bits(Rx_io_rx_flit_bits),
    .io_rx_creditRB_free(Rx_io_rx_creditRB_free),
    .io_rx_replayPkgID(Rx_io_rx_replayPkgID),
    .io_rxDebugState(Rx_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(Rx_io_rxDebugLastCorrectPkgID),
    .io_preAddrIn(Rx_io_preAddrIn),
    .io_rx2TxCreditARWFree_valid(Rx_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(Rx_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_valid(Rx_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(Rx_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_valid(Rx_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(Rx_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_valid(Rx_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(Rx_io_rx2TxPackageIDOut_bits)
  );
  ResetSync_d2d rstTxSync ( // @[D2dSlave.scala 35:25]
    .clock(rstTxSync_clock),
    .reset_in(rstTxSync_reset_in),
    .reset_out(rstTxSync_reset_out)
  );
  ResetSync_d2d rstRxSync ( // @[D2dSlave.scala 40:25]
    .clock(rstRxSync_clock),
    .reset_in(rstRxSync_reset_in),
    .reset_out(rstRxSync_reset_out)
  );
  SAsyncQueue_5 asyncQPackageIDUsed ( // @[D2dSlave.scala 49:35]
    .wr_clock(asyncQPackageIDUsed_wr_clock),
    .wr_reset(asyncQPackageIDUsed_wr_reset),
    .wr_valid(asyncQPackageIDUsed_wr_valid),
    .wr_bits(asyncQPackageIDUsed_wr_bits),
    .rd_clock(asyncQPackageIDUsed_rd_clock),
    .rd_reset(asyncQPackageIDUsed_rd_reset),
    .rd_ready(asyncQPackageIDUsed_rd_ready),
    .rd_valid(asyncQPackageIDUsed_rd_valid),
    .rd_bits(asyncQPackageIDUsed_rd_bits)
  );
  SAsyncQueue_6 asyncQCreditARWFree ( // @[D2dSlave.scala 62:35]
    .wr_clock(asyncQCreditARWFree_wr_clock),
    .wr_reset(asyncQCreditARWFree_wr_reset),
    .wr_valid(asyncQCreditARWFree_wr_valid),
    .wr_bits(asyncQCreditARWFree_wr_bits),
    .rd_clock(asyncQCreditARWFree_rd_clock),
    .rd_reset(asyncQCreditARWFree_rd_reset),
    .rd_ready(asyncQCreditARWFree_rd_ready),
    .rd_valid(asyncQCreditARWFree_rd_valid),
    .rd_bits(asyncQCreditARWFree_rd_bits)
  );
  SAsyncQueue_7 asyncQCreditRBFree ( // @[D2dSlave.scala 75:34]
    .wr_clock(asyncQCreditRBFree_wr_clock),
    .wr_reset(asyncQCreditRBFree_wr_reset),
    .wr_valid(asyncQCreditRBFree_wr_valid),
    .wr_bits(asyncQCreditRBFree_wr_bits),
    .rd_clock(asyncQCreditRBFree_rd_clock),
    .rd_reset(asyncQCreditRBFree_rd_reset),
    .rd_valid(asyncQCreditRBFree_rd_valid),
    .rd_bits(asyncQCreditRBFree_rd_bits)
  );
  SAsyncQueue_5 asyncQPackageIDOut ( // @[D2dSlave.scala 88:34]
    .wr_clock(asyncQPackageIDOut_wr_clock),
    .wr_reset(asyncQPackageIDOut_wr_reset),
    .wr_valid(asyncQPackageIDOut_wr_valid),
    .wr_bits(asyncQPackageIDOut_wr_bits),
    .rd_clock(asyncQPackageIDOut_rd_clock),
    .rd_reset(asyncQPackageIDOut_rd_reset),
    .rd_ready(asyncQPackageIDOut_rd_ready),
    .rd_valid(asyncQPackageIDOut_rd_valid),
    .rd_bits(asyncQPackageIDOut_rd_bits)
  );
  SD2dSlaveCtrlRegIf D2dSlaveCtrlRegIf ( // @[D2dSlave.scala 97:33]
    .clock(D2dSlaveCtrlRegIf_clock),
    .reset(D2dSlaveCtrlRegIf_reset),
    .io_ctrlBusPorts_readAddr_ready(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_ready),
    .io_ctrlBusPorts_readAddr_valid(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_valid),
    .io_ctrlBusPorts_readAddr_bits_addr(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr),
    .io_ctrlBusPorts_readData_ready(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_ready),
    .io_ctrlBusPorts_readData_valid(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_valid),
    .io_ctrlBusPorts_readData_bits_data(D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_bits_data),
    .io_ctrlBusPorts_writeAddr_ready(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_ready),
    .io_ctrlBusPorts_writeAddr_valid(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_valid),
    .io_ctrlBusPorts_writeAddr_bits_addr(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr),
    .io_ctrlBusPorts_writeData_ready(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_ready),
    .io_ctrlBusPorts_writeData_valid(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_valid),
    .io_ctrlBusPorts_writeData_bits_data(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_bits_data),
    .io_ctrlBusPorts_writeResp_ready(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_ready),
    .io_ctrlBusPorts_writeResp_valid(D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_valid),
    .io_inSlaveReplayLatency(D2dSlaveCtrlRegIf_io_inSlaveReplayLatency),
    .io_txDebugReplayState(D2dSlaveCtrlRegIf_io_txDebugReplayState),
    .io_txDebugReplayQueue(D2dSlaveCtrlRegIf_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(D2dSlaveCtrlRegIf_io_txDebugReplayCnt),
    .io_txDebugState(D2dSlaveCtrlRegIf_io_txDebugState),
    .io_rxDebugState(D2dSlaveCtrlRegIf_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(D2dSlaveCtrlRegIf_io_rxDebugLastCorrectPkgID),
    .io_preAddrIn(D2dSlaveCtrlRegIf_io_preAddrIn)
  );
  assign io_AXI4MasterPorts_readAddr_valid = Rx_io_outAXI4AR_valid; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_addr = Rx_io_outAXI4AR_bits_addr; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_id = Rx_io_outAXI4AR_bits_id; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_size = Rx_io_outAXI4AR_bits_size; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_len = Rx_io_outAXI4AR_bits_len; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_burst = Rx_io_outAXI4AR_bits_burst; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_cache = Rx_io_outAXI4AR_bits_cache; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_lock = Rx_io_outAXI4AR_bits_lock; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_prot = Rx_io_outAXI4AR_bits_prot; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_qos = Rx_io_outAXI4AR_bits_qos; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readAddr_bits_region = Rx_io_outAXI4AR_bits_region; // @[D2dSlave.scala 32:31]
  assign io_AXI4MasterPorts_readData_ready = Tx_io_inAXI4R_ready; // @[D2dSlave.scala 25:32]
  assign io_AXI4MasterPorts_writeAddr_valid = Rx_io_outAXI4AW_valid; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_addr = Rx_io_outAXI4AW_bits_addr; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_id = Rx_io_outAXI4AW_bits_id; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_size = Rx_io_outAXI4AW_bits_size; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_len = Rx_io_outAXI4AW_bits_len; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_burst = Rx_io_outAXI4AW_bits_burst; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_cache = Rx_io_outAXI4AW_bits_cache; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_lock = Rx_io_outAXI4AW_bits_lock; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_prot = Rx_io_outAXI4AW_bits_prot; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_qos = Rx_io_outAXI4AW_bits_qos; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeAddr_bits_region = Rx_io_outAXI4AW_bits_region; // @[D2dSlave.scala 30:32]
  assign io_AXI4MasterPorts_writeData_valid = Rx_io_outAXI4W_valid; // @[D2dSlave.scala 31:32]
  assign io_AXI4MasterPorts_writeData_bits_data = Rx_io_outAXI4W_bits_data; // @[D2dSlave.scala 31:32]
  assign io_AXI4MasterPorts_writeData_bits_last = Rx_io_outAXI4W_bits_last; // @[D2dSlave.scala 31:32]
  assign io_AXI4MasterPorts_writeData_bits_strb = Rx_io_outAXI4W_bits_strb; // @[D2dSlave.scala 31:32]
  assign io_AXI4MasterPorts_writeResp_ready = Tx_io_inAXI4B_ready; // @[D2dSlave.scala 24:32]
  assign io_ctrlBusPorts_readAddr_ready = D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_ready; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_readData_valid = D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_valid; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_readData_bits_data = D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_bits_data; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_readData_bits_resp = 2'h0; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_writeAddr_ready = D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_ready; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_writeData_ready = D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_ready; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_writeResp_valid = D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_valid; // @[D2dSlave.scala 98:19]
  assign io_ctrlBusPorts_writeResp_bits = 2'h0; // @[D2dSlave.scala 98:19]
  assign io_RId = rIDReg0; // @[D2dSlave.scala 21:10]
  assign io_BId = wIDReg0; // @[D2dSlave.scala 22:10]
  assign io_tx_clock = Tx_io_tx_clock; // @[D2dSlave.scala 27:9]
  assign io_tx_flit_valid = Tx_io_tx_flit_valid; // @[D2dSlave.scala 27:9]
  assign io_tx_flit_bits = Tx_io_tx_flit_bits; // @[D2dSlave.scala 27:9]
  assign io_tx_creditARW_free = Tx_io_tx_creditARW_free; // @[D2dSlave.scala 27:9]
  assign io_tx_replayPkgID = Tx_io_tx_replayPkgID; // @[D2dSlave.scala 27:9]
  assign Tx_clock = clock;
  assign Tx_reset = reset;
  assign Tx_io_txClock = io_txClock; // @[D2dSlave.scala 26:14]
  assign Tx_io_inAXI4R_valid = io_AXI4MasterPorts_readData_valid; // @[D2dSlave.scala 25:32]
  assign Tx_io_inAXI4R_bits_data = io_AXI4MasterPorts_readData_bits_data; // @[D2dSlave.scala 25:32]
  assign Tx_io_inAXI4R_bits_last = io_AXI4MasterPorts_readData_bits_last; // @[D2dSlave.scala 25:32]
  assign Tx_io_inAXI4R_bits_id = io_AXI4MasterPorts_readData_bits_id; // @[D2dSlave.scala 25:32]
  assign Tx_io_inAXI4R_bits_resp = io_AXI4MasterPorts_readData_bits_resp; // @[D2dSlave.scala 25:32]
  assign Tx_io_inAXI4B_valid = io_AXI4MasterPorts_writeResp_valid; // @[D2dSlave.scala 24:32]
  assign Tx_io_inAXI4B_bits_id = io_AXI4MasterPorts_writeResp_bits_id; // @[D2dSlave.scala 24:32]
  assign Tx_io_inAXI4B_bits_resp = io_AXI4MasterPorts_writeResp_bits_resp; // @[D2dSlave.scala 24:32]
  assign Tx_io_inSlaveReplayLatency = D2dSlaveCtrlRegIf_io_inSlaveReplayLatency; // @[D2dSlave.scala 99:30]
  assign Tx_io_rx2TxCreditARWFree_valid = asyncQCreditARWFree_rd_valid; // @[D2dSlave.scala 69:28]
  assign Tx_io_rx2TxCreditARWFree_bits = asyncQCreditARWFree_rd_bits; // @[D2dSlave.scala 69:28]
  assign Tx_io_rx2TxPackageIDUsed_valid = asyncQPackageIDUsed_rd_valid; // @[D2dSlave.scala 56:28]
  assign Tx_io_rx2TxPackageIDUsed_bits = asyncQPackageIDUsed_rd_bits; // @[D2dSlave.scala 56:28]
  assign Tx_io_rx2TxCreditRBFree_valid = asyncQCreditRBFree_rd_valid; // @[D2dSlave.scala 82:27]
  assign Tx_io_rx2TxCreditRBFree_bits = asyncQCreditRBFree_rd_bits; // @[D2dSlave.scala 82:27]
  assign Tx_io_rx2TxPackageIDOut_valid = asyncQPackageIDOut_rd_valid; // @[D2dSlave.scala 95:27]
  assign Tx_io_rx2TxPackageIDOut_bits = asyncQPackageIDOut_rd_bits; // @[D2dSlave.scala 95:27]
  assign Rx_clock = clock;
  assign Rx_reset = reset;
  assign Rx_io_outAXI4W_ready = io_AXI4MasterPorts_writeData_ready; // @[D2dSlave.scala 31:32]
  assign Rx_io_outAXI4AW_ready = io_AXI4MasterPorts_writeAddr_ready; // @[D2dSlave.scala 30:32]
  assign Rx_io_outAXI4AR_ready = io_AXI4MasterPorts_readAddr_ready; // @[D2dSlave.scala 32:31]
  assign Rx_io_rx_clock = io_rx_clock; // @[D2dSlave.scala 33:9]
  assign Rx_io_rx_flit_valid = io_rx_flit_valid; // @[D2dSlave.scala 33:9]
  assign Rx_io_rx_flit_bits = io_rx_flit_bits; // @[D2dSlave.scala 33:9]
  assign Rx_io_rx_creditRB_free = io_rx_creditRB_free; // @[D2dSlave.scala 33:9]
  assign Rx_io_rx_replayPkgID = io_rx_replayPkgID; // @[D2dSlave.scala 33:9]
  assign rstTxSync_clock = io_txClock; // @[D2dSlave.scala 36:22]
  assign rstTxSync_reset_in = reset; // @[D2dSlave.scala 37:46]
  assign rstRxSync_clock = io_rx_clock; // @[D2dSlave.scala 41:22]
  assign rstRxSync_reset_in = reset; // @[D2dSlave.scala 42:46]
  assign asyncQPackageIDUsed_wr_clock = io_rx_clock; // @[D2dSlave.scala 50:32]
  assign asyncQPackageIDUsed_wr_reset = rstRxSync_reset_out; // @[D2dSlave.scala 51:32]
  assign asyncQPackageIDUsed_wr_valid = Rx_io_rx2TxPackageIDUsed_valid; // @[D2dSlave.scala 55:26]
  assign asyncQPackageIDUsed_wr_bits = Rx_io_rx2TxPackageIDUsed_bits; // @[D2dSlave.scala 55:26]
  assign asyncQPackageIDUsed_rd_clock = io_txClock; // @[D2dSlave.scala 52:32]
  assign asyncQPackageIDUsed_rd_reset = rstTxSync_reset_out; // @[D2dSlave.scala 53:32]
  assign asyncQPackageIDUsed_rd_ready = 1'h1; // @[D2dSlave.scala 56:28]
  assign asyncQCreditARWFree_wr_clock = clock; // @[D2dSlave.scala 63:32]
  assign asyncQCreditARWFree_wr_reset = reset; // @[D2dSlave.scala 64:53]
  assign asyncQCreditARWFree_wr_valid = Rx_io_rx2TxCreditARWFree_valid; // @[D2dSlave.scala 68:26]
  assign asyncQCreditARWFree_wr_bits = Rx_io_rx2TxCreditARWFree_bits; // @[D2dSlave.scala 68:26]
  assign asyncQCreditARWFree_rd_clock = io_txClock; // @[D2dSlave.scala 65:32]
  assign asyncQCreditARWFree_rd_reset = rstTxSync_reset_out; // @[D2dSlave.scala 66:32]
  assign asyncQCreditARWFree_rd_ready = Tx_io_rx2TxCreditARWFree_ready; // @[D2dSlave.scala 69:28]
  assign asyncQCreditRBFree_wr_clock = io_rx_clock; // @[D2dSlave.scala 76:31]
  assign asyncQCreditRBFree_wr_reset = rstRxSync_reset_out; // @[D2dSlave.scala 77:31]
  assign asyncQCreditRBFree_wr_valid = Rx_io_rx2TxCreditRBFree_valid; // @[D2dSlave.scala 81:25]
  assign asyncQCreditRBFree_wr_bits = Rx_io_rx2TxCreditRBFree_bits; // @[D2dSlave.scala 81:25]
  assign asyncQCreditRBFree_rd_clock = io_txClock; // @[D2dSlave.scala 78:31]
  assign asyncQCreditRBFree_rd_reset = rstTxSync_reset_out; // @[D2dSlave.scala 79:31]
  assign asyncQPackageIDOut_wr_clock = io_rx_clock; // @[D2dSlave.scala 89:31]
  assign asyncQPackageIDOut_wr_reset = rstRxSync_reset_out; // @[D2dSlave.scala 90:31]
  assign asyncQPackageIDOut_wr_valid = Rx_io_rx2TxPackageIDOut_valid; // @[D2dSlave.scala 94:25]
  assign asyncQPackageIDOut_wr_bits = Rx_io_rx2TxPackageIDOut_bits; // @[D2dSlave.scala 94:25]
  assign asyncQPackageIDOut_rd_clock = io_txClock; // @[D2dSlave.scala 91:31]
  assign asyncQPackageIDOut_rd_reset = rstTxSync_reset_out; // @[D2dSlave.scala 92:31]
  assign asyncQPackageIDOut_rd_ready = Tx_io_rx2TxPackageIDOut_ready; // @[D2dSlave.scala 95:27]
  assign D2dSlaveCtrlRegIf_clock = clock;
  assign D2dSlaveCtrlRegIf_reset = reset;
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_valid = io_ctrlBusPorts_readAddr_valid; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr = io_ctrlBusPorts_readAddr_bits_addr; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_readData_ready = io_ctrlBusPorts_readData_ready; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_valid = io_ctrlBusPorts_writeAddr_valid; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr = io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_valid = io_ctrlBusPorts_writeData_valid; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeData_bits_data = io_ctrlBusPorts_writeData_bits_data; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_ctrlBusPorts_writeResp_ready = io_ctrlBusPorts_writeResp_ready; // @[D2dSlave.scala 98:19]
  assign D2dSlaveCtrlRegIf_io_txDebugReplayState = Tx_io_txDebugReplayState; // @[D2dSlave.scala 100:43]
  assign D2dSlaveCtrlRegIf_io_txDebugReplayQueue = Tx_io_txDebugReplayQueue; // @[D2dSlave.scala 101:43]
  assign D2dSlaveCtrlRegIf_io_txDebugReplayCnt = Tx_io_txDebugReplayCnt; // @[D2dSlave.scala 102:41]
  assign D2dSlaveCtrlRegIf_io_txDebugState = Tx_io_txDebugState; // @[D2dSlave.scala 103:37]
  assign D2dSlaveCtrlRegIf_io_rxDebugState = Rx_io_rxDebugState; // @[D2dSlave.scala 106:37]
  assign D2dSlaveCtrlRegIf_io_rxDebugLastCorrectPkgID = Rx_io_rxDebugLastCorrectPkgID; // @[D2dSlave.scala 107:48]
  assign D2dSlaveCtrlRegIf_io_preAddrIn = Rx_io_preAddrIn; // @[D2dSlave.scala 104:34]
  always @(posedge clock) begin
    if (reset) begin // @[Reg.scala 35:20]
      rIDReg0 <= 7'h0; // @[Reg.scala 35:20]
    end else if (rIDReg0_x2) begin // @[Reg.scala 36:18]
      rIDReg0 <= io_ARId; // @[Reg.scala 36:22]
    end
    if (reset) begin // @[Reg.scala 35:20]
      wIDReg0 <= 7'h0; // @[Reg.scala 35:20]
    end else if (wIDReg0_x5) begin // @[Reg.scala 36:18]
      wIDReg0 <= io_AWId; // @[Reg.scala 36:22]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  rIDReg0 = _RAND_0[6:0];
  _RAND_1 = {1{`RANDOM}};
  wIDReg0 = _RAND_1[6:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
