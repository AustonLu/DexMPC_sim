// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2008-2012 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 135243
//
// Date                   :  2012-08-17 10:19:46 +0100 (Fri, 17 Aug 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : avip axi monitor
//
// Description : 
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module avip_axi_monitor_wrapper (
   // global signals 
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
   WID,
   WDATA,
   WSTRB,
   WUSER,
   WLAST,
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
   RDATA,
   RRESP,
   RUSER,
   RLAST,
   RVALID,
   RREADY
 );

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter INSTANCE_NAME    = "AVIPMonitor";

  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter ADDR_WIDTH       = 32;
  parameter AWUSER_WIDTH     = 8;
  parameter ARUSER_WIDTH     = 8;
  parameter WUSER_WIDTH      = 8;
  parameter RUSER_WIDTH      = 8;
  parameter BUSER_WIDTH      = 8;
  parameter ID_WIDTH         = 16;

  parameter AWUSER_WIDTH_I   = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
  parameter ARUSER_WIDTH_I   = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
  parameter WUSER_WIDTH_I    = (WUSER_WIDTH == 0) ? 1 : WUSER_WIDTH;
  parameter RUSER_WIDTH_I    = (RUSER_WIDTH == 0) ? 1 : RUSER_WIDTH;
  parameter BUSER_WIDTH_I    = (BUSER_WIDTH == 0) ? 1 : BUSER_WIDTH;
  parameter ID_WIDTH_I       = (ID_WIDTH == 0) ? 1 : ID_WIDTH;

  parameter WDEPTH           = 1;
  parameter MAXRBURSTS       = 16;
  parameter MAXWBURSTS       = 16;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter USER_MAX_AW      = AWUSER_WIDTH_I - 1;
  parameter USER_MAX_AR      = ARUSER_WIDTH_I - 1;
  parameter USER_MAX_W       = WUSER_WIDTH_I - 1;
  parameter USER_MAX_B       = BUSER_WIDTH_I - 1;
  parameter USER_MAX_R       = RUSER_WIDTH_I - 1;
  parameter ID_MAX           = ID_WIDTH_I - 1;

  parameter WID_BITS         = ID_WIDTH_I;
  parameter RID_BITS         = ID_WIDTH_I;
  parameter AWUSER_BITS      = AWUSER_WIDTH_I + 16;
  parameter ARUSER_BITS      = ARUSER_WIDTH_I + 16;
  parameter WUSER_BITS       = WUSER_WIDTH_I;
  parameter BUSER_BITS       = BUSER_WIDTH_I;
  parameter RUSER_BITS       = RUSER_WIDTH_I;
  parameter ADDR_BITS        = ADDR_WIDTH;
  parameter DATA_BYTES       = DATA_WIDTH / 8;

//------------------------------------------------------------------------------
// Inputs
//------------------------------------------------------------------------------

  // Global signals
  input                ACLK;
  input                ARESETn;

  // Write Address channel
  input       [ID_MAX:0] AWID;
  input           [31:0] AWADDR;
  input            [3:0] AWLEN;
  input            [2:0] AWSIZE;
  input            [1:0] AWBURST;
  input            [3:0] AWCACHE;
  input            [2:0] AWPROT;
  input            [1:0] AWLOCK;
  input  [USER_MAX_AW:0] AWUSER;
  input                  AWVALID;
  input                  AWREADY;

  // Write data channel
  input       [ID_MAX:0] WID;   
  input     [DATA_MAX:0] WDATA; 
  input     [STRB_MAX:0] WSTRB; 
  input                  WLAST; 
  input   [USER_MAX_W:0] WUSER;
  input                  WVALID;
  input                  WREADY;

  // Write completion channel
  input       [ID_MAX:0] BID;
  input            [1:0] BRESP;
  input   [USER_MAX_B:0] BUSER;
  input                  BVALID;
  input                  BREADY;

  // Read Address channel
  input       [ID_MAX:0] ARID;   
  input           [31:0] ARADDR; 
  input            [3:0] ARLEN;  
  input            [2:0] ARSIZE; 
  input            [1:0] ARBURST;
  input            [3:0] ARCACHE;
  input            [2:0] ARPROT; 
  input            [1:0] ARLOCK; 
  input  [USER_MAX_AR:0] ARUSER;
  input                  ARVALID;
  input                  ARREADY;

  // Read data channel
  input       [ID_MAX:0] RID;
  input     [DATA_MAX:0] RDATA;
  input            [1:0] RRESP;
  input                  RLAST;
  input   [USER_MAX_R:0] RUSER;
  input                  RVALID;
  input                  RREADY;
//-----------------------------------------------------------------------------
// AVIP AXI signal interface related to the AVIP master
//-----------------------------------------------------------------------------

  defparam axi_master_signal_if.WID_BITS    = ID_WIDTH_I;
  defparam axi_master_signal_if.RID_BITS    = ID_WIDTH_I;
  defparam axi_master_signal_if.AWUSER_BITS = AWUSER_WIDTH_I;
  defparam axi_master_signal_if.ARUSER_BITS = ARUSER_WIDTH_I;
  defparam axi_master_signal_if.WUSER_BITS  = WUSER_WIDTH_I;
  defparam axi_master_signal_if.BUSER_BITS  = BUSER_WIDTH_I;
  defparam axi_master_signal_if.RUSER_BITS  = RUSER_WIDTH_I;
  defparam axi_master_signal_if.ADDR_BITS   = ADDR_WIDTH;
  defparam axi_master_signal_if.DATA_BYTES  = DATA_WIDTH / 8;

    avip_axi_signal_if axi_master_signal_if
                       (.ACLK           (ACLK),
                        .ACLKEN         (1'b1),
                        .ARESETn        (ARESETn)
                       );

//-----------------------------------------------------------------------------
// AVIP monitor signal interface
//-----------------------------------------------------------------------------
    // Write Address Channel 
    assign axi_master_signal_if.AWID    = AWID;
    assign axi_master_signal_if.AWADDR  = AWADDR;
    assign axi_master_signal_if.AWLEN   = AWLEN;
    assign axi_master_signal_if.AWSIZE  = AWSIZE;
    assign axi_master_signal_if.AWBURST = AWBURST;
    assign axi_master_signal_if.AWLOCK  = AWLOCK;
    assign axi_master_signal_if.AWCACHE = AWCACHE;
    assign axi_master_signal_if.AWPROT  = AWPROT;
    assign axi_master_signal_if.AWUSER  = AWUSER;
    assign axi_master_signal_if.AWVALID = AWVALID;
    assign axi_master_signal_if.AWREADY = AWREADY;
    // Write Channel 
    assign axi_master_signal_if.WID    = WID;
    assign axi_master_signal_if.WDATA  = WDATA;
    assign axi_master_signal_if.WSTRB  = WSTRB;
    assign axi_master_signal_if.WUSER  = WUSER;
    assign axi_master_signal_if.WLAST  = WLAST;
    assign axi_master_signal_if.WVALID = WVALID;
    assign axi_master_signal_if.WREADY = WREADY;
    // Write Response Channel 
    assign axi_master_signal_if.BID    = BID;
    assign axi_master_signal_if.BRESP  = BRESP;
    assign axi_master_signal_if.BUSER  = BUSER;
    assign axi_master_signal_if.BVALID = BVALID;
    assign axi_master_signal_if.BREADY = BREADY;
    // Read Address Channel 
    assign axi_master_signal_if.ARID    = ARID;
    assign axi_master_signal_if.ARADDR  = ARADDR;
    assign axi_master_signal_if.ARLEN   = ARLEN;
    assign axi_master_signal_if.ARSIZE  = ARSIZE;
    assign axi_master_signal_if.ARBURST = ARBURST;
    assign axi_master_signal_if.ARLOCK  = ARLOCK;
    assign axi_master_signal_if.ARCACHE = ARCACHE;
    assign axi_master_signal_if.ARPROT  = ARPROT;
    assign axi_master_signal_if.ARUSER  = ARUSER;
    assign axi_master_signal_if.ARVALID = ARVALID;
    assign axi_master_signal_if.ARREADY = ARREADY;
    // Read Channel 
    assign axi_master_signal_if.RID    = RID;
    assign axi_master_signal_if.RDATA  = RDATA;
    assign axi_master_signal_if.RRESP  = RRESP;
    assign axi_master_signal_if.RUSER  = RUSER;
    assign axi_master_signal_if.RLAST  = RLAST;
    assign axi_master_signal_if.RVALID = RVALID;
    assign axi_master_signal_if.RREADY = RREADY;

//-----------------------------------------------------------------------------
// AVIP monitor interface instance (connected to axi_master)
//-----------------------------------------------------------------------------

    avip_axi_monitor_if AVIPMon_master 
                        (.rtl_if(axi_master_signal_if));

    initial
    begin
        AVIPMon_master.create(INSTANCE_NAME, null, null, null);
        AVIPMon_master.set_param("Transaction Recording", "enable");
    end

endmodule

// --============================== End ==============================--
