
//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2016 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 208871
// File Date           :  2016-03-31 13:12:55 +0100 (Thu, 31 Mar 2016)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : HDL design file for AMBA interface block master domain
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                        nic400_ib_sSpi_ib_master_domain_1.v
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//  Master domain of AMBA Interface Block (IB) 'sSpi_ib'.
//
//  This IB is a component of ASIB named sSpi
// 
//  32bit to 64bit upsizer
//
//           SIF prot axi4
//           MIF prot axi4
//           SIF DW   32
//           MIF DW   64
//
//           MIF  axi4_m
//           RIF  axi4_m
//           IIF  axi4_m
//           BIF  axi4_m
//
//           ID Width     = 2
//           drive_id     = false
//
//           Burstbreak   = false
//
//------------------------------------------------------------------------------

`include "nic400_ib_sSpi_ib_defs_1.v"

`include "Axi.v"

module nic400_ib_sSpi_ib_master_domain_1
  (
  
    //axi4_m AXI bus

    //AW Channel
    awid_axi4_m,
    awaddr_axi4_m,
    awlen_axi4_m,
    awsize_axi4_m,
    awburst_axi4_m,
    awlock_axi4_m,
    awcache_axi4_m,
    awprot_axi4_m,
    awvalid_axi4_m,
    awvalid_vect_axi4_m,
    awready_axi4_m,

    //W Channel
    wdata_axi4_m,
    wstrb_axi4_m,
    wlast_axi4_m,
    wvalid_axi4_m,
    wready_axi4_m,

    //B Channel
    bid_axi4_m,
    bresp_axi4_m,
    bvalid_axi4_m,
    bready_axi4_m,

    //AR Channel
    arid_axi4_m,
    araddr_axi4_m,
    arlen_axi4_m,
    arsize_axi4_m,
    arburst_axi4_m,
    arlock_axi4_m,
    arcache_axi4_m,
    arprot_axi4_m,
    arvalid_axi4_m,
    arvalid_vect_axi4_m,
    arready_axi4_m,

    //R Channel
    rid_axi4_m,
    rdata_axi4_m,
    rresp_axi4_m,
    rlast_axi4_m,
    rvalid_axi4_m,
    rready_axi4_m,

    //QV Signals
    awqv_axi4_m,
    arqv_axi4_m,

    //Inter-domain IB bus

    //AW Inter-domain bus
    aw_data,
    aw_valid,
    aw_ready,

    //B Inter-domain bus
    b_data,
    b_valid,
    b_ready,

    //AR Inter-domain bus
    ar_data,
    ar_valid,
    ar_ready,

    //R Inter-domain bus
    r_data,
    r_valid,
    r_ready,

    //W Inter-domain bus
    w_data,
    w_valid,
    w_ready,

    //Clock and reset signals
    aclk,
    aresetn

  );




  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  
  //axi4_m AXI bus


  //AW Channel
  output  [7:0]       awid_axi4_m;              //write id of axi4_m AXI bus AW channel
  output  [31:0]      awaddr_axi4_m;            //write address of axi4_m AXI bus AW channel
  output  [7:0]       awlen_axi4_m;             //write length field of axi4_m AXI bus AW channel
  output  [2:0]       awsize_axi4_m;            //write size of axi4_m AXI bus AW channel
  output  [1:0]       awburst_axi4_m;           //write burst length of axi4_m AXI bus AW channel
  output              awlock_axi4_m;            //write lock of axi4_m AXI bus AW channel
  output  [3:0]       awcache_axi4_m;           //write cache field of axi4_m AXI bus AW channel
  output  [2:0]       awprot_axi4_m;            //write prot field of axi4_m AXI bus AW channel
  output              awvalid_axi4_m;           //write valid of axi4_m AXI bus AW channel
  output  [2:0]       awvalid_vect_axi4_m;      //write valid vector of axi4_m AXI bus AW channel
  input               awready_axi4_m;           //write ready of axi4_m AXI bus AW channel

  //W Channel
  output  [63:0]      wdata_axi4_m;             //write data of axi4_m AXI bus W Channel
  output  [7:0]       wstrb_axi4_m;             //write strobes of axi4_m AXI bus W Channel
  output              wlast_axi4_m;             //write last of axi4_m AXI bus W Channel
  output              wvalid_axi4_m;            //write valid of axi4_m AXI bus W Channel
  input               wready_axi4_m;            //write ready of axi4_m AXI bus W Channel

  //B Channel
  input   [7:0]       bid_axi4_m;               //b response id of axi4_m AXI bus B Channel
  input   [1:0]       bresp_axi4_m;             //b response status of axi4_m AXI bus B Channel
  input               bvalid_axi4_m;            //b response valid of axi4_m AXI bus B Channel
  output              bready_axi4_m;            //b response ready of axi4_m AXI bus B Channel

  //AR Channel
  output  [7:0]       arid_axi4_m;              //read id of axi4_m AXI bus AR Channel
  output  [31:0]      araddr_axi4_m;            //read address of axi4_m AXI bus AR Channel
  output  [7:0]       arlen_axi4_m;             //read length of axi4_m AXI bus AR Channel
  output  [2:0]       arsize_axi4_m;            //read size of axi4_m AXI bus AR Channel
  output  [1:0]       arburst_axi4_m;           //read burst length of axi4_m AXI bus AR Channel
  output              arlock_axi4_m;            //read lock of axi4_m AXI bus AR Channel
  output  [3:0]       arcache_axi4_m;           //read cache field of axi4_m AXI bus AR Channel
  output  [2:0]       arprot_axi4_m;            //read prot field of axi4_m AXI bus AR Channel
  output              arvalid_axi4_m;           //read valid of axi4_m AXI bus AR Channel
  output  [2:0]       arvalid_vect_axi4_m;      //read valid vector of axi4_m AXI bus AR Channel
  input               arready_axi4_m;           //read ready of axi4_m AXI bus AR Channel

  //R Channel
  input   [7:0]       rid_axi4_m;               //read id of axi4_m AXI bus R Channel
  input   [63:0]      rdata_axi4_m;             //read data of axi4_m AXI bus R Channel
  input   [1:0]       rresp_axi4_m;             //read response status of axi4_m AXI bus R Channel
  input               rlast_axi4_m;             //read last of axi4_m AXI bus R Channel
  input               rvalid_axi4_m;            //read valid of axi4_m AXI bus R Channel
  output              rready_axi4_m;            //read ready of axi4_m AXI bus R Channel

  //QV Signals
  output  [3:0]       awqv_axi4_m;              //QV value of axi4_m AXI bus AW Channel
  output  [3:0]       arqv_axi4_m;              //QV value of axi4_m AXI bus AR Channel

  //Inter-domain IB bus


  //AW Inter-domain bus
  input   [57:0]      aw_data;                  //AW Channel Data
  input               aw_valid;                 //AW Channel Valid signal
  output              aw_ready;                 //AW Channel Ready signal

  //B Inter-domain bus
  output  [3:0]       b_data;                   //B Channel Data
  output              b_valid;                  //B Channel Valid signal
  input               b_ready;                  //B Channel Ready signal

  //AR Inter-domain bus
  input   [57:0]      ar_data;                  //AR Channel Data
  input               ar_valid;                 //AR Channel Valid signal
  output              ar_ready;                 //AR Channel Ready signal

  //R Inter-domain bus
  output  [68:0]      r_data;                   //R Channel Data
  output              r_valid;                  //R Channel Valid signal
  input               r_ready;                  //R Channel Ready signal

  //W Inter-domain bus
  input   [72:0]      w_data;                   //W Channel Data
  input               w_valid;                  //W Channel Valid signal
  output              w_ready;                  //W Channel Ready signal

  //Clock and reset signals
  input               aclk;                     //main clock
  input               aresetn;                  //main reset


  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  wire                awvalid_master;
  wire                awready_master;
  wire                arvalid_master;
  wire                arready_master;
  wire                bvalid_master;
  wire                bready_master;
  wire                rvalid_master;



  wire [2:0]          awvalid_vector;
  wire [2:0]          arvalid_vector;

  wire                wr_cnt_empty;
  wire                mask_w;
  wire                mask_r;


  // Channel id output from internal blocks
  // before being appended with the asib_id
  wire [1:0]          awid;

  wire [1:0]          wid;
  wire [1:0]          arid;
  wire [1:0]          rid;
  wire [1:0]          bid;
  wire [3:0]          zero_pad;
      
  wire [1:0]          asib_sSpi_ib_siid;
  

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------




  // ---------------------------------------------------------------------------
  // AW Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // expand the concatenated registered values to the boundary outputs
  assign {
          awid,
          awaddr_axi4_m[31:0],
          awlen_axi4_m,
          awsize_axi4_m,
          awburst_axi4_m,
          awlock_axi4_m,
          awcache_axi4_m,
          awprot_axi4_m,
          awvalid_vector} = aw_data;

  

  assign awvalid_master = aw_valid;
  assign aw_ready = awready_master;






  // ---------------------------------------------------------------------------
  // AR Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // expand the concatenated registered values to the boundary outputs
  assign {
          arid,
          araddr_axi4_m[31:0],
          arlen_axi4_m,
          arsize_axi4_m,
          arburst_axi4_m,
          arlock_axi4_m,
          arcache_axi4_m,
          arprot_axi4_m,
          arvalid_vector} = ar_data;

  

  assign arvalid_master = ar_valid;
  assign ar_ready = arready_master;






  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // expand the concatenated registered values to the boundary outputs
  assign {
          wdata_axi4_m,
          wstrb_axi4_m,
          wlast_axi4_m} = w_data;

  

  assign wvalid_axi4_m = w_valid;
  assign w_ready = wready_axi4_m;




  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign r_data = {
          rid,
          rdata_axi4_m,
          rresp_axi4_m,
          rlast_axi4_m};

  assign r_valid = rvalid_axi4_m;
  assign rready_axi4_m = r_ready;


  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign b_data = {
          bid,
          bresp_axi4_m};

  assign b_valid = bvalid_master;
  assign bready_master = b_ready;

  // AW channel is set to wires at boundary.

  // AR channel is set to wires at boundary.

  // R channel is set to wires at boundary.

  // W channel is set to wires at boundary.

  // B channel is set to wires at boundary.

  // ---------------------------------------------------------------------------
  // Output ID concatenation
  // ---------------------------------------------------------------------------


  // id values in this section are defined in the top level design description
  // and are design specific.
  assign asib_sSpi_ib_siid = 2'b0;


  // ----------

  assign zero_pad = 4'b0;

  assign awid_axi4_m = {zero_pad,awid,asib_sSpi_ib_siid};
  assign arid_axi4_m = {zero_pad,arid,asib_sSpi_ib_siid};

  assign bid = bid_axi4_m[3:2];
  assign rid = rid_axi4_m[3:2];
  
  // End of ID section
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  //  Address channel transaction counting
  // ---------------------------------------------------------------------------

nic400_ib_sSpi_ib_maskcntl_1 u_maskcntl (
        // Master Interface address channel handshake signals
        .awvalid_m    (awvalid_master),
        .arvalid_m    (arvalid_master),
        .awready_m    (awready_master),
        .arready_m    (arready_master),
        // Master Interface return channel handshake signals
        .bvalid_m     (bvalid_master),
        .bready_m     (bready_master),
        .rvalid_m     (rvalid_master),
        .rready_m     (rready_axi4_m),
        // Mask signals
        .wr_cnt_empty (wr_cnt_empty),
        .mask_w       (mask_w),
        .mask_r       (mask_r),
        // QoS output signals
        .aw_qos_m     (awqv_axi4_m),
        .ar_qos_m     (arqv_axi4_m),
        // Miscelaneous connections
        .aclk         (aclk),
        .aresetn      (aresetn)
        );


  
  assign awvalid_axi4_m = (awvalid_master & !mask_w);
  assign arvalid_axi4_m = (arvalid_master & !mask_r);

  assign awready_master = (awready_axi4_m & !mask_w);
  assign arready_master = (arready_axi4_m & !mask_r);

  assign bvalid_master = (bvalid_axi4_m & !wr_cnt_empty);
  assign bready_axi4_m = (bready_master & !wr_cnt_empty);



  assign rvalid_master = rvalid_axi4_m & rlast_axi4_m;

  
  // Gate the output axvalid_vect_axi4_m with the channel valid
  assign awvalid_vect_axi4_m = ({3{awvalid_axi4_m}} & awvalid_vector);
  assign arvalid_vect_axi4_m = ({3{arvalid_axi4_m}} & arvalid_vector);
  
  // ---------------------------------------------------------------------------
  // Wiring at master_port
  // ---------------------------------------------------------------------------

  // AW channel is set to wires at master_port.

  // AR channel is set to wires at master_port.

  // R channel is set to wires at master_port.

  // W channel is set to wires at master_port.

  // B channel is set to wires at master_port.


  // ---------------------------------------------------------------------------







endmodule
`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"



// --================================= End ===================================--
