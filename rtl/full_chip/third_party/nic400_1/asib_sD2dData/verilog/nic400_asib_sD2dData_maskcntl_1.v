
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
// File Revision       : 135079
// File Date           :  2012-08-13 15:13:34 +0100 (Mon, 13 Aug 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose             : Structural file to implement counting and mask control
//                       of address channel transactions according to read and
//                       write issuing capabilities.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_asib_sD2dData_maskcntl_1
  (
    // Master Interface address channel handshake signals
    awvalid_m,
    awready_m,
    arvalid_m,
    arready_m,
    // Master Interface return channel handshake signals
    bvalid_m,
    bready_m,
    rvalid_m,
    rready_m,
    // Mask signals
    wr_cnt_empty,
    mask_w,
    mask_r,
    // QoS output signals
    aw_qos_m,
    ar_qos_m,
    // Miscellaneous connections
    aclk,
    aresetn
  );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  // Master Interface address channel handshake signals
  input             awvalid_m;
  input             awready_m;
  input             arvalid_m;
  input             arready_m;
  // Master Interface return channel handshake signals
  input             bvalid_m;
  input             bready_m;
  input             rvalid_m;
  input             rready_m;
  // Mask signals
  output            wr_cnt_empty;
  output            mask_w;
  output            mask_r;
  // QoS output signals
  output [3:0]      aw_qos_m;
  output [3:0]      ar_qos_m;
  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //------------------------------------------------------------------------------
  // Wires
  //------------------------------------------------------------------------------

  wire              push_rd;         // Read address accepted;
  wire              push_wr;         // Write address accepted
  wire              pop_rd;          // Last read beat accepted
  wire              pop_wr;          // Write transaction accepted
  wire              next_wr_cnt_empty;     // Next Write counter empty
  wire              wr_cnt_en;
  wire              rd_cnt_en;
  wire              wr_mask_en;
  wire              rd_mask_en;
  wire  [2:0]       next_rd_cnt;     // next outstanding reads count
  wire  [2:0]       next_wr_cnt;     // next outstanding writes count
  reg   [2:0]       wr_iss;
  reg   [2:0]       rd_iss;
  reg               next_mask_w;
  reg               next_mask_r;
  wire              nxt_limit_wr;
  wire              nxt_limit_rd;

  //------------------------------------------------------------------------------
  // Registers
  //------------------------------------------------------------------------------

  reg   [2:0]       rd_cnt;          // outstanding reads count
  reg   [2:0]       wr_cnt;          // outstanding writes count
  reg               wr_cnt_empty;     // Write counter empty
  reg               reg_mask_w;
  reg               reg_mask_r;

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  assign nxt_limit_wr = 1'b0;
  assign nxt_limit_rd = 1'b0;
  //---------------------------- Drive QoS outputs ----------------------------


  // Configured QoS value
  assign aw_qos_m = 4'h0;
  assign ar_qos_m = 4'h0;
  

 //-------------------- Outstanding transaction counters ---------------------

  assign push_rd = arvalid_m & arready_m;
  assign push_wr = awvalid_m & awready_m;

  assign pop_rd = rvalid_m & rready_m;
  assign pop_wr = bvalid_m & bready_m;

  // Determine next outstanding read counter
  assign next_rd_cnt = (push_rd & ~pop_rd) ? rd_cnt + 1'b1
                         : ((~push_rd & pop_rd) ? rd_cnt - 1'b1
                           : rd_cnt);

  // Determine next outstanding write counter
  assign next_wr_cnt = (push_wr & ~pop_wr) ? wr_cnt + 1'b1
                         : ((~push_wr & pop_wr) ? wr_cnt - 1'b1
                           : wr_cnt);





  assign wr_cnt_en = push_wr ^ pop_wr;
  assign rd_cnt_en = push_rd ^ pop_rd;
  assign next_wr_cnt_empty = (next_wr_cnt == 3'b0);

   always @(posedge aclk or negedge aresetn)
     begin : p_wr_cnt_seq
       if (!aresetn)
         begin
           wr_cnt <= {3{1'b0}};
           wr_cnt_empty <= 1'b1;
           rd_cnt <= {3{1'b0}};
         end
       else
         begin
           if (wr_cnt_en)
           begin
                wr_cnt <= next_wr_cnt;
                wr_cnt_empty <= next_wr_cnt_empty;
           end
           if (rd_cnt_en)
           begin
                rd_cnt <= next_rd_cnt;
           end
         end
     end // p_wr_cnt_seq

  //--------------------------- Mask Generation -------------------------------

  always @(next_wr_cnt or next_rd_cnt or nxt_limit_wr or nxt_limit_rd)
   begin : p_mask_comb
     wr_iss = 3'b100;
     rd_iss = 3'b100;

     next_mask_w = 1'b0;
     next_mask_r = 1'b0;

     // If the next write count will be reached then
     // mask all the write slave interfaces
     if (next_wr_cnt == wr_iss ||
              (|next_wr_cnt && nxt_limit_wr == 1'b1))
        next_mask_w = 1'b1;
     // If the next read count will be reached then
     // mask all the read slave interfaces
     if (next_rd_cnt ==  rd_iss ||
              (|next_rd_cnt && nxt_limit_rd == 1'b1))
        next_mask_r = 1'b1;
  end // p_mask_comb



  assign wr_mask_en =push_wr | pop_wr;
  assign rd_mask_en = push_rd | pop_rd;

   always @(posedge aclk or negedge aresetn)
     begin : p_wr_mask_seq
       if (!aresetn)
         begin
           reg_mask_w <= 1'b0;
         end
       else if (wr_mask_en)
         begin
           reg_mask_w <= next_mask_w;
         end
     end // p_wr_mask_seq

  assign mask_w = reg_mask_w;

   always @(posedge aclk or negedge aresetn)
     begin : p_rd_mask_seq
       if (!aresetn)
         begin
           reg_mask_r <= 1'b0;
         end
       else if (rd_mask_en)
         begin
           reg_mask_r <= next_mask_r;
         end
     end // p_rd_mask_seq

  assign mask_r = reg_mask_r;

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------

`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"

  reg limit_wr_align;
  reg limit_rd_align;

  //Allign the limit signals
  always @(posedge aclk or negedge aresetn)
     begin : p_limit_wr_align
        if (!aresetn) begin
           limit_wr_align <= 1'b0;
        end else if (~awvalid_m || push_wr) begin
           limit_wr_align <= nxt_limit_wr;
        end
     end

  always @(posedge aclk or negedge aresetn)
     begin : p_limit_rd_align
        if (!aresetn) begin
           limit_rd_align <= 1'b0;
        end else if (~arvalid_m || push_rd) begin
           limit_rd_align <= nxt_limit_rd;
        end
     end


  wire test_wr_limit;
  assign test_wr_limit = (|wr_cnt && (awvalid_m & !mask_w) && limit_wr_align);

   assert_never #(1,0,"ERROR, Wr issuing exceeded one when limited")
     ovl_wr_limit
       (/*AUTOINST*/
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (test_wr_limit)
        );


  wire test_rd_limit;
  assign test_rd_limit = (|rd_cnt && (arvalid_m & !mask_r) && limit_rd_align);

   assert_never #(1,0,"ERROR, read issuing exceeded one when limited")
     ovl_rd_limit
       (/*AUTOINST*/
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (test_rd_limit)
        );
  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if write transaction counter overflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_overflow #(
                       `OVL_FATAL,
                       3,
                       0,
                       7,
                       `OVL_ASSERT,
                       "Mask control write transaction counter has overflowed"
                      )
  ovl_wr_cnt_overflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (wr_cnt)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if write transaction counter underflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_underflow #(
                        `OVL_FATAL,
                        3,
                        0,
                        7,
                        `OVL_ASSERT,
                        "Mask control write transaction counter has underflowed"
                       )
  ovl_wr_cnt_underflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (wr_cnt)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if read transaction counter overflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_overflow #(
                       `OVL_FATAL,
                       3,
                       0,
                       7,
                       `OVL_ASSERT,
                       "Mask control read transaction counter has overflowed"
                      )
  ovl_rd_cnt_overflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (rd_cnt)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: FATAL error if read transaction counter underflows
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_no_underflow #(
                        `OVL_FATAL,
                        3,
                        0,
                        7,
                        `OVL_ASSERT,
                        "Mask control read transaction counter has underflowed"
                       )
  ovl_rd_cnt_underflow
  (
    .clk       (aclk),
    .reset_n   (aresetn),
    .test_expr (rd_cnt)
  );
  // OVL_ASSERT_END

`endif

  endmodule

//  --=============================== End ====================================--


