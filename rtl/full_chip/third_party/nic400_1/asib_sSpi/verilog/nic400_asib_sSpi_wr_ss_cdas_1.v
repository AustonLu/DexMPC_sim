
//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2011-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 131626
//
//  Date                :  2012-06-14 00:08:57 +0100 (Thu, 14 Jun 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : Transaction tracker to maintain status of
//                        outstanding transcations for a slave interface
//                        and to ensure that no cyclic dependency deadlocks
//                        can occur.
//
//  Key Configuration Details-
//      - Single Slave CDAS
//      - Acceptance capability 8
//      - Number of connected master interfaces 3
//
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------


module nic400_asib_sSpi_wr_ss_cdas_1
  (
    aw_enable,
    wr_enable,
    asel,
    avalid,
    aready,
    wvalid,
    wready,
    wlast,
    resp_valid,
    resp_ready,

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
    output       aw_enable;     // address channel enable
    output       wr_enable;     // Enable for the selected write channel
    input  [2:0] asel;     // Selected address channel
    input        avalid;     // add channel response
    input        aready;     // add channel response
    input        wvalid;     // request
    input        wready;     // response
    input        wlast;     // last flag
    // Slave Interface Buffered response handshake signals
    input        resp_valid;
    input        resp_ready;
    // Miscelaneous connections
    input        aclk;
    input        aresetn;


  //----------------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------------
  reg   [3:0]    next_last_cnt;    // next value for last counter
  wire           next_valid_add;     // next no last beat for the current write
  reg   [3:0]    next_tt_cnt;    // next transaction tracker value
  wire           next_empty;    // next transaction counter empty flag
  reg            dec_tt_cnt;    // tt_cnt to be decremented flag
  wire  [2:0]    asel_mask;   // mask fo legal selections
  wire  [2:0]    asel_masked;    // selection after being masked
  wire           asel_int;    // valid channel has been selected

  wire           add_push;   // Detection of AW tracker push
  wire           resp_pop;   //


  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------
  reg            valid_add;   // Last beat not received for the current write
  reg   [3:0]    last_cnt;   // Number of transactions with last write beat
  reg            asel_reg;   // registered incomingdestination
  reg            aready_reg;   // registered aready
  reg   [3:0]    tt_cnt;   // Number of accepted transactions

  reg            empty;     // Transaction tracker is empty
  reg   [2:0]    current_dest;   // Current destination



  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

   //----------------------- Write address push detection ----------------------

   // For single slave CDAS create a mask depending on if there are any
   // outstanding transactions or the incoming destination matches the
   // the current destination.
   assign asel_mask = current_dest | {3{empty}};
   // Mask the incoming destination
   assign asel_masked = (asel & asel_mask);
   assign asel_int = |asel_masked & avalid;

   // Register incoming add select a_sel and aready_m from master i/f to
   // enable detection of a new address push
   always @(posedge aclk or negedge aresetn)
     begin : p_add_push_seq
       if (!aresetn)
         begin
           asel_reg   <= 1'b0;
           aready_reg <= 1'b0;
         end
       else
         begin
           asel_reg   <= asel_int;
           aready_reg <= aready;
         end
     end // p_add_push_seq

   // Detect new address push ensuring no dependency on the aready_m
   // completion of the address transaction
   assign add_push = asel_int & (~asel_reg | aready_reg);


 //---------------------------- Combinatorial logic --------------------------


   assign resp_pop = resp_valid & resp_ready;

  // Count the number of outstanding transactions
   always @(add_push or resp_pop or tt_cnt)
     begin : p_next_tt_comb
        next_tt_cnt = tt_cnt;
        dec_tt_cnt = 1'b0;
        if (add_push && !resp_pop)
                next_tt_cnt = tt_cnt + 1'b1;
        if (!(add_push) && resp_pop)
          begin
                next_tt_cnt = tt_cnt - 1'b1;
                dec_tt_cnt = 1'b1;
          end
     end // p_next_tt_comb

   // Count the number of non-complete write channel bursts
   always @(wvalid or wready or wlast or resp_valid or resp_ready or last_cnt)
     begin : p_next_last_comb
        next_last_cnt = last_cnt;
        if ((wvalid && wready && wlast) && !(resp_valid && resp_ready))
                next_last_cnt = last_cnt + 1'b1;
        if (!(wvalid && wready && wlast) && (resp_valid && resp_ready))
                next_last_cnt = last_cnt - 1'b1;
     end // p_next_last_comb
  assign next_empty = (tt_cnt == 4'b0001) && dec_tt_cnt;

  //---------------------------- Sequential logic -----------------------------

   // Create next_valid_add from count values
   assign next_valid_add = (next_tt_cnt > next_last_cnt);

   always @(posedge aclk or negedge aresetn)
     begin : p_tt_last_seq
       if (!aresetn) begin
                last_cnt <= {4{1'b0}};
                valid_add <= 1'b0;
       end
       else  begin
                last_cnt <= next_last_cnt;
                // If the next transaction count is greater than the next last write
                // data beat then there is still a valid address select in the tracker
                valid_add <= next_valid_add;
       end
     end // p_tt_last_seq

   always @(posedge aclk or negedge aresetn)
     begin : p_tt_seq
       if (!aresetn)
         begin
             tt_cnt <= {4{1'b0}};
             empty <= 1'b1;
         end
       else if ((add_push) || (resp_valid && resp_ready))
         begin
             tt_cnt <= next_tt_cnt;
             empty <= next_empty;
         end
     end // p_tt_seq

   // Note that this register is datapath only and is therefore not
   // reset to reduce gates and power.
   always @(posedge aclk)
     begin : p_dest_seq
       if (((add_push) || (resp_valid && resp_ready)) && empty)
         begin
             current_dest <= asel;
         end
     end // end p_dest_seq



  //---------------------------- Output Enables -------------------------------



   assign aw_enable = |asel_masked;
   assign wr_enable = valid_add;



//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if write transaction counter overflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_overflow #(
                       `OVL_FATAL,
                       4,
                       0,
                       9,
                       `OVL_ASSERT,
                       "CDS write transaction counter has overflowed"
                      )
  ovl_tt_cnt_overflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (tt_cnt)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if write transaction counter underflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_underflow #(
                        `OVL_FATAL,
                        4,
                        0,
                        9,
                        `OVL_ASSERT,
                        "CDS write transaction counter has underflowed"
                       )
  ovl_tt_cnt_underflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (tt_cnt)
  );
  // OVL_ASSERT_END

`endif
// synopsys translate_on

  endmodule

//  --=============================== End ====================================--
