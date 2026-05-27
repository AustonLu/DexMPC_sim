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
//  Purpose             : AXI4 File Reader Bus Slave
//
//  A behavioural component that allows designers to simulate AXI4 systems
//  quickly and efficiently by generating explicit bus transfers.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FileRdSlaveAxi4
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
  RUSER,
  BUSER,
  WUSER,

  EMIT_DATA,
  EMIT_REQ,
  EMIT_ACK,

  WAIT_DATA,
  WAIT_REQ,
  WAIT_ACK

);

  // Functional configuration parameters
  parameter AW_ARRAY_SIZE     = 4000;               // Size of AW channel array
  parameter W_ARRAY_SIZE      = 1000;               // Size of W channel array
  parameter AR_ARRAY_SIZE     = 4000;               // Size of AR channel array
  parameter R_ARRAY_SIZE      = 1000;               // Size of R channel array
  parameter AWMSG_ARRAY_SIZE  = 1000;               // Size of AW comments array
  parameter ARMSG_ARRAY_SIZE  = 1000;               // Size of AR comments array

  parameter STIM_FILE_NAME    = "filestim";         // Stimulus file name stem
  parameter MESSAGE_TAG       = "FileRdSlaveAxi4:"; // Message prefix
  parameter VERBOSE           = 0;                  // Verbosity control
  parameter USE_X             = 1;                  // Drive X on invalid signals
  parameter DATA_WIDTH        = 64;                 // Width of data bus
  parameter ID_WIDTH          = 8;                  // Width of the ID bus
  parameter EW_WIDTH          = 8;                  // Width of the Emit & wait bus
  parameter ADDR_WIDTH        = 32;                 // Addr width
  parameter OUTSTANDING_WRITES = 16;                // max outstanding writes
  parameter OUTSTANDING_READS  = 16;                // max outstanding reads

  parameter AWUSER_WIDTH       = 8;                 //AWUSER signal width
  parameter ARUSER_WIDTH       = 8;                 //ARUSER signal width
  parameter WUSER_WIDTH        = 8;                 //WUSER signal width
  parameter BUSER_WIDTH        = 8;                 //BUSER signal width
  parameter RUSER_WIDTH        = 8;                 //RWUSER signal width
  parameter REQUIRE_AW_HNDSHK  = 1;                 //Require AW Handshake
  parameter REQUIRE_AR_HNDSHK  = 1;                 // Require AR Handshake
  parameter READY_HIGH         = 0;                  // 0 = ready-on-valid behaviour, 1 = ready-high.

  // Do not change these definitions
  parameter TIMER_WIDTH     = 32;                   // Width of timer vectors
  parameter DATA_MAX    = DATA_WIDTH - 1;           // Upper bound of data vector
  parameter STRB_WIDTH  = DATA_WIDTH / 8;           // Width of strobe vector
  parameter STRB_MAX    = STRB_WIDTH - 1;           // Upper bound of strobe vector
  parameter TIMER_MAX   = TIMER_WIDTH - 1 ;         // Upper bound of timer vector
  parameter ADDR_MAX    = ADDR_WIDTH - 1 ;          // Upper bound of timer vector
  parameter ID_MAX      = ID_WIDTH - 1;
  parameter EW_MAX      = EW_WIDTH - 1;
  parameter AWUSER_MAX  = AWUSER_WIDTH - 1;
  parameter ARUSER_MAX  = ARUSER_WIDTH - 1;
  parameter WUSER_MAX   = WUSER_WIDTH - 1;
  parameter RUSER_MAX   = RUSER_WIDTH - 1;
  parameter BUSER_MAX   = BUSER_WIDTH - 1;



  // Global Signals
  input               ACLK;          // Clock input
  input               ARESETn;       // Reset async input active low

  // Write Address Channel
  input  [ADDR_MAX:0] AWADDR;        // Address (for write channel)
  input    [ID_MAX:0] AWID;          // ID (for write channel)
  input         [7:0] AWLEN;         // Burst length (for write channel)
  input         [2:0] AWSIZE;        // Burst size (for write channel)
  input         [1:0] AWBURST;       // Burst type (for write channel)
  input               AWLOCK;        // Lock type (for write channel)
  input         [3:0] AWCACHE;       // Cache type (for write channel)
  input         [2:0] AWPROT;        // Protection type (for write channel)
  input         [3:0] AWQOS;         // Quality of service (for write channel)
  input         [3:0] AWREGION;      // Region select (for write channel)
  input               AWVALID;       // Address valid (for write channel)
  output              AWREADY;       // Address ready (for write channel)

  // Write Channel
  input               WLAST;         // Write last
  input    [ID_MAX:0] WID;           // ID output
  input  [DATA_MAX:0] WDATA;         // Write data
  input  [STRB_MAX:0] WSTRB;         // Write strobes
  input               WVALID;        // Write valid
  output              WREADY;        // Write ready

  // Write Response Channel
  output        [1:0] BRESP;         // Write response
  output   [ID_MAX:0] BID;           // Bid width
  output              BVALID;        // Response valid
  input               BREADY;        // Response ready

  // Read Address Channel
  input  [ADDR_MAX:0] ARADDR;        // Address (for read channel)
  input         [7:0] ARLEN;         // Burst length (for read channel)
  input    [ID_MAX:0] ARID;          // ID (for read channel)
  input         [2:0] ARSIZE;        // Burst size (for read channel)
  input         [1:0] ARBURST;       // Burst type (for read channel)
  input               ARLOCK;        // Lock type (for read channel)
  input         [3:0] ARCACHE;       // Cache type (for read channel)
  input         [2:0] ARPROT;        // Protection type (for read channel)
  input         [3:0] ARQOS;         // Quality of service (for read channel)
  input         [3:0] ARREGION;      // Region select (for read channel)
  input               ARVALID;       // Address valid (for read channel)
  output              ARREADY;       // Address ready (for read channel)

  // Read Channel
  output              RLAST;         // Read last - not used by FRM
  output  [ID_MAX:0]  RID;           // Read ID
  output [DATA_MAX:0] RDATA;         // Read data
  output        [1:0] RRESP;         // Read response
  output              RVALID;        // Read valid
  input               RREADY;        // Read ready

  //USER Signals
  input [AWUSER_MAX:0] AWUSER;       // Write address USER signal
  input [ARUSER_MAX:0] ARUSER;       // Read address USER signal
  input [WUSER_MAX:0]  WUSER;        // Write USER signal
  output [RUSER_MAX:0] RUSER;        // Read USER signal
  output [BUSER_MAX:0] BUSER;        // Write Response user signal

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

 //USER Signals
  wire [AWUSER_MAX:0] AWUSER;       // Write address USER signal
  wire [ARUSER_MAX:0] ARUSER;       // Read address USER signal
  wire [WUSER_MAX:0]  WUSER;        // Write USER signal
  wire [RUSER_MAX:0]  RUSER;        // Read USER signal
  wire [BUSER_MAX:0]  BUSER;        // Write Response user signal

  // Read Channel
  wire              RLAST;
  wire   [ID_MAX:0] RID;
  wire [DATA_MAX:0] RDATA;
  wire        [1:0] RRESP;
  wire              RVALID;
  wire              RREADY;

  // Internal Signals
  wire        [4:0] SyncReq;      // Channel synchonisation requests
  wire              SyncGrant;    // Synchonisation grant
  wire              QValid;      // Synchonisation grant to low power channel

  wire              AWComment;    // Issue comment associated with AWVALID
  wire              ARComment;    // Issue comment associated with ARVALID

  wire       [31:0] QLineNum;     // Stimulus source line number
  wire       [31:0] ARLineNum;    // Stimulus source line number
  wire              Quit;         // Quit command found
  wire              Stop;         // Stop the simulation
  wire              Terminate;    // Terminate the simulation

  wire              WEn;          // Write error valid
  wire              WErr;

  wire              AWEn;         // Write address complete
  wire              AREn;         // Read address complete

  //Outstanding transaction counters
  wire              out_rd_reached;
  wire              out_aw_reached;
  wire              out_w_reached;

  wire              wfirst;

  //B channel enables
  wire     [ID_MAX:0] BenableID;
  wire                Benable;

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

//------------------------------------------------------------------------------
// Beginning of main code (structural)
//------------------------------------------------------------------------------

  // Synchronisation and poll controller
  FrsSync
  uFrsSync
  (

    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .SyncReq        (SyncReq),
    .Quit           (Quit),
    .QValid         (QValid),

    .SyncGrant      (SyncGrant)

  );

  // AXI AW channel
  FrsA4
    #(AW_ARRAY_SIZE, {STIM_FILE_NAME,".aw"}, MESSAGE_TAG, VERBOSE,
        TIMER_WIDTH, ID_WIDTH, OUTSTANDING_WRITES, EW_WIDTH, ADDR_WIDTH, AWUSER_WIDTH, 0,
        READY_HIGH
     )
  uFrsAW
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .AReady         (AWREADY),
    .SyncGrant      (SyncGrant),
    .out_reached    (out_aw_reached),

    .AValid         (AWVALID),
    .AAddr          (AWADDR),
    .ALen           (AWLEN),
    .AId            (AWID),
    .ASize          (AWSIZE),
    .ABurst         (AWBURST),
    .AUser          (AWUSER),
    .ALock          (AWLOCK),
    .ACache         (AWCACHE),
    .AProt          (AWPROT),
    .AQoS           (AWQOS),
    .ARegion        (AWREGION),
    .SyncReq        (SyncReq[0]),
    .AEn            (AWEn),
    .CommentReq     (AWComment),
    .LineNum        (QLineNum),
    .Quit           (Quit),
    .Terminate      (Terminate),
    .Stop           (Stop),

    .AErr           (AWErr),

    .Aebus          (AWebus),
    .Aemit          (AWemit),
    .Awbus          (AWwbus),
    .Ago            (AWgo),
    .Apause         (AWpause)

  );

  // AXI W channel
  FrsW
    #(W_ARRAY_SIZE, {STIM_FILE_NAME,".w"}, MESSAGE_TAG, VERBOSE, DATA_WIDTH,
        TIMER_WIDTH, ID_WIDTH, EW_WIDTH, WUSER_WIDTH,
        READY_HIGH)
  uFrsW
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .WREADY         (WREADY),
    .SyncGrant      (SyncGrant),

    .out_reached    (out_w_reached),
    .wfirst         (wfirst),

    .WVALID         (WVALID),
    .WDATA          (WDATA),
    .WID            (WID),
    .WSTRB          (WSTRB),
    .WUSER          (WUSER),
    .WLAST          (WLAST),
    .SyncReq        (SyncReq[1]),

    .WEn            (WEn),
    .WErr           (WErr),

    .Webus          (Webus),
    .Wemit          (Wemit),
    .Wwbus          (Wwbus),
    .Wpause         (Wpause),
    .Wgo            (Wgo)

  );


  // AXI B channel
  FrsB
    #(AW_ARRAY_SIZE, {STIM_FILE_NAME,".b"}, MESSAGE_TAG, VERBOSE, TIMER_WIDTH,
    ID_WIDTH, EW_WIDTH, OUTSTANDING_WRITES, USE_X, BUSER_WIDTH)
  uFrsB
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .BVALID         (BVALID),
    .BID            (BID),
    .BUSER          (BUSER),
    .BRESP          (BRESP),
    .SyncGrant      (SyncGrant),

    .BREADY         (BREADY),
    .SyncReq        (SyncReq[2]),

    .EnableID      (BenableID),
    .Enable        (Benable),

    .Bebus          (Bebus),
    .Bemit          (Bemit),
    .Bwbus          (Bwbus),
    .Bpause         (Bpause),
    .Bgo            (Bgo)

  );

  //Outstanding Write Transaction Counter
  FrsWTransC
    #(OUTSTANDING_WRITES, ID_WIDTH, REQUIRE_AW_HNDSHK)
  uFrsWTransC
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Bvalid         (BREADY),
    .Bready         (BVALID),

     //AW Channel
    .AWvalid        (AWVALID),
    .AWready        (AWREADY),
    .AWid           (AWID),

    //W Channel
    .Wready         (WREADY),
    .Wvalid         (WVALID),
    .Wfirst         (wfirst),
    .Wlast          (WLAST),
    .Wid            (WID),

    .out_aw_reached (out_aw_reached),
    .out_w_reached  (out_w_reached),
    .BEnableID      (BenableID),
    .BEnable        (Benable)

  );

  // AXI AR channel
  FrsA4
   #(AR_ARRAY_SIZE, {STIM_FILE_NAME,".ar"}, MESSAGE_TAG, VERBOSE,
        TIMER_WIDTH, ID_WIDTH, OUTSTANDING_READS, EW_WIDTH, ADDR_WIDTH, ARUSER_WIDTH, 1,
        READY_HIGH
     )
  uFrsAR
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .AReady         (ARREADY),
    .SyncGrant      (SyncGrant),
    .out_reached    (out_rd_reached),

    .AValid         (ARVALID),
    .AAddr          (ARADDR),
    .ALen           (ARLEN),
    .AId            (ARID),
    .ASize          (ARSIZE),
    .ABurst         (ARBURST),
    .ALock          (ARLOCK),
    .AUser          (ARUSER),
    .ACache         (ARCACHE),
    .AProt          (ARPROT),
    .AQoS           (ARQOS),
    .ARegion        (ARREGION),
    .SyncReq        (SyncReq[3]),
    .AEn            (AREn),
    .CommentReq     (ARComment),
    .LineNum        (ARLineNum),
    .Quit           (),       // Only require signal from AW channel
    .Terminate      (),       // Only require signal from AW channel
    .Stop           (),       // Only require signal from AW channel

    .AErr           (ARErr),

    .Aebus          (ARebus),
    .Aemit          (ARemit),
    .Awbus          (ARwbus),
    .Apause         (ARpause),
    .Ago            (ARgo)

  );


  // AXI R Channel
  FrsR
    #(R_ARRAY_SIZE, {STIM_FILE_NAME,".r"}, MESSAGE_TAG, VERBOSE, DATA_WIDTH, ID_WIDTH,
        TIMER_WIDTH, EW_WIDTH, OUTSTANDING_READS, USE_X, RUSER_WIDTH, REQUIRE_AR_HNDSHK)
  uFrsR
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .RID            (RID),
    .RVALID         (RVALID),
    .RDATA          (RDATA),
    .RRESP          (RRESP),
    .RUSER          (RUSER),
    .RLAST          (RLAST),
    .SyncGrant      (SyncGrant),

    .ARVALID        (ARVALID),
    .ARREADY        (ARREADY),
    .ARID           (ARID),

    .RREADY         (RREADY),
    .SyncReq        (SyncReq[4]),

    .Rebus          (Rebus),
    .Remit          (Remit),
    .Rwbus          (Rwbus),
    .Rpause         (Rpause),
    .Rgo            (Rgo)

  );

  //Outstanding Read Transaction Counter
  FrsRTransC
    #(OUTSTANDING_READS)
  uFrsRTransC
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Rvalid         (RREADY),
    .Rready         (RVALID),
    .Rlast          (RLAST),

     //AW Channel
    .ARvalid        (ARVALID),
    .ARready        (ARREADY),

    .out_rd_reached (out_rd_reached)
  );

  //Local Event controller
  FrsEvent
    #(EW_WIDTH)
  uFrsEvent
  (
    .ACLK            (ACLK),
    .ARESETn         (ARESETn),

    //AW channel signals
    .AWebus          (AWebus),
    .AWemit          (AWemit),
    .AWwbus          (AWwbus),
    .AWpause         (AWpause),
    .AWgo            (AWgo),

    //AR channel signals
    .ARebus          (ARebus),
    .ARemit          (ARemit),
    .ARwbus          (ARwbus),
    .ARpause         (ARpause),
    .ARgo            (ARgo),

    //R channel signals
    .Rebus           (Rebus),
    .Remit           (Remit),
    .Rwbus           (Rwbus),
    .Rpause          (Rpause),
    .Rgo             (Rgo),

    //W channel signals
    .Webus           (Webus),
    .Wemit           (Wemit),
    .Wwbus           (Wwbus),
    .Wpause          (Wpause),
    .Wgo             (Wgo),

    //B channel signals
    .Bebus           (Bebus),
    .Bemit           (Bemit),
    .Bwbus           (Bwbus),
    .Bpause          (Bpause),
    .Bgo             (Bgo),

    //External Emit bus
    .EMIT_ID       (EMIT_DATA),
    .EMIT_REQ        (EMIT_REQ),
    .EMIT_ACK        (EMIT_ACK),

    //External Wait bus
    .WAIT_ID       (WAIT_DATA),
    .WAIT_REQ        (WAIT_REQ),
    .WAIT_ACK        (WAIT_ACK)


);

  // Message reporter
  FrsReporter
    #(MESSAGE_TAG, VERBOSE, DATA_WIDTH)
  uFrsReporter
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .WDATA          (WDATA),
    .WSTRB          (WSTRB),

    .QValid         (QValid),
    .QLineNum       (QLineNum),
    .Quit           (Quit),
    .Terminate      (Terminate),
    .Stop           (Stop),

    .WEn            (WEn),
    .WErr           (WErr),

    .AWEn           (AWEn),
    .AWErr          (AWErr),

    .AREn           (AREn),
    .ARErr          (ARErr)

  );


  // AW channel simulation messages
  FrsMsg
    #(AWMSG_ARRAY_SIZE, {STIM_FILE_NAME,".cw"}, MESSAGE_TAG, VERBOSE)
  uFrsAWMsg
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .CommentReq     (AWComment),
    .AEn            (AWEn),
    .LineNum        (QLineNum)
  );


  // AR channel simulation messages
  FrsMsg
    #(AWMSG_ARRAY_SIZE, {STIM_FILE_NAME,".cr"}, MESSAGE_TAG, VERBOSE)
  uFrsARMsg
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .CommentReq     (ARComment),
    .AEn            (AREn),
    .LineNum        (ARLineNum)
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

