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
//  File Revision       : 129771
//
//  Date                :  2012-05-11 11:13:49 +0100 (Fri, 11 May 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : This module is used with a single multi-layer
//                        map-layer to select the required add channel to 
//                        route through to the external master interface
//   
//  Key Configuration Details-
//      - Selecting one of 3 slave interfaces
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterIf (connect to external AXI slave)
//     *_s0 suffix to denote the SlaveIf (connect to external AXI master) 
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_add_sel_ml1_1
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
    // Current selected write channel
    aw_sel,
    wvalid_m,
    wready_m,
    wlast_m,
    // Master Interface return channel handshake signals
    bvalid_m,
    bready_m,
    rvalid_m,
    rready_m,
    rlast_m,
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

    // bchannel mask 
    wr_cnt_empty,
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
   
    // Current selected write channel
  output [2:0]      aw_sel;
  input             wvalid_m;
  input             wready_m;
  input             wlast_m;
  // Master Interface return channel handshake signals
  input             bvalid_m;
  input             bready_m;
  input             rvalid_m;
  input             rready_m;
  input             rlast_m;
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


  // bchannel mask 
  output            wr_cnt_empty;
  // Miscelaneous connections
  input             aclk;
  input             aresetn;

  //----------------------------------------------------------------------------
  // Wires 
  //----------------------------------------------------------------------------
  
  
  wire   [2:0]      aw_valid_vector;
  wire   [2:0]      ar_valid_vector;
  wire   [2:0]      aw_sel_i;
  wire   [2:0]      ar_sel_i;
  wire              last_rd;
  wire              last_slot;     // Only one slave slot available
  
  wire  [3:0]       wr_reqd_qv;    // QV value to be arbitrated next
  wire  [3:0]       rd_reqd_qv;    // QV value to be arbitrated next
  wire              wr_override;   // Override for last slot arbitration
  wire              rd_override;   // Override for last slot arbitration
  wire   [2:0]      rd_wr_awvalid;
  wire   [2:0]      rd_wr_arvalid;

  // Masked Write Address Channel Inputs
  wire   [7:0]      awid_masked0;
  wire   [31:0]     awaddr_masked0;
  wire   [7:0]      awlen_masked0;
  wire   [2:0]      awsize_masked0;
  wire   [1:0]      awburst_masked0;
  wire              awlock_masked0;
  wire   [3:0]      awcache_masked0;
  wire   [2:0]      awprot_masked0;
  wire   [3:0]      aw_qv_masked0;
  wire              awvalid_masked0;
  wire              awvalid_vect_masked0;
  // Masked Read Address Channel Inputs
  wire   [7:0]      arid_masked0;
  wire   [31:0]     araddr_masked0;
  wire   [7:0]      arlen_masked0;
  wire   [2:0]      arsize_masked0;
  wire   [1:0]      arburst_masked0;
  wire              arlock_masked0;
  wire   [3:0]      arcache_masked0;
  wire   [2:0]      arprot_masked0;
  wire   [3:0]      ar_qv_masked0;
  wire              arvalid_masked0;
  wire              arvalid_vect_masked0;

  // Masked Write Address Channel Inputs
  wire   [7:0]      awid_masked1;
  wire   [31:0]     awaddr_masked1;
  wire   [7:0]      awlen_masked1;
  wire   [2:0]      awsize_masked1;
  wire   [1:0]      awburst_masked1;
  wire              awlock_masked1;
  wire   [3:0]      awcache_masked1;
  wire   [2:0]      awprot_masked1;
  wire   [3:0]      aw_qv_masked1;
  wire              awvalid_masked1;
  wire              awvalid_vect_masked1;
  // Masked Read Address Channel Inputs
  wire   [7:0]      arid_masked1;
  wire   [31:0]     araddr_masked1;
  wire   [7:0]      arlen_masked1;
  wire   [2:0]      arsize_masked1;
  wire   [1:0]      arburst_masked1;
  wire              arlock_masked1;
  wire   [3:0]      arcache_masked1;
  wire   [2:0]      arprot_masked1;
  wire   [3:0]      ar_qv_masked1;
  wire              arvalid_masked1;
  wire              arvalid_vect_masked1;

  // Masked Write Address Channel Inputs
  wire   [7:0]      awid_masked2;
  wire   [31:0]     awaddr_masked2;
  wire   [7:0]      awlen_masked2;
  wire   [2:0]      awsize_masked2;
  wire   [1:0]      awburst_masked2;
  wire              awlock_masked2;
  wire   [3:0]      awcache_masked2;
  wire   [2:0]      awprot_masked2;
  wire   [3:0]      aw_qv_masked2;
  wire              awvalid_masked2;
  wire              awvalid_vect_masked2;
  // Masked Read Address Channel Inputs
  wire   [7:0]      arid_masked2;
  wire   [31:0]     araddr_masked2;
  wire   [7:0]      arlen_masked2;
  wire   [2:0]      arsize_masked2;
  wire   [1:0]      arburst_masked2;
  wire              arlock_masked2;
  wire   [3:0]      arcache_masked2;
  wire   [2:0]      arprot_masked2;
  wire   [3:0]      ar_qv_masked2;
  wire              arvalid_masked2;
  wire              arvalid_vect_masked2;

  // Mask control signals to remove a slave interface from the arb scheme
  wire   [2:0]      mask_w;
  wire   [2:0]      mask_r;

  // Internal Master Interface Write Address Channel
  wire   [7:0]      awid_m_i;
  wire   [31:0]     awaddr_m_i;
  wire   [7:0]      awlen_m_i;
  wire   [2:0]      awsize_m_i;
  wire   [1:0]      awburst_m_i;
  wire              awlock_m_i;
  wire   [3:0]      awcache_m_i;
  wire   [2:0]      awprot_m_i;
  wire              awvalid_m_i;
  wire              awvalid_vect_m_i;
  wire              awready_m_i;
  wire   [3:0]      aw_qv_m_i;
   
  // Internal Master Interface Read Address Channel
  wire   [7:0]      arid_m_i;
  wire   [31:0]     araddr_m_i;
  wire   [7:0]      arlen_m_i;
  wire   [2:0]      arsize_m_i;
  wire   [1:0]      arburst_m_i;
  wire              arlock_m_i;
  wire   [3:0]      arcache_m_i;
  wire   [2:0]      arprot_m_i;
  wire              arvalid_m_i;
  wire              arvalid_vect_m_i;
  wire              arready_m_i;
  wire   [3:0]      ar_qv_m_i;


  wire              valid_cnt_wr;
  wire              valid_cnt_rd;

  // Instantiate internal slave interface wires
  // SlaveInterface 0
  // Write Address Channel
  wire   [7:0]      awid_s0_i;
  wire   [31:0]     awaddr_s0_i;
  wire   [7:0]      awlen_s0_i;
  wire   [2:0]      awsize_s0_i;
  wire   [1:0]      awburst_s0_i;
  wire              awlock_s0_i;
  wire   [3:0]      awcache_s0_i;
  wire   [2:0]      awprot_s0_i;
  wire              awvalid_s0_i;
  wire              awvalid_vect_s0_i;
  wire              awready_s0_i;
  wire   [3:0]      aw_qv_s0_i;
  
  // Read Address Channel
  wire   [7:0]      arid_s0_i;
  wire   [31:0]     araddr_s0_i;
  wire   [7:0]      arlen_s0_i;
  wire   [2:0]      arsize_s0_i;
  wire   [1:0]      arburst_s0_i;
  wire              arlock_s0_i;
  wire   [3:0]      arcache_s0_i;
  wire   [2:0]      arprot_s0_i;
  wire              arvalid_s0_i;
  wire              arvalid_vect_s0_i;
  wire              arready_s0_i;
  wire   [3:0]      ar_qv_s0_i;
  

  // SlaveInterface 1
  // Write Address Channel
  wire   [7:0]      awid_s1_i;
  wire   [31:0]     awaddr_s1_i;
  wire   [7:0]      awlen_s1_i;
  wire   [2:0]      awsize_s1_i;
  wire   [1:0]      awburst_s1_i;
  wire              awlock_s1_i;
  wire   [3:0]      awcache_s1_i;
  wire   [2:0]      awprot_s1_i;
  wire              awvalid_s1_i;
  wire              awvalid_vect_s1_i;
  wire              awready_s1_i;
  wire   [3:0]      aw_qv_s1_i;
  
  // Read Address Channel
  wire   [7:0]      arid_s1_i;
  wire   [31:0]     araddr_s1_i;
  wire   [7:0]      arlen_s1_i;
  wire   [2:0]      arsize_s1_i;
  wire   [1:0]      arburst_s1_i;
  wire              arlock_s1_i;
  wire   [3:0]      arcache_s1_i;
  wire   [2:0]      arprot_s1_i;
  wire              arvalid_s1_i;
  wire              arvalid_vect_s1_i;
  wire              arready_s1_i;
  wire   [3:0]      ar_qv_s1_i;
  

  // SlaveInterface 2
  // Write Address Channel
  wire   [7:0]      awid_s2_i;
  wire   [31:0]     awaddr_s2_i;
  wire   [7:0]      awlen_s2_i;
  wire   [2:0]      awsize_s2_i;
  wire   [1:0]      awburst_s2_i;
  wire              awlock_s2_i;
  wire   [3:0]      awcache_s2_i;
  wire   [2:0]      awprot_s2_i;
  wire              awvalid_s2_i;
  wire              awvalid_vect_s2_i;
  wire              awready_s2_i;
  wire   [3:0]      aw_qv_s2_i;
  
  // Read Address Channel
  wire   [7:0]      arid_s2_i;
  wire   [31:0]     araddr_s2_i;
  wire   [7:0]      arlen_s2_i;
  wire   [2:0]      arsize_s2_i;
  wire   [1:0]      arburst_s2_i;
  wire              arlock_s2_i;
  wire   [3:0]      arcache_s2_i;
  wire   [2:0]      arprot_s2_i;
  wire              arvalid_s2_i;
  wire              arvalid_vect_s2_i;
  wire              arready_s2_i;
  wire   [3:0]      ar_qv_s2_i;
  



  //----------------------------------------------------------------------------
  // Registers 
  //----------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------
  // SlaveInterface 0
  // Write Address Channel
  assign awid_s0_i = awid_s0;
  assign awaddr_s0_i = awaddr_s0;
  assign awlen_s0_i = awlen_s0;
  assign awsize_s0_i = awsize_s0;
  assign awburst_s0_i = awburst_s0;
  assign awlock_s0_i = awlock_s0;
  assign awcache_s0_i = awcache_s0;
  assign awprot_s0_i = awprot_s0;
  assign awvalid_s0_i = awvalid_s0;
  assign awvalid_vect_s0_i = awvalid_vect_s0;
  assign aw_qv_s0_i = aw_qv_s0;
  assign awready_s0 = awready_s0_i;
   
  // Read Address Channel
  assign arid_s0_i = arid_s0;
  assign araddr_s0_i = araddr_s0;
  assign arlen_s0_i = arlen_s0;
  assign arsize_s0_i = arsize_s0;
  assign arburst_s0_i = arburst_s0;
  assign arlock_s0_i = arlock_s0;
  assign arcache_s0_i = arcache_s0;
  assign arprot_s0_i = arprot_s0;
  assign arvalid_s0_i = arvalid_s0;
  assign arvalid_vect_s0_i = arvalid_vect_s0;
  assign ar_qv_s0_i = ar_qv_s0;
  assign arready_s0 = arready_s0_i;

  // SlaveInterface 1
  // Write Address Channel
  assign awid_s1_i = awid_s1;
  assign awaddr_s1_i = awaddr_s1;
  assign awlen_s1_i = awlen_s1;
  assign awsize_s1_i = awsize_s1;
  assign awburst_s1_i = awburst_s1;
  assign awlock_s1_i = awlock_s1;
  assign awcache_s1_i = awcache_s1;
  assign awprot_s1_i = awprot_s1;
  assign awvalid_s1_i = awvalid_s1;
  assign awvalid_vect_s1_i = awvalid_vect_s1;
  assign aw_qv_s1_i = aw_qv_s1;
  assign awready_s1 = awready_s1_i;
   
  // Read Address Channel
  assign arid_s1_i = arid_s1;
  assign araddr_s1_i = araddr_s1;
  assign arlen_s1_i = arlen_s1;
  assign arsize_s1_i = arsize_s1;
  assign arburst_s1_i = arburst_s1;
  assign arlock_s1_i = arlock_s1;
  assign arcache_s1_i = arcache_s1;
  assign arprot_s1_i = arprot_s1;
  assign arvalid_s1_i = arvalid_s1;
  assign arvalid_vect_s1_i = arvalid_vect_s1;
  assign ar_qv_s1_i = ar_qv_s1;
  assign arready_s1 = arready_s1_i;

  // SlaveInterface 2
  // Write Address Channel
  assign awid_s2_i = awid_s2;
  assign awaddr_s2_i = awaddr_s2;
  assign awlen_s2_i = awlen_s2;
  assign awsize_s2_i = awsize_s2;
  assign awburst_s2_i = awburst_s2;
  assign awlock_s2_i = awlock_s2;
  assign awcache_s2_i = awcache_s2;
  assign awprot_s2_i = awprot_s2;
  assign awvalid_s2_i = awvalid_s2;
  assign awvalid_vect_s2_i = awvalid_vect_s2;
  assign aw_qv_s2_i = aw_qv_s2;
  assign awready_s2 = awready_s2_i;
   
  // Read Address Channel
  assign arid_s2_i = arid_s2;
  assign araddr_s2_i = araddr_s2;
  assign arlen_s2_i = arlen_s2;
  assign arsize_s2_i = arsize_s2;
  assign arburst_s2_i = arburst_s2;
  assign arlock_s2_i = arlock_s2;
  assign arcache_s2_i = arcache_s2;
  assign arprot_s2_i = arprot_s2;
  assign arvalid_s2_i = arvalid_s2;
  assign arvalid_vect_s2_i = arvalid_vect_s2;
  assign ar_qv_s2_i = ar_qv_s2;
  assign arready_s2 = arready_s2_i;


  //----------------------- Address channel Mask control ----------------------

nic400_bm0_maskcntl_ml1_1 u_nic400_bm0_maskcntl_ml1_1 (
        // Only one slave slot available
        .last_slot    (last_slot),
        // Master Interface address channel handshake signals
        .awvalid_m    (awvalid_m_i),
        .awready_m    (awready_m_i),
        .arvalid_m    (arvalid_m_i),
        .arready_m    (arready_m_i),
        .wvalid_m     (wvalid_m),
        .wready_m     (wready_m),
        .wlast_m      (wlast_m),

        // Master Interface return channel handshake signals
        .bvalid_m     (bvalid_m),
        .bready_m     (bready_m),
        .rvalid_m     (last_rd),
        .rready_m     (rready_m),
        // Arbitration mask vectors
        .wr_cnt_empty (wr_cnt_empty),
        .mask_w       (mask_w),
        .mask_r       (mask_r),
        // Miscelaneous connections
        .aclk         (aclk),
        .aresetn      (aresetn)
);


   assign last_rd = (rvalid_m & rlast_m);
   // Build a vector of write valids, one bit per attached slave interface
   assign aw_valid_vector[0] = awvalid_s0_i;
   assign aw_valid_vector[1] = awvalid_s1_i;
   assign aw_valid_vector[2] = awvalid_s2_i;
   // Build a vector of read valids, one bit per attached slave interface
   assign ar_valid_vector[0] = arvalid_s0_i;
   assign ar_valid_vector[1] = arvalid_s1_i;
   assign ar_valid_vector[2] = arvalid_s2_i;
   assign rd_wr_awvalid = aw_valid_vector & ~mask_w;
   assign rd_wr_arvalid = ar_valid_vector & ~mask_r;

// If wr iss plus rd iss is greater than combined iss then arbitrate 
nic400_bm0_rd_wr_arb_1_1 u_nic400_bm0_rd_wr_arb_1_1 (
        .wr_override    (wr_override),
        .rd_override    (rd_override),
        .last_slot      (last_slot),
        .wr_reqd_qv     (wr_reqd_qv),
        .rd_reqd_qv     (rd_reqd_qv),
        // Master Interface address channel handshake signals
        .awvalid        (|rd_wr_awvalid),
        .awvalid_m      (valid_cnt_wr),
        .awready_m      (awready_m_i),
        .arvalid        (|rd_wr_arvalid),
        .arvalid_m      (valid_cnt_rd),
        .arready_m      (arready_m_i),
        // Miscelaneous connections
        .aclk           (aclk),
        .aresetn        (aresetn)
);

  //----------------------- Address channel arbitration -----------------------
nic400_bm0_add_arb_ml1_1 u_nic400_bm0_aw_arb_ml1_1 (
        // Override arbitration
        .override       (wr_override),
        // Next required quality value
        .reqd_qv        (wr_reqd_qv),
        // Valid signal for counters
        .valid_cnt      (valid_cnt_wr),
        // Address Select Ouput 
        .a_sel          (aw_sel_i),
        // Input Select Criteria
        .a_valid_vector (aw_valid_vector),
        .aready         (awready_m_i),
        .mask           (mask_w),
        .qv0            (aw_qv_s0_i),
        .qv1            (aw_qv_s1_i),
        .qv2            (aw_qv_s2_i),
        // Miscelaneous connections
        .aclk           (aclk),
        .aresetn        (aresetn)
);

nic400_bm0_add_arb_ml1_1 u_nic400_bm0_ar_arb_ml1_1 (
        // Override arbitration
        .override       (rd_override),
        // Next required quality value
        .reqd_qv        (rd_reqd_qv),
        // Valid signal for counters
        .valid_cnt      (valid_cnt_rd),
        // Address Select Ouput 
        .a_sel          (ar_sel_i),
        // Input Select Criteria
        .a_valid_vector (ar_valid_vector),
        .aready         (arready_m_i),
        .mask           (mask_r),
        .qv0            (ar_qv_s0_i),
        .qv1            (ar_qv_s1_i),
        .qv2            (ar_qv_s2_i),
        // Miscelaneous connections
        .aclk          (aclk),
        .aresetn       (aresetn)
);

  //------------------------- Address channel Muxing --------------------------
  // Mask each slave interface address channel with its respective selction bit

    // Write Address Channel
    assign awid_masked0    = awid_s0_i & {8{aw_sel_i[0]}};
    assign awaddr_masked0  = awaddr_s0_i & {32{aw_sel_i[0]}};
    assign awlen_masked0   = awlen_s0_i & {8{aw_sel_i[0]}};
    assign awsize_masked0  = awsize_s0_i & {3{aw_sel_i[0]}};
    assign awburst_masked0 = awburst_s0_i & {2{aw_sel_i[0]}};
    assign awlock_masked0  = awlock_s0_i & {1{aw_sel_i[0]}};
    assign awcache_masked0 = awcache_s0_i & {4{aw_sel_i[0]}};
    assign awprot_masked0  = awprot_s0_i & {3{aw_sel_i[0]}};
    assign aw_qv_masked0   = aw_qv_s0_i & {4{aw_sel_i[0]}};
    assign awvalid_masked0 = awvalid_s0_i & aw_sel_i[0];
    assign awvalid_vect_masked0 = awvalid_vect_s0_i & aw_sel_i[0];
  
    // Read Address Channel
    assign arid_masked0   = arid_s0_i & {8{ar_sel_i[0]}};
    assign araddr_masked0  = araddr_s0_i & {32{ar_sel_i[0]}};
    assign arlen_masked0   = arlen_s0_i & {8{ar_sel_i[0]}};
    assign arsize_masked0  = arsize_s0_i & {3{ar_sel_i[0]}};
    assign arburst_masked0 = arburst_s0_i & {2{ar_sel_i[0]}};
    assign arlock_masked0  = arlock_s0_i & {1{ar_sel_i[0]}};
    assign arcache_masked0 = arcache_s0_i & {4{ar_sel_i[0]}};
    assign arprot_masked0  = arprot_s0_i & {3{ar_sel_i[0]}};
    assign ar_qv_masked0   = ar_qv_s0_i & {4{ar_sel_i[0]}};
    assign arvalid_masked0 = arvalid_s0_i & ar_sel_i[0];
    assign arvalid_vect_masked0 = arvalid_vect_s0_i & ar_sel_i[0];

    // Write Address Channel
    assign awid_masked1    = awid_s1_i & {8{aw_sel_i[1]}};
    assign awaddr_masked1  = awaddr_s1_i & {32{aw_sel_i[1]}};
    assign awlen_masked1   = awlen_s1_i & {8{aw_sel_i[1]}};
    assign awsize_masked1  = awsize_s1_i & {3{aw_sel_i[1]}};
    assign awburst_masked1 = awburst_s1_i & {2{aw_sel_i[1]}};
    assign awlock_masked1  = awlock_s1_i & {1{aw_sel_i[1]}};
    assign awcache_masked1 = awcache_s1_i & {4{aw_sel_i[1]}};
    assign awprot_masked1  = awprot_s1_i & {3{aw_sel_i[1]}};
    assign aw_qv_masked1   = aw_qv_s1_i & {4{aw_sel_i[1]}};
    assign awvalid_masked1 = awvalid_s1_i & aw_sel_i[1];
    assign awvalid_vect_masked1 = awvalid_vect_s1_i & aw_sel_i[1];
  
    // Read Address Channel
    assign arid_masked1   = arid_s1_i & {8{ar_sel_i[1]}};
    assign araddr_masked1  = araddr_s1_i & {32{ar_sel_i[1]}};
    assign arlen_masked1   = arlen_s1_i & {8{ar_sel_i[1]}};
    assign arsize_masked1  = arsize_s1_i & {3{ar_sel_i[1]}};
    assign arburst_masked1 = arburst_s1_i & {2{ar_sel_i[1]}};
    assign arlock_masked1  = arlock_s1_i & {1{ar_sel_i[1]}};
    assign arcache_masked1 = arcache_s1_i & {4{ar_sel_i[1]}};
    assign arprot_masked1  = arprot_s1_i & {3{ar_sel_i[1]}};
    assign ar_qv_masked1   = ar_qv_s1_i & {4{ar_sel_i[1]}};
    assign arvalid_masked1 = arvalid_s1_i & ar_sel_i[1];
    assign arvalid_vect_masked1 = arvalid_vect_s1_i & ar_sel_i[1];

    // Write Address Channel
    assign awid_masked2    = awid_s2_i & {8{aw_sel_i[2]}};
    assign awaddr_masked2  = awaddr_s2_i & {32{aw_sel_i[2]}};
    assign awlen_masked2   = awlen_s2_i & {8{aw_sel_i[2]}};
    assign awsize_masked2  = awsize_s2_i & {3{aw_sel_i[2]}};
    assign awburst_masked2 = awburst_s2_i & {2{aw_sel_i[2]}};
    assign awlock_masked2  = awlock_s2_i & {1{aw_sel_i[2]}};
    assign awcache_masked2 = awcache_s2_i & {4{aw_sel_i[2]}};
    assign awprot_masked2  = awprot_s2_i & {3{aw_sel_i[2]}};
    assign aw_qv_masked2   = aw_qv_s2_i & {4{aw_sel_i[2]}};
    assign awvalid_masked2 = awvalid_s2_i & aw_sel_i[2];
    assign awvalid_vect_masked2 = awvalid_vect_s2_i & aw_sel_i[2];
  
    // Read Address Channel
    assign arid_masked2   = arid_s2_i & {8{ar_sel_i[2]}};
    assign araddr_masked2  = araddr_s2_i & {32{ar_sel_i[2]}};
    assign arlen_masked2   = arlen_s2_i & {8{ar_sel_i[2]}};
    assign arsize_masked2  = arsize_s2_i & {3{ar_sel_i[2]}};
    assign arburst_masked2 = arburst_s2_i & {2{ar_sel_i[2]}};
    assign arlock_masked2  = arlock_s2_i & {1{ar_sel_i[2]}};
    assign arcache_masked2 = arcache_s2_i & {4{ar_sel_i[2]}};
    assign arprot_masked2  = arprot_s2_i & {3{ar_sel_i[2]}};
    assign ar_qv_masked2   = ar_qv_s2_i & {4{ar_sel_i[2]}};
    assign arvalid_masked2 = arvalid_s2_i & ar_sel_i[2];
    assign arvalid_vect_masked2 = arvalid_vect_s2_i & ar_sel_i[2];



    // Assign the Master Interface Address Channel Outputs from the 
    // Masked Slave Interface Inputs
    // Write Address Channel
    assign awid_m_i    = awid_masked0
                       | awid_masked1
                       | awid_masked2;
    assign awaddr_m_i  = awaddr_masked0
                       | awaddr_masked1
                       | awaddr_masked2;
    assign awlen_m_i   = awlen_masked0
                       | awlen_masked1
                       | awlen_masked2;
    assign awsize_m_i  = awsize_masked0
                       | awsize_masked1
                       | awsize_masked2;
    assign awburst_m_i = awburst_masked0
                       | awburst_masked1
                       | awburst_masked2;
    assign awlock_m_i  = awlock_masked0
                       | awlock_masked1
                       | awlock_masked2;
    assign awcache_m_i = awcache_masked0
                       | awcache_masked1
                       | awcache_masked2;
    assign awprot_m_i  = awprot_masked0
                       | awprot_masked1
                       | awprot_masked2;
    assign aw_qv_m_i   = aw_qv_masked0
                       | aw_qv_masked1
                       | aw_qv_masked2;
    assign awvalid_m_i = (awvalid_masked0
                      | awvalid_masked1
                      | awvalid_masked2);
     assign awvalid_vect_m_i = (awvalid_vect_masked0
                      | awvalid_vect_masked1
                      | awvalid_vect_masked2);
  
    // Read Address Channel
    assign arid_m_i    = arid_masked0
                       | arid_masked1
                       | arid_masked2;
    assign araddr_m_i  = araddr_masked0
                       | araddr_masked1
                       | araddr_masked2;
    assign arlen_m_i   = arlen_masked0
                       | arlen_masked1
                       | arlen_masked2;
    assign arsize_m_i  = arsize_masked0
                       | arsize_masked1
                       | arsize_masked2;
    assign arburst_m_i = arburst_masked0
                       | arburst_masked1
                       | arburst_masked2;
    assign arlock_m_i  = arlock_masked0
                       | arlock_masked1
                       | arlock_masked2;
    assign arcache_m_i = arcache_masked0
                       | arcache_masked1
                       | arcache_masked2;
    assign arprot_m_i  = arprot_masked0
                       | arprot_masked1
                       | arprot_masked2;
    assign ar_qv_m_i   = ar_qv_masked0
                       | ar_qv_masked1
                       | ar_qv_masked2;
    assign arvalid_m_i = (arvalid_masked0
                       | arvalid_masked1
                       | arvalid_masked2);
    assign arvalid_vect_m_i = (arvalid_vect_masked0
                       | arvalid_vect_masked1
                       | arvalid_vect_masked2);

    // Mask the ready signals back to the current slave interface

    assign awready_s0_i     = awready_m_i & aw_sel_i[0];
    assign arready_s0_i     = arready_m_i & ar_sel_i[0];

    assign awready_s1_i     = awready_m_i & aw_sel_i[1];
    assign arready_s1_i     = arready_m_i & ar_sel_i[1];

    assign awready_s2_i     = awready_m_i & aw_sel_i[2];
    assign arready_s2_i     = arready_m_i & ar_sel_i[2];

    // Write Address Channel
    assign awid_m         = awid_m_i;
    assign awaddr_m       = awaddr_m_i;
    assign awlen_m        = awlen_m_i;
    assign awsize_m       = awsize_m_i;
    assign awburst_m      = awburst_m_i;
    assign awlock_m       = awlock_m_i;
    assign awcache_m      = awcache_m_i;
    assign awprot_m       = awprot_m_i;
    assign aw_qv_m        = aw_qv_m_i;
    assign awvalid_m      = awvalid_m_i;
    assign awvalid_vect_m = awvalid_vect_m_i;
   
    // Read Address Channel
    assign arid_m         = arid_m_i;
    assign araddr_m       = araddr_m_i;
    assign arlen_m        = arlen_m_i;
    assign arsize_m       = arsize_m_i;
    assign arburst_m      = arburst_m_i;
    assign arlock_m       = arlock_m_i;
    assign arcache_m      = arcache_m_i;
    assign arprot_m       = arprot_m_i;
    assign ar_qv_m        = ar_qv_m_i;
    assign arvalid_m      = arvalid_m_i;
    assign arvalid_vect_m = arvalid_vect_m_i;

    // Assign return ready signals
    assign awready_m_i    = awready_m;
    assign arready_m_i    = arready_m;

    // Output select signals
    assign aw_sel         = aw_sel_i;



endmodule



//  --=============================== End ====================================--

