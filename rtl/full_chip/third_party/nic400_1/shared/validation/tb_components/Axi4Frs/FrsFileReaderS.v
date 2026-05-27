// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 87876
//  File Date           :  2010-03-05 13:27:48 +0000 (Fri, 05 Mar 2010)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : FRS file reader
//
//                        A behavioral module that converts values in
//                        a stimulus file into signals. Asserts FileValid until
//                        file is exhausted.
//                        This is re-ordering slave FileReader.
//
//                        It keeps a record of which vectors have been completed
//                        It outputs the first incomplete beat from a particular ID.
//                        NB.. THIS FILEREADER DOES NOT CHECK IF A BEAT CAN BE ACCEPTED
//                        I.E. READ DATA CAN BE ACCEPTED BEFORE THE ADDRESS IS SENT.
//                        CONSEQUENTLY IT MUST BE USED IN CONJUCTION WITH AXIPC
//
//                        FileValid is driven low if there in no suitable databeat
//                        incicating an error if the incoming ID is valid
//
//                        It also monitors the wait bus and sets the wait flag
//                        will update any waits between the current location
//                        and the next sync (irrespective of ID)
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrsFileReaderS
(
  ACLK,
  ARESETn,
  FileReady,

  ID,

  Wait,
  Wait_valid,

  FileValid,
  SyncValid,
  FileData
);


  // Module parameters
  parameter FILE_LEN    = 1000;                   // Length of stimulus memory
  parameter VECTOR_WIDTH  = 128;                  // Width of stimulus memory
  parameter STIM_FILE_NAME  = "";                 // Stimulus file name
  parameter MESSAGE_TAG    = "FileRdMasterAxi:";  // Message prefix
  parameter VERBOSE       = 1;                    // Verbosity control
  parameter FILE_ID       = 16'hd000;             // Used to identify file type
  parameter WAIT_BASE     = 0;
  parameter EW_WIDTH      = 8;
  parameter ID_BASE       = 8;
  parameter ID_WIDTH      = 8;

  // Calculated parameters - do not modify
  parameter VECTOR_MAX
              = VECTOR_WIDTH - 1;       // Upper bound of stimulus memory vector

  parameter EW_MAX = EW_WIDTH -1;
  parameter ID_MAX = ID_WIDTH -1;
  parameter ID_TOP = ID_BASE + ID_MAX;

  // Module Inputs
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               FileReady;        // Read another vector

  input [ID_MAX:0]    ID;

  input [EW_MAX:0]    Wait;             //Incoming wait bus
  input               Wait_valid;       //Wait valid signal

  // Module Outputs
  output              FileValid;        // Valid vector in file
  output              SyncValid;        // Valid vector in file
  output [VECTOR_MAX:0] FileData;       // Current vector in file

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                ACLK;
  wire                ARESETn;
  wire                FileReady;

  wire                FileValid;
  wire [VECTOR_MAX:0] FileData;


// Internal Signals

  // File array of length specified by FILE_LEN.
  // Contains the vector data from the file
  reg  [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array

  reg  [VECTOR_MAX:0] Vector;
  wire  [VECTOR_MAX:0] currVector;
  reg  [VECTOR_MAX:0] selectVector;
  reg [31:0]         Pointer;

  reg  [FILE_LEN - 1:0] Wait_flags;
  reg  [FILE_LEN - 1:0] Complete;
  reg  [FILE_LEN - 1:0] Nxt_Wait_flags;

  wire               wait_update;


  // Flag inidcates when to read the next vector
  wire                Update;           // update the array pointer

  // Pointers into stimulus array
  reg    [31:0]       ArrayPt;          // pointer to current stimulus vector
  wire   [31:0]       ArrayPtNext;      // pointer to next stimulus vector

  reg    [31:0]       ArrayMax;         // limit of valid vectors in array
  reg    [31:0]       select;           // Current vector


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

    if (VERBOSE > 0)
      begin
        // report the stimulus file name
        $display(
          "%t %s %s %s",
          $time,
          MESSAGE_TAG,
          "Loading stimulus file",
          STIM_FILE_NAME
        );

        // report the stimulus array size
        $display(
          "%t %s %s %0d",
          $time,
          MESSAGE_TAG,
          "Stimulus array size",
          FILE_LEN
        );
      end

    // Load the file into memory
    $readmemh(STIM_FILE_NAME, FileMem);

    // Determine the number of vectors in the array
    ArrayMax = 32'h00000000;
    while ( (ArrayMax < FILE_LEN) &&
            (FileMem[ArrayMax] !== {VECTOR_WIDTH{1'bx}})  ) begin
      Vector = FileMem[ArrayMax];
      //Set the wait flags
      Wait_flags[ArrayMax] = Vector[11];
      ArrayMax = ArrayMax + 1;
    end

  end


//------------------------------------------------------------------------------
// Determine end of file
//------------------------------------------------------------------------------

  assign currVector = FileMem[ArrayPt];
  assign FileValid = ~SyncValid && ((select < ArrayMax) && ~selectVector[0]);
  assign SyncValid = currVector[0];

//------------------------------------------------------------------------------
// Complete logic
// (select is the current output)
//------------------------------------------------------------------------------

  //Find the first enabled non-complete transaction ID
  always @(ArrayPt or ArrayMax or Complete or ID)
     begin

          //Default
          select = ArrayPt;
          selectVector = FileMem[select];

          //non-complete ID match
          while ((Complete[select] || (selectVector[ID_TOP:ID_BASE] != ID) &&
            (select < ArrayMax) && ~selectVector[0])) begin

             //increment the pointer
             select = select + 1;
             selectVector = FileMem[select];
          end
    end

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_CompleteReg

    if (!ARESETn) begin
      Complete <= {FILE_LEN{1'b0}};
    end else if (FileReady) begin
      Complete[select] <= 1'b1;
    end
  end

//------------------------------------------------------------------------------
// Array pointer update signal
//------------------------------------------------------------------------------
  // Ready for a new vector and stimulus array not empty
  assign Update = FileReady & (FileValid | SyncValid);

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

  always @ (posedge ACLK or negedge ARESETn)
   begin : p_ArrayPtReg

    if (!ARESETn) begin
       ArrayPt <= 1; //First vector is a channel code not a vector
    end else if (Update) begin
       ArrayPt <= ArrayPt + array_jump(Complete, ArrayPt, select);
    end
  end

//------------------------------------------------------------------------------
// Update Wait_flags
//------------------------------------------------------------------------------
  always @(Wait or ArrayPt or Wait_flags or ArrayMax) begin

      Nxt_Wait_flags = Wait_flags;
      Pointer = ArrayPt;
      Vector = FileMem[Pointer];

      while ((!Vector[0]) && (Pointer < ArrayMax)) begin
           if (Vector[WAIT_BASE+EW_WIDTH-1:WAIT_BASE] == Wait) begin
              Nxt_Wait_flags[Pointer] = 1'b0;
           end
           Pointer = Pointer + 1;
           Vector = FileMem[Pointer];
      end
  end

  assign wait_update = Wait_valid;

 always @ (posedge ACLK)
  begin : p_waitflags
    if (wait_update)
      // update wait flags
      Wait_flags <= Nxt_Wait_flags;
  end

//------------------------------------------------------------------------------
// Look up values in array at pointer
//------------------------------------------------------------------------------
  assign FileData = (SyncValid) ? FileMem[ArrayPt] :
                   {selectVector[VECTOR_MAX:12], Wait_flags[select], selectVector[10:0]};


//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: Stimulus file version check
  //----------------------------------------------------------------------------
  // Check the version of the stimulus file is compatible with this hdl
  // The upper 8 bits of the first word in the file identify the version
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never
    #(0, 0, { MESSAGE_TAG,
      " Incompatible stimulus file: ", STIM_FILE_NAME }
    )
  fileversion
    (ACLK, ARESETn, (FileMem[0] >> 16) != FILE_ID);


  // OVL_ASSERT_END

`endif


endmodule

// --================================= End ===================================--

