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
//  Purpose : Two cycle reset synchroniser with DFT bypass
//
// --=========================================================================--

module nic400__rst_sync_1
  (
   input wire  clk,
   input wire  resetn,
   input wire  dftrstdisable,
   output wire resetn_out
   );

  wire         resetn_int;

  // The last register in the synchroniser chain,
  // with a synchronous input.
  nic400_syncn_1 u_reset_sync
    (
     .clk     (clk),
     .resetn  (resetn),
     .din     (1'b1),
     .dout    (resetn_int)
     );

  assign resetn_out = resetn_int | dftrstdisable;

endmodule

