// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2014 ARM Limited
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


module FrmR
(
  ACLK,
  ARESETn,

  RVALID,
  RDATA,
  RID,
  RRESP,
  RUSER,
  SyncGrant,
  Polling,
  ResetPoll,

  RREADY,
  SyncReq,

  REn,
  DataErr,
  DataExp,
  DataMask,
  RespErr,
  RespExp,
  RespMask,
  LineNum,

  PollReq,
  PollRepeats,
  DataNe,

  Rebus,
  Remit,
  Rpause,
  Rwbus,
  Rgo
);


  // Module parameters
  parameter FILE_ARRAY_SIZE   = 1000;             // Size of command array
  parameter STIM_FILE_NAME        = "undef";            // Stimulus File name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter DATA_WIDTH      = 64;                 // Width of data bus
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // ID width
  parameter EW_WIDTH        = 8;                  // Width of the RDATA bus
  parameter USER_WIDTH      = 8;

  // Calculated parameters - do not modify
  parameter ID_PACK_WIDTH = (ID_WIDTH <= 4) ? 4 :
                            (ID_WIDTH > 4 & ID_WIDTH <= 8) ? 8 :
                            (ID_WIDTH > 8 & ID_WIDTH <= 12) ? 12 :
                            (ID_WIDTH > 12 & ID_WIDTH <= 16) ? 16 :
                            (ID_WIDTH > 16 & ID_WIDTH <= 20) ? 20 :
                            (ID_WIDTH > 20 & ID_WIDTH <= 24) ? 24 :
                            (ID_WIDTH > 24 & ID_WIDTH <= 28) ? 28 : 32;

  parameter ID_BASE      = 64 + TIMER_WIDTH + DATA_WIDTH + DATA_WIDTH;
  parameter WAIT_BASE    = 64 + TIMER_WIDTH + DATA_WIDTH + DATA_WIDTH + ID_PACK_WIDTH;
  parameter WAIT_TOP     = WAIT_BASE + EW_WIDTH - 1;
  parameter EMIT_BASE    = WAIT_TOP + 1;
  parameter EMIT_TOP     = EMIT_BASE + EW_WIDTH - 1;
  parameter USER_BASE    = EMIT_TOP + 1;

  parameter USER_MAX   = USER_WIDTH - 1;
  parameter DATA_MAX   = DATA_WIDTH - 1;  // Upper bound of data vector
  parameter TIMER_MAX  = TIMER_WIDTH - 1; // Upper bound of timer vector

  parameter VECTOR_WIDTH = (            // Length of file vector
                          32 +          // command word
                          32 +          // line number
                          TIMER_WIDTH + // RRWait
                          DATA_WIDTH +  // Data
                          DATA_WIDTH +   // Mask
                          ID_PACK_WIDTH +
                          EW_WIDTH + 
                          EW_WIDTH + 
                          USER_WIDTH
                          ) ;

  parameter EW_MAX = EW_WIDTH - 1;
  parameter VECTOR_MAX = VECTOR_WIDTH - 1;// Upper bound of file vector

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  input                 RVALID;         // Read valid
  input  [DATA_MAX:0]   RDATA;          // Actual read data
  input  [ID_WIDTH-1:0] RID;            // Actual Read ID
  input         [1:0]   RRESP;          // Actual read response
  input [USER_MAX:0]    RUSER;          // Actual read user signal      

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels

  // Poll signals
  input               Polling;          // Polling current command
  input               ResetPoll;        // Poll iteration complete

// Module Outputs

  // To AXI interface
  output              RREADY;           // Write valid

  // Reporting
  output              REn;              // Read error signals are valid

  output              DataErr;          // Read data mismatch
  output [DATA_MAX:0] DataExp;          // Expected read data
  output [DATA_MAX:0] DataMask;         // Read data mask

  output              RespErr;          // Read response mismatch
  output        [1:0] RespExp;          // Expected read reponse
  output        [1:0] RespMask;         // Read reponse mask

  output       [31:0] LineNum;          // Stimulus source line number

  // Synchronisation
  output              SyncReq;          // Local sync command

  // Poll
  output              PollReq;          // Poll request
  output [TIMER_MAX:0] PollRepeats;     // Maximum poll iterations
  output              DataNe;           // Data check type not equal

  output [EW_MAX:0]   Rebus;            //emit bus
  output              Remit;            //emit enable
  input               Rpause;           //emit buffer status flag
  input [EW_MAX:0]    Rwbus;
  input               Rgo;


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  // From AXI interface
  wire                ACLK;
  wire                ARESETn;
  wire                RVALID;
  wire   [DATA_MAX:0] RDATA;
  wire [ID_WIDTH-1:0] RID;
  wire          [1:0] RRESP;
  wire [USER_MAX:0]   RUSER;

  // Synchronisation
  wire                SyncReq;

    // Poll signals
  wire                Polling;
  wire                ResetPoll;

  // To AXI interface
  wire                RREADY;

  // Reporting
  wire                REn;

  reg                 DataErr;
  wire   [DATA_MAX:0] DataExp;
  wire   [DATA_MAX:0] DataMask;

  reg                 RespErr;
  wire          [1:0] RespExp;
  wire          [1:0] RespMask;

  wire         [31:0] LineNum;

  // Synchronisation
  wire                SyncGrant;

  // Poll
  wire                PollReq;
  wire  [TIMER_MAX:0] PollRepeats;
  wire                DataNe;

// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty
  wire                FileReady;        // Fetch new command from file

  // Handshake between sync control and timeout control
  wire                CmdValid;         // Valid transfer command
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Internal FileData
  wire  [TIMER_MAX:0] VTime;            // Read ready time
  wire                ResetSync;        // Reset timers on true SYNC command
  wire                Restart;          // Restart to file reader

  // Data comparison
  wire                DataDiff;         // Actual and expected data difference

  // Timing
  wire                ResetTimer;       // Reset the delay timer


  // Internal versions of output signals
  wire                iRReady;          // Internal RREADY
  wire                iSyncReq;         // Internal SyncReq
  wire                iDataNe;          // Internal DataNe

  wire                iDataErr;         // Internal DataErr (multivalue logic)
  wire                iRespErr;         // Internal RespErr (multivalue logic)
  wire                RespIDErr;

  wire   [DATA_MAX:0] iDataExp;         // Internal DataExp
  wire   [DATA_MAX:0] iDataMask;        // Internal DataMask

  wire          [1:0] iRespExp;         // Internal RespExp
  wire          [1:0] iRespMask;        // Internal RespMask

  wire   [USER_MAX:0] iUserExp;         // Internal User Signal

  wire                 Rwait;
  wire                 Remit_i;
  wire                 SyncValid;

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  File reader
  //  ---------------------------------------------------------------------

  FrmFileReaderS
    // Positionally mappd module parameters
    #(FILE_ARRAY_SIZE,
      STIM_FILE_NAME,
      VECTOR_WIDTH,
      MESSAGE_TAG,
      VERBOSE,
      16'hc001,        // File ID for B channel
      WAIT_BASE,
      EW_WIDTH,
      ID_BASE,
      ID_WIDTH)
  uReader
  (

    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .FileReady      (FileReady),
    .Restart        (Restart),

    .FileValid      (FileValid),
    .SyncValid      (SyncValid),
    .FileData       (FileData),

    .Wait           (Rwbus),
    .Wait_valid     (Rgo),

    .ID             (RID)
  );

  //Detect Failed identifiers
  assign RespIDErr = RVALID & ~FileValid;

  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated values in file
  //  ---------------------------------------------------------------------


  assign iDataMask                      // Data mask
    = FileData[DATA_MAX+DATA_WIDTH+TIMER_WIDTH+64:DATA_WIDTH+TIMER_WIDTH+64];

  assign iDataExp                       // Expected data
    = FileData[DATA_MAX+TIMER_WIDTH+64:TIMER_WIDTH+64];

  assign VTime                          // Read ready time
    = FileData[TIMER_MAX+64:64];

  assign LineNum    = FileData[63:32];  // Stimulus file line number

  assign iRespMask  = FileData[17:16];  // Write response mask
  assign iRespExp   = FileData[15:14];  // Expected write response
  assign iUserExp   = FileData[USER_BASE+USER_MAX:USER_BASE];   // Expected user signal

  // Control signals are qualified with FileValid
  assign Restart    = SyncValid & FileData[8];  // Restart
  assign iDataNe    = FileValid & FileData[3];  // Data comparison not equal
  assign PollReq    = FileValid & FileData[2];  // Poll command
  assign ResetSync  = SyncValid & FileData[1];  // Reset timer
  assign iSyncReq   = SyncValid & FileData[0];  // Sync command

  assign Rebus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];
  assign Remit_i        = (FileData[10] == 1'b1);
  assign Remit          = Remit_i & REn;
  assign Rwait          = FileData[11];

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  // or current command is being polled
  assign CmdValid = FileValid  & ~iSyncReq & ~Rwait & ~(Remit_i & Rpause) & RVALID;


  // Fetch a new command
  assign FileReady =
                (
                  REn                   // ready for next command
                  & ~iSyncReq           // not a SYNC command
                  & ~Polling            // not polling current command
                  & ~Rwait
                  &  ~(Remit_i & Rpause)
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
    .OutputReady    (RVALID),
    .VTime          (VTime),

    .InputReady     (CmdReady),
    .OutputValid    (iRReady)
  );


  // Reset timer on true SYNC commands and poll iterations
  assign ResetTimer = ResetSync | ResetPoll;


  //  ---------------------------------------------------------------------
  //  Data actual vs expected value comparison
  //  ---------------------------------------------------------------------

  // Compare the read data, unless test is masked out
  assign DataDiff = |((iDataExp ^ RDATA) & iDataMask);


  // Determine if data error taking accounting of mask and check type eq or ne
  assign iDataErr =
              (~iDataNe & DataDiff) |   // test equal fails
              (iDataNe & ~DataDiff &    // test not equal fails
                (|iDataMask));          // mask not zero


  // Ensure that test always fails if unmaksed data is X in simulation.
  // Converts multivalued logic to 0 or 1.
  always @ (iDataErr)
  begin : p_DataErrComb
    if (iDataErr == 1'b0) // Note that test will fail if iDataErr is 1'bx
      DataErr = 1'b0;
    else
      DataErr = 1'b1;
  end


  //  ---------------------------------------------------------------------
  //  Response actual vs expected value comparison
  //  ---------------------------------------------------------------------

  // Compare the read response, unless test is masked out
  assign iRespErr =
            |(                          // Single bit result
              {((iRespExp ^ RRESP)        // Bitwise test response
                & iRespMask),             // Test mask

               (|(iUserExp ^ RUSER) & 1'b0),//RUSER[0]),

                RespIDErr}
              );


  // Ensure that test always fails if unmaksed response is X in simulation.
  // Converts multivalued logic to 0 or 1.
  always @ (iRespErr)
  begin : p_RespErrComb
    if (iRespErr == 1'b0) // Note that test will fail if iRespErr is 1'bx
      RespErr = 1'b0;
    else
      RespErr = 1'b1;
  end

 
  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign RREADY       = iRReady;
  assign SyncReq      = iSyncReq;
  assign REn          = RREADY & RVALID;
  assign DataNe       = iDataNe;
  assign PollRepeats  = VTime;  // Poll repeats and read ready time share field
  assign DataExp      = iDataExp;
  assign DataMask     = iDataMask;
  assign RespExp      = iRespExp;
  assign RespMask     = iRespMask;


endmodule

// --================================= End ===================================--




