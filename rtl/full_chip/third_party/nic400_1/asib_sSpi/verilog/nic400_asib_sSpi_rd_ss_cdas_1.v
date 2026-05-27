//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2011-2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 202165
//
//  Date                :  2015-10-08 10:45:24 +0100 (Thu, 08 Oct 2015)
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
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------


module nic400_asib_sSpi_rd_ss_cdas_1
  (
    ar_enable,
    asel,
    avalid,
    aready,
    resp_valid,
    resp_last,
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
    output       ar_enable;     // address enable until acc cap is reached
    input  [2:0] asel;     // Selected address channel
    input        avalid;
    input        aready;
    input        resp_valid;
    input        resp_last;
    input        resp_ready;
    // Miscelaneous connections
    input        aclk;
    input        aresetn;

  //----------------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------------

  reg   [3:0]    next_tt_cnt;    // next transaction tracker value
  wire           resp_pop;
  wire           tt_reg_enable;
  wire           next_empty;    // next transaction counter empty flag
  reg            dec_tt_cnt;    // tt_cnt to be decremented flag
  wire           asel_int;    // valid channel has been selected
  wire  [2:0]    asel_mask;    // mask fo legal selections
  wire  [2:0]    asel_masked;    // selection after being masked
  wire  [2:0]    next_tt_reg;    // next transaction tracker selection



  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------

  reg   [3:0]    tt_cnt;    // outstanding transaction counter
  reg            empty;     // Transaction tracker is empty
  reg   [2:0]    tt_reg;     // Selected master interface
  reg   [2:0]    current_dest;     // Current destination


  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  //---------------------------- Combinatorial logic --------------------------

   // For single slave CDAS create a mask depending on if there are any
   // outstanding transactions or the incoming destination matches the
   // the current destination.
   assign asel_mask = current_dest | {3{empty}};
   // Mask the incoming destination
   assign asel_masked = (asel & asel_mask);
   assign asel_int = |asel_masked & avalid;
   assign resp_pop = resp_valid & resp_ready & resp_last;


   // For single slave transaction tracker count the number of
   // outstanding transactions
   always @(asel_int or aready or resp_pop or tt_cnt)
     begin : p_next_tt_comb
        next_tt_cnt = tt_cnt;
        dec_tt_cnt = 1'b0;
        if ((asel_int && aready) && !resp_pop) begin
                next_tt_cnt = tt_cnt + 1'b1;
        end
        if (!(asel_int && aready) && resp_pop) begin
                next_tt_cnt = tt_cnt - 1'b1;
                dec_tt_cnt = 1'b1;
        end
     end // p_next_tt_comb
  // Determine next selected destination
   assign next_tt_reg = (|asel && aready) ? asel
                        : (tt_cnt == 4'b0001 && dec_tt_cnt) ? {3{1'b0}}
                        : tt_reg;

   assign next_empty = (tt_cnt == 4'b0001) && dec_tt_cnt;

   assign tt_reg_enable = ((asel_int && avalid && aready)
                           || (resp_valid && resp_last && resp_ready));


  //---------------------------- Sequential logic -----------------------------

   always @(posedge aclk or negedge aresetn)
     begin : p_tt_seq
       if (!aresetn)
         begin
                tt_cnt <= {4{1'b0}};
                empty <= 1'b1;
                tt_reg <= {3{1'b0}};
         end
       else if (tt_reg_enable)
         begin
                tt_reg <= next_tt_reg;
                tt_cnt <= next_tt_cnt;
                empty <= next_empty;
         end
     end // end p_tt_seq

   // Note that this register is datapath only and is therefore not
   // reset to reduce gates and power.
   always @(posedge aclk)
     begin : p_dest_seq
       if (tt_reg_enable & empty)
         begin
                current_dest <= asel;
         end
     end // end p_dest_seq



  //---------------------------- Output Enables -------------------------------



   assign ar_enable = |asel_masked;



//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if read transaction counter overflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_overflow #(
                       `OVL_FATAL,
                       4,
                       0,
                       8,
                       `OVL_ASSERT,
                       "CDS read transaction counter has overflowed"
                      )
  ovl_tt_cnt_overflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (tt_cnt)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if read transaction counter underflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_underflow #(
                        `OVL_FATAL,
                        4,
                        0,
                        8,
                        `OVL_ASSERT,
                        "CDS read transaction counter has underflowed"
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
