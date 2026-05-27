//-=============================================================================
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//                      (C) COPYRIGHT 2015 ARM Limited.
//                            ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//-============================================================================
//  Version and Release Control Information:
//
//   File Revision       : 168777
//
//   Date                :  2014-03-11 16:32:30 +0000 (Tue, 11 Mar 2014)
//
//   Release Information : PL401-r1p2-00rel0
//
//-=============================================================================
//  Purpose : The default, synthesiser-inferred implementation of a 1-bit
//            synchroniser flop.
//
// --=========================================================================--

module nic400_sync_flop_1
(
  input  wire clk,
  input  wire resetn,
  input  wire din,
  output reg  dout
);

  // An edge-sensitive register is inferred from
  // this code.
  always @(posedge clk or negedge resetn)
  begin : 1_sync_flop_cell
    if (!resetn)
      dout <= 1'b0;
    else
      dout <= din;
  end

endmodule

