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
//  Purpose : The default, synthesiser-inferred implementation of an N-level
//            synchroniser structure.
//
// --=========================================================================--

module nic400_syncn_1
(
  input  wire clk,
  input  wire resetn,
  input  wire din,
  output wire dout
);

  parameter LEVELS = 2;

  wire [LEVELS-1:0] d_int;

  // The first register in the synchroniser chain,
  // with the asynchronous input.
  nic400_sync_flop_1 u_sync_flop_async_1
  (
    .clk     (clk),
    .resetn  (resetn),
    .din     (din),
    .dout    (d_int[0])
  );

  genvar i;
  generate
    if (LEVELS>2)
    begin : g_levels_gt_2
      // The other synchronisers in the chain
      for (i=0 ; i<LEVELS-2 ; i=i+1)
      begin : g_i
        nic400_sync_flop_1 u_sync_flop_part_1
        (
          .clk     (clk),
          .resetn  (resetn),
          .din     (d_int[i]),
          .dout    (d_int[i+1])
        );
      end
    end
  endgenerate

  // The last register in the synchroniser chain,
  // with a synchronous input.
  nic400_sync_flop_1 u_sync_flop_sync_1
  (
    .clk     (clk),
    .resetn  (resetn),
    .din     (d_int[LEVELS-2]),
    .dout    (d_int[LEVELS-1])
  );

  assign dout = d_int[LEVELS-1];

endmodule

