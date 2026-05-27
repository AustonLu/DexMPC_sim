module MQueue(
  input        clock,
  input        reset,
  output       io_enq_ready,
  input        io_enq_valid,
  input  [1:0] io_enq_bits,
  input        io_deq_ready,
  output       io_deq_valid,
  output [1:0] io_deq_bits
);
`ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_GARBAGE_ASSIGN
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  reg [1:0] ram [0:99]; // @[Decoupled.scala 275:95]
  wire  ram_io_deq_bits_MPORT_en; // @[Decoupled.scala 275:95]
  wire [6:0] ram_io_deq_bits_MPORT_addr; // @[Decoupled.scala 275:95]
  wire [1:0] ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 275:95]
  wire [1:0] ram_MPORT_data; // @[Decoupled.scala 275:95]
  wire [6:0] ram_MPORT_addr; // @[Decoupled.scala 275:95]
  wire  ram_MPORT_mask; // @[Decoupled.scala 275:95]
  wire  ram_MPORT_en; // @[Decoupled.scala 275:95]
  reg [6:0] enq_ptr_value; // @[Counter.scala 61:40]
  reg [6:0] deq_ptr_value; // @[Counter.scala 61:40]
  reg  maybe_full; // @[Decoupled.scala 278:27]
  wire  ptr_match = enq_ptr_value == deq_ptr_value; // @[Decoupled.scala 279:33]
  wire  empty = ptr_match & ~maybe_full; // @[Decoupled.scala 280:25]
  wire  full = ptr_match & maybe_full; // @[Decoupled.scala 281:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 52:35]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 52:35]
  wire  wrap = enq_ptr_value == 7'h63; // @[Counter.scala 73:24]
  wire [6:0] _value_T_1 = enq_ptr_value + 7'h1; // @[Counter.scala 77:24]
  wire  wrap_1 = deq_ptr_value == 7'h63; // @[Counter.scala 73:24]
  wire [6:0] _value_T_3 = deq_ptr_value + 7'h1; // @[Counter.scala 77:24]
  assign ram_io_deq_bits_MPORT_en = 1'h1;
  assign ram_io_deq_bits_MPORT_addr = deq_ptr_value;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign ram_io_deq_bits_MPORT_data = ram[ram_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 275:95]
  `else
  assign ram_io_deq_bits_MPORT_data = ram_io_deq_bits_MPORT_addr >= 7'h64 ? _RAND_1[1:0] :
    ram[ram_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 275:95]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
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
    if (reset) begin // @[Counter.scala 61:40]
      enq_ptr_value <= 7'h0; // @[Counter.scala 61:40]
    end else if (do_enq) begin // @[Decoupled.scala 288:16]
      if (wrap) begin // @[Counter.scala 87:20]
        enq_ptr_value <= 7'h0; // @[Counter.scala 87:28]
      end else begin
        enq_ptr_value <= _value_T_1; // @[Counter.scala 77:15]
      end
    end
    if (reset) begin // @[Counter.scala 61:40]
      deq_ptr_value <= 7'h0; // @[Counter.scala 61:40]
    end else if (do_deq) begin // @[Decoupled.scala 292:16]
      if (wrap_1) begin // @[Counter.scala 87:20]
        deq_ptr_value <= 7'h0; // @[Counter.scala 87:28]
      end else begin
        deq_ptr_value <= _value_T_3; // @[Counter.scala 77:15]
      end
    end
    if (reset) begin // @[Decoupled.scala 278:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 278:27]
    end else if (do_enq != do_deq) begin // @[Decoupled.scala 295:27]
      maybe_full <= do_enq; // @[Decoupled.scala 296:16]
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
`ifdef RANDOMIZE_GARBAGE_ASSIGN
  _RAND_1 = {1{`RANDOM}};
`endif // RANDOMIZE_GARBAGE_ASSIGN
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 100; initvar = initvar+1)
    ram[initvar] = _RAND_0[1:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{`RANDOM}};
  enq_ptr_value = _RAND_2[6:0];
  _RAND_3 = {1{`RANDOM}};
  deq_ptr_value = _RAND_3[6:0];
  _RAND_4 = {1{`RANDOM}};
  maybe_full = _RAND_4[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module MMasterTxAppLayer(
  output        io_appInAXI4W_ready,
  input         io_appInAXI4W_valid,
  input  [63:0] io_appInAXI4W_bits_data,
  input         io_appInAXI4W_bits_last,
  input  [7:0]  io_appInAXI4W_bits_strb,
  output        io_appInAXI4AW_ready,
  input         io_appInAXI4AW_valid,
  input  [20:0] io_appInAXI4AW_bits_addr,
  input  [6:0]  io_appInAXI4AW_bits_id,
  input  [2:0]  io_appInAXI4AW_bits_size,
  input  [7:0]  io_appInAXI4AW_bits_len,
  input  [1:0]  io_appInAXI4AW_bits_burst,
  input  [3:0]  io_appInAXI4AW_bits_cache,
  input         io_appInAXI4AW_bits_lock,
  input  [2:0]  io_appInAXI4AW_bits_prot,
  input  [3:0]  io_appInAXI4AW_bits_qos,
  input  [3:0]  io_appInAXI4AW_bits_region,
  output        io_appInAXI4AR_ready,
  input         io_appInAXI4AR_valid,
  input  [20:0] io_appInAXI4AR_bits_addr,
  input  [6:0]  io_appInAXI4AR_bits_id,
  input  [2:0]  io_appInAXI4AR_bits_size,
  input  [7:0]  io_appInAXI4AR_bits_len,
  input  [1:0]  io_appInAXI4AR_bits_burst,
  input  [3:0]  io_appInAXI4AR_bits_cache,
  input         io_appInAXI4AR_bits_lock,
  input  [2:0]  io_appInAXI4AR_bits_prot,
  input  [3:0]  io_appInAXI4AR_bits_qos,
  input  [3:0]  io_appInAXI4AR_bits_region,
  input         io_appOutAXI4W_ready,
  output        io_appOutAXI4W_valid,
  output [72:0] io_appOutAXI4W_bits,
  input         io_appOutAXI4AW_ready,
  output        io_appOutAXI4AW_valid,
  output [65:0] io_appOutAXI4AW_bits,
  input         io_appOutAXI4AR_ready,
  output        io_appOutAXI4AR_valid,
  output [65:0] io_appOutAXI4AR_bits,
  input  [10:0] io_preAddrIn
);
  wire [8:0] writeData_bits_hi = {io_appInAXI4W_bits_strb,io_appInAXI4W_bits_last}; // @[Cat.scala 33:92]
  wire [15:0] ReadAddress_bits_lo = {io_appInAXI4AR_bits_lock,io_appInAXI4AR_bits_cache,io_appInAXI4AR_bits_prot,
    io_appInAXI4AR_bits_qos,io_appInAXI4AR_bits_region}; // @[Cat.scala 33:92]
  wire [49:0] ReadAddress_bits_hi = {io_appInAXI4AR_bits_id[4:0],io_preAddrIn,io_appInAXI4AR_bits_addr,
    io_appInAXI4AR_bits_len,io_appInAXI4AR_bits_size,io_appInAXI4AR_bits_burst}; // @[Cat.scala 33:92]
  wire [15:0] writeAddress_bits_lo = {io_appInAXI4AW_bits_lock,io_appInAXI4AW_bits_cache,io_appInAXI4AW_bits_prot,
    io_appInAXI4AW_bits_qos,io_appInAXI4AW_bits_region}; // @[Cat.scala 33:92]
  wire [49:0] writeAddress_bits_hi = {io_appInAXI4AW_bits_id[4:0],io_preAddrIn,io_appInAXI4AW_bits_addr,
    io_appInAXI4AW_bits_len,io_appInAXI4AW_bits_size,io_appInAXI4AW_bits_burst}; // @[Cat.scala 33:92]
  assign io_appInAXI4W_ready = io_appOutAXI4W_ready; // @[AppLayer.scala 18:23 26:18]
  assign io_appInAXI4AW_ready = io_appOutAXI4AW_ready; // @[AppLayer.scala 57:26 82:19]
  assign io_appInAXI4AR_ready = io_appOutAXI4AR_ready; // @[AppLayer.scala 29:25 55:19]
  assign io_appOutAXI4W_valid = io_appInAXI4W_valid; // @[AppLayer.scala 18:23 19:19]
  assign io_appOutAXI4W_bits = {writeData_bits_hi,io_appInAXI4W_bits_data}; // @[Cat.scala 33:92]
  assign io_appOutAXI4AW_valid = io_appInAXI4AW_ready & io_appInAXI4AW_valid; // @[Decoupled.scala 52:35]
  assign io_appOutAXI4AW_bits = {writeAddress_bits_hi,writeAddress_bits_lo}; // @[Cat.scala 33:92]
  assign io_appOutAXI4AR_valid = io_appInAXI4AR_ready & io_appInAXI4AR_valid; // @[Decoupled.scala 52:35]
  assign io_appOutAXI4AR_bits = {ReadAddress_bits_hi,ReadAddress_bits_lo}; // @[Cat.scala 33:92]
endmodule
module MAsyncFifoMemory(
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
module MAsyncFifo(
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
  MAsyncFifoMemory mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue(
  input         wr_clock,
  input         wr_reset,
  output        wr_ready,
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
  MAsyncFifo fifo ( // @[AsyncFifo.scala 169:20]
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
module MAsyncFifoMemory_1(
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
module MAsyncFifo_1(
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
  MAsyncFifoMemory_1 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_1(
  input         wr_clock,
  input         wr_reset,
  output        wr_ready,
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
  MAsyncFifo_1 fifo ( // @[AsyncFifo.scala 169:20]
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
module MQueue_2(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [94:0] io_enq_bits,
  input         io_deq_ready,
  output        io_deq_valid,
  output [94:0] io_deq_bits
);
`ifdef RANDOMIZE_MEM_INIT
  reg [95:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg [94:0] ram [0:15]; // @[Decoupled.scala 275:95]
  wire  ram_io_deq_bits_MPORT_en; // @[Decoupled.scala 275:95]
  wire [3:0] ram_io_deq_bits_MPORT_addr; // @[Decoupled.scala 275:95]
  wire [94:0] ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 275:95]
  wire [94:0] ram_MPORT_data; // @[Decoupled.scala 275:95]
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
    ram[initvar] = _RAND_0[94:0];
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
module McrcGen(
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
module McrcGen_2(
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
module MMasterTxLinkLayer(
  input         clock,
  input         reset,
  output        io_txLL2PhyIO_clock,
  output        io_txLL2PhyIO_flit_valid,
  output [15:0] io_txLL2PhyIO_flit_bits,
  output        io_txLL2PhyIO_creditRB_free,
  output        io_txLL2PhyIO_replayPkgID,
  output        io_inAXI4W_ready,
  input         io_inAXI4W_valid,
  input  [72:0] io_inAXI4W_bits,
  output        io_inAXI4AW_ready,
  input         io_inAXI4AW_valid,
  input  [65:0] io_inAXI4AW_bits,
  output        io_inAXI4AR_ready,
  input         io_inAXI4AR_valid,
  input  [65:0] io_inAXI4AR_bits,
  output [31:0] io_txDebugReplayState,
  output [31:0] io_txDebugReplayQueue,
  output [31:0] io_txDebugReplayCnt,
  output [2:0]  io_txDebugState,
  input  [11:0] io_inMasterReplayLatency,
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
  reg [127:0] _RAND_2;
  reg [127:0] _RAND_3;
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
  reg [31:0] _RAND_29;
  reg [31:0] _RAND_30;
  reg [31:0] _RAND_31;
`endif // RANDOMIZE_REG_INIT
  wire  replayQueueFirst_clock; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueFirst_reset; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueFirst_io_enq_valid; // @[DataLinkLayer.scala 69:32]
  wire [94:0] replayQueueFirst_io_enq_bits; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueFirst_io_deq_ready; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueFirst_io_deq_valid; // @[DataLinkLayer.scala 69:32]
  wire [94:0] replayQueueFirst_io_deq_bits; // @[DataLinkLayer.scala 69:32]
  wire  replayQueueSecond_clock; // @[DataLinkLayer.scala 73:33]
  wire  replayQueueSecond_reset; // @[DataLinkLayer.scala 73:33]
  wire  replayQueueSecond_io_enq_ready; // @[DataLinkLayer.scala 73:33]
  wire  replayQueueSecond_io_enq_valid; // @[DataLinkLayer.scala 73:33]
  wire [94:0] replayQueueSecond_io_enq_bits; // @[DataLinkLayer.scala 73:33]
  wire  replayQueueSecond_io_deq_ready; // @[DataLinkLayer.scala 73:33]
  wire  replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 73:33]
  wire [94:0] replayQueueSecond_io_deq_bits; // @[DataLinkLayer.scala 73:33]
  wire [85:0] tmpAWData_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] tmpAWData_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [85:0] tmpARData_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] tmpARData_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [92:0] tmpWData_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] tmpWData_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [85:0] replayQueueFirst_io_enq_bits_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] replayQueueFirst_io_enq_bits_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [85:0] replayQueueFirst_io_enq_bits_crcgen_1_io_in; // @[crcGen.scala 99:24]
  wire [15:0] replayQueueFirst_io_enq_bits_crcgen_1_io_out; // @[crcGen.scala 99:24]
  wire [92:0] replayQueueFirst_io_enq_bits_crcgen_2_io_in; // @[crcGen.scala 99:24]
  wire [15:0] replayQueueFirst_io_enq_bits_crcgen_2_io_out; // @[crcGen.scala 99:24]
  reg [2:0] state; // @[DataLinkLayer.scala 31:24]
  reg [95:0] tmpWData; // @[DataLinkLayer.scala 35:26]
  reg [111:0] tmpAWData; // @[DataLinkLayer.scala 36:26]
  reg [111:0] tmpARData; // @[DataLinkLayer.scala 37:26]
  reg [2:0] axi4AWTCCnt; // @[DataLinkLayer.scala 40:29]
  reg [2:0] axi4ARTCCnt; // @[DataLinkLayer.scala 41:29]
  reg [2:0] axi4WTCCnt; // @[DataLinkLayer.scala 42:29]
  reg [4:0] creditWCnt; // @[DataLinkLayer.scala 45:27]
  reg [2:0] creditAWCnt; // @[DataLinkLayer.scala 47:28]
  reg [2:0] creditARCnt; // @[DataLinkLayer.scala 49:28]
  reg [3:0] pkgID; // @[DataLinkLayer.scala 53:22]
  reg [15:0] txData; // @[DataLinkLayer.scala 55:24]
  reg  txDataValid; // @[DataLinkLayer.scala 56:28]
  reg  replayState; // @[DataLinkLayer.scala 59:28]
  reg [3:0] packageTmpId; // @[DataLinkLayer.scala 61:29]
  reg [7:0] replayPkgCnt; // @[DataLinkLayer.scala 75:29]
  reg  secondToFirst; // @[DataLinkLayer.scala 77:30]
  reg [7:0] replayCnt; // @[DataLinkLayer.scala 79:26]
  reg [7:0] replayCntAllTime; // @[DataLinkLayer.scala 80:33]
  reg  replayStateDelay; // @[DataLinkLayer.scala 81:33]
  reg  secondToFirstDelay; // @[DataLinkLayer.scala 82:35]
  reg [11:0] masterReplayLatency; // @[DataLinkLayer.scala 83:36]
  reg [11:0] replayCheckCnt; // @[DataLinkLayer.scala 86:31]
  wire  _T_3 = io_inAXI4AW_ready & io_inAXI4AW_valid; // @[Decoupled.scala 52:35]
  wire [3:0] _pkgID_T_1 = pkgID + 4'h1; // @[DataLinkLayer.scala 97:24]
  wire [19:0] tmpAWData_hi = {16'h1234,pkgID}; // @[Cat.scala 33:92]
  wire [111:0] _tmpAWData_T_1 = {26'h0,pkgID,tmpAWData_crcgen_io_out,io_inAXI4AW_bits}; // @[Cat.scala 33:92]
  wire  _T_4 = replayQueueFirst_io_deq_ready & replayQueueFirst_io_deq_valid; // @[Decoupled.scala 52:35]
  wire  _T_5 = replayState & _T_4; // @[DataLinkLayer.scala 106:30]
  wire  _T_7 = replayQueueFirst_io_deq_bits[94:93] == 2'h1; // @[DataLinkLayer.scala 106:133]
  wire  _T_9 = io_inAXI4AR_ready & io_inAXI4AR_valid; // @[Decoupled.scala 52:35]
  wire [19:0] tmpARData_hi = {16'h5678,pkgID}; // @[Cat.scala 33:92]
  wire [111:0] _tmpARData_T_1 = {26'h0,pkgID,tmpARData_crcgen_io_out,io_inAXI4AR_bits}; // @[Cat.scala 33:92]
  wire  _T_13 = replayQueueFirst_io_deq_bits[94:93] == 2'h2; // @[DataLinkLayer.scala 130:133]
  wire  _T_14 = _T_5 & replayQueueFirst_io_deq_bits[94:93] == 2'h2; // @[DataLinkLayer.scala 130:62]
  wire  _T_15 = replayState & replayQueueFirst_io_deq_valid; // @[DataLinkLayer.scala 138:30]
  wire  _T_17 = replayQueueFirst_io_deq_bits[94:93] == 2'h3; // @[DataLinkLayer.scala 138:134]
  wire [1:0] _GEN_0 = replayState & replayQueueFirst_io_deq_valid & replayQueueFirst_io_deq_bits[94:93] == 2'h3 ? 2'h3
     : 2'h0; // @[DataLinkLayer.scala 138:144 139:15 143:15]
  wire [1:0] _GEN_2 = _T_5 & replayQueueFirst_io_deq_bits[94:93] == 2'h2 ? 2'h2 : _GEN_0; // @[DataLinkLayer.scala 130:142 131:15]
  wire [15:0] _GEN_3 = _T_5 & replayQueueFirst_io_deq_bits[94:93] == 2'h2 ? 16'h5678 : 16'h0; // @[DataLinkLayer.scala 130:142 134:16]
  wire [2:0] _GEN_5 = _T_5 & replayQueueFirst_io_deq_bits[94:93] == 2'h2 ? 3'h0 : axi4ARTCCnt; // @[DataLinkLayer.scala 130:142 136:21 41:29]
  wire [111:0] _GEN_6 = _T_5 & replayQueueFirst_io_deq_bits[94:93] == 2'h2 ? {{26'd0}, replayQueueFirst_io_deq_bits[85:0
    ]} : tmpARData; // @[DataLinkLayer.scala 130:142 137:19 37:26]
  wire [1:0] _GEN_7 = _T_9 ? 2'h2 : _GEN_2; // @[DataLinkLayer.scala 114:35 115:15]
  wire  _GEN_9 = _T_9 | _T_14; // @[DataLinkLayer.scala 114:35 119:21]
  wire [1:0] _GEN_13 = replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1 ? 2'h1 : _GEN_7; // @[DataLinkLayer.scala 106:142 107:15]
  wire  _GEN_15 = replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1 | _GEN_9; // @[DataLinkLayer.scala 106:142 111:21]
  wire [1:0] _GEN_21 = _T_3 ? 2'h1 : _GEN_13; // @[DataLinkLayer.scala 90:29 91:15]
  wire  _GEN_23 = _T_3 | _GEN_15; // @[DataLinkLayer.scala 90:29 95:21]
  wire [2:0] _axi4AWTCCnt_T_1 = axi4AWTCCnt + 3'h1; // @[DataLinkLayer.scala 149:34]
  wire [2:0] _state_T_1 = 3'h7 - 3'h1; // @[DataLinkLayer.scala 150:64]
  wire [1:0] _state_T_3 = axi4AWTCCnt < _state_T_1 ? 2'h1 : 2'h3; // @[DataLinkLayer.scala 150:19]
  wire [6:0] _txData_T = {axi4AWTCCnt, 4'h0}; // @[DataLinkLayer.scala 151:44]
  wire [111:0] _txData_T_1 = tmpAWData >> _txData_T; // @[DataLinkLayer.scala 151:28]
  wire [2:0] _axi4ARTCCnt_T_1 = axi4ARTCCnt + 3'h1; // @[DataLinkLayer.scala 155:34]
  wire [1:0] _state_T_7 = axi4ARTCCnt < _state_T_1 ? 2'h2 : 2'h0; // @[DataLinkLayer.scala 156:19]
  wire [6:0] _txData_T_3 = {axi4ARTCCnt, 4'h0}; // @[DataLinkLayer.scala 157:44]
  wire [111:0] _txData_T_4 = tmpARData >> _txData_T_3; // @[DataLinkLayer.scala 157:28]
  wire  _T_28 = io_inAXI4W_ready & io_inAXI4W_valid; // @[Decoupled.scala 52:35]
  wire [19:0] tmpWData_hi = {16'h9abc,pkgID}; // @[Cat.scala 33:92]
  wire [95:0] _tmpWData_T_1 = {3'h0,pkgID,tmpWData_crcgen_io_out,io_inAXI4W_bits}; // @[Cat.scala 33:92]
  wire  _T_33 = _T_5 & _T_17; // @[DataLinkLayer.scala 178:62]
  wire [1:0] _GEN_29 = _T_15 & _T_13 ? 2'h0 : 2'h3; // @[DataLinkLayer.scala 190:144 191:15 195:15]
  wire [1:0] _GEN_31 = _T_15 & _T_7 ? 2'h0 : _GEN_29; // @[DataLinkLayer.scala 186:144 187:15]
  wire [2:0] _GEN_33 = _T_5 & _T_17 ? 3'h4 : {{1'd0}, _GEN_31}; // @[DataLinkLayer.scala 178:143 179:15]
  wire [15:0] _GEN_34 = _T_5 & _T_17 ? 16'h9abc : 16'h0; // @[DataLinkLayer.scala 178:143 182:16]
  wire [2:0] _GEN_36 = _T_5 & _T_17 ? 3'h0 : axi4WTCCnt; // @[DataLinkLayer.scala 178:143 184:20 42:29]
  wire [95:0] _GEN_37 = _T_5 & _T_17 ? {{3'd0}, replayQueueFirst_io_deq_bits[92:0]} : tmpWData; // @[DataLinkLayer.scala 178:143 185:18 35:26]
  wire [2:0] _GEN_38 = _T_28 ? 3'h4 : _GEN_33; // @[DataLinkLayer.scala 162:29 163:15]
  wire [15:0] _GEN_39 = _T_28 ? 16'h9abc : _GEN_34; // @[DataLinkLayer.scala 162:29 166:16]
  wire  _GEN_40 = _T_28 | _T_33; // @[DataLinkLayer.scala 162:29 167:21]
  wire [2:0] _GEN_41 = _T_28 ? 3'h0 : _GEN_36; // @[DataLinkLayer.scala 162:29 168:20]
  wire [3:0] _GEN_42 = _T_28 ? _pkgID_T_1 : pkgID; // @[DataLinkLayer.scala 162:29 169:15 53:22]
  wire [95:0] _GEN_43 = _T_28 ? _tmpWData_T_1 : _GEN_37; // @[DataLinkLayer.scala 162:29 171:20]
  wire [2:0] _axi4WTCCnt_T_1 = axi4WTCCnt + 3'h1; // @[DataLinkLayer.scala 201:32]
  wire [2:0] _state_T_9 = 3'h6 - 3'h1; // @[DataLinkLayer.scala 202:62]
  wire [1:0] _state_T_12 = tmpWData[64] ? 2'h0 : 2'h3; // @[DataLinkLayer.scala 202:85]
  wire [2:0] _state_T_13 = axi4WTCCnt < _state_T_9 ? 3'h4 : {{1'd0}, _state_T_12}; // @[DataLinkLayer.scala 202:19]
  wire [6:0] _txData_T_6 = {axi4WTCCnt, 4'h0}; // @[DataLinkLayer.scala 203:42]
  wire [95:0] _txData_T_7 = tmpWData >> _txData_T_6; // @[DataLinkLayer.scala 203:27]
  wire [2:0] _GEN_44 = 3'h4 == state ? _axi4WTCCnt_T_1 : axi4WTCCnt; // @[DataLinkLayer.scala 88:17 201:18 42:29]
  wire [2:0] _GEN_45 = 3'h4 == state ? _state_T_13 : state; // @[DataLinkLayer.scala 202:13 88:17 31:24]
  wire [15:0] _GEN_46 = 3'h4 == state ? _txData_T_7[15:0] : txData; // @[DataLinkLayer.scala 203:14 88:17 55:24]
  wire  _GEN_47 = 3'h4 == state | txDataValid; // @[DataLinkLayer.scala 88:17 204:19 56:28]
  wire  _GEN_50 = 3'h3 == state ? _GEN_40 : _GEN_47; // @[DataLinkLayer.scala 88:17]
  wire  _GEN_57 = 3'h2 == state | _GEN_50; // @[DataLinkLayer.scala 88:17 158:19]
  wire  _GEN_64 = 3'h1 == state | _GEN_57; // @[DataLinkLayer.scala 88:17 152:19]
  wire  _io_inAXI4AW_ready_T = state == 3'h0; // @[DataLinkLayer.scala 211:31]
  wire  _io_inAXI4AW_ready_T_3 = ~replayState; // @[DataLinkLayer.scala 211:69]
  wire  _io_inAXI4AR_ready_T_7 = ~_T_3; // @[DataLinkLayer.scala 212:120]
  wire  _io_inAXI4AR_ready_T_10 = ~_T_28; // @[DataLinkLayer.scala 212:143]
  wire  _io_inAXI4W_ready_T = state == 3'h3; // @[DataLinkLayer.scala 213:31]
  reg [1:0] creditRB_freeReg; // @[DataLinkLayer.scala 216:33]
  reg [1:0] creditRB_freeCnt; // @[DataLinkLayer.scala 218:33]
  reg  creditRB_freeOutReg; // @[DataLinkLayer.scala 220:36]
  wire  _T_45 = io_rx2TxCreditRBFree_ready & io_rx2TxCreditRBFree_valid; // @[Decoupled.scala 52:35]
  wire  _T_50 = ~_T_45; // @[DataLinkLayer.scala 230:14]
  wire  _GEN_80 = _T_50 & creditRB_freeCnt == 2'h2 & creditRB_freeReg[1]; // @[DataLinkLayer.scala 233:69 234:25 237:25]
  wire  _GEN_82 = ~_T_45 & creditRB_freeCnt == 2'h1 ? creditRB_freeReg[0] : _GEN_80; // @[DataLinkLayer.scala 230:69 231:25]
  reg [3:0] replayPkgIDReg; // @[DataLinkLayer.scala 243:31]
  reg [2:0] replayPkgIDCnt; // @[DataLinkLayer.scala 245:31]
  reg  replayPkgIDOutReg; // @[DataLinkLayer.scala 247:34]
  wire  _T_57 = io_rx2TxPackageIDOut_ready & io_rx2TxPackageIDOut_valid; // @[Decoupled.scala 52:35]
  wire [2:0] _replayPkgIDCnt_T_1 = replayPkgIDCnt + 3'h1; // @[DataLinkLayer.scala 256:38]
  wire  _T_62 = ~_T_57; // @[DataLinkLayer.scala 257:14]
  wire [2:0] _replayPkgIDOutReg_T_1 = replayPkgIDCnt - 3'h1; // @[DataLinkLayer.scala 258:56]
  wire [3:0] _replayPkgIDOutReg_T_2 = replayPkgIDReg >> _replayPkgIDOutReg_T_1; // @[DataLinkLayer.scala 258:40]
  wire  _GEN_87 = _T_62 & replayPkgIDCnt == 3'h4 & _replayPkgIDOutReg_T_2[0]; // @[DataLinkLayer.scala 260:89 261:23 264:23]
  wire  _GEN_89 = ~_T_57 & replayPkgIDCnt > 3'h0 & replayPkgIDCnt < 3'h4 ? _replayPkgIDOutReg_T_2[0] : _GEN_87; // @[DataLinkLayer.scala 257:113 258:23]
  wire  _T_71 = io_rx2TxCreditARWFree_ready & io_rx2TxCreditARWFree_valid; // @[Decoupled.scala 52:35]
  wire  _T_72 = ~_T_71; // @[DataLinkLayer.scala 280:23]
  wire [4:0] _creditWCnt_T_1 = creditWCnt - 5'h1; // @[DataLinkLayer.scala 281:30]
  wire [4:0] _creditWCnt_T_5 = creditWCnt + 5'h1; // @[DataLinkLayer.scala 285:30]
  wire [2:0] _creditAWCnt_T_1 = creditAWCnt - 3'h1; // @[DataLinkLayer.scala 291:32]
  wire [2:0] _creditAWCnt_T_5 = creditAWCnt + 3'h1; // @[DataLinkLayer.scala 295:32]
  wire [2:0] _creditARCnt_T_1 = creditARCnt - 3'h1; // @[DataLinkLayer.scala 301:32]
  wire [2:0] _creditARCnt_T_5 = creditARCnt + 3'h1; // @[DataLinkLayer.scala 305:32]
  wire  _T_110 = io_rx2TxPackageIDUsed_ready & io_rx2TxPackageIDUsed_valid; // @[Decoupled.scala 52:35]
  wire [3:0] _T_112 = packageTmpId + 4'h1; // @[DataLinkLayer.scala 312:83]
  wire  _T_113 = io_rx2TxPackageIDUsed_bits == _T_112; // @[DataLinkLayer.scala 312:65]
  wire  _T_118 = io_rx2TxPackageIDUsed_bits != _T_112; // @[DataLinkLayer.scala 314:72]
  wire  _T_127 = ~replayQueueFirst_io_deq_valid; // @[DataLinkLayer.scala 325:30]
  wire  _T_129 = ~replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 325:64]
  wire  _T_130 = replayState & ~replayQueueFirst_io_deq_valid & ~replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 325:61]
  wire  _GEN_104 = replayState & ~replayQueueFirst_io_deq_valid & ~replayQueueSecond_io_deq_valid ? 1'h0 : replayState; // @[DataLinkLayer.scala 325:96 326:17 328:17]
  wire [94:0] _replayQueueFirst_io_enq_bits_T_1 = {9'h80,pkgID,replayQueueFirst_io_enq_bits_crcgen_io_out,
    io_inAXI4AW_bits}; // @[Cat.scala 33:92]
  wire [94:0] _replayQueueFirst_io_enq_bits_T_3 = {9'h100,pkgID,replayQueueFirst_io_enq_bits_crcgen_1_io_out,
    io_inAXI4AR_bits}; // @[Cat.scala 33:92]
  wire [94:0] _replayQueueFirst_io_enq_bits_T_5 = {2'h3,pkgID,replayQueueFirst_io_enq_bits_crcgen_2_io_out,
    io_inAXI4W_bits}; // @[Cat.scala 33:92]
  wire  _T_134 = replayState & secondToFirst; // @[DataLinkLayer.scala 367:25]
  wire  _GEN_106 = replayState & secondToFirst & replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 367:42 368:35 372:35]
  wire [94:0] _GEN_107 = replayState & secondToFirst ? replayQueueSecond_io_deq_bits : 95'h0; // @[DataLinkLayer.scala 367:42 369:34 373:34]
  wire  _GEN_108 = _T_28 | _GEN_106; // @[DataLinkLayer.scala 354:30 355:35]
  wire [94:0] _GEN_109 = _T_28 ? _replayQueueFirst_io_enq_bits_T_5 : _GEN_107; // @[DataLinkLayer.scala 354:30 357:36]
  wire  _GEN_110 = _T_9 | _GEN_108; // @[DataLinkLayer.scala 343:31 344:35]
  wire [94:0] _GEN_111 = _T_9 ? _replayQueueFirst_io_enq_bits_T_3 : _GEN_109; // @[DataLinkLayer.scala 343:31 350:36]
  wire  _T_149 = _T_17 & io_rx2TxPackageIDUsed_bits == replayQueueFirst_io_deq_bits[92:89]; // @[DataLinkLayer.scala 381:85]
  wire  _T_150 = (replayQueueFirst_io_deq_bits[93] ^ replayQueueFirst_io_deq_bits[94]) & io_rx2TxPackageIDUsed_bits ==
    replayQueueFirst_io_deq_bits[85:82] | _T_149; // @[DataLinkLayer.scala 380:252]
  wire  _T_151 = _T_110 & replayQueueFirst_io_deq_valid & _io_inAXI4AW_ready_T_3 & _T_150; // @[DataLinkLayer.scala 379:84]
  wire  _T_159 = _io_inAXI4AW_ready_T & _T_13; // @[DataLinkLayer.scala 385:24]
  wire  _T_160 = _io_inAXI4AW_ready_T & _T_7 | _T_159; // @[DataLinkLayer.scala 384:115]
  wire  _T_164 = _io_inAXI4W_ready_T & _T_17; // @[DataLinkLayer.scala 386:33]
  wire  _T_165 = _T_160 | _T_164; // @[DataLinkLayer.scala 385:105]
  wire  _T_169 = _T_165 & replayState & replayQueueFirst_io_deq_valid & ~secondToFirst; // @[DataLinkLayer.scala 386:163]
  wire  _GEN_118 = _T_134 & replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 405:43 406:36 408:36]
  wire [7:0] _replayPkgCnt_T_1 = replayPkgCnt + 8'h1; // @[DataLinkLayer.scala 419:34]
  wire  _T_182 = _io_inAXI4AW_ready_T_3 & replayStateDelay; // @[DataLinkLayer.scala 420:27]
  wire [11:0] _replayCheckCnt_T_1 = replayCheckCnt + 12'h1; // @[DataLinkLayer.scala 429:38]
  wire  _T_193 = replayState & replayCheckCnt == masterReplayLatency; // @[DataLinkLayer.scala 430:26]
  wire  _T_194 = replayState & replayCheckCnt == masterReplayLatency & replayQueueSecond_io_deq_valid; // @[DataLinkLayer.scala 430:68]
  wire  _T_198 = _T_193 & _T_129; // @[DataLinkLayer.scala 432:68]
  wire  _GEN_126 = _T_198 ? 1'h0 : secondToFirst; // @[DataLinkLayer.scala 440:103 441:19 443:19]
  wire  _T_207 = replayState & ~replayStateDelay; // @[DataLinkLayer.scala 446:20]
  wire [7:0] _replayCnt_T_1 = replayCnt + 8'h1; // @[DataLinkLayer.scala 451:28]
  wire [7:0] _replayCntAllTime_T_1 = replayCntAllTime + 8'h1; // @[DataLinkLayer.scala 457:42]
  reg [31:0] rTxDebugReplayState; // @[DataLinkLayer.scala 464:36]
  reg [31:0] rTxDebugReplayQueue; // @[DataLinkLayer.scala 465:36]
  reg [31:0] rTxDebugReplayCnt; // @[DataLinkLayer.scala 466:34]
  wire [8:0] rTxDebugReplayState_lo = {secondToFirst,pkgID,packageTmpId}; // @[Cat.scala 33:92]
  wire [22:0] rTxDebugReplayState_hi = {14'h0,replayCntAllTime,replayState}; // @[Cat.scala 33:92]
  wire [1:0] rTxDebugReplayQueue_lo = {replayQueueSecond_io_enq_ready,replayQueueSecond_io_deq_valid}; // @[Cat.scala 33:92]
  wire [29:0] rTxDebugReplayQueue_hi = {28'h0,replayQueueFirst_io_enq_ready,replayQueueFirst_io_deq_valid}; // @[Cat.scala 33:92]
  wire [19:0] rTxDebugReplayCnt_lo = {replayCnt,replayCheckCnt}; // @[Cat.scala 33:92]
  wire [11:0] rTxDebugReplayCnt_hi = {4'h0,replayPkgCnt}; // @[Cat.scala 33:92]
  MQueue_2 replayQueueFirst ( // @[DataLinkLayer.scala 69:32]
    .clock(replayQueueFirst_clock),
    .reset(replayQueueFirst_reset),
    .io_enq_ready(replayQueueFirst_io_enq_ready),
    .io_enq_valid(replayQueueFirst_io_enq_valid),
    .io_enq_bits(replayQueueFirst_io_enq_bits),
    .io_deq_ready(replayQueueFirst_io_deq_ready),
    .io_deq_valid(replayQueueFirst_io_deq_valid),
    .io_deq_bits(replayQueueFirst_io_deq_bits)
  );
  MQueue_2 replayQueueSecond ( // @[DataLinkLayer.scala 73:33]
    .clock(replayQueueSecond_clock),
    .reset(replayQueueSecond_reset),
    .io_enq_ready(replayQueueSecond_io_enq_ready),
    .io_enq_valid(replayQueueSecond_io_enq_valid),
    .io_enq_bits(replayQueueSecond_io_enq_bits),
    .io_deq_ready(replayQueueSecond_io_deq_ready),
    .io_deq_valid(replayQueueSecond_io_deq_valid),
    .io_deq_bits(replayQueueSecond_io_deq_bits)
  );
  McrcGen tmpAWData_crcgen ( // @[crcGen.scala 99:24]
    .io_in(tmpAWData_crcgen_io_in),
    .io_out(tmpAWData_crcgen_io_out)
  );
  McrcGen tmpARData_crcgen ( // @[crcGen.scala 99:24]
    .io_in(tmpARData_crcgen_io_in),
    .io_out(tmpARData_crcgen_io_out)
  );
  McrcGen_2 tmpWData_crcgen ( // @[crcGen.scala 99:24]
    .io_in(tmpWData_crcgen_io_in),
    .io_out(tmpWData_crcgen_io_out)
  );
  McrcGen replayQueueFirst_io_enq_bits_crcgen ( // @[crcGen.scala 99:24]
    .io_in(replayQueueFirst_io_enq_bits_crcgen_io_in),
    .io_out(replayQueueFirst_io_enq_bits_crcgen_io_out)
  );
  McrcGen replayQueueFirst_io_enq_bits_crcgen_1 ( // @[crcGen.scala 99:24]
    .io_in(replayQueueFirst_io_enq_bits_crcgen_1_io_in),
    .io_out(replayQueueFirst_io_enq_bits_crcgen_1_io_out)
  );
  McrcGen_2 replayQueueFirst_io_enq_bits_crcgen_2 ( // @[crcGen.scala 99:24]
    .io_in(replayQueueFirst_io_enq_bits_crcgen_2_io_in),
    .io_out(replayQueueFirst_io_enq_bits_crcgen_2_io_out)
  );
  assign io_txLL2PhyIO_clock = clock; // @[DataLinkLayer.scala 271:23]
  assign io_txLL2PhyIO_flit_valid = txDataValid; // @[DataLinkLayer.scala 270:28]
  assign io_txLL2PhyIO_flit_bits = txData; // @[DataLinkLayer.scala 269:28]
  assign io_txLL2PhyIO_creditRB_free = creditRB_freeOutReg; // @[DataLinkLayer.scala 240:31]
  assign io_txLL2PhyIO_replayPkgID = replayPkgIDOutReg; // @[DataLinkLayer.scala 267:29]
  assign io_inAXI4W_ready = state == 3'h3 & creditWCnt > 5'h1 & _io_inAXI4AW_ready_T_3 & replayQueueFirst_io_enq_ready
     & _io_inAXI4AR_ready_T_7; // @[DataLinkLayer.scala 213:124]
  assign io_inAXI4AW_ready = state == 3'h0 & creditAWCnt > 3'h1 & ~replayState & replayQueueFirst_io_enq_ready; // @[DataLinkLayer.scala 211:83]
  assign io_inAXI4AR_ready = _io_inAXI4AW_ready_T & creditARCnt > 3'h1 & _io_inAXI4AW_ready_T_3 &
    replayQueueFirst_io_enq_ready & ~_T_3 & ~_T_28; // @[DataLinkLayer.scala 212:139]
  assign io_txDebugReplayState = rTxDebugReplayState; // @[DataLinkLayer.scala 472:25]
  assign io_txDebugReplayQueue = rTxDebugReplayQueue; // @[DataLinkLayer.scala 473:25]
  assign io_txDebugReplayCnt = rTxDebugReplayCnt; // @[DataLinkLayer.scala 474:23]
  assign io_txDebugState = state; // @[DataLinkLayer.scala 475:28]
  assign io_rx2TxCreditARWFree_ready = 1'h1; // @[DataLinkLayer.scala 278:31]
  assign io_rx2TxPackageIDUsed_ready = 1'h1; // @[DataLinkLayer.scala 310:31]
  assign io_rx2TxCreditRBFree_ready = creditRB_freeCnt == 2'h0; // @[DataLinkLayer.scala 239:51]
  assign io_rx2TxPackageIDOut_ready = replayPkgIDCnt == 3'h0; // @[DataLinkLayer.scala 266:49]
  assign replayQueueFirst_clock = clock;
  assign replayQueueFirst_reset = reset;
  assign replayQueueFirst_io_enq_valid = _T_3 | _GEN_110; // @[DataLinkLayer.scala 332:25 333:35]
  assign replayQueueFirst_io_enq_bits = _T_3 ? _replayQueueFirst_io_enq_bits_T_1 : _GEN_111; // @[DataLinkLayer.scala 332:25 339:36]
  assign replayQueueFirst_io_deq_ready = _T_151 | _T_169; // @[DataLinkLayer.scala 382:4 383:35]
  assign replayQueueSecond_clock = clock;
  assign replayQueueSecond_reset = reset;
  assign replayQueueSecond_io_enq_valid = replayState & _T_4; // @[DataLinkLayer.scala 394:20]
  assign replayQueueSecond_io_enq_bits = _T_5 ? replayQueueFirst_io_deq_bits : 95'h0; // @[DataLinkLayer.scala 394:52 396:35 399:35]
  assign replayQueueSecond_io_deq_ready = replayState & _T_110 & _T_113 | _GEN_118; // @[DataLinkLayer.scala 403:107 404:36]
  assign tmpAWData_crcgen_io_in = {tmpAWData_hi,io_inAXI4AW_bits}; // @[Cat.scala 33:92]
  assign tmpARData_crcgen_io_in = {tmpARData_hi,io_inAXI4AR_bits}; // @[Cat.scala 33:92]
  assign tmpWData_crcgen_io_in = {tmpWData_hi,io_inAXI4W_bits}; // @[Cat.scala 33:92]
  assign replayQueueFirst_io_enq_bits_crcgen_io_in = {tmpAWData_hi,io_inAXI4AW_bits}; // @[Cat.scala 33:92]
  assign replayQueueFirst_io_enq_bits_crcgen_1_io_in = {tmpARData_hi,io_inAXI4AR_bits}; // @[Cat.scala 33:92]
  assign replayQueueFirst_io_enq_bits_crcgen_2_io_in = {tmpWData_hi,io_inAXI4W_bits}; // @[Cat.scala 33:92]
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      state <= 3'h0;
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 88:17]
      state <= {{1'd0}, _GEN_21}; // @[DataLinkLayer.scala 150:13]
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 88:17]
      state <= {{1'd0}, _state_T_3}; // @[DataLinkLayer.scala 156:13]
    end else if (3'h2 == state) begin // @[DataLinkLayer.scala 88:17]
      state <= {{1'd0}, _state_T_7};
    end else if (3'h3 == state) begin
      state <= _GEN_38;
    end else begin
      state <= _GEN_45;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      tmpWData <= 96'h0; // @[DataLinkLayer.scala 35:26]
    end else if (!(3'h0 == state)) begin // @[DataLinkLayer.scala 88:17]
      if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 88:17]
        if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 88:17]
          if (3'h3 == state) begin // @[DataLinkLayer.scala 35:26]
            tmpWData <= _GEN_43;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      tmpAWData <= 112'h0; // @[DataLinkLayer.scala 106:142 113:19 36:26 90:29 99:21]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 36:26]
      if (_T_3) begin
        tmpAWData <= _tmpAWData_T_1;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1) begin
        tmpAWData <= {{26'd0}, replayQueueFirst_io_deq_bits[85:0]};
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      tmpARData <= 112'h0; // @[DataLinkLayer.scala 106:142 123:21 37:{26,26} 90:29 114:35]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 37:26]
      if (!(_T_3)) begin
        if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1)) begin
          if (_T_9) begin
            tmpARData <= _tmpARData_T_1;
          end else begin
            tmpARData <= _GEN_6;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      axi4AWTCCnt <= 3'h0; // @[DataLinkLayer.scala 106:142 112:21 40:29 90:29 96:21]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 88:17]
      if (_T_3) begin // @[DataLinkLayer.scala 149:19]
        axi4AWTCCnt <= 3'h0;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1) begin
        axi4AWTCCnt <= 3'h0;
      end
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 40:29]
      axi4AWTCCnt <= _axi4AWTCCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      axi4ARTCCnt <= 3'h0; // @[DataLinkLayer.scala 106:142 120:21 41:{29,29} 90:29 114:35]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 88:17]
      if (!(_T_3)) begin // @[DataLinkLayer.scala 41:29]
        if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1)) begin
          if (_T_9) begin
            axi4ARTCCnt <= 3'h0;
          end else begin
            axi4ARTCCnt <= _GEN_5;
          end
        end
      end
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 88:17]
      if (3'h2 == state) begin // @[DataLinkLayer.scala 41:29]
        axi4ARTCCnt <= _axi4ARTCCnt_T_1;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      axi4WTCCnt <= 3'h0; // @[DataLinkLayer.scala 42:29]
    end else if (!(3'h0 == state)) begin // @[DataLinkLayer.scala 88:17]
      if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 88:17]
        if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 88:17]
          if (3'h3 == state) begin
            axi4WTCCnt <= _GEN_41;
          end else begin
            axi4WTCCnt <= _GEN_44;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 280:51]
      creditWCnt <= 5'h10; // @[DataLinkLayer.scala 281:16]
    end else if (_T_28 & ~_T_71) begin // @[DataLinkLayer.scala 282:90]
      creditWCnt <= _creditWCnt_T_1; // @[DataLinkLayer.scala 283:16]
    end else if (_T_28 & _T_71 & ~io_rx2TxCreditARWFree_bits[2]) begin // @[DataLinkLayer.scala 284:90]
      creditWCnt <= _creditWCnt_T_1; // @[DataLinkLayer.scala 285:16]
    end else if (_io_inAXI4AR_ready_T_10 & _T_71 & io_rx2TxCreditARWFree_bits[2]) begin // @[DataLinkLayer.scala 287:16]
      creditWCnt <= _creditWCnt_T_5;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 290:52]
      creditAWCnt <= 3'h4; // @[DataLinkLayer.scala 291:17]
    end else if (_T_3 & _T_72) begin // @[DataLinkLayer.scala 292:91]
      creditAWCnt <= _creditAWCnt_T_1; // @[DataLinkLayer.scala 293:17]
    end else if (_T_3 & _T_71 & ~io_rx2TxCreditARWFree_bits[1]) begin // @[DataLinkLayer.scala 294:91]
      creditAWCnt <= _creditAWCnt_T_1; // @[DataLinkLayer.scala 295:17]
    end else if (_io_inAXI4AR_ready_T_7 & _T_71 & io_rx2TxCreditARWFree_bits[1]) begin // @[DataLinkLayer.scala 297:17]
      creditAWCnt <= _creditAWCnt_T_5;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 300:52]
      creditARCnt <= 3'h4; // @[DataLinkLayer.scala 301:17]
    end else if (_T_9 & _T_72) begin // @[DataLinkLayer.scala 302:91]
      creditARCnt <= _creditARCnt_T_1; // @[DataLinkLayer.scala 303:17]
    end else if (_T_9 & _T_71 & ~io_rx2TxCreditARWFree_bits[0]) begin // @[DataLinkLayer.scala 304:91]
      creditARCnt <= _creditARCnt_T_1; // @[DataLinkLayer.scala 305:17]
    end else if (~_T_9 & _T_71 & io_rx2TxCreditARWFree_bits[0]) begin // @[DataLinkLayer.scala 307:17]
      creditARCnt <= _creditARCnt_T_5;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      pkgID <= 4'h0; // @[DataLinkLayer.scala 106:142 121:15 53:{22,22} 90:29 97:15 114:35]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 88:17]
      if (_T_3) begin // @[DataLinkLayer.scala 53:22]
        pkgID <= _pkgID_T_1;
      end else if (!(replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1)) begin
        if (_T_9) begin
          pkgID <= _pkgID_T_1;
        end
      end
    end else if (!(3'h1 == state)) begin // @[DataLinkLayer.scala 88:17]
      if (!(3'h2 == state)) begin // @[DataLinkLayer.scala 88:17]
        if (3'h3 == state) begin // @[DataLinkLayer.scala 53:22]
          pkgID <= _GEN_42;
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      txData <= 16'h0; // @[DataLinkLayer.scala 106:142 110:16 118:16 90:29 94:16 114:35]
    end else if (3'h0 == state) begin // @[DataLinkLayer.scala 88:17]
      if (_T_3) begin // @[DataLinkLayer.scala 151:14]
        txData <= 16'h1234;
      end else if (replayState & _T_4 & replayQueueFirst_io_deq_bits[94:93] == 2'h1) begin
        txData <= 16'h1234;
      end else if (_T_9) begin
        txData <= 16'h5678;
      end else begin
        txData <= _GEN_3;
      end
    end else if (3'h1 == state) begin // @[DataLinkLayer.scala 88:17]
      txData <= _txData_T_1[15:0]; // @[DataLinkLayer.scala 157:14]
    end else if (3'h2 == state) begin // @[DataLinkLayer.scala 88:17]
      txData <= _txData_T_4[15:0];
    end else if (3'h3 == state) begin
      txData <= _GEN_39;
    end else begin
      txData <= _GEN_46;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 88:17]
      txDataValid <= 1'h0;
    end else if (3'h0 == state) begin
      txDataValid <= _GEN_23;
    end else begin
      txDataValid <= _GEN_64;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 321:108]
      replayState <= 1'h0; // @[DataLinkLayer.scala 322:17]
    end else begin
      replayState <= _io_inAXI4AW_ready_T_3 & _T_110 & _T_118 | _GEN_104;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 312:90]
      packageTmpId <= 4'hf; // @[DataLinkLayer.scala 313:18]
    end else if (_T_110 & io_rx2TxPackageIDUsed_bits == _T_112) begin
      packageTmpId <= io_rx2TxPackageIDUsed_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 418:52]
      replayPkgCnt <= 8'h0; // @[DataLinkLayer.scala 419:18]
    end else if (_T_5) begin // @[DataLinkLayer.scala 420:47]
      replayPkgCnt <= _replayPkgCnt_T_1; // @[DataLinkLayer.scala 421:18]
    end else if (_io_inAXI4AW_ready_T_3 & replayStateDelay) begin // @[DataLinkLayer.scala 423:18]
      replayPkgCnt <= 8'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 438:96]
      secondToFirst <= 1'h0; // @[DataLinkLayer.scala 439:19]
    end else begin
      secondToFirst <= _T_194 | _GEN_126;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 446:41]
      replayCnt <= 8'h0; // @[DataLinkLayer.scala 447:15]
    end else if (replayState & ~replayStateDelay) begin // @[DataLinkLayer.scala 448:47]
      replayCnt <= 8'h1; // @[DataLinkLayer.scala 449:15]
    end else if (_T_182) begin // @[DataLinkLayer.scala 450:66]
      replayCnt <= 8'h0; // @[DataLinkLayer.scala 451:15]
    end else if (_T_134 & ~secondToFirstDelay) begin // @[DataLinkLayer.scala 453:15]
      replayCnt <= _replayCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 456:41]
      replayCntAllTime <= 8'h0; // @[DataLinkLayer.scala 457:22]
    end else if (_T_207) begin // @[DataLinkLayer.scala 459:22]
      replayCntAllTime <= _replayCntAllTime_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 81:33]
      replayStateDelay <= 1'h0; // @[DataLinkLayer.scala 81:33]
    end else begin
      replayStateDelay <= replayState; // @[DataLinkLayer.scala 81:33]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 82:35]
      secondToFirstDelay <= 1'h0; // @[DataLinkLayer.scala 82:35]
    end else begin
      secondToFirstDelay <= secondToFirst; // @[DataLinkLayer.scala 82:35]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 83:36]
      masterReplayLatency <= 12'h400; // @[DataLinkLayer.scala 83:36]
    end else begin
      masterReplayLatency <= io_inMasterReplayLatency; // @[DataLinkLayer.scala 84:23]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 426:89]
      replayCheckCnt <= 12'h0; // @[DataLinkLayer.scala 427:20]
    end else if (_T_130) begin // @[DataLinkLayer.scala 428:136]
      replayCheckCnt <= 12'h0; // @[DataLinkLayer.scala 429:20]
    end else if (replayState & replayCheckCnt != masterReplayLatency & _T_127 & replayQueueSecond_io_deq_valid) begin // @[DataLinkLayer.scala 430:102]
      replayCheckCnt <= _replayCheckCnt_T_1; // @[DataLinkLayer.scala 431:20]
    end else if (!(replayState & replayCheckCnt == masterReplayLatency & replayQueueSecond_io_deq_valid)) begin // @[DataLinkLayer.scala 432:103]
      if (_T_193 & _T_129) begin // @[DataLinkLayer.scala 435:20]
        replayCheckCnt <= 12'h0;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 221:34]
      creditRB_freeReg <= 2'h0; // @[DataLinkLayer.scala 222:22]
    end else if (_T_45) begin // @[DataLinkLayer.scala 224:22]
      creditRB_freeReg <= io_rx2TxCreditRBFree_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 227:62]
      creditRB_freeCnt <= 2'h0; // @[DataLinkLayer.scala 229:22]
    end else if (_T_45 & creditRB_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 230:69]
      creditRB_freeCnt <= 2'h1; // @[DataLinkLayer.scala 232:22]
    end else if (~_T_45 & creditRB_freeCnt == 2'h1) begin // @[DataLinkLayer.scala 233:69]
      creditRB_freeCnt <= 2'h2; // @[DataLinkLayer.scala 235:22]
    end else if (_T_50 & creditRB_freeCnt == 2'h2) begin // @[DataLinkLayer.scala 218:33]
      creditRB_freeCnt <= 2'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 227:62]
      creditRB_freeOutReg <= 1'h0; // @[DataLinkLayer.scala 228:25]
    end else begin
      creditRB_freeOutReg <= _T_45 & creditRB_freeCnt == 2'h0 | _GEN_82;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 248:34]
      replayPkgIDReg <= 4'h0; // @[DataLinkLayer.scala 249:20]
    end else if (_T_57) begin // @[DataLinkLayer.scala 251:20]
      replayPkgIDReg <= io_rx2TxPackageIDOut_bits;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 254:60]
      replayPkgIDCnt <= 3'h0; // @[DataLinkLayer.scala 256:20]
    end else if (_T_57 & replayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 257:113]
      replayPkgIDCnt <= _replayPkgIDCnt_T_1; // @[DataLinkLayer.scala 259:20]
    end else if (~_T_57 & replayPkgIDCnt > 3'h0 & replayPkgIDCnt < 3'h4) begin // @[DataLinkLayer.scala 260:89]
      replayPkgIDCnt <= _replayPkgIDCnt_T_1; // @[DataLinkLayer.scala 262:20]
    end else if (_T_62 & replayPkgIDCnt == 3'h4) begin // @[DataLinkLayer.scala 245:31]
      replayPkgIDCnt <= 3'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 254:60]
      replayPkgIDOutReg <= 1'h0; // @[DataLinkLayer.scala 255:23]
    end else begin
      replayPkgIDOutReg <= _T_57 & replayPkgIDCnt == 3'h0 | _GEN_89;
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
  state = _RAND_0[2:0];
  _RAND_1 = {3{`RANDOM}};
  tmpWData = _RAND_1[95:0];
  _RAND_2 = {4{`RANDOM}};
  tmpAWData = _RAND_2[111:0];
  _RAND_3 = {4{`RANDOM}};
  tmpARData = _RAND_3[111:0];
  _RAND_4 = {1{`RANDOM}};
  axi4AWTCCnt = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  axi4ARTCCnt = _RAND_5[2:0];
  _RAND_6 = {1{`RANDOM}};
  axi4WTCCnt = _RAND_6[2:0];
  _RAND_7 = {1{`RANDOM}};
  creditWCnt = _RAND_7[4:0];
  _RAND_8 = {1{`RANDOM}};
  creditAWCnt = _RAND_8[2:0];
  _RAND_9 = {1{`RANDOM}};
  creditARCnt = _RAND_9[2:0];
  _RAND_10 = {1{`RANDOM}};
  pkgID = _RAND_10[3:0];
  _RAND_11 = {1{`RANDOM}};
  txData = _RAND_11[15:0];
  _RAND_12 = {1{`RANDOM}};
  txDataValid = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  replayState = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  packageTmpId = _RAND_14[3:0];
  _RAND_15 = {1{`RANDOM}};
  replayPkgCnt = _RAND_15[7:0];
  _RAND_16 = {1{`RANDOM}};
  secondToFirst = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  replayCnt = _RAND_17[7:0];
  _RAND_18 = {1{`RANDOM}};
  replayCntAllTime = _RAND_18[7:0];
  _RAND_19 = {1{`RANDOM}};
  replayStateDelay = _RAND_19[0:0];
  _RAND_20 = {1{`RANDOM}};
  secondToFirstDelay = _RAND_20[0:0];
  _RAND_21 = {1{`RANDOM}};
  masterReplayLatency = _RAND_21[11:0];
  _RAND_22 = {1{`RANDOM}};
  replayCheckCnt = _RAND_22[11:0];
  _RAND_23 = {1{`RANDOM}};
  creditRB_freeReg = _RAND_23[1:0];
  _RAND_24 = {1{`RANDOM}};
  creditRB_freeCnt = _RAND_24[1:0];
  _RAND_25 = {1{`RANDOM}};
  creditRB_freeOutReg = _RAND_25[0:0];
  _RAND_26 = {1{`RANDOM}};
  replayPkgIDReg = _RAND_26[3:0];
  _RAND_27 = {1{`RANDOM}};
  replayPkgIDCnt = _RAND_27[2:0];
  _RAND_28 = {1{`RANDOM}};
  replayPkgIDOutReg = _RAND_28[0:0];
  _RAND_29 = {1{`RANDOM}};
  rTxDebugReplayState = _RAND_29[31:0];
  _RAND_30 = {1{`RANDOM}};
  rTxDebugReplayQueue = _RAND_30[31:0];
  _RAND_31 = {1{`RANDOM}};
  rTxDebugReplayCnt = _RAND_31[31:0];
`endif // RANDOMIZE_REG_INIT
  if (reset) begin
    state = 3'h0;
  end
  if (reset) begin
    tmpWData = 96'h0;
  end
  if (reset) begin
    tmpAWData = 112'h0;
  end
  if (reset) begin
    tmpARData = 112'h0;
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
    creditWCnt = 5'h10;
  end
  if (reset) begin
    creditAWCnt = 3'h4;
  end
  if (reset) begin
    creditARCnt = 3'h4;
  end
  if (reset) begin
    pkgID = 4'h0;
  end
  if (reset) begin
    txData = 16'h0;
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
    masterReplayLatency = 12'h400;
  end
  if (reset) begin
    replayCheckCnt = 12'h0;
  end
  if (reset) begin
    creditRB_freeReg = 2'h0;
  end
  if (reset) begin
    creditRB_freeCnt = 2'h0;
  end
  if (reset) begin
    creditRB_freeOutReg = 1'h0;
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
module MMasterTxPhy(
  input         io_txLL2PhyIO_clock,
  input         io_txLL2PhyIO_flit_valid,
  input  [15:0] io_txLL2PhyIO_flit_bits,
  input         io_txLL2PhyIO_creditRB_free,
  input         io_txLL2PhyIO_replayPkgID,
  output        io_txPhyIO_clock,
  output        io_txPhyIO_flit_valid,
  output [15:0] io_txPhyIO_flit_bits,
  output        io_txPhyIO_creditRB_free,
  output        io_txPhyIO_replayPkgID
);
  assign io_txPhyIO_clock = io_txLL2PhyIO_clock; // @[Phy.scala 12:20]
  assign io_txPhyIO_flit_valid = io_txLL2PhyIO_flit_valid; // @[Phy.scala 11:19]
  assign io_txPhyIO_flit_bits = io_txLL2PhyIO_flit_bits; // @[Phy.scala 11:19]
  assign io_txPhyIO_creditRB_free = io_txLL2PhyIO_creditRB_free; // @[Phy.scala 13:28]
  assign io_txPhyIO_replayPkgID = io_txLL2PhyIO_replayPkgID; // @[Phy.scala 14:26]
endmodule
module Md2dMasterTx(
  input         clock,
  input         reset,
  input         io_txClock,
  output        io_inAXI4W_ready,
  input         io_inAXI4W_valid,
  input  [63:0] io_inAXI4W_bits_data,
  input         io_inAXI4W_bits_last,
  input  [7:0]  io_inAXI4W_bits_strb,
  output        io_inAXI4AW_ready,
  input         io_inAXI4AW_valid,
  input  [20:0] io_inAXI4AW_bits_addr,
  input  [6:0]  io_inAXI4AW_bits_id,
  input  [2:0]  io_inAXI4AW_bits_size,
  input  [7:0]  io_inAXI4AW_bits_len,
  input  [1:0]  io_inAXI4AW_bits_burst,
  input  [3:0]  io_inAXI4AW_bits_cache,
  input         io_inAXI4AW_bits_lock,
  input  [2:0]  io_inAXI4AW_bits_prot,
  input  [3:0]  io_inAXI4AW_bits_qos,
  input  [3:0]  io_inAXI4AW_bits_region,
  output        io_inAXI4AR_ready,
  input         io_inAXI4AR_valid,
  input  [20:0] io_inAXI4AR_bits_addr,
  input  [6:0]  io_inAXI4AR_bits_id,
  input  [2:0]  io_inAXI4AR_bits_size,
  input  [7:0]  io_inAXI4AR_bits_len,
  input  [1:0]  io_inAXI4AR_bits_burst,
  input  [3:0]  io_inAXI4AR_bits_cache,
  input         io_inAXI4AR_bits_lock,
  input  [2:0]  io_inAXI4AR_bits_prot,
  input  [3:0]  io_inAXI4AR_bits_qos,
  input  [3:0]  io_inAXI4AR_bits_region,
  input  [10:0] io_preAddrIn,
  output        io_tx_clock,
  output        io_tx_flit_valid,
  output [15:0] io_tx_flit_bits,
  output        io_tx_creditRB_free,
  output        io_tx_replayPkgID,
  output [31:0] io_txDebugReplayState,
  output [31:0] io_txDebugReplayQueue,
  output [31:0] io_txDebugReplayCnt,
  output [2:0]  io_txDebugState,
  input  [11:0] io_inMasterReplayLatency,
  input         io_rx2TxCreditARWFree_valid,
  input  [2:0]  io_rx2TxCreditARWFree_bits,
  input         io_rx2TxPackageIDUsed_valid,
  input  [3:0]  io_rx2TxPackageIDUsed_bits,
  output        io_rx2TxCreditRBFree_ready,
  input         io_rx2TxCreditRBFree_valid,
  input  [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDOut_ready,
  input         io_rx2TxPackageIDOut_valid,
  input  [3:0]  io_rx2TxPackageIDOut_bits
);
  wire  rstTxSync_clock; // @[D2dMasterTx.scala 25:25]
  wire  rstTxSync_reset_in; // @[D2dMasterTx.scala 25:25]
  wire  rstTxSync_reset_out; // @[D2dMasterTx.scala 25:25]
  wire  MasterTxAppLayer_io_appInAXI4W_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4W_valid; // @[D2dMasterTx.scala 30:32]
  wire [63:0] MasterTxAppLayer_io_appInAXI4W_bits_data; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4W_bits_last; // @[D2dMasterTx.scala 30:32]
  wire [7:0] MasterTxAppLayer_io_appInAXI4W_bits_strb; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AW_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AW_valid; // @[D2dMasterTx.scala 30:32]
  wire [20:0] MasterTxAppLayer_io_appInAXI4AW_bits_addr; // @[D2dMasterTx.scala 30:32]
  wire [6:0] MasterTxAppLayer_io_appInAXI4AW_bits_id; // @[D2dMasterTx.scala 30:32]
  wire [2:0] MasterTxAppLayer_io_appInAXI4AW_bits_size; // @[D2dMasterTx.scala 30:32]
  wire [7:0] MasterTxAppLayer_io_appInAXI4AW_bits_len; // @[D2dMasterTx.scala 30:32]
  wire [1:0] MasterTxAppLayer_io_appInAXI4AW_bits_burst; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AW_bits_cache; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AW_bits_lock; // @[D2dMasterTx.scala 30:32]
  wire [2:0] MasterTxAppLayer_io_appInAXI4AW_bits_prot; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AW_bits_qos; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AW_bits_region; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AR_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AR_valid; // @[D2dMasterTx.scala 30:32]
  wire [20:0] MasterTxAppLayer_io_appInAXI4AR_bits_addr; // @[D2dMasterTx.scala 30:32]
  wire [6:0] MasterTxAppLayer_io_appInAXI4AR_bits_id; // @[D2dMasterTx.scala 30:32]
  wire [2:0] MasterTxAppLayer_io_appInAXI4AR_bits_size; // @[D2dMasterTx.scala 30:32]
  wire [7:0] MasterTxAppLayer_io_appInAXI4AR_bits_len; // @[D2dMasterTx.scala 30:32]
  wire [1:0] MasterTxAppLayer_io_appInAXI4AR_bits_burst; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AR_bits_cache; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appInAXI4AR_bits_lock; // @[D2dMasterTx.scala 30:32]
  wire [2:0] MasterTxAppLayer_io_appInAXI4AR_bits_prot; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AR_bits_qos; // @[D2dMasterTx.scala 30:32]
  wire [3:0] MasterTxAppLayer_io_appInAXI4AR_bits_region; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4W_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4W_valid; // @[D2dMasterTx.scala 30:32]
  wire [72:0] MasterTxAppLayer_io_appOutAXI4W_bits; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4AW_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4AW_valid; // @[D2dMasterTx.scala 30:32]
  wire [65:0] MasterTxAppLayer_io_appOutAXI4AW_bits; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4AR_ready; // @[D2dMasterTx.scala 30:32]
  wire  MasterTxAppLayer_io_appOutAXI4AR_valid; // @[D2dMasterTx.scala 30:32]
  wire [65:0] MasterTxAppLayer_io_appOutAXI4AR_bits; // @[D2dMasterTx.scala 30:32]
  wire [10:0] MasterTxAppLayer_io_preAddrIn; // @[D2dMasterTx.scala 30:32]
  wire  asyncQW_wr_clock; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_wr_reset; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_wr_ready; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_wr_valid; // @[D2dMasterTx.scala 37:23]
  wire [72:0] asyncQW_wr_bits; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_rd_clock; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_rd_reset; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_rd_ready; // @[D2dMasterTx.scala 37:23]
  wire  asyncQW_rd_valid; // @[D2dMasterTx.scala 37:23]
  wire [72:0] asyncQW_rd_bits; // @[D2dMasterTx.scala 37:23]
  wire  asyncQAR_wr_clock; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_wr_reset; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_wr_ready; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_wr_valid; // @[D2dMasterTx.scala 45:24]
  wire [65:0] asyncQAR_wr_bits; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_rd_clock; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_rd_reset; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_rd_ready; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAR_rd_valid; // @[D2dMasterTx.scala 45:24]
  wire [65:0] asyncQAR_rd_bits; // @[D2dMasterTx.scala 45:24]
  wire  asyncQAW_wr_clock; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_wr_reset; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_wr_ready; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_wr_valid; // @[D2dMasterTx.scala 53:24]
  wire [65:0] asyncQAW_wr_bits; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_rd_clock; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_rd_reset; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_rd_ready; // @[D2dMasterTx.scala 53:24]
  wire  asyncQAW_rd_valid; // @[D2dMasterTx.scala 53:24]
  wire [65:0] asyncQAW_rd_bits; // @[D2dMasterTx.scala 53:24]
  wire  masterTxLinkLayer_clock; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_reset; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_txLL2PhyIO_clock; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_txLL2PhyIO_flit_valid; // @[D2dMasterTx.scala 61:35]
  wire [15:0] masterTxLinkLayer_io_txLL2PhyIO_flit_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_txLL2PhyIO_creditRB_free; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_txLL2PhyIO_replayPkgID; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4W_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4W_valid; // @[D2dMasterTx.scala 61:35]
  wire [72:0] masterTxLinkLayer_io_inAXI4W_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4AW_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4AW_valid; // @[D2dMasterTx.scala 61:35]
  wire [65:0] masterTxLinkLayer_io_inAXI4AW_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4AR_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_inAXI4AR_valid; // @[D2dMasterTx.scala 61:35]
  wire [65:0] masterTxLinkLayer_io_inAXI4AR_bits; // @[D2dMasterTx.scala 61:35]
  wire [31:0] masterTxLinkLayer_io_txDebugReplayState; // @[D2dMasterTx.scala 61:35]
  wire [31:0] masterTxLinkLayer_io_txDebugReplayQueue; // @[D2dMasterTx.scala 61:35]
  wire [31:0] masterTxLinkLayer_io_txDebugReplayCnt; // @[D2dMasterTx.scala 61:35]
  wire [2:0] masterTxLinkLayer_io_txDebugState; // @[D2dMasterTx.scala 61:35]
  wire [11:0] masterTxLinkLayer_io_inMasterReplayLatency; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxCreditARWFree_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxCreditARWFree_valid; // @[D2dMasterTx.scala 61:35]
  wire [2:0] masterTxLinkLayer_io_rx2TxCreditARWFree_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxPackageIDUsed_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dMasterTx.scala 61:35]
  wire [3:0] masterTxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxCreditRBFree_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxCreditRBFree_valid; // @[D2dMasterTx.scala 61:35]
  wire [1:0] masterTxLinkLayer_io_rx2TxCreditRBFree_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxPackageIDOut_ready; // @[D2dMasterTx.scala 61:35]
  wire  masterTxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dMasterTx.scala 61:35]
  wire [3:0] masterTxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dMasterTx.scala 61:35]
  wire  masterTxPhy_io_txLL2PhyIO_clock; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txLL2PhyIO_flit_valid; // @[D2dMasterTx.scala 62:29]
  wire [15:0] masterTxPhy_io_txLL2PhyIO_flit_bits; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txLL2PhyIO_creditRB_free; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txLL2PhyIO_replayPkgID; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txPhyIO_clock; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txPhyIO_flit_valid; // @[D2dMasterTx.scala 62:29]
  wire [15:0] masterTxPhy_io_txPhyIO_flit_bits; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txPhyIO_creditRB_free; // @[D2dMasterTx.scala 62:29]
  wire  masterTxPhy_io_txPhyIO_replayPkgID; // @[D2dMasterTx.scala 62:29]
  ResetSync_d2d rstTxSync ( // @[D2dMasterTx.scala 25:25]
    .clock(rstTxSync_clock),
    .reset_in(rstTxSync_reset_in),
    .reset_out(rstTxSync_reset_out)
  );
  MMasterTxAppLayer MasterTxAppLayer ( // @[D2dMasterTx.scala 30:32]
    .io_appInAXI4W_ready(MasterTxAppLayer_io_appInAXI4W_ready),
    .io_appInAXI4W_valid(MasterTxAppLayer_io_appInAXI4W_valid),
    .io_appInAXI4W_bits_data(MasterTxAppLayer_io_appInAXI4W_bits_data),
    .io_appInAXI4W_bits_last(MasterTxAppLayer_io_appInAXI4W_bits_last),
    .io_appInAXI4W_bits_strb(MasterTxAppLayer_io_appInAXI4W_bits_strb),
    .io_appInAXI4AW_ready(MasterTxAppLayer_io_appInAXI4AW_ready),
    .io_appInAXI4AW_valid(MasterTxAppLayer_io_appInAXI4AW_valid),
    .io_appInAXI4AW_bits_addr(MasterTxAppLayer_io_appInAXI4AW_bits_addr),
    .io_appInAXI4AW_bits_id(MasterTxAppLayer_io_appInAXI4AW_bits_id),
    .io_appInAXI4AW_bits_size(MasterTxAppLayer_io_appInAXI4AW_bits_size),
    .io_appInAXI4AW_bits_len(MasterTxAppLayer_io_appInAXI4AW_bits_len),
    .io_appInAXI4AW_bits_burst(MasterTxAppLayer_io_appInAXI4AW_bits_burst),
    .io_appInAXI4AW_bits_cache(MasterTxAppLayer_io_appInAXI4AW_bits_cache),
    .io_appInAXI4AW_bits_lock(MasterTxAppLayer_io_appInAXI4AW_bits_lock),
    .io_appInAXI4AW_bits_prot(MasterTxAppLayer_io_appInAXI4AW_bits_prot),
    .io_appInAXI4AW_bits_qos(MasterTxAppLayer_io_appInAXI4AW_bits_qos),
    .io_appInAXI4AW_bits_region(MasterTxAppLayer_io_appInAXI4AW_bits_region),
    .io_appInAXI4AR_ready(MasterTxAppLayer_io_appInAXI4AR_ready),
    .io_appInAXI4AR_valid(MasterTxAppLayer_io_appInAXI4AR_valid),
    .io_appInAXI4AR_bits_addr(MasterTxAppLayer_io_appInAXI4AR_bits_addr),
    .io_appInAXI4AR_bits_id(MasterTxAppLayer_io_appInAXI4AR_bits_id),
    .io_appInAXI4AR_bits_size(MasterTxAppLayer_io_appInAXI4AR_bits_size),
    .io_appInAXI4AR_bits_len(MasterTxAppLayer_io_appInAXI4AR_bits_len),
    .io_appInAXI4AR_bits_burst(MasterTxAppLayer_io_appInAXI4AR_bits_burst),
    .io_appInAXI4AR_bits_cache(MasterTxAppLayer_io_appInAXI4AR_bits_cache),
    .io_appInAXI4AR_bits_lock(MasterTxAppLayer_io_appInAXI4AR_bits_lock),
    .io_appInAXI4AR_bits_prot(MasterTxAppLayer_io_appInAXI4AR_bits_prot),
    .io_appInAXI4AR_bits_qos(MasterTxAppLayer_io_appInAXI4AR_bits_qos),
    .io_appInAXI4AR_bits_region(MasterTxAppLayer_io_appInAXI4AR_bits_region),
    .io_appOutAXI4W_ready(MasterTxAppLayer_io_appOutAXI4W_ready),
    .io_appOutAXI4W_valid(MasterTxAppLayer_io_appOutAXI4W_valid),
    .io_appOutAXI4W_bits(MasterTxAppLayer_io_appOutAXI4W_bits),
    .io_appOutAXI4AW_ready(MasterTxAppLayer_io_appOutAXI4AW_ready),
    .io_appOutAXI4AW_valid(MasterTxAppLayer_io_appOutAXI4AW_valid),
    .io_appOutAXI4AW_bits(MasterTxAppLayer_io_appOutAXI4AW_bits),
    .io_appOutAXI4AR_ready(MasterTxAppLayer_io_appOutAXI4AR_ready),
    .io_appOutAXI4AR_valid(MasterTxAppLayer_io_appOutAXI4AR_valid),
    .io_appOutAXI4AR_bits(MasterTxAppLayer_io_appOutAXI4AR_bits),
    .io_preAddrIn(MasterTxAppLayer_io_preAddrIn)
  );
  MAsyncQueue asyncQW ( // @[D2dMasterTx.scala 37:23]
    .wr_clock(asyncQW_wr_clock),
    .wr_reset(asyncQW_wr_reset),
    .wr_ready(asyncQW_wr_ready),
    .wr_valid(asyncQW_wr_valid),
    .wr_bits(asyncQW_wr_bits),
    .rd_clock(asyncQW_rd_clock),
    .rd_reset(asyncQW_rd_reset),
    .rd_ready(asyncQW_rd_ready),
    .rd_valid(asyncQW_rd_valid),
    .rd_bits(asyncQW_rd_bits)
  );
  MAsyncQueue_1 asyncQAR ( // @[D2dMasterTx.scala 45:24]
    .wr_clock(asyncQAR_wr_clock),
    .wr_reset(asyncQAR_wr_reset),
    .wr_ready(asyncQAR_wr_ready),
    .wr_valid(asyncQAR_wr_valid),
    .wr_bits(asyncQAR_wr_bits),
    .rd_clock(asyncQAR_rd_clock),
    .rd_reset(asyncQAR_rd_reset),
    .rd_ready(asyncQAR_rd_ready),
    .rd_valid(asyncQAR_rd_valid),
    .rd_bits(asyncQAR_rd_bits)
  );
  MAsyncQueue_1 asyncQAW ( // @[D2dMasterTx.scala 53:24]
    .wr_clock(asyncQAW_wr_clock),
    .wr_reset(asyncQAW_wr_reset),
    .wr_ready(asyncQAW_wr_ready),
    .wr_valid(asyncQAW_wr_valid),
    .wr_bits(asyncQAW_wr_bits),
    .rd_clock(asyncQAW_rd_clock),
    .rd_reset(asyncQAW_rd_reset),
    .rd_ready(asyncQAW_rd_ready),
    .rd_valid(asyncQAW_rd_valid),
    .rd_bits(asyncQAW_rd_bits)
  );
  MMasterTxLinkLayer masterTxLinkLayer ( // @[D2dMasterTx.scala 61:35]
    .clock(masterTxLinkLayer_clock),
    .reset(masterTxLinkLayer_reset),
    .io_txLL2PhyIO_clock(masterTxLinkLayer_io_txLL2PhyIO_clock),
    .io_txLL2PhyIO_flit_valid(masterTxLinkLayer_io_txLL2PhyIO_flit_valid),
    .io_txLL2PhyIO_flit_bits(masterTxLinkLayer_io_txLL2PhyIO_flit_bits),
    .io_txLL2PhyIO_creditRB_free(masterTxLinkLayer_io_txLL2PhyIO_creditRB_free),
    .io_txLL2PhyIO_replayPkgID(masterTxLinkLayer_io_txLL2PhyIO_replayPkgID),
    .io_inAXI4W_ready(masterTxLinkLayer_io_inAXI4W_ready),
    .io_inAXI4W_valid(masterTxLinkLayer_io_inAXI4W_valid),
    .io_inAXI4W_bits(masterTxLinkLayer_io_inAXI4W_bits),
    .io_inAXI4AW_ready(masterTxLinkLayer_io_inAXI4AW_ready),
    .io_inAXI4AW_valid(masterTxLinkLayer_io_inAXI4AW_valid),
    .io_inAXI4AW_bits(masterTxLinkLayer_io_inAXI4AW_bits),
    .io_inAXI4AR_ready(masterTxLinkLayer_io_inAXI4AR_ready),
    .io_inAXI4AR_valid(masterTxLinkLayer_io_inAXI4AR_valid),
    .io_inAXI4AR_bits(masterTxLinkLayer_io_inAXI4AR_bits),
    .io_txDebugReplayState(masterTxLinkLayer_io_txDebugReplayState),
    .io_txDebugReplayQueue(masterTxLinkLayer_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(masterTxLinkLayer_io_txDebugReplayCnt),
    .io_txDebugState(masterTxLinkLayer_io_txDebugState),
    .io_inMasterReplayLatency(masterTxLinkLayer_io_inMasterReplayLatency),
    .io_rx2TxCreditARWFree_ready(masterTxLinkLayer_io_rx2TxCreditARWFree_ready),
    .io_rx2TxCreditARWFree_valid(masterTxLinkLayer_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(masterTxLinkLayer_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_ready(masterTxLinkLayer_io_rx2TxPackageIDUsed_ready),
    .io_rx2TxPackageIDUsed_valid(masterTxLinkLayer_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(masterTxLinkLayer_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_ready(masterTxLinkLayer_io_rx2TxCreditRBFree_ready),
    .io_rx2TxCreditRBFree_valid(masterTxLinkLayer_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(masterTxLinkLayer_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_ready(masterTxLinkLayer_io_rx2TxPackageIDOut_ready),
    .io_rx2TxPackageIDOut_valid(masterTxLinkLayer_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(masterTxLinkLayer_io_rx2TxPackageIDOut_bits)
  );
  MMasterTxPhy masterTxPhy ( // @[D2dMasterTx.scala 62:29]
    .io_txLL2PhyIO_clock(masterTxPhy_io_txLL2PhyIO_clock),
    .io_txLL2PhyIO_flit_valid(masterTxPhy_io_txLL2PhyIO_flit_valid),
    .io_txLL2PhyIO_flit_bits(masterTxPhy_io_txLL2PhyIO_flit_bits),
    .io_txLL2PhyIO_creditRB_free(masterTxPhy_io_txLL2PhyIO_creditRB_free),
    .io_txLL2PhyIO_replayPkgID(masterTxPhy_io_txLL2PhyIO_replayPkgID),
    .io_txPhyIO_clock(masterTxPhy_io_txPhyIO_clock),
    .io_txPhyIO_flit_valid(masterTxPhy_io_txPhyIO_flit_valid),
    .io_txPhyIO_flit_bits(masterTxPhy_io_txPhyIO_flit_bits),
    .io_txPhyIO_creditRB_free(masterTxPhy_io_txPhyIO_creditRB_free),
    .io_txPhyIO_replayPkgID(masterTxPhy_io_txPhyIO_replayPkgID)
  );
  assign io_inAXI4W_ready = MasterTxAppLayer_io_appInAXI4W_ready; // @[D2dMasterTx.scala 32:34]
  assign io_inAXI4AW_ready = MasterTxAppLayer_io_appInAXI4AW_ready; // @[D2dMasterTx.scala 33:35]
  assign io_inAXI4AR_ready = MasterTxAppLayer_io_appInAXI4AR_ready; // @[D2dMasterTx.scala 34:35]
  assign io_tx_clock = masterTxPhy_io_txPhyIO_clock; // @[D2dMasterTx.scala 68:11]
  assign io_tx_flit_valid = masterTxPhy_io_txPhyIO_flit_valid; // @[D2dMasterTx.scala 68:11]
  assign io_tx_flit_bits = masterTxPhy_io_txPhyIO_flit_bits; // @[D2dMasterTx.scala 68:11]
  assign io_tx_creditRB_free = masterTxPhy_io_txPhyIO_creditRB_free; // @[D2dMasterTx.scala 68:11]
  assign io_tx_replayPkgID = masterTxPhy_io_txPhyIO_replayPkgID; // @[D2dMasterTx.scala 68:11]
  assign io_txDebugReplayState = masterTxLinkLayer_io_txDebugReplayState; // @[D2dMasterTx.scala 71:27]
  assign io_txDebugReplayQueue = masterTxLinkLayer_io_txDebugReplayQueue; // @[D2dMasterTx.scala 70:27]
  assign io_txDebugReplayCnt = masterTxLinkLayer_io_txDebugReplayCnt; // @[D2dMasterTx.scala 73:25]
  assign io_txDebugState = masterTxLinkLayer_io_txDebugState; // @[D2dMasterTx.scala 72:21]
  assign io_rx2TxCreditRBFree_ready = masterTxLinkLayer_io_rx2TxCreditRBFree_ready; // @[D2dMasterTx.scala 78:26]
  assign io_rx2TxPackageIDOut_ready = masterTxLinkLayer_io_rx2TxPackageIDOut_ready; // @[D2dMasterTx.scala 79:26]
  assign rstTxSync_clock = io_txClock; // @[D2dMasterTx.scala 26:22]
  assign rstTxSync_reset_in = reset; // @[D2dMasterTx.scala 27:46]
  assign MasterTxAppLayer_io_appInAXI4W_valid = io_inAXI4W_valid; // @[D2dMasterTx.scala 32:34]
  assign MasterTxAppLayer_io_appInAXI4W_bits_data = io_inAXI4W_bits_data; // @[D2dMasterTx.scala 32:34]
  assign MasterTxAppLayer_io_appInAXI4W_bits_last = io_inAXI4W_bits_last; // @[D2dMasterTx.scala 32:34]
  assign MasterTxAppLayer_io_appInAXI4W_bits_strb = io_inAXI4W_bits_strb; // @[D2dMasterTx.scala 32:34]
  assign MasterTxAppLayer_io_appInAXI4AW_valid = io_inAXI4AW_valid; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_addr = io_inAXI4AW_bits_addr; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_id = io_inAXI4AW_bits_id; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_size = io_inAXI4AW_bits_size; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_len = io_inAXI4AW_bits_len; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_burst = io_inAXI4AW_bits_burst; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_cache = io_inAXI4AW_bits_cache; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_lock = io_inAXI4AW_bits_lock; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_prot = io_inAXI4AW_bits_prot; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_qos = io_inAXI4AW_bits_qos; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AW_bits_region = io_inAXI4AW_bits_region; // @[D2dMasterTx.scala 33:35]
  assign MasterTxAppLayer_io_appInAXI4AR_valid = io_inAXI4AR_valid; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_addr = io_inAXI4AR_bits_addr; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_id = io_inAXI4AR_bits_id; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_size = io_inAXI4AR_bits_size; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_len = io_inAXI4AR_bits_len; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_burst = io_inAXI4AR_bits_burst; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_cache = io_inAXI4AR_bits_cache; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_lock = io_inAXI4AR_bits_lock; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_prot = io_inAXI4AR_bits_prot; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_qos = io_inAXI4AR_bits_qos; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appInAXI4AR_bits_region = io_inAXI4AR_bits_region; // @[D2dMasterTx.scala 34:35]
  assign MasterTxAppLayer_io_appOutAXI4W_ready = asyncQW_wr_ready; // @[D2dMasterTx.scala 42:35]
  assign MasterTxAppLayer_io_appOutAXI4AW_ready = asyncQAW_wr_ready; // @[D2dMasterTx.scala 58:36]
  assign MasterTxAppLayer_io_appOutAXI4AR_ready = asyncQAR_wr_ready; // @[D2dMasterTx.scala 50:36]
  assign MasterTxAppLayer_io_preAddrIn = io_preAddrIn; // @[D2dMasterTx.scala 31:33]
  assign asyncQW_wr_clock = clock; // @[D2dMasterTx.scala 38:20]
  assign asyncQW_wr_reset = reset; // @[D2dMasterTx.scala 39:41]
  assign asyncQW_wr_valid = MasterTxAppLayer_io_appOutAXI4W_valid; // @[D2dMasterTx.scala 42:35]
  assign asyncQW_wr_bits = MasterTxAppLayer_io_appOutAXI4W_bits; // @[D2dMasterTx.scala 42:35]
  assign asyncQW_rd_clock = io_txClock; // @[D2dMasterTx.scala 40:20]
  assign asyncQW_rd_reset = rstTxSync_reset_out; // @[D2dMasterTx.scala 41:20]
  assign asyncQW_rd_ready = masterTxLinkLayer_io_inAXI4W_ready; // @[D2dMasterTx.scala 63:34]
  assign asyncQAR_wr_clock = clock; // @[D2dMasterTx.scala 46:21]
  assign asyncQAR_wr_reset = reset; // @[D2dMasterTx.scala 47:42]
  assign asyncQAR_wr_valid = MasterTxAppLayer_io_appOutAXI4AR_valid; // @[D2dMasterTx.scala 50:36]
  assign asyncQAR_wr_bits = MasterTxAppLayer_io_appOutAXI4AR_bits; // @[D2dMasterTx.scala 50:36]
  assign asyncQAR_rd_clock = io_txClock; // @[D2dMasterTx.scala 48:21]
  assign asyncQAR_rd_reset = rstTxSync_reset_out; // @[D2dMasterTx.scala 49:21]
  assign asyncQAR_rd_ready = masterTxLinkLayer_io_inAXI4AR_ready; // @[D2dMasterTx.scala 65:35]
  assign asyncQAW_wr_clock = clock; // @[D2dMasterTx.scala 54:21]
  assign asyncQAW_wr_reset = reset; // @[D2dMasterTx.scala 55:42]
  assign asyncQAW_wr_valid = MasterTxAppLayer_io_appOutAXI4AW_valid; // @[D2dMasterTx.scala 58:36]
  assign asyncQAW_wr_bits = MasterTxAppLayer_io_appOutAXI4AW_bits; // @[D2dMasterTx.scala 58:36]
  assign asyncQAW_rd_clock = io_txClock; // @[D2dMasterTx.scala 56:21]
  assign asyncQAW_rd_reset = rstTxSync_reset_out; // @[D2dMasterTx.scala 57:21]
  assign asyncQAW_rd_ready = masterTxLinkLayer_io_inAXI4AW_ready; // @[D2dMasterTx.scala 64:35]
  assign masterTxLinkLayer_clock = io_txClock;
  assign masterTxLinkLayer_reset = rstTxSync_reset_out;
  assign masterTxLinkLayer_io_inAXI4W_valid = asyncQW_rd_valid; // @[D2dMasterTx.scala 63:34]
  assign masterTxLinkLayer_io_inAXI4W_bits = asyncQW_rd_bits; // @[D2dMasterTx.scala 63:34]
  assign masterTxLinkLayer_io_inAXI4AW_valid = asyncQAW_rd_valid; // @[D2dMasterTx.scala 64:35]
  assign masterTxLinkLayer_io_inAXI4AW_bits = asyncQAW_rd_bits; // @[D2dMasterTx.scala 64:35]
  assign masterTxLinkLayer_io_inAXI4AR_valid = asyncQAR_rd_valid; // @[D2dMasterTx.scala 65:35]
  assign masterTxLinkLayer_io_inAXI4AR_bits = asyncQAR_rd_bits; // @[D2dMasterTx.scala 65:35]
  assign masterTxLinkLayer_io_inMasterReplayLatency = io_inMasterReplayLatency; // @[D2dMasterTx.scala 74:48]
  assign masterTxLinkLayer_io_rx2TxCreditARWFree_valid = io_rx2TxCreditARWFree_valid; // @[D2dMasterTx.scala 76:27]
  assign masterTxLinkLayer_io_rx2TxCreditARWFree_bits = io_rx2TxCreditARWFree_bits; // @[D2dMasterTx.scala 76:27]
  assign masterTxLinkLayer_io_rx2TxPackageIDUsed_valid = io_rx2TxPackageIDUsed_valid; // @[D2dMasterTx.scala 77:27]
  assign masterTxLinkLayer_io_rx2TxPackageIDUsed_bits = io_rx2TxPackageIDUsed_bits; // @[D2dMasterTx.scala 77:27]
  assign masterTxLinkLayer_io_rx2TxCreditRBFree_valid = io_rx2TxCreditRBFree_valid; // @[D2dMasterTx.scala 78:26]
  assign masterTxLinkLayer_io_rx2TxCreditRBFree_bits = io_rx2TxCreditRBFree_bits; // @[D2dMasterTx.scala 78:26]
  assign masterTxLinkLayer_io_rx2TxPackageIDOut_valid = io_rx2TxPackageIDOut_valid; // @[D2dMasterTx.scala 79:26]
  assign masterTxLinkLayer_io_rx2TxPackageIDOut_bits = io_rx2TxPackageIDOut_bits; // @[D2dMasterTx.scala 79:26]
  assign masterTxPhy_io_txLL2PhyIO_clock = masterTxLinkLayer_io_txLL2PhyIO_clock; // @[D2dMasterTx.scala 66:37]
  assign masterTxPhy_io_txLL2PhyIO_flit_valid = masterTxLinkLayer_io_txLL2PhyIO_flit_valid; // @[D2dMasterTx.scala 66:37]
  assign masterTxPhy_io_txLL2PhyIO_flit_bits = masterTxLinkLayer_io_txLL2PhyIO_flit_bits; // @[D2dMasterTx.scala 66:37]
  assign masterTxPhy_io_txLL2PhyIO_creditRB_free = masterTxLinkLayer_io_txLL2PhyIO_creditRB_free; // @[D2dMasterTx.scala 66:37]
  assign masterTxPhy_io_txLL2PhyIO_replayPkgID = masterTxLinkLayer_io_txLL2PhyIO_replayPkgID; // @[D2dMasterTx.scala 66:37]
endmodule
module MAsyncFifoMemory_3(
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
module MAsyncFifo_3(
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
  MAsyncFifoMemory_3 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_3(
  input         wr_clock,
  input         wr_reset,
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
  MAsyncFifo_3 fifo ( // @[AsyncFifo.scala 169:20]
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
module MAsyncFifoMemory_4(
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
module MAsyncFifo_4(
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
  MAsyncFifoMemory_4 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_4(
  input        wr_clock,
  input        wr_reset,
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
  MAsyncFifo_4 fifo ( // @[AsyncFifo.scala 169:20]
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
module McrcGen_6(
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
module McrcGen_7(
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
module MMasterRxLinkLayer(
  input         clock,
  input         reset,
  input         io_rxPhy2LLIO_flit_valid,
  input  [7:0]  io_rxPhy2LLIO_flit_bits,
  input         io_rxPhy2LLIO_creditARW_free,
  input         io_rxPhy2LLIO_replayPkgID,
  output        io_outAXI4R_valid,
  output [71:0] io_outAXI4R_bits,
  output        io_outAXI4B_valid,
  output [6:0]  io_outAXI4B_bits,
  output [2:0]  io_rxDebugState,
  output [3:0]  io_rxDebugLastCorrectPkgID,
  output        io_rx2TxCreditARWFree_valid,
  output [2:0]  io_rx2TxCreditARWFree_bits,
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
`endif // RANDOMIZE_REG_INIT
  wire [18:0] crcGene_crcgen_io_in; // @[crcGen.scala 99:24]
  wire [15:0] crcGene_crcgen_io_out; // @[crcGen.scala 99:24]
  wire [83:0] crcGene_crcgen_1_io_in; // @[crcGen.scala 99:24]
  wire [15:0] crcGene_crcgen_1_io_out; // @[crcGen.scala 99:24]
  reg [7:0] rxFlitBitReg; // @[DataLinkLayer.scala 490:29]
  reg  rxFlitValidReg; // @[DataLinkLayer.scala 492:31]
  reg  outRValid; // @[DataLinkLayer.scala 495:26]
  reg [95:0] outRData; // @[DataLinkLayer.scala 496:25]
  reg [95:0] outRDataShift; // @[DataLinkLayer.scala 497:30]
  reg  outBValid; // @[DataLinkLayer.scala 499:26]
  reg [31:0] outBData; // @[DataLinkLayer.scala 500:26]
  reg [31:0] outBDataShift; // @[DataLinkLayer.scala 501:31]
  reg [3:0] axi4RTCCnt; // @[DataLinkLayer.scala 504:28]
  reg [2:0] axi4BTCCnt; // @[DataLinkLayer.scala 505:28]
  reg [3:0] errorTCCnt; // @[DataLinkLayer.scala 512:28]
  reg [1:0] state; // @[DataLinkLayer.scala 518:22]
  wire [2:0] _axi4BTCCnt_T_1 = axi4BTCCnt + 3'h1; // @[DataLinkLayer.scala 561:34]
  wire [2:0] _state_T_1 = 3'h4 - 3'h1; // @[DataLinkLayer.scala 562:64]
  wire  _state_T_2 = axi4BTCCnt < _state_T_1; // @[DataLinkLayer.scala 562:33]
  wire [31:0] _outBData_T = outBData & outBDataShift; // @[DataLinkLayer.scala 564:30]
  wire [5:0] _outBData_T_1 = {axi4BTCCnt, 3'h0}; // @[DataLinkLayer.scala 564:77]
  wire [70:0] _GEN_62 = {{63'd0}, rxFlitBitReg}; // @[DataLinkLayer.scala 564:62]
  wire [70:0] _outBData_T_2 = _GEN_62 << _outBData_T_1; // @[DataLinkLayer.scala 564:62]
  wire [70:0] _GEN_60 = {{39'd0}, _outBData_T}; // @[DataLinkLayer.scala 564:46]
  wire [70:0] _outBData_T_3 = _GEN_60 | _outBData_T_2; // @[DataLinkLayer.scala 564:46]
  wire [31:0] _outBDataShift_T_4 = {outBDataShift[23:0],outBDataShift[31:24]}; // @[Cat.scala 33:92]
  wire [3:0] _axi4RTCCnt_T_1 = axi4RTCCnt + 4'h1; // @[DataLinkLayer.scala 570:34]
  wire [3:0] _state_T_5 = 4'hc - 4'h1; // @[DataLinkLayer.scala 571:64]
  wire  _state_T_6 = axi4RTCCnt < _state_T_5; // @[DataLinkLayer.scala 571:33]
  wire [95:0] _outRData_T = outRData & outRDataShift; // @[DataLinkLayer.scala 573:30]
  wire [6:0] _outRData_T_1 = {axi4RTCCnt, 3'h0}; // @[DataLinkLayer.scala 573:77]
  wire [134:0] _GEN_63 = {{127'd0}, rxFlitBitReg}; // @[DataLinkLayer.scala 573:62]
  wire [134:0] _outRData_T_2 = _GEN_63 << _outRData_T_1; // @[DataLinkLayer.scala 573:62]
  wire [134:0] _GEN_61 = {{39'd0}, _outRData_T}; // @[DataLinkLayer.scala 573:46]
  wire [134:0] _outRData_T_3 = _GEN_61 | _outRData_T_2; // @[DataLinkLayer.scala 573:46]
  wire [95:0] _outRDataShift_T_4 = {outRDataShift[87:0],outRDataShift[95:88]}; // @[Cat.scala 33:92]
  wire [3:0] _errorTCCnt_T_1 = errorTCCnt + 4'h1; // @[DataLinkLayer.scala 579:32]
  wire  _state_T_10 = errorTCCnt < _state_T_5; // @[DataLinkLayer.scala 580:31]
  wire [1:0] _state_T_11 = errorTCCnt < _state_T_5 ? 2'h3 : 2'h0; // @[DataLinkLayer.scala 580:19]
  wire  _outRValid_T_7 = _state_T_10 ? 1'h0 : 1'h1; // @[DataLinkLayer.scala 582:25]
  wire [134:0] _GEN_15 = 2'h2 == state ? _outRData_T_3 : {{39'd0}, outRData}; // @[DataLinkLayer.scala 520:17 573:18 496:25]
  wire [70:0] _GEN_21 = 2'h1 == state ? _outBData_T_3 : {{39'd0}, outBData}; // @[DataLinkLayer.scala 520:17 564:18 500:26]
  wire [134:0] _GEN_25 = 2'h1 == state ? {{39'd0}, outRData} : _GEN_15; // @[DataLinkLayer.scala 520:17 496:25]
  wire [134:0] _GEN_28 = 2'h0 == state ? 135'h0 : _GEN_25; // @[DataLinkLayer.scala 520:17 522:16]
  wire [70:0] _GEN_31 = 2'h0 == state ? 71'h0 : _GEN_21; // @[DataLinkLayer.scala 520:17 525:16]
  reg [3:0] lastCorrectPkgID; // @[DataLinkLayer.scala 591:33]
  wire [15:0] _crcOut_T_2 = outRValid ? outRData[87:72] : 16'h0; // @[DataLinkLayer.scala 616:8]
  wire [15:0] crcOut = outBValid ? outBData[22:7] : _crcOut_T_2; // @[DataLinkLayer.scala 615:16]
  wire [15:0] _crcGene_T_4 = outRValid ? crcGene_crcgen_1_io_out : 16'h0; // @[DataLinkLayer.scala 619:8]
  wire [15:0] crcGene = outBValid ? crcGene_crcgen_io_out : _crcGene_T_4; // @[DataLinkLayer.scala 618:17]
  wire  _crcCorrect_T = crcOut == crcGene; // @[DataLinkLayer.scala 621:39]
  wire  _crcCorrect_T_2 = outRValid & _crcCorrect_T; // @[DataLinkLayer.scala 622:8]
  wire  crcCorrect = outBValid ? crcOut == crcGene : _crcCorrect_T_2; // @[DataLinkLayer.scala 621:20]
  wire  dataOutValid = outBValid | outRValid; // @[DataLinkLayer.scala 613:29]
  wire [3:0] _pkgIdOut_T_2 = outRValid ? outRData[91:88] : lastCorrectPkgID; // @[DataLinkLayer.scala 625:8]
  wire [3:0] pkgIdOut = outBValid ? outBData[26:23] : _pkgIdOut_T_2; // @[DataLinkLayer.scala 624:18]
  wire [3:0] _pkgIdCorrect_T_1 = lastCorrectPkgID + 4'h1; // @[DataLinkLayer.scala 627:67]
  wire  pkgIdCorrect = dataOutValid & pkgIdOut == _pkgIdCorrect_T_1; // @[DataLinkLayer.scala 627:33]
  wire  dataCorrect = crcCorrect & pkgIdCorrect; // @[DataLinkLayer.scala 629:30]
  wire [11:0] crcGene_hi = {8'hcd,pkgIdOut}; // @[Cat.scala 33:92]
  wire [11:0] crcGene_hi_1 = {8'h12,pkgIdOut}; // @[Cat.scala 33:92]
  wire  _T_16 = dataOutValid & ~dataCorrect; // @[DataLinkLayer.scala 635:27]
  wire [3:0] _GEN_40 = dataOutValid & ~dataCorrect ? lastCorrectPkgID : 4'h0; // @[DataLinkLayer.scala 635:43 638:31 642:31]
  reg  txReplayPkgIdReg; // @[DataLinkLayer.scala 646:33]
  reg  txCreditARW_freeReg; // @[DataLinkLayer.scala 648:36]
  reg [2:0] rx2TxCreditARW_freeReg; // @[DataLinkLayer.scala 652:39]
  reg  rx2TxCreditARW_freeValid; // @[DataLinkLayer.scala 653:41]
  reg [1:0] rx2TxCreditARW_freeCnt; // @[DataLinkLayer.scala 655:39]
  wire  _T_17 = rx2TxCreditARW_freeCnt == 2'h0; // @[DataLinkLayer.scala 657:54]
  wire  _T_21 = rx2TxCreditARW_freeCnt == 2'h3; // @[DataLinkLayer.scala 666:37]
  wire [2:0] _rx2TxCreditARW_freeReg_T_1 = {txCreditARW_freeReg,rx2TxCreditARW_freeReg[2:1]}; // @[Cat.scala 33:92]
  reg [3:0] rx2TxReplayPkgIDReg; // @[DataLinkLayer.scala 684:37]
  reg  rx2TxReplayPkgIDRegValid; // @[DataLinkLayer.scala 686:41]
  reg [2:0] rx2TxReplayPkgIDCnt; // @[DataLinkLayer.scala 688:36]
  wire  _T_23 = rx2TxReplayPkgIDCnt == 3'h0; // @[DataLinkLayer.scala 690:48]
  wire [2:0] _rx2TxReplayPkgIDCnt_T_1 = rx2TxReplayPkgIDCnt + 3'h1; // @[DataLinkLayer.scala 691:48]
  wire  _T_28 = rx2TxReplayPkgIDCnt == 3'h4; // @[DataLinkLayer.scala 696:34]
  wire [3:0] _rx2TxReplayPkgIDReg_T_1 = {txReplayPkgIdReg,rx2TxReplayPkgIDReg[3:1]}; // @[Cat.scala 33:92]
  McrcGen_6 crcGene_crcgen ( // @[crcGen.scala 99:24]
    .io_in(crcGene_crcgen_io_in),
    .io_out(crcGene_crcgen_io_out)
  );
  McrcGen_7 crcGene_crcgen_1 ( // @[crcGen.scala 99:24]
    .io_in(crcGene_crcgen_1_io_in),
    .io_out(crcGene_crcgen_1_io_out)
  );
  assign io_outAXI4R_valid = outRValid & dataCorrect; // @[DataLinkLayer.scala 610:34]
  assign io_outAXI4R_bits = outRData[71:0]; // @[DataLinkLayer.scala 611:31]
  assign io_outAXI4B_valid = outBValid & dataCorrect; // @[DataLinkLayer.scala 607:34]
  assign io_outAXI4B_bits = outBData[6:0]; // @[DataLinkLayer.scala 608:31]
  assign io_rxDebugState = {{1'd0}, state}; // @[DataLinkLayer.scala 713:19]
  assign io_rxDebugLastCorrectPkgID = lastCorrectPkgID; // @[DataLinkLayer.scala 714:30]
  assign io_rx2TxCreditARWFree_valid = rx2TxCreditARW_freeValid; // @[DataLinkLayer.scala 680:31]
  assign io_rx2TxCreditARWFree_bits = rx2TxCreditARW_freeReg; // @[DataLinkLayer.scala 679:30]
  assign io_rx2TxPackageIDUsed_valid = rx2TxReplayPkgIDRegValid; // @[DataLinkLayer.scala 710:31]
  assign io_rx2TxPackageIDUsed_bits = rx2TxReplayPkgIDReg; // @[DataLinkLayer.scala 709:30]
  assign io_rx2TxPackageIDOut_valid = dataOutValid & dataCorrect | _T_16; // @[DataLinkLayer.scala 631:36 633:32]
  assign io_rx2TxPackageIDOut_bits = dataOutValid & dataCorrect ? pkgIdOut : _GEN_40; // @[DataLinkLayer.scala 631:36 634:31]
  assign crcGene_crcgen_io_in = {crcGene_hi,outBData[6:0]}; // @[Cat.scala 33:92]
  assign crcGene_crcgen_1_io_in = {crcGene_hi_1,outRData[71:0]}; // @[Cat.scala 33:92]
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 490:29]
      rxFlitBitReg <= 8'h0; // @[DataLinkLayer.scala 490:29]
    end else begin
      rxFlitBitReg <= io_rxPhy2LLIO_flit_bits; // @[DataLinkLayer.scala 491:16]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 492:31]
      rxFlitValidReg <= 1'h0; // @[DataLinkLayer.scala 492:31]
    end else begin
      rxFlitValidReg <= io_rxPhy2LLIO_flit_valid; // @[DataLinkLayer.scala 493:18]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      outRValid <= 1'h0; // @[DataLinkLayer.scala 523:17]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      outRValid <= 1'h0; // @[DataLinkLayer.scala 495:26]
    end else if (!(2'h1 == state)) begin // @[DataLinkLayer.scala 520:17]
      if (2'h2 == state) begin // @[DataLinkLayer.scala 520:17]
        if (_state_T_6) begin // @[DataLinkLayer.scala 582:19]
          outRValid <= 1'h0;
        end else begin
          outRValid <= 1'h1;
        end
      end else if (2'h3 == state) begin // @[DataLinkLayer.scala 495:26]
        outRValid <= _outRValid_T_7;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 496:25]
      outRData <= 96'h0; // @[DataLinkLayer.scala 496:25]
    end else begin
      outRData <= _GEN_28[95:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      outRDataShift <= 96'h0; // @[DataLinkLayer.scala 524:21]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      outRDataShift <= 96'hffffffffffffffffffffff00; // @[DataLinkLayer.scala 497:30]
    end else if (!(2'h1 == state)) begin // @[DataLinkLayer.scala 520:17]
      if (2'h2 == state) begin // @[DataLinkLayer.scala 497:30]
        outRDataShift <= _outRDataShift_T_4;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      outBValid <= 1'h0; // @[DataLinkLayer.scala 526:17]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      outBValid <= 1'h0; // @[DataLinkLayer.scala 563:25]
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 499:26]
      if (_state_T_2) begin
        outBValid <= 1'h0;
      end else begin
        outBValid <= 1'h1;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 500:26]
      outBData <= 32'h0; // @[DataLinkLayer.scala 500:26]
    end else begin
      outBData <= _GEN_31[31:0];
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      outBDataShift <= 32'h0; // @[DataLinkLayer.scala 528:23]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      outBDataShift <= 32'hffffff00; // @[DataLinkLayer.scala 565:23]
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 501:31]
      outBDataShift <= _outBDataShift_T_4;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      axi4RTCCnt <= 4'h0; // @[DataLinkLayer.scala 532:27 504:28 533:81 537:22 504:28 538:87 551:24]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 504:28]
        if (rxFlitBitReg == 8'h12) begin
          axi4RTCCnt <= 4'h0;
        end else if (!(rxFlitBitReg == 8'hcd)) begin
          axi4RTCCnt <= 4'h0;
        end
      end
    end else if (!(2'h1 == state)) begin // @[DataLinkLayer.scala 520:17]
      if (2'h2 == state) begin // @[DataLinkLayer.scala 504:28]
        axi4RTCCnt <= _axi4RTCCnt_T_1;
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      axi4BTCCnt <= 3'h0; // @[DataLinkLayer.scala 532:27 505:{28,28,28} 533:81 538:87 542:22]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 561:20]
        if (!(rxFlitBitReg == 8'h12)) begin
          if (rxFlitBitReg == 8'hcd) begin
            axi4BTCCnt <= 3'h0;
          end
        end
      end
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 505:28]
      axi4BTCCnt <= _axi4BTCCnt_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      errorTCCnt <= 4'h0; // @[DataLinkLayer.scala 512:28]
    end else if (!(2'h0 == state)) begin // @[DataLinkLayer.scala 520:17]
      if (!(2'h1 == state)) begin // @[DataLinkLayer.scala 520:17]
        if (!(2'h2 == state)) begin // @[DataLinkLayer.scala 520:17]
          if (2'h3 == state) begin // @[DataLinkLayer.scala 512:28]
            errorTCCnt <= _errorTCCnt_T_1;
          end
        end
      end
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 520:17]
      state <= 2'h0; // @[DataLinkLayer.scala 532:27 533:81 536:17 538:87 541:17 550:19 555:15]
    end else if (2'h0 == state) begin // @[DataLinkLayer.scala 520:17]
      if (rxFlitValidReg) begin // @[DataLinkLayer.scala 562:15]
        if (rxFlitBitReg == 8'h12) begin
          state <= 2'h2;
        end else if (rxFlitBitReg == 8'hcd) begin
          state <= 2'h1;
        end else begin
          state <= 2'h2;
        end
      end else begin
        state <= 2'h0;
      end
    end else if (2'h1 == state) begin // @[DataLinkLayer.scala 520:17]
      state <= {{1'd0}, axi4BTCCnt < _state_T_1}; // @[DataLinkLayer.scala 571:21]
    end else if (2'h2 == state) begin // @[DataLinkLayer.scala 520:17]
      if (axi4RTCCnt < _state_T_5) begin // @[DataLinkLayer.scala 580:13]
        state <= 2'h2;
      end else begin
        state <= 2'h0;
      end
    end else if (2'h3 == state) begin // @[DataLinkLayer.scala 518:22]
      state <= _state_T_11;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 631:36]
      lastCorrectPkgID <= 4'hf; // @[DataLinkLayer.scala 632:22]
    end else if (dataOutValid & dataCorrect) begin
      lastCorrectPkgID <= _pkgIdCorrect_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 646:33]
      txReplayPkgIdReg <= 1'h0; // @[DataLinkLayer.scala 646:33]
    end else begin
      txReplayPkgIdReg <= io_rxPhy2LLIO_replayPkgID; // @[DataLinkLayer.scala 647:20]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 648:36]
      txCreditARW_freeReg <= 1'h0; // @[DataLinkLayer.scala 648:36]
    end else begin
      txCreditARW_freeReg <= io_rxPhy2LLIO_creditARW_free; // @[DataLinkLayer.scala 649:23]
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 674:39]
      rx2TxCreditARW_freeReg <= 3'h0; // @[DataLinkLayer.scala 675:28]
    end else if (_T_17) begin // @[DataLinkLayer.scala 677:28]
      rx2TxCreditARW_freeReg <= 3'h0;
    end else begin
      rx2TxCreditARW_freeReg <= _rx2TxCreditARW_freeReg_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 657:62]
      rx2TxCreditARW_freeValid <= 1'h0; // @[DataLinkLayer.scala 659:30]
    end else if (txCreditARW_freeReg & rx2TxCreditARW_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 660:45]
      rx2TxCreditARW_freeValid <= 1'h0; // @[DataLinkLayer.scala 662:30]
    end else if (rx2TxCreditARW_freeCnt == 2'h1) begin // @[DataLinkLayer.scala 663:45]
      rx2TxCreditARW_freeValid <= 1'h0; // @[DataLinkLayer.scala 665:30]
    end else if (rx2TxCreditARW_freeCnt == 2'h2) begin
      rx2TxCreditARW_freeValid <= 1'h0;
    end else begin
      rx2TxCreditARW_freeValid <= _T_21;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 657:62]
      rx2TxCreditARW_freeCnt <= 2'h0; // @[DataLinkLayer.scala 658:28]
    end else if (txCreditARW_freeReg & rx2TxCreditARW_freeCnt == 2'h0) begin // @[DataLinkLayer.scala 660:45]
      rx2TxCreditARW_freeCnt <= 2'h1; // @[DataLinkLayer.scala 661:28]
    end else if (rx2TxCreditARW_freeCnt == 2'h1) begin // @[DataLinkLayer.scala 663:45]
      rx2TxCreditARW_freeCnt <= 2'h2; // @[DataLinkLayer.scala 664:28]
    end else if (rx2TxCreditARW_freeCnt == 2'h2) begin
      rx2TxCreditARW_freeCnt <= 2'h3;
    end else begin
      rx2TxCreditARW_freeCnt <= 2'h0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 704:36]
      rx2TxReplayPkgIDReg <= 4'h0; // @[DataLinkLayer.scala 705:25]
    end else if (_T_23) begin // @[DataLinkLayer.scala 707:25]
      rx2TxReplayPkgIDReg <= 4'h0;
    end else begin
      rx2TxReplayPkgIDReg <= _rx2TxReplayPkgIDReg_T_1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 690:56]
      rx2TxReplayPkgIDRegValid <= 1'h0; // @[DataLinkLayer.scala 692:30]
    end else if (txReplayPkgIdReg & rx2TxReplayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 693:93]
      rx2TxReplayPkgIDRegValid <= 1'h0; // @[DataLinkLayer.scala 695:30]
    end else if (rx2TxReplayPkgIDCnt > 3'h0 & rx2TxReplayPkgIDCnt < 3'h4) begin
      rx2TxReplayPkgIDRegValid <= 1'h0;
    end else begin
      rx2TxReplayPkgIDRegValid <= _T_28;
    end
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin // @[DataLinkLayer.scala 690:56]
      rx2TxReplayPkgIDCnt <= 3'h0; // @[DataLinkLayer.scala 691:25]
    end else if (txReplayPkgIdReg & rx2TxReplayPkgIDCnt == 3'h0) begin // @[DataLinkLayer.scala 693:93]
      rx2TxReplayPkgIDCnt <= _rx2TxReplayPkgIDCnt_T_1; // @[DataLinkLayer.scala 694:25]
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
  rxFlitBitReg = _RAND_0[7:0];
  _RAND_1 = {1{`RANDOM}};
  rxFlitValidReg = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  outRValid = _RAND_2[0:0];
  _RAND_3 = {3{`RANDOM}};
  outRData = _RAND_3[95:0];
  _RAND_4 = {3{`RANDOM}};
  outRDataShift = _RAND_4[95:0];
  _RAND_5 = {1{`RANDOM}};
  outBValid = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  outBData = _RAND_6[31:0];
  _RAND_7 = {1{`RANDOM}};
  outBDataShift = _RAND_7[31:0];
  _RAND_8 = {1{`RANDOM}};
  axi4RTCCnt = _RAND_8[3:0];
  _RAND_9 = {1{`RANDOM}};
  axi4BTCCnt = _RAND_9[2:0];
  _RAND_10 = {1{`RANDOM}};
  errorTCCnt = _RAND_10[3:0];
  _RAND_11 = {1{`RANDOM}};
  state = _RAND_11[1:0];
  _RAND_12 = {1{`RANDOM}};
  lastCorrectPkgID = _RAND_12[3:0];
  _RAND_13 = {1{`RANDOM}};
  txReplayPkgIdReg = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  txCreditARW_freeReg = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  rx2TxCreditARW_freeReg = _RAND_15[2:0];
  _RAND_16 = {1{`RANDOM}};
  rx2TxCreditARW_freeValid = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  rx2TxCreditARW_freeCnt = _RAND_17[1:0];
  _RAND_18 = {1{`RANDOM}};
  rx2TxReplayPkgIDReg = _RAND_18[3:0];
  _RAND_19 = {1{`RANDOM}};
  rx2TxReplayPkgIDRegValid = _RAND_19[0:0];
  _RAND_20 = {1{`RANDOM}};
  rx2TxReplayPkgIDCnt = _RAND_20[2:0];
`endif // RANDOMIZE_REG_INIT
  if (reset) begin
    rxFlitBitReg = 8'h0;
  end
  if (reset) begin
    rxFlitValidReg = 1'h0;
  end
  if (reset) begin
    outRValid = 1'h0;
  end
  if (reset) begin
    outRData = 96'h0;
  end
  if (reset) begin
    outRDataShift = 96'h0;
  end
  if (reset) begin
    outBValid = 1'h0;
  end
  if (reset) begin
    outBData = 32'h0;
  end
  if (reset) begin
    outBDataShift = 32'h0;
  end
  if (reset) begin
    axi4RTCCnt = 4'h0;
  end
  if (reset) begin
    axi4BTCCnt = 3'h0;
  end
  if (reset) begin
    errorTCCnt = 4'h0;
  end
  if (reset) begin
    state = 2'h0;
  end
  if (reset) begin
    lastCorrectPkgID = 4'hf;
  end
  if (reset) begin
    txReplayPkgIdReg = 1'h0;
  end
  if (reset) begin
    txCreditARW_freeReg = 1'h0;
  end
  if (reset) begin
    rx2TxCreditARW_freeReg = 3'h0;
  end
  if (reset) begin
    rx2TxCreditARW_freeValid = 1'h0;
  end
  if (reset) begin
    rx2TxCreditARW_freeCnt = 2'h0;
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
module MMasterRxPhy(
  output       io_rxPhy2LLIO_flit_valid,
  output [7:0] io_rxPhy2LLIO_flit_bits,
  output       io_rxPhy2LLIO_creditARW_free,
  output       io_rxPhy2LLIO_replayPkgID,
  input        io_rxPhyIO_flit_valid,
  input  [7:0] io_rxPhyIO_flit_bits,
  input        io_rxPhyIO_creditARW_free,
  input        io_rxPhyIO_replayPkgID
);
  assign io_rxPhy2LLIO_flit_valid = io_rxPhyIO_flit_valid; // @[Phy.scala 22:22]
  assign io_rxPhy2LLIO_flit_bits = io_rxPhyIO_flit_bits; // @[Phy.scala 22:22]
  assign io_rxPhy2LLIO_creditARW_free = io_rxPhyIO_creditARW_free; // @[Phy.scala 24:32]
  assign io_rxPhy2LLIO_replayPkgID = io_rxPhyIO_replayPkgID; // @[Phy.scala 25:29]
endmodule
module MskidBuffer(
  input         clock,
  input         reset,
  output        io_i_data_ready,
  input         io_i_data_valid,
  input  [71:0] io_i_data_bits,
  input         io_o_data_ready,
  output        io_o_data_valid,
  output [71:0] io_o_data_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [95:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [95:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg  r_valid; // @[skidBuffer.scala 15:24]
  reg [71:0] r_data; // @[skidBuffer.scala 16:23]
  wire  _T = io_i_data_ready & io_i_data_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = io_o_data_ready ? 1'h0 : r_valid; // @[skidBuffer.scala 20:30 21:13 23:13]
  wire  _GEN_1 = _T & (io_o_data_valid & ~io_o_data_ready) | _GEN_0; // @[skidBuffer.scala 18:64 19:13]
  wire  _T_5 = ~io_o_data_valid | io_o_data_ready; // @[skidBuffer.scala 26:45]
  reg  ro_valid; // @[skidBuffer.scala 47:27]
  reg [71:0] ro_data; // @[skidBuffer.scala 48:26]
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
      r_data <= 72'h0; // @[skidBuffer.scala 16:23]
    end else if (~io_o_data_valid | io_o_data_ready) begin // @[skidBuffer.scala 26:65]
      r_data <= 72'h0; // @[skidBuffer.scala 27:12]
    end else if (io_i_data_valid & io_i_data_ready) begin // @[skidBuffer.scala 28:89]
      r_data <= io_i_data_bits; // @[skidBuffer.scala 29:12]
    end
    if (reset) begin // @[skidBuffer.scala 47:27]
      ro_valid <= 1'h0; // @[skidBuffer.scala 47:27]
    end else if (_T_5) begin // @[skidBuffer.scala 49:46]
      ro_valid <= io_i_data_valid | r_valid; // @[skidBuffer.scala 50:16]
    end
    if (reset) begin // @[skidBuffer.scala 48:26]
      ro_data <= 72'h0; // @[skidBuffer.scala 48:26]
    end else if (_T_5) begin // @[skidBuffer.scala 55:46]
      if (r_valid) begin // @[skidBuffer.scala 56:21]
        ro_data <= r_data; // @[skidBuffer.scala 57:17]
      end else if (io_i_data_valid) begin // @[skidBuffer.scala 58:55]
        ro_data <= io_i_data_bits; // @[skidBuffer.scala 59:17]
      end else begin
        ro_data <= 72'h0; // @[skidBuffer.scala 61:17]
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
  r_data = _RAND_1[71:0];
  _RAND_2 = {1{`RANDOM}};
  ro_valid = _RAND_2[0:0];
  _RAND_3 = {3{`RANDOM}};
  ro_data = _RAND_3[71:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module MskidBuffer_1(
  input        clock,
  input        reset,
  output       io_i_data_ready,
  input        io_i_data_valid,
  input  [6:0] io_i_data_bits,
  input        io_o_data_ready,
  output       io_o_data_valid,
  output [6:0] io_o_data_bits
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg  r_valid; // @[skidBuffer.scala 15:24]
  reg [6:0] r_data; // @[skidBuffer.scala 16:23]
  wire  _T = io_i_data_ready & io_i_data_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = io_o_data_ready ? 1'h0 : r_valid; // @[skidBuffer.scala 20:30 21:13 23:13]
  wire  _GEN_1 = _T & (io_o_data_valid & ~io_o_data_ready) | _GEN_0; // @[skidBuffer.scala 18:64 19:13]
  wire  _T_5 = ~io_o_data_valid | io_o_data_ready; // @[skidBuffer.scala 26:45]
  reg  ro_valid; // @[skidBuffer.scala 47:27]
  reg [6:0] ro_data; // @[skidBuffer.scala 48:26]
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
      r_data <= 7'h0; // @[skidBuffer.scala 16:23]
    end else if (~io_o_data_valid | io_o_data_ready) begin // @[skidBuffer.scala 26:65]
      r_data <= 7'h0; // @[skidBuffer.scala 27:12]
    end else if (io_i_data_valid & io_i_data_ready) begin // @[skidBuffer.scala 28:89]
      r_data <= io_i_data_bits; // @[skidBuffer.scala 29:12]
    end
    if (reset) begin // @[skidBuffer.scala 47:27]
      ro_valid <= 1'h0; // @[skidBuffer.scala 47:27]
    end else if (_T_5) begin // @[skidBuffer.scala 49:46]
      ro_valid <= io_i_data_valid | r_valid; // @[skidBuffer.scala 50:16]
    end
    if (reset) begin // @[skidBuffer.scala 48:26]
      ro_data <= 7'h0; // @[skidBuffer.scala 48:26]
    end else if (_T_5) begin // @[skidBuffer.scala 55:46]
      if (r_valid) begin // @[skidBuffer.scala 56:21]
        ro_data <= r_data; // @[skidBuffer.scala 57:17]
      end else if (io_i_data_valid) begin // @[skidBuffer.scala 58:55]
        ro_data <= io_i_data_bits; // @[skidBuffer.scala 59:17]
      end else begin
        ro_data <= 7'h0; // @[skidBuffer.scala 61:17]
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
  _RAND_1 = {1{`RANDOM}};
  r_data = _RAND_1[6:0];
  _RAND_2 = {1{`RANDOM}};
  ro_valid = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  ro_data = _RAND_3[6:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module MMasterRxAppLayer(
  input         clock,
  input         reset,
  output        io_appInAXI4R_ready,
  input         io_appInAXI4R_valid,
  input  [71:0] io_appInAXI4R_bits,
  output        io_appInAXI4B_ready,
  input         io_appInAXI4B_valid,
  input  [6:0]  io_appInAXI4B_bits,
  input         io_appOutAXI4R_ready,
  output        io_appOutAXI4R_valid,
  output [63:0] io_appOutAXI4R_bits_data,
  output        io_appOutAXI4R_bits_last,
  output [4:0]  io_appOutAXI4R_bits_id,
  output [1:0]  io_appOutAXI4R_bits_resp,
  input         io_appOutAXI4B_ready,
  output        io_appOutAXI4B_valid,
  output [4:0]  io_appOutAXI4B_bits_id,
  output [1:0]  io_appOutAXI4B_bits_resp
);
  wire  skidBufferR_clock; // @[AppLayer.scala 92:27]
  wire  skidBufferR_reset; // @[AppLayer.scala 92:27]
  wire  skidBufferR_io_i_data_ready; // @[AppLayer.scala 92:27]
  wire  skidBufferR_io_i_data_valid; // @[AppLayer.scala 92:27]
  wire [71:0] skidBufferR_io_i_data_bits; // @[AppLayer.scala 92:27]
  wire  skidBufferR_io_o_data_ready; // @[AppLayer.scala 92:27]
  wire  skidBufferR_io_o_data_valid; // @[AppLayer.scala 92:27]
  wire [71:0] skidBufferR_io_o_data_bits; // @[AppLayer.scala 92:27]
  wire  skidBufferB_clock; // @[AppLayer.scala 111:27]
  wire  skidBufferB_reset; // @[AppLayer.scala 111:27]
  wire  skidBufferB_io_i_data_ready; // @[AppLayer.scala 111:27]
  wire  skidBufferB_io_i_data_valid; // @[AppLayer.scala 111:27]
  wire [6:0] skidBufferB_io_i_data_bits; // @[AppLayer.scala 111:27]
  wire  skidBufferB_io_o_data_ready; // @[AppLayer.scala 111:27]
  wire  skidBufferB_io_o_data_valid; // @[AppLayer.scala 111:27]
  wire [6:0] skidBufferB_io_o_data_bits; // @[AppLayer.scala 111:27]
  wire  _skidBufferR_io_i_data_bits_T_3 = io_appInAXI4R_valid & io_appInAXI4R_bits[64]; // @[AppLayer.scala 96:8]
  wire [64:0] skidBufferR_io_i_data_bits_lo = {_skidBufferR_io_i_data_bits_T_3,io_appInAXI4R_bits[63:0]}; // @[Cat.scala 33:92]
  wire [6:0] skidBufferR_io_i_data_bits_hi = {io_appInAXI4R_bits[71:67],io_appInAXI4R_bits[66:65]}; // @[Cat.scala 33:92]
  MskidBuffer skidBufferR ( // @[AppLayer.scala 92:27]
    .clock(skidBufferR_clock),
    .reset(skidBufferR_reset),
    .io_i_data_ready(skidBufferR_io_i_data_ready),
    .io_i_data_valid(skidBufferR_io_i_data_valid),
    .io_i_data_bits(skidBufferR_io_i_data_bits),
    .io_o_data_ready(skidBufferR_io_o_data_ready),
    .io_o_data_valid(skidBufferR_io_o_data_valid),
    .io_o_data_bits(skidBufferR_io_o_data_bits)
  );
  MskidBuffer_1 skidBufferB ( // @[AppLayer.scala 111:27]
    .clock(skidBufferB_clock),
    .reset(skidBufferB_reset),
    .io_i_data_ready(skidBufferB_io_i_data_ready),
    .io_i_data_valid(skidBufferB_io_i_data_valid),
    .io_i_data_bits(skidBufferB_io_i_data_bits),
    .io_o_data_ready(skidBufferB_io_o_data_ready),
    .io_o_data_valid(skidBufferB_io_o_data_valid),
    .io_o_data_bits(skidBufferB_io_o_data_bits)
  );
  assign io_appInAXI4R_ready = skidBufferR_io_i_data_ready; // @[AppLayer.scala 100:23]
  assign io_appInAXI4B_ready = skidBufferB_io_i_data_ready; // @[AppLayer.scala 114:23]
  assign io_appOutAXI4R_valid = skidBufferR_io_o_data_valid; // @[AppLayer.scala 102:24]
  assign io_appOutAXI4R_bits_data = skidBufferR_io_o_data_bits[63:0]; // @[AppLayer.scala 104:57]
  assign io_appOutAXI4R_bits_last = skidBufferR_io_o_data_bits[64]; // @[AppLayer.scala 105:57]
  assign io_appOutAXI4R_bits_id = skidBufferR_io_o_data_bits[71:67]; // @[AppLayer.scala 107:55]
  assign io_appOutAXI4R_bits_resp = skidBufferR_io_o_data_bits[66:65]; // @[AppLayer.scala 106:57]
  assign io_appOutAXI4B_valid = skidBufferB_io_o_data_valid; // @[AppLayer.scala 116:24]
  assign io_appOutAXI4B_bits_id = skidBufferB_io_o_data_bits[6:2]; // @[AppLayer.scala 119:55]
  assign io_appOutAXI4B_bits_resp = skidBufferB_io_o_data_bits[1:0]; // @[AppLayer.scala 118:57]
  assign skidBufferR_clock = clock;
  assign skidBufferR_reset = reset;
  assign skidBufferR_io_i_data_valid = io_appInAXI4R_valid; // @[AppLayer.scala 99:31]
  assign skidBufferR_io_i_data_bits = {skidBufferR_io_i_data_bits_hi,skidBufferR_io_i_data_bits_lo}; // @[Cat.scala 33:92]
  assign skidBufferR_io_o_data_ready = io_appOutAXI4R_ready; // @[AppLayer.scala 103:31]
  assign skidBufferB_clock = clock;
  assign skidBufferB_reset = reset;
  assign skidBufferB_io_i_data_valid = io_appInAXI4B_valid; // @[AppLayer.scala 113:31]
  assign skidBufferB_io_i_data_bits = io_appInAXI4B_bits; // @[AppLayer.scala 112:30]
  assign skidBufferB_io_o_data_ready = io_appOutAXI4B_ready; // @[AppLayer.scala 117:31]
endmodule
module Md2dMasterRx(
  input         clock,
  input         reset,
  input         io_outAXI4R_ready,
  output        io_outAXI4R_valid,
  output [63:0] io_outAXI4R_bits_data,
  output        io_outAXI4R_bits_last,
  output [4:0]  io_outAXI4R_bits_id,
  output [1:0]  io_outAXI4R_bits_resp,
  input         io_outAXI4B_ready,
  output        io_outAXI4B_valid,
  output [4:0]  io_outAXI4B_bits_id,
  output [1:0]  io_outAXI4B_bits_resp,
  input         io_rx_clock,
  input         io_rx_flit_valid,
  input  [7:0]  io_rx_flit_bits,
  input         io_rx_creditARW_free,
  input         io_rx_replayPkgID,
  output [2:0]  io_rxDebugState,
  output [3:0]  io_rxDebugLastCorrectPkgID,
  output        io_rx2TxCreditARWFree_valid,
  output [2:0]  io_rx2TxCreditARWFree_bits,
  output        io_rx2TxPackageIDUsed_valid,
  output [3:0]  io_rx2TxPackageIDUsed_bits,
  output        io_rx2TxCreditRBFree_valid,
  output [1:0]  io_rx2TxCreditRBFree_bits,
  output        io_rx2TxPackageIDOut_valid,
  output [3:0]  io_rx2TxPackageIDOut_bits
);
  wire  rstRxSync_clock; // @[D2dMasterRx.scala 20:25]
  wire  rstRxSync_reset_in; // @[D2dMasterRx.scala 20:25]
  wire  rstRxSync_reset_out; // @[D2dMasterRx.scala 20:25]
  wire  asyncQR_wr_clock; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_wr_reset; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_wr_valid; // @[D2dMasterRx.scala 25:23]
  wire [71:0] asyncQR_wr_bits; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_rd_clock; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_rd_reset; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_rd_ready; // @[D2dMasterRx.scala 25:23]
  wire  asyncQR_rd_valid; // @[D2dMasterRx.scala 25:23]
  wire [71:0] asyncQR_rd_bits; // @[D2dMasterRx.scala 25:23]
  wire  asyncQB_wr_clock; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_wr_reset; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_wr_valid; // @[D2dMasterRx.scala 31:23]
  wire [6:0] asyncQB_wr_bits; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_rd_clock; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_rd_reset; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_rd_ready; // @[D2dMasterRx.scala 31:23]
  wire  asyncQB_rd_valid; // @[D2dMasterRx.scala 31:23]
  wire [6:0] asyncQB_rd_bits; // @[D2dMasterRx.scala 31:23]
  wire  masterRxLinkLayer_clock; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_reset; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rxPhy2LLIO_flit_valid; // @[D2dMasterRx.scala 42:35]
  wire [7:0] masterRxLinkLayer_io_rxPhy2LLIO_flit_bits; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rxPhy2LLIO_creditARW_free; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rxPhy2LLIO_replayPkgID; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_outAXI4R_valid; // @[D2dMasterRx.scala 42:35]
  wire [71:0] masterRxLinkLayer_io_outAXI4R_bits; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_outAXI4B_valid; // @[D2dMasterRx.scala 42:35]
  wire [6:0] masterRxLinkLayer_io_outAXI4B_bits; // @[D2dMasterRx.scala 42:35]
  wire [2:0] masterRxLinkLayer_io_rxDebugState; // @[D2dMasterRx.scala 42:35]
  wire [3:0] masterRxLinkLayer_io_rxDebugLastCorrectPkgID; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rx2TxCreditARWFree_valid; // @[D2dMasterRx.scala 42:35]
  wire [2:0] masterRxLinkLayer_io_rx2TxCreditARWFree_bits; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dMasterRx.scala 42:35]
  wire [3:0] masterRxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dMasterRx.scala 42:35]
  wire  masterRxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dMasterRx.scala 42:35]
  wire [3:0] masterRxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dMasterRx.scala 42:35]
  wire  masterRxPhy_io_rxPhy2LLIO_flit_valid; // @[D2dMasterRx.scala 43:29]
  wire [7:0] masterRxPhy_io_rxPhy2LLIO_flit_bits; // @[D2dMasterRx.scala 43:29]
  wire  masterRxPhy_io_rxPhy2LLIO_creditARW_free; // @[D2dMasterRx.scala 43:29]
  wire  masterRxPhy_io_rxPhy2LLIO_replayPkgID; // @[D2dMasterRx.scala 43:29]
  wire  masterRxPhy_io_rxPhyIO_flit_valid; // @[D2dMasterRx.scala 43:29]
  wire [7:0] masterRxPhy_io_rxPhyIO_flit_bits; // @[D2dMasterRx.scala 43:29]
  wire  masterRxPhy_io_rxPhyIO_creditARW_free; // @[D2dMasterRx.scala 43:29]
  wire  masterRxPhy_io_rxPhyIO_replayPkgID; // @[D2dMasterRx.scala 43:29]
  wire  MasterRxNegSync_clock; // @[D2dMasterRx.scala 46:33]
  wire  MasterRxNegSync_reset; // @[D2dMasterRx.scala 46:33]
  wire [10:0] MasterRxNegSync_x; // @[D2dMasterRx.scala 46:33]
  wire [10:0] MasterRxNegSync_y; // @[D2dMasterRx.scala 46:33]
  wire  MasterRxAppLayer_clock; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_reset; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appInAXI4R_ready; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appInAXI4R_valid; // @[D2dMasterRx.scala 71:32]
  wire [71:0] MasterRxAppLayer_io_appInAXI4R_bits; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appInAXI4B_ready; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appInAXI4B_valid; // @[D2dMasterRx.scala 71:32]
  wire [6:0] MasterRxAppLayer_io_appInAXI4B_bits; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appOutAXI4R_ready; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appOutAXI4R_valid; // @[D2dMasterRx.scala 71:32]
  wire [63:0] MasterRxAppLayer_io_appOutAXI4R_bits_data; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appOutAXI4R_bits_last; // @[D2dMasterRx.scala 71:32]
  wire [4:0] MasterRxAppLayer_io_appOutAXI4R_bits_id; // @[D2dMasterRx.scala 71:32]
  wire [1:0] MasterRxAppLayer_io_appOutAXI4R_bits_resp; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appOutAXI4B_ready; // @[D2dMasterRx.scala 71:32]
  wire  MasterRxAppLayer_io_appOutAXI4B_valid; // @[D2dMasterRx.scala 71:32]
  wire [4:0] MasterRxAppLayer_io_appOutAXI4B_bits_id; // @[D2dMasterRx.scala 71:32]
  wire [1:0] MasterRxAppLayer_io_appOutAXI4B_bits_resp; // @[D2dMasterRx.scala 71:32]
  wire  _io_rx2TxCreditRBFree_valid_T = asyncQR_rd_ready & asyncQR_rd_valid; // @[Decoupled.scala 52:35]
  wire  _io_rx2TxCreditRBFree_valid_T_1 = asyncQB_rd_ready & asyncQB_rd_valid; // @[Decoupled.scala 52:35]
  wire [1:0] _io_rx2TxCreditRBFree_valid_T_2 = {_io_rx2TxCreditRBFree_valid_T,_io_rx2TxCreditRBFree_valid_T_1}; // @[Cat.scala 33:92]
  wire [1:0] MasterRxNegSync_io_x_lo = {io_rx_creditARW_free,io_rx_replayPkgID}; // @[Cat.scala 33:92]
  wire [8:0] MasterRxNegSync_io_x_hi = {io_rx_flit_valid,io_rx_flit_bits}; // @[Cat.scala 33:92]
  ResetSync_d2d rstRxSync ( // @[D2dMasterRx.scala 20:25]
    .clock(rstRxSync_clock),
    .reset_in(rstRxSync_reset_in),
    .reset_out(rstRxSync_reset_out)
  );
  MAsyncQueue_3 asyncQR ( // @[D2dMasterRx.scala 25:23]
    .wr_clock(asyncQR_wr_clock),
    .wr_reset(asyncQR_wr_reset),
    .wr_valid(asyncQR_wr_valid),
    .wr_bits(asyncQR_wr_bits),
    .rd_clock(asyncQR_rd_clock),
    .rd_reset(asyncQR_rd_reset),
    .rd_ready(asyncQR_rd_ready),
    .rd_valid(asyncQR_rd_valid),
    .rd_bits(asyncQR_rd_bits)
  );
  MAsyncQueue_4 asyncQB ( // @[D2dMasterRx.scala 31:23]
    .wr_clock(asyncQB_wr_clock),
    .wr_reset(asyncQB_wr_reset),
    .wr_valid(asyncQB_wr_valid),
    .wr_bits(asyncQB_wr_bits),
    .rd_clock(asyncQB_rd_clock),
    .rd_reset(asyncQB_rd_reset),
    .rd_ready(asyncQB_rd_ready),
    .rd_valid(asyncQB_rd_valid),
    .rd_bits(asyncQB_rd_bits)
  );
  MMasterRxLinkLayer masterRxLinkLayer ( // @[D2dMasterRx.scala 42:35]
    .clock(masterRxLinkLayer_clock),
    .reset(masterRxLinkLayer_reset),
    .io_rxPhy2LLIO_flit_valid(masterRxLinkLayer_io_rxPhy2LLIO_flit_valid),
    .io_rxPhy2LLIO_flit_bits(masterRxLinkLayer_io_rxPhy2LLIO_flit_bits),
    .io_rxPhy2LLIO_creditARW_free(masterRxLinkLayer_io_rxPhy2LLIO_creditARW_free),
    .io_rxPhy2LLIO_replayPkgID(masterRxLinkLayer_io_rxPhy2LLIO_replayPkgID),
    .io_outAXI4R_valid(masterRxLinkLayer_io_outAXI4R_valid),
    .io_outAXI4R_bits(masterRxLinkLayer_io_outAXI4R_bits),
    .io_outAXI4B_valid(masterRxLinkLayer_io_outAXI4B_valid),
    .io_outAXI4B_bits(masterRxLinkLayer_io_outAXI4B_bits),
    .io_rxDebugState(masterRxLinkLayer_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(masterRxLinkLayer_io_rxDebugLastCorrectPkgID),
    .io_rx2TxCreditARWFree_valid(masterRxLinkLayer_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(masterRxLinkLayer_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_valid(masterRxLinkLayer_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(masterRxLinkLayer_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxPackageIDOut_valid(masterRxLinkLayer_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(masterRxLinkLayer_io_rx2TxPackageIDOut_bits)
  );
  MMasterRxPhy masterRxPhy ( // @[D2dMasterRx.scala 43:29]
    .io_rxPhy2LLIO_flit_valid(masterRxPhy_io_rxPhy2LLIO_flit_valid),
    .io_rxPhy2LLIO_flit_bits(masterRxPhy_io_rxPhy2LLIO_flit_bits),
    .io_rxPhy2LLIO_creditARW_free(masterRxPhy_io_rxPhy2LLIO_creditARW_free),
    .io_rxPhy2LLIO_replayPkgID(masterRxPhy_io_rxPhy2LLIO_replayPkgID),
    .io_rxPhyIO_flit_valid(masterRxPhy_io_rxPhyIO_flit_valid),
    .io_rxPhyIO_flit_bits(masterRxPhy_io_rxPhyIO_flit_bits),
    .io_rxPhyIO_creditARW_free(masterRxPhy_io_rxPhyIO_creditARW_free),
    .io_rxPhyIO_replayPkgID(masterRxPhy_io_rxPhyIO_replayPkgID)
  );
  NegSync #(.DW(11)) MasterRxNegSync ( // @[D2dMasterRx.scala 46:33]
    .clock(MasterRxNegSync_clock),
    .reset(MasterRxNegSync_reset),
    .x(MasterRxNegSync_x),
    .y(MasterRxNegSync_y)
  );
  MMasterRxAppLayer MasterRxAppLayer ( // @[D2dMasterRx.scala 71:32]
    .clock(MasterRxAppLayer_clock),
    .reset(MasterRxAppLayer_reset),
    .io_appInAXI4R_ready(MasterRxAppLayer_io_appInAXI4R_ready),
    .io_appInAXI4R_valid(MasterRxAppLayer_io_appInAXI4R_valid),
    .io_appInAXI4R_bits(MasterRxAppLayer_io_appInAXI4R_bits),
    .io_appInAXI4B_ready(MasterRxAppLayer_io_appInAXI4B_ready),
    .io_appInAXI4B_valid(MasterRxAppLayer_io_appInAXI4B_valid),
    .io_appInAXI4B_bits(MasterRxAppLayer_io_appInAXI4B_bits),
    .io_appOutAXI4R_ready(MasterRxAppLayer_io_appOutAXI4R_ready),
    .io_appOutAXI4R_valid(MasterRxAppLayer_io_appOutAXI4R_valid),
    .io_appOutAXI4R_bits_data(MasterRxAppLayer_io_appOutAXI4R_bits_data),
    .io_appOutAXI4R_bits_last(MasterRxAppLayer_io_appOutAXI4R_bits_last),
    .io_appOutAXI4R_bits_id(MasterRxAppLayer_io_appOutAXI4R_bits_id),
    .io_appOutAXI4R_bits_resp(MasterRxAppLayer_io_appOutAXI4R_bits_resp),
    .io_appOutAXI4B_ready(MasterRxAppLayer_io_appOutAXI4B_ready),
    .io_appOutAXI4B_valid(MasterRxAppLayer_io_appOutAXI4B_valid),
    .io_appOutAXI4B_bits_id(MasterRxAppLayer_io_appOutAXI4B_bits_id),
    .io_appOutAXI4B_bits_resp(MasterRxAppLayer_io_appOutAXI4B_bits_resp)
  );
  assign io_outAXI4R_valid = MasterRxAppLayer_io_appOutAXI4R_valid; // @[D2dMasterRx.scala 78:15]
  assign io_outAXI4R_bits_data = MasterRxAppLayer_io_appOutAXI4R_bits_data; // @[D2dMasterRx.scala 78:15]
  assign io_outAXI4R_bits_last = MasterRxAppLayer_io_appOutAXI4R_bits_last; // @[D2dMasterRx.scala 78:15]
  assign io_outAXI4R_bits_id = MasterRxAppLayer_io_appOutAXI4R_bits_id; // @[D2dMasterRx.scala 78:15]
  assign io_outAXI4R_bits_resp = MasterRxAppLayer_io_appOutAXI4R_bits_resp; // @[D2dMasterRx.scala 78:15]
  assign io_outAXI4B_valid = MasterRxAppLayer_io_appOutAXI4B_valid; // @[D2dMasterRx.scala 79:15]
  assign io_outAXI4B_bits_id = MasterRxAppLayer_io_appOutAXI4B_bits_id; // @[D2dMasterRx.scala 79:15]
  assign io_outAXI4B_bits_resp = MasterRxAppLayer_io_appOutAXI4B_bits_resp; // @[D2dMasterRx.scala 79:15]
  assign io_rxDebugState = masterRxLinkLayer_io_rxDebugState; // @[D2dMasterRx.scala 64:21]
  assign io_rxDebugLastCorrectPkgID = masterRxLinkLayer_io_rxDebugLastCorrectPkgID; // @[D2dMasterRx.scala 65:32]
  assign io_rx2TxCreditARWFree_valid = masterRxLinkLayer_io_rx2TxCreditARWFree_valid; // @[D2dMasterRx.scala 62:27]
  assign io_rx2TxCreditARWFree_bits = masterRxLinkLayer_io_rx2TxCreditARWFree_bits; // @[D2dMasterRx.scala 62:27]
  assign io_rx2TxPackageIDUsed_valid = masterRxLinkLayer_io_rx2TxPackageIDUsed_valid; // @[D2dMasterRx.scala 61:27]
  assign io_rx2TxPackageIDUsed_bits = masterRxLinkLayer_io_rx2TxPackageIDUsed_bits; // @[D2dMasterRx.scala 61:27]
  assign io_rx2TxCreditRBFree_valid = _io_rx2TxCreditRBFree_valid_T_2 != 2'h0; // @[D2dMasterRx.scala 38:79]
  assign io_rx2TxCreditRBFree_bits = {_io_rx2TxCreditRBFree_valid_T,_io_rx2TxCreditRBFree_valid_T_1}; // @[Cat.scala 33:92]
  assign io_rx2TxPackageIDOut_valid = masterRxLinkLayer_io_rx2TxPackageIDOut_valid; // @[D2dMasterRx.scala 63:26]
  assign io_rx2TxPackageIDOut_bits = masterRxLinkLayer_io_rx2TxPackageIDOut_bits; // @[D2dMasterRx.scala 63:26]
  assign rstRxSync_clock = io_rx_clock; // @[D2dMasterRx.scala 21:22]
  assign rstRxSync_reset_in = reset; // @[D2dMasterRx.scala 22:46]
  assign asyncQR_wr_clock = io_rx_clock; // @[D2dMasterRx.scala 26:20]
  assign asyncQR_wr_reset = rstRxSync_reset_out; // @[D2dMasterRx.scala 27:20]
  assign asyncQR_wr_valid = masterRxLinkLayer_io_outAXI4R_valid; // @[D2dMasterRx.scala 67:16]
  assign asyncQR_wr_bits = masterRxLinkLayer_io_outAXI4R_bits; // @[D2dMasterRx.scala 67:16]
  assign asyncQR_rd_clock = clock; // @[D2dMasterRx.scala 28:20]
  assign asyncQR_rd_reset = reset; // @[D2dMasterRx.scala 29:41]
  assign asyncQR_rd_ready = MasterRxAppLayer_io_appInAXI4R_ready; // @[D2dMasterRx.scala 74:14]
  assign asyncQB_wr_clock = io_rx_clock; // @[D2dMasterRx.scala 32:20]
  assign asyncQB_wr_reset = rstRxSync_reset_out; // @[D2dMasterRx.scala 33:20]
  assign asyncQB_wr_valid = masterRxLinkLayer_io_outAXI4B_valid; // @[D2dMasterRx.scala 68:16]
  assign asyncQB_wr_bits = masterRxLinkLayer_io_outAXI4B_bits; // @[D2dMasterRx.scala 68:16]
  assign asyncQB_rd_clock = clock; // @[D2dMasterRx.scala 34:20]
  assign asyncQB_rd_reset = reset; // @[D2dMasterRx.scala 35:41]
  assign asyncQB_rd_ready = MasterRxAppLayer_io_appInAXI4B_ready; // @[D2dMasterRx.scala 76:14]
  assign masterRxLinkLayer_clock = io_rx_clock;
  assign masterRxLinkLayer_reset = rstRxSync_reset_out;
  assign masterRxLinkLayer_io_rxPhy2LLIO_flit_valid = masterRxPhy_io_rxPhy2LLIO_flit_valid; // @[D2dMasterRx.scala 58:37]
  assign masterRxLinkLayer_io_rxPhy2LLIO_flit_bits = masterRxPhy_io_rxPhy2LLIO_flit_bits; // @[D2dMasterRx.scala 58:37]
  assign masterRxLinkLayer_io_rxPhy2LLIO_creditARW_free = masterRxPhy_io_rxPhy2LLIO_creditARW_free; // @[D2dMasterRx.scala 58:37]
  assign masterRxLinkLayer_io_rxPhy2LLIO_replayPkgID = masterRxPhy_io_rxPhy2LLIO_replayPkgID; // @[D2dMasterRx.scala 58:37]
  assign masterRxPhy_io_rxPhyIO_flit_valid = MasterRxNegSync_y[10]; // @[D2dMasterRx.scala 51:62]
  assign masterRxPhy_io_rxPhyIO_flit_bits = MasterRxNegSync_y[9:2]; // @[D2dMasterRx.scala 52:62]
  assign masterRxPhy_io_rxPhyIO_creditARW_free = MasterRxNegSync_y[1]; // @[D2dMasterRx.scala 53:66]
  assign masterRxPhy_io_rxPhyIO_replayPkgID = MasterRxNegSync_y[0]; // @[D2dMasterRx.scala 54:64]
  assign MasterRxNegSync_clock = io_rx_clock; // @[D2dMasterRx.scala 47:30]
  assign MasterRxNegSync_reset = rstRxSync_reset_out; // @[D2dMasterRx.scala 48:30]
  assign MasterRxNegSync_x = {MasterRxNegSync_io_x_hi,MasterRxNegSync_io_x_lo}; // @[Cat.scala 33:92]
  assign MasterRxAppLayer_clock = clock;
  assign MasterRxAppLayer_reset = reset;
  assign MasterRxAppLayer_io_appInAXI4R_valid = asyncQR_rd_valid; // @[D2dMasterRx.scala 74:14]
  assign MasterRxAppLayer_io_appInAXI4R_bits = asyncQR_rd_bits; // @[D2dMasterRx.scala 74:14]
  assign MasterRxAppLayer_io_appInAXI4B_valid = asyncQB_rd_valid; // @[D2dMasterRx.scala 76:14]
  assign MasterRxAppLayer_io_appInAXI4B_bits = asyncQB_rd_bits; // @[D2dMasterRx.scala 76:14]
  assign MasterRxAppLayer_io_appOutAXI4R_ready = io_outAXI4R_ready; // @[D2dMasterRx.scala 78:15]
  assign MasterRxAppLayer_io_appOutAXI4B_ready = io_outAXI4B_ready; // @[D2dMasterRx.scala 79:15]
endmodule
module MAsyncFifoMemory_5(
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
module MAsyncFifo_5(
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
  MAsyncFifoMemory_5 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_5(
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
  MAsyncFifo_5 fifo ( // @[AsyncFifo.scala 169:20]
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
module MAsyncFifoMemory_6(
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
module MAsyncFifo_6(
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
  MAsyncFifoMemory_6 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_6(
  input        wr_clock,
  input        wr_reset,
  input        wr_valid,
  input  [2:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
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
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  MAsyncFifo_6 fifo ( // @[AsyncFifo.scala 169:20]
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
module MAsyncFifoMemory_7(
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
module MAsyncFifo_7(
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
  MAsyncFifoMemory_7 mem ( // @[AsyncFifo.scala 79:19]
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
module MAsyncQueue_7(
  input        wr_clock,
  input        wr_reset,
  input        wr_valid,
  input  [1:0] wr_bits,
  input        rd_clock,
  input        rd_reset,
  input        rd_ready,
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
  wire  _fifo_rd_pop_T_4 = rd_ready & rd_valid; // @[Decoupled.scala 52:35]
  wire  _GEN_0 = fifoRdValid | outValid; // @[AsyncFifo.scala 199:29 200:16 193:27]
  MAsyncFifo_7 fifo ( // @[AsyncFifo.scala 169:20]
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
module MD2dMasterCtrlRegIf(
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
  output [10:0] io_preAddrIn,
  output [11:0] io_inMasterReplayLatency,
  input  [31:0] io_txDebugReplayState,
  input  [31:0] io_txDebugReplayQueue,
  input  [31:0] io_txDebugReplayCnt,
  input  [2:0]  io_txDebugState,
  input  [2:0]  io_rxDebugState,
  input  [3:0]  io_rxDebugLastCorrectPkgID
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
  reg  ctrl_reg_WrEn; // @[D2dMasterRegIf.scala 19:30]
  reg [31:0] ctrl_reg_Wrdata; // @[D2dMasterRegIf.scala 20:32]
  reg  ctrl_aw_en; // @[D2dMasterRegIf.scala 21:27]
  reg [7:0] ctrl_awaddr; // @[D2dMasterRegIf.scala 23:29]
  reg  ctrl_awready; // @[D2dMasterRegIf.scala 24:29]
  reg  ctrl_wready; // @[D2dMasterRegIf.scala 25:29]
  reg  ctrl_bvalid; // @[D2dMasterRegIf.scala 27:29]
  reg [7:0] ctrl_araddr; // @[D2dMasterRegIf.scala 28:29]
  reg  ctrl_arready; // @[D2dMasterRegIf.scala 29:29]
  reg [31:0] ctrl_rdata; // @[D2dMasterRegIf.scala 30:29]
  reg  ctrl_rvalid; // @[D2dMasterRegIf.scala 32:28]
  wire  _T_3 = ~ctrl_awready & io_ctrlBusPorts_writeAddr_valid & io_ctrlBusPorts_writeData_valid & ctrl_aw_en; // @[D2dMasterRegIf.scala 47:92]
  wire  _T_4 = io_ctrlBusPorts_writeResp_ready & ctrl_bvalid; // @[D2dMasterRegIf.scala 51:46]
  wire  _GEN_1 = io_ctrlBusPorts_writeResp_ready & ctrl_bvalid | ctrl_aw_en; // @[D2dMasterRegIf.scala 51:61 53:16 21:27]
  wire  _GEN_3 = ~ctrl_awready & io_ctrlBusPorts_writeAddr_valid & io_ctrlBusPorts_writeData_valid & ctrl_aw_en ? 1'h0
     : _GEN_1; // @[D2dMasterRegIf.scala 47:106 50:16]
  wire  _T_12 = ~ctrl_wready & io_ctrlBusPorts_writeData_valid & io_ctrlBusPorts_writeAddr_valid & ctrl_aw_en; // @[D2dMasterRegIf.scala 63:91]
  wire  _T_15 = ctrl_wready & io_ctrlBusPorts_writeData_valid & ctrl_awready & io_ctrlBusPorts_writeAddr_valid; // @[D2dMasterRegIf.scala 69:71]
  wire  _GEN_7 = _T_4 ? 1'h0 : ctrl_bvalid; // @[D2dMasterRegIf.scala 81:61 82:17 27:29]
  wire  _GEN_8 = ctrl_awready & io_ctrlBusPorts_writeAddr_valid & ctrl_wready & io_ctrlBusPorts_writeData_valid | _GEN_7
    ; // @[D2dMasterRegIf.scala 77:106 78:17]
  wire  _T_21 = ~ctrl_arready & io_ctrlBusPorts_readAddr_valid; // @[D2dMasterRegIf.scala 91:22]
  wire  _T_24 = ctrl_arready & io_ctrlBusPorts_readAddr_valid & ~ctrl_rvalid; // @[D2dMasterRegIf.scala 100:55]
  wire  _GEN_12 = ctrl_rvalid & io_ctrlBusPorts_readData_ready ? 1'h0 : ctrl_rvalid; // @[D2dMasterRegIf.scala 105:60 107:17 32:28]
  wire  _GEN_13 = ctrl_arready & io_ctrlBusPorts_readAddr_valid & ~ctrl_rvalid | _GEN_12; // @[D2dMasterRegIf.scala 100:71 102:17]
  reg [10:0] rPreAddrIn; // @[D2dMasterRegIf.scala 114:27]
  wire [31:0] _ctrl_rdata_T = {21'h0,rPreAddrIn}; // @[Cat.scala 33:92]
  wire [31:0] _GEN_16 = _T_24 & ctrl_araddr == 8'h0 ? _ctrl_rdata_T : ctrl_rdata; // @[D2dMasterRegIf.scala 120:50 121:16 30:29]
  reg [11:0] rMasterReplayLatency; // @[D2dMasterRegIf.scala 125:37]
  wire [31:0] _ctrl_rdata_T_1 = {20'h0,rMasterReplayLatency}; // @[Cat.scala 33:92]
  wire [31:0] _GEN_18 = _T_24 & ctrl_araddr == 8'h4 ? _ctrl_rdata_T_1 : _GEN_16; // @[D2dMasterRegIf.scala 131:50 132:16]
  reg [31:0] rTxDebugReplayState; // @[D2dMasterRegIf.scala 136:36]
  reg [31:0] rTxDebugReplayQueue; // @[D2dMasterRegIf.scala 137:36]
  reg [31:0] rTxDebugReplayCnt; // @[D2dMasterRegIf.scala 138:34]
  wire [31:0] _GEN_19 = _T_24 & ctrl_araddr == 8'h8 ? rTxDebugReplayState : _GEN_18; // @[D2dMasterRegIf.scala 151:50 152:16]
  wire [31:0] _GEN_20 = _T_24 & ctrl_araddr == 8'hc ? rTxDebugReplayQueue : _GEN_19; // @[D2dMasterRegIf.scala 163:50 164:16]
  wire [5:0] _rDebugState_T = {io_txDebugState,io_rxDebugState}; // @[Cat.scala 33:92]
  reg [5:0] rDebugState; // @[D2dMasterRegIf.scala 171:28]
  wire [31:0] _ctrl_rdata_T_2 = {26'h0,rDebugState}; // @[Cat.scala 33:92]
  reg [3:0] rRxDebugLastCorrectPkgID; // @[D2dMasterRegIf.scala 178:41]
  wire [31:0] _ctrl_rdata_T_3 = {28'h0,rRxDebugLastCorrectPkgID}; // @[Cat.scala 33:92]
  assign io_ctrlBusPorts_readAddr_ready = ctrl_arready; // @[D2dMasterRegIf.scala 38:38]
  assign io_ctrlBusPorts_readData_valid = ctrl_rvalid; // @[D2dMasterRegIf.scala 41:38]
  assign io_ctrlBusPorts_readData_bits_data = ctrl_rdata; // @[D2dMasterRegIf.scala 39:38]
  assign io_ctrlBusPorts_writeAddr_ready = ctrl_awready; // @[D2dMasterRegIf.scala 34:38]
  assign io_ctrlBusPorts_writeData_ready = ctrl_wready; // @[D2dMasterRegIf.scala 35:38]
  assign io_ctrlBusPorts_writeResp_valid = ctrl_bvalid; // @[D2dMasterRegIf.scala 37:38]
  assign io_preAddrIn = rPreAddrIn; // @[D2dMasterRegIf.scala 123:16]
  assign io_inMasterReplayLatency = rMasterReplayLatency; // @[D2dMasterRegIf.scala 134:28]
  always @(posedge clock) begin
    if (reset) begin // @[D2dMasterRegIf.scala 19:30]
      ctrl_reg_WrEn <= 1'h0; // @[D2dMasterRegIf.scala 19:30]
    end else begin
      ctrl_reg_WrEn <= _T_15;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 20:32]
      ctrl_reg_Wrdata <= 32'h0; // @[D2dMasterRegIf.scala 20:32]
    end else begin
      ctrl_reg_Wrdata <= io_ctrlBusPorts_writeData_bits_data; // @[D2dMasterRegIf.scala 75:19]
    end
    ctrl_aw_en <= reset | _GEN_3; // @[D2dMasterRegIf.scala 21:{27,27}]
    if (reset) begin // @[D2dMasterRegIf.scala 23:29]
      ctrl_awaddr <= 8'h0; // @[D2dMasterRegIf.scala 23:29]
    end else if (_T_3) begin // @[D2dMasterRegIf.scala 58:107]
      ctrl_awaddr <= io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dMasterRegIf.scala 60:17]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 24:29]
      ctrl_awready <= 1'h0; // @[D2dMasterRegIf.scala 24:29]
    end else begin
      ctrl_awready <= _T_3;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 25:29]
      ctrl_wready <= 1'h0; // @[D2dMasterRegIf.scala 25:29]
    end else begin
      ctrl_wready <= _T_12;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 27:29]
      ctrl_bvalid <= 1'h0; // @[D2dMasterRegIf.scala 27:29]
    end else begin
      ctrl_bvalid <= _GEN_8;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 28:29]
      ctrl_araddr <= 8'h0; // @[D2dMasterRegIf.scala 28:29]
    end else if (~ctrl_arready & io_ctrlBusPorts_readAddr_valid) begin // @[D2dMasterRegIf.scala 91:56]
      ctrl_araddr <= io_ctrlBusPorts_readAddr_bits_addr; // @[D2dMasterRegIf.scala 95:17]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 29:29]
      ctrl_arready <= 1'h0; // @[D2dMasterRegIf.scala 29:29]
    end else begin
      ctrl_arready <= _T_21;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 30:29]
      ctrl_rdata <= 32'h0; // @[D2dMasterRegIf.scala 30:29]
    end else if (_T_24 & ctrl_araddr == 8'h18) begin // @[D2dMasterRegIf.scala 180:50]
      ctrl_rdata <= _ctrl_rdata_T_3; // @[D2dMasterRegIf.scala 181:16]
    end else if (_T_24 & ctrl_araddr == 8'h14) begin // @[D2dMasterRegIf.scala 174:50]
      ctrl_rdata <= _ctrl_rdata_T_2; // @[D2dMasterRegIf.scala 175:16]
    end else if (_T_24 & ctrl_araddr == 8'h10) begin // @[D2dMasterRegIf.scala 167:50]
      ctrl_rdata <= rTxDebugReplayCnt; // @[D2dMasterRegIf.scala 168:16]
    end else begin
      ctrl_rdata <= _GEN_20;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 32:28]
      ctrl_rvalid <= 1'h0; // @[D2dMasterRegIf.scala 32:28]
    end else begin
      ctrl_rvalid <= _GEN_13;
    end
    if (reset) begin // @[D2dMasterRegIf.scala 114:27]
      rPreAddrIn <= 11'h0; // @[D2dMasterRegIf.scala 114:27]
    end else if (ctrl_reg_WrEn & ctrl_awaddr == 8'h0) begin // @[D2dMasterRegIf.scala 117:50]
      rPreAddrIn <= ctrl_reg_Wrdata[10:0]; // @[D2dMasterRegIf.scala 118:16]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 125:37]
      rMasterReplayLatency <= 12'h400; // @[D2dMasterRegIf.scala 125:37]
    end else if (ctrl_reg_WrEn & ctrl_awaddr == 8'h4) begin // @[D2dMasterRegIf.scala 128:50]
      rMasterReplayLatency <= ctrl_reg_Wrdata[11:0]; // @[D2dMasterRegIf.scala 129:26]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 136:36]
      rTxDebugReplayState <= 32'h0; // @[D2dMasterRegIf.scala 136:36]
    end else begin
      rTxDebugReplayState <= io_txDebugReplayState; // @[D2dMasterRegIf.scala 136:36]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 137:36]
      rTxDebugReplayQueue <= 32'h0; // @[D2dMasterRegIf.scala 137:36]
    end else begin
      rTxDebugReplayQueue <= io_txDebugReplayQueue; // @[D2dMasterRegIf.scala 137:36]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 138:34]
      rTxDebugReplayCnt <= 32'h0; // @[D2dMasterRegIf.scala 138:34]
    end else begin
      rTxDebugReplayCnt <= io_txDebugReplayCnt; // @[D2dMasterRegIf.scala 138:34]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 171:28]
      rDebugState <= 6'h0; // @[D2dMasterRegIf.scala 171:28]
    end else begin
      rDebugState <= _rDebugState_T; // @[D2dMasterRegIf.scala 171:28]
    end
    if (reset) begin // @[D2dMasterRegIf.scala 178:41]
      rRxDebugLastCorrectPkgID <= 4'h0; // @[D2dMasterRegIf.scala 178:41]
    end else begin
      rRxDebugLastCorrectPkgID <= io_rxDebugLastCorrectPkgID; // @[D2dMasterRegIf.scala 178:41]
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
  rMasterReplayLatency = _RAND_12[11:0];
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
module Md2dMaster(
  input         clock,
  input         reset,
  input         io_txClock,
  output        io_AXI4SlavePorts_readAddr_ready,
  input         io_AXI4SlavePorts_readAddr_valid,
  input  [20:0] io_AXI4SlavePorts_readAddr_bits_addr,
  input  [6:0]  io_AXI4SlavePorts_readAddr_bits_id,
  input  [2:0]  io_AXI4SlavePorts_readAddr_bits_size,
  input  [7:0]  io_AXI4SlavePorts_readAddr_bits_len,
  input  [1:0]  io_AXI4SlavePorts_readAddr_bits_burst,
  input  [3:0]  io_AXI4SlavePorts_readAddr_bits_cache,
  input         io_AXI4SlavePorts_readAddr_bits_lock,
  input  [2:0]  io_AXI4SlavePorts_readAddr_bits_prot,
  input  [3:0]  io_AXI4SlavePorts_readAddr_bits_qos,
  input  [3:0]  io_AXI4SlavePorts_readAddr_bits_region,
  input         io_AXI4SlavePorts_readData_ready,
  output        io_AXI4SlavePorts_readData_valid,
  output [63:0] io_AXI4SlavePorts_readData_bits_data,
  output        io_AXI4SlavePorts_readData_bits_last,
  output [6:0]  io_AXI4SlavePorts_readData_bits_id,
  output [1:0]  io_AXI4SlavePorts_readData_bits_resp,
  output        io_AXI4SlavePorts_writeAddr_ready,
  input         io_AXI4SlavePorts_writeAddr_valid,
  input  [20:0] io_AXI4SlavePorts_writeAddr_bits_addr,
  input  [6:0]  io_AXI4SlavePorts_writeAddr_bits_id,
  input  [2:0]  io_AXI4SlavePorts_writeAddr_bits_size,
  input  [7:0]  io_AXI4SlavePorts_writeAddr_bits_len,
  input  [1:0]  io_AXI4SlavePorts_writeAddr_bits_burst,
  input  [3:0]  io_AXI4SlavePorts_writeAddr_bits_cache,
  input         io_AXI4SlavePorts_writeAddr_bits_lock,
  input  [2:0]  io_AXI4SlavePorts_writeAddr_bits_prot,
  input  [3:0]  io_AXI4SlavePorts_writeAddr_bits_qos,
  input  [3:0]  io_AXI4SlavePorts_writeAddr_bits_region,
  output        io_AXI4SlavePorts_writeData_ready,
  input         io_AXI4SlavePorts_writeData_valid,
  input  [63:0] io_AXI4SlavePorts_writeData_bits_data,
  input         io_AXI4SlavePorts_writeData_bits_last,
  input  [7:0]  io_AXI4SlavePorts_writeData_bits_strb,
  input         io_AXI4SlavePorts_writeResp_ready,
  output        io_AXI4SlavePorts_writeResp_valid,
  output [6:0]  io_AXI4SlavePorts_writeResp_bits_id,
  output [1:0]  io_AXI4SlavePorts_writeResp_bits_resp,
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
  output [15:0] io_tx_flit_bits,
  output        io_tx_creditRB_free,
  output        io_tx_replayPkgID,
  input         io_rx_clock,
  input         io_rx_flit_valid,
  input  [7:0]  io_rx_flit_bits,
  input         io_rx_creditARW_free,
  input         io_rx_replayPkgID
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  wire  D2dIdAxiArPreQueue_clock; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiArPreQueue_reset; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiArPreQueue_io_enq_ready; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiArPreQueue_io_enq_valid; // @[D2dMaster.scala 26:34]
  wire [1:0] D2dIdAxiArPreQueue_io_enq_bits; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiArPreQueue_io_deq_ready; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiArPreQueue_io_deq_valid; // @[D2dMaster.scala 26:34]
  wire [1:0] D2dIdAxiArPreQueue_io_deq_bits; // @[D2dMaster.scala 26:34]
  wire  D2dIdAxiAwPreQueue_clock; // @[D2dMaster.scala 44:34]
  wire  D2dIdAxiAwPreQueue_reset; // @[D2dMaster.scala 44:34]
  wire  D2dIdAxiAwPreQueue_io_enq_ready; // @[D2dMaster.scala 44:34]
  wire  D2dIdAxiAwPreQueue_io_enq_valid; // @[D2dMaster.scala 44:34]
  wire [1:0] D2dIdAxiAwPreQueue_io_enq_bits; // @[D2dMaster.scala 44:34]
  wire  D2dIdAxiAwPreQueue_io_deq_ready; // @[D2dMaster.scala 44:34]
  wire  D2dIdAxiAwPreQueue_io_deq_valid; // @[D2dMaster.scala 44:34]
  wire [1:0] D2dIdAxiAwPreQueue_io_deq_bits; // @[D2dMaster.scala 44:34]
  wire  Tx_clock; // @[D2dMaster.scala 49:18]
  wire  Tx_reset; // @[D2dMaster.scala 49:18]
  wire  Tx_io_txClock; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4W_ready; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4W_valid; // @[D2dMaster.scala 49:18]
  wire [63:0] Tx_io_inAXI4W_bits_data; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4W_bits_last; // @[D2dMaster.scala 49:18]
  wire [7:0] Tx_io_inAXI4W_bits_strb; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AW_ready; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AW_valid; // @[D2dMaster.scala 49:18]
  wire [20:0] Tx_io_inAXI4AW_bits_addr; // @[D2dMaster.scala 49:18]
  wire [6:0] Tx_io_inAXI4AW_bits_id; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_inAXI4AW_bits_size; // @[D2dMaster.scala 49:18]
  wire [7:0] Tx_io_inAXI4AW_bits_len; // @[D2dMaster.scala 49:18]
  wire [1:0] Tx_io_inAXI4AW_bits_burst; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AW_bits_cache; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AW_bits_lock; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_inAXI4AW_bits_prot; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AW_bits_qos; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AW_bits_region; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AR_ready; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AR_valid; // @[D2dMaster.scala 49:18]
  wire [20:0] Tx_io_inAXI4AR_bits_addr; // @[D2dMaster.scala 49:18]
  wire [6:0] Tx_io_inAXI4AR_bits_id; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_inAXI4AR_bits_size; // @[D2dMaster.scala 49:18]
  wire [7:0] Tx_io_inAXI4AR_bits_len; // @[D2dMaster.scala 49:18]
  wire [1:0] Tx_io_inAXI4AR_bits_burst; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AR_bits_cache; // @[D2dMaster.scala 49:18]
  wire  Tx_io_inAXI4AR_bits_lock; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_inAXI4AR_bits_prot; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AR_bits_qos; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_inAXI4AR_bits_region; // @[D2dMaster.scala 49:18]
  wire [10:0] Tx_io_preAddrIn; // @[D2dMaster.scala 49:18]
  wire  Tx_io_tx_clock; // @[D2dMaster.scala 49:18]
  wire  Tx_io_tx_flit_valid; // @[D2dMaster.scala 49:18]
  wire [15:0] Tx_io_tx_flit_bits; // @[D2dMaster.scala 49:18]
  wire  Tx_io_tx_creditRB_free; // @[D2dMaster.scala 49:18]
  wire  Tx_io_tx_replayPkgID; // @[D2dMaster.scala 49:18]
  wire [31:0] Tx_io_txDebugReplayState; // @[D2dMaster.scala 49:18]
  wire [31:0] Tx_io_txDebugReplayQueue; // @[D2dMaster.scala 49:18]
  wire [31:0] Tx_io_txDebugReplayCnt; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_txDebugState; // @[D2dMaster.scala 49:18]
  wire [11:0] Tx_io_inMasterReplayLatency; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxCreditARWFree_valid; // @[D2dMaster.scala 49:18]
  wire [2:0] Tx_io_rx2TxCreditARWFree_bits; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxPackageIDUsed_valid; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_rx2TxPackageIDUsed_bits; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxCreditRBFree_ready; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxCreditRBFree_valid; // @[D2dMaster.scala 49:18]
  wire [1:0] Tx_io_rx2TxCreditRBFree_bits; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxPackageIDOut_ready; // @[D2dMaster.scala 49:18]
  wire  Tx_io_rx2TxPackageIDOut_valid; // @[D2dMaster.scala 49:18]
  wire [3:0] Tx_io_rx2TxPackageIDOut_bits; // @[D2dMaster.scala 49:18]
  wire  Rx_clock; // @[D2dMaster.scala 56:18]
  wire  Rx_reset; // @[D2dMaster.scala 56:18]
  wire  Rx_io_outAXI4R_ready; // @[D2dMaster.scala 56:18]
  wire  Rx_io_outAXI4R_valid; // @[D2dMaster.scala 56:18]
  wire [63:0] Rx_io_outAXI4R_bits_data; // @[D2dMaster.scala 56:18]
  wire  Rx_io_outAXI4R_bits_last; // @[D2dMaster.scala 56:18]
  wire [4:0] Rx_io_outAXI4R_bits_id; // @[D2dMaster.scala 56:18]
  wire [1:0] Rx_io_outAXI4R_bits_resp; // @[D2dMaster.scala 56:18]
  wire  Rx_io_outAXI4B_ready; // @[D2dMaster.scala 56:18]
  wire  Rx_io_outAXI4B_valid; // @[D2dMaster.scala 56:18]
  wire [4:0] Rx_io_outAXI4B_bits_id; // @[D2dMaster.scala 56:18]
  wire [1:0] Rx_io_outAXI4B_bits_resp; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx_clock; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx_flit_valid; // @[D2dMaster.scala 56:18]
  wire [7:0] Rx_io_rx_flit_bits; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx_creditARW_free; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx_replayPkgID; // @[D2dMaster.scala 56:18]
  wire [2:0] Rx_io_rxDebugState; // @[D2dMaster.scala 56:18]
  wire [3:0] Rx_io_rxDebugLastCorrectPkgID; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx2TxCreditARWFree_valid; // @[D2dMaster.scala 56:18]
  wire [2:0] Rx_io_rx2TxCreditARWFree_bits; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx2TxPackageIDUsed_valid; // @[D2dMaster.scala 56:18]
  wire [3:0] Rx_io_rx2TxPackageIDUsed_bits; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx2TxCreditRBFree_valid; // @[D2dMaster.scala 56:18]
  wire [1:0] Rx_io_rx2TxCreditRBFree_bits; // @[D2dMaster.scala 56:18]
  wire  Rx_io_rx2TxPackageIDOut_valid; // @[D2dMaster.scala 56:18]
  wire [3:0] Rx_io_rx2TxPackageIDOut_bits; // @[D2dMaster.scala 56:18]
  wire  rstTxSync_clock; // @[D2dMaster.scala 73:25]
  wire  rstTxSync_reset_in; // @[D2dMaster.scala 73:25]
  wire  rstTxSync_reset_out; // @[D2dMaster.scala 73:25]
  wire  rstRxSync_clock; // @[D2dMaster.scala 78:25]
  wire  rstRxSync_reset_in; // @[D2dMaster.scala 78:25]
  wire  rstRxSync_reset_out; // @[D2dMaster.scala 78:25]
  wire  asyncQPackageIDUsed_wr_clock; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_wr_reset; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_wr_valid; // @[D2dMaster.scala 87:35]
  wire [3:0] asyncQPackageIDUsed_wr_bits; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_rd_clock; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_rd_reset; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_rd_ready; // @[D2dMaster.scala 87:35]
  wire  asyncQPackageIDUsed_rd_valid; // @[D2dMaster.scala 87:35]
  wire [3:0] asyncQPackageIDUsed_rd_bits; // @[D2dMaster.scala 87:35]
  wire  asyncQCreditARWFree_wr_clock; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditARWFree_wr_reset; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditARWFree_wr_valid; // @[D2dMaster.scala 100:35]
  wire [2:0] asyncQCreditARWFree_wr_bits; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditARWFree_rd_clock; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditARWFree_rd_reset; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditARWFree_rd_valid; // @[D2dMaster.scala 100:35]
  wire [2:0] asyncQCreditARWFree_rd_bits; // @[D2dMaster.scala 100:35]
  wire  asyncQCreditRBFree_wr_clock; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_wr_reset; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_wr_valid; // @[D2dMaster.scala 113:34]
  wire [1:0] asyncQCreditRBFree_wr_bits; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_rd_clock; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_rd_reset; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_rd_ready; // @[D2dMaster.scala 113:34]
  wire  asyncQCreditRBFree_rd_valid; // @[D2dMaster.scala 113:34]
  wire [1:0] asyncQCreditRBFree_rd_bits; // @[D2dMaster.scala 113:34]
  wire  asyncQPackageIDOut_wr_clock; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_wr_reset; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_wr_valid; // @[D2dMaster.scala 126:34]
  wire [3:0] asyncQPackageIDOut_wr_bits; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_rd_clock; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_rd_reset; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_rd_ready; // @[D2dMaster.scala 126:34]
  wire  asyncQPackageIDOut_rd_valid; // @[D2dMaster.scala 126:34]
  wire [3:0] asyncQPackageIDOut_rd_bits; // @[D2dMaster.scala 126:34]
  wire  D2dMasterCtrlRegIf_clock; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_reset; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_ready; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_valid; // @[D2dMaster.scala 135:34]
  wire [7:0] D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_ready; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_valid; // @[D2dMaster.scala 135:34]
  wire [31:0] D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_bits_data; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_ready; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_valid; // @[D2dMaster.scala 135:34]
  wire [7:0] D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_ready; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_valid; // @[D2dMaster.scala 135:34]
  wire [31:0] D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_bits_data; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_ready; // @[D2dMaster.scala 135:34]
  wire  D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_valid; // @[D2dMaster.scala 135:34]
  wire [10:0] D2dMasterCtrlRegIf_io_preAddrIn; // @[D2dMaster.scala 135:34]
  wire [11:0] D2dMasterCtrlRegIf_io_inMasterReplayLatency; // @[D2dMaster.scala 135:34]
  wire [31:0] D2dMasterCtrlRegIf_io_txDebugReplayState; // @[D2dMaster.scala 135:34]
  wire [31:0] D2dMasterCtrlRegIf_io_txDebugReplayQueue; // @[D2dMaster.scala 135:34]
  wire [31:0] D2dMasterCtrlRegIf_io_txDebugReplayCnt; // @[D2dMaster.scala 135:34]
  wire [2:0] D2dMasterCtrlRegIf_io_txDebugState; // @[D2dMaster.scala 135:34]
  wire [2:0] D2dMasterCtrlRegIf_io_rxDebugState; // @[D2dMaster.scala 135:34]
  wire [3:0] D2dMasterCtrlRegIf_io_rxDebugLastCorrectPkgID; // @[D2dMaster.scala 135:34]
  wire  rIDReg0_x2 = io_ctrlBusPorts_readAddr_ready & io_ctrlBusPorts_readAddr_valid; // @[Decoupled.scala 52:35]
  reg [6:0] rIDReg0; // @[Reg.scala 35:20]
  wire  wIDReg0_x5 = io_ctrlBusPorts_writeAddr_ready & io_ctrlBusPorts_writeAddr_valid; // @[Decoupled.scala 52:35]
  reg [6:0] wIDReg0; // @[Reg.scala 35:20]
  reg  readDataFirstReg; // @[D2dMaster.scala 23:33]
  reg [1:0] readDataIdPreReg; // @[D2dMaster.scala 24:33]
  wire  _D2dIdAxiArPreQueue_io_deq_ready_T = ~readDataFirstReg; // @[D2dMaster.scala 29:38]
  wire  _D2dIdAxiArPreQueue_io_deq_ready_T_1 = io_AXI4SlavePorts_readData_ready & io_AXI4SlavePorts_readData_valid; // @[Decoupled.scala 52:35]
  wire  _T_2 = _D2dIdAxiArPreQueue_io_deq_ready_T_1 & _D2dIdAxiArPreQueue_io_deq_ready_T; // @[D2dMaster.scala 31:40]
  wire  _T_3 = ~io_AXI4SlavePorts_readData_bits_last; // @[D2dMaster.scala 31:64]
  wire  _T_10 = _D2dIdAxiArPreQueue_io_deq_ready_T_1 & readDataFirstReg; // @[D2dMaster.scala 37:46]
  wire  _GEN_2 = _T_10 & _T_3 | readDataFirstReg; // @[D2dMaster.scala 39:107 40:22 23:33]
  wire  _GEN_3 = _D2dIdAxiArPreQueue_io_deq_ready_T_1 & readDataFirstReg & io_AXI4SlavePorts_readData_bits_last ? 1'h0
     : _GEN_2; // @[D2dMaster.scala 37:106 38:22]
  wire  _GEN_4 = _T_2 & io_AXI4SlavePorts_readData_bits_last ? 1'h0 : _GEN_3; // @[D2dMaster.scala 34:107 35:22]
  wire  _GEN_6 = _D2dIdAxiArPreQueue_io_deq_ready_T_1 & _D2dIdAxiArPreQueue_io_deq_ready_T & ~
    io_AXI4SlavePorts_readData_bits_last | _GEN_4; // @[D2dMaster.scala 31:102 32:22]
  wire [6:0] _io_AXI4SlavePorts_readData_bits_id_T_1 = {D2dIdAxiArPreQueue_io_deq_bits,Rx_io_outAXI4R_bits_id}; // @[Cat.scala 33:92]
  wire [6:0] _io_AXI4SlavePorts_readData_bits_id_T_2 = {readDataIdPreReg,Rx_io_outAXI4R_bits_id}; // @[Cat.scala 33:92]
  MQueue D2dIdAxiArPreQueue ( // @[D2dMaster.scala 26:34]
    .clock(D2dIdAxiArPreQueue_clock),
    .reset(D2dIdAxiArPreQueue_reset),
    .io_enq_ready(D2dIdAxiArPreQueue_io_enq_ready),
    .io_enq_valid(D2dIdAxiArPreQueue_io_enq_valid),
    .io_enq_bits(D2dIdAxiArPreQueue_io_enq_bits),
    .io_deq_ready(D2dIdAxiArPreQueue_io_deq_ready),
    .io_deq_valid(D2dIdAxiArPreQueue_io_deq_valid),
    .io_deq_bits(D2dIdAxiArPreQueue_io_deq_bits)
  );
  MQueue D2dIdAxiAwPreQueue ( // @[D2dMaster.scala 44:34]
    .clock(D2dIdAxiAwPreQueue_clock),
    .reset(D2dIdAxiAwPreQueue_reset),
    .io_enq_ready(D2dIdAxiAwPreQueue_io_enq_ready),
    .io_enq_valid(D2dIdAxiAwPreQueue_io_enq_valid),
    .io_enq_bits(D2dIdAxiAwPreQueue_io_enq_bits),
    .io_deq_ready(D2dIdAxiAwPreQueue_io_deq_ready),
    .io_deq_valid(D2dIdAxiAwPreQueue_io_deq_valid),
    .io_deq_bits(D2dIdAxiAwPreQueue_io_deq_bits)
  );
  Md2dMasterTx Tx ( // @[D2dMaster.scala 49:18]
    .clock(Tx_clock),
    .reset(Tx_reset),
    .io_txClock(Tx_io_txClock),
    .io_inAXI4W_ready(Tx_io_inAXI4W_ready),
    .io_inAXI4W_valid(Tx_io_inAXI4W_valid),
    .io_inAXI4W_bits_data(Tx_io_inAXI4W_bits_data),
    .io_inAXI4W_bits_last(Tx_io_inAXI4W_bits_last),
    .io_inAXI4W_bits_strb(Tx_io_inAXI4W_bits_strb),
    .io_inAXI4AW_ready(Tx_io_inAXI4AW_ready),
    .io_inAXI4AW_valid(Tx_io_inAXI4AW_valid),
    .io_inAXI4AW_bits_addr(Tx_io_inAXI4AW_bits_addr),
    .io_inAXI4AW_bits_id(Tx_io_inAXI4AW_bits_id),
    .io_inAXI4AW_bits_size(Tx_io_inAXI4AW_bits_size),
    .io_inAXI4AW_bits_len(Tx_io_inAXI4AW_bits_len),
    .io_inAXI4AW_bits_burst(Tx_io_inAXI4AW_bits_burst),
    .io_inAXI4AW_bits_cache(Tx_io_inAXI4AW_bits_cache),
    .io_inAXI4AW_bits_lock(Tx_io_inAXI4AW_bits_lock),
    .io_inAXI4AW_bits_prot(Tx_io_inAXI4AW_bits_prot),
    .io_inAXI4AW_bits_qos(Tx_io_inAXI4AW_bits_qos),
    .io_inAXI4AW_bits_region(Tx_io_inAXI4AW_bits_region),
    .io_inAXI4AR_ready(Tx_io_inAXI4AR_ready),
    .io_inAXI4AR_valid(Tx_io_inAXI4AR_valid),
    .io_inAXI4AR_bits_addr(Tx_io_inAXI4AR_bits_addr),
    .io_inAXI4AR_bits_id(Tx_io_inAXI4AR_bits_id),
    .io_inAXI4AR_bits_size(Tx_io_inAXI4AR_bits_size),
    .io_inAXI4AR_bits_len(Tx_io_inAXI4AR_bits_len),
    .io_inAXI4AR_bits_burst(Tx_io_inAXI4AR_bits_burst),
    .io_inAXI4AR_bits_cache(Tx_io_inAXI4AR_bits_cache),
    .io_inAXI4AR_bits_lock(Tx_io_inAXI4AR_bits_lock),
    .io_inAXI4AR_bits_prot(Tx_io_inAXI4AR_bits_prot),
    .io_inAXI4AR_bits_qos(Tx_io_inAXI4AR_bits_qos),
    .io_inAXI4AR_bits_region(Tx_io_inAXI4AR_bits_region),
    .io_preAddrIn(Tx_io_preAddrIn),
    .io_tx_clock(Tx_io_tx_clock),
    .io_tx_flit_valid(Tx_io_tx_flit_valid),
    .io_tx_flit_bits(Tx_io_tx_flit_bits),
    .io_tx_creditRB_free(Tx_io_tx_creditRB_free),
    .io_tx_replayPkgID(Tx_io_tx_replayPkgID),
    .io_txDebugReplayState(Tx_io_txDebugReplayState),
    .io_txDebugReplayQueue(Tx_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(Tx_io_txDebugReplayCnt),
    .io_txDebugState(Tx_io_txDebugState),
    .io_inMasterReplayLatency(Tx_io_inMasterReplayLatency),
    .io_rx2TxCreditARWFree_valid(Tx_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(Tx_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_valid(Tx_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(Tx_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_ready(Tx_io_rx2TxCreditRBFree_ready),
    .io_rx2TxCreditRBFree_valid(Tx_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(Tx_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_ready(Tx_io_rx2TxPackageIDOut_ready),
    .io_rx2TxPackageIDOut_valid(Tx_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(Tx_io_rx2TxPackageIDOut_bits)
  );
  Md2dMasterRx Rx ( // @[D2dMaster.scala 56:18]
    .clock(Rx_clock),
    .reset(Rx_reset),
    .io_outAXI4R_ready(Rx_io_outAXI4R_ready),
    .io_outAXI4R_valid(Rx_io_outAXI4R_valid),
    .io_outAXI4R_bits_data(Rx_io_outAXI4R_bits_data),
    .io_outAXI4R_bits_last(Rx_io_outAXI4R_bits_last),
    .io_outAXI4R_bits_id(Rx_io_outAXI4R_bits_id),
    .io_outAXI4R_bits_resp(Rx_io_outAXI4R_bits_resp),
    .io_outAXI4B_ready(Rx_io_outAXI4B_ready),
    .io_outAXI4B_valid(Rx_io_outAXI4B_valid),
    .io_outAXI4B_bits_id(Rx_io_outAXI4B_bits_id),
    .io_outAXI4B_bits_resp(Rx_io_outAXI4B_bits_resp),
    .io_rx_clock(Rx_io_rx_clock),
    .io_rx_flit_valid(Rx_io_rx_flit_valid),
    .io_rx_flit_bits(Rx_io_rx_flit_bits),
    .io_rx_creditARW_free(Rx_io_rx_creditARW_free),
    .io_rx_replayPkgID(Rx_io_rx_replayPkgID),
    .io_rxDebugState(Rx_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(Rx_io_rxDebugLastCorrectPkgID),
    .io_rx2TxCreditARWFree_valid(Rx_io_rx2TxCreditARWFree_valid),
    .io_rx2TxCreditARWFree_bits(Rx_io_rx2TxCreditARWFree_bits),
    .io_rx2TxPackageIDUsed_valid(Rx_io_rx2TxPackageIDUsed_valid),
    .io_rx2TxPackageIDUsed_bits(Rx_io_rx2TxPackageIDUsed_bits),
    .io_rx2TxCreditRBFree_valid(Rx_io_rx2TxCreditRBFree_valid),
    .io_rx2TxCreditRBFree_bits(Rx_io_rx2TxCreditRBFree_bits),
    .io_rx2TxPackageIDOut_valid(Rx_io_rx2TxPackageIDOut_valid),
    .io_rx2TxPackageIDOut_bits(Rx_io_rx2TxPackageIDOut_bits)
  );
  ResetSync_d2d rstTxSync ( // @[D2dMaster.scala 73:25]
    .clock(rstTxSync_clock),
    .reset_in(rstTxSync_reset_in),
    .reset_out(rstTxSync_reset_out)
  );
  ResetSync_d2d rstRxSync ( // @[D2dMaster.scala 78:25]
    .clock(rstRxSync_clock),
    .reset_in(rstRxSync_reset_in),
    .reset_out(rstRxSync_reset_out)
  );
  MAsyncQueue_5 asyncQPackageIDUsed ( // @[D2dMaster.scala 87:35]
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
  MAsyncQueue_6 asyncQCreditARWFree ( // @[D2dMaster.scala 100:35]
    .wr_clock(asyncQCreditARWFree_wr_clock),
    .wr_reset(asyncQCreditARWFree_wr_reset),
    .wr_valid(asyncQCreditARWFree_wr_valid),
    .wr_bits(asyncQCreditARWFree_wr_bits),
    .rd_clock(asyncQCreditARWFree_rd_clock),
    .rd_reset(asyncQCreditARWFree_rd_reset),
    .rd_valid(asyncQCreditARWFree_rd_valid),
    .rd_bits(asyncQCreditARWFree_rd_bits)
  );
  MAsyncQueue_7 asyncQCreditRBFree ( // @[D2dMaster.scala 113:34]
    .wr_clock(asyncQCreditRBFree_wr_clock),
    .wr_reset(asyncQCreditRBFree_wr_reset),
    .wr_valid(asyncQCreditRBFree_wr_valid),
    .wr_bits(asyncQCreditRBFree_wr_bits),
    .rd_clock(asyncQCreditRBFree_rd_clock),
    .rd_reset(asyncQCreditRBFree_rd_reset),
    .rd_ready(asyncQCreditRBFree_rd_ready),
    .rd_valid(asyncQCreditRBFree_rd_valid),
    .rd_bits(asyncQCreditRBFree_rd_bits)
  );
  MAsyncQueue_5 asyncQPackageIDOut ( // @[D2dMaster.scala 126:34]
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
  MD2dMasterCtrlRegIf D2dMasterCtrlRegIf ( // @[D2dMaster.scala 135:34]
    .clock(D2dMasterCtrlRegIf_clock),
    .reset(D2dMasterCtrlRegIf_reset),
    .io_ctrlBusPorts_readAddr_ready(D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_ready),
    .io_ctrlBusPorts_readAddr_valid(D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_valid),
    .io_ctrlBusPorts_readAddr_bits_addr(D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr),
    .io_ctrlBusPorts_readData_ready(D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_ready),
    .io_ctrlBusPorts_readData_valid(D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_valid),
    .io_ctrlBusPorts_readData_bits_data(D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_bits_data),
    .io_ctrlBusPorts_writeAddr_ready(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_ready),
    .io_ctrlBusPorts_writeAddr_valid(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_valid),
    .io_ctrlBusPorts_writeAddr_bits_addr(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr),
    .io_ctrlBusPorts_writeData_ready(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_ready),
    .io_ctrlBusPorts_writeData_valid(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_valid),
    .io_ctrlBusPorts_writeData_bits_data(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_bits_data),
    .io_ctrlBusPorts_writeResp_ready(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_ready),
    .io_ctrlBusPorts_writeResp_valid(D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_valid),
    .io_preAddrIn(D2dMasterCtrlRegIf_io_preAddrIn),
    .io_inMasterReplayLatency(D2dMasterCtrlRegIf_io_inMasterReplayLatency),
    .io_txDebugReplayState(D2dMasterCtrlRegIf_io_txDebugReplayState),
    .io_txDebugReplayQueue(D2dMasterCtrlRegIf_io_txDebugReplayQueue),
    .io_txDebugReplayCnt(D2dMasterCtrlRegIf_io_txDebugReplayCnt),
    .io_txDebugState(D2dMasterCtrlRegIf_io_txDebugState),
    .io_rxDebugState(D2dMasterCtrlRegIf_io_rxDebugState),
    .io_rxDebugLastCorrectPkgID(D2dMasterCtrlRegIf_io_rxDebugLastCorrectPkgID)
  );
  assign io_AXI4SlavePorts_readAddr_ready = Tx_io_inAXI4AR_ready; // @[D2dMaster.scala 50:30]
  assign io_AXI4SlavePorts_readData_valid = Rx_io_outAXI4R_valid; // @[D2dMaster.scala 57:36]
  assign io_AXI4SlavePorts_readData_bits_data = Rx_io_outAXI4R_bits_data; // @[D2dMaster.scala 62:40]
  assign io_AXI4SlavePorts_readData_bits_last = Rx_io_outAXI4R_bits_last; // @[D2dMaster.scala 64:40]
  assign io_AXI4SlavePorts_readData_bits_id = _D2dIdAxiArPreQueue_io_deq_ready_T ?
    _io_AXI4SlavePorts_readData_bits_id_T_1 : _io_AXI4SlavePorts_readData_bits_id_T_2; // @[D2dMaster.scala 59:44]
  assign io_AXI4SlavePorts_readData_bits_resp = Rx_io_outAXI4R_bits_resp; // @[D2dMaster.scala 61:40]
  assign io_AXI4SlavePorts_writeAddr_ready = Tx_io_inAXI4AW_ready; // @[D2dMaster.scala 51:31]
  assign io_AXI4SlavePorts_writeData_ready = Tx_io_inAXI4W_ready; // @[D2dMaster.scala 52:31]
  assign io_AXI4SlavePorts_writeResp_valid = Rx_io_outAXI4B_valid; // @[D2dMaster.scala 66:37]
  assign io_AXI4SlavePorts_writeResp_bits_id = {D2dIdAxiAwPreQueue_io_deq_bits,Rx_io_outAXI4B_bits_id}; // @[Cat.scala 33:92]
  assign io_AXI4SlavePorts_writeResp_bits_resp = Rx_io_outAXI4B_bits_resp; // @[D2dMaster.scala 69:41]
  assign io_ctrlBusPorts_readAddr_ready = D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_ready; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_readData_valid = D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_valid; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_readData_bits_data = D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_bits_data; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_readData_bits_resp = 2'h0; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_writeAddr_ready = D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_ready; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_writeData_ready = D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_ready; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_writeResp_valid = D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_valid; // @[D2dMaster.scala 136:19]
  assign io_ctrlBusPorts_writeResp_bits = 2'h0; // @[D2dMaster.scala 136:19]
  assign io_RId = rIDReg0; // @[D2dMaster.scala 21:10]
  assign io_BId = wIDReg0; // @[D2dMaster.scala 22:10]
  assign io_tx_clock = Tx_io_tx_clock; // @[D2dMaster.scala 54:9]
  assign io_tx_flit_valid = Tx_io_tx_flit_valid; // @[D2dMaster.scala 54:9]
  assign io_tx_flit_bits = Tx_io_tx_flit_bits; // @[D2dMaster.scala 54:9]
  assign io_tx_creditRB_free = Tx_io_tx_creditRB_free; // @[D2dMaster.scala 54:9]
  assign io_tx_replayPkgID = Tx_io_tx_replayPkgID; // @[D2dMaster.scala 54:9]
  assign D2dIdAxiArPreQueue_clock = clock;
  assign D2dIdAxiArPreQueue_reset = reset;
  assign D2dIdAxiArPreQueue_io_enq_valid = io_AXI4SlavePorts_readAddr_ready & io_AXI4SlavePorts_readAddr_valid; // @[Decoupled.scala 52:35]
  assign D2dIdAxiArPreQueue_io_enq_bits = io_AXI4SlavePorts_readAddr_bits_id[6:5]; // @[D2dMaster.scala 28:76]
  assign D2dIdAxiArPreQueue_io_deq_ready = ~readDataFirstReg & _D2dIdAxiArPreQueue_io_deq_ready_T_1; // @[D2dMaster.scala 29:56]
  assign D2dIdAxiAwPreQueue_clock = clock;
  assign D2dIdAxiAwPreQueue_reset = reset;
  assign D2dIdAxiAwPreQueue_io_enq_valid = io_AXI4SlavePorts_writeAddr_ready & io_AXI4SlavePorts_writeAddr_valid; // @[Decoupled.scala 52:35]
  assign D2dIdAxiAwPreQueue_io_enq_bits = io_AXI4SlavePorts_writeAddr_bits_id[6:5]; // @[D2dMaster.scala 46:77]
  assign D2dIdAxiAwPreQueue_io_deq_ready = io_AXI4SlavePorts_writeResp_ready & io_AXI4SlavePorts_writeResp_valid; // @[Decoupled.scala 52:35]
  assign Tx_clock = clock;
  assign Tx_reset = reset;
  assign Tx_io_txClock = io_txClock; // @[D2dMaster.scala 53:14]
  assign Tx_io_inAXI4W_valid = io_AXI4SlavePorts_writeData_valid; // @[D2dMaster.scala 52:31]
  assign Tx_io_inAXI4W_bits_data = io_AXI4SlavePorts_writeData_bits_data; // @[D2dMaster.scala 52:31]
  assign Tx_io_inAXI4W_bits_last = io_AXI4SlavePorts_writeData_bits_last; // @[D2dMaster.scala 52:31]
  assign Tx_io_inAXI4W_bits_strb = io_AXI4SlavePorts_writeData_bits_strb; // @[D2dMaster.scala 52:31]
  assign Tx_io_inAXI4AW_valid = io_AXI4SlavePorts_writeAddr_valid; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_addr = io_AXI4SlavePorts_writeAddr_bits_addr; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_id = io_AXI4SlavePorts_writeAddr_bits_id; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_size = io_AXI4SlavePorts_writeAddr_bits_size; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_len = io_AXI4SlavePorts_writeAddr_bits_len; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_burst = io_AXI4SlavePorts_writeAddr_bits_burst; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_cache = io_AXI4SlavePorts_writeAddr_bits_cache; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_lock = io_AXI4SlavePorts_writeAddr_bits_lock; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_prot = io_AXI4SlavePorts_writeAddr_bits_prot; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_qos = io_AXI4SlavePorts_writeAddr_bits_qos; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AW_bits_region = io_AXI4SlavePorts_writeAddr_bits_region; // @[D2dMaster.scala 51:31]
  assign Tx_io_inAXI4AR_valid = io_AXI4SlavePorts_readAddr_valid; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_addr = io_AXI4SlavePorts_readAddr_bits_addr; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_id = io_AXI4SlavePorts_readAddr_bits_id; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_size = io_AXI4SlavePorts_readAddr_bits_size; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_len = io_AXI4SlavePorts_readAddr_bits_len; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_burst = io_AXI4SlavePorts_readAddr_bits_burst; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_cache = io_AXI4SlavePorts_readAddr_bits_cache; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_lock = io_AXI4SlavePorts_readAddr_bits_lock; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_prot = io_AXI4SlavePorts_readAddr_bits_prot; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_qos = io_AXI4SlavePorts_readAddr_bits_qos; // @[D2dMaster.scala 50:30]
  assign Tx_io_inAXI4AR_bits_region = io_AXI4SlavePorts_readAddr_bits_region; // @[D2dMaster.scala 50:30]
  assign Tx_io_preAddrIn = D2dMasterCtrlRegIf_io_preAddrIn; // @[D2dMaster.scala 137:19]
  assign Tx_io_inMasterReplayLatency = D2dMasterCtrlRegIf_io_inMasterReplayLatency; // @[D2dMaster.scala 138:31]
  assign Tx_io_rx2TxCreditARWFree_valid = asyncQCreditARWFree_rd_valid; // @[D2dMaster.scala 107:28]
  assign Tx_io_rx2TxCreditARWFree_bits = asyncQCreditARWFree_rd_bits; // @[D2dMaster.scala 107:28]
  assign Tx_io_rx2TxPackageIDUsed_valid = asyncQPackageIDUsed_rd_valid; // @[D2dMaster.scala 94:28]
  assign Tx_io_rx2TxPackageIDUsed_bits = asyncQPackageIDUsed_rd_bits; // @[D2dMaster.scala 94:28]
  assign Tx_io_rx2TxCreditRBFree_valid = asyncQCreditRBFree_rd_valid; // @[D2dMaster.scala 120:27]
  assign Tx_io_rx2TxCreditRBFree_bits = asyncQCreditRBFree_rd_bits; // @[D2dMaster.scala 120:27]
  assign Tx_io_rx2TxPackageIDOut_valid = asyncQPackageIDOut_rd_valid; // @[D2dMaster.scala 133:27]
  assign Tx_io_rx2TxPackageIDOut_bits = asyncQPackageIDOut_rd_bits; // @[D2dMaster.scala 133:27]
  assign Rx_clock = clock;
  assign Rx_reset = reset;
  assign Rx_io_outAXI4R_ready = io_AXI4SlavePorts_readData_ready; // @[D2dMaster.scala 58:24]
  assign Rx_io_outAXI4B_ready = io_AXI4SlavePorts_writeResp_ready; // @[D2dMaster.scala 67:24]
  assign Rx_io_rx_clock = io_rx_clock; // @[D2dMaster.scala 71:9]
  assign Rx_io_rx_flit_valid = io_rx_flit_valid; // @[D2dMaster.scala 71:9]
  assign Rx_io_rx_flit_bits = io_rx_flit_bits; // @[D2dMaster.scala 71:9]
  assign Rx_io_rx_creditARW_free = io_rx_creditARW_free; // @[D2dMaster.scala 71:9]
  assign Rx_io_rx_replayPkgID = io_rx_replayPkgID; // @[D2dMaster.scala 71:9]
  assign rstTxSync_clock = io_txClock; // @[D2dMaster.scala 74:22]
  assign rstTxSync_reset_in = reset; // @[D2dMaster.scala 75:46]
  assign rstRxSync_clock = io_rx_clock; // @[D2dMaster.scala 79:22]
  assign rstRxSync_reset_in = reset; // @[D2dMaster.scala 80:46]
  assign asyncQPackageIDUsed_wr_clock = io_rx_clock; // @[D2dMaster.scala 88:32]
  assign asyncQPackageIDUsed_wr_reset = rstRxSync_reset_out; // @[D2dMaster.scala 89:32]
  assign asyncQPackageIDUsed_wr_valid = Rx_io_rx2TxPackageIDUsed_valid; // @[D2dMaster.scala 93:26]
  assign asyncQPackageIDUsed_wr_bits = Rx_io_rx2TxPackageIDUsed_bits; // @[D2dMaster.scala 93:26]
  assign asyncQPackageIDUsed_rd_clock = io_txClock; // @[D2dMaster.scala 90:32]
  assign asyncQPackageIDUsed_rd_reset = rstTxSync_reset_out; // @[D2dMaster.scala 91:32]
  assign asyncQPackageIDUsed_rd_ready = 1'h1; // @[D2dMaster.scala 94:28]
  assign asyncQCreditARWFree_wr_clock = io_rx_clock; // @[D2dMaster.scala 101:32]
  assign asyncQCreditARWFree_wr_reset = rstRxSync_reset_out; // @[D2dMaster.scala 102:32]
  assign asyncQCreditARWFree_wr_valid = Rx_io_rx2TxCreditARWFree_valid; // @[D2dMaster.scala 106:26]
  assign asyncQCreditARWFree_wr_bits = Rx_io_rx2TxCreditARWFree_bits; // @[D2dMaster.scala 106:26]
  assign asyncQCreditARWFree_rd_clock = io_txClock; // @[D2dMaster.scala 103:32]
  assign asyncQCreditARWFree_rd_reset = rstTxSync_reset_out; // @[D2dMaster.scala 104:32]
  assign asyncQCreditRBFree_wr_clock = clock; // @[D2dMaster.scala 114:31]
  assign asyncQCreditRBFree_wr_reset = reset; // @[D2dMaster.scala 115:52]
  assign asyncQCreditRBFree_wr_valid = Rx_io_rx2TxCreditRBFree_valid; // @[D2dMaster.scala 119:25]
  assign asyncQCreditRBFree_wr_bits = Rx_io_rx2TxCreditRBFree_bits; // @[D2dMaster.scala 119:25]
  assign asyncQCreditRBFree_rd_clock = io_txClock; // @[D2dMaster.scala 116:31]
  assign asyncQCreditRBFree_rd_reset = rstTxSync_reset_out; // @[D2dMaster.scala 117:31]
  assign asyncQCreditRBFree_rd_ready = Tx_io_rx2TxCreditRBFree_ready; // @[D2dMaster.scala 120:27]
  assign asyncQPackageIDOut_wr_clock = io_rx_clock; // @[D2dMaster.scala 127:31]
  assign asyncQPackageIDOut_wr_reset = rstRxSync_reset_out; // @[D2dMaster.scala 128:31]
  assign asyncQPackageIDOut_wr_valid = Rx_io_rx2TxPackageIDOut_valid; // @[D2dMaster.scala 132:25]
  assign asyncQPackageIDOut_wr_bits = Rx_io_rx2TxPackageIDOut_bits; // @[D2dMaster.scala 132:25]
  assign asyncQPackageIDOut_rd_clock = io_txClock; // @[D2dMaster.scala 129:31]
  assign asyncQPackageIDOut_rd_reset = rstTxSync_reset_out; // @[D2dMaster.scala 130:31]
  assign asyncQPackageIDOut_rd_ready = Tx_io_rx2TxPackageIDOut_ready; // @[D2dMaster.scala 133:27]
  assign D2dMasterCtrlRegIf_clock = clock;
  assign D2dMasterCtrlRegIf_reset = reset;
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_valid = io_ctrlBusPorts_readAddr_valid; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_readAddr_bits_addr = io_ctrlBusPorts_readAddr_bits_addr; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_readData_ready = io_ctrlBusPorts_readData_ready; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_valid = io_ctrlBusPorts_writeAddr_valid; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_writeAddr_bits_addr = io_ctrlBusPorts_writeAddr_bits_addr; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_valid = io_ctrlBusPorts_writeData_valid; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_writeData_bits_data = io_ctrlBusPorts_writeData_bits_data; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_ctrlBusPorts_writeResp_ready = io_ctrlBusPorts_writeResp_ready; // @[D2dMaster.scala 136:19]
  assign D2dMasterCtrlRegIf_io_txDebugReplayState = Tx_io_txDebugReplayState; // @[D2dMaster.scala 139:44]
  assign D2dMasterCtrlRegIf_io_txDebugReplayQueue = Tx_io_txDebugReplayQueue; // @[D2dMaster.scala 140:44]
  assign D2dMasterCtrlRegIf_io_txDebugReplayCnt = Tx_io_txDebugReplayCnt; // @[D2dMaster.scala 141:42]
  assign D2dMasterCtrlRegIf_io_txDebugState = Tx_io_txDebugState; // @[D2dMaster.scala 142:38]
  assign D2dMasterCtrlRegIf_io_rxDebugState = Rx_io_rxDebugState; // @[D2dMaster.scala 144:38]
  assign D2dMasterCtrlRegIf_io_rxDebugLastCorrectPkgID = Rx_io_rxDebugLastCorrectPkgID; // @[D2dMaster.scala 145:49]
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
    if (reset) begin // @[D2dMaster.scala 23:33]
      readDataFirstReg <= 1'h0; // @[D2dMaster.scala 23:33]
    end else begin
      readDataFirstReg <= _GEN_6;
    end
    if (reset) begin // @[D2dMaster.scala 24:33]
      readDataIdPreReg <= 2'h0; // @[D2dMaster.scala 24:33]
    end else if (_D2dIdAxiArPreQueue_io_deq_ready_T_1 & _D2dIdAxiArPreQueue_io_deq_ready_T & ~
      io_AXI4SlavePorts_readData_bits_last) begin // @[D2dMaster.scala 31:102]
      readDataIdPreReg <= D2dIdAxiArPreQueue_io_deq_bits; // @[D2dMaster.scala 33:22]
    end else if (_T_2 & io_AXI4SlavePorts_readData_bits_last) begin // @[D2dMaster.scala 34:107]
      readDataIdPreReg <= D2dIdAxiArPreQueue_io_deq_bits; // @[D2dMaster.scala 36:22]
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
  _RAND_2 = {1{`RANDOM}};
  readDataFirstReg = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  readDataIdPreReg = _RAND_3[1:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
