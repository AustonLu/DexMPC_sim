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
//  Purpose : Clock domain crossing synchronizer.  This module should be used
//            wherever an unsafe asynchronous input must be used.
//
//------------------------------------------------------------------------------

module nic400_cdc_capt_sync_1 (clk, resetn, d_async, sync_en, q);

  parameter WIDTH = 4;

  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input                clk;
  input                resetn;
  input [WIDTH-1:0]    d_async;     // May be connected to an asynchronous input
  input                sync_en;
  output [WIDTH-1:0]   q;


  // ------------------------------------------------------
  // reg/wire declarations
  // ------------------------------------------------------
  wire [WIDTH-1:0]     d_noz;
  reg  [WIDTH-1:0]     d_sync1;
  reg  [WIDTH-1:0]     q;

`ifdef ARM_CDC_CHECK

  nic400_cdc_random_1 #(WIDTH) u_cdc_random_z(
                             .din (d_async),
                             .dout (d_noz)
                             );

`else

  assign d_noz = d_async;

`endif

  always @(posedge clk or negedge resetn)
    if (!resetn)
      begin
        d_sync1 <= {WIDTH{1'b0}};
        q <= {WIDTH{1'b0}};
      end
    else if(sync_en)
      begin
        d_sync1 <= d_noz;
        q <= d_sync1;
      end
      
endmodule

