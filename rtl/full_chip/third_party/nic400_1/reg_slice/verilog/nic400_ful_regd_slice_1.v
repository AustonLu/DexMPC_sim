//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2004-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//  Version and Release Control Information:
//
//  File Revision       : 150000
//  File Date           :  2013-05-09 16:07:32 +0100 (Thu, 09 May 2013)
//
//  Release Information : PL401-r1p2-00rel0
//-----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//
//                               ful_regd_slice.v
//                              ================
//
//----------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The ful_regd_slice is a sub-component of the reg_slice_axi that provides 
// full timing isolation between the source and destination interfaces.
//
//   The ful_regd_slice monitors and drives the handshake signals from/to
// the master and slave interfaces.  The component instantiates two storage
// registers to ensure a minimum latency of 1 and back to back transfer
// support.  A minimum of two storage registers are required for full timing
// isolation due to the latency effects of the registers and protocol 
// requirements.
//
// A single variable size signal array is used to enable reuse over all AXI
// channels.
//
// sel_b is split into a bused signal in order to reduce the loading on the
// registers generating sel_b.  Each sel_b[] signal drives no more than 8
// multiplexor elements.  sel_b[NUM_SEL_LINES] drives the remainder, sel_b[0] is
// used in the control logic.
//
//----------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module nic400_ful_regd_slice_1
  (
   // global signals
   aresetn,
   aclk,

   // Inputs
   valid_src,
   ready_dst,
   payload_src,

   // outputs
   valid_dst,
   ready_src,
   payload_dst
   );

  //----------------------------------------------------------------------------
  // parameters
  //----------------------------------------------------------------------------
  // user defined parameters
  parameter PAYLD_WIDTH = 2;

  // calculated parameters (do not alter)
  parameter PAYLD_MAX = (PAYLD_WIDTH - 1);
  parameter NUM_SEL_LINES  = (PAYLD_WIDTH + 7) / 8;
  parameter REM_SEL_LINE   = (((PAYLD_WIDTH - 1) % 8) + 1);


  //----------------------------------------------------------------------------
  // port definitions
  //----------------------------------------------------------------------------
  // global interconnect inputs
  input                 aresetn;        // AXI global reset
  input                 aclk;           // AXI global clock

  // inputs
  input                 valid_src;      // transfer valid from the source
  input                 ready_dst;      // destination ready to accept transfer
  input [PAYLD_MAX:0]   payload_src;    // transfer payload from source

  // outputs
  output                valid_dst;      // transfer valid to the destination
  output                ready_src;      // source ready to accept transfer
  output [PAYLD_MAX:0]  payload_dst;    // transfer payload from source

  //----------------------------------------------------------------------------
  // port type declarations
  //----------------------------------------------------------------------------
  wire                  aresetn;        // AXI global reset
  wire                  aclk;           // AXI global clock

  // inputs
  wire                  valid_src;      // transfer valid from the source
  wire                  ready_dst;      // destination ready to accept transfer
  wire [PAYLD_MAX:0]    payload_src;    // transfer payload from source

  // outputs
  wire                  valid_dst;      // transfer valid to the destination
  wire                  ready_src;      // source ready to accept transfer
  reg [PAYLD_MAX:0]     payload_dst;    // transfer payload to destination

  //----------------------------------------------------------------------------
  // internal signals declarations
  //----------------------------------------------------------------------------
  wire                  enable_a;       // enable the load of payload register A
  wire                  enable_b;       // enable the load of payload register B
  wire                  load_sel_en;    // enable the load selection to change
  wire                  nxt_valid_a;    // next value for valid_a
  wire                  nxt_valid_b;    // next value for valid_a
  reg [PAYLD_MAX:0]     payload_reg_a;  // storage register A
  reg [PAYLD_MAX:0]     payload_reg_b;  // storage register B
  reg                   valid_a;        // status of the register set A
  reg                   valid_b;        // status of the register set A
  wire                  iready_src;     // internal version of ready_src
  wire                  ivalid_dst;     // internal version of valid_dst
  reg                   load_b;         // load selection for the next transfer
  reg [NUM_SEL_LINES:0] sel_b;          // select driver for payload_dst
  wire                  sel_b_en;       // enable for select driver register

  //----------------------------------------------------------------------------
  // start of code
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // output valid_dst;
  //----------------------------------------------------------------------------
  assign valid_dst = ivalid_dst;

  //----------------------------------------------------------------------------
  // output ready_src;
  //----------------------------------------------------------------------------
  assign ready_src = iready_src;

  //----------------------------------------------------------------------------
  // output payload_dst;
  //----------------------------------------------------------------------------
  // If sel_b is driven high, drive the contents of payload B onto the output.
  // If sel_b is not driven high, drive the contents of payload A onto the output.
  always @(sel_b or payload_reg_a or payload_reg_b)
  begin : p_payload_mux
    integer i;    // Loop counter through the select lines
    integer j;    // Loop counter through the bits in each mux array
    integer base; // Increment through the bit number of the payload
    base = 0;
    // Mux for the full bytes of payload
    for (i=1; i<NUM_SEL_LINES; i=i+1)
    begin
      for (j=base; j<(base+8); j=j+1)
        payload_dst[j] = (sel_b[i] ? payload_reg_b[j] : payload_reg_a[j]);
      base = (8 * i);
    end
    // Mux for the remaining bits of payload
    for (j=base; j<(base+REM_SEL_LINE); j=j+1)
      payload_dst[j] = (sel_b[NUM_SEL_LINES] ? payload_reg_b[j] : payload_reg_a[j]);
  end

  //----------------------------------------------------------------------------
  // wire enable_a;
  //----------------------------------------------------------------------------
  // Enable signal to load payload register A.  This can happen when selected
  // by the load_b signal and a handshake on the source interface.  The signal
  // iready_src is only driven high when either of the payload registers are
  // empty, which ensures the payload cannot be overridden.
  assign enable_a = ~load_b & valid_src & iready_src;

  //----------------------------------------------------------------------------
  // wire enable_b;
  //----------------------------------------------------------------------------
  // Enable signal to load payload register B.  This can happen when selected
  // by the load_b signal and a handshake on the source interface.  The signal
  // iready_src is only driven high when either of the payload registers are
  // empty, which ensures the payload cannot be overridden.
  assign enable_b = load_b & valid_src & iready_src;

  //----------------------------------------------------------------------------
  // wire load_sel_en;
  //----------------------------------------------------------------------------
  // Enable signal for the register that selects which payload register will
  // be loaded next.  The control is updated when a handshake occurs on the
  // source interface.  The signal iready_src is only driven high when either of
  // the payload registers are empty, which ensures the payload cannot be
  // overridden.
  assign load_sel_en = valid_src & iready_src;

  //----------------------------------------------------------------------------
  // wire nxt_valid_a;
  //----------------------------------------------------------------------------
  // Next value for the payload register A status flag.  If the payload
  // register A is loaded, as flagged by the enable_a signal, it will contain
  // a valid payload.  If payload A is driven on the destination interface
  // and a valid-ready handshake occurs, then the payload is invalid.
  assign nxt_valid_a = (enable_a ? 1'b1
                      :((~sel_b[0] & ivalid_dst & ready_dst) ? 1'b0
                        : valid_a));

  //----------------------------------------------------------------------------
  // wire nxt_valid_b;
  //----------------------------------------------------------------------------
  // Next value for the payload register B status flag.  If the payload
  // register B is loaded, as flagged by the enable_b signal, it will contain
  // a valid payload.  If payload B is driven on the destination interface
  // and a valid-ready handshake occurs, then the payload is invalid.
  assign nxt_valid_b = (enable_b ? 1'b1
                      :((sel_b[0] & ivalid_dst & ready_dst) ? 1'b0
                        : valid_b));

  //----------------------------------------------------------------------------
  // reg payload_reg_a;
  //----------------------------------------------------------------------------
  // Holds transfer payload information.  A payload is loaded when a
  // handshake occurs on the source interface and this register has been
  // selected.  See enable_a for details.
  always @(posedge aclk)
  begin : p_payload_reg_a
    if (enable_a)
      payload_reg_a <= payload_src;
  end // block : p_payload_reg_a

  //----------------------------------------------------------------------------
  // reg payload_reg_b;
  //----------------------------------------------------------------------------
  // Holds transfer payload information.  A payload is loaded when a
  // handshake occurs on the source interface and this register has been
  // selected.  See enable_b for details.
  always @(posedge aclk)
  begin : p_payload_reg_b
    if (enable_b)
      payload_reg_b <= payload_src;
  end // block : p_payload_reg_b

  //----------------------------------------------------------------------------
  // reg valid_a;
  //----------------------------------------------------------------------------
  // Status of payload register A.  This register is driven high when a
  // payload is loaded in to payload register A.  It is driven low when the
  // stored payload has been driven on the destination interface, and a
  // valid-ready handshake has occurred.  See nxt_valid_a for more details.
  always @(posedge aclk or negedge aresetn)
  begin : p_valid_a
    if (~aresetn)
      valid_a <= 1'b0;
    else
      valid_a <= nxt_valid_a;
  end // block : p_valid_a

  //----------------------------------------------------------------------------
  // reg valid_b;
  //----------------------------------------------------------------------------
  // Status of payload register B.  This register is driven high when a
  // payload is loaded in to payload register B.  It is driven low when the
  // stored payload has been driven on the destination interface, and a
  // valid-ready handshake has occurred.  See nxt_valid_b for more details.
  always @(posedge aclk or negedge aresetn)
  begin : p_valid_b
    if (~aresetn)
      valid_b <= 1'b0;
    else
      valid_b <= nxt_valid_b;
  end // block : p_valid_b

  //----------------------------------------------------------------------------
  // wire iready_src;
  //----------------------------------------------------------------------------
  // Calculated ready status of the ful_regd_slice component.  If either payload
  // register A or payload register B are empty, then the ful_regd_slice
  // component is ready to accept a transfer payload.
  assign iready_src = ~valid_a | ~valid_b;

  //----------------------------------------------------------------------------
  // wire ivalid_dst;
  //----------------------------------------------------------------------------
  // Calculated valid status of the ful_reg_slice component.  If either payload
  // register A or payload register B contain a valid payload, then the 
  // ful_regd_slice component can issue a valid transfer payload.
  assign ivalid_dst = valid_a | valid_b;

  //----------------------------------------------------------------------------
  // reg load_b;
  //----------------------------------------------------------------------------
  // Control flag to select in which payload register to load the next
  // transfer payload. The control toggled to indicate an alternate selection
  // between the two payload registers.  See load_sel_en for more details.
  always @(posedge aclk or negedge aresetn)
  begin : p_load_b
    if (~aresetn)
      load_b <= 1'b0;
    else
      if (load_sel_en)
        load_b <= ~load_b;
  end // block : p_load_b

  //----------------------------------------------------------------------------
  // wire sel_b_en;
  //----------------------------------------------------------------------------
  // Determines when to toggle the output select. Only toggles when a 
  // register contains a valid payload in order to reduce toggle power.
  assign sel_b_en = ((~sel_b[0] & nxt_valid_b & (~valid_a | ready_dst)) |
                     ( sel_b[0] & nxt_valid_a & (~valid_b | ready_dst)));
 
  //----------------------------------------------------------------------------
  // reg sel_b;
  //----------------------------------------------------------------------------
  // Control flag to select from which payload register to drive the
  // destination output.  The control toggled to indicate an alternate selection
  // between the two payload registers.  See drive_sel_en for more details.
  always @(posedge aclk or negedge aresetn)
  begin : p_sel_b
    if (~aresetn)
      sel_b <= {NUM_SEL_LINES+1{1'b0}};
    else
      if (sel_b_en)
        sel_b <= ~sel_b;
  end // block : p_sel_b

endmodule // ful_regd_slice
//----------------------------------  END  -------------------------------------

