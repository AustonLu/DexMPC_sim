//  --========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2004-2009 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//  
//  ----------------------------------------------------------------------------
//  Version and Release Control Information:
//  
//  File Name          : AhbToApb.v,v
//  File Revision      : 1.7
//  
//  Release Information : BP010-AC-39002-r3p0-00rel0
//  
//  ----------------------------------------------------------------------------
//  Purpose            : Converts AHB peripheral transfers to APB transfers
//  --========================================================================--

`timescale 1ns/1ps

module AhbToApb (
// Inputs
                 // Global signals
                 HCLK,
                 HRESETn,
                 // AHB interface
                 HADDR,
                 HTRANS,  // Connect HTRANS[1] signal of HTRANS[1:0]
                 HWRITE,
                 HWDATA,
                 HSEL,
                 HREADY,
                 // APB interface
                 PREADY,
                 PSLVERR,
                 PRDATA,
                 // Scan signals
                 SCANENABLE,
                 SCANINHCLK,
// Outputs
                 // AHB interface
                 HRDATA,
                 HREADYOUT,
                 HRESP,
                 // APB interface
                 PENABLE,
                 PSEL,
                 PSELS0,
                 PSELS1,
                 PSELS2,
                 PSELS3,
                 PSELS4,
                 PSELS5,
                 PSELS6,
                 PSELS7,
                 PSELS8,
                 PSELS9,
                 PSELS10,
                 PSELS11,
                 PSELS12,
                 PSELS13,
                 PSELS14,
                 PSELS15,
                 PADDR,
                 PWRITE,
                 PWDATA,
                 // Scan signals
                 SCANOUTHCLK
                );
    
// Inputs
input         HCLK;            // AHB Bus Clock
input         HRESETn;         // AHB system level Reset
input  [31:0] HADDR;           // AHB address input for APB accesses
input         HTRANS;          // AHB transfer type indication for APB accesses
input         HWRITE;          // AHB transfer(R/W) direction for APB accesses
input  [31:0] HWDATA;          // AHB write data for APB accesses
input         HSEL;            // AHB select line for APB accesses
input         HREADY;          // AHB transfer completion input signal
input         PREADY;          // APB transfer completion input signal
input         PSLVERR;         // APB error response indication input signal
input  [31:0] PRDATA;          // APB read data
input         SCANENABLE;      // Enable for Scan Mode
input         SCANINHCLK;      // Scan chain input with respect to HCLK

// Outputs
output [31:0] HRDATA;          // AHB read data from APB slave
output        HREADYOUT;       // AHB transfer completion output signal
output [1:0]  HRESP;           // AHB response output for APB accesses
output [31:0] PWDATA;          // APB write data from AHB
output        PENABLE;         // APB Enable
output        PSEL;            // Select signal for APB bus transfer
output        PSELS0;          // APB select for slave 0
output        PSELS1;          // APB select for slave 1
output        PSELS2;          // APB select for slave 2
output        PSELS3;          // APB select for slave 3
output        PSELS4;          // APB select for slave 4
output        PSELS5;          // APB select for slave 5
output        PSELS6;          // APB select for slave 6
output        PSELS7;          // APB select for slave 7
output        PSELS8;          // APB select for slave 8
output        PSELS9;          // APB select for slave 9
output        PSELS10;         // APB select for slave 10
output        PSELS11;         // APB select for slave 11
output        PSELS12;         // APB select for slave 12
output        PSELS13;         // APB select for slave 13
output        PSELS14;         // APB select for slave 14
output        PSELS15;         // APB select for slave 15
output [31:0] PADDR;           // APB address
output        PWRITE;          // APB transfer(R/W) direction
output        SCANOUTHCLK;     // Scan chain output with respect to HCLK

// -----------------------------------------------------------------------------
// Signal declarations for i/o ports
// -----------------------------------------------------------------------------

// Inputs
wire         HCLK;            // AHB Bus Clock
wire         HRESETn;         // AHB system level Reset
wire  [31:0] HADDR;           // AHB address input for APB accesses
wire         HTRANS;          // AHB transfer type indication for APB accesses
wire         HWRITE;          // AHB transfer(R/W) direction for APB accesses
wire  [31:0] HWDATA;          // AHB write data for APB accesses
wire         HSEL;            // AHB select line for APB accesses
wire         HREADY;          // AHB transfer completion input signal
wire         PREADY;          // APB transfer completion input signal
wire         PSLVERR;         // APB error response indication input signal
wire  [31:0] PRDATA;          // APB read data
wire         SCANENABLE;      // Enable for Scan Mode
wire         SCANINHCLK;      // Scan chain input with respect to HCLK

// Outputs
reg   [31:0] HRDATA;          // AHB read data from APB slave
wire         HREADYOUT;       // AHB transfer completion output signal
wire  [1:0]  HRESP;           // AHB response output for APB accesses

wire  [31:0] PWDATA;          // APB write data from AHB
wire         PENABLE;         // APB Enable
wire         PSEL;            // Select signal for APB bus transfer
wire         PSELS0;          // APB select for slave 0
wire         PSELS1;          // APB select for slave 1
wire         PSELS2;          // APB select for slave 2
wire         PSELS3;          // APB select for slave 3
wire         PSELS4;          // APB select for slave 4
wire         PSELS5;          // APB select for slave 5
wire         PSELS6;          // APB select for slave 6
wire         PSELS7;          // APB select for slave 7
wire         PSELS8;          // APB select for slave 8
wire         PSELS9;          // APB select for slave 9
wire         PSELS10;         // APB select for slave 10
wire         PSELS11;         // APB select for slave 11
wire         PSELS12;         // APB select for slave 12
wire         PSELS13;         // APB select for slave 13
wire         PSELS14;         // APB select for slave 14
wire         PSELS15;         // APB select for slave 15
wire  [31:0] PADDR;           // APB address
wire         PWRITE;          // APB transfer(R/W) direction
wire         SCANOUTHCLK;     // Scan chain output with respect to HCLK


// -----------------------------------------------------------------------------
//
//                               AhbToApb
//                               ========
//
// -----------------------------------------------------------------------------
//   The 16-Slot APB Bridge provides an interface between the high-speed AHB 
// domain and the low-power APB domain. The Bridge appears as a slave on AHB, 
// whereas on APB, it is the master. Read and write transfers on the AHB are 
// converted into corresponding transfers on the APB. As the APB is not 
// pipelined, wait states are added during transfers to and from the APB when 
// the AHB is required to wait for the APB protocol.
//
// -----------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

// EASY Peripherals address decoding values:
`define S0BASE  4'b0000
`define S1BASE  4'b0001
`define S2BASE  4'b0010
`define S3BASE  4'b0011
`define S4BASE  4'b0100
`define S5BASE  4'b0101
`define S6BASE  4'b0110
`define S7BASE  4'b0111
`define S8BASE  4'b1000
`define S9BASE  4'b1001
`define S10BASE 4'b1010
`define S11BASE 4'b1011
`define S12BASE 4'b1100
`define S13BASE 4'b1101
`define S14BASE 4'b1110
`define S15BASE 4'b1111

//------------------------------------------------------------------------------
// Wire declarations
//------------------------------------------------------------------------------
wire        ValidApbTxn;
// Indication that valid AHB transfer is initiated for APB slave

wire        ClkEn4Hrdata;
// Clock enable for HRDATA F/F's

wire        En4Psel;
// Enable condition for PSEL F/F

wire        En4Hready;
// Enable condition for HREADYOUT F/F

wire        En4Penable;
// Enable condition for PENABLE F/F

wire        ApbEnableCyc;
// Enable cycle indication to complete APB transfer.

wire        En4AhbErr;
// Enable condition for AhbErr F/F

wire  [3:0] PaddrSlice;
// Selecting the portion of PADDR for demultiplexing PSEL

//------------------------------------------------------------------------------
// Register declarations
//------------------------------------------------------------------------------
reg         iPWRITE;
// Internal signal of PWRITE

reg  [31:0] iPADDR;
// Internal signal of PADDR

reg         iPENABLE;
// Internal signal of PENABLE

reg         NextPENABLE;
// D-Input of iPENABLE F/F

reg         iHREADYOUT;
// Internal signal of HREADYOUT

reg         NextHREADYOUT;
// D-Input of HREADYOUT F/F

reg         iPSEL;
// Internal signal of PSEL

reg         NextPSEL;
// D-Input of iPSEL F/F

reg  [15:0] PselEn;
// Decoder o/p to enable PSEL for 16 probable slaves

reg         AhbErr;
// Indication to drive error response on AHB

reg         NextAhbErr;
// D-Input of AhbErr F/F

//------------------------------------------------------------------------------
// Function declarations
//------------------------------------------------------------------------------
 
// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------


//------------------------------------------------------------------------------
// ValidApbTxn :
// ~~~~~~~~~~~~~
// ValidApbTxn : Valid AHB transfer for APB slaves.
// ValidApbTxn is asserted(active high) when all of the following signals
// are sampled asserted.
// HTRANS[1]   -> Implies that the transfer is sequential or non-sequential.
// HSEL        -> Implies that the transfer is intended for APB slaves.
// HREADY      -> Implies that the previous transfer on the bus is completed.
// 
//------------------------------------------------------------------------------
assign ValidApbTxn = HSEL & HREADY & HTRANS; 


//------------------------------------------------------------------------------
// ApbEnableCyc :
// ~~~~~~~~~~~~~~
// ApbEnableCyc : Enable cycle indication to complete APB transfer.
// This signal is driven to 'logic 1' for 1 HCLK cycle when PREADY and PENABLE
// is sampled asserted. 
//------------------------------------------------------------------------------
assign ApbEnableCyc = PREADY & iPENABLE;

// -----------------------------------------------------------------------------
// PWRITE :
// ~~~~~~~~
// PWRITE is a registered output.
// HWRITE is registered only when ValidApbTxn(connected to clockenable) is
// sampled asserted. 
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_PwriteSeq
  if (HRESETn == 1'b0)
    begin
      iPWRITE     <= 1'b0;
    end
  else
    begin
      if (ValidApbTxn == 1'b1)
        begin
          iPWRITE <= HWRITE;
        end
    end
end // p_PwriteSeq

// -----------------------------------------------------------------------------
// PADDR :
// ~~~~~~~
// PADDR is a registered output.
// HADDR is registered only when ValidApbTxn(connected to clockenable) is
// sampled asserted. 
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_PaddrSeq
  if (HRESETn == 1'b0)
    begin
      iPADDR     <= {32{1'b0}};
    end
  else
    begin
      if (ValidApbTxn == 1'b1)
        begin
          iPADDR <= HADDR;
        end
    end
end // p_PaddrSeq

//------------------------------------------------------------------------------
// ClkEn4Hrdata :
// ~~~~~~~~~~~~~~
// ClkEn4Hrdata: Clock enable for HRDATA.
// ClkEn4Hrdata is asserted only when the Read data transfer is in progress.
// Following condition needs to be true to ensure that the ClkEn4Hrdata is
// active for just 1 clock cycle(1 HCLK wide pulse).
// PWRITE = READ     --> Implies that read transfer is initiated on APB lines.
// ApbEnableCyc = 1  --> Implies enable phase on APB is initiated.
//------------------------------------------------------------------------------
assign ClkEn4Hrdata = (~iPWRITE) & ApbEnableCyc;


// -----------------------------------------------------------------------------
// HRDATA :
// ~~~~~~~~
// HRDATA is a registered output.
// HRDATA is registered only when ClkEn4Hrdata(connected to clockenable) is
// sampled asserted. 
// ClkEn4Hrdata is asserted only when the Read data transfer is in progress.
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_HrdataSeq
  if (HRESETn == 1'b0)
    begin
      HRDATA     <= {32{1'b0}};
    end
  else
    begin
      if (ClkEn4Hrdata == 1'b1)
        begin
          HRDATA <= PRDATA;
        end
    end
end // p_HrdataSeq


// -----------------------------------------------------------------------------
// En4Psel :
// ~~~~~~~~~
// En4Psel : Enable signal for PSEL.
// En4Psel is asserted(active high) only when there is a valid transfer
// initiated from AHB side or when the ongoing APB transfer is completed.
// This signal ensures that the o/p of the HSEL F/F is toggled
// only when this signal is sampled asserted, otherwise the previous o/p is
// sustained.
// En4Psel is asserted on two occasions for each APB transfer.
// In each occasion the signal is asserted for 1 HCLK cycle.
// Any of the Following condition will set En4Psel = 1
// (ValidApbTxn = 1) --> Implies that AHB transfer is initiated on AHB.
// ApbEnableCyc = 1  --> Implies enable phase on APB is initiated.
//
// En4Psel will be high on following occasions.
// a) When valid AHB transfer for APB is initiated, it will be high for
//    1 HCLK cycle.
// b) When APB transfer is about to complete, it will be high for 1 HCLK cycle.
// In total, it will be high for 2 HCLK clock cycles.
// -----------------------------------------------------------------------------
assign En4Psel   = ValidApbTxn | ApbEnableCyc;

// -----------------------------------------------------------------------------
// En4Hready :
// ~~~~~~~~~~~
// En4Hready : Enable signal for HREADYOUT.
// En4Hready is asserted(active high) only when there is a valid transfer
// initiated from AHB side or when the ongoing APB transfer is completed.
// This signal ensures that the o/p of the HREADOUT F/F is toggled
// only when this signal is sampled asserted, otherwise the previous o/p is
// sustained.
// En4Hready is asserted on two occasions for each APB transfer.
// In each occasion the signal is asserted for 1 HCLK cycle.
// Any of the following condition will set En4Hready = 1
// (ValidApbTxn = 1) --> Implies that AHB transfer is initiated on AHB.
// (ApbEnableCyc = 1) and (PSLVERR = 0)
//                   --> Implies enable phase on APB is initiated without any
//                       error response from APB slave.
// (HREADYOUT = 0) and (AhbErr = 1)
//                   --> Implies that ist cycle of error response is complete.
//
// En4Hready will be high on following occasions.
// a) When valid AHB transfer for APB is initiated, it will be high for
//    1 HCLK cycle.
// b) When APB transfer is about to complete, and there was no slave error
//    response. It will be high for 1 HCLK cycle.
// In total, it will be high for 2 HCLK clock cycles.
// -----------------------------------------------------------------------------
assign En4Hready = ValidApbTxn | (ApbEnableCyc & (~PSLVERR)) |
                   ((~iHREADYOUT) & AhbErr);


// -----------------------------------------------------------------------------
// This block is responsible for
// a) D-Input logic on HREADYOUT
// b) D-Input logic on PSEL
// 
// PSEL :
// ~~~~~~
// PSEL is a registered output.
// PSEL is asserted when there is a valid transaction initiated on AHB and
// de-asserted when APB transfer is complete.
// En4Psel going high for the first time will assert PSEL.
// En4Psel going high for second time will de-assert PSEL.
// When En4Psel is sampled low, the PSEL o/p is sustained.
//
// HREADYOUT :
// ~~~~~~~~~~~
// HREADYOUT is a registered output.
// HREADYOUT is de-asserted when there is a valid transaction initiated on AHB
// and asserted when APB transfer is about to complete.
// En4Hready going high for the first time will de-assert HREADYOUT.
// En4Hready going high for second time will assert HREADYOUT.
// When En4Hready is sampled low, the HREADYOUT o/p is sustained.
//
// -----------------------------------------------------------------------------
always @(ValidApbTxn)
begin : p_PselHreadyComb
  if (ValidApbTxn == 1'b1)
    begin
      NextHREADYOUT = 1'b0;
      NextPSEL      = 1'b1;
    end
  else
    begin
      NextHREADYOUT = 1'b1;
      NextPSEL      = 1'b0;
    end
end // p_PselHreadyComb


// -----------------------------------------------------------------------------
// This block is responsible for clocking PSEL.
// The reset vaue of PSEL F/F is set as 0.
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_PselSeq
  if (HRESETn == 1'b0)
    begin
      iPSEL <= 1'b0;
    end
  else
    begin
      if (En4Psel == 1'b1)
        begin
          iPSEL <= NextPSEL;
        end
    end
end // p_PselSeq

// -----------------------------------------------------------------------------
// This block is responsible for clocking HREADYOUT.
// The reset vaue of HREADYOUT F/F is set as 1.
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_HreadySeq
  if (HRESETn == 1'b0)
    begin
      iHREADYOUT <= 1'b1;
    end
  else
    begin
      if (En4Hready == 1'b1)
        begin
          iHREADYOUT <= NextHREADYOUT;
        end
    end
end // p_HreadySeq


// -----------------------------------------------------------------------------
// En4Penable :
// ~~~~~~~~~~~~
// En4Penable : Enable for PENABLE.
// En4Penable is asserted on two occasions for each APB transfer.
// In each occasion the signal is asserted for 1 HCLK cycle.
// a) During the setup phase on APB bus. i.e. When PSEL is asserted but PENABLE
//    is de-asserted.
// b) When APB transfer is about to complete. 1.e. when both PREADY and PENABLE
//    is sampled asserted.
// -----------------------------------------------------------------------------
assign En4Penable = (iPSEL & (~iPENABLE)) | ApbEnableCyc;


// -----------------------------------------------------------------------------
// This block is responsible for
// D-Input logic on PENABLE F/F
// PENABLE :
// ~~~~~~~~~
// PENABLE is a registered output.
// PENABLE is asserted after the setup phase on APB and
// de-asserted when APB transfer is complete.
// En4Penable going high for the first time will assert PENABLE.
// En4Penable going high for second time will de-assert PENABLE.
// When En4Penable is sampled low, the PENABLE o/p is sustained.
//
// -----------------------------------------------------------------------------
always @(iPSEL or iPENABLE)
begin : p_PenableComb
  if ((iPSEL & (~iPENABLE)) == 1'b1)
    begin
      NextPENABLE  = 1'b1;
    end
  else 
    begin
      NextPENABLE  = 1'b0;
    end
end // p_PenableComb


// -----------------------------------------------------------------------------
// This block is responsible for clocking PENABLE.
// The reset vaue of PENABLE F/F is set as 0.
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_PenableSeq
  if (HRESETn == 1'b0)
    begin
      iPENABLE <= 1'b0;
    end
  else
    begin
      if (En4Penable == 1'b1)
        begin
          iPENABLE <= NextPENABLE;
        end
    end
end // p_PenableSeq

//------------------------------------------------------------------------------
// Selecting the portion of PADDR for demultiplexing PSEL
//------------------------------------------------------------------------------
assign PaddrSlice = iPADDR[15:12];

//------------------------------------------------------------------------------
// Decoder on PaddrSlice lines to accomodate 16 possible APB slaves
//------------------------------------------------------------------------------
always @ (PaddrSlice)
begin : p_PaddrDecComb
  PselEn = {16{1'b0}};
  case (PaddrSlice)
    `S0BASE :  PselEn[0]  = 1'b1;

    `S1BASE :  PselEn[1]  = 1'b1;

    `S2BASE :  PselEn[2]  = 1'b1;

    `S3BASE :  PselEn[3]  = 1'b1;

    `S4BASE :  PselEn[4]  = 1'b1;

    `S5BASE :  PselEn[5]  = 1'b1;

    `S6BASE :  PselEn[6]  = 1'b1;

    `S7BASE :  PselEn[7]  = 1'b1;

    `S8BASE :  PselEn[8]  = 1'b1;

    `S9BASE :  PselEn[9]  = 1'b1;

    `S10BASE : PselEn[10] = 1'b1;

    `S11BASE : PselEn[11] = 1'b1;

    `S12BASE : PselEn[12] = 1'b1;

    `S13BASE : PselEn[13] = 1'b1;

    `S14BASE : PselEn[14] = 1'b1;

    `S15BASE : PselEn[15] = 1'b1;

    default :
      ;
  endcase
end // p_PaddrDecComb


//------------------------------------------------------------------------------
// Assigning PSEL for 16 probable APB slaves
//------------------------------------------------------------------------------
assign PSELS0  = iPSEL & PselEn[0];
assign PSELS1  = iPSEL & PselEn[1];
assign PSELS2  = iPSEL & PselEn[2];
assign PSELS3  = iPSEL & PselEn[3];
assign PSELS4  = iPSEL & PselEn[4];
assign PSELS5  = iPSEL & PselEn[5];
assign PSELS6  = iPSEL & PselEn[6];
assign PSELS7  = iPSEL & PselEn[7];
assign PSELS8  = iPSEL & PselEn[8];
assign PSELS9  = iPSEL & PselEn[9];
assign PSELS10 = iPSEL & PselEn[10];
assign PSELS11 = iPSEL & PselEn[11];
assign PSELS12 = iPSEL & PselEn[12];
assign PSELS13 = iPSEL & PselEn[13];
assign PSELS14 = iPSEL & PselEn[14];
assign PSELS15 = iPSEL & PselEn[15];


//------------------------------------------------------------------------------
// En4AhbErr :
// ~~~~~~~~~~~
// En4AhbErr : Enable condition for AhbErr F/F.
// En4AhbErr is high for 2 HCLK clock cycles in case of APB error response.
// En4AhbErr is set on following conditions,
// when APB slave respond with error response during the enable phase of APB
// transaction.
// When the second cycle of error response on AHB is about to finish.
//------------------------------------------------------------------------------
assign En4AhbErr = (ApbEnableCyc & PSLVERR) | (AhbErr & iHREADYOUT);


// -----------------------------------------------------------------------------
// This block is responsible for
// D-Input logic on AhbErr F/F
// AhbErr :
// ~~~~~~~~
// AhbErr is asserted when error on APB transfer is sampled.
// AhbErr is de-asserted when 2 cycle error response on AHB transfer is
// complete.
// En4AhbErr going high for the first time will assert AhbErr.
// En4AhbErr going high for second time will de-assert AhbErr.
//
// -----------------------------------------------------------------------------
always @(ApbEnableCyc or PSLVERR)
begin : p_AhbErrComb
  if ((ApbEnableCyc & PSLVERR) == 1'b1)
    begin
      NextAhbErr  = 1'b1;
    end
  else 
    begin
      NextAhbErr  = 1'b0;
    end
end // p_AhbErrComb

// -----------------------------------------------------------------------------
// This block is responsible for clocking AhbErr.
// The reset vaue of AhbErr F/F is set as 0.
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_AhbErrSeq
  if (HRESETn == 1'b0)
    begin
      AhbErr <= 1'b0;
    end
  else
    begin
      if (En4AhbErr == 1'b1)
        begin
          AhbErr <= NextAhbErr;
        end
    end
end // p_AhbErrSeq

//------------------------------------------------------------------------------
// HRRESP :
// ~~~~~~~~
// When PSLVERR is sampled in the enable cycle HRESP[0] is driven to logic 1
// to indicate error response on AHB. 2 cycle error response is implemented
// to satisfy AHB protocol. After which HRESP is driven as 'OKAY' response. 
//------------------------------------------------------------------------------
assign HRESP = {1'b0, AhbErr};

//------------------------------------------------------------------------------
// HWDATA input is directly driven out as PWDATA
//------------------------------------------------------------------------------
assign PWDATA = HWDATA;



// -----------------------------------------------------------------------------
// Assigning internal copies to output ports
// -----------------------------------------------------------------------------
assign HREADYOUT = iHREADYOUT;
assign PWRITE    = iPWRITE;
assign PADDR     = iPADDR;
assign PENABLE   = iPENABLE;
assign PSEL      = iPSEL;



// synopsys translate_off
// -----------------------------------------------------------------------------
// START OF PROTOCOL CHECKERS
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// END OF PROTOCOL CHECKERS
// -----------------------------------------------------------------------------
// synopsys translate_on

endmodule

// --================================= End ===================================--

