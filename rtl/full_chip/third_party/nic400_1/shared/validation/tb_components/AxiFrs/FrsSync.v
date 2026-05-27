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
//  File Name           : FrsSync.v,v
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


module FrsSync
(
  ACLK,
  ARESETn,

  SyncReq,
  Quit,
  QValid,

  SyncGrant
);

// Module Inputs

  // Global signals
  input               ACLK;         // Clock input
  input               ARESETn;      // Reset async input active low

  // Synchronisation
  input         [4:0] SyncReq;      // Channel synchonisation requests

  // Quit signals
  input               Quit;         // Quit command found
  output              QValid;        

// Module Outputs

  // Synchronisation
  output              SyncGrant;    // Synchonisation grant

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals
  // Global Signals
  wire                ACLK;
  wire                ARESETn;

  wire          [4:0] SyncReq;

  wire                Quit;

  wire                SyncGrant;

// Internal Signals
  wire                SyncAll;          // Sync requested by all channels

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------


 //  ---------------------------------------------------------------------
  //  Synchronisation
  //  ---------------------------------------------------------------------

  // Determine if all channels are requesting syncronisation
  assign SyncAll = &SyncReq;


  // For non-poll channels, sync is not granted for polled commands
  //  until poll is complete
  assign SyncGrant  =
     (                                  // Grant on completion of poll 
      SyncAll &                         
      ~Quit                          // Do not grant following quit command,
    );

  assign QValid = Quit & SyncAll;  

endmodule

// --================================= End ===================================--




