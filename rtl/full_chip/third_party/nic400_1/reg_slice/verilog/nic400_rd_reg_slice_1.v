//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2012-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 150000
// File Date           :  2013-05-09 16:07:32 +0100 (Thu, 09 May 2013)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : 
//                                rd_reg_slice.v
//                               ==============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The rd_reg_slice component is a read channel register slice. The register
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

module nic400_rd_reg_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port interface
   rids,
   rdatas,
   rresps,
   rusers,
   rlasts,
   rvalids,
   rreadys,

   // master port interface
   ridm,
   rdatam,
   rrespm,
   ruserm,
   rlastm,
   rvalidm,
   rreadym
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user defined parameters
  parameter ID_WIDTH    = 4;            // width of the id field
  parameter DATA_WIDTH  = 64;           // width of the data field
  parameter USER_WIDTH  = 32;           // width of the user sideband field
  parameter HNDSHK_MODE = `RS_REGD;     // register slice handshake mode

  // calculated parameters
  parameter ID_MAX      = (ID_WIDTH - 1);
  parameter DATA_MAX    = (DATA_WIDTH - 1);
  parameter USER_MAX    = (USER_WIDTH - 1);
  parameter PAYLD_WIDTH = (ID_WIDTH + DATA_WIDTH + USER_WIDTH + 3);
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
  output [ID_MAX:0]     rids;             // id field
  output [DATA_MAX:0]   rdatas;           // data field
  output [1:0]          rresps;           // response field
  output [USER_MAX:0]   rusers;           // user field
  output                rlasts;           // last field
  output                rvalids;          // transfer valid
  input                 rreadys;          // ready for transfer

  // master port interface
  input [ID_MAX:0]      ridm;             // id field
  input [DATA_MAX:0]    rdatam;           // data field
  input [1:0]           rrespm;           // response field
  input [USER_MAX:0]    ruserm;           // user field
  input                 rlastm;           // last field
  input                 rvalidm;          // transfer valid
  output                rreadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  wire                  aresetn;          // axi reset
  wire                  aclk;             // axi clock

  // slave port interface
  wire [ID_MAX:0]       rids;             // id field
  wire [DATA_MAX:0]     rdatas;           // data field
  wire [1:0]            rresps;           // response field
  wire [USER_MAX:0]     rusers;           // user field
  wire                  rlasts;           // last field
  wire                  rvalids;          // transfer valid
  wire                  rreadys;          // ready for transfer

  // master port interface
  wire [ID_MAX:0]       ridm;             // id field
  wire [DATA_MAX:0]     rdatam;           // data field
  wire [1:0]            rrespm;           // response field
  wire [USER_MAX:0]     ruserm;           // user field
  wire                  rlastm;           // last field
  wire                  rvalidm;          // transfer valid
  wire                  rreadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire [PAYLD_MAX:0]    payld_src;      // concatenation of the inputs
  wire [PAYLD_MAX:0]    payld_regd;     // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_fwd_regd;  // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_rev_regd;  // concatenation of the registered inputs
  wire                  rvalid_regd;    // valid from the fully isolated slice
  wire                  rvalid_fwd_regd; // valid from the fwd path isolated slice
  wire                  rvalid_rev_regd; // valid from the rev path isolated slice
  wire                  rready_regd;    // ready from the fully isolated slice
  wire                  rready_fwd_regd; // ready from the fwd path isolated slice
  wire                  rready_rev_regd; // ready from the rev path isolated slice

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // output rvalids;
  // ---------------------------------------------------------------------------
  // selection of the valid as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the source input.
  assign rvalids = ((INT_HNDSHK_MODE == `RS_REGD)        ? rvalid_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? rvalid_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? rvalid_rev_regd
                        : rvalidm)));

  // ---------------------------------------------------------------------------
  // slave port outputs
  // ---------------------------------------------------------------------------
  // expand the concatenated registered values to the master port outputs
  // a required by the select signal
  assign {rids,
          rdatas,
          rresps,
          rusers,
          rlasts} = ((INT_HNDSHK_MODE == `RS_REGD)        ? payld_regd
                     :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? payld_fwd_regd
                       :((INT_HNDSHK_MODE == `RS_REV_REG) ? payld_rev_regd
                         : {ridm,
                            rdatam,
                            rrespm,
                            ruserm,
                            rlastm})));

  // ---------------------------------------------------------------------------
  // output rreadym;
  // ---------------------------------------------------------------------------
  // selection of the ready as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the src input.
  assign rreadym = ((INT_HNDSHK_MODE == `RS_REGD)        ? rready_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? rready_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? rready_rev_regd
                        : rreadys)));

  // ---------------------------------------------------------------------------
  // wire [PAYLD_MAX:0] payload_src;
  // ---------------------------------------------------------------------------
  // the inputs are concatenated to interface to the generic register set
  assign payld_src = {ridm,
                     rdatam,
                     rrespm,
                     ruserm,
                     rlastm};

  // ---------------------------------------------------------------------------
  //  Full Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_ful_regd_slice_1 #(PAYLD_WIDTH) u_ful_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (rvalidm),
     .ready_dst       (rreadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (rready_regd),
     .valid_dst       (rvalid_regd),
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
     .valid_src       (rvalidm),
     .ready_dst       (rreadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (rready_fwd_regd),
     .valid_dst       (rvalid_fwd_regd),
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
     .valid_src       (rvalidm),
     .ready_dst       (rreadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (rready_rev_regd),
     .valid_dst       (rvalid_rev_regd),
     .payload_dst     (payld_rev_regd)
     );

  // ---------------------------------------------------------------------------
endmodule

`include "reg_slice_axi_undefs.v"

// ----------------------------------- End -------------------------------------

