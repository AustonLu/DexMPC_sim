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
//                               nic400_asib_sD2dData.v
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


`include "nic400_asib_sD2dData_defs_1.v"

module nic400_asib_sD2dData_1
 (
  
    //sD2dData_m AXI bus

    //AW Channel
    awid_sD2dData_m,
    awaddr_sD2dData_m,
    awlen_sD2dData_m,
    awsize_sD2dData_m,
    awburst_sD2dData_m,
    awlock_sD2dData_m,
    awcache_sD2dData_m,
    awprot_sD2dData_m,
    awvalid_sD2dData_m,
    awvalid_vect_sD2dData_m,
    awready_sD2dData_m,

    //W Channel
    wdata_sD2dData_m,
    wstrb_sD2dData_m,
    wlast_sD2dData_m,
    wvalid_sD2dData_m,
    wready_sD2dData_m,

    //B Channel
    bid_sD2dData_m,
    bresp_sD2dData_m,
    bvalid_sD2dData_m,
    bready_sD2dData_m,

    //AR Channel
    arid_sD2dData_m,
    araddr_sD2dData_m,
    arlen_sD2dData_m,
    arsize_sD2dData_m,
    arburst_sD2dData_m,
    arlock_sD2dData_m,
    arcache_sD2dData_m,
    arprot_sD2dData_m,
    arvalid_sD2dData_m,
    arvalid_vect_sD2dData_m,
    arready_sD2dData_m,

    //R Channel
    rid_sD2dData_m,
    rdata_sD2dData_m,
    rresp_sD2dData_m,
    rlast_sD2dData_m,
    rvalid_sD2dData_m,
    rready_sD2dData_m,

    //QoS Signals
    awqv_sD2dData_m,
    arqv_sD2dData_m,

    //sD2dData_s AXI bus

    //AW Channel
    awid_sD2dData_s,
    awaddr_sD2dData_s,
    awlen_sD2dData_s,
    awsize_sD2dData_s,
    awburst_sD2dData_s,
    awlock_sD2dData_s,
    awcache_sD2dData_s,
    awprot_sD2dData_s,
    awvalid_sD2dData_s,
    awready_sD2dData_s,

    //W Channel
    wdata_sD2dData_s,
    wstrb_sD2dData_s,
    wlast_sD2dData_s,
    wvalid_sD2dData_s,
    wready_sD2dData_s,

    //B Channel
    bid_sD2dData_s,
    bresp_sD2dData_s,
    bvalid_sD2dData_s,
    bready_sD2dData_s,

    //AR Channel
    arid_sD2dData_s,
    araddr_sD2dData_s,
    arlen_sD2dData_s,
    arsize_sD2dData_s,
    arburst_sD2dData_s,
    arlock_sD2dData_s,
    arcache_sD2dData_s,
    arprot_sD2dData_s,
    arvalid_sD2dData_s,
    arready_sD2dData_s,

    //R Channel
    rid_sD2dData_s,
    rdata_sD2dData_s,
    rresp_sD2dData_s,
    rlast_sD2dData_s,
    rvalid_sD2dData_s,
    rready_sD2dData_s,

    //Clock, reset and tie-off signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //sD2dData_m AXI bus


  //AW Channel
  output  [7:0]       awid_sD2dData_m;              //write id of sD2dData_m AXI bus AW channel
  output  [31:0]      awaddr_sD2dData_m;            //write address of sD2dData_m AXI bus AW channel
  output  [7:0]       awlen_sD2dData_m;             //write length field of sD2dData_m AXI bus AW channel
  output  [2:0]       awsize_sD2dData_m;            //write size of sD2dData_m AXI bus AW channel
  output  [1:0]       awburst_sD2dData_m;           //write burst length of sD2dData_m AXI bus AW channel
  output              awlock_sD2dData_m;            //write lock of sD2dData_m AXI bus AW channel
  output  [3:0]       awcache_sD2dData_m;           //write cache field of sD2dData_m AXI bus AW channel
  output  [2:0]       awprot_sD2dData_m;            //write prot field of sD2dData_m AXI bus AW channel
  output              awvalid_sD2dData_m;           //write valid of sD2dData_m AXI bus AW channel
  output  [2:0]       awvalid_vect_sD2dData_m;      //write valid vector of sD2dData_m AXI bus AW channel
  input               awready_sD2dData_m;           //write ready of sD2dData_m AXI bus AW channel

  //W Channel
  output  [63:0]      wdata_sD2dData_m;             //write data of sD2dData_m AXI bus W Channel
  output  [7:0]       wstrb_sD2dData_m;             //write strobes of sD2dData_m AXI bus W Channel
  output              wlast_sD2dData_m;             //write last of sD2dData_m AXI bus W Channel
  output              wvalid_sD2dData_m;            //write valid of sD2dData_m AXI bus W Channel
  input               wready_sD2dData_m;            //write ready of sD2dData_m AXI bus W Channel

  //B Channel
  input   [7:0]       bid_sD2dData_m;               //b response id of sD2dData_m AXI bus B Channel
  input   [1:0]       bresp_sD2dData_m;             //b response status of sD2dData_m AXI bus B Channel
  input               bvalid_sD2dData_m;            //b response valid of sD2dData_m AXI bus B Channel
  output              bready_sD2dData_m;            //b response ready of sD2dData_m AXI bus B Channel

  //AR Channel
  output  [7:0]       arid_sD2dData_m;              //read id of sD2dData_m AXI bus AR Channel
  output  [31:0]      araddr_sD2dData_m;            //read address of sD2dData_m AXI bus AR Channel
  output  [7:0]       arlen_sD2dData_m;             //read length of sD2dData_m AXI bus AR Channel
  output  [2:0]       arsize_sD2dData_m;            //read size of sD2dData_m AXI bus AR Channel
  output  [1:0]       arburst_sD2dData_m;           //read burst length of sD2dData_m AXI bus AR Channel
  output              arlock_sD2dData_m;            //read lock of sD2dData_m AXI bus AR Channel
  output  [3:0]       arcache_sD2dData_m;           //read cache field of sD2dData_m AXI bus AR Channel
  output  [2:0]       arprot_sD2dData_m;            //read prot field of sD2dData_m AXI bus AR Channel
  output              arvalid_sD2dData_m;           //read valid of sD2dData_m AXI bus AR Channel
  output  [2:0]       arvalid_vect_sD2dData_m;      //read valid vector of sD2dData_m AXI bus AR Channel
  input               arready_sD2dData_m;           //read ready of sD2dData_m AXI bus AR Channel

  //R Channel
  input   [7:0]       rid_sD2dData_m;               //read id of sD2dData_m AXI bus R Channel
  input   [63:0]      rdata_sD2dData_m;             //read data of sD2dData_m AXI bus R Channel
  input   [1:0]       rresp_sD2dData_m;             //read response status of sD2dData_m AXI bus R Channel
  input               rlast_sD2dData_m;             //read last of sD2dData_m AXI bus R Channel
  input               rvalid_sD2dData_m;            //read valid of sD2dData_m AXI bus R Channel
  output              rready_sD2dData_m;            //read ready of sD2dData_m AXI bus R Channel

  //QoS Signals
  output  [3:0]       awqv_sD2dData_m;              //QoS value of sD2dData_m AXI bus AW Channel
  output  [3:0]       arqv_sD2dData_m;              //QoS value of sD2dData_m AXI bus AR Channel

  //sD2dData_s AXI bus


  //AW Channel
  input   [4:0]       awid_sD2dData_s;              //write id of sD2dData_s AXI bus AW channel
  input   [31:0]      awaddr_sD2dData_s;            //write address of sD2dData_s AXI bus AW channel
  input   [7:0]       awlen_sD2dData_s;             //write length field of sD2dData_s AXI bus AW channel
  input   [2:0]       awsize_sD2dData_s;            //write size of sD2dData_s AXI bus AW channel
  input   [1:0]       awburst_sD2dData_s;           //write burst length of sD2dData_s AXI bus AW channel
  input               awlock_sD2dData_s;            //write lock of sD2dData_s AXI bus AW channel
  input   [3:0]       awcache_sD2dData_s;           //write cache field of sD2dData_s AXI bus AW channel
  input   [2:0]       awprot_sD2dData_s;            //write prot field of sD2dData_s AXI bus AW channel
  input               awvalid_sD2dData_s;           //write valid of sD2dData_s AXI bus AW channel
  output              awready_sD2dData_s;           //write ready of sD2dData_s AXI bus AW channel

  //W Channel
  input   [63:0]      wdata_sD2dData_s;             //write data of sD2dData_s AXI bus W Channel
  input   [7:0]       wstrb_sD2dData_s;             //write strobes of sD2dData_s AXI bus W Channel
  input               wlast_sD2dData_s;             //write last of sD2dData_s AXI bus W Channel
  input               wvalid_sD2dData_s;            //write valid of sD2dData_s AXI bus W Channel
  output              wready_sD2dData_s;            //write ready of sD2dData_s AXI bus W Channel

  //B Channel
  output  [4:0]       bid_sD2dData_s;               //b response id of sD2dData_s AXI bus B Channel
  output  [1:0]       bresp_sD2dData_s;             //b response status of sD2dData_s AXI bus B Channel
  output              bvalid_sD2dData_s;            //b response valid of sD2dData_s AXI bus B Channel
  input               bready_sD2dData_s;            //b response ready of sD2dData_s AXI bus B Channel

  //AR Channel
  input   [4:0]       arid_sD2dData_s;              //read id of sD2dData_s AXI bus AR Channel
  input   [31:0]      araddr_sD2dData_s;            //read address of sD2dData_s AXI bus AR Channel
  input   [7:0]       arlen_sD2dData_s;             //read length of sD2dData_s AXI bus AR Channel
  input   [2:0]       arsize_sD2dData_s;            //read size of sD2dData_s AXI bus AR Channel
  input   [1:0]       arburst_sD2dData_s;           //read burst length of sD2dData_s AXI bus AR Channel
  input               arlock_sD2dData_s;            //read lock of sD2dData_s AXI bus AR Channel
  input   [3:0]       arcache_sD2dData_s;           //read cache field of sD2dData_s AXI bus AR Channel
  input   [2:0]       arprot_sD2dData_s;            //read prot field of sD2dData_s AXI bus AR Channel
  input               arvalid_sD2dData_s;           //read valid of sD2dData_s AXI bus AR Channel
  output              arready_sD2dData_s;           //read ready of sD2dData_s AXI bus AR Channel

  //R Channel
  output  [4:0]       rid_sD2dData_s;               //read id of sD2dData_s AXI bus R Channel
  output  [63:0]      rdata_sD2dData_s;             //read data of sD2dData_s AXI bus R Channel
  output  [1:0]       rresp_sD2dData_s;             //read response status of sD2dData_s AXI bus R Channel
  output              rlast_sD2dData_s;             //read last of sD2dData_s AXI bus R Channel
  output              rvalid_sD2dData_s;            //read valid of sD2dData_s AXI bus R Channel
  input               rready_sD2dData_s;            //read ready of sD2dData_s AXI bus R Channel

  //Clock, reset and tie-off signals
  input               aclk;                         //main clock
  input               aresetn;                      //main reset



  
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

  wire [3:0]          arcache_int_sD2dData_m;
  wire [3:0]          awcache_int_sD2dData_m;
  wire [2:0]          arprot_int_sD2dData_m;
  wire [2:0]          awprot_int_sD2dData_m;
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
  wire [1:0]          asib_sD2dData_siid;
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

  assign asib_sD2dData_siid = 2'b10;


  // ----------

  assign zero_pad = 1'b0;

  assign awid_sD2dData_m = {zero_pad,awid,asib_sD2dData_siid};
  assign arid_sD2dData_m = {zero_pad,arid,asib_sD2dData_siid};
  assign bid = bid_sD2dData_m[6:2];
  assign rid = rid_sD2dData_m[6:2];

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





  assign arvalid_sD2dData_m = arvalid_int_m & cds_ar_enable & !mask_r;
  assign awvalid_sD2dData_m = awvalid_int_m & cds_aw_enable & !mask_w;
  assign arready_int_m  = arready_sD2dData_m & cds_ar_enable & !mask_r;
  assign awready_int_m  = awready_sD2dData_m & cds_aw_enable & !mask_w;


  // Address assigns across decode block
  assign awaddr_int_m = awaddr_int_s;
  assign araddr_int_m = araddr_int_s;

  // Address assigns at master_port
  assign awaddr_sD2dData_m = awaddr_int_m;
  assign araddr_sD2dData_m = araddr_int_m;

  // Drive AxPROT bits to appropriate values
  assign arprot_sD2dData_m[2] = arprot_int_sD2dData_m[2];
  assign arprot_sD2dData_m[1] = 1'b1;
  assign arprot_sD2dData_m[0] = arprot_int_sD2dData_m[0];

  assign awprot_sD2dData_m[2] = awprot_int_sD2dData_m[2];
  assign awprot_sD2dData_m[1] = 1'b1;
  assign awprot_sD2dData_m[0] = awprot_int_sD2dData_m[0];

  //------------------------------------------------------------------------------
  // AW address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sD2dData_decode_1 u_aw_add_decode
  (
    .addr_s                 (awaddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (awprot_sD2dData_m[1]),
    .acache_in              (awcache_int_sD2dData_m),
    .acache_out             (awcache_sD2dData_m),
    .avalid_int             (awvalid_vector)

  );

nic400_asib_sD2dData_wr_ss_cdas_1 u_asib_sD2dData_wr_ss_cdas
  (
    .aw_enable              (cds_aw_enable),
    .wr_enable              (cds_w_enable),
    .asel                   (awvalid_vector),
    .avalid                 (awvalid_int_m),
    .aready                 (awready_int_m),
    .wvalid                 (wvalid_sD2dData_m),
    .wready                 (wready_sD2dData_m),
    .wlast                  (wlast_sD2dData_m),
    .resp_valid             (bvalid_sD2dData_m),
    .resp_ready             (bready_sD2dData_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );


  //------------------------------------------------------------------------------
  // AR address decode
  //
  //------------------------------------------------------------------------------

  nic400_asib_sD2dData_decode_1 u_ar_add_decode
  (
    .addr_s                 (araddr_int_s),
    .security62               (security62),
    .security63               (security63),
    .aprot                  (arprot_sD2dData_m[1]),
    .acache_in              (arcache_int_sD2dData_m),
    .acache_out             (arcache_sD2dData_m),
    .avalid_int             (arvalid_vector)

  );

nic400_asib_sD2dData_rd_ss_cdas_1 u_asib_sD2dData_rd_ss_cdas
  (
    .ar_enable              (cds_ar_enable),
    .asel                   (arvalid_vector),
    .avalid                 (arvalid_int_m),
    .aready                 (arready_int_m),
    .resp_valid             (rvalid_sD2dData_m),
    .resp_last              (rlast_sD2dData_m),
    .resp_ready             (rready_sD2dData_m),

    // Miscelaneous connections
    .aclk                   (aclk),
    .aresetn                (aresetn)
  );

  // ---------------------------------------------------------------------------
  //  Address channel transaction counting
  // ---------------------------------------------------------------------------


  // Mask control present = true
  nic400_asib_sD2dData_maskcntl_1 u_asib_sD2dData_maskcntl (
      // Master Interface address channel handshake signals
      .awvalid_m    (awvalid_int_m),
      .arvalid_m    (arvalid_int_m),
      .awready_m    (awready_int_m),
      .arready_m    (arready_int_m),
      // Master Interface return channel handshake signals
      .bvalid_m     (bvalid_sD2dData_m),
      .bready_m     (bready_sD2dData_m),
      .rvalid_m     (rvalid_maskcntl),
      .rready_m     (rready_sD2dData_m),

      // Write counter status
      .wr_cnt_empty (wr_cnt_empty),
      // Mask signals
      .mask_w       (mask_w),
      .mask_r       (mask_r),
      // QoS output signals
      .aw_qos_m     (awqv_sD2dData_m),
      .ar_qos_m     (arqv_sD2dData_m),
      // Miscelaneous connections
      .aclk         (aclk),
      .aresetn      (aresetn)
      );

  assign rvalid_maskcntl = rvalid_sD2dData_m & rlast_sD2dData_m;

 

  assign bvalid_master = (bvalid_sD2dData_m & ~wr_cnt_empty);
  assign bready_sD2dData_m = (bready_master & ~wr_cnt_empty);

  // ---------------------------------------------------------------------------


  // Gate the output axvalid_vect_sD2dData_m with the channel valid
    
  assign awvalid_vect_sD2dData_m = ({3{awvalid_sD2dData_m}} & awvalid_vector);
  assign arvalid_vect_sD2dData_m = ({3{arvalid_sD2dData_m}} & arvalid_vector);
    
  // ---------------------------------------------------------------------------
  // AW Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign aw_slave_port_src_data = {awid_sD2dData_s,
          awaddr_sD2dData_s,
          awlen_sD2dData_s,
          awsize_sD2dData_s,
          awburst_sD2dData_s,
          awlock_sD2dData_s,
          awcache_sD2dData_s,
          awprot_sD2dData_s};

  // expand the concatenated registered values to the slave port outputs
  assign {awid,
          awaddr_int_s,
          awlen_sD2dData_m,
          awsize_sD2dData_m,
          awburst_sD2dData_m,
          awlock_sD2dData_m,
          awcache_int_sD2dData_m,
          awprot_int_sD2dData_m} = aw_slave_port_dst_data;



  assign awvalid_int_s = aw_slave_port_dst_valid;
  assign aw_slave_port_dst_ready = awready_int_s;

  assign aw_slave_port_src_valid = awvalid_sD2dData_s;
  assign awready_sD2dData_s = aw_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_slave_port_src_data = {wdata_sD2dData_s,
          wstrb_sD2dData_s,
          wlast_sD2dData_s};

  // expand the concatenated registered values to the slave port outputs
  assign {wdata_sD2dData_m,
          wstrb_sD2dData_m,
          wlast_sD2dData_m} = w_slave_port_dst_data;



  assign wvalid_sD2dData_m = w_slave_port_dst_valid;
  assign w_slave_port_dst_ready = wready_sD2dData_m;

  assign w_slave_port_src_valid = wvalid_sD2dData_s;
  assign wready_sD2dData_s = w_slave_port_src_ready;

  // ---------------------------------------------------------------------------
  // AR Channel timing block wiring at slave_port
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign ar_slave_port_src_data = {arid_sD2dData_s,
          araddr_sD2dData_s,
          arlen_sD2dData_s,
          arsize_sD2dData_s,
          arburst_sD2dData_s,
          arlock_sD2dData_s,
          arcache_sD2dData_s,
          arprot_sD2dData_s};

  // expand the concatenated registered values to the slave port outputs
  assign {arid,
          araddr_int_s,
          arlen_sD2dData_m,
          arsize_sD2dData_m,
          arburst_sD2dData_m,
          arlock_sD2dData_m,
          arcache_int_sD2dData_m,
          arprot_int_sD2dData_m} = ar_slave_port_dst_data;



  assign arvalid_int_s = ar_slave_port_dst_valid;
  assign ar_slave_port_dst_ready = arready_int_s;

  assign ar_slave_port_src_valid = arvalid_sD2dData_s;
  assign arready_sD2dData_s = ar_slave_port_src_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at slave_port
  //
  // No register specified for R Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_slave_port_src_data = {rid,
          rdata_sD2dData_m,
          rresp_sD2dData_m,
          rlast_sD2dData_m};

  // expand the concatenated registered values to the slave port outputs
  assign {rid_sD2dData_s,
          rdata_sD2dData_s,
          rresp_sD2dData_s,
          rlast_sD2dData_s} = r_slave_port_dst_data;


  assign r_slave_port_dst_data = r_slave_port_src_data;

  assign rvalid_sD2dData_s = rvalid_sD2dData_m;
  assign rready_sD2dData_m = rready_sD2dData_s;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at slave_port
  //
  // No register specified for B Channel: Wire straight across
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_slave_port_src_data = {bid,
          bresp_sD2dData_m};

  // expand the concatenated registered values to the slave port outputs
  assign {bid_sD2dData_s,
          bresp_sD2dData_s} = b_slave_port_dst_data;


  assign b_slave_port_dst_data = b_slave_port_src_data;

  assign bvalid_sD2dData_s = bvalid_master;
  assign bready_master = bready_sD2dData_s;

  // ---------------------------------------------------------------------------
  // Instantiation of Timing Isolation Blocks
  // ---------------------------------------------------------------------------

  //  AW Channel Timing Isolation Register Block on slave_port

  // HNDSHK_MODE = rev
  // PAYLOAD_WIDTH = 58
  nic400_asib_sD2dData_chan_slice_1
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
  nic400_asib_sD2dData_chan_slice_1
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
  nic400_asib_sD2dData_chan_slice_1
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

`include "nic400_asib_sD2dData_undefs_1.v"



// --================================= End ===================================--
