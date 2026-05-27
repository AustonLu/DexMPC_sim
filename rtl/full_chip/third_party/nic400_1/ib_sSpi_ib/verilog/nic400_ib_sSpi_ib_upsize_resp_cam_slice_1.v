//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 127275
// File Date           :  2012-03-19 15:37:15 +0000 (Mon, 19 Mar 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : A slot of the storage for the ID and hazard
//           information required by the Upsizer B channel
//------------------------------------------------------------------------------

module nic400_ib_sSpi_ib_upsize_resp_cam_slice_1
  (
    // global interconnect signals
    aresetn,
    aclk,

    // ID inputs (to all slices)
    matchid,        //ID arriving on the Bchannel
    hazardid,       //ID on the AW channel being input

    //Control Signals
    store,
    push_slice,
    pop_slice,
    update,
    match_pointer,

    //If a hazard has been detected
    hazard_in,
    hazard_pointer,

    //Signal to be saved
    n_response,
    bresp_in,

    //Outputs
    hazard,
    match,
    valid,
    bresp_out

  );

 `include "nic400_ib_sSpi_ib_defs_1.v"

  //------------------------------------------------------------------------------
  // IO 
  //------------------------------------------------------------------------------

  //System Inputs
  input                 aresetn;
  input                 aclk;

  input [1:0]           matchid;
  input [1:0]           hazardid;

  input                 store;
  input                 push_slice;
  input                 pop_slice;
  input                 update;

  input [1:0]           hazard_pointer;
  input [1:0]           match_pointer;
  input                 hazard_in;

  input                 n_response;
  input [1:0]           bresp_in;

  output                hazard;
  output                match;
  output                valid;
  output [1:0]          bresp_out;

 //------------------------------------------------------------------------
 // Registers
 //------------------------------------------------------------------------ 

  reg [1:0]             id_reg;
  reg [1:0]             pointer_reg;

  reg                   hazard_reg;
  reg                   valid_reg;
  reg                   last_reg;
  reg                   n_response_reg;
  reg [1:0]             bresp_reg;

 //------------------------------------------------------------------------ 
 // Wires
 //------------------------------------------------------------------------

  wire [1:0]            next_id_reg;
  wire [1:0]            next_pointer_reg;

  wire                  next_hazard_reg;
  wire                  next_valid_reg;
  wire                  next_last_reg;
  wire                  next_n_response_reg;
  wire [1:0]            next_bresp_reg;

  wire                  allowed_to_match;
  wire                  bid_match;
  wire                  awid_match;
  wire                  match_i;
  wire                  last_reg_wr_en;
  wire                  hazard_reg_wr_en;
  wire                  valid_reg_wr_en;
  wire                  n_response_reg_wr_en;
  wire                  default_reg_wr_en;

  wire                  pointer_match;

 //------------------------------------------------------------------------
 // Main Code
 //------------------------------------------------------------------------

 //ID match Logic
 assign bid_match = (matchid == id_reg);
 assign awid_match = (hazardid == id_reg);
 
 //match Output - This slice can only report a match if the BID matches, the
 //slice is valid, doesn't report a hazard and Two_reponse isn't set.
 assign allowed_to_match = valid_reg && ~hazard_reg && ~n_response_reg;
 assign match_i = allowed_to_match && bid_match;
 assign match   = match_i;
 
 //hazard Detection output
 //All transactions to the same ID are stored as linked lists. A slice can only
 //report a hazard if it is at the bottom of the list. The new slice then points to the
 //one reporting the hazard.
 assign hazard = awid_match && last_reg && valid_reg && ~(match_i && pop_slice);

 //Normal Register Enable
 assign default_reg_wr_en = (store && push_slice);

 //ID Logic
 assign next_id_reg = hazardid;

 always @(posedge aclk)
   begin : id_seq
      if (default_reg_wr_en)
         id_reg <= next_id_reg;
   end // id_seq

 //pointer Logic ... this points to the previous transaction from the same ID
 //pointer is only valid when hazard is
 assign next_pointer_reg = hazard_pointer;

  always @(posedge aclk)
   begin : pointer_seq
      if (default_reg_wr_en)
         pointer_reg <= next_pointer_reg;
   end // pointer_seq

 //Last Logic
 //This indicates that this is the last item in a hazard queue
 assign next_last_reg = (store && push_slice) ? 1'b1 : 
                        ((awid_match) ? 1'b0 : last_reg);

 assign last_reg_wr_en = (default_reg_wr_en || (awid_match && valid_reg && push_slice));
 
  always @(posedge aclk)
   begin : last_seq
      if (last_reg_wr_en)
         last_reg <= next_last_reg;
   end // last_seq

 //hazard Logic
 //pointer match
 assign pointer_match = (pointer_reg == match_pointer);

 //The only reason for updating this register is for a store or
 //It been promoted to the top of the queue .. => it will be 0
 assign next_hazard_reg = (store && push_slice) ? hazard_in : 1'b0;

 assign hazard_reg_wr_en = (default_reg_wr_en || (pointer_match && valid_reg && pop_slice));

  always @(posedge aclk)
   begin : hazard_seq
      if (hazard_reg_wr_en)
         hazard_reg <= next_hazard_reg;
   end // hazard_seq

 //valid_Logic

 assign next_valid_reg = (store && push_slice) || (n_response_reg); 

 assign valid_reg_wr_en = default_reg_wr_en || (match_i && pop_slice);

   always @(posedge aclk or negedge aresetn)
   begin : valid_seq
      if (!aresetn) 
         valid_reg <= 1'b0;
      else if (valid_reg_wr_en)
         valid_reg <= next_valid_reg;
   end // valid_seq

  //Set valid ouput
  assign valid = valid_reg;

  //Two response logic ... This is used to mask the first match duriong a wrap that
  //was unaligned to the wider bus;
  assign next_n_response_reg = (store && push_slice) ? n_response :  1'b0;
  
  assign next_bresp_reg = (store && push_slice) ? 2'b0 : (bresp_in | bresp_reg);

  assign n_response_reg_wr_en = (bid_match && ~hazard_reg && update && (n_response_reg)) || (store && push_slice);

  always @(posedge aclk or negedge aresetn)
   begin : two_resp_seq
     if (!aresetn) begin
         n_response_reg <= 1'b0; 
         bresp_reg <= 2'b0;
     end else if (n_response_reg_wr_en) begin
         n_response_reg <= next_n_response_reg;
         bresp_reg <= next_bresp_reg;
     end
   end // two_resp_seq
   
   assign bresp_out = {2{match_i}} & bresp_reg;

`ifdef ARM_ASSERT_ON

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that n_response_reg is zero when slice not valid 
   //------------------------------------------------------------------------
   // If this slice is not valid then must be empty 
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_never #(0,0,"n_resp reg is always zero when slice is invalid")
  ovl_n_resp_val
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        (~valid_reg && |n_response_reg)
     );
   // OVL_ASSERT_END

`endif

`include "nic400_ib_sSpi_ib_undefs_1.v"
endmodule

//------------------------------------------------------------------------------
//  End of File : $RCSfile: UpsizeAxi_resp_cam_slice,v $
//------------------------------------------------------------------------------

