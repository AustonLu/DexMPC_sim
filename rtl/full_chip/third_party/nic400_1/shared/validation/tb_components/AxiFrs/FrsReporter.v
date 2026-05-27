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
//  File Name           : FrsReporter.v,v
//  File Revision       : 1.26
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master message reporter
//
//                        A behavioural module that issues messages to the
//                        simulation environment.
//
// --=========================================================================--

`timescale 1ns / 1ps

`include "Axi.v"

module FrsReporter
(
  ACLK,
  ARESETn,

  WDATA,
  WSTRB,

  QValid,
  QLineNum,
  Quit,
  Terminate,
  Stop,

  WEn,
  WErr,

  AWEn,
  AWErr,

  AREn,
  ARErr
);


  // Module parameters
  parameter MESSAGE_TAG = "FileRdSlaveAxi:";     // Message prefix
  parameter VERBOSE     = 1;                     // Verbosity control
  parameter DATA_WIDTH  = 64;                    // Width of data bus

  // Calculated parameters - do not modify
  parameter DATA_MAX    = DATA_WIDTH - 1;        // Upper bound of data vector
  parameter STRB_MAX    = (DATA_WIDTH / 8) - 1;  // Upper bound of strobe vector

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  input  [DATA_MAX:0] WDATA;            // Write data
  input  [STRB_MAX:0] WSTRB;            // Write Strobes

  // Quit notification signals
  input               QValid;           // Indicates when to quit
  input        [31:0] QLineNum;         // Quit stimulus line number
  input               Quit;             // Quit idle command executed
  input               Terminate;        // Quit terminate command executed
  input               Stop;             // Quit stop command executed

  // Error reporing signals
  input               WEn;              // Write data error is valid
  input               WErr;

  input               AWEn;             // Write Address mismatch is valid
  input               AWErr;            // AW Mismatch

  input               AREn;             // Read Address mismatch is valid
  input               ARErr;            // AR Mismatch

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

`define MAX_RESP_STRING_LEN 8


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

 // From AXI interface
  wire               ACLK;             // Clock input
  wire               ARESETn;          // Reset async input active low

//  wire  [DATA_MAX:0] WDATA;            // Write data
//  wire  [STRB_MAX:0] WSTRB;            // Write Strobes

  // Quit notification signals
  wire               QValid;           // Indicates when to quit
  wire        [31:0] QLineNum;         // Quit stimulus line number
  wire               Quit;             // Quit idle command executed
  wire               Terminate;        // Quit terminate command executed
  wire               Stop;             // Quit stop command executed

  // Error reporing signals
//  wire               WEn;              // Write data error is valid
//  wire               WDataErr;         // Write data mismatch
//  wire  [DATA_MAX:0] WDataExp;         // Expected Write Data
//  wire  [STRB_MAX:0] WStrbExp;         // Expected Strobe access
//  wire        [31:0] WLineNum;         // Write Error Line Num

  wire               AWEn;             // Write Address mismatch is valid
  wire               AWErr;            // AW Mismatch

  wire               AREn;             // Read Address mismatch is valid
  wire               ARErr;            // AR Mismatch


// Internal Signals
  reg         [31:0] WErrCount;    // Number of write response errors
  reg         [31:0] ARErrCount;    // Number of read response errors
  reg         [31:0] AWErrCount;    // Number of read response errors

  reg                QuitReg;          // Delayed quit signal
  reg                TermReg;          // Delayed terminate signal
  reg                StopReg;          // Delayed stop signal

//------------------------------------------------------------------------------
// Beginning of main code (behavioral)
//------------------------------------------------------------------------------

  //  ---------------------------------------------------------------------
  //  Set up the time format
  //  ---------------------------------------------------------------------

  initial
  begin : p_TimeFormatBhav
      $timeformat(-9, 0, " ns", 0);
  end


  //  ---------------------------------------------------------------------
  //  Sign-on banner at exit from reset
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
    begin : p_Banner
      reg BannerDone; // Flag indicates banner already displayed

      if (!ARESETn)
        BannerDone <= 1'b0;

      else if (!BannerDone)
        begin
          BannerDone <= 1'b1;

          if (VERBOSE > 0)
            begin
              $display("%t %s", $time, MESSAGE_TAG);
              $display("");
              $display("  **********************************************");
              $display("  **** ARM File Reader Master AXI");
              $display("  **** (C) ARM Limited 2004");
              $display("  **********************************************");
              $display("");
            end
        end
    end


  //  ---------------------------------------------------------------------
  //  Behavioral Quit and Quit messages
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
  begin : p_QuitBhav

    if (QValid & Quit & ~QuitReg & (VERBOSE > 0))
      begin

        if (Terminate)                  // Quit terminate
          begin
            // Report quit terminate command
            $display(
              "%t %s %s %0s %0d",
               $time,
               MESSAGE_TAG,
              "Simulation terminated",
              "at stimulus line",
              QLineNum
            );
          end

        else if (Stop)                  // Quit stop
          begin
            // Report quit stop command
            $display(
              "%t %s %s %0s %0d",
               $time,
               MESSAGE_TAG,
              "Simulation halted",
              "at stimulus line",
              QLineNum
            );
          end

        else                            // Quit idle
          begin
            // Report quit idle command
            $display(
              "%t %s %s %0s %0d",
               $time,
               MESSAGE_TAG,
              "Stimulus complete",
              "at stimulus line",
              QLineNum
            );
          end

        $display("%t %s", $time, MESSAGE_TAG);
        $display("");
        $display("  ************************************************");
        $display("  Simulation Summary:");
        $display("    W Channel Mismatches : %0d", WErrCount);
        $display("    AW Channel Mismatches : %0d", AWErrCount);
        $display("    AR Channel Mismatches : %0d", ARErrCount);
        $display("  ************************************************");
        $display("");
      end

  end


  //  ---------------------------------------------------------------------
  //  Register quit signal so that quit messges happen once only
  //  ---------------------------------------------------------------------
  always @ (posedge ACLK or negedge ARESETn)
    begin : p_QuitReg
      if (!ARESETn)
        QuitReg <= 1'b0;

      else if (QValid)
        QuitReg <= Quit;
    end


  //  ---------------------------------------------------------------------
  //  Register quit terminate signal so that quit always happens after summary
  //  ---------------------------------------------------------------------
  always @ (posedge ACLK or negedge ARESETn)
    begin : p_TermReg
      if (!ARESETn)
        TermReg <= 1'b0;

      else if (QValid)
        TermReg <= Terminate;
    end


  //  ---------------------------------------------------------------------
  //  Terminate the simulation
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
  begin : p_TermBhav
    if (TermReg)
      $finish;
  end


  //  ---------------------------------------------------------------------
  //  Register quit stop signal so that quit always happens after summary
  //  ---------------------------------------------------------------------
  always @ (posedge ACLK or negedge ARESETn)
    begin : p_StopReg
      if (!ARESETn)
        StopReg <= 1'b0;

      else if (QValid)
        StopReg <= Stop;
    end



  //  ---------------------------------------------------------------------
  //  Stop the simulation
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
  begin : p_StopBhav
    if (StopReg)
      $stop;
  end


  //  ---------------------------------------------------------------------
  //  W Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_WErrCountSeq
   if  (!ARESETn)
     WErrCount  <= 32'h00000000;

   else if (WErr & WEn)
     WErrCount  <= WErrCount + 32'h00000001; // Increment error count

  end

  //  ---------------------------------------------------------------------
  //  AW Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_AWErrCountSeq
   if  (!ARESETn)
     AWErrCount  <= 32'h00000000;

   else if (AWErr & AWEn)
     AWErrCount  <= AWErrCount + 32'h00000001; // Increment error count

  end

  //  ---------------------------------------------------------------------
  //  AR Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_ARErrCountSeq
   if  (!ARESETn)
     ARErrCount  <= 32'h00000000;

   else if (ARErr & AREn)
     ARErrCount  <= ARErrCount + 32'h00000001; // Increment error count

  end  

  //  ---------------------------------------------------------------------
  //  W Error Report
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_WErrRptBhav
      if (WErr & WEn)
          $display(
            "%t %0s %0s %0s (%0d)",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Incorrect or Unexpected W beat received",
            WErrCount
          );

    end

  //  ---------------------------------------------------------------------
  //  AW Error Report
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_AWErrRptBhav
      if (AWErr & AWEn)
          $display(
            "%t %0s %0s %0s (%0d)",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Incorrect or Unexpected AW beat received",
            AWErrCount
          );

    end

  //  ---------------------------------------------------------------------
  //  AR Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_ARErrRptBhav
      if (ARErr & AREn)
          $display(
            "%t %0s %0s %0s (%0d)",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Incorrect or Unexpected AR beat received",
            ARErrCount
          );

    end

endmodule

// --================================= End ===================================--

