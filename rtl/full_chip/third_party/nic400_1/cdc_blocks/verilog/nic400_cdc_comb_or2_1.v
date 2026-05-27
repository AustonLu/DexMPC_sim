//===========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted  
//  by a subsisting licensing agreement from ARM Limited or its affiliates.
//                                                                         
//                (C) COPYRIGHT 2012 ARM Limited or its affiliates.   
//                    ALL RIGHTS RESERVED                                  
//                                                                         
//  This entire notice must be reproduced on all copies of this file       
//  and copies of this file may only be made by a person if such person is 
//  permitted to do so under the terms of a subsisting license agreement   
//  from ARM Limited or its affiliates.                                    
//                                                                         
//  SVN Information                                                        
//                                                                         
//  Revision            : 127895
//  Release information : PL401-r1p2-00rel0
//                                                                         
// ----------------------------------------------------------------------------
//  Purpose : CDC two-input OR gate.  May be connected on a CDC path.
//
//  Implementations should replace this with a cell that is known to be
//  glitch-free with respect to an input while the other input is 0.
// ----------------------------------------------------------------------------

module nic400_cdc_comb_or2_1 (din1_async, din2_async, dout_async);

  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input  din1_async; // May be connected to an asynchronous input
  input  din2_async; // May be connected to an asynchronous input
  output dout_async;

  // ------------------------------------------------------
  // reg/wire declarations
  // ------------------------------------------------------
  reg    dout_async;
  // Propagate Zs
  always @(din1_async or din2_async)
    begin
`ifdef ARM_CDC_CHECK
      case ({din1_async, din2_async})
        2'b00 : dout_async = 1'b0;
        2'b01 : dout_async = 1'b1;
        2'b0x : dout_async = 1'b0;
        2'b0z : dout_async = 1'b0;
        2'b10 : dout_async = 1'b1;
        2'bx0 : dout_async = 1'b0;
        2'bz0 : dout_async = 1'b0;
        2'b11 : dout_async = 1'b1;
        2'b1z : dout_async = 1'bz;
        2'bxz : dout_async = 1'bz;
        2'bz1 : dout_async = 1'bz;
        2'bzx : dout_async = 1'bz;
        default : dout_async = 1'bx;
      endcase
`else
      dout_async = din1_async | din2_async;
`endif
    end
  
endmodule
