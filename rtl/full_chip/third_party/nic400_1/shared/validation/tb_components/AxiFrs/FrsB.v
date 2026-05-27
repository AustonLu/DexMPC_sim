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
//  File Name           : FrsB.v,v
//  File Revision       : 1.21
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master B group interface
//
//                        Reads write completion channel and timing information
//                        from a text file. Generates BID, BRESP and BVALID info
// --=========================================================================--

`timescale 1ns / 1ps


module FrsB
(
  //System Signals
  ACLK,
  ARESETn,

  //BChannel
  BVALID,
  BRESP,
  BID,
  BUSER,
  BREADY,

  //Sync Interface
  SyncGrant,
  SyncReq,

  //Enable signals
  EnableID,
  Enable,
 
  //BChannel EW bus
  Bebus,
  Bemit,
  Bpause,
  Bwbus,
  Bgo

);

  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME  = "filestim.b";       // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // Width of ID vectors
  parameter EW_WIDTH        = 8;                  // Width of Emit/Wait vectors
  parameter OUT_TRANS       = 8;                  // Outstanding transactions
  parameter USE_X           = 0;                  // Drive X onto unused data lines 
  parameter USER_WIDTH      = 0;                  // User signal width


  // Calculated parameters - do not modify
  parameter EW_MAX          = EW_WIDTH -1;        
  parameter USER_MAX        = USER_WIDTH -1;        

  parameter ID_PACK_WIDTH = (ID_WIDTH <= 4) ? 4 :
                            (ID_WIDTH > 4 & ID_WIDTH <= 8) ? 8 :
                            (ID_WIDTH > 8 & ID_WIDTH <= 12) ? 12 :
                            (ID_WIDTH > 12 & ID_WIDTH <= 16) ? 16 :
                            (ID_WIDTH > 16 & ID_WIDTH <= 20) ? 20 :
                            (ID_WIDTH > 20 & ID_WIDTH <= 24) ? 24 :
                            (ID_WIDTH > 24 & ID_WIDTH <= 28) ? 28 : 32;

  parameter TIMER_MAX   = TIMER_WIDTH - 1 ;   // Upper bound of timer vector
  parameter VECTOR_WIDTH = (
                          32 +          // command word,
                          TIMER_WIDTH + // BRWait
                          ID_PACK_WIDTH +
                          EW_WIDTH + 
                          EW_WIDTH +
                          USER_WIDTH
                          );

  parameter ID_BASE    = 32 + TIMER_WIDTH;
  parameter ID_TOP     = ID_BASE + ID_WIDTH - 1;

  parameter WAIT_BASE  = ID_BASE + ID_PACK_WIDTH;
  parameter WAIT_TOP   = WAIT_BASE + EW_WIDTH - 1;
  parameter EMIT_BASE  = WAIT_BASE + EW_WIDTH;
  parameter EMIT_TOP   = EMIT_BASE + EW_WIDTH - 1;
  parameter USER_BASE  = EMIT_TOP + 1;

  parameter VECTOR_MAX = VECTOR_WIDTH - 1;

  // From AXI interface
  input                 ACLK;             // Clock input
  input                 ARESETn;          // Reset async input active low

  //BChannel
  output                BVALID;           // Write response valid
  output          [1:0] BRESP;            // Write response
  output [ID_WIDTH-1:0] BID;              // Write ID      
  output   [USER_MAX:0] BUSER;            // Write response USER signal
  input                 BREADY;           // Write response ready

  // Synchronisation
  input                 SyncGrant;        // Sync granted from all channels
  output                SyncReq;          // Local sync command

  //Enable Signals
  input [ID_WIDTH-1:0]  EnableID;         // Write ID
  input                 Enable;           // Wlast valid

  // Emit/Wait bus
  output     [EW_MAX:0] Bebus;          // Emit code
  output                Bemit;          // emit code
  input                 Bpause;         // Pause code
  input      [EW_MAX:0] Bwbus;          // Wait code 
  input                 Bgo;            // Go signal

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

  //internal channel signals
  wire [2:0]            iBresp;
  wire [ID_WIDTH-1:0]   iBid;
  wire [USER_MAX:0]     iBuser;
  wire                  iBValid;

  wire                  DataValid;
  wire                  DataReady;
  wire                  SyncValid;
  wire                  FileValid;


  wire                  Empty;

  wire [VECTOR_MAX:0]   FileData;
  wire                  FileReady;

  wire                  illegal_ID;

  wire [31:0]           Time;


//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  File reader
  //
  //  //File Reader will assume that vectors are sorted in time order (between syncs)
  //  //Reponses will always be sent earliest possible first.
  // 
  //  ---------------------------------------------------------------------

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
      32,
      TIMER_WIDTH,
      0               //Requie Hndshk
    )
  uReader
  (

    .ACLK             (ACLK),
    .ARESETn          (ARESETn),
    
    .Enable_ID          (EnableID),
    .Enable_ID_valid    (Enable),
    .Enable_ID_ready_in (1'b1),
    .Enable_ID_error    (illegal_ID),

    .FileData         (FileData),
    .FileReady        (FileReady),
    .FileValid        (FileValid),

    .Time             (Time),

    .Wait             (Bwbus),
    .Wait_valid       (Bgo),

    .SyncValid        (SyncValid),
    .SyncReady        (SyncGrant)

  );

  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated vector in file
  //  ---------------------------------------------------------------------

  assign iBid           = FileData[ID_TOP:ID_BASE];   // Write response ID
  assign iBresp         = FileData[15:14];            // Write response 
  assign iBuser         = FileData[USER_BASE+USER_MAX:USER_BASE]; 

  // Control signals are qualified with SyncValid
  assign SyncReq        = SyncValid;                  // Sync Bit

  assign Bebus          = FileData[EMIT_TOP:EMIT_BASE];
  assign Bemit_i        = (FileData[10] == 1'b1);
  assign Bemit          = Bemit_i & FileReady;

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  assign iBValid = FileValid & ~(Bpause & Bemit_i);

  // Fetch a new command
  assign FileReady = iBValid & BREADY;
         

  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------

  FrsTimer
    #(TIMER_WIDTH)
  uTimer
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Sync           (SyncGrant),
    .Time           (Time)
  );

  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign BVALID  = iBValid; 
  assign BID     = (BVALID) ? iBid   : {ID_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign BRESP   = (BVALID) ? iBresp : (USE_X) ? 2'bx : 2'b0;
  assign BUSER   = (BVALID) ? iBuser : {USER_WIDTH{(USE_X) ? 1'bx : 1'b0}};

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
    #(0, 0, "Tried to enable non-existant transaction - B channel" )
  illegalID
    (ACLK, ARESETn, illegal_ID);


  // OVL_ASSERT_END

`endif

endmodule

// --================================= End ===================================--

