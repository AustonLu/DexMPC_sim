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
//  File Revision       : 89761
//  File Date           :  2010-04-27 16:59:52 +0100 (Tue, 27 Apr 2010)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : Write transaction tracker
//
//                      : Counts the number of active write transactions
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrsWTransC
(
  ACLK,
  ARESETn,

  //Bchannel
  Bvalid,
  Bready,

  //AW Channel
  AWvalid,
  AWready,
  AWid,

  //W Channel
  Wready,
  Wvalid,
  Wfirst,
  Wlast,
  Wid,

  out_aw_reached,
  out_w_reached,
  BEnableID,
  BEnable

);


  // Module parameters
  parameter OUTSTD_WRITES        = 16;         // Oustanding addresses
  parameter ID_WIDTH             = 8;          // ID width
  parameter REQUIRE_AW_HNDSHK    = 0;          // Require AW Handshake

  parameter ID_MAX               = ID_WIDTH -1;

  // System interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  //Bchannel
  input               Bvalid;
  input               Bready;

  //AW Channel
  input               AWvalid;
  input               AWready;
  input [ID_MAX:0]    AWid;

  //W Channel
  input               Wready;
  input               Wvalid;
  input               Wfirst;
  input               Wlast;
  input [ID_MAX:0]    Wid;


  output              out_aw_reached;
  output              out_w_reached;

  output [ID_MAX:0]   BEnableID;
  output              BEnable;

 //-----------------------------------------------------------------------------------------
 // signals
 //-----------------------------------------------------------------------------------------

  wire                trans_complete;
  wire                new_w;
  wire                w_complete;
  wire                new_aw;
  wire                new_transaction;
  wire                req_aw_hndshk;


  wire [7:0]          next_out_trans;
  wire [7:0]          next_out_aw;
  wire [7:0]          next_out_w;
  wire [7:0]          next_out_w_comp;

  reg [7:0]           out_trans;
  reg [7:0]           out_aw;
  reg [7:0]           out_w;
  reg [7:0]           out_w_comp;


 //-----------------------------------------------------------------------------------------
 // main code
 //-----------------------------------------------------------------------------------------

  assign   trans_complete = Bvalid & Bready;
  assign   new_w          = Wready & Wvalid & Wfirst;
  assign   w_complete     = Wready & Wvalid & Wlast;
  assign   new_aw         = AWvalid & AWready;

 //-----------------------------------------------------------------------------------------
 // counters
 //-----------------------------------------------------------------------------------------

 //AW counter
 //Increment on AW (unless W > 0)
 //Decrement on W  (if AW > 0)
 //Do nothing if both AW and W

 assign next_out_aw = (new_aw & (out_w == 0) & ~new_w) ? out_aw + 8'b1 :
                      (new_w & (out_aw > 0) & ~new_aw) ? out_aw - 8'b1 : out_aw;

 //W counter
 //Increment on W (unless AW > 0)
 //Decrement on AW (if W > 0)
 //Do nothing if both AW and W

 assign next_out_w = (new_w & (out_aw == 0) & ~new_aw) ? out_w + 8'b1 :
                     (new_aw & (out_w > 0) & ~new_w) ? out_w - 8'b1 : out_w;


 //Trans counter
 //Increment when new_aw and aw>0 or new_w and w>0
 //Decrement when transcomplete
 assign new_transaction = (new_w  & out_aw == 0) |
                          (new_aw & out_w  == 0);

 assign next_out_trans = (new_transaction & ~trans_complete) ? out_trans + 8'b1 :
                         (trans_complete & ~new_transaction) ? out_trans - 8'b1 : out_trans;

 //flag out_w_comp is used in BEnable for cases of one outstanding leading write, which finishes wlast
 //Coz there is no indication whether wlast finished or not in the case that there is only one outstanding write
 assign next_out_w_comp = (w_complete & ~new_aw & (|next_out_w)) ? out_w_comp + 8'b1 :
                          (~w_complete & new_aw & (|out_w_comp)) ? out_w_comp - 8'b1 : out_w_comp;
 //counters
 always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           out_w <= 8'b0;
           out_aw <= 8'b0;
           out_trans <= 8'b0;
           out_w_comp <= 8'b0;

       end else begin
           out_w <= next_out_w;
           out_aw <= next_out_aw;
           out_trans <= next_out_trans;
           out_w_comp <= next_out_w_comp;
       end
    end

 //assign the output
 assign out_aw_reached = (out_trans >= OUTSTD_WRITES && out_w == 0);
 assign out_w_reached  = (out_trans >= OUTSTD_WRITES && out_aw == 0);

 //assign req_aw_handshk
 assign req_aw_hndshk = (REQUIRE_AW_HNDSHK == 1) ? 1'b1 : 1'b0;

 //BEnable
 assign BEnableID = (req_aw_hndshk == 1'b0) ? Wid :
                    //If a w beat completes and there are leading or concurrent aw then Wid
                    (w_complete & (|out_aw | ~|next_out_w)) ? Wid :
                    //Else AWID
                    AWid;

 assign BEnable   = (req_aw_hndshk == 1'b0) ? w_complete :
                    //When a wbeat complete and there are leading or complete aw beats
                    (w_complete & (|out_aw | ~|next_out_w)) |
                    //Or when an AW beat completes and there is leading write data
                    (new_aw & (|out_w_comp));

endmodule

// --================================= End ===================================--

