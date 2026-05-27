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
//  Version and Release Control Information:
//
//  File Revision       : 126202
//
//  Date                :  2012-03-02 11:28:07 +0000 (Fri, 02 Mar 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : This module implements the return channels (R and B)
//                        routing of transactions back to the correct slave
//                        interface as defined by the transactions ID.
//   
//  Key Configuration Details-
//      - Number of connected slave interfaces 3
//   
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterInterface (connect to external AXI slave)
//     *_s0 suffix to denote the SlaveInterface  (connect to external AXI master) 
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_ret_sel_ml0_1
  (
    // bchannel mask 
    wr_cnt_empty,

    // SlaveInterface 0
    // Write Response Channel
    bid_s0,
    bresp_s0,
    bvalid_s0,
    bready_s0,  
    // Read Channel
    rid_s0,
    rdata_s0,
    rresp_s0,
    rlast_s0,
    rvalid_s0,
    rready_s0,

    // SlaveInterface 1
    // Write Response Channel
    bid_s1,
    bresp_s1,
    bvalid_s1,
    bready_s1,  
    // Read Channel
    rid_s1,
    rdata_s1,
    rresp_s1,
    rlast_s1,
    rvalid_s1,
    rready_s1,

    // SlaveInterface 2
    // Write Response Channel
    bid_s2,
    bresp_s2,
    bvalid_s2,
    bready_s2,  
    // Read Channel
    rid_s2,
    rdata_s2,
    rresp_s2,
    rlast_s2,
    rvalid_s2,
    rready_s2,

    // MasterInterface 
    // Write Response Channel
    bid_m,
    bresp_m,
    bvalid_m,
    bready_m,
    // Read Channel
    rid_m,
    rdata_m,
    rresp_m,
    rlast_m,
    rvalid_m,
    rready_m
 );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  // bchannel mask 
  input             wr_cnt_empty;
  // MasterInterface 
  // Write Response Channel
  input [7:0]       bid_m;
  input [1:0]       bresp_m;
  input             bvalid_m;
  output            bready_m;
  // Read Channel
  input [7:0]       rid_m;
  input [63:0]      rdata_m;
  input [1:0]       rresp_m;
  input             rlast_m;
  input             rvalid_m;
  output            rready_m;

  // SlaveInterface 0
  // Write Response Channel
  output [7:0]      bid_s0;
  output [1:0]      bresp_s0;
  output            bvalid_s0;
  input             bready_s0;  
  // Read Channel
  output  [7:0]     rid_s0;
  output  [63:0]    rdata_s0;
  output [1:0]      rresp_s0;
  output            rlast_s0;
  output            rvalid_s0;
  input             rready_s0;

  // SlaveInterface 1
  // Write Response Channel
  output [7:0]      bid_s1;
  output [1:0]      bresp_s1;
  output            bvalid_s1;
  input             bready_s1;  
  // Read Channel
  output  [7:0]     rid_s1;
  output  [63:0]    rdata_s1;
  output [1:0]      rresp_s1;
  output            rlast_s1;
  output            rvalid_s1;
  input             rready_s1;

  // SlaveInterface 2
  // Write Response Channel
  output [7:0]      bid_s2;
  output [1:0]      bresp_s2;
  output            bvalid_s2;
  input             bready_s2;  
  // Read Channel
  output  [7:0]     rid_s2;
  output  [63:0]    rdata_s2;
  output [1:0]      rresp_s2;
  output            rlast_s2;
  output            rvalid_s2;
  input             rready_s2;



  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------

  wire              bvalid_masked;
  wire              bready_comb;
  // SlaveInterface 0
  // Write Response Channel Masked signals
  wire              bready_masked0;  
  // Read Channel Masked signals
  wire              rready_masked0;

  // SlaveInterface 1
  // Write Response Channel Masked signals
  wire              bready_masked1;  
  // Read Channel Masked signals
  wire              rready_masked1;

  // SlaveInterface 2
  // Write Response Channel Masked signals
  wire              bready_masked2;  
  // Read Channel Masked signals
  wire              rready_masked2;
  reg [2:0]       bsel; // One hot vector, of buffered response selects
  reg [2:0]       rsel; // One hot vector, of read selects


  //------------------------------------------------------------------------------
  // Registers 
  //------------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

   //------------------------ Calculate Return Selects ------------------------


   always @(bid_m or bvalid_m)
   begin : p_b_ret_sel
     // Declare local variables
     reg [2:0] loc_bsel; 
     reg [1:0] i_bid_m;
     // clear select bits
     loc_bsel = {3{1'b0}};
     if (bvalid_m)
     begin
        // Set the correct bit
        i_bid_m = bid_m[1:0];
        loc_bsel[i_bid_m] = 1'b1;
        bsel = loc_bsel;
     end else
     begin
        i_bid_m = {2{1'b0}};
        bsel = {3{1'b0}};
     end 
   end // p_b_ret_sel

   always @(rid_m or rvalid_m)
   begin : p_r_ret_sel
     // Declare local variables
     reg [2:0] loc_rsel; 
     reg [1:0] i_rid_m;
     // clear select bits
     loc_rsel = {3{1'b0}};
     if (rvalid_m)
     begin
        // Set the correct bit
        i_rid_m = rid_m[1:0];
        loc_rsel[i_rid_m] = 1'b1;
        rsel = loc_rsel;
     end else
     begin
        i_rid_m = {2{1'b0}};
        rsel = {3{1'b0}};
     end 
   end // p_r_ret_sel


   assign bvalid_masked = bvalid_m & ~wr_cnt_empty;

   //------------------------- Write Response De-Mux --------------------------

    assign bid_s0  = bid_m & {8{bsel[0]}};
    assign bresp_s0  = bresp_m & {2{bsel[0]}};
    assign bvalid_s0  = bvalid_masked & bsel[0];

    assign bid_s1  = bid_m & {8{bsel[1]}};
    assign bresp_s1  = bresp_m & {2{bsel[1]}};
    assign bvalid_s1  = bvalid_masked & bsel[1];

    assign bid_s2  = bid_m & {8{bsel[2]}};
    assign bresp_s2  = bresp_m & {2{bsel[2]}};
    assign bvalid_s2  = bvalid_masked & bsel[2];


   //-------------------------- Read Channel De-Mux ---------------------------

    assign rid_s0 = rid_m & {8{rsel[0]}};
    assign rdata_s0 = rdata_m & {64{rsel[0]}};
    assign rresp_s0 = rresp_m & {2{rsel[0]}};
    assign rlast_s0 = rlast_m & rsel[0];
    assign rvalid_s0 = rvalid_m & rsel[0];

    assign rid_s1 = rid_m & {8{rsel[1]}};
    assign rdata_s1 = rdata_m & {64{rsel[1]}};
    assign rresp_s1 = rresp_m & {2{rsel[1]}};
    assign rlast_s1 = rlast_m & rsel[1];
    assign rvalid_s1 = rvalid_m & rsel[1];

    assign rid_s2 = rid_m & {8{rsel[2]}};
    assign rdata_s2 = rdata_m & {64{rsel[2]}};
    assign rresp_s2 = rresp_m & {2{rsel[2]}};
    assign rlast_s2 = rlast_m & rsel[2];
    assign rvalid_s2 = rvalid_m & rsel[2];


    // Mask the ready signals back to the current slave interface
    assign bready_masked0 = bready_s0 & bsel[0];
    assign rready_masked0 = rready_s0 & rsel[0];
    assign bready_masked1 = bready_s1 & bsel[1];
    assign rready_masked1 = rready_s1 & rsel[1];
    assign bready_masked2 = bready_s2 & bsel[2];
    assign rready_masked2 = rready_s2 & rsel[2];

    // Mux the masked ready signals back to the master interface
    assign bready_comb = bready_masked0 | bready_masked1 | bready_masked2;
    assign bready_m = bready_comb & ~wr_cnt_empty;
    assign rready_m = rready_masked0 | rready_masked1 | rready_masked2;


//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off
`ifdef ARM_ASSERT_ON


assert_never #(1,0,"ERROR, RID SIID received larger than local no of slave if's")
ovl_assert_illegal_rid
   (
    .clk       (nic400_bm0_1.aclk),
    .reset_n   (nic400_bm0_1.aresetn),
    .test_expr (p_r_ret_sel.i_rid_m > 3));

assert_never #(1,0,"ERROR, BID SIID received larger than local no of slave if's")
ovl_assert_illegal_bid
   (
    .clk       (nic400_bm0_1.aclk),
    .reset_n   (nic400_bm0_1.aresetn),
    .test_expr (p_b_ret_sel.i_bid_m > 3));



`endif
// synopsys translate_on

endmodule

//  --=============================== End ====================================--

