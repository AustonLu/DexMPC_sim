// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 87876
//  File Date           :  2010-03-05 13:27:48 +0000 (Fri, 05 Mar 2010)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : Write transaction tracker
//
//                      : Counts the number of active write transactions
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrsRTransC
(
  ACLK,
  ARESETn,

  //Bchannel
  Rvalid,
  Rready,
  Rlast,

  //AW Channel
  ARvalid,
  ARready,

  //Outstanding Transaction
  out_rd_reached


);


  // Module parameters
  parameter OUTSTD_READS        = 16;                 // Oustanding addresses

  // System interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  //Bchannel
  input               Rvalid;
  input               Rready;
  input               Rlast;

  //AW Channel
  input               ARvalid;
  input               ARready;

  output              out_rd_reached;

 //-----------------------------------------------------------------------------------------
 // signals
 //-----------------------------------------------------------------------------------------

  wire                trans_complete;
  wire                new_ar;


  wire [7:0]          next_out_trans;

  reg [7:0]           out_trans;

 //-----------------------------------------------------------------------------------------
 // main code
 //-----------------------------------------------------------------------------------------

  assign   trans_complete = Rvalid & Rready & Rlast;
  assign   new_ar         = ARvalid & ARready;

 //-----------------------------------------------------------------------------------------
 // counters
 //-----------------------------------------------------------------------------------------

 //Trans counter
 //Increment when new_ar
 //Decrement when transcomplete
 assign next_out_trans = (new_ar & ~trans_complete) ? out_trans + 8'b1 :
                         (trans_complete & ~new_ar) ? out_trans - 8'b1 : out_trans;

 //counters
 always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           out_trans <= 8'b0;
       end else begin
           out_trans <= next_out_trans;
       end
    end

 //assign the output
 assign out_rd_reached = (out_trans >= OUTSTD_READS);

endmodule

// --================================= End ===================================--

