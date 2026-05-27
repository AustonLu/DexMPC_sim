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
//  File Name           : FrsW.v,v
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

module FrsW
(
  ACLK,
  ARESETn,
  WREADY,
  SyncGrant,
  out_reached,
  wfirst,

  WVALID,
  WDATA,
  WID,
  WSTRB,
  WLAST,
  WUSER,
  SyncReq,

  WEn,
  WErr,

  Webus,
  Wemit,
  Wpause,
  Wwbus,
  Wgo

);


  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME  = "filestim.a";       // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control
  parameter DATA_WIDTH      = 64;                 // Width of data bus
  parameter TIMER_WIDTH     = 32;                 // Width of timer vectors
  parameter ID_WIDTH        = 8;                  // ID width bus
  parameter EW_WIDTH        = 8;                  // EW width bus
  parameter USER_WIDTH      = 0;                  // Width of the user signal

  // Calculated parameters - do not modify
  parameter DATA_MAX   = DATA_WIDTH - 1;  // Upper bound of data vector
  parameter STRB_WIDTH = DATA_WIDTH / 8;  // Width of strobe vector
  parameter STRB_MAX   = STRB_WIDTH - 1;  // Upper bound of strobe vector
  parameter TIMER_MAX  = TIMER_WIDTH - 1; // Upper bound of timer vector
  parameter EW_MAX     = EW_WIDTH - 1;    // Upper bound of emit & wait buses
  parameter ID_MAX     = ID_WIDTH - 1;    // Upper bound of ID bus
  parameter USER_MAX   = USER_WIDTH - 1;  // Upper bound of the USER bus

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
                          ID_PACK_WIDTH +  // ID
                          EW_WIDTH +    // emit 
                          EW_WIDTH +    // wait 
                          USER_WIDTH    // user
                          );

  parameter VECTOR_MAX = VECTOR_WIDTH - 1;// Upper bound of file vector
  parameter ID_BASE    = STRB_MAX+DATA_WIDTH+TIMER_WIDTH+64+1;
  parameter WAIT_BASE  = ID_BASE+ID_PACK_WIDTH;
  parameter EMIT_BASE  = WAIT_BASE + EW_WIDTH;
  parameter USER_BASE  = EMIT_BASE + EW_WIDTH;

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  output              WREADY;           // Write ready

  // Synchronisation
  input               SyncGrant;        // Sync granted from all channels
  
  //Outstanding transaction interface
  input               out_reached;
  output              wfirst;

// Module Outputs
  output              WEn;
  output              WErr;

  // From AXI interface
  input               WVALID;           // Write valid
  input  [DATA_MAX:0] WDATA;            // Write data
  input    [ID_MAX:0] WID;              // Write ID
  input  [STRB_MAX:0] WSTRB;            // Write strobe
  input               WLAST;            // Last write transfer
  input  [USER_MAX:0] WUSER;            // User Signal

  // Synchronisation
  output              SyncReq;          // Local sync command

  // Emit/Wait bus
  output [EW_MAX:0]   Webus;            // Emit code
  output              Wemit;            // emit code
  input [EW_MAX:0]    Wwbus;            // wait code
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
  wire                CmdReady;         // Timeout control can accept command

  // Signals from file reader
  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire  [TIMER_MAX:0] RTime;            // Write valid time

  // Internal versions of output signals
  wire   [DATA_MAX:0] iWDATA;           // internal WDATA
  reg    [DATA_MAX:0] iWSTRB_ext;       // internal WDATA
  reg    [DATA_MAX:0] WSTRB_ext;       // internal WDATA
  wire   [STRB_MAX:0] iWSTRB;           // internal WSTRB
  wire     [ID_MAX:0] iWID;             // internal WID
  wire                iWLAST;           // internal WLAST
  wire   [USER_MAX:0] iWUSER;           // internal WUSER
  wire                iWREADY;          // internal WREADY
  wire                iWREADY_next;     // internal WREADY
  reg                 iWREADY_reg;      // internal WREADY
  wire                iSyncReq;         // internal SyncReq

  //Emit go bus
  wire [EW_MAX:0]     Webus;            // Emit code
  wire                Wemit;            // emit
  wire                Wwait;            // wait
  wire                Wemit_i;          // interal emit
  wire                Wwmatch;            // wait code
  wire                Wpause;
  wire                Wgo;              // Go

  wire                SyncValid;
  reg [31:0]          counter;
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

    .ID             (WID),

    .Wait           (Wwbus),
    .Wait_valid     (Wgo),

    .FileValid      (FileValid),
    .SyncValid      (SyncValid),
    .FileData       (FileData)
  );

  assign WEn  =  WVALID && WREADY;
  
  //  ---------------------------------------------------------------------
  //  Assign signals from concatenated vector in file
  //  ---------------------------------------------------------------------
  
  assign iWID       = FileData[ID_BASE+ID_MAX:ID_BASE];
    
  assign iWSTRB                         // Strobe
    = FileData[STRB_MAX+DATA_WIDTH+TIMER_WIDTH+64:DATA_WIDTH+TIMER_WIDTH+64];

  assign iWDATA                         // Data
    = FileData[DATA_MAX+TIMER_WIDTH+64:TIMER_WIDTH+64];

  assign RTime                          // Write valid time
    = FileData[TIMER_MAX+64:64];

  assign iWLAST     = FileData[14];     // WLAST flag
  assign iWUSER     = FileData[USER_BASE+USER_MAX:USER_BASE];

  // Control signals are qualified with FileValid
  assign iSyncReq   = SyncValid & FileData[0];  // Sync command

  assign wfirst     = FileData[7];

  //Emit go bus
  assign Webus          = FileData[EMIT_BASE+EW_MAX:EMIT_BASE];
  assign Wwait          = FileData[11];
  assign Wemit_i        = (FileData[10] == 1'b1);
  assign Wemit          = FileReady & Wemit_i; 


  //  ---------------------------------------------------------------------
  //  Handshake and synchronisation logic
  //  ---------------------------------------------------------------------

  // Ready if file not empty, unless there is a sync command
  assign CmdReady = WVALID & FileValid & ~iSyncReq & ~Wwait & ~(Wpause & Wemit_i) & ~(out_reached & wfirst);

  // Fetch a new command
  assign FileReady = WEn | SyncGrant;

  //  ---------------------------------------------------------------------
  //  Response actual vs expected value comparison
  //  ---------------------------------------------------------------------

  //Extend WSTRB
  always @(WSTRB or iWSTRB) begin
      for (counter = 0; counter < (STRB_WIDTH); counter = counter + 1) begin
              WSTRB_ext[(counter *8)]   = WSTRB[counter];
              WSTRB_ext[(counter *8)+1] = WSTRB[counter];
              WSTRB_ext[(counter *8)+2] = WSTRB[counter];
              WSTRB_ext[(counter *8)+3] = WSTRB[counter];
              WSTRB_ext[(counter *8)+4] = WSTRB[counter];
              WSTRB_ext[(counter *8)+5] = WSTRB[counter];
              WSTRB_ext[(counter *8)+6] = WSTRB[counter];
              WSTRB_ext[(counter *8)+7] = WSTRB[counter];
              iWSTRB_ext[(counter *8)]   = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+1] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+2] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+3] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+4] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+5] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+6] = iWSTRB[counter];
              iWSTRB_ext[(counter *8)+7] = iWSTRB[counter];
      end
  end

  
  // Compare the address channel fields, unless test is masked out
  // ID is not checked in here as it is implicit in the transaction look up
  assign iMatchErr =
              (iWLAST != WLAST) |
              ((iWUSER != WUSER) & 1'b0) | //WUSER[0]) |
              ((iWDATA & iWSTRB_ext) != (WDATA & iWSTRB_ext)) |
              (WSTRB != iWSTRB);
              
  // Ensure that test always fails if unmaksed response is X in simulation.
  // Converts multivalued logic to 0 or 1.
  always @ (iMatchErr)
  begin : p_RespErrComb
    if (iMatchErr == 1'b0) // Note that test will fail if iMatchErr is 1'bx
      MatchErr = 1'b0;
    else
      MatchErr = 1'b1;
  end

  assign WErr      = MatchErr | (WVALID & !FileValid);

  // Error Reporting
  always @(posedge ACLK) begin
      
      if (WVALID & ~FileValid) begin
             $display("%t %s No available transactions found for ID %0d", $time, MESSAGE_TAG, WID); 
      end
      
      if (WEn && FileValid && MatchErr) begin

              if (iWLAST !== WLAST) begin
                  $display("%t %s WLAST incorrect. Expected %d found %d", $time, MESSAGE_TAG, iWLAST, WLAST); 
              end

              if (iWUSER !== WUSER) begin
                  $display("%t %s User incorrect. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, iWUSER, WUSER); 
              end

              if (iWSTRB !== WSTRB) begin
                  $display("%t %s Strobes incorrect. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, iWSTRB, WSTRB); 
              end

              if (((iWDATA & iWSTRB_ext) != (WDATA & iWSTRB_ext))) begin
                  $display("%t %s Strobed data incorrect. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, (iWDATA & iWSTRB_ext), (WDATA & iWSTRB_ext)); 
                  $display("%t %s Unstrobed data. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, (iWDATA), (WDATA)); 
                  $display("%t %s Strobe. Expected 0x%x found 0x%x", $time, MESSAGE_TAG, (iWSTRB_ext), (iWSTRB_ext)); 
              end

      end        
  end
  //  ---------------------------------------------------------------------
  //  Timing generation
  //  ---------------------------------------------------------------------
  assign    next_last_valid = WVALID & ~WREADY;

  always @(posedge ACLK or negedge ARESETn)
    begin
        if (!ARESETn) begin
            last_valid <= 1'b0;
        end else begin
            last_valid <= next_last_valid;
        end
    end
 
  assign new_transaction = WVALID & ~last_valid;

  FrsTimeOut
    #(TIMER_WIDTH)
  uTimeOut
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .Start          (new_transaction),
    .InputReady     (CmdReady),        
    .OutputReady    (iWREADY),
    .Time           (RTime)
  );

  //  ---------------------------------------------------------------------
  //  Drive output with internal signal
  //  ---------------------------------------------------------------------

  assign WREADY = iWREADY;
  assign SyncReq = iSyncReq;

endmodule

// --================================= End ===================================--


