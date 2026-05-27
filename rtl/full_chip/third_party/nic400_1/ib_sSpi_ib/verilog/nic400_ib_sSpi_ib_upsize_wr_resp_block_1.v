//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 168940
// File Date           :  2014-03-13 13:26:17 +0000 (Thu, 13 Mar 2014)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : This module is responsible for removing extra Responses from the B
//           channel
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//  Config :
//           o  Outstanding write responses  = 4
//
//------------------------------------------------------------------------------
module nic400_ib_sSpi_ib_upsize_wr_resp_block_1
  (
  //Inputs
  bvalid_m,
  bready_s,
  bresp_m,
  bid_m,

  bchannel_ready,

  //Inputs
  bchannel_valid,
  bchannel_data,

  //Outputs
  bvalid_s,
  bready_m,
  bid_s,
  bresp_s,

  aclk,
  aresetn
  );

`include "nic400_ib_sSpi_ib_defs_1.v"

  //System
  input                   aclk;
  input                   aresetn;

  // AWID
  output                  bchannel_ready;   //Used to stop the AW when response Queue is full

  // BCHANNEL outputs
  output                  bvalid_s;          //BVALID being sent to narrow bus
  output                  bready_m;          //BREADY being sent onto wide bus
  output [1:0]            bid_s;             //BID being sent
  output [1:0]            bresp_s;           //BRESP being sent

  //BCHANNEL inputs
  input                   bvalid_m;
  input                   bready_s;
  input [1:0]             bid_m;
  input [1:0]             bresp_m;

  //Control inputs
  input                   bchannel_valid;
  input [2:0]             bchannel_data;

  //------------------------------------------------------------------------
  // Wires
  //------------------------------------------------------------------------

   wire [3:0]             match_bus;
   wire [3:0]             hazard_bus;

   wire [3:0]             valid_bus;
   wire                   match;              //a match has occured
   wire                   hazard;             //hazard detected

   wire                   bready_m_i;
   wire                   bhndshk;

   wire                   push_slice;
   wire                   pop_slice;          //push and pop signals for the CAM Slices
   wire                   update;
   

   wire [1:0]             awid;
   wire                   n_response;
   wire                   next_bchannel_ready;
   
   wire [1:0]             bresp_out_0;
   wire [1:0]             bresp_out_1;
   wire [1:0]             bresp_out_2;
   wire [1:0]             bresp_out_3;
    
  //------------------------------------------------------------------------
  // Regs
  //------------------------------------------------------------------------

   reg [1:0]              hazard_pointer;
   reg [1:0]              match_pointer;

   reg [3:0]              store;

   reg                    bchannel_ready_i;  

  //------------------------------------------------------------------------
  // Decode bchannel Data
  //------------------------------------------------------------------------

   assign awid = bchannel_data[2:1];
   assign n_response = bchannel_data[0];
  //------------------------------------------------------------------------
  // Main Code
  //------------------------------------------------------------------------

   //match
   assign match = |match_bus;

   //hazard
   assign hazard = |hazard_bus;

   //Not ready if all Slices are full (unless one is about to be emptied)
   //A slot will be emptied on match and update
   assign next_bchannel_ready = ~(&(valid_bus | (store & {4{push_slice}}))) || (pop_slice);

   //Registered bchannel ready
   always @(posedge aclk or negedge aresetn)
    begin : bchannel_seq
      if (!aresetn)
         bchannel_ready_i <= 1'b0;
      else
         bchannel_ready_i <= next_bchannel_ready;
    end //bchannel_seq

   assign bchannel_ready = bchannel_ready_i;
   //store decode Logic
   always @(valid_bus or match_bus)
     begin : store_decode
        if (!valid_bus[0])
           store = 4'b0001;
         else if (!valid_bus[1])
            store = 4'b0010;
         else if (!valid_bus[2])
            store = 4'b0100;
         else if (!valid_bus[3])
            store = 4'b1000;
        else
            store = match_bus;
      end // store_decode

    //Distribute the number of the Slice reporting a hazard
   always @(hazard_bus)
     begin : hazard_num_distibution
       case (hazard_bus)
          4'b0 : hazard_pointer = 2'b0;
           4'd1 : hazard_pointer = 2'd0;
          4'd2 : hazard_pointer = 2'd1;
          4'd4 : hazard_pointer = 2'd2;
          4'd8 : hazard_pointer = 2'd3;
         default : hazard_pointer = 2'bx;
       endcase
     end

    //Distribute the number of the Slice reporting a match
   always @(match_bus)
     begin : match_num_distibution
       case (match_bus)
          4'b0 : match_pointer = 2'b0;
           4'd1 : match_pointer = 2'd0;
          4'd2 : match_pointer = 2'd1;
          4'd4 : match_pointer = 2'd2;
          4'd8 : match_pointer = 2'd3;
         default : match_pointer = 2'bx;
       endcase
     end

    //Indicate that that data is being written form the AWChannel
    assign push_slice = bchannel_ready_i && bchannel_valid;

    //Indicate incoming on B channel
    assign bhndshk = bvalid_m && bready_m_i;
    assign update = bhndshk;
    assign pop_slice = update && match;

   //------------------------------------------------------------------------
   // B channel Control
   //------------------------------------------------------------------------

    //Output BREADY
    assign bready_m_i = bvalid_m && (bready_s || ~match);
    assign bready_m   = bready_m_i;
    //bchannel outputs
    assign bid_s = bid_m;
    assign bresp_s = (bresp_m
                      |  bresp_out_0
                      |  bresp_out_1
                      |  bresp_out_2
                      |  bresp_out_3 );

    //BVALID is only sent if a match is detected
    assign bvalid_s = (bvalid_m && match);


   //------------------------------------------------------------------------
   // CAM SLices
   //------------------------------------------------------------------------

    
     //Cam Slice number 0 //

     nic400_ib_sSpi_ib_upsize_resp_cam_slice_1 u_upsize_resp_cam_slice_0
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .matchid              (bid_m),
        .hazardid             (awid),

        //Control Signals
        .store                (store[0]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        .n_response           (n_response),
        .bresp_in             (bresp_m),

        //Outputs
        .hazard               (hazard_bus[0]),
        .match                (match_bus[0]),
        .valid                (valid_bus[0]),
        .bresp_out            (bresp_out_0)
     );
     
     //Cam Slice number 1 //

     nic400_ib_sSpi_ib_upsize_resp_cam_slice_1 u_upsize_resp_cam_slice_1
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .matchid              (bid_m),
        .hazardid             (awid),

        //Control Signals
        .store                (store[1]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        .n_response           (n_response),
        .bresp_in             (bresp_m),

        //Outputs
        .hazard               (hazard_bus[1]),
        .match                (match_bus[1]),
        .valid                (valid_bus[1]),
        .bresp_out            (bresp_out_1)
     );
     
     //Cam Slice number 2 //

     nic400_ib_sSpi_ib_upsize_resp_cam_slice_1 u_upsize_resp_cam_slice_2
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .matchid              (bid_m),
        .hazardid             (awid),

        //Control Signals
        .store                (store[2]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        .n_response           (n_response),
        .bresp_in             (bresp_m),

        //Outputs
        .hazard               (hazard_bus[2]),
        .match                (match_bus[2]),
        .valid                (valid_bus[2]),
        .bresp_out            (bresp_out_2)
     );
     
     //Cam Slice number 3 //

     nic400_ib_sSpi_ib_upsize_resp_cam_slice_1 u_upsize_resp_cam_slice_3
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .matchid              (bid_m),
        .hazardid             (awid),

        //Control Signals
        .store                (store[3]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        .n_response           (n_response),
        .bresp_in             (bresp_m),

        //Outputs
        .hazard               (hazard_bus[3]),
        .match                (match_bus[3]),
        .valid                (valid_bus[3]),
        .bresp_out            (bresp_out_3)
     );
     


`ifdef ARM_ASSERT_ON
`include "std_ovl_defines.h"

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that only one Slice ever matches
   //------------------------------------------------------------------------
   // If more than one slot matches the hazard detection logic has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_zero_one_hot #(`OVL_FATAL,4,0,"More than one B Channel Slice matched")
  ovl_single_ID_match
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        ({4{bvalid_m}} & match_bus)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that only one Slice ever reports a hazard
   //------------------------------------------------------------------------
   // If more than one slot matches the last detection logic has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_zero_one_hot #(`OVL_FATAL,4,0,"More than one B Channel Slice hazard")
  ovl_single_hazard
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        ({4{bchannel_valid}} & hazard_bus)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that there is never an incoming transaction when there are
   //             no valid slices
   //------------------------------------------------------------------------
   // If no slices are valid then something has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_never #(`OVL_FATAL,`OVL_ASSERT,"No slices are valid and there is an incoming transaction")
  ovl_bslice_none_valid
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        (~|valid_bus && bvalid_m)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that if an incoming transaction has an ex_okay resp
   //             then it must match a slice .. and be output as an ex_okay
   //------------------------------------------------------------------------
   // If no slices are valid then something has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,`OVL_ASSERT,"ex_okay reponses lost")
  ovl_exokay_lost
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (bvalid_m && bresp_m == 2'b01),
     .consequent_expr  (match && bresp_s == 2'b01)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: This block has a normal V/R handshake input. However, in all
   // NIC400 configurations. Valid should only ever asserted when ready is.
   //------------------------------------------------------------------------
   // Handshake error
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,`OVL_ASSERT,"B Channel HndShk Error")
  ovl_input_hndshk_error
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (bchannel_valid),
     .consequent_expr  (bchannel_ready_i)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: HandShk tracking
   //------------------------------------------------------------------------
   // Check for handshake under/overflow
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
   assert_fifo_index #(`OVL_FATAL, 4, 1, 1, 0,"ERROR, BChannel Look-Up under or overflowed")
      ovl_bchannel_fifo_index
         (
           .clk       (aclk),
           .reset_n   (aresetn),
           .push      (bchannel_ready_i && bchannel_valid),
           .pop       (bvalid_s && bready_s)
         );
   // OVL_ASSERT_END


  // CAM ID Registers
  wire [1:0] cam_id_reg [0:3];

  assign cam_id_reg[0] = u_upsize_resp_cam_slice_0.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 0 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 0 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 0 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_0_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[0] && u_upsize_resp_cam_slice_0.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_resp_cam_slice_0.pointer_reg] && (cam_id_reg[0] == cam_id_reg[u_upsize_resp_cam_slice_0.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 0 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 0 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 0 is last but is pointed to by another valid CAM")
  ovl_cam_0_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[0] && u_upsize_resp_cam_slice_0.last_reg),
     .consequent_expr  (!(
                          (valid_bus[1] && u_upsize_resp_cam_slice_1.hazard_reg && u_upsize_resp_cam_slice_1.pointer_reg == 0) ||
                          (valid_bus[2] && u_upsize_resp_cam_slice_2.hazard_reg && u_upsize_resp_cam_slice_2.pointer_reg == 0) ||
                          (valid_bus[3] && u_upsize_resp_cam_slice_3.hazard_reg && u_upsize_resp_cam_slice_3.pointer_reg == 0)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[1] = u_upsize_resp_cam_slice_1.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 1 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 1 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 1 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_1_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[1] && u_upsize_resp_cam_slice_1.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_resp_cam_slice_1.pointer_reg] && (cam_id_reg[1] == cam_id_reg[u_upsize_resp_cam_slice_1.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 1 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 1 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 1 is last but is pointed to by another valid CAM")
  ovl_cam_1_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[1] && u_upsize_resp_cam_slice_1.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_resp_cam_slice_0.hazard_reg && u_upsize_resp_cam_slice_0.pointer_reg == 1) ||
                          (valid_bus[2] && u_upsize_resp_cam_slice_2.hazard_reg && u_upsize_resp_cam_slice_2.pointer_reg == 1) ||
                          (valid_bus[3] && u_upsize_resp_cam_slice_3.hazard_reg && u_upsize_resp_cam_slice_3.pointer_reg == 1)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[2] = u_upsize_resp_cam_slice_2.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 2 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 2 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 2 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_2_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[2] && u_upsize_resp_cam_slice_2.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_resp_cam_slice_2.pointer_reg] && (cam_id_reg[2] == cam_id_reg[u_upsize_resp_cam_slice_2.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 2 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 2 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 2 is last but is pointed to by another valid CAM")
  ovl_cam_2_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[2] && u_upsize_resp_cam_slice_2.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_resp_cam_slice_0.hazard_reg && u_upsize_resp_cam_slice_0.pointer_reg == 2) ||
                          (valid_bus[1] && u_upsize_resp_cam_slice_1.hazard_reg && u_upsize_resp_cam_slice_1.pointer_reg == 2) ||
                          (valid_bus[3] && u_upsize_resp_cam_slice_3.hazard_reg && u_upsize_resp_cam_slice_3.pointer_reg == 2)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[3] = u_upsize_resp_cam_slice_3.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 3 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 3 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 3 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_3_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[3] && u_upsize_resp_cam_slice_3.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_resp_cam_slice_3.pointer_reg] && (cam_id_reg[3] == cam_id_reg[u_upsize_resp_cam_slice_3.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 3 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 3 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(`OVL_FATAL,0,"CAM 3 is last but is pointed to by another valid CAM")
  ovl_cam_3_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[3] && u_upsize_resp_cam_slice_3.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_resp_cam_slice_0.hazard_reg && u_upsize_resp_cam_slice_0.pointer_reg == 3) ||
                          (valid_bus[1] && u_upsize_resp_cam_slice_1.hazard_reg && u_upsize_resp_cam_slice_1.pointer_reg == 3) ||
                          (valid_bus[2] && u_upsize_resp_cam_slice_2.hazard_reg && u_upsize_resp_cam_slice_2.pointer_reg == 3)))
     );
  // OVL_ASSERT_END
  

`endif

`include "nic400_ib_sSpi_ib_undefs_1.v"

endmodule
