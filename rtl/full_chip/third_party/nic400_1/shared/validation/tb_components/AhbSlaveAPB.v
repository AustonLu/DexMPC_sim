//============================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2003-2009 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : $RCSfile: AhbSlaveAPB,v $
//  File Revision       : 84668
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             : This is the AHB Slave Capture Block
//============================================================================--

module AhbSlaveAPB
  (
   // AHB signals
   HCLK,
   HRESETn,
   HRDATA,
   HREADY,
   HRESP,
   HADDR,
   HTRANS,
   HWRITE,
   HSIZE,
   HBURST,
   HPROT,
   HWDATA, 
   HMASTLOCK,
   
   HREADYOUT,
   HSEL, 
   
   // APB signals
   pclk,
   PRDATA, 
   PREADY, 
   PSEL, 
   PENABLE, 
   PWRITE, 
   PADDR, 
   PWDATA

   );


//------------------------------------------------------------------------------
// INDEX:   1) Parameters
//------------------------------------------------------------------------------


  // INDEX:        - Configurable (user can set)
  // =====
  // Parameters below can be set by the user.

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH = 32;         // data bus width, default = 32-bit

  parameter DATA_MAX   = DATA_WIDTH-1; // data max index


//------------------------------------------------------------------------------
// INDEX:   IO
//------------------------------------------------------------------------------
    
  input                           HCLK;      // Clock
  input                           HRESETn;   // Reset
  input             [DATA_MAX:0]  HRDATA;    // AHB Read Data
  input                           HREADY;    // AHB Ready
  input                           HRESP;     // AHB Response
  input                   [31:0]  HADDR;     // AHB Address
  input                    [1:0]  HTRANS;    // AHB Transfer
  input                           HWRITE;    // AHB Direction
  input                    [2:0]  HSIZE;     // AHB Size
  input                    [2:0]  HBURST;    // AHB Burst
  input                    [3:0]  HPROT;     // AHB Protection
  input             [DATA_MAX:0]  HWDATA;    // AHB Write Data
  input                           HMASTLOCK; // AHB lock (address phase)
 
  input                           HREADYOUT;  // AHB slave Readyout
  input                           HSEL;       // AHB hsel
  
  // INDEX:        - Low Power Interface
  // =====

  output [31:0]        PRDATA; 
  output               PREADY; 
  input                PSEL; 
  input                PENABLE; 
  input                PWRITE;
  input [31:0]         PADDR; 
  input [31:0]         PWDATA;
  input                pclk;

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
`define REG0       12'h000       // Register 0 Offset

//------------------------------------------------------------------------------
// wires
//------------------------------------------------------------------------------

 reg [31:0]            PRDATA; 
 wire                  enable;
 wire [31:0]           reg0;

//------------------------------------------------------------------------------
// APB  logic
//------------------------------------------------------------------------------
  assign PREADY = 1'b1;

  always@(enable or PADDR or PWRITE or
          reg0 ) begin
    PRDATA = 32'b0;
    if(enable && !PWRITE)
      case(PADDR[11:0])
       `REG0 : PRDATA = reg0;
        default  : PRDATA = 32'd0;
      endcase
  end

  assign enable = (PSEL & ~PWRITE & PENABLE);
  
//------------------------------------------------------------------------------
// Register 0
//------------------------------------------------------------------------------

 assign reg0 = {30'b0, HWRITE, HREADY};

endmodule
