//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2012-2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 189213
// File Date           :  2015-02-25 08:59:06 +0000 (Wed, 25 Feb 2015)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose : Single mux to clamp unstable values to zero when crossing domains.
//            This file will stop the simulation if unsafe values are detected.
// -----------------------------------------------------------------------------

module nic400_cdc_capt_nosync_1 (d_async, q, valid);

  parameter WIDTH = 4; // Width of the payload

  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input              valid;
  input  [WIDTH-1:0] d_async;     // May be connected to an asynchronous input
  output [WIDTH-1:0] q;

 // Generate an AND gate to mask each payload bit
 genvar d;
 generate
    for (d=0;d<WIDTH;d=d+1)
      begin : d_mask

  nic400_cdc_comb_and2_1  u_cdc_and2 (
   .din1_async (d_async[d]),   
   .din2       (valid),
   .dout       (q[d])
  );
 
      end

 endgenerate

`ifdef ARM_CDC_CHECK

  integer   i;

  // Use an assertion if assertions are enabled.
  wire [WIDTH-1:0]  q_d;
  reg               z_detect;

  initial
    z_detect = 1'b0;

  // Create a delayed signal to ensure that any error fires at the correct
  // time
  assign #1 q_d = q;

  // Stop the simulation if any bits are Z when mux is enabled
  always @(q_d)
    if (valid)
      for (i = 0; i <= WIDTH; i = i + 1)
        if (d_async[i] === 1'bz)
          begin
            z_detect <= 1'b1;
          end

  always @(posedge z_detect)
     begin
          $display("FATAL : Unsafe operation detected across CDC boundary");
          $stop;
     end

`endif

endmodule

