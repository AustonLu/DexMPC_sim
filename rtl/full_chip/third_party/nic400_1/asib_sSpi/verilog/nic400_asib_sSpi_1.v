//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2017 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 226322
// File Date           :  2017-11-13 14:54:55 +0000 (Mon, 13 Nov 2017)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : HDL design file for AXI slave interface block
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                               nic400_asib_sSpi.v
//                               =============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The Axi Slave Interface Block provides an interface between an external
//slave port on NIC400 and interconnect.
//
//   The ASIB can be configured to provide four modes of operation for each of
// the channels:
//    1. fully registered (total timing isolation between
//                         master and slave ports)
//    2. forward path registered only (timing isolation on data/ctrl/valid
//                                     paths only)
//    3. reverse path registered only (timing isolation on ready paths only)
//
//------------------------------------------------------------------------------


`include "nic400_asib_sSpi_defs_1.v"

module nic400_asib_sSpi_1
 (
  
    //sSpi_s AXI bus

    //AW Channel
    awid_sSpi_s,
    awaddr_sSpi_s,
    awlen_sSpi_s,
    awsize_sSpi_s,
    awburst_sSpi_s,
    awlock_sSpi_s,
    awcache_sSpi_s,
    awprot_sSpi_s,
    awvalid_sSpi_s,
    awready_sSpi_s,

    //W Channel
    wdata_sSpi_s,
    wstrb_sSpi_s,
    wlast_sSpi_s,
    wvalid_sSpi_s,
    wready_sSpi_s,

    //B Channel
    bid_sSpi_s,
    bresp_sSpi_s,
    bvalid_sSpi_s,
    bready_sSpi_s,

    //AR Channel
    arid_sSpi_s,
    araddr_sSpi_s,
    arlen_sSpi_s,
    arsize_sSpi_s,
    arburst_sSpi_s,
    arlock_sSpi_s,
    arcache_sSpi_s,
    arprot_sSpi_s,
    arvalid_sSpi_s,
    arready_sSpi_s,

    //R Channel
    rid_sSpi_s,
    rdata_sSpi_s,
    rresp_sSpi_s,
    rlast_sSpi_s,
    rvalid_sSpi_s,
    rready_sSpi_s,

    //sSpi_m AXI bus

    //AW Channel
    awid_sSpi_m,
    awaddr_sSpi_m,
    awlen_sSpi_m,
    awsize_sSpi_m,
    awburst_sSpi_m,
    awlock_sSpi_m,
    awcache_sSpi_m,
    awprot_sSpi_m,
    awvalid_sSpi_m,
    awvalid_vect_sSpi_m,
    awready_sSpi_m,

    //W Channel
    wdata_sSpi_m,
    wstrb_sSpi_m,
    wlast_sSpi_m,
    wvalid_sSpi_m,
    wready_sSpi_m,

    //B Channel
    bid_sSpi_m,
    bresp_sSpi_m,
    bvalid_sSpi_m,
    bready_sSpi_m,

    //AR Channel
    arid_sSpi_m,
    araddr_sSpi_m,
    arlen_sSpi_m,
    arsize_sSpi_m,
    arburst_sSpi_m,
    arlock_sSpi_m,
    arcache_sSpi_m,
    arprot_sSpi_m,
    arvalid_sSpi_m,
    arvalid_vect_sSpi_m,
    arready_sSpi_m,

    //R Channel
    rid_sSpi_m,
    rdata_sSpi_m,
    rresp_sSpi_m,
    rlast_sSpi_m,
    rvalid_sSpi_m,
    rready_sSpi_m,

    //Clock, reset and tie-off signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //sSpi_s AXI bus


  //AW Channel
  input   [1:0]       awid_sSpi_s;              //write id of sSpi_s AXI bus AW channel
  input   [31:0]      awaddr_sSpi_s;            //write address of sSpi_s AXI bus AW channel
  input   [7:0]       awlen_sSpi_s;             //write length field of sSpi_s AXI bus AW channel
  input   [2:0]       awsize_sSpi_s;            //write size of sSpi_s AXI bus AW channel
  input   [1:0]       awburst_sSpi_s;           //write burst length of sSpi_s AXI bus AW channel
  input               awlock_sSpi_s;            //write lock of sSpi_s AXI bus AW channel
  input   [3:0]       awcache_sSpi_s;           //write cache field of sSpi_s AXI bus AW channel
  input   [2:0]       awprot_sSpi_s;            //write prot field of sSpi_s AXI bus AW channel
  input               awvalid_sSpi_s;           //write valid of sSpi_s AXI bus AW channel
  output              awready_sSpi_s;           //write ready of sSpi_s AXI bus AW channel

  //W Channel
  input   [31:0]      wdata_sSpi_s;             //write data of sSpi_s AXI bus W Channel
  input   [3:0]       wstrb_sSpi_s;             //write strobes of sSpi_s AXI bus W Channel
  input               wlast_sSpi_s;             //write last of sSpi_s AXI bus W Channel
  input               wvalid_sSpi_s;            //write valid of sSpi_s AXI bus W Channel
  output              wready_sSpi_s;            //write ready of sSpi_s AXI bus W Channel

  //B Channel
  output  [1:0]       bid_sSpi_s;               //b response id of sSpi_s AXI bus B Channel
  output  [1:0]       bresp_sSpi_s;             //b response status of sSpi_s AXI bus B Channel
  output              bvalid_sSpi_s;            //b response valid of sSpi_s AXI bus B Channel
  input               bready_sSpi_s;            //b response ready of sSpi_s AXI bus B Channel

  //AR Channel
  input   [1:0]       arid_sSpi_s;              //read id of sSpi_s AXI bus AR Channel
  input   [31:0]      araddr_sSpi_s;            //read address of sSpi_s AXI bus AR Channel
  input   [7:0]       arlen_sSpi_s;             //read length of sSpi_s AXI bus AR Channel
  input   [2:0]       arsize_sSpi_s;            //read size of sSpi_s AXI bus AR Channel
  input   [1:0]       arburst_sSpi_s;           //read burst length of sSpi_s AXI bus AR Channel
  input               arlock_sSpi_s;            //read lock of sSpi_s AXI bus AR Channel
  input   [3:0]       arcache_sSpi_s;           //read cache field of sSpi_s AXI bus AR Channel
  input   [2:0]       arprot_sSpi_s;            //read prot field of sSpi_s AXI bus AR Channel
  input               arvalid_sSpi_s;           //read valid of sSpi_s AXI bus AR Channel
  output              arready_sSpi_s;           //read ready of sSpi_s AXI bus AR Channel

  //R Channel
  output  [1:0]       rid_sSpi_s;               //read id of sSpi_s AXI bus R Channel
  output  [31:0]      rdata_sSpi_s;             //read data of sSpi_s AXI bus R Channel
  output  [1:0]       rresp_sSpi_s;             //read response status of sSpi_s AXI bus R Channel
  output              rlast_sSpi_s;             //read last of sSpi_s AXI bus R Channel
  output              rvalid_sSpi_s;            //read valid of sSpi_s AXI bus R Channel
  input               rready_sSpi_s;            //read ready of sSpi_s AXI bus R Channel

  //sSpi_m AXI bus


  //AW Channel
  output  [1:0]       awid_sSpi_m;              //write id of sSpi_m AXI bus AW channel
  output  [31:0]      awaddr_sSpi_m;            //write address of sSpi_m AXI bus AW channel
  output  [7:0]       awlen_sSpi_m;             //write length field of sSpi_m AXI bus AW channel
  output  [2:0]       awsize_sSpi_m;            //write size of sSpi_m AXI bus AW channel
  output  [1:0]       awburst_sSpi_m;           //write burst length of sSpi_m AXI bus AW channel
  output              awlock_sSpi_m;            //write lock of sSpi_m AXI bus AW channel
  output  [3:0]       awcache_sSpi_m;           //write cache field of sSpi_m AXI bus AW channel
  output  [2:0]       awprot_sSpi_m;            //write prot field of sSpi_m AXI bus AW channel
  output              awvalid_sSpi_m;           //write valid of sSpi_m AXI bus AW channel
  output  [2:0]       awvalid_vect_sSpi_m;      //write valid vector of sSpi_m AXI bus AW channel
  input               awready_sSpi_m;           //write ready of sSpi_m AXI bus AW channel

  //W Channel
  output  [31:0]      wdata_sSpi_m;             //write data of sSpi_m AXI bus W Channel
  output  [3:0]       wstrb_sSpi_m;             //write strobes of sSpi_m AXI bus W Channel
  output              wlast_sSpi_m;             //write last of sSpi_m AXI bus W Channel
  output              wvalid_sSpi_m;            //write valid of sSpi_m AXI bus W Channel
  input               wready_sSpi_m;            //write ready of sSpi_m AXI bus W Channel

  //B Channel
  input   [1:0]       bid_sSpi_m;               //b response id of sSpi_m AXI bus B Channel
  input   [1:0]       bresp_sSpi_m;             //b response status of sSpi_m AXI bus B Channel
  input               bvalid_sSpi_m;            //b response valid of sSpi_m AXI bus B Channel
  output              bready_sSpi_m;            //b response ready of sSpi_m AXI bus B Channel

  //AR Channel
  output  [1:0]       arid_sSpi_m;              //read id of sSpi_m AXI bus AR Channel
  output  [31:0]      araddr_sSpi_m;            //read address of sSpi_m AXI bus AR Channel
  output  [7:0]       arlen_sSpi_m;             //read length of sSpi_m AXI bus AR Channel
  output  [2:0]       arsize_sSpi_m;            //read size of sSpi_m AXI bus AR Channel
  output  [1:0]       arburst_sSpi_m;           //read burst length of sSpi_m AXI bus AR Channel
  output              arlock_sSpi_m;            //read lock of sSpi_m AXI bus AR Channel
  output  [3:0]       arcache_sSpi_m;           //read cache field of sSpi_m AXI bus AR Channel
  output  [2:0]       arprot_sSpi_m;            //read prot field of sSpi_m AXI bus AR Channel
  output              arvalid_sSpi_m;           //read valid of sSpi_m AXI bus AR Channel
  output  [2:0]       arvalid_vect_sSpi_m;      //read valid vector of sSpi_m AXI bus AR Channel
  input               arready_sSpi_m;           //read ready of sSpi_m AXI bus AR Channel

  //R Channel
  input   [1:0]       rid_sSpi_m;               //read id of sSpi_m AXI bus R Channel
  input   [31:0]      rdata_sSpi_m;             //read data of sSpi_m AXI bus R Channel
  input   [1:0]       rresp_sSpi_m;             //read response status of sSpi_m AXI bus R Channel
  input               rlast_sSpi_m;             //read last of sSpi_m AXI bus R Channel
  input               rvalid_sSpi_m;            //read valid of sSpi_m AXI bus R Channel
  output              rready_sSpi_m;            //read ready of sSpi_m AXI bus R Channel

  //Clock, reset and tie-off signals
  input               aclk;                     //main clock
  input               aresetn;                  //main reset



  
  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------


  // AW Channel wires at slave_port
  wire           aw_slave_port_dst_valid;
  wire           aw_slave_port_dst_ready;
  wire           aw_slave_port_src_valid;
  wire           aw_slave_port_src_ready;

  wire [54:0]    aw_slave_port_src_data;     // concatenation of the inputs
  wire [54:0]    aw_slave_port_dst_data;     // concatenation of the registered inputs

  // W Channel wires at slave_port
  wire           w_slave_port_dst_valid;
  wire           w_slave_port_dst_ready;
  wire           w_slave_port_src_valid;
  wire           w_slave_port_src_ready;

  wire [36:0]    w_slave_port_src_data;     // concatenation of the inputs
  wire [36:0]    w_slave_port_dst_data;     // concatenation of the registered inputs

  // AR Channel wires at slave_port
  wire           ar_slave_port_dst_valid;
  wire           ar_slave_port_dst_ready;
  wire           ar_slave_port_src_valid;
  wire           ar_slave_port_src_ready;

  wire [54:0]    ar_slave_port_src_data;     // concatenation of the inputs
  wire [54:0]    ar_slave_port_dst_data;     // concatenation of the registered inputs

  // R Channel wires at slave_port
  wire [36:0]    r_slave_port_src_data;     // concatenation of the inputs
  wire [36:0]    r_slave_port_dst_data;     // concatenation of the registered inputs

  // B Channel wires at slave_port
  wire [3:0]     b_slave_port_src_data;     // concatenation of the inputs
  wire [3:0]     b_slave_port_dst_data;     // concatenation of the registered inputs

  wire                security62;
  wire                security63;
  wire [2:0]          awvalid_vect_sSpi_m;            //
  wire [2:0]          arvalid_vect_sSpi_m;            //
  wire [3:0]          arcache_int_sSpi_m;
  wire [3:0]          awcache_int_sSpi_m;
  wire [2:0]          arprot_int_sSpi_m;
  wire [2:0]          awprot_int_sSpi_m;
  wire                arready_int_m;
  wire                awready_int_m;
  wire                arvalid_int_m;
  wire                awvalid_int_m;
  wire                arready_int_s;
  wire                awready_int_s;
  wire                arvalid_int_s;
  wire                awvalid_int_s;
  wire [31:0]         awaddr_int_s;
  wire [31:0]         araddr_int_s;
  wire [31:0]         awaddr_int_m;
  wire [31:0]         araddr_int_m;
  wire                cds_aw_enable;
  wire                cds_ar_enable;
  wire                cds_w_enable;

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  // Fixed security targets
  assign security62 = 1'b0;
  assign security63 = 1'b0;

  // AxVALID and AxREADY assigns

  // Wiring of int signals
  assign arvalid_int_m = arvalid_int_s;
  assign awvalid_int_m = awvalid_int_s;

  assign arready_int_s = arready_int_m;
  assign awready_int_s = awready_int_m;



  // Wiring at master_port
  assign arvalid_sSpi_m = arvalid_int_m & cds_ar_enable;
  assign awvalid_sSpi_m = awvalid_int_m & cds_aw_enable;
  assign arready_int_m  = arready_sSpi_m & cds_ar_enable;
  assign awready_int_m  = awready_sSpi_m & cds_aw_enable;

  // Address assigns across decode block
  assign awaddr_int_m = awaddr_int_s;
  assign araddr_int_m = araddr_int_s;

  // Address assigns at master_port
  assign awaddr_sSpi_m = awaddr_int_m;
  assign araddr_sSpi_m = araddr_int_m;

  // Drive AxPROT bits to appropriate values
  assign arprot_sSpi_m[2] = arprot_int_sSpi_m[2];
  assign arprot_sSpi_m[1] = 1'b1;
  assign arprot_sSpi_m[0] = arprot_int_sSpi_m[0];

  assign awprot_sSpi_m[2] = awprot_int_sSpi_m[2];
  assign awprot_sSpi_m[1] = 1'b1;
  assign awprot_sSpi_m[0] = awprot_int_sSpi_m[0];

  //------------------------------------------------------------------------------
  // AW address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sSpi_decode_1 u_aw_add_decode
  (
    .addr_s                 (awaddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (awprot_sSpi_m[1]),
    .acache_in              (awcache_int_sSpi_m),
    .acache_out             (awcache_sSpi_m),
    .avalid_int             (awvalid_vect_sSpi_m)

  );

nic400_asib_sSpi_wr_ss_cdas_1 u_asib_sSpi_wr_ss_cdas
  (
    .aw_enable              (cds_aw_enable),
    .wr_enable              (cds_w_enable),
    .asel                   (awvalid_vect_sSpi_m),
    .avalid                 (awvalid_int_m),
    .aready                 (awready_int_m),
    .wvalid                 (wvalid_sSpi_m),
    .wready                 (wready_sSpi_m),
    .wlast                  (wlast_sSpi_m),
    .resp_valid             (bvalid_sSpi_m),
    .resp_ready             (bready_sSpi_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );


  //------------------------------------------------------------------------------
  // AR address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sSpi_decode_1 u_ar_add_decode
  (
    .addr_s                 (araddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (arprot_sSpi_m[1]),
    .acache_in              (arcache_int_sSpi_m),
    .acache_out             (arcache_sSpi_m),
    .avalid_int             (arvalid_vect_sSpi_m)

  );

nic400_asib_sSpi_rd_ss_cdas_1 u_asib_sSpi_rd_ss_cdas
  (
    .ar_enable              (cds_ar_enable),
    .asel                   (arvalid_vect_sSpi_m),
    .avalid                 (arvalid_int_m),
    .aready                 (arready_int_m),
    .resp_valid             (rvalid_sSpi_m),
    .resp_last              (rlast_sSpi_m),
    .resp_ready             (rready_sSpi_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );

  // ---------------------------------------------------------------------------
  // AW Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign aw_slave_port_src_data = {awid_sSpi_s,
          awaddr_sSpi_s,
          awlen_sSpi_s,
          awsize_sSpi_s,
          awburst_sSpi_s,
          awlock_sSpi_s,
          awcache_sSpi_s,
          awprot_sSpi_s};

  // expand the concatenated registered values to the slave port outputs
  assign {awid_sSpi_m,
          awaddr_int_s,
          awlen_sSpi_m,
          awsize_sSpi_m,
          awburst_sSpi_m,
          awlock_sSpi_m,
          awcache_int_sSpi_m,
          awprot_int_sSpi_m} = aw_slave_port_dst_data;



  assign awvalid_int_s = aw_slave_port_dst_valid;
  assign aw_slave_port_dst_ready = awready_int_s;

  assign aw_slave_port_src_valid = awvalid_sSpi_s;
  assign awready_sSpi_s = aw_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_slave_port_src_data = {wdata_sSpi_s,
          wstrb_sSpi_s,
          wlast_sSpi_s};

  // expand the concatenated registered values to the slave port outputs
  assign {wdata_sSpi_m,
          wstrb_sSpi_m,
          wlast_sSpi_m} = w_slave_port_dst_data;



  assign wvalid_sSpi_m = w_slave_port_dst_valid;
  assign w_slave_port_dst_ready = wready_sSpi_m;

  assign w_slave_port_src_valid = wvalid_sSpi_s;
  assign wready_sSpi_s = w_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // AR Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign ar_slave_port_src_data = {arid_sSpi_s,
          araddr_sSpi_s,
          arlen_sSpi_s,
          arsize_sSpi_s,
          arburst_sSpi_s,
          arlock_sSpi_s,
          arcache_sSpi_s,
          arprot_sSpi_s};

  // expand the concatenated registered values to the slave port outputs
  assign {arid_sSpi_m,
          araddr_int_s,
          arlen_sSpi_m,
          arsize_sSpi_m,
          arburst_sSpi_m,
          arlock_sSpi_m,
          arcache_int_sSpi_m,
          arprot_int_sSpi_m} = ar_slave_port_dst_data;



  assign arvalid_int_s = ar_slave_port_dst_valid;
  assign ar_slave_port_dst_ready = arready_int_s;

  assign ar_slave_port_src_valid = arvalid_sSpi_s;
  assign arready_sSpi_s = ar_slave_port_src_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at slave_port
  //
  // No register specified for R Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_slave_port_src_data = {rid_sSpi_m,
          rdata_sSpi_m,
          rresp_sSpi_m,
          rlast_sSpi_m};

  // expand the concatenated registered values to the slave port outputs
  assign {rid_sSpi_s,
          rdata_sSpi_s,
          rresp_sSpi_s,
          rlast_sSpi_s} = r_slave_port_dst_data;


  assign r_slave_port_dst_data = r_slave_port_src_data;

  assign rvalid_sSpi_s = rvalid_sSpi_m;
  assign rready_sSpi_m = rready_sSpi_s;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at slave_port
  //
  // No register specified for B Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_slave_port_src_data = {bid_sSpi_m,
          bresp_sSpi_m};

  // expand the concatenated registered values to the slave port outputs
  assign {bid_sSpi_s,
          bresp_sSpi_s} = b_slave_port_dst_data;


  assign b_slave_port_dst_data = b_slave_port_src_data;

  assign bvalid_sSpi_s = bvalid_sSpi_m;
  assign bready_sSpi_m = bready_sSpi_s;

  // ---------------------------------------------------------------------------
  // Instantiation of Timing Isolation Blocks
  // ---------------------------------------------------------------------------

  //  AW Channel Timing Isolation Register Block on slave_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 55
  nic400_asib_sSpi_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       55  // Payload Width
     )
  u_aw_slave_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (aw_slave_port_src_valid),
     .src_data              (aw_slave_port_src_data),
     .dst_ready             (aw_slave_port_dst_ready),

     // outputs
     .src_ready             (aw_slave_port_src_ready),
     .dst_data              (aw_slave_port_dst_data),
     .dst_valid             (aw_slave_port_dst_valid)
     );



  //  W Channel Timing Isolation Register Block on slave_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 37
  nic400_asib_sSpi_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       37  // Payload Width
     )
  u_w_slave_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (w_slave_port_src_valid),
     .src_data              (w_slave_port_src_data),
     .dst_ready             (w_slave_port_dst_ready),

     // outputs
     .src_ready             (w_slave_port_src_ready),
     .dst_data              (w_slave_port_dst_data),
     .dst_valid             (w_slave_port_dst_valid)
     );



  //  AR Channel Timing Isolation Register Block on slave_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 55
  nic400_asib_sSpi_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       55  // Payload Width
     )
  u_ar_slave_port_chan_slice
    (
     // global interconnect inputs
     .aresetn               (aresetn),
     .aclk                  (aclk),
     // inputs
     .src_valid             (ar_slave_port_src_valid),
     .src_data              (ar_slave_port_src_data),
     .dst_ready             (ar_slave_port_dst_ready),

     // outputs
     .src_ready             (ar_slave_port_src_ready),
     .dst_data              (ar_slave_port_dst_data),
     .dst_valid             (ar_slave_port_dst_valid)
     );



  // R channel is set to wires at slave_port.

  // B channel is set to wires at slave_port.


  // ---------------------------------------------------------------------------



//  ==========================================================================
//  OVL Assertions
//  ==========================================================================
`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"



  //----------------------------------------------------------------------------
  // OVL_ASSERT: Ensure that AR valid vector is one hot when ARVALID
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot
    #(`OVL_FATAL, 3, `OVL_ASSERT,
      "Error: AR Valid vector not one-hot zero")
      ovl_arvalid_vect_one_hot_zero
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( {3{arvalid_int_m}} & arvalid_vect_sSpi_m )
      );
  assert_never
    #(`OVL_FATAL, `OVL_ASSERT,
      "Error: AR Valid vector not one-hot during ARVALID")
      ovl_arvalid_vect_one_hot_when_arvalid
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( arvalid_int_m & ~|arvalid_vect_sSpi_m )
      );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: Ensure that AW valid vector is one hot when AWVALID
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_zero_one_hot
    #(`OVL_FATAL, 3, `OVL_ASSERT,
      "Error: AW Valid vector not one-hot zero")
      ovl_awvalid_vect_one_hot_zero
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( {3{awvalid_int_m}} & awvalid_vect_sSpi_m )
      );
  assert_never
    #(`OVL_FATAL, `OVL_ASSERT,
      "Error: AW Valid vector not one-hot during AWVALID")
      ovl_awvalid_vect_one_hot_when_awvalid
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( awvalid_int_m & ~|awvalid_vect_sSpi_m )
      );
  // OVL_ASSERT_END


`endif
// ---------------------------------------------------------------------------


endmodule

`include "nic400_asib_sSpi_undefs_1.v"



// --================================= End ===================================--
