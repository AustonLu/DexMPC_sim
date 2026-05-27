//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 189839
// File Date           :  2015-03-06 13:47:18 +0000 (Fri, 06 Mar 2015)
// Release Information : PL401-r1p2-00rel0
//-----------------------------------------------------------------------------
//  Purpose : CDC two-input AND gate.  May be connected on a CDC path.
//
//  Implementations should replace this with a cell that is known to be
//  glitch-free with respect to the async input while the other input is 0.
//-----------------------------------------------------------------------------

module nic400_cdc_comb_and2_1 (din1_async, din2, dout);

  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input  din1_async; // May be connected to an asynchronous input
  input  din2; // May be connected to an asynchronous input
  output dout;

  // ------------------------------------------------------
  // reg/wire declarations
  // ------------------------------------------------------
  reg    dout;

  always @(din1_async or din2)
    begin

      dout= din1_async & din2;

    end
  
endmodule
