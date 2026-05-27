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
//  File Revision       : 129771
//
//  Date                :  2012-05-11 11:13:49 +0100 (Fri, 11 May 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : A Bus matrix write channel router. Stalls connected
//                        slave inetrface write channels until the address
//                        is arbitrated.
//   
//  Key Configuration Details-
//      - Number of connected slave interfaces 3
//      - Acceptance capability 1
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

module nic400_bm0_wr_sel_ml1_1
  (
    // Miscelaneous connections
    aclk,
    aresetn,
    // Channel Enable
    aw_sel,
    awready_m,
    // SlaveInterface 0
    // Write Channel
    wdata_s0,
    wstrb_s0,   
    wlast_s0,
    wvalid_s0,
    wready_s0,

    // SlaveInterface 1
    // Write Channel
    wdata_s1,
    wstrb_s1,   
    wlast_s1,
    wvalid_s1,
    wready_s1,

    // SlaveInterface 2
    // Write Channel
    wdata_s2,
    wstrb_s2,   
    wlast_s2,
    wvalid_s2,
    wready_s2,

    // MasterInterface 
    // Write Channel
    wdata_m,
    wstrb_m,
    wlast_m,
    wvalid_m,
    wready_m
  );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  // MasterInterface 
  // Write Channel
  output  [63:0]    wdata_m;
  output  [7:0]     wstrb_m;
  output            wlast_m;
  output            wvalid_m;
  input             wready_m;
  // SlaveInterfaces
  // Write Channel
  input  [63:0]     wdata_s0;
  input  [7:0]      wstrb_s0;   
  input             wlast_s0;
  input             wvalid_s0;
  output            wready_s0;
  // Write Channel
  input  [63:0]     wdata_s1;
  input  [7:0]      wstrb_s1;   
  input             wlast_s1;
  input             wvalid_s1;
  output            wready_s1;
  // Write Channel
  input  [63:0]     wdata_s2;
  input  [7:0]      wstrb_s2;   
  input             wlast_s2;
  input             wvalid_s2;
  output            wready_s2;


  // Channel Enable
  input [2:0]    aw_sel;
  input             awready_m;

  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------

  wire              add_push;  // 
  wire              last_beat; // Last beat of write burst status flag
  // Masked Write Channel
  wire   [63:0]     wdata_masked0;
  wire   [7:0]      wstrb_masked0;   
  wire              wlast_masked0;
  wire              wvalid_masked0;
  // Masked Write Channel
  wire   [63:0]     wdata_masked1;
  wire   [7:0]      wstrb_masked1;   
  wire              wlast_masked1;
  wire              wvalid_masked1;
  // Masked Write Channel
  wire   [63:0]     wdata_masked2;
  wire   [7:0]      wstrb_masked2;   
  wire              wlast_masked2;
  wire              wvalid_masked2;


  wire   [2:0]     next_wr_ch_en; // next one hot vector of wr channel enables 
 

  //------------------------------------------------------------------------------
  // Registers 
  //------------------------------------------------------------------------------

  reg               aw_sel_reg; // 
  reg               awready_reg;  // 
  reg   [2:0]       wr_ch_en; // One hot vector, of write channel enables

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


   //----------------------- Write address push detection ----------------------

   // Register incoming add select aw_sel and awready_m from master i/f to
   // enable detection of a new address push
   always @(posedge aclk or negedge aresetn)
     begin : p_add_push_seq
       if (!aresetn)
         begin
             aw_sel_reg  <= 1'b0;
             awready_reg <= 1'b0;
         end
       else
         begin
            if ((|aw_sel) || aw_sel_reg)
             begin
                 aw_sel_reg  <= |aw_sel;
             end
            if (awready_m || awready_reg)
             begin
                awready_reg   <= awready_m;
             end
         end
     end // p_add_push_seq

   // Detect new address push ensuring no dependency on the awready_m 
   // completion of the address transaction
   assign add_push = (|aw_sel & ~aw_sel_reg) | (|aw_sel & aw_sel_reg & awready_reg);


   // Determine when current transaction is ending
   assign last_beat = wvalid_m & wready_m & wlast_m;




   //----------------------- Write Source Enable Selection ----------------------

   // Determine next slave interface input write channel to enable or clear
   // If the fifo isn't empty then assign to the fifo output otherwise assign 
   // the incoming selected slave interface
   assign next_wr_ch_en = (add_push) ? aw_sel : {3{1'b0}};



   always @(posedge aclk or negedge aresetn)
     begin : p_wr_ch_en_seq
       if (!aresetn)
         begin
             wr_ch_en    <= {3{1'b0}};
         end
       else if (last_beat | (~|wr_ch_en & ((add_push))))
         begin
             wr_ch_en    <=   next_wr_ch_en;
         end
     end // p_wr_ch_en_seq

     

   //------------------------ Write Channel Multiplexing -----------------------

    assign wdata_masked0  = wdata_s0 & {64{wr_ch_en[0]}};
    assign wstrb_masked0  = wstrb_s0 & {8{wr_ch_en[0]}}; 
    assign wlast_masked0  = wlast_s0 & wr_ch_en[0];
    assign wvalid_masked0 = wvalid_s0 & wr_ch_en[0];

    assign wdata_masked1  = wdata_s1 & {64{wr_ch_en[1]}};
    assign wstrb_masked1  = wstrb_s1 & {8{wr_ch_en[1]}}; 
    assign wlast_masked1  = wlast_s1 & wr_ch_en[1];
    assign wvalid_masked1 = wvalid_s1 & wr_ch_en[1];

    assign wdata_masked2  = wdata_s2 & {64{wr_ch_en[2]}};
    assign wstrb_masked2  = wstrb_s2 & {8{wr_ch_en[2]}}; 
    assign wlast_masked2  = wlast_s2 & wr_ch_en[2];
    assign wvalid_masked2 = wvalid_s2 & wr_ch_en[2];

    // Master Interface Write Channel Assignment
    assign wdata_m  = wdata_masked0 | wdata_masked1 | wdata_masked2;
    assign wstrb_m  = wstrb_masked0 | wstrb_masked1 | wstrb_masked2;
    assign wlast_m  = wlast_masked0 | wlast_masked1 | wlast_masked2;
    assign wvalid_m = wvalid_masked0 | wvalid_masked1 | wvalid_masked2;

    // Mask the ready signals back to the current slave interface
    assign wready_s0 = (wready_m & wr_ch_en[0]);
    assign wready_s1 = (wready_m & wr_ch_en[1]);
    assign wready_s2 = (wready_m & wr_ch_en[2]);

    //------------------------------------------------------------------------------
    // OVL Assertions
    //------------------------------------------------------------------------------
    // synopsys translate_off
 
    `ifdef ARM_ASSERT_ON

      parameter  WR_ISS_DEPTH = 1;
      assert_zero_one_hot #(0,3,0,"ERROR, More than one write channel enabled")
         ovl_write_channel_en
           (
            .clk       (aclk),
            .reset_n   (aresetn),
            .test_expr (wr_ch_en)
            );


    `endif
    // synopsys translate_on


endmodule

//  --=============================== End ====================================--

