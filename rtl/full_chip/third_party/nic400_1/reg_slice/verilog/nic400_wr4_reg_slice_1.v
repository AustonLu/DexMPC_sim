//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2004-2011 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 104935
// File Date           :  2011-02-18 22:05:24 +0000 (Fri, 18 Feb 2011)
//
// Release Information : PL401-r1p2-00rel0
//-----------------------------------------------------------------------------
// Purpose             : HDL design file to register the
//                       AXI write channel.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                                wr_reg_slice.v
//                               ==============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The wr_reg_slice component is a write channel register slice. The register
// slice uses three generic components:
//    1. ful_regd_slice
//    2. fwd_regd_slice
//    2. rev_regd_slice
//
//   The ful_regd_slice is a generic component that provides full timing
// isolation between the source and destination interfaces which can be reused
// for any axi channel.
//   The fwd_regd_slice is a generic component that provides forward-path timing
// isolation between the source and destination which can be reused
// for any axi channel.
//   The rev_regd_slice is a generic component that provides reverse-path timing
// isolation between the source and destination which can be reused
// for any axi channel.
//
// The unused instances are optimised-out during synthesis.
//
//------------------------------------------------------------------------------


`include "reg_slice_axi_defs.v"

module nic400_wr4_reg_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port interface
   wdatas,
   wstrbs,
   wusers,
   wlasts,
   wvalids,
   wreadys,

   // master port interface
   wdatam,
   wstrbm,
   wuserm,
   wlastm,
   wvalidm,
   wreadym
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user defined parameters
  parameter DATA_WIDTH  = 64;           // width of the data field
  parameter USER_WIDTH  = 32;           // width of the user sideband field
  parameter HNDSHK_MODE = `RS_REGD;     // register slice handshake mode

  // calculated parameters
  parameter DATA_MAX      = (DATA_WIDTH - 1);
  parameter STRB_WIDTH    = (DATA_WIDTH / 8);
  parameter STRB_MAX      = (STRB_WIDTH - 1);
  parameter USER_MAX      = (USER_WIDTH - 1);
  parameter PAYLD_WIDTH = (DATA_WIDTH + STRB_WIDTH + USER_WIDTH + 1);
  parameter PAYLD_MAX   = (PAYLD_WIDTH - 1);
`ifdef ARM_ASSERT_ON
 // Assign a wire to select mode of operation to improve verification
  wire [1:0] INT_HNDSHK_MODE = HNDSHK_MODE; // Wire register slice handshake mode
`else
 // Assign a parameter to select mode of operation to ease synthesis optimisation
  parameter  INT_HNDSHK_MODE = HNDSHK_MODE; // Internal register slice handshake mode
`endif

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  input                 aresetn;          // axi reset
  input                 aclk;             // axi clock

  // slave port interface
  input [DATA_MAX:0]    wdatas;           // data field
  input [STRB_MAX:0]    wstrbs;           // strobe field
  input [USER_MAX:0]    wusers;           // user field
  input                 wlasts;           // last field
  input                 wvalids;          // transfer valid
  output                wreadys;          // ready for transfer

  // master port interface
  output [DATA_MAX:0]   wdatam;           // data field
  output [STRB_MAX:0]   wstrbm;           // strobe field
  output [USER_MAX:0]   wuserm;           // user field
  output                wlastm;           // last field
  output                wvalidm;          // transfer valid
  input                 wreadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  wire                  aresetn;          // axi reset
  wire                  aclk;             // axi clock

  // slave port interface
  wire [DATA_MAX:0]     wdatas;           // data field
  wire [STRB_MAX:0]     wstrbs;           // strobe field
  wire [USER_MAX:0]     wusers;           // user field
  wire                  wlasts;           // last field
  wire                  wvalids;          // transfer valid
  wire                  wreadys;          // ready for transfer

  // master port interface
  wire [DATA_MAX:0]     wdatam;           // data field
  wire [STRB_MAX:0]     wstrbm;           // strobe field
  wire [USER_MAX:0]     wuserm;           // user field
  wire                  wlastm;           // last field
  wire                  wvalidm;          // transfer valid
  wire                  wreadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire [PAYLD_MAX:0]    payld_src;      // concatenation of the inputs
  wire [PAYLD_MAX:0]    payld_regd;     // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_fwd_regd;  // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_rev_regd;  // concatenation of the registered inputs
  wire                  wvalid_regd;    // valid from the fully isolated slice
  wire                  wvalid_fwd_regd; // valid from the fwd path isolated slice
  wire                  wvalid_rev_regd; // valid from the rev path isolated slice
  wire                  wready_regd;    // ready from the fully isolated slice
  wire                  wready_fwd_regd; // ready from the fwd path isolated slice
  wire                  wready_rev_regd; // ready from the rev path isolated slice

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // output wreadys;
  // ---------------------------------------------------------------------------
  // selection of the ready as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the dest input.
  assign wreadys = ((INT_HNDSHK_MODE == `RS_REGD)        ? wready_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? wready_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? wready_rev_regd
                        : wreadym)));

  // ---------------------------------------------------------------------------
  // Master port outputs
  // ---------------------------------------------------------------------------
  // expand the concatenated registered values to the master port outputs
  // a required by the select signal
  assign {wdatam,
          wstrbm,
          wuserm,
          wlastm} = ((INT_HNDSHK_MODE == `RS_REGD)        ? payld_regd
                     :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? payld_fwd_regd
                       :((INT_HNDSHK_MODE == `RS_REV_REG) ? payld_rev_regd
                         : {wdatas,
                            wstrbs,
                            wusers,
                            wlasts})));

  // ---------------------------------------------------------------------------
  // output wvalidm;
  // ---------------------------------------------------------------------------
  // selection of the valid as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the source input.
  assign wvalidm = ((INT_HNDSHK_MODE == `RS_REGD)        ? wvalid_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? wvalid_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? wvalid_rev_regd
                        : wvalids)));

  // ---------------------------------------------------------------------------
  // wire [PAYLD_MAX:0] payld_src;
  // ---------------------------------------------------------------------------
  // the inputs are concatenated to interface to the generic register set
  assign payld_src = {wdatas,
                     wstrbs,
                     wusers,
                     wlasts};

  // ---------------------------------------------------------------------------
  //  Full Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_ful_regd_slice_1 #(PAYLD_WIDTH) u_ful_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (wvalids),
     .ready_dst       (wreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (wready_regd),
     .valid_dst       (wvalid_regd),
     .payload_dst     (payld_regd)
     );

  // ---------------------------------------------------------------------------
  //  Forward Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_fwd_regd_slice_1 #(PAYLD_WIDTH) u_fwd_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (wvalids),
     .ready_dst       (wreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (wready_fwd_regd),
     .valid_dst       (wvalid_fwd_regd),
     .payload_dst     (payld_fwd_regd)
     );

  // ---------------------------------------------------------------------------
  //  Reverse Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_rev_regd_slice_1 #(PAYLD_WIDTH) u_rev_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (wvalids),
     .ready_dst       (wreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (wready_rev_regd),
     .valid_dst       (wvalid_rev_regd),
     .payload_dst     (payld_rev_regd)
     );

  // ---------------------------------------------------------------------------
endmodule

`include "reg_slice_axi_undefs.v"

// ----------------------------------- End -------------------------------------

