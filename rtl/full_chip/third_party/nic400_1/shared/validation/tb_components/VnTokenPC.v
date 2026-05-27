//============================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2011-2012 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 134081
//
// Date                   :  2012-07-21 23:21:26 +0100 (Sat, 21 Jul 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose: Single channel Virtual Network Token Interface Protocol Checker
//============================================================================--


`timescale 1ns/1ns

module VnTokenPC
(

   // AXI Channel Signals
   AWVALID,
   AWVALID_VECT,
   AWREADY,
   AWVNET,
   AWID,
   WVALID,
   WREADY,
   WVNET,
   ARVALID,
   ARVALID_VECT,
   ARREADY,
   ARVNET,
   ARID,

   // Token Interface Signals 0
   VAWVALID_0,
   VAWREADY_0,
   VAWQOS_0,
   VWVALID_0,
   VWREADY_0,
   VARVALID_0,
   VARREADY_0,
   VARQOS_0,

   // Token Interface Signals 1
   VAWVALID_1,
   VAWREADY_1,
   VAWQOS_1,
   VWVALID_1,
   VWREADY_1,
   VARVALID_1,
   VARREADY_1,
   VARQOS_1,

   // Token Interface Signals 2
   VAWVALID_2,
   VAWREADY_2,
   VAWQOS_2,
   VWVALID_2,
   VWREADY_2,
   VARVALID_2,
   VARREADY_2,
   VARQOS_2,

   // Token Interface Signals 3
   VAWVALID_3,
   VAWREADY_3,
   VAWQOS_3,
   VWVALID_3,
   VWREADY_3,
   VARVALID_3,
   VARREADY_3,
   VARQOS_3,

   // Token Interface Signals 4
   VAWVALID_4,
   VAWREADY_4,
   VAWQOS_4,
   VWVALID_4,
   VWREADY_4,
   VARVALID_4,
   VARREADY_4,
   VARQOS_4,

   // Token Interface Signals 5
   VAWVALID_5,
   VAWREADY_5,
   VAWQOS_5,
   VWVALID_5,
   VWREADY_5,
   VARVALID_5,
   VARREADY_5,
   VARQOS_5,

   // Token Interface Signals 6
   VAWVALID_6,
   VAWREADY_6,
   VAWQOS_6,
   VWVALID_6,
   VWREADY_6,
   VARVALID_6,
   VARREADY_6,
   VARQOS_6,

   // Token Interface Signals 7
   VAWVALID_7,
   VAWREADY_7,
   VAWQOS_7,
   VWVALID_7,
   VWREADY_7,
   VARVALID_7,
   VARREADY_7,
   VARQOS_7,

   // Token Interface Signals 8
   VAWVALID_8,
   VAWREADY_8,
   VAWQOS_8,
   VWVALID_8,
   VWREADY_8,
   VARVALID_8,
   VARREADY_8,
   VARQOS_8,

   // Token Interface Signals 9
   VAWVALID_9,
   VAWREADY_9,
   VAWQOS_9,
   VWVALID_9,
   VWREADY_9,
   VARVALID_9,
   VARREADY_9,
   VARQOS_9,

   // Token Interface Signals 10
   VAWVALID_10,
   VAWREADY_10,
   VAWQOS_10,
   VWVALID_10,
   VWREADY_10,
   VARVALID_10,
   VARREADY_10,
   VARQOS_10,

   // Token Interface Signals 11
   VAWVALID_11,
   VAWREADY_11,
   VAWQOS_11,
   VWVALID_11,
   VWREADY_11,
   VARVALID_11,
   VARREADY_11,
   VARQOS_11,

      // Token Interface Signals 11
   VAWVALID_12,
   VAWREADY_12,
   VAWQOS_12,
   VWVALID_12,
   VWREADY_12,
   VARVALID_12,
   VARREADY_12,
   VARQOS_12,

   // Global Signals
   ACLK,
   ARESETn

);


//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------


  // Parameters below can be set by the user.

  // Select the number of channel ID bits required
  parameter ID_WIDTH = 4;          // (A|W|R|B)ID width

  parameter VALID_WIDTH = 1;

  // Set VNET number for the virtual network being checked by this instance
  parameter VNET = 4'b0;         // VNET number, default = 0

  // valid_vect mask for non_vn transfers
  parameter NON_VN_MASK = 0;

  //parameter for prerequest
  parameter PREREQUEST = 0;

  //parameter for direction : 0 = upstream, 1 = downstram
  parameter DIRECTION = 0;

  // Calculated (user should not override)
  // =====================================
  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  localparam VALID_MAX = VALID_WIDTH-1;
  localparam ID_MAX    = ID_WIDTH-1;   // ID max index


//------------------------------------------------------------------------------
// Inputs (no outputs)
//------------------------------------------------------------------------------


   // AXI Channel Signals
  input                AWVALID;
  input  [VALID_MAX:0] AWVALID_VECT;
  input                AWREADY;
  input          [3:0] AWVNET;
  input     [ID_MAX:0] AWID;
  input                WVALID;
  input                WREADY;
  input          [3:0] WVNET;
  input                ARVALID;
  input  [VALID_MAX:0] ARVALID_VECT;
  input                ARREADY;
  input          [3:0] ARVNET;
  input     [ID_MAX:0] ARID;

   // Token Interface Signals 0
  input                VAWVALID_0;
  input                VAWREADY_0;
  input          [3:0] VAWQOS_0;
  input                VWVALID_0;
  input                VWREADY_0;
  input                VARVALID_0;
  input                VARREADY_0;
  input          [3:0] VARQOS_0;

   // Token Interface Signals 1
  input                VAWVALID_1;
  input                VAWREADY_1;
  input          [3:0] VAWQOS_1;
  input                VWVALID_1;
  input                VWREADY_1;
  input                VARVALID_1;
  input                VARREADY_1;
  input          [3:0] VARQOS_1;

   // Token Interface Signals 2
  input                VAWVALID_2;
  input                VAWREADY_2;
  input          [3:0] VAWQOS_2;
  input                VWVALID_2;
  input                VWREADY_2;
  input                VARVALID_2;
  input                VARREADY_2;
  input          [3:0] VARQOS_2;

   // Token Interface Signals 3
  input                VAWVALID_3;
  input                VAWREADY_3;
  input          [3:0] VAWQOS_3;
  input                VWVALID_3;
  input                VWREADY_3;
  input                VARVALID_3;
  input                VARREADY_3;
  input          [3:0] VARQOS_3;

   // Token Interface Signals 4
  input                VAWVALID_4;
  input                VAWREADY_4;
  input          [3:0] VAWQOS_4;
  input                VWVALID_4;
  input                VWREADY_4;
  input                VARVALID_4;
  input                VARREADY_4;
  input          [3:0] VARQOS_4;

   // Token Interface Signals 5
  input                VAWVALID_5;
  input                VAWREADY_5;
  input          [3:0] VAWQOS_5;
  input                VWVALID_5;
  input                VWREADY_5;
  input                VARVALID_5;
  input                VARREADY_5;
  input          [3:0] VARQOS_5;

   // Token Interface Signals 6
  input                VAWVALID_6;
  input                VAWREADY_6;
  input          [3:0] VAWQOS_6;
  input                VWVALID_6;
  input                VWREADY_6;
  input                VARVALID_6;
  input                VARREADY_6;
  input          [3:0] VARQOS_6;

   // Token Interface Signals 7
  input                VAWVALID_7;
  input                VAWREADY_7;
  input          [3:0] VAWQOS_7;
  input                VWVALID_7;
  input                VWREADY_7;
  input                VARVALID_7;
  input                VARREADY_7;
  input          [3:0] VARQOS_7;

   // Token Interface Signals 8
  input                VAWVALID_8;
  input                VAWREADY_8;
  input          [3:0] VAWQOS_8;
  input                VWVALID_8;
  input                VWREADY_8;
  input                VARVALID_8;
  input                VARREADY_8;
  input          [3:0] VARQOS_8;

   // Token Interface Signals 9
  input                VAWVALID_9;
  input                VAWREADY_9;
  input          [3:0] VAWQOS_9;
  input                VWVALID_9;
  input                VWREADY_9;
  input                VARVALID_9;
  input                VARREADY_9;
  input          [3:0] VARQOS_9;

   // Token Interface Signals 10
  input                VAWVALID_10;
  input                VAWREADY_10;
  input          [3:0] VAWQOS_10;
  input                VWVALID_10;
  input                VWREADY_10;
  input                VARVALID_10;
  input                VARREADY_10;
  input          [3:0] VARQOS_10;

   // Token Interface Signals 11
  input                VAWVALID_11;
  input                VAWREADY_11;
  input          [3:0] VAWQOS_11;
  input                VWVALID_11;
  input                VWREADY_11;
  input                VARVALID_11;
  input                VARREADY_11;
  input          [3:0] VARQOS_11;

   // Token Interface Signals 11
  input                VAWVALID_12;
  input                VAWREADY_12;
  input          [3:0] VAWQOS_12;
  input                VWVALID_12;
  input                VWREADY_12;
  input                VARVALID_12;
  input                VARREADY_12;
  input          [3:0] VARQOS_12;


   // Global Signals
  input                ACLK;
  input                ARESETn;


//----------------------------------------------------------------------------
// Wires
//----------------------------------------------------------------------------

  wire                 aw_valid_vnet;
  wire                 w_valid_vnet;
  wire                 ar_valid_vnet;

  wire                 vaw_hshk_0;
  wire                 vaw_hshk_1;
  wire                 vaw_hshk_2;
  wire                 vaw_hshk_3;
  wire                 vaw_hshk_4;
  wire                 vaw_hshk_5;
  wire                 vaw_hshk_6;
  wire                 vaw_hshk_7;
  wire                 vaw_hshk_8;
  wire                 vaw_hshk_9;
  wire                 vaw_hshk_10;
  wire                 vaw_hshk_11;
  wire                 vaw_hshk_12;

  wire          [12:0] vaw_valid_vector;
  wire          [12:0] vaw_handshake_vector;


  wire                 var_hshk_0;
  wire                 var_hshk_1;
  wire                 var_hshk_2;
  wire                 var_hshk_3;
  wire                 var_hshk_4;
  wire                 var_hshk_5;
  wire                 var_hshk_6;
  wire                 var_hshk_7;
  wire                 var_hshk_8;
  wire                 var_hshk_9;
  wire                 var_hshk_10;
  wire                 var_hshk_11;
  wire                 var_hshk_12;

  wire          [12:0] var_valid_vector;
  wire          [12:0] var_handshake_vector;


  wire                 vw_hshk_0;
  wire                 vw_hshk_1;
  wire                 vw_hshk_2;
  wire                 vw_hshk_3;
  wire                 vw_hshk_4;
  wire                 vw_hshk_5;
  wire                 vw_hshk_6;
  wire                 vw_hshk_7;
  wire                 vw_hshk_8;
  wire                 vw_hshk_9;
  wire                 vw_hshk_10;
  wire                 vw_hshk_11;
  wire                 vw_hshk_12;

  wire          [12:0] vw_valid_vector;
  wire          [12:0] vw_handshake_vector;


  wire                 vw_handshake;
  wire                 w_handshake;

  reg           [31:0] aw_token_count;
  wire          [31:0] next_aw_token_count;

  reg           [31:0] w_token_count;
  wire          [31:0] next_w_token_count;

  reg           [31:0] ar_token_count;
  wire          [31:0] next_ar_token_count;


  wire                 vaw_token_check;
  wire                 vw_token_check;
  wire                 var_token_check;


  wire          [12:0] vaw_sticky_valid_check;
  wire          [12:0] vw_sticky_valid_check;
  wire          [12:0] var_sticky_valid_check;

  reg           [12:0] vaw_sticky_valid_check_reg;
  reg           [12:0] vw_sticky_valid_check_reg;
  reg           [12:0] var_sticky_valid_check_reg;


  wire           [3:0] vaw_hshk_val;
  wire           [3:0] var_hshk_val;
  wire           [3:0] vw_hshk_val;


// ---------------------------------------------------------------------------
//  start of code
// ---------------------------------------------------------------------------

  assign aw_valid_vnet = (AWVNET == VNET) & AWVALID;
  assign w_valid_vnet  = (WVNET  == VNET) & WVALID;
  assign ar_valid_vnet = (ARVNET == VNET) & ARVALID;

  assign vaw_hshk_0  = VAWVALID_0  & VAWREADY_0;
  assign vaw_hshk_1  = VAWVALID_1  & VAWREADY_1;
  assign vaw_hshk_2  = VAWVALID_2  & VAWREADY_2;
  assign vaw_hshk_3  = VAWVALID_3  & VAWREADY_3;
  assign vaw_hshk_4  = VAWVALID_4  & VAWREADY_4;
  assign vaw_hshk_5  = VAWVALID_5  & VAWREADY_5;
  assign vaw_hshk_6  = VAWVALID_6  & VAWREADY_6;
  assign vaw_hshk_7  = VAWVALID_7  & VAWREADY_7;
  assign vaw_hshk_8  = VAWVALID_8  & VAWREADY_8;
  assign vaw_hshk_9  = VAWVALID_9  & VAWREADY_9;
  assign vaw_hshk_10 = VAWVALID_10 & VAWREADY_10;
  assign vaw_hshk_11 = VAWVALID_11 & VAWREADY_11;
  assign vaw_hshk_12 = VAWVALID_12 & VAWREADY_12;

  assign vaw_valid_vector = {VAWVALID_0,
                             VAWVALID_1,
                             VAWVALID_2,
                             VAWVALID_3,
                             VAWVALID_4,
                             VAWVALID_5,
                             VAWVALID_6,
                             VAWVALID_7,
                             VAWVALID_8,
                             VAWVALID_9,
                             VAWVALID_10,
                             VAWVALID_11,
                             VAWVALID_12};

  assign vaw_handshake_vector = {vaw_hshk_0,
                                 vaw_hshk_1,
                                 vaw_hshk_2,
                                 vaw_hshk_3,
                                 vaw_hshk_4,
                                 vaw_hshk_5,
                                 vaw_hshk_6,
                                 vaw_hshk_7,
                                 vaw_hshk_8,
                                 vaw_hshk_9,
                                 vaw_hshk_10,
                                 vaw_hshk_11,
                                 vaw_hshk_12};



  assign vaw_hshk_val  = (DIRECTION) ? count_handshake(vaw_handshake_vector) : 4'b0001;
  assign vaw_handshake = |vaw_handshake_vector;
  assign aw_handshake  = aw_valid_vnet & AWREADY;

  assign next_aw_token_count = (~vaw_handshake &  aw_handshake) ? aw_token_count - 1                :
                               (vaw_handshake  & ~aw_handshake) ? aw_token_count + vaw_hshk_val     :
                               (vaw_handshake  &  aw_handshake) ? aw_token_count + vaw_hshk_val - 1 :
                                                                   aw_token_count;

  always @(negedge ARESETn or posedge ACLK)
  begin : p_aw_token_count
    if (!ARESETn)
    begin  // reset
      aw_token_count <= 32'h00000000 + PREREQUEST;
    end
    else
    begin  // clk edge
      aw_token_count <= next_aw_token_count;
    end
  end // block: p_aw_token_count


  assign var_hshk_0  = VARVALID_0  & VARREADY_0;
  assign var_hshk_1  = VARVALID_1  & VARREADY_1;
  assign var_hshk_2  = VARVALID_2  & VARREADY_2;
  assign var_hshk_3  = VARVALID_3  & VARREADY_3;
  assign var_hshk_4  = VARVALID_4  & VARREADY_4;
  assign var_hshk_5  = VARVALID_5  & VARREADY_5;
  assign var_hshk_6  = VARVALID_6  & VARREADY_6;
  assign var_hshk_7  = VARVALID_7  & VARREADY_7;
  assign var_hshk_8  = VARVALID_8  & VARREADY_8;
  assign var_hshk_9  = VARVALID_9  & VARREADY_9;
  assign var_hshk_10 = VARVALID_10 & VARREADY_10;
  assign var_hshk_11 = VARVALID_11 & VARREADY_11;
  assign var_hshk_12 = VARVALID_12 & VARREADY_12;

  assign var_valid_vector = {VARVALID_0,
                             VARVALID_1,
                             VARVALID_2,
                             VARVALID_3,
                             VARVALID_4,
                             VARVALID_5,
                             VARVALID_6,
                             VARVALID_7,
                             VARVALID_8,
                             VARVALID_9,
                             VARVALID_10,
                             VARVALID_11,
                             VARVALID_12};

  assign var_handshake_vector = {var_hshk_0,
                                 var_hshk_1,
                                 var_hshk_2,
                                 var_hshk_3,
                                 var_hshk_4,
                                 var_hshk_5,
                                 var_hshk_6,
                                 var_hshk_7,
                                 var_hshk_8,
                                 var_hshk_9,
                                 var_hshk_10,
                                 var_hshk_11,
                                 var_hshk_12};


  assign var_hshk_val  = (DIRECTION) ? count_handshake(var_handshake_vector) : 4'b0001;
  assign var_handshake = |var_handshake_vector;
  assign ar_handshake  = ar_valid_vnet & ARREADY;

  assign next_ar_token_count = (~var_handshake &  ar_handshake) ? ar_token_count - 1                :
                               ( var_handshake & ~ar_handshake) ? ar_token_count + var_hshk_val     :
                               ( var_handshake &  ar_handshake) ? ar_token_count + var_hshk_val - 1 :
                                                                  ar_token_count;

  always @(negedge ARESETn or posedge ACLK)
  begin : p_ar_token_count
    if (!ARESETn)
    begin  // reset
      ar_token_count <= 32'h00000000 + PREREQUEST;
    end
    else
    begin  // clk edge
      ar_token_count <= next_ar_token_count;
    end
  end // block: p_ar_token_count


  assign vw_hshk_0  = VWVALID_0  & VWREADY_0;
  assign vw_hshk_1  = VWVALID_1  & VWREADY_1;
  assign vw_hshk_2  = VWVALID_2  & VWREADY_2;
  assign vw_hshk_3  = VWVALID_3  & VWREADY_3;
  assign vw_hshk_4  = VWVALID_4  & VWREADY_4;
  assign vw_hshk_5  = VWVALID_5  & VWREADY_5;
  assign vw_hshk_6  = VWVALID_6  & VWREADY_6;
  assign vw_hshk_7  = VWVALID_7  & VWREADY_7;
  assign vw_hshk_8  = VWVALID_8  & VWREADY_8;
  assign vw_hshk_9  = VWVALID_9  & VWREADY_9;
  assign vw_hshk_10 = VWVALID_10 & VWREADY_10;
  assign vw_hshk_11 = VWVALID_11 & VWREADY_11;
  assign vw_hshk_12 = VWVALID_12 & VWREADY_12;

  assign vw_valid_vector = {VWVALID_0,
                            VWVALID_1,
                            VWVALID_2,
                            VWVALID_3,
                            VWVALID_4,
                            VWVALID_5,
                            VWVALID_6,
                            VWVALID_7,
                            VWVALID_8,
                            VWVALID_9,
                            VWVALID_10,
                            VWVALID_11,
                            VWVALID_12};

  assign vw_handshake_vector = {vw_hshk_0,
                                vw_hshk_1,
                                vw_hshk_2,
                                vw_hshk_3,
                                vw_hshk_4,
                                vw_hshk_5,
                                vw_hshk_6,
                                vw_hshk_7,
                                vw_hshk_8,
                                vw_hshk_9,
                                vw_hshk_10,
                                vw_hshk_11,
                                vw_hshk_12};


  assign vw_hshk_val  = (DIRECTION) ? count_handshake(vw_handshake_vector) : 4'b0001;
  assign vw_handshake = |vw_handshake_vector;
  assign w_handshake  = w_valid_vnet & WREADY;

  assign next_w_token_count  = (~vw_handshake &  w_handshake) ? w_token_count - 1               :
                               ( vw_handshake & ~w_handshake) ? w_token_count + vw_hshk_val     :
                               ( vw_handshake &  w_handshake) ? w_token_count + vw_hshk_val - 1 :
                                                                w_token_count;

  always @(negedge ARESETn or posedge ACLK)
  begin : p_wtoken_count
    if (!ARESETn)
    begin  // reset
      w_token_count <= 32'h00000000;
    end
    else
    begin  // clk edge
      w_token_count <= next_w_token_count;
    end
  end // block: p_w_count


  // Only assert valid when token is present
  assign vaw_token_check = aw_valid_vnet & (aw_token_count == 0);
  assign vw_token_check  = w_valid_vnet  & (w_token_count  == 0);
  assign var_token_check = ar_valid_vnet & (ar_token_count == 0);


  // Token valid must be sticky until handshake
  assign vaw_sticky_valid_check = vaw_valid_vector & ~vaw_handshake_vector;
  assign vw_sticky_valid_check  = vw_valid_vector  & ~vw_handshake_vector;
  assign var_sticky_valid_check = var_valid_vector & ~var_handshake_vector;

  always @(negedge ARESETn or posedge ACLK)
  begin : p_sticky_valid_check_reg
    if (!ARESETn)
    begin  // reset
      vaw_sticky_valid_check_reg <= 13'b0000000000000;
      vw_sticky_valid_check_reg  <= 13'b0000000000000;
      var_sticky_valid_check_reg <= 13'b0000000000000;
    end
    else
    begin  // clk edge
      vaw_sticky_valid_check_reg <= vaw_sticky_valid_check;
      vw_sticky_valid_check_reg  <= vw_sticky_valid_check;
      var_sticky_valid_check_reg <= var_sticky_valid_check;
    end
  end // block: p_sticky_valid_check_reg


  // Check tokens have returned to quiescent value at end of test
  final
  begin : p_token_count_check
    assert_aw_token_count_check:
      assert(aw_token_count == PREREQUEST) else
        $error("ERROR: aw_token_count has not returned to quiescent value at end of test");
    assert_w_token_count_check:
      assert(w_token_count == 4'b0000) else
        $error("ERROR: w_token_count has not returned to quiescent value at end of test");
    assert_ar_token_count_check:
      assert(ar_token_count == PREREQUEST) else
        $error("ERROR: ar_token_count has not returned to quiescent value at end of test");
  end

  function [3:0] count_handshake;
    input [12:0] handshake_vector;
    integer i;
    begin
       count_handshake = 4'b0000;
       for (i = 0; i < 13; i = i+1)
         count_handshake = count_handshake + handshake_vector[i];
    end
  endfunction

`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"

  //------------------------------------------------------------------------
  // OVL_ASSERT: No AW Valid without token
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_never
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: An AW token must be present before asserting valid")
      ovl_aw_valid_before_token
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (vaw_token_check)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: No W Valid without token
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_never
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: A W channel token must be present before asserting valid")
      ovl_w_valid_before_token
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (vw_token_check)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: No AR Valid without token
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_never
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: An AR token must be present before asserting valid")
      ovl_ar_valid_before_token
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (var_token_check)
      );
  // OVL_ASSERT_END


  //------------------------------------------------------------------------
  // OVL_ASSERT: Only one AW token handshake per cycle
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot
    #(`OVL_ERROR, 13,`OVL_ASSERT,
      "ERROR: Multiple AW token handshakes in same the cycle not allowed")
      ovl_aw_one_token_per_cycle
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((DIRECTION) ? 13'b1 : vaw_handshake_vector)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: Only one W token handshake per cycle
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot
    #(`OVL_ERROR, 13,`OVL_ASSERT,
      "ERROR: Multiple W token handshakes in same the cycle not allowed")
      ovl_w_one_token_per_cycle
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((DIRECTION) ? 13'b1 : vw_handshake_vector)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: Only one AR token handshake per cycle
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot
    #(`OVL_ERROR, 13,`OVL_ASSERT,
      "ERROR: Multiple AR token handshakes in same the cycle not allowed")
      ovl_ar_one_token_per_cycle
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((DIRECTION) ? 13'b1 : var_handshake_vector)
      );
  // OVL_ASSERT_END


  //------------------------------------------------------------------------
  // OVL_ASSERT: Sticky VAWVALID
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_always
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: Once VAWVALID is asserted, it must remain asserted until VAWREADY is high")
      ovl_vaw_sticky_valid_check
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((vaw_sticky_valid_check_reg & vaw_valid_vector) == vaw_sticky_valid_check_reg)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: Sticky VWVALID
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_always
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: Once VWVALID is asserted, it must remain asserted until VWREADY is high")
      ovl_vw_sticky_valid_check
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((vw_sticky_valid_check_reg & vw_valid_vector) == vw_sticky_valid_check_reg)
      );
  // OVL_ASSERT_END

  //------------------------------------------------------------------------
  // OVL_ASSERT: Sticky VARVALID
  //------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_always
    #(`OVL_ERROR, `OVL_ASSERT,
      "ERROR: Once VARVALID is asserted, it must remain asserted until VARREADY is high")
      ovl_var_sticky_valid_check
      (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr ((var_sticky_valid_check_reg & var_valid_vector) == var_sticky_valid_check_reg)
      );
  // OVL_ASSERT_END

`endif //ARM_ASSERT_ON


endmodule // VnTokenPC
