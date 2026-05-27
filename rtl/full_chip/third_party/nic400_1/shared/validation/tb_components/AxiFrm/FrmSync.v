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
//  File Name           : FrmSync.v,v
//  File Revision       : 1.8
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master synchronisation and poll controller
//
//                        Controls the synchronisation grant signals
//                        and the R and AR channels during polled commands
//
// --=========================================================================--

`timescale 1ns / 1ps


module FrmSync
(
  ACLK,
  ARESETn,

  nLpReq,
  SyncReq,
  ResetSync,
  Quit,
  Restart,
  PollRepeats,
  PollReq,
  AEn,
  REn,
  DataErr,
  RespErr,

  SyncGrantP,
  SyncGrantNP,
  LpGrant,
  Polling,
  PollPhaseA,
  PollTimeOut,
  PollDone,
  ResetTimer
);


  // Module parameters
  parameter TIMER_WIDTH = 32;               // Width of timer vectors

  // Calculated parameters - do not modify
  parameter TIMER_MAX   = TIMER_WIDTH - 1;  // Upper bound of timer vector


// Module Inputs

  // Global signals
  input               ACLK;         // Clock input
  input               ARESETn;      // Reset async input active low

  // Synchronisation
  input               nLpReq;       // Low power request active low
  input         [4:0] SyncReq;      // Channel synchonisation requests
  input               ResetSync;    // Reset timers on SYNC command

  // Quit signals
  input               Quit;         // Quit command found
  input               Restart;      // Restart stimulus from first command

  // Poll signals
  input [TIMER_MAX:0] PollRepeats;  // Number of poll repeats
  input               PollReq;      // Poll request

  input               AEn;          // Poll addresss phase complete
  input               REn;          // Poll data phase complete
  input               DataErr;      // Read data mismatch
  input               RespErr;      // Read response mismatch

// Module Outputs

  // Synchronisation
  output              SyncGrantP;   // Synchonisation grant to poll channels
  output              SyncGrantNP;  // Synchonisation grant to non-poll channels
  output              LpGrant;      // Low power mode grant

  // Poll signals
  output              Polling;      // Poll in progress
  output              PollPhaseA;   // Poll read address enable
  output              PollTimeOut;  // Poll timed out
  output              PollDone;     // Polling and poll done
  output              ResetTimer;   // Reset the delay timer

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  // Global Signals
  wire                ACLK;
  wire                ARESETn;

  wire                nLpReq;
  wire          [4:0] SyncReq;
  wire                ResetSync;

  wire                Quit;
  wire                Restart;

  wire  [TIMER_MAX:0] PollRepeats;
  wire                PollReq;

  wire                AEn;
  wire                REn;
  wire                DataErr;
  wire                RespErr;

  wire                SyncGrantP;
  wire                SyncGrantNP;
  wire                LpGrant;

  wire                Polling;
  wire                PollPhaseA;
  wire                PollTimeOut;
  wire                PollDone;
  wire                ResetTimer;


// Internal Signals
  wire                SyncAll;          // Sync requested by all channels

  // Poll control signals
  wire                PollingNext;      // Next value of Polling
  wire                PollSuccess;      // Poll sucessful

  reg   [TIMER_MAX:0] PollCount;        // Poll timeout counter
  wire  [TIMER_MAX:0] PollCountNext;    // Next value of PollCount
  wire                PollPhaseANext;   // Next value of PollPhaseA

  // Internal versions of output signals
  wire                iSyncGrantP;      // Internal SyncGrantP
  reg                 iPolling;         // Internal Polling
  reg                 iPollPhaseA;      // Internal PollPhaseA
  wire                iPollTimeOut;     // Internal PollTimeOut
  wire                iPollDone;        // Internal PollDone

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------


 //  ---------------------------------------------------------------------
  //  Synchronisation
  //  ---------------------------------------------------------------------

  // Determine if all channels are requesting syncronisation
  assign SyncAll    = &SyncReq;


  // For non-poll channels, sync is not granted for polled commands
  //  until poll is complete
  assign SyncGrantNP  =
    iPollDone | (                       // Grant on completion of poll
      ~PollReq &                        // Poll is not requested
      SyncAll &                         // SyncReq from all channels
      (nLpReq |                         // Low power mode not requested
                ~ResetSync) &           //  or cannot accept low power request
      (~Quit |                          // Do not grant following quit command,
               Restart)                 //  unless restart is requested
    );

  // Synchronisation to poll channels (AR and R) occurs when all channels are 
  // requesting syncronisation, and also and on completion of poll
  assign iSyncGrantP =
    iPollDone | (                       // Grant on completion of poll
      SyncAll &                         // SyncReq from all channels
      (nLpReq |                         // Low power mode not requested
                ~ResetSync | PollReq) & //  or cannot accept low power request
      (~Quit |                          // Do not grant following quit command,
               Restart)                 //  unless restart is requested
    );

  // For low power channel, sync is not granted for polled commands, nor
  // for implicit SYNC commands that are inserted during locked sequences
  // because low power request can only be accepted on explicity SYNC commands
  assign LpGrant   = SyncAll & ResetSync & ~PollReq;


  //  ---------------------------------------------------------------------
  //  Poll logic
  //  ---------------------------------------------------------------------
  assign PollingNext = (~iPollDone) &
                       ((PollReq & iSyncGrantP) |
                       iPolling);


  // Polling register
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_PollingSeq
      if (!ARESETn)
        iPolling <= 1'b0;

      else
        iPolling <= PollingNext;

    end


  //  ---------------------------------------------------------------------
  //  Poll timing generation
  //  ---------------------------------------------------------------------

  // Reset timer on each poll iteration
  assign ResetTimer = iPolling & REn;


  //  ---------------------------------------------------------------------
  //  Poll completion
  //  ---------------------------------------------------------------------

  // Poll is successful when comparison passes
  assign PollSuccess  = ~DataErr & ~RespErr;

  // Poll times out when timer reaches zero
  assign iPollTimeOut = (PollCount == {{TIMER_MAX{1'b0}}, 1'b1});

  // Poll is done when polling, read transfer is valid
  //  and poll either succeeds or times out
  assign iPollDone    = iPolling & REn & (iPollTimeOut | PollSuccess);


  //  ---------------------------------------------------------------------
  //  Poll timeout counter
  //  ---------------------------------------------------------------------

  // Next value of poll timeout counter
  assign PollCountNext =
            iSyncGrantP ?
              PollRepeats :                         // Load on sync event
            (PollCount == {TIMER_WIDTH{1'b0}}) ?
              PollCount:                            // Never time out if zero
            (REn) ?
              PollCount - {{TIMER_MAX{1'b0}}, 1'b1}:// Decrement each iteration
            PollCount;                              // Hold previous value


  // Poll timeout couner
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_PollCountSeq
      if (!ARESETn)
        PollCount <= {TIMER_WIDTH{1'b0}};

      else
        PollCount <= PollCountNext;

    end


  //  ---------------------------------------------------------------------
  //  Poll address channel waiting
  //  ---------------------------------------------------------------------
  // The read address for repeated commands during a poll is not issued until
  // the read transfer has completed. The signal PollPhaseA is used to enable
  // the start of the read address transfer.

  // Determine if poll iteration not complete
  assign PollPhaseANext = ~iPolling |     // Enable AR commands if not polling
                          (
                            ~AEn &        // Reset when address phase complete
                            (REn |        // Set when read phase complete
                            iPollPhaseA)  // Hold term
                          );


  // Command done register
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_ARDoneSeq
      if (!ARESETn)
        iPollPhaseA <= 1'b1;

      else
        iPollPhaseA <= PollPhaseANext;

    end


  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign SyncGrantP   = iSyncGrantP;
  assign Polling      = iPolling;
  assign PollPhaseA   = iPollPhaseA;
  assign PollTimeOut  = iPollTimeOut;
  assign PollDone     = iPollDone;


endmodule

// --================================= End ===================================--




