//------------------------------------------------------------------------------
//   The confidential and proprietary information contained in this file may
//   only be used by a person authorised under and to the extent permitted
//   by a subsisting licensing agreement from ARM Limited.
//    (C) COPYRIGHT 2001-2013 ARM Limited
//        ALL RIGHTS RESERVED
//   This entire notice must be reproduced on all copies of this file
//   and copies of this file may only be made by a person if such person is
//   permitted to do so under the terms of a subsisting license agreement
//   from ARM Limited.
//
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FileReadCore.v,v
//  File Revision       : 1.2
//
//  Release Information : r0p1-00rel0 
//
//------------------------------------------------------------------------------
//  Purpose             : The AHB-Lite file reader bus master reads in a file
//                        and decodes it into AHB-Lite (with ARM11 extensions)
//                        bus transfers.
//------------------------------------------------------------------------------

module AhbFrs (

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
               
  HREADYOUT,
  HSEL,

  ID, //extra signal to track transaction info             
             
  // Event handling ports
  WAIT_REQ,
  WAIT_ACK,
  WAIT_DATA,
  EMIT_REQ,           
  EMIT_ACK, 
  EMIT_DATA
  );
  
  parameter  ADDR_WIDTH    = 32;  
  parameter  ADDR_MAX      = ADDR_WIDTH - 1;  
  parameter  DATA_WIDTH    = 32;
  parameter  DATA_MAX      = DATA_WIDTH - 1;
  parameter  EW_WIDTH      = 32;
  parameter  EW_MAX        = EW_WIDTH -1;  
  parameter  ID_WIDTH      = 32;
  parameter  ID_MAX        = ID_WIDTH -1 ;
  
  parameter  STRB_WIDTH     = DATA_WIDTH/8; // support 64 bit currently
  parameter  STRB_MAX       = STRB_WIDTH - 1;
  
  parameter  STIM_FILE_NAME= "filestim.m3d";   // stimulus data file name
  parameter  MESSAGE_TAG   = "AhbFrs:";    // tag on each FileReader message
  parameter  StimArraySize = 1000; // array size, should be large enough to hold
                                 
  // system ports
  input          HCLK;      // system clock
  input          HRESETn;   // system reset

  // AHB ports
  input          HREADY;    // master ready signal
  input          HSEL;
  output         HREADYOUT; // slave ready signal  
  
  output              HRESP;     // slave response (HRESP is 1 bit for AHB Lite)
  output [DATA_MAX:0] HRDATA;    // data from slave to master
  input  [DATA_MAX:0] HWDATA;    // data from master to slave
  
  input [1:0]         HTRANS;    // transfer type
  input [2:0]         HBURST;    // burst type
  input [3:0]         HPROT;     // protection 
  input [2:0]         HSIZE;     // transfer size
  input               HWRITE;    // transfer direction
  input               HMASTLOCK; // transfer is a locked transfer
  input [ADDR_MAX:0]  HADDR;     // transfer address

  input [ID_MAX:0]    ID;     //extra info  

  // Event handling ports
  input              WAIT_REQ;  // input request line
  output             WAIT_ACK;  // input acknowledge line
  input  [EW_MAX:0]  WAIT_DATA;   // input event bus        
  output             EMIT_REQ;  // output request line 
  input              EMIT_ACK;  // output acknowledge line
  output [EW_MAX:0]  EMIT_DATA;   // output event bus  
  
  
//------------------------------------------------------------------------------
  // Constant declarations
//------------------------------------------------------------------------------



  // Information message
  `define OPENFILE_MSG "%t %s Reading stimulus file %s"
  `define DATA_ERR_MSG "\n %t %s #ERROR# Data received did not match expectation."

  `define ADDRESS_MSG     " Address       = %h"
  `define ACTUAL_DATA     " Actual data   = %h"
  `define EXPECTED_DATA   " Expected data = %h"
  `define LINE_NUM        " Stimulus Line:  %0d"
  `define SIZE_MSG        " Size          = %0d bytes"
  // Inent messages because of the length of the time variable
  `define INDENT "                     "

  // End of Simulation Summary messages
  `define QUIT_MSG        "Simulation Quit requested."
  `define END_MSG         "Stimulus completed."


  // HTRANS signal encoding
  `define TRN_IDLE      2'b00   // Idle transfer
  `define TRN_BUSY      2'b01   // Busy transfer
  `define TRN_NONSEQ    2'b10   // Non-sequential
  `define TRN_SEQ       2'b11   // Sequential

  // Commands
  `define CMD_WRITE     8'b00000000
  `define CMD_READ      8'b00010000
  `define CMD_SEQ       8'b00100000
  `define CMD_QUIT      8'b10000000
  `define CMD_EMIT      8'b10010000
  `define CMD_WAIT      8'b10100000


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  // AHB Input/Output signals
  wire       	    HCLK;                // system clock
  wire       	    HRESETn;             // system reset
  wire       	    HREADY;              // slave ready signal
  wire              HREADYOUT;
  wire 	            HRESP;               // slave response
  wire [DATA_MAX:0] HRDATA;              // data from slave to master
  wire       [1:0]  HTRANS;              // transfer type
  wire 	     [2:0]  HBURST;              // burst type
  wire 	     [3:0]  HPROT;               // protection
  wire 	     [2:0]  HSIZE;               // transfer size
  wire       	    HWRITE;              // transfer direction
  wire       	    HMASTLOCK;           // transfer is a locked transfer
  wire [ADDR_MAX:0] HADDR;               // transfer address
  wire [DATA_MAX:0] HWDATA;              // data from master to slave

  wire [ID_MAX:0]   ID;     
  // Event outputs
  wire        	    EMIT_REQ;        // output request line
  wire              EMIT_ACK;        // output acknowledge line
  wire   [EW_MAX:0] EMIT_DATA;         // output event bus  

  // Event inputs
  wire              WAIT_REQ;        // input request line
  wire      	    WAIT_ACK;        // input acknowledge line
  wire   [EW_MAX:0] WAIT_DATA;         // input event bus   

  // Signals from file data
  wire       [21:0] FileCmd;             // current command buffer  
  wire [DATA_MAX:0] FileData;            // data read from stimulus file
  wire [STRB_MAX:0] FileStrb;
  wire [ADDR_MAX:0] FileAddr;
  wire              FileResp;
  reg  [DATA_MAX:0] DataMask;                //data mask generated by FileStrb
 
  wire        [7:0] Cmd;                 // current command buffer
  wire 	     [2:0]  Burst;               // burst value read from stimulus file
  wire 	     [2:0]  Size;                // size value read from stimulus file
  wire              Lock;                // lock value read from stimulus file
  wire       [5:0]  Prot;                // prot value read from stimulus file  Prot[5:4] tied to 0

  wire        [7:0] ExpectedCmd;         // current command buffer
  wire       [2:0]  ExpectedBurst;       // burst value read from stimulus file
  wire       [2:0]  ExpectedSize;        // size value read from stimulus file
  wire              ExpectedLock;        // lock value read from stimulus file
  wire	     [5:0]  ExpectedProt;        // prot value read from stimulus file  Prot[5:4] tied to 0


    // Internal signals
  wire [ADDR_MAX:0] iHADDR;              // internal version of HADDR output
  wire [DATA_MAX:0] iHWDATA;             // internal version of HWDATA output
  wire       [1:0]  iHTRANS;             // internal version of HTRANS output
  wire              iHWRITE;             // internal version of HWRITE output
  wire [ID_MAX:0]   iID;          

  // Registered signals

  reg  	     [21:0] CommandReg;              // regstered version of the current command  

  
  wire              Waiting;
  wire              Delaying;
  

  reg [ADDR_MAX:0] HAddrReg;            // registered version of iHADDR
  reg [DATA_MAX:0] HWdataReg;           // registered version of iHWDATA
  reg [DATA_MAX:0] HRdataReg;           // registered version of  HRDATA  
  reg 	     [1:0] HTransReg;           // registered version of iHTRANS
  reg         	   HWriteReg;           // registered version of iHWRITE
  
  reg         	   HLOCKReg;            // Registered version of HLOCK
  reg	     [2:0] HSizeReg;

  reg              HrespReg;              //indicate the second cycle of error response
  
  // Error signal
  integer          DataErrCnt;                   // read data errors  
  wire        	   DataError;           // flag to indicate read data is incorrect
  integer          i;                   // loop counter
   
  // EMIT command registers
  wire  [EW_MAX:0] EmitID;              // ID of EMIT command from stimulus file
  wire             Emit_valid;            // EMIT complete flag
  wire  [EW_MAX:0] WaitID;              // ID of WAIT command from stimulus file   
  wire             Wait_valid;            // WAIT finished flag

  wire             emit_now;
  wire             emit_hold;
  wire             complete;
  reg              complete_reg;

  
//------------------------------------------------------------------------------
// Main code
//------------------------------------------------------------------------------
  
     
// Instantiate AhbFrsCore, reading stimulus file
  defparam uAhbFrsCore.DATA_WIDTH       = DATA_WIDTH;
  defparam uAhbFrsCore.ADDR_WIDTH       = ADDR_WIDTH;
  defparam uAhbFrsCore.EW_WIDTH         = EW_WIDTH;
  defparam uAhbFrsCore.ID_WIDTH         = ID_WIDTH;
  defparam uAhbFrsCore.STIM_FILE_NAME   = STIM_FILE_NAME;
  defparam uAhbFrsCore.FILE_LEN         = StimArraySize;
  
 AhbFrsCore uAhbFrsCore
  (
    .HCLK           (HCLK),
    .HRESETn        (HRESETn),
    .FileReady      (FileReady),
    .FileValid      (FileValid),

    .dir            (~iHWRITE),
    .id             (iID),   
    .WaitID         (WaitID),
    .Wait_valid     (Wait_valid),
    .EmitID         (EmitID),
    .Emit_valid     (Emit_valid),
    .VecComplete    (complete),

    .FileData       (FileData),
    .FileCmd        (FileCmd),
    .FileStrb       (FileStrb),
    .FileAddr       (FileAddr),
    .FileResp       (FileResp),
    .Waiting        (Waiting),
    .Delaying       (Delaying)
  );  

 // Instantiate AhbFrsEvent
  defparam  uFrsEvent.EW_WIDTH         = EW_WIDTH;   
  
  AhbFrsEvent  uFrsEvent 
  (
    .HCLK            (HCLK),
    .HRESETn         (HRESETn),

    //Signals for FrsCore
    .ebus            (EmitID),
    .emit_now        (emit_now),
    .wbus            (WaitID),
    .go              (Wait_valid),

    .hold            (emit_hold),

    //External Emit bus
    .EMIT_DATA       (EMIT_DATA),
    .EMIT_REQ        (EMIT_REQ),
    .EMIT_ACK        (EMIT_ACK),

    //External Wait bus
    .WAIT_DATA       (WAIT_DATA),
    .WAIT_REQ        (WAIT_REQ),
    .WAIT_ACK        (WAIT_ACK)
   );

//------------------------------------------------------------------------------
// Emit logic
//------------------------------------------------------------------------------

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_complete_reg
      if (HRESETn != 1'b1) begin  
         complete_reg <= 1'b0;
      end else if (complete & ~emit_hold) begin
         complete_reg <= 1'b1;
      end
    end   

  assign emit_now = (Emit_valid && HREADY) ||      //Emit on a data phase
                       (complete && ~complete_reg && ~emit_hold);   //or on complete

//------------------------------------------------------------------------------
// Register Input values
//------------------------------------------------------------------------------
// The input address, write signal and transfer type are registered when HREADY is asserted.

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_RegOutputsSeq
      if  (HRESETn != 1'b1)
        begin
          HAddrReg  <= {ADDR_WIDTH{1'b0}};
          HTransReg <= {2{1'b0}};
          HWriteReg <= 1'b0;
          HRdataReg <= {DATA_WIDTH{1'b0}};
          HWdataReg <= {DATA_WIDTH{1'b0}};          
          HSizeReg  <= 3'b000;
        end
      else
        if (HREADY == 1'b1)
          begin
            HTransReg <= iHTRANS;
            HAddrReg  <= iHADDR;
            HWriteReg <= iHWRITE;
            HRdataReg <= HRDATA;
            HWdataReg <= iHWDATA;            
            HSizeReg  <= Size;
          end // if (HREADY)
    end // block: p_regOutputsSeq

  //FileReady is the DATA request signal for AhbFrsCore 
  assign FileReady = ((iHTRANS == `TRN_NONSEQ) || (iHTRANS == `TRN_SEQ)) && HREADY;
        
  assign Cmd = (iHTRANS == `TRN_SEQ) ? `CMD_SEQ : (iHWRITE == 1'b1 && iHTRANS == `TRN_NONSEQ) ? `CMD_WRITE : (iHWRITE == 1'b0 && iHTRANS == `TRN_NONSEQ) ? `CMD_READ : {8{1'b1}};
  assign iHADDR    = HADDR;
  assign iID       = ID;  
  assign iHTRANS   = HTRANS;
  assign iHWRITE   = HWRITE;
  assign Lock      = HMASTLOCK;
  assign Size      = HSIZE;
  assign Burst     = HBURST;
  assign Prot      = {2'b00,HPROT};
       
//------------------------------------------------------------------------------
// HDATA
//-----------------------------------------------------------------------------  

  assign iHWDATA = HWDATA;
  
  assign HRDATA = (
                    (HWriteReg  == 1'b0) &&
                    ((HTransReg == `TRN_NONSEQ) || (HTransReg == `TRN_SEQ)) &&
                    (HREADY     == 1'b1) 
                   ) ? FileData : HRdataReg;
  
//------------------------------------------------------------------------------
// HRESP  Logic : Note error response takes two cycles
// first cycle with HRESP high and HREADYOUT low, second with both high
//------------------------------------------------------------------------------

  assign HREADYOUT = ~Waiting &&      //Wait
                         ~Delaying &&         //Timed delay
                              (~HRESP || HrespReg) &&    //First part of error response
                                ~(emit_hold && Emit_valid && (HTransReg != `TRN_IDLE));  // We want to emit but can't and the last htrans wasn't idle


  assign HRESP     = ~Waiting &&    //Wait
                        ~Delaying &&    // Timed delay
                           ~(emit_hold && Emit_valid && (HTransReg != `TRN_IDLE)) &&  //EMit in progress and we want to emit again
                                FileResp && ((HTransReg == `TRN_NONSEQ) || (HTransReg == `TRN_SEQ));   //and there is an error

  always @ (posedge HCLK or negedge HRESETn)
  begin : p_resp
    if (!HRESETn) begin
       HrespReg  <= 1'b0;
    end else if (HRESP) begin
       HrespReg  <= ~HrespReg;
    end 
  end

  // Generate data mask for HWDATA comparison
  always @(FileStrb)
  begin : p_data_mask
    integer i;    
    integer j;  
    integer base; // Increment through the bit number of the payload
    base = 0;
    
    for (i=0; i<STRB_WIDTH; i=i+1)
    begin
      for (j=base; j<(base+8); j=j+1)
        DataMask[j] = FileStrb[i];
      base = (8 * (i+1));
    end
  end
 
  // If DataCompare is non-zero, flag an error.
  assign DataError = ((iHWDATA & DataMask) != (FileData & DataMask)) && HWriteReg && HREADY && ((HTransReg == `TRN_NONSEQ) || (HTransReg == `TRN_SEQ));
  
//------------------------------------------------------------------------------
// Report errors to simulation environment
//------------------------------------------------------------------------------
// This process responds to error signals with an acknowledge signal and
//  reports the error to the simulation environment

  always @ (posedge HCLK or negedge HRESETn)
    begin : p_ReportErrorsBhav
      if (HRESETn != 1'b1)
        begin
          DataErrCnt = 0;
        end
      else
        if (DataError == 1'b1)
        begin
              $display (`DATA_ERR_MSG, $time, MESSAGE_TAG);
              //$write   (`INDENT);
              $display (`ADDRESS_MSG, HAddrReg);
              //$write   (`INDENT);
              $display (`SIZE_MSG, 1<<HSizeReg);
              //$write   (`INDENT);
              $display (`ACTUAL_DATA, iHWDATA);
              //$write   (`INDENT);
              $display (`EXPECTED_DATA, FileData);
                             
              DataErrCnt = DataErrCnt + 1;       // increment data error counter
        end // if (DataError === 1'b1 && PollState === `ST_NO_POLL)
    end 	// block: p_ReportErrorsBhav

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

assign ExpectedCmd   = FileCmd[21:14];  // current command buffer
assign ExpectedSize  = FileCmd[13:11];  // burst value read from stimulus file
assign ExpectedBurst = FileCmd[10:8];   // size value read from stimulus file
assign ExpectedProt  = FileCmd[7:2];    // lock value read from stimulus file
assign ExpectedLock  = FileCmd[1];      // prot value read from stimulus file  Prot[5:4] tied to 0

assert_never #(2,0,"WARNING, Error in AHB Command")
ovl_assert_ahb_command_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ExpectedCmd != Cmd));

assert_never #(2,0,"WARNING, Error in AHB Size")
ovl_assert_ahb_size_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ExpectedSize != Size));

assert_never #(2,0,"WARNING, Error in AHB Burst")
ovl_assert_ahb_burst_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ExpectedBurst != Burst));

assert_never #(2,0,"WARNING, Error in AHB Prot")
ovl_assert_ahb_prot_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ExpectedProt != Prot));

assert_never #(2,0,"WARNING, Error in AHB Lock")
ovl_assert_ahb_lock_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ExpectedLock != Lock));

assert_never #(2,0,"WARNING, Error in AHB Address")
ovl_assert_ahb_addr_error
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & FileAddr != iHADDR));

`endif

//------------------------------------------------------------------------------
// END OF BEHAVIOURAL CODE
//------------------------------------------------------------------------------

  
  `undef ADDRESS_MSG
  `undef ACTUAL_DATA
  `undef EXPECTED_DATA
  `undef LINE_NUM
  `undef SIZE_MSG
  // Inent messages because of the length of the time variable
  `undef INDENT

  // End of Simulation Summary messages
  `undef QUIT_MSG
  `undef END_MSG


  // HTRANS signal encoding
  `undef TRN_IDLE
  `undef TRN_BUSY
  `undef TRN_NONSEQ
  `undef TRN_SEQ

  `undef CMD_WRITE     
  `undef CMD_READ      
  `undef CMD_SEQ       
  `undef CMD_QUIT      
  `undef CMD_EMIT      
  `undef CMD_WAIT
  
  `undef OPENFILE_MSG
  `undef DATA_ERR_MSG

  
endmodule 

//------------------------------------------------------------------------------
