//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 127895
// File Date           :  2012-03-28 13:19:47 +0100 (Wed, 28 Mar 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose : CDC two-input multiplexer.  May be connected on a CDC path.
//
//  Implementations should replace this with a cell that is known to be
//  glitch-free while unselected inputs change.
//
//  The select input must be driven from a register in the receiving clock 
//  domain.
//------------------------------------------------------------------------------

module nic400_cdc_comb_mux2_1
(
  din1_async,
  din2_async,
  sel,
  dout_async
);


  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input     din1_async; // May be connected to an asynchronous input
  input     din2_async; // May be connected to an asynchronous input
  input     sel;
  output    dout_async;

  // ------------------------------------------------------
  // reg/wire declarations
  // ------------------------------------------------------
  reg       muxout;
  wire      dout_async;

  always @(din1_async or din2_async or sel)
    case (sel)
      1'b0 : muxout = din1_async;
      1'b1 : muxout = din2_async;
      default : muxout = 1'bx;
    endcase
  
`ifdef ARM_CDC_CHECK
  assign dout_async = (sel === 1'bz) ? 1'bz : muxout;
`else
  assign dout_async = muxout;
`endif
  
endmodule

