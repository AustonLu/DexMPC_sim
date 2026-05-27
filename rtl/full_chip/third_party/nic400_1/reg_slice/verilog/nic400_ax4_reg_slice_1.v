//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2004-2013 ARM Limited.
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
// Purpose             : HDL design file to register an AXI address channel
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//
//                                ax4_reg_slice.v
//                               ==============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The ax4_reg_slice component is a generic address channel register slice that
// can be used for the write or read address channels. The register slice uses
// three generic components:
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

module nic400_ax4_reg_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port interface
   axids,
   axaddrs,
   axlens,
   axsizes,
   axbursts,
   axlocks,
   axcaches,
   axprots,
   axusers,
   axvalids,
   axreadys,

   // master port interface
   axidm,
   axaddrm,
   axlenm,
   axsizem,
   axburstm,
   axlockm,
   axcachem,
   axprotm,
   axuserm,
   axvalidm,
   axreadym
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user parameters
  parameter ID_WIDTH = 4;               // width of the id field
  parameter USER_WIDTH = 32;            // width of the user sideband field
  parameter HNDSHK_MODE = `RS_REGD;     // register slice handshake mode
  parameter ADDR_WIDTH  = 32;           // width of the address field
   
  // calculated parameters (do not modify)
  parameter ID_MAX      = (ID_WIDTH - 1);
  parameter USER_MAX    = (USER_WIDTH-1);
  parameter PAYLD_WIDTH = (ID_WIDTH + USER_WIDTH + ADDR_WIDTH + 21);
  parameter PAYLD_MAX   = (PAYLD_WIDTH - 1);
  parameter ADDR_MAX    = (ADDR_WIDTH - 1);
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
  input [ID_MAX:0]      axids;            // id field
  input [ADDR_MAX:0]    axaddrs;          // address field
  input [7:0]           axlens;           // length field
  input [2:0]           axsizes;          // size field
  input [1:0]           axbursts;         // burst field
  input                 axlocks;          // lock field
  input [3:0]           axcaches;         // cache field
  input [2:0]           axprots;          // protection field
  input [USER_MAX:0]    axusers;          // user field
  input                 axvalids;         // transfer valid
  output                axreadys;         // ready for transfer

  // master port interface
  output [ID_MAX:0]     axidm;            // id field
  output [ADDR_MAX:0]   axaddrm;          // address field
  output [7:0]          axlenm;           // length field
  output [2:0]          axsizem;          // size field
  output [1:0]          axburstm;         // burst field
  output                axlockm;          // lock field
  output [3:0]          axcachem;         // cache field
  output [2:0]          axprotm;          // protection field
  output [USER_MAX:0]   axuserm;          // user field
  output                axvalidm;         // transfer valid
  input                 axreadym;         // ready for transfer

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  wire                  aresetn;          // axi reset
  wire                  aclk;             // axi clock

  // slave port interface
  wire [ID_MAX:0]       axids;            // id field
  wire [ADDR_MAX:0]     axaddrs;          // address field
  wire [7:0]            axlens;           // length field
  wire [2:0]            axsizes;          // size field
  wire [1:0]            axbursts;         // burst field
  wire                  axlocks;          // lock field
  wire [3:0]            axcaches;         // cache field
  wire [2:0]            axprots;          // protection field
  wire [USER_MAX:0]     axusers;          // user field
  wire                  axvalids;         // transfer valid
  wire                  axreadys;         // ready for transfer

  // master port interface
  wire [ID_MAX:0]       axidm;            // id field
  wire [ADDR_MAX:0]     axaddrm;          // address field
  wire [7:0]            axlenm;           // length field
  wire [2:0]            axsizem;          // size field
  wire [1:0]            axburstm;         // burst field
  wire                  axlockm;          // lock field
  wire [3:0]            axcachem;         // cache field
  wire [2:0]            axprotm;          // protection field
  wire [USER_MAX:0]     axuserm;          // user field
  wire                  axvalidm;         // transfer valid
  wire                  axreadym;         // ready for transfer

  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire [PAYLD_MAX:0]    payld_src;      // concatenation of the inputs
  wire [PAYLD_MAX:0]    payld_regd;     // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_fwd_regd;  // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_rev_regd;  // concatenation of the registered inputs
  wire                  ax_valid_regd;   // valid from the fully isolated slice
  wire                  ax_valid_fwd_regd;// valid from the fwd path isolated slice
  wire                  ax_valid_rev_regd;// valid from the rev path isolated slice
  wire                  ax_ready_regd;   // ready from the fully isolated slice
  wire                  ax_ready_fwd_regd;// ready from the fwd path isolated slice
  wire                  ax_ready_rev_regd;// ready from the rev path isolated slice

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // output axreadys;
  // ---------------------------------------------------------------------------
  // selection of the ready as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the dest input.
  assign axreadys = ((INT_HNDSHK_MODE == `RS_REGD)        ? ax_ready_regd
                     :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? ax_ready_fwd_regd
                       :((INT_HNDSHK_MODE == `RS_REV_REG) ? ax_ready_rev_regd
                         : axreadym)));

  // ---------------------------------------------------------------------------
  // Master port outputs
  // ---------------------------------------------------------------------------
  // expand the concatenated registered values to the master port outputs
  // as required by the static mode parameter. If the mode parameter is
  // out of bounds the outputs are tied to the source inputs.
  assign {axidm,
          axaddrm,
          axlenm,
          axsizem,
          axburstm,
          axlockm,
          axcachem,
          axprotm,
          axuserm} = ((INT_HNDSHK_MODE == `RS_REGD)        ? payld_regd
                      :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? payld_fwd_regd
                        :((INT_HNDSHK_MODE == `RS_REV_REG) ? payld_rev_regd
                          : {axids,
                             axaddrs,
                             axlens,
                             axsizes,
                             axbursts,
                             axlocks,
                             axcaches,
                             axprots,
                             axusers})));

  // ---------------------------------------------------------------------------
  // output axvalidm;
  // ---------------------------------------------------------------------------
  // selection of the valid as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the source input.
  assign axvalidm = ((INT_HNDSHK_MODE == `RS_REGD)        ? ax_valid_regd
                     :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? ax_valid_fwd_regd
                       :((INT_HNDSHK_MODE == `RS_REV_REG) ? ax_valid_rev_regd
                         : axvalids)));

  // ---------------------------------------------------------------------------
  // wire [PAYLD_MAX:0] payld_src;
  // ---------------------------------------------------------------------------
  // the inputs are concatenated to interface to the generic register set
  assign payld_src = {axids,
                     axaddrs,
                     axlens,
                     axsizes,
                     axbursts,
                     axlocks,
                     axcaches,
                     axprots,
                     axusers};

  // ---------------------------------------------------------------------------
  //  Full Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_ful_regd_slice_1 #(PAYLD_WIDTH) u_ful_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (axvalids),
     .ready_dst       (axreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ax_ready_regd),
     .valid_dst       (ax_valid_regd),
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
     .valid_src       (axvalids),
     .ready_dst       (axreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ax_ready_fwd_regd),
     .valid_dst       (ax_valid_fwd_regd),
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
     .valid_src       (axvalids),
     .ready_dst       (axreadym),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ax_ready_rev_regd),
     .valid_dst       (ax_valid_rev_regd),
     .payload_dst     (payld_rev_regd)
     );

  // ---------------------------------------------------------------------------
endmodule

`include "reg_slice_axi_undefs.v"

// ----------------------------------- End -------------------------------------

