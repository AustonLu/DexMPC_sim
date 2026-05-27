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
//  File Date           :  2010-02-10 14:21:24 +0000 (Wed, 10 Feb 2010)
//  File Revision       : 87153
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : transaction tracker
//
//                      : Counts the number of active transactions
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmTransC
(
  ACLK,
  ARESETn,

  //reps channel
  Rvalid,
  Rready,
  Rlast,

  //A Channel
  Avalid,
  Aready,

  //Outstanding Transaction
  out_reached


);


  // Module parameters
  parameter OUTSTD_TRANS        = 16;                 // Oustanding addresses

  // System interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  //resp channel
  input               Rvalid;
  input               Rready;
  input               Rlast;


  //A Channel
  input               Avalid;
  input               Aready;

  output              out_reached;

 //-----------------------------------------------------------------------------------------
 // signals
 //-----------------------------------------------------------------------------------------

  wire                trans_complete;
  wire                new_a;


  wire [7:0]          next_out_trans;

  reg [7:0]           out_trans;

 //-----------------------------------------------------------------------------------------
 // main code
 //-----------------------------------------------------------------------------------------

  assign   trans_complete = Rvalid & Rready & Rlast;
  assign   new_a         = Avalid & Aready;

 //-----------------------------------------------------------------------------------------
 // counters
 //-----------------------------------------------------------------------------------------

 //Trans counter
 //Increment when new_a
 //Decrement when transcomplete
 assign next_out_trans = (new_a & ~trans_complete) ? out_trans + 8'b1 :
                         (trans_complete & ~new_a) ? out_trans - 8'b1 : out_trans;

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
 assign out_reached = (out_trans >= OUTSTD_TRANS);

endmodule

// --================================= End ===================================--

