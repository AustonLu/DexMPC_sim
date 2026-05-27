//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2005-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//  Version and Release Control Information:
//
//  File Revision       : 58538
//  File Date           :  2009-04-06 15:29:21 +0100 (Mon, 06 Apr 2009)
//
//  Release Information : PL401-r1p2-00rel0
//-----------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                              rev_regd_slice.v
//                             ================
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The rev_regd_slice is a sub-component of the reg_slice_axi that provides 
// reverse-path timing isolation between the source and destination 
// interfaces.
//
//   The rev_regd_slice monitors and drives the handshake signals from/to
// the master and slave interfaces. The component instantiates one storage
// register and ensures a minimum latency of 1 and back to back transfer
// support by using a combinatorial path from valid_src to valid_dst.
//
// A single variable size signal array is used to enable reuse over all AXI
// channels.
//
// buffer_full is split into a bused signal in order to reduce the loading on
// the registers generating buffer_full.  Each buffer_full[] signal drives no
// more than 8 multiplexor elements.  buffer_full[NUM_SEL_LINES] drives the
// remainder, buffer_full[0] is used in the control logic.
//
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module rev_regd_slice
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
  // Parameters
  //----------------------------------------------------------------------------
  parameter PAYLD_WIDTH = 1;

  // calculated parameters (do not alter)
  parameter PAYLD_MAX      = PAYLD_WIDTH - 1;
  parameter NUM_SEL_LINES  = (PAYLD_WIDTH + 7) / 8;
  parameter REM_SEL_LINE   = (((PAYLD_WIDTH - 1) % 8) + 1);

  //----------------------------------------------------------------------------
  // Inputs / Outputs
  //----------------------------------------------------------------------------

  // Global signals
  input                 aclk;            // global AXI clock
  input                 aresetn;         // global AXI reset

  input [PAYLD_MAX:0]   payload_src;     // Input payload
  output [PAYLD_MAX:0]  payload_dst;     // Output payload


  // AXI muxed address input port
  input                 valid_src;       // Address/Control valid handshake
  output                ready_src;       // Address/Control ready handshake

  // AXI registe         red address output port
  output                valid_dst;       // Address/Control valid handshake
  input                 ready_dst;       // Address/Control ready handshake

  //----------------------------------------------------------------------------
  // Port signal declarations
  //----------------------------------------------------------------------------
  reg [PAYLD_MAX:0]     payload_dst;     // Output payload

  //----------------------------------------------------------------------------
  // Internal signal declarations
  //----------------------------------------------------------------------------
  reg [PAYLD_MAX:0]     payload_reg;     // Internal buffer
  wire                  buffer_en;       // Enable for internal buffer
  wire                  buffer_full_en;  // D-type enable for buffer_full
  reg [NUM_SEL_LINES:0] buffer_full;     // Indicates when the buffer is in use


  //----------------------------------------------------------------------------
  // BEGINNING OF MAIN CODE
  //----------------------------------------------------------------------------

  // Use an enable on the buffer to save power
  assign buffer_en = (valid_src & ~buffer_full[0] & ~ready_dst);

  always @(posedge aclk)
  begin : p_buffer_seq
    if (buffer_en)
      payload_reg <= payload_src;
  end

  // Set the buffer_full flag when the buffer is loaded.  Clear the flag when
  // the stored data is accepted
  assign buffer_full_en = (buffer_en | ready_dst);

  // Register buffer_full
  always @(negedge aresetn or posedge aclk)
  begin : p_buffer_full_seq
    if (~aresetn)
      buffer_full <= {NUM_SEL_LINES+1{1'b0}};
    else if (buffer_full_en)
      buffer_full <= {NUM_SEL_LINES+1{buffer_en}};
  end

  // Registered ready output
  assign ready_src = ~buffer_full[0];

  // Combinatorial valid and payload outputs
  assign valid_dst = (valid_src | buffer_full[0]);

  always @(buffer_full or payload_reg or payload_src)
  begin : p_payload_mux
    integer i;    // Loop counter through the select lines
    integer j;    // Loop counter through the bits in each mux array
    integer base; // Increment through the bit number of the payload
    base = 0;
    // Mux for the full bytes of payload
    for (i=1; i<NUM_SEL_LINES; i=i+1)
    begin
      for (j=base; j<(base+8); j=j+1)
        payload_dst[j] = (buffer_full[i] ? payload_reg[j] : payload_src[j]);
      base = (8 * i);
    end
    // Mux for the remaining bits of payload
    for (j=base; j<(base+REM_SEL_LINE); j=j+1)
      payload_dst[j] = (buffer_full[NUM_SEL_LINES] ? payload_reg[j]
                         : payload_src[j]);
  end

endmodule // rev_regd_slice

