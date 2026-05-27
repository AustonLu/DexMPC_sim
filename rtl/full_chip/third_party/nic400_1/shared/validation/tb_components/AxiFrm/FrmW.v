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
//  File Name           : FrmW.v,v
//  File Revision       : 1.14
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master W group interface
//
//                        Reads write channel and timing information
//                        from a text file and converts them transfers on
//                        the W group of the AXI interface.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmW
(
  ACLK,
  ARESETn,

  WREADY,
  SyncGrant,

  WVALID,
  WDATA,
  WID,
  WSTRB,
  WLAST,
  WUSER,
  SyncReq,

  Webus,
  Wemit,
  Wpause,
  Wwbus,
  Wgo

);


  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME        = "undef";            // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter DATA_WIDTH      = 64;                 // Width of data bus
  parameter USE_X           = 1;                  // Drive X on invalid signals
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // ID width bus
  parameter EW_WIDTH        = 8;                  // EW width bus
  parameter USER_WIDTH      = 8;                  // User width

  // Calculated parameters - do not modify
  parameter DATA_MAX   = DATA_WIDTH - 1;  // Upper bound of data vector
  parameter STRB_WIDTH = DATA_WIDTH / 8;  // Width of strobe vector
  parameter STRB_MAX   = STRB_WIDTH - 1;  // Upper bound of strobe vector
  parameter TIMER_MAX  = TIMER_WIDTH - 1; // Upper bound of timer vector
  parameter EW_MAX     = EW_WIDTH - 1;    // Upper bound of emit & wait buses
  parameter ID_MAX     = ID_WIDTH - 1;    // Upper bound of ID bus
  parameter USER_MAX   = USER_WIDTH - 1;  // Upper bound of User bus

  parameter ID_PACK_WIDTH = (ID_WIDTH <= 4) ? 4 :
                            (ID_WIDTH > 4 & ID_WIDTH <= 8) ? 8 :
                            (ID_WIDTH > 8 & ID_WIDTH <= 12) ? 12 :
                            (ID_WIDTH > 12 & ID_WIDTH <= 16) ? 16 :
                            (ID_WIDTH > 16 & ID_WIDTH <= 20) ? 20 :
                            (ID_WIDTH > 20 & ID_WIDTH <= 24) ? 24 :
                            (ID_WIDTH > 24 & ID_WIDTH <= 28) ? 28 : 32;

  parameter VECTOR_WIDTH = (            // Length of file vector
                          32 +          // cmd word,
                          32 +          // line number
                          TIMER_WIDTH + // WVWait
                          DATA_WIDTH +  // Data
                          STRB_WIDTH +  // Mask
                          ID_PACK_WIDTH +    //ID
                          EW_WIDTH +    //emit 
                          EW_WIDTH +    //wait 
                          USER_WIDTH
                          );

  parameter VECTOR_MAX = VECTOR_WIDTH - 1;// Upper bound of file vector
  parameter ID_BASE    = STRB_MAX  + DATA_WIDTH+TIMER_WIDTH+64+1;
  parameter WAIT_BASE  = ID_BASE   + ID_PACK_WIDTH;
  parameter EMIT_BASE  = WAIT_BASE + EW_WIDTH;
  parameter USER_BASE  = EMIT_BASE + EW_WIDTH;

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  input               WREADY;           // Write ready

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels

// Module Outputs

  // To AXI interface
  output              WVALID;           // Write valid
  output [DATA_MAX:0] WDATA;            // Write data
  output   [ID_MAX:0] WID;              // Write ID
  output [STRB_MAX:0] WSTRB;            // Write strobe
  output              WLAST;            // Last write transfer
  output [USER_MAX:0] WUSER;            // User width

  // Synchronisation
  output              SyncReq;          // Local sync command

  // Emit/Wait bus
  output [EW_MAX:0]   Webus;            // Emit code
  output              Wemit;            // emit code
  input  [EW_MAX:0]   Wwbus;            // wait code
  input               Wpause;           
  input               Wgo;              // Go code

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  // From AXI interface
  wire                ACLK;
  wire                ARESETn;
  wire                WREADY;

  // Synchronisation
  wire                SyncReq;


  // To AXI interface
  wire                WVALID;
  wire   [DATA_MAX:0] WDATA;
  wire     [ID_MAX:0] WID;
  wire   [STRB_MAX:0] WSTRB;
  wire                WLAST;
  wire   [USER_MAX:0] WUSER;

  // Synchronisation
  wire                SyncGrant;


// Internal Signals

  // Handshake between file reader and sync control
  wire                FileValid;        // File not empty
  wire                FileReady;        // Fetch new command from file

  // Handshake between sync control and timeout control
  wire                CmdValid;         // Valid transfer command
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire  [TIMER_MAX:0] VTime;            // Write valid time
  wire                ResetSync;        // Reset timers on true SYNC command
  wire                Restart;          // Restart to file reader

  // Internal versions of output signals
  wire                iWVALID;          // internal WVALID
  wire   [DATA_MAX:0] iWDATA;           // internal WDATA
  wire   [STRB_MAX:0] iWSTRB;           // internal WSTRB
  wire     [ID_MAX:0] iWID;             // internal WID
  wire                iWLAST;           // internal WLAST
  wire   [USER_MAX:0] iWUSER;           // internal WUSER
  wire                iSyncReq;         // internal SyncReq

  //Emit go bus
  wire [EW_MAX:0]     Webus;            // Emit code
  wire                Wemit;            // emit
  wire                Wwait;            // wait
  wire                Wemit_i;          // interal emit
  wire                Wwmatch;            // wait code
  wire                Wpause;
  wire                Wgo;              // Go

  wire                timer_reset;


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
    .Restart        (Restart),

    .Wait           (Wwbus),
    .Wait_valid     (Wgo),

    .FileValid      (FileValid),
    .FileData       (FileData)
  );

  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated vector in file
  //  ---------------------------------------------------------------------
  
  assign iWID       = FileData[ID_BASE+ID_MAX:ID_BASE];
    
  assign iWSTRB                         // Strobe
    = FileData[STRB_MAX+DATA_WIDTH+TIMER_WIDTH+64:DATA_WIDTH+TIMER_WIDTH+64];

  assign iWDATA                         // Data
    = FileData[DATA_MAX+TIMER_WIDTH+64:TIMER_WIDTH+64];

  assign VTime                          // Write valid time
    = FileData[TIMER_MAX+64:64];

  assign iWLAST     = FileData[14];     // WLAST flag
  assign iWUSER     = FileData[USER_BASE+USER_MAX:USER_BASE];  // WUSER data

  // Control signals are qualified with FileValid
  assign Restart    = FileValid & FileData[8];  // Restart
  assign ResetSync  = FileValid & FileData[1];  // Reset timer
  assign iSyncReq   = FileValid & FileData[0];  // Sync command

  //Emit go bus
  assign Webus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];

  assign Wemit_i        = (FileData[10] == 1'b1);
  assign Wwait          = FileData[11];
  assign Wemit          = FileReady & Wemit_i; 


  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Output is valid if file not empty, unless there is a sync command
  assign CmdValid = FileValid  & ~iSyncReq & ~Wwait & ~(Wpause & Wemit_i);

  // Fetch a new command
  assign FileReady =
            (
              (CmdReady 
                   & ~iSyncReq
                       & ~Wwait
                           & ~(Wpause & Wemit_i))    // not a SYNC command and ready
                |  SyncGrant            // sync granted by all channels
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

    .Sync           (timer_reset),
    .InputValid     (CmdValid),
    .OutputReady    (WREADY),
    .VTime          (VTime),

    .InputReady     (CmdReady),
    .OutputValid    (iWVALID)
  );

  assign timer_reset = ResetSync;

  //  ---------------------------------------------------------------------
  //  Combinatorially drive AXI to X when invalid
  //  ---------------------------------------------------------------------

  assign WDATA  = iWVALID ? iWDATA  : {DATA_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign WSTRB  = iWVALID ? iWSTRB  : {STRB_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign WID    = iWVALID ? iWID    :   {ID_WIDTH{USE_X ? 1'bx : 1'b0}};
  assign WLAST  = iWVALID ? iWLAST  :            {USE_X ? 1'bx : 1'b0};
  assign WUSER  = iWVALID ? iWUSER  : {USER_WIDTH{USE_X ? 1'bx : 1'b0}};


  //  ---------------------------------------------------------------------
  //  Drive output with internal signal
  //  ---------------------------------------------------------------------

  assign WVALID   = iWVALID;
  assign SyncReq  = iSyncReq;


endmodule

// --================================= End ===================================--

