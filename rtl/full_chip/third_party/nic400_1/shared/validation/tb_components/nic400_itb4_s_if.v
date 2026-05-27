// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2006-2012 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 135247
//
// Date                   :  2012-08-17 10:56:37 +0100 (Fri, 17 Aug 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC400 axi slave interface
//
// Description : This block is an ITB4 slave that can be used in the main NIC400
//               testbench.
//
//
// This file is used to allow differences between standard AXI and NIC400 internal
// AXI that are never exposed to the system.
//
//  These differences are:
//
//    1) B and R READY signals can be X when valid is not true. (READY-ON-VALID path)
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module nic400_itb4_s_if(

                 // Global signals
                 ACLK,
                 ACLKEN,
                 ARESETn,

                 // Read Address Channel
                 AID,
                 AADDR,
                 ALEN,
                 ASIZE,
                 ABURST,
                 AVALID,
                 AVALID_VECT,
                 AREADY,
                 ALOCK,
                 ACACHE,
                 APROT,
                 AUSER,
                 AREGION,
                 AWRITE,

                 // Read Channel
                 DID,
                 DLAST,
                 DDATA,
                 DRESP,
                 DVALID,
                 DREADY,
                 DUSER,
                 DBNR,

                 // Write Channel
                 WID,
                 WLAST,
                 WSTRB,
                 WDATA,
                 WVALID,
                 WREADY,
                 WUSER,

                 //EMIT/WAIT channels .. only used in FRM mode
                 EMIT_DATA,
                 EMIT_REQ,
                 EMIT_ACK,

                 WAIT_DATA,
                 WAIT_REQ,
                 WAIT_ACK,

                 // APB3 Interface
                 PCLK,
                 PRESETn,
                 PSEL,
                 PENABLE,
                 PWRITE,
                 PADDR,
                 PWDATA,
                 PREADY,
                 PSLVERR,
                 PRDATA

);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter ADDR_WIDTH       = 32;
  parameter AUSER_WIDTH      = 16;
  parameter WUSER_WIDTH      = 16;
  parameter RUSER_WIDTH      = 16;
  parameter ID_WIDTH         = 16;
  parameter VALID_WIDTH      = 1;
  parameter EW_WIDTH         = 16;


  parameter read_issuing_capability      = 16;
  parameter write_issuing_capability     = 16;
  parameter combined_issuing_capability  = 16;
  parameter limit_acceptance_capability     = 0;
  parameter leading_writes   = 0;

  parameter INSTANCE         = "undef";

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter USER_MAX_A       = (AUSER_WIDTH == 0) ? 0 : AUSER_WIDTH - 1;
  parameter USER_MAX_W       = (WUSER_WIDTH == 0)  ? 0 : WUSER_WIDTH - 1;
  parameter USER_MAX_R       = (RUSER_WIDTH == 0)  ? 0 : RUSER_WIDTH - 1;
  parameter ID_MAX           = (ID_WIDTH == 0)     ? 0 : ID_WIDTH - 1;
  parameter VALID_MAX        = VALID_WIDTH - 1;
  parameter EW_MAX           = EW_WIDTH -1;

  parameter regions_flag     = 0;

  parameter DriveOnlyOnEnable = 0;


// -----------------------------------------------------------------------------
//  IO Declaration
// -----------------------------------------------------------------------------

// Clock and Reset in AXI4 domain
input                   ACLK;            // AXI Bus Clock
input                   ACLKEN;          // AXI Bus Clock Enable
input                   ARESETn;         // AXI Reset

// Read Address Channel
input  [ID_MAX:0]       AID;            // address ID
input  [ADDR_MAX:0]     AADDR;          // address
input  [7:0]            ALEN;           // burst length
input  [2:0]            ASIZE;          // burst size
input  [1:0]            ABURST;         // burst type
input                   AVALID;         // address valid
input  [VALID_MAX:0]    AVALID_VECT;    // address valid
output                  AREADY;         // address ready
input  [3:0]            ACACHE;         // cache information
input                   ALOCK;          // lock information
input  [2:0]            APROT;          // protection information
input  [USER_MAX_A:0]   AUSER;          // protection information
input                   AWRITE;         // direction signal
input [3:0]             AREGION;

// Read Channel
output  [ID_MAX:0]      DID;            // data ID
output                  DLAST;          // last
output  [DATA_MAX:0]    DDATA;          // data
output  [1:0]           DRESP;          // response
output                  DVALID;         // response valid
input                   DREADY;         // response ready
output  [USER_MAX_R:0]  DUSER;          // protection information
output                  DBNR;           // data type signal

// Write Channel
input  [ID_MAX:0]       WID;             // Wid
input                   WLAST;           // Write last
input  [STRB_MAX:0]     WSTRB;           // Write strobes
input  [DATA_MAX:0]     WDATA;           // Write data
input                   WVALID;          // Write valid
output                  WREADY;          // Write ready
input  [USER_MAX_W:0]   WUSER;           // Read protection information

//Emit and Wait channels only used in FRM mode
output [EW_MAX:0]       EMIT_DATA;       //Emit data
output                  EMIT_REQ;        //Emit Request
input                   EMIT_ACK;        //Emit acknoledgement

input  [EW_MAX:0]       WAIT_DATA;       //Wait data
input                   WAIT_REQ;        //Wait Request
output                  WAIT_ACK;        //Waitr acknoledgement

// APB3 Interface
input                   PENABLE;         // APB Enable
input                   PWRITE;          // APB transfer(R/W) direction
input  [31:0]           PADDR;           // APB address
input  [31:0]           PWDATA;          // APB write data
output                  PREADY;          // APB transfer completion signal for slaves
output                  PSLVERR;         // APB transfer response signal for slaves
output [31:0]           PRDATA;          // APB read data for slave0
input                   PSEL;

input                   PCLK;
input                   PRESETn;

// -----------------------------------------------------------------------------
// Wire/register Declarations
// -----------------------------------------------------------------------------
wire [3:0]             AQV;             // quality value
wire [3:0]             AREGION_int;

wire  [ID_MAX:0]       RID;             // Read data ID
wire  [1:0]            RRESP;           // Read response
wire                   RVALID;          // Read response valid
wire                   RREADY;          // Read response ready

wire  [ID_MAX:0]       BID;             // Write response ID
wire  [1:0]            BRESP;           // Write response
wire                   BVALID;          // Write response valid
wire                   BREADY;          // Write response ready

wire [VALID_MAX:0]     AWVALID_EN;
wire [VALID_MAX:0]     ARVALID_EN;
wire [VALID_MAX:0]     AWVALID_VECT;
wire [VALID_MAX:0]     ARVALID_VECT;
wire                   AWVALID;
wire                   ARVALID;
wire                   AWREADY;
wire                   ARREADY;

wire                   channel_sel;     // Channel Select
wire                   next_stall;
reg                    stall;
reg                    select_random;
reg                    select_reg;
wire                   select;

// -----------------------------------------------------------------------------
//  NIC400 Test component
// -----------------------------------------------------------------------------
assign AREGION_int = (regions_flag == 0) ?  4'b0000 : AREGION;

// -----------------------------------------------------------------------------
// AXI4 Slave Block
// -----------------------------------------------------------------------------

defparam uAxiSlave.ADDR_WIDTH       = ADDR_WIDTH;
defparam uAxiSlave.DATA_WIDTH       = DATA_WIDTH;
defparam uAxiSlave.EW_WIDTH         = EW_WIDTH;
defparam uAxiSlave.ID_WIDTH         = ID_WIDTH;
defparam uAxiSlave.STRB_WIDTH       = STRB_WIDTH;
defparam uAxiSlave.WUSER_WIDTH      = USER_MAX_W + 1;
defparam uAxiSlave.RUSER_WIDTH      = USER_MAX_R + 1;
defparam uAxiSlave.AWUSER_WIDTH     = USER_MAX_A + 1;
defparam uAxiSlave.ARUSER_WIDTH     = USER_MAX_A + 1;
defparam uAxiSlave.BUSER_WIDTH      = 1'b1;
defparam uAxiSlave.INSTANCE         = INSTANCE;
defparam uAxiSlave.INSTANCE_TYPE    = "PL301_AXI4S_";
defparam uAxiSlave.read_issuing_capability  = read_issuing_capability;
defparam uAxiSlave.write_issuing_capability = write_issuing_capability;
defparam uAxiSlave.combined_issuing_capability  = combined_issuing_capability;
defparam uAxiSlave.limit_acceptance_capability  = limit_acceptance_capability;
defparam uAxiSlave.leading_writes   = leading_writes;
defparam uAxiSlave.VALID_WIDTH      = VALID_WIDTH;
defparam uAxiSlave.regions_flag     = regions_flag;
defparam uAxiSlave.DriveOnlyOnEnable = DriveOnlyOnEnable;
defparam uAxiSlave.PortIsInternal   = 1;

nic400_axi4_s_if uAxiSlave (

      .ACLK         (ACLK),
      .ACLKEN       (ACLKEN),
      .ARESETn      (ARESETn),

      .AWID         (AID),
      .AWADDR       (AADDR),
      .AWLEN        (ALEN),
      .AWQV         (AQV),
      .AWREGION     (AREGION_int),
      .AWSIZE       (ASIZE),
      .AWBURST      (ABURST),
      .AWLOCK       (ALOCK),
      .AWCACHE      (ACACHE),
      .AWPROT       (APROT),
      .AWVALID_VECT (AWVALID_VECT),
      .AWVALID      (AWVALID),
      .AWREADY      (AWREADY),
      .AWVNET       (4'b0000),

      .WDATA        (WDATA),
      .WSTRB        (WSTRB),
      .WLAST        (WLAST),
      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WVNET        (4'b0000),

      .BID          (BID),
      .BRESP        (BRESP),
      .BVALID       (BVALID),
      .BREADY       (BREADY & BVALID),

      .ARID         (AID),
      .ARADDR       (AADDR),
      .ARLEN        (ALEN),
      .ARQV         (AQV),
      .ARREGION     (AREGION_int),
      .ARSIZE       (ASIZE),
      .ARBURST      (ABURST),
      .ARLOCK       (ALOCK),
      .ARCACHE      (ACACHE),
      .ARPROT       (APROT),
      .ARVALID_VECT (ARVALID_VECT),
      .ARVALID      (ARVALID),
      .ARREADY      (ARREADY),
      .ARVNET       (4'b0000),

      .RID          (RID),
      .RDATA        (DDATA),
      .RRESP        (RRESP),
      .RLAST        (DLAST),
      .RVALID       (RVALID),
      .RREADY       (RREADY & RVALID),

      .AWUSER       (AUSER),
      .WUSER        (WUSER),
      .BUSER        (),
      .ARUSER       (AUSER),
      .RUSER        (DUSER),

      .EMIT_DATA    (EMIT_DATA),
      .EMIT_REQ     (EMIT_REQ),
      .EMIT_ACK     (EMIT_ACK),

      .WAIT_DATA    (WAIT_DATA),
      .WAIT_REQ     (WAIT_REQ),
      .WAIT_ACK     (WAIT_ACK),

      .FN_MOD       (),

      // APB3 Interface
      .PCLK         (PCLK),
      .PRESETn      (PRESETn),
      .PSEL         (PSEL),
      .PENABLE      (PENABLE),
      .PWRITE       (PWRITE),
      .PADDR        (PADDR),
      .PWDATA       (PWDATA),
      .PREADY       (PREADY),
      .PSLVERR      (PSLVERR),
      .PRDATA       (PRDATA)

  );

  assign AQV = 4'h0;


// -----------------------------------------------------------------------------
//  Mux - behavioural mux with random arbitartion;
// -----------------------------------------------------------------------------

assign next_stall = DVALID & ~DREADY;

always @(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) begin
      stall <= 1'b0;
      select_reg <= 1'b0;
    end else begin
      stall <= next_stall;
      select_reg <= channel_sel;
    end
end

//ACLK ensures that the value is regularly updated
always @(posedge ACLK) begin

    select_random = $random;

end

assign  select = (RVALID & ~BVALID) ? 1'b0 :
             ((BVALID & ~RVALID) ? 1'b1 : select_random);

assign  channel_sel = (stall) ? select_reg : select;

// Address channel assignments
assign AREADY = (AWRITE & AVALID) ? AWREADY : ARREADY;
assign AWVALID_EN = {VALID_WIDTH{AWRITE & AVALID}};
assign ARVALID_EN = {VALID_WIDTH{~AWRITE & AVALID}};
assign AWVALID_VECT = 1'b0;
assign ARVALID_VECT = 1'b0;
assign AWVALID = AWRITE & AVALID;
assign ARVALID = ~AWRITE & AVALID;

//Data channel mux
assign DBNR = channel_sel;
assign BREADY = DREADY & channel_sel;
assign RREADY = DREADY & ~channel_sel;

assign DVALID = (channel_sel) ? BVALID : RVALID;
assign DID    = (channel_sel) ? BID : RID;
assign DRESP  = (channel_sel) ? BRESP : RRESP;


endmodule

//  --=============================== End ====================================--

