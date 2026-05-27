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
// File Revision       : 180332
// File Date           :  2014-09-08 11:00:02 +0100 (Mon, 08 Sep 2014)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose             : This module is responsible for muxing the upsizer R 
//                       data channel, mapping larger RData beats onto the 
//                       smaller upstream data bus.
//                       This module lives in the IB Slave Domain.
//                       This module will also mask the larger rlast to the 
//                       final, narrower rdata beat.
//                       It contains a single register for storing the data this 
//                       is so it can be used without an attached fifo. 
//                       (the V/R will attach directly to the AXI R channel)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//  Config :
//           o  Outstanding Reads  = 4
//
//------------------------------------------------------------------------------

module nic400_ib_sSpi_ib_upsize_rd_chan_1
  (
  //rchannel Outputs
  rvalid_s,
  rdata_s,
  rlast_s,
  rid_s,
  rresp_s,

  //rchannel Inputs
  rready_s,

  //rchannel Inputs
  rvalid_m,
  rdata_m,
  rlast_m,
  rid_m,
  rresp_m,

  //rchannel Outputs
  rready_m,

  //From the Archannel forward block
  archannel_data,
  archannel_valid,
  archannel_ready,

  aclk,
  aresetn
  );

`include "nic400_ib_sSpi_ib_defs_1.v"

  //System
  input                     aclk;
  input                     aresetn;

  // To/From the Archannel forward block
  input                     archannel_valid;
  output                    archannel_ready;
  input [16:0]              archannel_data;

  // To/From the RFIFO
  input                     rvalid_m;
  output                    rready_m;

  input [63:0]              rdata_m;
  input [1:0]               rid_m;
  input [1:0]               rresp_m;
  input                     rlast_m;

  //Slave Bus rchannel signals
  input                     rready_s;

  output                    rvalid_s;
  output [31:0]             rdata_s;
  output [1:0]              rid_s;
  output [1:0]              rresp_s;
  output                    rlast_s;

   //------------------------------------------------------------------------
   // Wires
   //------------------------------------------------------------------------

   wire                                                archannel_ready_i;
   wire [3:0]               match_bus;
   wire [3:0]               hazard_bus;
   wire [3:0]               valid_bus;
   wire [3:0]               last_addr_match_bus;
   wire [3:0]               beat_complete_slice_bus;

   wire                     hazard;           //Hazard detected
   wire                     last_addr_match;  //Signal to move to next beat
   wire                     beat_complete_slice;

   wire                     archannel_hndshk;
   wire                     rchannel_hndshk;

   wire                     push_slice;
   wire                     pop_slice;          //push and pop_slice signals for the CAM Slices
   wire                     update;

   wire                     beat_complete;

   wire                     data_select;

   wire                     addr;
   
   wire [1:0]               rid_m;

   //These are signals muxed between data from the rchannel or it's register version
   wire [63:0]              rdata;
   wire                     rlast_in;
   wire                     rlast_s_i;
   wire [1:0]               rresp_s;
   wire                     addr_out0;
   wire                     addr_out1;
   wire                     addr_out2;
   wire                     addr_out3;

   //byte mask for read data
   wire [3:0]               rdata_byte_mask0;
   wire [3:0]               rdata_byte_mask1;
   wire [3:0]               rdata_byte_mask2;
   wire [3:0]               rdata_byte_mask3;
   wire [3:0]               rdata_byte_mask;

   wire [31:0]              rdata_beat_mask;

   wire [31:0]              rdata_s;

   //------------------------------------------------------------------------
   // Regs
   //------------------------------------------------------------------------

   reg [31:0]               rdata_s_demux;
   reg [1:0]                hazard_pointer;
   reg [1:0]                match_pointer;

   reg [3:0]                store;

   //------------------------------------------------------------------------
   // Decode RFIFO data
   //------------------------------------------------------------------------

   assign rid_s = rid_m;
   assign rlast_in = rlast_m;
   assign rresp_s = rresp_m;
   assign rdata = rdata_m;


   //------------------------------------------------------------------------
   // Combine Signals from Cam Slices
   //------------------------------------------------------------------------

   //Hazard
   assign hazard = |hazard_bus;

   //Last
   assign last_addr_match = |(last_addr_match_bus & match_bus);

   //Bypass
   assign beat_complete_slice = |(beat_complete_slice_bus & match_bus);

   //Select addr values;
   assign addr = addr_out0
               | addr_out1
               | addr_out2
               | addr_out3;

   //Select rdata byte mask;
   assign rdata_byte_mask = rdata_byte_mask0
                          | rdata_byte_mask1
                          | rdata_byte_mask2
                          | rdata_byte_mask3;

   assign rdata_beat_mask = {{8{rdata_byte_mask[3]}},
                             {8{rdata_byte_mask[2]}},
                             {8{rdata_byte_mask[1]}},
                             {8{rdata_byte_mask[0]}}};
  
   //------------------------------------------------------------------------
   // Calculate address increment
   //------------------------------------------------------------------------

   //Set data_Select
   assign data_select = addr;

   //------------------------------------------------------------------------
   // Set rdata demux & RLAST generatation
   //------------------------------------------------------------------------

   always @(data_select or rdata)
     begin : rdata_demux
     case (data_select)
         1'd0 : rdata_s_demux = rdata[31:0];
         1'd1 : rdata_s_demux = rdata[63:32];
         default : rdata_s_demux = 32'bx;
        endcase
     end // rdata_demux

   //mask out unused byte lanes
   assign rdata_s = rdata_s_demux & rdata_beat_mask;


   
   assign rlast_s_i = last_addr_match  && rlast_in;
   assign rlast_s   = rlast_s_i;
   //------------------------------------------------------------------------
   // Valid/Ready Generation for all signals
   //------------------------------------------------------------------------

   //Archannel_ready is true when there is an empty slice (or about to be)
   assign archannel_ready_i = ~&valid_bus;
   assign archannel_ready   = archannel_ready_i;
   //Detect AR channel handshake
   assign archannel_hndshk = archannel_ready_i && archannel_valid;

   //A slice is pushed when an AR channel handhake.
   //It is identifed by push and store signals
   assign push_slice = archannel_hndshk;

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

   //Distribute the number of the Slice reporting a Hazard
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

   //Distribute the number of the Slice reporting a Hazard
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

   //Detect a complete beat
   assign beat_complete = (rlast_s_i | beat_complete_slice) && update;


   //rchannel_ready
   assign rready_m = beat_complete && rvalid_m;


   //RVALIDS is alwyas true wheile there is valid data in the device
   assign rvalid_s = rvalid_m;


   //Detect handshake on the Slave R Channel
   assign rchannel_hndshk = rvalid_m && rready_s;

   //The addr registers are updated on every handshake on the Rchannel
   assign update = rchannel_hndshk;

   //The Selcted cam Slice is pop when an Slce R Channel handsake with RLAST occurs
   assign pop_slice = update && rlast_s_i;

   //------------------------------------------------------------------------
   // CAM SLices
   //------------------------------------------------------------------------

    
     //Cam Slice number 0 //
     nic400_ib_sSpi_ib_upsize_rd_cam_slice_1 u_upsize_rd_cam_slice_0
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .match_id              (rid_m),

        //Control Signals
        .store                (store[0]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .archannel_data       (archannel_data),
        .rlast_in             (rlast_in),
        
        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        //Outputs
        .hazard               (hazard_bus[0]),
        .match                (match_bus[0]),
        .valid                (valid_bus[0]),
        .addr_out             (addr_out0),
        .last_addr_match      (last_addr_match_bus[0]),
        .beat_complete        (beat_complete_slice_bus[0]),
        .rdata_byte_mask      (rdata_byte_mask0)
     );
     
     //Cam Slice number 1 //
     nic400_ib_sSpi_ib_upsize_rd_cam_slice_1 u_upsize_rd_cam_slice_1
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .match_id              (rid_m),

        //Control Signals
        .store                (store[1]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .archannel_data       (archannel_data),
        .rlast_in             (rlast_in),
        
        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        //Outputs
        .hazard               (hazard_bus[1]),
        .match                (match_bus[1]),
        .valid                (valid_bus[1]),
        .addr_out             (addr_out1),
        .last_addr_match      (last_addr_match_bus[1]),
        .beat_complete        (beat_complete_slice_bus[1]),
        .rdata_byte_mask      (rdata_byte_mask1)
     );
     
     //Cam Slice number 2 //
     nic400_ib_sSpi_ib_upsize_rd_cam_slice_1 u_upsize_rd_cam_slice_2
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .match_id              (rid_m),

        //Control Signals
        .store                (store[2]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .archannel_data       (archannel_data),
        .rlast_in             (rlast_in),
        
        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        //Outputs
        .hazard               (hazard_bus[2]),
        .match                (match_bus[2]),
        .valid                (valid_bus[2]),
        .addr_out             (addr_out2),
        .last_addr_match      (last_addr_match_bus[2]),
        .beat_complete        (beat_complete_slice_bus[2]),
        .rdata_byte_mask      (rdata_byte_mask2)
     );
     
     //Cam Slice number 3 //
     nic400_ib_sSpi_ib_upsize_rd_cam_slice_1 u_upsize_rd_cam_slice_3
     (
         // global signals
        .aresetn              (aresetn),
        .aclk                 (aclk),

        // ID inputs (to all slices)
        .match_id              (rid_m),

        //Control Signals
        .store                (store[3]),
        .push_slice           (push_slice),
        .pop_slice            (pop_slice),
        .update               (update),
        .match_pointer        (match_pointer),

        .archannel_data       (archannel_data),
        .rlast_in             (rlast_in),
        
        .hazard_in            (hazard),
        .hazard_pointer       (hazard_pointer),

        //Outputs
        .hazard               (hazard_bus[3]),
        .match                (match_bus[3]),
        .valid                (valid_bus[3]),
        .addr_out             (addr_out3),
        .last_addr_match      (last_addr_match_bus[3]),
        .beat_complete        (beat_complete_slice_bus[3]),
        .rdata_byte_mask      (rdata_byte_mask3)
     );
     


`ifdef ARM_ASSERT_ON
`include "std_ovl_defines.h"

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that only one Slice ever matches
   //------------------------------------------------------------------------
   // If more than one slot matches the hazard detection logic has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_zero_one_hot #(`OVL_FATAL,4,`OVL_ASSERT,"More than one Rd Channel Slice matched")
  ovl_single_ID_match
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        ({4{rchannel_hndshk}} & match_bus)
     );
   // OVL_ASSERT_END

   //------------------------------------------------------------------------
   // OVL_ASSERT: Check that only one Slice ever reports a hazard
   //------------------------------------------------------------------------
   // If more than one slot matches the last detection logic has gone wrong
   //------------------------------------------------------------------------

   // OVL_ASSERT_RTL
  assert_zero_one_hot #(`OVL_FATAL,4,`OVL_ASSERT,"More than one Rd Channel Slice hazard")
  ovl_single_hazard
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .test_expr        ({4{archannel_hndshk}} & hazard_bus)
     );
   // OVL_ASSERT_END


  // CAM ID Registers
  wire [1:0]    cam_id_reg [0:3];

  assign cam_id_reg[0] = u_upsize_rd_cam_slice_0.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 0 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 0 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 0 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_0_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[0] && u_upsize_rd_cam_slice_0.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_rd_cam_slice_0.pointer_reg] && (cam_id_reg[0] == cam_id_reg[u_upsize_rd_cam_slice_0.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 0 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 0 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 0 is last but is pointed to by another valid CAM")
  ovl_cam_0_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[0] && u_upsize_rd_cam_slice_0.last_reg),
     .consequent_expr  (!(
                          (valid_bus[1] && u_upsize_rd_cam_slice_1.hazard_reg && u_upsize_rd_cam_slice_1.pointer_reg == 0) ||
                          (valid_bus[2] && u_upsize_rd_cam_slice_2.hazard_reg && u_upsize_rd_cam_slice_2.pointer_reg == 0) ||
                          (valid_bus[3] && u_upsize_rd_cam_slice_3.hazard_reg && u_upsize_rd_cam_slice_3.pointer_reg == 0)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[1] = u_upsize_rd_cam_slice_1.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 1 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 1 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 1 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_1_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[1] && u_upsize_rd_cam_slice_1.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_rd_cam_slice_1.pointer_reg] && (cam_id_reg[1] == cam_id_reg[u_upsize_rd_cam_slice_1.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 1 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 1 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 1 is last but is pointed to by another valid CAM")
  ovl_cam_1_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[1] && u_upsize_rd_cam_slice_1.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_rd_cam_slice_0.hazard_reg && u_upsize_rd_cam_slice_0.pointer_reg == 1) ||
                          (valid_bus[2] && u_upsize_rd_cam_slice_2.hazard_reg && u_upsize_rd_cam_slice_2.pointer_reg == 1) ||
                          (valid_bus[3] && u_upsize_rd_cam_slice_3.hazard_reg && u_upsize_rd_cam_slice_3.pointer_reg == 1)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[2] = u_upsize_rd_cam_slice_2.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 2 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 2 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 2 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_2_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[2] && u_upsize_rd_cam_slice_2.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_rd_cam_slice_2.pointer_reg] && (cam_id_reg[2] == cam_id_reg[u_upsize_rd_cam_slice_2.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 2 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 2 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 2 is last but is pointed to by another valid CAM")
  ovl_cam_2_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[2] && u_upsize_rd_cam_slice_2.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_rd_cam_slice_0.hazard_reg && u_upsize_rd_cam_slice_0.pointer_reg == 2) ||
                          (valid_bus[1] && u_upsize_rd_cam_slice_1.hazard_reg && u_upsize_rd_cam_slice_1.pointer_reg == 2) ||
                          (valid_bus[3] && u_upsize_rd_cam_slice_3.hazard_reg && u_upsize_rd_cam_slice_3.pointer_reg == 2)))
     );
  // OVL_ASSERT_END
  
  assign cam_id_reg[3] = u_upsize_rd_cam_slice_3.id_reg;

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 3 pointing at valid CAM with same ID
  //------------------------------------------------------------------------
  // Check that if CAM 3 is valid and not at top then it points to
  // another valid CAM that has the same ID
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 3 is valid but does not point to another valid CAM with the same ID")
  ovl_cam_3_valid_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[3] && u_upsize_rd_cam_slice_3.hazard_reg),
     .consequent_expr  (valid_bus[u_upsize_rd_cam_slice_3.pointer_reg] && (cam_id_reg[3] == cam_id_reg[u_upsize_rd_cam_slice_3.pointer_reg]))
     );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: CAM 3 not pointed to when last
  //------------------------------------------------------------------------
  // Check that if CAM 3 is valid and is last then no other
  // valid CAM points to it
  //------------------------------------------------------------------------

  // OVL_ASSERT_RTL
  assert_implication #(0,0,"CAM 3 is last but is pointed to by another valid CAM")
  ovl_cam_3_no_last_link
    (
     .clk              (aclk),
     .reset_n          (aresetn),
     .antecedent_expr  (valid_bus[3] && u_upsize_rd_cam_slice_3.last_reg),
     .consequent_expr  (!(
                          (valid_bus[0] && u_upsize_rd_cam_slice_0.hazard_reg && u_upsize_rd_cam_slice_0.pointer_reg == 3) ||
                          (valid_bus[1] && u_upsize_rd_cam_slice_1.hazard_reg && u_upsize_rd_cam_slice_1.pointer_reg == 3) ||
                          (valid_bus[2] && u_upsize_rd_cam_slice_2.hazard_reg && u_upsize_rd_cam_slice_2.pointer_reg == 3)))
     );
  // OVL_ASSERT_END
  

`endif

endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"

