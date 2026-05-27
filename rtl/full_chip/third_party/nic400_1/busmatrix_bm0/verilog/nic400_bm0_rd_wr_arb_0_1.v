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
//------------------------------------------------------------------------------
//  File Purpose        : Module for a bus matrix arbitration node used
//                        to arbitrate between AR and AW channels when there 
//                        are co-incident transactions.
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

module nic400_bm0_rd_wr_arb_0_1
  (
    wr_override,
    rd_override,
    last_slot,
    wr_reqd_qv,
    rd_reqd_qv,
    // Master Interface address channel handshake signals
    awvalid,
    awvalid_m,
    awready_m,
    arvalid,
    arvalid_m,
    arready_m,
    // Miscelaneous connections
    aclk,
    aresetn
  );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  output            wr_override;
  output            rd_override;
  input             last_slot;
  input  [3:0]      wr_reqd_qv;
  input  [3:0]      rd_reqd_qv;
  // Master Interface address channel handshake signals
  input             awvalid;
  input             awvalid_m;
  input             awready_m;
  input             arvalid;
  input             arvalid_m;
  input             arready_m;
  // Miscelaneous connections
  input             aclk;
  input             aresetn;


  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------
  
  reg           priority_upd;
  wire          rd_priority;
  wire          wr_priority;
  reg           wr_override;
  reg           rd_override;
  wire          next_stall_rd;
  wire          next_stall_wr;
  wire          last_slot_en;

  //------------------------------------------------------------------------------
  // Registers 
  //------------------------------------------------------------------------------

  reg           rw_priority;
  reg           stall_rd;
  reg           stall_wr;

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  assign next_stall_rd = (arvalid_m & ~arready_m);
  assign next_stall_wr = (awvalid_m & ~awready_m);

   always @(posedge aclk or negedge aresetn)
   begin : p_stall_seq
        if (!aresetn) begin
             stall_rd <= 1'b0;
             stall_wr <= 1'b0;
        end else begin
             stall_rd <= next_stall_rd;
             stall_wr <= next_stall_wr;
        end 
   end // p_stall_seq

  // Determine if the read or write chanel has a defined priority, based upon
  // either a higher qv or to maintain the sticky valid protocol
  assign rd_priority = ((rd_reqd_qv > wr_reqd_qv) && !stall_wr) || stall_rd;
  assign wr_priority = ((wr_reqd_qv > rd_reqd_qv) && !stall_rd) || stall_wr;
  assign last_slot_en = (awvalid | stall_wr) & (arvalid | stall_rd) & last_slot;

  always @(rd_priority or wr_priority or last_slot_en or
           awready_m or arready_m or rw_priority)
   begin : p_override
        rd_override = 1'b0;
        wr_override = 1'b0;
        priority_upd = 1'b0;
        if (last_slot_en) begin
            // When a last slot transaction is accepted then 
            // then enable the round robin tracker to toggle
            priority_upd = awready_m | arready_m;
            if (wr_priority)
                rd_override = 1'b1;
            else if (rd_priority)
                wr_override = 1'b1;
            else
            begin
                // If no defined priority then use round tracker to 
                // determine channel to override
                wr_override = rw_priority;
                rd_override = ~rw_priority;
            end
        end
   end // p_override


   always @(posedge aclk or negedge aresetn)
   begin : p_priority_seq
        if (!aresetn) begin
             rw_priority <= 1'b0;
        end else if (priority_upd) begin
             // Toggle the last slot round robin tracker
             rw_priority <= ~rw_priority;
        end 
   end // p_priority_seq

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON

   assert_never #(2,0,"last_slot and read and writes stall")
     ovl_wr_post_del_wtr
       (/*AUTOINST*/
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr ( last_slot & stall_rd & stall_wr)
       );


`endif
// synopsys translate_on

  endmodule

//  --=============================== End ====================================--
