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
//  File Revision       : 134319
//
//  Date                :  2012-07-27 14:43:09 +0100 (Fri, 27 Jul 2012)
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


module nic400_bm0_wr_ss_tt_s2_1
  (
    aw_enable,
    tt_enable,
    wr_enable,
    asel,
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
    output [2:0] aw_enable;     // address channel enable 
    output [2:0] tt_enable;     // Enable for the selected return channel
    output [2:0] wr_enable;     // Enable for the selected write channel
    input  [2:0] asel;     // Selected address channel
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


  reg   [2:0]    next_last_cnt;    // next value for last counter
  wire  [1:0]    next_valid_add;     // next no last beat for the current write 
  wire  [2:0]    next_tt_reg;   // next transaction tracker selection
  reg   [2:0]    next_tt_cnt;    // next transaction tracker value
  reg            dec_tt_cnt;    // tt_cnt to be decremented flag

  wire  [2:0]    int_tt_en;    // Enable for the selected return channel
  wire           next_empty;    // next transaction counter empty flag
  wire  [2:0]    asel_mask;   // mask fo legal selections
  wire  [2:0]    asel_masked;    // selection after being masked
  wire           asel_int;    // valid channel has been selected

  wire           add_push;           // Detection of AW tracker push
  wire           aw_enable_bit;      // 
  wire           next_add_stall;     // next addr stall to ensure sticky valid
  wire           next_resp_stall;    // next resp stall to ensure sticky valid

  //----------------------------------------------------------------------------
  // Registers 
  //----------------------------------------------------------------------------


  reg [1:0]         valid_add;   // Last beat not received for the current write
  reg   [2:0]    last_cnt;   // Number of transactions with last write beat
  reg   [2:0]    tt_cnt;   // Number of accepted transactions
  reg            add_stall;
  reg   [2:0]    tt_reg;   // Selected master interface
  reg            resp_stall;   // resp stall to ensure sticky valid
  reg            asel_reg;   // registered incomingdestination
  reg            aready_reg;   // registered aready

  wire           valid_add_en;
  reg            empty;     // Transaction tracker is empty

  reg   [2:0]    reg_tt_en;     // Enable for the selected return channel

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

   //----------------------- Write address push detection ----------------------

   // For single slave CDAS create a mask depending on if there are any 
   // outstanding transactions or the incoming destination matches the
   // the current destination.
   assign asel_mask = tt_reg | {3{empty}};
   // Mask the incoming destination
   assign asel_masked = (asel & asel_mask);
   assign asel_int = |asel_masked & aw_enable_bit;

   // Register incoming add select a_sel and aready_m from master i/f to
   // enable detection of a new address push
   always @(posedge aclk or negedge aresetn)
     begin : p_add_push_seq
       if (!aresetn)
         begin
             asel_reg  <= 1'b0;
             aready_reg <= 1'b0;
         end
       else
         begin
            if (asel_int || asel_reg)
             begin
                 asel_reg  <= asel_int;
             end
            if (aready_reg || aready)
             begin
                aready_reg   <= aready;
             end
         end
     end // p_add_push_seq

   // Detect new address push ensuring no dependency on the aready_m 
   // completion of the address transaction
   assign add_push = ((asel_int & ~asel_reg) | (asel_int & asel_reg & aready_reg));


 //---------------------------- Combinatorial logic --------------------------
  // Count the number of outstanding transactions
   always @(add_push or resp_valid or resp_ready or tt_cnt)
     begin : p_next_tt_comb
        next_tt_cnt = tt_cnt;
        dec_tt_cnt = 1'b0;
        if (add_push && !(resp_valid && resp_ready)) 
                next_tt_cnt = tt_cnt + 1'b1;
        if (!(add_push) && (resp_valid && resp_ready))  begin
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

  // Determine next selected destination
    assign next_tt_reg = (add_push) ? asel 
                        : (tt_cnt == 3'b001 && dec_tt_cnt) ? {3{1'b0}}
                        : tt_reg;

   assign next_empty = (tt_cnt == 3'b001) && dec_tt_cnt;

  //---------------------------- Sequential logic -----------------------------

   assign next_valid_add[0] = (add_push & ~(wvalid & wready & wlast)) ? 1'b1 :
                              (~add_push & (wvalid & wready & wlast)) ? valid_add[1] :
                               valid_add[0];
   assign next_valid_add[1] = (add_push & ~(wvalid & wready & wlast)) ? valid_add[0] :
                              (~add_push & (wvalid & wready & wlast)) ? 1'b0 :
                               valid_add[1];

   assign valid_add_en = (add_push | (wvalid & wready & wlast));


  always @(posedge aclk or negedge aresetn)
     begin : p_tt_last_seq
       if (!aresetn) begin 
             last_cnt <= {3{1'b0}};
       end
       else 
        begin
             last_cnt <= next_last_cnt;
       end
     end // p_tt_last_seq

  always @(posedge aclk or negedge aresetn)
     begin : p_val_seq
       if (!aresetn) begin 
             valid_add <= 2'b00;
       end
       else if (valid_add_en)
        begin
             valid_add <= next_valid_add;
       end
     end // p_val_seq


   always @(posedge aclk or negedge aresetn)
     begin : p_tt_seq 
       if (!aresetn) 
         begin
             tt_reg <= {3{1'b0}};
             tt_cnt <= {3{1'b0}};
             empty <= 1'b1;
         end
       else if ((add_push) || (resp_valid && resp_ready))
         begin
             tt_reg <= next_tt_reg;
             tt_cnt <= next_tt_cnt;
             empty <= next_empty;
         end
       end // p_tt_seq
 

  //---------------------------- Output Enables -------------------------------

   assign next_add_stall = (asel_int & ~aready);
   assign next_resp_stall = (resp_valid & ~resp_ready);

   always @(posedge aclk or negedge aresetn)
     begin : p_stall_seq
       if (!aresetn)
         begin
          resp_stall <= 1'b0;
          add_stall  <= 1'b0;
        end
       else
         begin
          resp_stall <= next_resp_stall;
          add_stall  <= next_add_stall;
        end
     end // p_stall_seq

   assign aw_enable_bit = add_stall ? 1'b1 : (~valid_add[1]);
   assign aw_enable = asel_masked & {3{aw_enable_bit}};

   assign wr_enable = tt_reg & {3{valid_add[0]}};
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



`endif 
// synopsys translate_on

  endmodule

//  --=============================== End ====================================--
