// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2003-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Date           :  2010-03-05 13:27:48 +0000 (Fri, 05 Mar 2010)
//  File Revision       : 87876
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : AXI4 File Reader Bus Master
//
//  A behavioural component that allows designers to simulate AXI4 systems
//  quickly and efficiently by generating explicit bus transfers.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FileRdMasterAxi4
(
  ACLK,
  ARESETn,

  AWADDR,
  AWLEN,
  AWSIZE,
  AWBURST,
  AWLOCK,
  AWID,
  AWCACHE,
  AWPROT,
  AWQOS,
  AWREGION,
  AWVALID,
  AWREADY,

  WLAST,
  WID,
  WDATA,
  WSTRB,
  WVALID,
  WREADY,

  BRESP,
  BID,
  BVALID,
  BREADY,

  ARADDR,
  ARLEN,
  ARSIZE,
  ARID,
  ARBURST,
  ARLOCK,
  ARCACHE,
  ARPROT,
  ARQOS,
  ARREGION,
  ARVALID,
  ARREADY,

  RLAST,
  RID,
  RDATA,
  RRESP,
  RVALID,
  RREADY,

  AWUSER,
  ARUSER,
  BUSER,
  WUSER,
  RUSER,

  CSYSREQ,
  CACTIVE,
  CSYSACK,

  EMIT_DATA,
  EMIT_REQ,
  EMIT_ACK,

  WAIT_DATA,
  WAIT_REQ,
  WAIT_ACK

);

  // Functional configuration parameters
  parameter AW_ARRAY_SIZE     = 4000;             // Size of AW channel array
  parameter W_ARRAY_SIZE      = 1000;             // Size of W channel array
  parameter AR_ARRAY_SIZE     = 4000;             // Size of AR channel array
  parameter R_ARRAY_SIZE      = 1000;             // Size of R channel array
  parameter AWMSG_ARRAY_SIZE  = 1000;             // Size of AW comments array
  parameter ARMSG_ARRAY_SIZE  = 1000;             // Size of AR comments array

  parameter MESSAGE_TAG    = "FileRdMasterAxi4:"; // Message prefix
  parameter VERBOSE        = 0;                   // Verbosity control
  parameter USE_X          = 1;                   // Drive X on invalid signals
  parameter DATA_WIDTH     = 64;                  // Width of data bus
  parameter AWUSER_WIDTH   = 8;                   // Width of the AW User bus
  parameter ARUSER_WIDTH   = 8;                   // Width of the AR User bus
  parameter WUSER_WIDTH    = 8;                   // Width of the W User bus
  parameter BUSER_WIDTH    = 8;                   // Width of the B User bus
  parameter RUSER_WIDTH    = 8;                   // Width of the R User bus
  parameter ID_WIDTH       = 8;                   // Width of the ID bus
  parameter EW_WIDTH       = 8;                   // Width of the Emit & wait bus
  parameter ADDR_WIDTH     = 32;                  // Addr width
  parameter OUTSTANDING_WRITES = 16;              // max outstanding writes
  parameter OUTSTANDING_READS  = 16;              // max outstanding reads

  parameter STIM_FILE_NAME = "undef";             // Stimulus file name

  // Do not change these definitions
  parameter TIMER_WIDTH = 32;               // Width of timer vectors
  parameter DATA_MAX    = DATA_WIDTH - 1;   // Upper bound of data vector
  parameter STRB_WIDTH  = DATA_WIDTH / 8;   // Width of strobe vector
  parameter STRB_MAX    = STRB_WIDTH - 1;   // Upper bound of strobe vector
  parameter TIMER_MAX   = TIMER_WIDTH - 1 ; // Upper bound of timer vector
  parameter ADDR_MAX    = ADDR_WIDTH - 1 ;  // Upper bound of timer vector
  parameter ID_MAX      = ID_WIDTH - 1;
  parameter EW_MAX      = EW_WIDTH - 1;
  parameter AWUSER_MAX  = AWUSER_WIDTH - 1; // Upper bound of the AW User bus
  parameter ARUSER_MAX  = ARUSER_WIDTH - 1; // Upper bound of the AR User bus
  parameter WUSER_MAX   = WUSER_WIDTH - 1;  // Upper bound of the W User bus
  parameter BUSER_MAX   = BUSER_WIDTH - 1;  // Upper bound of the B User bus
  parameter RUSER_MAX   = RUSER_WIDTH - 1;  // Upper bound of the R User bus


  // Global Signals
  input               ACLK;          // Clock input
  input               ARESETn;       // Reset async input active low

  // Write Address Channel
  output [ADDR_MAX:0] AWADDR;        // Address (for write channel)
  output   [ID_MAX:0] AWID;          // ID (for write channel)
  output        [7:0] AWLEN;         // Burst length (for write channel)
  output        [2:0] AWSIZE;        // Burst size (for write channel)
  output        [1:0] AWBURST;       // Burst type (for write channel)
  output              AWLOCK;        // Lock type (for write channel)
  output        [3:0] AWCACHE;       // Cache type (for write channel)
  output        [2:0] AWPROT;        // Protection type (for write channel)
  output        [3:0] AWQOS;         // Quality of service (for write channel)
  output        [3:0] AWREGION;      // Region select (for write channel)
  output              AWVALID;       // Address valid (for write channel)
  input               AWREADY;       // Address ready (for write channel)

  // Write Channel
  output              WLAST;         // Write last
  output   [ID_MAX:0] WID;           // ID output
  output [DATA_MAX:0] WDATA;         // Write data
  output [STRB_MAX:0] WSTRB;         // Write strobes
  output              WVALID;        // Write valid
  input               WREADY;        // Write ready

  // Write Response Channel
  input         [1:0] BRESP;         // Write response
  input    [ID_MAX:0] BID;           // Bid width
  input               BVALID;        // Response valid
  output              BREADY;        // Response ready

  // Read Address Channel
  output [ADDR_MAX:0] ARADDR;        // Address (for read channel)
  output        [7:0] ARLEN;         // Burst length (for read channel)
  output   [ID_MAX:0] ARID;          // ID (for read channel)
  output        [2:0] ARSIZE;        // Burst size (for read channel)
  output        [1:0] ARBURST;       // Burst type (for read channel)
  output              ARLOCK;        // Lock type (for read channel)
  output        [3:0] ARCACHE;       // Cache type (for read channel)
  output        [2:0] ARPROT;        // Protection type (for read channel)
  output        [3:0] ARQOS;         // Quality of service (for read channel)
  output        [3:0] ARREGION;      // Region select (for read channel)
  output              ARVALID;       // Address valid (for read channel)
  input               ARREADY;       // Address ready (for read channel)

  // Read Channel

  input               RLAST;         // Read last - not used by FRM
  input    [ID_MAX:0] RID;           // Read ID
  input  [DATA_MAX:0] RDATA;         // Read data
  input         [1:0] RRESP;         // Read response
  input               RVALID;        // Read valid
  output              RREADY;        // Read ready

  //User signals
  output [ARUSER_MAX:0] ARUSER;      //AR User signal
  output [AWUSER_MAX:0] AWUSER;      //AW User signal
  output [WUSER_MAX:0]  WUSER;       //W User signal
  input  [RUSER_MAX:0]  RUSER;       //B User signal
  input  [BUSER_MAX:0]  BUSER;       //R User signal

  // Low Power Interface
  output              CACTIVE;       // Power request
  output              CSYSACK;       // Power acknowledge
  input               CSYSREQ;       // Power enable

  output [EW_MAX:0]   EMIT_DATA;     // Emit code
  output              EMIT_REQ;      // Emit req
  input               EMIT_ACK;      // Emit ack

  input [EW_MAX:0]    WAIT_DATA;     // Wait code
  input               WAIT_REQ;      // Wait req
  output              WAIT_ACK;      // Wait ack

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  // Global Signals
  wire              ACLK;
  wire              ARESETn;

  // Write Address Channel
  wire [ADDR_MAX:0] AWADDR;
  wire   [ID_MAX:0] AWID;
  wire        [7:0] AWLEN;
  wire        [2:0] AWSIZE;
  wire        [1:0] AWBURST;
  wire              AWLOCK;
  wire        [3:0] AWCACHE;
  wire        [2:0] AWPROT;
  wire        [3:0] AWQOS;
  wire        [3:0] AWREGION;
  wire              AWVALID;
  wire              AWREADY;

  // Write Channel
  wire              WLAST;
  wire   [ID_MAX:0] WID;
  wire [DATA_MAX:0] WDATA;
  wire [STRB_MAX:0] WSTRB;
  wire              WVALID;
  wire              WREADY;

  // Write Response Channel
  wire        [1:0] BRESP;
  wire   [ID_MAX:0] BID;
  wire              BVALID;
  wire              BREADY;

  // Read Address Channel
  wire [ADDR_MAX:0] ARADDR;
  wire        [7:0] ARLEN;
  wire   [ID_MAX:0] ARID;
  wire        [2:0] ARSIZE;
  wire        [1:0] ARBURST;
  wire              ARLOCK;
  wire        [3:0] ARCACHE;
  wire        [2:0] ARPROT;
  wire        [3:0] ARQOS;
  wire        [3:0] ARREGION;
  wire              ARVALID;
  wire              ARREADY;

  // Read Channel
  wire              RLAST;
  wire   [ID_MAX:0] RID;
  wire [DATA_MAX:0] RDATA;
  wire        [1:0] RRESP;
  wire              RVALID;
  wire              RREADY;

  //User signals
  wire [ARUSER_MAX:0] ARUSER;      //AR User signal
  wire [AWUSER_MAX:0] AWUSER;      //AW User signal
  wire [WUSER_MAX:0]  WUSER;       //W User signal
  wire [RUSER_MAX:0]  RUSER;       //B User signal
  wire [BUSER_MAX:0]  BUSER;       //R User signal

  // Low Power Interface
  wire              CSYSACK;
  tri1              CSYSREQ;    // Weak pull-up in case unconnected
  wire              CACTIVE;

// Internal Signals
  wire              nLpReq;       // Enable from low power channel

  wire        [4:0] SyncReq;      // Channel synchonisation requests
  wire              SyncGrantP;   // Synchonisation grant to poll channels
  wire              SyncGrantNP;  // Synchonisation grant to non-poll channels
  wire              LpGrant;      // Synchonisation grant to low power channel
  wire              ResetSync;    // Reset timers on SYNC command

  wire              AWComment;    // Issue comment associated with AWVALID
  wire              ARComment;    // Issue comment associated with ARVALID

  wire       [31:0] QLineNum;     // Stimulus source line number
  wire              Quit;         // Quit command found
  wire              Restart;      // Restart stimulus from first command
  wire              Stop;         // Stop the simulation
  wire              Terminate;    // Terminate the simulation

  wire              BEn;          // Write response error valid
  wire              BRespErr;     // Write response mismatch
  wire       [31:0] BLineNum;     // Write response stimulus line number
  wire        [1:0] BRespExp;     // Expected write response
  wire        [1:0] BRespMask;    // Write response mask

  wire              AWEn;         // Write address complete
  wire              AREn;         // Read address complete
  wire              REn;          // Read complete
  wire              RDataErr;     // Read data error
  wire       [31:0] RLineNum;     // Read data stimulus line number
  wire [DATA_MAX:0] RDataExp;     // Expected RDATA
  wire [DATA_MAX:0] RDataMask;    // Read data mask
  wire              RRespErr;     // Read response error
  wire        [1:0] RRespExp;     // Expected read response
  wire        [1:0] RRespMask;    // Read response mask

  wire              PollReq;      // Poll requested
  wire              Polling;      // Poll in progress
  wire              PollPhaseA;   // Poll read address enable
  wire              PollTimeOut;  // Poll timed out
  wire              PollDone;     // Polling and poll complete

  wire              DataNe;       // Poll check is not equal
  wire              ResetTimer;   // Reset timer on poll iteration
  wire [TIMER_MAX:0] PollRepeats; // Number of poll iterations

  //Emit/Wait bus signals
  wire [EW_WIDTH-1:0] AWebus;     // Emit code
  wire                AWemit;     // emit
  wire [EW_WIDTH-1:0] AWwbus;     // wait code
  wire                AWgo;       // Go
  wire                AWpause;    // Pause channel

  wire [EW_WIDTH-1:0] ARebus;     // Emit code
  wire                ARemit;     // emit
  wire [EW_WIDTH-1:0] ARwbus;     // wait code
  wire                ARgo;       // Go
  wire                ARpause;    // Pause

  wire [EW_WIDTH-1:0] Rebus;      // Emit code
  wire                Remit;      // emit
  wire [EW_WIDTH-1:0] Rwbus;      // wait code
  wire                Rgo;        // Go
  wire                Rpause;     // Pause

  wire [EW_WIDTH-1:0] Webus;      // Emit code
  wire                Wemit;      // emit
  wire [EW_WIDTH-1:0] Wwbus;      // wait code
  wire                Wgo;        // Go
  wire                Wpause;     // Pause

  wire [EW_WIDTH-1:0] Bebus;      // Emit code
  wire                Bemit;      // emit
  wire [EW_WIDTH-1:0] Bwbus;      // wait code
  wire                Bgo;        // Go
  wire                Bpause;     // Pause

  wire                out_rd_reached;
  wire                out_wr_reached;


//------------------------------------------------------------------------------
// Beginning of main code (structural)
//------------------------------------------------------------------------------

  // Synchronisation and poll controller
  FrmSync
    #(TIMER_WIDTH)
  uFrmSyncPoll
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .nLpReq         (nLpReq),
    .SyncReq        (SyncReq),
    .ResetSync      (ResetSync),
    .Quit           (Quit),
    .Restart        (Restart),

    .PollRepeats    (PollRepeats),
    .PollReq        (PollReq),
    .AEn            (AREn),
    .REn            (REn),
    .DataErr        (RDataErr),
    .RespErr        (RRespErr),

    .SyncGrantP     (SyncGrantP),
    .SyncGrantNP    (SyncGrantNP),
    .LpGrant        (LpGrant),
    .Polling        (Polling),
    .PollPhaseA     (PollPhaseA),
    .PollTimeOut    (PollTimeOut),
    .PollDone       (PollDone),
    .ResetTimer     (ResetTimer)

  );


  // AXI C (low power) channel
  FrmC
  uFrmC
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .CSYSREQ        (CSYSREQ),
    .LpGrant        (LpGrant),

    .nLpReq         (nLpReq),
    .CACTIVE        (CACTIVE),
    .CSYSACK        (CSYSACK)
  );


  // AXI AW channel
  FrmA4
    #(AW_ARRAY_SIZE, {STIM_FILE_NAME, ".aw"}, MESSAGE_TAG, VERBOSE,
        USE_X, TIMER_WIDTH, ID_WIDTH, EW_WIDTH, ADDR_WIDTH, AWUSER_WIDTH, 1
     )
  uFrmAW
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .AReady         (AWREADY),
    .SyncGrant      (SyncGrantNP),
    .out_reached    (out_wr_reached),

    .Polling        (1'b0),
    .PollPhaseA     (1'b1),
    .ResetPoll      (1'b0),

    .AValid         (AWVALID),
    .AAddr          (AWADDR),
    .ALen           (AWLEN),
    .AId            (AWID),
    .ASize          (AWSIZE),
    .ABurst         (AWBURST),
    .ALock          (AWLOCK),
    .ACache         (AWCACHE),
    .AProt          (AWPROT),
    .AQoS           (AWQOS),
    .ARegion        (AWREGION),
    .AUser          (AWUSER),
    .SyncReq        (SyncReq[0]),
    .ResetSync      (ResetSync),
    .AEn            (AWEn),
    .CommentReq     (AWComment),
    .LineNum        (QLineNum),
    .Quit           (Quit),
    .Restart        (Restart),
    .Terminate      (Terminate),
    .Stop           (Stop),

    .Aebus          (AWebus),
    .Aemit          (AWemit),
    .Awbus          (AWwbus),
    .Ago            (AWgo),
    .Apause         (AWpause)

  );

  // AXI W channel
  FrmW
    #(W_ARRAY_SIZE, {STIM_FILE_NAME, ".w"}, MESSAGE_TAG, VERBOSE, DATA_WIDTH,
        USE_X, TIMER_WIDTH, ID_WIDTH, EW_WIDTH, WUSER_WIDTH)
  uFrmW
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .WREADY         (WREADY),
    .SyncGrant      (SyncGrantNP),

    .WVALID         (WVALID),
    .WDATA          (WDATA),
    .WID            (WID),
    .WSTRB          (WSTRB),
    .WLAST          (WLAST),
    .WUSER          (WUSER),
    .SyncReq        (SyncReq[1]),

    .Webus          (Webus),
    .Wemit          (Wemit),
    .Wwbus          (Wwbus),
    .Wpause         (Wpause),
    .Wgo            (Wgo)

  );


  // AXI B channel
  FrmB
    #(AW_ARRAY_SIZE, {STIM_FILE_NAME, ".b"}, MESSAGE_TAG, VERBOSE, TIMER_WIDTH,
    ID_WIDTH, EW_WIDTH, BUSER_WIDTH)
  uFrmB
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .BVALID         (BVALID),
    .BID            (BID),
    .BRESP          (BRESP),
    .BUSER          (BUSER),
    .SyncGrant      (SyncGrantNP),

    .BREADY         (BREADY),
    .SyncReq        (SyncReq[2]),

    .BEn            (BEn),
    .RespErr        (BRespErr),
    .RespExp        (BRespExp),
    .RespMask       (BRespMask),
    .LineNum        (BLineNum),

    .Bebus          (Bebus),
    .Bemit          (Bemit),
    .Bwbus          (Bwbus),
    .Bpause         (Bpause),
    .Bgo            (Bgo)

  );

  // AXI AR channel
  FrmA4
   #(AW_ARRAY_SIZE, {STIM_FILE_NAME, ".ar"}, MESSAGE_TAG, VERBOSE,
        USE_X, TIMER_WIDTH, ID_WIDTH, EW_WIDTH, ADDR_WIDTH, ARUSER_WIDTH
     )
  uFrmAR
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .AReady         (ARREADY),
    .SyncGrant      (SyncGrantP),
    .out_reached    (out_rd_reached),

    .Polling        (Polling),
    .PollPhaseA     (PollPhaseA),
    .ResetPoll      (ResetTimer),

    .AValid         (ARVALID),
    .AAddr          (ARADDR),
    .ALen           (ARLEN),
    .AId            (ARID),
    .ASize          (ARSIZE),
    .ABurst         (ARBURST),
    .ALock          (ARLOCK),
    .ACache         (ARCACHE),
    .AProt          (ARPROT),
    .AQoS           (ARQOS),
    .ARegion        (ARREGION),
    .AUser          (ARUSER),
    .SyncReq        (SyncReq[3]),
    .ResetSync      (),       // Only require signal from AW channel
    .AEn            (AREn),
    .CommentReq     (ARComment),
    .LineNum        (),       // Only require signal from AW channel
    .Quit           (),       // Only require signal from AW channel
    .Restart        (),       // Only require signal from AW channel
    .Terminate      (),       // Only require signal from AW channel
    .Stop           (),        // Only require signal from AW channel

    .Aebus          (ARebus),
    .Aemit          (ARemit),
    .Awbus          (ARwbus),
    .Apause         (ARpause),
    .Ago            (ARgo)

  );

  // AXI R Channel
  FrmR
    #(R_ARRAY_SIZE, {STIM_FILE_NAME, ".r"}, MESSAGE_TAG, VERBOSE, DATA_WIDTH,
        TIMER_WIDTH, ID_WIDTH, EW_WIDTH, RUSER_WIDTH)
  uFrmR
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .RVALID         (RVALID),
    .RDATA          (RDATA),
    .RID            (RID),
    .RRESP          (RRESP),
    .RUSER          (RUSER),
    .SyncGrant      (SyncGrantP),

    .RREADY         (RREADY),
    .SyncReq        (SyncReq[4]),
    .Polling        (Polling),
    .ResetPoll      (ResetTimer),

    .REn            (REn),
    .DataErr        (RDataErr),
    .DataExp        (RDataExp),
    .DataMask       (RDataMask),

    .RespErr        (RRespErr),
    .RespExp        (RRespExp),
    .RespMask       (RRespMask),
    .LineNum        (RLineNum),

    .PollReq        (PollReq),
    .PollRepeats    (PollRepeats),
    .DataNe         (DataNe),

    .Rebus          (Rebus),
    .Remit          (Remit),
    .Rwbus          (Rwbus),
    .Rpause         (Rpause),
    .Rgo            (Rgo)

  );


  //Outstanding Read Transaction Counter
  FrmTransC
    #(OUTSTANDING_READS)
  uFrmRTransC
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Rvalid         (RVALID),
    .Rready         (RREADY),
    .Rlast          (RLAST),

     //AR Channel
    .Avalid         (ARVALID),
    .Aready         (ARREADY),

    .out_reached    (out_rd_reached)
  );


  //Outstanding Write Transaction Counter
  FrmTransC
    #(OUTSTANDING_WRITES)
  uFrmWTransC
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Rvalid         (BVALID),
    .Rready         (BREADY),
    .Rlast          (1'b1),

     //AW Channel
    .Avalid         (AWVALID),
    .Aready         (AWREADY),

    .out_reached    (out_wr_reached)
  );


  //Local Event controller
  FrmEvent
    #(EW_WIDTH)
  uFrmEvent
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    //AW channel signals
    .AWebus         (AWebus),
    .AWemit         (AWemit),
    .AWwbus         (AWwbus),
    .AWpause        (AWpause),
    .AWgo           (AWgo),

    //AR channel signals
    .ARebus         (ARebus),
    .ARemit         (ARemit),
    .ARwbus         (ARwbus),
    .ARpause        (ARpause),
    .ARgo           (ARgo),

    //R channel signals
    .Rebus          (Rebus),
    .Remit          (Remit),
    .Rwbus          (Rwbus),
    .Rpause         (Rpause),
    .Rgo            (Rgo),

    //W channel signals
    .Webus          (Webus),
    .Wemit          (Wemit),
    .Wwbus          (Wwbus),
    .Wpause         (Wpause),
    .Wgo            (Wgo),

    //B channel signals
    .Bebus          (Bebus),
    .Bemit          (Bemit),
    .Bwbus          (Bwbus),
    .Bpause         (Bpause),
    .Bgo            (Bgo),

    //External Emit bus
    .EMIT_ID        (EMIT_DATA),
    .EMIT_REQ       (EMIT_REQ),
    .EMIT_ACK       (EMIT_ACK),

    //External Wait bus
    .WAIT_ID        (WAIT_DATA),
    .WAIT_REQ       (WAIT_REQ),
    .WAIT_ACK       (WAIT_ACK)


);

  // Message reporter
  FrmReporter
    #(MESSAGE_TAG, VERBOSE, DATA_WIDTH)
  uFrmReporter
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .BRESP          (BRESP),

    .RDATA          (RDATA),
    .RRESP          (RRESP),

    .QValid         (LpGrant),
    .QLineNum       (QLineNum),
    .Quit           (Quit),
    .Restart        (Restart),
    .Terminate      (Terminate),
    .Stop           (Stop),

    .Polling        (Polling),
    .PollTimeOut    (PollTimeOut),
    .DataNe         (DataNe),

    .BEn            (BEn),
    .BRespErr       (BRespErr),
    .BRespExp       (BRespExp),
    .BRespMask      (BRespMask),
    .BLineNum       (BLineNum),

    .REn            (REn),
    .RDataErr       (RDataErr),
    .RDataExp       (RDataExp),
    .RDataMask      (RDataMask),
    .RRespErr       (RRespErr),
    .RRespExp       (RRespExp),
    .RRespMask      (RRespMask),
    .RLineNum       (RLineNum)
  );


  // AW channel simulation messages
  FrmMsg
    #(AWMSG_ARRAY_SIZE, {STIM_FILE_NAME, ".cw"}, MESSAGE_TAG, VERBOSE)
  uFrmAWMsg
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .CommentReq     (AWComment),
    .AEn            (AWEn),
    .Polling        (Polling),
    .PollDone       (PollDone),
    .Restart        (Restart)
  );


  // AR channel simulation messages
  FrmMsg
    #(AWMSG_ARRAY_SIZE, {STIM_FILE_NAME, ".cr"}, MESSAGE_TAG, VERBOSE)
  uFrmARMsg
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .CommentReq     (ARComment),
    .AEn            (AREn),
    .Polling        (Polling),
    .PollDone       (PollDone),
    .Restart        (Restart)
  );


//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: USE_X parameter check
  //---------------------------------------------------------------------------
  // Warn if invalid signals are not being driven to 'X'. Payload signals should
  // not be relied upon unless qualified by the approptate 'valid' signal.
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_proposition
    #(2, 0, { MESSAGE_TAG,
      " Not driving invalid AXI outputs to X may give misleading results" }
    )
  frmaxiusenox
    (ARESETn, USE_X == 1);

  // OVL_ASSERT_END


  //----------------------------------------------------------------------------
  // OVL_ASSERT: TIMER_WIDTH parameter check
  //---------------------------------------------------------------------------
  // TIMER_WIDTH must be 32 bits. Report an error if this parameter is
  // overridden to any other value.
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_proposition
    #(0, 0, { MESSAGE_TAG,
      " TIMER_WIDTH parameter must be set to 32" }
    )
  frmaxitimerwidth
    (ARESETn, TIMER_WIDTH == 32);

  // OVL_ASSERT_END


`endif

endmodule

// --================================= End ===================================--

