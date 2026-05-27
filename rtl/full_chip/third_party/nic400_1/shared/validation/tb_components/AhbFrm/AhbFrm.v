//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2001-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 150003
// File Date           :  2013-05-09 16:14:54 +0100 (Thu, 09 May 2013)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose : The AHB-Lite file reader bus master reads in a file and decodes
//            it into AHB-Lite (with ARM11 extensions) bus transfers.
//------------------------------------------------------------------------------

module AhbFrm (

  // AHB ports
  HCLK,
  HRESETn,
  HREADY,
  HRESP,
  HRDATA,
  HTRANS,
  HBURST,
  HPROT,
  HSIZE,
  HWRITE,
  HMASTLOCK,
  HADDR,
  HWDATA,

  // Event handling ports
  WAIT_REQ,
  WAIT_ACK,
  WAIT_DATA,
  EMIT_REQ,
  EMIT_ACK,
  EMIT_DATA
  );

  parameter  DATA_WIDTH    = 32;
  parameter  DATA_MAX      = DATA_WIDTH - 1;
  parameter  STRB_WIDTH    = DATA_WIDTH/8;
  parameter  STRB_MAX      = STRB_WIDTH - 1;
  parameter  InputFileName = "filestim.m3d";   // stimulus data file name
  parameter  MessageTag    = "AhbFrm:";    // tag on each FileReader message
  parameter  StimArraySize = 14000; // array size, should be large enough to hold
                                   //  entire stimulus data file
  parameter  ADDR_WIDTH    = 32;
  parameter  ADDR_MAX      = ADDR_WIDTH - 1;
  parameter  EW_WIDTH      = 32;
  parameter  EW_MAX        = EW_WIDTH - 1;
  // system ports
  input          HCLK;      // system clock
  input          HRESETn;   // system reset

  // AHB ports
  input          HREADY;    // slave ready signal
  input          HRESP;     // slave response
  input  [DATA_MAX:0]  HRDATA;    // data from slave to master
  output [1:0]   HTRANS;    // transfer type
  output [2:0]   HBURST;    // burst type
  output [3:0]   HPROT;     // protection (HPROT[5:4] unconnected for non-ARM11)
  output [2:0]   HSIZE;     // transfer size
  output         HWRITE;    // transfer direction
  output         HMASTLOCK; // transfer is a locked transfer
  output [ADDR_MAX:0]  HADDR;     // transfer address
  output [DATA_MAX:0]  HWDATA;    // data from master to slave

  // Event handling ports
  input          WAIT_REQ;  // input request line
  output         WAIT_ACK;  // input acknowledge line
  input  [EW_MAX:0]  WAIT_DATA;   // input ID bus
  output         EMIT_REQ;  // output request line
  input          EMIT_ACK;  // output acknowledge line
  output [EW_MAX:0]  EMIT_DATA;   // output ID bus

//------------------------------------------------------------------------------
  // Constant declarations
//------------------------------------------------------------------------------

  `define UNDEF8        8'hx
  `define LOW32         {32{1'b0}}


  // Sign-on banner
  `define SIGN_ON_MSG1 " ************************************************"
  `define SIGN_ON_MSG2 " **** ARM AHB File Reader Master"
  `define SIGN_ON_MSG3 " **** (C) ARM Limited 2001-2008"
  `define SIGN_ON_MSG4 " ************************************************"

  // Information message
  `define OPENFILE_MSG "%t %s Reading stimulus file %s"

  // Error messages
  `define SLAVE_ERR_MSG1 "\n %t %s #ERROR# Expected Okay response was not received from Slave."
  `define SLAVE_ERR_MSG2 "\n %t %s #ERROR# Expected Error response was not received from Slave."
  `define SLAVE_XFAIL_MSG1 "\n %t %s #ERROR# Slave responded with an unexpected XFAIL."
  `define SLAVE_XFAIL_MSG2 "\n %t %s #ERROR# Expected XFAIL response was not received from Slave."
  `define DATA_ERR_MSG "\n %t %s #ERROR# Data received did not match expectation."
  `define POLL_ERR_MSG "\n %t %s #ERROR# Poll command timed out after %0d repeats."
  `define CMD_MSG "\n %t %s #ERROR# Unknown command value in file."
  `define EMIT_MSG "\n %t %s #ERROR# Event not released as dealing with previous EMIT command."

  `define ADDRESS_MSG     " Address       = %h"
  `define ACTUAL_DATA     " Actual data   = %h"
  `define EXPECTED_DATA   " Expected data = %h"
  `define DATA_MASK       " Mask          = %h"
  `define LINE_NUM        " Stimulus Line:  %0d"
  `define SIZE_MSG        " Size          = %0d bytes"
  // Inent messages because of the length of the time variable
  `define INDENT "                     "

  // End of Simulation Summary messages
  `define QUIT_MSG        "Simulation Quit requested."
  `define END_MSG         "Stimulus completed."

  `define SUMMARY_HEADER  " ******* SIMULATION SUMMARY *******"
  `define SUMMARY_FOOTER  " **********************************"
  `define SUMMARY_DATA    " ** Data Mismatches     : %0d"
  `define SUMMARY_POLL    " ** Poll TimeOuts       : %0d"
  `define SUMMARY_SLAVE   " ** Response Mismatches : %0d"


  // HTRANS signal encoding
  `define TRN_IDLE      2'b00   // Idle transfer
  `define TRN_BUSY      2'b01   // Busy transfer
  `define TRN_NONSEQ    2'b10   // Non-sequential
  `define TRN_SEQ       2'b11   // Sequential

  // HSIZE signal encoding
  `define SZ_BYTE       3'b000  //  8-bit access
  `define SZ_HALF       3'b001  // 16-bit access
  `define SZ_WORD       3'b010  // 32-bit access
  `define SZ_DWORD      3'b011  // 64-bit access
  `define SZ_128        3'b100  // 128-bit access
  `define SZ_256        3'b101  // 256-bit access

  // HBURST signal encoding
  `define BUR_SINGLE    3'b000  // Single
  `define BUR_INCR      3'b001  // Incrementing
  `define BUR_WRAP4     3'b010  // 4-beat wrap
  `define BUR_INCR4     3'b011  // 4-beat incr
  `define BUR_WRAP8     3'b100  // 8-beat wrap
  `define BUR_INCR8     3'b101  // 8-beat incr
  `define BUR_WRAP16    3'b110  // 16-beat wrap
  `define BUR_INCR16    3'b111  // 16-beat incr

  // Wrap boundary limits
  `define NOBOUND       4'b0000
  `define BOUND4        4'b0001
  `define BOUND8        4'b0010
  `define BOUND16       4'b0011
  `define BOUND32       4'b0100
  `define BOUND64       4'b0101
  `define BOUND128      4'b0110
  `define BOUND256      4'b0111
  `define BOUND512      4'b1000
  // Commands
  `define CMD_WRITE     8'b00000000
  `define CMD_READ      8'b00010000
  `define CMD_SEQ       8'b00100000
  `define CMD_BUSY      8'b00110000
  `define CMD_IDLE      8'b01000000
  `define CMD_POLL      8'b01010000
  `define CMD_LOOP      8'b01100000
  `define CMD_COMM      8'b01110000
  `define CMD_QUIT      8'b10000000
  `define CMD_EMIT      8'b10010000
  `define CMD_WAIT      8'b10100000

  // Error responses
  `define ERR_OKAY      2'b00
  `define ERR_CONT      2'b01
  `define ERR_CANC      2'b10
  `define ERR_XFAIL     2'b11


  // Poll command states
  `define ST_NO_POLL    2'b00
  `define ST_POLL_READ  2'b01
  `define ST_POLL_TEST  2'b10

  // EMIT command states
  `define ST_EVENT_IDLE     2'b00
  `define ST_EVENT_REQHIGH  2'b01
  `define ST_EVENT_REQLOW   2'b10

   // WAIT command states
  `define ST_WAIT_IDLE      3'b000
  `define ST_WAIT_ACKHIGH   3'b001
  `define ST_WAIT_RESUME    3'b010
  `define ST_WAIT_CLEAR     3'b011
  `define ST_WAIT_NOWAIT    3'b100


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  // AHB Input/Output signals
  wire        HCLK;                // system clock
  wire        HRESETn;             // system reset
  wire        HREADY;              // slave ready signal
  wire        HRESP;               // slave response
  wire [DATA_MAX:0] HRDATA;              // data from slave to master
  wire [1:0]  HTRANS;              // transfer type
  wire [2:0]  HBURST;              // burst type
  wire [3:0]  HPROT;               // protection
  wire [2:0]  HSIZE;               // transfer size
  wire        HWRITE;              // transfer direction
  wire        HMASTLOCK;           // transfer is a locked transfer
  wire [ADDR_MAX:0] HADDR;               // transfer address
  wire [DATA_MAX:0] HWDATA;              // data from master to slave

  // Event going out
  reg         EMIT_REQ;        // output request line
  wire        EMIT_ACK;        // output acknowledge line
  reg    [EW_MAX:0] EMIT_DATA;         // output ID bus

  // Event coming in
  wire        WAIT_REQ;        // input request line
  reg         WAIT_ACK;        // input acknowledge line
  wire   [EW_MAX:0] WAIT_DATA;         // input ID bus

  // File read control
  wire        RdNext;              // ready to read next command indicator

  // Signals from file data
  reg  [7:0]  Cmd;                 // current command buffer
  reg  [63:0] Addr;                // address read from stimulus file
  reg  [DATA_MAX:0] Data;                // data read from stimulus file
  reg  [DATA_MAX:0] DataMask;            // mask read from stimulus file
  reg  [DATA_MAX:0] DataTmp;                // temp data read from stimulus file
  reg  [DATA_MAX:0] DataMaskTmp;            // temp mask read from stimulus file
  reg  [2:0]  Burst;               // burst value read from stimulus file
  reg  [2:0]  Size;                // size value read from stimulus file
  reg         Lock;                // lock value read from stimulus file
  reg  [5:0]  Prot;                // prot value read from stimulus file
  reg         Dir;                 // idle direction flag from stimulus file
  reg  [1:0]  ErrResp;             // error response from stimulus file
  reg         WaitRdy;             // wait field flag from stimulus file
  reg  [STRB_MAX:0]  Bstrb;               // bstrb value read from stimulus file
  reg         Unalign;             // unalign value read from stimulus file
  reg         UseBstrbFlag;        // indicates whether bstrb value should be
                                     // used

  // Registered signals
  reg  [7:0]  CmdReg;              // regstered version of the current command
                                     // buffer
  reg  [DATA_MAX:0] DataReg;             // regstered version of the stimulus file
                                     // data
  reg  [DATA_MAX:0] MaskReg;             // regstered version of the stimulus file
                                     // data mask
  reg  [2:0]  SizeReg;             // regstered version of the stimulus file
                                     // size value
  reg  [1:0]  ErrRespReg;          // regstered version of the error response
                                     // from stimulus file

  // Address calculation signals
  wire        NonZero;             // flag to indicate haddr needs incrementing
  reg  [5:0]  AddValue;            // value to be added to the current address
  reg  [4:0]  AlignMask;           // mask to align incremented address correctly
  reg  [3:0]  Boundary;            // limit of wrapping addresses
  wire [ADDR_MAX:0] IncrAddr;            // new address value
  reg  [ADDR_MAX:0] WrappedAddr;         // new wrapped address
  wire [ADDR_MAX:0] AlignedAddr;         // new aligned address
  wire [4:0]  AlignedAddrL;        // address lsb alignment values

  // Error signal
  wire        DataError;           // flag to indicate read data is incorrect

  // Internal signals
  wire [ADDR_MAX:0] iHADDR;              // internal version of HADDR output
  wire [DATA_MAX:0] iHWDATA;             // internal version of HWDATA output
  reg  [1:0]  iHTRANS;             // internal version of HTRANS output
  wire        iHWRITE;             // internal version of HWRITE output

  // Registered internal signals
  reg  [ADDR_MAX:0] HAddrReg;            // registered version of iHADDR
  reg  [DATA_MAX:0] HWdataReg;           // registered version of iHWDATA
  reg  [1:0]  HTransReg;           // registered version of iHTRANS
  reg         HWriteReg;           // registered version of iHWRITE

  // Poll command state machine
  reg  [1:0]  NextPollState;       // next poll state
  reg  [1:0]  PollState;           // current poll state

  // Compared read data
  wire [DATA_MAX:0] Mask;                // data mask accounting for Bstrb value
  reg  [DATA_MAX:0] DataCompare;         // comparison register for read data
  reg               Datax;

  // Poll timeout signals
  reg  [31:0] TimeOut;             // timeout value for poll
  reg  [31:0] TimeOutReg;          // registered timeout value
  reg  [31:0] PollCount;           // poll counter
  reg  [31:0] NextPollCount;       // next poll count

  // Read command signals
  reg         UseBstrbTmp;         // flag indicates that Bstrb should be read
                                     //  from stimulus file
  integer     StimLineTmp;         // temporary stimulus line counter
  reg [31:0]  LoopNumber;          // count looping commands
  integer     i;                   // loop counter

  // Registered versions of signals for EMIT and WAIT commands
  reg  [ADDR_MAX:0] iHADDR_Reg;          // Registered version of internal HADDR
  reg         HLOCKReg;            // Registered version of HLOCK

  // WAIT command registers
  wire            Waiting;             // WAIT state flag
  reg      [31:0] WaitID;              // ID of WAIT command from stimulus file
  wire            WaitDone;            // WAIT finished flag
  reg             WaitBusy;            // WAIT after busy flag

//------------------------------------------------------------------------------
// START OF BEHAVIOURAL CODE
//------------------------------------------------------------------------------

  // Stimulus reading signals
  reg  [31:0] FileArray [0:StimArraySize];  // stimulus file data
  reg  [31:0] FileArrayTmp;                 // current value in stimulus file
  integer     ArrayPt;                      // pointer to stimulus file data

  integer     StimLineNum;                  // input stimulus line number
                                              // counter
  integer     StimLineReg;                  // stim line counter registered into
                                              // data phase

  // Stimulus end signals
  reg         StimEnd;                      // signals end of input stimulus file
  reg         StimEndData;                  // StimEnd registered into data phase
  reg         StimEndDataReg;               // registered StimEndData

  reg         SkipSeq;                      // signals to skip end of sequence
                                              // upon Error

  reg         BannerDone;                   // true if sign-on banner has been
                                              // displayed

  // Error counters for end of simulation summary
  integer     DataErrCnt;                   // read data errors
  integer     SlaveRespCnt;                 // unexpected slave ERROR responses
  integer     PollErrCnt;                   // Poll timeouts

  reg  [7:0]  CommWordsHex [0:79];          // comment array
  reg  [4:0]  CommWordNum;                  // number of words in comment
                                              // command
  reg         Quit;

  integer     data_width = DATA_WIDTH;
  wire        wait_in_progress;
  reg [EW_MAX:0] last_wait_id;
  reg          last_wait_seen;
  wire         nxt_last_wait_seen;
  wire         emit_pause;
  wire [31:0]  next_vector;


//------------------------------------------------------------------------------
// Print Comment command string to simulation window
//------------------------------------------------------------------------------
// The fileconv script converts the comment into ASCII hex values this
//  task prints the string from the CommWordsHex array.

  task SimulationComment;                           // no input or return values
     integer index;                                           // character index
    begin
     $write   ("%t %s ", $time, MessageTag);

      // loop through the characters in the array and print
      for (index = 0; index < (CommWordNum*4); index = index + 1)

        // do not print ASCII NULL character
        if (CommWordsHex[index] !== 8'b00000000)

          // print each character
          $write("%s", CommWordsHex[index]);

      // end the line
      $display("");
    end
  endtask

//------------------------------------------------------------------------------
// Open Command File
//------------------------------------------------------------------------------
// Reads the command file into an array. This process is only executed once.

  initial
    begin : p_OpenFileBhav

      // report the stimulus file name to the simulation environment
      $display (`OPENFILE_MSG, $time, MessageTag, InputFileName);
      $readmemh(InputFileName, FileArray);

    end


//------------------------------------------------------------------------------
// Sign-on banner
//------------------------------------------------------------------------------
// Writes a message to the simulation environment on exit from reset.
  always @ (posedge HCLK or negedge HRESETn)
    begin : p_BannerBhav
      if (HRESETn !== 1'b1)
       BannerDone <= 1'b0;
      else
        if (BannerDone !== 1'b1)
          begin
            BannerDone <= 1'b1;
            $display ("%t %s", $time, MessageTag);
            //$write   (`INDENT);
            $display (`SIGN_ON_MSG1);
            //$write   (`INDENT);
            $display (`SIGN_ON_MSG2);
            //$write   (`INDENT);
            $display (`SIGN_ON_MSG3);
            //$write   (`INDENT);
            $display (`SIGN_ON_MSG4);
          end
    end


//------------------------------------------------------------------------------
// Report errors to simulation environment
//------------------------------------------------------------------------------
// This process responds to error signals with an acknowledge signal and
//  reports the error to the simulation environment

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_ReportErrorsBhav
      if (HRESETn !== 1'b1)
        begin
          DataErrCnt = 0;
          SlaveRespCnt = 0;
          PollErrCnt = 0;
        end
      else
        if (HREADY === 1'b1 && SkipSeq !== 1'b1)            // transfer complete

          // report an unexpected error response from slave
          if ((HRESP == 1'b1) && (ErrRespReg === `ERR_OKAY))
            begin
              $display (`SLAVE_ERR_MSG1, $time, MessageTag);
              //$write   (`INDENT);
              $display (`LINE_NUM, StimLineReg);
              //$write   (`INDENT);
              $display (`ADDRESS_MSG, HAddrReg);
              SlaveRespCnt = SlaveRespCnt + 1;  // increment slave error counter
            end

          // report expected error response missing from slave
          else if ((HRESP == 1'b0) &&
                   ((ErrRespReg === `ERR_CONT) || (ErrRespReg === `ERR_CANC)))
            begin
              $display (`SLAVE_ERR_MSG2, $time, MessageTag);
              //$write   (`INDENT);
              $display (`LINE_NUM, StimLineReg);
              //$write   (`INDENT);
              $display (`ADDRESS_MSG, HAddrReg);
              SlaveRespCnt = SlaveRespCnt + 1;  // increment slave error counter
            end

          // report poll timeout error
          else if ( (DataError === 1'b1) &&  (PollCount === 32'h00000001))
            begin
              $display (`POLL_ERR_MSG, $time, MessageTag, TimeOutReg);
              //$write   (`INDENT);
              $display (`LINE_NUM, StimLineReg);
              //$write   (`INDENT);
              $display (`ADDRESS_MSG, HAddrReg);
              //$write   (`INDENT);
              $display (`SIZE_MSG, 1<<SizeReg);

              //$write   (`INDENT);
              $display (`ACTUAL_DATA, HRDATA);
              //$write   (`INDENT);
              $display (`EXPECTED_DATA, DataReg);
              //$write   (`INDENT);
              $display (`DATA_MASK, MaskReg);

              PollErrCnt = PollErrCnt + 1;       // increment poll error counter
            end // if (DataError === 1'b1 && PollCount === 32'h00000001)

          // report data error
          else if ((DataError === 1'b1) && (PollState === `ST_NO_POLL))
            begin
              $display (`DATA_ERR_MSG, $time, MessageTag);
              //$write   (`INDENT);
              $display (`LINE_NUM, StimLineReg);
              //$write   (`INDENT);
              $display (`ADDRESS_MSG, HAddrReg);
              //$write   (`INDENT);
              $display (`SIZE_MSG, 1<<SizeReg);

              //$write   (`INDENT);
              $display (`ACTUAL_DATA, HRDATA);
              //$write   (`INDENT);
              $display (`EXPECTED_DATA, DataReg);
              //$write   (`INDENT);
              $display (`DATA_MASK, MaskReg);

              DataErrCnt = DataErrCnt + 1;       // increment data error counter
            end // if (DataError === 1'b1 && PollState === `ST_NO_POLL)
    end // block: p_ReportErrorsBhav


//------------------------------------------------------------------------------
// Read Command
//------------------------------------------------------------------------------
// Reads next command from the array, if the previous one has completed,
// indicated by RdNext. If a looped command or wait is being executed, then the
// command is not updated, if no more commands are available in the stimulus,
// default signal values are used.
// Control information that must be preserved is registered by this procedure.

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_CmdReadBhav

      if (HRESETn !== 1'b1)
        begin
          // signal reset values
          Cmd           <= `CMD_IDLE;
          Addr          <= {64{1'b0}};
          Data          <= {DATA_WIDTH{1'b0}};
          DataMask      <= {DATA_WIDTH{1'b1}};
          Size          <= `SZ_BYTE;
          Burst         <= `BUR_SINGLE;
          Prot          <= 6'b000000;
          Dir           <= 1'b0;
          Lock          <= 1'b0;
          Bstrb         <= {STRB_WIDTH{1'b0}};
          UseBstrbFlag  <= 1'b1;
          Unalign       <= 1'b0;

          ErrResp       <= 2'b00;
          SkipSeq       <= 1'b0;
          StimEnd       <= 1'b0;

          LoopNumber    <= {32{1'b0}};
          TimeOut       <= {32{1'b0}};
          StimLineNum   <= 0;
          StimLineTmp    = 0;

          ArrayPt        = 1'b0;            // Go to beginning of command array
          FileArrayTmp  <= {32{1'b0}};

          // Initialise regs for dealing with emit instruction
          EMIT_REQ      <= 1'b0;
          EMIT_DATA     <= {EW_WIDTH{1'b0}};

          // Initialise regs for dealing with wait instruction
          WaitID        <= {32{1'b0}};

        end // if (HRESETn !== 1'b1)
      else  // HCLK rising edge
        begin

          SkipSeq <= 1'b0; // sequence skip complete

          // copy signal values into variables
          StimLineTmp = StimLineNum;
          UseBstrbTmp = UseBstrbFlag;

          if (RdNext === 1'b1 && Waiting === 1'b0 && emit_pause === 1'b0) // ready for next command
            begin

              // If ErrCanc is set, an error received and no new burst
              //  starting, skip the remaining SEQ, BUSY, EMIT, WAIT
              // and Comment commands in this burst.
              if ((HRESP == 1'b1) &&
                  (HREADY === 1'b1) &&
                  (ErrRespReg === `ERR_CANC) &&
                  ((Cmd === `CMD_SEQ) || (Cmd === `CMD_BUSY)))
                begin

                  SkipSeq <= 1'b1;     // signals that sequence is being skipped

                  // cancel current looping command
                  LoopNumber = {32{1'b0}};

                  FileArrayTmp = FileArray [ArrayPt];

                  // skip all commands in the current burst
                  while ((FileArrayTmp [31:24] === `CMD_SEQ)  ||
                         (FileArrayTmp [31:24] === `CMD_BUSY) ||
                         (FileArrayTmp [31:24] === `CMD_LOOP) ||
                         (FileArrayTmp [31:24] === `CMD_EMIT) ||
                         (FileArrayTmp [31:24] === `CMD_WAIT) ||
                         (FileArrayTmp [31:24] === `CMD_COMM))
                    begin

                      // increment stimulus line counter
                      StimLineTmp = StimLineTmp + FileArrayTmp [5:0];

                      if (FileArrayTmp [31:24] === `CMD_SEQ)         // skip SEQ
                        if (FileArrayTmp [6] === 1'b1)
                          // skip Bstrb field if present
                          ArrayPt = ArrayPt + 6;
                        else
                          ArrayPt = ArrayPt + 5;

                      else if (FileArrayTmp [31:24] === `CMD_BUSY)  // skip BUSY
                        if (FileArrayTmp [6] === 1'b1)
                          // skip Bstrb field if present
                          ArrayPt = ArrayPt + 2;
                        else
                          ArrayPt = ArrayPt + 1;

                      else if (FileArrayTmp [31:24] === `CMD_LOOP)  // skip LOOP
                        ArrayPt = ArrayPt + 2;

                      else if (FileArrayTmp [31:24] === `CMD_EMIT)  // skip EMIT
                        ArrayPt = ArrayPt + 2;

                      else if (FileArrayTmp [31:24] === `CMD_WAIT)  // skip WAIT
                        ArrayPt = ArrayPt + 2;

                      else
                        begin                            // skip Comment command
                          ArrayPt = ArrayPt + 1;
                          FileArrayTmp = FileArray [ArrayPt];
                          ArrayPt = ArrayPt + FileArrayTmp [4:0];
                          ArrayPt = ArrayPt + 1;
                        end

                      // Read a fresh word from the stimulus array
                      FileArrayTmp = FileArray [ArrayPt];

                    end // while loop
                end // if (HRESP...

              // Read a fresh word from the stimulus array
              FileArrayTmp = FileArray [ArrayPt];

              // Comment command prints a string to the simulation window in
              //  zero simulation time.
              while (FileArrayTmp [31:24] === `CMD_COMM &&        // comment cmd
                     LoopNumber === `LOW32)       // current command not looping
                begin

                  // increment stimulus line counter
                  StimLineTmp = StimLineTmp + FileArrayTmp [5:0];

                  ArrayPt = ArrayPt + 1;

                  // get number of words
                  FileArrayTmp = FileArray [ArrayPt];
                  CommWordNum  = FileArrayTmp [4:0];

                  ArrayPt = ArrayPt + 1;
                  FileArrayTmp = FileArray [ArrayPt];

                  // read in lines occupied by comment data
                  for (i = 0; i < CommWordNum; i = i + 1)
                    begin
                      // store each character individually
                      CommWordsHex[(i * 4 + 0)] = FileArrayTmp [31:24];
                      CommWordsHex[(i * 4 + 1)] = FileArrayTmp [23:16];
                      CommWordsHex[(i * 4 + 2)] = FileArrayTmp [15:8];
                      CommWordsHex[(i * 4 + 3)] = FileArrayTmp [7:0];

                      ArrayPt = ArrayPt + 1;
                      FileArrayTmp = FileArray [ArrayPt];
                    end

                  // call task to display the comment
                  SimulationComment;

                end // while loop

                if (LoopNumber !== `LOW32)
                  // A command is currently looping
                  LoopNumber = (LoopNumber - 1'b1);

                else

                  begin

                    FileArrayTmp = FileArray [ArrayPt];

                    // If an event is encountered set the event register and
                    // increment the array pointer round the instruction
                    // so that the next instruction is simultaneously
                    // decoded by the FRBM
                    if (FileArrayTmp [31:24] === `CMD_EMIT)
                      begin
                            EMIT_REQ       <= ~EMIT_REQ;
                            StimLineTmp    = StimLineTmp + FileArrayTmp [5:0];
                            ArrayPt        = ArrayPt + 1;
                            EMIT_DATA     <= FileArray [ArrayPt];
                            ArrayPt        = ArrayPt + 1;
                            FileArrayTmp   = FileArray [ArrayPt];
                      end // CMD_EMIT


                    case (FileArrayTmp [31:24])

                      `CMD_WRITE : begin
                        // Get each write command field
                        Cmd           <= FileArrayTmp [31:24];
                        Size          <= FileArrayTmp [23:21];
                        Burst         <= FileArrayTmp [20:18];
                        Prot          <= FileArrayTmp [17:12];
                        Lock          <= FileArrayTmp [11];
                        ErrResp       <= FileArrayTmp [9:8];
                        Unalign       <= FileArrayTmp [7];
                        UseBstrbTmp    = FileArrayTmp [6];
                        StimLineTmp    = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt        = ArrayPt + 1;
			if (ADDR_WIDTH > 32)
			begin
                          Addr[63:32] <= FileArray [ArrayPt];
                          ArrayPt      = ArrayPt + 1;
			end
                        Addr[31:0]    <= FileArray [ArrayPt];
                        ArrayPt        = ArrayPt + 1;
                        DataTmp        = 0;

                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataTmp      = DataTmp | (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end
                        Data          <= DataTmp;

                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp    = FileArray [ArrayPt];
                          Bstrb          <= FileArrayTmp [STRB_MAX:0];
                          ArrayPt         = ArrayPt + 1;
                        end

                      end // case: `CMD_WRITE

                      `CMD_READ : begin
                        Cmd           <= FileArrayTmp [31:24];
                        Size          <= FileArrayTmp [23:21];
                        Burst         <= FileArrayTmp [20:18];
                        Prot          <= FileArrayTmp [17:12];
                        Lock          <= FileArrayTmp [11];
                        ErrResp       <= FileArrayTmp [9:8];
                        Unalign       <= FileArrayTmp [7];
                        UseBstrbTmp    = FileArrayTmp [6];
                        StimLineTmp    = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt        = ArrayPt + 1;
			if (ADDR_WIDTH > 32)
			begin
                          Addr[63:32] <= FileArray [ArrayPt];
                          ArrayPt      = ArrayPt + 1;
			end
                        Addr[31:0]    <= FileArray [ArrayPt];
                        ArrayPt        = ArrayPt + 1;

                        DataTmp        = 0;
                        DataMaskTmp    = 0;
                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataTmp      = DataTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end

                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataMaskTmp  = DataMaskTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end
                        Data        <= DataTmp;
                        DataMask    <= DataMaskTmp;

                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp  = FileArray [ArrayPt];
                          Bstrb        <= FileArrayTmp [STRB_MAX:0];
                          ArrayPt       = (ArrayPt + 1);
                        end
                      end // case: `CMD_READ

                      `CMD_SEQ : begin
                        // Get each sequential command field
                        Cmd     <= FileArrayTmp [31:24];
                        ErrResp <= FileArrayTmp [9:8];
                        UseBstrbTmp = FileArrayTmp [6];
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt  = ArrayPt + 1;

                        DataTmp        = 0;
                        DataMaskTmp    = 0;
                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataTmp      = DataTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end

                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataMaskTmp  = DataMaskTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end
                        Data        <= DataTmp;
                        DataMask    <= DataMaskTmp;

                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp  = FileArray [ArrayPt];
                          Bstrb        <= FileArrayTmp [STRB_MAX:0];
                          ArrayPt       = ArrayPt + 1;
                        end
                      end // case: `CMD_SEQ

                      `CMD_BUSY : begin
                        // Set busy command field
                        Cmd        <= FileArrayTmp [31:24];
                        WaitRdy    <= FileArrayTmp [8];
                        UseBstrbTmp = FileArrayTmp [6];
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                        ErrResp <= `ERR_OKAY;
                        ArrayPt  = ArrayPt + 1;
                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp  = FileArray [ArrayPt];
                          Bstrb        <= FileArrayTmp [STRB_MAX:0];
                          ArrayPt       = (ArrayPt + 1);
                        end
                        // Check if the following command is a WAIT
                        // and if so set the WaitRdy field so that
                        // it is read at the correct time. The actual WaitRdy
                        // value is registered for use when resuming from wait
                        FileArrayTmp  = FileArray [ArrayPt];
                        if (FileArrayTmp [31:24] === `CMD_WAIT)
                          begin
                            WaitRdy    <= 1'b0;
                            WaitBusy   <= 1'b1;
                            // If a WAIT comes at the start of a locked transfer
                            // preceding cycle must be repeated to ensure
                            // WAIT is entered at the correct time
                            if ((Cmd === `CMD_WRITE || Cmd === `CMD_READ)
                                && HMASTLOCK === 1'b1 && HLOCKReg === 1'b0)
                              LoopNumber = { {31{1'b0}}, 1'b1 };
                          end
                      end // case: `CMD_BUSY

                      `CMD_IDLE : begin
                        // Get each idle command field
                        Cmd        <= FileArrayTmp [31:24];
                        Size       <= FileArrayTmp [23:21];
                        Burst      <= FileArrayTmp [20:18];
                        Prot       <= FileArrayTmp [17:12];
                        Lock       <= FileArrayTmp [11];
                        Dir        <= FileArrayTmp [10];
                        WaitRdy    <= FileArrayTmp [8];
                        Unalign    <= FileArrayTmp [7];
                        UseBstrbTmp = FileArrayTmp [6];
                        ErrResp    <= `ERR_OKAY;
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt     = ArrayPt + 1;
			if (ADDR_WIDTH > 32)
			begin
                          Addr[63:32] <= FileArray [ArrayPt];
                          ArrayPt      = ArrayPt + 1;
			end
                        Addr[31:0] <= FileArray [ArrayPt];
                        ArrayPt     = ArrayPt + 1;
                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp  = FileArray [ArrayPt];
                          Bstrb        <= FileArrayTmp  [STRB_MAX:0];
                          ArrayPt       = ArrayPt + 1;
                        end
                        // Check if the following command is a WAIT
                        // and if so set the WaitRdy field so that
                        // it is read at the correct time. The actual WaitRdy
                        // value is registered for use when resuming from wait
                        FileArrayTmp  = FileArray [ArrayPt];
                        if (FileArrayTmp [31:24] === `CMD_WAIT)
                          begin
                            WaitRdy    <= 1'b0;
                            WaitBusy   <= 1'b0;
                            // If a WAIT comes at the start of a locked transfer
                            // preceding cycle must be repeated to ensure
                            // WAIT is entered at the correct time
                            if ((Cmd === `CMD_WRITE || Cmd === `CMD_READ)
                                && HMASTLOCK === 1'b1 && HLOCKReg === 1'b0)
                              LoopNumber = { {31{1'b0}}, 1'b1 };
                          end
                      end // case: `CMD_IDLE

                      `CMD_POLL : begin
                        // Get each poll command field
                        Cmd     <= FileArrayTmp [31:24];
                        Size    <= FileArrayTmp [23:21];
                        Burst   <= FileArrayTmp [20:18];
                        Prot    <= FileArrayTmp [17:12];
                        Unalign <= FileArrayTmp [7];
                        UseBstrbTmp = FileArrayTmp [6];
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                        Lock    <= 1'b0 ;
                        ErrResp <= `ERR_OKAY;// Poll doesn't support ERROR field
                        ArrayPt  = ArrayPt + 1;
                        FileArrayTmp  = FileArray [ArrayPt];
                        TimeOut <= FileArrayTmp [31:0];    // Poll timeout value
                        ArrayPt  = ArrayPt + 1;
			if (ADDR_WIDTH > 32)
			begin
                          Addr[63:32] <= FileArray [ArrayPt];
                          ArrayPt      = ArrayPt + 1;
			end
                        Addr[31:0] <= FileArray [ArrayPt];
                        ArrayPt     = ArrayPt + 1;

                        DataTmp        = 0;
                        DataMaskTmp    = 0;
                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataTmp      = DataTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end

                        for (i = DATA_WIDTH/32-1; i >= 0; i = i-1)
                        begin
                          DataMaskTmp  = DataMaskTmp |  (FileArray [ArrayPt] << 32*i);
                          ArrayPt      = ArrayPt + 1;
                        end
                        Data        <= DataTmp;
                        DataMask    <= DataMaskTmp;

                        // Bstrb field is present if UseBstrbTmp is set
                        if (UseBstrbTmp === 1'b1) begin
                          FileArrayTmp  = FileArray [ArrayPt];
                          Bstrb        <= FileArrayTmp [STRB_MAX:0];
                          ArrayPt       = (ArrayPt + 1);
                        end
                      end // case: `CMD_POLL

                      `CMD_LOOP : begin
                        // Loops are counted from n to 0 so the loop number is
                        //  reduced by 1.
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt  = ArrayPt + 1;
                        FileArrayTmp   = FileArray [ArrayPt];
                        LoopNumber = (FileArrayTmp [31:0] - 1'b1);
                        ArrayPt  = ArrayPt + 1;
                      end // case: `CMD_LOOP

                      `CMD_WAIT : begin
                        // Get each wait command field
                        Cmd         <= FileArrayTmp [31:24];
                        StimLineTmp  = StimLineTmp + FileArrayTmp [5:0];
                        ArrayPt      = ArrayPt + 1;
                        WaitID      <= FileArray [ArrayPt];
                        ArrayPt      = ArrayPt + 1;
                        ErrResp <= `ERR_OKAY;
                      end // case: `CMD_WAIT

                      `CMD_QUIT : begin
                        // Exit simulation and print error summary
                        Cmd         <= FileArrayTmp [31:24];
                        Addr        <= {64{1'b0}};
                        Data        <= {DATA_WIDTH{1'b0}};
                        DataMask    <= {DATA_WIDTH{1'b1}};
                        Size        <= `SZ_BYTE;
                        Burst       <= `BUR_SINGLE;
                        Prot        <= 6'b000000;
                        Dir         <= 1'b0;
                        Lock        <= 1'b0;
                        WaitRdy     <= 1'b0;
                        Bstrb       <= {STRB_WIDTH{1'b0}};
                        Unalign     <= 1'b0;
                        ErrResp     <= `ERR_OKAY;
                        UseBstrbTmp = 1;
                        StimLineTmp = StimLineTmp + FileArrayTmp [5:0];
                      end

                      `UNDEF8 : begin
                        // Set defaults as file stimulus exhausted
                        Cmd         <= `CMD_IDLE;
                        Addr        <= {64{1'b0}};
                        Data        <= {DATA_WIDTH{1'b0}};
                        DataMask    <= {DATA_WIDTH{1'b1}};
                        Size        <= `SZ_BYTE;
                        Burst       <= `BUR_SINGLE;
                        Prot        <= 6'b000000;
                        Dir         <= 1'b0;
                        Lock        <= 1'b0;
                        WaitRdy     <= 1'b0;
                        Bstrb       <= {STRB_WIDTH{1'b0}} ;
                        Unalign     <= 1'b0;
                        UseBstrbTmp = 1;
                        ErrResp     <= `ERR_OKAY;
                        StimEnd     <= 1'b1;         // set end of stimulus flag
                      end

                      default : begin
                        $display (`CMD_MSG, $time, MessageTag);
                        $stop; // stop the simulation
                      end

                    endcase // case(FileArrayTmp [2:0])

                    StimLineNum <= StimLineTmp;  // update stimulus line counter

                  end // else: !if(LoopNumber !== 32'h00000000)

            UseBstrbFlag <= UseBstrbTmp;                // update Use Bstrb Flag

          end // RdNext = '1'
        end // else: if (HRESETn !== 1'b1)
    end // always begin

//------------------------------------------------------------------------------
// Quit simulation if found Q command in stimulus file
//------------------------------------------------------------------------------

  always @ (posedge HCLK)
    begin : p_SimulationEnd
      if  (~Quit && ( CmdReg === `CMD_QUIT ||
            ((StimEndData === 1'b1) && (StimEndDataReg === 1'b0)))
          )
        begin
          // stimulus just exhausted
          $display ("");
          $write   ("%t %s ", $time, MessageTag);

          if  (CmdReg === `CMD_QUIT)
              // simulation ended by Quit command
              $display (`QUIT_MSG);
          else
              // simulation ended by completion of stimulus
              $display (`END_MSG);

          // write summary info
          $display ("");
          $display (`SUMMARY_HEADER);
          $display (`SUMMARY_DATA, DataErrCnt);
          $display (`SUMMARY_SLAVE, SlaveRespCnt);
          $display (`SUMMARY_POLL, PollErrCnt);
          $display (`SUMMARY_FOOTER);
          $display ("");

        end // if begin
    end  // always begin

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_Quit
      if (!HRESETn)
        Quit <= 1'b0;
      else if (CmdReg == `CMD_QUIT)
        Quit <= 1'b1;
    end

//------------------------------------------------------------------------------
// END OF BEHAVIOURAL CODE
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Register Current Command
//------------------------------------------------------------------------------
// The current command is registered when a new command is read from the file

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_RegFileSeq
      if (HRESETn !== 1'b1)
        begin
          CmdReg       <= 8'b00000000;
          DataReg      <= {DATA_WIDTH{1'b0}};
          MaskReg      <= {DATA_WIDTH{1'b0}};
          SizeReg      <= 3'b000;
          ErrRespReg   <= 2'b00;
          StimEndData  <= 1'b0;
          StimLineReg  <= 0;
          TimeOutReg   <= {32{1'b0}};
        end // if (HRESETn !== 1'b1)
      else
        if (HREADY === 1'b1)
          begin
            CmdReg      <= Cmd;
            DataReg     <= Data;
            MaskReg     <= Mask;
            SizeReg     <= Size;
            ErrRespReg  <= ErrResp;
            StimEndData <= StimEnd;
            StimLineReg <= StimLineNum;
            TimeOutReg  <= TimeOut;
          end // if (HREADY === 1'b1)
    end // block: p_RegFileSeq


//------------------------------------------------------------------------------
// Register Stimulus End Flag
//------------------------------------------------------------------------------
// Stimulus End Flag is registered so that the summary information is only
//  displayed once.

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_StimEndReg
      if  (HRESETn !== 1'b1)
        StimEndDataReg <= 1'b0;
      else
        StimEndDataReg <= StimEndData;
    end

//------------------------------------------------------------------------------
// Register Output values
//------------------------------------------------------------------------------
// The output address, write signal and transfer type are registered when
//  HREADY is asserted.

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_RegOutputsSeq
      if  (HRESETn !== 1'b1)
        begin
          HAddrReg  <= {ADDR_WIDTH{1'b0}};
          HTransReg <= {2{1'b0}};
          HWriteReg <= 1'b0;
        end
      else
        if (HREADY === 1'b1)
          begin
            HTransReg <= iHTRANS;
            HAddrReg  <= iHADDR;
            HWriteReg <= iHWRITE;
          end // if (HREADY)
    end // block: p_regOutputsSeq


//------------------------------------------------------------------------------
// Mask used for rounding down address before incrementing
//------------------------------------------------------------------------------
  always @ (Size)
    begin : p_AlignMaskComb
      case (Size )
        `SZ_BYTE  : AlignMask = 5'b11111;
        `SZ_HALF  : AlignMask = 5'b11110;
        `SZ_WORD  : AlignMask = 5'b11100;
        `SZ_DWORD : AlignMask = 5'b11000;
        `SZ_128   : AlignMask = 5'b10000;
        `SZ_256   : AlignMask = 5'b00000;
        default   : AlignMask = 5'b11111;
      endcase
  end


//------------------------------------------------------------------------------
// Calculate aligned address
//------------------------------------------------------------------------------
//  Base of incremented address is calculated by rounding down initial address
//  to boundary of transfer (container) size.

  assign AlignedAddrL   = (HAddrReg [4:0] & AlignMask);
  assign AlignedAddr    = {HAddrReg [ADDR_MAX:5], AlignedAddrL};


//------------------------------------------------------------------------------
// Determine AddValue and calculate address
//------------------------------------------------------------------------------

// The value to be added to the address is based on the current command, the
//  previous command and the width of the data.
//
// The address should be incremented when:
//   HTRANS is sequential or busy and previous Cmd is sequential or read
//   or write (NONSEQ).

  assign NonZero = (((Cmd === `CMD_SEQ)  && (CmdReg === `CMD_SEQ))   ||
                    ((Cmd === `CMD_SEQ)  && (CmdReg === `CMD_WRITE)) ||
                    ((Cmd === `CMD_SEQ)  && (CmdReg === `CMD_READ))  ||
                    ((Cmd === `CMD_BUSY) && (CmdReg === `CMD_SEQ))   ||
                    ((Cmd === `CMD_BUSY) && (CmdReg === `CMD_WRITE)) ||
                    ((Cmd === `CMD_BUSY) && (CmdReg === `CMD_READ))) ? 1'b1
                   : 1'b0;

  always @ (Size or NonZero)
    begin : p_CalcAddValueComb
      if (NonZero === 1'b1)
        begin
          case (Size)
            `SZ_BYTE : AddValue = 6'b000001;
            `SZ_HALF : AddValue = 6'b000010;
            `SZ_WORD : AddValue = 6'b000100;
            `SZ_DWORD: AddValue = 6'b001000;
            `SZ_128  : AddValue = 6'b010000;
            `SZ_256  : AddValue = 6'b100000;
            default  : AddValue = 6'b000000;
          endcase // case(Size)
        end // if NonZero
      else
        AddValue = 6'b000000;
    end // block: p_CalcAddValueComb

//------------------------------------------------------------------------------
// Calculate new address value
//------------------------------------------------------------------------------
// A 10-bit incrementer is not used, so that bursts >1k bytes may be tested

  // Pad AddValue to ADDR_WIDTH bits
  assign  IncrAddr = AlignedAddr + { {(ADDR_WIDTH-6){1'b0}}, AddValue };

//------------------------------------------------------------------------------
// Trap wrapping burst boundaries
//------------------------------------------------------------------------------

// When the burst is a wrapping burst the calculated address must not cross
//  the boundary (size(bytes) x beats in burst).
// The boundary value is set based on the Burst and Size values

  always @ (Size or Burst)
    begin : p_BoundaryValueComb
      case (Size)

        `SZ_BYTE :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND4;
            `BUR_WRAP8  : Boundary = `BOUND8;
            `BUR_WRAP16 : Boundary = `BOUND16;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)

        `SZ_HALF :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND8;
            `BUR_WRAP8  : Boundary = `BOUND16;
            `BUR_WRAP16 : Boundary = `BOUND32;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)

        `SZ_WORD :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND16;
            `BUR_WRAP8  : Boundary = `BOUND32;
            `BUR_WRAP16 : Boundary = `BOUND64;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)

        `SZ_DWORD :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND32;
            `BUR_WRAP8  : Boundary = `BOUND64;
            `BUR_WRAP16 : Boundary = `BOUND128;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)
        `SZ_128 :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND64;
            `BUR_WRAP8  : Boundary = `BOUND128;
            `BUR_WRAP16 : Boundary = `BOUND256;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)
        `SZ_256 :
          case (Burst)
            `BUR_WRAP4  : Boundary = `BOUND128;
            `BUR_WRAP8  : Boundary = `BOUND256;
            `BUR_WRAP16 : Boundary = `BOUND512;
            `BUR_SINGLE,
            `BUR_INCR,
            `BUR_INCR4,
            `BUR_INCR8,
            `BUR_INCR16 : Boundary = `NOBOUND;
            default     : Boundary = `NOBOUND;
          endcase // case (Burst)

        default         : Boundary = `NOBOUND;
      endcase // case (Size)
    end // block: p_BoundaryValueComb

// The calculated address is checked to see if it has crossed the boundary.
//  If it has the result address is wrapped, otherwise it is equal to the
//  calculated address.

 always @ (Boundary or IncrAddr or AlignedAddr)
   begin : p_WrappedAddrComb

      case (Boundary)

        `NOBOUND :
            WrappedAddr = IncrAddr;

        `BOUND4  :
          if  (IncrAddr [1:0] === 2'b00)
            begin
              WrappedAddr [ADDR_MAX:2] = AlignedAddr [ADDR_MAX:2];
              WrappedAddr [1:0] = 2'b00;
            end // if (IncrAddr [1:0] === 2'b00)
          else
            WrappedAddr = IncrAddr;

        `BOUND8 :
          if  (IncrAddr [2:0] === 3'b000)
            begin
              WrappedAddr [ADDR_MAX:3] = AlignedAddr [ADDR_MAX:3];
              WrappedAddr [2:0] = 3'b000;
            end // if (IncrAddr [2:0] === 3'b000)
          else
            WrappedAddr = IncrAddr;

        `BOUND16 :
          if  (IncrAddr [3:0] === 4'b0000)
            begin
              WrappedAddr [ADDR_MAX:4] = AlignedAddr [ADDR_MAX:4];
              WrappedAddr [3:0] = 4'b0000;
            end // if (IncrAddr [3:0] === 4'b0000)
          else
            WrappedAddr = IncrAddr;

        `BOUND32 :
          if  (IncrAddr [4:0] === 5'b00000)
            begin
              WrappedAddr [ADDR_MAX:5] = AlignedAddr [ADDR_MAX:5];
              WrappedAddr [4:0] = 5'b00000;
            end // if (IncrAddr [4:0] === 5'b00000)
          else
            WrappedAddr = IncrAddr;

        `BOUND64 :
          if  (IncrAddr [5:0] === 6'b000000)
            begin
              WrappedAddr [ADDR_MAX:6] = AlignedAddr [ADDR_MAX:6];
              WrappedAddr [5:0] = 6'b000000;
            end // if (IncrAddr [5:0] === 6'b000000)
          else
            WrappedAddr = IncrAddr;

        `BOUND128 :
          if  (IncrAddr [6:0] === 7'b0000000)
            begin
              WrappedAddr [ADDR_MAX:7] = AlignedAddr [ADDR_MAX:7];
              WrappedAddr [6:0] = 7'b0000000;
            end // if (IncrAddr [6:0] === 7'b000000)
          else
            WrappedAddr = IncrAddr;

        `BOUND256 :
          if  (IncrAddr [7:0] === 8'b00000000)
            begin
              WrappedAddr [ADDR_MAX:8] = AlignedAddr [ADDR_MAX:8];
              WrappedAddr [7:0] = 8'b00000000;
            end // if (IncrAddr [7:0] === 8'b0000000)
          else
            WrappedAddr = IncrAddr;

        `BOUND512 :
          if  (IncrAddr [8:0] === 9'b000000000)
            begin
              WrappedAddr [ADDR_MAX:9] = AlignedAddr [ADDR_MAX:9];
              WrappedAddr [8:0] = 9'b000000000;
            end // if (IncrAddr [7:0] === 8'b0000000)
          else
            WrappedAddr = IncrAddr;

        default :
          WrappedAddr  = {ADDR_WIDTH{1'b0}};

      endcase // case(Boundary)

    end // block: p_WrappedAddrComb


//------------------------------------------------------------------------------
// Address Output
//------------------------------------------------------------------------------
// Address is calculated when there is a busy or sequential command otherwise
//  the value from the input file is used. The registered address (HADDRReg)
//  is used for poll commands.

  // Register iHADDR so that its value can be maintained during waits
  always @ (posedge HCLK or negedge HRESETn)
    begin : p_iHADDRRegSeq
      if  (HRESETn !== 1'b1)
        iHADDR_Reg <= {ADDR_WIDTH{1'b0}};
      else
        iHADDR_Reg <= iHADDR;
    end // p_iHADDRRegSeq


  assign iHADDR = ((Cmd === `CMD_BUSY) || (Cmd === `CMD_SEQ) ) ? WrappedAddr

                   : (Cmd === `CMD_WAIT) ? iHADDR_Reg

                   : Addr[ADDR_MAX:0];

  assign  HADDR  = iHADDR;


//------------------------------------------------------------------------------
// Next Line File Read Control
//------------------------------------------------------------------------------
// If the FileReader is not attempting a transfer that will result in data
//  transfer, the master can continue to read commands from the file when HREADY
//  is low. The exception is when the command being executed is a poll command.
// Cases when the next instruction can be read:
// 1. System is not polling and HREADY is high.
// 2. System is not polling and there is an IDLE or BUSY command with the wait
//    field not specified.
// 3. System is not polling, and WaitRdNextSpike is high indicating that the
//    system should resume from the WAIT state.

  assign RdNext = (NextPollState ===`ST_NO_POLL && (HREADY === 1'b1 ||
                  (WaitRdy === 1'b0 && (Cmd ===`CMD_BUSY ||
                  Cmd ===`CMD_IDLE))) )
                  ? 1'b1
                  : 1'b0;

//------------------------------------------------------------------------------
// Transfer Type Control
//------------------------------------------------------------------------------
// Transfer type output, when executing a poll command HTRANS can only be
//  set to NONSEQ or IDLE, depending on the poll state.
// HTRANS over-ridden to IDLE when cancelling a burst due to error response.
// For the other commands HTRANS is set to NONSEQ for read and write commands,
//  SEQ for sequential and BUSY for busy commands.

  always @ (Cmd or ErrRespReg or HRESP or HREADY or NextPollState)
    begin : p_HTRANSControlComb
      if  (Cmd === `CMD_POLL)
        begin
          if (NextPollState === `ST_POLL_TEST)
            iHTRANS = `TRN_NONSEQ;
          else
            iHTRANS = `TRN_IDLE;
        end
      else if ((HRESP == 1'b1) &&              // ERROR response received
               (ErrRespReg === `ERR_CANC) &&          // ERROR response expected
               (HREADY === 1'b1) &&               // 2nd cycle of ERROR response
               (Cmd === `CMD_SEQ || Cmd === `CMD_BUSY))        // burst transfer
        iHTRANS = `TRN_IDLE;                          // cancel pending transfer
      else
        case (Cmd)
          `CMD_WRITE : iHTRANS = `TRN_NONSEQ;
          `CMD_READ  : iHTRANS = `TRN_NONSEQ;
          `CMD_SEQ   : iHTRANS = `TRN_SEQ;
          `CMD_BUSY  : iHTRANS = `TRN_BUSY;
          `CMD_IDLE  : iHTRANS = `TRN_IDLE;
          `CMD_EMIT  : iHTRANS = {1'b0, HTransReg[1]};
          `CMD_QUIT  : iHTRANS = `TRN_IDLE;
          `CMD_WAIT  :
            begin
              if (WaitBusy === 1'b1)
                iHTRANS = `TRN_BUSY;
              else
                iHTRANS = `TRN_IDLE;
            end
          default    : iHTRANS = `TRN_IDLE;
        endcase // case (Cmd)
    end // block: p_HTRANSControlComb

  assign  HTRANS = iHTRANS;

//------------------------------------------------------------------------------
// Direction Control
//------------------------------------------------------------------------------
// HWRITE is only asserted for a write command or the idle command, when dir
// set. HWRITE retains its value until the end of the burst.


  assign iHWRITE = ((Cmd === `CMD_BUSY) || (Cmd === `CMD_SEQ) ||
                   ((Cmd === `CMD_WAIT) && (WaitBusy === 1'b1)) ) ? HWriteReg

                   : ((Cmd === `CMD_WRITE) ||
                      ((Cmd === `CMD_IDLE) && (Dir === 1'b1)) ||
                      ((Cmd === `CMD_WAIT) && (Dir === 1'b1)) ) ? 1'b1

                   : 1'b0;

  assign  HWRITE = iHWRITE;

//------------------------------------------------------------------------------
// Other Transfer Control Information
//------------------------------------------------------------------------------

  assign HMASTLOCK  = Lock;
  assign HSIZE      = Size;
  assign HBURST     = Burst;
  assign HPROT      = Prot[3:0]; //Prot has 6 bits




//------------------------------------------------------------------------------
// Resultant mask - taking into account Bstrb values
//------------------------------------------------------------------------------
// Assumes 64-bit data bus, and that UseBstrbFlag signal will be asserted
//  for all unaligned transfers.

  assign Mask =  DataMask;




//------------------------------------------------------------------------------
// Data Control and Compare
//------------------------------------------------------------------------------
// When the transfer type from the previous address cycle was TRN_NONSEQ or
//  TRN_SEQ then either the read or write data bus will be active in the
//  next cycle.
// write data is recorded in the address cycle

  assign iHWDATA = (
                    (iHWRITE === 1'b1) &&
                    (HREADY === 1'b1) &&
                    ((iHTRANS === `TRN_NONSEQ) ||
                     (iHTRANS === `TRN_SEQ))
                   ) ? Data
                   : {DATA_WIDTH{1'b0}};

  // The write data is registered when HREADY is asserted
  always @ (posedge HCLK or negedge HRESETn)
    begin : p_regWDataSeq
      if (HRESETn !== 1'b1)
        HWdataReg <= {DATA_WIDTH{1'b0}};
      else if (HREADY === 1'b1)
        HWdataReg <= iHWDATA;
    end // block: p_regWDataSeq

  // The registered value is output on the AHB-Lite interface
  assign  HWDATA = HWdataReg;

  // Read data is recorded in the cycle after the address and compared with
  //  the expected data value after applying the mask.
  // Note that the data is checked only if an OKAY response is received.
  always @ (DataReg or HRESP or HRDATA or MaskReg or HTransReg or HWriteReg)
    begin : p_DataCompareComb
      if  ((HWriteReg === 1'b0) && (HRESP == 1'b0) &&
           ((HTransReg ===`TRN_NONSEQ) || (HTransReg ===`TRN_SEQ)))
        begin
          DataCompare = ((DataReg & MaskReg) ^ (HRDATA & MaskReg));
          Datax = (HRDATA === {DATA_WIDTH{1'bz}} || HRDATA === {DATA_WIDTH{1'bx}});
        end
      else
        begin
          DataCompare = {DATA_WIDTH{1'b0}};
          Datax = 1'b0;
        end

    end // block: p_DataCompareComb

  // If DataCompare is non-zero, flag an error.
  assign DataError = (DataCompare !== {DATA_WIDTH{1'b0}}) || Datax ? 1'b1
                     : 1'b0;

//------------------------------------------------------------------------------
// Poll State Machine
//------------------------------------------------------------------------------
// The poll command requires two AHB transfers: a read followed by an idle to
//  get the data from the read transfer. This command will continue until the
//  data read matches the expected data or the poll timeout count is reached.
// The state machine is used to control the read and idle transfers and the
//  completion of the poll command.

  always @ (PollState or Cmd or DataError or PollCount or TimeOut)
    begin : p_PollStateComb
      case (PollState)

        `ST_NO_POLL : begin
          if (Cmd === `CMD_POLL) // if poll command, read transfer in this cycle
            begin
              NextPollState = `ST_POLL_TEST;          // test data in next cycle
              NextPollCount = TimeOut;   // load poll counter with timeout value
            end
          else                                                // no poll command
            begin
              NextPollState = `ST_NO_POLL;
              NextPollCount = PollCount;
            end
        end // case: `ST_NO_POLL

        `ST_POLL_TEST : begin                     // data phase of poll transfer
          if (DataError === 1'b0 ||        // data matched and non-ERROR response
              PollCount === 32'h00000001)                      // poll timed out
            begin
              NextPollState = `ST_NO_POLL;
              NextPollCount = 32'b00000000;
            end
          else
            begin                     // data not matched and poll not timed out
              NextPollState = `ST_POLL_READ;                       // poll again
              if (PollCount !== 32'b00000000)
                NextPollCount = PollCount - 1'b1;   // decrement timeout counter
              else
                NextPollCount = PollCount;
            end
        end // case: `ST_POLL_TEST

        `ST_POLL_READ :                        // address phase of poll transfer
          begin
            NextPollState = `ST_POLL_TEST; // next state always to test the data
            NextPollCount = PollCount;
          end

        default:                                     // illegal state transition
          begin
            NextPollState = `ST_NO_POLL;
            NextPollCount = PollCount;
          end

      endcase // case(PollState)
    end // block: p_PollStateComb

  // Poll state and count registers
  always @ (posedge HCLK or negedge HRESETn)
    begin : p_PollStateSeq
      if  (HRESETn !== 1'b1)
        begin
          PollState <= `ST_NO_POLL;
          PollCount <= 32'b00000000;
        end
      else
        if (HREADY)                       // updated on each transfer completion
          begin
            PollState <= NextPollState;
            PollCount <= NextPollCount;
          end
    end // block: p_PollStateSeq


//------------------------------------------------------------------------------
// Register HMASTLOCK
//------------------------------------------------------------------------------
// HMASTLOCK is registered every bus cycle to allow entering WAIT to occur at
// the current time when starting locked transfers.

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_HLOCKRegSeq
      if (HRESETn !== 1'b1)
        HLOCKReg <= 1'b0;
      else if (HREADY)
        HLOCKReg <= HMASTLOCK;
    end // block: p_HLOCKRegSeq


//------------------------------------------------------------------------------
// Resume from WAIT for Event
//------------------------------------------------------------------------------

  assign wait_in_progress = WAIT_REQ ^ WAIT_ACK;

  //Arbitation register
  always @(posedge HCLK or negedge HRESETn)
    begin
      if (~HRESETn) begin
        WAIT_ACK <= 1'b0;
      end else if (wait_in_progress) begin
        WAIT_ACK <= ~WAIT_ACK;
      end  
    end

  always @(posedge HCLK or negedge HRESETn)
    begin
      if (~HRESETn) begin
        last_wait_id <= {EW_WIDTH{1'bx}};
        last_wait_seen <= 1'b0;
      end else begin
        last_wait_id <= WaitID;
        last_wait_seen <= nxt_last_wait_seen;
      end  
    end

  assign nxt_last_wait_seen = (last_wait_id !== WaitID) ? (WaitDone === 1'b1) : (last_wait_seen | (WaitDone === 1'b1));   

  assign WaitDone = (WAIT_DATA == WaitID[EW_MAX:0]) && wait_in_progress;

  //Don't wait if the last wait was the correct code
  assign Waiting  = (Cmd === `CMD_WAIT && WaitDone !== 1'b1 && nxt_last_wait_seen == 1'b0) ? 1'b1 : 1'b0;

  //emit pause if the next transaction is a EMIT and the emit bus is busy
  assign next_vector = FileArray[ArrayPt];
  assign emit_pause = (EMIT_REQ ^ EMIT_ACK) && (next_vector[31:24] == `CMD_EMIT);


  `undef UNDEF8      
  `undef LOW32       
  `undef SIGN_ON_MSG1
  `undef SIGN_ON_MSG2
  `undef SIGN_ON_MSG3
  `undef SIGN_ON_MSG4
  `undef SLAVE_ERR_MSG1
  `undef SLAVE_ERR_MSG2
  `undef SLAVE_XFAIL_MSG1
  `undef SLAVE_XFAIL_MSG2
  `undef CMD_MSG
  `undef EMIT_MSG
  `undef ADDRESS_MSG
  `undef ACTUAL_DATA
  `undef EXPECTED_DATA
  `undef DATA_MASK
  `undef LINE_NUM
  `undef SIZE_MSG
  `undef INDENT
  `undef QUIT_MSG
  `undef END_MSG
  `undef SUMMARY_HEADER
  `undef SUMMARY_FOOTER
  `undef SUMMARY_DATA
  `undef SUMMARY_POLL
  `undef SUMMARY_SLAVE
  `undef TRN_IDLE
  `undef TRN_BUSY
  `undef TRN_NONSEQ
  `undef TRN_SEQ
  `undef SZ_BYTE
  `undef SZ_HALF
  `undef SZ_WORD
  `undef SZ_DWORD
  `undef SZ_128
  `undef SZ_256
  `undef BUR_SINGLE
  `undef BUR_INCR
  `undef BUR_WRAP4
  `undef BUR_INCR4
  `undef BUR_WRAP8
  `undef BUR_INCR8
  `undef BUR_WRAP16
  `undef BUR_INCR16
  `undef NOBOUND
  `undef BOUND4
  `undef BOUND8
  `undef BOUND16
  `undef BOUND32
  `undef BOUND64
  `undef BOUND128
  `undef BOUND256
  `undef BOUND512
  `undef CMD_WAIT
  `undef ERR_OKAY
  `undef ERR_CONT
  `undef ERR_CANC
  `undef ERR_XFAIL
  `undef ST_NO_POLL
  `undef ST_POLL_READ
  `undef ST_POLL_TEST
  `undef ST_EVENT_IDLE
  `undef ST_EVENT_REQHIGH
  `undef ST_EVENT_REQLOW
  `undef ST_WAIT_IDLE
  `undef ST_WAIT_ACKHIGH
  `undef ST_WAIT_RESUME
  `undef ST_WAIT_CLEAR
  `undef ST_WAIT_NOWAIT

  `undef CMD_WRITE
  `undef CMD_READ
  `undef CMD_SEQ
  `undef CMD_BUSY
  `undef CMD_IDLE
  `undef CMD_POLL
  `undef CMD_LOOP
  `undef CMD_COMM
  `undef CMD_QUIT
  `undef CMD_EMIT
  `undef CMD_WAIT
  `undef OPENFILE_MSG
  `undef DATA_ERR_MSG
  `undef POLL_ERR_MSG

endmodule // FileReadCore

//------------------------------------------------------------------------------
