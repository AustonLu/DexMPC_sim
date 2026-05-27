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
//  File Name           : FrmMsg.v,v
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

module FrmMsg
(
  ACLK,
  ARESETn,
  CommentReq,
  AEn,
  Polling,
  PollDone,
  Restart
);


  // Module parameters
  parameter FILE_ARRAY_SIZE = 1000;               // Size of command array
  parameter STIM_FILE_NAME        = "undef";            // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:"; // Message prefix
  parameter VERBOSE         = 1;                  // Verbosity control

  // Calculated parameters - do not modify
  parameter VECTOR_WIDTH = 8*80;                  // Length of file vector
  parameter VECTOR_MAX = VECTOR_WIDTH - 1 ;       // Upper bound of file vector

// Module Inputs

  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               CommentReq;       // Comment is requested
  input               AEn;              // Address transfer completed
  input               Polling;          // Polling current command
  input               PollDone;         // Polling and poll done
  input               Restart;          // Restart stimulus from first command

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                ACLK;    
  wire                ARESETn; 
  wire                CommentReq;
  wire                AEn;     
  wire                Polling; 
  wire                PollDone;
  wire                Restart; 

// Internal Signals

  wire [VECTOR_MAX:0] FileData;         // Concatenated vector from file reader
  wire                FileValid;        // File not empty
  wire                FileReady;        // Fetch new comment from file
  reg                 CommentDone;      // Comment associated with current 
                                        //  transfer has been issued.
  wire                CommentDoneNext;  // Next value of CommentDone

//------------------------------------------------------------------------------
// Beginning of main code (behavioral)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  File reader
  //  ---------------------------------------------------------------------

  FrmFileReader
    // Positionally mappd module parameters
    #(FILE_ARRAY_SIZE,
      STIM_FILE_NAME,
      VECTOR_WIDTH,
      MESSAGE_TAG,
      VERBOSE,
      16'hc001                          // File ID for comment file
    )
  uReader
  (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),
    .FileReady      (FileReady),
    .Restart        (Restart),

    .FileValid      (FileValid),
    .FileData       (FileData)
  );


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
            FileData
          );
    end

  //  ---------------------------------------------------------------------
  //  Handshake logic
  //  ---------------------------------------------------------------------

  // Fetch a comment from the file
  assign FileReady = CommentReq & ~CommentDone;
  
  // Determine if comment has already been issued
  assign CommentDoneNext =
    ~(AEn & ~Polling) &                 // Reset on handshake unless polling
    ~PollDone &                         // Reset when polled command completes
    (    
      CommentReq |                      // Set when comment is issued
      CommentDone                       // Keep previous value
    );
  
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
  // COmment file has underflowed.
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never
    #(0, 0, { MESSAGE_TAG,
      " Comment file underflow" }
    )
  frmaxicommentunderflow
    (ACLK, ARESETn,
      FileReady & ~FileValid);

  // OVL_ASSERT_END

`endif


endmodule

// --================================= End ===================================--

