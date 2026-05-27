// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2010-2012 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 123384
//
// Date                   :  2012-01-06 18:33:57 +0000 (Fri, 06 Jan 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
//  Purpose             : This is the AXI4 Master Capture Block
//============================================================================--

module Axi4MasterAPB
  (
   // Global Signals
   ACLK,
   ARESETn,

   // Write Address Channel
   AWID,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
   AWUSER,
   AWVALID,
   AWREADY,

   // Write Channel
   WLAST,
   WDATA,
   WSTRB,
   WUSER,
   WVALID,
   WREADY,

   // Write Response Channel
   BID,
   BRESP,
   BUSER,
   BVALID,
   BREADY,

   // Read Address Channel
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
   ARUSER,
   ARVALID,
   ARREADY,

   // Read Channel
   RID,
   RLAST,
   RDATA,
   RRESP,
   RUSER,
   RVALID,
   RREADY,

   pclk,
   PRDATA, 
   PREADY, 
   PSEL, 
   PENABLE, 
   PWRITE, 
   PADDR, 
   PWDATA,
   
   //External Wait bus
   WAIT_DATA,
   WAIT_REQ,
   WAIT_ACK

   );


//------------------------------------------------------------------------------
// INDEX:   1) Parameters
//------------------------------------------------------------------------------


  // INDEX:        - Configurable (user can set)
  // =====
  // Parameters below can be set by the user.

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH = 64;         // data bus width, default = 64-bit

  // Select the number of channel ID bits required
  parameter ID_WIDTH = 4;          // (A|W|R|B)ID width

  // Select the size of the USER buses, default = 32-bit
  parameter AWUSER_WIDTH = 32; // width of the user AW sideband field
  parameter WUSER_WIDTH  = 32; // width of the user W  sideband field
  parameter BUSER_WIDTH  = 32; // width of the user B  sideband field
  parameter ARUSER_WIDTH = 32; // width of the user AR sideband field
  parameter RUSER_WIDTH  = 32; // width of the user R  sideband field
  parameter EW_WIDTH     = 8;
  
   // INDEX:        - Calculated (user should not override)
  // =====
  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  parameter DATA_MAX   = DATA_WIDTH-1; // data max index
  parameter STRB_WIDTH = DATA_WIDTH/8; // WSTRB width
  parameter STRB_MAX   = STRB_WIDTH-1; // WSTRB max index
  parameter ID_MAX     = ID_WIDTH-1;   // ID max index

  parameter AWUSER_MAX = AWUSER_WIDTH-1; // AWUSER max index
  parameter  WUSER_MAX =  WUSER_WIDTH-1; // WUSER  max index
  parameter  BUSER_MAX =  BUSER_WIDTH-1; // BUSER  max index
  parameter ARUSER_MAX = ARUSER_WIDTH-1; // ARUSER max index
  parameter  RUSER_MAX =  RUSER_WIDTH-1; // RUSER  max index
  parameter EW_MAX      = EW_WIDTH - 1;

//------------------------------------------------------------------------------
// INDEX:   IO
//------------------------------------------------------------------------------


  // INDEX:        - Global Signals 
  // =====
  input                ACLK;        // AXI Clock
  input                ARESETn;     // AXI Reset


  // INDEX:        - Write Address Channel
  // =====
  input     [ID_MAX:0] AWID;
  input         [31:0] AWADDR;
  input          [7:0] AWLEN;
  input          [2:0] AWSIZE;
  input          [1:0] AWBURST;
  input          [3:0] AWCACHE;
  input          [2:0] AWPROT;
  input                AWLOCK;
  input [AWUSER_MAX:0] AWUSER;
  input                AWVALID;
  input                AWREADY;


  // INDEX:        - Write Data Channel
  // =====
  input   [DATA_MAX:0] WDATA;
  input   [STRB_MAX:0] WSTRB;
  input  [WUSER_MAX:0] WUSER;
  input                WLAST;
  input                WVALID;
  input                WREADY;


  // INDEX:        - Write Response Channel
  // =====
  input     [ID_MAX:0] BID;
  input          [1:0] BRESP;
  input  [BUSER_MAX:0] BUSER;
  input                BVALID;
  input                BREADY;


  // INDEX:        - Read Address Channel
  // =====
  input     [ID_MAX:0] ARID;
  input         [31:0] ARADDR;
  input          [7:0] ARLEN;
  input          [2:0] ARSIZE;
  input          [1:0] ARBURST;
  input          [3:0] ARCACHE;
  input          [2:0] ARPROT;
  input                ARLOCK;
  input [ARUSER_MAX:0] ARUSER;
  input                ARVALID;
  input                ARREADY;


  // INDEX:        - Read Data Channel
  // =====
  input     [ID_MAX:0] RID;
  input   [DATA_MAX:0] RDATA;
  input          [1:0] RRESP;
  input  [RUSER_MAX:0] RUSER;
  input                RLAST;
  input                RVALID;
  input                RREADY;

  // INDEX:        - Low Power Interface
  // =====

  output [31:0]        PRDATA; 
  output               PREADY; 
  input                PSEL; 
  input                PENABLE; 
  input                PWRITE;
  input [31:0]         PADDR; 
  input [31:0]         PWDATA;
  input                pclk;

  //External Wait bus
  input [EW_MAX:0]      WAIT_DATA;
  input                 WAIT_REQ;
  input                 WAIT_ACK;

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
`define REG0       12'h000       // Register 0 Offset
  
`define REG2       12'h008       // Register 8 Offset
`define REG3       12'h00c       // Register c Offset
`define REG5       12'h014       // Register 14 offset
`define REG6       12'h018       // Register 18 offset
`define REG7       12'h01c       // Register 1c offset
`define REG8       12'h020       // Register 20 offset
`define REG9       12'h024       // Register 24 offset
`define REG10      12'h028       // Register 28 offset
 
//------------------------------------------------------------------------------
// wires
//------------------------------------------------------------------------------

  reg [31:0]           PRDATA;
  wire                 enable;
  wire [31:0]          reg0;
  wire [31:0]          reg2;
  wire [31:0]          reg3;
  wire [31:0]          reg5; //awvalid_counter
  wire [31:0]          reg6; //arvalid_counter
  wire [31:0]          reg7; //rev_r_counter
  wire [31:0]          reg8; //rev_b_counter
  wire [31:0]          reg9; //rev_r_write
  wire [31:0]          reg10;//rev_b_write

  reg                  arvalid_reg;
  reg                  awvalid_reg;
  reg                  rvalid_set;
  reg                  bvalid_set;
  reg [31:0]           arvalid_falls;
  reg [31:0]           awvalid_falls;
  wire                 arvalid_fall;
  wire                 awvalid_fall;
  reg [31:0]           awvalid_counter;
  reg [31:0]           arvalid_counter;
  reg [31:0]           rev_r_counter;
  reg [31:0]           rev_b_counter;
  reg [31:0]           rev_r_write;
  reg [31:0]           rev_b_write;
//------------------------------------------------------------------------------
// APB  logic
//------------------------------------------------------------------------------
  assign PREADY = 1'b1;

  always@(enable or PADDR or PWRITE or
          reg0 or reg2 or reg3 or reg5 or reg6 or reg7 or reg8) begin
    PRDATA = 32'b0;
    if(enable && !PWRITE)
      case(PADDR[11:0])
        `REG0 : PRDATA = reg0;
        `REG2 : PRDATA = reg2;
        `REG3 : PRDATA = reg3;
        `REG5 : PRDATA = reg5;
        `REG6 : PRDATA = reg6;
        `REG7 : PRDATA = reg7;
        `REG8 : PRDATA = reg8;
        default  : PRDATA = 32'd0;
      endcase
  end

  assign enable = (PSEL & ~PWRITE & PENABLE);
  
//------------------------------------------------------------------------------
// Register 0
//------------------------------------------------------------------------------

  assign reg0 = {22'b0, BVALID, BREADY, WVALID, WREADY, AWVALID, AWREADY, 
                       RVALID, RREADY, ARVALID, ARREADY};

  
//------------------------------------------------------------------------------
// count falling edge of AXVALID (reg2 and reg3)
//------------------------------------------------------------------------------
  assign reg2 = awvalid_falls;
  assign reg3 = arvalid_falls;
  
  always @(negedge ARESETn or posedge ACLK)
  begin : AX_valid_reg
    if (!ARESETn) begin
      arvalid_reg <= 1'b0;
      awvalid_reg <= 1'b0;
    end
    else 
    begin
      arvalid_reg <= ARVALID;
      awvalid_reg <= AWVALID;
    end
  end

  assign arvalid_fall = ~ARVALID & arvalid_reg;
  assign awvalid_fall = ~AWVALID & awvalid_reg;

  always @(negedge ARESETn or posedge ACLK)
  begin : arvalid_count
    if (!ARESETn) 
      arvalid_falls <= 32'h00000000;
    else 
    begin if (arvalid_fall)
      arvalid_falls <= arvalid_falls + 1'b1;
    end
  end


  always @(negedge ARESETn or posedge ACLK)
  begin : awvalid_count
    if (!ARESETn) 
      awvalid_falls <= 32'h00000000;
    else 
    begin if (awvalid_fall)
      awvalid_falls <= awvalid_falls + 1'b1;
    end
  end
  
//------------------------------------------------------------------------------
//Count the number of times valid and ready are high together
//------------------------------------------------------------------------------
assign reg5 = awvalid_counter;
assign reg6 = arvalid_counter;

always @(negedge ARESETn or posedge ACLK)
  begin : aw_count
    if (!ARESETn) 
    begin
      awvalid_counter <= 32'h00000000; 
    end
     else if(PENABLE & PSEL & PWRITE & PADDR == `REG5)
    begin
      awvalid_counter <= PWDATA;
    end
    else if (AWVALID && AWREADY)
    begin
      awvalid_counter <= awvalid_counter + 32'b1;
    end
  end

always @(negedge ARESETn or posedge ACLK)
  begin : ar_count
    if (!ARESETn)
    begin
      arvalid_counter <= 32'h00000000;
    end
    else if(PENABLE & PSEL & PWRITE & PADDR == `REG6)
    begin
      arvalid_counter <= PWDATA;
    end
    else if (ARVALID && ARREADY)
    begin 
      arvalid_counter <= arvalid_counter + 32'b1;
    end
  end
  
//--------------------------------------------------------------------------------
// Count the clock cycles till R/B Valid goes high
//--------------------------------------------------------------------------------
assign reg7 = rev_r_counter;
assign reg8 = rev_b_counter;
 
always @(negedge ARESETn or posedge ACLK)
  begin : reverse_rwrite
    if (!ARESETn)
    begin
      rev_r_write <= 32'h00000000;
    end
    else if(PADDR == `REG9 && PWRITE && PSEL && PENABLE)
    begin
       rev_r_write <= PWDATA;
    end
  end
  
 always @(negedge ARESETn or posedge ACLK)
  begin : r_val
    if (!ARESETn) begin
      rev_r_counter <= 32'h00000000;
      rvalid_set <= 1'b0;
    end
    else if (PADDR == `REG9 && PWRITE && PSEL && PENABLE) begin
        rev_r_counter <= 32'h00000000;
        rvalid_set <= 1'b0;
    end 
    else if((rev_r_write == WAIT_DATA) && (WAIT_REQ ^ WAIT_ACK)) begin
        rev_r_counter <= {31'b0, ~RVALID};
        rvalid_set <= ~RVALID;
    end
    else begin
      if(RVALID)
         rvalid_set <=1'b0;
      else if(rvalid_set)  
         rev_r_counter <= rev_r_counter + 32'b1;
    end
  end
  
always @(negedge ARESETn or posedge ACLK)
  begin : reverse_bwrite
    if (!ARESETn)
    begin
      rev_b_write <= 32'h00000000;
    end
    else if(PADDR == `REG10 && PWRITE && PSEL && PENABLE)
    begin
       rev_b_write <= PWDATA;
    end
  end

always @(negedge ARESETn or posedge ACLK)
  begin : b_val
    if (!ARESETn) begin
      rev_b_counter <= 32'h00000000;
      bvalid_set <= 1'b0;
    end
    else if (PADDR == `REG10 && PWRITE && PSEL && PENABLE) begin
        rev_b_counter <= 32'h00000000;
        bvalid_set <= 1'b0;
    end 
    else if((rev_b_write == WAIT_DATA) && (WAIT_REQ ^ WAIT_ACK)) begin
        rev_b_counter <= {31'b0, ~BVALID};
        bvalid_set <= ~BVALID;
    end
    else begin
      if(BVALID)
         bvalid_set <=1'b0;
      else if(bvalid_set)  
         rev_b_counter <= rev_b_counter + 32'b1;
    end
  end

 
endmodule
