
//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2004-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 126562
// File Date           :  2012-03-07 14:23:18 +0000 (Wed, 07 Mar 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose: AXI InterConnect default Slave
//------------------------------------------------------------------------------




`include "nic400_default_slave_ds_1_defs_1.v"

module nic400_default_slave_ds_1_1 (

    
    //AW Channel
    awid,
    awvalid,
    awready,

    //W Channel
    wlast,
    wvalid,
    wready,

    //B Channel
    bid,
    bresp,
    bvalid,
    bready,

    //AR Channel
    arid,
    arlen,
    arvalid,
    arready,

    //R Channel
    rid,
    rresp,
    rlast,
    rvalid,
    rready,

    //Clock and reset signals
    aclk,
    aresetn


);


//------------------------------------------------------------------------------
// Inputs / Outputs
//------------------------------------------------------------------------------



  //AW Channel
  input   [7:0]       awid;         //write id of AXI bus AW channel
  input               awvalid;      //write valid of AXI bus AW channel
  output              awready;      //write ready of AXI bus AW channel

  //W Channel
  input               wlast;        //write last of AXI bus W Channel
  input               wvalid;       //write valid of AXI bus W Channel
  output              wready;       //write ready of AXI bus W Channel

  //B Channel
  output  [7:0]       bid;          //b response id of AXI bus B Channel
  output  [1:0]       bresp;        //b response status of AXI bus B Channel
  output              bvalid;       //b response valid of AXI bus B Channel
  input               bready;       //b response ready of AXI bus B Channel

  //AR Channel
  input   [7:0]       arid;         //read id of AXI bus AR Channel
  input   [7:0]       arlen;        //read length of AXI bus AR Channel
  input               arvalid;      //read valid of AXI bus AR Channel
  output              arready;      //read ready of AXI bus AR Channel

  //R Channel
  output  [7:0]       rid;          //read id of AXI bus R Channel
  output  [1:0]       rresp;        //read response status of AXI bus R Channel
  output              rlast;        //read last of AXI bus R Channel
  output              rvalid;       //read valid of AXI bus R Channel
  input               rready;       //read ready of AXI bus R Channel

  //Clock and reset signals
  input               aclk;         //main clock
  input               aresetn;      //main reset


//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

// AXI Standard Defines

`include "Axi.v"

//-------------------------------------------------------------------------
//  Signal declarations
//-------------------------------------------------------------------------

wire         aclk;                              // Clock input
wire         aresetn;                           // Reset async input active low

// Write Address channel
wire   [7:0] awid;
wire         awvalid;                           // Address valid
wire         awready;                           // Address ready

// Write channel
wire         wlast;                             // Write last
wire         wvalid;                            // Write valid
wire         wready;                            // Write ready

// Write response channel
wire         bvalid;                            // Write response valid
wire         bready;                            // Write response ready
wire   [7:0] bid;  // Response ID
wire   [1:0] bresp;                             // Write response

// Read Address Channel
wire   [7:0] arid; // Address ID
wire   [7:0] arlen;                             // Burst length
wire         arvalid;                           // Address valid
wire         arready;                           // Address ready

// Read channel
wire  [7:0] rid;   // Read ID
wire  [1:0] rresp;                              // Read response
wire        rlast;                              // Read last
wire        rvalid;                             // Read valid
wire        rready;                             // Read ready

// Internal signals
// AW
reg         aw_state;                            // Current aw_state
reg         aw_state_nxt;                         // Next aw_state
reg         i_awready;                           // Internal awready
wire        awtrans;                            // Flag for AW transaction handshake

// W
reg         w_state;                             // Current w_state
reg         w_state_nxt;                          // Next w_state
reg         i_wready;                            // Internal wready

// B
reg         b_state;                             // Current b_state
reg         b_state_nxt;                          // Next b_state
reg         i_bvalid;                            // Internal bvalid
reg   [7:0] i_bid;  // Internal bid

// AR
reg         ar_state;                            // Current ar_state
reg         ar_state_nxt;                         // Next ar_state
reg         i_arready;                           // Internal arready
wire        artrans;                            // Flag for AR transaction handshake
// R
reg         r_state;                             // Current r_state
reg         r_state_nxt;                          // Next r_state
reg         i_rvalid;                            // Internal rvalid
reg   [7:0] reads_left;                          // reads_left Counter
reg   [7:0] reads_left_nxt;                       // next reads_left counter value
wire        i_rlast;                             // Internal rvalid
reg   [7:0] i_rid;  // Internal rid

assign      awtrans = awvalid & i_awready;   // Assign AW handshake
assign      awready = i_awready;                 // Assign output from int signal
assign      wready  = i_wready;                  // Assign output from int signal
assign      bvalid  = i_bvalid;                  // Assign output from int signal
assign      bresp   = `AXI_RESP_DECERR;         // Tie off Response to DECERR   
assign      bid     = i_bid;                     // Assign output from int signal

assign      arready = i_arready;                 // Assign output from int signal
assign      artrans = arvalid & i_arready;   // Assign AR handshake
assign      rvalid  = i_rvalid;                  // Assign output from int signal
assign      rresp   = `AXI_RESP_DECERR;         // Tie off Response to DECERR
assign      rlast   = i_rlast;                   // Assign output from int signal
assign      rid     = i_rid;                     // Assign output from int signal

// drive i_rlast whenever the reads_left count is zero
assign      i_rlast = (reads_left == {8{1'b0}}) ? 1'b1 : 1'b0;


//-------------------------------------------------------------------------
// awready State Machine
//-------------------------------------------------------------------------

always @(awvalid or i_bvalid or bready or aw_state)
  begin : p_aw_state_comb
    case (aw_state)
  
      `AXIBM_AW_READY_HIGH : 
         begin 
           i_awready = 1'b1; 
           aw_state_nxt = awvalid ? `AXIBM_AW_READY_LOW : 
          `AXIBM_AW_READY_HIGH; 
         end
      
      `AXIBM_AW_READY_LOW :
         begin
           i_awready = 1'b0;
           aw_state_nxt = (i_bvalid & bready) ? `AXIBM_AW_READY_HIGH : 
          `AXIBM_AW_READY_LOW;
         end
      
      default : aw_state_nxt = `AXIBM_AW_READY_HIGH;

    endcase
  end // p_aw_state_comb


// Clock the registers
  
always @(negedge aresetn or posedge aclk)
  begin : p_aw_stateSeq
    if (~aresetn)
      aw_state <= `AXIBM_AW_READY_HIGH;    // On reset, go defaults
    else
      aw_state <= aw_state_nxt;              // On a clock, pop the Nxt
  end

//-------------------------------------------------------------------------
// wready State Machine
//-------------------------------------------------------------------------

always @(i_awready or wvalid or wlast or i_bvalid or w_state)
  begin : p_w_state_comb
    case (w_state)
  
      `AXIBM_W_READY_LOW :
         begin
           i_wready = 1'b0;
           w_state_nxt = (i_awready || i_bvalid) ? `AXIBM_W_READY_LOW : 
          `AXIBM_W_READY_HIGH;
         end

      `AXIBM_W_READY_HIGH :
         begin
           i_wready = 1'b1;
           w_state_nxt = (wlast & wvalid) ?  `AXIBM_W_READY_LOW : 
          `AXIBM_W_READY_HIGH;
         end

      default : w_state_nxt = `AXIBM_W_READY_LOW;
      
    endcase
  end // p_w_state_comb
  
  
// Clock the registers
  
always @(negedge aresetn or posedge aclk)
  begin : p_w_state_seq
    if (~aresetn)
      w_state  <= `AXIBM_W_READY_LOW;     // On reset, go defaults
    else
      w_state  <= w_state_nxt;              // On a clock, pop the Nxt
  end

//-------------------------------------------------------------------------
// bvalid State Machine
//-------------------------------------------------------------------------

always @(wlast or i_wready or wvalid or bready or b_state)
  begin : p_b_state_comb
    case (b_state)
  
      `AXIBM_B_VALID_LOW :
         begin
            i_bvalid = 1'b0;
            b_state_nxt = (wlast & i_wready & wvalid) ? `AXIBM_B_VALID_HIGH :
           `AXIBM_B_VALID_LOW;
         end

      `AXIBM_B_VALID_HIGH :
         begin
           i_bvalid = 1'b1;
           b_state_nxt = (bready) ? `AXIBM_B_VALID_LOW : 
          `AXIBM_B_VALID_HIGH;
         end

      default : b_state_nxt = `AXIBM_B_VALID_LOW;
      
    endcase
  end // p_b_state_comb
  
  
// Clock the registers
  
  always @(negedge aresetn or posedge aclk)
    begin : p_b_stateSeq
      if (~aresetn)
        b_state  <= `AXIBM_B_VALID_LOW;      // On reset, go defaults
      else
       b_state  <= b_state_nxt;                // On a clock, pop the Nxt
    end

//-------------------------------------------------------------------------
// bid 
//-------------------------------------------------------------------------

always @(negedge aresetn or posedge aclk)
  begin : p_bid_set_seq
    if (~aresetn)
      i_bid <= {8{1'b0}};  // On reset, go defaults
    else if(awtrans)
      i_bid <= awid;       // On a clock and a handshake, set the bid from awid
  end

//-------------------------------------------------------------------------
// arready State Machine
//-------------------------------------------------------------------------


always @(arvalid or rready or i_rlast or ar_state)
  begin : p_ar_stateComb
    case (ar_state)
  
      `AXIBM_AR_READY_HIGH : 
         begin 
           i_arready = 1'b1; 
           ar_state_nxt = arvalid ? `AXIBM_AR_READY_LOW : 
          `AXIBM_AR_READY_HIGH; 
         end
      
      `AXIBM_AR_READY_LOW :
         begin
           i_arready = 1'b0;
           ar_state_nxt = (rready & i_rlast) ? `AXIBM_AR_READY_HIGH : 
          `AXIBM_AR_READY_LOW;
         end
      
      default : ar_state_nxt = `AXIBM_AR_READY_HIGH;

    endcase
  end // p_ar_stateComb


// Clock the registers
  
always @(negedge aresetn or posedge aclk)
  begin : p_ar_state_seq
    if (~aresetn)
      ar_state <= `AXIBM_AR_READY_HIGH;      // On reset, go defaults
    else
      ar_state <= ar_state_nxt;                // On a clock, pop the Nxt
  end

//-------------------------------------------------------------------------
// rvalid State Machine
//-------------------------------------------------------------------------

always @(artrans or i_rlast or rready or r_state)
  begin : p_r_state_comb
    case (r_state)
    
      `AXIBM_R_VALID_LOW :
         begin
           i_rvalid = 1'b0;
           r_state_nxt =  (artrans) ? `AXIBM_R_VALID_HIGH : 
          `AXIBM_R_VALID_LOW;
         end

      `AXIBM_R_VALID_HIGH :
         begin
           i_rvalid = 1'b1;
           r_state_nxt = (i_rlast & rready) ? `AXIBM_R_VALID_LOW : 
          `AXIBM_R_VALID_HIGH;
         end

      default : r_state_nxt = `AXIBM_R_VALID_LOW;
        
    endcase
  end // p_r_state_comb
  
  
// Clock the registers
  
always @(negedge aresetn or posedge aclk)
  begin : p_r_stateSeq
    if (~aresetn)
      r_state  <= `AXIBM_R_VALID_LOW;     // On reset, go defaults
    else
      r_state  <= r_state_nxt;              // On a clock, pop the Nxt
  end

//-------------------------------------------------------------------------
// rid 
//-------------------------------------------------------------------------

always @(negedge aresetn or posedge aclk)
  begin : p_rid_set_seq
    if (~aresetn)
      i_rid <= {8{1'b0}};  // On reset, go defaults
    else if(artrans)
      i_rid <= arid;                     // On a clock and a handshake, 
                                           // set the rid from arid
  end

//-------------------------------------------------------------------------
// Decrement counter on Read handshake and rising clock
//-------------------------------------------------------------------------

always @( artrans or arlen or rready or i_rvalid or reads_left)
  begin : p_r_counter_dec_comb
    if (artrans)                      // AR Handshake, set
       reads_left_nxt = arlen;
    else if((reads_left != {8{1'b0}}) & rready & i_rvalid)   
       // R Handshake, not rlast, decrement
       reads_left_nxt = reads_left - {{7{1'b0}},1'b1}; // spyglass disable W484
    else                              // Rlast do nothing
       reads_left_nxt = reads_left;
  end // p_r_counter_dec_comb
  

// Clock the register to decrement the counter
always @(negedge aresetn or posedge aclk)
  begin : p_r_counter_dec_seq
    if (~aresetn)
      reads_left  <= {8{1'b0}};       // On reset, go defaults
    else
      reads_left  <= reads_left_nxt;  // On a clock, pop the Nxt
  end


`include "Axi_undefs.v" //spyglass disable W701

endmodule

`include "nic400_default_slave_ds_1_undefs_1.v"


