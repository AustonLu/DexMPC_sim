//-----------------------------------------------------------------------------
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
//
//  Version and Release Control Information:
//
//  File Revision       : 150000
//  File Date           :  2013-05-09 16:07:32 +0100 (Thu, 09 May 2013)
//
//  Release Information : PL401-r1p2-00rel0
//-----------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                              fwd_regd_slice.v
//                             ================
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The fwd_regd_slice is a sub-component of the reg_slice_axi that provides 
// forward-path timing isolation between the source and destination 
// interfaces.
//
//   The fwd_regd_slice monitors and drives the handshake signals from/to
// the master and slave interfaces. The component instantiates one storage
// register and ensures a minimum latency of 1 and back to back transfer
// support by using a combinatorial path from ready_dst to ready_src.
//
// A single variable size signal array is used to enable reuse over all AXI
// channels.
//
//------------------------------------------------------------------------------


module nic400_fwd_regd_slice_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // inputs
   valid_src,
   ready_dst,
   payload_src,

   // outputs
   ready_src,
   valid_dst,
   payload_dst
   );

  //----------------------------------------------------------------------------
  // parameters
  //----------------------------------------------------------------------------
  // user defined parameters
  parameter PAYLD_WIDTH = 2;

  // calculated parameters (do not alter)
  parameter PAYLD_MAX = (PAYLD_WIDTH - 1);

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  input                 aresetn;        // AXI global reset
  input                 aclk;           // AXI global clock

  // inputs
  input                 valid_src;      // transfer valid from the source
  input                 ready_dst;      // destination ready to accept transfer
  input [PAYLD_MAX:0]   payload_src;    // transfer payload from source

  // outputs
  output                valid_dst;      // transfer valid to the destination
  output                ready_src;      // source ready to accept transfer
  output [PAYLD_MAX:0]  payload_dst;    // transfer payload for destination

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  wire                  aresetn;        // AXI global reset
  wire                  aclk;           // AXI global clock

  // inputs
  wire                  valid_src;      // transfer valid from the source
  wire                  ready_dst;      // destination ready to accept transfer
  wire [PAYLD_MAX:0]    payload_src;    // transfer payload from source

  // outputs
  wire                  valid_dst;      // transfer valid to the destination
  wire                  ready_src;      // source ready to accept transfer
  reg [PAYLD_MAX:0]     payload_dst;    // transfer payload for destination

  // ---------------------------------------------------------------------------
  //  Internal signals
  // ---------------------------------------------------------------------------
  wire                  payload_en;     // enable for storage register
  wire                  valid_dst_en;   // enable for valid_dst
  reg                   ivalid_dst;     // internal version of valid_dst

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  output valid_dst;
  // ---------------------------------------------------------------------------
  assign valid_dst = ivalid_dst;

  // ---------------------------------------------------------------------------
  //  output ready_src;
  // ---------------------------------------------------------------------------
  // the register slice is ready if the destination is ready to accept a
  // transfer, or if the slice doesn't hold a transfer.
  assign ready_src = ready_dst | ~ivalid_dst;

  // ---------------------------------------------------------------------------
  // output [PAYLD_MAX:0] payload_dst;
  // ---------------------------------------------------------------------------
  // Payload register.  This register holds the payload transfer.  It is
  // updated when a new transfer payload is accepted on the source interface.
  // See payload_en for more details.
  always @(posedge aclk)
  begin : p_payload_dst
    if (payload_en)
      payload_dst <= payload_src;
  end // block : p_payload_dst

  // ---------------------------------------------------------------------------
  //  wire payload_en;
  // ---------------------------------------------------------------------------
  // the transfer should be loaded in to the registers if the source is
  // attempting to transfer and the slice is empty, or if the source is
  // attempting to transfer and the slice is full but the destination is
  // removing the current transfer
  assign payload_en = ((valid_src & ~ivalid_dst) |
                       (valid_src & ivalid_dst & ready_dst));

  // ---------------------------------------------------------------------------
  //  wire valid_dst_nxt;
  // ---------------------------------------------------------------------------
  // the register slice will contain a transfer if:
  //  1. the source is attempting to transfer
  //  2. if the slice is full but the destination cannot accept it.
  assign valid_dst_en = (valid_src | ready_dst);

  // ---------------------------------------------------------------------------
  //  wire ivalid_dst;
  // ---------------------------------------------------------------------------
  // Payload status flag.  This register indicates whether the payload register
  // holds a valid transfer payload.  The value is driven high if a new 
  // payload transfer is loaded or if a current payload is not accepted by
  // the destination interface. See valid_dst_nxt for more details.
  always @(posedge aclk or negedge aresetn)
  begin : p_ivalid_dst
    if (~aresetn)
      ivalid_dst <= 1'b0;
    else if (valid_dst_en)
      ivalid_dst <= valid_src;
  end // block : p_ivalid_dst

  // ---------------------------------------------------------------------------
endmodule
//----------------------------------  END  -------------------------------------

