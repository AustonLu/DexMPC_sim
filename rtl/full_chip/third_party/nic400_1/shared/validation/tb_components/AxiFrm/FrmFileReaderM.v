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
//  File Name           : FrmFileReader.v,v
//  File Revision       : 1.10
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : FRM file reader
//
//                        A behavioral module that converts values in
//                        a stimulus file into signals. Asserts FileValid until
//                        file is exhausted. File pointer is reset by Restart
//                        input.
//
//                        This is non-re-ordering master FileReader.
// 
//                        It also monitors the wait bus and sets the wait flag
//                        will update any waits between the current location
//                        and the next sync (irrespective of ID)
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmFileReaderM
(
  ACLK,
  ARESETn,
  FileReady,
  Restart,

  Wait,
  Wait_valid,
  
  FileValid,
  FileData
);


  // Module parameters
  parameter FILE_LEN    = 1000;                   // Length of stimulus memory
  parameter STIM_FILE_NAME    = "undef";                // stimulus file name
  parameter VECTOR_WIDTH  = 128;                  // Width of stimulus memory
  parameter MESSAGE_TAG    = "FileRdMasterAxi:";  // Message prefix
  parameter VERBOSE       = 1;                    // Verbosity control
  parameter FILE_ID       = 16'hc001;             // Used to identify file type
  parameter WAIT_BASE     = 0;
  parameter EW_WIDTH      = 8;

  // Calculated parameters - do not modify
  parameter VECTOR_MAX
              = VECTOR_WIDTH - 1;       // Upper bound of stimulus memory vector

  parameter EW_MAX = EW_WIDTH -1;

  // Module Inputs
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               FileReady;        // Read another vector
  input               Restart;          // Restart stimulus from first vector

  input [EW_MAX:0]    Wait;             //Incoming wait bus
  input               Wait_valid;       //Wait valid signal

  // Module Outputs
  output              FileValid;        // Valid vector in file
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
  wire                Restart;

  wire                FileValid;
  wire [VECTOR_MAX:0] FileData;


// Internal Signals

  // File array of length specified by FILE_LEN.
  // Contains the vector data from the file
  reg  [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array

  reg  [VECTOR_MAX:0] Vector;
  wire  [VECTOR_MAX:0] currVector;
  reg [31:0]         Pointer;

  reg  [FILE_LEN - 1:0] Wait_flags;
  reg  [FILE_LEN - 1:0] Nxt_Wait_flags;

  wire               wait_update; 


  // Flag indicates that there is valid data in the array
  reg                 iFileValid;       // internal FileValid
  wire                FileValidNext;    // next FileValid


  // Flag inidcates when to read the next vector
  wire                Update;           // update the array pointer

  // Pointers into stimulus array
  reg    [31:0]       ArrayPt;          // pointer to current stimulus vector
  wire   [31:0]       ArrayPtNext;      // pointer to next stimulus vector

  reg    [31:0]       ArrayMax;         // limit of valid vectors in array


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

  assign FileValidNext = (ArrayPtNext < ArrayMax) ? 1'b1 : 1'b0;

//------------------------------------------------------------------------------
// File Valid register
//------------------------------------------------------------------------------
// Sequential process that updates the FileValid signal, indicating when
// the output vector is valid

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_FileValidReg

    if (!ARESETn)
      iFileValid <= 1'b0;

    else
      // update array pointer
      iFileValid <= FileValidNext;
  end


//------------------------------------------------------------------------------
// Array pointer update signal
//------------------------------------------------------------------------------
  // Ready for a new vector and stimulus array not empty
  assign Update = FileReady & iFileValid;

//------------------------------------------------------------------------------
// Next value of array pointer
//------------------------------------------------------------------------------
  assign ArrayPtNext = Update ? ( Restart ? 1 : ArrayPt + 1 ) :
                       ArrayPt;


//------------------------------------------------------------------------------
// Update array pointer
//------------------------------------------------------------------------------
// Sequential process that updates the stimulus array pointer

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_ArrayPtReg

    if (!ARESETn)
      ArrayPt <= 1; // First vector is at FileData 1 (header at FileData 0)

    else 
      // update array pointer
      ArrayPt <= ArrayPtNext;
  end

//------------------------------------------------------------------------------
// Update Wait_flags
//------------------------------------------------------------------------------
  always @(Wait or ArrayPt or Wait_flags or ArrayMax or Restart) begin 

      Nxt_Wait_flags = Wait_flags;
      Pointer = (Restart) ? 32'b0 : ArrayPt;
      Vector = FileMem[Pointer];

      while (Pointer < ArrayMax) begin
           if (Vector[WAIT_BASE+EW_WIDTH-1:WAIT_BASE] == Wait) begin
              Nxt_Wait_flags[Pointer] = 1'b0;   
           end

           if (Restart) begin
              Nxt_Wait_flags[Pointer] = Vector[11];
           end  

           Pointer = Pointer + 1;
           Vector = FileMem[Pointer];

      end
  end

  assign wait_update = Wait_valid | Restart;

 always @ (posedge ACLK)
  begin : p_waitflags
    if (wait_update)
      // update wait flags
      Wait_flags <= Nxt_Wait_flags;
  end

//------------------------------------------------------------------------------
// Look up values in array at pointer
//------------------------------------------------------------------------------
  assign currVector = FileMem [ArrayPt];
  assign FileData = {currVector[VECTOR_MAX:12], Wait_flags[ArrayPt], currVector[10:0]};

//------------------------------------------------------------------------------
// Drive output signals with internal version
//------------------------------------------------------------------------------
   assign FileValid = iFileValid;


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

