//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 1998-2002, 2006-2009 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      Checked In          :  2009-11-05 21:17:37 +0000 (Thu, 05 Nov 2009)
//      Revision            : 84668
//
//-----------------------------------------------------------------------------
//  Purpose             : This is the  little-endian version of the
//                        Internal Memory component, and is a behavioral 
//                        Verilog model, which is not representative of a real
//                        on-chip RAM.
//
//                        The memory has no wait-states and can be configured
//                        to a specified size (default is 10 bits, equivalent 
//                        to 1Kbyte).
//
//                        The code reads in a simplified Verilog $readmemh
//                        format file, for compatability with VHDL simulation
//                        world files.
//
//                        To support big-endian mode, the code must be modified
//                        accordingly. Please check your system for the correct
//                        interpretation of the required big-endian format.
//
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module AhbMem(HCLK, HRESETn, HADDR, HTRANS, HWRITE, HSIZE, HWDATA, HSEL,
                HREADY, HRDATA, HREADYOUT, HRESP);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------
  parameter DATA_WIDTH       = 32;            
  parameter DATA_MAX         = DATA_WIDTH - 1;

  
  input                 HCLK;
  input                 HRESETn;
  input          [31:0] HADDR;
  input           [1:0] HTRANS;
  input                 HWRITE;
  input           [2:0] HSIZE;
  input   [DATA_MAX:0]  HWDATA; 
  input                 HSEL;
  input                 HREADY;

  output  [DATA_MAX:0]  HRDATA;
  output                HREADYOUT;
  output          [1:0] HRESP;


//------------------------------------------------------------------------------
// Default memory size and input filename settings
//------------------------------------------------------------------------------
  parameter MEM_ADDR_WIDTH  = 10;           // Memory size in address bits, 1kB default
  parameter FileName = "ahbram.dat";           // Input filename
  parameter ADDR_BOTTOM_BIT  = 2;           // it is equal to log2(DATA_WIDTH/8)
       
`define MEM_ARRAY_MAX (1 << (MEM_ADDR_WIDTH - ADDR_BOTTOM_BIT) - 1)
  
//------------------------------------------------------------------------------
//  Constant declarations
//------------------------------------------------------------------------------
// HTRANS transfer type signal encoding
  `define TRN_IDLE   2'b00
  `define TRN_BUSY   2'b01
  `define TRN_NONSEQ 2'b10
  `define TRN_SEQ    2'b11

// HRESP transfer response signal encoding
  `define RSP_OKAY   2'b00
  `define RSP_ERROR  2'b01
  `define RSP_RETRY  2'b10
  `define RSP_SPLIT  2'b11

  // HSIZE signal encoding
  `define SZ_BYTE       3'b000  //  8-bit access
  `define SZ_HALF       3'b001  // 16-bit access
  `define SZ_WORD       3'b010  // 32-bit access
  `define SZ_DWORD      3'b011  // 64-bit access
  `define SZ_128        3'b100  // 128-bit access

  
//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input/Output Signals
  wire        HCLK;
  wire        HRESETn;
  wire  [31:0] HADDR;
  wire  [1:0] HTRANS;
  wire        HWRITE;
  wire  [2:0] HSIZE;
  wire  [DATA_MAX:0] HWDATA;
  wire        HSEL;
  wire        HREADY;
  wire        HREADYOUT;

  reg   [1:0] HRESP;
  reg   [DATA_MAX:0] HRDATA;

  // Memory signals
  reg  [DATA_MAX:0] Mem [0:`MEM_ARRAY_MAX]; // Memory register array
  reg  [DATA_MAX:0] Data;                  // Temporary data store
  reg  [DATA_MAX:0] Mask;                  // Temporary data mask
  reg  [DATA_MAX:0] TempData;       
  integer           MemAddr;               // Memory address being accessed
  integer           i;                     // Loop counter for memory initialisation

  // Control Signals
  wire        ValidReg;              // valid data phase
  wire        ACRegEn;               // enable for address and control registers

  // Signals registered into data phase
  reg         HselReg;               // registered HSEL
  reg  [31:0] HaddrReg;              // registered HADDR
  reg   [1:0] HtransReg;             // registered HTRANS
  reg         HwriteReg;             // registered HWRITE
  reg   [2:0] HsizeReg;              // registered HSIZE

  // Ready/Response Signals
  wire        Invalid;               // indicates an ERROR response required
  wire  [1:0] HrespNext;             // D-input of HRESP register
  wire        HreadyNext;            // D-input of HREADYOUT register
  reg         iHREADYOUT;            // internal version of HREADYOUT output

  integer     BottomAddr;
  
//------------------------------------------------------------------------------
// Initialise Memory (only once)
//------------------------------------------------------------------------------

  initial
  begin
    for (i = 0; i <= `MEM_ARRAY_MAX; i = i + 1)
      Mem[i] = {DATA_WIDTH{1'b0}};
    if (FileName != "")
    begin
      $display("### Loading internal memory ###");
      $readmemh(FileName, Mem);
    end
  end


//------------------------------------------------------------------------------
// Beginning of main code
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Valid transfer detection
//------------------------------------------------------------------------------
// The slave must only respond to a valid transfer, so this must be detected.
 
  always @(negedge (HRESETn) or posedge (HCLK))
  begin
    if (!HRESETn)
      HselReg <= 1'b0;
    else
    begin
      if (HREADY)
        HselReg <= HSEL;
    end
  end
 
// Valid AHB transfers only take place when a non-sequential or sequential
// transfer is shown on HTRANS - an idle or busy transfer should be ignored.

  assign ValidReg = (HselReg == 1'b1 && (HtransReg == `TRN_NONSEQ ||
                                         HtransReg == `TRN_SEQ)) ? 1'b1 :
                    1'b0;

//------------------------------------------------------------------------------
// Address and control registers
//------------------------------------------------------------------------------
// Registers are used to store the address and control signals from the address
//  phase for use in the data phase of the transfer.
// Only enabled when the HREADY input is HIGH and the module is addressed.

  assign ACRegEn = HSEL & HREADY;

  always @(negedge (HRESETn) or posedge (HCLK))
  begin
    if (!HRESETn)
    begin
      HaddrReg  <= 32'h0000_0000;
      HtransReg <= 2'b00;
      HwriteReg <= 1'b0;
      HsizeReg  <= 3'b000;
    end
    else
    begin
      if (ACRegEn)
      begin
        HaddrReg  <= HADDR;
        HtransReg <= HTRANS;
        HwriteReg <= HWRITE;
        HsizeReg  <= HSIZE;
      end
    end
  end

//------------------------------------------------------------------------------
//  Memory read and write
//------------------------------------------------------------------------------


  always @(ValidReg or HaddrReg or HCLK)
  begin
    if (ValidReg)                        // Common to read and write operations
    begin
      MemAddr = HaddrReg[MEM_ADDR_WIDTH-1 : ADDR_BOTTOM_BIT]; // Memory address for this transfer
      Data = Mem[MemAddr];               // Data from addressed location
      Mask = {DATA_WIDTH{1'b0}} ;
      TempData = {DATA_WIDTH{1'b0}} ;
      
      @(posedge HCLK)   // Write-only section performed on the rising clock edge
      if (HwriteReg && ValidReg)
      begin
        TempData =  HWDATA ;

        case (HsizeReg)

          `SZ_BYTE  : Mask = 8'hFF << HaddrReg[3:0]%(DATA_WIDTH/8);               // Byte access

          `SZ_HALF  : Mask = 16'hFFFF << HaddrReg[3:1]%(DATA_WIDTH/16) ;               // Halfword access

          `SZ_WORD  : Mask = 32'hFFFFFFFF << HaddrReg[3:2]%(DATA_WIDTH/32)  ;              // Word access
          
          `SZ_DWORD : Mask = {64{1'b1}}   << HaddrReg[3]%(DATA_WIDTH/64) ;              // dWord access

          `SZ_128   : Mask = {128{1'b1}} ;                                             // 128-bit access  
                   
          default :     
           Mask = {DATA_WIDTH{1'b0}} ;

        endcase // case(HsizeReg)
        
        Mem[MemAddr] = (TempData & Mask) | (Data & ~Mask)  ;
      end
      
    end
  end

//------------------------------------------------------------------------------
// Output Drivers
//------------------------------------------------------------------------------
// Drive output data bus during read operation

  always @(ValidReg or HwriteReg or Data)
  begin
    if (ValidReg && !HwriteReg) // Valid read transfer
      HRDATA = Data;
    else
      HRDATA = {DATA_WIDTH{1'b0}};
  end

// Detect illegal accesses of larger than  HSIZE > data_width
  assign Invalid = ((HREADY == 1'b1 && HSEL == 1'b1 &&
                    (HTRANS == `TRN_NONSEQ || HTRANS == `TRN_SEQ) &&
                    ((1<<HSIZE) > (DATA_WIDTH/8))) ? 1'b1 :
                   1'b0);

// Generate first wait-state for two-cycle ERROR response
  assign HreadyNext = (iHREADYOUT == 1'b0 ? 1'b1 :
                      (Invalid == 1'b1 ? 1'b0 :
                      1'b1));

  always @( negedge (HRESETn) or posedge (HCLK) )
    begin
      if ((!HRESETn))
        iHREADYOUT <= 1'b1;
      else
        iHREADYOUT <= HreadyNext;
    end
 
  assign HREADYOUT = iHREADYOUT;

// An OKAY response is generated for transfers of legal size,
//  but a two cycle ERROR response is generated if a non-sequential
//  or sequential transfer is attempted and HSIZE > DATA_WIDTH.
  assign HrespNext = (Invalid == 1'b1 ? `RSP_ERROR : `RSP_OKAY);

  always @( negedge (HRESETn) or posedge (HCLK) )
    begin
      if ((!HRESETn))
        HRESP <= `RSP_OKAY;
      else
        begin
          if (iHREADYOUT)
            HRESP <= HrespNext;
        end
    end

//------------------------------------------------------------------------------
//  Constant declarations
//------------------------------------------------------------------------------
// HTRANS transfer type signal encoding
  `undef TRN_IDLE   
  `undef TRN_BUSY   
  `undef TRN_NONSEQ 
  `undef TRN_SEQ  


// HRESP transfer response signal encoding
  `undef RSP_OKAY  
  `undef RSP_ERROR 
  `undef RSP_RETRY 
  `undef RSP_SPLIT 

// Number of memory locations
  `undef MEM_ARRAY_MAX
  

endmodule

// --================================= End ===================================--

