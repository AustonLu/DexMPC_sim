
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
// File Date           :  2009-07-01 14:20:39 +0100 (Wed, 01 Jul 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : AMIB Combinatorial Byte Lane Strobe Generator.
// 
//           Configured for a 32-bit datawidth.
// 
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi.v"


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module axi_to_ahb_s_gen_32
(
  // inputs
  addr,
  burst_size,
  // output
  strb
);

//------------------------------------------------------------------------------
// Block Parameters
//------------------------------------------------------------------------------

  // Use Definable Parameters
  parameter DATA_WIDTH = 32;                // Data Width

  // Calculated Parameters
  parameter STRB_WIDTH = (DATA_WIDTH / 8);  // Strobe Width
  parameter STRB_MAX   = (STRB_WIDTH - 1);  // Strobe MSB


//------------------------------------------------------------------------------
// Block Inputs and Outputs
//------------------------------------------------------------------------------

  input          [1:0]  addr;               // Current address
  input          [2:0]  burst_size;         // Burst size

  output  [STRB_MAX:0]  strb;               // Correct byte lane strobes

  wire           [1:0]  addr;               // Current address
  wire           [2:0]  burst_size;         // Burst size
  reg     [STRB_MAX:0]  strb;               // Correct byte lane strobes


//------------------------------------------------------------------------------
//
//  Main body of code
//  =================
//
//------------------------------------------------------------------------------

  // Calculate byte lane strobes from address and burst size
  always @ (burst_size or addr)
  begin : p_strb_gen_comb
    case (burst_size)
      `AXI_ASIZE_8 :
        case (addr[1:0])
          2'b00   : strb = 4'b0001;
          2'b01   : strb = 4'b0010;
          2'b10   : strb = 4'b0100;
          2'b11   : strb = 4'b1000;
          default : strb = 4'bxxxx;
        endcase // case (addr[1:0])
      
      `AXI_ASIZE_16 :
        case (addr[1:0])
          2'b00   : strb = 4'b0011;
          2'b01   : strb = 4'b0010;
          2'b10   : strb = 4'b1100;
          2'b11   : strb = 4'b1000;
          default : strb = 4'bxxxx;
        endcase // case (addr[1:0])
      
      `AXI_ASIZE_32 :
        case (addr[1:0])
          2'b00   : strb = 4'b1111;
          2'b01   : strb = 4'b1110;
          2'b10   : strb = 4'b1100;
          2'b11   : strb = 4'b1000;
          default : strb = 4'bxxxx;
        endcase // case (addr[1:0])

      default : strb = 4'bxxxx;
    endcase // case (burst_size)
  end // block: p_strb_gen_comb


endmodule // axi_to_ahb_s_gen_32


//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi_undefs.v"


//------------------------------------------------------------------------------
// End of File
//------------------------------------------------------------------------------

