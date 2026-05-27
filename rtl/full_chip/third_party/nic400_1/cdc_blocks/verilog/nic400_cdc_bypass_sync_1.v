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

module nic400_cdc_bypass_sync_1
(
  clk,
  resetn,
  sync_en,
  mux_sel,
  d_async,
  q
);

//------------------------------------------------------------------------------
// Port Declarations
//------------------------------------------------------------------------------

  input          clk;
  input          resetn;
  input          sync_en;
  input          mux_sel;
  input          d_async;
  output         q;

//------------------------------------------------------------------------------
// reg/wire Declarations
//------------------------------------------------------------------------------

  wire           d_capt;

//------------------------------------------------------------------------------
// Main Code
//------------------------------------------------------------------------------

  nic400_cdc_capt_sync_1 #(1) u_cdc_capt_sync
  (
    .clk     (clk),
    .resetn  (resetn),
    .sync_en (sync_en),
    .d_async (d_async),
    .q       (d_capt)
  );

  nic400_cdc_comb_mux2_1 u_cdc_mux
  (
    .din1_async (d_async),
    .din2_async (d_capt),
    .sel        (mux_sel),
    .dout_async (q)
  );

`ifdef ARM_CDC_CHECK

`ifdef ARM_ASSERT_ON
  assert_never #(0, 0, "Unsafe operation detected across CDC boundary4") uovl011
   (.clk              (clk),
     .reset_n          (resetn),
     .test_expr        (q === 1'bz)
   );
`endif

`endif

endmodule

