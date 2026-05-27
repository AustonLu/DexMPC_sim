//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 129373
//
//  Date                :  2012-05-02 08:41:35 +0100 (Wed, 02 May 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : Structural file to implement a single
//                        build layers module of a multi layer 
//                        AXI bus matrix 
//   
//  Key Configuration Details-
//      - Master Interface number : 2
//      - Connected to 3 slave interfaces
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterInterface (connect to external AXI slave)
//     *_s0 suffix to denote the SlaveInterface  (connect to external AXI master) 
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_ml_mlayer_2_1
  (
    // MasterInterface 
    // Write Address Channel
    awid_m,
    awaddr_m,
    awlen_m,
    awsize_m,
    awburst_m,
    awlock_m,
    awcache_m,
    awprot_m,
    awvalid_m,
    awvalid_vect_m,
    awready_m,
    aw_qv_m,
   
    // Write Channel
    wdata_m,
    wstrb_m,
    wlast_m,
    wvalid_m,
    wready_m,

    // Write Response Channel
    bid_m,
    bresp_m,
    bvalid_m,
    bready_m,

    // Read Address Channel
    arid_m,
    araddr_m,
    arlen_m,
    arsize_m,
    arburst_m,
    arlock_m,
    arcache_m,
    arprot_m,
    arvalid_m,
    arvalid_vect_m,
    arready_m,
    ar_qv_m,
   
    // Read Channel
    rid_m,
    rdata_m,
    rresp_m,
    rlast_m,
    rvalid_m,
    rready_m,

    // SlaveInterface 0
    // Write Address Channel
    awid_s0,
    awaddr_s0,
    awlen_s0,
    awsize_s0,
    awburst_s0,
    awlock_s0,
    awcache_s0,
    awprot_s0,
    awvalid_s0,
    awvalid_vect_s0,
    awready_s0,
    aw_qv_s0,
   
    // Write Channel
    wdata_s0,
    wstrb_s0,   
    wlast_s0,
    wvalid_s0,
    wready_s0,

    // Write Response Channel
    bid_s0,
    bresp_s0,
    bvalid_s0,
    bready_s0,  

    // Read Address Channel
    arid_s0,
    araddr_s0,
    arlen_s0,
    arsize_s0,
    arburst_s0,
    arlock_s0,
    arcache_s0,
    arprot_s0,
    arvalid_s0,
    arvalid_vect_s0,
    arready_s0,
    ar_qv_s0,
   
    // Read Channel
    rid_s0,
    rdata_s0,
    rresp_s0,
    rlast_s0,
    rvalid_s0,
    rready_s0,

    // SlaveInterface 1
    // Write Address Channel
    awid_s1,
    awaddr_s1,
    awlen_s1,
    awsize_s1,
    awburst_s1,
    awlock_s1,
    awcache_s1,
    awprot_s1,
    awvalid_s1,
    awvalid_vect_s1,
    awready_s1,
    aw_qv_s1,
   
    // Write Channel
    wdata_s1,
    wstrb_s1,   
    wlast_s1,
    wvalid_s1,
    wready_s1,

    // Write Response Channel
    bid_s1,
    bresp_s1,
    bvalid_s1,
    bready_s1,  

    // Read Address Channel
    arid_s1,
    araddr_s1,
    arlen_s1,
    arsize_s1,
    arburst_s1,
    arlock_s1,
    arcache_s1,
    arprot_s1,
    arvalid_s1,
    arvalid_vect_s1,
    arready_s1,
    ar_qv_s1,
   
    // Read Channel
    rid_s1,
    rdata_s1,
    rresp_s1,
    rlast_s1,
    rvalid_s1,
    rready_s1,

    // SlaveInterface 2
    // Write Address Channel
    awid_s2,
    awaddr_s2,
    awlen_s2,
    awsize_s2,
    awburst_s2,
    awlock_s2,
    awcache_s2,
    awprot_s2,
    awvalid_s2,
    awvalid_vect_s2,
    awready_s2,
    aw_qv_s2,
   
    // Write Channel
    wdata_s2,
    wstrb_s2,   
    wlast_s2,
    wvalid_s2,
    wready_s2,

    // Write Response Channel
    bid_s2,
    bresp_s2,
    bvalid_s2,
    bready_s2,  

    // Read Address Channel
    arid_s2,
    araddr_s2,
    arlen_s2,
    arsize_s2,
    arburst_s2,
    arlock_s2,
    arcache_s2,
    arprot_s2,
    arvalid_s2,
    arvalid_vect_s2,
    arready_s2,
    ar_qv_s2,
   
    // Read Channel
    rid_s2,
    rdata_s2,
    rresp_s2,
    rlast_s2,
    rvalid_s2,
    rready_s2,

    // Miscelaneous connections
    aclk,
    aresetn
  );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  // MasterInterface 

  // Write Address Channel
  output [7:0]      awid_m;
  output [31:0]     awaddr_m;
  output [7:0]      awlen_m;
  output [2:0]      awsize_m;
  output [1:0]      awburst_m;
  output            awlock_m;
  output [3:0]      awcache_m;
  output [2:0]      awprot_m;
  output            awvalid_m;
  output            awvalid_vect_m;
  input             awready_m;
  output [3:0]      aw_qv_m;
   
  // Write Channel
  output  [63:0]    wdata_m;
  output  [7:0]     wstrb_m;
  output            wlast_m;
  output            wvalid_m;
  input             wready_m;

  // Write Response Channel
  input [7:0]       bid_m;
  input [1:0]       bresp_m;
  input             bvalid_m;
  output            bready_m;

  // Read Address Channel
  output [7:0]      arid_m;
  output [31:0]     araddr_m;
  output [7:0]      arlen_m;
  output [2:0]      arsize_m;
  output [1:0]      arburst_m;
  output            arlock_m;
  output [3:0]      arcache_m;
  output [2:0]      arprot_m;
  output            arvalid_m;
  output            arvalid_vect_m;
  input             arready_m;
  output [3:0]      ar_qv_m;
   
  // Read Channel
  input [7:0]       rid_m;
  input [63:0]      rdata_m;
  input [1:0]       rresp_m;
  input             rlast_m;
  input             rvalid_m;
  output            rready_m;


  // SlaveInterface 0
  // Write Address Channel
  input  [7:0]      awid_s0;
  input  [31:0]     awaddr_s0;
  input  [7:0]      awlen_s0;
  input  [2:0]      awsize_s0;
  input  [1:0]      awburst_s0;
  input             awlock_s0;
  input  [3:0]      awcache_s0;
  input  [2:0]      awprot_s0;
  input             awvalid_s0;
  input             awvalid_vect_s0;
  output            awready_s0;
  input  [3:0]      aw_qv_s0;
   
    // Write Channel
  input  [63:0]     wdata_s0;
  input  [7:0]      wstrb_s0;   
  input             wlast_s0;
  input             wvalid_s0;
  output            wready_s0;

  // Write Response Channel
  output [7:0]      bid_s0;
  output [1:0]      bresp_s0;
  output            bvalid_s0;
  input             bready_s0;  

  // Read Address Channel
  input  [7:0]      arid_s0;
  input  [31:0]     araddr_s0;
  input  [7:0]      arlen_s0;
  input  [2:0]      arsize_s0;
  input  [1:0]      arburst_s0;
  input             arlock_s0;
  input  [3:0]      arcache_s0;
  input  [2:0]      arprot_s0;
  input             arvalid_s0;
  input             arvalid_vect_s0;
  output            arready_s0;
  input  [3:0]      ar_qv_s0;

  // Read Channel
  output  [7:0]     rid_s0;
  output  [63:0]    rdata_s0;
  output [1:0]      rresp_s0;
  output            rlast_s0;
  output            rvalid_s0;
  input             rready_s0;

  // SlaveInterface 1
  // Write Address Channel
  input  [7:0]      awid_s1;
  input  [31:0]     awaddr_s1;
  input  [7:0]      awlen_s1;
  input  [2:0]      awsize_s1;
  input  [1:0]      awburst_s1;
  input             awlock_s1;
  input  [3:0]      awcache_s1;
  input  [2:0]      awprot_s1;
  input             awvalid_s1;
  input             awvalid_vect_s1;
  output            awready_s1;
  input  [3:0]      aw_qv_s1;
   
    // Write Channel
  input  [63:0]     wdata_s1;
  input  [7:0]      wstrb_s1;   
  input             wlast_s1;
  input             wvalid_s1;
  output            wready_s1;

  // Write Response Channel
  output [7:0]      bid_s1;
  output [1:0]      bresp_s1;
  output            bvalid_s1;
  input             bready_s1;  

  // Read Address Channel
  input  [7:0]      arid_s1;
  input  [31:0]     araddr_s1;
  input  [7:0]      arlen_s1;
  input  [2:0]      arsize_s1;
  input  [1:0]      arburst_s1;
  input             arlock_s1;
  input  [3:0]      arcache_s1;
  input  [2:0]      arprot_s1;
  input             arvalid_s1;
  input             arvalid_vect_s1;
  output            arready_s1;
  input  [3:0]      ar_qv_s1;

  // Read Channel
  output  [7:0]     rid_s1;
  output  [63:0]    rdata_s1;
  output [1:0]      rresp_s1;
  output            rlast_s1;
  output            rvalid_s1;
  input             rready_s1;

  // SlaveInterface 2
  // Write Address Channel
  input  [7:0]      awid_s2;
  input  [31:0]     awaddr_s2;
  input  [7:0]      awlen_s2;
  input  [2:0]      awsize_s2;
  input  [1:0]      awburst_s2;
  input             awlock_s2;
  input  [3:0]      awcache_s2;
  input  [2:0]      awprot_s2;
  input             awvalid_s2;
  input             awvalid_vect_s2;
  output            awready_s2;
  input  [3:0]      aw_qv_s2;
   
    // Write Channel
  input  [63:0]     wdata_s2;
  input  [7:0]      wstrb_s2;   
  input             wlast_s2;
  input             wvalid_s2;
  output            wready_s2;

  // Write Response Channel
  output [7:0]      bid_s2;
  output [1:0]      bresp_s2;
  output            bvalid_s2;
  input             bready_s2;  

  // Read Address Channel
  input  [7:0]      arid_s2;
  input  [31:0]     araddr_s2;
  input  [7:0]      arlen_s2;
  input  [2:0]      arsize_s2;
  input  [1:0]      arburst_s2;
  input             arlock_s2;
  input  [3:0]      arcache_s2;
  input  [2:0]      arprot_s2;
  input             arvalid_s2;
  input             arvalid_vect_s2;
  output            arready_s2;
  input  [3:0]      ar_qv_s2;

  // Read Channel
  output  [7:0]     rid_s2;
  output  [63:0]    rdata_s2;
  output [1:0]      rresp_s2;
  output            rlast_s2;
  output            rvalid_s2;
  input             rready_s2;

  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------

  wire   [2:0]      aw_sel;
  // bchannel mask 
  wire              wr_cnt_empty;

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  //----------------------- Address channel selection -------------------------

nic400_bm0_add_sel_ml2_1 u_nic400_bm0_add_sel_ml2_1 (
        // AW MasterInterface 
        .awid_m         (awid_m),
        .awaddr_m       (awaddr_m),
        .awlen_m        (awlen_m),
        .awsize_m       (awsize_m),
        .awburst_m      (awburst_m),
        .awlock_m       (awlock_m),
        .awcache_m      (awcache_m),
        .awprot_m       (awprot_m),
        .awvalid_m      (awvalid_m),
        .awvalid_vect_m (awvalid_vect_m),
        .awready_m      (awready_m),
        .aw_qv_m        (aw_qv_m),
        
        // AR MasterInterface 
        .arid_m         (arid_m),
        .araddr_m       (araddr_m),
        .arlen_m        (arlen_m),
        .arsize_m       (arsize_m),
        .arburst_m      (arburst_m),
        .arlock_m       (arlock_m),
        .arcache_m      (arcache_m),
        .arprot_m       (arprot_m),
        .arvalid_m      (arvalid_m),
        .arvalid_vect_m (arvalid_vect_m),
        .arready_m      (arready_m),
        .ar_qv_m        (ar_qv_m),
        // Current Selected write channel
        .aw_sel         (aw_sel),
        // Master Interface write channel handshake signals
        .wvalid_m       (wvalid_m),
        .wready_m       (wready_m),
        .wlast_m        (wlast_m),
        // Master Interface return channel handshake signals
        .bvalid_m       (bvalid_m),
        .bready_m       (bready_m),
        .rvalid_m       (rvalid_m),
        .rready_m       (rready_m),
        .rlast_m        (rlast_m),
        // SlaveInterface 0
        // Write Address Channel
        .awid_s0         (awid_s0),
        .awaddr_s0       (awaddr_s0),
        .awlen_s0        (awlen_s0),
        .awsize_s0       (awsize_s0),
        .awburst_s0      (awburst_s0),
        .awlock_s0       (awlock_s0),
        .awcache_s0      (awcache_s0),
        .awprot_s0       (awprot_s0),
        .awvalid_s0      (awvalid_s0),
        .awvalid_vect_s0 (awvalid_vect_s0),
        .awready_s0      (awready_s0),
        .aw_qv_s0        (aw_qv_s0),
        // Read Address Channel
        .arid_s0         (arid_s0),
        .araddr_s0       (araddr_s0),
        .arlen_s0        (arlen_s0),
        .arsize_s0       (arsize_s0),
        .arburst_s0      (arburst_s0),
        .arlock_s0       (arlock_s0),
        .arcache_s0      (arcache_s0),
        .arprot_s0       (arprot_s0),
        .arvalid_s0      (arvalid_s0),
        .arvalid_vect_s0 (arvalid_vect_s0),
        .arready_s0      (arready_s0),
        .ar_qv_s0        (ar_qv_s0),

        // SlaveInterface 1
        // Write Address Channel
        .awid_s1         (awid_s1),
        .awaddr_s1       (awaddr_s1),
        .awlen_s1        (awlen_s1),
        .awsize_s1       (awsize_s1),
        .awburst_s1      (awburst_s1),
        .awlock_s1       (awlock_s1),
        .awcache_s1      (awcache_s1),
        .awprot_s1       (awprot_s1),
        .awvalid_s1      (awvalid_s1),
        .awvalid_vect_s1 (awvalid_vect_s1),
        .awready_s1      (awready_s1),
        .aw_qv_s1        (aw_qv_s1),
        // Read Address Channel
        .arid_s1         (arid_s1),
        .araddr_s1       (araddr_s1),
        .arlen_s1        (arlen_s1),
        .arsize_s1       (arsize_s1),
        .arburst_s1      (arburst_s1),
        .arlock_s1       (arlock_s1),
        .arcache_s1      (arcache_s1),
        .arprot_s1       (arprot_s1),
        .arvalid_s1      (arvalid_s1),
        .arvalid_vect_s1 (arvalid_vect_s1),
        .arready_s1      (arready_s1),
        .ar_qv_s1        (ar_qv_s1),

        // SlaveInterface 2
        // Write Address Channel
        .awid_s2         (awid_s2),
        .awaddr_s2       (awaddr_s2),
        .awlen_s2        (awlen_s2),
        .awsize_s2       (awsize_s2),
        .awburst_s2      (awburst_s2),
        .awlock_s2       (awlock_s2),
        .awcache_s2      (awcache_s2),
        .awprot_s2       (awprot_s2),
        .awvalid_s2      (awvalid_s2),
        .awvalid_vect_s2 (awvalid_vect_s2),
        .awready_s2      (awready_s2),
        .aw_qv_s2        (aw_qv_s2),
        // Read Address Channel
        .arid_s2         (arid_s2),
        .araddr_s2       (araddr_s2),
        .arlen_s2        (arlen_s2),
        .arsize_s2       (arsize_s2),
        .arburst_s2      (arburst_s2),
        .arlock_s2       (arlock_s2),
        .arcache_s2      (arcache_s2),
        .arprot_s2       (arprot_s2),
        .arvalid_s2      (arvalid_s2),
        .arvalid_vect_s2 (arvalid_vect_s2),
        .arready_s2      (arready_s2),
        .ar_qv_s2        (ar_qv_s2),

        // bchannel mask 
        .wr_cnt_empty   (wr_cnt_empty),
        // Miscelaneous connections
        .aclk           (aclk),
        .aresetn        (aresetn)
);

  //------------------------ Write channel selection --------------------------
nic400_bm0_wr_sel_ml2_1 u_nic400_bm0_wr_sel_ml2_1 (
        // Slave Interface Write Channels
        .wdata_s0     (wdata_s0),
        .wstrb_s0     (wstrb_s0),
        .wlast_s0     (wlast_s0),
        .wvalid_s0    (wvalid_s0),
        .wready_s0    (wready_s0),

        .wdata_s1     (wdata_s1),
        .wstrb_s1     (wstrb_s1),
        .wlast_s1     (wlast_s1),
        .wvalid_s1    (wvalid_s1),
        .wready_s1    (wready_s1),

        .wdata_s2     (wdata_s2),
        .wstrb_s2     (wstrb_s2),
        .wlast_s2     (wlast_s2),
        .wvalid_s2    (wvalid_s2),
        .wready_s2    (wready_s2),

        // Accepted Selected write channel
        .aw_sel       (aw_sel),
        .awready_m    (awready_m),
        // Miscelaneous connections
        .aclk         (aclk),
        .aresetn      (aresetn),
        // Master Interface Write Channel
        .wdata_m      (wdata_m),
        .wstrb_m      (wstrb_m),
        .wlast_m      (wlast_m),
        .wvalid_m     (wvalid_m),
        .wready_m     (wready_m)
);


  //------------------------- Return channel control --------------------------

nic400_bm0_ret_sel_ml2_1 u_nic400_bm0_ret_sel_ml2_1 (
        // bchannel mask 
        .wr_cnt_empty (wr_cnt_empty),
        // Slave Interface Return Channels
        // Write Response Channel 0
        .bid_s0       (bid_s0),
        .bresp_s0     (bresp_s0),
        .bvalid_s0    (bvalid_s0),
        .bready_s0    (bready_s0),
        // Read Channel 0
        .rid_s0       (rid_s0),
        .rdata_s0     (rdata_s0),
        .rresp_s0     (rresp_s0),
        .rlast_s0     (rlast_s0),
        .rvalid_s0    (rvalid_s0),
        .rready_s0    (rready_s0),
        // Write Response Channel 1
        .bid_s1       (bid_s1),
        .bresp_s1     (bresp_s1),
        .bvalid_s1    (bvalid_s1),
        .bready_s1    (bready_s1),
        // Read Channel 1
        .rid_s1       (rid_s1),
        .rdata_s1     (rdata_s1),
        .rresp_s1     (rresp_s1),
        .rlast_s1     (rlast_s1),
        .rvalid_s1    (rvalid_s1),
        .rready_s1    (rready_s1),
        // Write Response Channel 2
        .bid_s2       (bid_s2),
        .bresp_s2     (bresp_s2),
        .bvalid_s2    (bvalid_s2),
        .bready_s2    (bready_s2),
        // Read Channel 2
        .rid_s2       (rid_s2),
        .rdata_s2     (rdata_s2),
        .rresp_s2     (rresp_s2),
        .rlast_s2     (rlast_s2),
        .rvalid_s2    (rvalid_s2),
        .rready_s2    (rready_s2),
        // Master Interface Write Response Channel
        .bid_m        (bid_m),
        .bresp_m      (bresp_m),
        .bvalid_m     (bvalid_m),
        .bready_m     (bready_m),
        // Master Interface Read Channel
        .rid_m        (rid_m),
        .rdata_m      (rdata_m),
        .rresp_m      (rresp_m),
        .rlast_m      (rlast_m),
        .rvalid_m     (rvalid_m),
        .rready_m     (rready_m)
);


  //------------------------------------------------------------------------------
  // OVL Assertions
  //------------------------------------------------------------------------------
  // synopsys translate_off
 
    `ifdef ARM_ASSERT_ON

 wire [2:0] rsel;
 wire [2:0] bsel;
 assign rsel = u_nic400_bm0_ret_sel_ml2_1.rsel;
 assign bsel = u_nic400_bm0_ret_sel_ml2_1.rsel;

      assert_zero_one_hot #(0,3,0,"ERROR, More than one read response destination")
         ovl_rsel_en2
           (
            .clk       (aclk),
            .reset_n   (aresetn),
            .test_expr (rsel)
            );
      assert_zero_one_hot #(0,3,0,"ERROR, More than one buffered response destination")
         ovl_bsel_en2
           (
            .clk       (aclk),
            .reset_n   (aresetn),
            .test_expr (bsel)
            );


    `endif
  // synopsys translate_on

  endmodule

//  --=============================== End ====================================--

