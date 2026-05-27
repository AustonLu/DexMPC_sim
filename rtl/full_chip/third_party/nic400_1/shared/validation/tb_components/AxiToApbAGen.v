//  --=====================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2004-2009 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//  -------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : $RCSfile: AxiToApbAGen.v,v $
//  File Revision       : 84668
//
//  Release Information : PL401-r1p2-00rel0
//
//  -------------------------------------------------------------------------
//  Purpose             : Combinatorial address incrementor
//                        The address only increments over 4kB, so bits 12 
//                        and greater won't change.
//  --=====================================================================--


`timescale 1ns / 1ps

//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi.v"

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module AxiToApbAGen
  (
  // inputs
    AddrIn,
    ALEN,
    ASIZE,
    ABURST,
  // output
    AddrOut
  );

  input  [11 : 0] AddrIn;   //  Current address
  input   [3 : 0] ALEN;     //  Burst length
  input   [2 : 0] ASIZE;    //  Burst size
  input   [1 : 0] ABURST;   //  Burst type

  output [11 : 0] AddrOut;  //  Next address

  wire   [11 : 0] AddrIn;
  wire    [3 : 0] ALEN;
  wire    [2 : 0] ASIZE;
  wire    [1 : 0] ABURST;
  wire   [11 : 0] AddrOut;

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  reg  [11 : 0] OffsetAddr; //  shifted address
  wire [11 : 0] IncrAddr;   //  incremented address
  wire [11 : 0] WrapAddr;   //  wrapped address
  wire [11 : 0] MuxAddr;    //  address selected by burst type
  reg  [11 : 0] CalcAddr;   //  final calculated address


//  -------------------------------------------------------------------------
//
//  Main body of code
//  =================
//
//  -------------------------------------------------------------------------


//  -------------------------------------------------------------------------
//  Combinational address shift right
//
//  OffsetAddr indicates the address bits of interest, depending on ASIZE
//  -------------------------------------------------------------------------
  always @ (ASIZE or AddrIn)
  begin : p_OffsetAddrComb
    case (ASIZE)
      `AXI_ASIZE_8  : OffsetAddr <= AddrIn[11:0];
      `AXI_ASIZE_16 : OffsetAddr <= { 1'b0 ,  AddrIn[11:1] };
      `AXI_ASIZE_32 : OffsetAddr <= { 2'b00,  AddrIn[11:2] };
      `AXI_ASIZE_64 : OffsetAddr <= { 3'b000, AddrIn[11:3] };
      default       : OffsetAddr <= {12{1'bx}}; // illegal switch
    endcase
  end

  // increment the address
  assign IncrAddr = OffsetAddr + 1'b1;


//  -------------------------------------------------------------------------
//  Address wrapping
//
//  The address of the next transfer should wrap on the next transfer if the
//  boundary is reached. Assumes ASIZE = 2, 4, 8, or 16.
//  -------------------------------------------------------------------------
  // Upper bits of wrapped address remain static
  assign WrapAddr[11:4] = OffsetAddr[11:4];

  // Wrap lower bits according to length of burst
  assign WrapAddr[3:0]  = (ALEN & IncrAddr[3:0]) | (~ALEN & OffsetAddr[3:0]);


//  -------------------------------------------------------------------------
//  Combinational address multiplexor
//
//  Choose the final offset address depending on burst type
//  -------------------------------------------------------------------------

  assign MuxAddr = ABURST == `AXI_ABURST_WRAP ? WrapAddr : IncrAddr;
  

//  -------------------------------------------------------------------------
//  Combinational address shift left
//
//  Shift the bits of interest to the correct bits of the resultant address
//  -------------------------------------------------------------------------
  always @ (ASIZE or MuxAddr)
  begin : p_CalcAddrComb
    case (ASIZE)
      `AXI_ASIZE_8  : CalcAddr <= MuxAddr;
      `AXI_ASIZE_16 : CalcAddr <= {MuxAddr [10:0],1'b0 };
      `AXI_ASIZE_32 : CalcAddr <= {MuxAddr [ 9:0],2'b00};
      `AXI_ASIZE_64 : CalcAddr <= {MuxAddr [ 8:0],3'b000};
      default       : CalcAddr <= {12{1'bx}}; // illegal switch
    endcase
  end

  assign AddrOut = (ABURST == `AXI_ABURST_FIXED) ? AddrIn : CalcAddr;
  
endmodule
//  --=============================== End =================================--
