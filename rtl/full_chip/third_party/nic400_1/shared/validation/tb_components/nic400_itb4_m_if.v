// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2008-2011 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 122797
//
// Date                   :  2011-12-13 11:05:14 +0000 (Tue, 13 Dec 2011)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC400 axi slave interface
//
// Description : This block is an AXI master that can be used in the main NIC400
//               testbench.
// This file is used to allow differences between standard AXI and NIC400 internal
// AXI that are never exposed to the system.
//
//  These differences are:
//
//    1) None
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module nic400_itb4_m_if(

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
                 AREGION,
                 AREADY,
                 ALOCK,
                 ACACHE,
                 APROT,
                 AUSER,
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

  parameter DATA_WIDTH      = 32;
  parameter STRB_WIDTH      = 4;
  parameter ADDR_WIDTH      = 32;
  parameter ID_WIDTH        = 16;
  parameter VALID_WIDTH     = 1;
  parameter EW_WIDTH        = 16;
  parameter INSTANCE        = "undef";
  parameter WUSER_WIDTH     = 8;
  parameter RUSER_WIDTH     = 8;
  parameter AUSER_WIDTH     = 0;

  parameter read_acceptance_capability      = 16;
  parameter write_acceptance_capability     = 16;
  parameter unlimited_acceptance_capability = 0;
  parameter limit_issuing_capability        = 0;
  parameter leading_write_depth             = 0;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter USER_MAX_A       = (AUSER_WIDTH == 0) ? 0 : AUSER_WIDTH - 1;
  parameter USER_MAX_AR      = (AUSER_WIDTH == 0) ? 0 : AUSER_WIDTH - 1;
  parameter USER_MAX_AW      = (AUSER_WIDTH == 0) ? 0 : AUSER_WIDTH - 1;
  parameter USER_MAX_W       = (WUSER_WIDTH == 0)  ? 0 : WUSER_WIDTH - 1;
  parameter USER_MAX_R       = (RUSER_WIDTH == 0)  ? 0 : RUSER_WIDTH - 1;
  parameter ID_MAX           = (ID_WIDTH == 0)     ? 0 : ID_WIDTH - 1;
  parameter VALID_MAX        = VALID_WIDTH - 1;
  parameter EW_MAX           = EW_WIDTH - 1;

  parameter DriveOnlyOnEnable = 0;
  parameter MaxWaits          = 5000;


// -----------------------------------------------------------------------------
//  IO Declaration
// -----------------------------------------------------------------------------

// Clock and Reset in AXI domain
input                   ACLK;            // AXI Bus Clock
input                   ACLKEN;          // AXI Bus Clock Enable
input                   ARESETn;         // AXI Reset

// Read Address Channel
output  [ID_MAX:0]      AID;            // address ID
output  [ADDR_MAX:0]    AADDR;          // address
output  [7:0]           ALEN;           // burst length
output  [2:0]           ASIZE;          // burst size
output  [1:0]           ABURST;         // burst type
output                  AVALID;         // address valid
output  [VALID_MAX:0]   AVALID_VECT;    // address valid
output  [3:0]           AREGION;        // region select
input                   AREADY;         // address ready
output  [2:0]           APROT;          // protection information
output  [3:0]           ACACHE;         // Cache signals
output                  ALOCK;          // Lock signals
output  [USER_MAX_A:0]  AUSER;          // user fields
output                  AWRITE;         // direction signal

// Read Channel
input   [ID_MAX:0]      DID;             // Data data ID
input                   DLAST;           // Data last
input   [DATA_MAX:0]    DDATA;           // Data data
input   [1:0]           DRESP;           // Data response
input                   DVALID;          // Data response valid
output                  DREADY;          // Data response ready
input  [USER_MAX_R:0]   DUSER;           // Data user fields
input                   DBNR;            // Reponse type field

// Write Channel
output                  WLAST;           // Write last
output  [STRB_MAX:0]    WSTRB;           // Write last
output  [DATA_MAX:0]    WDATA;           // Write data
output                  WVALID;          // Write valid
input                   WREADY;          // Write ready
output  [USER_MAX_W:0]  WUSER;           // Read user fields

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

input                   PCLK;            //Testbench clock
input                   PRESETn;         //Testbench reset

// -----------------------------------------------------------------------------
// Wires
// -----------------------------------------------------------------------------
// Read Address Channel
wire   [ID_MAX:0]      ARID;            // Read address ID
wire   [ADDR_MAX:0]    ARADDR;          // Read address
wire   [3:0]           ARQV;            // Read quality value
wire   [7:0]           ARLEN;           // Read burst length
wire   [2:0]           ARSIZE;          // Read burst size
wire   [1:0]           ARBURST;         // Read burst type
wire                   ARVALID;         // Read address valid
wire   [VALID_MAX:0]   ARVALID_VECT;    // Read address valid
wire   [3:0]           ARREGION;        // Read region select
wire                   ARREADY;         // Read address ready
wire   [2:0]           ARPROT;          // Read protection information
wire   [3:0]           ARCACHE;         // Read Cache signals
wire                   ARLOCK;          // Read Lock signals
wire   [USER_MAX_AR:0] ARUSER;          // Read user fields

wire                   RVALID;          // Read response valid
wire                   RREADY;          // Read response ready

// Write Address Channel
wire   [ID_MAX:0]      AWID;            // Write address ID
wire   [ADDR_MAX:0]    AWADDR;          // Write address
wire   [3:0]           AWQV;            // Write quality value
wire   [7:0]           AWLEN;           // Write burst length
wire   [2:0]           AWSIZE;          // Write burst size
wire   [1:0]           AWBURST;         // Write burst type
wire                   AWVALID;         // Write address valid
wire   [VALID_MAX:0]   AWVALID_VECT;    // Write address valid
wire   [3:0]           AWREGION;        // Write region selection
wire                   AWREADY;         // Write address ready
wire   [3:0]           AWCACHE;         // Write Cache signals
wire                   AWLOCK;          // Write Lock signals
wire   [2:0]           AWPROT;          // Write protection information
wire   [USER_MAX_AW:0] AWUSER;          // Read user fields

// Write Channel
wire                   WLAST;           // Write last
wire   [STRB_MAX:0]    WSTRB;           // Write last
wire   [DATA_MAX:0]    WDATA;           // Write data
wire                   WVALID;          // Write valid
wire                   WREADY;          // Write ready
wire   [USER_MAX_W:0]  WUSER;           // Read user fields

// Write Response Channel
wire                   BVALID;          // Write response valid
wire                   BREADY;          // Write response ready

wire                   channel_sel;     // Channel Select
wire                   next_stall;
reg                    stall;
wire                   select;
reg                    select_reg;
reg                    select_random;


// -----------------------------------------------------------------------------
//  NIC400 Test component
// -----------------------------------------------------------------------------

defparam uAxiMaster.ADDR_WIDTH       = ADDR_WIDTH;
defparam uAxiMaster.DATA_WIDTH       = DATA_WIDTH;
defparam uAxiMaster.EW_WIDTH         = EW_WIDTH;
defparam uAxiMaster.ID_WIDTH         = ID_WIDTH;
defparam uAxiMaster.VALID_WIDTH      = VALID_WIDTH;
defparam uAxiMaster.STRB_WIDTH       = STRB_WIDTH;
defparam uAxiMaster.AWUSER_WIDTH     = AUSER_WIDTH;
defparam uAxiMaster.ARUSER_WIDTH     = AUSER_WIDTH;
defparam uAxiMaster.WUSER_WIDTH      = WUSER_WIDTH;
defparam uAxiMaster.RUSER_WIDTH      = RUSER_WIDTH;
defparam uAxiMaster.BUSER_WIDTH      = 1'b1;
defparam uAxiMaster.INSTANCE         = INSTANCE;
defparam uAxiMaster.INSTANCE_TYPE    = "PL301_AXI4M_";
defparam uAxiMaster.read_acceptance_capability      = read_acceptance_capability;
defparam uAxiMaster.write_acceptance_capability     = write_acceptance_capability;
defparam uAxiMaster.unlimited_acceptance_capability = unlimited_acceptance_capability;
defparam uAxiMaster.limit_issuing_capability        = limit_issuing_capability;
defparam uAxiMaster.leading_write_depth             = leading_write_depth;
defparam uAxiMaster.AllowLeadingRdata               = 1;
defparam uAxiMaster.DriveOnlyOnEnable               = DriveOnlyOnEnable;
defparam uAxiMaster.PortIsInternal                  = 1;
defparam uAxiMaster.MaxWaits                        = MaxWaits;

nic400_axi4_m_if uAxiMaster (

      .ACLK         (ACLK),
      .ACLKEN       (ACLKEN),
      .ARESETn      (ARESETn),

      .AWID         (AWID),
      .AWADDR       (AWADDR),
      .AWLEN        (AWLEN),
      .AWQV         (AWQV),
      .AWREGION     (AWREGION),
      .AWSIZE       (AWSIZE),
      .AWBURST      (AWBURST),
      .AWLOCK       (AWLOCK),
      .AWCACHE      (AWCACHE),
      .AWPROT       (AWPROT),
      .AWVALID_VECT (AWVALID_VECT),
      .AWVALID      (AWVALID),
      .AWREADY      (AWREADY),
      .AWVNET       (),

      .WDATA        (WDATA),
      .WSTRB        (WSTRB),
      .WLAST        (WLAST),
      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WVNET        (),

      .BID          (DID),
      .BRESP        (DRESP),
      .BVALID       (BVALID),
      .BREADY       (BREADY),

      .ARID         (ARID),
      .ARADDR       (ARADDR),
      .ARLEN        (ARLEN),
      .ARQV         (ARQV),
      .ARREGION     (ARREGION),
      .ARSIZE       (ARSIZE),
      .ARBURST      (ARBURST),
      .ARLOCK       (ARLOCK),
      .ARCACHE      (ARCACHE),
      .ARPROT       (ARPROT),
      .ARVALID_VECT (ARVALID_VECT),
      .ARVALID      (ARVALID),
      .ARREADY      (ARREADY),
      .ARVNET       (),

      .RID          (DID),
      .RDATA        (DDATA),
      .RRESP        (DRESP),
      .RLAST        (DLAST),
      .RVALID       (RVALID),
      .RREADY       (RREADY),

      .AWUSER       (AWUSER),
      .WUSER        (WUSER),
      .BUSER        (1'b0),
      .ARUSER       (ARUSER),
      .RUSER        (DUSER),

      .EMIT_DATA    (EMIT_DATA),
      .EMIT_REQ     (EMIT_REQ),
      .EMIT_ACK     (EMIT_ACK),

      .WAIT_DATA    (WAIT_DATA),
      .WAIT_REQ     (WAIT_REQ),
      .WAIT_ACK     (WAIT_ACK),

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
      .PRDATA       (PRDATA),

      .FN_MOD       ()
  );

// -----------------------------------------------------------------------------
//  Mux - behavioural mux with random arbitartion;
// -----------------------------------------------------------------------------

assign next_stall = AVALID & ~AREADY;

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

assign  select =  (ARVALID & ~AWVALID) ? 1'b0 :
             ((AWVALID & ~ARVALID) ? 1'b1 : select_random);

assign  channel_sel = (stall) ? select_reg : select;

//Address Channel fwd signals
assign  AID         = (channel_sel) ? AWID          : ARID;         // address ID
assign  AADDR       = (channel_sel) ? AWADDR        : ARADDR;       // address
assign  ALEN        = (channel_sel) ? AWLEN         : ARLEN;        // burst length
assign  ASIZE       = (channel_sel) ? AWSIZE        : ARSIZE;       // burst size
assign  ABURST      = (channel_sel) ? AWBURST       : ARBURST;      // burst type
assign  AVALID      = (channel_sel) ? AWVALID       : ARVALID;      // address valid
assign  AVALID_VECT = (channel_sel) ? AWVALID_VECT  : ARVALID_VECT; // address valid
assign  AREGION     = (channel_sel) ? AWREGION      : ARREGION;     // region select
assign  APROT       = (channel_sel) ? AWPROT        : ARPROT;       // protection information
assign  ACACHE      = (channel_sel) ? AWCACHE       : ARCACHE;      // Cache signals
assign  ALOCK       = (channel_sel) ? AWLOCK        : ARLOCK;       // Lock signals
assign  AUSER       = (channel_sel) ? AWUSER        : ARUSER;       // AUser signals
assign  AWRITE      = channel_sel;

//Address channel ready signals
assign  #1 AWREADY    =  channel_sel && AREADY;  // address ready
assign  #1 ARREADY    = ~channel_sel && AREADY;  // address ready

//Data
assign  BVALID     = (DBNR) & DVALID;
assign  RVALID     = (~DBNR) & DVALID;
assign  DREADY     = (BVALID) ? BREADY : RREADY;

endmodule

//  --=============================== End ====================================--

