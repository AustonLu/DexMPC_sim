// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2009 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FrmR.v,v
//  File Revision       : 1.25
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master R group interface
//
//                        Reads write completion channel and timing information
//                        from a text file. Generates RREADY signal and
//                        tests transfers received on the R group of
//                        the AXI interface.
//
// --=========================================================================--

`timescale 1ns / 1ps


module FrsR
(
  ACLK,
  ARESETn,
  RID,
  RVALID,
  RDATA,
  RLAST,
  RRESP,
  RUSER,
  SyncGrant,

  ARVALID,
  ARREADY,
  ARID,

  RREADY,
  SyncReq,

  Rebus,
  Remit,
  Rwbus,
  Rpause,
  Rgo
);


  // Module parameters
  parameter FILE_ARRAY_SIZE   = 1000;               // Size of command array
  parameter STIM_FILE_NAME    = "filestim.a";       // Stimulus file name
  parameter MESSAGE_TAG       = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE           = 1;                  // Verbosity control
  parameter DATA_WIDTH        = 64;                 // Width of data bus
  parameter ID_WIDTH          = 8;
  parameter TIMER_WIDTH       = 32;                 // Width of timer vectors
  parameter EW_WIDTH          = 8;
  parameter OUT_TRANS         = 8;
  parameter USE_X             = 1;
  parameter USER_WIDTH        = 1;
  parameter REQUIRE_AR_HNDSHK = 1;                  // Require AR Handshake

  // Calculated parameters - do not modify
  parameter DATA_MAX   = DATA_WIDTH - 1;  // Upper bound of data vector
  parameter TIMER_MAX  = TIMER_WIDTH - 1; // Upper bound of timer vector
  parameter ID_MAX     = ID_WIDTH - 1;    // Upper bound of ID vector
  parameter EW_MAX     = EW_WIDTH - 1;    // Upper bound of Emit and Wait vectors
  parameter USER_MAX   = USER_WIDTH - 1;  // Upper bound of User bus

  parameter ID_PACK_WIDTH = (ID_WIDTH <= 4) ? 4 :
                            (ID_WIDTH > 4 & ID_WIDTH <= 8) ? 8 :
                            (ID_WIDTH > 8 & ID_WIDTH <= 12) ? 12 :
                            (ID_WIDTH > 12 & ID_WIDTH <= 16) ? 16 :
                            (ID_WIDTH > 16 & ID_WIDTH <= 20) ? 20 :
                            (ID_WIDTH > 20 & ID_WIDTH <= 24) ? 24 :
                            (ID_WIDTH > 24 & ID_WIDTH <= 28) ? 28 : 32;

  parameter VECTOR_WIDTH = (            // Length of file vector
                          32 +          // command word
                          32 +          // line number
                          TIMER_WIDTH + // RRWait
                          DATA_WIDTH +  // Data
                          DATA_WIDTH +  // Mask
                          ID_PACK_WIDTH +    //ID
                          EW_WIDTH +    //Emit
                          EW_WIDTH +    //Wait
                          USER_WIDTH
                          ) ;

  parameter VECTOR_MAX = VECTOR_WIDTH - 1;// Upper bound of file vector
  parameter ID_BASE    = 64 + TIMER_WIDTH + DATA_WIDTH + DATA_WIDTH; 
  parameter ID_TOP     = ID_BASE + ID_WIDTH - 1;
  parameter WAIT_BASE  = ID_BASE + ID_PACK_WIDTH;
  parameter WAIT_TOP   = WAIT_BASE + EW_WIDTH - 1;
  parameter EMIT_BASE  = WAIT_TOP + 1;
  parameter EMIT_TOP   = EMIT_BASE + EW_WIDTH - 1;
  parameter USER_BASE  = EMIT_TOP + 1;

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  output               RVALID;          // Read valid
  output  [ID_MAX:0]   RID;             // Read ID
  output               RLAST;           // Read last
  output  [DATA_MAX:0] RDATA;           // Read data
  output         [1:0] RRESP;           // Response
  output  [USER_MAX:0] RUSER;           // USER signal

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels

  input               ARVALID;
  input               ARREADY;
  input    [ID_MAX:0] ARID;

  // To AXI interface
  input               RREADY;           // Write valid

  // Synchronisation
  output              SyncReq;          // Local sync command

  //Emit Wait bus
  output [EW_MAX:0]    Rebus;           //Read emit bus
  output               Remit;           //Emit valid signal
  input [EW_MAX:0]     Rwbus;           //Wait bus
  input                Rpause;          //Pause Signal
  input                Rgo;             //Go signal


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  // From AXI interface
  wire                ACLK;
  wire                ARESETn;
  wire                RVALID;
  wire   [DATA_MAX:0] RDATA;
  wire          [1:0] RRESP;
  wire                RLAST;
  wire   [USER_MAX:0] RUSER;

  // Synchronisation
  wire                SyncReq;

  wire                ARVALID;
  wire                ARREADY;
  wire     [ID_MAX:0] ARID;

  // To AXI interface
  wire                RREADY;

  // Synchronisation
  wire                SyncGrant;

// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty
  wire                SyncValid;
  wire                FileReady;        // Fetch new command from file

  // Handshake between sync control and timeout control
  wire                CmdValid;         // Valid transfer command
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Internal FileData

  // Timing
  wire                ResetTimer;       // Reset the delay timer

  wire                Remit_i;

  //internal verisons of output signals
  wire                iRValid;
  wire [ID_MAX:0]     iRId;
  wire [DATA_WIDTH-1:0] iRdata;
  wire [1:0]          iRResp;
  wire                iRLast;
  wire [USER_MAX:0]   iRuser;

  wire [31:0]         Time;

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  FrsFileReaderM
    // Positionally mappd module parameters
    #(FILE_ARRAY_SIZE,
      VECTOR_WIDTH,
      STIM_FILE_NAME,
      MESSAGE_TAG,
      VERBOSE,
      16'hd000,        // File ID for B channel
      ID_WIDTH,
      ID_BASE,
      EW_WIDTH,
      WAIT_BASE,
      0,
      7,
      OUT_TRANS,
      64,
      TIMER_WIDTH,
      REQUIRE_AR_HNDSHK,
      8
    )
  uReader
  (

    .ACLK             (ACLK),
    .ARESETn          (ARESETn),
    
    .Enable_ID          (ARID),
    .Enable_ID_valid    (ARVALID),
    .Enable_ID_ready_in (ARREADY),
    .Enable_ID_error  (illegal_ID),

    .FileData         (FileData),
    .FileReady        (FileReady),
    .FileValid        (FileValid),

    .Time             (Time),

    .Wait             (Rwbus),
    .Wait_valid       (Rgo),

    .SyncValid        (SyncValid),
    .SyncReady        (SyncGrant)

  );

  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated values in file
  //  ---------------------------------------------------------------------

  assign iRdata      = FileData[DATA_MAX+TIMER_WIDTH+64:TIMER_WIDTH+64];
  assign iRResp      = FileData[15:14];  // Expected write response
  assign iRId        = FileData[ID_TOP:ID_BASE];
  assign iRLast      = FileData[8];
  assign iRuser      = FileData[USER_BASE+USER_MAX:USER_BASE];

  // Control signals are qualified with SyncValid
  assign SyncReq     = SyncValid;  // Sync command

  assign Rebus       = FileData[EMIT_TOP:EMIT_BASE];
  assign Remit_i     = (FileData[10] == 1'b1);
  assign Remit       = Remit_i & FileReady;

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  // or current command is being polled
  assign iRValid = FileValid  & ~(Rpause & Remit_i);

  // Fetch a new command
  assign FileReady = iRValid & RREADY;

  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------

  FrsTimer
    #(TIMER_WIDTH)
  uTimer
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Sync           (SyncValid),
    .Time           (Time)
  );


  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign RVALID       = iRValid;
  assign RDATA        = (iRValid) ? iRdata   : {DATA_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign RID          = (iRValid) ? iRId     : {ID_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign RRESP        = (iRValid) ? iRResp   : {2{USE_X ? 1'bx : 1'b0}};
  assign RUSER        = (iRValid) ? iRuser   : {USER_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign RLAST        = (iRValid) ? iRLast   : (USE_X ? 1'bx : 1'b0);

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: Stimulus file version check
  //----------------------------------------------------------------------------
  // Check that we never try to enable an illigal ID
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never
    #(0, 0, "Tried to enable non-existant transaction - R channel" )
  illegalID
    (ACLK, ARESETn, illegal_ID);


  // OVL_ASSERT_END

`endif

endmodule

// --================================= End ===================================--




