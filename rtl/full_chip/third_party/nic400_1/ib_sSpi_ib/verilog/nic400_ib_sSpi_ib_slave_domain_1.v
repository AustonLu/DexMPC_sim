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
// Purpose : HDL design file for AMBA interface block slave domain
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//                        nic400_ib_sSpi_ib_slave_domain_1.v
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//  Slave domain of AMBA Interface Block (IB) 'sSpi_ib'.
//
//  This IB is a component of ASIB named sSpi
//  
//  32bit to 64bit upsize
//
//           SIF prot axi4
//           MIF prot axi4
//           SIF DW   32
//           MIF DW   64
//
//           MIF  axi4_m
//           RIF  axi4_s
//           IIF  axi4_s
//           BIF  bif
//
//           Burstbreak   = false
//------------------------------------------------------------------------------

`include "nic400_ib_sSpi_ib_defs_1.v"
`include "Axi.v"

module nic400_ib_sSpi_ib_slave_domain_1
  (
  
    //axi4_s AXI bus

    //AW Channel
    awid_axi4_s,
    awaddr_axi4_s,
    awlen_axi4_s,
    awsize_axi4_s,
    awburst_axi4_s,
    awlock_axi4_s,
    awcache_axi4_s,
    awprot_axi4_s,
    awvalid_axi4_s,
    awvalid_vect_axi4_s,
    awready_axi4_s,

    //W Channel
    wdata_axi4_s,
    wstrb_axi4_s,
    wlast_axi4_s,
    wvalid_axi4_s,
    wready_axi4_s,

    //B Channel
    bid_axi4_s,
    bresp_axi4_s,
    bvalid_axi4_s,
    bready_axi4_s,

    //AR Channel
    arid_axi4_s,
    araddr_axi4_s,
    arlen_axi4_s,
    arsize_axi4_s,
    arburst_axi4_s,
    arlock_axi4_s,
    arcache_axi4_s,
    arprot_axi4_s,
    arvalid_axi4_s,
    arvalid_vect_axi4_s,
    arready_axi4_s,

    //R Channel
    rid_axi4_s,
    rdata_axi4_s,
    rresp_axi4_s,
    rlast_axi4_s,
    rvalid_axi4_s,
    rready_axi4_s,

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
  
  //axi4_s AXI bus


  //AW Channel
  input   [1:0]       awid_axi4_s;              //write id of axi4_s AXI bus AW channel
  input   [31:0]      awaddr_axi4_s;            //write address of axi4_s AXI bus AW channel
  input   [7:0]       awlen_axi4_s;             //write length field of axi4_s AXI bus AW channel
  input   [2:0]       awsize_axi4_s;            //write size of axi4_s AXI bus AW channel
  input   [1:0]       awburst_axi4_s;           //write burst length of axi4_s AXI bus AW channel
  input               awlock_axi4_s;            //write lock of axi4_s AXI bus AW channel
  input   [3:0]       awcache_axi4_s;           //write cache field of axi4_s AXI bus AW channel
  input   [2:0]       awprot_axi4_s;            //write prot field of axi4_s AXI bus AW channel
  input               awvalid_axi4_s;           //write valid of axi4_s AXI bus AW channel
  input   [2:0]       awvalid_vect_axi4_s;      //write valid vector of axi4_s AXI bus AW channel
  output              awready_axi4_s;           //write ready of axi4_s AXI bus AW channel

  //W Channel
  input   [31:0]      wdata_axi4_s;             //write data of axi4_s AXI bus W Channel
  input   [3:0]       wstrb_axi4_s;             //write strobes of axi4_s AXI bus W Channel
  input               wlast_axi4_s;             //write last of axi4_s AXI bus W Channel
  input               wvalid_axi4_s;            //write valid of axi4_s AXI bus W Channel
  output              wready_axi4_s;            //write ready of axi4_s AXI bus W Channel

  //B Channel
  output  [1:0]       bid_axi4_s;               //b response id of axi4_s AXI bus B Channel
  output  [1:0]       bresp_axi4_s;             //b response status of axi4_s AXI bus B Channel
  output              bvalid_axi4_s;            //b response valid of axi4_s AXI bus B Channel
  input               bready_axi4_s;            //b response ready of axi4_s AXI bus B Channel

  //AR Channel
  input   [1:0]       arid_axi4_s;              //read id of axi4_s AXI bus AR Channel
  input   [31:0]      araddr_axi4_s;            //read address of axi4_s AXI bus AR Channel
  input   [7:0]       arlen_axi4_s;             //read length of axi4_s AXI bus AR Channel
  input   [2:0]       arsize_axi4_s;            //read size of axi4_s AXI bus AR Channel
  input   [1:0]       arburst_axi4_s;           //read burst length of axi4_s AXI bus AR Channel
  input               arlock_axi4_s;            //read lock of axi4_s AXI bus AR Channel
  input   [3:0]       arcache_axi4_s;           //read cache field of axi4_s AXI bus AR Channel
  input   [2:0]       arprot_axi4_s;            //read prot field of axi4_s AXI bus AR Channel
  input               arvalid_axi4_s;           //read valid of axi4_s AXI bus AR Channel
  input   [2:0]       arvalid_vect_axi4_s;      //read valid vector of axi4_s AXI bus AR Channel
  output              arready_axi4_s;           //read ready of axi4_s AXI bus AR Channel

  //R Channel
  output  [1:0]       rid_axi4_s;               //read id of axi4_s AXI bus R Channel
  output  [31:0]      rdata_axi4_s;             //read data of axi4_s AXI bus R Channel
  output  [1:0]       rresp_axi4_s;             //read response status of axi4_s AXI bus R Channel
  output              rlast_axi4_s;             //read last of axi4_s AXI bus R Channel
  output              rvalid_axi4_s;            //read valid of axi4_s AXI bus R Channel
  input               rready_axi4_s;            //read ready of axi4_s AXI bus R Channel

  //Inter-domain IB bus


  //AW Inter-domain bus
  output  [57:0]      aw_data;                  //AW Channel Data
  output              aw_valid;                 //AW Channel Valid signal
  input               aw_ready;                 //AW Channel Ready signal

  //B Inter-domain bus
  input   [3:0]       b_data;                   //B Channel Data
  input               b_valid;                  //B Channel Valid signal
  output              b_ready;                  //B Channel Ready signal

  //AR Inter-domain bus
  output  [57:0]      ar_data;                  //AR Channel Data
  output              ar_valid;                 //AR Channel Valid signal
  input               ar_ready;                 //AR Channel Ready signal

  //R Inter-domain bus
  input   [68:0]      r_data;                   //R Channel Data
  input               r_valid;                  //R Channel Valid signal
  output              r_ready;                  //R Channel Ready signal

  //W Inter-domain bus
  output  [72:0]      w_data;                   //W Channel Data
  output              w_valid;                  //W Channel Valid signal
  input               w_ready;                  //W Channel Ready signal

  //Clock and reset signals
  input               aclk;                     //main clock
  input               aresetn;                  //main reset
   

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------


  //------------------------------------------------------------------------------
  // Wires that run between blocks
  //------------------------------------------------------------------------------

  //Signals between write address format and B channel
  wire [2:0]          bdata_data;
  wire                bdata_valid;
  wire                bdata_ready;

  //Signals between the AW Format Block and the Write Control Block
  wire [15:0]         awdata_data;
  wire                awdata_valid;
  wire                awdata_ready;

  //Signals between write_control and merge buffer
  wire                merge;
  wire                merge_clear;
  wire [1:0]          data_select;
  wire                strb_skid_valid;

  //Signals from the merge buffer to the write_contol block
  wire [63:0]         wdata_merged;
  wire [7:0]          wstrb_merged;
  //Signals bewteen read address format and CAM Slices
  wire [16:0]         arfifo_data;
  wire                arfifo_valid;
  wire                arfifo_ready;  
  wire  [57:0]        aw_fmt_src_data;
  wire  [57:0]        ar_fmt_src_data;
  wire  [57:0]        aw_fmt_dst_data;
  wire  [57:0]        ar_fmt_dst_data;

  // AXI_bif BIF



  // AW Channel: Connections between AW format block and boundary
  wire [1:0]          awid_bif;
  wire [31:0]         awaddr_bif;
  wire [7:0]          awlen_bif;
  wire [2:0]          awsize_bif;
  wire [1:0]          awburst_bif;
  wire           awlock_bif;
  wire [3:0]          awcache_bif;
  wire [2:0]          awprot_bif;
  wire                awvalid_bif;
  wire [2:0]          awvalid_vect_bif;
  wire                awready_bif;

  // AR Channel: Connections between AR format block and boundary
  wire [1:0]          arid_bif;
  wire [31:0]         araddr_bif;
  wire [7:0]          arlen_bif;
  wire [2:0]          arsize_bif;
  wire [1:0]          arburst_bif;
  wire           arlock_bif;
  wire [3:0]          arcache_bif;
  wire [2:0]          arprot_bif;
  wire                arvalid_bif;
  wire [2:0]          arvalid_vect_bif;
  wire                arready_bif;
  // W Channel: Connections between write control block and boundary
  wire                wvalid_bif;
  wire                wready_bif;
  wire [63:0]         wdata_bif;
  wire [7:0]          wstrb_bif;
  wire                wlast_bif;
  // B Channel: Connections between B lookup block and boundary
  wire [1:0]          bid_bif;
  wire [1:0]          bresp_bif;
  wire                bvalid_bif;
  wire                bready_bif;

  // R Channel: Connections between read channel block and boundary
  wire [1:0]          rid_bif;
  wire [1:0]          rresp_bif;
  wire [63:0]         rdata_bif;
  wire                rlast_bif;
  wire                rvalid_bif;
  wire                rready_bif;


  // AXI_fmt
  // AR Channel
  wire                arvalid_fmt;
  wire [2:0]          arvalid_vect_fmt;
  wire [31:0]         araddr_fmt;
  wire [7:0]          arlen_fmt;
  wire [2:0]          arsize_fmt;
  wire [1:0]          arburst_fmt;
  wire           arlock_fmt;
  wire [3:0]          arcache_fmt;
  wire [2:0]          arprot_fmt;
  wire [1:0]          arid_fmt;
  wire                arready_fmt;
  // AW Channel
  wire                awvalid_fmt;
  wire [2:0]          awvalid_vect_fmt;
  wire [31:0]         awaddr_fmt;
  wire [7:0]          awlen_fmt;
  wire [2:0]          awsize_fmt;
  wire [1:0]          awburst_fmt;
  wire           awlock_fmt;
  wire [3:0]          awcache_fmt;
  wire [2:0]          awprot_fmt;
  wire [1:0]          awid_fmt;
  wire                awready_fmt;

  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------



  assign aw_fmt_src_data = {
          awid_axi4_s,
          awaddr_axi4_s[31:0],
          awlen_axi4_s,
          awsize_axi4_s,
          awburst_axi4_s,
          awlock_axi4_s,
          awcache_axi4_s,
          awprot_axi4_s,
          awvalid_vect_axi4_s};


  assign awvalid_fmt  = awvalid_axi4_s;
  assign awready_axi4_s = awready_fmt;
  assign aw_fmt_dst_data  = aw_fmt_src_data;


  // expand the concatenated registered values to the master port outputs
  assign {
          awid_fmt,
          awaddr_fmt[31:0],
          awlen_fmt,
          awsize_fmt,
          awburst_fmt,
          awlock_fmt,
          awcache_fmt,
          awprot_fmt,
          awvalid_vect_fmt} = aw_fmt_dst_data;

  //------------------------------------------------------------------------------
  // AW Format Block - Formats the AW Channel and send info to the AWFIFO and
  //                  B Channels 
  //------------------------------------------------------------------------------
  nic400_ib_sSpi_ib_upsize_wr_addr_fmt_1 u_axi_write_address_format
  (
    // global interconnect signals
    .aresetn                          (aresetn),
    .aclk                             (aclk),

    

    //Signals to/from the Bchannel
    .bdata_data                       (bdata_data),
    .bdata_valid                      (bdata_valid),
    .bdata_ready                      (bdata_ready),

    //Signals to the Write Control Block
    .awfmt_valid                      (awdata_valid),
    .awfmt_ready                      (awdata_ready),
    .awfmt_data                       (awdata_data),

    // Slave Port Write Address Channel
    .awid_s                           (awid_fmt),
    .awaddr_s                         (awaddr_fmt),
    .awlen_s                          (awlen_fmt),
    .awsize_s                         (awsize_fmt),
    .awburst_s                        (awburst_fmt),
    .awvalid_s                        (awvalid_fmt),
    .awready_s                        (awready_fmt),
    .awprot_s                         (awprot_fmt),
    .awcache_s                        (awcache_fmt),
    .awlock_s                         (awlock_fmt),

    // Master Port Write Address Channel
    .awid_m                           (awid_bif),
    .awaddr_m                         (awaddr_bif),
    .awlen_m                          (awlen_bif),
    .awsize_m                         (awsize_bif),
    .awburst_m                        (awburst_bif),
    .awvalid_m                        (awvalid_bif),
    .awready_m                        (awready_bif),
    .awprot_m                         (awprot_bif),
    .awlock_m                         (awlock_bif),
    .awcache_m                        (awcache_bif)
  );
  
  
  assign awvalid_vect_bif = awvalid_vect_fmt;

  //------------------------------------------------------------------------------
  // Write Control - Controls the merge buffer and pushes to the wfifo/W Channel
  //------------------------------------------------------------------------------

nic400_ib_sSpi_ib_upsize_wr_cntrl_1 u_upsize_axi_write_control
  (
    // global interconnect signals
    .aresetn                          (aresetn),
    .aclk                             (aclk),

    //Signals to/from the AW format block
    .awfifo_valid                     (awdata_valid),
    .awfifo_ready                     (awdata_ready),
    .awfifo_data                      (awdata_data),

    // Slave Port Write  Channel
    .wvalid_s                         (wvalid_axi4_s),
    .wready_s                         (wready_axi4_s),
    .wlast                            (wlast_axi4_s),

    // Merge buffer Contol signals
    .merge                            (merge),
    .merge_clear                      (merge_clear),
    .data_select                      (data_select),
    .strb_skid_valid                  (strb_skid_valid),

    //Data from merge buffer
    .wdata_merged                     (wdata_merged),
    .wstrb_merged                     (wstrb_merged),

    // Master Port Write  Channel
    .wvalid_m                         (wvalid_bif),
    .wready_m                         (wready_bif),
    .wlast_m                          (wlast_bif),
    .wdata_m                          (wdata_bif),
    .wstrb_m                          (wstrb_bif)
  );


  //------------------------------------------------------------------------------
  // Merge Buffer - Merges data on the Slave W Channel and passes it to the WFIFO
  // Excess   false
  // Scale    2
  // SDW-byte 4
  // Sum      9
  //------------------------------------------------------------------------------

  nic400_ib_sSpi_ib_upsize_wr_merge_buffer_1 u_upsize_axi_write_merge_buffer
  (
    // global interconnect signals
    .aresetn                          (aresetn),
    .aclk                             (aclk),

    // outputs
    .wdata_out                        (wdata_merged),
    .wstrb_out                        (wstrb_merged),

    //Inputs
    .wdata_in                         (wdata_axi4_s),
    .wstrb_in                         (wstrb_axi4_s),

    //Control Signals
    .data_select                      (data_select),
    .merge_skid_valid                 (strb_skid_valid),
    .merge                            (merge),
    .merge_clear                      (merge_clear)
  );



//------------------------------------------------------------------------------
// B Channel Block - Monitors B Channel and removes
//------------------------------------------------------------------------------
  nic400_ib_sSpi_ib_upsize_wr_resp_block_1 u_upsize_axi_write_response_block
  (

  //System Inputs
  .aclk                               (aclk),
  .aresetn                            (aresetn),

  //Signals from write Address format Block
  .bchannel_ready                     (bdata_ready),
  .bchannel_valid                     (bdata_valid),
  .bchannel_data                      (bdata_data),

  //Slave B channel Signals
  .bready_s                           (bready_axi4_s),
  .bvalid_s                           (bvalid_axi4_s),
  .bid_s                              (bid_axi4_s),
  .bresp_s                            (bresp_axi4_s),

  //Master B channel Signals
  .bresp_m                            (bresp_bif),
  .bid_m                              (bid_bif),
  .bvalid_m                           (bvalid_bif),
  .bready_m                           (bready_bif)

  );


  // the inputs are concatenated to interface to the generic register set
  assign ar_fmt_src_data = {
          arid_axi4_s,
          araddr_axi4_s[31:0],
          arlen_axi4_s,
          arsize_axi4_s,
          arburst_axi4_s,
          arlock_axi4_s,
          arcache_axi4_s,
          arprot_axi4_s,
          arvalid_vect_axi4_s};



  assign arvalid_fmt  = arvalid_axi4_s;
  assign arready_axi4_s = arready_fmt;
  assign ar_fmt_dst_data  = ar_fmt_src_data;


  // expand the concatenated registered values to the master port outputs
  assign {
          arid_fmt,
          araddr_fmt[31:0],
          arlen_fmt,
          arsize_fmt,
          arburst_fmt,
          arlock_fmt,
          arcache_fmt,
          arprot_fmt,
          arvalid_vect_fmt} = ar_fmt_dst_data;


  //------------------------------------------------------------------------------
  //  Read Address channel coding
  //------------------------------------------------------------------------------

  nic400_ib_sSpi_ib_upsize_rd_addr_fmt_1 u_axi_read_address_format
  (
    // global interconnect signals
    .aresetn                          (aresetn),
    .aclk                             (aclk),

    //Signals to the ARfifo
    .ardata_valid                     (arfifo_valid),
    .ardata_ready                     (arfifo_ready),
    .ardata_data                      (arfifo_data),

    // Slave Port Write Address Channel
    .arid_s                           (arid_fmt),
    .araddr_s                         (araddr_fmt),
    .arlen_s                          (arlen_fmt),
    .arsize_s                         (arsize_fmt),
    .arburst_s                        (arburst_fmt),
    .arvalid_s                        (arvalid_fmt),
    .arready_s                        (arready_fmt),
    .arprot_s                         (arprot_fmt),
    .arcache_s                        (arcache_fmt),
    .arlock_s                         (arlock_fmt),

    // Master Port Write Address Channel
    .arid_m                           (arid_bif),
    .araddr_m                         (araddr_bif),
    .arlen_m                          (arlen_bif),
    .arsize_m                         (arsize_bif),
    .arburst_m                        (arburst_bif),
    .arvalid_m                        (arvalid_bif),
    .arready_m                        (arready_bif),
    .arprot_m                         (arprot_bif),
    .arlock_m                         (arlock_bif),
    .arcache_m                        (arcache_bif)
  );

  assign arvalid_vect_bif = arvalid_vect_fmt;

  //------------------------------------------------------------------------------
  //  Read Channel - Demuxes the appropriate data onto the Slave READ bus
  //------------------------------------------------------------------------------

  nic400_ib_sSpi_ib_upsize_rd_chan_1 u_upsize_axi_read_channel
  (

  // global interconnect signals
  .aresetn                           (aresetn),
  .aclk                              (aclk),

  //Signals from the AR Format Block
  .archannel_data                    (arfifo_data),
  .archannel_valid                   (arfifo_valid),
  .archannel_ready                   (arfifo_ready),

  //RChannel Slave Side Outputs
  .rvalid_s                          (rvalid_axi4_s),
  .rdata_s                           (rdata_axi4_s),
  .rlast_s                           (rlast_axi4_s),
  .rid_s                             (rid_axi4_s),
  .rresp_s                           (rresp_axi4_s),

  //RChannel Slave Side Inputs
  .rready_s                          (rready_axi4_s),

  //RChannel Boundary Side Inputs
  .rvalid_m                          (rvalid_bif),
  .rdata_m                           (rdata_bif),
  .rlast_m                           (rlast_bif),
  .rid_m                             (rid_bif),
  .rresp_m                           (rresp_bif),
  //RChannel Boundary Side Outputs
  .rready_m                          (rready_bif)

  );



  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // AW Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign aw_data = {
          awid_bif,
          awaddr_bif,
          awlen_bif,
          awsize_bif,
          awburst_bif,
          awlock_bif,
          awcache_bif,
          awprot_bif,
          awvalid_vect_bif};


  assign aw_valid = awvalid_bif;

  assign awready_bif = aw_ready;

  // ---------------------------------------------------------------------------
  // AR Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign ar_data = {
          arid_bif,
          araddr_bif,
          arlen_bif,
          arsize_bif,
          arburst_bif,
          arlock_bif,
          arcache_bif,
          arprot_bif,
          arvalid_vect_bif};


  assign ar_valid = arvalid_bif;

  assign arready_bif = ar_ready;

  // ---------------------------------------------------------------------------
  // W Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // the inputs are concatenated to interface to the generic register set
  assign w_data = {
          wdata_bif,
          wstrb_bif,
          wlast_bif};


  assign w_valid = wvalid_bif;

  assign wready_bif = w_ready;


  // ---------------------------------------------------------------------------
  // R Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // expand the concatenated registered values to the master port outputs
  assign {
          rid_bif,
          rdata_bif,
          rresp_bif,
          rlast_bif} = r_data;

  assign r_ready = rready_bif;
  assign rvalid_bif = r_valid;




  // ---------------------------------------------------------------------------
  // B Channel timing block wiring at boundary
  // ---------------------------------------------------------------------------

  // expand the concatenated registered values to the master port outputs
  assign {
          bid_bif,
          bresp_bif} = b_data;

  assign b_ready = bready_bif;
  assign bvalid_bif = b_valid;



  // AW channel is set to wires at boundary.
    
  // AR channel is set to wires at boundary.
    
  // R channel is set to wires at boundary.
    
  // W channel is set to wires at boundary.
    
  // B channel is set to wires at boundary.
    

  // ---------------------------------------------------------------------------

endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"



// --================================= End ===================================--
