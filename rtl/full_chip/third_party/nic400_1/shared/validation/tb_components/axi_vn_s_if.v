// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2010-2014 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 96879
//
// Date                   :  2010-10-08 12:12:59 +0100 (Fri, 08 Oct 2010)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC400 axi slave interface
//
// Description : This block is an external VN AXI slave that can be used in the
//               main NIC400 testbench.
//
//               Contains an eXVC AXIS or FRS component
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module axi_vn_s_if(

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
        
        // Write Address Channel
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
        
        
        //vnet sideband signals
        AWVNET,
        ARVNET,
        WVNET,
        
        // Virtual Network 0 Token Request
        // Write Address Token Request 
        VAWVALID_0,
        VAWREADY_0,
        VAWQOS_0,
        // Write Token Request 
        VWVALID_0,
        VWREADY_0,
        // Read Address Token Request 
        VARVALID_0,
        VARREADY_0,
        VARQOS_0,
        
        // Virtual Network 1 Token Request
        // Write Address Token Request 
        VAWVALID_1,
        VAWREADY_1,
        VAWQOS_1,
        // Write Token Request 
        VWVALID_1,
        VWREADY_1,
        // Read Address Token Request 
        VARVALID_1,
        VARREADY_1,
        VARQOS_1,
        
        // Virtual Network 2 Token Request
        // Write Address Token Request 
        VAWVALID_2,
        VAWREADY_2,
        VAWQOS_2,
        // Write Token Request 
        VWVALID_2,
        VWREADY_2,
        // Read Address Token Request 
        VARVALID_2,
        VARREADY_2,
        VARQOS_2,
        
        // Virtual Network 3 Token Request
        // Write Address Token Request 
        VAWVALID_3,
        VAWREADY_3,
        VAWQOS_3,
        // Write Token Request 
        VWVALID_3,
        VWREADY_3,
        // Read Address Token Request 
        VARVALID_3,
        VARREADY_3,
        VARQOS_3,
        
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

    // Vnet Values
    parameter VNETS                         = 2;
    parameter VNET_VALUE0                   = 0;
    parameter VNET_VALUE1                   = 1;
    parameter VNET_VALUE2                   = 2;
    parameter VNET_VALUE3                   = 3;

    parameter VNET_PREFETCH0    	    = 0;
    parameter VNET_PREFETCH1    	    = 0;
    parameter VNET_PREFETCH2    	    = 0;
    parameter VNET_PREFETCH3    	    = 0;

    parameter DATA_WIDTH                    = 32;
    parameter STRB_WIDTH                    = 4;
    parameter ADDR_WIDTH                    = 32;
    parameter AWUSER_WIDTH                  = 16;
    parameter ARUSER_WIDTH                  = 16;
    parameter RUSER_WIDTH                   = 16;
    parameter WUSER_WIDTH                   = 16;
    parameter BUSER_WIDTH                   = 16;
    parameter ID_WIDTH                      = 16;
    parameter EW_WIDTH                      = 8;
  
    parameter read_issuing_capability    = 16;
    parameter write_issuing_capability   = 16;
    parameter limit_acceptance_capability   = 0;
  
    //If limit_acceptance_capability is true then the FRM should limit the number of transactions
    //rather than letting the DMC do it.
    parameter AXIPC_READS                   = (limit_acceptance_capability == 1) ?
                                               read_issuing_capability + 10 : read_issuing_capability;
    parameter AXIPC_WRITES                  = (limit_acceptance_capability == 1) ?
                                               write_issuing_capability + 10 + 32: write_issuing_capability + 32;
  
    parameter INSTANCE                      = "undef";
    parameter INSTANCE_TYPE                 = "AXIS_";
  
    parameter AWUSER_WIDTH_I                = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
    parameter ARUSER_WIDTH_I                = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
    parameter WUSER_WIDTH_I                 = (WUSER_WIDTH == 0) ? 1 : WUSER_WIDTH;
    parameter RUSER_WIDTH_I                 = (RUSER_WIDTH == 0) ? 1 : RUSER_WIDTH;
    parameter BUSER_WIDTH_I                 = (BUSER_WIDTH == 0) ? 1 : BUSER_WIDTH;
    parameter ID_WIDTH_I                    = (ID_WIDTH == 0) ? 1 : ID_WIDTH;
  
    parameter DATA_MAX                      = DATA_WIDTH - 1;
    parameter STRB_MAX                      = STRB_WIDTH - 1;
    parameter ADDR_MAX                      = ADDR_WIDTH - 1;
    parameter ID_MAX                        = ID_WIDTH_I - 1;
    parameter EW_MAX                        = EW_WIDTH -1;
    parameter USER_MAX_AW                   = AWUSER_WIDTH_I - 1;
    parameter USER_MAX_AR                   = ARUSER_WIDTH_I - 1;
    parameter USER_MAX_R                    = RUSER_WIDTH_I - 1;
    parameter USER_MAX_W                    = WUSER_WIDTH_I - 1;
    parameter USER_MAX_B                    = BUSER_WIDTH_I - 1;
  
    parameter regions_flag                  = 0;
  
    parameter AllowLeadingRdata             = 0;
    parameter AllowIllegalCache             = 0;
  
    parameter DriveOnlyOnEnable             = 0;
    parameter PortIsInternal                = 0;
    parameter USE_X                         = 1;
  
  
// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

    // Clock and Reset in AXI domain
    input                   ACLK;            // AXI Bus Clock
    input                   ACLKEN;          // AXI Bus Clock Enable
    input                   ARESETn;         // AXI Reset
    
    // Read Address Channel
    input   [ID_MAX:0]      ARID;            // Read address ID
    input   [ADDR_MAX:0]    ARADDR;          // Read address
    input   [3:0]           ARLEN;           // Read burst length
    input   [3:0]           ARQV;            // Read QV value
    input   [3:0]           ARREGION;        // Read region signal
    
    input   [2:0]           ARSIZE;          // Read burst size
    input   [1:0]           ARBURST;         // Read burst type
    input                   ARVALID;         // Read address valid
    output                  ARREADY;         // Read address ready
    input   [3:0]           ARCACHE;         // Read cache information
    input   [1:0]           ARLOCK;          // Read lock information
    input   [2:0]           ARPROT;          // Read protection information
    input   [USER_MAX_AR:0] ARUSER;          // Read protection information
    
    // Read Channel
    output  [ID_MAX:0]      RID;             // Read data ID
    output                  RLAST;           // Read last
    output  [DATA_MAX:0]    RDATA;           // Read data
    output  [1:0]           RRESP;           // Read response
    output                  RVALID;          // Read response valid
    input                   RREADY;          // Read response ready
    output  [USER_MAX_R:0]  RUSER;          // Read protection information
    
    // Write Address Channel
    input   [ID_MAX:0]      AWID;            // Write address ID
    input   [ADDR_MAX:0]    AWADDR;          // Write address
    input   [3:0]           AWLEN;           // Write burst length
    input   [3:0]           AWQV;            // Write QV value
    input   [3:0]           AWREGION;        // Write region signal
    input   [2:0]           AWSIZE;          // Write burst size
    input   [1:0]           AWBURST;         // Write burst type
    input                   AWVALID;         // Write address valid
    output                  AWREADY;         // Write address ready
    input   [3:0]           AWCACHE;         // Write cache information
    input   [1:0]           AWLOCK;          // Write lock information
    input   [2:0]           AWPROT;          // Write protection information
    input   [USER_MAX_AW:0] AWUSER;          // Read protection information
    
    // Write Channel
    input   [ID_MAX:0]      WID;             // Wid
    input                   WLAST;           // Write last
    input   [STRB_MAX:0]    WSTRB;           // Write strobes
    input   [DATA_MAX:0]    WDATA;           // Write data
    input                   WVALID;          // Write valid
    output                  WREADY;          // Write ready
    input   [USER_MAX_W:0]  WUSER;          // Read protection information
    
    // Write Response Channel
    output  [ID_MAX:0]      BID;             // Write response ID
    output  [1:0]           BRESP;           // Write response
    output                  BVALID;          // Write response valid
    input                   BREADY;          // Write response ready
    output  [USER_MAX_B:0]  BUSER;          // Read protection information
    
    //vnet sideband signals
    input   [3:0]           AWVNET;
    input   [3:0]           ARVNET;
    input   [3:0]           WVNET;
    
    // Virtual Network 0 Token Request
    //--------------------------------
    // Write Address Token Request 
    input                   VAWVALID_0;
    output                  VAWREADY_0;
    input   [3:0]           VAWQOS_0;
    // Write Token Request 
    input                   VWVALID_0;
    output                  VWREADY_0;
    // Read Address Token Request 
    input                   VARVALID_0;
    output                  VARREADY_0;
    input   [3:0] VARQOS_0;
    
    // Virtual Network 1 Token Request
    //--------------------------------
    // Write Address Token Request 
    input                   VAWVALID_1;
    output                  VAWREADY_1;
    input   [3:0]           VAWQOS_1;
    // Write Token Request 
    input                   VWVALID_1;
    output                  VWREADY_1;
    // Read Address Token Request 
    input                   VARVALID_1;
    output                  VARREADY_1;
    input   [3:0]           VARQOS_1;
    
    // Virtual Network 2 Token Request
    //--------------------------------
    // Write Address Token Request 
    input                   VAWVALID_2;
    output                  VAWREADY_2;
    input   [3:0]           VAWQOS_2;
    // Write Token Request 
    input                   VWVALID_2;
    output                  VWREADY_2;
    // Read Address Token Request 
    input                   VARVALID_2;
    output                  VARREADY_2;
    input   [3:0]           VARQOS_2;
    
    // Virtual Network 3 Token Request
    //--------------------------------
    // Write Address Token Request 
    input                   VAWVALID_3;
    output                  VAWREADY_3;
    input   [3:0]           VAWQOS_3;
    // Write Token Request 
    input                   VWVALID_3;
    output                  VWREADY_3;
    // Read Address Token Request 
    input                   VARVALID_3;
    output                  VARREADY_3;
    input   [3:0]           VARQOS_3;
    
    //Emit and Wait channels only used in FRM mode
    output  [EW_MAX:0]      EMIT_DATA;       //Emit data
    output                  EMIT_REQ;        //Emit Request
    input                   EMIT_ACK;        //Emit acknoledgement
    
    input   [EW_MAX:0]      WAIT_DATA;       //Wait data
    input                   WAIT_REQ;        //Wait Request
    output                  WAIT_ACK;        //Waitr acknoledgement
    
    // APB3 Interface
    input                   PENABLE;         // APB Enable
    input                   PWRITE;          // APB transfer(R/W) direction
    input   [31:0]          PADDR;           // APB address
    input   [31:0]          PWDATA;          // APB write data
    output                  PREADY;          // APB transfer completion signal for slaves
    output                  PSLVERR;         // APB transfer response signal for slaves
    output  [31:0]          PRDATA;          // APB read data for slave0
    input                   PSEL;
    
    input                   PCLK;
    input                   PRESETn;
    
// -----------------------------------------------------------------------------
//  Wire and Register Declarations
// -----------------------------------------------------------------------------

    wire    [3:0]           AWREGION_int;
    wire    [3:0]           ARREGION_int;
    wire [USER_MAX_AW+16:0] AWUSER_int;
    wire [USER_MAX_AR+16:0] ARUSER_int;

    wire    [ID_MAX:0]      RID_i;             // Read data ID
    wire                    RLAST_i;           // Read last
    wire    [DATA_MAX:0]    RDATA_i;           // Read data
    wire    [1:0]           RRESP_i;           // Read response
    wire    [USER_MAX_R:0]  RUSER_i;           // Read user field
    
    wire    [ID_MAX:0]      BID_i;             // Write response ID
    wire    [1:0]           BRESP_i;           // Write response
    wire    [USER_MAX_B:0]  BUSER_i;           // Write response user field
    
//------------------------------------------------------------------------------
// Output Wires
//------------------------------------------------------------------------------

    assign RID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : RID_i;
    assign RLAST = (DriveOnlyOnEnable & ~ACLKEN) ? 1'bx : RLAST_i;
    assign RDATA = (DriveOnlyOnEnable & ~ACLKEN) ? {DATA_WIDTH{1'bx}} : RDATA_i;
    assign RRESP = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : RRESP_i;
    assign RUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((RUSER_WIDTH_I == 1) ? 1'bx : {RUSER_WIDTH_I{1'bx}}) : RUSER_i;
  
    assign BID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : BID_i;
    assign BRESP = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : BRESP_i;
    assign BUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((BUSER_WIDTH_I == 1) ? 1'bx : {BUSER_WIDTH_I{1'bx}}) : BUSER_i;

//------------------------------------------------------------------------------
// Encoding AxUSER
//------------------------------------------------------------------------------
    assign AWREGION_int     = (regions_flag == 0) ? 4'b0000 : AWREGION;
    assign ARREGION_int     = (regions_flag == 0) ? 4'b0000 : ARREGION;
  
    assign AWUSER_int       = {AWUSER, 8'b0, AWQV, AWREGION_int};
    assign ARUSER_int       = {ARUSER, 8'b0, ARQV, ARREGION_int};


`ifdef SN
//------------------------------------------------------------------------------
// XVC Slave - used with random tests
//------------------------------------------------------------------------------
  defparam uAxiVnSlave.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiVnSlave.ID_WIDTH       = ID_WIDTH_I;

  defparam uAxiVnSlave.AWUSER_WIDTH   = AWUSER_WIDTH_I;
  defparam uAxiVnSlave.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiVnSlave.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiVnSlave.ARUSER_WIDTH   = ARUSER_WIDTH_I;
  defparam uAxiVnSlave.RUSER_WIDTH    = RUSER_WIDTH_I;
  defparam uAxiVnSlave.ADDR_WIDTH     = ADDR_WIDTH;             

  defparam uAxiVnSlave.NUM_VNETS   = VNETS;
  defparam uAxiVnSlave.VN0_VNET    = VNET_VALUE0;
  defparam uAxiVnSlave.VN1_VNET    = VNET_VALUE1;
  defparam uAxiVnSlave.VN2_VNET    = VNET_VALUE2;
  defparam uAxiVnSlave.VN3_VNET    = VNET_VALUE3;

  Axi3VnSlaveXvc uAxiVnSlave (
      .ACLK         (ACLK),
      .ARESETn      (ARESETn),

      .AWVALID      (AWVALID),
      .AWREADY      (AWREADY),
      .AWID         (AWID),
      .AWADDR       (AWADDR),
      .AWLEN        (AWLEN),
      .AWSIZE       (AWSIZE),
      .AWBURST      (AWBURST),
      .AWLOCK       (AWLOCK),
      .AWCACHE      (AWCACHE),
      .AWPROT       (AWPROT),
      .AWREGION     (AWREGION),
      .AWQV         (AWQV),
      .AWVNET       (AWVNET),
      .AWVALID_VECT (1'b0),

      .WID          (WID),
      .WDATA        (WDATA),
      .WSTRB        (WSTRB),
      .WLAST        (WLAST),
      .WVALID       (WVALID),
      .WREADY       (WREADY),
      .WVNET        (WVNET),

      .BID          (BID_i),
      .BRESP        (BRESP_i),
      .BVALID       (BVALID),
      .BREADY       (BREADY),

      .ARVALID      (ARVALID),
      .ARREADY      (ARREADY),
      .ARID         (ARID),
      .ARADDR       (ARADDR),
      .ARLEN        (ARLEN),
      .ARSIZE       (ARSIZE),
      .ARBURST      (ARBURST),
      .ARLOCK       (ARLOCK),
      .ARCACHE      (ARCACHE),
      .ARPROT       (ARPROT),
      .ARREGION     (ARREGION),
      .ARQV         (ARQV),
      .ARVNET       (ARVNET),
      .ARVALID_VECT (1'b0),

      .WUSER        (WUSER),
      .AWUSER       (AWUSER),
      .BUSER        (BUSER_i),
      .ARUSER       (ARUSER),
      .RUSER        (RUSER_i),

      .RVALID       (RVALID),
      .RREADY       (RREADY),
      .RID          (RID_i),
      .RDATA        (RDATA_i),
      .RRESP        (RRESP_i),
      .RLAST        (RLAST_i),

      // Virtual Network 0
      .vawvalid_vn0_s0    (VAWVALID_0),
      .vawready_vn0_s0    (VAWREADY_0),
      .vawqv_vn0_s0       (VAWQOS_0),
      .vwvalid_vn0_s0     (VWVALID_0),
      .vwready_vn0_s0     (VWREADY_0),
      .varvalid_vn0_s0    (VARVALID_0),
      .varready_vn0_s0    (VARREADY_0),
      .varqv_vn0_s0       (VARQOS_0),
  
      .vawvalid_vn0_s1    (1'b0),
      .vawready_vn0_s1    (),
      .vawqv_vn0_s1       (4'b0000),
      .vwvalid_vn0_s1     (1'b0),
      .vwready_vn0_s1     (),
      .varvalid_vn0_s1    (1'b0),
      .varready_vn0_s1    (),
      .varqv_vn0_s1       (4'b0000),
  
      .vawvalid_vn0_s2    (1'b0),
      .vawready_vn0_s2    (),
      .vawqv_vn0_s2       (4'b0000),
      .vwvalid_vn0_s2     (1'b0),
      .vwready_vn0_s2     (),
      .varvalid_vn0_s2    (1'b0),
      .varready_vn0_s2    (),
      .varqv_vn0_s2       (4'b0000),
  
      .vawvalid_vn0_s3    (1'b0),
      .vawready_vn0_s3    (),
      .vawqv_vn0_s3       (4'b0000),
      .vwvalid_vn0_s3     (1'b0),
      .vwready_vn0_s3     (),
      .varvalid_vn0_s3    (1'b0),
      .varready_vn0_s3    (),
      .varqv_vn0_s3       (4'b0000),
  
      .vawvalid_vn0_s4    (1'b0),
      .vawready_vn0_s4    (),
      .vawqv_vn0_s4       (4'b0000),
      .vwvalid_vn0_s4     (1'b0),
      .vwready_vn0_s4     (),
      .varvalid_vn0_s4    (1'b0),
      .varready_vn0_s4    (),
      .varqv_vn0_s4       (4'b0000),
  
      .vawvalid_vn0_s5    (1'b0),
      .vawready_vn0_s5    (),
      .vawqv_vn0_s5       (4'b0000),
      .vwvalid_vn0_s5     (1'b0),
      .vwready_vn0_s5     (),
      .varvalid_vn0_s5    (1'b0),
      .varready_vn0_s5    (),
      .varqv_vn0_s5       (4'b0000),
  
      .vawvalid_vn0_s6    (1'b0),
      .vawready_vn0_s6    (),
      .vawqv_vn0_s6       (4'b0000),
      .vwvalid_vn0_s6     (1'b0),
      .vwready_vn0_s6     (),
      .varvalid_vn0_s6    (1'b0),
      .varready_vn0_s6    (),
      .varqv_vn0_s6       (4'b0000),
  
      .vawvalid_vn0_s7    (1'b0),
      .vawready_vn0_s7    (),
      .vawqv_vn0_s7       (4'b0000),
      .vwvalid_vn0_s7     (1'b0),
      .vwready_vn0_s7     (),
      .varvalid_vn0_s7    (1'b0),
      .varready_vn0_s7    (),
      .varqv_vn0_s7       (4'b0000),
  
      .vawvalid_vn0_s8    (1'b0),
      .vawready_vn0_s8    (),
      .vawqv_vn0_s8       (4'b0000),
      .vwvalid_vn0_s8     (1'b0),
      .vwready_vn0_s8     (),
      .varvalid_vn0_s8    (1'b0),
      .varready_vn0_s8    (),
      .varqv_vn0_s8       (4'b0000),
  
      .vawvalid_vn0_s9    (1'b0),
      .vawready_vn0_s9    (),
      .vawqv_vn0_s9       (4'b0000),
      .vwvalid_vn0_s9     (1'b0),
      .vwready_vn0_s9     (),
      .varvalid_vn0_s9    (1'b0),
      .varready_vn0_s9    (),
      .varqv_vn0_s9       (4'b0000),
  
      .vawvalid_vn0_s10   (1'b0),
      .vawready_vn0_s10   (),
      .vawqv_vn0_s10      (4'b0000),
      .vwvalid_vn0_s10    (1'b0),
      .vwready_vn0_s10    (),
      .varvalid_vn0_s10   (1'b0),
      .varready_vn0_s10   (),
      .varqv_vn0_s10      (4'b0000),
  
      .vawvalid_vn0_s11   (1'b0),
      .vawready_vn0_s11   (),
      .vawqv_vn0_s11      (4'b0000),
      .vwvalid_vn0_s11    (1'b0),
      .vwready_vn0_s11    (),
      .varvalid_vn0_s11   (1'b0),
      .varready_vn0_s11   (),
      .varqv_vn0_s11      (4'b0000),

      // Virtual Network 1
      .vawvalid_vn1_s0    (VAWVALID_1),
      .vawready_vn1_s0    (VAWREADY_1),
      .vawqv_vn1_s0       (VAWQOS_1),
      .vwvalid_vn1_s0     (VWVALID_1),
      .vwready_vn1_s0     (VWREADY_1),
      .varvalid_vn1_s0    (VARVALID_1),
      .varready_vn1_s0    (VARREADY_1),
      .varqv_vn1_s0       (VARQOS_1),
  
      .vawvalid_vn1_s1    (1'b0),
      .vawready_vn1_s1    (),
      .vawqv_vn1_s1       (4'b0000),
      .vwvalid_vn1_s1     (1'b0),
      .vwready_vn1_s1     (),
      .varvalid_vn1_s1    (1'b0),
      .varready_vn1_s1    (),
      .varqv_vn1_s1       (4'b0000),
  
      .vawvalid_vn1_s2    (1'b0),
      .vawready_vn1_s2    (),
      .vawqv_vn1_s2       (4'b0000),
      .vwvalid_vn1_s2     (1'b0),
      .vwready_vn1_s2     (),
      .varvalid_vn1_s2    (1'b0),
      .varready_vn1_s2    (),
      .varqv_vn1_s2       (4'b0000),
  
      .vawvalid_vn1_s3    (1'b0),
      .vawready_vn1_s3    (),
      .vawqv_vn1_s3       (4'b0000),
      .vwvalid_vn1_s3     (1'b0),
      .vwready_vn1_s3     (),
      .varvalid_vn1_s3    (1'b0),
      .varready_vn1_s3    (),
      .varqv_vn1_s3       (4'b0000),
  
      .vawvalid_vn1_s4    (1'b0),
      .vawready_vn1_s4    (),
      .vawqv_vn1_s4       (4'b0000),
      .vwvalid_vn1_s4     (1'b0),
      .vwready_vn1_s4     (),
      .varvalid_vn1_s4    (1'b0),
      .varready_vn1_s4    (),
      .varqv_vn1_s4       (4'b0000),
  
      .vawvalid_vn1_s5    (1'b0),
      .vawready_vn1_s5    (),
      .vawqv_vn1_s5       (4'b0000),
      .vwvalid_vn1_s5     (1'b0),
      .vwready_vn1_s5     (),
      .varvalid_vn1_s5    (1'b0),
      .varready_vn1_s5    (),
      .varqv_vn1_s5       (4'b0000),
  
      .vawvalid_vn1_s6    (1'b0),
      .vawready_vn1_s6    (),
      .vawqv_vn1_s6       (4'b0000),
      .vwvalid_vn1_s6     (1'b0),
      .vwready_vn1_s6     (),
      .varvalid_vn1_s6    (1'b0),
      .varready_vn1_s6    (),
      .varqv_vn1_s6       (4'b0000),
  
      .vawvalid_vn1_s7    (1'b0),
      .vawready_vn1_s7    (),
      .vawqv_vn1_s7       (4'b0000),
      .vwvalid_vn1_s7     (1'b0),
      .vwready_vn1_s7     (),
      .varvalid_vn1_s7    (1'b0),
      .varready_vn1_s7    (),
      .varqv_vn1_s7       (4'b0000),
  
      .vawvalid_vn1_s8    (1'b0),
      .vawready_vn1_s8    (),
      .vawqv_vn1_s8       (4'b0000),
      .vwvalid_vn1_s8     (1'b0),
      .vwready_vn1_s8     (),
      .varvalid_vn1_s8    (1'b0),
      .varready_vn1_s8    (),
      .varqv_vn1_s8       (4'b0000),
  
      .vawvalid_vn1_s9    (1'b0),
      .vawready_vn1_s9    (),
      .vawqv_vn1_s9       (4'b0000),
      .vwvalid_vn1_s9     (1'b0),
      .vwready_vn1_s9     (),
      .varvalid_vn1_s9    (1'b0),
      .varready_vn1_s9    (),
      .varqv_vn1_s9       (4'b0000),
  
      .vawvalid_vn1_s10   (1'b0),
      .vawready_vn1_s10   (),
      .vawqv_vn1_s10      (4'b0000),
      .vwvalid_vn1_s10    (1'b0),
      .vwready_vn1_s10    (),
      .varvalid_vn1_s10   (1'b0),
      .varready_vn1_s10   (),
      .varqv_vn1_s10      (4'b0000),
  
      .vawvalid_vn1_s11   (1'b0),
      .vawready_vn1_s11   (),
      .vawqv_vn1_s11      (4'b0000),
      .vwvalid_vn1_s11    (1'b0),
      .vwready_vn1_s11    (),
      .varvalid_vn1_s11   (1'b0),
      .varready_vn1_s11   (),
      .varqv_vn1_s11      (4'b0000),
 
      // Virtual Network 2
      .vawvalid_vn2_s0    (VAWVALID_2),
      .vawready_vn2_s0    (VAWREADY_2),
      .vawqv_vn2_s0       (VAWQOS_2),
      .vwvalid_vn2_s0     (VWVALID_2),
      .vwready_vn2_s0     (VWREADY_2),
      .varvalid_vn2_s0    (VARVALID_2),
      .varready_vn2_s0    (VARREADY_2),
      .varqv_vn2_s0       (VARQOS_2),
  
      .vawvalid_vn2_s1    (1'b0),
      .vawready_vn2_s1    (),
      .vawqv_vn2_s1       (4'b0000),
      .vwvalid_vn2_s1     (1'b0),
      .vwready_vn2_s1     (),
      .varvalid_vn2_s1    (1'b0),
      .varready_vn2_s1    (),
      .varqv_vn2_s1       (4'b0000),
  
      .vawvalid_vn2_s2    (1'b0),
      .vawready_vn2_s2    (),
      .vawqv_vn2_s2       (4'b0000),
      .vwvalid_vn2_s2     (1'b0),
      .vwready_vn2_s2     (),
      .varvalid_vn2_s2    (1'b0),
      .varready_vn2_s2    (),
      .varqv_vn2_s2       (4'b0000),
  
      .vawvalid_vn2_s3    (1'b0),
      .vawready_vn2_s3    (),
      .vawqv_vn2_s3       (4'b0000),
      .vwvalid_vn2_s3     (1'b0),
      .vwready_vn2_s3     (),
      .varvalid_vn2_s3    (1'b0),
      .varready_vn2_s3    (),
      .varqv_vn2_s3       (4'b0000),
  
      .vawvalid_vn2_s4    (1'b0),
      .vawready_vn2_s4    (),
      .vawqv_vn2_s4       (4'b0000),
      .vwvalid_vn2_s4     (1'b0),
      .vwready_vn2_s4     (),
      .varvalid_vn2_s4    (1'b0),
      .varready_vn2_s4    (),
      .varqv_vn2_s4       (4'b0000),
  
      .vawvalid_vn2_s5    (1'b0),
      .vawready_vn2_s5    (),
      .vawqv_vn2_s5       (4'b0000),
      .vwvalid_vn2_s5     (1'b0),
      .vwready_vn2_s5     (),
      .varvalid_vn2_s5    (1'b0),
      .varready_vn2_s5    (),
      .varqv_vn2_s5       (4'b0000),
  
      .vawvalid_vn2_s6    (1'b0),
      .vawready_vn2_s6    (),
      .vawqv_vn2_s6       (4'b0000),
      .vwvalid_vn2_s6     (1'b0),
      .vwready_vn2_s6     (),
      .varvalid_vn2_s6    (1'b0),
      .varready_vn2_s6    (),
      .varqv_vn2_s6       (4'b0000),
  
      .vawvalid_vn2_s7    (1'b0),
      .vawready_vn2_s7    (),
      .vawqv_vn2_s7       (4'b0000),
      .vwvalid_vn2_s7     (1'b0),
      .vwready_vn2_s7     (),
      .varvalid_vn2_s7    (1'b0),
      .varready_vn2_s7    (),
      .varqv_vn2_s7       (4'b0000),
  
      .vawvalid_vn2_s8    (1'b0),
      .vawready_vn2_s8    (),
      .vawqv_vn2_s8       (4'b0000),
      .vwvalid_vn2_s8     (1'b0),
      .vwready_vn2_s8     (),
      .varvalid_vn2_s8    (1'b0),
      .varready_vn2_s8    (),
      .varqv_vn2_s8       (4'b0000),
  
      .vawvalid_vn2_s9    (1'b0),
      .vawready_vn2_s9    (),
      .vawqv_vn2_s9       (4'b0000),
      .vwvalid_vn2_s9     (1'b0),
      .vwready_vn2_s9     (),
      .varvalid_vn2_s9    (1'b0),
      .varready_vn2_s9    (),
      .varqv_vn2_s9       (4'b0000),
  
      .vawvalid_vn2_s10   (1'b0),
      .vawready_vn2_s10   (),
      .vawqv_vn2_s10      (4'b0000),
      .vwvalid_vn2_s10    (1'b0),
      .vwready_vn2_s10    (),
      .varvalid_vn2_s10   (1'b0),
      .varready_vn2_s10   (),
      .varqv_vn2_s10      (4'b0000),
  
      .vawvalid_vn2_s11   (1'b0),
      .vawready_vn2_s11   (),
      .vawqv_vn2_s11      (4'b0000),
      .vwvalid_vn2_s11    (1'b0),
      .vwready_vn2_s11    (),
      .varvalid_vn2_s11   (1'b0),
      .varready_vn2_s11   (),
      .varqv_vn2_s11      (4'b0000),
 
      // Virtual Network 3
      .vawvalid_vn3_s0    (VAWVALID_3),
      .vawready_vn3_s0    (VAWREADY_3),
      .vawqv_vn3_s0       (VAWQOS_3),
      .vwvalid_vn3_s0     (VWVALID_3),
      .vwready_vn3_s0     (VWREADY_3),
      .varvalid_vn3_s0    (VARVALID_3),
      .varready_vn3_s0    (VARREADY_3),
      .varqv_vn3_s0       (VARQOS_3),
  
      .vawvalid_vn3_s1    (1'b0),
      .vawready_vn3_s1    (),
      .vawqv_vn3_s1       (4'b0000),
      .vwvalid_vn3_s1     (1'b0),
      .vwready_vn3_s1     (),
      .varvalid_vn3_s1    (1'b0),
      .varready_vn3_s1    (),
      .varqv_vn3_s1       (4'b0000),
  
      .vawvalid_vn3_s2    (1'b0),
      .vawready_vn3_s2    (),
      .vawqv_vn3_s2       (4'b0000),
      .vwvalid_vn3_s2     (1'b0),
      .vwready_vn3_s2     (),
      .varvalid_vn3_s2    (1'b0),
      .varready_vn3_s2    (),
      .varqv_vn3_s2       (4'b0000),
  
      .vawvalid_vn3_s3    (1'b0),
      .vawready_vn3_s3    (),
      .vawqv_vn3_s3       (4'b0000),
      .vwvalid_vn3_s3     (1'b0),
      .vwready_vn3_s3     (),
      .varvalid_vn3_s3    (1'b0),
      .varready_vn3_s3    (),
      .varqv_vn3_s3       (4'b0000),
  
      .vawvalid_vn3_s4    (1'b0),
      .vawready_vn3_s4    (),
      .vawqv_vn3_s4       (4'b0000),
      .vwvalid_vn3_s4     (1'b0),
      .vwready_vn3_s4     (),
      .varvalid_vn3_s4    (1'b0),
      .varready_vn3_s4    (),
      .varqv_vn3_s4       (4'b0000),
  
      .vawvalid_vn3_s5    (1'b0),
      .vawready_vn3_s5    (),
      .vawqv_vn3_s5       (4'b0000),
      .vwvalid_vn3_s5     (1'b0),
      .vwready_vn3_s5     (),
      .varvalid_vn3_s5    (1'b0),
      .varready_vn3_s5    (),
      .varqv_vn3_s5       (4'b0000),
  
      .vawvalid_vn3_s6    (1'b0),
      .vawready_vn3_s6    (),
      .vawqv_vn3_s6       (4'b0000),
      .vwvalid_vn3_s6     (1'b0),
      .vwready_vn3_s6     (),
      .varvalid_vn3_s6    (1'b0),
      .varready_vn3_s6    (),
      .varqv_vn3_s6       (4'b0000),
  
      .vawvalid_vn3_s7    (1'b0),
      .vawready_vn3_s7    (),
      .vawqv_vn3_s7       (4'b0000),
      .vwvalid_vn3_s7     (1'b0),
      .vwready_vn3_s7     (),
      .varvalid_vn3_s7    (1'b0),
      .varready_vn3_s7    (),
      .varqv_vn3_s7       (4'b0000),
  
      .vawvalid_vn3_s8    (1'b0),
      .vawready_vn3_s8    (),
      .vawqv_vn3_s8       (4'b0000),
      .vwvalid_vn3_s8     (1'b0),
      .vwready_vn3_s8     (),
      .varvalid_vn3_s8    (1'b0),
      .varready_vn3_s8    (),
      .varqv_vn3_s8       (4'b0000),
  
      .vawvalid_vn3_s9    (1'b0),
      .vawready_vn3_s9    (),
      .vawqv_vn3_s9       (4'b0000),
      .vwvalid_vn3_s9     (1'b0),
      .vwready_vn3_s9     (),
      .varvalid_vn3_s9    (1'b0),
      .varready_vn3_s9    (),
      .varqv_vn3_s9       (4'b0000),
  
      .vawvalid_vn3_s10   (1'b0),
      .vawready_vn3_s10   (),
      .vawqv_vn3_s10      (4'b0000),
      .vwvalid_vn3_s10    (1'b0),
      .vwready_vn3_s10    (),
      .varvalid_vn3_s10   (1'b0),
      .varready_vn3_s10   (),
      .varqv_vn3_s10      (4'b0000),
  
      .vawvalid_vn3_s11   (1'b0),
      .vawready_vn3_s11   (),
      .vawqv_vn3_s11      (4'b0000),
      .vwvalid_vn3_s11    (1'b0),
      .vwready_vn3_s11    (),
      .varvalid_vn3_s11   (1'b0),
      .varready_vn3_s11   (),
      .varqv_vn3_s11      (4'b0000)

  );

  // When using specman tie-off the unused Event buses
  assign  EMIT_REQ   = 1'b0;
  assign  EMIT_DATA  = {EW_WIDTH{1'b0}};
  assign  WAIT_ACK   = 1'b0;

`else

//------------------------------------------------------------------------------
// FRM Slave - used with directed tests
//------------------------------------------------------------------------------
    defparam uAxiSlave.DATA_WIDTH     = DATA_WIDTH;
    defparam uAxiSlave.ID_WIDTH       = ID_WIDTH_I;
  
    defparam uAxiSlave.AWUSER_WIDTH   = AWUSER_WIDTH_I + 16;
    defparam uAxiSlave.WUSER_WIDTH    = WUSER_WIDTH_I;
    defparam uAxiSlave.BUSER_WIDTH    = BUSER_WIDTH_I;
    defparam uAxiSlave.ARUSER_WIDTH   = ARUSER_WIDTH_I + 16;
    defparam uAxiSlave.RUSER_WIDTH    = RUSER_WIDTH_I;
    defparam uAxiSlave.ADDR_WIDTH     = ADDR_WIDTH;             
  
    defparam uAxiSlave.AW_ARRAY_SIZE     = 10000;             // Size of AW channel array
    defparam uAxiSlave.W_ARRAY_SIZE      = 50000;             // Size of W channel array
    defparam uAxiSlave.AR_ARRAY_SIZE     = 10000;             // Size of AR channel array
    defparam uAxiSlave.R_ARRAY_SIZE      = 50000;             // Size of R channel array
    defparam uAxiSlave.AWMSG_ARRAY_SIZE  = 10000;             // Size of AW comments array
    defparam uAxiSlave.ARMSG_ARRAY_SIZE  = 10000;             // Size of AR comments array
    defparam uAxiSlave.REQUIRE_AW_HNDSHK = 0;                 // Don't wait for AW handshake
  
    //The + 5 on these parameters prevents the test component from ever limiting the DUT
    defparam uAxiSlave.OUTSTANDING_WRITES = write_issuing_capability + 5;
    defparam uAxiSlave.OUTSTANDING_READS  = read_issuing_capability + 5;
  
    defparam uAxiSlave.STIM_FILE_NAME    = {INSTANCE_TYPE, INSTANCE};          //Name of the stimulus file
  
    defparam uAxiSlave.MESSAGE_TAG     = {"slave_", INSTANCE};       // Message prefix
    defparam uAxiSlave.VERBOSE         = 1;                  // Verbosity control
    defparam uAxiSlave.USE_X           = USE_X;                  // Drive X on invalid signals
    defparam uAxiSlave.EW_WIDTH        = EW_WIDTH;                  // Width of the Emit & wait bus
    defparam uAxiSlave.REQUIRE_AR_HNDSHK = (AllowLeadingRdata == 0);  // Width of the Emit & wait bus
  
    FileRdSlaveAxi uAxiSlave (
        .ACLK         (ACLK),
        .ARESETn      (ARESETn),
  
        .AWVALID      (AWVALID),
        .AWREADY      (AWREADY),
        .AWID         (AWID),
        .AWADDR       (AWADDR),
        .AWLEN        (AWLEN),
        .AWSIZE       (AWSIZE),
        .AWBURST      (AWBURST),
        .AWLOCK       (AWLOCK),
        .AWCACHE      (AWCACHE),
        .AWPROT       (AWPROT),
  
        .WID          (WID),
        .WDATA        (WDATA),
        .WSTRB        (WSTRB),
        .WLAST        (WLAST),
        .WVALID       (WVALID),
        .WREADY       (WREADY),
  
        .BID          (BID_i),
        .BRESP        (BRESP_i),
        .BVALID       (BVALID),
        .BREADY       (BREADY),
  
        .ARVALID      (ARVALID),
        .ARREADY      (ARREADY),
        .ARID         (ARID),
        .ARADDR       (ARADDR),
        .ARLEN        (ARLEN),
        .ARSIZE       (ARSIZE),
        .ARBURST      (ARBURST),
        .ARLOCK       (ARLOCK),
        .ARCACHE      (ARCACHE),
        .ARPROT       (ARPROT),
  
        .EMIT_DATA    (EMIT_DATA),
        .EMIT_REQ     (EMIT_REQ),
        .EMIT_ACK     (EMIT_ACK),
  
        .WAIT_DATA    (WAIT_DATA),
        .WAIT_REQ     (WAIT_REQ),
        .WAIT_ACK     (WAIT_ACK),
  
        .WUSER        (WUSER),
        .AWUSER       (AWUSER_int),
        .BUSER        (BUSER_i),
        .ARUSER       (ARUSER_int),
        .RUSER        (RUSER_i),
  
        .RVALID       (RVALID),
        .RREADY       (RREADY),
        .RID          (RID_i),
        .RDATA        (RDATA_i),
        .RRESP        (RRESP_i),
        .RLAST        (RLAST_i)
    );

    //The FRS does not really deal with tokens ....
    //Simply tie the ready signals to zero is sufficient for simple test cases
    //VNETS can be ignored as the FRS finds the next beat according to ID.
    //and IDS must not be on multiple VNETS at the same time.

    assign VAWREADY_0 = 1'b1;
    assign VAWREADY_1 = 1'b1;
    assign VAWREADY_2 = 1'b1;
    assign VAWREADY_3 = 1'b1;

    assign VARREADY_0 = 1'b1;
    assign VARREADY_1 = 1'b1;
    assign VARREADY_2 = 1'b1;
    assign VARREADY_3 = 1'b1;

    assign VWREADY_0  = 1'b1;
    assign VWREADY_1  = 1'b1;
    assign VWREADY_2  = 1'b1;
    assign VWREADY_3  = 1'b1;

`endif

//------------------------------------------------------------------------------
// AXI Slave APB Checker
//------------------------------------------------------------------------------
    defparam uAxiSlaveAPB.DATA_WIDTH = DATA_WIDTH;
    defparam uAxiSlaveAPB.ID_WIDTH   = ID_WIDTH_I;
    defparam uAxiSlaveAPB.EW_WIDTH   = EW_WIDTH;
    defparam uAxiSlaveAPB.AWUSER_WIDTH = AWUSER_WIDTH_I;
    defparam uAxiSlaveAPB.WUSER_WIDTH  = WUSER_WIDTH_I;
    defparam uAxiSlaveAPB.BUSER_WIDTH  = BUSER_WIDTH_I;
    defparam uAxiSlaveAPB.ARUSER_WIDTH = ARUSER_WIDTH_I;
    defparam uAxiSlaveAPB.RUSER_WIDTH  = RUSER_WIDTH_I;
    //Do not required AW handshake for VN aware Axi3
    defparam uAxiSlaveAPB.REQUIRE_AW_HNDSHK = 0;
  
    AxiSlaveAPB uAxiSlaveAPB (

        .ACLK           (ACLK),
        .ARESETn        (ARESETn),
   
        .AWVALID_VECT   (1'b0),
        .AWID           (AWID),
        .AWADDR         (AWADDR[31:0]),
        .AWLEN          (AWLEN),
        .AWSIZE         (AWSIZE),
        .AWBURST        (AWBURST),
        .AWLOCK         (AWLOCK),
        .AWCACHE        (AWCACHE),
        .AWPROT         (AWPROT),
        .AWUSER         (AWUSER),
        .AWVALID        (AWVALID),
        .AWREADY        (AWREADY),
        .AWREGION       (AWREGION),
        .AWQV           (AWQV),


        .WID            (WID),
        .WLAST          (WLAST),
        .WDATA          (WDATA),
        .WSTRB          (WSTRB),
        .WUSER          (WUSER),
        .WVALID         (WVALID),
        .WREADY         (WREADY),
  
        .BID            (BID_i),
        .BRESP          (BRESP_i),
        .BUSER          (BUSER_i),
        .BVALID         (BVALID),
        .BREADY         (BREADY),
    
        .ARVALID_VECT   (1'b0),
        .ARID           (ARID),
        .ARADDR         (ARADDR[31:0]),
        .ARLEN          (ARLEN),
        .ARSIZE         (ARSIZE),
        .ARBURST        (ARBURST),
        .ARLOCK         (ARLOCK),
        .ARCACHE        (ARCACHE),
        .ARPROT         (ARPROT),
        .ARUSER         (ARUSER),
        .ARVALID        (ARVALID),
        .ARREADY        (ARREADY),
        .ARREGION       (ARREGION),
        .ARQV           (ARQV),

        .RID            (RID_i),
        .RLAST          (RLAST_i),
        .RDATA          (RDATA_i),
        .RRESP          (RRESP_i),
        .RUSER          (RUSER_i),
        .RVALID         (RVALID),
        .RREADY         (RREADY),
  
        .pclk           (PCLK),
        .presetn        (PRESETn),
        .PRDATA         (PRDATA),
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
// OVLs
//------------------------------------------------------------------------------
    reg     [4:0]           VALID_prev;
    reg     [4:0]           READY_prev;
    
    wire    [6:0]           next_out_reads;
    wire    [6:0]           next_out_writes;
    reg     [6:0]           out_reads;
    reg     [6:0]           out_writes;
    reg                     error_v;
    reg                     error_r;
    reg                     PCLK_pulse;
    reg                     ACLK_pulse;
    
    wire                    ACLKENDEL;         // Delayed clock enable
    wire                    ACLKPC;            // Clock for protocol checker
    
//------------------------------------------------------------------------------
// Transaction Counters
//------------------------------------------------------------------------------
  //AR Channel

  assign next_out_reads = (ARVALID & ARREADY & ~(RLAST_i & RVALID & RREADY)) ? out_reads + 7'b1 :
                          (RLAST_i & RVALID & RREADY & ~(ARVALID & ARREADY)) ? out_reads - 7'b1 : out_reads;

  //AW Channel
  assign next_out_writes = (AWVALID & AWREADY & ~(BVALID & BREADY)) ? out_writes + 7'b1 :
                           (BVALID & BREADY & ~(AWVALID & AWREADY)) ? out_writes - 7'b1 : out_writes;

  //counters
  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           out_writes <= 7'b0;
           out_reads <= 7'b0;
       end else begin
           out_writes <= next_out_writes;
           out_reads <= next_out_reads;
       end
    end

  assert_never #(0,0,"Read Acceptance Capability exceeded")
     ovl_read_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (!limit_acceptance_capability && |read_issuing_capability && out_reads > read_issuing_capability)
       );

  assert_never #(0,0,"Write Acceptance Capability exceeded")
     ovl_write_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (!limit_acceptance_capability && (out_writes[6] == 1'b0 && out_writes[5:0] > write_issuing_capability))
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

//------------------------------------------------------------------------------
// CACHE OVLS Not in Internal PC
//------------------------------------------------------------------------------

 assert_implication #(1, 0,
    "AXI_ERRM_ARCACHE. When ARVALID is high, if ARCACHE[1] is low then ARCACHE[3] and ARCACHE[2] must also be low. Spec: table 5-1 on page 5-3."
  )  axi_errm_arcache
     (.clk              (ACLK),
      .reset_n          (ARESETn),
      .antecedent_expr  (AllowIllegalCache == 0 & (ARVALID) & ~ARCACHE[1]),
      .consequent_expr  (ARCACHE[3:2] == 2'b00)
      );

  assert_implication #(1, 0,
    "AXI_ERRM_AWCACHE. When AWVALID is high, if AWCACHE[1] is low then AWCACHE[3] and AWCACHE[2] must also be low. Spec: table 5-1 on page 5-3."
  )  axi_errm_awcache
     (.clk              (ACLK),
      .reset_n          (ARESETn),
      .antecedent_expr  (AllowIllegalCache == 0 & (AWVALID) & ~AWCACHE[1]),
      .consequent_expr  (AWCACHE[3:2] == 2'b00)
      );

//------------------------------------------------------------------------------
// AXI Protocol Checkers
//------------------------------------------------------------------------------
    assign #3 ACLKENDEL = ACLKEN;  // Delay 1ns more than clk_reset_if
  
    assign ACLKPC = (PortIsInternal) ? ~ACLKENDEL : ACLK;
  
    defparam uAxiVnPC.DATA_WIDTH = DATA_WIDTH;
    defparam uAxiVnPC.ADDR_WIDTH = ADDR_WIDTH;
    defparam uAxiVnPC.ID_WIDTH   = ID_WIDTH_I;
    defparam uAxiVnPC.WDEPTH     = 1;
    defparam uAxiVnPC.MAXRBURSTS = 500;
    defparam uAxiVnPC.MAXWBURSTS = 500;
    defparam uAxiVnPC.MAXWAITS   = 5000;
    defparam uAxiVnPC.AWUSER_WIDTH = AWUSER_WIDTH_I;
    defparam uAxiVnPC.WUSER_WIDTH  = WUSER_WIDTH_I;
    defparam uAxiVnPC.BUSER_WIDTH  = BUSER_WIDTH_I;
    defparam uAxiVnPC.ARUSER_WIDTH = ARUSER_WIDTH_I;
    defparam uAxiVnPC.RUSER_WIDTH  = RUSER_WIDTH_I;
    defparam uAxiVnPC.EXMON_WIDTH  = (ID_WIDTH_I > 10) : 10 : ID_WIDTH_I;
    defparam uAxiVnPC.AXI_ERRL_PropertyType = 2; // No Low power interface checking

    defparam uAxiVnPC.NUM_VNETS    =  VNETS;
    defparam uAxiVnPC.VN0_VNET     =  VNET_VALUE0;
    defparam uAxiVnPC.VN1_VNET     =  VNET_VALUE1;
    defparam uAxiVnPC.VN2_VNET     =  VNET_VALUE2;
    defparam uAxiVnPC.VN3_VNET     =  VNET_VALUE3;

    AxiVnPC uAxiVnPC (

        // Global Signals
        .ACLK           (ACLKPC),
        .ARESETn        (ARESETn),
  
        // Write Address Channel
        .AWVALID        (AWVALID),
        .AWREADY        (AWREADY),
        .AWID           (AWID),
        .AWADDR         (AWADDR),
        .AWLEN          (AWLEN),
        .AWSIZE         (AWSIZE),
        .AWBURST        (AWBURST),
        .AWLOCK         (AWLOCK),
        .AWCACHE        (AWCACHE),
        .AWPROT         (AWPROT),
        .AWREGION       (AWREGION),
        .AWQOS          (AWQV),
        .AWUSER         (AWUSER),
  
        // Write Channel
        .WVALID         (WVALID),
        .WREADY         (WREADY),
        .WID            (WID),
        .WLAST          (WLAST),
        .WDATA          (WDATA),
        .WSTRB          (WSTRB),
        .WUSER          (WUSER),
  
        // Write Response Channel
        .BVALID         (BVALID),
        .BREADY         (BREADY),
        .BID            (BID_i),
        .BRESP          (BRESP_i),
        .BUSER          (BUSER_i),
  
        // Read Address Channel
        .ARVALID        (ARVALID),
        .ARREADY        (ARREADY),
        .ARID           (ARID),
        .ARADDR         (ARADDR),
        .ARLEN          (ARLEN),
        .ARSIZE         (ARSIZE),
        .ARBURST        (ARBURST),
        .ARLOCK         (ARLOCK),
        .ARCACHE        (ARCACHE),
        .ARPROT         (ARPROT),
        .ARREGION       (ARREGION),
        .ARQOS          (ARQV),
        .ARUSER         (ARUSER),
  
        // Read Channel
        .RVALID         (RVALID),
        .RREADY         (RREADY),
        .RID            (RID_i),
        .RLAST          (RLAST_i),
        .RDATA          (RDATA_i),
        .RRESP          (RRESP_i),
        .RUSER          (RUSER_i),
  
        // Low power interface
        .CACTIVE        (1'b0),
        .CSYSREQ        (1'b0),
        .CSYSACK        (1'b0),
  
        //vnet sideband signals
        .AWVNET         (AWVNET),
        .ARVNET         (ARVNET),
        .WVNET          (WVNET)
  
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

`ifdef TRACE  
  axi_trace     u_axi_trace (
      .ACLK           (ACLK),
      .ARESETn        (ARESETn),
      .AWID           (1'b0/*AWID*/),
      .AWADDR         (AWADDR),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        (AWCACHE),
      .AWPROT         (AWPROT),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .WID            (1'b0/*WID*/),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WLAST          (WLAST),
      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .BID            (1'b0/*BID_i*/),
      .BRESP          (BRESP_i),
      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .ARID           (1'b0/*ARID*/),
      .ARADDR         (ARADDR),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        (ARCACHE),
      .ARPROT         (ARPROT),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .RID            (1'b0/*RID_i*/),
      .RDATA          (RDATA_i),
      .RRESP          (RRESP_i),
      .RLAST          (RLAST_i),
      .RVALID         (RVALID),
      .RREADY         (RREADY)
);
defparam u_axi_trace.ADDR_WIDTH = ADDR_WIDTH;
defparam u_axi_trace.DATA_WIDTH = DATA_WIDTH;
defparam u_axi_trace.ECHO = 1'b1;
//defparam u_axi_trace.ID_WIDTH = ID_WIDTH;
defparam u_axi_trace.ID_WIDTH = 1; // Remove ID for static latency ID_WIDTH;
defparam u_axi_trace.STRB_WIDTH = STRB_WIDTH;
defparam u_axi_trace.UNIT_NAME = INSTANCE;

`endif

`endif //ARM_ASSERT_ON

endmodule

//  --=============================== End ====================================--

