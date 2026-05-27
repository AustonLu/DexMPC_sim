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
//                               nic400_asib_sIrisBridge.v
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


`include "nic400_asib_sIrisBridge_defs_1.v"

module nic400_asib_sIrisBridge_1
 (
  
    //sIrisBridge_m AXI bus

    //AW Channel
    awid_sIrisBridge_m,
    awaddr_sIrisBridge_m,
    awlen_sIrisBridge_m,
    awsize_sIrisBridge_m,
    awburst_sIrisBridge_m,
    awlock_sIrisBridge_m,
    awcache_sIrisBridge_m,
    awprot_sIrisBridge_m,
    awvalid_sIrisBridge_m,
    awvalid_vect_sIrisBridge_m,
    awready_sIrisBridge_m,

    //W Channel
    wdata_sIrisBridge_m,
    wstrb_sIrisBridge_m,
    wlast_sIrisBridge_m,
    wvalid_sIrisBridge_m,
    wready_sIrisBridge_m,

    //B Channel
    bid_sIrisBridge_m,
    bresp_sIrisBridge_m,
    bvalid_sIrisBridge_m,
    bready_sIrisBridge_m,

    //AR Channel
    arid_sIrisBridge_m,
    araddr_sIrisBridge_m,
    arlen_sIrisBridge_m,
    arsize_sIrisBridge_m,
    arburst_sIrisBridge_m,
    arlock_sIrisBridge_m,
    arcache_sIrisBridge_m,
    arprot_sIrisBridge_m,
    arvalid_sIrisBridge_m,
    arvalid_vect_sIrisBridge_m,
    arready_sIrisBridge_m,

    //R Channel
    rid_sIrisBridge_m,
    rdata_sIrisBridge_m,
    rresp_sIrisBridge_m,
    rlast_sIrisBridge_m,
    rvalid_sIrisBridge_m,
    rready_sIrisBridge_m,

    //QoS Signals
    awqv_sIrisBridge_m,
    arqv_sIrisBridge_m,

    //sIrisBridge_s AXI bus

    //AW Channel
    awid_sIrisBridge_s,
    awaddr_sIrisBridge_s,
    awlen_sIrisBridge_s,
    awsize_sIrisBridge_s,
    awburst_sIrisBridge_s,
    awlock_sIrisBridge_s,
    awcache_sIrisBridge_s,
    awprot_sIrisBridge_s,
    awvalid_sIrisBridge_s,
    awready_sIrisBridge_s,

    //W Channel
    wdata_sIrisBridge_s,
    wstrb_sIrisBridge_s,
    wlast_sIrisBridge_s,
    wvalid_sIrisBridge_s,
    wready_sIrisBridge_s,

    //B Channel
    bid_sIrisBridge_s,
    bresp_sIrisBridge_s,
    bvalid_sIrisBridge_s,
    bready_sIrisBridge_s,

    //AR Channel
    arid_sIrisBridge_s,
    araddr_sIrisBridge_s,
    arlen_sIrisBridge_s,
    arsize_sIrisBridge_s,
    arburst_sIrisBridge_s,
    arlock_sIrisBridge_s,
    arcache_sIrisBridge_s,
    arprot_sIrisBridge_s,
    arvalid_sIrisBridge_s,
    arready_sIrisBridge_s,

    //R Channel
    rid_sIrisBridge_s,
    rdata_sIrisBridge_s,
    rresp_sIrisBridge_s,
    rlast_sIrisBridge_s,
    rvalid_sIrisBridge_s,
    rready_sIrisBridge_s,

    //Clock, reset and tie-off signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //sIrisBridge_m AXI bus


  //AW Channel
  output  [7:0]       awid_sIrisBridge_m;              //write id of sIrisBridge_m AXI bus AW channel
  output  [31:0]      awaddr_sIrisBridge_m;            //write address of sIrisBridge_m AXI bus AW channel
  output  [7:0]       awlen_sIrisBridge_m;             //write length field of sIrisBridge_m AXI bus AW channel
  output  [2:0]       awsize_sIrisBridge_m;            //write size of sIrisBridge_m AXI bus AW channel
  output  [1:0]       awburst_sIrisBridge_m;           //write burst length of sIrisBridge_m AXI bus AW channel
  output              awlock_sIrisBridge_m;            //write lock of sIrisBridge_m AXI bus AW channel
  output  [3:0]       awcache_sIrisBridge_m;           //write cache field of sIrisBridge_m AXI bus AW channel
  output  [2:0]       awprot_sIrisBridge_m;            //write prot field of sIrisBridge_m AXI bus AW channel
  output              awvalid_sIrisBridge_m;           //write valid of sIrisBridge_m AXI bus AW channel
  output  [2:0]       awvalid_vect_sIrisBridge_m;      //write valid vector of sIrisBridge_m AXI bus AW channel
  input               awready_sIrisBridge_m;           //write ready of sIrisBridge_m AXI bus AW channel

  //W Channel
  output  [63:0]      wdata_sIrisBridge_m;             //write data of sIrisBridge_m AXI bus W Channel
  output  [7:0]       wstrb_sIrisBridge_m;             //write strobes of sIrisBridge_m AXI bus W Channel
  output              wlast_sIrisBridge_m;             //write last of sIrisBridge_m AXI bus W Channel
  output              wvalid_sIrisBridge_m;            //write valid of sIrisBridge_m AXI bus W Channel
  input               wready_sIrisBridge_m;            //write ready of sIrisBridge_m AXI bus W Channel

  //B Channel
  input   [7:0]       bid_sIrisBridge_m;               //b response id of sIrisBridge_m AXI bus B Channel
  input   [1:0]       bresp_sIrisBridge_m;             //b response status of sIrisBridge_m AXI bus B Channel
  input               bvalid_sIrisBridge_m;            //b response valid of sIrisBridge_m AXI bus B Channel
  output              bready_sIrisBridge_m;            //b response ready of sIrisBridge_m AXI bus B Channel

  //AR Channel
  output  [7:0]       arid_sIrisBridge_m;              //read id of sIrisBridge_m AXI bus AR Channel
  output  [31:0]      araddr_sIrisBridge_m;            //read address of sIrisBridge_m AXI bus AR Channel
  output  [7:0]       arlen_sIrisBridge_m;             //read length of sIrisBridge_m AXI bus AR Channel
  output  [2:0]       arsize_sIrisBridge_m;            //read size of sIrisBridge_m AXI bus AR Channel
  output  [1:0]       arburst_sIrisBridge_m;           //read burst length of sIrisBridge_m AXI bus AR Channel
  output              arlock_sIrisBridge_m;            //read lock of sIrisBridge_m AXI bus AR Channel
  output  [3:0]       arcache_sIrisBridge_m;           //read cache field of sIrisBridge_m AXI bus AR Channel
  output  [2:0]       arprot_sIrisBridge_m;            //read prot field of sIrisBridge_m AXI bus AR Channel
  output              arvalid_sIrisBridge_m;           //read valid of sIrisBridge_m AXI bus AR Channel
  output  [2:0]       arvalid_vect_sIrisBridge_m;      //read valid vector of sIrisBridge_m AXI bus AR Channel
  input               arready_sIrisBridge_m;           //read ready of sIrisBridge_m AXI bus AR Channel

  //R Channel
  input   [7:0]       rid_sIrisBridge_m;               //read id of sIrisBridge_m AXI bus R Channel
  input   [63:0]      rdata_sIrisBridge_m;             //read data of sIrisBridge_m AXI bus R Channel
  input   [1:0]       rresp_sIrisBridge_m;             //read response status of sIrisBridge_m AXI bus R Channel
  input               rlast_sIrisBridge_m;             //read last of sIrisBridge_m AXI bus R Channel
  input               rvalid_sIrisBridge_m;            //read valid of sIrisBridge_m AXI bus R Channel
  output              rready_sIrisBridge_m;            //read ready of sIrisBridge_m AXI bus R Channel

  //QoS Signals
  output  [3:0]       awqv_sIrisBridge_m;              //QoS value of sIrisBridge_m AXI bus AW Channel
  output  [3:0]       arqv_sIrisBridge_m;              //QoS value of sIrisBridge_m AXI bus AR Channel

  //sIrisBridge_s AXI bus


  //AW Channel
  input   [4:0]       awid_sIrisBridge_s;              //write id of sIrisBridge_s AXI bus AW channel
  input   [31:0]      awaddr_sIrisBridge_s;            //write address of sIrisBridge_s AXI bus AW channel
  input   [7:0]       awlen_sIrisBridge_s;             //write length field of sIrisBridge_s AXI bus AW channel
  input   [2:0]       awsize_sIrisBridge_s;            //write size of sIrisBridge_s AXI bus AW channel
  input   [1:0]       awburst_sIrisBridge_s;           //write burst length of sIrisBridge_s AXI bus AW channel
  input               awlock_sIrisBridge_s;            //write lock of sIrisBridge_s AXI bus AW channel
  input   [3:0]       awcache_sIrisBridge_s;           //write cache field of sIrisBridge_s AXI bus AW channel
  input   [2:0]       awprot_sIrisBridge_s;            //write prot field of sIrisBridge_s AXI bus AW channel
  input               awvalid_sIrisBridge_s;           //write valid of sIrisBridge_s AXI bus AW channel
  output              awready_sIrisBridge_s;           //write ready of sIrisBridge_s AXI bus AW channel

  //W Channel
  input   [63:0]      wdata_sIrisBridge_s;             //write data of sIrisBridge_s AXI bus W Channel
  input   [7:0]       wstrb_sIrisBridge_s;             //write strobes of sIrisBridge_s AXI bus W Channel
  input               wlast_sIrisBridge_s;             //write last of sIrisBridge_s AXI bus W Channel
  input               wvalid_sIrisBridge_s;            //write valid of sIrisBridge_s AXI bus W Channel
  output              wready_sIrisBridge_s;            //write ready of sIrisBridge_s AXI bus W Channel

  //B Channel
  output  [4:0]       bid_sIrisBridge_s;               //b response id of sIrisBridge_s AXI bus B Channel
  output  [1:0]       bresp_sIrisBridge_s;             //b response status of sIrisBridge_s AXI bus B Channel
  output              bvalid_sIrisBridge_s;            //b response valid of sIrisBridge_s AXI bus B Channel
  input               bready_sIrisBridge_s;            //b response ready of sIrisBridge_s AXI bus B Channel

  //AR Channel
  input   [4:0]       arid_sIrisBridge_s;              //read id of sIrisBridge_s AXI bus AR Channel
  input   [31:0]      araddr_sIrisBridge_s;            //read address of sIrisBridge_s AXI bus AR Channel
  input   [7:0]       arlen_sIrisBridge_s;             //read length of sIrisBridge_s AXI bus AR Channel
  input   [2:0]       arsize_sIrisBridge_s;            //read size of sIrisBridge_s AXI bus AR Channel
  input   [1:0]       arburst_sIrisBridge_s;           //read burst length of sIrisBridge_s AXI bus AR Channel
  input               arlock_sIrisBridge_s;            //read lock of sIrisBridge_s AXI bus AR Channel
  input   [3:0]       arcache_sIrisBridge_s;           //read cache field of sIrisBridge_s AXI bus AR Channel
  input   [2:0]       arprot_sIrisBridge_s;            //read prot field of sIrisBridge_s AXI bus AR Channel
  input               arvalid_sIrisBridge_s;           //read valid of sIrisBridge_s AXI bus AR Channel
  output              arready_sIrisBridge_s;           //read ready of sIrisBridge_s AXI bus AR Channel

  //R Channel
  output  [4:0]       rid_sIrisBridge_s;               //read id of sIrisBridge_s AXI bus R Channel
  output  [63:0]      rdata_sIrisBridge_s;             //read data of sIrisBridge_s AXI bus R Channel
  output  [1:0]       rresp_sIrisBridge_s;             //read response status of sIrisBridge_s AXI bus R Channel
  output              rlast_sIrisBridge_s;             //read last of sIrisBridge_s AXI bus R Channel
  output              rvalid_sIrisBridge_s;            //read valid of sIrisBridge_s AXI bus R Channel
  input               rready_sIrisBridge_s;            //read ready of sIrisBridge_s AXI bus R Channel

  //Clock, reset and tie-off signals
  input               aclk;                            //main clock
  input               aresetn;                         //main reset



  
  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------


  // AW Channel wires at slave_port
  wire           aw_slave_port_dst_valid;
  wire           aw_slave_port_dst_ready;
  wire           aw_slave_port_src_valid;
  wire           aw_slave_port_src_ready;

  wire [57:0]    aw_slave_port_src_data;     // concatenation of the inputs
  wire [57:0]    aw_slave_port_dst_data;     // concatenation of the registered inputs

  // W Channel wires at slave_port
  wire           w_slave_port_dst_valid;
  wire           w_slave_port_dst_ready;
  wire           w_slave_port_src_valid;
  wire           w_slave_port_src_ready;

  wire [72:0]    w_slave_port_src_data;     // concatenation of the inputs
  wire [72:0]    w_slave_port_dst_data;     // concatenation of the registered inputs

  // AR Channel wires at slave_port
  wire           ar_slave_port_dst_valid;
  wire           ar_slave_port_dst_ready;
  wire           ar_slave_port_src_valid;
  wire           ar_slave_port_src_ready;

  wire [57:0]    ar_slave_port_src_data;     // concatenation of the inputs
  wire [57:0]    ar_slave_port_dst_data;     // concatenation of the registered inputs

  // R Channel wires at slave_port
  wire [71:0]    r_slave_port_src_data;     // concatenation of the inputs
  wire [71:0]    r_slave_port_dst_data;     // concatenation of the registered inputs

  // B Channel wires at slave_port
  wire [6:0]     b_slave_port_src_data;     // concatenation of the inputs
  wire [6:0]     b_slave_port_dst_data;     // concatenation of the registered inputs

  wire                security62;
  wire                security63;
  wire [2:0]          awvalid_vector;            //
  wire [2:0]          arvalid_vector;            //
  wire                rvalid_maskcntl;
  wire                bvalid_master;
  wire                bready_master;

  wire                mask_w;
  wire                mask_r;


  wire                wr_cnt_empty;

  wire [3:0]          arcache_int_sIrisBridge_m;
  wire [3:0]          awcache_int_sIrisBridge_m;
  wire [2:0]          arprot_int_sIrisBridge_m;
  wire [2:0]          awprot_int_sIrisBridge_m;
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
  //Channel id output from internal blocks before being appended with the asib_id
  wire [4:0]          awid;
  wire [4:0]          bid;
  wire [4:0]          arid;
  wire [4:0]          rid;


  wire                zero_pad;
  wire [1:0]          asib_sIrisBridge_siid;
  wire                cds_aw_enable;
  wire                cds_ar_enable;
  wire                cds_w_enable;

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // Output ID concatenation
  // ---------------------------------------------------------------------------


  // id values in this section are defined in the top level design description
  // and are design specific.

  assign asib_sIrisBridge_siid = 2'b1;


  // ----------

  assign zero_pad = 1'b0;

  assign awid_sIrisBridge_m = {zero_pad,awid,asib_sIrisBridge_siid};
  assign arid_sIrisBridge_m = {zero_pad,arid,asib_sIrisBridge_siid};
  assign bid = bid_sIrisBridge_m[6:2];
  assign rid = rid_sIrisBridge_m[6:2];

  // End of ID section
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





  assign arvalid_sIrisBridge_m = arvalid_int_m & cds_ar_enable & !mask_r;
  assign awvalid_sIrisBridge_m = awvalid_int_m & cds_aw_enable & !mask_w;
  assign arready_int_m  = arready_sIrisBridge_m & cds_ar_enable & !mask_r;
  assign awready_int_m  = awready_sIrisBridge_m & cds_aw_enable & !mask_w;


  // Address assigns across decode block
  assign awaddr_int_m = awaddr_int_s;
  assign araddr_int_m = araddr_int_s;

  // Address assigns at master_port
  assign awaddr_sIrisBridge_m = awaddr_int_m;
  assign araddr_sIrisBridge_m = araddr_int_m;

  // Drive AxPROT bits to appropriate values
  assign arprot_sIrisBridge_m[2] = arprot_int_sIrisBridge_m[2];
  assign arprot_sIrisBridge_m[1] = 1'b1;
  assign arprot_sIrisBridge_m[0] = arprot_int_sIrisBridge_m[0];

  assign awprot_sIrisBridge_m[2] = awprot_int_sIrisBridge_m[2];
  assign awprot_sIrisBridge_m[1] = 1'b1;
  assign awprot_sIrisBridge_m[0] = awprot_int_sIrisBridge_m[0];

  //------------------------------------------------------------------------------
  // AW address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sIrisBridge_decode_1 u_aw_add_decode
  (
    .addr_s                 (awaddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (awprot_sIrisBridge_m[1]),
    .acache_in              (awcache_int_sIrisBridge_m),
    .acache_out             (awcache_sIrisBridge_m),
    .avalid_int             (awvalid_vector)

  );

nic400_asib_sIrisBridge_wr_ss_cdas_1 u_asib_sIrisBridge_wr_ss_cdas
  (
    .aw_enable              (cds_aw_enable),
    .wr_enable              (cds_w_enable),
    .asel                   (awvalid_vector),
    .avalid                 (awvalid_int_m),
    .aready                 (awready_int_m),
    .wvalid                 (wvalid_sIrisBridge_m),
    .wready                 (wready_sIrisBridge_m),
    .wlast                  (wlast_sIrisBridge_m),
    .resp_valid             (bvalid_sIrisBridge_m),
    .resp_ready             (bready_sIrisBridge_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );


  //------------------------------------------------------------------------------
  // AR address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sIrisBridge_decode_1 u_ar_add_decode
  (
    .addr_s                 (araddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (arprot_sIrisBridge_m[1]),
    .acache_in              (arcache_int_sIrisBridge_m),
    .acache_out             (arcache_sIrisBridge_m),
    .avalid_int             (arvalid_vector)

  );

nic400_asib_sIrisBridge_rd_ss_cdas_1 u_asib_sIrisBridge_rd_ss_cdas
  (
    .ar_enable              (cds_ar_enable),
    .asel                   (arvalid_vector),
    .avalid                 (arvalid_int_m),
    .aready                 (arready_int_m),
    .resp_valid             (rvalid_sIrisBridge_m),
    .resp_last              (rlast_sIrisBridge_m),
    .resp_ready             (rready_sIrisBridge_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );

  // ---------------------------------------------------------------------------
  //  Address channel transaction counting
  // ---------------------------------------------------------------------------


  // Mask control present = true
  nic400_asib_sIrisBridge_maskcntl_1 u_asib_sIrisBridge_maskcntl (
      // Master Interface address channel handshake signals
      .awvalid_m    (awvalid_int_m),
      .arvalid_m    (arvalid_int_m),
      .awready_m    (awready_int_m),
      .arready_m    (arready_int_m),
      // Master Interface return channel handshake signals
      .bvalid_m     (bvalid_sIrisBridge_m),
      .bready_m     (bready_sIrisBridge_m),
      .rvalid_m     (rvalid_maskcntl),
      .rready_m     (rready_sIrisBridge_m),

      // Write counter status
      .wr_cnt_empty (wr_cnt_empty),
      // Mask signals
      .mask_w       (mask_w),
      .mask_r       (mask_r),
      // QoS output signals
      .aw_qos_m     (awqv_sIrisBridge_m),
      .ar_qos_m     (arqv_sIrisBridge_m),
      // Miscelaneous connections
      .aclk         (aclk),
      .aresetn      (aresetn)
      );

  assign rvalid_maskcntl = rvalid_sIrisBridge_m & rlast_sIrisBridge_m;

 

  assign bvalid_master = (bvalid_sIrisBridge_m & ~wr_cnt_empty);
  assign bready_sIrisBridge_m = (bready_master & ~wr_cnt_empty);

  // ---------------------------------------------------------------------------


  // Gate the output axvalid_vect_sIrisBridge_m with the channel valid
    
  assign awvalid_vect_sIrisBridge_m = ({3{awvalid_sIrisBridge_m}} & awvalid_vector);
  assign arvalid_vect_sIrisBridge_m = ({3{arvalid_sIrisBridge_m}} & arvalid_vector);
    
  // ---------------------------------------------------------------------------
  // AW Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign aw_slave_port_src_data = {awid_sIrisBridge_s,
          awaddr_sIrisBridge_s,
          awlen_sIrisBridge_s,
          awsize_sIrisBridge_s,
          awburst_sIrisBridge_s,
          awlock_sIrisBridge_s,
          awcache_sIrisBridge_s,
          awprot_sIrisBridge_s};

  // expand the concatenated registered values to the slave port outputs
  assign {awid,
          awaddr_int_s,
          awlen_sIrisBridge_m,
          awsize_sIrisBridge_m,
          awburst_sIrisBridge_m,
          awlock_sIrisBridge_m,
          awcache_int_sIrisBridge_m,
          awprot_int_sIrisBridge_m} = aw_slave_port_dst_data;



  assign awvalid_int_s = aw_slave_port_dst_valid;
  assign aw_slave_port_dst_ready = awready_int_s;

  assign aw_slave_port_src_valid = awvalid_sIrisBridge_s;
  assign awready_sIrisBridge_s = aw_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_slave_port_src_data = {wdata_sIrisBridge_s,
          wstrb_sIrisBridge_s,
          wlast_sIrisBridge_s};

  // expand the concatenated registered values to the slave port outputs
  assign {wdata_sIrisBridge_m,
          wstrb_sIrisBridge_m,
          wlast_sIrisBridge_m} = w_slave_port_dst_data;



  assign wvalid_sIrisBridge_m = w_slave_port_dst_valid;
  assign w_slave_port_dst_ready = wready_sIrisBridge_m;

  assign w_slave_port_src_valid = wvalid_sIrisBridge_s;
  assign wready_sIrisBridge_s = w_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // AR Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign ar_slave_port_src_data = {arid_sIrisBridge_s,
          araddr_sIrisBridge_s,
          arlen_sIrisBridge_s,
          arsize_sIrisBridge_s,
          arburst_sIrisBridge_s,
          arlock_sIrisBridge_s,
          arcache_sIrisBridge_s,
          arprot_sIrisBridge_s};

  // expand the concatenated registered values to the slave port outputs
  assign {arid,
          araddr_int_s,
          arlen_sIrisBridge_m,
          arsize_sIrisBridge_m,
          arburst_sIrisBridge_m,
          arlock_sIrisBridge_m,
          arcache_int_sIrisBridge_m,
          arprot_int_sIrisBridge_m} = ar_slave_port_dst_data;



  assign arvalid_int_s = ar_slave_port_dst_valid;
  assign ar_slave_port_dst_ready = arready_int_s;

  assign ar_slave_port_src_valid = arvalid_sIrisBridge_s;
  assign arready_sIrisBridge_s = ar_slave_port_src_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at slave_port
  //
  // No register specified for R Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_slave_port_src_data = {rid,
          rdata_sIrisBridge_m,
          rresp_sIrisBridge_m,
          rlast_sIrisBridge_m};

  // expand the concatenated registered values to the slave port outputs
  assign {rid_sIrisBridge_s,
          rdata_sIrisBridge_s,
          rresp_sIrisBridge_s,
          rlast_sIrisBridge_s} = r_slave_port_dst_data;


  assign r_slave_port_dst_data = r_slave_port_src_data;

  assign rvalid_sIrisBridge_s = rvalid_sIrisBridge_m;
  assign rready_sIrisBridge_m = rready_sIrisBridge_s;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at slave_port
  //
  // No register specified for B Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_slave_port_src_data = {bid,
          bresp_sIrisBridge_m};

  // expand the concatenated registered values to the slave port outputs
  assign {bid_sIrisBridge_s,
          bresp_sIrisBridge_s} = b_slave_port_dst_data;


  assign b_slave_port_dst_data = b_slave_port_src_data;

  assign bvalid_sIrisBridge_s = bvalid_master;
  assign bready_master = bready_sIrisBridge_s;

  // ---------------------------------------------------------------------------
  // Instantiation of Timing Isolation Blocks
  // ---------------------------------------------------------------------------

  //  AW Channel Timing Isolation Register Block on slave_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 58
  nic400_asib_sIrisBridge_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       58  // Payload Width
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
  // PAYLOAD_WIDTH = 73
  nic400_asib_sIrisBridge_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       73  // Payload Width
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
  // PAYLOAD_WIDTH = 58
  nic400_asib_sIrisBridge_chan_slice_1
    #(
       `RS_REV_REG,  // Handshake Mode
       58  // Payload Width
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
        .test_expr ( {3{arvalid_int_m}} & arvalid_vector )
      );
  assert_never
    #(`OVL_FATAL, `OVL_ASSERT,
      "Error: AR Valid vector not one-hot during ARVALID")
      ovl_arvalid_vect_one_hot_when_arvalid
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( arvalid_int_m & ~|arvalid_vector )
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
        .test_expr ( {3{awvalid_int_m}} & awvalid_vector )
      );
  assert_never
    #(`OVL_FATAL, `OVL_ASSERT,
      "Error: AW Valid vector not one-hot during AWVALID")
      ovl_awvalid_vect_one_hot_when_awvalid
      (
        .clk (aclk),
        .reset_n (aresetn),
        .test_expr ( awvalid_int_m & ~|awvalid_vector )
      );
  // OVL_ASSERT_END


`endif
// ---------------------------------------------------------------------------


endmodule

`include "nic400_asib_sIrisBridge_undefs_1.v"



// --================================= End ===================================--
