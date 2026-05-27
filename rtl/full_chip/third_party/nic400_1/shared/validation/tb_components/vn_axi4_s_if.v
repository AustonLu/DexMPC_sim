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
// Purpose : NIC400 axi4 slave interface
//
// Description : This block is an AXI4 slave that can be used in the main NIC400
//               testbench.
//
//               Currently contain an eXVC AXI4S or FRS component
//
//               NIC400r0p0 uses multi-bit AW and ARValid. These are
//               deviations from standard AXI4 and are, therefore, not output from
//               standard AXI4 signals.
//
//               The multibit AW and ARValid are added to the top of the AxUSER
//               signal and passed intro the testcomponent for checking.
//
//               AxValid is converted from a one-hot value to an 4bit value
//               where 4'b0 => AxVALID[0]
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module axi4_s_if(

                 // Global signals
                 ACLK,
                 ACLKEN,
                 ARESETn,

                 // Read Address Channel
                 ARID,
                 ARADDR,
                 ARLEN,
                 ARQV,
                 ARREGION,
                 ARSIZE,
                 ARBURST,
                 ARVALID,
                 ARREADY,
                 ARLOCK,
                 ARCACHE,
                 ARPROT,
                 ARUSER,

                 // Read Channel
                 RID,
                 RLAST,
                 RDATA,
                 RRESP,
                 RVALID,
                 RREADY,
                 RUSER,

                 // Write Address Channel
                 AWID,
                 AWADDR,
                 AWLEN,
                 AWQV,
                 AWREGION,
                 AWSIZE,
                 AWBURST,
                 AWVALID,
                 AWLOCK,
                 AWCACHE,
                 AWREADY,
                 AWPROT,
                 AWUSER,

                 // Write Channel
                 WLAST,
                 WSTRB,
                 WDATA,
                 WVALID,
                 WREADY,
                 WUSER,

                 // Write Response Channel
                 BID,
                 BRESP,
                 BVALID,
                 BREADY,
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
                                  //VNET Signals
                 AWVNET,
                 WVNET,
                 ARVNET,

                 // Virtual Network 0
                 vawvalid_vn0_s0,
                 vawready_vn0_s0,
                 vawqv_vn0_s0,
                 vwvalid_vn0_s0,
                 vwready_vn0_s0,
                 varvalid_vn0_s0,
                 varready_vn0_s0,
                 varqv_vn0_s0,

                 vawvalid_vn0_s1,
                 vawready_vn0_s1,
                 vawqv_vn0_s1,
                 vwvalid_vn0_s1,
                 vwready_vn0_s1,
                 varvalid_vn0_s1,
                 varready_vn0_s1,
                 varqv_vn0_s1,

                 vawvalid_vn0_s2,
                 vawready_vn0_s2,
                 vawqv_vn0_s2,
                 vwvalid_vn0_s2,
                 vwready_vn0_s2,
                 varvalid_vn0_s2,
                 varready_vn0_s2,
                 varqv_vn0_s2,

                 vawvalid_vn0_s3,
                 vawready_vn0_s3,
                 vawqv_vn0_s3,
                 vwvalid_vn0_s3,
                 vwready_vn0_s3,
                 varvalid_vn0_s3,
                 varready_vn0_s3,
                 varqv_vn0_s3,

                 vawvalid_vn0_s4,
                 vawready_vn0_s4,
                 vawqv_vn0_s4,
                 vwvalid_vn0_s4,
                 vwready_vn0_s4,
                 varvalid_vn0_s4,
                 varready_vn0_s4,
                 varqv_vn0_s4,

                 vawvalid_vn0_s5,
                 vawready_vn0_s5,
                 vawqv_vn0_s5,
                 vwvalid_vn0_s5,
                 vwready_vn0_s5,
                 varvalid_vn0_s5,
                 varready_vn0_s5,
                 varqv_vn0_s5,

                 vawvalid_vn0_s6,
                 vawready_vn0_s6,
                 vawqv_vn0_s6,
                 vwvalid_vn0_s6,
                 vwready_vn0_s6,
                 varvalid_vn0_s6,
                 varready_vn0_s6,
                 varqv_vn0_s6,

                 vawvalid_vn0_s7,
                 vawready_vn0_s7,
                 vawqv_vn0_s7,
                 vwvalid_vn0_s7,
                 vwready_vn0_s7,
                 varvalid_vn0_s7,
                 varready_vn0_s7,
                 varqv_vn0_s7,

                 vawvalid_vn0_s8,
                 vawready_vn0_s8,
                 vawqv_vn0_s8,
                 vwvalid_vn0_s8,
                 vwready_vn0_s8,
                 varvalid_vn0_s8,
                 varready_vn0_s8,
                 varqv_vn0_s8,

                 vawvalid_vn0_s9,
                 vawready_vn0_s9,
                 vawqv_vn0_s9,
                 vwvalid_vn0_s9,
                 vwready_vn0_s9,
                 varvalid_vn0_s9,
                 varready_vn0_s9,
                 varqv_vn0_s9,

                 vawvalid_vn0_s10,
                 vawready_vn0_s10,
                 vawqv_vn0_s10,
                 vwvalid_vn0_s10,
                 vwready_vn0_s10,
                 varvalid_vn0_s10,
                 varready_vn0_s10,
                 varqv_vn0_s10,

                 vawvalid_vn0_s11,
                 vawready_vn0_s11,
                 vawqv_vn0_s11,
                 vwvalid_vn0_s11,
                 vwready_vn0_s11,
                 varvalid_vn0_s11,
                 varready_vn0_s11,
                 varqv_vn0_s11,

                 // Virtual Network 1
                 vawvalid_vn1_s0,
                 vawready_vn1_s0,
                 vawqv_vn1_s0,
                 vwvalid_vn1_s0,
                 vwready_vn1_s0,
                 varvalid_vn1_s0,
                 varready_vn1_s0,
                 varqv_vn1_s0,

                 vawvalid_vn1_s1,
                 vawready_vn1_s1,
                 vawqv_vn1_s1,
                 vwvalid_vn1_s1,
                 vwready_vn1_s1,
                 varvalid_vn1_s1,
                 varready_vn1_s1,
                 varqv_vn1_s1,

                 vawvalid_vn1_s2,
                 vawready_vn1_s2,
                 vawqv_vn1_s2,
                 vwvalid_vn1_s2,
                 vwready_vn1_s2,
                 varvalid_vn1_s2,
                 varready_vn1_s2,
                 varqv_vn1_s2,

                 vawvalid_vn1_s3,
                 vawready_vn1_s3,
                 vawqv_vn1_s3,
                 vwvalid_vn1_s3,
                 vwready_vn1_s3,
                 varvalid_vn1_s3,
                 varready_vn1_s3,
                 varqv_vn1_s3,

                 vawvalid_vn1_s4,
                 vawready_vn1_s4,
                 vawqv_vn1_s4,
                 vwvalid_vn1_s4,
                 vwready_vn1_s4,
                 varvalid_vn1_s4,
                 varready_vn1_s4,
                 varqv_vn1_s4,

                 vawvalid_vn1_s5,
                 vawready_vn1_s5,
                 vawqv_vn1_s5,
                 vwvalid_vn1_s5,
                 vwready_vn1_s5,
                 varvalid_vn1_s5,
                 varready_vn1_s5,
                 varqv_vn1_s5,

                 vawvalid_vn1_s6,
                 vawready_vn1_s6,
                 vawqv_vn1_s6,
                 vwvalid_vn1_s6,
                 vwready_vn1_s6,
                 varvalid_vn1_s6,
                 varready_vn1_s6,
                 varqv_vn1_s6,

                 vawvalid_vn1_s7,
                 vawready_vn1_s7,
                 vawqv_vn1_s7,
                 vwvalid_vn1_s7,
                 vwready_vn1_s7,
                 varvalid_vn1_s7,
                 varready_vn1_s7,
                 varqv_vn1_s7,

                 vawvalid_vn1_s8,
                 vawready_vn1_s8,
                 vawqv_vn1_s8,
                 vwvalid_vn1_s8,
                 vwready_vn1_s8,
                 varvalid_vn1_s8,
                 varready_vn1_s8,
                 varqv_vn1_s8,

                 vawvalid_vn1_s9,
                 vawready_vn1_s9,
                 vawqv_vn1_s9,
                 vwvalid_vn1_s9,
                 vwready_vn1_s9,
                 varvalid_vn1_s9,
                 varready_vn1_s9,
                 varqv_vn1_s9,

                 vawvalid_vn1_s10,
                 vawready_vn1_s10,
                 vawqv_vn1_s10,
                 vwvalid_vn1_s10,
                 vwready_vn1_s10,
                 varvalid_vn1_s10,
                 varready_vn1_s10,
                 varqv_vn1_s10,

                 vawvalid_vn1_s11,
                 vawready_vn1_s11,
                 vawqv_vn1_s11,
                 vwvalid_vn1_s11,
                 vwready_vn1_s11,
                 varvalid_vn1_s11,
                 varready_vn1_s11,
                 varqv_vn1_s11,

                 // Virtual Network 2
                 vawvalid_vn2_s0,
                 vawready_vn2_s0,
                 vawqv_vn2_s0,
                 vwvalid_vn2_s0,
                 vwready_vn2_s0,
                 varvalid_vn2_s0,
                 varready_vn2_s0,
                 varqv_vn2_s0,

                 vawvalid_vn2_s1,
                 vawready_vn2_s1,
                 vawqv_vn2_s1,
                 vwvalid_vn2_s1,
                 vwready_vn2_s1,
                 varvalid_vn2_s1,
                 varready_vn2_s1,
                 varqv_vn2_s1,

                 vawvalid_vn2_s2,
                 vawready_vn2_s2,
                 vawqv_vn2_s2,
                 vwvalid_vn2_s2,
                 vwready_vn2_s2,
                 varvalid_vn2_s2,
                 varready_vn2_s2,
                 varqv_vn2_s2,

                 vawvalid_vn2_s3,
                 vawready_vn2_s3,
                 vawqv_vn2_s3,
                 vwvalid_vn2_s3,
                 vwready_vn2_s3,
                 varvalid_vn2_s3,
                 varready_vn2_s3,
                 varqv_vn2_s3,

                 vawvalid_vn2_s4,
                 vawready_vn2_s4,
                 vawqv_vn2_s4,
                 vwvalid_vn2_s4,
                 vwready_vn2_s4,
                 varvalid_vn2_s4,
                 varready_vn2_s4,
                 varqv_vn2_s4,

                 vawvalid_vn2_s5,
                 vawready_vn2_s5,
                 vawqv_vn2_s5,
                 vwvalid_vn2_s5,
                 vwready_vn2_s5,
                 varvalid_vn2_s5,
                 varready_vn2_s5,
                 varqv_vn2_s5,

                 vawvalid_vn2_s6,
                 vawready_vn2_s6,
                 vawqv_vn2_s6,
                 vwvalid_vn2_s6,
                 vwready_vn2_s6,
                 varvalid_vn2_s6,
                 varready_vn2_s6,
                 varqv_vn2_s6,

                 vawvalid_vn2_s7,
                 vawready_vn2_s7,
                 vawqv_vn2_s7,
                 vwvalid_vn2_s7,
                 vwready_vn2_s7,
                 varvalid_vn2_s7,
                 varready_vn2_s7,
                 varqv_vn2_s7,

                 vawvalid_vn2_s8,
                 vawready_vn2_s8,
                 vawqv_vn2_s8,
                 vwvalid_vn2_s8,
                 vwready_vn2_s8,
                 varvalid_vn2_s8,
                 varready_vn2_s8,
                 varqv_vn2_s8,

                 vawvalid_vn2_s9,
                 vawready_vn2_s9,
                 vawqv_vn2_s9,
                 vwvalid_vn2_s9,
                 vwready_vn2_s9,
                 varvalid_vn2_s9,
                 varready_vn2_s9,
                 varqv_vn2_s9,

                 vawvalid_vn2_s10,
                 vawready_vn2_s10,
                 vawqv_vn2_s10,
                 vwvalid_vn2_s10,
                 vwready_vn2_s10,
                 varvalid_vn2_s10,
                 varready_vn2_s10,
                 varqv_vn2_s10,

                 vawvalid_vn2_s11,
                 vawready_vn2_s11,
                 vawqv_vn2_s11,
                 vwvalid_vn2_s11,
                 vwready_vn2_s11,
                 varvalid_vn2_s11,
                 varready_vn2_s11,
                 varqv_vn2_s11,

                 // Virtual Network 3
                 vawvalid_vn3_s0,
                 vawready_vn3_s0,
                 vawqv_vn3_s0,
                 vwvalid_vn3_s0,
                 vwready_vn3_s0,
                 varvalid_vn3_s0,
                 varready_vn3_s0,
                 varqv_vn3_s0,

                 vawvalid_vn3_s1,
                 vawready_vn3_s1,
                 vawqv_vn3_s1,
                 vwvalid_vn3_s1,
                 vwready_vn3_s1,
                 varvalid_vn3_s1,
                 varready_vn3_s1,
                 varqv_vn3_s1,

                 vawvalid_vn3_s2,
                 vawready_vn3_s2,
                 vawqv_vn3_s2,
                 vwvalid_vn3_s2,
                 vwready_vn3_s2,
                 varvalid_vn3_s2,
                 varready_vn3_s2,
                 varqv_vn3_s2,

                 vawvalid_vn3_s3,
                 vawready_vn3_s3,
                 vawqv_vn3_s3,
                 vwvalid_vn3_s3,
                 vwready_vn3_s3,
                 varvalid_vn3_s3,
                 varready_vn3_s3,
                 varqv_vn3_s3,

                 vawvalid_vn3_s4,
                 vawready_vn3_s4,
                 vawqv_vn3_s4,
                 vwvalid_vn3_s4,
                 vwready_vn3_s4,
                 varvalid_vn3_s4,
                 varready_vn3_s4,
                 varqv_vn3_s4,

                 vawvalid_vn3_s5,
                 vawready_vn3_s5,
                 vawqv_vn3_s5,
                 vwvalid_vn3_s5,
                 vwready_vn3_s5,
                 varvalid_vn3_s5,
                 varready_vn3_s5,
                 varqv_vn3_s5,

                 vawvalid_vn3_s6,
                 vawready_vn3_s6,
                 vawqv_vn3_s6,
                 vwvalid_vn3_s6,
                 vwready_vn3_s6,
                 varvalid_vn3_s6,
                 varready_vn3_s6,
                 varqv_vn3_s6,

                 vawvalid_vn3_s7,
                 vawready_vn3_s7,
                 vawqv_vn3_s7,
                 vwvalid_vn3_s7,
                 vwready_vn3_s7,
                 varvalid_vn3_s7,
                 varready_vn3_s7,
                 varqv_vn3_s7,

                 vawvalid_vn3_s8,
                 vawready_vn3_s8,
                 vawqv_vn3_s8,
                 vwvalid_vn3_s8,
                 vwready_vn3_s8,
                 varvalid_vn3_s8,
                 varready_vn3_s8,
                 varqv_vn3_s8,

                 vawvalid_vn3_s9,
                 vawready_vn3_s9,
                 vawqv_vn3_s9,
                 vwvalid_vn3_s9,
                 vwready_vn3_s9,
                 varvalid_vn3_s9,
                 varready_vn3_s9,
                 varqv_vn3_s9,

                 vawvalid_vn3_s10,
                 vawready_vn3_s10,
                 vawqv_vn3_s10,
                 vwvalid_vn3_s10,
                 vwready_vn3_s10,
                 varvalid_vn3_s10,
                 varready_vn3_s10,
                 varqv_vn3_s10,

                 vawvalid_vn3_s11,
                 vawready_vn3_s11,
                 vawqv_vn3_s11,
                 vwvalid_vn3_s11,
                 vwready_vn3_s11,
                 varvalid_vn3_s11,
                 varready_vn3_s11,
                 varqv_vn3_s11

);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter ADDR_WIDTH       = 32;
  parameter AWUSER_WIDTH     = 16;
  parameter ARUSER_WIDTH     = 16;
  parameter RUSER_WIDTH      = 16;
  parameter WUSER_WIDTH      = 16;
  parameter BUSER_WIDTH      = 16;
  parameter ID_WIDTH         = 16;
  parameter VALID_WIDTH      = 1;
  parameter EW_WIDTH         = 8;

  parameter read_issuing_capability  = 16;
  parameter write_issuing_capability  = 16;
  parameter combined_issuing_capability  = 16;
  parameter limit_acceptance_capability  = 0;

  parameter leading_writes   = 32;

  //If limit_acceptance_capability is true then the FRM should limit the number of transactions
  //rather than letting the DMC do it.
  parameter AXIPC_READS      = (limit_acceptance_capability == 1) ?
                                read_issuing_capability + 10 : read_issuing_capability;
  parameter AXIPC_WRITES     = (limit_acceptance_capability == 1) ?
                                write_issuing_capability + 10 + 32: write_issuing_capability + 32;

  parameter INSTANCE         = "undef";
  parameter INSTANCE_TYPE    = "AXIS_";

  parameter AWUSER_WIDTH_I   = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
  parameter ARUSER_WIDTH_I   = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
  parameter WUSER_WIDTH_I    = (WUSER_WIDTH == 0) ? 1 : WUSER_WIDTH;
  parameter RUSER_WIDTH_I    = (RUSER_WIDTH == 0) ? 1 : RUSER_WIDTH;
  parameter BUSER_WIDTH_I    = (BUSER_WIDTH == 0) ? 1 : BUSER_WIDTH;
  parameter ID_WIDTH_I       = (ID_WIDTH == 0) ? 1 : ID_WIDTH;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter ID_MAX           = ID_WIDTH_I - 1;
  parameter VALID_MAX        = VALID_WIDTH - 1;
  parameter EW_MAX           = EW_WIDTH -1;
  parameter USER_MAX_AW      = AWUSER_WIDTH_I - 1;
  parameter USER_MAX_AR      = ARUSER_WIDTH_I - 1;
  parameter USER_MAX_R       = RUSER_WIDTH_I - 1;
  parameter USER_MAX_W       = WUSER_WIDTH_I - 1;
  parameter USER_MAX_B       = BUSER_WIDTH_I - 1;

  parameter regions_flag     = 0;

  parameter AllowLeadingRdata = 0;
  parameter AllowIllegalCache = 0;

  parameter DriveOnlyOnEnable = 0;
  parameter PortIsInternal    = 0;


// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

// Clock and Reset in AXI domain
input                   ACLK;            // AXI Bus Clock
input                   ACLKEN;          // AXI Bus Clock Enable
input                   ARESETn;         // AXI Reset

// Read Address Channel
input  [ID_MAX:0]       ARID;            // Read address ID
input  [ADDR_MAX:0]     ARADDR;          // Read address
input  [7:0]            ARLEN;           // Read burst length
input  [3:0]            ARQV;            // Read QV value
input  [3:0]            ARREGION;        // Read region signal

input  [2:0]            ARSIZE;          // Read burst size
input  [1:0]            ARBURST;         // Read burst type
input  [VALID_MAX:0]    ARVALID;         // Read address valid
output                  ARREADY;         // Read address ready
input  [3:0]            ARCACHE;         // Read cache information
input                   ARLOCK;          // Read lock information
input  [2:0]            ARPROT;          // Read protection information
input  [USER_MAX_AR:0]  ARUSER;          // Read user information

// Read Channel
output  [ID_MAX:0]      RID;             // Read data ID
output                  RLAST;           // Read last
output  [DATA_MAX:0]    RDATA;           // Read data
output  [1:0]           RRESP;           // Read response
output                  RVALID;          // Read response valid
input                   RREADY;          // Read response ready
output  [USER_MAX_R:0]  RUSER;           // Read user information

// Write Address Channel
input  [ID_MAX:0]       AWID;            // Write address ID
input  [ADDR_MAX:0]     AWADDR;          // Write address
input  [7:0]            AWLEN;           // Write burst length
input  [3:0]            AWQV;            // Write QV value
input  [3:0]            AWREGION;        // Write region signal
input  [2:0]            AWSIZE;          // Write burst size
input  [1:0]            AWBURST;         // Write burst type
input  [VALID_MAX:0]    AWVALID;         // Write address valid
output                  AWREADY;         // Write address ready
input  [3:0]            AWCACHE;         // Write cache information
input                   AWLOCK;          // Write lock information
input  [2:0]            AWPROT;          // Write protection information
input  [USER_MAX_AW:0]  AWUSER;          // Write user information

// Write Channel
input                   WLAST;           // Write last
input  [STRB_MAX:0]     WSTRB;           // Write strobes
input  [DATA_MAX:0]     WDATA;           // Write data
input                   WVALID;          // Write valid
output                  WREADY;          // Write ready
input  [USER_MAX_W:0]   WUSER;           // Write user information

// Write Response Channel
output  [ID_MAX:0]      BID;             // Write response ID
output  [1:0]           BRESP;           // Write response
output                  BVALID;          // Write response valid
input                   BREADY;          // Write response ready
output  [USER_MAX_B:0]  BUSER;           // Write response user information

//Emit and Wait channels only used in FRM mode
output [EW_MAX:0]      EMIT_DATA;       //Emit data
output                 EMIT_REQ;        //Emit Request
input                  EMIT_ACK;        //Emit acknoledgement

input  [EW_MAX:0]      WAIT_DATA;       //Wait data
input                  WAIT_REQ;        //Wait Request
output                 WAIT_ACK;        //Waitr acknoledgement

// APB3 Interface
input         PENABLE;         // APB Enable
input         PWRITE;          // APB transfer(R/W) direction
input  [31:0] PADDR;           // APB address
input  [31:0] PWDATA;          // APB write data
output        PREADY;          // APB transfer completion signal for slaves
output        PSLVERR;         // APB transfer response signal for slaves
output [31:0] PRDATA;          // APB read data for slave0
input         PSEL;

input         PCLK;
input         PRESETn;

//VNET Signals
input   [3:0]       AWVNET;                      //vnet value of vnb1_axi_s_0 AXI bus AW Channel
input   [3:0]       WVNET;                       //vnet value of vnb1_axi_s_0 AXI bus W Channel
input   [3:0]       ARVNET;                      //vnet value of vnb1_axi_s_0 AXI bus AR Channel

//Virtual Network Token Control
input               vawvalid_vn0_s0;
output              vawready_vn0_s0;
input   [3:0]       vawqv_vn0_s0;
input               vwvalid_vn0_s0;
output              vwready_vn0_s0;
input               varvalid_vn0_s0;
output              varready_vn0_s0;
input   [3:0]       varqv_vn0_s0;

input               vawvalid_vn0_s1;
output              vawready_vn0_s1;
input   [3:0]       vawqv_vn0_s1;
input               vwvalid_vn0_s1;
output              vwready_vn0_s1;
input               varvalid_vn0_s1;
output              varready_vn0_s1;
input   [3:0]       varqv_vn0_s1;

input               vawvalid_vn0_s2;
output              vawready_vn0_s2;
input   [3:0]       vawqv_vn0_s2;
input               vwvalid_vn0_s2;
output              vwready_vn0_s2;
input               varvalid_vn0_s2;
output              varready_vn0_s2;
input   [3:0]       varqv_vn0_s2;

input               vawvalid_vn0_s3;
output              vawready_vn0_s3;
input   [3:0]       vawqv_vn0_s3;
input               vwvalid_vn0_s3;
output              vwready_vn0_s3;
input               varvalid_vn0_s3;
output              varready_vn0_s3;
input   [3:0]       varqv_vn0_s3;

input               vawvalid_vn0_s4;
output              vawready_vn0_s4;
input   [3:0]       vawqv_vn0_s4;
input               vwvalid_vn0_s4;
output              vwready_vn0_s4;
input               varvalid_vn0_s4;
output              varready_vn0_s4;
input   [3:0]       varqv_vn0_s4;

input               vawvalid_vn0_s5;
output              vawready_vn0_s5;
input   [3:0]       vawqv_vn0_s5;
input               vwvalid_vn0_s5;
output              vwready_vn0_s5;
input               varvalid_vn0_s5;
output              varready_vn0_s5;
input   [3:0]       varqv_vn0_s5;

input               vawvalid_vn0_s6;
output              vawready_vn0_s6;
input   [3:0]       vawqv_vn0_s6;
input               vwvalid_vn0_s6;
output              vwready_vn0_s6;
input               varvalid_vn0_s6;
output              varready_vn0_s6;
input   [3:0]       varqv_vn0_s6;

input               vawvalid_vn0_s7;
output              vawready_vn0_s7;
input   [3:0]       vawqv_vn0_s7;
input               vwvalid_vn0_s7;
output              vwready_vn0_s7;
input               varvalid_vn0_s7;
output              varready_vn0_s7;
input   [3:0]       varqv_vn0_s7;

input               vawvalid_vn0_s8;
output              vawready_vn0_s8;
input   [3:0]       vawqv_vn0_s8;
input               vwvalid_vn0_s8;
output              vwready_vn0_s8;
input               varvalid_vn0_s8;
output              varready_vn0_s8;
input   [3:0]       varqv_vn0_s8;

input               vawvalid_vn0_s9;
output              vawready_vn0_s9;
input   [3:0]       vawqv_vn0_s9;
input               vwvalid_vn0_s9;
output              vwready_vn0_s9;
input               varvalid_vn0_s9;
output              varready_vn0_s9;
input   [3:0]       varqv_vn0_s9;

input               vawvalid_vn0_s10;
output              vawready_vn0_s10;
input   [3:0]       vawqv_vn0_s10;
input               vwvalid_vn0_s10;
output              vwready_vn0_s10;
input               varvalid_vn0_s10;
output              varready_vn0_s10;
input   [3:0]       varqv_vn0_s10;

input               vawvalid_vn0_s11;
output              vawready_vn0_s11;
input   [3:0]       vawqv_vn0_s11;
input               vwvalid_vn0_s11;
output              vwready_vn0_s11;
input               varvalid_vn0_s11;
output              varready_vn0_s11;
input   [3:0]       varqv_vn0_s11;

//Virtual Network Token Control
input               vawvalid_vn1_s0;
output              vawready_vn1_s0;
input   [3:0]       vawqv_vn1_s0;
input               vwvalid_vn1_s0;
output              vwready_vn1_s0;
input               varvalid_vn1_s0;
output              varready_vn1_s0;
input   [3:0]       varqv_vn1_s0;

input               vawvalid_vn1_s1;
output              vawready_vn1_s1;
input   [3:0]       vawqv_vn1_s1;
input               vwvalid_vn1_s1;
output              vwready_vn1_s1;
input               varvalid_vn1_s1;
output              varready_vn1_s1;
input   [3:0]       varqv_vn1_s1;

input               vawvalid_vn1_s2;
output              vawready_vn1_s2;
input   [3:0]       vawqv_vn1_s2;
input               vwvalid_vn1_s2;
output              vwready_vn1_s2;
input               varvalid_vn1_s2;
output              varready_vn1_s2;
input   [3:0]       varqv_vn1_s2;

input               vawvalid_vn1_s3;
output              vawready_vn1_s3;
input   [3:0]       vawqv_vn1_s3;
input               vwvalid_vn1_s3;
output              vwready_vn1_s3;
input               varvalid_vn1_s3;
output              varready_vn1_s3;
input   [3:0]       varqv_vn1_s3;

input               vawvalid_vn1_s4;
output              vawready_vn1_s4;
input   [3:0]       vawqv_vn1_s4;
input               vwvalid_vn1_s4;
output              vwready_vn1_s4;
input               varvalid_vn1_s4;
output              varready_vn1_s4;
input   [3:0]       varqv_vn1_s4;

input               vawvalid_vn1_s5;
output              vawready_vn1_s5;
input   [3:0]       vawqv_vn1_s5;
input               vwvalid_vn1_s5;
output              vwready_vn1_s5;
input               varvalid_vn1_s5;
output              varready_vn1_s5;
input   [3:0]       varqv_vn1_s5;

input               vawvalid_vn1_s6;
output              vawready_vn1_s6;
input   [3:0]       vawqv_vn1_s6;
input               vwvalid_vn1_s6;
output              vwready_vn1_s6;
input               varvalid_vn1_s6;
output              varready_vn1_s6;
input   [3:0]       varqv_vn1_s6;

input               vawvalid_vn1_s7;
output              vawready_vn1_s7;
input   [3:0]       vawqv_vn1_s7;
input               vwvalid_vn1_s7;
output              vwready_vn1_s7;
input               varvalid_vn1_s7;
output              varready_vn1_s7;
input   [3:0]       varqv_vn1_s7;

input               vawvalid_vn1_s8;
output              vawready_vn1_s8;
input   [3:0]       vawqv_vn1_s8;
input               vwvalid_vn1_s8;
output              vwready_vn1_s8;
input               varvalid_vn1_s8;
output              varready_vn1_s8;
input   [3:0]       varqv_vn1_s8;

input               vawvalid_vn1_s9;
output              vawready_vn1_s9;
input   [3:0]       vawqv_vn1_s9;
input               vwvalid_vn1_s9;
output              vwready_vn1_s9;
input               varvalid_vn1_s9;
output              varready_vn1_s9;
input   [3:0]       varqv_vn1_s9;

input               vawvalid_vn1_s10;
output              vawready_vn1_s10;
input   [3:0]       vawqv_vn1_s10;
input               vwvalid_vn1_s10;
output              vwready_vn1_s10;
input               varvalid_vn1_s10;
output              varready_vn1_s10;
input   [3:0]       varqv_vn1_s10;

input               vawvalid_vn1_s11;
output              vawready_vn1_s11;
input   [3:0]       vawqv_vn1_s11;
input               vwvalid_vn1_s11;
output              vwready_vn1_s11;
input               varvalid_vn1_s11;
output              varready_vn1_s11;
input   [3:0]       varqv_vn1_s11;

//Virtual Network Token Control
input               vawvalid_vn2_s0;
output              vawready_vn2_s0;
input   [3:0]       vawqv_vn2_s0;
input               vwvalid_vn2_s0;
output              vwready_vn2_s0;
input               varvalid_vn2_s0;
output              varready_vn2_s0;
input   [3:0]       varqv_vn2_s0;

input               vawvalid_vn2_s1;
output              vawready_vn2_s1;
input   [3:0]       vawqv_vn2_s1;
input               vwvalid_vn2_s1;
output              vwready_vn2_s1;
input               varvalid_vn2_s1;
output              varready_vn2_s1;
input   [3:0]       varqv_vn2_s1;

input               vawvalid_vn2_s2;
output              vawready_vn2_s2;
input   [3:0]       vawqv_vn2_s2;
input               vwvalid_vn2_s2;
output              vwready_vn2_s2;
input               varvalid_vn2_s2;
output              varready_vn2_s2;
input   [3:0]       varqv_vn2_s2;

input               vawvalid_vn2_s3;
output              vawready_vn2_s3;
input   [3:0]       vawqv_vn2_s3;
input               vwvalid_vn2_s3;
output              vwready_vn2_s3;
input               varvalid_vn2_s3;
output              varready_vn2_s3;
input   [3:0]       varqv_vn2_s3;

input               vawvalid_vn2_s4;
output              vawready_vn2_s4;
input   [3:0]       vawqv_vn2_s4;
input               vwvalid_vn2_s4;
output              vwready_vn2_s4;
input               varvalid_vn2_s4;
output              varready_vn2_s4;
input   [3:0]       varqv_vn2_s4;

input               vawvalid_vn2_s5;
output              vawready_vn2_s5;
input   [3:0]       vawqv_vn2_s5;
input               vwvalid_vn2_s5;
output              vwready_vn2_s5;
input               varvalid_vn2_s5;
output              varready_vn2_s5;
input   [3:0]       varqv_vn2_s5;

input               vawvalid_vn2_s6;
output              vawready_vn2_s6;
input   [3:0]       vawqv_vn2_s6;
input               vwvalid_vn2_s6;
output              vwready_vn2_s6;
input               varvalid_vn2_s6;
output              varready_vn2_s6;
input   [3:0]       varqv_vn2_s6;

input               vawvalid_vn2_s7;
output              vawready_vn2_s7;
input   [3:0]       vawqv_vn2_s7;
input               vwvalid_vn2_s7;
output              vwready_vn2_s7;
input               varvalid_vn2_s7;
output              varready_vn2_s7;
input   [3:0]       varqv_vn2_s7;

input               vawvalid_vn2_s8;
output              vawready_vn2_s8;
input   [3:0]       vawqv_vn2_s8;
input               vwvalid_vn2_s8;
output              vwready_vn2_s8;
input               varvalid_vn2_s8;
output              varready_vn2_s8;
input   [3:0]       varqv_vn2_s8;

input               vawvalid_vn2_s9;
output              vawready_vn2_s9;
input   [3:0]       vawqv_vn2_s9;
input               vwvalid_vn2_s9;
output              vwready_vn2_s9;
input               varvalid_vn2_s9;
output              varready_vn2_s9;
input   [3:0]       varqv_vn2_s9;

input               vawvalid_vn2_s10;
output              vawready_vn2_s10;
input   [3:0]       vawqv_vn2_s10;
input               vwvalid_vn2_s10;
output              vwready_vn2_s10;
input               varvalid_vn2_s10;
output              varready_vn2_s10;
input   [3:0]       varqv_vn2_s10;

input               vawvalid_vn2_s11;
output              vawready_vn2_s11;
input   [3:0]       vawqv_vn2_s11;
input               vwvalid_vn2_s11;
output              vwready_vn2_s11;
input               varvalid_vn2_s11;
output              varready_vn2_s11;
input   [3:0]       varqv_vn2_s11;

//Virtual Network Token Control
input               vawvalid_vn3_s0;
output              vawready_vn3_s0;
input   [3:0]       vawqv_vn3_s0;
input               vwvalid_vn3_s0;
output              vwready_vn3_s0;
input               varvalid_vn3_s0;
output              varready_vn3_s0;
input   [3:0]       varqv_vn3_s0;

input               vawvalid_vn3_s1;
output              vawready_vn3_s1;
input   [3:0]       vawqv_vn3_s1;
input               vwvalid_vn3_s1;
output              vwready_vn3_s1;
input               varvalid_vn3_s1;
output              varready_vn3_s1;
input   [3:0]       varqv_vn3_s1;

input               vawvalid_vn3_s2;
output              vawready_vn3_s2;
input   [3:0]       vawqv_vn3_s2;
input               vwvalid_vn3_s2;
output              vwready_vn3_s2;
input               varvalid_vn3_s2;
output              varready_vn3_s2;
input   [3:0]       varqv_vn3_s2;

input               vawvalid_vn3_s3;
output              vawready_vn3_s3;
input   [3:0]       vawqv_vn3_s3;
input               vwvalid_vn3_s3;
output              vwready_vn3_s3;
input               varvalid_vn3_s3;
output              varready_vn3_s3;
input   [3:0]       varqv_vn3_s3;

input               vawvalid_vn3_s4;
output              vawready_vn3_s4;
input   [3:0]       vawqv_vn3_s4;
input               vwvalid_vn3_s4;
output              vwready_vn3_s4;
input               varvalid_vn3_s4;
output              varready_vn3_s4;
input   [3:0]       varqv_vn3_s4;

input               vawvalid_vn3_s5;
output              vawready_vn3_s5;
input   [3:0]       vawqv_vn3_s5;
input               vwvalid_vn3_s5;
output              vwready_vn3_s5;
input               varvalid_vn3_s5;
output              varready_vn3_s5;
input   [3:0]       varqv_vn3_s5;

input               vawvalid_vn3_s6;
output              vawready_vn3_s6;
input   [3:0]       vawqv_vn3_s6;
input               vwvalid_vn3_s6;
output              vwready_vn3_s6;
input               varvalid_vn3_s6;
output              varready_vn3_s6;
input   [3:0]       varqv_vn3_s6;

input               vawvalid_vn3_s7;
output              vawready_vn3_s7;
input   [3:0]       vawqv_vn3_s7;
input               vwvalid_vn3_s7;
output              vwready_vn3_s7;
input               varvalid_vn3_s7;
output              varready_vn3_s7;
input   [3:0]       varqv_vn3_s7;

input               vawvalid_vn3_s8;
output              vawready_vn3_s8;
input   [3:0]       vawqv_vn3_s8;
input               vwvalid_vn3_s8;
output              vwready_vn3_s8;
input               varvalid_vn3_s8;
output              varready_vn3_s8;
input   [3:0]       varqv_vn3_s8;

input               vawvalid_vn3_s9;
output              vawready_vn3_s9;
input   [3:0]       vawqv_vn3_s9;
input               vwvalid_vn3_s9;
output              vwready_vn3_s9;
input               varvalid_vn3_s9;
output              varready_vn3_s9;
input   [3:0]       varqv_vn3_s9;

input               vawvalid_vn3_s10;
output              vawready_vn3_s10;
input   [3:0]       vawqv_vn3_s10;
input               vwvalid_vn3_s10;
output              vwready_vn3_s10;
input               varvalid_vn3_s10;
output              varready_vn3_s10;
input   [3:0]       varqv_vn3_s10;

input               vawvalid_vn3_s11;
output              vawready_vn3_s11;
input   [3:0]       vawqv_vn3_s11;
input               vwvalid_vn3_s11;
output              vwready_vn3_s11;
input               varvalid_vn3_s11;
output              varready_vn3_s11;
input   [3:0]       varqv_vn3_s11;

// -----------------------------------------------------------------------------
//  Wire and Register Declarations
// -----------------------------------------------------------------------------

wire [3:0]            AWREGION_int;
wire [3:0]            ARREGION_int;
reg  [4:0]            VALID_prev;
reg  [4:0]            READY_prev;

wire [USER_MAX_AW+16:0]       AWUSER_int;
wire [USER_MAX_AR+16:0]       ARUSER_int;

reg  [VALID_MAX:0]           ARVALID_int;
reg  [VALID_MAX:0]           AWVALID_int;

reg  [7:0]                   ARVALID_val;
reg  [7:0]                   AWVALID_val;

wire [6:0]               next_out_reads;
wire [6:0]               next_out_writes;
reg  [6:0]               out_reads;
reg  [6:0]               out_writes;
reg                      error_v;
reg                      error_r;
reg                      PCLK_pulse;
reg                      ACLK_pulse;

wire  [ID_MAX:0]      RID_i;             // Read data ID
wire                  RLAST_i;           // Read last
wire  [DATA_MAX:0]    RDATA_i;           // Read data
wire  [1:0]           RRESP_i;           // Read response
wire  [USER_MAX_R:0]  RUSER_i;           // Read user field

wire  [ID_MAX:0]      BID_i;             // Write response ID
wire  [1:0]           BRESP_i;           // Write response
wire  [USER_MAX_B:0]  BUSER_i;           // Write response user field


 //VNET Signals
wire   [3:0]       AWVNET;
wire   [3:0]       WVNET;
wire   [3:0]       ARVNET;

 //Virtual Network Token Control
wire               vawvalid_vn0_s0;
reg                vawready_vn0_s0;
wire   [3:0]       vawqv_vn0_s0;
wire               vwvalid_vn0_s0;
reg                vwready_vn0_s0;
wire               varvalid_vn0_s0;
reg                varready_vn0_s0;
wire   [3:0]       varqv_vn0_s0;

wire               vawvalid_vn0_s1;
reg                vawready_vn0_s1;
wire   [3:0]       vawqv_vn0_s1;
wire               vwvalid_vn0_s1;
reg                vwready_vn0_s1;
wire               varvalid_vn0_s1;
reg                varready_vn0_s1;
wire   [3:0]       varqv_vn0_s1;

wire               vawvalid_vn0_s2;
reg                vawready_vn0_s2;
wire   [3:0]       vawqv_vn0_s2;
wire               vwvalid_vn0_s2;
reg                vwready_vn0_s2;
wire               varvalid_vn0_s2;
reg                varready_vn0_s2;
wire   [3:0]       varqv_vn0_s2;

wire               vawvalid_vn0_s3;
reg                vawready_vn0_s3;
wire   [3:0]       vawqv_vn0_s3;
wire               vwvalid_vn0_s3;
reg                vwready_vn0_s3;
wire               varvalid_vn0_s3;
reg                varready_vn0_s3;
wire   [3:0]       varqv_vn0_s3;

wire               vawvalid_vn0_s4;
reg                vawready_vn0_s4;
wire   [3:0]       vawqv_vn0_s4;
wire               vwvalid_vn0_s4;
reg                vwready_vn0_s4;
wire               varvalid_vn0_s4;
reg                varready_vn0_s4;
wire   [3:0]       varqv_vn0_s4;

wire               vawvalid_vn0_s5;
reg                vawready_vn0_s5;
wire   [3:0]       vawqv_vn0_s5;
wire               vwvalid_vn0_s5;
reg                vwready_vn0_s5;
wire               varvalid_vn0_s5;
reg                varready_vn0_s5;
wire   [3:0]       varqv_vn0_s5;

wire               vawvalid_vn0_s6;
reg                vawready_vn0_s6;
wire   [3:0]       vawqv_vn0_s6;
wire               vwvalid_vn0_s6;
reg                vwready_vn0_s6;
wire               varvalid_vn0_s6;
reg                varready_vn0_s6;
wire   [3:0]       varqv_vn0_s6;

wire               vawvalid_vn0_s7;
reg                vawready_vn0_s7;
wire   [3:0]       vawqv_vn0_s7;
wire               vwvalid_vn0_s7;
reg                vwready_vn0_s7;
wire               varvalid_vn0_s7;
reg                varready_vn0_s7;
wire   [3:0]       varqv_vn0_s7;

wire               vawvalid_vn0_s8;
reg                vawready_vn0_s8;
wire   [3:0]       vawqv_vn0_s8;
wire               vwvalid_vn0_s8;
reg                vwready_vn0_s8;
wire               varvalid_vn0_s8;
reg                varready_vn0_s8;
wire   [3:0]       varqv_vn0_s8;

wire               vawvalid_vn0_s9;
reg                vawready_vn0_s9;
wire   [3:0]       vawqv_vn0_s9;
wire               vwvalid_vn0_s9;
reg                vwready_vn0_s9;
wire               varvalid_vn0_s9;
reg                varready_vn0_s9;
wire   [3:0]       varqv_vn0_s9;

wire               vawvalid_vn0_s10;
reg                vawready_vn0_s10;
wire   [3:0]       vawqv_vn0_s10;
wire               vwvalid_vn0_s10;
reg                vwready_vn0_s10;
wire               varvalid_vn0_s10;
reg                varready_vn0_s10;
wire   [3:0]       varqv_vn0_s10;

wire               vawvalid_vn0_s11;
reg                vawready_vn0_s11;
wire   [3:0]       vawqv_vn0_s11;
wire               vwvalid_vn0_s11;
reg                vwready_vn0_s11;
wire               varvalid_vn0_s11;
reg                varready_vn0_s11;
wire   [3:0]       varqv_vn0_s11;

//Virtual Network Token Control
wire               vawvalid_vn1_s0;
reg                vawready_vn1_s0;
wire   [3:0]       vawqv_vn1_s0;
wire               vwvalid_vn1_s0;
reg                vwready_vn1_s0;
wire               varvalid_vn1_s0;
reg                varready_vn1_s0;
wire   [3:0]       varqv_vn1_s0;

wire               vawvalid_vn1_s1;
reg                vawready_vn1_s1;
wire   [3:0]       vawqv_vn1_s1;
wire               vwvalid_vn1_s1;
reg                vwready_vn1_s1;
wire               varvalid_vn1_s1;
reg                varready_vn1_s1;
wire   [3:0]       varqv_vn1_s1;

wire               vawvalid_vn1_s2;
reg                vawready_vn1_s2;
wire   [3:0]       vawqv_vn1_s2;
wire               vwvalid_vn1_s2;
reg                vwready_vn1_s2;
wire               varvalid_vn1_s2;
reg                varready_vn1_s2;
wire   [3:0]       varqv_vn1_s2;

wire               vawvalid_vn1_s3;
reg                vawready_vn1_s3;
wire   [3:0]       vawqv_vn1_s3;
wire               vwvalid_vn1_s3;
reg                vwready_vn1_s3;
wire               varvalid_vn1_s3;
reg                varready_vn1_s3;
wire   [3:0]       varqv_vn1_s3;

wire               vawvalid_vn1_s4;
reg                vawready_vn1_s4;
wire   [3:0]       vawqv_vn1_s4;
wire               vwvalid_vn1_s4;
reg                vwready_vn1_s4;
wire               varvalid_vn1_s4;
reg                varready_vn1_s4;
wire   [3:0]       varqv_vn1_s4;

wire               vawvalid_vn1_s5;
reg                vawready_vn1_s5;
wire   [3:0]       vawqv_vn1_s5;
wire               vwvalid_vn1_s5;
reg                vwready_vn1_s5;
wire               varvalid_vn1_s5;
reg                varready_vn1_s5;
wire   [3:0]       varqv_vn1_s5;

wire               vawvalid_vn1_s6;
reg                vawready_vn1_s6;
wire   [3:0]       vawqv_vn1_s6;
wire               vwvalid_vn1_s6;
reg                vwready_vn1_s6;
wire               varvalid_vn1_s6;
reg                varready_vn1_s6;
wire   [3:0]       varqv_vn1_s6;

wire               vawvalid_vn1_s7;
reg                vawready_vn1_s7;
wire   [3:0]       vawqv_vn1_s7;
wire               vwvalid_vn1_s7;
reg                vwready_vn1_s7;
wire               varvalid_vn1_s7;
reg                varready_vn1_s7;
wire   [3:0]       varqv_vn1_s7;

wire               vawvalid_vn1_s8;
reg                vawready_vn1_s8;
wire   [3:0]       vawqv_vn1_s8;
wire               vwvalid_vn1_s8;
reg                vwready_vn1_s8;
wire               varvalid_vn1_s8;
reg                varready_vn1_s8;
wire   [3:0]       varqv_vn1_s8;

wire               vawvalid_vn1_s9;
reg                vawready_vn1_s9;
wire   [3:0]       vawqv_vn1_s9;
wire               vwvalid_vn1_s9;
reg                vwready_vn1_s9;
wire               varvalid_vn1_s9;
reg                varready_vn1_s9;
wire   [3:0]       varqv_vn1_s9;

wire               vawvalid_vn1_s10;
reg                vawready_vn1_s10;
wire   [3:0]       vawqv_vn1_s10;
wire               vwvalid_vn1_s10;
reg                vwready_vn1_s10;
wire               varvalid_vn1_s10;
reg                varready_vn1_s10;
wire   [3:0]       varqv_vn1_s10;

wire               vawvalid_vn1_s11;
reg                vawready_vn1_s11;
wire   [3:0]       vawqv_vn1_s11;
wire               vwvalid_vn1_s11;
reg                vwready_vn1_s11;
wire               varvalid_vn1_s11;
reg                varready_vn1_s11;
wire   [3:0]       varqv_vn1_s11;

//Virtual Network Token Control
wire               vawvalid_vn2_s0;
reg                vawready_vn2_s0;
wire   [3:0]       vawqv_vn2_s0;
wire               vwvalid_vn2_s0;
reg                vwready_vn2_s0;
wire               varvalid_vn2_s0;
reg                varready_vn2_s0;
wire   [3:0]       varqv_vn2_s0;

wire               vawvalid_vn2_s1;
reg                vawready_vn2_s1;
wire   [3:0]       vawqv_vn2_s1;
wire               vwvalid_vn2_s1;
reg                vwready_vn2_s1;
wire               varvalid_vn2_s1;
reg                varready_vn2_s1;
wire   [3:0]       varqv_vn2_s1;

wire               vawvalid_vn2_s2;
reg                vawready_vn2_s2;
wire   [3:0]       vawqv_vn2_s2;
wire               vwvalid_vn2_s2;
reg                vwready_vn2_s2;
wire               varvalid_vn2_s2;
reg                varready_vn2_s2;
wire   [3:0]       varqv_vn2_s2;

wire               vawvalid_vn2_s3;
reg                vawready_vn2_s3;
wire   [3:0]       vawqv_vn2_s3;
wire               vwvalid_vn2_s3;
reg                vwready_vn2_s3;
wire               varvalid_vn2_s3;
reg                varready_vn2_s3;
wire   [3:0]       varqv_vn2_s3;

wire               vawvalid_vn2_s4;
reg                vawready_vn2_s4;
wire   [3:0]       vawqv_vn2_s4;
wire               vwvalid_vn2_s4;
reg                vwready_vn2_s4;
wire               varvalid_vn2_s4;
reg                varready_vn2_s4;
wire   [3:0]       varqv_vn2_s4;

wire               vawvalid_vn2_s5;
reg                vawready_vn2_s5;
wire   [3:0]       vawqv_vn2_s5;
wire               vwvalid_vn2_s5;
reg                vwready_vn2_s5;
wire               varvalid_vn2_s5;
reg                varready_vn2_s5;
wire   [3:0]       varqv_vn2_s5;

wire               vawvalid_vn2_s6;
reg                vawready_vn2_s6;
wire   [3:0]       vawqv_vn2_s6;
wire               vwvalid_vn2_s6;
reg                vwready_vn2_s6;
wire               varvalid_vn2_s6;
reg                varready_vn2_s6;
wire   [3:0]       varqv_vn2_s6;

wire               vawvalid_vn2_s7;
reg                vawready_vn2_s7;
wire   [3:0]       vawqv_vn2_s7;
wire               vwvalid_vn2_s7;
reg                vwready_vn2_s7;
wire               varvalid_vn2_s7;
reg                varready_vn2_s7;
wire   [3:0]       varqv_vn2_s7;

wire               vawvalid_vn2_s8;
reg                vawready_vn2_s8;
wire   [3:0]       vawqv_vn2_s8;
wire               vwvalid_vn2_s8;
reg                vwready_vn2_s8;
wire               varvalid_vn2_s8;
reg                varready_vn2_s8;
wire   [3:0]       varqv_vn2_s8;

wire               vawvalid_vn2_s9;
reg                vawready_vn2_s9;
wire   [3:0]       vawqv_vn2_s9;
wire               vwvalid_vn2_s9;
reg                vwready_vn2_s9;
wire               varvalid_vn2_s9;
reg                varready_vn2_s9;
wire   [3:0]       varqv_vn2_s9;

wire               vawvalid_vn2_s10;
reg                vawready_vn2_s10;
wire   [3:0]       vawqv_vn2_s10;
wire               vwvalid_vn2_s10;
reg                vwready_vn2_s10;
wire               varvalid_vn2_s10;
reg                varready_vn2_s10;
wire   [3:0]       varqv_vn2_s10;

wire               vawvalid_vn2_s11;
reg                vawready_vn2_s11;
wire   [3:0]       vawqv_vn2_s11;
wire               vwvalid_vn2_s11;
reg                vwready_vn2_s11;
wire               varvalid_vn2_s11;
reg                varready_vn2_s11;
wire   [3:0]       varqv_vn2_s11;

//Virtual Network Token Control
wire               vawvalid_vn3_s0;
reg                vawready_vn3_s0;
wire   [3:0]       vawqv_vn3_s0;
wire               vwvalid_vn3_s0;
reg                vwready_vn3_s0;
wire               varvalid_vn3_s0;
reg                varready_vn3_s0;
wire   [3:0]       varqv_vn3_s0;

wire               vawvalid_vn3_s1;
reg                vawready_vn3_s1;
wire   [3:0]       vawqv_vn3_s1;
wire               vwvalid_vn3_s1;
reg                vwready_vn3_s1;
wire               varvalid_vn3_s1;
reg                varready_vn3_s1;
wire   [3:0]       varqv_vn3_s1;

wire               vawvalid_vn3_s2;
reg                vawready_vn3_s2;
wire   [3:0]       vawqv_vn3_s2;
wire               vwvalid_vn3_s2;
reg                vwready_vn3_s2;
wire               varvalid_vn3_s2;
reg                varready_vn3_s2;
wire   [3:0]       varqv_vn3_s2;

wire               vawvalid_vn3_s3;
reg                vawready_vn3_s3;
wire   [3:0]       vawqv_vn3_s3;
wire               vwvalid_vn3_s3;
reg                vwready_vn3_s3;
wire               varvalid_vn3_s3;
reg                varready_vn3_s3;
wire   [3:0]       varqv_vn3_s3;

wire               vawvalid_vn3_s4;
reg                vawready_vn3_s4;
wire   [3:0]       vawqv_vn3_s4;
wire               vwvalid_vn3_s4;
reg                vwready_vn3_s4;
wire               varvalid_vn3_s4;
reg                varready_vn3_s4;
wire   [3:0]       varqv_vn3_s4;

wire               vawvalid_vn3_s5;
reg                vawready_vn3_s5;
wire   [3:0]       vawqv_vn3_s5;
wire               vwvalid_vn3_s5;
reg                vwready_vn3_s5;
wire               varvalid_vn3_s5;
reg                varready_vn3_s5;
wire   [3:0]       varqv_vn3_s5;

wire               vawvalid_vn3_s6;
reg                vawready_vn3_s6;
wire   [3:0]       vawqv_vn3_s6;
wire               vwvalid_vn3_s6;
reg                vwready_vn3_s6;
wire               varvalid_vn3_s6;
reg                varready_vn3_s6;
wire   [3:0]       varqv_vn3_s6;

wire               vawvalid_vn3_s7;
reg                vawready_vn3_s7;
wire   [3:0]       vawqv_vn3_s7;
wire               vwvalid_vn3_s7;
reg                vwready_vn3_s7;
wire               varvalid_vn3_s7;
reg                varready_vn3_s7;
wire   [3:0]       varqv_vn3_s7;

wire               vawvalid_vn3_s8;
reg                vawready_vn3_s8;
wire   [3:0]       vawqv_vn3_s8;
wire               vwvalid_vn3_s8;
reg                vwready_vn3_s8;
wire               varvalid_vn3_s8;
reg                varready_vn3_s8;
wire   [3:0]       varqv_vn3_s8;

wire               vawvalid_vn3_s9;
reg                vawready_vn3_s9;
wire   [3:0]       vawqv_vn3_s9;
wire               vwvalid_vn3_s9;
reg                vwready_vn3_s9;
wire               varvalid_vn3_s9;
reg                varready_vn3_s9;
wire   [3:0]       varqv_vn3_s9;

wire               vawvalid_vn3_s10;
reg                vawready_vn3_s10;
wire   [3:0]       vawqv_vn3_s10;
wire               vwvalid_vn3_s10;
reg                vwready_vn3_s10;
wire               varvalid_vn3_s10;
reg                varready_vn3_s10;
wire   [3:0]       varqv_vn3_s10;

wire               vawvalid_vn3_s11;
reg                vawready_vn3_s11;
wire   [3:0]       vawqv_vn3_s11;
wire               vwvalid_vn3_s11;
reg                vwready_vn3_s11;
wire               varvalid_vn3_s11;
reg                varready_vn3_s11;
wire   [3:0]       varqv_vn3_s11;

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
  assign AWREGION_int = (regions_flag == 0) ? 4'b0000 : AWREGION;
  assign ARREGION_int = (regions_flag == 0) ? 4'b0000 : ARREGION;

  assign AWUSER_int = {AWUSER, AWVALID_val, AWQV, AWREGION_int};
  assign ARUSER_int = {ARUSER, ARVALID_val, ARQV, ARREGION_int};

  //Re-encode the valid signal
  //AW Channel
  always @(AWVALID)
    begin

      AWVALID_int = AWVALID >> 1;
      AWVALID_val = 8'b0;

      while (AWVALID_int != {VALID_WIDTH{1'b0}}) begin
          AWVALID_int = AWVALID_int >> 1;
          AWVALID_val = AWVALID_val + 1;
      end
    end

  //AR Channel
  always @(ARVALID)
    begin

     ARVALID_int = ARVALID >> 1;
     ARVALID_val = 8'b0;

     while (ARVALID_int != {VALID_WIDTH{1'b0}}) begin
          ARVALID_int = ARVALID_int >> 1;
          ARVALID_val = ARVALID_val + 1;
     end
  end

//------------------------------------------------------------------------------
// AXI Slave APB Checker
//------------------------------------------------------------------------------
  defparam uAxi4SlaveAPB.DATA_WIDTH = DATA_WIDTH;
  defparam uAxi4SlaveAPB.ID_WIDTH   = ID_WIDTH_I;
  defparam uAxi4SlaveAPB.EW_WIDTH   = EW_WIDTH;
  defparam uAxi4SlaveAPB.AWUSER_WIDTH = AWUSER_WIDTH_I + 16;
  defparam uAxi4SlaveAPB.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxi4SlaveAPB.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxi4SlaveAPB.ARUSER_WIDTH = ARUSER_WIDTH_I + 16;
  defparam uAxi4SlaveAPB.RUSER_WIDTH  = RUSER_WIDTH_I;


  Axi4SlaveAPB uAxi4SlaveAPB (

      .ACLK           (ACLK),
      .ARESETn        (ARESETn),

      .AWID           (AWID),
      .AWADDR         (AWADDR[31:0]),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        (AWCACHE),
      .AWPROT         (AWPROT),
      .AWUSER         (AWUSER_int),
      .AWVALID        (|AWVALID),
      .AWREADY        (AWREADY),

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

      .ARID           (ARID),
      .ARADDR         (ARADDR[31:0]),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        (ARCACHE),
      .ARPROT         (ARPROT),
      .ARUSER         (ARUSER_int),
      .ARVALID        (|ARVALID),
      .ARREADY        (ARREADY),

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
// Transaction Counters
//------------------------------------------------------------------------------
  //AR Channel

  assign next_out_reads = (|ARVALID & ARREADY & ~(RLAST_i & RVALID & RREADY)) ? out_reads + 7'b1 :
                          (RLAST_i & RVALID & RREADY & ~(|ARVALID & ARREADY)) ? out_reads - 7'b1 : out_reads;

  //AW Channel
  assign next_out_writes = (|AWVALID & AWREADY & ~(BVALID & BREADY)) ? out_writes + 7'b1 :
                           (BVALID & BREADY & ~(|AWVALID & AWREADY)) ? out_writes - 7'b1 : out_writes;

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
      .antecedent_expr  (AllowIllegalCache == 0 & (|ARVALID) & ~ARCACHE[1]),
      .consequent_expr  (ARCACHE[3:2] == 2'b00)
      );

  assert_implication #(1, 0,
    "AXI_ERRM_AWCACHE. When AWVALID is high, if AWCACHE[1] is low then AWCACHE[3] and AWCACHE[2] must also be low. Spec: table 5-1 on page 5-3."
  )  axi_errm_awcache
     (.clk              (ACLK),
      .reset_n          (ARESETn),
      .antecedent_expr  (AllowIllegalCache == 0 & (|AWVALID) & ~AWCACHE[1]),
      .consequent_expr  (AWCACHE[3:2] == 2'b00)
      );


  //------------------------------------------------------------------------
  // OVL_ASSERT: Only one AWValid bit should be high at time
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot #(0,VALID_WIDTH+1,0,"Only one AWValid bit should be high at a time")
  ovl_awvalid_one_hot
    (
     .clk       (ACLK),
     .reset_n   (PRESETn),
     .test_expr ({1'b0,AWVALID})
    );
   // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: Only one ARValid bit should be high at time
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot #(0,VALID_WIDTH+1,0,"Only one ARValid bit should be high at a time")
  ovl_arvalid_one_hot
    (
     .clk       (ACLK),
     .reset_n   (PRESETn),
     .test_expr ({1'b0,ARVALID})
    );
   // OVL_ASSERT_END

`endif //ARM_ASSERT_ON

initial
begin
// Virtual Network 0
   vawready_vn0_s0     = 1'b0;
   vwready_vn0_s0      = 1'b0;
   varready_vn0_s0     = 1'b0;

   vawready_vn0_s1     = 1'b0;
   vwready_vn0_s1      = 1'b0;
   varready_vn0_s1     = 1'b0;

   vawready_vn0_s2     = 1'b0;
   vwready_vn0_s2      = 1'b0;
   varready_vn0_s2     = 1'b0;

   vawready_vn0_s2     = 1'b0;
   vwready_vn0_s2      = 1'b0;
   varready_vn0_s2     = 1'b0;

   vawready_vn0_s3     = 1'b0;
   vwready_vn0_s3      = 1'b0;
   varready_vn0_s3     = 1'b0;

   vawready_vn0_s4     = 1'b0;
   vwready_vn0_s4      = 1'b0;
   varready_vn0_s4     = 1'b0;

   vawready_vn0_s5     = 1'b0;
   vwready_vn0_s5      = 1'b0;
   varready_vn0_s5     = 1'b0;

   vawready_vn0_s6     = 1'b0;
   vwready_vn0_s6      = 1'b0;
   varready_vn0_s6     = 1'b0;

   vawready_vn0_s7     = 1'b0;
   vwready_vn0_s7      = 1'b0;
   varready_vn0_s7     = 1'b0;

   vawready_vn0_s8     = 1'b0;
   vwready_vn0_s8      = 1'b0;
   varready_vn0_s8     = 1'b0;

   vawready_vn0_s9     = 1'b0;
   vwready_vn0_s9      = 1'b0;
   varready_vn0_s9     = 1'b0;

   vawready_vn0_s10    = 1'b0;
   vwready_vn0_s10     = 1'b0;
   varready_vn0_s10    = 1'b0;

   vawready_vn0_s11    = 1'b0;
   vwready_vn0_s11     = 1'b0;
   varready_vn0_s11    = 1'b0;

   // Virtual Network 1
   vawready_vn1_s0     = 1'b0;
   vwready_vn1_s0      = 1'b0;
   varready_vn1_s0     = 1'b0;

   vawready_vn1_s1     = 1'b0;
   vwready_vn1_s1      = 1'b0;
   varready_vn1_s1     = 1'b0;

   vawready_vn1_s2     = 1'b0;
   vwready_vn1_s2      = 1'b0;
   varready_vn1_s2     = 1'b0;

   vawready_vn1_s2     = 1'b0;
   vwready_vn1_s2      = 1'b0;
   varready_vn1_s2     = 1'b0;

   vawready_vn1_s3     = 1'b0;
   vwready_vn1_s3      = 1'b0;
   varready_vn1_s3     = 1'b0;

   vawready_vn1_s4     = 1'b0;
   vwready_vn1_s4      = 1'b0;
   varready_vn1_s4     = 1'b0;

   vawready_vn1_s5     = 1'b0;
   vwready_vn1_s5      = 1'b0;
   varready_vn1_s5     = 1'b0;

   vawready_vn1_s6     = 1'b0;
   vwready_vn1_s6      = 1'b0;
   varready_vn1_s6     = 1'b0;

   vawready_vn1_s7     = 1'b0;
   vwready_vn1_s7      = 1'b0;
   varready_vn1_s7     = 1'b0;

   vawready_vn1_s8     = 1'b0;
   vwready_vn1_s8      = 1'b0;
   varready_vn1_s8     = 1'b0;

   vawready_vn1_s9     = 1'b0;
   vwready_vn1_s9      = 1'b0;
   varready_vn1_s9     = 1'b0;

   vawready_vn1_s10    = 1'b0;
   vwready_vn1_s10     = 1'b0;
   varready_vn1_s10    = 1'b0;

   vawready_vn1_s11    = 1'b0;
   vwready_vn1_s11     = 1'b0;
   varready_vn1_s11    = 1'b0;

   // Virtual Network 2
   vawready_vn2_s0     = 1'b0;
   vwready_vn2_s0      = 1'b0;
   varready_vn2_s0     = 1'b0;

   vawready_vn2_s1     = 1'b0;
   vwready_vn2_s1      = 1'b0;
   varready_vn2_s1     = 1'b0;

   vawready_vn2_s2     = 1'b0;
   vwready_vn2_s2      = 1'b0;
   varready_vn2_s2     = 1'b0;

   vawready_vn2_s2     = 1'b0;
   vwready_vn2_s2      = 1'b0;
   varready_vn2_s2     = 1'b0;

   vawready_vn2_s3     = 1'b0;
   vwready_vn2_s3      = 1'b0;
   varready_vn2_s3     = 1'b0;

   vawready_vn2_s4     = 1'b0;
   vwready_vn2_s4      = 1'b0;
   varready_vn2_s4     = 1'b0;

   vawready_vn2_s5     = 1'b0;
   vwready_vn2_s5      = 1'b0;
   varready_vn2_s5     = 1'b0;

   vawready_vn2_s6     = 1'b0;
   vwready_vn2_s6      = 1'b0;
   varready_vn2_s6     = 1'b0;

   vawready_vn2_s7     = 1'b0;
   vwready_vn2_s7      = 1'b0;
   varready_vn2_s7     = 1'b0;

   vawready_vn2_s8     = 1'b0;
   vwready_vn2_s8      = 1'b0;
   varready_vn2_s8     = 1'b0;

   vawready_vn2_s9     = 1'b0;
   vwready_vn2_s9      = 1'b0;
   varready_vn2_s9     = 1'b0;

   vawready_vn2_s10    = 1'b0;
   vwready_vn2_s10     = 1'b0;
   varready_vn2_s10    = 1'b0;

   vawready_vn2_s11    = 1'b0;
   vwready_vn2_s11     = 1'b0;
   varready_vn2_s11    = 1'b0;

   // Virtual Network 3
   vawready_vn3_s0     = 1'b0;
   vwready_vn3_s0      = 1'b0;
   varready_vn3_s0     = 1'b0;

   vawready_vn3_s1     = 1'b0;
   vwready_vn3_s1      = 1'b0;
   varready_vn3_s1     = 1'b0;

   vawready_vn3_s2     = 1'b0;
   vwready_vn3_s2      = 1'b0;
   varready_vn3_s2     = 1'b0;

   vawready_vn3_s2     = 1'b0;
   vwready_vn3_s2      = 1'b0;
   varready_vn3_s2     = 1'b0;

   vawready_vn3_s3     = 1'b0;
   vwready_vn3_s3      = 1'b0;
   varready_vn3_s3     = 1'b0;

   vawready_vn3_s4     = 1'b0;
   vwready_vn3_s4      = 1'b0;
   varready_vn3_s4     = 1'b0;

   vawready_vn3_s5     = 1'b0;
   vwready_vn3_s5      = 1'b0;
   varready_vn3_s5     = 1'b0;

   vawready_vn3_s6     = 1'b0;
   vwready_vn3_s6      = 1'b0;
   varready_vn3_s6     = 1'b0;

   vawready_vn3_s7     = 1'b0;
   vwready_vn3_s7      = 1'b0;
   varready_vn3_s7     = 1'b0;

   vawready_vn3_s8     = 1'b0;
   vwready_vn3_s8      = 1'b0;
   varready_vn3_s8     = 1'b0;

   vawready_vn3_s9     = 1'b0;
   vwready_vn3_s9      = 1'b0;
   varready_vn3_s9     = 1'b0;

   vawready_vn3_s10    = 1'b0;
   vwready_vn3_s10     = 1'b0;
   varready_vn3_s10    = 1'b0;

   vawready_vn3_s11    = 1'b0;
   vwready_vn3_s11     = 1'b0;
   varready_vn3_s11    = 1'b0;

end

endmodule

//  --=============================== End ====================================--

