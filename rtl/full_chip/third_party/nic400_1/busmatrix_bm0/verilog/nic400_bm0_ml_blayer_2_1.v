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
//
//  File Revision       : 132916
//
//  Date                :  2012-07-02 13:38:10 +0100 (Mon, 02 Jul 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : Structural file to implement a single
//                        build layers module of a multi layer 
//                        AXI bus matrix 
//   
//  Key Configuration Details-
//      - Slave Interface number : 2
//      - Connected to 3 master interfaces
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterIf (connect to external AXI slave)
//     *_s0 suffix to denote the SlaveIf  (connect to external AXI master) 
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_ml_blayer_2_1
  (
    // SlaveInterface Port

    // Write Address Channel
    awid_s,
    awaddr_s,
    awlen_s,
    awsize_s,
    awburst_s,
    awlock_s,
    awcache_s,
    awprot_s,
    awvalid_s,
    awvalid_vect_s,
    awready_s,
    aw_qv_s,
   
    // Write Channel
    wdata_s,
    wstrb_s,
    wlast_s,
    wvalid_s,
    wready_s,

    // Write Response Channel
    bid_s,
    bresp_s,
    bvalid_s,
    bready_s,

    // Read Address Channel
    arid_s,
    araddr_s,
    arlen_s,
    arsize_s,
    arburst_s,
    arlock_s,
    arcache_s,
    arprot_s,
    arvalid_s,
    arvalid_vect_s,
    arready_s,
    ar_qv_s,
   
    // Read Channel
    rid_s,
    rdata_s,
    rresp_s,
    rlast_s,
    rvalid_s,
    rready_s,


    // Master Interface 0 Port

    // Write Address Channel
    awid_m0,
    awaddr_m0,
    awlen_m0,
    awsize_m0,
    awburst_m0,
    awlock_m0,
    awcache_m0,
    awprot_m0,
    awvalid_m0,
    awvalid_vect_m0,
    awready_m0,
    aw_qv_m0,
   
    // Write Channel
    wdata_m0,
    wstrb_m0,
    wlast_m0,
    wvalid_m0,
    wready_m0,

    // Write Response Channel
    bid_m0,
    bresp_m0,
    bvalid_m0,
    bready_m0,

    // Read Address Channel
    arid_m0,
    araddr_m0,
    arlen_m0,
    arsize_m0,
    arburst_m0,
    arlock_m0,
    arcache_m0,
    arprot_m0,
    arvalid_m0,
    arvalid_vect_m0,
    arready_m0,
    ar_qv_m0,
   
    // Read Channel
    rid_m0,
    rdata_m0,
    rresp_m0,
    rlast_m0,
    rvalid_m0,
    rready_m0,
    // Master Interface 1 Port

    // Write Address Channel
    awid_m1,
    awaddr_m1,
    awlen_m1,
    awsize_m1,
    awburst_m1,
    awlock_m1,
    awcache_m1,
    awprot_m1,
    awvalid_m1,
    awvalid_vect_m1,
    awready_m1,
    aw_qv_m1,
   
    // Write Channel
    wdata_m1,
    wstrb_m1,
    wlast_m1,
    wvalid_m1,
    wready_m1,

    // Write Response Channel
    bid_m1,
    bresp_m1,
    bvalid_m1,
    bready_m1,

    // Read Address Channel
    arid_m1,
    araddr_m1,
    arlen_m1,
    arsize_m1,
    arburst_m1,
    arlock_m1,
    arcache_m1,
    arprot_m1,
    arvalid_m1,
    arvalid_vect_m1,
    arready_m1,
    ar_qv_m1,
   
    // Read Channel
    rid_m1,
    rdata_m1,
    rresp_m1,
    rlast_m1,
    rvalid_m1,
    rready_m1,
    // Master Interface 2 Port

    // Write Address Channel
    awid_m2,
    awaddr_m2,
    awlen_m2,
    awsize_m2,
    awburst_m2,
    awlock_m2,
    awcache_m2,
    awprot_m2,
    awvalid_m2,
    awvalid_vect_m2,
    awready_m2,
    aw_qv_m2,
   
    // Write Channel
    wdata_m2,
    wstrb_m2,
    wlast_m2,
    wvalid_m2,
    wready_m2,

    // Write Response Channel
    bid_m2,
    bresp_m2,
    bvalid_m2,
    bready_m2,

    // Read Address Channel
    arid_m2,
    araddr_m2,
    arlen_m2,
    arsize_m2,
    arburst_m2,
    arlock_m2,
    arcache_m2,
    arprot_m2,
    arvalid_m2,
    arvalid_vect_m2,
    arready_m2,
    ar_qv_m2,
   
    // Read Channel
    rid_m2,
    rdata_m2,
    rresp_m2,
    rlast_m2,
    rvalid_m2,
    rready_m2,
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

  // SlaveInterface Port
  // Write Address Channel
  input [7:0]       awid_s;
  input [31:0]      awaddr_s;
  input [7:0]       awlen_s;
  input [2:0]       awsize_s;
  input [1:0]       awburst_s;
  input             awlock_s;
  input [3:0]       awcache_s;
  input [2:0]       awprot_s;
  input             awvalid_s;
  input [2:0]            awvalid_vect_s;
  output            awready_s;
  input [3:0]       aw_qv_s;

  // Write Channel
  input  [63:0]     wdata_s;
  input  [7:0]      wstrb_s;
  input             wlast_s;
  input             wvalid_s;
  output            wready_s;

  // Write Response Channel
  output [7:0]      bid_s;
  output [1:0]      bresp_s;
  output            bvalid_s;
  input             bready_s;

  // Read Address Channel
  input [7:0]       arid_s;
  input [31:0]      araddr_s;
  input [7:0]       arlen_s;
  input [2:0]       arsize_s;
  input [1:0]       arburst_s;
  input             arlock_s;
  input [3:0]       arcache_s;
  input [2:0]       arprot_s;
  input             arvalid_s;
  input [2:0]            arvalid_vect_s;
  output            arready_s;
  input [3:0]       ar_qv_s;

  // Read Channel
  output [7:0]      rid_s;
  output [63:0]     rdata_s;
  output [1:0]      rresp_s;
  output            rlast_s;
  output            rvalid_s;
  input             rready_s;

  // Master Interface 0 Port

  // Write Address Channel
  output [7:0]      awid_m0;
  output [31:0]     awaddr_m0;
  output [7:0]      awlen_m0;
  output [2:0]      awsize_m0;
  output [1:0]      awburst_m0;
  output            awlock_m0;
  output [3:0]      awcache_m0;
  output [2:0]      awprot_m0;
  output            awvalid_m0;
  output           awvalid_vect_m0;
  input             awready_m0;
  output [3:0]      aw_qv_m0;
   
  // Write Channel
  output  [63:0]    wdata_m0;
  output  [7:0]     wstrb_m0;
  output            wlast_m0;
  output            wvalid_m0;
  input             wready_m0;

  // Write Response Channel
  input [7:0]       bid_m0;
  input [1:0]       bresp_m0;
  input             bvalid_m0;
  output            bready_m0;

  // Read Address Channel
  output  [7:0]     arid_m0;
  output  [31:0]    araddr_m0;
  output  [7:0]     arlen_m0;
  output  [2:0]     arsize_m0;
  output  [1:0]     arburst_m0;
  output            arlock_m0;
  output  [3:0]     arcache_m0;
  output  [2:0]     arprot_m0;
  output            arvalid_m0;
  output            arvalid_vect_m0;
  input             arready_m0;
  output  [3:0]     ar_qv_m0;
   
  // Read Channel
  input [7:0]       rid_m0;
  input [63:0]      rdata_m0;
  input [1:0]       rresp_m0;
  input             rlast_m0;
  input             rvalid_m0;
  output            rready_m0;

  // Master Interface 1 Port

  // Write Address Channel
  output [7:0]      awid_m1;
  output [31:0]     awaddr_m1;
  output [7:0]      awlen_m1;
  output [2:0]      awsize_m1;
  output [1:0]      awburst_m1;
  output            awlock_m1;
  output [3:0]      awcache_m1;
  output [2:0]      awprot_m1;
  output            awvalid_m1;
  output           awvalid_vect_m1;
  input             awready_m1;
  output [3:0]      aw_qv_m1;
   
  // Write Channel
  output  [63:0]    wdata_m1;
  output  [7:0]     wstrb_m1;
  output            wlast_m1;
  output            wvalid_m1;
  input             wready_m1;

  // Write Response Channel
  input [7:0]       bid_m1;
  input [1:0]       bresp_m1;
  input             bvalid_m1;
  output            bready_m1;

  // Read Address Channel
  output  [7:0]     arid_m1;
  output  [31:0]    araddr_m1;
  output  [7:0]     arlen_m1;
  output  [2:0]     arsize_m1;
  output  [1:0]     arburst_m1;
  output            arlock_m1;
  output  [3:0]     arcache_m1;
  output  [2:0]     arprot_m1;
  output            arvalid_m1;
  output            arvalid_vect_m1;
  input             arready_m1;
  output  [3:0]     ar_qv_m1;
   
  // Read Channel
  input [7:0]       rid_m1;
  input [63:0]      rdata_m1;
  input [1:0]       rresp_m1;
  input             rlast_m1;
  input             rvalid_m1;
  output            rready_m1;

  // Master Interface 2 Port

  // Write Address Channel
  output [7:0]      awid_m2;
  output [31:0]     awaddr_m2;
  output [7:0]      awlen_m2;
  output [2:0]      awsize_m2;
  output [1:0]      awburst_m2;
  output            awlock_m2;
  output [3:0]      awcache_m2;
  output [2:0]      awprot_m2;
  output            awvalid_m2;
  output           awvalid_vect_m2;
  input             awready_m2;
  output [3:0]      aw_qv_m2;
   
  // Write Channel
  output  [63:0]    wdata_m2;
  output  [7:0]     wstrb_m2;
  output            wlast_m2;
  output            wvalid_m2;
  input             wready_m2;

  // Write Response Channel
  input [7:0]       bid_m2;
  input [1:0]       bresp_m2;
  input             bvalid_m2;
  output            bready_m2;

  // Read Address Channel
  output  [7:0]     arid_m2;
  output  [31:0]    araddr_m2;
  output  [7:0]     arlen_m2;
  output  [2:0]     arsize_m2;
  output  [1:0]     arburst_m2;
  output            arlock_m2;
  output  [3:0]     arcache_m2;
  output  [2:0]     arprot_m2;
  output            arvalid_m2;
  output            arvalid_vect_m2;
  input             arready_m2;
  output  [3:0]     ar_qv_m2;
   
  // Read Channel
  input [7:0]       rid_m2;
  input [63:0]      rdata_m2;
  input [1:0]       rresp_m2;
  input             rlast_m2;
  input             rvalid_m2;
  output            rready_m2;

  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //------------------------------------------------------------------------------
  // Wires 
  //------------------------------------------------------------------------------

  wire [2:0]           aw_enable;
  wire [2:0]           ar_enable;
  wire [2:0]           awready_s_int;
  wire [2:0]           wready_s_int;
  wire [2:0]           arready_s_int;
  wire [2:0]           awsel;
  wire [2:0]           arsel;
  wire [2:0]           tt_enable_wr;
  wire [2:0]           wr_enable;
  wire [2:0]           tt_enable_rd;
  wire [2:0]           bvalid_s_int;
  wire [23:0]           bid_s_int;
  wire [5:0]           bresp_s_int;
  wire [2:0]           rvalid_s_int;
  wire [2:0]           rlast_s_int;
  wire [23:0]           rid_s_int;
  wire [191:0]           rdata_s_int;
  wire [5:0]           rresp_s_int;


  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


  //------------------------- Address channel routing -------------------------
  // AW - wire aw slave interface ports to all master interface port outputs,
  // rip off only the required valid bits to each port
  assign awid_m0 = awid_s;
  assign awaddr_m0 = awaddr_s;
  assign awlen_m0 = awlen_s;
  assign awsize_m0 = awsize_s;
  assign awburst_m0 = awburst_s;
  assign awlock_m0 = awlock_s;
  assign awcache_m0 = awcache_s;
  assign awprot_m0 = awprot_s;
  assign aw_qv_m0 = aw_qv_s;
  assign awvalid_m0 = awvalid_s & aw_enable[0];
  assign awvalid_vect_m0 = awvalid_vect_s[0] & aw_enable[0]; 

  assign awid_m1 = awid_s;
  assign awaddr_m1 = awaddr_s;
  assign awlen_m1 = awlen_s;
  assign awsize_m1 = awsize_s;
  assign awburst_m1 = awburst_s;
  assign awlock_m1 = awlock_s;
  assign awcache_m1 = awcache_s;
  assign awprot_m1 = awprot_s;
  assign aw_qv_m1 = aw_qv_s;
  assign awvalid_m1 = awvalid_s & aw_enable[1];
  assign awvalid_vect_m1 = awvalid_vect_s[1] & aw_enable[1]; 

  assign awid_m2 = awid_s;
  assign awaddr_m2 = awaddr_s;
  assign awlen_m2 = awlen_s;
  assign awsize_m2 = awsize_s;
  assign awburst_m2 = awburst_s;
  assign awlock_m2 = awlock_s;
  assign awcache_m2 = awcache_s;
  assign awprot_m2 = awprot_s;
  assign aw_qv_m2 = aw_qv_s;
  assign awvalid_m2 = awvalid_s & aw_enable[2];
  assign awvalid_vect_m2 = awvalid_vect_s[2] & aw_enable[2]; 

  assign awready_s_int[0] = awready_m0 & aw_enable[0];
  assign awready_s_int[1] = awready_m1 & aw_enable[1];
  assign awready_s_int[2] = awready_m2 & aw_enable[2]; 
  assign awready_s = |awready_s_int;


  // AR - wire ar slave interface ports to all master interface port outputs,
  // rip off only the required valid bits to each port
  assign arid_m0 = arid_s;
  assign araddr_m0 = araddr_s;
  assign arlen_m0 = arlen_s;
  assign arsize_m0 = arsize_s;
  assign arburst_m0 = arburst_s;
  assign arlock_m0 = arlock_s;
  assign arcache_m0 = arcache_s;
  assign arprot_m0 = arprot_s;
  assign ar_qv_m0 = ar_qv_s;
  assign arvalid_m0 = arvalid_s & ar_enable[0];
  assign arvalid_vect_m0 = arvalid_vect_s[0]  & ar_enable[0];

  assign arid_m1 = arid_s;
  assign araddr_m1 = araddr_s;
  assign arlen_m1 = arlen_s;
  assign arsize_m1 = arsize_s;
  assign arburst_m1 = arburst_s;
  assign arlock_m1 = arlock_s;
  assign arcache_m1 = arcache_s;
  assign arprot_m1 = arprot_s;
  assign ar_qv_m1 = ar_qv_s;
  assign arvalid_m1 = arvalid_s & ar_enable[1];
  assign arvalid_vect_m1 = arvalid_vect_s[1]  & ar_enable[1];

  assign arid_m2 = arid_s;
  assign araddr_m2 = araddr_s;
  assign arlen_m2 = arlen_s;
  assign arsize_m2 = arsize_s;
  assign arburst_m2 = arburst_s;
  assign arlock_m2 = arlock_s;
  assign arcache_m2 = arcache_s;
  assign arprot_m2 = arprot_s;
  assign ar_qv_m2 = ar_qv_s;
  assign arvalid_m2 = arvalid_s & ar_enable[2];
  assign arvalid_vect_m2 = arvalid_vect_s[2]  & ar_enable[2];

  assign arready_s_int[0] = arready_m0 & ar_enable[0];
  assign arready_s_int[1] = arready_m1 & ar_enable[1];
  assign arready_s_int[2] = arready_m2 & ar_enable[2]; 
  assign arready_s = |arready_s_int;


  // Create a vector of valids for each master interface selection for
  // the transaction tracker 
  assign awsel[0] = awvalid_s & awvalid_vect_s[0];
  assign arsel[0] = arvalid_s & arvalid_vect_s[0];
  assign awsel[1] = awvalid_s & awvalid_vect_s[1];
  assign arsel[1] = arvalid_s & arvalid_vect_s[1];
  assign awsel[2] = awvalid_s & awvalid_vect_s[2];
  assign arsel[2] = arvalid_s & arvalid_vect_s[2];

  //--------------- Instantiate the active transaction trackers ---------------
  // Writes
  nic400_bm0_wr_ss_tt_s2_1 u_nic400_bm0_wr_ss_tt_4_3m_1 (
        // Outputs
        .aw_enable    (aw_enable),
        .tt_enable    (tt_enable_wr),
        .wr_enable    (wr_enable),
        // Inputs
        .asel         (awsel),
        .aready       (awready_s),
        .wvalid       (wvalid_s),
        .wready       (wready_s),
        .wlast        (wlast_s),
        .resp_valid   (bvalid_s),
        .resp_ready   (bready_s),
        // Miscelaneous connections
        .aclk         (aclk),
        .aresetn      (aresetn)
  );

  // Reads
  nic400_bm0_rd_ss_tt_s2_1 u_nic400_bm0_rd_ss_tt_4_3m_1 (
        // Outputs
        .ar_enable    (ar_enable),
        .tt_enable    (tt_enable_rd),
        // Inputs

        .asel         (arsel),
        .aready       (arready_s),
        .resp_valid   (rvalid_s),
        .resp_last    (rlast_s),
        .resp_ready   (rready_s),

        // Miscelaneous connections
        .aclk         (aclk),
        .aresetn      (aresetn)
  );

  //-------------------------- Write channel routing --------------------------
  assign wdata_m0 = wdata_s;
  assign wstrb_m0 = wstrb_s;
  assign wlast_m0 = wlast_s;
  assign wvalid_m0 = wvalid_s & wr_enable[0];
  assign wready_s_int[0] = wready_m0 & wr_enable[0];

  assign wdata_m1 = wdata_s;
  assign wstrb_m1 = wstrb_s;
  assign wlast_m1 = wlast_s;
  assign wvalid_m1 = wvalid_s & wr_enable[1];
  assign wready_s_int[1] = wready_m1 & wr_enable[1];

  assign wdata_m2 = wdata_s;
  assign wstrb_m2 = wstrb_s;
  assign wlast_m2 = wlast_s;
  assign wvalid_m2 = wvalid_s & wr_enable[2];
  assign wready_s_int[2] = wready_m2 & wr_enable[2];
  
  assign wready_s = |wready_s_int;


  //------------- Instantiate the response channel arbitration modules---------

  // For single slave or no cyclic dependancy scheme configurations there is no
  // arbitration required for the return channels as only one master interface
  // can have outstanding transactions at any time.


  //--------------- Instantiate the response channel routing modules-----------
  // Writes
  assign bid_s_int[7:0] = bid_m0 & {8{tt_enable_wr[0]}};
  assign bresp_s_int[1:0] = bresp_m0 & {2{tt_enable_wr[0]}};
  assign bvalid_s_int[0] = bvalid_m0 & tt_enable_wr[0];
  assign bready_m0 = bready_s & tt_enable_wr[0];

  assign bid_s_int[15:8] = bid_m1 & {8{tt_enable_wr[1]}};
  assign bresp_s_int[3:2] = bresp_m1 & {2{tt_enable_wr[1]}};
  assign bvalid_s_int[1] = bvalid_m1 & tt_enable_wr[1];
  assign bready_m1 = bready_s & tt_enable_wr[1];

  assign bid_s_int[23:16] = bid_m2 & {8{tt_enable_wr[2]}};
  assign bresp_s_int[5:4] = bresp_m2 & {2{tt_enable_wr[2]}};
  assign bvalid_s_int[2] = bvalid_m2 & tt_enable_wr[2];
  assign bready_m2 = bready_s & tt_enable_wr[2];
  // Or the masked vectors to provide the mux outputs
  assign bvalid_s = |bvalid_s_int;
  assign bid_s = bid_s_int[7:0]
                 | bid_s_int[15:8]
                 | bid_s_int[23:16];
  assign bresp_s = bresp_s_int[1:0]
                 | bresp_s_int[3:2]
                 | bresp_s_int[5:4];

  // Reads
  assign rid_s_int[7:0] = rid_m0 & {8{tt_enable_rd[0]}};
  assign rdata_s_int[63:0] = rdata_m0 & {64{tt_enable_rd[0]}};
  assign rresp_s_int[1:0] = rresp_m0 & {2{tt_enable_rd[0]}};
  assign rlast_s_int[0] = rlast_m0 & tt_enable_rd[0];
  assign rvalid_s_int[0] = rvalid_m0 & tt_enable_rd[0];
  assign rready_m0 = rready_s & tt_enable_rd[0];

  assign rid_s_int[15:8] = rid_m1 & {8{tt_enable_rd[1]}};
  assign rdata_s_int[127:64] = rdata_m1 & {64{tt_enable_rd[1]}};
  assign rresp_s_int[3:2] = rresp_m1 & {2{tt_enable_rd[1]}};
  assign rlast_s_int[1] = rlast_m1 & tt_enable_rd[1];
  assign rvalid_s_int[1] = rvalid_m1 & tt_enable_rd[1];
  assign rready_m1 = rready_s & tt_enable_rd[1];

  assign rid_s_int[23:16] = rid_m2 & {8{tt_enable_rd[2]}};
  assign rdata_s_int[191:128] = rdata_m2 & {64{tt_enable_rd[2]}};
  assign rresp_s_int[5:4] = rresp_m2 & {2{tt_enable_rd[2]}};
  assign rlast_s_int[2] = rlast_m2 & tt_enable_rd[2];
  assign rvalid_s_int[2] = rvalid_m2 & tt_enable_rd[2];
  assign rready_m2 = rready_s & tt_enable_rd[2];
 // Or the masked vectors to provide the mux outputs 
  assign rvalid_s = |rvalid_s_int;
  assign rlast_s = |rlast_s_int;
  assign rid_s = rid_s_int[7:0]
                 | rid_s_int[15:8]
                 | rid_s_int[23:16];
  assign rresp_s = rresp_s_int[1:0]
                 | rresp_s_int[3:2]
                 | rresp_s_int[5:4];
  assign rdata_s = rdata_s_int[63:0]
                 | rdata_s_int[127:64]
                 | rdata_s_int[191:128];

  endmodule

//  --=============================== End ====================================--

