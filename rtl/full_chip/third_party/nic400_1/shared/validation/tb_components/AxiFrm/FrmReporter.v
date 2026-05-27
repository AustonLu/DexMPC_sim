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
//  File Name           : FrmReporter.v,v
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

module FrmReporter
(
  ACLK,
  ARESETn,

  BRESP,

  RDATA,
  RRESP,

  QValid,
  QLineNum,
  Quit,
  Terminate,
  Restart,
  Stop,

  Polling,
  PollTimeOut,
  DataNe,

  BEn,
  BRespErr,
  BRespExp,
  BRespMask,
  BLineNum,

  REn,
  RDataErr,
  RDataExp,
  RDataMask,
  RRespErr,
  RRespExp,
  RRespMask,
  RLineNum
);


  // Module parameters
  parameter MESSAGE_TAG = "FileRdMasterAxi:";     // Message prefix
  parameter VERBOSE     = 1;                      // Verbosity control
  parameter DATA_WIDTH  = 64;                     // Width of data bus

  // Calculated parameters - do not modify
  parameter DATA_MAX    = DATA_WIDTH - 1;         // Upper bound of data vector

// Module Inputs

  // From AXI interface
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low

  input         [1:0] BRESP;            // Write response

  input  [DATA_MAX:0] RDATA;            // Read data
  input         [1:0] RRESP;            // Read response

  // Quit notification signals
  input               QValid;           // Indicates when to quit
  input        [31:0] QLineNum;         // Quit stimulus line number
  input               Quit;             // Quit idle command executed
  input               Restart;          // Quit restart command executed
  input               Terminate;        // Quit terminate command executed
  input               Stop;             // Quit stop command executed

  // Poll signals
  input               Polling;          // Poll in progress
  input               PollTimeOut;      // Poll has timed out
  input               DataNe;           // Data test not equal

  // Error reporing signals
  input               BEn;              // Write response error is valid
  input               BRespErr;         // Write response mismatch
  input         [1:0] BRespExp;         // Expected write response
  input         [1:0] BRespMask;        // Write response mask
  input        [31:0] BLineNum;         // Write response stimulus line number

  input               REn;              // Read error is valid
  input               RDataErr;         // Read data mismatch
  input  [DATA_MAX:0] RDataExp;         // Expected read data
  input  [DATA_MAX:0] RDataMask;        // Read data mask
  input               RRespErr;         // Read response mismatch
  input         [1:0] RRespExp;         // Expected read response
  input         [1:0] RRespMask;        // Read response mask
  input        [31:0] RLineNum;         // Read data stimulus line number

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

`define MAX_RESP_STRING_LEN 8


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                ACLK;
  wire                ARESETn;

  wire          [1:0] BRESP;

  wire   [DATA_MAX:0] RDATA;
  wire          [1:0] RRESP;

  wire                QValid;
  wire         [31:0] QLineNum;
  wire                Quit;
  wire                Restart;
  wire                Terminate;
  wire                Stop;

  wire                Polling;
  wire                PollTimeOut;
  wire                DataNe;

  wire                BRespErr;
  wire          [1:0] BRespExp;
  wire          [1:0] BRespMask;
  wire         [31:0] BLineNum;


  wire                RDataErr;
  wire   [DATA_MAX:0] RDataExp;
  wire   [DATA_MAX:0] RDataMask;
  wire                RRespErr;
  wire          [1:0] RRespExp;
  wire          [1:0] RRespMask;
  wire         [31:0] RLineNum;

// Internal Signals
  reg          [31:0] BRespErrCount;    // Number of write response errors
  reg          [31:0] RRespErrCount;    // Number of read response errors
  reg          [31:0] DataErrCount;     // Number of read data errors

  reg                 QuitReg;          // Delayed quit signal
  reg                 TermReg;          // Delayed terminate signal
  reg                 StopReg;          // Delayed stop signal

//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------

   //-----------------------------------------------------------------------
   // Function to convert the numeric response encoding to a string
   //------------------------------------------------------------------------
   function [(`MAX_RESP_STRING_LEN * 8):0] RespString;
     input [1:0]  Resp;
   begin
     // Blank the string prior to symbollic assignment
     RespString = {`MAX_RESP_STRING_LEN{8'h00}};
     // Assign the symbollic string
     case (Resp)
       `AXI_RESP_OKAY:   RespString[(4*8-1):0] = "OKAY";
       `AXI_RESP_EXOKAY: RespString[(6*8-1):0] = "EXOKAY";
       `AXI_RESP_SLVERR: RespString[(6*8-1):0] = "SLVERR";
       `AXI_RESP_DECERR: RespString[(6*8-1):0] = "DECERR";
       default:          RespString[(7*8-1):0] = "UNKNOWN";
     endcase
   end
   endfunction


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

        else if (Restart)               // Quit restart
          begin
            // Report quit restart command
            $display(
              "%t %s %s %0s %0d",
               $time,
               MESSAGE_TAG,
              "Restarting stimulus from the first vector",
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
        $display("    Data Mismatches : %0d", DataErrCount);
        $display("    Read Response Mismatches : %0d", RRespErrCount);
        $display("    Write Response Mismatches : %0d", BRespErrCount);
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
  //  BRESP Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_BRespErrCountSeq
   if  (!ARESETn)
     BRespErrCount  <= 32'h00000000;

   else if (BRespErr & BEn)
     BRespErrCount  <= BRespErrCount + 32'h00000001; // Increment error count

  end

  //  ---------------------------------------------------------------------
  //  RRESP Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_RRespErrCountSeq
   if  (!ARESETn)
     RRespErrCount  <= 32'h00000000;

   else if (RRespErr & REn & (~Polling | PollTimeOut))
     RRespErrCount  <= RRespErrCount + 32'h00000001; // Increment error count

  end

  //  ---------------------------------------------------------------------
  //  RDATA Error counter
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_RDataErrCountSeq
   if  (!ARESETn)
     DataErrCount  <= 32'h00000000;

   else if (RDataErr & REn & (~Polling | PollTimeOut))
     DataErrCount  <= DataErrCount + 32'h00000001; // Increment error count

  end


  //  ---------------------------------------------------------------------
  //  BRESP Error reporting
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_BRespErrRptBhav
      if (BRespErr & BEn)
      begin
        if (BRESP != BRespExp)
          $display(
            "%t %0s %0s %0s (%0d): %0s %0s %0s %0s %0s %0d",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Write response",
            BRespErrCount,
            "Actual:",
            RespString(BRESP),
            "Expected:",
            RespString(BRespExp),
            "at stimulus line",
            BLineNum
          );
        else           
          $display(
            "%t %0s %0s %0s (%0d): %0s %0d",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Write response user error",
            BRespErrCount,
            "at stimulus line",
            BLineNum
          );
      end	
    end

  //  ---------------------------------------------------------------------
  //  RRESP Error reporting
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_RRespErrRptBhav
      if (RRespErr & REn & (~Polling | PollTimeOut))        
      begin
        if (RRESP != RRespExp)
          $display(
            "%t %0s %0s %0s (%0d): %0s %0s %0s %0s %0s %0d",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Read response",
            RRespErrCount,
            "Actual:",
            RespString(RRESP),
            "Expected:",
            RespString(RRespExp),
            "at stimulus line",
            RLineNum
          );
        else           
          $display(
            "%t %0s %0s %0s (%0d): %0s %0d",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Possible Read response user error",
            RRespErrCount,
            "at stimulus line",
            RLineNum
          );
      end

    end

  //  ---------------------------------------------------------------------
  //  RDATA Error reporting
  //  ---------------------------------------------------------------------

  always @ (posedge ACLK)
    begin : p_DataErrRptBhav
      if (RDataErr & REn & (~Polling | PollTimeOut))
          $display(
            "%t %0s %0s %0s (%0d): %0s 0x%x %0s %0s 0x%x %0s 0x%x %0s %0d",
            $time,
            MESSAGE_TAG,
            "ERROR:",
            "Read data",
            DataErrCount,
            "Actual:",
            RDATA,
            "Expected:",
            DataNe ? "ne": "eq",
            RDataExp,
            "Mask",
            RDataMask,
            "at stimulus line",
            RLineNum
          );

    end


endmodule

// --================================= End ===================================--

