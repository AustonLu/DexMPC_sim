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
//                               nic400_amib_mGauxCore_1.v
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


`include "nic400_amib_mGauxCore_defs_1.v"

module nic400_amib_mGauxCore_1
  (
  
    //mGauxCore_s AXI bus

    //AW Channel
    awid_mGauxCore_s,
    awaddr_mGauxCore_s,
    awlen_mGauxCore_s,
    awsize_mGauxCore_s,
    awburst_mGauxCore_s,
    awlock_mGauxCore_s,
    awcache_mGauxCore_s,
    awprot_mGauxCore_s,
    awvalid_mGauxCore_s,
    awready_mGauxCore_s,

    //W Channel
    wdata_mGauxCore_s,
    wstrb_mGauxCore_s,
    wlast_mGauxCore_s,
    wvalid_mGauxCore_s,
    wready_mGauxCore_s,

    //B Channel
    bid_mGauxCore_s,
    bresp_mGauxCore_s,
    bvalid_mGauxCore_s,
    bready_mGauxCore_s,

    //AR Channel
    arid_mGauxCore_s,
    araddr_mGauxCore_s,
    arlen_mGauxCore_s,
    arsize_mGauxCore_s,
    arburst_mGauxCore_s,
    arlock_mGauxCore_s,
    arcache_mGauxCore_s,
    arprot_mGauxCore_s,
    arvalid_mGauxCore_s,
    arready_mGauxCore_s,

    //R Channel
    rid_mGauxCore_s,
    rdata_mGauxCore_s,
    rresp_mGauxCore_s,
    rlast_mGauxCore_s,
    rvalid_mGauxCore_s,
    rready_mGauxCore_s,

    //mGauxCore_m AXI bus

    //AW Channel
    awid_mGauxCore_m,
    awaddr_mGauxCore_m,
    awlen_mGauxCore_m,
    awsize_mGauxCore_m,
    awburst_mGauxCore_m,
    awlock_mGauxCore_m,
    awcache_mGauxCore_m,
    awprot_mGauxCore_m,
    awvalid_mGauxCore_m,
    awready_mGauxCore_m,

    //W Channel
    wdata_mGauxCore_m,
    wstrb_mGauxCore_m,
    wlast_mGauxCore_m,
    wvalid_mGauxCore_m,
    wready_mGauxCore_m,

    //B Channel
    bid_mGauxCore_m,
    bresp_mGauxCore_m,
    bvalid_mGauxCore_m,
    bready_mGauxCore_m,

    //AR Channel
    arid_mGauxCore_m,
    araddr_mGauxCore_m,
    arlen_mGauxCore_m,
    arsize_mGauxCore_m,
    arburst_mGauxCore_m,
    arlock_mGauxCore_m,
    arcache_mGauxCore_m,
    arprot_mGauxCore_m,
    arvalid_mGauxCore_m,
    arready_mGauxCore_m,

    //R Channel
    rid_mGauxCore_m,
    rdata_mGauxCore_m,
    rresp_mGauxCore_m,
    rlast_mGauxCore_m,
    rvalid_mGauxCore_m,
    rready_mGauxCore_m,

    //Clock and reset signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //mGauxCore_s AXI bus


  //AW Channel
  input   [7:0]       awid_mGauxCore_s;         //write id of mGauxCore_s AXI bus AW channel
  input   [31:0]      awaddr_mGauxCore_s;       //write address of mGauxCore_s AXI bus AW channel
  input   [7:0]       awlen_mGauxCore_s;        //write length field of mGauxCore_s AXI bus AW channel
  input   [2:0]       awsize_mGauxCore_s;       //write size of mGauxCore_s AXI bus AW channel
  input   [1:0]       awburst_mGauxCore_s;      //write burst length of mGauxCore_s AXI bus AW channel
  input               awlock_mGauxCore_s;       //write lock of mGauxCore_s AXI bus AW channel
  input   [3:0]       awcache_mGauxCore_s;      //write cache field of mGauxCore_s AXI bus AW channel
  input   [2:0]       awprot_mGauxCore_s;       //write prot field of mGauxCore_s AXI bus AW channel
  input               awvalid_mGauxCore_s;      //write valid of mGauxCore_s AXI bus AW channel
  output              awready_mGauxCore_s;      //write ready of mGauxCore_s AXI bus AW channel

  //W Channel
  input   [63:0]      wdata_mGauxCore_s;        //write data of mGauxCore_s AXI bus W Channel
  input   [7:0]       wstrb_mGauxCore_s;        //write strobes of mGauxCore_s AXI bus W Channel
  input               wlast_mGauxCore_s;        //write last of mGauxCore_s AXI bus W Channel
  input               wvalid_mGauxCore_s;       //write valid of mGauxCore_s AXI bus W Channel
  output              wready_mGauxCore_s;       //write ready of mGauxCore_s AXI bus W Channel

  //B Channel
  output  [7:0]       bid_mGauxCore_s;          //b response id of mGauxCore_s AXI bus B Channel
  output  [1:0]       bresp_mGauxCore_s;        //b response status of mGauxCore_s AXI bus B Channel
  output              bvalid_mGauxCore_s;       //b response valid of mGauxCore_s AXI bus B Channel
  input               bready_mGauxCore_s;       //b response ready of mGauxCore_s AXI bus B Channel

  //AR Channel
  input   [7:0]       arid_mGauxCore_s;         //read id of mGauxCore_s AXI bus AR Channel
  input   [31:0]      araddr_mGauxCore_s;       //read address of mGauxCore_s AXI bus AR Channel
  input   [7:0]       arlen_mGauxCore_s;        //read length of mGauxCore_s AXI bus AR Channel
  input   [2:0]       arsize_mGauxCore_s;       //read size of mGauxCore_s AXI bus AR Channel
  input   [1:0]       arburst_mGauxCore_s;      //read burst length of mGauxCore_s AXI bus AR Channel
  input               arlock_mGauxCore_s;       //read lock of mGauxCore_s AXI bus AR Channel
  input   [3:0]       arcache_mGauxCore_s;      //read cache field of mGauxCore_s AXI bus AR Channel
  input   [2:0]       arprot_mGauxCore_s;       //read prot field of mGauxCore_s AXI bus AR Channel
  input               arvalid_mGauxCore_s;      //read valid of mGauxCore_s AXI bus AR Channel
  output              arready_mGauxCore_s;      //read ready of mGauxCore_s AXI bus AR Channel

  //R Channel
  output  [7:0]       rid_mGauxCore_s;          //read id of mGauxCore_s AXI bus R Channel
  output  [63:0]      rdata_mGauxCore_s;        //read data of mGauxCore_s AXI bus R Channel
  output  [1:0]       rresp_mGauxCore_s;        //read response status of mGauxCore_s AXI bus R Channel
  output              rlast_mGauxCore_s;        //read last of mGauxCore_s AXI bus R Channel
  output              rvalid_mGauxCore_s;       //read valid of mGauxCore_s AXI bus R Channel
  input               rready_mGauxCore_s;       //read ready of mGauxCore_s AXI bus R Channel

  //mGauxCore_m AXI bus


  //AW Channel
  output  [6:0]       awid_mGauxCore_m;         //write id of mGauxCore_m AXI bus AW channel
  output  [31:0]      awaddr_mGauxCore_m;       //write address of mGauxCore_m AXI bus AW channel
  output  [7:0]       awlen_mGauxCore_m;        //write length field of mGauxCore_m AXI bus AW channel
  output  [2:0]       awsize_mGauxCore_m;       //write size of mGauxCore_m AXI bus AW channel
  output  [1:0]       awburst_mGauxCore_m;      //write burst length of mGauxCore_m AXI bus AW channel
  output              awlock_mGauxCore_m;       //write lock of mGauxCore_m AXI bus AW channel
  output  [3:0]       awcache_mGauxCore_m;      //write cache field of mGauxCore_m AXI bus AW channel
  output  [2:0]       awprot_mGauxCore_m;       //write prot field of mGauxCore_m AXI bus AW channel
  output              awvalid_mGauxCore_m;      //write valid of mGauxCore_m AXI bus AW channel
  input               awready_mGauxCore_m;      //write ready of mGauxCore_m AXI bus AW channel

  //W Channel
  output  [63:0]      wdata_mGauxCore_m;        //write data of mGauxCore_m AXI bus W Channel
  output  [7:0]       wstrb_mGauxCore_m;        //write strobes of mGauxCore_m AXI bus W Channel
  output              wlast_mGauxCore_m;        //write last of mGauxCore_m AXI bus W Channel
  output              wvalid_mGauxCore_m;       //write valid of mGauxCore_m AXI bus W Channel
  input               wready_mGauxCore_m;       //write ready of mGauxCore_m AXI bus W Channel

  //B Channel
  input   [6:0]       bid_mGauxCore_m;          //b response id of mGauxCore_m AXI bus B Channel
  input   [1:0]       bresp_mGauxCore_m;        //b response status of mGauxCore_m AXI bus B Channel
  input               bvalid_mGauxCore_m;       //b response valid of mGauxCore_m AXI bus B Channel
  output              bready_mGauxCore_m;       //b response ready of mGauxCore_m AXI bus B Channel

  //AR Channel
  output  [6:0]       arid_mGauxCore_m;         //read id of mGauxCore_m AXI bus AR Channel
  output  [31:0]      araddr_mGauxCore_m;       //read address of mGauxCore_m AXI bus AR Channel
  output  [7:0]       arlen_mGauxCore_m;        //read length of mGauxCore_m AXI bus AR Channel
  output  [2:0]       arsize_mGauxCore_m;       //read size of mGauxCore_m AXI bus AR Channel
  output  [1:0]       arburst_mGauxCore_m;      //read burst length of mGauxCore_m AXI bus AR Channel
  output              arlock_mGauxCore_m;       //read lock of mGauxCore_m AXI bus AR Channel
  output  [3:0]       arcache_mGauxCore_m;      //read cache field of mGauxCore_m AXI bus AR Channel
  output  [2:0]       arprot_mGauxCore_m;       //read prot field of mGauxCore_m AXI bus AR Channel
  output              arvalid_mGauxCore_m;      //read valid of mGauxCore_m AXI bus AR Channel
  input               arready_mGauxCore_m;      //read ready of mGauxCore_m AXI bus AR Channel

  //R Channel
  input   [6:0]       rid_mGauxCore_m;          //read id of mGauxCore_m AXI bus R Channel
  input   [63:0]      rdata_mGauxCore_m;        //read data of mGauxCore_m AXI bus R Channel
  input   [1:0]       rresp_mGauxCore_m;        //read response status of mGauxCore_m AXI bus R Channel
  input               rlast_mGauxCore_m;        //read last of mGauxCore_m AXI bus R Channel
  input               rvalid_mGauxCore_m;       //read valid of mGauxCore_m AXI bus R Channel
  output              rready_mGauxCore_m;       //read ready of mGauxCore_m AXI bus R Channel

  //Clock and reset signals
  input               aclk;                     //main clock
  input               aresetn;                  //main reset



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
  (wdata_mGauxCore_s[63:56]  & {8{wstrb_mGauxCore_s[7]}}),
  (wdata_mGauxCore_s[55:48]  & {8{wstrb_mGauxCore_s[6]}}),
  (wdata_mGauxCore_s[47:40]  & {8{wstrb_mGauxCore_s[5]}}),
  (wdata_mGauxCore_s[39:32]  & {8{wstrb_mGauxCore_s[4]}}),
  (wdata_mGauxCore_s[31:24]  & {8{wstrb_mGauxCore_s[3]}}),
  (wdata_mGauxCore_s[23:16]  & {8{wstrb_mGauxCore_s[2]}}),
  (wdata_mGauxCore_s[15:8]  & {8{wstrb_mGauxCore_s[1]}}),
  (wdata_mGauxCore_s[7:0]  & {8{wstrb_mGauxCore_s[0]}})};
  
  // ---------------------------------------------------------------------------
  //  ID reduction - Reduces ID width to minimum required for connected slave
  // ---------------------------------------------------------------------------

  
  assign awid = {awid_mGauxCore_s[6],
  awid_mGauxCore_s[5],
  awid_mGauxCore_s[4],
  awid_mGauxCore_s[3],
  awid_mGauxCore_s[2],
  awid_mGauxCore_s[1],
  awid_mGauxCore_s[0]};

  assign arid = {arid_mGauxCore_s[6],
  arid_mGauxCore_s[5],
  arid_mGauxCore_s[4],
  arid_mGauxCore_s[3],
  arid_mGauxCore_s[2],
  arid_mGauxCore_s[1],
  arid_mGauxCore_s[0]};


  // Rebuild the return IDs
  assign rid_mGauxCore_s = {1'b0,
    rid[6],
    rid[5],
    rid[4],
    rid[3],
    rid[2],
    rid[1],
    rid[0]};

  assign bid_mGauxCore_s = {1'b0,
    bid[6],
    bid[5],
    bid[4],
    bid[3],
    bid[2],
    bid[1],
    bid[0]};
  // aw Channel
  assign awid_mGauxCore_m     = awid;
  assign awaddr_mGauxCore_m   = awaddr_mGauxCore_s;
  assign awlen_mGauxCore_m    = awlen_mGauxCore_s;
  assign awsize_mGauxCore_m   = awsize_mGauxCore_s;
  assign awburst_mGauxCore_m  = awburst_mGauxCore_s;
  assign awlock_mGauxCore_m   = awlock_mGauxCore_s;
  assign awcache_mGauxCore_m  = awcache_mGauxCore_s;
  assign awprot_mGauxCore_m   = awprot_mGauxCore_s;
  assign awvalid_mGauxCore_m  = awvalid_mGauxCore_s;
  assign awready_mGauxCore_s  = awready_mGauxCore_m;
  // ar Channel
  assign arid_mGauxCore_m     = arid;
  assign araddr_mGauxCore_m   = araddr_mGauxCore_s;
  assign arlen_mGauxCore_m    = arlen_mGauxCore_s;
  assign arsize_mGauxCore_m   = arsize_mGauxCore_s;
  assign arburst_mGauxCore_m  = arburst_mGauxCore_s;
  assign arlock_mGauxCore_m   = arlock_mGauxCore_s;
  assign arcache_mGauxCore_m  = arcache_mGauxCore_s;
  assign arprot_mGauxCore_m   = arprot_mGauxCore_s;
  assign arvalid_mGauxCore_m  = arvalid_mGauxCore_s;
  assign arready_mGauxCore_s  = arready_mGauxCore_m;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_master_port_src_data = {wdata_destrob,
        wstrb_mGauxCore_s,
        wlast_mGauxCore_s};

  // expand the concatenated registered values to the master port outputs
  assign {wdata_mGauxCore_m,
        wstrb_mGauxCore_m,
        wlast_mGauxCore_m} = w_master_port_dst_data;

  assign wvalid_mGauxCore_m = w_master_port_dst_valid;
  assign w_master_port_dst_ready = wready_mGauxCore_m;

  assign w_master_port_src_valid = wvalid_mGauxCore_s;
  assign wready_mGauxCore_s = w_master_port_src_ready;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_master_port_src_data = {bid_mGauxCore_m,
        bresp_mGauxCore_m};

  // expand the concatenated registered values to the master port outputs
  assign {bid,
        bresp_mGauxCore_s} = b_master_port_dst_data;

  assign bvalid_mGauxCore_s =  b_master_port_dst_valid;
  assign b_master_port_dst_ready = bready_mGauxCore_s;

  assign b_master_port_src_valid = bvalid_mGauxCore_m;
  assign bready_mGauxCore_m = b_master_port_src_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at Master Port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_master_port_src_data = {rid_mGauxCore_m,
        rdata_mGauxCore_m,
        rresp_mGauxCore_m,
        rlast_mGauxCore_m};

  // expand the concatenated registered values to the master port outputs
  assign {rid,
        rdata_mGauxCore_s,
        rresp_mGauxCore_s,
        rlast_mGauxCore_s} = r_master_port_dst_data;

  assign rvalid_mGauxCore_s =  r_master_port_dst_valid;
  assign r_master_port_dst_ready = rready_mGauxCore_s;

  assign r_master_port_src_valid = rvalid_mGauxCore_m;
  assign rready_mGauxCore_m = r_master_port_src_ready;




  // ---------------------------------------------------------------------------
  // Instantiation of Timing Isolation Blocks
  // ---------------------------------------------------------------------------

  //  W Channel Timing Isolation Register Block on master_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 73
  nic400_amib_mGauxCore_chan_slice_1
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
  nic400_amib_mGauxCore_chan_slice_1
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
  nic400_amib_mGauxCore_chan_slice_1
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


  assign wif_hndshk = wvalid_mGauxCore_m & wready_mGauxCore_m;
  assign strobeless_wdata = wif_hndshk & (
  (|wdata_mGauxCore_m[63:56]  & ~wstrb_mGauxCore_m[7]) | 
  (|wdata_mGauxCore_m[55:48]  & ~wstrb_mGauxCore_m[6]) | 
  (|wdata_mGauxCore_m[47:40]  & ~wstrb_mGauxCore_m[5]) | 
  (|wdata_mGauxCore_m[39:32]  & ~wstrb_mGauxCore_m[4]) | 
  (|wdata_mGauxCore_m[31:24]  & ~wstrb_mGauxCore_m[3]) | 
  (|wdata_mGauxCore_m[23:16]  & ~wstrb_mGauxCore_m[2]) | 
  (|wdata_mGauxCore_m[15:8]  & ~wstrb_mGauxCore_m[1]) | 
  (|wdata_mGauxCore_m[7:0]  & ~wstrb_mGauxCore_m[0]));



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

`include "nic400_amib_mGauxCore_undefs_1.v"

// --================================= End ===================================--
