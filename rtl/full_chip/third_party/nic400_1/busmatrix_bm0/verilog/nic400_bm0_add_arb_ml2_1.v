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
//  File Revision       : 133220
//
//  Date                :  2012-07-05 21:48:32 +0100 (Thu, 05 Jul 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//  ----------------------------------------------------------------------------
//------------------------------------------------------------------------------
//  File Purpose        : Single cycle arbitration based on quality value (QV)
//                        Mask vector values set on bit basis to mask slave
//                        interfaces individually if required.
//  
//  Key Configuration Details-
//      - Arbitrating 3 slave interfaces
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//   *_m<n> suffix to denote a MasterInterface (connect to external AXI slave)
//   *_s0 suffix to denote the SlaveInterface  (connect to external AXI master) 
//
//------------------------------------------------------------------------------

`include "reg_slice_axi_defs.v"
//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_add_arb_ml2_1
  (
    // Address Select Ouput 
    a_sel,
    // Input Select Criteria 
    a_valid_vector,
    aready,
    mask,
    qv0,
    qv1,
    qv2,
    // Miscelaneous connections
    aclk,
    aresetn
  );


  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------



  parameter REQUESTS      = 3;
  parameter QOS_WIDTH     = 4;

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  // Select Address Channel
  output [2:0]      a_sel;
  // Input Select Criteria 
  input  [2:0]      a_valid_vector;
  input             aready;
  input  [2:0]      mask;
  input  [3:0]      qv0;
  input  [3:0]      qv1;
  input  [3:0]      qv2;

  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //----------------------------------------------------------------------------
  // Wires 
  //----------------------------------------------------------------------------

  wire              update;    // signal to indicate LRG list needs updating
  wire  [2:0]       a_sel;      // Output selection
  wire              valid_op;    // Unary OR of the valid output vector
  wire              next_stall;    // Next stall arbitration control signal
  wire              sel_en;    // Enable to store select if stalled
  wire  [2:0]       int_sel;    // selected slave interface number

  wire  [(REQUESTS*QOS_WIDTH)-1:0]  request_qos;
  wire  [REQUESTS-1:0]              request;
  wire  [QOS_WIDTH-1:0]             max_qos;
  wire  [REQUESTS-1:0]              is_highest_qos;
  wire  [2:0]       qv_valids ;    // 
 
  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------

  reg               stall;    // Stall arbitration control signal
  reg   [2:0]       reg_sel;     // Registered select

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------



  //-------------------- Detect arbitratrion cycle timing ---------------------

   // Detect when an arbitrated valid handshake doesn't complete so that
   // the arbitration can be stalled to maintain the sticky valid
   assign valid_op = |a_sel;
   assign next_stall = (valid_op & ~aready);

   always @(posedge aclk or negedge aresetn)
     begin : p_stall_seq
       if (!aresetn)
         begin
          stall <= 1'b0;
        end
       else
         begin
          stall <= next_stall;
        end
     end // p_stall_seq


   // Concatanate all the qos values
   assign request_qos = {qv2 ,
                        qv1 ,
                        qv0};
// ---------------------------------------------------------------------------
// QOS Arbitration
// ---------------------------------------------------------------------------

  assign qv_valids = a_valid_vector;

nic400_bm0_qv_cmp_1 #(.REQUESTS (REQUESTS), .QOS_WIDTH (QOS_WIDTH)) u_highest_qos (
 .request_valids (qv_valids),   
 .request_qos    (request_qos),      
 .highest_mh     (is_highest_qos),
 .highest_qos    (max_qos)
);

// ---------------------------------------------------------------------------
// Valid Squelch
//   Suppresses valid signals based on the
//   following method:
//
//   -- QV priority.  If the requestor does not have the highest QOS value,
//      the request is squelched.
// ---------------------------------------------------------------------------

assign request = is_highest_qos & ~mask;

// ---------------------------------------------------------------------------
// LRG Arbitration
// ---------------------------------------------------------------------------

assign update = (|request &  ~stall);

nic400_bm0_lrg_arb_1 #(.WIDTH(REQUESTS)) u_lrg_arb (
  .aclk       (aclk),
  .aresetn    (aresetn),
  .update_en  (update),
  .request    (request),
  .grant      (int_sel)
);


  




  //------------------------- Update Selected Output --------------------------


   always @(posedge aclk or negedge aresetn)
     begin : p_a_sel_seq
       if (!aresetn)
         begin
          reg_sel <= {3{1'b0}};
        end
       else if (sel_en)
         begin
          reg_sel <= int_sel;
        end
     end // p_a_sel_seq
 
   assign sel_en = (next_stall & ~stall);

   assign a_sel = stall ? reg_sel : int_sel;

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON

   assert_zero_one_hot #(0,3,0,"ERROR, More than one slave interface arbitrated")
     ovl_slave_if_arb
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (a_sel)
        );

   assert_never #(0,0,"ERROR, No transaction was arbitrated when expected") 
      ovl_lrg_always_arb
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr ((|(a_valid_vector & ~mask)) && (~|a_sel))
       );

   
   assert_implication #(0, 0, "ERROR, Higher QV than selected available on port 0")
     ovl_high_qv_avail0
      (
       .clk             (aclk),
       .reset_n         (aresetn),
       .antecedent_expr (a_valid_vector[0]),
       .consequent_expr (max_qos >= qv0)
     );
   
   assert_implication #(0, 0, "ERROR, Higher QV than selected available on port 1")
     ovl_high_qv_avail1
      (
       .clk             (aclk),
       .reset_n         (aresetn),
       .antecedent_expr (a_valid_vector[1]),
       .consequent_expr (max_qos >= qv1)
     );
   
   assert_implication #(0, 0, "ERROR, Higher QV than selected available on port 2")
     ovl_high_qv_avail2
      (
       .clk             (aclk),
       .reset_n         (aresetn),
       .antecedent_expr (a_valid_vector[2]),
       .consequent_expr (max_qos >= qv2)
     );
   
`endif
// synopsys translate_on


  endmodule

`include "reg_slice_axi_undefs.v"

//  --=============================== End ====================================--

