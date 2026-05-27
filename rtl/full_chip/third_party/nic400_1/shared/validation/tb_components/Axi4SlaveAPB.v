//------------------------------------------------------------------------------
//   The confidential and proprietary information contained in this file may
//   only be used by a person authorised under and to the extent permitted
//   by a subsisting licensing agreement from ARM Limited.
//    (C) COPYRIGHT 2010-2012 ARM Limited
//        ALL RIGHTS RESERVED
//   This entire notice must be reproduced on all copies of this file
//   and copies of this file may only be made by a person if such person is
//   permitted to do so under the terms of a subsisting license agreement
//   from ARM Limited.
//
//  ----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Date           :
//  File Revision       : $Revision:$
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             : This is the AXI4 Slave Capture Block
//------------------------------------------------------------------------------

module Axi4SlaveAPB
  (
   // Global Signals
   ACLK,
   ARESETn,

   // Write Address Channel
   AWVALID_VECT,
   AWVALID,
   AWREADY,
   AWID,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
   AWREGION,
   AWQV,
   AWUSER,

   // Write Channel
   WVALID,
   WREADY,
   WLAST,
   WDATA,
   WSTRB,
   WUSER,

   // Write Response Channel
   BVALID,
   BREADY,
   BID,
   BRESP,
   BUSER,

   // Read Address Channel
   ARVALID_VECT,
   ARVALID,
   ARREADY,
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
   ARREGION,
   ARQV,
   ARUSER,

   // Read Channel
   RVALID,
   RREADY,
   RID,
   RLAST,
   RDATA,
   RRESP,
   RUSER,

   pclk,
   presetn,
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
  parameter VALID_WIDTH = 1;         // valid_vect width, default = 1-bit

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
  parameter VALID_MAX  = VALID_WIDTH-1; // valid_vect max index
  parameter DATA_MAX   = DATA_WIDTH-1;  // data max index
  parameter STRB_WIDTH = DATA_WIDTH/8;  // WSTRB width
  parameter STRB_MAX   = STRB_WIDTH-1;  // WSTRB max index
  parameter ID_MAX     = ID_WIDTH-1;    // ID max index

  parameter AWUSER_MAX = AWUSER_WIDTH-1; // AWUSER max index
  parameter WUSER_MAX =  WUSER_WIDTH-1; // WUSER  max index
  parameter BUSER_MAX =  BUSER_WIDTH-1; // BUSER  max index
  parameter ARUSER_MAX = ARUSER_WIDTH-1; // ARUSER max index
  parameter RUSER_MAX =  RUSER_WIDTH-1; // RUSER  max index
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
  input  [VALID_MAX:0] AWVALID_VECT;
  input                AWVALID;
  input                AWREADY;
  input     [ID_MAX:0] AWID;
  input         [31:0] AWADDR;
  input          [7:0] AWLEN;
  input          [2:0] AWSIZE;
  input          [1:0] AWBURST;
  input          [3:0] AWCACHE;
  input                AWLOCK;
  input          [2:0] AWPROT;
  input          [3:0] AWREGION;
  input          [3:0] AWQV;
  input [AWUSER_MAX:0] AWUSER;


  // INDEX:        - Write Data Channel
  // =====
  input                WVALID;
  input                WREADY;
  input   [DATA_MAX:0] WDATA;
  input   [STRB_MAX:0] WSTRB;
  input  [WUSER_MAX:0] WUSER;
  input                WLAST;


  // INDEX:        - Write Response Channel
  // =====
  input                BVALID;
  input                BREADY;
  input     [ID_MAX:0] BID;
  input          [1:0] BRESP;
  input  [BUSER_MAX:0] BUSER;


  // INDEX:        - Read Address Channel
  // =====
  input  [VALID_MAX:0] ARVALID_VECT;
  input                ARVALID;
  input                ARREADY;
  input     [ID_MAX:0] ARID;
  input         [31:0] ARADDR;
  input          [7:0] ARLEN;
  input          [2:0] ARSIZE;
  input          [1:0] ARBURST;
  input          [3:0] ARCACHE;
  input                ARLOCK;
  input          [2:0] ARPROT;
  input          [3:0] ARREGION;
  input          [3:0] ARQV;
  input [ARUSER_MAX:0] ARUSER;


  // INDEX:        - Read Data Channel
  // =====
  input                RVALID;
  input                RREADY;
  input     [ID_MAX:0] RID;
  input   [DATA_MAX:0] RDATA;
  input          [1:0] RRESP;
  input  [RUSER_MAX:0] RUSER;
  input                RLAST;

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
  input                presetn;

  //External Wait bus
  input [EW_MAX:0]      WAIT_DATA;
  input                 WAIT_REQ;
  input                 WAIT_ACK;



//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
`define REG0       12'h000       // Register 0 Offset
`define REG1       12'h004       // Register 4 Offset

  
`define REG2       12'h008       // Register 8 Offset
`define REG3       12'h00c       // Register c Offset
`define REG4       12'h010       // Register 10 offset
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
  wire [31:0]          reg1;
  wire [31:0]          reg2;
  wire [31:0]          reg3;
  wire [31:0]          reg4; // decode
  wire [31:0]          reg5; // fwd_aw_counter
  wire [31:0]          reg6; // fwd_ar_counter
  wire [31:0]          reg7; // fwd_w_counter
  wire [31:0]          reg8; // fwd_aw_write
  wire [31:0]          reg9; // fwd_ar_write
  wire [31:0]          reg10;// fwd_w_write
  reg                  req_aw_hndshk;
  reg                  arvalid_reg;
  reg                  awvalid_reg;
  reg                  awvalid_set;
  reg                  arvalid_set;
  reg                  wvalid_set;
  reg [31:0]           arvalid_falls;
  reg [31:0]           awvalid_falls;
  wire                 arvalid_fall;
  wire                 awvalid_fall;
  reg[7:0]             valid;
  reg[3:0]             qv;
  reg[3:0]             region;
  reg[31:0]            fwd_aw_counter;
  reg[31:0]            fwd_ar_counter;
  reg[31:0]            fwd_w_counter;
  reg[31:0]            fwd_aw_write;
  reg[31:0]            fwd_ar_write;
  reg[31:0]            fwd_w_write;

reg  [VALID_MAX:0]     ARVALID_int;
reg  [VALID_MAX:0]     AWVALID_int;

reg  [7:0]             ARVALID_val;
reg  [7:0]             AWVALID_val;

//------------------------------------------------------------------------------
// APB  logic
//------------------------------------------------------------------------------
  assign PREADY = 1'b1;

  always@(enable or PADDR or PWRITE or
          reg0 or reg1 or reg2 or reg3 or reg4 or reg5 or reg6 or reg7 or reg8 or reg9 or reg10) begin
    PRDATA = 32'b0;
    if(enable && !PWRITE)
      case(PADDR[11:0])
        `REG0 : PRDATA = reg0;
        `REG1 : PRDATA = reg1;
        `REG2 : PRDATA = reg2;
        `REG3 : PRDATA = reg3;
        `REG4 : PRDATA = reg4;
        `REG5 : PRDATA = reg5;
        `REG6 : PRDATA = reg6;
        `REG7 : PRDATA = reg7;
        `REG8 : PRDATA = reg8;
        `REG9 : PRDATA = reg9;
        `REG10: PRDATA = reg10;
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
// Register 1 - Early Write Response Enable
//------------------------------------------------------------------------------

 assign reg1 = {31'b0, req_aw_hndshk};
`ifndef SN
 // Force and Release to enable/disable early write response
 always @(req_aw_hndshk)
  begin: ewr_force
    if (req_aw_hndshk) begin
      force   uAxiSlave.uFrsWTransC.req_aw_hndshk = 1'b1;
    end else begin
      force   uAxiSlave.uFrsWTransC.req_aw_hndshk = 1'b0;
    end
  end
`endif
 // APB Regsiter
 always @(posedge ACLK or negedge ARESETn)
  begin: ewr_reg
    if (~ARESETn) begin
      req_aw_hndshk <= 1'b1;
    end else if (PADDR == `REG1 && PWRITE && PSEL && PENABLE) begin
      req_aw_hndshk <= PWDATA[0];
    end
  end

//------------------------------------------------------------------------------
//Read the Value of the Valid into the decode register
//------------------------------------------------------------------------------
  //Re-encode the valid signal
  //AW Channel
  always @(AWVALID_VECT)
    begin

      AWVALID_int = AWVALID_VECT >> 1;
      AWVALID_val = 8'b0;

      while (AWVALID_int != {VALID_WIDTH{1'b0}}) begin
          AWVALID_int = AWVALID_int >> 1;
          AWVALID_val = AWVALID_val + 1;
      end
    end

  //AR Channel
  always @(ARVALID_VECT)
    begin

     ARVALID_int = ARVALID_VECT >> 1;
     ARVALID_val = 8'b0;

     while (ARVALID_int != {VALID_WIDTH{1'b0}}) begin
          ARVALID_int = ARVALID_int >> 1;
          ARVALID_val = ARVALID_val + 1;
     end
  end

 always @(negedge ARESETn or posedge ACLK)
  begin :AX_decode 
    if (!ARESETn) 
    begin
      valid  <= 8'h00;
      qv     <= 4'h0;
      region <= 4'h0;
    end
    else if(AWVALID)
    begin
      region <= AWREGION;
      qv     <= AWQV;
      valid  <= AWVALID_val;
    end
    else if(ARVALID)
    begin
      region <= ARREGION;
      qv     <= ARQV;
      valid  <= ARVALID_val;
    end
  end

  assign reg4 = {16'b0,valid,qv,region};
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
  
//--------------------------------------------------------------------------------
// Count the clock cycles till AR/AW/W Valid goes high
//--------------------------------------------------------------------------------
assign reg5 = fwd_aw_counter;
assign reg6 = fwd_ar_counter;
assign reg7 = fwd_w_counter;
//assign reg8 = fwd_aw_write;

always @(negedge ARESETn or posedge ACLK)
  begin : forward_awwrite
    if (!ARESETn)
    begin
      fwd_aw_write <= 32'h00000000;
    end
    else if(PADDR == `REG8 && PWRITE && PSEL && PENABLE)
    begin
       fwd_aw_write <= PWDATA;
    end
  end

  
always @(negedge ARESETn or posedge ACLK)
  begin : aw_val
    if (!ARESETn) begin
      fwd_aw_counter <= 32'h00000000;
      awvalid_set <= 1'b0;
    end
    else if (PADDR == `REG8 && PWRITE && PSEL && PENABLE) begin
        fwd_aw_counter <= 32'h00000000;
        awvalid_set <= 1'b0;
    end 
    else if((fwd_aw_write == WAIT_DATA) && (WAIT_REQ ^ WAIT_ACK)) begin
        fwd_aw_counter <= {31'b0, ~AWVALID};
        awvalid_set <= ~AWVALID;
    end
    else begin
      if(AWVALID)
         awvalid_set <=1'b0;
      else if(awvalid_set)  
         fwd_aw_counter <= fwd_aw_counter + 32'b1;
    end
  end
always @(negedge ARESETn or posedge ACLK)
  begin : forward_arwrite
    if (!ARESETn)
    begin
      fwd_ar_write <= 32'h00000000;
    end
    else if(PADDR == `REG9 && PWRITE && PSEL && PENABLE)
    begin
       fwd_ar_write <= PWDATA;
    end
  end
always @(negedge ARESETn or posedge ACLK)
  begin : ar_val
    if (!ARESETn) begin
      fwd_ar_counter <= 32'h00000000;
      arvalid_set <= 1'b0;
    end
    else if (PADDR == `REG9 && PWRITE && PSEL && PENABLE) begin
        fwd_ar_counter <= 32'h00000000;
        arvalid_set <= 1'b0;
    end 
    else if((fwd_ar_write == WAIT_DATA) && (WAIT_REQ ^ WAIT_ACK)) begin
        fwd_ar_counter <= {31'b0, ~ARVALID};
        arvalid_set <= ~ARVALID;
    end
    else begin
      if(ARVALID)
         arvalid_set <=1'b0;
      else if(arvalid_set)  
         fwd_ar_counter <= fwd_ar_counter + 32'b1;
    end
  end
always @(negedge ARESETn or posedge ACLK)
  begin : forward_wwrite
    if (!ARESETn)
    begin
      fwd_w_write <= 32'h00000000;
    end
    else if(PADDR == `REG10 && PWRITE && PSEL && PENABLE)
    begin
       fwd_w_write <= PWDATA;
    end
  end
always @(negedge ARESETn or posedge ACLK)
  begin : w_val
    if (!ARESETn) begin
      fwd_w_counter <= 32'h00000000;
      wvalid_set <= 1'b0;
    end
    else if (PADDR == `REG10 && PWRITE && PSEL && PENABLE) begin
        fwd_w_counter <= 32'h00000000;
        wvalid_set <= 1'b0;
    end 
    else if((fwd_w_write == WAIT_DATA) && (WAIT_REQ ^ WAIT_ACK)) begin
        fwd_w_counter <= {31'b0, ~WVALID};
        wvalid_set <= ~WVALID;
    end
    else begin
      if(WVALID)
         wvalid_set <=1'b0;
      else if(wvalid_set)  
         fwd_w_counter <= fwd_w_counter + 32'b1;
    end
  end


endmodule


