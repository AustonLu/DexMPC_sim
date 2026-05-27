//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2004-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 104297
// File Date           :  2011-02-11 14:32:58 +0000 (Fri, 11 Feb 2011)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose             : File reader master B group interface
//
//                        Reads write completion channel and timing information
//                        from a text file. generates BREADY signal and
//                        tests transfers received on the B group of
//                        the AXI interface.
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ps


module FrmB
(
  ACLK,
  ARESETn,

  BVALID,
  BRESP,
  BID,
  BUSER,
  SyncGrant,

  BREADY,
  SyncReq,

  BEn,

  RespErr,
  RespExp,
  RespMask,

  LineNum,

  Bebus,
  Bemit,
  Bpause,
  Bwbus,
  Bgo

);

  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME        = "undef";            // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // Width of ID vectors
  parameter EW_WIDTH        = 8;                  // Width of Emit/Wait vectors
  parameter USER_WIDTH      = 8;                  // Width of the User Signal


  // Calculated parameters - do not modify
  parameter EW_MAX          = EW_WIDTH-1;
  parameter USER_MAX        = USER_WIDTH-1;

  parameter TIMER_MAX   = TIMER_WIDTH - 1 ;   // Upper bound of timer vector

  parameter ID_WIDTH_RND   = ((ID_WIDTH / 4) * 4);
  parameter ID_PACK_WIDTH  = (ID_WIDTH_RND == ID_WIDTH) ?
                               ID_WIDTH_RND : ID_WIDTH_RND + 4;

  parameter EW_WIDTH_RND   = ((EW_WIDTH / 4) * 4);
  parameter EW_PACK_WIDTH  = (EW_WIDTH_RND == EW_WIDTH) ?
                               EW_WIDTH_RND : EW_WIDTH_RND + 4;

  parameter USER_WIDTH_RND  = ((USER_WIDTH / 4) * 4);
  parameter USER_PACK_WIDTH = (USER_WIDTH_RND == USER_WIDTH) ?
                               USER_WIDTH_RND : USER_WIDTH_RND + 4;

  parameter VECTOR_WIDTH = (
                          32 +          // command word,
                          32 +          // line number
                          TIMER_WIDTH +  // BRWait
                          ID_PACK_WIDTH +
                          EW_PACK_WIDTH +
                          EW_PACK_WIDTH +
                          USER_PACK_WIDTH
                          );



  parameter ID_BASE    = 64 + TIMER_WIDTH;
  parameter WAIT_BASE  = ID_BASE + ID_PACK_WIDTH;
  parameter WAIT_TOP   = WAIT_BASE + EW_WIDTH - 1;
  parameter EMIT_BASE  = WAIT_BASE + EW_PACK_WIDTH;
  parameter EMIT_TOP   = EMIT_BASE + EW_WIDTH - 1;
  parameter USER_BASE  = EMIT_BASE + EW_PACK_WIDTH;
  parameter VECTOR_MAX = VECTOR_WIDTH - 1 ;


// Module Inputs

  // From AXI interface
  input                ACLK;             // Clock input
  input                ARESETn;          // Reset async input active low

  input                BVALID;           // Write response valid
  input          [1:0] BRESP;            // Write response
  input [ID_WIDTH-1:0] BID;              // Write ID
  input [USER_MAX:0]   BUSER;            // Write response user signals

  // Synchronisation
  input                SyncGrant;        // Sync granted from all channels

// Module Outputs

  // To AXI interface
  output              BREADY;           // Write response ready

  // Synchronisation
  output              SyncReq;          // Local sync command

  // Reporting
  output              BEn;              // Error signal is valid
  output              RespErr;          // Read response mismatch
  output        [1:0] RespExp;          // Expected write reponse
  output        [1:0] RespMask;         // Write reponse mask
  output       [31:0] LineNum;          // Stimulus source line number

  // Emit/Wait bus
  output   [EW_MAX:0] Bebus;            // Emit code
  output              Bemit;            // emit code
  input               Bpause;           // buffer full warning
  input    [EW_MAX:0] Bwbus;            // Wait code
  input               Bgo;              // Go code


//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  // From AXI interface
  wire                ACLK;
  wire                ARESETn;
  wire                BVALID;
  wire          [1:0] BRESP;
  wire [ID_WIDTH-1:0] BID;
  wire [USER_MAX:0]   BUSER;

  // Synchronisation
  wire                SyncGrant;

  // To AXI interface
  wire                BREADY;

  // Synchronisation
  wire                SyncReq;

  // Reporting
  wire                BEn;
  reg                 RespErr;
  wire                RespIDErr;        // Read response ID mismatch
  wire          [1:0] RespExp;
  wire          [1:0] RespMask;
  wire         [31:0] LineNum;

// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty
  wire                FileValidPoll;        // File not empty
  wire                FileReady;        // Fetch new command from file

  // Handshake between sync control and timeout control
  wire                CmdValid;         // Valid transfer command
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire  [TIMER_MAX:0] VTime;            // Write response ready time
  wire                ResetSync;        // Reset timer on true SYNC command
  wire                Restart;          // Restart to file reader

  // Internal versions of output signals
  wire                iSyncReq;         // Internal SyncReq
  wire   [USER_MAX:0] iUserExp;         // Internal User signals
  wire                iRespErr;         // Internal RespErr (multivalue logic)
  wire          [1:0] iRespExp;         // Internal RespExp
  wire          [1:0] iRespMask;        // Internal RespMask

  wire                ID_error;         // Tried to receive a non-enabled ID
  wire [TIMER_MAX:0]  Time;             // Time vector to the fileReader

  wire                Bemit_i;
  wire                Bwait;

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
    .FileValidPoll  (FileValidPoll),
    .SyncValid      (SyncValid),
    .FileData       (FileData),

    .Wait           (Bwbus),
    .Wait_valid     (Bgo),

    .ID             (BID)
  );

  //Detect Failed identifiers
  assign RespIDErr = BVALID & ~FileValid;

  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated vector in file
  //  ---------------------------------------------------------------------

  assign VTime                          // Write response ready time
    = FileData[TIMER_MAX+64:64];

  assign LineNum    = FileData[63:32];  // Stimulus file line number

  assign iRespMask  = FileData[17:16];  // Write response mask
  assign iRespExp   = FileData[15:14];  // Expected write response
  assign iUserExp   = FileData[USER_BASE+USER_MAX:USER_BASE]; //Expected User Signal

  // Control signals are qualified with FileValid
  assign Restart    = SyncValid & FileData[8];  // Restart
  assign ResetSync  = SyncValid & FileData[1];  // Reset timer
  assign iSyncReq   = SyncValid & FileData[0];  // Sync command

  assign Bebus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];
  assign Bemit_i        = (FileData[10] == 1'b1);
  assign Bemit          = Bemit_i & CmdReady;
  assign Bwait          = FileData[11];

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  assign CmdValid = FileValid & ~iSyncReq & ~Bwait & ~(Bemit_i & Bpause);

  // Fetch a new command
  assign FileReady =
            (
              (CmdReady &
                  ~iSyncReq &
                     ~Bwait &
                       ~(Bemit_i & Bpause))    // not a SYNC command and ready
                | SyncGrant             // sync granted by all channels
            );


  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------

  FrmTimeOut
    #(TIMER_WIDTH)
  uTimeOut
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Sync           (ResetSync),
    .InputValid     (CmdValid),
    .OutputReady    (BVALID),
    .VTime          (VTime),

    .InputReady     (CmdReady),
    .OutputValid    (BREADY)
  );

  //  ---------------------------------------------------------------------
  //  Response actual vs expected value comparison
  //  ---------------------------------------------------------------------

  // Compare the write response, unless test is masked out
  assign iRespErr =
            |(                          // Single bit result
              {((iRespExp ^ BRESP)      // Bitwise test response
                & iRespMask),           // Test mask

                |(iUserExp ^ BUSER),    //User signal

                RespIDErr}              // An ID Error implies a protocol violation
                                        // This term is here in case OVLs are not enabled
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

  assign SyncReq  = iSyncReq;
  assign BEn      = CmdReady;
  assign RespExp  = iRespExp;
  assign RespMask = iRespMask;


endmodule

// --================================= End ===================================--

