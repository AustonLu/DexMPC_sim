// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2004-2012 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 135245
//
// Date                   :  2012-08-17 10:28:31 +0100 (Fri, 17 Aug 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
//  Purpose             : APB monitor interface.
// --=========================================================================--

module apb_monitor (
    // Inputs
    PCLK,
    PCLKEN,
    PRESETn,
    PSEL,
    PENABLE,
    PREADY,
    PSLVERR,
    PADDR,
    PWRITE,
    PWDATA,
    PRDATA,
    PID,
    PSTROBE
  );

  // Module parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter ID_WIDTH = 1;
  parameter SEL_WIDTH  = 2;
  parameter LOGFILE    = "log.apb";

  parameter DW = DATA_WIDTH - 1;
  parameter MW = (DATA_WIDTH /8) - 1;
  parameter AW = ADDR_WIDTH - 1;
  parameter SW = SEL_WIDTH - 1;
  parameter IW = ID_WIDTH - 1;

  // Inputs
  input         PCLK;
  input         PCLKEN;
  input         PRESETn;

  input [SW:0]  PSEL;
  input         PENABLE;
  input         PREADY;
  input         PSLVERR;
  input         PWRITE;
  input [AW:0]  PADDR;
  input [DW:0]  PWDATA;
  input [DW:0]  PRDATA;
  input [IW:0]  PID;
  input [MW:0]  PSTROBE;


`ifdef ARM_ASSERT_ON
//------------------------------------------------------------------------------
//
//                        ApbPC Module
//                       ==============
//
//------------------------------------------------------------------------------
//
// Overview
// ========
//
// Assertions to verify the APB protocol is adhered to
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  wire [SW:0]   PSEL;
  wire          PENABLE;
  wire          PREADY;
  wire          PSLVERR;
  wire          PWRITE;
  wire  [AW:0]  PADDR;
  wire  [DW:0]  PWDATA;
  wire  [DW:0]  PRDATA;

  reg [SW:0]    PSELreg;
  reg           PENABLEreg;
  reg           PREADYreg;
  reg           PSLVERRreg;
  reg           PWRITEreg;
  reg   [AW:0]  PADDRreg;
  reg   [DW:0]  PWDATAreg;
  reg   [DW:0]  PRDATAreg;

  wire          StartTrans;
  wire          EndTrans;
  wire          InTrans;
  reg           InTransreg;
  reg           StartTransreg;
  reg           EndTransreg;

  wire          PSELall;
  reg   [DW:0]  Mask;        
  wire  [DW:0]  PWDATA_MASK;        


//------------------------------------------------------------------------------
// Main logic
//------------------------------------------------------------------------------

  // Clock and Reset Defines
  // =====
  // Can be used for clock enable, or to clock OVL on negedge (to avoid races).
  //
  // OVL: Assertion Instances
  `ifdef APB_OVL_CLK
  `else
     `define APB_OVL_CLK PCLK
  `endif
  //
  `ifdef APB_OVL_RSTn
  `else
     `define APB_OVL_RSTn PRESETn
  `endif
  //
  // AUX: Auxiliary Logic
  `ifdef APB_AUX_CLK
  `else
     `define APB_AUX_CLK PCLK
  `endif
  //
  `ifdef APB_AUX_RSTn
  `else
     `define APB_AUX_RSTn PRESETn
  `endif

//------------------------------------------------------------------------------
// Main logic
//------------------------------------------------------------------------------

  assign StartTrans = |PSEL & !PENABLE;
  assign EndTrans   = |PSEL & PENABLE & PREADY;
  assign InTrans    = InTransreg ? !EndTrans : StartTrans;

  // OR-reduce PSEL
  assign PSELall = |PSEL;

  // Create a strobed version of HWDATA
  integer i;
  always @(PSTROBE)
    begin 
       Mask = {DATA_WIDTH{1'b0}};
       for (i = 0; i <= MW; i = i+1) 
       begin
          Mask = {{8{PSTROBE[i]}}, Mask[DATA_WIDTH-1:8]};  
       end
    end
   
  assign PWDATA_MASK = PWDATA & Mask;

//--------------------------------------
// ASSERTION 1
// Check PSEL always takes a value (not X)
//--------------------------------------
  assert_never #(0,0,"PSEL signal")
    uPSELcheck (`APB_OVL_CLK, `APB_OVL_RSTn, |(PSEL ^ PSEL));

//--------------------------------------
// ASSERTION 2
// Check PENABLE always takes a value (not X)
//--------------------------------------
  assert_never #(0,0,"PENABLE signal")
    uPENABLEcheck (`APB_OVL_CLK, `APB_OVL_RSTn, (PENABLE ^ PENABLE));

//--------------------------------------
// ASSERTION 3
// Check PWRITE always takes a value (not X)
//--------------------------------------
  assert_never #(0,0,"PWRITE signal")
    uPWRITEcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & (PWRITE ^ PWRITE));

//--------------------------------------
// ASSERTION 4
// Check PADDR always takes a value (not X)
//--------------------------------------
  assert_never #(0,0,"PADDR signal")
    uPADDRcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & (|(PADDR ^ PADDR)));

//--------------------------------------
// ASSERTION 5
// Check PREADY takes a value (not X) when PENABLE is asserted
//--------------------------------------
  assert_never #(0,0,"PREADY signal")
    uPREADYcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PENABLE & (PREADY ^ PREADY));

//--------------------------------------
// ASSERTION 6
// Check PSEL doesn't go high for 2 cycles without PENABLE going high
//--------------------------------------
  assert_never #(0,0,"PSEL asserted for 2 cycles without PENABLE going high")
    uPSEL2PENABLEcheck (`APB_OVL_CLK, `APB_OVL_RSTn,
                        StartTransreg & StartTrans);

//--------------------------------------
// ASSERTION 7
// Check PENABLE goes low immediately after PREADY is asserted
//--------------------------------------
  assert_never #(0,0,"PENABLE stayed high after end of transaction")
    uPENABLEendcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PENABLE & EndTransreg);

//--------------------------------------
// ASSERTION 8
// Check PADDR is maintained during a transaction
//--------------------------------------
  assert_never #(0,0,"PADDR changed during a transaction")
    uPADDRstablecheck (`APB_OVL_CLK, `APB_OVL_RSTn,
                       InTransreg & |(PADDR ^ PADDRreg));

//--------------------------------------
// ASSERTION 9
// Check PWDATA is maintained during a write transaction
//--------------------------------------
  assert_never #(0,0,"PWDATA changed during a transaction")
    uPWDATAstablecheck (`APB_OVL_CLK, `APB_OVL_RSTn,
                        PWRITE & InTransreg & |(PWDATA_MASK ^ PWDATAreg));

//--------------------------------------
// ASSERTION 10
// Check PWRITE is maintained during a transaction
//--------------------------------------
  assert_never #(0,0,"PWRITE changed during a transaction")
    uPWRITEstablecheck (`APB_OVL_CLK, `APB_OVL_RSTn,
                        InTransreg & (PWRITE ^ PWRITEreg));

`ifdef APB_STABLE_CHECKS

//--------------------------------------
// ASSERTION 11
// Check PADDR only changes when PSEL = 1 and PENABLE = 0
//--------------------------------------
  assert_never #(2,0,"PADDR can only change at the start of a transaction")
    uPADDRstable2check (`APB_OVL_CLK, `APB_OVL_RSTn,
                        !StartTrans & !EndTransreg & |(PADDR ^ PADDRreg));

//--------------------------------------
// ASSERTION 12
// Check PWDATA only changes when PSEL = 1 and PENABLE = 0
//--------------------------------------
  assert_never #(2,0,"PWDATA can only change at the start of a transaction")
    uPWDATAstable2check (`APB_OVL_CLK, `APB_OVL_RSTn,
                         !StartTrans & |(PWDATA_MASK ^ PWDATAreg));

//--------------------------------------
// ASSERTION 13
// Check PWRITE only changes when PSEL = 1 and PENABLE = 0  or
// when PSELreg = 1 and PENABLEreg = 1
//--------------------------------------
  assert_never #(2,0,
                 "PWRITE can only change at the start or after a transaction")
    uPWRITEstable2check (APB_OVL_CLK, `APB_OVL_RSTn, !(StartTrans |
                         EndTransreg) & (PWRITE ^ PWRITEreg));

`endif

//------------------------------------------------------------------------------
// ASSERTION 14
// Check PRDATA takes a value (not X) on read cycles
//------------------------------------------------------------------------------
  assert_never #(0,0,"PRDATA valid on read cycle")
    uPRDATAcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & PENABLE &
                  !PWRITE & PREADY & |(PRDATA ^ PRDATA));

//------------------------------------------------------------------------------
// ASSERTION 15
// Check PWDATA takes a value (not X) on write cycles
//------------------------------------------------------------------------------
  assert_never #(0,0,"PWDATA valid on write cycle")
    uPWDATAcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & PENABLE & PWRITE &
                  |(PWDATA_MASK ^ PWDATA_MASK));

//--------------------------------------
// ASSERTION 16
// Check the correct PSEL is maintained during a transaction
//--------------------------------------
  assert_never #(0,0,"PSEL changed during a transaction")
    uPSELstablecheck (`APB_OVL_CLK, `APB_OVL_RSTn,
                      InTransreg & |(PSEL ^ PSELreg));

//--------------------------------------
// ASSERTION 17
// Check PSEL is always one-hot or zero
//--------------------------------------
// Note: extended PSEL by 1-bit (set to zero) to avoid warning when SEL_WIDTH=1
  assert_zero_one_hot #(0,SEL_WIDTH+1,0,"PSEL not one-hot")
    uPSELonehot (`APB_OVL_CLK, `APB_OVL_RSTn, {1'b0, PSEL});

//--------------------------------------
// ASSERTION 18
// Check bottom 2 bits of PADDR are zero
// when device is selected
//--------------------------------------

//  assert_always #(2,0,"PADDR least significant 2 bits non-zero")
//    uPADDRlsbcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PADDR[1:0] == 2'b00);

//--------------------------------------
// ASSERTION 19
// Check PSEL and PENABLE don't go together high at the start of a transaction
//--------------------------------------
  assert_never #(0,0,"PSEL and PENABLE both active at start of transaction")
    uPSELPENABLEcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & PENABLE &
                       (!(|PSELreg) | EndTransreg));

//------------------------------------------------------------------------------
// ASSERTION 20
// Check PSLVERR always takes a value (not X)
//------------------------------------------------------------------------------
  assert_never #(0,0,"PSLVERR signal")
    uPSLVERRcheck (`APB_OVL_CLK, `APB_OVL_RSTn, PSELall & PENABLE & PREADY &
                   |(PSLVERR ^ PSLVERR));


// All registers are gated by PCLKEN
always @ (posedge `APB_AUX_CLK or negedge `APB_AUX_RSTn)
  begin
    if  (!`APB_AUX_RSTn)
      begin
        PSELreg       <= {SEL_WIDTH{1'b0}};
        PENABLEreg    <= 1'b0;
        PREADYreg     <= 1'b0;
        PWRITEreg     <= 1'b0;
        PSLVERRreg    <= 1'b0;
        PWDATAreg     <= {DATA_WIDTH{1'b0}};
        PRDATAreg     <= {DATA_WIDTH{1'b0}};
        PADDRreg      <= {ADDR_WIDTH{1'b0}};
        InTransreg    <= 1'b0;
        StartTransreg <= 1'b0;
        EndTransreg   <= 1'b0;
      end
    else if (PCLKEN)
      begin
        PSELreg       <= PSEL;
        PENABLEreg    <= PENABLE;
        PREADYreg     <= PREADY;
        PWDATAreg     <= PWDATA_MASK;
        PWRITEreg     <= PWRITE;
        PRDATAreg     <= PRDATA;
        PADDRreg      <= PADDR;
        PSLVERRreg    <= PSLVERR;
        InTransreg    <= InTrans;
        StartTransreg <= StartTrans;
        EndTransreg   <= EndTrans;
      end
  end

`endif

`ifdef APBLOGGER
//------------------------------------------------------------------------------
// APB transaction logging
//------------------------------------------------------------------------------

  ApbLogger
    #(ADDR_WIDTH, DATA_WIDTH, SEL_WIDTH, LOGFILE)
  uApbLogger (
      // Inputs
      .PCLK    (`APB_AUX_CLK),
      .PCLKEN  (PCLKEN),
      .PRESETn (`APB_AUX_RSTn),
      .PREADY  (PREADY),
      .PSEL    (PSEL),
      .PENABLE (PENABLE),
      .PWRITE  (PWRITE),
      .PWDATA  (PWDATA),
      .PRDATA  (PRDATA),
      .PADDR   (PADDR)
    );

`endif

endmodule

// --================================= End ===================================--
