
//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 188785
// File Date           :  2008-09-25 19:21:47 +0100 (Thu, 25 Sep 2008)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : This module determines the source of the ahb transfer
//------------------------------------------------------------------------------

module ahb_aux
(
    hid,
    hstrobes
);   

//------------------------------------------------------------------------------
// Parameter declarations
//------------------------------------------------------------------------------  

   parameter INSTANCE = "undef"; 
   parameter ID_WIDTH = 16;

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------

   output [ID_WIDTH-1:0]      hid;       //ID of the incoming transaction
   output [31:0]              hstrobes;

//------------------------------------------------------------------------------
// wire declarations 
//------------------------------------------------------------------------------  

   
   wire [ID_WIDTH-1:0] hid;

//------------------------------------------------------------------------------
// code declarations 
//------------------------------------------------------------------------------  
    
   

   //Determine the id of the current transaction
`ifdef ARM_NET_SIM
   
`else
   
`endif
  
   assign hid =  {ID_WIDTH{1'b0}};

   assign hstrobes =  {32{1'b0}};

endmodule

