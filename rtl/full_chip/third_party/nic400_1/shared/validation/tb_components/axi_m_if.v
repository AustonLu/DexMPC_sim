// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2008-2014 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 169640
//
// Date                   :  2014-03-24 16:36:37 +0000 (Mon, 24 Mar 2014)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC-400 axi slave interface
//
// Description : This block is an AXI master that can be used in the main NIC-400
//               testbench.
//
//               Currently contains an eXVC AXIS or FRM component
//
//               PL301r2 uses AxQV, AxRegion and multi-bit AxVectors. These are
//               deviations from standard AXI and are, therefore, not output from
//               standard AXI signals.
//
//               They are decoded from the top of the AxUSER
//
//               AxQV is passed as a 4 bit unchanged value. AxValid is converted
//               from a 4bit value to a one-hot where 4'b0 => AxVALID[0]
//
//               This component is limited to issuing 100 active transactions.
//               This is more than any single acceptance capability and more
//               than enough for testing an unconstrainted port which is
//               essentially either a fifo or regslice
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module axi_m_if(
                 // Global signals
                 ACLK,
                 ACLKEN,
                 ARESETn,

                 // Read Address Channel
                 ARVALID,
                 ARREADY,
                 ARID,
                 ARADDR,
                 ARLEN,
                 ARQOS,
                 ARREGION,
                 ARSIZE,
                 ARBURST,
                 ARLOCK,
                 ARCACHE,
                 ARPROT,
                 ARUSER,

                 // Read Channel
                 RVALID,
                 RREADY,
                 RID,
                 RDATA,
                 RRESP,
                 RLAST,
                 RUSER,

                 // Write Address Channel
                 AWVALID,
                 AWREADY,
                 AWID,
                 AWADDR,
                 AWLEN,
                 AWQOS,
                 AWREGION,
                 AWSIZE,
                 AWBURST,
                 AWLOCK,
                 AWCACHE,
                 AWPROT,
                 AWUSER,

                 // Write Channel
                 WVALID,
                 WREADY,
                 WID,
                 WLAST,
                 WSTRB,
                 WDATA,
                 WUSER,

                 // Write Response Channel
                 BVALID,
                 BREADY,
                 BID,
                 BRESP,
                 BUSER,

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
// Defines
// ------------------------------------------------------------------------------
  `define   LIM_REG        12'hFFC

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter ADDR_WIDTH       = 32;
  parameter AWUSER_WIDTH     = 8;
  parameter ARUSER_WIDTH     = 8;
  parameter WUSER_WIDTH      = 8;
  parameter RUSER_WIDTH      = 8;
  parameter BUSER_WIDTH      = 8;
  parameter ID_WIDTH         = 16;
  parameter EW_WIDTH         = 16;
  parameter INSTANCE         = "undef";
  parameter INSTANCE_TYPE    = "AXIM_";

  parameter read_acceptance_capability      = 16;
  parameter write_acceptance_capability     = 16;

  //This parameter indicates that the connected slave_if does not limit its acceptance capability 1/0
  parameter unlimited_acceptance_capability = 0;
  //This parameter causes the FRM to limit its issuing to the acceptance capability 1/0
  parameter limit_issuing_capability        = 0;
  //This parameter is used to indicate the maximum allowable (not constained) leading write depth <int>
  parameter leading_write_depth             = 0;

  parameter AWUSER_WIDTH_I   = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
  parameter ARUSER_WIDTH_I   = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
  parameter WUSER_WIDTH_I    = (WUSER_WIDTH == 0)  ? 1 : WUSER_WIDTH;
  parameter RUSER_WIDTH_I    = (RUSER_WIDTH == 0)  ? 1 : RUSER_WIDTH;
  parameter BUSER_WIDTH_I    = (BUSER_WIDTH == 0)  ? 1 : BUSER_WIDTH;
  parameter ID_WIDTH_I       = (ID_WIDTH == 0)     ? 1 : ID_WIDTH;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter USER_MAX_AW      = AWUSER_WIDTH_I - 1;
  parameter USER_MAX_AR      = ARUSER_WIDTH_I - 1;
  parameter USER_MAX_W       = WUSER_WIDTH_I - 1;
  parameter USER_MAX_B       = BUSER_WIDTH_I - 1;
  parameter USER_MAX_R       = RUSER_WIDTH_I - 1;
  parameter ID_MAX           = ID_WIDTH_I - 1;
  parameter EW_MAX           = EW_WIDTH - 1;

  parameter AllowIllegalCache = 0;
  parameter AllowLeadingRdata = 0;

  parameter DriveOnlyOnEnable = 0;
  parameter PortIsInternal    = 0;
  parameter MaxWaits          = 5000;
  parameter RecommendOn       = 1;
  parameter RecMaxWaitOn      = 1;
  parameter USE_X             = 1;


// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

// Clock and Reset in AXI domain
input                   ACLK;            // AXI Bus Clock
input                   ACLKEN;          // AXI Bus Clock Enable
input                   ARESETn;         // AXI Bus Reset

// Read Address Channel
output                  ARVALID;         // Read valid signal
input                   ARREADY;         // Read address ready
output  [ID_MAX:0]      ARID;            // Read address ID
output  [ADDR_MAX:0]    ARADDR;          // Read address
output  [3:0]           ARLEN;           // Read burst length
output  [2:0]           ARSIZE;          // Read burst size
output  [1:0]           ARBURST;         // Read burst type
output  [3:0]           ARCACHE;         // Read Cache signals
output  [1:0]           ARLOCK;          // Read Lock signals
output  [2:0]           ARPROT;          // Read protection information
output  [3:0]           ARREGION;        // Read Region selector
output  [3:0]           ARQOS;           // Read Quality value
output  [USER_MAX_AR:0] ARUSER;          // Read user fields

// Read Channel
input                   RVALID;          // Read response valid
output                  RREADY;          // Read response ready
input   [ID_MAX:0]      RID;             // Read data ID
input                   RLAST;           // Read last
input   [DATA_MAX:0]    RDATA;           // Read data
input   [1:0]           RRESP;           // Read response
input  [USER_MAX_R:0]   RUSER;           // Read user fields

// Write Address Channel
output                  AWVALID;         // Write address valid
input                   AWREADY;         // Write address ready
output  [ID_MAX:0]      AWID;            // Write address ID
output  [ADDR_MAX:0]    AWADDR;          // Write address
output  [3:0]           AWLEN;           // Write burst length
output  [2:0]           AWSIZE;          // Write burst size
output  [1:0]           AWBURST;         // Write burst type
output  [3:0]           AWCACHE;         // Write Cache signals
output  [1:0]           AWLOCK;          // Write Lock signals
output  [2:0]           AWPROT;          // Write protection information
output  [3:0]           AWREGION;        // Write Region selector
output  [3:0]           AWQOS;           // Write Quality value
output  [USER_MAX_AW:0] AWUSER;          // Write user fields

// Write Channel
output                  WVALID;          // Write valid
input                   WREADY;          // Write ready
output  [ID_MAX:0]      WID;             // Wid
output                  WLAST;           // Write last
output  [STRB_MAX:0]    WSTRB;           // Write last
output  [DATA_MAX:0]    WDATA;           // Write data
output  [USER_MAX_W:0]  WUSER;           // Write user fields

// Write Response Channel
input                   BVALID;          // Write response valid
output                  BREADY;          // Write response ready
input   [ID_MAX:0]      BID;             // Write response ID
input   [1:0]           BRESP;           // Write response
input  [USER_MAX_B:0]   BUSER;           // Write response user fields

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
//  wire and register declarations
// -----------------------------------------------------------------------------

  wire                     AWVALID_out;
  wire                     ARVALID_out;
  reg  [4:0]               VALID_prev;
  reg  [4:0]               READY_prev;
  reg  [7:0]               ARcount;
  reg  [7:0]               AWcount;

  wire [USER_MAX_AW+16:0]  AWUSER_int;
  wire [USER_MAX_AR+16:0]  ARUSER_int;

  wire [6:0]               next_out_reads;
  wire [6:0]               next_out_writes;
  wire [6:0]               next_out_write_data;
  wire                     next_wlast_reg;
  wire [6:0]               leading_writes;
  wire                     no_leading_writes;
  reg  [6:0]               out_reads;
  reg  [6:0]               out_writes;
  reg  [6:0]               out_write_data;
  reg                      wlast_reg;

  wire                     iARVALID;
  wire                     iAWVALID;
  wire                     iARREADY;
  wire                     iAWREADY;

  reg                      error_v;
  reg                      error_r;
  reg                      PCLK_pulse;
  reg                      ACLK_pulse;

  wire  [ID_MAX:0]         ARID_int;
  wire  [ID_MAX:0]         AWID_int;
  wire  [ID_MAX:0]         WID_int;

  wire  [ID_MAX:0]         ARID_i;          // Read address ID
  wire  [ADDR_MAX:0]       ARADDR_i;        // Read address
  wire  [3:0]              ARLEN_i;         // Read burst length
  wire  [2:0]              ARSIZE_i;        // Read burst size
  wire  [1:0]              ARBURST_i;       // Read burst type
  wire  [2:0]              ARPROT_i;        // Read protection information
  wire  [3:0]              ARCACHE_i;       // Read Cache signals
  wire  [1:0]              ARLOCK_i;        // Read Lock signals
  wire  [3:0]              ARREGION_i;      // Read Region signals
  wire  [3:0]              ARQV_i;          // Read QV signals
  wire  [USER_MAX_AR:0]    ARUSER_i;        // Read User signals


  wire  [ID_MAX:0]         AWID_i;          // Write address ID
  wire  [ADDR_MAX:0]       AWADDR_i;        // Write address
  wire  [3:0]              AWLEN_i;         // Write burst length
  wire  [2:0]              AWSIZE_i;        // Write burst size
  wire  [1:0]              AWBURST_i;       // Write burst type
  wire  [2:0]              AWPROT_i;        // Write protection information
  wire  [3:0]              AWCACHE_i;       // Write Cache signals
  wire  [1:0]              AWLOCK_i;        // Write Lock signals
  wire  [3:0]              AWREGION_i;      // Write Region signals
  wire  [3:0]              AWQV_i;          // Write QV signals
  wire  [USER_MAX_AW:0]    AWUSER_i;        // Write User signals

  wire  [ID_MAX:0]         WID_i;           // Wid
  wire                     WLAST_i;         // Write last
  wire  [STRB_MAX:0]       WSTRB_i;         // Write last
  wire  [DATA_MAX:0]       WDATA_i;         // Write data
  wire  [USER_MAX_W:0]     WUSER_i;         // Write user fields

  wire                     ACLKENDEL;       // Delayed clock enable
  wire                     ACLKPC;          // Clock for protocol checker

//------------------------------------------------------------------------------
// Output Wires
//------------------------------------------------------------------------------

  assign ARID_i = (ID_WIDTH == 0) ? 1'b0 : ARID_int;
  assign AWID_i = (ID_WIDTH == 0) ? 1'b0 : AWID_int;
  assign WID_i  = (ID_WIDTH == 0) ? 1'b0 : WID_int;

  assign ARID     = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : ARID_i;
  assign ARADDR   = (DriveOnlyOnEnable & ~ACLKEN) ? {ADDR_WIDTH{1'bx}} : ARADDR_i;
  assign ARLEN    = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : ARLEN_i;
  assign ARSIZE   = (DriveOnlyOnEnable & ~ACLKEN) ? {3{1'bx}} : ARSIZE_i;
  assign ARBURST  = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : ARBURST_i;
  assign ARPROT   = (DriveOnlyOnEnable & ~ACLKEN) ? {3{1'bx}} : ARPROT_i;
  assign ARCACHE  = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : ARCACHE_i;
  assign ARLOCK   = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : ARLOCK_i;
  assign ARREGION = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : ARREGION_i;
  assign ARQOS    = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : ARQV_i;
  assign ARUSER   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ARUSER_WIDTH_I == 1) ? 1'bx : {ARUSER_WIDTH_I{1'bx}}) : ARUSER_i[USER_MAX_AR:0];


  assign AWID     = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : AWID_i;
  assign AWADDR   = (DriveOnlyOnEnable & ~ACLKEN) ? {ADDR_WIDTH{1'bx}} : AWADDR_i;
  assign AWLEN    = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : AWLEN_i;
  assign AWSIZE   = (DriveOnlyOnEnable & ~ACLKEN) ? {3{1'bx}} : AWSIZE_i;
  assign AWBURST  = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : AWBURST_i;
  assign AWPROT   = (DriveOnlyOnEnable & ~ACLKEN) ? {3{1'bx}} : AWPROT_i;
  assign AWCACHE  = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : AWCACHE_i;
  assign AWLOCK   = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : AWLOCK_i;
  assign AWREGION = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : AWREGION_i;
  assign AWQOS    = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : AWQV_i;
  assign AWUSER   = (DriveOnlyOnEnable & ~ACLKEN) ? ((AWUSER_WIDTH_I == 1) ? 1'bx : {AWUSER_WIDTH_I{1'bx}}) : AWUSER_i[USER_MAX_AW:0];

  assign WID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : WID_i;
  assign WLAST = (DriveOnlyOnEnable & ~ACLKEN) ? 1'bx : WLAST_i;
  assign WSTRB = (DriveOnlyOnEnable & ~ACLKEN) ? {STRB_WIDTH{1'bx}} : WSTRB_i;
  assign WDATA = (DriveOnlyOnEnable & ~ACLKEN) ? {DATA_WIDTH{1'bx}} : WDATA_i;
  assign WUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((WUSER_WIDTH_I == 1) ? 1'bx : {WUSER_WIDTH_I{1'bx}}) : WUSER_i;

// -----------------------------------------------------------------------------
// Limit issuing capability Register
// -----------------------------------------------------------------------------
wire                       lim_cap_addr_sel;
reg                        lim_cap_apb;
reg                        lim_cap;
wire   [31:0]              PRDATA_int;

assign lim_cap_addr_sel = PSEL && PENABLE && (PADDR[11:0] == `LIM_REG);

//APB Regsiter
always @(posedge PCLK or negedge PRESETn)
  begin
      if (~PRESETn) begin
         lim_cap_apb <= limit_issuing_capability;
      end else if (lim_cap_addr_sel && PWRITE) begin
         lim_cap_apb <= PWDATA[0];
      end
  end

assign PRDATA[31:1] = PRDATA_int[31:1];
assign PRDATA[0] = (lim_cap_addr_sel) ? lim_cap_apb : PRDATA_int[0];

//Synchronise to ACLK
always @(posedge ACLK or negedge ARESETn)
  begin
      if (~PRESETn) begin
         lim_cap <= limit_issuing_capability;
      end else begin
         lim_cap <= lim_cap_apb;
      end
  end


//------------------------------------------------------------------------------
// AXI Master
//------------------------------------------------------------------------------
  `ifdef SN
  defparam uAxiMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiMaster.ID_WIDTH       = ID_WIDTH_I;
  defparam uAxiMaster.ADDR_WIDTH     = ADDR_WIDTH;         // Addr width

  defparam uAxiMaster.AWUSER_WIDTH   = AWUSER_WIDTH_I;
  defparam uAxiMaster.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiMaster.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiMaster.ARUSER_WIDTH   = ARUSER_WIDTH_I;
  defparam uAxiMaster.RUSER_WIDTH    = RUSER_WIDTH_I;

  Axi3pMasterXvc uAxiMaster (
      .ACLK         (ACLK),
      .ARESETn      (ARESETn),

      .AWVALID      (iAWVALID),
      .AWREADY      (iAWREADY),
      .AWID         (AWID_int),
      .AWADDR       (AWADDR_i),
      .AWLEN        (AWLEN_i),
      .AWSIZE       (AWSIZE_i),
      .AWBURST      (AWBURST_i),
      .AWLOCK       (AWLOCK_i),
      .AWCACHE      (AWCACHE_i),
      .AWPROT       (AWPROT_i),
      .AWREGION     (AWREGION_i),
      .AWQV         (AWQV_i),

      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WID          (WID_int),
      .WDATA        (WDATA_i),
      .WSTRB        (WSTRB_i),
      .WLAST        (WLAST_i),

      .BVALID       (BVALID),
      .BREADY       (BREADY),
      .BID          (BID),
      .BRESP        (BRESP),

      .ARVALID      (iARVALID),
      .ARREADY      (iARREADY),
      .ARID         (ARID_int),
      .ARADDR       (ARADDR_i),
      .ARLEN        (ARLEN_i),
      .ARSIZE       (ARSIZE_i),
      .ARBURST      (ARBURST_i),
      .ARLOCK       (ARLOCK_i),
      .ARCACHE      (ARCACHE_i),
      .ARPROT       (ARPROT_i),
      .ARREGION     (ARREGION_i),
      .ARQV         (ARQV_i),

      .AWUSER       (AWUSER_i),
      .WUSER        (WUSER_i),
      .BUSER        (BUSER),
      .ARUSER       (ARUSER_i),
      .RUSER        (RUSER),

      .RVALID       (RVALID),
      .RREADY       (RREADY),
      .RID          (RID),
      .RDATA        (RDATA),
      .RRESP        (RRESP),
      .RLAST        (RLAST)
  );

  // When using specman tie-off the unused Event buses
  assign  EMIT_REQ   = EMIT_ACK;
  assign  EMIT_DATA  = {EW_WIDTH{1'b0}};
  assign  WAIT_ACK   = WAIT_REQ;

  `else
  defparam uAxiMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiMaster.ID_WIDTH       = ID_WIDTH_I;
  defparam uAxiMaster.ADDR_WIDTH     = ADDR_WIDTH;         // Addr width

  defparam uAxiMaster.AWUSER_WIDTH   = AWUSER_WIDTH_I + 16;
  defparam uAxiMaster.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiMaster.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiMaster.ARUSER_WIDTH   = ARUSER_WIDTH_I + 16;
  defparam uAxiMaster.RUSER_WIDTH    = RUSER_WIDTH_I;

  defparam uAxiMaster.AW_ARRAY_SIZE     = 10000;             // Size of AW channel array
  defparam uAxiMaster.W_ARRAY_SIZE      = 50000;             // Size of W channel array
  defparam uAxiMaster.AR_ARRAY_SIZE     = 10000;             // Size of AR channel array
  defparam uAxiMaster.R_ARRAY_SIZE      = 50000;             // Size of R channel array
  defparam uAxiMaster.AWMSG_ARRAY_SIZE  = 10000;             // Size of AW comments array
  defparam uAxiMaster.ARMSG_ARRAY_SIZE  = 10000;             // Size of AR comments array

  defparam  uAxiMaster.OUTSTANDING_WRITES = (limit_issuing_capability) ? write_acceptance_capability + 5 : 100;
  defparam  uAxiMaster.OUTSTANDING_READS  = (limit_issuing_capability) ? read_acceptance_capability + 5 : 100;

  defparam uAxiMaster.STIM_FILE_NAME  = {INSTANCE_TYPE, INSTANCE};
  defparam uAxiMaster.MESSAGE_TAG     = {"master_", INSTANCE}; // Message prefix
  defparam uAxiMaster.VERBOSE         = 1;                  // Verbosity control
  defparam uAxiMaster.USE_X           = USE_X;                  // Drive X on invalid signals
  defparam uAxiMaster.EW_WIDTH        = EW_WIDTH;           // Width of the Emit & wait bus

  FileRdMasterAxi uAxiMaster (
      .ACLK         (ACLK),
      .ARESETn      (ARESETn),

      .AWVALID      (iAWVALID),
      .AWREADY      (iAWREADY),
      .AWID         (AWID_int),
      .AWADDR       (AWADDR_i),
      .AWLEN        (AWLEN_i),
      .AWSIZE       (AWSIZE_i),
      .AWBURST      (AWBURST_i),
      .AWLOCK       (AWLOCK_i),
      .AWCACHE      (AWCACHE_i),
      .AWPROT       (AWPROT_i),

      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WID          (WID_int),
      .WDATA        (WDATA_i),
      .WSTRB        (WSTRB_i),
      .WLAST        (WLAST_i),

      .BVALID       (BVALID),
      .BREADY       (BREADY),
      .BID          (BID),
      .BRESP        (BRESP),

      .ARVALID      (iARVALID),
      .ARREADY      (iARREADY),
      .ARID         (ARID_int),
      .ARADDR       (ARADDR_i),
      .ARLEN        (ARLEN_i),
      .ARSIZE       (ARSIZE_i),
      .ARBURST      (ARBURST_i),
      .ARLOCK       (ARLOCK_i),
      .ARCACHE      (ARCACHE_i),
      .ARPROT       (ARPROT_i),

       //Connect FRM signals the the AXIM XVC doesn;t have
      .CSYSREQ      (1'b1),
      .CACTIVE      (),
      .CSYSACK      (),

      .EMIT_DATA    (EMIT_DATA),
      .EMIT_REQ     (EMIT_REQ),
      .EMIT_ACK     (EMIT_ACK),

      .WAIT_DATA    (WAIT_DATA),
      .WAIT_REQ     (WAIT_REQ),
      .WAIT_ACK     (WAIT_ACK),

      .AWUSER       (AWUSER_int),
      .WUSER        (WUSER_i),
      .BUSER        (BUSER),
      .ARUSER       (ARUSER_int),
      .RUSER        (RUSER),

      .RVALID       (RVALID),
      .RREADY       (RREADY),
      .RID          (RID),
      .RDATA        (RDATA),
      .RRESP        (RRESP),
      .RLAST        (RLAST)
  );

// -----------------------------------------------------------------------------
//  Valid, QV and Region extraction logic
// -----------------------------------------------------------------------------

  //AxQV value assignments
  assign AWQV_i = AWUSER_int[7:4];
  assign ARQV_i = ARUSER_int[7:4];

  //AxRegion assignments
  assign AWREGION_i = AWUSER_int[3:0];
  assign ARREGION_i = ARUSER_int[3:0];

  //AxUser assignments
  assign AWUSER_i = AWUSER_int[USER_MAX_AW+16:16];
  assign ARUSER_i = ARUSER_int[USER_MAX_AR+16:16];

  `endif

// -----------------------------------------------------------------------------
// Transaction Counters, limiters and assertions
// -----------------------------------------------------------------------------



  //AR Channel
  assign next_out_reads = (ARVALID & ARREADY & ~(RLAST & RVALID & RREADY)) ? out_reads + 7'b1 :
                          (RLAST & RVALID & RREADY & ~(ARVALID & ARREADY)) ? out_reads - 7'b1 : out_reads;

  //AW Channel
  assign next_out_writes = (AWVALID & AWREADY & ~(BVALID & BREADY)) ? out_writes + 7'b1 :
                           (BVALID & BREADY & ~(AWVALID & AWREADY)) ? out_writes - 7'b1 : out_writes;

  //AW Channel
  assign next_out_write_data = (wlast_reg & WVALID & WREADY & ~(BVALID & BREADY)) ? out_write_data + 7'b1 :
                           (BVALID & BREADY & ~(wlast_reg & WVALID & WREADY)) ? out_write_data - 7'b1 : out_write_data;

  //Leading write
  assign next_wlast_reg = (WLAST_i & WVALID & WREADY) ? 1'b1 :
                          (~WLAST_i & WVALID & WREADY) ? 1'b0 : wlast_reg;

  assign leading_writes = (out_write_data > out_writes) ? out_write_data - out_writes : 7'b0;
  assign no_leading_writes = (leading_writes < 7'd1) ? 1'b1 : 1'b0;

  assign AWVALID = iAWVALID & ((lim_cap == 0) || (out_writes[6] | (out_writes[5:0] < write_acceptance_capability)));
  assign ARVALID = iARVALID & ((lim_cap == 0) || (out_reads < read_acceptance_capability));

  assign iAWREADY = AWREADY & ((lim_cap == 0) || (out_writes[6] | (out_writes[5:0] < write_acceptance_capability)));
  assign iARREADY = ARREADY & ((lim_cap == 0) || (out_reads < read_acceptance_capability));

  //counters
  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           out_writes <= 7'b0;
           out_reads <= 7'b0;
           out_write_data <= 7'b0;
           wlast_reg <= 1'b1;
       end else begin
           out_writes <= next_out_writes;
           out_reads <= next_out_reads;
           out_write_data <= next_out_write_data;
           wlast_reg <= next_wlast_reg;
       end
    end

  `ifdef ARM_ASSERT_ON

  assert_never #(0,0,"Read Acceptance Capability exceeded")
     ovl_read_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((unlimited_acceptance_capability == 0) & (lim_cap == 1) & (out_reads > read_acceptance_capability))
       );

  assert_never #(0,0,"Write Acceptance Capability exceeded")
     ovl_write_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((unlimited_acceptance_capability == 0) & (lim_cap == 1) & ~out_writes[6] & (out_writes[5:0] > write_acceptance_capability))
       );

  assert_never #(0,0,"Leading Write Acceptance Capability exceeded")
     ovl_leading_write_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((unlimited_acceptance_capability == 0) & (lim_cap == 1) & (leading_write_depth > leading_writes))
       );

  always @(posedge PCLK)
    begin
      PCLK_pulse = 1'b1;
      ACLK_pulse = 1'b1;
      #1 PCLK_pulse = 1'b0;
      #1 ACLK_pulse = 1'b0;
    end

  always @(negedge PCLK_pulse)
    begin
      VALID_prev <= {ARVALID, AWVALID, RVALID, WVALID, BVALID};
      READY_prev <= {ARREADY, AWREADY, RREADY, WREADY, BREADY};

      if (~ACLK_pulse)
        begin
          if (VALID_prev != {ARVALID, AWVALID, RVALID, WVALID, BVALID})
            error_v = 1'b1;
          if (READY_prev != {ARREADY, AWREADY, RREADY, WREADY, BREADY})
            error_r = 1'b1;
        end
        #1 error_v = 1'b0;
        #1 error_r = 1'b0;
    end


  assert_proposition #(0,0,"No VALID change between at any time other than an ACLK edge")
     ovl_no_valid_change
       (/*AUTOINST*/
        .reset_n   (ARESETn),
        .test_expr (error_v !== 1'b1)
       );

  assert_proposition #(0,0,"No READY change between at any time other than an ACLK edge")
     ovl_no_ready_change
       (/*AUTOINST*/
        .reset_n   (ARESETn),
        .test_expr (error_r !== 1'b1)
       );

  `endif //ARM_ASSERT_ON

//------------------------------------------------------------------------------
// AXI Master APB Checker
//------------------------------------------------------------------------------
  defparam uAxiMasterAPB.DATA_WIDTH = DATA_WIDTH;
  defparam uAxiMasterAPB.ID_WIDTH   = ID_WIDTH_I;
  defparam uAxiMasterAPB.EW_WIDTH   = EW_WIDTH;
  defparam uAxiMasterAPB.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam uAxiMasterAPB.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxiMasterAPB.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxiMasterAPB.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam uAxiMasterAPB.RUSER_WIDTH  = RUSER_WIDTH_I;

  AxiMasterAPB uAxiMasterAPB (

      .ACLK           (ACLK),
      .ARESETn        (ARESETn),

      .AWID           (AWID_i),
      .AWADDR         (AWADDR_i[31:0]),
      .AWLEN          (AWLEN_i),
      .AWSIZE         (AWSIZE_i),
      .AWBURST        (AWBURST_i),
      .AWLOCK         (AWLOCK_i),
      .AWCACHE        (AWCACHE_i),
      .AWPROT         (AWPROT_i),
      .AWUSER         (AWUSER_i),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),

      .WID            (WID_i),
      .WLAST          (WLAST_i),
      .WDATA          (WDATA_i),
      .WSTRB          (WSTRB_i),
      .WUSER          (WUSER_i),
      .WVALID         (WVALID),
      .WREADY         (WREADY),

      .BID            (BID),
      .BRESP          (BRESP),
      .BUSER          (BUSER),
      .BVALID         (BVALID),
      .BREADY         (BREADY),

      .ARID           (ARID_i),
      .ARADDR         (ARADDR_i[31:0]),
      .ARLEN          (ARLEN_i),
      .ARSIZE         (ARSIZE_i),
      .ARBURST        (ARBURST_i),
      .ARLOCK         (ARLOCK_i),
      .ARCACHE        (ARCACHE_i),
      .ARPROT         (ARPROT_i),
      .ARUSER         (ARUSER_i),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),

      .RID            (RID),
      .RLAST          (RLAST),
      .RDATA          (RDATA),
      .RRESP          (RRESP),
      .RUSER          (RUSER),
      .RVALID         (RVALID),
      .RREADY         (RREADY),

      .pclk           (PCLK),
      .PRDATA         (PRDATA_int),
      .PREADY         (PREADY),
      .PSEL           (PSEL),
      .PENABLE        (PENABLE),
      .PWRITE         (PWRITE),
      .PADDR          (PADDR),
      .PWDATA         (PWDATA),

      .WAIT_DATA      (WAIT_DATA),
      .WAIT_REQ       (WAIT_REQ),
      .WAIT_ACK       (WAIT_ACK)


  );

  assign PSLVERR = 1'b0;

`ifdef ARM_ASSERT_ON

//------------------------------------------------------------------------------
// AXI Protocol Checkers
//------------------------------------------------------------------------------

  assign #3 ACLKENDEL = ACLKEN;  // Delay 1ns more than clk_reset_if

  assign ACLKPC = (PortIsInternal) ? ~ACLKENDEL : ACLK;

  defparam uAxiPC.VALID_WIDTH  = 1;
  defparam uAxiPC.DATA_WIDTH   = DATA_WIDTH;
  defparam uAxiPC.ADDR_WIDTH   = ADDR_WIDTH;         // Addr width
  defparam uAxiPC.ID_WIDTH     = ID_WIDTH_I;
  defparam uAxiPC.WDEPTH       = 1;
  //The +1 are because AxiPC counts transactions from valid assertion not-handshake.
  defparam uAxiPC.MAXRBURSTS   = 200 + 1;
  defparam uAxiPC.MAXWBURSTS   = 200 + 1 + leading_write_depth + 1;
  defparam uAxiPC.MAXWAITS     = MaxWaits;
  defparam uAxiPC.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam uAxiPC.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxiPC.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxiPC.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam uAxiPC.RUSER_WIDTH  = RUSER_WIDTH_I;
  defparam uAxiPC.AllowLeadingRdata = AllowLeadingRdata;
  defparam uAxiPC.AXI_ERRL_PropertyType = 2; // No Low power interface checking
  // Recommended Rules Enable
  defparam uAxiPC.RecommendOn   = RecommendOn;    // enable/disable reporting of all  AXI_REC*_* rules
  defparam uAxiPC.RecMaxWaitOn  = RecMaxWaitOn;   // enable/disable reporting of just AXI_REC*_MAX_WAIT rules

  PL301_AxiPC uAxiPC (

      .ACLK           (ACLKPC),
      .ARESETn        (ARESETn),

      .AWVALID_VECT   (1'b0),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .AWID           (AWID_i),
      .AWADDR         (AWADDR_i),
      .AWLEN          (AWLEN_i),
      .AWSIZE         (AWSIZE_i),
      .AWBURST        (AWBURST_i),
      .AWLOCK         (AWLOCK_i),
      .AWCACHE        (AWCACHE_i),
      .AWPROT         (AWPROT_i),
      .AWREGION       (AWREGION_i),
      .AWQV           (AWQV_i),
      .AWUSER         (AWUSER_i),

      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .WID            (WID_i),
      .WLAST          (WLAST_i),
      .WDATA          (WDATA_i),
      .WSTRB          (WSTRB_i),
      .WUSER          (WUSER_i),

      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .BID            (BID),
      .BRESP          (BRESP),
      .BUSER          (BUSER),

      .ARVALID_VECT   (1'b0),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .ARID           (ARID_i),
      .ARADDR         (ARADDR_i),
      .ARLEN          (ARLEN_i),
      .ARSIZE         (ARSIZE_i),
      .ARBURST        (ARBURST_i),
      .ARLOCK         (ARLOCK_i),
      .ARCACHE        (ARCACHE_i),
      .ARPROT         (ARPROT_i),
      .ARREGION       (ARREGION_i),
      .ARQV           (ARQV_i),
      .ARUSER         (ARUSER_i),

      .RVALID         (RVALID),
      .RREADY         (RREADY),
      .RID            (RID),
      .RLAST          (RLAST),
      .RDATA          (RDATA),
      .RRESP          (RRESP),
      .RUSER          (RUSER),

      .CACTIVE        (1'b0),
      .CSYSREQ        (1'b0),
      .CSYSACK        (1'b0)
  );

`endif 

`ifdef VPE

  defparam u_avip_axi_monitor.INSTANCE_NAME = "axi_m_if";
  defparam u_avip_axi_monitor.DATA_WIDTH = DATA_WIDTH;
  defparam u_avip_axi_monitor.ADDR_WIDTH = ADDR_WIDTH;         // Addr width
  defparam u_avip_axi_monitor.ID_WIDTH   = ID_WIDTH_I;
  defparam u_avip_axi_monitor.WDEPTH     = 1;
  defparam u_avip_axi_monitor.MAXRBURSTS = 200;
  defparam u_avip_axi_monitor.MAXWBURSTS = 200 + leading_write_depth + 1;
  defparam u_avip_axi_monitor.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam u_avip_axi_monitor.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam u_avip_axi_monitor.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam u_avip_axi_monitor.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam u_avip_axi_monitor.RUSER_WIDTH  = RUSER_WIDTH_I;
  defparam u_avip_axi_monitor.STRB_WIDTH = STRB_WIDTH;

  avip_axi_monitor_wrapper u_avip_axi_monitor (
      .ACLK           (ACLK),
      .ARESETn        (ARESETn),
      .AWID           (AWID_i),
      .AWADDR         (AWADDR_i),
      .AWLEN          (AWLEN_i),
      .AWSIZE         (AWSIZE_i),
      .AWBURST        (AWBURST_i),
      .AWLOCK         (AWLOCK_i),
      .AWCACHE        (AWCACHE_i),
      .AWPROT         (AWPROT_i),
      .AWUSER         (AWUSER_i),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .WID            (WID_i),
      .WDATA          (WDATA_i),
      .WSTRB          (WSTRB_i),
      .WLAST          (WLAST_i),
      .WUSER          (WUSER_int),
      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .BID            (BID),
      .BRESP          (BRESP),
      .BUSER          (BUSER_int),
      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .ARID           (ARID_i),
      .ARADDR         (ARADDR_i),
      .ARLEN          (ARLEN_i),
      .ARSIZE         (ARSIZE_i),
      .ARBURST        (ARBURST_i),
      .ARLOCK         (ARLOCK_i),
      .ARCACHE        (ARCACHE_i),
      .ARPROT         (ARPROT_i),
      .ARUSER         (ARUSER_i),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .RID            (RID),
      .RDATA          (RDATA),
      .RRESP          (RRESP),
      .RLAST          (RLAST),
      .RUSER          (RUSER_int),
      .RVALID         (RVALID),
      .RREADY         (RREADY)
  );

`endif

`ifdef TRACE  
  axi_trace     u_axi_trace (
      .ACLK           (ACLK),
      .ARESETn        (ARESETn),
      .AWID           (1'b0/*AWID_i*/),
      .AWADDR         (AWADDR_i),
      .AWLEN          (AWLEN_i),
      .AWSIZE         (AWSIZE_i),
      .AWBURST        (AWBURST_i),
      .AWLOCK         (AWLOCK_i),
      .AWCACHE        (AWCACHE_i),
      .AWPROT         (AWPROT_i),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .WID            (1'b0/*WID_i*/),
      .WDATA          (WDATA_i),
      .WSTRB          (WSTRB_i),
      .WLAST          (WLAST_i),
      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .BID            (1'b0/*BID*/),
      .BRESP          (BRESP),
      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .ARID           (1'b0/*ARID_i*/),
      .ARADDR         (ARADDR_i),
      .ARLEN          (ARLEN_i),
      .ARSIZE         (ARSIZE_i),
      .ARBURST        (ARBURST_i),
      .ARLOCK         (ARLOCK_i),
      .ARCACHE        (ARCACHE_i),
      .ARPROT         (ARPROT_i),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .RID            (1'b0/*RID*/),
      .RDATA          (RDATA),
      .RRESP          (RRESP),
      .RLAST          (RLAST),
      .RVALID         (RVALID),
      .RREADY         (RREADY)
  );

  defparam u_axi_trace.ADDR_WIDTH = ADDR_WIDTH;
  defparam u_axi_trace.DATA_WIDTH = DATA_WIDTH;
  defparam u_axi_trace.ECHO = 1'b1;
  defparam u_axi_trace.ID_WIDTH = 1; // Remove ID for static latency ID_WIDTH;
  defparam u_axi_trace.STRB_WIDTH = STRB_WIDTH;
  defparam u_axi_trace.UNIT_NAME = INSTANCE;

`endif

endmodule

//  --=============================== End ====================================--

