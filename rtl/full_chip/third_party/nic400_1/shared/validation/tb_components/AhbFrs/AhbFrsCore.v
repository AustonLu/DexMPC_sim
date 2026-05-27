// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2008-2009 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FrsFileReader.v,v
//  File Revision       : 1.10
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : FRM file reader
//
//                        A behavioral module that converts values in
//                        a stimulus file into signals. Asserts FileValid until
//                        file is exhausted. 
//                        This is re-ordering slave FileReader.
//
//                        FileValid is driven low if there in no suitable databeat
//                        incicating an error if the incoming ID is valid
// 
//                        It also monitors the wait bus and sets the wait flag
//                        will update any waits between the current location
//                        and the next sync (irrespective of ID)
//
// --=========================================================================--


module AhbFrsCore
(
  HCLK,
  HRESETn,
  FileReady,  
  FileValid,

  dir,
  id,
 
  WaitID,
  Wait_valid,
  EmitID,
  Emit_valid,
  VecComplete,

  FileData,
  FileStrb,
  FileAddr,
  FileResp,
  FileCmd,
  Waiting,
  Delaying
);


`define OPENFILE_MSG "%d %s Reading stimulus file %s"
  
  // Module parameters  
  parameter  STIM_FILE_NAME  = "";                   // Stimulus file name
  parameter  MESSAGE_TAG     = "AhbFrs:";             // Message prefix 

  parameter  DELAY_BASE     = 0;                   //fixed
  parameter  DELAY_WDITH    = 32;                  
  parameter  ID_BASE        = 32;                  //fixed
  parameter  ID_WIDTH       = 32;                  
  parameter  DATA_WIDTH     = 32;
  parameter  STRB_BASE      = 32+32 ;              //fixed 
  parameter  STRB_WIDTH     = DATA_WIDTH/8;        //vector widith fixed at 32, support 256-bits bus
  parameter  DATA_BASE      = 32+32+32;            //fixed
  parameter  ADDR_BASE      = DATA_BASE+DATA_WIDTH ; 
  parameter  ADDR_WIDTH     = 32; 
  parameter  COMMAND_BASE   = (ADDR_WIDTH > 32) ? (ADDR_BASE+64) : (ADDR_BASE+32);
  parameter  COMMAND_WIDTH  = 32;                  // 
  parameter  DIR_BIT        = 0;
  
  parameter  EW_WIDTH       = 32;  
  parameter  EW_MAX         = EW_WIDTH -1;
  parameter  ADDR_MAX       = ADDR_WIDTH -1;
  parameter  ID_MAX         = ID_WIDTH -1 ;
  parameter  DATA_MAX       = DATA_WIDTH - 1;
  parameter  STRB_MAX       = STRB_WIDTH - 1;  
  parameter  CMD_MAX        = COMMAND_WIDTH - 1;  
  parameter  COMMAND_TOP    = COMMAND_BASE + COMMAND_WIDTH - 1;
  


  parameter  VECTOR_WIDTH  = COMMAND_BASE + COMMAND_WIDTH;
  parameter  VECTOR_MAX    = VECTOR_WIDTH - 1;       // Upper bound of stimulus memory vector
  parameter  FILE_LEN      = 1000;                   // Length of stimulus memory
  
  // the input file will always hold 128 bit for data padded with zero if data_width less than 128

  // Module Inputs
  input               HCLK;             // Clock input
  input               HRESETn;          // Reset async input active low
  input               FileReady;        // Read another vector
  
  input [ID_MAX:0]    id;               //id signal
  input               dir;              //direction

  input [EW_MAX:0]    WaitID;           //Incoming wait bus
  input               Wait_valid;       //Wait valid signal

  output [EW_MAX:0]   EmitID;           //Outgoing emit bus
  output              Emit_valid;       //Emit valid signal
  output              VecComplete;         //Output complete

  // Module Outputs
  output              FileValid;        // Valid vector in file
  output       [21:0] FileCmd;
  output [DATA_MAX:0] FileData;         // Current Data vector in file
  output [ADDR_MAX:0] FileAddr;         // Current Data vector in file
  output [STRB_MAX:0] FileStrb;         // Strobe vector,used as data comparason mask. it's the bottom 16 bit of COMMAND in vector file, support 64 bit currently
  output              FileResp;
  
  output              Waiting;
  output              Delaying;
  
  
//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                  HCLK;
  wire                  HRESETn;
  wire                  FileReady;

  wire                  FileValid;
  wire     [DATA_MAX:0] FileData;
  wire     [STRB_MAX:0] FileStrb;
  wire                  FileResp;  
  wire           [21:0] FileCmd;
  wire                  Waiting;
  wire       [EW_MAX:0] Waiting_ID;
  wire                  Emit_valid;
  wire       [EW_MAX:0] EmitID;

  // File array of length specified by FILE_LEN.
  // Contains the vector data from the file
  reg    [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array
  reg    [31:0]         Delay_queue;
  
  reg    [VECTOR_MAX:0] Vector;
  reg    [VECTOR_MAX:0] selectVector;
  reg    [31:0]         Pointer;
  
  reg        [EW_MAX:0] Wait_array [0:(FILE_LEN - 1)];
  reg  [FILE_LEN - 1:0] Wait_flags;  
  reg        [EW_MAX:0] Emit_array [0:(FILE_LEN - 1)];
  reg  [FILE_LEN - 1:0] Emit_flags;
  
  reg  [FILE_LEN - 1:0] Complete;
  reg  [FILE_LEN - 1:0] Complete_Rst;
  reg  [FILE_LEN - 1:0] Nxt_Wait_flags;

  wire                  wait_update;


  // Flag inidcates when to read the next vector
  wire                  Update;           // update the array pointer

  // Pointers into stimulus array
  reg    [31:0]         ArrayPt;          // pointer to current stimulus vector
  wire   [31:0]         ArrayPtNext;      // pointer to next stimulus vector

  reg    [31:0]         ArrayMax;         // limit of valid vectors in array
  reg    [31:0]         select;           // Current vector
  reg    [31:0]         selectReg; 


//------------------------------------------------------------------------------
// Beginning of main code (behavioral)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Set up the time format
//------------------------------------------------------------------------------

  initial
  begin : p_TimeFormatBhav
      $timeformat(-9, 0, " ns", 0);
  end

//----------------------------------------------------------------------------
// Open vector File
//----------------------------------------------------------------------------
// Loads the vector file into an array and determines the number of vectors in
// the array. This process is only executed once.

  initial
  begin : p_OpenFileBhav


    // report the stimulus file name to the simulation environment
    $display (`OPENFILE_MSG, $time, MESSAGE_TAG, STIM_FILE_NAME);
    $readmemh(STIM_FILE_NAME, FileMem);

    // Determine the number of vectors in the array
    ArrayMax   = 32'h00000000;
    Wait_flags = {FILE_LEN{1'b0}};
    Emit_flags = {FILE_LEN{1'b0}};    
    Complete   = {FILE_LEN{1'b0}};    
    
    while ( (ArrayMax < FILE_LEN) && 
            (FileMem[ArrayMax] !== {VECTOR_WIDTH{1'bx}})  ) begin

      Vector = FileMem[ArrayMax];      

      //Set the wait flags
      if (Vector[COMMAND_TOP:COMMAND_TOP-7] == 8'b10100000)  begin //CMD_WAIT
        Wait_flags[ArrayMax+1] = 1'b1;
        Wait_array[ArrayMax+1] = Vector[ADDR_BASE+EW_MAX:ADDR_BASE];
        Complete[ArrayMax] = 1'b1;
      end
      
      //Set the emit flags
      if (Vector[COMMAND_TOP:COMMAND_TOP-7] == 8'b10010000)   begin //CMD_EMIT
        Emit_flags[ArrayMax-1] = 1'b1;
        Emit_array[ArrayMax-1] = Vector[ADDR_BASE+EW_MAX:ADDR_BASE];
        Complete[ArrayMax] = 1'b1;
      end
      
      ArrayMax = ArrayMax + 1;
    end

  end


//------------------------------------------------------------------------------
// Determine end of file
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Complete logic 
// (select is the current output)
//------------------------------------------------------------------------------

  //Find the first enabled non-complete transaction ID 
  always @(ArrayPt or ArrayMax or Complete or dir or id)
     begin

          //Default 
          select = ArrayPt;
          selectVector = FileMem[select];
          
          //non-complete ID match
          while ((Complete[select] || !((selectVector[COMMAND_BASE+10] == dir) && (selectVector[ID_MAX+ID_BASE:ID_BASE] == id))) && 
            (select < ArrayMax)) begin 

               //increment the pointer
               select = select + 1;
               selectVector = FileMem[select];
          end
    end

  always @ (posedge HCLK or negedge HRESETn)
  begin : p_CompleteReg

    if (!HRESETn) begin
      selectReg  <= 1'b0;
    end else if (Update) begin 
      Complete[select] <= 1'b1;    
      selectReg        <= select;     
     end
  end
  
  assign Waiting = Wait_flags[selectReg] ? 1'b1 : 1'b0;
  assign Emit_valid = Emit_flags[selectReg] ? 1'b1 : 1'b0;  
  assign EmitID = Emit_valid ? Emit_array[selectReg] : {EW_WIDTH{1'b0}}; 
  assign Waiting_ID = Waiting ? Wait_array[selectReg] : {EW_WIDTH{1'b0}};
  
//------------------------------------------------------------------------------
// Array Pointer Logic 
//------------------------------------------------------------------------------
  function [31:0] array_jump;

     input [FILE_LEN-1:0] Complete;
     input [31:0]         ArrayPt;
     input [31:0]         Complete_now;
 
     begin
        array_jump = 32'b0;
        while(Complete[array_jump + ArrayPt] || (Complete_now == (array_jump + ArrayPt))) begin
            array_jump = array_jump + 1;  
        end
     end

  endfunction

  always @ (posedge HCLK or negedge HRESETn)
   begin : p_ArrayPtReg

    if (!HRESETn) begin
       ArrayPt <= 0; 
    end else if (Update) begin
       ArrayPt <= ArrayPt + array_jump(Complete, ArrayPt, select);
    end
  end

//------------------------------------------------------------------------------
// Update Wait_flags
//------------------------------------------------------------------------------
 always @(WaitID or ArrayPt or Wait_flags or ArrayMax) begin 

      Nxt_Wait_flags = Wait_flags;
      Pointer = ArrayPt;
      Vector = FileMem[Pointer];

      while (Pointer < ArrayMax) begin
           if ((Wait_flags[Pointer]) && Wait_array[Pointer] == WaitID) begin
              Nxt_Wait_flags[Pointer] = 1'b0;   
           end
           Pointer = Pointer + 1;
      end
 end

 assign wait_update = Wait_valid;

 always @ (posedge HCLK)
  begin : p_waitflags
    if (wait_update) 
      // update wait flags
      Wait_flags <= Nxt_Wait_flags;
  end

//------------------------------------------------------------------------------
// Look up values in array at pointer
//------------------------------------------------------------------------------

  assign FileValid  = (select < ArrayMax);
  assign Update     = FileReady & FileValid;
  assign FileData   = FileMem[selectReg][DATA_MAX+DATA_BASE:DATA_BASE];
  assign FileStrb   = FileMem[selectReg][STRB_BASE+STRB_MAX:STRB_BASE];
  assign FileResp   = FileMem[selectReg][COMMAND_BASE];  
  assign FileCmd    = FileMem[select][COMMAND_TOP:COMMAND_BASE+10];  
  assign FileAddr   = FileMem[select][ADDR_BASE+ADDR_WIDTH-1:ADDR_BASE];  
  
//------------------------------------------------------------------------------
// Delay Logic 
//------------------------------------------------------------------------------
  assign Delaying   = |Delay_queue ? 1'b1 : 1'b0;  

  always @(posedge HCLK or negedge HRESETn)
  begin : p_Delay_queue
    if (! HRESETn) begin
       Delay_queue <= {32{1'b0}};     
    end else if (Update) begin
        Delay_queue <= FileMem[select][31:0];
    end else if (Delaying) begin
        Delay_queue <= Delay_queue - 32'h1;
    end
  end

//------------------------------------------------------------------------------
// Completion Logic 
//------------------------------------------------------------------------------

  assign VecComplete = (ArrayPt == (ArrayMax - 1));

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

assert_never #(1,0,"ERROR, No transaction found for incoming ID and direction")
ovl_assert_no_responding_data
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (FileReady & ~FileValid));

assert_never #(1,0,"ERROR, Update FIFO during Delaying")
ovl_assert_update_when_delay
   (
    .clk       (HCLK),
    .reset_n   (HRESETn),
    .test_expr (Update & (Delaying|Waiting)));
  
  // OVL_ASSERT_END

`endif

`undef OPENFILE_MSG
  
endmodule

// --================================= End ===================================--

