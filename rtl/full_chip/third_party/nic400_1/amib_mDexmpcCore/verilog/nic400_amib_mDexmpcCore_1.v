//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2012-2017 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 226260
// File Date           :  2017-11-09 13:06:27 +0000 (Thu, 09 Nov 2017)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Verilog-2001 (IEEE Std 1364-2001)
//------------------------------------------------------------------------------
// Purpose : HDL design file for AMBA master interface block
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                               nic400_amib_mDexmpcCore_1.v
//                               =============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The Axi Master Interface Block provides an interface between an interconnect
// and an external slave port on NIC400.
//
//   The AMIB can be configured to provide four modes of operation for each of
// the channels:
//    1. fully registered (total timing isolation between
//                         master and slave ports)
//    2. forward path registered only (timing isolation on data/ctrl/valid
//                                     paths only)
//    3. reverse path registered only (timing isolation on ready paths only)
//
//------------------------------------------------------------------------------


`include "nic400_amib_mDexmpcCore_defs_1.v"

module nic400_amib_mDexmpcCore_1
  (
  
    //mDexmpcCore_s AXI bus

    //AW Channel
    awid_mDexmpcCore_s,
    awaddr_mDexmpcCore_s,
    awlen_mDexmpcCore_s,
    awsize_mDexmpcCore_s,
    awburst_mDexmpcCore_s,
    awlock_mDexmpcCore_s,
    awcache_mDexmpcCore_s,
    awprot_mDexmpcCore_s,
    awvalid_mDexmpcCore_s,
    awready_mDexmpcCore_s,

    //W Channel
    wdata_mDexmpcCore_s,
    wstrb_mDexmpcCore_s,
    wlast_mDexmpcCore_s,
    wvalid_mDexmpcCore_s,
    wready_mDexmpcCore_s,

    //B Channel
    bid_mDexmpcCore_s,
    bresp_mDexmpcCore_s,
    bvalid_mDexmpcCore_s,
    bready_mDexmpcCore_s,

    //AR Channel
    arid_mDexmpcCore_s,
    araddr_mDexmpcCore_s,
    arlen_mDexmpcCore_s,
    arsize_mDexmpcCore_s,
    arburst_mDexmpcCore_s,
    arlock_mDexmpcCore_s,
    arcache_mDexmpcCore_s,
    arprot_mDexmpcCore_s,
    arvalid_mDexmpcCore_s,
    arready_mDexmpcCore_s,

    //R Channel
    rid_mDexmpcCore_s,
    rdata_mDexmpcCore_s,
    rresp_mDexmpcCore_s,
    rlast_mDexmpcCore_s,
    rvalid_mDexmpcCore_s,
    rready_mDexmpcCore_s,

    //mDexmpcCore_m AXI bus

    //AW Channel
    awid_mDexmpcCore_m,
    awaddr_mDexmpcCore_m,
    awlen_mDexmpcCore_m,
    awsize_mDexmpcCore_m,
    awburst_mDexmpcCore_m,
    awlock_mDexmpcCore_m,
    awcache_mDexmpcCore_m,
    awprot_mDexmpcCore_m,
    awvalid_mDexmpcCore_m,
    awready_mDexmpcCore_m,

    //W Channel
    wdata_mDexmpcCore_m,
    wstrb_mDexmpcCore_m,
    wlast_mDexmpcCore_m,
    wvalid_mDexmpcCore_m,
    wready_mDexmpcCore_m,

    //B Channel
    bid_mDexmpcCore_m,
    bresp_mDexmpcCore_m,
    bvalid_mDexmpcCore_m,
    bready_mDexmpcCore_m,

    //AR Channel
    arid_mDexmpcCore_m,
    araddr_mDexmpcCore_m,
    arlen_mDexmpcCore_m,
    arsize_mDexmpcCore_m,
    arburst_mDexmpcCore_m,
    arlock_mDexmpcCore_m,
    arcache_mDexmpcCore_m,
    arprot_mDexmpcCore_m,
    arvalid_mDexmpcCore_m,
    arready_mDexmpcCore_m,

    //R Channel
    rid_mDexmpcCore_m,
    rdata_mDexmpcCore_m,
    rresp_mDexmpcCore_m,
    rlast_mDexmpcCore_m,
    rvalid_mDexmpcCore_m,
    rready_mDexmpcCore_m,

    //Clock and reset signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //mDexmpcCore_s AXI bus


  //AW Channel
  input   [7:0]       awid_mDexmpcCore_s;         //write id of mDexmpcCore_s AXI bus AW channel
  input   [31:0]      awaddr_mDexmpcCore_s;       //write address of mDexmpcCore_s AXI bus AW channel
  input   [7:0]       awlen_mDexmpcCore_s;        //write length field of mDexmpcCore_s AXI bus AW channel
  input   [2:0]       awsize_mDexmpcCore_s;       //write size of mDexmpcCore_s AXI bus AW channel
  input   [1:0]       awburst_mDexmpcCore_s;      //write burst length of mDexmpcCore_s AXI bus AW channel
  input               awlock_mDexmpcCore_s;       //write lock of mDexmpcCore_s AXI bus AW channel
  input   [3:0]       awcache_mDexmpcCore_s;      //write cache field of mDexmpcCore_s AXI bus AW channel
  input   [2:0]       awprot_mDexmpcCore_s;       //write prot field of mDexmpcCore_s AXI bus AW channel
  input               awvalid_mDexmpcCore_s;      //write valid of mDexmpcCore_s AXI bus AW channel
  output              awready_mDexmpcCore_s;      //write ready of mDexmpcCore_s AXI bus AW channel

  //W Channel
  input   [63:0]      wdata_mDexmpcCore_s;        //write data of mDexmpcCore_s AXI bus W Channel
  input   [7:0]       wstrb_mDexmpcCore_s;        //write strobes of mDexmpcCore_s AXI bus W Channel
  input               wlast_mDexmpcCore_s;        //write last of mDexmpcCore_s AXI bus W Channel
  input               wvalid_mDexmpcCore_s;       //write valid of mDexmpcCore_s AXI bus W Channel
  output              wready_mDexmpcCore_s;       //write ready of mDexmpcCore_s AXI bus W Channel

  //B Channel
  output  [7:0]       bid_mDexmpcCore_s;          //b response id of mDexmpcCore_s AXI bus B Channel
  output  [1:0]       bresp_mDexmpcCore_s;        //b response status of mDexmpcCore_s AXI bus B Channel
  output              bvalid_mDexmpcCore_s;       //b response valid of mDexmpcCore_s AXI bus B Channel
  input               bready_mDexmpcCore_s;       //b response ready of mDexmpcCore_s AXI bus B Channel

  //AR Channel
  input   [7:0]       arid_mDexmpcCore_s;         //read id of mDexmpcCore_s AXI bus AR Channel
  input   [31:0]      araddr_mDexmpcCore_s;       //read address of mDexmpcCore_s AXI bus AR Channel
  input   [7:0]       arlen_mDexmpcCore_s;        //read length of mDexmpcCore_s AXI bus AR Channel
  input   [2:0]       arsize_mDexmpcCore_s;       //read size of mDexmpcCore_s AXI bus AR Channel
  input   [1:0]       arburst_mDexmpcCore_s;      //read burst length of mDexmpcCore_s AXI bus AR Channel
  input               arlock_mDexmpcCore_s;       //read lock of mDexmpcCore_s AXI bus AR Channel
  input   [3:0]       arcache_mDexmpcCore_s;      //read cache field of mDexmpcCore_s AXI bus AR Channel
  input   [2:0]       arprot_mDexmpcCore_s;       //read prot field of mDexmpcCore_s AXI bus AR Channel
  input               arvalid_mDexmpcCore_s;      //read valid of mDexmpcCore_s AXI bus AR Channel
  output              arready_mDexmpcCore_s;      //read ready of mDexmpcCore_s AXI bus AR Channel

  //R Channel
  output  [7:0]       rid_mDexmpcCore_s;          //read id of mDexmpcCore_s AXI bus R Channel
  output  [63:0]      rdata_mDexmpcCore_s;        //read data of mDexmpcCore_s AXI bus R Channel
  output  [1:0]       rresp_mDexmpcCore_s;        //read response status of mDexmpcCore_s AXI bus R Channel
  output              rlast_mDexmpcCore_s;        //read last of mDexmpcCore_s AXI bus R Channel
  output              rvalid_mDexmpcCore_s;       //read valid of mDexmpcCore_s AXI bus R Channel
  input               rready_mDexmpcCore_s;       //read ready of mDexmpcCore_s AXI bus R Channel

  //mDexmpcCore_m AXI bus


  //AW Channel
  output  [6:0]       awid_mDexmpcCore_m;         //write id of mDexmpcCore_m AXI bus AW channel
  output  [31:0]      awaddr_mDexmpcCore_m;       //write address of mDexmpcCore_m AXI bus AW channel
  output  [7:0]       awlen_mDexmpcCore_m;        //write length field of mDexmpcCore_m AXI bus AW channel
  output  [2:0]       awsize_mDexmpcCore_m;       //write size of mDexmpcCore_m AXI bus AW channel
  output  [1:0]       awburst_mDexmpcCore_m;      //write burst length of mDexmpcCore_m AXI bus AW channel
  output              awlock_mDexmpcCore_m;       //write lock of mDexmpcCore_m AXI bus AW channel
  output  [3:0]       awcache_mDexmpcCore_m;      //write cache field of mDexmpcCore_m AXI bus AW channel
  output  [2:0]       awprot_mDexmpcCore_m;       //write prot field of mDexmpcCore_m AXI bus AW channel
  output              awvalid_mDexmpcCore_m;      //write valid of mDexmpcCore_m AXI bus AW channel
  input               awready_mDexmpcCore_m;      //write ready of mDexmpcCore_m AXI bus AW channel

  //W Channel
  output  [63:0]      wdata_mDexmpcCore_m;        //write data of mDexmpcCore_m AXI bus W Channel
  output  [7:0]       wstrb_mDexmpcCore_m;        //write strobes of mDexmpcCore_m AXI bus W Channel
  output              wlast_mDexmpcCore_m;        //write last of mDexmpcCore_m AXI bus W Channel
  output              wvalid_mDexmpcCore_m;       //write valid of mDexmpcCore_m AXI bus W Channel
  input               wready_mDexmpcCore_m;       //write ready of mDexmpcCore_m AXI bus W Channel

  //B Channel
  input   [6:0]       bid_mDexmpcCore_m;          //b response id of mDexmpcCore_m AXI bus B Channel
  input   [1:0]       bresp_mDexmpcCore_m;        //b response status of mDexmpcCore_m AXI bus B Channel
  input               bvalid_mDexmpcCore_m;       //b response valid of mDexmpcCore_m AXI bus B Channel
  output              bready_mDexmpcCore_m;       //b response ready of mDexmpcCore_m AXI bus B Channel

  //AR Channel
  output  [6:0]       arid_mDexmpcCore_m;         //read id of mDexmpcCore_m AXI bus AR Channel
  output  [31:0]      araddr_mDexmpcCore_m;       //read address of mDexmpcCore_m AXI bus AR Channel
  output  [7:0]       arlen_mDexmpcCore_m;        //read length of mDexmpcCore_m AXI bus AR Channel
  output  [2:0]       arsize_mDexmpcCore_m;       //read size of mDexmpcCore_m AXI bus AR Channel
  output  [1:0]       arburst_mDexmpcCore_m;      //read burst length of mDexmpcCore_m AXI bus AR Channel
  output              arlock_mDexmpcCore_m;       //read lock of mDexmpcCore_m AXI bus AR Channel
  output  [3:0]       arcache_mDexmpcCore_m;      //read cache field of mDexmpcCore_m AXI bus AR Channel
  output  [2:0]       arprot_mDexmpcCore_m;       //read prot field of mDexmpcCore_m AXI bus AR Channel
  output              arvalid_mDexmpcCore_m;      //read valid of mDexmpcCore_m AXI bus AR Channel
  input               arready_mDexmpcCore_m;      //read ready of mDexmpcCore_m AXI bus AR Channel

  //R Channel
  input   [6:0]       rid_mDexmpcCore_m;          //read id of mDexmpcCore_m AXI bus R Channel
  input   [63:0]      rdata_mDexmpcCore_m;        //read data of mDexmpcCore_m AXI bus R Channel
  input   [1:0]       rresp_mDexmpcCore_m;        //read response status of mDexmpcCore_m AXI bus R Channel
  input               rlast_mDexmpcCore_m;        //read last of mDexmpcCore_m AXI bus R Channel
  input               rvalid_mDexmpcCore_m;       //read valid of mDexmpcCore_m AXI bus R Channel
  output              rready_mDexmpcCore_m;       //read ready of mDexmpcCore_m AXI bus R Channel

  //Clock and reset signals
  input               aclk;                       //main clock
  input               aresetn;                    //main reset



  //----------------------------------------------------------------------------
  // Internal wires
  //----------------------------------------------------------------------------



  wire           w_master_port_dst_valid;
  wire           w_master_port_dst_ready;
  wire           w_master_port_src_valid;
  wire           w_master_port_src_ready;

  wire [72:0]    w_master_port_src_data;     // concatenation of the inputs
  wire [72:0]    w_master_port_dst_data;     // concatenation of the registered inputs



  wire           b_master_port_dst_valid;
  wire           b_master_port_dst_ready;
  wire           b_master_port_src_valid;
  wire           b_master_port_src_ready;

  wire [8:0]     b_master_port_src_data;     // concatenation of the inputs
  wire [8:0]     b_master_port_dst_data;     // concatenation of the registered inputs



  wire           r_master_port_dst_valid;
  wire           r_master_port_dst_ready;
  wire           r_master_port_src_valid;
  wire           r_master_port_src_ready;

  wire [73:0]    r_master_port_src_data;     // concatenation of the inputs
  wire [73:0]    r_master_port_dst_data;     // concatenation of the registered inputs


  //----------------------------------------------------------------------------
  // Internal AXI wires
  //----------------------------------------------------------------------------


  wire [6:0]    awid;
  wire [6:0]    bid;
  wire [6:0]    arid;
  wire [6:0]    rid;


  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------
  wire [63:0]   wdata_destrob;
  assign wdata_destrob = {
  (wdata_mDexmpcCore_s[63:56]  & {8{wstrb_mDexmpcCore_s[7]}}),
  (wdata_mDexmpcCore_s[55:48]  & {8{wstrb_mDexmpcCore_s[6]}}),
  (wdata_mDexmpcCore_s[47:40]  & {8{wstrb_mDexmpcCore_s[5]}}),
  (wdata_mDexmpcCore_s[39:32]  & {8{wstrb_mDexmpcCore_s[4]}}),
  (wdata_mDexmpcCore_s[31:24]  & {8{wstrb_mDexmpcCore_s[3]}}),
  (wdata_mDexmpcCore_s[23:16]  & {8{wstrb_mDexmpcCore_s[2]}}),
  (wdata_mDexmpcCore_s[15:8]  & {8{wstrb_mDexmpcCore_s[1]}}),
  (wdata_mDexmpcCore_s[7:0]  & {8{wstrb_mDexmpcCore_s[0]}})};
  
  // ---------------------------------------------------------------------------
  //  ID reduction - Reduces ID width to minimum required for connected slave
  // ---------------------------------------------------------------------------

  
  assign awid = {awid_mDexmpcCore_s[6],
  awid_mDexmpcCore_s[5],
  awid_mDexmpcCore_s[4],
  awid_mDexmpcCore_s[3],
  awid_mDexmpcCore_s[2],
  awid_mDexmpcCore_s[1],
  awid_mDexmpcCore_s[0]};

  assign arid = {arid_mDexmpcCore_s[6],
  arid_mDexmpcCore_s[5],
  arid_mDexmpcCore_s[4],
  arid_mDexmpcCore_s[3],
  arid_mDexmpcCore_s[2],
  arid_mDexmpcCore_s[1],
  arid_mDexmpcCore_s[0]};


  // Rebuild the return IDs
  assign rid_mDexmpcCore_s = {1'b0,
    rid[6],
    rid[5],
    rid[4],
    rid[3],
    rid[2],
    rid[1],
    rid[0]};

  assign bid_mDexmpcCore_s = {1'b0,
    bid[6],
    bid[5],
    bid[4],
    bid[3],
    bid[2],
    bid[1],
    bid[0]};
  // aw Channel
  assign awid_mDexmpcCore_m     = awid;
  assign awaddr_mDexmpcCore_m   = awaddr_mDexmpcCore_s;
  assign awlen_mDexmpcCore_m    = awlen_mDexmpcCore_s;
  assign awsize_mDexmpcCore_m   = awsize_mDexmpcCore_s;
  assign awburst_mDexmpcCore_m  = awburst_mDexmpcCore_s;
  assign awlock_mDexmpcCore_m   = awlock_mDexmpcCore_s;
  assign awcache_mDexmpcCore_m  = awcache_mDexmpcCore_s;
  assign awprot_mDexmpcCore_m   = awprot_mDexmpcCore_s;
  assign awvalid_mDexmpcCore_m  = awvalid_mDexmpcCore_s;
  assign awready_mDexmpcCore_s  = awready_mDexmpcCore_m;
  // ar Channel
  assign arid_mDexmpcCore_m     = arid;
  assign araddr_mDexmpcCore_m   = araddr_mDexmpcCore_s;
  assign arlen_mDexmpcCore_m    = arlen_mDexmpcCore_s;
  assign arsize_mDexmpcCore_m   = arsize_mDexmpcCore_s;
  assign arburst_mDexmpcCore_m  = arburst_mDexmpcCore_s;
  assign arlock_mDexmpcCore_m   = arlock_mDexmpcCore_s;
  assign arcache_mDexmpcCore_m  = arcache_mDexmpcCore_s;
  assign arprot_mDexmpcCore_m   = arprot_mDexmpcCore_s;
  assign arvalid_mDexmpcCore_m  = arvalid_mDexmpcCore_s;
  assign arready_mDexmpcCore_s  = arready_mDexmpcCore_m;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_master_port_src_data = {wdata_destrob,
        wstrb_mDexmpcCore_s,
        wlast_mDexmpcCore_s};

  // expand the concatenated registered values to the master port outputs
  assign {wdata_mDexmpcCore_m,
        wstrb_mDexmpcCore_m,
        wlast_mDexmpcCore_m} = w_master_port_dst_data;

  assign wvalid_mDexmpcCore_m = w_master_port_dst_valid;
  assign w_master_port_dst_ready = wready_mDexmpcCore_m;

  assign w_master_port_src_valid = wvalid_mDexmpcCore_s;
  assign wready_mDexmpcCore_s = w_master_port_src_ready;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_master_port_src_data = {bid_mDexmpcCore_m,
        bresp_mDexmpcCore_m};

  // expand the concatenated registered values to the master port outputs
  assign {bid,
        bresp_mDexmpcCore_s} = b_master_port_dst_data;

  assign bvalid_mDexmpcCore_s =  b_master_port_dst_valid;
  assign b_master_port_dst_ready = bready_mDexmpcCore_s;

  assign b_master_port_src_valid = bvalid_mDexmpcCore_m;
  assign bready_mDexmpcCore_m = b_master_port_src_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_master_port_src_data = {rid_mDexmpcCore_m,
        rdata_mDexmpcCore_m,
        rresp_mDexmpcCore_m,
        rlast_mDexmpcCore_m};

  // expand the concatenated registered values to the master port outputs
  assign {rid,
        rdata_mDexmpcCore_s,
        rresp_mDexmpcCore_s,
        rlast_mDexmpcCore_s} = r_master_port_dst_data;

  assign rvalid_mDexmpcCore_s =  r_master_port_dst_valid;
  assign r_master_port_dst_ready = rready_mDexmpcCore_s;

  assign r_master_port_src_valid = rvalid_mDexmpcCore_m;
  assign rready_mDexmpcCore_m = r_master_port_src_ready;




  // ---------------------------------------------------------------------------
  // Instantiation of Timing Isolation Blocks
  // ---------------------------------------------------------------------------

  //  W Channel Timing Isolation Register Block on master_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 73
  nic400_amib_mDexmpcCore_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       73  // Payload Width
     )
  u_w_master_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (w_master_port_src_valid),
     .src_data              (w_master_port_src_data),
     .dst_ready             (w_master_port_dst_ready),

     // outputs
     .src_ready             (w_master_port_src_ready),
     .dst_data              (w_master_port_dst_data),
     .dst_valid             (w_master_port_dst_valid)
     );



  //  B Channel Timing Isolation Register Block on master_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 9
  nic400_amib_mDexmpcCore_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       9  // Payload Width
     )
  u_b_master_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (b_master_port_src_valid),
     .src_data              (b_master_port_src_data),
     .dst_ready             (b_master_port_dst_ready),

     // outputs
     .src_ready             (b_master_port_src_ready),
     .dst_data              (b_master_port_dst_data),
     .dst_valid             (b_master_port_dst_valid)
     );



  //  R Channel Timing Isolation Register Block on master_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 74
  nic400_amib_mDexmpcCore_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       74  // Payload Width
     )
  u_r_master_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (r_master_port_src_valid),
     .src_data              (r_master_port_src_data),
     .dst_ready             (r_master_port_dst_ready),

     // outputs
     .src_ready             (r_master_port_src_ready),
     .dst_data              (r_master_port_dst_data),
     .dst_valid             (r_master_port_dst_valid)
     );



  // AW channel is set to wires at master_port.

  // AR channel is set to wires at master_port.

  // AW channel is set to wires at slave_port.

  // AR channel is set to wires at slave_port.

  // R channel is set to wires at slave_port.

  // W channel is set to wires at slave_port.

  // B channel is set to wires at slave_port.


//==============================================================================
// OVL Assertions
//==============================================================================
`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"



  //----------------------------------------------------------------------------
  // OVL_ASSERT: Destrobe WDATA out.
  //----------------------------------------------------------------------------
  //
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  wire strobeless_wdata;
  wire wif_hndshk;


  assign wif_hndshk = wvalid_mDexmpcCore_m & wready_mDexmpcCore_m;
  assign strobeless_wdata = wif_hndshk & (
  (|wdata_mDexmpcCore_m[63:56]  & ~wstrb_mDexmpcCore_m[7]) | 
  (|wdata_mDexmpcCore_m[55:48]  & ~wstrb_mDexmpcCore_m[6]) | 
  (|wdata_mDexmpcCore_m[47:40]  & ~wstrb_mDexmpcCore_m[5]) | 
  (|wdata_mDexmpcCore_m[39:32]  & ~wstrb_mDexmpcCore_m[4]) | 
  (|wdata_mDexmpcCore_m[31:24]  & ~wstrb_mDexmpcCore_m[3]) | 
  (|wdata_mDexmpcCore_m[23:16]  & ~wstrb_mDexmpcCore_m[2]) | 
  (|wdata_mDexmpcCore_m[15:8]  & ~wstrb_mDexmpcCore_m[1]) | 
  (|wdata_mDexmpcCore_m[7:0]  & ~wstrb_mDexmpcCore_m[0]));



  assert_never #(`OVL_WARNING,
                 `OVL_ASSERT,
                 "AMIB: WDATA not destrobed.")
  amib_destrob_mif
  (
    .clk        (aclk),
    .reset_n    (aresetn),
    .test_expr  (strobeless_wdata)
  );
  // OVL_ASSERT_END


  `endif // ARM_ASSERT_ON



endmodule

`include "nic400_amib_mDexmpcCore_undefs_1.v"

// --================================= End ===================================--
