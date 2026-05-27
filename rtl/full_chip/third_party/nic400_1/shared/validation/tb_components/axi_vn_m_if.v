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
// File Revision          : 122515
//
// Date                   :  2011-12-06 10:40:11 +0000 (Tue, 06 Dec 2011)
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
module axi_vn_m_if(
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
                 ARVNET,

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
                 AWVNET,

                 // Write Channel
                 WVALID,
                 WREADY,
                 WID,
                 WLAST,
                 WSTRB,
                 WDATA,
                 WUSER,
                 WVNET,

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
                 PRDATA,

                 //Token Control
                 // Virtual Network 0
                 VAWVALID_0,
                 VAWREADY_0,
                 VAWQOS_0,
                 VARVALID_0,
                 VARREADY_0,
                 VARQOS_0,
                 VWVALID_0,
                 VWREADY_0,
        
                 // Virtual Network 1
                 VAWVALID_1,
                 VAWREADY_1,
                 VAWQOS_1,
                 VARVALID_1,
                 VARREADY_1,
                 VARQOS_1,
                 VWVALID_1,
                 VWREADY_1,
        
                 // Virtual Network 2
                 VAWVALID_2,
                 VAWREADY_2,
                 VAWQOS_2,
                 VARVALID_2,
                 VARREADY_2,
                 VARQOS_2,
                 VWVALID_2,
                 VWREADY_2,
        
                 // Virtual Network 3
                 VAWVALID_3,
                 VAWREADY_3,
                 VAWQOS_3,
                 VARVALID_3,
                 VARREADY_3,
                 VARQOS_3,
                 VWVALID_3,
                 VWREADY_3

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

  //VNET parameter
  parameter VNETS             = 1;
  parameter VNET_VALUE0       = 0;
  parameter VNET_VALUE1       = 0;
  parameter VNET_VALUE2       = 0;
  parameter VNET_VALUE3       = 0;
  parameter VNET_PREFETCH0    = 0;
  parameter VNET_PREFETCH1    = 0;
  parameter VNET_PREFETCH2    = 0;
  parameter VNET_PREFETCH3    = 0;

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
output  [3:0]           ARVNET;          // Read VNET

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
output  [3:0]           AWVNET;          // Read VNET

// Write Channel
output                  WVALID;          // Write valid
input                   WREADY;          // Write ready
output  [ID_MAX:0]      WID;             // Wid
output                  WLAST;           // Write last
output  [STRB_MAX:0]    WSTRB;           // Write last
output  [DATA_MAX:0]    WDATA;           // Write data
output  [USER_MAX_W:0]  WUSER;           // Write user fields
output  [3:0]           WVNET;          // Read VNET

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

// Virtual Network 0
output                  VAWVALID_0;
input                   VAWREADY_0;
output  [3:0]           VAWQOS_0;
output                  VARVALID_0;
input                   VARREADY_0;
output  [3:0]           VARQOS_0;
output                  VWVALID_0;
input                   VWREADY_0;
    
// Virtual Network 1
output                  VAWVALID_1;
input                   VAWREADY_1;
output  [3:0]           VAWQOS_1;
output                  VARVALID_1;
input                   VARREADY_1;
output  [3:0]           VARQOS_1;
output                  VWVALID_1;
input                   VWREADY_1;

// Virtual Network 2
output                  VAWVALID_2;
input                   VAWREADY_2;
output  [3:0]           VAWQOS_2;
output                  VARVALID_2;
input                   VARREADY_2;
output  [3:0]           VARQOS_2;
output                  VWVALID_2;
input                   VWREADY_2;
    
// Virtual Network 3
output                  VAWVALID_3;
input                   VAWREADY_3;
output  [3:0]           VAWQOS_3;
output                  VARVALID_3;
input                   VARREADY_3;
output  [3:0]           VARQOS_3;
output                  VWVALID_3;
input                   VWREADY_3;


// -----------------------------------------------------------------------------
//  wire and register declarations
// -----------------------------------------------------------------------------

  wire                     AWVALID_out;
  wire                     ARVALID_out;
  reg  [4:0]               VALID_prev;
  reg  [4:0]               READY_prev;
  reg  [7:0]               ARcount;
  reg  [7:0]               AWcount;

  wire [USER_MAX_AW+20:0]  AWUSER_int;
  wire [USER_MAX_AR+20:0]  ARUSER_int;
  wire [USER_MAX_W+4:0]    WUSER_int;

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
  wire  [3:0]              ARVNET_i;        // REad VNET signals


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
  wire  [3:0]              AWVNET_i;        // REad VNET signals

  reg   [3:0]              ARQV_reg;        // 
  reg   [3:0]              AWQV_reg;        // 

  wire  [ID_MAX:0]         WID_i;           // Wid
  wire                     WLAST_i;         // Write last
  wire  [STRB_MAX:0]       WSTRB_i;         // Write last
  wire  [DATA_MAX:0]       WDATA_i;         // Write data
  wire  [USER_MAX_W:0]     WUSER_i;         // Write user fields
  wire  [3:0]              WVNET_i;        // REad VNET signals

  wire                     ACLKENDEL;       // Delayed clock enable
  wire                     ACLKPC;          // Clock for protocol checker

 `ifndef SN

  wire  arenable;
  wire  awenable;
  wire  wenable;

  reg [3:0] AWVNET_r;
  reg [3:0] WVNET_r;
  reg [3:0] ARVNET_r;

  wire  ARVALID_int;
  wire  AWVALID_int;
  wire  WVALID_int;
  wire  ARREADY_int;
  wire  AWREADY_int;
  wire  WREADY_int;
  wire  ARREADY_masked;
  wire  AWREADY_masked;
  wire  WREADY_masked;

  wire  [3:0] arvalid_match_vnet;
  wire  [3:0] awvalid_match_vnet;
  wire  [3:0] wvalid_match_vnet;

  reg  artoken_0;
  reg  awtoken_0;
  reg  wtoken_0;
  reg  artoken_1;
  reg  awtoken_1;
  reg  wtoken_1;
  reg  artoken_2;
  reg  awtoken_2;
  reg  wtoken_2;
  reg  artoken_3;
  reg  awtoken_3;
  reg  wtoken_3;

  wire  nxt_artoken_0;
  wire  nxt_awtoken_0;
  wire  nxt_wtoken_0;
  wire  nxt_artoken_1;
  wire  nxt_awtoken_1;
  wire  nxt_wtoken_1;
  wire  nxt_artoken_2;
  wire  nxt_awtoken_2;
  wire  nxt_wtoken_2;
  wire  nxt_artoken_3;
  wire  nxt_awtoken_3;
  wire  nxt_wtoken_3;

  `endif

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
  assign ARVNET   = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : ARVNET_i;


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
  assign AWVNET   = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : AWVNET_i;

  assign WID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : WID_i;
  assign WLAST = (DriveOnlyOnEnable & ~ACLKEN) ? 1'bx : WLAST_i;
  assign WSTRB = (DriveOnlyOnEnable & ~ACLKEN) ? {STRB_WIDTH{1'bx}} : WSTRB_i;
  assign WDATA = (DriveOnlyOnEnable & ~ACLKEN) ? {DATA_WIDTH{1'bx}} : WDATA_i;
  assign WUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((WUSER_WIDTH_I == 1) ? 1'bx : {WUSER_WIDTH_I{1'bx}}) : WUSER_i;
  assign WVNET   = (DriveOnlyOnEnable & ~ACLKEN) ? {4{1'bx}} : WVNET_i;

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
  defparam uAxiVnMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiVnMaster.ID_WIDTH       = ID_WIDTH_I;
  defparam uAxiVnMaster.ADDR_WIDTH     = ADDR_WIDTH;         // Addr width

  defparam uAxiVnMaster.AWUSER_WIDTH   = AWUSER_WIDTH_I;
  defparam uAxiVnMaster.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiVnMaster.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiVnMaster.ARUSER_WIDTH   = ARUSER_WIDTH_I;
  defparam uAxiVnMaster.RUSER_WIDTH    = RUSER_WIDTH_I;

  defparam uAxiVnMaster.VN0_NUM_IF  = 1;
  defparam uAxiVnMaster.VN1_NUM_IF  = 1;       
  defparam uAxiVnMaster.VN2_NUM_IF  = 1;       
  defparam uAxiVnMaster.VN3_NUM_IF  = 1;      

  defparam uAxiVnMaster.NUM_VNETS   = VNETS;
  defparam uAxiVnMaster.VN0_VNET    = VNET_VALUE0;
  defparam uAxiVnMaster.VN1_VNET    = VNET_VALUE1;
  defparam uAxiVnMaster.VN2_VNET    = VNET_VALUE2;
  defparam uAxiVnMaster.VN3_VNET    = VNET_VALUE3;

  Axi3VnMasterXvc uAxiVnMaster (

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
      .AWVNET       (AWVNET_i),
      .AWVALID_VECT (),

      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WID          (WID_int),
      .WDATA        (WDATA_i),
      .WSTRB        (WSTRB_i),
      .WLAST        (WLAST_i),
      .WVNET        (WVNET_i),

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
      .ARVNET       (ARVNET_i),
      .ARVALID_VECT (),

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
      .RLAST        (RLAST),

      // Virtual Network 0
      .vawvalid_vn0_m0    (VAWVALID_0),
      .vawready_vn0_m0    (VAWREADY_0),
      .vawqv_vn0_m0       (VAWQOS_0),
      .vwvalid_vn0_m0     (VWVALID_0),
      .vwready_vn0_m0     (VWREADY_0),
      .varvalid_vn0_m0    (VARVALID_0),
      .varready_vn0_m0    (VARREADY_0),
      .varqv_vn0_m0       (VARQOS_0),
  
      .vawvalid_vn0_m1    (),
      .vawready_vn0_m1    (1'b0),
      .vawqv_vn0_m1       (),
      .vwvalid_vn0_m1     (),
      .vwready_vn0_m1     (1'b0),
      .varvalid_vn0_m1    (),
      .varready_vn0_m1    (1'b0),
      .varqv_vn0_m1       (),
  
      .vawvalid_vn0_m2    (),
      .vawready_vn0_m2    (1'b0),
      .vawqv_vn0_m2       (),
      .vwvalid_vn0_m2     (),
      .vwready_vn0_m2     (1'b0),
      .varvalid_vn0_m2    (),
      .varready_vn0_m2    (1'b0),
      .varqv_vn0_m2       (),
  
      .vawvalid_vn0_m3    (),
      .vawready_vn0_m3    (1'b0),
      .vawqv_vn0_m3       (),
      .vwvalid_vn0_m3     (),
      .vwready_vn0_m3     (1'b0),
      .varvalid_vn0_m3    (),
      .varready_vn0_m3    (1'b0),
      .varqv_vn0_m3       (),
  
      .vawvalid_vn0_m4    (),
      .vawready_vn0_m4    (1'b0),
      .vawqv_vn0_m4       (),
      .vwvalid_vn0_m4     (),
      .vwready_vn0_m4     (1'b0),
      .varvalid_vn0_m4    (),
      .varready_vn0_m4    (1'b0),
      .varqv_vn0_m4       (),
  
      .vawvalid_vn0_m5    (),
      .vawready_vn0_m5    (1'b0),
      .vawqv_vn0_m5       (),
      .vwvalid_vn0_m5     (),
      .vwready_vn0_m5     (1'b0),
      .varvalid_vn0_m5    (),
      .varready_vn0_m5    (1'b0),
      .varqv_vn0_m5       (),
  
      .vawvalid_vn0_m6    (),
      .vawready_vn0_m6    (1'b0),
      .vawqv_vn0_m6       (),
      .vwvalid_vn0_m6     (),
      .vwready_vn0_m6     (1'b0),
      .varvalid_vn0_m6    (),
      .varready_vn0_m6    (1'b0),
      .varqv_vn0_m6       (),
  
      .vawvalid_vn0_m7    (),
      .vawready_vn0_m7    (1'b0),
      .vawqv_vn0_m7       (),
      .vwvalid_vn0_m7     (),
      .vwready_vn0_m7     (1'b0),
      .varvalid_vn0_m7    (),
      .varready_vn0_m7    (1'b0),
      .varqv_vn0_m7       (),
  
      .vawvalid_vn0_m8    (),
      .vawready_vn0_m8    (1'b0),
      .vawqv_vn0_m8       (),
      .vwvalid_vn0_m8     (),
      .vwready_vn0_m8     (1'b0),
      .varvalid_vn0_m8    (),
      .varready_vn0_m8    (1'b0),
      .varqv_vn0_m8       (),
  
      .vawvalid_vn0_m9    (),
      .vawready_vn0_m9    (1'b0),
      .vawqv_vn0_m9       (),
      .vwvalid_vn0_m9     (),
      .vwready_vn0_m9     (1'b0),
      .varvalid_vn0_m9    (),
      .varready_vn0_m9    (1'b0),
      .varqv_vn0_m9       (),
  
      .vawvalid_vn0_m10   (),
      .vawready_vn0_m10   (1'b0),
      .vawqv_vn0_m10      (),
      .vwvalid_vn0_m10    (),
      .vwready_vn0_m10    (1'b0),
      .varvalid_vn0_m10   (),
      .varready_vn0_m10   (1'b0),
      .varqv_vn0_m10      (),
  
      .vawvalid_vn0_m11   (),
      .vawready_vn0_m11   (1'b0),
      .vawqv_vn0_m11      (),
      .vwvalid_vn0_m11    (),
      .vwready_vn0_m11    (1'b0),
      .varvalid_vn0_m11   (),
      .varready_vn0_m11   (1'b0),
      .varqv_vn0_m11      (),

      // Virtual Network 1
      .vawvalid_vn1_m0    (VAWVALID_1),
      .vawready_vn1_m0    (VAWREADY_1),
      .vawqv_vn1_m0       (VAWQOS_1),
      .vwvalid_vn1_m0     (VWVALID_1),
      .vwready_vn1_m0     (VWREADY_1),
      .varvalid_vn1_m0    (VARVALID_1),
      .varready_vn1_m0    (VARREADY_1),
      .varqv_vn1_m0       (VARQOS_1),
  
      .vawvalid_vn1_m1    (),
      .vawready_vn1_m1    (1'b0),
      .vawqv_vn1_m1       (),
      .vwvalid_vn1_m1     (),
      .vwready_vn1_m1     (1'b0),
      .varvalid_vn1_m1    (),
      .varready_vn1_m1    (1'b0),
      .varqv_vn1_m1       (),
  
      .vawvalid_vn1_m2    (),
      .vawready_vn1_m2    (1'b0),
      .vawqv_vn1_m2       (),
      .vwvalid_vn1_m2     (),
      .vwready_vn1_m2     (1'b0),
      .varvalid_vn1_m2    (),
      .varready_vn1_m2    (1'b0),
      .varqv_vn1_m2       (),
  
      .vawvalid_vn1_m3    (),
      .vawready_vn1_m3    (1'b0),
      .vawqv_vn1_m3       (),
      .vwvalid_vn1_m3     (),
      .vwready_vn1_m3     (1'b0),
      .varvalid_vn1_m3    (),
      .varready_vn1_m3    (1'b0),
      .varqv_vn1_m3       (),
  
      .vawvalid_vn1_m4    (),
      .vawready_vn1_m4    (1'b0),
      .vawqv_vn1_m4       (),
      .vwvalid_vn1_m4     (),
      .vwready_vn1_m4     (1'b0),
      .varvalid_vn1_m4    (),
      .varready_vn1_m4    (1'b0),
      .varqv_vn1_m4       (),
  
      .vawvalid_vn1_m5    (),
      .vawready_vn1_m5    (1'b0),
      .vawqv_vn1_m5       (),
      .vwvalid_vn1_m5     (),
      .vwready_vn1_m5     (1'b0),
      .varvalid_vn1_m5    (),
      .varready_vn1_m5    (1'b0),
      .varqv_vn1_m5       (),
  
      .vawvalid_vn1_m6    (),
      .vawready_vn1_m6    (1'b0),
      .vawqv_vn1_m6       (),
      .vwvalid_vn1_m6     (),
      .vwready_vn1_m6     (1'b0),
      .varvalid_vn1_m6    (),
      .varready_vn1_m6    (1'b0),
      .varqv_vn1_m6       (),
  
      .vawvalid_vn1_m7    (),
      .vawready_vn1_m7    (1'b0),
      .vawqv_vn1_m7       (),
      .vwvalid_vn1_m7     (),
      .vwready_vn1_m7     (1'b0),
      .varvalid_vn1_m7    (),
      .varready_vn1_m7    (1'b0),
      .varqv_vn1_m7       (),
  
      .vawvalid_vn1_m8    (),
      .vawready_vn1_m8    (1'b0),
      .vawqv_vn1_m8       (),
      .vwvalid_vn1_m8     (),
      .vwready_vn1_m8     (1'b0),
      .varvalid_vn1_m8    (),
      .varready_vn1_m8    (1'b0),
      .varqv_vn1_m8       (),
  
      .vawvalid_vn1_m9    (),
      .vawready_vn1_m9    (1'b0),
      .vawqv_vn1_m9       (),
      .vwvalid_vn1_m9     (),
      .vwready_vn1_m9     (1'b0),
      .varvalid_vn1_m9    (),
      .varready_vn1_m9    (1'b0),
      .varqv_vn1_m9       (),
  
      .vawvalid_vn1_m10   (),
      .vawready_vn1_m10   (1'b0),
      .vawqv_vn1_m10      (),
      .vwvalid_vn1_m10    (),
      .vwready_vn1_m10    (1'b0),
      .varvalid_vn1_m10   (),
      .varready_vn1_m10   (1'b0),
      .varqv_vn1_m10      (),
  
      .vawvalid_vn1_m11   (),
      .vawready_vn1_m11   (1'b0),
      .vawqv_vn1_m11      (),
      .vwvalid_vn1_m11    (),
      .vwready_vn1_m11    (1'b0),
      .varvalid_vn1_m11   (),
      .varready_vn1_m11   (1'b0),
      .varqv_vn1_m11      (),
 
      // Virtual Network 2
      .vawvalid_vn2_m0    (VAWVALID_2),
      .vawready_vn2_m0    (VAWREADY_2),
      .vawqv_vn2_m0       (VAWQOS_2),
      .vwvalid_vn2_m0     (VWVALID_2),
      .vwready_vn2_m0     (VWREADY_2),
      .varvalid_vn2_m0    (VARVALID_2),
      .varready_vn2_m0    (VARREADY_2),
      .varqv_vn2_m0       (VARQOS_2),
  
      .vawvalid_vn2_m1    (),
      .vawready_vn2_m1    (1'b0),
      .vawqv_vn2_m1       (),
      .vwvalid_vn2_m1     (),
      .vwready_vn2_m1     (1'b0),
      .varvalid_vn2_m1    (),
      .varready_vn2_m1    (1'b0),
      .varqv_vn2_m1       (),
  
      .vawvalid_vn2_m2    (),
      .vawready_vn2_m2    (1'b0),
      .vawqv_vn2_m2       (),
      .vwvalid_vn2_m2     (),
      .vwready_vn2_m2     (1'b0),
      .varvalid_vn2_m2    (),
      .varready_vn2_m2    (1'b0),
      .varqv_vn2_m2       (),
  
      .vawvalid_vn2_m3    (),
      .vawready_vn2_m3    (1'b0),
      .vawqv_vn2_m3       (),
      .vwvalid_vn2_m3     (),
      .vwready_vn2_m3     (1'b0),
      .varvalid_vn2_m3    (),
      .varready_vn2_m3    (1'b0),
      .varqv_vn2_m3       (),
  
      .vawvalid_vn2_m4    (),
      .vawready_vn2_m4    (1'b0),
      .vawqv_vn2_m4       (),
      .vwvalid_vn2_m4     (),
      .vwready_vn2_m4     (1'b0),
      .varvalid_vn2_m4    (),
      .varready_vn2_m4    (1'b0),
      .varqv_vn2_m4       (),
  
      .vawvalid_vn2_m5    (),
      .vawready_vn2_m5    (1'b0),
      .vawqv_vn2_m5       (),
      .vwvalid_vn2_m5     (),
      .vwready_vn2_m5     (1'b0),
      .varvalid_vn2_m5    (),
      .varready_vn2_m5    (1'b0),
      .varqv_vn2_m5       (),
  
      .vawvalid_vn2_m6    (),
      .vawready_vn2_m6    (1'b0),
      .vawqv_vn2_m6       (),
      .vwvalid_vn2_m6     (),
      .vwready_vn2_m6     (1'b0),
      .varvalid_vn2_m6    (),
      .varready_vn2_m6    (1'b0),
      .varqv_vn2_m6       (),
  
      .vawvalid_vn2_m7    (),
      .vawready_vn2_m7    (1'b0),
      .vawqv_vn2_m7       (),
      .vwvalid_vn2_m7     (),
      .vwready_vn2_m7     (1'b0),
      .varvalid_vn2_m7    (),
      .varready_vn2_m7    (1'b0),
      .varqv_vn2_m7       (),
  
      .vawvalid_vn2_m8    (),
      .vawready_vn2_m8    (1'b0),
      .vawqv_vn2_m8       (),
      .vwvalid_vn2_m8     (),
      .vwready_vn2_m8     (1'b0),
      .varvalid_vn2_m8    (),
      .varready_vn2_m8    (1'b0),
      .varqv_vn2_m8       (),
  
      .vawvalid_vn2_m9    (),
      .vawready_vn2_m9    (1'b0),
      .vawqv_vn2_m9       (),
      .vwvalid_vn2_m9     (),
      .vwready_vn2_m9     (1'b0),
      .varvalid_vn2_m9    (),
      .varready_vn2_m9    (1'b0),
      .varqv_vn2_m9       (),
  
      .vawvalid_vn2_m10   (),
      .vawready_vn2_m10   (1'b0),
      .vawqv_vn2_m10      (),
      .vwvalid_vn2_m10    (),
      .vwready_vn2_m10    (1'b0),
      .varvalid_vn2_m10   (),
      .varready_vn2_m10   (1'b0),
      .varqv_vn2_m10      (),
  
      .vawvalid_vn2_m11   (),
      .vawready_vn2_m11   (1'b0),
      .vawqv_vn2_m11      (),
      .vwvalid_vn2_m11    (),
      .vwready_vn2_m11    (1'b0),
      .varvalid_vn2_m11   (),
      .varready_vn2_m11   (1'b0),
      .varqv_vn2_m11      (),
 
      // Virtual Network 3
      .vawvalid_vn3_m0    (VAWVALID_3),
      .vawready_vn3_m0    (VAWREADY_3),
      .vawqv_vn3_m0       (VAWQOS_3),
      .vwvalid_vn3_m0     (VWVALID_3),
      .vwready_vn3_m0     (VWREADY_3),
      .varvalid_vn3_m0    (VARVALID_3),
      .varready_vn3_m0    (VARREADY_3),
      .varqv_vn3_m0       (VARQOS_3),
  
      .vawvalid_vn3_m1    (),
      .vawready_vn3_m1    (1'b0),
      .vawqv_vn3_m1       (),
      .vwvalid_vn3_m1     (),
      .vwready_vn3_m1     (1'b0),
      .varvalid_vn3_m1    (),
      .varready_vn3_m1    (1'b0),
      .varqv_vn3_m1       (),
  
      .vawvalid_vn3_m2    (),
      .vawready_vn3_m2    (1'b0),
      .vawqv_vn3_m2       (),
      .vwvalid_vn3_m2     (),
      .vwready_vn3_m2     (1'b0),
      .varvalid_vn3_m2    (),
      .varready_vn3_m2    (1'b0),
      .varqv_vn3_m2       (),
  
      .vawvalid_vn3_m3    (),
      .vawready_vn3_m3    (1'b0),
      .vawqv_vn3_m3       (),
      .vwvalid_vn3_m3     (),
      .vwready_vn3_m3     (1'b0),
      .varvalid_vn3_m3    (),
      .varready_vn3_m3    (1'b0),
      .varqv_vn3_m3       (),
  
      .vawvalid_vn3_m4    (),
      .vawready_vn3_m4    (1'b0),
      .vawqv_vn3_m4       (),
      .vwvalid_vn3_m4     (),
      .vwready_vn3_m4     (1'b0),
      .varvalid_vn3_m4    (),
      .varready_vn3_m4    (1'b0),
      .varqv_vn3_m4       (),
  
      .vawvalid_vn3_m5    (),
      .vawready_vn3_m5    (1'b0),
      .vawqv_vn3_m5       (),
      .vwvalid_vn3_m5     (),
      .vwready_vn3_m5     (1'b0),
      .varvalid_vn3_m5    (),
      .varready_vn3_m5    (1'b0),
      .varqv_vn3_m5       (),
  
      .vawvalid_vn3_m6    (),
      .vawready_vn3_m6    (1'b0),
      .vawqv_vn3_m6       (),
      .vwvalid_vn3_m6     (),
      .vwready_vn3_m6     (1'b0),
      .varvalid_vn3_m6    (),
      .varready_vn3_m6    (1'b0),
      .varqv_vn3_m6       (),
  
      .vawvalid_vn3_m7    (),
      .vawready_vn3_m7    (1'b0),
      .vawqv_vn3_m7       (),
      .vwvalid_vn3_m7     (),
      .vwready_vn3_m7     (1'b0),
      .varvalid_vn3_m7    (),
      .varready_vn3_m7    (1'b0),
      .varqv_vn3_m7       (),
  
      .vawvalid_vn3_m8    (),
      .vawready_vn3_m8    (1'b0),
      .vawqv_vn3_m8       (),
      .vwvalid_vn3_m8     (),
      .vwready_vn3_m8     (1'b0),
      .varvalid_vn3_m8    (),
      .varready_vn3_m8    (1'b0),
      .varqv_vn3_m8       (),
  
      .vawvalid_vn3_m9    (),
      .vawready_vn3_m9    (1'b0),
      .vawqv_vn3_m9       (),
      .vwvalid_vn3_m9     (),
      .vwready_vn3_m9     (1'b0),
      .varvalid_vn3_m9    (),
      .varready_vn3_m9    (1'b0),
      .varqv_vn3_m9       (),
  
      .vawvalid_vn3_m10   (),
      .vawready_vn3_m10   (1'b0),
      .vawqv_vn3_m10      (),
      .vwvalid_vn3_m10    (),
      .vwready_vn3_m10    (1'b0),
      .varvalid_vn3_m10   (),
      .varready_vn3_m10   (1'b0),
      .varqv_vn3_m10      (),
  
      .vawvalid_vn3_m11   (),
      .vawready_vn3_m11   (1'b0),
      .vawqv_vn3_m11      (),
      .vwvalid_vn3_m11    (),
      .vwready_vn3_m11    (1'b0),
      .varvalid_vn3_m11   (),
      .varready_vn3_m11   (1'b0),
      .varqv_vn3_m11      ()

  );

  // When using specman tie-off the unused Event buses
  assign  EMIT_REQ   = EMIT_ACK;
  assign  EMIT_DATA  = {EW_WIDTH{1'b0}};
  assign  WAIT_ACK   = WAIT_REQ;

  `else
  defparam uAxiMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiMaster.ID_WIDTH       = ID_WIDTH_I;
  defparam uAxiMaster.ADDR_WIDTH     = ADDR_WIDTH;         // Addr width

  defparam uAxiMaster.AWUSER_WIDTH   = AWUSER_WIDTH_I + 20;
  defparam uAxiMaster.WUSER_WIDTH    = WUSER_WIDTH_I + 4;
  defparam uAxiMaster.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiMaster.ARUSER_WIDTH   = ARUSER_WIDTH_I + 20;
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

      .AWVALID      (AWVALID_int),
      .AWREADY      (AWREADY_int),
      .AWID         (AWID_int),
      .AWADDR       (AWADDR_i),
      .AWLEN        (AWLEN_i),
      .AWSIZE       (AWSIZE_i),
      .AWBURST      (AWBURST_i),
      .AWLOCK       (AWLOCK_i),
      .AWCACHE      (AWCACHE_i),
      .AWPROT       (AWPROT_i),

      .WVALID       (WVALID_int),
      .WREADY       (WREADY_int),
      .WID          (WID_int),
      .WDATA        (WDATA_i),
      .WSTRB        (WSTRB_i),
      .WLAST        (WLAST_i),

      .BVALID       (BVALID),
      .BREADY       (BREADY),
      .BID          (BID),
      .BRESP        (BRESP),

      .ARVALID      (ARVALID_int),
      .ARREADY      (ARREADY_int),
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
      .WUSER        (WUSER_int),
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

  always @(AWUSER_int) begin
      case (AWUSER_int[3:0]) 
         4'b0000 : AWVNET_r = VNET_VALUE0;
         4'b0001 : AWVNET_r = VNET_VALUE1;
         4'b0010 : AWVNET_r = VNET_VALUE2;
         4'b0011 : AWVNET_r = VNET_VALUE3;
         default : AWVNET_r = 4'b0000;
      endcase
  end

  always @(WUSER_int) begin
      case (WUSER_int[3:0]) 
         4'b0000 : WVNET_r = VNET_VALUE0;
         4'b0001 : WVNET_r = VNET_VALUE1;
         4'b0010 : WVNET_r = VNET_VALUE2;
         4'b0011 : WVNET_r = VNET_VALUE3;
         default : WVNET_r = 4'b0000;
      endcase
  end

  always @(ARUSER_int) begin
      case (ARUSER_int[3:0]) 
         4'b0000 : ARVNET_r = VNET_VALUE0;
         4'b0001 : ARVNET_r = VNET_VALUE1;
         4'b0010 : ARVNET_r = VNET_VALUE2;
         4'b0011 : ARVNET_r = VNET_VALUE3;
         default : ARVNET_r = 4'b0000;
      endcase
  end

  //VNET extration logic
  assign AWVNET_i = AWVNET_r;
  assign ARVNET_i = ARVNET_r;
  assign WVNET_i  = WVNET_r;

  //AxRegion assignments
  assign AWREGION_i = AWUSER_int[7:4];
  assign ARREGION_i = ARUSER_int[7:4];

  //AxQV value assignments
  assign AWQV_i = (AWVALID) ? AWUSER_int[11:8] : AWQV_reg;
  assign ARQV_i = (ARVALID) ? ARUSER_int[11:8] : ARQV_reg;

  //AxUser assignments
  assign AWUSER_i = AWUSER_int[USER_MAX_AW+20:20];
  assign ARUSER_i = ARUSER_int[USER_MAX_AR+20:20];
  assign WUSER_i  = WUSER_int[USER_MAX_W+4:4];

  //QV registers
  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           AWQV_reg   <= 4'b0000;
       end else if (AWVALID) begin
           AWQV_reg   <= AWQV_i;
       end
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           ARQV_reg   <= 4'b0000;
       end else if (ARVALID) begin
           ARQV_reg   <= ARQV_i;
       end
    end

  // -----------------------------------------------------------------------------
  //  Token generation
  // -----------------------------------------------------------------------------
  defparam uVnIDMonitor.ID_WIDTH     = ID_WIDTH;         
  defparam uVnIDMonitor.NUM_VNETS    = VNETS;
  defparam uVnIDMonitor.VNET_0       = VNET_VALUE0;
  defparam uVnIDMonitor.VNET_1       = VNET_VALUE1;
  defparam uVnIDMonitor.VNET_2       = VNET_VALUE2;
  defparam uVnIDMonitor.VNET_3       = VNET_VALUE3;
  defparam uVnIDMonitor.NO_ERROR_ON_M_VNET = 1;            //Mask .. don't error 
  defparam uVnIDMonitor.MAXWBURSTS   = 200;
  defparam uVnIDMonitor.MAXRBURSTS   = 200;              
  defparam uVnIDMonitor.AXI4_N_3     = 0;              
  defparam uVnIDMonitor.VALID_WIDTH  = 4;              

  VnIDMonitor uVnIDMonitor (

   // AXI AW Channel Signals
   .AWVALID                (AWVALID_int),
   .AWREADY                (AWREADY_masked),
   .AWID                   (AWID),
   .AWVNET                 (AWVNET),
   .AWVALIDo               (awvalid_match_vnet),
   .AWREADYo               (AWREADY_int),

   // AXI W Channel Signals
   .WVALID                 (WVALID_int),
   .WREADY                 (WREADY_masked),
   .WVNET                  (WVNET),
   .WLAST                  (WLAST),
   .WID                    (WID),
   .WVALIDo                (wvalid_match_vnet),
   .WREADYo                (WREADY_int),

   // AXI AR Channel Signals
   .ARVALID                (ARVALID_int),
   .ARREADY                (ARREADY_masked),
   .ARID                   (ARID),
   .ARVNET                 (ARVNET),
   .ARVALIDo               (arvalid_match_vnet),
   .ARREADYo               (ARREADY_int),

   //Bchannel
   .BVALID                 (BVALID),
   .BREADY                 (BREADY),
   .BID                    (BID),
   .BVALIDo                (),       //Not required here

   //Rchannnel
   .RVALID                 (RVALID),
   .RREADY                 (RREADY),
   .RLAST                  (RLAST),
   .RID                    (RID),
   .RVALIDo                (),       //Not required here

   // Global Signals
   .ACLK             (ACLK),
   .ARESETn          (ARESETn)

);

  //Create Mask signals
  assign arenable = ((arvalid_match_vnet[0] & artoken_0) ||
                     (arvalid_match_vnet[1] & artoken_1) ||
                     (arvalid_match_vnet[2] & artoken_2) ||
                     (arvalid_match_vnet[3] & artoken_3));

  assign awenable = ((awvalid_match_vnet[0] & awtoken_0) ||
                     (awvalid_match_vnet[1] & awtoken_1) ||
                     (awvalid_match_vnet[2] & awtoken_2) ||
                     (awvalid_match_vnet[3] & awtoken_3));

  assign wenable = ((wvalid_match_vnet[0] & wtoken_0) ||
                    (wvalid_match_vnet[1] & wtoken_1) ||
                    (wvalid_match_vnet[2] & wtoken_2) ||
                    (wvalid_match_vnet[3] & wtoken_3));

  assign iARVALID    = ARVALID_int & arenable;
  assign ARREADY_masked = iARREADY & arenable;
  assign iAWVALID    = AWVALID_int & awenable;
  assign AWREADY_masked = iAWREADY & awenable;
  assign WVALID      = WVALID_int & wenable;
  assign WREADY_masked  = WREADY & wenable;

  //Drive the token request (VALID signals)
  assign VARVALID_0 = ~artoken_0 && (arvalid_match_vnet[0] || VNET_PREFETCH0);
  assign VAWVALID_0 = ~awtoken_0 && (awvalid_match_vnet[0] || VNET_PREFETCH0);
  assign VWVALID_0  = ~wtoken_0  && wvalid_match_vnet[0];
  assign VARVALID_1 = ~artoken_1 && (arvalid_match_vnet[1] || VNET_PREFETCH1);
  assign VAWVALID_1 = ~awtoken_1 && (awvalid_match_vnet[1] || VNET_PREFETCH1);
  assign VWVALID_1  = ~wtoken_1  && wvalid_match_vnet[1];
  assign VARVALID_2 = ~artoken_2 && (arvalid_match_vnet[2] || VNET_PREFETCH2);
  assign VAWVALID_2 = ~awtoken_2 && (awvalid_match_vnet[2] || VNET_PREFETCH2);
  assign VWVALID_2  = ~wtoken_2  && wvalid_match_vnet[2];
  assign VARVALID_3 = ~artoken_3 && (arvalid_match_vnet[3] || VNET_PREFETCH3);
  assign VAWVALID_3 = ~awtoken_3 && (awvalid_match_vnet[3] || VNET_PREFETCH3);
  assign VWVALID_3  = ~wtoken_3  && wvalid_match_vnet[3];

  //Drive the TOken QOS to the standard QoS 
  assign VAWQOS_0   = AWQV_i;
  assign VARQOS_0   = ARQV_i;
  assign VAWQOS_1   = AWQV_i;
  assign VARQOS_1   = ARQV_i;
  assign VAWQOS_2   = AWQV_i;
  assign VARQOS_2   = ARQV_i;
  assign VAWQOS_3   = AWQV_i;
  assign VARQOS_3   = ARQV_i;

  //Determine the next value of the token
  assign nxt_artoken_0 = (VARVALID_0 & VARREADY_0) ? 1'b1 : ((arvalid_match_vnet[0] & ARVALID & ARREADY) ? 1'b0 : artoken_0);
  assign nxt_awtoken_0 = (VAWVALID_0 & VAWREADY_0) ? 1'b1 : ((awvalid_match_vnet[0] & AWVALID & AWREADY) ? 1'b0 : awtoken_0);
  assign nxt_wtoken_0  = (VWVALID_0 & VWREADY_0) ? 1'b1 :   ((wvalid_match_vnet[0] & WVALID & WREADY)    ? 1'b0 : wtoken_0);
  assign nxt_artoken_1 = (VARVALID_1 & VARREADY_1) ? 1'b1 : ((arvalid_match_vnet[1] & ARVALID & ARREADY) ? 1'b0 : artoken_1);
  assign nxt_awtoken_1 = (VAWVALID_1 & VAWREADY_1) ? 1'b1 : ((awvalid_match_vnet[1] & AWVALID & AWREADY) ? 1'b0 : awtoken_1);
  assign nxt_wtoken_1  = (VWVALID_1 & VWREADY_1) ? 1'b1 :   ((wvalid_match_vnet[1] & WVALID & WREADY)    ? 1'b0 : wtoken_1);
  assign nxt_artoken_2 = (VARVALID_2 & VARREADY_2) ? 1'b1 : ((arvalid_match_vnet[2] & ARVALID & ARREADY) ? 1'b0 : artoken_2);
  assign nxt_awtoken_2 = (VAWVALID_2 & VAWREADY_2) ? 1'b1 : ((awvalid_match_vnet[2] & AWVALID & AWREADY) ? 1'b0 : awtoken_2);
  assign nxt_wtoken_2  = (VWVALID_2 & VWREADY_2) ? 1'b1 :   ((wvalid_match_vnet[2] & WVALID & WREADY)    ? 1'b0 : wtoken_2);
  assign nxt_artoken_3 = (VARVALID_3 & VARREADY_3) ? 1'b1 : ((arvalid_match_vnet[3] & ARVALID & ARREADY) ? 1'b0 : artoken_3);
  assign nxt_awtoken_3 = (VAWVALID_3 & VAWREADY_3) ? 1'b1 : ((awvalid_match_vnet[3] & AWVALID & AWREADY) ? 1'b0 : awtoken_3);
  assign nxt_wtoken_3  = (VWVALID_3 & VWREADY_3) ? 1'b1 :   ((wvalid_match_vnet[3] & WVALID & WREADY)    ? 1'b0 : wtoken_3);

  //Token registers
  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           artoken_0  <= VNET_PREFETCH0;
           awtoken_0  <= VNET_PREFETCH0;
           wtoken_0   <= 1'b0;
           artoken_1  <= VNET_PREFETCH1;
           awtoken_1  <= VNET_PREFETCH1;
           wtoken_1   <= 1'b0;
           artoken_2  <= VNET_PREFETCH2;
           awtoken_2  <= VNET_PREFETCH2;
           wtoken_2   <= 1'b0;
           artoken_3  <= VNET_PREFETCH3;
           awtoken_3  <= VNET_PREFETCH3;
           wtoken_3   <= 1'b0;    
       end else begin
           artoken_0  <= nxt_artoken_0;
           awtoken_0  <= nxt_awtoken_0;
           wtoken_0   <= nxt_wtoken_0;
           artoken_1  <= nxt_artoken_1;
           awtoken_1  <= nxt_awtoken_1;
           wtoken_1   <= nxt_wtoken_1;
           artoken_2  <= nxt_artoken_2;
           awtoken_2  <= nxt_awtoken_2;
           wtoken_2   <= nxt_wtoken_2;
           artoken_3  <= nxt_artoken_3;
           awtoken_3  <= nxt_awtoken_3;
           wtoken_3   <= nxt_wtoken_3;    
       end
    end

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

  defparam uAxiVnPC.VALID_WIDTH  = 1;
  defparam uAxiVnPC.DATA_WIDTH   = DATA_WIDTH;
  defparam uAxiVnPC.ADDR_WIDTH   = ADDR_WIDTH;         // Addr width
  defparam uAxiVnPC.ID_WIDTH     = ID_WIDTH_I;
  defparam uAxiVnPC.WDEPTH       = 1;
  //The +1 are because AxiPC counts transactions from valid assertion not-handshake.
  defparam uAxiVnPC.MAXRBURSTS   = 200 + 1;
  defparam uAxiVnPC.MAXWBURSTS   = 200 + 1 + leading_write_depth + 1;
  defparam uAxiVnPC.MAXWAITS     = MaxWaits;
  defparam uAxiVnPC.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam uAxiVnPC.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxiVnPC.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxiVnPC.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam uAxiVnPC.RUSER_WIDTH  = RUSER_WIDTH_I;
  defparam uAxiVnPC.AllowLeadingRdata = AllowLeadingRdata;
  defparam uAxiVnPC.AXI_ERRL_PropertyType = 2; // No Low power interface checking
  // Recommended Rules Enable
  defparam uAxiVnPC.RecommendOn   = RecommendOn;    // enable/disable reporting of all  AXI_REC*_* rules
  defparam uAxiVnPC.RecMaxWaitOn  = RecMaxWaitOn;   // enable/disable reporting of just AXI_REC*_MAX_WAIT rules

  defparam uAxiVnPC.NUM_VNETS     = VNETS;
  defparam uAxiVnPC.VN0_VNET      = VNET_VALUE0;
  defparam uAxiVnPC.VN1_VNET      = VNET_VALUE1;
  defparam uAxiVnPC.VN2_VNET      = VNET_VALUE2;
  defparam uAxiVnPC.VN3_VNET      = VNET_VALUE3;

  NIC400_AxiVnPC uAxiVnPC (

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
      .CSYSACK        (1'b0),

      .AWVNET         (AWVNET_i),
      .WVNET          (WVNET_i),
      .ARVNET         (ARVNET_i)
  );

defparam uVNTokenPC0.DIRECTION = 0;
defparam uVNTokenPC0.ID_WIDTH = ID_WIDTH_I;
defparam uVNTokenPC0.NON_VN_MASK = 0;
defparam uVNTokenPC0.PREREQUEST = VNET_PREFETCH0;
defparam uVNTokenPC0.VALID_WIDTH = 1;
defparam uVNTokenPC0.VNET = VNET_VALUE0;

VnTokenPC     uVNTokenPC0 (
  .AWVALID              (AWVALID),
  .AWVALID_VECT         (1'b0),
  .AWREADY              (AWREADY),
  .AWVNET               (AWVNET),
  .WVALID               (WVALID),
  .WREADY               (WREADY),
  .WVNET                (WVNET),
  .ARVALID              (ARVALID),
  .ARVALID_VECT         (1'b0),
  .ARREADY              (ARREADY),
  .ARVNET               (ARVNET),
  .ARID                 (ARID),
  .AWID                 (AWID),
  .VAWVALID_0           (VAWVALID_0),
  .VAWREADY_0           (VAWREADY_0),
  .VAWQOS_0             (VAWQOS_0),
  .VWVALID_0            (VWVALID_0),
  .VWREADY_0            (VWREADY_0),
  .VARVALID_0           (VARVALID_0),
  .VARREADY_0           (VARREADY_0),
  .VARQOS_0             (VARQOS_0),
  .VAWVALID_1           (1'b0),
  .VAWREADY_1           (1'b0),
  .VAWQOS_1             (4'b0),
  .VWVALID_1            (1'b0),
  .VWREADY_1            (1'b0),
  .VARVALID_1           (1'b0),
  .VARREADY_1           (1'b0),
  .VARQOS_1             (4'b0),
  .VAWVALID_10          (1'b0),
  .VAWREADY_10          (1'b0),
  .VAWQOS_10            (4'b0),
  .VWVALID_10           (1'b0),
  .VWREADY_10           (1'b0),
  .VARVALID_10          (1'b0),
  .VARREADY_10          (1'b0),
  .VARQOS_10            (4'b0),
  .VAWVALID_11          (1'b0),
  .VAWREADY_11          (1'b0),
  .VAWQOS_11            (4'b0),
  .VWVALID_11           (1'b0),
  .VWREADY_11           (1'b0),
  .VARVALID_11          (1'b0),
  .VARREADY_11          (1'b0),
  .VARQOS_11            (4'b0),
  .VAWVALID_12          (1'b0),
  .VAWREADY_12          (1'b0),
  .VAWQOS_12            (4'b0),
  .VWVALID_12           (1'b0),
  .VWREADY_12           (1'b0),
  .VARVALID_12          (1'b0),
  .VARREADY_12          (1'b0),
  .VARQOS_12            (4'b0),
  .ACLK                 (ACLKPC),
  .ARESETn              (ARESETn),
  .VAWVALID_2           (1'b0),
  .VAWREADY_2           (1'b0),
  .VAWQOS_2             (4'b0),
  .VWVALID_2            (1'b0),
  .VWREADY_2            (1'b0),
  .VARVALID_2           (1'b0),
  .VARREADY_2           (1'b0),
  .VARQOS_2             (4'b0),
  .VAWVALID_3           (1'b0),
  .VAWREADY_3           (1'b0),
  .VAWQOS_3             (4'b0),
  .VWVALID_3            (1'b0),
  .VWREADY_3            (1'b0),
  .VARVALID_3           (1'b0),
  .VARREADY_3           (1'b0),
  .VARQOS_3             (4'b0),
  .VAWVALID_4           (1'b0),
  .VAWREADY_4           (1'b0),
  .VAWQOS_4             (4'b0),
  .VWVALID_4            (1'b0),
  .VWREADY_4            (1'b0),
  .VARVALID_4           (1'b0),
  .VARREADY_4           (1'b0),
  .VARQOS_4             (4'b0),
  .VAWVALID_5           (1'b0),
  .VAWREADY_5           (1'b0),
  .VAWQOS_5             (4'b0),
  .VWVALID_5            (1'b0),
  .VWREADY_5            (1'b0),
  .VARVALID_5           (1'b0),
  .VARREADY_5           (1'b0),
  .VARQOS_5             (4'b0),
  .VAWVALID_6           (1'b0),
  .VAWREADY_6           (1'b0),
  .VAWQOS_6             (4'b0),
  .VWVALID_6            (1'b0),
  .VWREADY_6            (1'b0),
  .VARVALID_6           (1'b0),
  .VARREADY_6           (1'b0),
  .VARQOS_6             (4'b0),
  .VAWVALID_7           (1'b0),
  .VAWREADY_7           (1'b0),
  .VAWQOS_7             (4'b0),
  .VWVALID_7            (1'b0),
  .VWREADY_7            (1'b0),
  .VARVALID_7           (1'b0),
  .VARREADY_7           (1'b0),
  .VARQOS_7             (4'b0),
  .VAWVALID_8           (1'b0),
  .VAWREADY_8           (1'b0),
  .VAWQOS_8             (4'b0),
  .VWVALID_8            (1'b0),
  .VWREADY_8            (1'b0),
  .VARVALID_8           (1'b0),
  .VARREADY_8           (1'b0),
  .VARQOS_8             (4'b0),
  .VAWVALID_9           (1'b0),
  .VAWREADY_9           (1'b0),
  .VAWQOS_9             (4'b0),
  .VWVALID_9            (1'b0),
  .VWREADY_9            (1'b0),
  .VARVALID_9           (1'b0),
  .VARREADY_9           (1'b0),
  .VARQOS_9             (4'b0)
);


defparam uVNTokenPC1.DIRECTION = 0;
defparam uVNTokenPC1.ID_WIDTH = ID_WIDTH_I;
defparam uVNTokenPC1.NON_VN_MASK = 0;
defparam uVNTokenPC1.PREREQUEST = VNET_PREFETCH1;
defparam uVNTokenPC1.VALID_WIDTH = 1;
defparam uVNTokenPC1.VNET = VNET_VALUE1;

VnTokenPC     uVNTokenPC1 (
  .AWVALID              (AWVALID),
  .AWVALID_VECT         (1'b0),
  .AWREADY              (AWREADY),
  .AWVNET               (AWVNET),
  .WVALID               (WVALID),
  .WREADY               (WREADY),
  .WVNET                (WVNET),
  .ARVALID              (ARVALID),
  .ARVALID_VECT         (1'b0),
  .ARREADY              (ARREADY),
  .ARVNET               (ARVNET),
  .ARID                 (ARID),
  .AWID                 (AWID),
  .VAWVALID_0           (VAWVALID_1),
  .VAWREADY_0           (VAWREADY_1),
  .VAWQOS_0             (VAWQOS_1),
  .VWVALID_0            (VWVALID_1),
  .VWREADY_0            (VWREADY_1),
  .VARVALID_0           (VARVALID_1),
  .VARREADY_0           (VARREADY_1),
  .VARQOS_0             (VARQOS_1),
  .VAWVALID_1           (1'b0),
  .VAWREADY_1           (1'b0),
  .VAWQOS_1             (4'b0),
  .VWVALID_1            (1'b0),
  .VWREADY_1            (1'b0),
  .VARVALID_1           (1'b0),
  .VARREADY_1           (1'b0),
  .VARQOS_1             (4'b0),
  .VAWVALID_10          (1'b0),
  .VAWREADY_10          (1'b0),
  .VAWQOS_10            (4'b0),
  .VWVALID_10           (1'b0),
  .VWREADY_10           (1'b0),
  .VARVALID_10          (1'b0),
  .VARREADY_10          (1'b0),
  .VARQOS_10            (4'b0),
  .VAWVALID_11          (1'b0),
  .VAWREADY_11          (1'b0),
  .VAWQOS_11            (4'b0),
  .VWVALID_11           (1'b0),
  .VWREADY_11           (1'b0),
  .VARVALID_11          (1'b0),
  .VARREADY_11          (1'b0),
  .VARQOS_11            (4'b0),
  .VAWVALID_12          (1'b0),
  .VAWREADY_12          (1'b0),
  .VAWQOS_12            (4'b0),
  .VWVALID_12           (1'b0),
  .VWREADY_12           (1'b0),
  .VARVALID_12          (1'b0),
  .VARREADY_12          (1'b0),
  .VARQOS_12            (4'b0),
  .ACLK                 (ACLKPC),
  .ARESETn              (ARESETn),
  .VAWVALID_2           (1'b0),
  .VAWREADY_2           (1'b0),
  .VAWQOS_2             (4'b0),
  .VWVALID_2            (1'b0),
  .VWREADY_2            (1'b0),
  .VARVALID_2           (1'b0),
  .VARREADY_2           (1'b0),
  .VARQOS_2             (4'b0),
  .VAWVALID_3           (1'b0),
  .VAWREADY_3           (1'b0),
  .VAWQOS_3             (4'b0),
  .VWVALID_3            (1'b0),
  .VWREADY_3            (1'b0),
  .VARVALID_3           (1'b0),
  .VARREADY_3           (1'b0),
  .VARQOS_3             (4'b0),
  .VAWVALID_4           (1'b0),
  .VAWREADY_4           (1'b0),
  .VAWQOS_4             (4'b0),
  .VWVALID_4            (1'b0),
  .VWREADY_4            (1'b0),
  .VARVALID_4           (1'b0),
  .VARREADY_4           (1'b0),
  .VARQOS_4             (4'b0),
  .VAWVALID_5           (1'b0),
  .VAWREADY_5           (1'b0),
  .VAWQOS_5             (4'b0),
  .VWVALID_5            (1'b0),
  .VWREADY_5            (1'b0),
  .VARVALID_5           (1'b0),
  .VARREADY_5           (1'b0),
  .VARQOS_5             (4'b0),
  .VAWVALID_6           (1'b0),
  .VAWREADY_6           (1'b0),
  .VAWQOS_6             (4'b0),
  .VWVALID_6            (1'b0),
  .VWREADY_6            (1'b0),
  .VARVALID_6           (1'b0),
  .VARREADY_6           (1'b0),
  .VARQOS_6             (4'b0),
  .VAWVALID_7           (1'b0),
  .VAWREADY_7           (1'b0),
  .VAWQOS_7             (4'b0),
  .VWVALID_7            (1'b0),
  .VWREADY_7            (1'b0),
  .VARVALID_7           (1'b0),
  .VARREADY_7           (1'b0),
  .VARQOS_7             (4'b0),
  .VAWVALID_8           (1'b0),
  .VAWREADY_8           (1'b0),
  .VAWQOS_8             (4'b0),
  .VWVALID_8            (1'b0),
  .VWREADY_8            (1'b0),
  .VARVALID_8           (1'b0),
  .VARREADY_8           (1'b0),
  .VARQOS_8             (4'b0),
  .VAWVALID_9           (1'b0),
  .VAWREADY_9           (1'b0),
  .VAWQOS_9             (4'b0),
  .VWVALID_9            (1'b0),
  .VWREADY_9            (1'b0),
  .VARVALID_9           (1'b0),
  .VARREADY_9           (1'b0),
  .VARQOS_9             (4'b0)
);
defparam uVNTokenPC2.DIRECTION = 0;
defparam uVNTokenPC2.ID_WIDTH = ID_WIDTH_I;
defparam uVNTokenPC2.NON_VN_MASK = 0;
defparam uVNTokenPC2.PREREQUEST = VNET_PREFETCH2;
defparam uVNTokenPC2.VALID_WIDTH = 1;
defparam uVNTokenPC2.VNET = VNET_VALUE2;


VnTokenPC     uVNTokenPC2 (
  .AWVALID              (AWVALID),
  .AWVALID_VECT         (1'b0),
  .AWREADY              (AWREADY),
  .AWVNET               (AWVNET),
  .WVALID               (WVALID),
  .WREADY               (WREADY),
  .WVNET                (WVNET),
  .ARVALID              (ARVALID),
  .ARVALID_VECT         (1'b0),
  .ARREADY              (ARREADY),
  .ARVNET               (ARVNET),
  .ARID                 (ARID),
  .AWID                 (AWID),
  .VAWVALID_0           (VAWVALID_2),
  .VAWREADY_0           (VAWREADY_2),
  .VAWQOS_0             (VAWQOS_2),
  .VWVALID_0            (VWVALID_2),
  .VWREADY_0            (VWREADY_2),
  .VARVALID_0           (VARVALID_2),
  .VARREADY_0           (VARREADY_2),
  .VARQOS_0             (VARQOS_2),
  .VAWVALID_1           (1'b0),
  .VAWREADY_1           (1'b0),
  .VAWQOS_1             (4'b0),
  .VWVALID_1            (1'b0),
  .VWREADY_1            (1'b0),
  .VARVALID_1           (1'b0),
  .VARREADY_1           (1'b0),
  .VARQOS_1             (4'b0),
  .VAWVALID_10          (1'b0),
  .VAWREADY_10          (1'b0),
  .VAWQOS_10            (4'b0),
  .VWVALID_10           (1'b0),
  .VWREADY_10           (1'b0),
  .VARVALID_10          (1'b0),
  .VARREADY_10          (1'b0),
  .VARQOS_10            (4'b0),
  .VAWVALID_11          (1'b0),
  .VAWREADY_11          (1'b0),
  .VAWQOS_11            (4'b0),
  .VWVALID_11           (1'b0),
  .VWREADY_11           (1'b0),
  .VARVALID_11          (1'b0),
  .VARREADY_11          (1'b0),
  .VARQOS_11            (4'b0),
  .VAWVALID_12          (1'b0),
  .VAWREADY_12          (1'b0),
  .VAWQOS_12            (4'b0),
  .VWVALID_12           (1'b0),
  .VWREADY_12           (1'b0),
  .VARVALID_12          (1'b0),
  .VARREADY_12          (1'b0),
  .VARQOS_12            (4'b0),
  .ACLK                 (ACLKPC),
  .ARESETn              (ARESETn),
  .VAWVALID_2           (1'b0),
  .VAWREADY_2           (1'b0),
  .VAWQOS_2             (4'b0),
  .VWVALID_2            (1'b0),
  .VWREADY_2            (1'b0),
  .VARVALID_2           (1'b0),
  .VARREADY_2           (1'b0),
  .VARQOS_2             (4'b0),
  .VAWVALID_3           (1'b0),
  .VAWREADY_3           (1'b0),
  .VAWQOS_3             (4'b0),
  .VWVALID_3            (1'b0),
  .VWREADY_3            (1'b0),
  .VARVALID_3           (1'b0),
  .VARREADY_3           (1'b0),
  .VARQOS_3             (4'b0),
  .VAWVALID_4           (1'b0),
  .VAWREADY_4           (1'b0),
  .VAWQOS_4             (4'b0),
  .VWVALID_4            (1'b0),
  .VWREADY_4            (1'b0),
  .VARVALID_4           (1'b0),
  .VARREADY_4           (1'b0),
  .VARQOS_4             (4'b0),
  .VAWVALID_5           (1'b0),
  .VAWREADY_5           (1'b0),
  .VAWQOS_5             (4'b0),
  .VWVALID_5            (1'b0),
  .VWREADY_5            (1'b0),
  .VARVALID_5           (1'b0),
  .VARREADY_5           (1'b0),
  .VARQOS_5             (4'b0),
  .VAWVALID_6           (1'b0),
  .VAWREADY_6           (1'b0),
  .VAWQOS_6             (4'b0),
  .VWVALID_6            (1'b0),
  .VWREADY_6            (1'b0),
  .VARVALID_6           (1'b0),
  .VARREADY_6           (1'b0),
  .VARQOS_6             (4'b0),
  .VAWVALID_7           (1'b0),
  .VAWREADY_7           (1'b0),
  .VAWQOS_7             (4'b0),
  .VWVALID_7            (1'b0),
  .VWREADY_7            (1'b0),
  .VARVALID_7           (1'b0),
  .VARREADY_7           (1'b0),
  .VARQOS_7             (4'b0),
  .VAWVALID_8           (1'b0),
  .VAWREADY_8           (1'b0),
  .VAWQOS_8             (4'b0),
  .VWVALID_8            (1'b0),
  .VWREADY_8            (1'b0),
  .VARVALID_8           (1'b0),
  .VARREADY_8           (1'b0),
  .VARQOS_8             (4'b0),
  .VAWVALID_9           (1'b0),
  .VAWREADY_9           (1'b0),
  .VAWQOS_9             (4'b0),
  .VWVALID_9            (1'b0),
  .VWREADY_9            (1'b0),
  .VARVALID_9           (1'b0),
  .VARREADY_9           (1'b0),
  .VARQOS_9             (4'b0)
);


defparam uVNTokenPC3.DIRECTION = 0;
defparam uVNTokenPC3.ID_WIDTH = ID_WIDTH_I;
defparam uVNTokenPC3.NON_VN_MASK = 0;
defparam uVNTokenPC3.PREREQUEST = VNET_PREFETCH3;
defparam uVNTokenPC3.VALID_WIDTH = 1;
defparam uVNTokenPC3.VNET = VNET_VALUE3;

VnTokenPC     uVNTokenPC3 (
  .AWVALID              (AWVALID),
  .AWVALID_VECT         (1'b0),
  .AWREADY              (AWREADY),
  .AWVNET               (AWVNET),
  .WVALID               (WVALID),
  .WREADY               (WREADY),
  .WVNET                (WVNET),
  .ARVALID              (ARVALID),
  .ARVALID_VECT         (1'b0),
  .ARREADY              (ARREADY),
  .ARVNET               (ARVNET),
  .ARID                 (ARID),
  .AWID                 (AWID),
  .VAWVALID_0           (VAWVALID_3),
  .VAWREADY_0           (VAWREADY_3),
  .VAWQOS_0             (VAWQOS_3),
  .VWVALID_0            (VWVALID_3),
  .VWREADY_0            (VWREADY_3),
  .VARVALID_0           (VARVALID_3),
  .VARREADY_0           (VARREADY_3),
  .VARQOS_0             (VARQOS_3),
  .VAWVALID_1           (1'b0),
  .VAWREADY_1           (1'b0),
  .VAWQOS_1             (4'b0),
  .VWVALID_1            (1'b0),
  .VWREADY_1            (1'b0),
  .VARVALID_1           (1'b0),
  .VARREADY_1           (1'b0),
  .VARQOS_1             (4'b0),
  .VAWVALID_10          (1'b0),
  .VAWREADY_10          (1'b0),
  .VAWQOS_10            (4'b0),
  .VWVALID_10           (1'b0),
  .VWREADY_10           (1'b0),
  .VARVALID_10          (1'b0),
  .VARREADY_10          (1'b0),
  .VARQOS_10            (4'b0),
  .VAWVALID_11          (1'b0),
  .VAWREADY_11          (1'b0),
  .VAWQOS_11            (4'b0),
  .VWVALID_11           (1'b0),
  .VWREADY_11           (1'b0),
  .VARVALID_11          (1'b0),
  .VARREADY_11          (1'b0),
  .VARQOS_11            (4'b0),
  .VAWVALID_12          (1'b0),
  .VAWREADY_12          (1'b0),
  .VAWQOS_12            (4'b0),
  .VWVALID_12           (1'b0),
  .VWREADY_12           (1'b0),
  .VARVALID_12          (1'b0),
  .VARREADY_12          (1'b0),
  .VARQOS_12            (4'b0),
  .ACLK                 (ACLKPC),
  .ARESETn              (ARESETn),
  .VAWVALID_2           (1'b0),
  .VAWREADY_2           (1'b0),
  .VAWQOS_2             (4'b0),
  .VWVALID_2            (1'b0),
  .VWREADY_2            (1'b0),
  .VARVALID_2           (1'b0),
  .VARREADY_2           (1'b0),
  .VARQOS_2             (4'b0),
  .VAWVALID_3           (1'b0),
  .VAWREADY_3           (1'b0),
  .VAWQOS_3             (4'b0),
  .VWVALID_3            (1'b0),
  .VWREADY_3            (1'b0),
  .VARVALID_3           (1'b0),
  .VARREADY_3           (1'b0),
  .VARQOS_3             (4'b0),
  .VAWVALID_4           (1'b0),
  .VAWREADY_4           (1'b0),
  .VAWQOS_4             (4'b0),
  .VWVALID_4            (1'b0),
  .VWREADY_4            (1'b0),
  .VARVALID_4           (1'b0),
  .VARREADY_4           (1'b0),
  .VARQOS_4             (4'b0),
  .VAWVALID_5           (1'b0),
  .VAWREADY_5           (1'b0),
  .VAWQOS_5             (4'b0),
  .VWVALID_5            (1'b0),
  .VWREADY_5            (1'b0),
  .VARVALID_5           (1'b0),
  .VARREADY_5           (1'b0),
  .VARQOS_5             (4'b0),
  .VAWVALID_6           (1'b0),
  .VAWREADY_6           (1'b0),
  .VAWQOS_6             (4'b0),
  .VWVALID_6            (1'b0),
  .VWREADY_6            (1'b0),
  .VARVALID_6           (1'b0),
  .VARREADY_6           (1'b0),
  .VARQOS_6             (4'b0),
  .VAWVALID_7           (1'b0),
  .VAWREADY_7           (1'b0),
  .VAWQOS_7             (4'b0),
  .VWVALID_7            (1'b0),
  .VWREADY_7            (1'b0),
  .VARVALID_7           (1'b0),
  .VARREADY_7           (1'b0),
  .VARQOS_7             (4'b0),
  .VAWVALID_8           (1'b0),
  .VAWREADY_8           (1'b0),
  .VAWQOS_8             (4'b0),
  .VWVALID_8            (1'b0),
  .VWREADY_8            (1'b0),
  .VARVALID_8           (1'b0),
  .VARREADY_8           (1'b0),
  .VARQOS_8             (4'b0),
  .VAWVALID_9           (1'b0),
  .VAWREADY_9           (1'b0),
  .VAWQOS_9             (4'b0),
  .VWVALID_9            (1'b0),
  .VWREADY_9            (1'b0),
  .VARVALID_9           (1'b0),
  .VARREADY_9           (1'b0),
  .VARQOS_9             (4'b0)
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

