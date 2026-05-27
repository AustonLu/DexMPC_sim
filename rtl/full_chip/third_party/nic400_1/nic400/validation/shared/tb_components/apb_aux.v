
//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 149994
// File Date           :  2009-05-01 11:37:44 +0100 (Fri, 01 May 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : This module determines the source of the apb transfer
//------------------------------------------------------------------------------

module apb_aux
(
    pid,
    pstrobe
);   

//------------------------------------------------------------------------------
// Parameter declarations
//------------------------------------------------------------------------------  

   parameter INSTANCE = "undef"; //not used placeholder for consistancy
   parameter ID_WIDTH = 16;

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------

   output [ID_WIDTH-1:0]      pid;       //ID of the incoming transaction
   output [3:0]               pstrobe;   //Strobes value of the incoming transaction

//------------------------------------------------------------------------------
// wire declarations 
//------------------------------------------------------------------------------  

   
   wire [ID_WIDTH-1:0] pid;

//------------------------------------------------------------------------------
// code declarations 
//------------------------------------------------------------------------------  
    
   

//Determine the id of the current transaction
`ifdef ARM_NET_SIM
   
`else
   
`endif

   assign pid =  {ID_WIDTH{1'b0}};

`ifdef ARM_NET_SIM
   
`else
   
`endif

   assign pstrobe =  {4{1'b0}};


endmodule

