// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2008-2012 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Date           :  2012-08-17 10:56:37 +0100 (Fri, 17 Aug 2012)
//  File Revision       : 135247
//
//  Release Information : PL401-r1p2-00rel0
//
// -----------------------------------------------------------------------------
//  Purpose             : FRS file reader Slave
//
//                        A behavioral module that converts values in
//                        a stimulus file into signals. Asserts FileValid until
//                        file is exhausted. 
//                        This is re-ordering slave FileReader.
//
//                        It keeps a record of which vectors have been completed
//                        It outputs the first incomplete beat from a particular ID.
//
// --=========================================================================--

`timescale 1ns / 1ps

module ApbFrsCore
(
  pclk,
  presetn,
  FileReady,

  command,
  id,
  resp,
  strobe,
  pprot,

  Delaying,
  FileAddr,
  FileValid,
  FileData
);


  // Information message
  `define OPENFILE_MSG "%d %s Reading stimulus file %s"
  `define DATA_ERR_MSG "%d %s #ERROR# Data received did not match expectation."
  
  // Module parameters
  // input vector will in the format of command, address, data, response, id, delay
  parameter  VECTOR_WIDTH  = 8 + 32 + 32 + 4 + 4 + 4 +32 +32;    // Width of stimulus memory vector (8-bit commond + 32 address + 32 Data + 4 pprot + 4 strb + 4 resp  + 32 id + 32 delay) 
  parameter  VECTOR_MAX    = VECTOR_WIDTH - 1;       // Upper bound of stimulus memory vector
  parameter  FILE_LEN      = 5000;                   // Length of stimulus memory
                        
  parameter  STIM_FILE_NAME = "";                 // Stimulus file name
  parameter  MESSAGE_TAG    = "ApbFrs:";  // Message prefix
  parameter  DELAY_WDITH    = 32;
  parameter  ID_BASE        = 32;         //fixed
  parameter  ID_WIDTH       = 32;
  parameter  ID_MAX         = ID_WIDTH -1 ;
  parameter  RESP_BASE      = 64;         //fixed
  parameter  STRB_BASE      = 68;         //fixed
  parameter  PPROT_BASE     = 72;         //fixed  
  parameter  DATA_BASE      = 76;         //fixed  
  parameter  ADDR_BASE      = 32 + DATA_BASE;
  parameter  ADDR_WIDTH     = 32;  
  parameter  COMMAND_BASE   = ADDR_BASE + ADDR_WIDTH;
  

  // Module Inputs
  input               pclk;             // Clock input
  input               presetn;          // Reset async input active low
  input               FileReady;        // Read another vector

  input      [7:0]    command;    
  input [ID_MAX:0]    id;

  output              resp;
  output [3:0]        strobe;
  output [2:0]        pprot;
  output              Delaying;
  
                

  // Module Outputs
  output              FileValid;        // Valid vector in file
  output    [31:0]    FileData;       // Current vector in file
  output    [31:0]    FileAddr;       // Current vector in file

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                pclk;
  wire                presetn;
  wire                FileReady;

  wire                FileValid;
  wire         [31:0] FileData;

// Internal Signals

  // File array of length specified by FILE_LEN.
  // Contains the vector data from the file
  reg  [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array

  reg  [31:0]          Delay_queue;
  
  reg  [VECTOR_MAX:0] Vector;
  reg  [VECTOR_MAX:0] selectVector;
  reg  [31:0]         Pointer;
  
  reg  [FILE_LEN - 1:0] Complete;

  // Flag inidcates when to read the next vector
  wire                Update;           // update the array pointer

  // Pointers into stimulus array
  reg    [31:0]       ArrayPt;          // pointer to current stimulus vector
  wire   [31:0]       ArrayPtNext;      // pointer to next stimulus vector

  reg    [31:0]       ArrayMax;         // limit of valid vectors in array
  reg    [31:0]       select;           // Current vector
  reg    [31:0]       selectReg; 

  wire                Delaying;
  

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
    ArrayMax = 32'h00000000;
    
    while ( (ArrayMax < FILE_LEN) && 
            (FileMem[ArrayMax] !== {VECTOR_WIDTH{1'bx}})  ) begin
      Vector = FileMem[ArrayMax];   
      ArrayMax = ArrayMax + 1;
    end

  end


//------------------------------------------------------------------------------
// Complete logic 
// (select is the current output)
//------------------------------------------------------------------------------

  //Find the first enabled non-complete transaction ID 
  always @(ArrayPt or ArrayMax or Complete or command or id)
     begin

          //Default 
          select = ArrayPt;
          selectVector = FileMem[select];
          
          //non-complete ID match
          while ((Complete[select] || !((selectVector[ID_BASE+ID_MAX:ID_BASE] == id) && (selectVector[COMMAND_BASE+7:COMMAND_BASE] == command))) && (select < ArrayMax)) begin 

             //increment the pointer
             select = select + 1;
             selectVector = FileMem[select];
          end
    end

  always @(negedge presetn or posedge pclk)
  begin : p_CompleteReg

    if (!presetn) begin
      Complete   <= {FILE_LEN{1'b0}};
      selectReg  <= 1'b0;
    end else if (Update) begin 
      Complete[select] <= 1'b1;    
      selectReg        <= select;     
     end
  end
  

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

  always @(negedge presetn or posedge pclk)
   begin : p_ArrayPtReg

    if (!presetn) begin
       ArrayPt <= 0; //First vector is a channel code not a vector 
    end else if (Update) begin
       ArrayPt <= ArrayPt + array_jump(Complete, ArrayPt, select);
    end
  end

//------------------------------------------------------------------------------
// Look up values in array at pointer
//------------------------------------------------------------------------------

  assign FileValid  = (select < ArrayMax);
  assign Update     = FileReady & FileValid;
  assign FileData   = FileMem[select][31+DATA_BASE:DATA_BASE];
  assign FileAddr   = FileMem[select][31+ADDR_BASE:ADDR_BASE];
  assign resp       = FileMem[select][RESP_BASE];
  assign strobe     = FileMem[select][STRB_BASE+3:STRB_BASE];	
  assign pprot      = FileMem[select][PPROT_BASE+2:PPROT_BASE];

//------------------------------------------------------------------------------
// Delay Logic 
//------------------------------------------------------------------------------
  assign Delaying   = |Delay_queue ? 1'b1 : 1'b0;  

  always @(negedge presetn or posedge pclk)
  begin : p_Delay_queue
    if (!presetn) begin
       Delay_queue <= {32{1'b0}}; 
    end else if (Update) begin
        Delay_queue <= FileMem[select][31:0];
    end else if (Delaying) begin
        Delay_queue <= Delay_queue - 32'h1;
    end
  end

 `undef OPENFILE_MSG
 `undef DATA_ERR_MSG                 

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  // OVL_ASSERT_END

assert_never #(1,0,"ERROR, There is no corresponding data found in FIFO")
ovl_assert_no_responding_data
   (
    .clk       (pclk),
    .reset_n   (presetn),
    .test_expr (FileReady & ~FileValid));

assert_never #(1,0,"ERROR, Update FIFO during Delaying")
ovl_assert_update_when_delay
   (
    .clk       (pclk),
    .reset_n   (presetn),
    .test_expr (Update & Delaying));
  
`endif


endmodule

// --================================= End ===================================--

