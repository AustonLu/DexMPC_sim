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
//  File Name           : FrsMsg.v,v
//  File Revision       : 1.1
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master simulation comment issuer
//
//                        Issues comments to the simulation envirmonment
//                        from internal arrey when requested 
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrsMsg
(
  ACLK,
  ARESETn,
  CommentReq,
  AEn,
  LineNum
);


  // Module parameters
  parameter FILE_LEN    = 1000;                   // Length of stimulus memory
  parameter STIM_FILE_NAME  = "filestim.c";       // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control

  // Calculated parameters - do not modify
  parameter VECTOR_WIDTH = 8*80 + 32;             // Length of file vector
  parameter VECTOR_MAX = VECTOR_WIDTH - 1 ;       // Upper bound of file vector

// Module Inputs

  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               CommentReq;       // Comment is requested
  input               AEn;              // Address transfer completed
  input [31:0]        LineNum;          // Comment Line Number

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                ACLK;    
  wire                ARESETn; 
  wire                CommentReq;
  wire                AEn;     
  wire [31:0]         LineNum; 

// Internal Signals

  reg [VECTOR_MAX:0]  FileData;         // Concatenated vector from file reader
  reg                 CommentDone;      // Comment associated with current 
                                        //  transfer has been issued.
  wire                CommentDoneNext;  // Next value of CommentDone

  reg  [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array
  reg  [31:0]         ArrayPt;          // pointer to current stimulus vector 
  reg  [31:0]         ArrayMax;         // limit of valid vectors in array

//------------------------------------------------------------------------------
// Beginning of main code (behavioral)
//------------------------------------------------------------------------------

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
            (FileMem[ArrayMax] !== {VECTOR_WIDTH{1'bx}})  )
      ArrayMax = ArrayMax + 1;

  end

  //  ---------------------------------------------------------------------
  //  Find the comment in the file
  //  ---------------------------------------------------------------------

  always @(ArrayMax or LineNum) begin

     //Default 
     ArrayPt = 1;
     FileData = FileMem[ArrayPt];

     //find the first Enabled ID match
     while ((FileData[31:0] != LineNum) && 
            (ArrayPt < ArrayMax)) begin 

             //increment the pointer
             ArrayPt = ArrayPt + 1;
             FileData = FileMem[ArrayPt];
     end

  end 
  
  //  ---------------------------------------------------------------------
  //  Issue the comment to the simulation environment
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_CommentBhav
      if ((CommentReq & ~CommentDone) & (VERBOSE > 0))
          $display(
            "%t %0s %0s",
            $time,
            MESSAGE_TAG,
            FileData[VECTOR_MAX:32]
          );
    end

  //  ---------------------------------------------------------------------
  //  Handshake logic
  //  ---------------------------------------------------------------------

  // Determine if comment has already been issued
  assign CommentDoneNext = ~(AEn) & (CommentReq | CommentDone);  
  
  // Sequential prpcess to update CommentDone signal
  always @ (posedge ACLK or negedge ARESETn)
  begin : p_CommentDoneSeq
   if  (!ARESETn)
     CommentDone  <= 1'b0;
   else
     CommentDone  <= CommentDoneNext;
  end


//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: Comment file underflow
  //----------------------------------------------------------------------------
  // Comment not found.
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never
    #(0, 0, { MESSAGE_TAG,
      " Comment not found" }
    )
  frmcommentnotfound
    (ACLK, ARESETn,
     (CommentReq & (ArrayPt == ArrayMax)));

  // OVL_ASSERT_END

`endif


endmodule

// --================================= End ===================================--

