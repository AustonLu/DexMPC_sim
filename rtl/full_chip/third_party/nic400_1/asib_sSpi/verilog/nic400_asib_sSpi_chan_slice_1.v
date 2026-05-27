//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 126102
// File Date           :  2012-02-29 17:39:07 +0000 (Wed, 29 Feb 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose             : HDL design file to register an
//                       AXI channel
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                               nic400_asib_sSpi_chan_slice.v
//                               =========================
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The Channel Slice component is a generic channel register slice that
// can be used for the write or read address channels. The register slice uses
// three generic components:
//    1. ful_regd_slice
//    2. fwd_regd_slice
//    2. rev_regd_slice
//
//   The ful_regd_slice is a generic component that provides full timing
// isolation between the source and destination interfaces which can be reused
// for any AXI channel.
//   The fwd_regd_slice is a generic component that provides forward-path timing
// isolation between the source and destination which can be reused
// for any AXI channel.
//   The rev_regd_slice is a generic component that provides reverse-path timing
// isolation between the source and destination which can be reused
// for any AXI channel.
//
// The unused instances are optimised-out during synthesis.
//
//------------------------------------------------------------------------------


`include "nic400_asib_sSpi_defs_1.v"

module nic400_asib_sSpi_chan_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port interface
   src_data,
   src_valid,
   src_ready,

   // master port interface
   dst_data,
   dst_valid,
   dst_ready
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user parameters
  parameter HNDSHK_MODE = `RS_REV_REG;     // register slice handshake mode
  parameter PAYLD_WIDTH = 12;
  
  // calculated parameters (do not modify)
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
  input                 aresetn;          // AXI reset
  input                 aclk;             // AXI clock

  input  [PAYLD_MAX:0]  src_data;         // Input payload
  output [PAYLD_MAX:0]  dst_data;         // Output payload


  // AXI muxed address input port
  input                 src_valid;        // Address/Control valid handshake
  output                src_ready;        // Address/Control ready handshake

  // AXI registered address output port
  output                dst_valid;        // Address/Control valid handshake
  input                 dst_ready;        // Address/Control ready handshake


  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire [PAYLD_MAX:0]    payld_src;       // concatenation of the inputs
  wire [PAYLD_MAX:0]    payld_regd;      // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_fwd_regd;  // concatenation of the registered inputs
  wire [PAYLD_MAX:0]    payld_rev_regd;  // concatenation of the registered inputs
  wire                  valid_regd;      // valid from the fully isolated slice
  wire                  valid_fwd_regd;  // valid from the fwd path isolated slice
  wire                  valid_rev_regd;  // valid from the rev path isolated slice
  wire                  ready_regd;      // ready from the fully isolated slice
  wire                  ready_fwd_regd;  // ready from the fwd path isolated slice
  wire                  ready_rev_regd;  // ready from the rev path isolated slice

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // output src_ready;
  // ---------------------------------------------------------------------------
  // selection of the ready as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the dest input.
  assign src_ready = ((INT_HNDSHK_MODE == `RS_REGD)         ? ready_regd
                       :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? ready_fwd_regd
                         :((INT_HNDSHK_MODE == `RS_REV_REG) ? ready_rev_regd
                           : dst_ready)));

  // ---------------------------------------------------------------------------
  // Master port outputs
  // ---------------------------------------------------------------------------
  // expand the concatenated registered values to the master port outputs
  // as required by the static mode parameter. If the mode parameter is
  // out of bounds the outputs are tied to the source inputs.
  assign dst_data = ((INT_HNDSHK_MODE == `RS_REGD)         ? payld_regd
                      :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? payld_fwd_regd
                        :((INT_HNDSHK_MODE == `RS_REV_REG) ? payld_rev_regd
                          : src_data)));

  // ---------------------------------------------------------------------------
  // output dst_valid;
  // ---------------------------------------------------------------------------
  // selection of the valid as required by the static mode parameter. If the
  // mode parameter is out of bounds the output are tied to the source input.
  assign dst_valid = ((INT_HNDSHK_MODE == `RS_REGD)         ? valid_regd
                       :((INT_HNDSHK_MODE == `RS_FWD_REG)   ? valid_fwd_regd
                         :((INT_HNDSHK_MODE == `RS_REV_REG) ? valid_rev_regd
                           : src_valid)));

  // ---------------------------------------------------------------------------
  // wire [PAYLD_MAX:0] payld_src;
  // ---------------------------------------------------------------------------
  // the inputs are concatenated to interface to the generic register set
  assign payld_src = src_data;

  // ---------------------------------------------------------------------------
  //  Full Timing Isolation Register Slice
  // ---------------------------------------------------------------------------
  nic400_ful_regd_slice_1 #(PAYLD_WIDTH) u_ful_regd_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // inputs
     .valid_src       (src_valid),
     .ready_dst       (dst_ready),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ready_regd),
     .valid_dst       (valid_regd),
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
     .valid_src       (src_valid),
     .ready_dst       (dst_ready),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ready_fwd_regd),
     .valid_dst       (valid_fwd_regd),
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
     .valid_src       (src_valid),
     .ready_dst       (dst_ready),
     .payload_src     (payld_src),

     // outputs
     .ready_src       (ready_rev_regd),
     .valid_dst       (valid_rev_regd),
     .payload_dst     (payld_rev_regd)
     );

  // ---------------------------------------------------------------------------
  
  
  //  ==========================================================================
  //  OVL Assertions
  //  ==========================================================================
`ifdef ARM_ASSERT_ON

  wire [1:0]            hndshk_mode_w;     // hnkshk mode

  // ---------------------------------------------------------------------------
  // Hndshk mode;
  // ---------------------------------------------------------------------------
  assign hndshk_mode_w = INT_HNDSHK_MODE;

  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of reg_slice HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_aw_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((hndshk_mode_w == `RS_REGD         ) |
                    (hndshk_mode_w == `RS_FWD_REG      ) |
                    (hndshk_mode_w == `RS_REV_REG      ) |
                    (hndshk_mode_w == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

`endif

endmodule

`include "nic400_asib_sSpi_undefs_1.v"

// ----------------------------------- End -------------------------------------

