
// --========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2005-2013 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
// -----------------------------------------------------------------------------
//
//  Version and Release Control Information:
//
//  File Revision          : 150003
//  File Date              :  2013-05-09 16:14:54 +0100 (Thu, 09 May 2013)
//
//  Release Information    : PL401-r1p2-00rel0
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Purpose: Clock and Reset Interface
//
// This block generates the clock and reset signals
//
// The generation logic can be controlled via the APB interface, which has the
// following programmers interface:
//
// Each clock_domain has one register where:
//
// [7:0] clock divisor
// [15:8] offset
// [16] reset_n bit
// [17] reset bit
//
//
// NB This block will only update clock periods on the rising edge of the clock
//    NB THIS BLOCK IS APB3
// --=========================================================================--

`timescale 1ns/1ps

module clk_reset_if
  (

   //Signals for each clock

   clk0clk,
   clk0clk_tb,
   clk0resetn,
   clk0clk_r,
   clk0resetn_r,
   clk0en,
   clk0en_apb,


   //Global TB clocks
   clk_tb,
   resetn_tb,

   //APB programming interface
   prdata,
   pready,
   psel,
   penable,
   pslverr,
   pwrite,
   paddr,
   pwdata
  );

  // Clock and Resets

  output       clk0clk;
  output       clk0clk_tb;
  output       clk0resetn;
  output       clk0clk_r;
  output       clk0resetn_r;
  output       clk0en;
  output       clk0en_apb;


  // Global resets
  output        clk_tb;
  output        resetn_tb;

  // APB3 Block Interface
  output [31:0] prdata;
  output        pready;
  input         psel;
  input         penable;
  input         pwrite;
  input [31:0]  paddr;
  input [31:0]  pwdata;
  output        pslverr;

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
// PSEL decoding is done using bits [15:12], so look at [11:0] here
`define CLK_REG0       12'd0       // Register 0 Offset

`define CLK_REG1       12'd4       // Register 1 Offset
`define CLK_REG1_INIT  32'h00000000  // Initial Value


`define INT_CLK_PERIOD 50 // Internal Clock Period


//------------------------------------------------------------------------------
// Registers
//------------------------------------------------------------------------------
  // Clock and Reset in AXI domain
  reg           int_clk_i;
  reg           int_resetn_init;


  // Used in generation of reset
  integer       i;


  reg          clk0clk;
  reg          clk0clk_tb;
  reg          clk0clk_r;
  reg          clk0resetn;
  reg          clk0resetn_r;


//------------------------------------------------------------------------------
// Wires
//------------------------------------------------------------------------------
  //shared write signals
  wire          enable;
  reg [31:0]    prdata;




  // APB write decode
  wire          def_reg_wr;

  wire          reg_clk0_wr;
  reg [31:0]    reg_clk0;

  reg  [7:0]    clk0_count;
  wire [7:0]    clk0_count_next;
  wire [7:0]    clk0_ratio;
  wire [7:0]    clk0_ratio_in;
  wire [7:0]    clk0_en_ratio;
  reg  [7:0]    clk0_en_count;

  reg           clk0clk_int;
  reg           clk0resetn_init;
  wire          assert_clk0resetn;
  wire          assert_clk0resetn_r;
  reg           deassert_clk0resetn;
  reg           deassert_clk0resetn_r;
  wire          clk0_update;
  wire          clk0_up_del;
  wire          clk0_up_or;
  wire          clk0en_del;
  wire          clk0en_apb_a;
  wire          clk0en_apb_z;
  wire          default_slave;
  reg [8:0]     count;
  wire [8:0]    next_count;
  reg           cgen_reset;
  reg           clk_tb;
  reg           resetn_tb_init;
  reg  [1:0]     clk_stop_reg;
  reg           rclk_stop_reg;
  wire [1:0]     clk_stop;
  wire           rclk_stop;
  reg           disable_clk_gate_reg;
  wire          disable_clk_gate;

 

//------------------------------------------------------------------------------
// APB write logic
//------------------------------------------------------------------------------
// Revisit add terms
  always@(psel or penable or paddr or pwrite 
          or reg_clk0) begin
    prdata = 32'b0;
    if(psel && penable)
      case(paddr[11:0])
       `CLK_REG1 : prdata = reg_clk0;
       default   : prdata = 32'd0;
      endcase
  end

  //PREADY is held low while enable is high and no wr signal is accepted
  assign default_slave = enable &
                         (paddr[11:0] != `CLK_REG0
                          & paddr[11:0] != `CLK_REG1
                         );

  assign pready = ~enable | def_reg_wr | reg_clk0_wr |default_slave;


  assign enable = (psel & pwrite & penable);

  assign pslverr = 1'b0;


  assign def_reg_wr = (paddr[11:0] == `CLK_REG0) & enable;

  always @ (posedge clk_tb or negedge int_resetn_init) begin
    if (!int_resetn_init) begin
        clk_stop_reg         <= 32'b0;
        rclk_stop_reg        <= 1'b0;
        disable_clk_gate_reg <= 1'b0;
    end else if (def_reg_wr) begin
        clk_stop_reg         <= pwdata[0];
        rclk_stop_reg        <= pwdata[1];
        disable_clk_gate_reg <= pwdata[2];
    end
  end

  assign clk_stop         =  clk_stop_reg;
  assign rclk_stop        =  rclk_stop_reg;
  assign disable_clk_gate = disable_clk_gate_reg | clk_stop[1];


  assign reg_clk0_wr = (paddr[11:0] == `CLK_REG1) & enable;

  always @ (posedge clk_tb or negedge int_resetn_init) begin
    if (!int_resetn_init) begin
      reg_clk0 <= `CLK_REG1_INIT;
    end else if (reg_clk0_wr) begin
      reg_clk0 <= pwdata;
    end else if (def_reg_wr) begin
       reg_clk0[17:16] <= pwdata[17:16];
    end
  end


//------------------------------------------------------------------------------
// Initial Clock and Reset Generation
//------------------------------------------------------------------------------

  initial
    begin
      int_clk_i  = 1'b1;
    end

  // Generate internal clock
  always
    begin
       #`INT_CLK_PERIOD int_clk_i  <= ~int_clk_i;
    end

  // Hold reset low initially for 10 cycles
  initial
    begin
      int_resetn_init = 0;
      for (i = 0; i < 10; i = i + 1)
        @(int_clk_i);
      int_resetn_init = 1;
    end

  // Hold cgen_reset low initially for 1 ns
  initial
    begin
      cgen_reset = 1'b1;
      #1 cgen_reset = 1'b0;
      #1 cgen_reset = 1'b1;
    end

   always@(posedge clk_tb) begin
      begin
         resetn_tb_init <= int_resetn_init;
      end
   end

  //Assign resetn_tb
  assign resetn_tb = resetn_tb_init & int_resetn_init;

//------------------------------------------------------------------------------
// Reset Generation
//------------------------------------------------------------------------------



   assign assert_clk0resetn   = ~reg_clk0[17];
   assign assert_clk0resetn_r = ~reg_clk0[16];

   always@(posedge clk0clk_int or negedge cgen_reset) begin
      if (!cgen_reset) begin
         deassert_clk0resetn   <= 1'b1;
         deassert_clk0resetn_r <= 1'b1;
      end else begin
         deassert_clk0resetn   <= assert_clk0resetn;
         deassert_clk0resetn_r <= assert_clk0resetn_r;
      end
   end

   always@(posedge clk0clk_int) begin
      begin
         clk0resetn_init <= int_resetn_init;
      end
   end

   initial
      begin
         clk0resetn   = 1'b0;
         clk0resetn_r = 1'b0;
      end

   always@(assert_clk0resetn   or deassert_clk0resetn   or clk0resetn_init or int_resetn_init)
      begin
         clk0resetn   = assert_clk0resetn   & deassert_clk0resetn   & clk0resetn_init & int_resetn_init;
      end

   always@(assert_clk0resetn_r or deassert_clk0resetn_r or clk0resetn_init or int_resetn_init)
      begin
         clk0resetn_r = assert_clk0resetn_r & deassert_clk0resetn_r & clk0resetn_init & int_resetn_init;
      end

     

//------------------------------------------------------------------------------
// Clock Generation
//------------------------------------------------------------------------------
  always@(posedge int_clk_i or negedge cgen_reset) begin
      if (!cgen_reset) begin
         clk0clk_int   <= 1'b0;
         clk0clk       <= 1'b0;
         clk0clk_r     <= 1'b0;
         clk0clk_tb    <= 1'b0;
         
         count <= 9'h00;
         clk_tb  <= 1'b0;
      end else begin
         clk_tb  <= ~clk_tb;
         count <= next_count;
         
         if (~clk_stop[0] || ~clk0resetn) begin
             clk0clk_int   <= clk0_update;
             clk0clk       <= clk0_update;
             clk0clk_r     <= clk0_update;
             
         end
         clk0clk_tb    <= clk0_update;
         
      end
  end

  assign next_count = count + 9'b1;


  assign clk0_update = ({clk0_count, 1'b1} == next_count);

  // Generate aclk from register ratio
  always@(posedge int_clk_i or negedge cgen_reset) begin
    if (!cgen_reset)
      clk0_count <= 1'b0;
    else if (clk0_update)
      clk0_count <= next_count[8:1] + clk0_ratio;
    else if (reg_clk0_wr)
      //Load with the next alligned count value
      clk0_count <= count[8:1] + clk0_count_next + pwdata[15:8];
  end

  assign clk0_count_next = clk0_ratio_in - (count[8:1] % clk0_ratio_in);

  //Create ENABLE to divide CLK
  always@(posedge clk0clk_int or negedge cgen_reset) begin
    if (!cgen_reset)
      clk0_en_count <= 8'h01;
    else if ((clk0_en_count == clk0_en_ratio) || reg_clk0_wr || (clk0_en_ratio == 8'h01))
      clk0_en_count <= 8'h01;
    else if (clk0_en_ratio != 8'h01)
      clk0_en_count <= clk0_en_count + 8'h01;
  end

  assign clk0_offset_diff = {8{reg_clk0_wr}} & (pwdata[15:8] - reg_clk0[15:8]);

  assign clk0_ratio = (|reg_clk0[7:0]) ? reg_clk0[7:0] : 8'b00000001;
  assign clk0_ratio_in = (|pwdata[7:0]) ? pwdata[7:0] : 8'b00000001;
  assign clk0_en_ratio = (|reg_clk0[25:18]) ? reg_clk0[25:18] : 8'b00000001;
  assign #2 clk0_up_del = clk0_update;
  assign clk0_up_or = clk0_update | clk0_up_del;
  assign clk0en = clk0_up_or;
  assign clk0en_del = clk0_up_del;
  assign clk0en_apb_a = (clk0_en_count == clk0_en_ratio) & clk0_update;
  assign #2 clk0en_apb_z = clk0en_apb_a;
  assign clk0en_apb = clk0en_apb_a | clk0en_apb_z;


endmodule

// --================================== End ==================================--
