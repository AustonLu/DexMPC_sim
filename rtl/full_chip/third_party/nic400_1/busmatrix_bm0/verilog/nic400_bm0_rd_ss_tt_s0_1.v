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
//  File Revision       : 132916
//
//  Date                :  2012-07-02 13:38:10 +0100 (Mon, 02 Jul 2012)
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
//      - Acceptance capability 4
//      - Number of connected master interfaces 3
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



module nic400_bm0_rd_ss_tt_s0_1
  (
    ar_enable,
    tt_enable,

    asel,
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
    output [2:0]    ar_enable;     // Enable for the selected address channel
    output [2:0]    tt_enable;     // Enable for the selected return channel

    input  [2:0]    asel;     // Selected address channel
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

  reg   [2:0]    next_tt_cnt;    // next transaction tracker value
  wire           tt_reg_enable;    // Enable for transaction counter
  wire           next_resp_stall;    // next resp stall to ensure sticky valid
  reg   [2:0]    reg_tt_en;     // registered return channel select
  wire  [2:0]    int_tt_en;     // Enable for the selected return channel
  wire           next_empty;    // next transaction counter empty flag
  reg            dec_tt_cnt;    // tt_cnt to be decremented flag
  wire           asel_int;    // valid channel has been selected
  wire  [2:0]    asel_mask;    // mask fo legal selections
  wire  [2:0]    asel_masked;    // selection after being masked
  wire  [2:0]    next_tt_reg;    // next transaction tracker selection


  //----------------------------------------------------------------------------
  // Registers 
  //----------------------------------------------------------------------------

  reg            resp_stall;    // resp stall to ensure sticky valid
  reg   [2:0]    tt_cnt;    // outstanding transaction counter
  reg            empty;     // Transaction tracker is empty
  reg   [2:0]    tt_reg;     // Selected master interface


  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

   //---------------------------- Combinatorial logic --------------------------

   // For single slave CDAS create a mask depending on if there are any 
   // outstanding transactions or the incoming destination matches the
   // the current destination.
   assign asel_mask = tt_reg | {3{empty}};
   // Mask the incoming destination
   assign asel_masked = (asel & asel_mask);
   assign asel_int = |asel_masked;

   // For single slave transaction tracker count the number of 
   // outstanding transactions
   always @(asel_int or aready or resp_valid or resp_last or resp_ready or tt_cnt)
     begin : p_next_tt_comb
        next_tt_cnt = tt_cnt;
        dec_tt_cnt = 1'b0;
        if ((asel_int && aready) && !(resp_valid && resp_last && resp_ready)) begin
                next_tt_cnt = tt_cnt + 1'b1;
        end
        if (!(asel_int && aready) && (resp_valid && resp_last && resp_ready)) begin
                next_tt_cnt = tt_cnt - 1'b1;
                dec_tt_cnt = 1'b1;
        end
     end // p_next_tt_comb
  // Determine next selected destination
   assign next_tt_reg = (|asel && aready) ? asel 
                        : (tt_cnt == 3'b001 && dec_tt_cnt) ? {3{1'b0}}
                        : tt_reg;

   assign next_empty = (tt_cnt == 3'b001) && dec_tt_cnt;

   assign tt_reg_enable = ((asel_int && aready)
                           || (resp_valid && resp_last && resp_ready));

  //---------------------------- Sequential logic -----------------------------


   always @(posedge aclk or negedge aresetn)
     begin : p_tt_seq
       if (!aresetn) 
         begin
                tt_reg <= {3{1'b0}};
                tt_cnt <= {3{1'b0}};
                empty <= 1'b1;
         end
       else if (tt_reg_enable)
         begin
                tt_reg <= next_tt_reg;
                tt_cnt <= next_tt_cnt;
                empty <= next_empty;
         end
     end // end p_tt_seq
  //---------------------------- Output Enables -------------------------------

   assign next_resp_stall = (resp_valid & ~resp_ready);

   always @(posedge aclk or negedge aresetn)
     begin : p_stall_seq
       if (!aresetn)
         begin
          resp_stall <= 1'b0;
        end
       else
         begin
          resp_stall <= next_resp_stall;
        end
     end // p_stall_seq

 
   assign ar_enable = asel_masked;
   assign int_tt_en = tt_reg;
 

   always @(posedge aclk or negedge aresetn)
     begin : p_tt_en_seq
       if (!aresetn)
         begin
          reg_tt_en <= {3{1'b0}};
        end
       else if (next_resp_stall && !resp_stall)
         begin
          reg_tt_en <= int_tt_en;
        end
     end // p_tt_en_seq
 
   assign tt_enable = resp_stall ? reg_tt_en : int_tt_en;

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON


assign dec_from_zero = (tt_cnt==2'b00) & resp_valid & resp_ready;

assert_never #(1,0,"ERROR, Transaction Counter decrementing from 0")
ovl_assert_dec_empty
   (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (dec_from_zero));

assign inc_from_full = (tt_cnt==3'b100) & |asel & aready;

assert_never #(1,0,"ERROR, Transaction Counter incrementing when full")
ovl_assert_inc_full
   (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (inc_from_full));


`endif
// synopsys translate_on

  endmodule

//  --=============================== End ====================================--
