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
//  Revision            : 104094
//  Release information : PL401-r1p2-00rel0
//                                                                         
// ----------------------------------------------------------------------------
//  Purpose : CDC three-input OR gate.  May be connected on a CDC path.
//
//  Implementations should replace this with a cell that is known to be
//  glitch-free with respect to an input while the other input is 0.
// ----------------------------------------------------------------------------

module nic400_cdc_comb_or3_1 (din1_async, din2_async, din3_async, dout_async);

  // ------------------------------------------------------
  // port declaration
  // ------------------------------------------------------
  input  din1_async; // May be connected to an asynchronous input
  input  din2_async; // May be connected to an asynchronous input
  input  din3_async; // May be connected to an asynchronous input
  output dout_async;

  reg    dout_async;

`ifdef ARM_CDC_CHECK

  // ------------------------------------------------------
  // reg/wire declarations
  // ------------------------------------------------------
  // Propagate Zs
  reg    dout_async_int;
`endif

  always @(din1_async or din2_async or din3_async)
    begin

`ifdef ARM_CDC_CHECK
      case ({din1_async, din2_async, din3_async})
        3'b??x  : dout_async_int = 1'bx;
        3'b?x?  : dout_async_int = 1'bx;
        3'bx??  : dout_async_int = 1'bx;
        3'b000  : dout_async_int = 1'b0;
        3'b001  : dout_async_int = 1'b1;
        3'b010  : dout_async_int = 1'b1;
        3'b011  : dout_async_int = 1'b1;
        3'b100  : dout_async_int = 1'b1;
        3'b101  : dout_async_int = 1'b1;
        3'b110  : dout_async_int = 1'b1;
        3'b111  : dout_async_int = 1'b1;
        default : dout_async_int = 1'bx;
      endcase
    
      dout_async = ((din1_async === 1'bz) || (din2_async === 1'bz) || (din3_async === 1'bz)) ? 1'bz : dout_async_int;
`else
      dout_async = din1_async | din2_async | din3_async;
`endif
    end
  
endmodule
