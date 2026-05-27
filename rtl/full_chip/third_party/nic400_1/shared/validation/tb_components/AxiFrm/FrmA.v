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
//  File Name           : FrmA.v,v
//  File Revision       : 1.25
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master A group interface
//
//                        Reads address channel and timing information
//                        from a text file and converts them transfers on
//                        the AW or AR group of the AXI interface.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmA
(
  ACLK,
  ARESETn,

  AReady,
  SyncGrant,
  Polling,
  PollPhaseA,
  ResetPoll,
  out_reached,
 
  AValid,
  AAddr,
  ALen,
  ASize,
  ABurst,
  ALock,
  AId,
  ACache,
  AProt,
  AUser,
  SyncReq,
  ResetSync,
  AEn,
  CommentReq,
  LineNum,
  Quit,
  Restart,
  Terminate,
  Stop,

  Aebus,
  Aemit,
  Awbus,
  Apause,
  Ago

);


  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME  = "undef";      // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter USE_X           = 1;                  // Drive X on invalid signals
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // Width of ID bus
  parameter EW_WIDTH        = 8;                  // Event bus width
  parameter ADDR_WIDTH      = 32;                 // Addr bus width
  parameter USER_WIDTH      = 8;                  // User Width  
  parameter EMITONSYNC      = 0;                  // Emit on SYNC

  // Calculated parameters - do not modify
  parameter TIMER_MAX       = TIMER_WIDTH - 1 ;       // Upper bound of timer vector
  parameter ID_MAX          = ID_WIDTH - 1;
  parameter USER_MAX        = USER_WIDTH - 1;
  parameter ADDR_MAX        = ADDR_WIDTH - 1;
  parameter EW_MAX          = EW_WIDTH - 1;

  parameter ID_WIDTH_RND   = ((ID_WIDTH / 4) * 4);
  parameter ID_PACK_WIDTH  = (ID_WIDTH_RND == ID_WIDTH) ?
                               ID_WIDTH_RND : ID_WIDTH_RND + 4;

  parameter ADDR_WIDTH_RND  = ((ADDR_WIDTH / 4) * 4);
  parameter ADDR_PACK_WIDTH = (ADDR_WIDTH_RND == ADDR_WIDTH) ?
                               ADDR_WIDTH_RND : ADDR_WIDTH_RND + 4;

  parameter VECTOR_WIDTH = (                 // Length of file vector
                          32 +               // command word,
                          32 +               // line number
                          TIMER_WIDTH +      // AVWait
                          ADDR_PACK_WIDTH +       // Address
                          ID_PACK_WIDTH +    // Id width
                          EW_WIDTH +
                          EW_WIDTH +
                          USER_WIDTH
                          ) ;

  parameter VECTOR_MAX = VECTOR_WIDTH - 1 ;       // Upper bound of file vector
  parameter ADDR_BASE = 64 + TIMER_WIDTH;
  parameter ID_BASE   = TIMER_WIDTH + 64 + ADDR_PACK_WIDTH;
  parameter WAIT_BASE = ID_BASE   + ID_PACK_WIDTH;
  parameter EMIT_BASE = WAIT_BASE + EW_WIDTH;
  parameter USER_BASE = EMIT_BASE + EW_WIDTH;

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               AReady;           // Address ready

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels
  input               out_reached;
  
    // Poll signals
  input               Polling;          // Polling current command
                                        //  - tie off low if no poll
  input               PollPhaseA;       // Enable address phase
                                        //  - tie off high if no poll
  input               ResetPoll;        // Reset timer on poll iteration
                                        //  - tie off low if no poll

// Module Outputs

  // To AXI interface
  output              AValid;           // Address valid
  output [ADDR_MAX:0] AAddr;            // Address
  output        [3:0] ALen;             // Burst length
  output   [ID_MAX:0] AId;              // Burst length
  output        [2:0] ASize;            // Burst size
  output        [1:0] ABurst;           // Burst type
  output        [1:0] ALock;            // Lock type
  output [USER_MAX:0] AUser;            // User signal
  output        [3:0] ACache;           // Cache type
  output        [2:0] AProt;            // Protection type

  // Synchronisation
  output              SyncReq;          // Local sync command
  output              ResetSync;        // Reset timers on SYNC command

  // Poll signals
  output              AEn;              // Address phase completed

  // To external comment publishing module
  output              CommentReq;       // Request a comment

  // To FRM reporter
  output       [31:0] LineNum;          // Stimulus source line number
  output              Quit;             // Quit command found
  output              Restart;          // Restart stimulus from first command
  output              Terminate;        // End the simulation
  output              Stop;             // Halt the simulation

 // Emit/Wait bus
  output   [EW_MAX:0] Aebus;            // Emit code
  output              Aemit;            // emit code
  input    [EW_MAX:0] Awbus;            // wait code
  input               Apause;           // Go code
  input               Ago;              // Wait valid indicator

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  // From AXI interface
  wire                ACLK;
  wire                ARESETn;
  wire                AReady;

  // Synchronisation
  wire                SyncGrant;

  // Poll
  wire                Polling;
  wire                PollPhaseA;
  wire                ResetPoll;

  // To AXI interface
  wire                AValid;
  wire   [ADDR_MAX:0] AAddr;
  wire          [3:0] ALen;
  wire          [2:0] ASize;
  wire     [ID_MAX:0] AId;
  wire          [1:0] ABurst;
  wire   [USER_MAX:0] AUser;
  wire          [1:0] ALock;
  wire          [3:0] ACache;
  wire          [2:0] AProt;

  // Synchronisation
  wire                SyncReq;
  wire                ResetSync;

  // Poll
  wire                AEn;

  // To external comment publishing module
  wire                CommentReq;

  // To FRM reporter
  wire         [31:0] LineNum;
  wire                Quit;
  wire                Stop;
  wire                Restart;
  wire                Terminate;

// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty
  wire                FileReady;        // Fetch new command from file

  // Handshake between sync control and timeout control
  wire                CmdValid;         // Valid transfer command
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire  [TIMER_MAX:0] VTime;            // Address valid time

  // Timing
  wire                ResetTimer;       // Reset the delay timer

  // Internal versions of output signals
  wire                iSyncReq;         // internal SyncReq
  wire                iResetSync;       // internal ResetSync
  wire                iRestart;         // internal Restart to file reader

  wire                iAValid;          // internal AValid
  wire   [ADDR_MAX:0] iAAddr;           // internal AAddr
  wire          [3:0] iALen;            // internal ALen
  wire          [2:0] iASize;           // internal ASize
  wire          [1:0] iABurst;          // internal ABurst
  wire   [USER_MAX:0] iAUser;           // internal AUser
  wire          [1:0] iALock;           // internal ALock
  wire     [ID_MAX:0] iAId  ;           // internal AId
  wire          [3:0] iACache;          // internal ACache
  wire          [2:0] iAProt;           // internal AProt

  wire                iCommentReq;      // internal CommentReq

  //Emit go bus
  wire     [EW_MAX:0] Aebus;            // Emit code
  wire                Aemit;            // emit
  wire                Aemit_i;          // emit internal
  wire                Await;            // wait 
  wire                Apause;           // pause channel
  wire                Ago;              // input bus is valid

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  File reader
  //  ---------------------------------------------------------------------

  FrmFileReaderM
    // Positionally mappd module parameters
    #(FILE_ARRAY_SIZE,
      STIM_FILE_NAME,
      VECTOR_WIDTH,
      MESSAGE_TAG,
      VERBOSE,
      16'hc001,                          // File ID for A channel
      WAIT_BASE,
      EW_WIDTH
    )
  uReader
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .FileReady      (FileReady),
    .Restart        (iRestart),

    .Wait           (Awbus),
    .Wait_valid     (Ago),

    .FileValid      (FileValid),
    .FileData       (FileData)
  );


  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated vector in file
  //  ---------------------------------------------------------------------

  assign iAAddr                                   // Address
    = FileData[ADDR_WIDTH+TIMER_WIDTH+63:TIMER_WIDTH+64];

  assign VTime                                    // AVALID time
    = FileData[TIMER_MAX+64:64];

  assign LineNum        = FileData[63:32];        // Stimulus file line number

  assign iAProt         = FileData[31:29];        // Protection field
  assign iACache        = FileData[28:25];        // Cache field
  assign iABurst        = FileData[24:23];        // Burst field
  assign iALock         = FileData[22:21];        // Lock field
  assign iASize         = FileData[20:18];        // Size field
  assign iALen          = FileData[17:14];        // Length field
  assign iAId           = FileData[ID_WIDTH+ID_BASE-1:ID_BASE];  // ID field
  assign iAUser         = FileData[USER_BASE+USER_MAX:USER_BASE]; //User field
  assign iCommentReq    = FileData[9];            // Request comment

  // Control signals are qualified with FileValid
  assign iRestart       = FileValid & FileData[8];  // Restart
  assign Terminate      = FileValid & FileData[7];  // Terminate
  assign Stop           = FileValid & FileData[6];  // Stop
  assign Quit           = FileValid & FileData[5];  // Quit
  assign iResetSync     = FileValid & FileData[1];  // Reset timer
  assign iSyncReq       = FileValid & FileData[0];  // Sync command

 //Emit go bus
  assign Aebus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];
  assign Aemit_i        = (FileData[10] == 1'b1);
  assign Aemit          = Aemit_i & (CmdReady | (SyncGrant && EMITONSYNC));
  assign Await          = FileData[11];

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  // or poll iteration is not complete
  assign CmdValid = FileValid  &        //File is valid
                      ~iSyncReq &         //not a sync
                         PollPhaseA &        //polling
                           ~Await     &         //not waiting ... 
                              ~out_reached   &         //not reaching the outstanding trans limit
                                ~(Apause & Aemit_i);   // Not trying to emit
                            


  // Fetch a new command
  assign FileReady =
                (
                  CmdReady              // ready for next command
                  & ~iSyncReq           // not a SYNC command
                  & ~Polling            // not polling current command
                  & ~Await              // not waiting
                  & ~(Apause & Aemit_i) // not blocked by an emit
                )
                | SyncGrant;            // syncronisation event


  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------

  FrmTimeOut
    #(TIMER_WIDTH)
  uTimeOut
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Sync           (ResetTimer),
    .InputValid     (CmdValid),
    .OutputReady    (AReady),
    .VTime          (VTime),

    .InputReady     (CmdReady),
    .OutputValid    (iAValid)
  );

  // Reset timer on SYNC commands and poll iterations
  assign ResetTimer = iResetSync | ResetPoll;


  //  ---------------------------------------------------------------------
  //  Combinatorially drive AXI to X or 0 when invalid
  //  ---------------------------------------------------------------------

  assign AAddr  = iAValid ? iAAddr  : {ADDR_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign ALen   = iAValid ? iALen   : {4{USE_X ? 1'bx : 1'b0}};
  assign AId    = iAValid ? iAId    : {ID_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign ASize  = iAValid ? iASize  : {3{USE_X ? 1'bx : 1'b0}};
  assign ABurst = iAValid ? iABurst : {2{USE_X ? 1'bx : 1'b0}};
  assign ALock  = iAValid ? iALock  : {2{USE_X ? 1'bx : 1'b0}};
  assign ACache = iAValid ? iACache : {4{USE_X ? 1'bx : 1'b0}};
  assign AProt  = iAValid ? iAProt  : {3{USE_X ? 1'bx : 1'b0}};
  assign AUser  = iAValid ? iAUser  : {USER_WIDTH{USE_X ? 1'bx : 1'b0}};


  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign AValid     = iAValid;
  assign SyncReq    = iSyncReq;
  assign ResetSync  = iResetSync;
  assign AEn        = CmdReady;
  assign Restart    = iRestart;

  // Request comment when address is valid
  assign CommentReq = iCommentReq & iAValid;

endmodule

// --================================= End ===================================--

