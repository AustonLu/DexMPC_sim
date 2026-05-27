
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
// File Revision       : 135247
// File Date           :  2009-04-10 16:53:24 +0100 (Fri, 10 Apr 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : AMIB Combinatorial Address Incrementor
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi.v"


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module axi_to_ahb_a_gen_32
(
  // inputs
  addr_in,
  alen,
  asize,
  aburst,
  // output
  addr_out
);


//------------------------------------------------------------------------------
// Block Parameters
//------------------------------------------------------------------------------

  // User Definable Parameters
  parameter ADDR_WIDTH = 12;                // Address Width

  // Calculated Parameters
  parameter ADDR_MSB   = (ADDR_WIDTH-1);    // Address MSB
  parameter ADDR_WM2   = (ADDR_WIDTH-2);    // Address Width Minus 2
  parameter ADDR_WM3   = (ADDR_WIDTH-3);    // Address Width Minus 3
  parameter ADDR_WM4   = (ADDR_WIDTH-4);    // Address Width Minus 4
  parameter ADDR_WM5   = (ADDR_WIDTH-5);    // Address Width Minus 5
  parameter ADDR_WM6   = (ADDR_WIDTH-6);    // Address Width Minus 6


//------------------------------------------------------------------------------
// Block Inputs and Outputs
//------------------------------------------------------------------------------

  input   [ADDR_MSB:0]  addr_in;            // Current address
  input          [3:0]  alen;               // Burst length
  input          [2:0]  asize;              // Burst size
  input          [1:0]  aburst;             // Burst type

  output  [ADDR_MSB:0]  addr_out;           // Next address

  wire    [ADDR_MSB:0]  addr_in;            // Current address
  wire           [3:0]  alen;               // Burst length
  wire           [2:0]  asize;              // Burst size
  wire           [1:0]  aburst;             // Burst type
  wire    [ADDR_MSB:0]  addr_out;           // Next address


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  reg     [ADDR_MSB:0]  offset_addr;        // shifted address
  wire    [ADDR_MSB:0]  incr_addr;          // incremented address
  wire    [ADDR_MSB:0]  wrap_addr;          // wrapped address
  wire    [ADDR_MSB:0]  mux_addr;           // address selected by burst type
  reg     [ADDR_MSB:0]  calc_addr;          // final calculated address


//------------------------------------------------------------------------------
//
//  Main body of code
//  =================
//
//------------------------------------------------------------------------------

  //--------------------------------------------------------------------------
  // Combinational address shift right
  //
  // offset_addr indicates the address bits of interest, depending on asize
  //--------------------------------------------------------------------------
  always @ (asize or addr_in)
  begin : p_offset_addr_comb
    case (asize)
      `AXI_ASIZE_8    : offset_addr = addr_in[ADDR_MSB:0];
      `AXI_ASIZE_16   : offset_addr = {1'b0,     addr_in[ADDR_MSB:1]};
      `AXI_ASIZE_32   : offset_addr = {2'b00,    addr_in[ADDR_MSB:2]};
      `AXI_ASIZE_64   : offset_addr = {3'b000,   addr_in[ADDR_MSB:3]};
      `AXI_ASIZE_128  : offset_addr = {4'b0000,  addr_in[ADDR_MSB:4]};
      `AXI_ASIZE_256  : offset_addr = {5'b00000, addr_in[ADDR_MSB:5]};
      `AXI_ASIZE_512  : offset_addr = addr_in[ADDR_MSB:0];  // illegal asize
      `AXI_ASIZE_1024 : offset_addr = addr_in[ADDR_MSB:0];  // illegal asize
      default         : offset_addr = {ADDR_WIDTH{1'bx}};
    endcase
  end // p_offset_addr_comb

  // increment the address
  assign incr_addr = offset_addr + 1'b1;


  //--------------------------------------------------------------------------
  // Address wrapping
  //
  // The address of the next transfer should wrap on the next transfer if the
  // boundary is reached. Assumes alen = 2, 4, 8, or 16.
  //--------------------------------------------------------------------------
  // Upper bits of wrapped address remain static
  assign wrap_addr[ADDR_MSB:4] = offset_addr[ADDR_MSB:4];

  // Wrap lower bits according to length of burst
  assign wrap_addr[3:0] = ( alen &   incr_addr[3:0]) |
                          (~alen & offset_addr[3:0]);


  //--------------------------------------------------------------------------
  // Combinational address multiplexor
  //
  // Choose the final offset address depending on burst type
  //--------------------------------------------------------------------------

  assign mux_addr = (aburst == `AXI_ABURST_WRAP) ? wrap_addr : incr_addr;


  //--------------------------------------------------------------------------
  // Combinational address shift left
  //
  // Shift the bits of interest to the correct bits of the resultant address
  //--------------------------------------------------------------------------
  always @ (asize or mux_addr)
  begin : p_calc_addr_comb
    case (asize)
      `AXI_ASIZE_8    : calc_addr =  mux_addr[ADDR_MSB:0];
      `AXI_ASIZE_16   : calc_addr = {mux_addr[ADDR_WM2:0], 1'b0};
      `AXI_ASIZE_32   : calc_addr = {mux_addr[ADDR_WM3:0], 2'b00};
      `AXI_ASIZE_64   : calc_addr = {mux_addr[ADDR_WM4:0], 3'b000};
      `AXI_ASIZE_128  : calc_addr = {mux_addr[ADDR_WM5:0], 4'b0000};
      `AXI_ASIZE_256  : calc_addr = {mux_addr[ADDR_WM6:0], 5'b00000};
      `AXI_ASIZE_512  : calc_addr =  mux_addr[ADDR_MSB:0];  // illegal asize
      `AXI_ASIZE_1024 : calc_addr =  mux_addr[ADDR_MSB:0];  // illegal asize
      default         : calc_addr = {ADDR_WIDTH{1'bx}};
    endcase
  end // p_calc_addr_comb

  assign addr_out = (aburst == `AXI_ABURST_FIXED) ? addr_in : calc_addr;


endmodule // axi_to_ahb_a_gen_32


//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi_undefs.v"


//------------------------------------------------------------------------------
// End of File
//------------------------------------------------------------------------------

