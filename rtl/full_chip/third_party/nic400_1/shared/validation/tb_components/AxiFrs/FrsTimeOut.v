// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2003-2009 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FrsTimeOut.v,v
//  File Revision       : 1.8
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : Time out control block
//
//  Modifies the handshake based on a delay timer
//  Resets timer on SYNC commands
//  Timer counts up until specified terminal count is reached, at which time
//  data becomes valid.
//
// --=========================================================================--

`timescale 1ns / 1ps


module FrsTimeOut
(
  ACLK,
  ARESETn,
  Start,
  InputReady,
  OutputReady,
  Time

);

  // Module parameters
  parameter TIMER_WIDTH  = 32;                  // Width of timer vectors

  // Calculated parameters - do not modify
  parameter TIMER_MAX    = TIMER_WIDTH - 1 ;    // Upper bound of timer vector

  input               ACLK;             // Global clock signal
  input               ARESETn;          // Global reset signal
  input               Start;            // Resets timer
  input               InputReady;       // Valid data at input
  output              OutputReady;      // Ready to receive data at output
  input [TIMER_MAX:0] Time;            // Time when OutputValid asserted


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  // Module Inputs
  wire                ACLK;
  wire                ARESETn;
  wire                Start;
  wire                InputReady;
  wire                OutputReady;
  wire  [TIMER_MAX:0] Time;

// Internal Signals
  wire  [TIMER_MAX:0] TimerNext;        // Next value of valid delay timer
  reg   [TIMER_MAX:0] Timer;            // Valid delay timer registers
  wire                TimeOut;          // Valid delay timer times out


//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  // The modified handshake signals
  assign OutputReady  = InputReady  & TimeOut;


  // Next value of delay timer
  assign TimerNext =
            TimeOut ? {TIMER_MAX+1{1'b0}} :
            Start ? Time - {{TIMER_MAX{1'b0}}, 1'b1} : // Load new value
            Timer - {{TIMER_MAX{1'b0}}, 1'b1};  // Increment


  // Set flag when timer reaches delay value
  assign TimeOut = (Start) ? ~|Time : ~|Timer;


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

