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
//  File Name           : FrmC.v,v
//  File Revision       : 1.7
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : File reader master C group interface
//
//                        Accepts a request on AXI C group to enter low-power
//                        mode only once the LpGrant input is asserted.
//                        Exit from low power mode is always acknowledged.
//                        Deasserts the nLpReq output when low power mode
//                        is requested, to prevent FRM proceeding past SYNC
//                        commands.
//                        Asserts the nLpReq output when low power mode is
//                        exited so that normal operation can continue.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmC
(
  ACLK,
  ARESETn,
  CSYSREQ,
  LpGrant,

  nLpReq,
  CACTIVE,
  CSYSACK
);

  // Module Inputs
  input               ACLK;             // Clock input
  input               ARESETn;          // Reset async input active low
  input               CSYSREQ;          // Power enable input
  input               LpGrant;          // Low power mode accepted input

  // Module Outputs
  output              nLpReq;           // nLpReq output
  output              CACTIVE;          // Power request
  output              CSYSACK;          // Power acknowledge


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  wire                ACLK;
  wire                ARESETn;
  wire                CSYSREQ;
  wire                LpGrant;

  wire                nLpReq;
  wire                CACTIVE;
  wire                CSYSACK;

// Internal Signals
  wire                CSysAckNext;      // Next value of CSYSACK

  // Internal versions of output signals
  reg                 iCActive;         // Internal CACTIVE
  reg                 iCSysAck;         // Internal CSYSACK


//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  // Drive the nLpReq signal with the power enable signal from the AXI interface
  assign nLpReq = CSYSREQ;

  // Low power request (CSYSREQ low) is acknowledged when the FRM is not active.
  // Normal operation request (CSYSREQ high) is acknowledged immediately.
  assign CSysAckNext = CSYSREQ ? 1'b1 : (
                       // normal operation request

                       (~CSYSREQ & LpGrant & ~iCActive) ? 1'b0 :
                       // low power request granted and CACTIVE is low

                       iCSysAck);
                       // otherwise keep stable

  // CSYSACK register
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_CsysAckSeq
      if (!ARESETn)
        iCSysAck <= 1'b1;
      else
        iCSysAck <= CSysAckNext;
    end


  // Assert power request whenever low power not granted
  always @ (negedge ARESETn or posedge ACLK)
    begin : p_CActiveSeq
      if (!ARESETn)
        iCActive <= 1'b1;
      else
        iCActive <= ~LpGrant;
    end


  //  ---------------------------------------------------------------------
  //  Drive outputs with internal signal
  //  ---------------------------------------------------------------------

  assign CACTIVE = iCActive;
  assign CSYSACK = iCSysAck;


endmodule

// --================================= End ===================================--

