// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//     (C) COPYRIGHT 2010-2012 ARM Limited
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 102866
//  File Date           :  2011-01-21 16:57:15 +0000 (Fri, 21 Jan 2011)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : File reader slave A group interface
//
//                        Reads address channel and timing information
//                        from a text file and converts them transfers on
//                        the AW or AR group of the AXI4 interface.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrsA4
(
  ACLK,
  ARESETn,
  AReady,
  SyncGrant,
  out_reached,

  AValid,
  AAddr,
  ALen,
  AId,
  ASize,
  ABurst,
  ALock,
  AUser,
  ACache,
  AProt,
  AQoS,
  ARegion,

  SyncReq,

  AEn,
  AErr,

  CommentReq,
  LineNum,
  Quit,
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
  parameter STIM_FILE_NAME  = "filestim.a";       // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdSlaveAxi:";  // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // Width of ID bus
  parameter OUTSTD_ADDR     = 16;                 // Oustanding addresses
  parameter EW_WIDTH        = 8;                  // Event bus width
  parameter ADDR_WIDTH      = 32;                 // Addr bus width
  parameter USER_WIDTH      = 0;                  // User signal width
  parameter EMITONSYNC      = 0;                  // EMIT ON SYNCs
  parameter READY_HIGH      = 0;                  // 0 = ready-on-valid behaviour, 1 = ready-high.

  // Calculated parameters - do not modify
  parameter TIMER_MAX       = TIMER_WIDTH - 1 ;   // Upper bound of timer vector
  parameter ID_MAX          = ID_WIDTH - 1;
  parameter ADDR_MAX        = ADDR_WIDTH - 1;
  parameter EW_MAX          = EW_WIDTH - 1;
  parameter USER_MAX        = USER_WIDTH - 1;
  parameter EXTENSION_WIDTH = 12;                 // Extended command width
  parameter EXTENSION_MAX   = EXTENSION_WIDTH - 1;

  parameter ID_WIDTH_RND   = ((ID_WIDTH / 4) * 4);
  parameter ID_PACK_WIDTH  = (ID_WIDTH_RND == ID_WIDTH) ?
                               ID_WIDTH_RND : ID_WIDTH_RND + 4;

  parameter ADDR_WIDTH_RND  = ((ADDR_WIDTH / 4) * 4);
  parameter ADDR_PACK_WIDTH = (ADDR_WIDTH_RND == ADDR_WIDTH) ?
                               ADDR_WIDTH_RND : ADDR_WIDTH_RND + 4;

  parameter EW_WIDTH_RND   = ((EW_WIDTH / 4) * 4);
  parameter EW_PACK_WIDTH  = (EW_WIDTH_RND == EW_WIDTH) ?
                               EW_WIDTH_RND : EW_WIDTH_RND + 4;

  parameter USER_WIDTH_RND  = ((USER_WIDTH / 4) * 4);
  parameter USER_PACK_WIDTH = (USER_WIDTH_RND == USER_WIDTH) ?
                               USER_WIDTH_RND : USER_WIDTH_RND + 4;

  parameter VECTOR_WIDTH = (                 // Length of file vector
                          32 +               // command word,
                          32 +               // line number
                          TIMER_WIDTH +      // AVWait
                          ADDR_PACK_WIDTH +  // Address
                          ID_PACK_WIDTH +    // Id width
                          EW_PACK_WIDTH +    // Event
                          EW_PACK_WIDTH +    // Event
                          USER_PACK_WIDTH +  // User
			  EXTENSION_WIDTH    // Extended command
                          ) ;

  parameter VECTOR_MAX = VECTOR_WIDTH - 1 ;       // Upper bound of file vector
  parameter ADDR_BASE = 64 + TIMER_WIDTH;
  parameter ID_BASE = TIMER_WIDTH + 64 + ADDR_PACK_WIDTH;
  parameter WAIT_BASE = ID_BASE + ID_PACK_WIDTH;
  parameter EMIT_BASE = WAIT_BASE + EW_PACK_WIDTH;
  parameter USER_BASE = EMIT_BASE + EW_PACK_WIDTH;
  parameter EXTENSION_BASE = USER_BASE + USER_PACK_WIDTH;

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  output              AReady;           // Address ready

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels
  input               out_reached;    //Indicates transfer complete

// Module Outputs

  // To AXI interface
  input               AValid;           // Address valid
  input  [ADDR_MAX:0] AAddr;            // Address
  input         [7:0] ALen;             // Burst length
  input    [ID_MAX:0] AId;              // ID width
  input         [2:0] ASize;            // Burst size
  input         [1:0] ABurst;           // Burst type
  input               ALock;            // Lock type
  input  [USER_MAX:0] AUser;            // User Signal
  input         [3:0] ACache;           // Cache type
  input         [2:0] AProt;            // Protection type
  input         [3:0] AQoS;             // Quality of service
  input         [3:0] ARegion;          // Region select

  // Synchronisation
  output              SyncReq;          // Local sync command

  // Error logging signals
  output              AEn;              // Address phase completed
  output              AErr;             // Address phase error

  // To external comment publishing module
  output              CommentReq;       // Request a comment

  // To FRM reporter
  output       [31:0] LineNum;          // Stimulus source line number
  output              Quit;             // Quit command found
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

  // To AXI interface
  wire                AValid;
  wire   [ADDR_MAX:0] AAddr;
  wire          [7:0] ALen;
  wire     [ID_MAX:0] AId;
  wire          [2:0] ASize;
  wire          [1:0] ABurst;
  wire                ALock;
  wire   [USER_MAX:0] AUser;
  wire          [3:0] ACache;
  wire          [2:0] AProt;
  wire          [3:0] AQoS;
  wire          [3:0] ARegion;

  // Synchronisation
  wire                SyncReq;

  // Poll
  wire                AEn;
  wire                AErr;

  // To external comment publishing module
  wire                CommentReq;

  // To FRM reporter
  wire         [31:0] LineNum;
  wire                Quit;
  wire                Stop;
  wire                Terminate;

// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty

  // Handshake between sync control and timeout control
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire  [TIMER_MAX:0] RTime;            // Address ready time

  // Internal versions of output signals
  wire                iSyncReq;         // internal SyncReq

  wire                iAReady;          // internal AReady
  wire   [ADDR_MAX:0] iAAddr;           // internal AAddr
  wire          [7:0] iALen;            // internal ALen
  wire          [2:0] iASize;           // internal ASize
  wire          [1:0] iABurst;          // internal ABurst
  wire     [ID_MAX:0] iAId;             // internal ID
  wire                iALock;           // internal ALock
  wire   [USER_MAX:0] iAUser;           // internal AUser
  wire          [3:0] iACache;          // internal ACache
  wire          [2:0] iAProt;           // internal AProt
  wire          [3:0] iAQoS;            // internal AQoS
  wire          [3:0] iARegion;         // internal ARegion

  wire                iCommentReq;      // internal CommentReq

  //Emit go bus
  wire     [EW_MAX:0] Aebus;            // Emit code
  wire                Aemit;            // emit
  wire                Aemit_i;          // emit internal
  wire                Await;            // wait
  wire                Apause;           // pause channel
  wire                Ago;              // input bus is valid

  //Tracker logic
  wire                vec_valid;        //signal valid
  wire [31:0]         Time;             //Time

  //Result comparison logic
  wire                iMatchErr;
  reg                 MatchErr;

  //Last valid registers
  reg                 last_valid;
  wire                next_last_valid;
  wire                new_transaction;


//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  File reader
  //  ---------------------------------------------------------------------
 FrsFileReaderS
    // Positionally mappd module parameters
    #(FILE_ARRAY_SIZE,
      VECTOR_WIDTH,
      STIM_FILE_NAME,
      MESSAGE_TAG,
      VERBOSE,
      16'hD000,                          // File ID for W channel
      WAIT_BASE,
      EW_WIDTH,
      ID_BASE,
      ID_WIDTH
    )
  uReader
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .FileReady      (FileReady),

    .ID             (AId),

    .Wait           (Awbus),
    .Wait_valid     (Ago),

    .FileValid      (FileValid),
    .SyncValid      (SyncValid),
    .FileData       (FileData)
  );

  //  ---------------------------------------------------------------------
  //  Decode vector information from data
  //  ---------------------------------------------------------------------

  assign iAAddr         = FileData[ADDR_MAX+ADDR_BASE:ADDR_BASE];  // Address
  assign RTime          = FileData[TIMER_MAX+64:64]; // AVALID time

  assign LineNum        = FileData[63:32]; // Stimulus file line number

  assign iAId           = FileData[ID_BASE+ID_MAX:ID_BASE]; // ID width
  assign iAProt         = FileData[31:29];        // Protection field
  assign iACache        = FileData[EXTENSION_BASE+3:EXTENSION_BASE]; // Cache field
  assign iABurst        = FileData[28:27];        // Burst field
  assign iALock         = FileData[24:24];        // Lock field
  assign iAUser         = FileData[USER_BASE+USER_MAX:USER_BASE]; // Lock field
  assign iASize         = FileData[23:21];        // Size field
  assign iALen          = FileData[20:13];        // Length field
  assign iAQoS          = FileData[EXTENSION_BASE+7:EXTENSION_BASE+4]; // QoS field
  assign iARegion       = FileData[EXTENSION_BASE+11:EXTENSION_BASE+8]; // Region field
  assign iCommentReq    = FileData[9];            // Request comment

  //  ---------------------------------------------------------------------
  //  Flow control signals
  //  ---------------------------------------------------------------------

  // Control signals are qualified with FileValid
  assign Terminate      = SyncValid & FileData[7];  // Terminate
  assign Stop           = SyncValid & FileData[6];  // Stop
  assign Quit           = SyncValid & FileData[5];  // Quit
  assign iSyncReq       = SyncValid & FileData[0];  // Sync command

  //  ---------------------------------------------------------------------
  //  Emit Logic
  //  ---------------------------------------------------------------------

  assign Aebus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];
  assign Aemit_i        = (FileData[10] == 1'b1);
  assign Await          = FileData[11];
  assign Aemit          = Aemit_i & (AEn | (SyncGrant && EMITONSYNC));

  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  assign CmdReady = (AValid || READY_HIGH)  & FileValid  & ~iSyncReq & ~Await & ~(Apause & Aemit_i) & ~out_reached;

  assign FileReady = AEn | (SyncGrant & iSyncReq);

  //  ---------------------------------------------------------------------
  //  Response actual vs expected value comparison
  //  ---------------------------------------------------------------------

  // Compare the address channel fields, unless test is masked out
  assign iMatchErr =
              ~((iAAddr == AAddr) &
              (iALen == ALen) &
              (iAId == AId) &
              (iASize == ASize) &
              (iABurst == ABurst) &
              (iALock == ALock) &
              (iACache == ACache) &
              (iAProt == AProt) &
              (iAQoS == AQoS) &
              (iARegion == ARegion) &
              (iAUser == AUser));

  // Ensure that test always fails if unmasked response is X in simulation.
  // Converts multivalued logic to 0 or 1.
  always @ (iMatchErr)
  begin : p_RespErrComb
    if (iMatchErr == 1'b0) // Note that test will fail if iMatchErr is 1'bx
      MatchErr = 1'b0;
    else
      MatchErr = 1'b1;
  end

  // Error Reporting
  always @(posedge ACLK) begin

      if (ARESETn) begin
         if (AValid & ~FileValid) begin
             $display("%t %s No available transactions found for ID %0d", $time, MESSAGE_TAG, AId);
             $finish;
         end

         if (AEn && FileValid && MatchErr) begin

              if (iAAddr !== AAddr) begin
                  $display("%t %s Address incorrect. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, iAAddr, AAddr);
              end

              if (iALen !== ALen) begin
                  $display("%t %s Length incorrect. Expected %d found %d", $time, MESSAGE_TAG, iALen + 1, ALen + 1);
              end

              if (iAId !== AId) begin
                  $display("%t %s Id incorrect. Expected %d found %d", $time, MESSAGE_TAG, iAId, AId);
              end

              if (iASize !== ASize) begin
                  $display("%t %s Size incorrect. Expected %d found %d", $time, MESSAGE_TAG, iASize, ASize);
              end

              if (iABurst !== ABurst) begin
                  $display("%t %s Burst incorrect. Expected %d found %d", $time, MESSAGE_TAG, iABurst, ABurst);
              end

              if (iALock !== ALock) begin
                  $display("%t %s Lock incorrect. Expected %d found %d", $time, MESSAGE_TAG, iALock, ALock);
              end

              if (iACache !== ACache) begin
                  $display("%t %s Cache incorrect. Expected %d found %d", $time, MESSAGE_TAG, iACache, ACache);
              end

              if (iAProt !== AProt) begin
                  $display("%t %s Prot incorrect. Expected %d found %d", $time, MESSAGE_TAG, iAProt, AProt);
              end

              if (iAQoS !== AQoS) begin
                  $display("%t %s QoS incorrect. Expected %d found %d", $time, MESSAGE_TAG, iAQoS, AQoS);
              end

              if (iARegion !== ARegion) begin
                  $display("%t %s Region incorrect. Expected %d found %d", $time, MESSAGE_TAG, iARegion, ARegion);
              end

              if (iAUser !== AUser) begin
                  $display("%t %s User incorrect. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, iAUser, AUser);
              end
         end
     end
  end

  assign AEn       = AValid && AReady;
  assign AErr      = MatchErr | (AValid & ~FileValid);

  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------
  assign    next_last_valid = AValid & ~AReady;

  always @(posedge ACLK or negedge ARESETn)
    begin
        if (!ARESETn) begin
            last_valid <= 1'b0;
        end else begin
            last_valid <= next_last_valid;
        end
    end

  assign new_transaction = AValid & ~last_valid;

  FrsTimeOut
    #(TIMER_WIDTH)
  uTimeOut
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Start          (new_transaction),
    .InputReady     (CmdReady),
    .Time           (RTime),

    .OutputReady    (iAReady)
  );

  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign CommentReq = iCommentReq & AEn;
  assign SyncReq    = iSyncReq;
  assign AReady     = iAReady;

endmodule

// --================================= End ===================================--

