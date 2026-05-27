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
//  File Revision       : 129373
//
//  Date                :  2012-05-02 08:41:35 +0100 (Wed, 02 May 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : AXI bus matrix arbitration node mask control     
//                        Counts outstanding transations and masks the
//                        arbitration when reached.
//   
//  Key Configuration Details-
//   
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterIf (connect to external AXI slave)
//     *_s0 suffix to denote the SlaveIf  (connect to external AXI master) 
//
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_maskcntl_ml2_1
  (
    // Master Interface address channel handshake signals
    awvalid_m,
    awready_m,
    arvalid_m,
    arready_m,
    wvalid_m,
    wready_m,
    wlast_m,

    // Master Interface return channel handshake signals
    bvalid_m,
    bready_m,
    rvalid_m,
    rready_m,
    // Arbitration mask vectors
    wr_cnt_empty,
    mask_w,
    mask_r,
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

  // Master Interface address channel handshake signals
  input             awvalid_m;
  input             awready_m;
  input             arvalid_m;
  input             arready_m;
  input             wvalid_m;
  input             wready_m;
  input             wlast_m;
  // Master Interface return channel handshake signals
  input             bvalid_m;
  input             bready_m;
  input             rvalid_m;
  input             rready_m;
  // Arbitration mask vectors
  output            wr_cnt_empty;
  output [2:0]      mask_w;
  output [2:0]      mask_r;
  // Miscelaneous connections
  input             aclk;
  input             aresetn;


  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------


  wire              push_wr;         // Write address accepted
  wire              push_rd;         // Read address accepted
  wire              pop_rd;          // Last read beat accepted
  wire              pop_wr;          // Write transaction accepted
  wire              next_wr_cnt_empty;     // Next Write counter empty
  wire              next_rd_cnt;     // next outstanding reads count
  wire              next_wr_cnt;     // next outstanding writes count 
  reg   [2:0]       next_mask_w;     // next mask for write address channel
  reg   [2:0]       next_mask_r;     // next mask for read address channel
  wire [1:0]        next_post_cnt;    // Indicate that posting AW tracking is full
  wire              post_cnt_en;
  wire              wt_push;          // 
  wire              wt_pop;           // 

  //------------------------------------------------------------------------------
  // Registers
  //------------------------------------------------------------------------------


  reg               wr_cnt_empty;     // Write counter empty
  reg               rd_cnt;          // outstanding reads count
  reg               wr_cnt;          // outstanding writes count
  reg   [2:0]       mask_w;          // mask for write address channel
  reg   [2:0]       mask_r;          // mask for read address channel
  reg   [1:0]       post_cnt;          // Indicate that posting AW tracking is full
  reg               full;            // Indicate that posting AW tracking is full
  wire              next_full;       // next AW tracking is full 

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  //-------------------- Outstanding transaction counters ---------------------
  // Used to track current number of outstanding transactions to enable the 
  // creation of a mask vector for masking each attached slave interface
  // If the number of transactions is reached then all the mask bits are set

  assign push_wr = awvalid_m & awready_m;
  assign push_rd = arvalid_m & arready_m;

  assign pop_rd = rvalid_m & rready_m;
  assign pop_wr = bvalid_m & bready_m;

  // Determine next outstanding read counter
  assign next_rd_cnt = (push_rd & ~pop_rd) ? rd_cnt + 'b1 :
                       ((~push_rd & pop_rd) ? rd_cnt - 'b1 :
                       rd_cnt);

  // Determine next outstanding write counter
  assign next_wr_cnt = (push_wr & ~pop_wr) ? wr_cnt + 'b1 :
                       ((~push_wr & pop_wr) ? wr_cnt - 'b1 :
                       wr_cnt);

  assign next_wr_cnt_empty = (next_wr_cnt == 1'd0);


  // Register current count values 
   always @(posedge aclk or negedge aresetn)
     begin : p_wr_cnt_seq
       if (!aresetn)
         begin
           wr_cnt <= {1{1'b0}};
           wr_cnt_empty <= 1'b1;
           rd_cnt <= {1{1'b0}};
         end
       else 
         begin
           if (push_wr ^ pop_wr)
           begin
                wr_cnt <= next_wr_cnt;
                wr_cnt_empty <= next_wr_cnt_empty;
           end
           if (push_rd ^ pop_rd)
           begin
                rd_cnt <= next_rd_cnt;
           end
         end
     end // p_wr_cnt_seq

  //--------------------------- AW post Limiting -------------------------------
   // 
   assign wt_push = push_wr;
   // 
   assign wt_pop = wvalid_m & wready_m & wlast_m;

   assign next_post_cnt =  wt_push && !wt_pop ? (post_cnt + 'b1)
                         : !wt_push && wt_pop ? (post_cnt - 'b1)
                         : post_cnt;

   assign next_full = (next_post_cnt == 2'b10) ? 1'b1 : 1'b0;

   assign post_cnt_en = (wt_push | wt_pop);

   always @(posedge aclk or negedge aresetn)
     begin : p_full_seq
       if (!aresetn)
         begin
           post_cnt <= 2'b00;
           full     <= 1'b0;
         end
       else
         begin
           if (post_cnt_en) 
             begin
                post_cnt <= next_post_cnt;
                full     <= next_full;
             end
         end
     end // p_full_seq

  //--------------------------- Mask Generation -------------------------------

  always @(next_wr_cnt or next_rd_cnt or next_full) 
   begin : p_mask_comb
     next_mask_w = {3{1'b0}};
     next_mask_r = {3{1'b0}};
     // If the next write count will be reached then
     // mask all the write slave interfaces
     if (next_wr_cnt == 1'b1 || next_full)
        next_mask_w = {3{1'b1}};
     // If the next read count will be reached then
     // mask all the read slave interfaces
     if (next_rd_cnt ==  1'b1)
        next_mask_r = {3{1'b1}};
  end // p_mask_comb


   always @(posedge aclk or negedge aresetn)
     begin : p_mask_seq
       if (!aresetn)
         begin
           mask_w <= {3{1'b0}};
           mask_r <= {3{1'b0}};
         end
       else begin 
         if (push_wr  | pop_wr
             | push_rd  | pop_rd | full)
           begin
              mask_w <= next_mask_w;
              mask_r <= next_mask_r;
           end
       end    
     end // p_mask_seq


//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
// synopsys translate_off

`ifdef ARM_ASSERT_ON



`endif
// synopsys translate_on

  endmodule

//  --=============================== End ====================================--

