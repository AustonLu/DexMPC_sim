// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2003-2013 ARM Limited
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
//  Purpose             : Timer control block
//
//  Modifies the handshake based on a delay timer
//  Resets timer on SYNC commands
//  Timer counts up until specified terminal count is reached, at which time
//  data becomes valid.
//
// --=========================================================================--

`timescale 1ns / 1ps


module FrsTimer
(
  ACLK,
  ARESETn,
  Sync,
  Time
);

  // Module parameters
  parameter TIMER_WIDTH  = 32;                  // Width of timer vectors

  // Calculated parameters - do not modify
  parameter TIMER_MAX    = TIMER_WIDTH - 1 ;    // Upper bound of timer vector

  // Module Inputs
  input               ACLK;             // Global clock signal
  input               ARESETn;          // Global reset signal
  input               Sync;             // Resets timer
  output [TIMER_MAX:0] Time;            // Time when OutputValid asserted


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  // Module Inputs
  wire                ACLK;
  wire                ARESETn;
  wire                Sync;
  wire  [TIMER_MAX:0] Time;

// Internal Signals
  wire  [TIMER_MAX:0] TimerNext;        // Next value of valid delay timer
  reg   [TIMER_MAX:0] Timer;            // Valid delay timer registers


//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  assign Time = Timer;

  // Next value of delay timer
  assign TimerNext =
            Sync ?  {{TIMER_MAX{1'b0}}, 1'b1} : // Reset to 0x01 if sync granted
            Timer + {{TIMER_MAX{1'b0}}, 1'b1};  // Increment

  // Timer and TimeOut registers
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_TimerSeq
      if (!ARESETn)
        Timer <= {TIMER_WIDTH{1'b0}};

      else
        Timer <= TimerNext;

    end



endmodule

// --================================= End ===================================--

