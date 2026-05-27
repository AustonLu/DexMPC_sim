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
//                                buf_reg_slice.v
//                               ===============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The buf_reg_slice component is a write response channel register slice.
// The register slice uses two generic components:
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

module nic400_buf_reg_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port interface
   bids,
   bresps,
   busers,
   bvalids,
   breadys,

   // master port interface
   bidm,
   brespm,
   buserm,
   bvalidm,
   breadym
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user defined parameters
  parameter ID_WIDTH    = 4;            // width of the id field
  parameter USER_WIDTH  = 32;           // width of the user sideband field
  parameter HNDSHK_MODE = `RS_REGD;     // register slice handshake mode

  // calculated parameters (do not modify)
  parameter ID_MAX      = (ID_WIDTH - 1);
  parameter USER_MAX    = (USER_WIDTH - 1);
  parameter PAYLD_WIDTH = (ID_WIDTH + USER_WIDTH + 2);
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
  output [ID_MAX:0]     bids;             // id field
  output [1:0]          bresps;           // response field
  output [USER_MAX:0]   busers;           // user field
  output                bvalids;          // transfer valid
  input                 breadys;          // ready for transfer

  // master port interface
  input [ID_MAX:0]      bidm;             // id field
  input [1:0]           brespm;           // response field
  input [USER_MAX:0]    buserm;           // user field
  input                 bvalidm;          // transfer valid
  output                breadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  wire                  aresetn;          // axi reset
  wire                  aclk;             // axi clock

  // slave port interface
  wire [ID_MAX:0]       bids;             // id field
  wire [1:0]            bresps;           // response field
  wire [USER_MAX:0]     busers;           // user field
  wire                  bvalids;          // transfer valid
  wire                  breadys;          // ready for transfer

  // master port interface
  wire [ID_MAX:0]       bidm;             // id field
  wire [1:0]            brespm;           // response field
  wire [USER_MAX:0]     buserm;           // user field
  wire                  bvalidm;          // transfer valid
  wire                  breadym;          // ready for transfer

  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire [PAYLD_MAX:0]    payld_src;      // concatenation of the inputs
  wire [PAYLD_MAX:0]    payld_regd;     // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_fwd_regd;  // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_rev_regd;  // concatenation of the registered inputs
  wire                  bvalid_regd;    // valid from the fully isolated slice
  wire                  bvalid_fwd_regd; // valid from the fwd path isolated slice
  wire                  bvalid_rev_regd; // valid from the rev path isolated slice
  wire                  bready_regd;    // ready from the fully isolated slice
  wire                  bready_fwd_regd; // ready from the fwd path isolated slice
  wire                  bready_rev_regd; // ready from the rev path isolated slice

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // output bvalids;
  // ---------------------------------------------------------------------------
  // selection of the valid as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the source input.
  assign bvalids = ((INT_HNDSHK_MODE == `RS_REGD)        ? bvalid_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? bvalid_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? bvalid_rev_regd
                        : bvalidm)));

  // ---------------------------------------------------------------------------
  // slave port outputs
  // ---------------------------------------------------------------------------
  // expand the concatenated registered values to the slave port outputs
  // as required by the static mode parameter. If the mode parameter is
  // out of bounds the outputs are tied to the master inputs.
  assign {bids,
          bresps,
          busers} = ((INT_HNDSHK_MODE == `RS_REGD)        ? payld_regd
                     :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? payld_fwd_regd
                       :((INT_HNDSHK_MODE == `RS_REV_REG) ? payld_rev_regd
                         : {bidm,
                            brespm,
                            buserm})));

  // ---------------------------------------------------------------------------
  // output breadym;
  // ---------------------------------------------------------------------------
  // selection of the ready as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the src input.
  assign breadym = ((INT_HNDSHK_MODE == `RS_REGD)        ? bready_regd
                    :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? bready_fwd_regd
                      :((INT_HNDSHK_MODE == `RS_REV_REG) ? bready_rev_regd
                        : breadys)));

  // ---------------------------------------------------------------------------
  // wire [PAYLD_MAX:0] payld_src;
  // ---------------------------------------------------------------------------
  // the inputs are concatenated to interface to the generic register set
  assign payld_src = {bidm,
                     brespm,
                     buserm};

  // ---------------------------------------------------------------------------
  //  Full Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_ful_regd_slice_1 #(PAYLD_WIDTH) u_ful_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (bvalidm),
     .ready_dst       (breadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (bready_regd),
     .valid_dst       (bvalid_regd),
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
     .valid_src       (bvalidm),
     .ready_dst       (breadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (bready_fwd_regd),
     .valid_dst       (bvalid_fwd_regd),
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
     .valid_src       (bvalidm),
     .ready_dst       (breadys),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (bready_rev_regd),
     .valid_dst       (bvalid_rev_regd),
     .payload_dst     (payld_rev_regd)
     );

  // ---------------------------------------------------------------------------
endmodule

`include "reg_slice_axi_undefs.v"

// ----------------------------------- End -------------------------------------

