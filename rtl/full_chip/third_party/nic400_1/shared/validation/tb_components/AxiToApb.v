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
//  File Name          : $RCSfile: AxiToApb.v,v $
//  File Revision      : 84668
//  
//  Release Information : PL401-r1p2-00rel0
//  
//  ----------------------------------------------------------------------------
//  Purpose            : Converts AXI peripheral transfers to APB transfers
//  --========================================================================--

`timescale 1ns/1ps

//------------------------------------------------------------------------------
// AXI Standard Defines
//------------------------------------------------------------------------------
`include "Axi.v"

module AxiToApb (
// Inputs
                 // Global signals
                 ACLK,
                 ARESETn,

                 // Read Address Channel 
                 ARID,
                 ARADDR,
                 ARUSER,
                 ARLEN,
                 ARSIZE,
                 ARBURST,
                 ARVALID,
                 ARREADY,
                 ARPROT,

                 // Read Channel 
                 RID,
                 RLAST,
                 RDATA,
                 RRESP,
                 RVALID,
                 RREADY,

                 // Write Address Channel 
                 AWID,
                 AWADDR,
                 AWUSER,
                 AWLEN,
                 AWSIZE,
                 AWBURST,
                 AWVALID,
                 AWREADY,
                 AWPROT,

                 // Write Channel 
                 WLAST,
                 WDATA,
                 WVALID,
                 WREADY,

                 // Write Response Channel 
                 BID,
                 BRESP,
                 BVALID,
                 BREADY,

                 // APB3 Interface
                 PSELS,
                 PENABLE,
                 PWRITE,
                 PADDR,
                 PWDATA,
                 PREADYS,
                 PSLVERRS,
                 PRDATA,
                 PCLKENS

                );

parameter     PORTS = 16;
parameter     MAX_PORT = PORTS - 1;


// Clock and Reset in AXI domain    
input         ACLK;            // AXI Bus Clock
input         ARESETn;         // AXI system level reset active low

// Read Address Channel 
input   [7:0] ARID;            // Read address ID
input  [31:0] ARADDR;          // Read address
input   [7:0] ARUSER;          // Read USER signals
input   [3:0] ARLEN;           // Read burst length
input   [2:0] ARSIZE;          // Read burst size
input   [1:0] ARBURST;         // Read burst type
input         ARVALID;         // Read address valid
output        ARREADY;         // Read address ready
input   [2:0] ARPROT;          // Read protection information

// Read Channel 
output  [7:0] RID;             // Read data ID
output        RLAST;           // Read last
output [31:0] RDATA;           // Read data
output  [1:0] RRESP;           // Read response
output        RVALID;          // Read response valid
input         RREADY;          // Read response ready

// Write Address Channel 
input   [7:0] AWID;            // Write address ID
input  [31:0] AWADDR;          // Write address
input   [7:0] AWUSER;          // Write USER signals
input   [3:0] AWLEN;           // Write burst length
input   [2:0] AWSIZE;          // Write burst size
input   [1:0] AWBURST;         // Write burst type
input         AWVALID;         // Write address valid
output        AWREADY;         // Write address ready
input   [2:0] AWPROT;          // Write protection information

// Write Channel 
input         WLAST;           // Write last
input  [31:0] WDATA;           // Write data
input         WVALID;          // Write valid
output        WREADY;          // Write ready

// Write Response Channel 
output  [7:0] BID;             // Write response ID
output  [1:0] BRESP;           // Write response
output        BVALID;          // Write response valid
input         BREADY;          // Write response ready

// APB3 Interface
output [MAX_PORT:0] PSELS;           // APB selects for slave 0
output        PENABLE;         // APB Enable
output        PWRITE;          // APB transfer(R/W) direction
output [31:0] PADDR;           // APB address
output [31:0] PWDATA;          // APB write data
input  [MAX_PORT:0] PREADYS;         // APB transfer completion signal for slaves
input  [MAX_PORT:0] PSLVERRS;        // APB transfer response signal for slaves
input  [MAX_PORT:0] PCLKENS;        // APB transfer response signal for slaves
input  [31:0] PRDATA;          // APB read data for slave0

// -----------------------------------------------------------------------------
// Signal declarations for i/o ports
// -----------------------------------------------------------------------------

// Clock and Reset in AXI domain    
wire         ACLK;            // AXI Bus Clock
wire         ARESETn;         // AXI system level reset active low

// Read Address Channel 
wire   [7:0] ARID;            // Read address ID
wire  [31:0] ARADDR;          // Read address
wire   [3:0] ARLEN;           // Read burst length
wire   [2:0] ARSIZE;          // Read burst size
wire   [1:0] ARBURST;         // Read burst type
wire         ARVALID;         // Read address valid
wire         ARREADY;         // Read address ready
wire   [2:0] ARPROT;          // Read protection information

// Read Channel 
reg    [7:0] RID;             // Read data ID
wire         RLAST;           // Read last
wire  [31:0] RDATA;           // Read data
wire   [1:0] RRESP;           // Read response
wire         RVALID;          // Read response valid
wire         RREADY;          // Read response ready

// Write Address Channel 
wire   [7:0] AWID;            // Write address ID
wire  [31:0] AWADDR;          // Write address
wire   [3:0] AWLEN;           // Write burst length
wire   [2:0] AWSIZE;          // Write burst size
wire   [1:0] AWBURST;         // Write burst type
wire         AWVALID;         // Write address valid
wire         AWREADY;         // Write address ready
wire   [2:0] AWPROT;          // Write protection information

// Write Channel 
wire         WLAST;           // Write last
wire  [31:0] WDATA;           // Write data
wire         WVALID;          // Write valid
wire         WREADY;          // Write ready

// Write Response Channel 
reg    [7:0] BID;             // Write response ID
wire   [1:0] BRESP;           // Write response
wire         BVALID;          // Write response valid
wire         BREADY;          // Write response ready

// APB3 Interface
wire         PCLKEN;          // Clock enable for APB clock
wire         PENABLE;         // APB Enable
wire         PWRITE;          // APB transfer(R/W) direction
wire  [31:0] PADDR;           // APB address
reg   [31:0] PWDATA;          // APB write data
wire  [MAX_PORT:0] PREADYS;         // APB transfer completion signal for slave
wire  [MAX_PORT:0] PSLVERRS;        // APB transfer response signal for slave0
wire  [31:0] PRDATA;          // APB read data for slave0

wire         PREADY;          // PREADY
wire         PSLVERR;         // PSLVERR

// Tie-Offs for PSEL selection
reg  [MAX_PORT:0] PSELEN;    // Indication as to whether APB slave is hooked

// -----------------------------------------------------------------------------
//
//                               AxiToApb
//                               ========
//
// -----------------------------------------------------------------------------
//   The 16-Slot APB Bridge provides an interface between the high-speed AXI 
// domain and the low-power APB domain. The Bridge appears as a slave on AXI, 
// whereas on APB, it is the master. Read and write transfers on the AXI are 
// converted into corresponding transfers on the APB. As the APB is not 
// pipelined, wait states are added during transfers to and from the APB when 
// the AXI is required to wait for the APB protocol.
//
// -----------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

// AXI BRIDGE STATE MACHINE ENCODING 
`define    BRIDGE_AXI_IDLE               6'b000001
`define    BRIDGE_APB_TRANSFER           6'b000010
`define    BRIDGE_WAIT_RREADY            6'b000100
`define    BRIDGE_WAIT_WVALID_OR_BREADY  6'b001000
`define    BRIDGE_AXITXN_WRERR           6'b010000
`define    BRIDGE_AXITXN_RDERR           6'b100000

// APB BRIDGE STATE MACHINE ENCODING
`define    BRIDGE_APB_IDLE               3'b001
`define    BRIDGE_APB_PSEL               3'b010
`define    BRIDGE_APB_PENABLE            3'b100

//------------------------------------------------------------------------------
// Wire declarations
//------------------------------------------------------------------------------
wire  [6:0] PaddrSlice;
wire  [6:0] NxtPaddrSlice;
// Selecting the portion of PADDR for demultiplexing PSEL

wire [31:0] IncrementedAddr;
// Incremented address derived by function call

wire        iRVALID;
// Internal signal of RVALID

wire        iWREADY;
// Internal signal of WREADY

wire        iBVALID;
// Internal signal of BVALID

wire        StartApb;
// Indication to start APB transfer

wire        WlastEn;
// Enable to register WLAST signal

//------------------------------------------------------------------------------
// Register declarations
//------------------------------------------------------------------------------
reg   [5:0] BridgeAxiSt;
// Bridge state vector for AXI SM

reg   [5:0] NextBridgeAxiSt;
// D-Input of bridge state vector for AXI SM

reg   [2:0] BridgeApbSt;
// Bridge state vector for APB SM

reg   [2:0] NextBridgeApbSt;
// D-Input of bridge state vector for APB SM

reg         PSEL;
// APB slave select

reg         NextPSEL;
// D-Input of PSEL

wire        AxiTxnRdErr;
// Indication that AXI control signal(ARPROT[1]) is incorrect during read

wire        AxiTxnWrErr;
// Indication that AXI control signal(AWPROT[1]) is incorrect during write

reg         LdAxiWrData;
// Indication to register AXI write data

reg         WlastReg;
// Holding register to hold WLAST signal during AXI write

reg   [3:0] BeatCnt;
// Counter for number of beats in a AXI read burst

reg   [3:0] NextBeatCnt;
// D-Input of BeatCnt F/F

reg   [3:0] AxiLen;
// Holding register to hold AXI transfer length

reg   [3:0] NextAxiLen;
// D-Input of AxiLen F/F

reg   [2:0] AxiSize;
// Holding register to hold AXI transfer size

reg   [2:0] NextAxiSize;
// D-Input of AxiSize F/F

reg   [1:0] BrstType;
// Holding register to hold AXI burst type

reg   [1:0] NextBrstType;
// D-Input of BrstType F/F

reg         AxiWrErr;
// Holding register for PSLVERR(APB slave device) during APB write

reg         NextAxiWrErr;
// D-Input of AxiWrErr F/F

reg         iPWRITE;
// Internal signal of PWRITE

reg         NextPWRITE;
// D-Input of iPWRITE F/F

reg  [31:0] iPADDR;
// Internal signal of PADDR

reg  [31:0] NextPADDR;
// D-Input of iPADDR F/F

reg  [31:0] iAUSER;
// Internal signal of AUSER

reg  [31:0] NextAUSER;
// D-Input of iAUSER F/F

reg         iPENABLE;
// Internal signal of PENABLE

reg         NextPENABLE;
// D-Input of iPENABLE F/F

reg         iARREADY;
// Internal signal of ARREADY

reg         NextARREADY;
// D-Input of iARREADY F/F

reg         iRLAST;
// Internal signal of RLAST

reg         NextRLAST;
// D-Input of iRLAST F/F

reg   [1:0] iRRESP;
// Internal signal of RRESP

reg   [1:0] NextRRESP;
// D-Input of iRRESP F/F

reg         RvalidAxi;
// RVALID generation from Bridge AXI SM

reg         NextRvalidAxi;
// D-Input of RvalidAxi F/F

reg         iAWREADY;
// Internal signal of AWREADY

reg         NextAWREADY;
// D-Input of iAWREADY F/F

reg         WreadyAxi;
// WREADY generation from Bridge AXI SM

reg         NextWreadyAxi;
// D-Input of WreadyAxi F/F

reg   [1:0] iBRESP;
// Internal signal of BRESP

reg   [1:0] NextBRESP;
// D-Input of iBRESP F/F

reg         BvalidAxi;
// BVALID generation from Bridge AXI SM

reg         NextBvalidAxi;
// D-Input of BvalidAxi F/F

reg  [MAX_PORT:0] PselDec;
reg  [MAX_PORT:0] NxtPselDec;
// Decoder o/p to enable PSEL for 16 probable slaves

reg         ApbComplete;
// Indication that APB transfer is complete

reg         NextApbComplete;
// D-Input of ApbComplete F/F

reg  [31:0] iRDATA;
// Internal signal of RDATA

reg  [31:0] NextRDATA;
// D-Input of iRDATA

reg         StartApbFromAxi;
// Indication to start APB transfer from AXI SM

reg         HoldStApbTxr;
// Signal to hold StartApbFromAxi till APB SM samples it

reg         NextHoldStApbTxr;
// D-Input of HoldStApbTxr F/F

reg   [6:0] PortSelect;
// Second level registering of PADDR[15:12] bus for multiplexing APB input

//------------------------------------------------------------------------------
// Function declarations
//------------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// This block registers Read address channel ID information.
// The AXI ARID input is registered when the bridge SM enters the
// APB set up phase. ARID is registered and driven out as RID. RID information
// driven on the bus becomes valid only when RVALID is asserted, but RID is
// driven well in advance before RVALID is asserted.
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_RdIdRegSeq
  if (ARESETn == 1'b0)
    begin
      RID     <= {8{1'b0}};
    end
  else
    begin
      if (iARREADY == 1'b1)
        begin
          RID <= ARID;
        end
    end
end // p_RdIdRegSeq

// -----------------------------------------------------------------------------
// This block registers Write address channel ID information.
// The AXI AWID input is registered when the bridge AXI SM enters the
// APB set up phase. AWID is registered and driven out as BID. BID information
// driven on the bus becomes valid only when BVALID is asserted, but BID is
// driven well in advance before BVALID is asserted.
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_WrIdRegSeq
  if (ARESETn == 1'b0)
    begin
      BID     <= {8{1'b0}};
    end
  else
    begin
      if (iAWREADY == 1'b1)
        begin
          BID <= AWID;
        end
    end
end // p_WrIdRegSeq

// -----------------------------------------------------------------------------
// This block registers AXI Write data on to PWDATA.
// AXI write data is registered whenever bridge AXI SM is entering the APB setup
// state to drive APB control signals(PSEL).
// When there is an erroneous AXI transaction also, WDATA gets registered onto
// PWDATA lines. This happens because of synthesis limitation. But the
// consequence is PWDATA line changes once for every erroneous AXI transfer.
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_AxiWrDataRegSeq
  if (ARESETn == 1'b0)
    begin
      PWDATA     <= {32{1'b0}};
    end
  else
    begin
      if (LdAxiWrData == 1'b1)
        begin
          PWDATA <= WDATA;
        end
    end
end // p_AxiWrDataRegSeq


// -----------------------------------------------------------------------------
// WlastEn is asserted when WDATA is accepted.
// i.e. when WVALID and iWREADY is sampled high
// -----------------------------------------------------------------------------
assign WlastEn = WVALID & iWREADY;


// -----------------------------------------------------------------------------
// WLAST is registered whenever valid data phase starts.
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_WlastRegSeq
  if (ARESETn == 1'b0)
    begin
      WlastReg     <= 1'b0;
    end
  else
    begin
      if (WlastEn == 1'b1)
        begin
          WlastReg <= WLAST;
        end
    end
end // p_WlastRegSeq

// ----------------------------------------------------------------
// Instantiation of Combinatorial address incrementer
// Inputs passed to the instance are 
// iPADDR       --> Current address which needs to be incremented for next
//                  transfer.
// AxiLen       --> Length of AXI transfer, which was registered in the APB set
//                  up phase. This information is required for WRAP transfers.
// AxiSize      --> AXI transfer width, which was registered in the APB set up
//                  phase. Values can be 8/16/32 bit.
// BrstType     --> AXI burst information, which was registered in the APB set
//                  up phase. Values can be FIXED/INCR/WRAP transfers.
// -----------------------------------------------------------------------------
AxiToApbAGen uAxiAddrGen
  (
   .AddrIn         (iPADDR[11:0]),
   .ALEN           (AxiLen),
   .ASIZE          (AxiSize),
   .ABURST         (BrstType),

   .AddrOut        (IncrementedAddr[11:0])
  );

// -----------------------------------------------------------------------------
// Upper address bits are unchanged
// -----------------------------------------------------------------------------
assign IncrementedAddr[31:12] = iPADDR[31:12];

// -----------------------------------------------------------------------------
//  B  R  I  D  G  E      A  X  I      S  T  A  T  E      M  A  C  H  I  N  E
// -----------------------------------------------------------------------------
// This is the main block which controls the generation of AXI and few
// APB signals.
//
// Summary State Description:
// ==========================
//
// BRIDGE_AXI_IDLE : Bridge IDLE State.
// Description     : Default state when AXI transfer for APB is not triggered.
// Entry           : a) On system reset
//                   b) On completion of the beats of transfer(as requested by
//                      AXI) for either READ/WRITE transfers. 
// Exit            : AXI transfer for APB is sampled asserted.
// No change       : When AXI transfer for APB is not sampled asserted.
//
//
//                 =================================
//
// BRIDGE_APB_TRANSFER : APB set up phase state.
// Description         : Bridge state, where PSEL is driven and AXI control
//                       information is registered if the SM is transitioning
//                       from BRIDGE_AXI_IDLE state.
// Entry               : a) From BRIDGE_AXI_IDLE state when valid AXI transfer
//                          for APB is sampled asserted.
//                       b) On completion of a beat of transfer(as requested by
//                          AXI) for either READ/WRITE transfers and still more
//                          needs to be done. Transitioning from
//                          BRIDGE_WAIT_RREADY and
//                          BRIDGE_WAIT_WVALID_OR_BREADY state.
// Exit                : When PREADY and PENABLE is sampled asserted
// No change           : -NA-
//
//
//                 =================================
//
// BRIDGE_WAIT_RREADY : Wait for RREADY state.
// Description        : Bridge SM enters this state at end of APB read cycle.
//                      In this state RVALID and relevant RRESP is driven and
//                      bridge SM is waiting for RREADY from the master to be
//                      asserted(indicating that RDATA is accepted).
// Entry              : From BRIDGE_APB_TRANSFER state after completion of APB
//                      enable cycle for read(not considering PCLKEN).
// Exit               : When RREADY is sampled asserted.
// No change          : When RREADY is sampled de-asserted.
//
//
//                 =================================
//
// BRIDGE_AXITXN_RDERR : Error transaction for Read from AXI Master.
// Description         : This state indicates that 
//                       a) AXI master tried to read trust zone protected APB
//                          slave with wrong protection information 
//                       b) AXI master tried to read APB slave slot which does
//                          not exist.
//                       In this state APB control signals PSEL and PENABLE is
//                       not asserted. In this state SM asserts RVALID/RLAST
//                       and RRESP as DECERR. RLAST is asserted for the last
//                       beat of the burst.
//                       RDATA values are don't care.
// Entry               : From BRIDGE_AXI_IDLE state when erroneous AXI read
//                       transfer is initiated by AXI master.
// Exit                : When RREADY is sampled asserted.
// No change           : When RREADY is sampled de-asserted.
//
//
//                 =================================
//
// BRIDGE_WAIT_WVALID_OR_BREADY
//                    : Wait for WVALID or BREADY state.
// Description        : Bridge SM enters this state at end of APB write cycle.
//                      In this state BVALID/BRESP is asserted if WLAST is
//                      sampled from master or else Bridge SM waits till WVALID
//                      is sampled asserted. 
//                      In case where end of transfer is reached Buffered
//                      channel transactions is triggered and Bridge SM waits
//                      for BREADY(indicating that master has accepted the
//                      buffered response) to be sampled asserted.
//                      In cases where more transfers are pending Bridge SM
//                      waits for WVALID to be asserted for new data.
// Entry              : From BRIDGE_APB_TRANSFER state after completion of APB
//                      enable cycle for write(not considering PCLKEN).
// Exit               : When BREADY is sampled asserted in case of last transfer
//                      or WVALID if further transfer is pending.
// No change          : When BREADY is sampled de-asserted in case of end of
//                      transfer or WVALID is sampled de-asserted.
//
//
//                 =================================
//
//
// BRIDGE_AXITXN_WRERR : Error transaction for Write from AXI Master.
// Description         : This state indicates that 
//                       a) AXI master tried to write trust zone protected APB
//                          slave with wrong protection information 
//                       b) AXI master tried to write APB slave slot which does
//                          not exist.
//                       In this state APB control signals PSEL and PENABLE is
//                       not asserted.
//                       In this state BVALID/BRESP(DECERR) is asserted if WLAST
//                       is sampled from master or else Bridge SM waits till
//                       WVALID is sampled asserted. 
//                       In case where end of transfer is reached Buffered
//                       channel transactions is triggered and Bridge SM waits
//                       for BREADY(indicating that master has accepted the
//                       buffered response) to be sampled asserted.
//                       In cases where more transfers are pending Bridge SM
//                       waits for WVALID to be asserted for new data.
// Entry               : From BRIDGE_AXI_IDLE state when erroneous AXI write 
//                       transfer is initiated by AXI master.
// Exit                : When BREADY is sampled asserted in case of last
//                       transfer or WVALID if further transfer is pending.
// No change           : When BREADY is sampled de-asserted in case of end of
//                       transfer or WVALID is sampled de-asserted.
//
//
// 
// -----------------------------------------------------------------------------
always @(BridgeAxiSt or iPENABLE or iPADDR or iPWRITE or iRVALID or iBVALID or
         BeatCnt or AWADDR or AWVALID or WVALID or BREADY or ARADDR or ARLEN or
         ARVALID or RREADY or PREADY or IncrementedAddr or AxiTxnRdErr or
         AxiTxnWrErr or ApbComplete or AWUSER or ARUSER)
begin : p_BridgeAxiSMComb
  NextBridgeAxiSt = BridgeAxiSt;          // Default value

  NextPADDR       = iPADDR;               // Default value

  NextAUSER       = iAUSER;               // Default value

  NextBeatCnt     = BeatCnt;              // Default value

  StartApbFromAxi = 1'b0;                 // Default value

  case (BridgeAxiSt)
    `BRIDGE_AXI_IDLE :
      begin
        // To implement round robin logic, PWRITE signal is used which has the
        // information of last accesses on APB.
        // On reset PWRITE is zero, hence WRITE is given priority over READ
        // for the first access after reset.
        // If previous access was a write then give priority to read...
        if ((ARVALID & iPWRITE) == 1'b1)
          begin
            // PADDR is in the critical path, hence ARADDR and AWADDR cannot be
            // registered after quering error condition.
            // PADDR is registered whenever there is an AXI trigger for APB
            // device. Consequence of this, is during error condition PADDR
            // bus will change once. Which is acceptable compared to amount of
            // erroneous transfer bandwidth.
            NextPADDR    = ARADDR;
            NextAUSER    = ARUSER;
            NextBeatCnt  = ARLEN;

            if (AxiTxnRdErr == 1'b1)
              begin
                NextBridgeAxiSt = `BRIDGE_AXITXN_RDERR;
              end
            else
              begin
                NextBridgeAxiSt = `BRIDGE_APB_TRANSFER;

                // Start the APB state machine
                StartApbFromAxi = 1'b1;
              end
          end

        // ...else give priority to write...
        else if ((AWVALID & WVALID) == 1'b1)
          begin
            // PADDR is in the critical path, hence ARADDR and AWADDR cannot be
            // registered after quering error condition.
            // PADDR is registered whenever there is an AXI trigger for APB
            // device. Consequence of this, is during error condition PADDR
            // bus will change once. Which is acceptable compared to amount of
            // erroneous transfer bandwidth.
            // Similar is the case for registering PWDATA from WDATA.
            NextPADDR    = AWADDR;
            NextAUSER    = AWUSER;

            if (AxiTxnWrErr == 1'b1)
              begin
                NextBridgeAxiSt = `BRIDGE_AXITXN_WRERR;
              end
            else
              begin
                NextBridgeAxiSt = `BRIDGE_APB_TRANSFER;

                // Start the APB state machine
                StartApbFromAxi = 1'b1;
              end
          end

        // ...else service read
        else if (ARVALID == 1'b1)
          begin
            // PADDR is in the critical path, hence ARADDR and AWADDR cannot be
            // registered after quering error condition.
            // PADDR is registered whenever there is an AXI trigger for APB
            // device. Consequence of this, is during error condition PADDR
            // bus will change once. Which is acceptable compared to amount of
            // erroneous transfer bandwidth.
            NextPADDR    = ARADDR;
            NextAUSER    = ARUSER;
            NextBeatCnt  = ARLEN;

            if (AxiTxnRdErr == 1'b1)
              begin
                NextBridgeAxiSt = `BRIDGE_AXITXN_RDERR;
              end
            else
              begin
                NextBridgeAxiSt = `BRIDGE_APB_TRANSFER;

                // Start the APB state machine
                StartApbFromAxi = 1'b1;
              end
          end

      end

    `BRIDGE_APB_TRANSFER :
      begin
        if ((PREADY & iPENABLE) == 1'b1)  // end of enable cycle(PCLKEN is not
          begin                           // considered)
            if (iPWRITE == 1'b1) 
              begin
                NextBridgeAxiSt = `BRIDGE_WAIT_WVALID_OR_BREADY;
              end
            else
              begin
                NextBridgeAxiSt = `BRIDGE_WAIT_RREADY;
              end
          end
      end

    `BRIDGE_WAIT_RREADY :
      begin
        if (ApbComplete == 1'b1)
          begin
            if (RREADY == 1'b1) // Master has accepted RDATA
              begin
                // If last beat of transfer is completed make a state transition
                // to BRIDGE_AXI_IDLE state or else continue to do further APB
                // read transfers.
                if ((|BeatCnt) == 1'b0)
                  begin
                    NextBridgeAxiSt = `BRIDGE_AXI_IDLE;
                  end
                else
                  begin
                    NextBridgeAxiSt = `BRIDGE_APB_TRANSFER;
                    StartApbFromAxi = 1'b1;
                    NextPADDR       = IncrementedAddr;
                    NextBeatCnt     = BeatCnt - 4'h1;
                  end
              end
          end
      end

    `BRIDGE_AXITXN_RDERR :
      begin
        if ((iRVALID & RREADY) == 1'b1) // Master has accepted the transfer
          begin
            // If last beat of transfer is completed make a state transition to
            // BRIDGE_AXI_IDLE state or else continue to assert RVALID for
            // remaining transfers.
            if ((|BeatCnt) == 1'b0)
              begin
                NextBridgeAxiSt = `BRIDGE_AXI_IDLE;
              end
            else
              begin
                NextBeatCnt     = BeatCnt - 4'h1;
              end
          end
      end

    `BRIDGE_WAIT_WVALID_OR_BREADY :
      begin
        if (ApbComplete == 1'b1)
          begin
            if (iBVALID == 1'b1) // Buffered channel transfer has been triggered
              begin
                if (BREADY == 1'b1) // Master has accepted the buffered response
                  begin
                    NextBridgeAxiSt = `BRIDGE_AXI_IDLE;
                  end
              end
            else if (WVALID == 1'b1) // More AXI WDATA for APB device
              begin
                NextBridgeAxiSt     = `BRIDGE_APB_TRANSFER;
                StartApbFromAxi     = 1'b1;
                NextPADDR           = IncrementedAddr;
              end
          end
      end

    `BRIDGE_AXITXN_WRERR :
      begin
        // Master has accepted the buffered response
        if ((iBVALID & BREADY) == 1'b1)
          begin
            NextBridgeAxiSt = `BRIDGE_AXI_IDLE;
          end
      end

    default :
      ;
  endcase
end // p_BridgeAxiSMComb

// -----------------------------------------------------------------------------
// Generation of AWREADY and ARREADY:
// AWREADY or ARREADY is asserted when Bridge AXI SM is in BRIDGE_AXI_IDLE
// state and a AXI write or AXI read transfer is triggered respectively.
// There is a round - robin logic in BRIDGE_AXI_IDLE state to decide on
// Read or Write transfer.
// -----------------------------------------------------------------------------
always @ (BridgeAxiSt or ARVALID or iPWRITE or AWVALID or WVALID)
begin : p_AddrReadyComb
  NextARREADY = 1'b0;      // Default value
  NextAWREADY = 1'b0;      // Default value
  if (BridgeAxiSt == `BRIDGE_AXI_IDLE)
    begin
      // If previous access was a write then give priority to read...
      if ((ARVALID & iPWRITE) == 1'b1)
        begin
          // Accept the address for read address channel
          NextARREADY = 1'b1;
        end

      // ...else give priority to write...
      else if ((AWVALID & WVALID) == 1'b1)
        begin
          // Accept the address for write address channel
          NextAWREADY = 1'b1;
        end

      // ...else service read
      else if (ARVALID == 1'b1)
        begin
          // Accept the address for read address channel
          NextARREADY = 1'b1;
        end
    end
end // p_AddrReadyComb

// -----------------------------------------------------------------------------
// Generation of PWRITE:
// PWRITE is driven when Bridge AXI SM is in BRIDGE_AXI_IDLE state.
// There is a round - robin logic in BRIDGE_AXI_IDLE state to decide on
// Read or Write transfer.
// -----------------------------------------------------------------------------
always @ (BridgeAxiSt or ARVALID or iPWRITE or AWVALID or WVALID)
begin : p_PwriteComb
  NextPWRITE = iPWRITE;      // Default value
  if (BridgeAxiSt == `BRIDGE_AXI_IDLE)
    begin
      // If previous access was a write then give priority to read...
      if ((ARVALID & iPWRITE) == 1'b1)
        begin
          NextPWRITE = 1'b0;
        end

      // ...else give priority to write...
      else if ((AWVALID & WVALID) == 1'b1)
        begin
          NextPWRITE = 1'b1;
        end

      // ...else service read
      else if (ARVALID == 1'b1)
        begin
          NextPWRITE = 1'b0;
        end
    end
end // p_PwriteComb

// -----------------------------------------------------------------------------
// Registering of AXI control signals.
// Register AXI read address bus control information if the
// initiated APB transfer is Read or else register AXI write address
// bus control information.
// These information needs to be registered after accepting the AXI address bus.
// -----------------------------------------------------------------------------
always @(AxiSize or AxiLen or BrstType or iAWREADY or AWSIZE or AWLEN or
         AWBURST or ARSIZE or ARLEN or ARBURST or iARREADY)
begin : p_AxiCtrlRegComb
  NextAxiSize  = AxiSize;
  NextAxiLen   = AxiLen;
  NextBrstType = BrstType;
  if (iAWREADY == 1'b1)
    begin
      NextAxiSize  = AWSIZE;
      NextAxiLen   = AWLEN;
      NextBrstType = AWBURST;
    end
  else if (iARREADY == 1'b1)
    begin
      NextAxiSize  = ARSIZE;
      NextAxiLen   = ARLEN;
      NextBrstType = ARBURST;
    end
end // p_AxiCtrlRegComb

// -----------------------------------------------------------------------------
// Generation of Read data channel hand shake signals.
// RvalidAxi :
// This signal is equivalent to RVALID if PCLKEN was sampled high when this
// signal is asserted. RvalidAxi is asserted after the completion of APB
// transfer without considering PCLKEN.
// When the transfer is erroneous from AXI side then, APB transfer is not
// performed. In this case RvalidAxi is asserted for the complete burst of
// transfer.
// RRESP :
// RRESP follows PSLVERR in case of normal APB transfer, or else it is set to
// DECERR when the AXI transfer is erroneous.
// RLAST :
// RLAST is asserted on the last beat of the read burst. For this BeatCnt
// counter value is utilized to generate RLAST.
// -----------------------------------------------------------------------------
always @(iRLAST or iRRESP or RvalidAxi or BridgeAxiSt or PREADY or iPENABLE or
         iPWRITE or BeatCnt or PSLVERR or ApbComplete or RREADY or iRVALID or
         RREADY)
begin : p_RdChGenComb
  NextRLAST       = iRLAST;               // Default value
  NextRRESP       = iRRESP;               // Default value
  NextRvalidAxi   = RvalidAxi;            // Default value

  case (BridgeAxiSt)
    `BRIDGE_APB_TRANSFER :
      begin
        // end of enable cycle(PCLKEN is not considered)
        if ((PREADY & iPENABLE & (~iPWRITE)) == 1'b1)
          begin
            // Drive RVALID/RRESP. RLAST is driven if last beat of transfer
            // is reached.
            NextRvalidAxi   = 1'b1;
            NextRLAST       = ~(|BeatCnt);
            NextRRESP       = {PSLVERR, 1'b0};
          end
      end

    `BRIDGE_WAIT_RREADY :
      begin
        if (ApbComplete == 1'b1)
          begin
            if (RREADY == 1'b1) // Master has accepted RDATA
              begin
                // De-assert AXI read data channel control information
                NextRvalidAxi   = 1'b0;
                NextRLAST       = 1'b0;
                NextRRESP       = `AXI_RESP_OKAY;
              end
          end
        else
          begin
            // Capture APB response to drive on RRESP
            NextRRESP    = {PSLVERR, 1'b0};
          end
      end

    `BRIDGE_AXITXN_RDERR :
      begin
        // It was an erroneous AXI transfer hence assert RVALID without
        // performing APB transfers.
        NextRvalidAxi   = 1'b1;

        // Assert RLAST for the last beat of the transfer
        NextRLAST       = ~(|BeatCnt);

        // Drive RRESP as DECERR as it was a erroneous transfer
        NextRRESP       = `AXI_RESP_DECERR;

        if ((iRVALID & RREADY) == 1'b1) // Master has accepted the transfer
          begin
            // If last beat of transfer is completed de-assert RVALID/RLAST
            // signals or else continue to assert RVALID for
            // remaining transfers.
            if ((|BeatCnt) == 1'b0)
              begin
                NextRvalidAxi   = 1'b0;
                NextRLAST       = 1'b0;
                NextRRESP       = `AXI_RESP_OKAY;
              end
            else
              begin
                NextRLAST       = ~(|BeatCnt[3:1]);
              end
          end
      end

    default :
      ;
  endcase
end // p_RdChGenComb

// -----------------------------------------------------------------------------
// Generation of Buffered channel hand shake signals.
// BvalidAxi :
// This signal is equivalent to BVALID if PCLKEN was sampled high when this
// signal is asserted. BvalidAxi is asserted after the completion of APB
// transfer (without considering PCLKEN) for last beat of write transfer.
//
// BRESP :
// When there is an error on any beat of the transfer then the buffered
// response is set to SLVERR.
// When there is an erroneous AXI transfer then buffered response is set to
// DECERR.
//
// -----------------------------------------------------------------------------
always @(BridgeAxiSt or iBRESP or BvalidAxi or AxiWrErr or PREADY or
         iPENABLE or iPWRITE or WlastReg or PSLVERR or ApbComplete or
         iBVALID or BREADY or WVALID or WLAST)
begin : p_BufChGenComb
  NextBRESP       = iBRESP;               // Default value
  NextBvalidAxi   = BvalidAxi;            // Default value
  NextAxiWrErr    = AxiWrErr;             // Default value

  case (BridgeAxiSt)
    `BRIDGE_APB_TRANSFER :
      begin
        // End of enable cycle(PCLKEN is not considered)
        if ((PREADY & iPENABLE & iPWRITE) == 1'b1)
          begin
            // If WLAST is sampled then drive BVALID/BRESP.
            NextBvalidAxi   = WlastReg;
            NextBRESP       = {(AxiWrErr | PSLVERR), 1'b0};
          end
      end

    `BRIDGE_WAIT_WVALID_OR_BREADY :
      begin
        if (ApbComplete == 1'b1)
          begin
            // Capture APB response till the last beat of the transfer is
            // initiated. This is used as a flag to drive BRESP as SLVERR if
            // any single beat of the AXI transfer to APB device is errored.
            if (WlastReg == 1'b0)
              begin
                NextAxiWrErr = iBRESP[1] | AxiWrErr;
              end
            else
              begin
                NextAxiWrErr = 1'b0;
              end

            // Master has accepted the buffered response
            if ((iBVALID & BREADY) == 1'b1)
              begin
                NextBvalidAxi   = 1'b0;
                NextBRESP       = `AXI_RESP_OKAY;
              end
          end
        else
          begin
            // Capture APB response to drive on BRESP
            NextBRESP    = {(AxiWrErr | PSLVERR), 1'b0};
          end
      end

    `BRIDGE_AXITXN_WRERR :
      begin
        if (iBVALID == 1'b1) // Buffered channel transfer has been triggered
          begin
            if (BREADY == 1'b1) // Master has accepted the buffered response
              begin
                NextBvalidAxi   = 1'b0;
                NextBRESP       = `AXI_RESP_OKAY;
              end
          end
        else if (WVALID == 1'b1)
          begin
            // Start buffered response channel transaction when WLAST is
            // sampled asserted.
            NextBvalidAxi   = WLAST;

            // Drive BRESP as DECERR since it was a erroneous transfer.
            NextBRESP       = `AXI_RESP_DECERR;
          end
      end

    default :
      ;
  endcase
end // p_BufChGenComb

// -----------------------------------------------------------------------------
// LdAxiWrData :
// WDATA is registerd onto PWDATA when LdAxiWrData is asserted.
// LdAxiWrData is asserted whenever AXI write transfer is triggered.
// After the round robin algorithm if AXI write is selected then LdAxiWrData
// is asserted for 1 ACLK.
// The condition when LdAxiWrData is asserted is
// a) At the beginning of the write transfer(after round robin algorithm
//    selects write to be performed)
// b) When all of the following condition is satisfied at the end of APB
//    transfer
//    ApbComplete  = 1 --> Implies end of APB transfer
//    WVALID = 1       --> Implies new write data for current ongoing write
//                         burst is available
//    iBVALID = 0      --> Last beat of the transfer is not asserted.
// -----------------------------------------------------------------------------
always @(BridgeAxiSt or ARVALID or iPWRITE or AWVALID or WVALID or
         ApbComplete or iBVALID)
begin : p_LdWrDataComb
  LdAxiWrData    = 1'b0;             // Default value

  case (BridgeAxiSt)
    `BRIDGE_AXI_IDLE :
      begin
        if (((ARVALID & iPWRITE) == 1'b0) &&
            ((AWVALID & WVALID) == 1'b1))
          begin
            // Register AXI write data
            LdAxiWrData = 1'b1;
          end
      end

    `BRIDGE_WAIT_WVALID_OR_BREADY :
      begin
        if ((ApbComplete & WVALID & (~iBVALID)) == 1'b1)
          begin
            // Register AXI write data
            LdAxiWrData = 1'b1;
          end
      end

    default :
      ;
  endcase
end // p_LdWrDataComb

// -----------------------------------------------------------------------------
// WreadyAxi :
// WreadyAxi is asserted along with AWREADY at the beginning of the transfer.
// For subsequent bursts WreadyAxi is asserted at the end of APB transfer.
// WreadyAxi is low by default for the first transfer but for subsequent
// transfers it is high.
// -----------------------------------------------------------------------------
always @(BridgeAxiSt or ARVALID or iPWRITE or AWVALID or WVALID or WreadyAxi or
         PREADY or iPENABLE or WlastReg or iBVALID or ApbComplete or WLAST) 
begin : p_WreadyComb
  NextWreadyAxi   = WreadyAxi;            // Default value

  case (BridgeAxiSt)
    `BRIDGE_AXI_IDLE :
      begin
        if (((ARVALID & iPWRITE) == 1'b0) &&
            ((AWVALID & WVALID) == 1'b1))
          begin
            // Accept AXI write data
            NextWreadyAxi = 1'b1;
          end
      end

    `BRIDGE_APB_TRANSFER :
      begin
        // End of enable cycle(PCLKEN is not considered)
        if ((PREADY & iPENABLE & iPWRITE) == 1'b1)
          begin
            NextWreadyAxi   = ~WlastReg;
          end
        else
          begin
            NextWreadyAxi = 1'b0;
          end
      end

    `BRIDGE_WAIT_WVALID_OR_BREADY :
      begin
        if (ApbComplete == 1'b1)
          begin
            // More AXI WDATA for current write burst to APB device.
            // WreadyAxi is de-asserted as it was pipelined.
            if (((~iBVALID) & WVALID) == 1'b1)
              begin
                NextWreadyAxi = 1'b0;
              end
          end
      end

    `BRIDGE_AXITXN_WRERR :
      begin
        // More AXI WDATA for current write burst.
        // WreadyAxi is de-asserted as it was pipelined.
        if (((~iBVALID) & WVALID & WLAST) == 1'b1)
          begin
            NextWreadyAxi = 1'b0;
          end
      end

    default :
      ;
  endcase
end // p_WreadyComb


// -----------------------------------------------------------------------------
// Synchronising StartApbFromAxi to PCLKEN
// -----------------------------------------------------------------------------
always @ (HoldStApbTxr or StartApbFromAxi or PSEL)
begin : p_SyncStartApbComb
  NextHoldStApbTxr = HoldStApbTxr;  // Default value
  if (StartApbFromAxi == 1'b1)
    begin
      NextHoldStApbTxr = 1'b1;
    end
  else if (PSEL == 1'b1)
    begin
      NextHoldStApbTxr = 1'b0;
    end
end // p_SyncStartApbComb

// -----------------------------------------------------------------------------
// StartApb is the OR'ed version of similar signal generated in AXI domain and
// the one generated till PCLKEN is sampled.
// -----------------------------------------------------------------------------
assign StartApb = StartApbFromAxi | HoldStApbTxr;


// -----------------------------------------------------------------------------
//  B  R  I  D  G  E      A  P  B      S  T  A  T  E      M  A  C  H  I  N  E
// -----------------------------------------------------------------------------
// This is the main block which controls the generation of APB control
// signals. This state machine is clocked by PCLCKEN.
//
// Summary State Description:
// ==========================
// BRIDGE_APB_IDLE : Idle state.
// Description     : This is the state where valid AXI transfer to APB trigger
//                   signal(StartApb) is polled continuously.
//                   When StartApb is sampled asserted APB cycle is triggered.
// Entry           : a) On system reset
//                   b) On completion of APB cycle.
// Exit            : When StartApb and PCLKEN is sampled asserted.
// No change       : When StartApb and PCLKEN is sampled de-asserted.
//
//
//                 =================================
//
// BRIDGE_APB_PSEL : APB set up phase state.
// Description     : Bridge state, where PSEL is driven.
// Entry           : From BRIDGE_APB_IDLE state.
// Exit            : Next clock cycle if PCLKEN is sampled asserted.
// No change       : When PCLKEN is sampled de-asserted.
//
//
//                 =================================
//
// BRIDGE_APB_ENABLE : APB enable phase state.
// Description       : Bridge State where PENABLE is asserted. In this state
//                     SM samples PREADY and PCLKEN signal to end the APB cycle.
// Entry             : From BRIDGE_APB_PSEL state.
// Exit              : At the end of enable phase, i.e. PREADY and PCLKEN is
//                     sampled asserted.
// No change         : When PREADY and PCLKEN is sampled de-asserted.
//
//
//------------------------------------------------------------------------------
always @ (BridgeApbSt or PSEL or iPENABLE or iRDATA or StartApb or PREADY or
          iPWRITE or PRDATA)
begin : p_BridgeApbSMComb
  NextBridgeApbSt = BridgeApbSt;      // Default value
  NextPSEL        = PSEL;             // Default value
  NextPENABLE     = iPENABLE;         // Default value
  NextApbComplete = 1'b1;             // Default value
  NextRDATA       = iRDATA;           // Default value

  case (BridgeApbSt)
    `BRIDGE_APB_IDLE :
      begin
        if (StartApb == 1'b1)
          begin
            NextBridgeApbSt = `BRIDGE_APB_PSEL;

            // Drive APB control signal --> PSEL
            NextPSEL        = 1'b1;
          end
      end

    `BRIDGE_APB_PSEL :
      begin
        NextBridgeApbSt = `BRIDGE_APB_PENABLE;

        // Drive APB control signal --> PENABLE
        NextPENABLE     = 1'b1;

        NextApbComplete = 1'b0;
      end

    `BRIDGE_APB_PENABLE :
      begin
        if (PREADY == 1'b1)  // end of enable phase
          begin
            NextBridgeApbSt = `BRIDGE_APB_IDLE;
            NextPSEL        = 1'b0;
            NextPENABLE     = 1'b0;
            NextApbComplete = 1'b1;
            if (iPWRITE == 1'b0)
              begin
                NextRDATA   = PRDATA;
              end
          end
        else
          begin
            NextApbComplete = 1'b0;
          end
      end

    default :
      ;
  endcase
end // p_BridgeApbSMComb

assign PCLKEN = |{PCLKENS & NxtPselDec};

// -----------------------------------------------------------------------------
// This block registers D-Input logic used in p_BridgeAPBSMComb process.
// All the flops are clock - enabled using PCLKEN
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_BridgeAPBSMSeq
  if (ARESETn == 1'b0)
    begin
      iRDATA               <= {32{1'b0}};
      BridgeApbSt          <= `BRIDGE_APB_IDLE;
      PSEL                 <= 1'b0;
      iPENABLE             <= 1'b0;
      ApbComplete          <= 1'b1;
    end
  else
    begin
      if (PCLKEN == 1'b1)
        begin
          iRDATA           <= NextRDATA;
          BridgeApbSt      <= NextBridgeApbSt;
          PSEL             <= NextPSEL;
          iPENABLE         <= NextPENABLE;
          ApbComplete      <= NextApbComplete;
        end
    end
end // p_BridgeAPBSMSeq

//------------------------------------------------------------------------------
// Set PSEL enable depending on what's connected to PREADY
//------------------------------------------------------------------------------
integer loop;

always @(PREADYS) begin
  for (loop = 0; loop < PORTS; loop=loop+1) begin
       PSELEN[loop] = (PREADYS[loop] !== 1'bz);   
   end
end

//------------------------------------------------------------------------------
// AxiTxnWrErr :
// ~~~~~~~~~~~~~
// This bridge does not ever error
//------------------------------------------------------------------------------
assign AxiTxnWrErr = 1'b0;

//------------------------------------------------------------------------------
// AxiTxnRdErr :
// ~~~~~~~~~~~~~
// This bridge does not ever error
//------------------------------------------------------------------------------
assign AxiTxnRdErr = 1'b0;

//------------------------------------------------------------------------------
// Selecting the portion of PADDR for demultiplexing PSEL
//------------------------------------------------------------------------------
assign PaddrSlice = (iAUSER > MAX_PORT) ? MAX_PORT : iAUSER;

//------------------------------------------------------------------------------
// Decoder on PaddrSlice lines to accomodate 16 possible APB slaves
//------------------------------------------------------------------------------
always @ (PaddrSlice)
begin : p_PaddrDecComb
  PselDec = {75{1'b0}};
  PselDec[PaddrSlice] = 1'b1;
end // p_PaddrDecComb

//------------------------------------------------------------------------------
// Selecting the portion of PADDR for demultiplexing PCLKEN
//------------------------------------------------------------------------------
assign NxtPaddrSlice = (NextAUSER > MAX_PORT) ? MAX_PORT : NextAUSER;

//------------------------------------------------------------------------------
// Decoder on PaddrSlice lines to accomodate 16 possible APB slaves
//------------------------------------------------------------------------------
always @ (NxtPaddrSlice)
begin : p_PaddrNxtDecComb
  NxtPselDec = {75{1'b0}};
  NxtPselDec[NxtPaddrSlice] = 1'b1;
end // p_PaddrDecComb

//------------------------------------------------------------------------------
// Assigning PSEL for 75 probable APB slaves
//------------------------------------------------------------------------------
assign PSELS  = {75{PSEL}} & PselDec;

//------------------------------------------------------------------------------
// Multiplexer on PortSelect lines to select PRDATAx/PREADYx/PSLVERRx
//------------------------------------------------------------------------------
assign PSLVERR = PSLVERRS[PortSelect];
assign PREADY = PREADYS[PortSelect];

// -----------------------------------------------------------------------------
// This block is responsible for clocking D-Input logic.
// -----------------------------------------------------------------------------
always @(posedge ACLK or negedge ARESETn)
begin : p_BridgeSMSeq
  if (ARESETn == 1'b0)
    begin
      BridgeAxiSt    <= `BRIDGE_AXI_IDLE;
      iPADDR         <= {32{1'b0}};
      iAUSER         <= 8'b0;
      iPWRITE        <= 1'b0;
      iARREADY       <= 1'b0;
      iRLAST         <= 1'b0;
      iRRESP         <= `AXI_RESP_OKAY;
      RvalidAxi      <= 1'b0;
      iAWREADY       <= 1'b0;
      WreadyAxi      <= 1'b0;
      iBRESP         <= `AXI_RESP_OKAY;
      BvalidAxi      <= 1'b0;
      BeatCnt        <= {4{1'b0}};
      AxiLen         <= {4{1'b0}};
      AxiSize        <= {3{1'b0}};
      BrstType       <= {2{1'b0}};
      AxiWrErr       <= 1'b0;
      HoldStApbTxr   <= 1'b0;
      PortSelect     <= {7{1'b0}};
    end
  else
    begin
      BridgeAxiSt    <= NextBridgeAxiSt;
      iPADDR         <= NextPADDR;
      iAUSER         <= NextAUSER;
      iPWRITE        <= NextPWRITE;
      iARREADY       <= NextARREADY;
      iRLAST         <= NextRLAST;
      iRRESP         <= NextRRESP;
      RvalidAxi      <= NextRvalidAxi;
      iAWREADY       <= NextAWREADY;
      WreadyAxi      <= NextWreadyAxi;
      iBRESP         <= NextBRESP;
      BvalidAxi      <= NextBvalidAxi;
      BeatCnt        <= NextBeatCnt;
      AxiLen         <= NextAxiLen;
      AxiSize        <= NextAxiSize;
      BrstType       <= NextBrstType;
      AxiWrErr       <= NextAxiWrErr;
      HoldStApbTxr   <= NextHoldStApbTxr;
      PortSelect     <= PaddrSlice;
    end
end // p_BridgeSMSeq

// -----------------------------------------------------------------------------
// Following AXI signals are derived after confirming that APB transfer is
// completed.
// -----------------------------------------------------------------------------
assign iRVALID = RvalidAxi & ApbComplete;
assign iBVALID = BvalidAxi & ApbComplete;
assign iWREADY = WreadyAxi & ApbComplete;

// -----------------------------------------------------------------------------
// Assigning internal copies to output ports
// -----------------------------------------------------------------------------
assign PWRITE    = iPWRITE;
assign PADDR     = iPADDR[31:0];
assign PENABLE   = iPENABLE;

assign ARREADY   = iARREADY;

assign RLAST     = iRLAST;
assign RRESP     = iRRESP;
assign RVALID    = iRVALID;
assign RDATA     = iRDATA;

assign AWREADY   = iAWREADY;

assign WREADY    = iWREADY;
assign BRESP     = iBRESP;
assign BVALID    = iBVALID;

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

