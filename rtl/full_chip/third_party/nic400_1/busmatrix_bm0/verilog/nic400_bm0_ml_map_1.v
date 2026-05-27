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
//  File Revision       : 126202
//
//  Date                :  2012-03-02 11:28:07 +0000 (Fri, 02 Mar 2012)
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  File Purpose        : Structural file that instantiates all the modules
//                        required to implement the build layers module of a
//                        multi layer AXI bus matrix 
//   
//  Key Configuration Details-
//       - Number of map layers (mlayers) : 3
//   
//
// Notes on port naming conventions- 
//
//     All AXI point to point connections can be considered a 
//     MasterInterface - SlaveInterface connection. 
//
//     The AXI ports on the NIC400 A3BM are named as follows-  
//
//     *_m<n> suffix to denote a MasterInterface (connect to external AXI slave)
//     *_s<n> suffix to denote a SlaveInterface (connect to external AXI master) 
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_bm0_ml_map_1
  (
    // External AXI Connections 

    // MasterInterface 0 (connects to Slave axi_m_0)
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

    // MasterInterface 1 (connects to Slave axi_m_1)
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

    // MasterInterface 2 (connects to Slave axi_m_2)
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


    // Internal AXI Connections 

    // Connects SlaveInterface 0  to Master Interface 0)

    // Write Address Channel
    awid_0_0,
    awaddr_0_0,
    awlen_0_0,
    awsize_0_0,
    awburst_0_0,
    awlock_0_0,
    awcache_0_0,
    awprot_0_0,
    awvalid_0_0,
    awvalid_vect_0_0,
    awready_0_0,
    aw_qv_0_0,
   
    // Write Channel
    wdata_0_0,
    wstrb_0_0,   
    wlast_0_0,
    wvalid_0_0,
    wready_0_0,

    // Write Response Channel
    bid_0_0,
    bresp_0_0,
    bvalid_0_0,
    bready_0_0,  

    // Read Address Channel
    arid_0_0,
    araddr_0_0,
    arlen_0_0,
    arsize_0_0,
    arburst_0_0,
    arlock_0_0,
    arcache_0_0,
    arprot_0_0,
    arvalid_0_0,
    arvalid_vect_0_0,
    arready_0_0,
    ar_qv_0_0,
   
    // Read Channel
    rid_0_0,
    rdata_0_0,
    rresp_0_0,
    rlast_0_0,
    rvalid_0_0,
    rready_0_0,


    // Connects SlaveInterface 0  to Master Interface 1)

    // Write Address Channel
    awid_0_1,
    awaddr_0_1,
    awlen_0_1,
    awsize_0_1,
    awburst_0_1,
    awlock_0_1,
    awcache_0_1,
    awprot_0_1,
    awvalid_0_1,
    awvalid_vect_0_1,
    awready_0_1,
    aw_qv_0_1,
   
    // Write Channel
    wdata_0_1,
    wstrb_0_1,   
    wlast_0_1,
    wvalid_0_1,
    wready_0_1,

    // Write Response Channel
    bid_0_1,
    bresp_0_1,
    bvalid_0_1,
    bready_0_1,  

    // Read Address Channel
    arid_0_1,
    araddr_0_1,
    arlen_0_1,
    arsize_0_1,
    arburst_0_1,
    arlock_0_1,
    arcache_0_1,
    arprot_0_1,
    arvalid_0_1,
    arvalid_vect_0_1,
    arready_0_1,
    ar_qv_0_1,
   
    // Read Channel
    rid_0_1,
    rdata_0_1,
    rresp_0_1,
    rlast_0_1,
    rvalid_0_1,
    rready_0_1,


    // Connects SlaveInterface 0  to Master Interface 2)

    // Write Address Channel
    awid_0_2,
    awaddr_0_2,
    awlen_0_2,
    awsize_0_2,
    awburst_0_2,
    awlock_0_2,
    awcache_0_2,
    awprot_0_2,
    awvalid_0_2,
    awvalid_vect_0_2,
    awready_0_2,
    aw_qv_0_2,
   
    // Write Channel
    wdata_0_2,
    wstrb_0_2,   
    wlast_0_2,
    wvalid_0_2,
    wready_0_2,

    // Write Response Channel
    bid_0_2,
    bresp_0_2,
    bvalid_0_2,
    bready_0_2,  

    // Read Address Channel
    arid_0_2,
    araddr_0_2,
    arlen_0_2,
    arsize_0_2,
    arburst_0_2,
    arlock_0_2,
    arcache_0_2,
    arprot_0_2,
    arvalid_0_2,
    arvalid_vect_0_2,
    arready_0_2,
    ar_qv_0_2,
   
    // Read Channel
    rid_0_2,
    rdata_0_2,
    rresp_0_2,
    rlast_0_2,
    rvalid_0_2,
    rready_0_2,


    // Connects SlaveInterface 1  to Master Interface 0)

    // Write Address Channel
    awid_1_0,
    awaddr_1_0,
    awlen_1_0,
    awsize_1_0,
    awburst_1_0,
    awlock_1_0,
    awcache_1_0,
    awprot_1_0,
    awvalid_1_0,
    awvalid_vect_1_0,
    awready_1_0,
    aw_qv_1_0,
   
    // Write Channel
    wdata_1_0,
    wstrb_1_0,   
    wlast_1_0,
    wvalid_1_0,
    wready_1_0,

    // Write Response Channel
    bid_1_0,
    bresp_1_0,
    bvalid_1_0,
    bready_1_0,  

    // Read Address Channel
    arid_1_0,
    araddr_1_0,
    arlen_1_0,
    arsize_1_0,
    arburst_1_0,
    arlock_1_0,
    arcache_1_0,
    arprot_1_0,
    arvalid_1_0,
    arvalid_vect_1_0,
    arready_1_0,
    ar_qv_1_0,
   
    // Read Channel
    rid_1_0,
    rdata_1_0,
    rresp_1_0,
    rlast_1_0,
    rvalid_1_0,
    rready_1_0,


    // Connects SlaveInterface 1  to Master Interface 1)

    // Write Address Channel
    awid_1_1,
    awaddr_1_1,
    awlen_1_1,
    awsize_1_1,
    awburst_1_1,
    awlock_1_1,
    awcache_1_1,
    awprot_1_1,
    awvalid_1_1,
    awvalid_vect_1_1,
    awready_1_1,
    aw_qv_1_1,
   
    // Write Channel
    wdata_1_1,
    wstrb_1_1,   
    wlast_1_1,
    wvalid_1_1,
    wready_1_1,

    // Write Response Channel
    bid_1_1,
    bresp_1_1,
    bvalid_1_1,
    bready_1_1,  

    // Read Address Channel
    arid_1_1,
    araddr_1_1,
    arlen_1_1,
    arsize_1_1,
    arburst_1_1,
    arlock_1_1,
    arcache_1_1,
    arprot_1_1,
    arvalid_1_1,
    arvalid_vect_1_1,
    arready_1_1,
    ar_qv_1_1,
   
    // Read Channel
    rid_1_1,
    rdata_1_1,
    rresp_1_1,
    rlast_1_1,
    rvalid_1_1,
    rready_1_1,


    // Connects SlaveInterface 1  to Master Interface 2)

    // Write Address Channel
    awid_1_2,
    awaddr_1_2,
    awlen_1_2,
    awsize_1_2,
    awburst_1_2,
    awlock_1_2,
    awcache_1_2,
    awprot_1_2,
    awvalid_1_2,
    awvalid_vect_1_2,
    awready_1_2,
    aw_qv_1_2,
   
    // Write Channel
    wdata_1_2,
    wstrb_1_2,   
    wlast_1_2,
    wvalid_1_2,
    wready_1_2,

    // Write Response Channel
    bid_1_2,
    bresp_1_2,
    bvalid_1_2,
    bready_1_2,  

    // Read Address Channel
    arid_1_2,
    araddr_1_2,
    arlen_1_2,
    arsize_1_2,
    arburst_1_2,
    arlock_1_2,
    arcache_1_2,
    arprot_1_2,
    arvalid_1_2,
    arvalid_vect_1_2,
    arready_1_2,
    ar_qv_1_2,
   
    // Read Channel
    rid_1_2,
    rdata_1_2,
    rresp_1_2,
    rlast_1_2,
    rvalid_1_2,
    rready_1_2,


    // Connects SlaveInterface 2  to Master Interface 0)

    // Write Address Channel
    awid_2_0,
    awaddr_2_0,
    awlen_2_0,
    awsize_2_0,
    awburst_2_0,
    awlock_2_0,
    awcache_2_0,
    awprot_2_0,
    awvalid_2_0,
    awvalid_vect_2_0,
    awready_2_0,
    aw_qv_2_0,
   
    // Write Channel
    wdata_2_0,
    wstrb_2_0,   
    wlast_2_0,
    wvalid_2_0,
    wready_2_0,

    // Write Response Channel
    bid_2_0,
    bresp_2_0,
    bvalid_2_0,
    bready_2_0,  

    // Read Address Channel
    arid_2_0,
    araddr_2_0,
    arlen_2_0,
    arsize_2_0,
    arburst_2_0,
    arlock_2_0,
    arcache_2_0,
    arprot_2_0,
    arvalid_2_0,
    arvalid_vect_2_0,
    arready_2_0,
    ar_qv_2_0,
   
    // Read Channel
    rid_2_0,
    rdata_2_0,
    rresp_2_0,
    rlast_2_0,
    rvalid_2_0,
    rready_2_0,


    // Connects SlaveInterface 2  to Master Interface 1)

    // Write Address Channel
    awid_2_1,
    awaddr_2_1,
    awlen_2_1,
    awsize_2_1,
    awburst_2_1,
    awlock_2_1,
    awcache_2_1,
    awprot_2_1,
    awvalid_2_1,
    awvalid_vect_2_1,
    awready_2_1,
    aw_qv_2_1,
   
    // Write Channel
    wdata_2_1,
    wstrb_2_1,   
    wlast_2_1,
    wvalid_2_1,
    wready_2_1,

    // Write Response Channel
    bid_2_1,
    bresp_2_1,
    bvalid_2_1,
    bready_2_1,  

    // Read Address Channel
    arid_2_1,
    araddr_2_1,
    arlen_2_1,
    arsize_2_1,
    arburst_2_1,
    arlock_2_1,
    arcache_2_1,
    arprot_2_1,
    arvalid_2_1,
    arvalid_vect_2_1,
    arready_2_1,
    ar_qv_2_1,
   
    // Read Channel
    rid_2_1,
    rdata_2_1,
    rresp_2_1,
    rlast_2_1,
    rvalid_2_1,
    rready_2_1,


    // Connects SlaveInterface 2  to Master Interface 2)

    // Write Address Channel
    awid_2_2,
    awaddr_2_2,
    awlen_2_2,
    awsize_2_2,
    awburst_2_2,
    awlock_2_2,
    awcache_2_2,
    awprot_2_2,
    awvalid_2_2,
    awvalid_vect_2_2,
    awready_2_2,
    aw_qv_2_2,
   
    // Write Channel
    wdata_2_2,
    wstrb_2_2,   
    wlast_2_2,
    wvalid_2_2,
    wready_2_2,

    // Write Response Channel
    bid_2_2,
    bresp_2_2,
    bvalid_2_2,
    bready_2_2,  

    // Read Address Channel
    arid_2_2,
    araddr_2_2,
    arlen_2_2,
    arsize_2_2,
    arburst_2_2,
    arlock_2_2,
    arcache_2_2,
    arprot_2_2,
    arvalid_2_2,
    arvalid_vect_2_2,
    arready_2_2,
    ar_qv_2_2,
   
    // Read Channel
    rid_2_2,
    rdata_2_2,
    rresp_2_2,
    rlast_2_2,
    rvalid_2_2,
    rready_2_2,


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
    // External AXI Connections 

    // MasterInterface 0 (connects to Slave axi_m_0)
    // Write Address Channel
    output [7:0]        awid_m0;
    output [31:0]       awaddr_m0;
    output [7:0]        awlen_m0;
    output [2:0]        awsize_m0;
    output [1:0]        awburst_m0;
    output              awlock_m0;
    output [3:0]        awcache_m0;
    output [2:0]        awprot_m0;
    output              awvalid_m0;
    output              awvalid_vect_m0;
    input               awready_m0;
    output [3:0]        aw_qv_m0;
   
    // Write Channel
    output [63:0]       wdata_m0;
    output [7:0]        wstrb_m0;   
    output              wlast_m0;
    output              wvalid_m0;
    input               wready_m0;

    // Write Response Channel
    input  [7:0]             bid_m0;
    input  [1:0]        bresp_m0;
    input               bvalid_m0;
    output              bready_m0;  

    // Read Address Channel
    output [7:0]        arid_m0;
    output [31:0]       araddr_m0;
    output [7:0]        arlen_m0;
    output [2:0]        arsize_m0;
    output [1:0]        arburst_m0;
    output              arlock_m0;
    output [3:0]        arcache_m0;
    output [2:0]        arprot_m0;
    output              arvalid_m0;
    output              arvalid_vect_m0;
    input               arready_m0;
    output [3:0]        ar_qv_m0;
   
    // Read Channel
    input  [7:0]        rid_m0;
    input  [63:0]       rdata_m0;
    input  [1:0]        rresp_m0;
    input               rlast_m0;
    input               rvalid_m0;
    output              rready_m0;

    // MasterInterface 1 (connects to Slave axi_m_1)
    // Write Address Channel
    output [7:0]        awid_m1;
    output [31:0]       awaddr_m1;
    output [7:0]        awlen_m1;
    output [2:0]        awsize_m1;
    output [1:0]        awburst_m1;
    output              awlock_m1;
    output [3:0]        awcache_m1;
    output [2:0]        awprot_m1;
    output              awvalid_m1;
    output              awvalid_vect_m1;
    input               awready_m1;
    output [3:0]        aw_qv_m1;
   
    // Write Channel
    output [63:0]       wdata_m1;
    output [7:0]        wstrb_m1;   
    output              wlast_m1;
    output              wvalid_m1;
    input               wready_m1;

    // Write Response Channel
    input  [7:0]             bid_m1;
    input  [1:0]        bresp_m1;
    input               bvalid_m1;
    output              bready_m1;  

    // Read Address Channel
    output [7:0]        arid_m1;
    output [31:0]       araddr_m1;
    output [7:0]        arlen_m1;
    output [2:0]        arsize_m1;
    output [1:0]        arburst_m1;
    output              arlock_m1;
    output [3:0]        arcache_m1;
    output [2:0]        arprot_m1;
    output              arvalid_m1;
    output              arvalid_vect_m1;
    input               arready_m1;
    output [3:0]        ar_qv_m1;
   
    // Read Channel
    input  [7:0]        rid_m1;
    input  [63:0]       rdata_m1;
    input  [1:0]        rresp_m1;
    input               rlast_m1;
    input               rvalid_m1;
    output              rready_m1;

    // MasterInterface 2 (connects to Slave axi_m_2)
    // Write Address Channel
    output [7:0]        awid_m2;
    output [31:0]       awaddr_m2;
    output [7:0]        awlen_m2;
    output [2:0]        awsize_m2;
    output [1:0]        awburst_m2;
    output              awlock_m2;
    output [3:0]        awcache_m2;
    output [2:0]        awprot_m2;
    output              awvalid_m2;
    output              awvalid_vect_m2;
    input               awready_m2;
    output [3:0]        aw_qv_m2;
   
    // Write Channel
    output [63:0]       wdata_m2;
    output [7:0]        wstrb_m2;   
    output              wlast_m2;
    output              wvalid_m2;
    input               wready_m2;

    // Write Response Channel
    input  [7:0]             bid_m2;
    input  [1:0]        bresp_m2;
    input               bvalid_m2;
    output              bready_m2;  

    // Read Address Channel
    output [7:0]        arid_m2;
    output [31:0]       araddr_m2;
    output [7:0]        arlen_m2;
    output [2:0]        arsize_m2;
    output [1:0]        arburst_m2;
    output              arlock_m2;
    output [3:0]        arcache_m2;
    output [2:0]        arprot_m2;
    output              arvalid_m2;
    output              arvalid_vect_m2;
    input               arready_m2;
    output [3:0]        ar_qv_m2;
   
    // Read Channel
    input  [7:0]        rid_m2;
    input  [63:0]       rdata_m2;
    input  [1:0]        rresp_m2;
    input               rlast_m2;
    input               rvalid_m2;
    output              rready_m2;


    // Internal AXI Connections 

    // Connects SlaveInterface 0  to Master Interface 0)

    // Write Address Channel
    input  [7:0]        awid_0_0;
    input  [31:0]       awaddr_0_0;
    input  [7:0]        awlen_0_0;
    input  [2:0]        awsize_0_0;
    input  [1:0]        awburst_0_0;
    input               awlock_0_0;
    input  [3:0]        awcache_0_0;
    input  [2:0]        awprot_0_0;
    input               awvalid_0_0;
    input               awvalid_vect_0_0;
    output              awready_0_0;
    input [3:0]         aw_qv_0_0;
   
    // Write Channel
    input [63:0]        wdata_0_0;
    input [7:0]         wstrb_0_0;   
    input               wlast_0_0;
    input               wvalid_0_0;
    output              wready_0_0;

    // Write Response Channel
    output [7:0]        bid_0_0;
    output [1:0]        bresp_0_0;
    output              bvalid_0_0;
    input               bready_0_0;  

    // Read Address Channel
    input  [7:0]        arid_0_0;
    input  [31:0]       araddr_0_0;
    input  [7:0]        arlen_0_0;
    input  [2:0]        arsize_0_0;
    input  [1:0]        arburst_0_0;
    input               arlock_0_0;
    input  [3:0]        arcache_0_0;
    input  [2:0]        arprot_0_0;
    input               arvalid_0_0;
    input               arvalid_vect_0_0;
    output              arready_0_0;
    input [3:0]         ar_qv_0_0;
   
    // Read Channel
    output [7:0]        rid_0_0;
    output [63:0]       rdata_0_0;
    output [1:0]        rresp_0_0;
    output              rlast_0_0;
    output              rvalid_0_0;
    input               rready_0_0;


    // Connects SlaveInterface 0  to Master Interface 1)

    // Write Address Channel
    input  [7:0]        awid_0_1;
    input  [31:0]       awaddr_0_1;
    input  [7:0]        awlen_0_1;
    input  [2:0]        awsize_0_1;
    input  [1:0]        awburst_0_1;
    input               awlock_0_1;
    input  [3:0]        awcache_0_1;
    input  [2:0]        awprot_0_1;
    input               awvalid_0_1;
    input               awvalid_vect_0_1;
    output              awready_0_1;
    input [3:0]         aw_qv_0_1;
   
    // Write Channel
    input [63:0]        wdata_0_1;
    input [7:0]         wstrb_0_1;   
    input               wlast_0_1;
    input               wvalid_0_1;
    output              wready_0_1;

    // Write Response Channel
    output [7:0]        bid_0_1;
    output [1:0]        bresp_0_1;
    output              bvalid_0_1;
    input               bready_0_1;  

    // Read Address Channel
    input  [7:0]        arid_0_1;
    input  [31:0]       araddr_0_1;
    input  [7:0]        arlen_0_1;
    input  [2:0]        arsize_0_1;
    input  [1:0]        arburst_0_1;
    input               arlock_0_1;
    input  [3:0]        arcache_0_1;
    input  [2:0]        arprot_0_1;
    input               arvalid_0_1;
    input               arvalid_vect_0_1;
    output              arready_0_1;
    input [3:0]         ar_qv_0_1;
   
    // Read Channel
    output [7:0]        rid_0_1;
    output [63:0]       rdata_0_1;
    output [1:0]        rresp_0_1;
    output              rlast_0_1;
    output              rvalid_0_1;
    input               rready_0_1;


    // Connects SlaveInterface 0  to Master Interface 2)

    // Write Address Channel
    input  [7:0]        awid_0_2;
    input  [31:0]       awaddr_0_2;
    input  [7:0]        awlen_0_2;
    input  [2:0]        awsize_0_2;
    input  [1:0]        awburst_0_2;
    input               awlock_0_2;
    input  [3:0]        awcache_0_2;
    input  [2:0]        awprot_0_2;
    input               awvalid_0_2;
    input               awvalid_vect_0_2;
    output              awready_0_2;
    input [3:0]         aw_qv_0_2;
   
    // Write Channel
    input [63:0]        wdata_0_2;
    input [7:0]         wstrb_0_2;   
    input               wlast_0_2;
    input               wvalid_0_2;
    output              wready_0_2;

    // Write Response Channel
    output [7:0]        bid_0_2;
    output [1:0]        bresp_0_2;
    output              bvalid_0_2;
    input               bready_0_2;  

    // Read Address Channel
    input  [7:0]        arid_0_2;
    input  [31:0]       araddr_0_2;
    input  [7:0]        arlen_0_2;
    input  [2:0]        arsize_0_2;
    input  [1:0]        arburst_0_2;
    input               arlock_0_2;
    input  [3:0]        arcache_0_2;
    input  [2:0]        arprot_0_2;
    input               arvalid_0_2;
    input               arvalid_vect_0_2;
    output              arready_0_2;
    input [3:0]         ar_qv_0_2;
   
    // Read Channel
    output [7:0]        rid_0_2;
    output [63:0]       rdata_0_2;
    output [1:0]        rresp_0_2;
    output              rlast_0_2;
    output              rvalid_0_2;
    input               rready_0_2;


    // Connects SlaveInterface 1  to Master Interface 0)

    // Write Address Channel
    input  [7:0]        awid_1_0;
    input  [31:0]       awaddr_1_0;
    input  [7:0]        awlen_1_0;
    input  [2:0]        awsize_1_0;
    input  [1:0]        awburst_1_0;
    input               awlock_1_0;
    input  [3:0]        awcache_1_0;
    input  [2:0]        awprot_1_0;
    input               awvalid_1_0;
    input               awvalid_vect_1_0;
    output              awready_1_0;
    input [3:0]         aw_qv_1_0;
   
    // Write Channel
    input [63:0]        wdata_1_0;
    input [7:0]         wstrb_1_0;   
    input               wlast_1_0;
    input               wvalid_1_0;
    output              wready_1_0;

    // Write Response Channel
    output [7:0]        bid_1_0;
    output [1:0]        bresp_1_0;
    output              bvalid_1_0;
    input               bready_1_0;  

    // Read Address Channel
    input  [7:0]        arid_1_0;
    input  [31:0]       araddr_1_0;
    input  [7:0]        arlen_1_0;
    input  [2:0]        arsize_1_0;
    input  [1:0]        arburst_1_0;
    input               arlock_1_0;
    input  [3:0]        arcache_1_0;
    input  [2:0]        arprot_1_0;
    input               arvalid_1_0;
    input               arvalid_vect_1_0;
    output              arready_1_0;
    input [3:0]         ar_qv_1_0;
   
    // Read Channel
    output [7:0]        rid_1_0;
    output [63:0]       rdata_1_0;
    output [1:0]        rresp_1_0;
    output              rlast_1_0;
    output              rvalid_1_0;
    input               rready_1_0;


    // Connects SlaveInterface 1  to Master Interface 1)

    // Write Address Channel
    input  [7:0]        awid_1_1;
    input  [31:0]       awaddr_1_1;
    input  [7:0]        awlen_1_1;
    input  [2:0]        awsize_1_1;
    input  [1:0]        awburst_1_1;
    input               awlock_1_1;
    input  [3:0]        awcache_1_1;
    input  [2:0]        awprot_1_1;
    input               awvalid_1_1;
    input               awvalid_vect_1_1;
    output              awready_1_1;
    input [3:0]         aw_qv_1_1;
   
    // Write Channel
    input [63:0]        wdata_1_1;
    input [7:0]         wstrb_1_1;   
    input               wlast_1_1;
    input               wvalid_1_1;
    output              wready_1_1;

    // Write Response Channel
    output [7:0]        bid_1_1;
    output [1:0]        bresp_1_1;
    output              bvalid_1_1;
    input               bready_1_1;  

    // Read Address Channel
    input  [7:0]        arid_1_1;
    input  [31:0]       araddr_1_1;
    input  [7:0]        arlen_1_1;
    input  [2:0]        arsize_1_1;
    input  [1:0]        arburst_1_1;
    input               arlock_1_1;
    input  [3:0]        arcache_1_1;
    input  [2:0]        arprot_1_1;
    input               arvalid_1_1;
    input               arvalid_vect_1_1;
    output              arready_1_1;
    input [3:0]         ar_qv_1_1;
   
    // Read Channel
    output [7:0]        rid_1_1;
    output [63:0]       rdata_1_1;
    output [1:0]        rresp_1_1;
    output              rlast_1_1;
    output              rvalid_1_1;
    input               rready_1_1;


    // Connects SlaveInterface 1  to Master Interface 2)

    // Write Address Channel
    input  [7:0]        awid_1_2;
    input  [31:0]       awaddr_1_2;
    input  [7:0]        awlen_1_2;
    input  [2:0]        awsize_1_2;
    input  [1:0]        awburst_1_2;
    input               awlock_1_2;
    input  [3:0]        awcache_1_2;
    input  [2:0]        awprot_1_2;
    input               awvalid_1_2;
    input               awvalid_vect_1_2;
    output              awready_1_2;
    input [3:0]         aw_qv_1_2;
   
    // Write Channel
    input [63:0]        wdata_1_2;
    input [7:0]         wstrb_1_2;   
    input               wlast_1_2;
    input               wvalid_1_2;
    output              wready_1_2;

    // Write Response Channel
    output [7:0]        bid_1_2;
    output [1:0]        bresp_1_2;
    output              bvalid_1_2;
    input               bready_1_2;  

    // Read Address Channel
    input  [7:0]        arid_1_2;
    input  [31:0]       araddr_1_2;
    input  [7:0]        arlen_1_2;
    input  [2:0]        arsize_1_2;
    input  [1:0]        arburst_1_2;
    input               arlock_1_2;
    input  [3:0]        arcache_1_2;
    input  [2:0]        arprot_1_2;
    input               arvalid_1_2;
    input               arvalid_vect_1_2;
    output              arready_1_2;
    input [3:0]         ar_qv_1_2;
   
    // Read Channel
    output [7:0]        rid_1_2;
    output [63:0]       rdata_1_2;
    output [1:0]        rresp_1_2;
    output              rlast_1_2;
    output              rvalid_1_2;
    input               rready_1_2;


    // Connects SlaveInterface 2  to Master Interface 0)

    // Write Address Channel
    input  [7:0]        awid_2_0;
    input  [31:0]       awaddr_2_0;
    input  [7:0]        awlen_2_0;
    input  [2:0]        awsize_2_0;
    input  [1:0]        awburst_2_0;
    input               awlock_2_0;
    input  [3:0]        awcache_2_0;
    input  [2:0]        awprot_2_0;
    input               awvalid_2_0;
    input               awvalid_vect_2_0;
    output              awready_2_0;
    input [3:0]         aw_qv_2_0;
   
    // Write Channel
    input [63:0]        wdata_2_0;
    input [7:0]         wstrb_2_0;   
    input               wlast_2_0;
    input               wvalid_2_0;
    output              wready_2_0;

    // Write Response Channel
    output [7:0]        bid_2_0;
    output [1:0]        bresp_2_0;
    output              bvalid_2_0;
    input               bready_2_0;  

    // Read Address Channel
    input  [7:0]        arid_2_0;
    input  [31:0]       araddr_2_0;
    input  [7:0]        arlen_2_0;
    input  [2:0]        arsize_2_0;
    input  [1:0]        arburst_2_0;
    input               arlock_2_0;
    input  [3:0]        arcache_2_0;
    input  [2:0]        arprot_2_0;
    input               arvalid_2_0;
    input               arvalid_vect_2_0;
    output              arready_2_0;
    input [3:0]         ar_qv_2_0;
   
    // Read Channel
    output [7:0]        rid_2_0;
    output [63:0]       rdata_2_0;
    output [1:0]        rresp_2_0;
    output              rlast_2_0;
    output              rvalid_2_0;
    input               rready_2_0;


    // Connects SlaveInterface 2  to Master Interface 1)

    // Write Address Channel
    input  [7:0]        awid_2_1;
    input  [31:0]       awaddr_2_1;
    input  [7:0]        awlen_2_1;
    input  [2:0]        awsize_2_1;
    input  [1:0]        awburst_2_1;
    input               awlock_2_1;
    input  [3:0]        awcache_2_1;
    input  [2:0]        awprot_2_1;
    input               awvalid_2_1;
    input               awvalid_vect_2_1;
    output              awready_2_1;
    input [3:0]         aw_qv_2_1;
   
    // Write Channel
    input [63:0]        wdata_2_1;
    input [7:0]         wstrb_2_1;   
    input               wlast_2_1;
    input               wvalid_2_1;
    output              wready_2_1;

    // Write Response Channel
    output [7:0]        bid_2_1;
    output [1:0]        bresp_2_1;
    output              bvalid_2_1;
    input               bready_2_1;  

    // Read Address Channel
    input  [7:0]        arid_2_1;
    input  [31:0]       araddr_2_1;
    input  [7:0]        arlen_2_1;
    input  [2:0]        arsize_2_1;
    input  [1:0]        arburst_2_1;
    input               arlock_2_1;
    input  [3:0]        arcache_2_1;
    input  [2:0]        arprot_2_1;
    input               arvalid_2_1;
    input               arvalid_vect_2_1;
    output              arready_2_1;
    input [3:0]         ar_qv_2_1;
   
    // Read Channel
    output [7:0]        rid_2_1;
    output [63:0]       rdata_2_1;
    output [1:0]        rresp_2_1;
    output              rlast_2_1;
    output              rvalid_2_1;
    input               rready_2_1;


    // Connects SlaveInterface 2  to Master Interface 2)

    // Write Address Channel
    input  [7:0]        awid_2_2;
    input  [31:0]       awaddr_2_2;
    input  [7:0]        awlen_2_2;
    input  [2:0]        awsize_2_2;
    input  [1:0]        awburst_2_2;
    input               awlock_2_2;
    input  [3:0]        awcache_2_2;
    input  [2:0]        awprot_2_2;
    input               awvalid_2_2;
    input               awvalid_vect_2_2;
    output              awready_2_2;
    input [3:0]         aw_qv_2_2;
   
    // Write Channel
    input [63:0]        wdata_2_2;
    input [7:0]         wstrb_2_2;   
    input               wlast_2_2;
    input               wvalid_2_2;
    output              wready_2_2;

    // Write Response Channel
    output [7:0]        bid_2_2;
    output [1:0]        bresp_2_2;
    output              bvalid_2_2;
    input               bready_2_2;  

    // Read Address Channel
    input  [7:0]        arid_2_2;
    input  [31:0]       araddr_2_2;
    input  [7:0]        arlen_2_2;
    input  [2:0]        arsize_2_2;
    input  [1:0]        arburst_2_2;
    input               arlock_2_2;
    input  [3:0]        arcache_2_2;
    input  [2:0]        arprot_2_2;
    input               arvalid_2_2;
    input               arvalid_vect_2_2;
    output              arready_2_2;
    input [3:0]         ar_qv_2_2;
   
    // Read Channel
    output [7:0]        rid_2_2;
    output [63:0]       rdata_2_2;
    output [1:0]        rresp_2_2;
    output              rlast_2_2;
    output              rvalid_2_2;
    input               rready_2_2;


  // Miscelaneous connections
    input               aclk;
    input               aresetn;

  // ---------------------------------------------------------------------------
  // Wires
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------


nic400_bm0_ml_mlayer_0_1 u_nic400_bm0_ml_mlayer0_1 (
        // MasterInterface 0 (connects to Master axi_m_0)
        // Write Address Channel
        .awid_m         (awid_m0),
        .awaddr_m       (awaddr_m0),
        .awlen_m        (awlen_m0),
        .awsize_m       (awsize_m0),
        .awburst_m      (awburst_m0),
        .awlock_m       (awlock_m0),
        .awcache_m      (awcache_m0),
        .awprot_m       (awprot_m0),
        .awvalid_m      (awvalid_m0),
        .awvalid_vect_m (awvalid_vect_m0),
        .awready_m      (awready_m0),
        .aw_qv_m        (aw_qv_m0),
   
        // Write Channel
        .wdata_m        (wdata_m0),
        .wstrb_m        (wstrb_m0),   
        .wlast_m        (wlast_m0),
        .wvalid_m       (wvalid_m0),
        .wready_m       (wready_m0),

        // Write Response Channel
        .bid_m          (bid_m0),
        .bresp_m        (bresp_m0),
        .bvalid_m       (bvalid_m0),
        .bready_m       (bready_m0),  

        // Read Address Channel
        .arid_m         (arid_m0),
        .araddr_m       (araddr_m0),
        .arlen_m        (arlen_m0),
        .arsize_m       (arsize_m0),
        .arburst_m      (arburst_m0),
        .arlock_m       (arlock_m0),
        .arcache_m      (arcache_m0),
        .arprot_m       (arprot_m0),
        .arvalid_m      (arvalid_m0),
        .arvalid_vect_m (arvalid_vect_m0),
        .arready_m      (arready_m0),
        .ar_qv_m        (ar_qv_m0),
   
        // Read Channel
        .rid_m          (rid_m0),
        .rdata_m        (rdata_m0),
        .rresp_m        (rresp_m0),
        .rlast_m        (rlast_m0),
        .rvalid_m       (rvalid_m0),
        .rready_m       (rready_m0),

    // Connects SlaveInterface 0  to Master Interface 0)
    // Write Address Channel
        .awid_s0         (awid_0_0),
        .awaddr_s0       (awaddr_0_0),
        .awlen_s0        (awlen_0_0),
        .awsize_s0       (awsize_0_0),
        .awburst_s0      (awburst_0_0),
        .awlock_s0       (awlock_0_0),
        .awcache_s0      (awcache_0_0),
        .awprot_s0       (awprot_0_0),
        .awvalid_s0      (awvalid_0_0),
        .awvalid_vect_s0 (awvalid_vect_0_0),
        .awready_s0      (awready_0_0),
        .aw_qv_s0        (aw_qv_0_0),
   
        // Write Channel
        .wdata_s0        (wdata_0_0),
        .wstrb_s0        (wstrb_0_0),   
        .wlast_s0        (wlast_0_0),
        .wvalid_s0       (wvalid_0_0),
        .wready_s0       (wready_0_0),

        // Write Response Channel
        .bid_s0          (bid_0_0),
        .bresp_s0        (bresp_0_0),
        .bvalid_s0       (bvalid_0_0),
        .bready_s0       (bready_0_0),  

        // Read Address Channel
        .arid_s0         (arid_0_0),
        .araddr_s0       (araddr_0_0),
        .arlen_s0        (arlen_0_0),
        .arsize_s0       (arsize_0_0),
        .arburst_s0      (arburst_0_0),
        .arlock_s0       (arlock_0_0),
        .arcache_s0      (arcache_0_0),
        .arprot_s0       (arprot_0_0),
        .arvalid_s0      (arvalid_0_0),
        .arvalid_vect_s0 (arvalid_vect_0_0),
        .arready_s0      (arready_0_0),
        .ar_qv_s0        (ar_qv_0_0),
   
        // Read Channel
        .rid_s0          (rid_0_0),
        .rdata_s0        (rdata_0_0),
        .rresp_s0        (rresp_0_0),
        .rlast_s0        (rlast_0_0),
        .rvalid_s0       (rvalid_0_0),
        .rready_s0       (rready_0_0),


    // Connects SlaveInterface 1  to Master Interface 0)
    // Write Address Channel
        .awid_s1         (awid_1_0),
        .awaddr_s1       (awaddr_1_0),
        .awlen_s1        (awlen_1_0),
        .awsize_s1       (awsize_1_0),
        .awburst_s1      (awburst_1_0),
        .awlock_s1       (awlock_1_0),
        .awcache_s1      (awcache_1_0),
        .awprot_s1       (awprot_1_0),
        .awvalid_s1      (awvalid_1_0),
        .awvalid_vect_s1 (awvalid_vect_1_0),
        .awready_s1      (awready_1_0),
        .aw_qv_s1        (aw_qv_1_0),
   
        // Write Channel
        .wdata_s1        (wdata_1_0),
        .wstrb_s1        (wstrb_1_0),   
        .wlast_s1        (wlast_1_0),
        .wvalid_s1       (wvalid_1_0),
        .wready_s1       (wready_1_0),

        // Write Response Channel
        .bid_s1          (bid_1_0),
        .bresp_s1        (bresp_1_0),
        .bvalid_s1       (bvalid_1_0),
        .bready_s1       (bready_1_0),  

        // Read Address Channel
        .arid_s1         (arid_1_0),
        .araddr_s1       (araddr_1_0),
        .arlen_s1        (arlen_1_0),
        .arsize_s1       (arsize_1_0),
        .arburst_s1      (arburst_1_0),
        .arlock_s1       (arlock_1_0),
        .arcache_s1      (arcache_1_0),
        .arprot_s1       (arprot_1_0),
        .arvalid_s1      (arvalid_1_0),
        .arvalid_vect_s1 (arvalid_vect_1_0),
        .arready_s1      (arready_1_0),
        .ar_qv_s1        (ar_qv_1_0),
   
        // Read Channel
        .rid_s1          (rid_1_0),
        .rdata_s1        (rdata_1_0),
        .rresp_s1        (rresp_1_0),
        .rlast_s1        (rlast_1_0),
        .rvalid_s1       (rvalid_1_0),
        .rready_s1       (rready_1_0),


    // Connects SlaveInterface 2  to Master Interface 0)
    // Write Address Channel
        .awid_s2         (awid_2_0),
        .awaddr_s2       (awaddr_2_0),
        .awlen_s2        (awlen_2_0),
        .awsize_s2       (awsize_2_0),
        .awburst_s2      (awburst_2_0),
        .awlock_s2       (awlock_2_0),
        .awcache_s2      (awcache_2_0),
        .awprot_s2       (awprot_2_0),
        .awvalid_s2      (awvalid_2_0),
        .awvalid_vect_s2 (awvalid_vect_2_0),
        .awready_s2      (awready_2_0),
        .aw_qv_s2        (aw_qv_2_0),
   
        // Write Channel
        .wdata_s2        (wdata_2_0),
        .wstrb_s2        (wstrb_2_0),   
        .wlast_s2        (wlast_2_0),
        .wvalid_s2       (wvalid_2_0),
        .wready_s2       (wready_2_0),

        // Write Response Channel
        .bid_s2          (bid_2_0),
        .bresp_s2        (bresp_2_0),
        .bvalid_s2       (bvalid_2_0),
        .bready_s2       (bready_2_0),  

        // Read Address Channel
        .arid_s2         (arid_2_0),
        .araddr_s2       (araddr_2_0),
        .arlen_s2        (arlen_2_0),
        .arsize_s2       (arsize_2_0),
        .arburst_s2      (arburst_2_0),
        .arlock_s2       (arlock_2_0),
        .arcache_s2      (arcache_2_0),
        .arprot_s2       (arprot_2_0),
        .arvalid_s2      (arvalid_2_0),
        .arvalid_vect_s2 (arvalid_vect_2_0),
        .arready_s2      (arready_2_0),
        .ar_qv_s2        (ar_qv_2_0),
   
        // Read Channel
        .rid_s2          (rid_2_0),
        .rdata_s2        (rdata_2_0),
        .rresp_s2        (rresp_2_0),
        .rlast_s2        (rlast_2_0),
        .rvalid_s2       (rvalid_2_0),
        .rready_s2       (rready_2_0),


        // Miscelaneous connections
        .aclk       (aclk),
        .aresetn    (aresetn)
  ); 

nic400_bm0_ml_mlayer_1_1 u_nic400_bm0_ml_mlayer1_1 (
        // MasterInterface 1 (connects to Master axi_m_1)
        // Write Address Channel
        .awid_m         (awid_m1),
        .awaddr_m       (awaddr_m1),
        .awlen_m        (awlen_m1),
        .awsize_m       (awsize_m1),
        .awburst_m      (awburst_m1),
        .awlock_m       (awlock_m1),
        .awcache_m      (awcache_m1),
        .awprot_m       (awprot_m1),
        .awvalid_m      (awvalid_m1),
        .awvalid_vect_m (awvalid_vect_m1),
        .awready_m      (awready_m1),
        .aw_qv_m        (aw_qv_m1),
   
        // Write Channel
        .wdata_m        (wdata_m1),
        .wstrb_m        (wstrb_m1),   
        .wlast_m        (wlast_m1),
        .wvalid_m       (wvalid_m1),
        .wready_m       (wready_m1),

        // Write Response Channel
        .bid_m          (bid_m1),
        .bresp_m        (bresp_m1),
        .bvalid_m       (bvalid_m1),
        .bready_m       (bready_m1),  

        // Read Address Channel
        .arid_m         (arid_m1),
        .araddr_m       (araddr_m1),
        .arlen_m        (arlen_m1),
        .arsize_m       (arsize_m1),
        .arburst_m      (arburst_m1),
        .arlock_m       (arlock_m1),
        .arcache_m      (arcache_m1),
        .arprot_m       (arprot_m1),
        .arvalid_m      (arvalid_m1),
        .arvalid_vect_m (arvalid_vect_m1),
        .arready_m      (arready_m1),
        .ar_qv_m        (ar_qv_m1),
   
        // Read Channel
        .rid_m          (rid_m1),
        .rdata_m        (rdata_m1),
        .rresp_m        (rresp_m1),
        .rlast_m        (rlast_m1),
        .rvalid_m       (rvalid_m1),
        .rready_m       (rready_m1),

    // Connects SlaveInterface 0  to Master Interface 1)
    // Write Address Channel
        .awid_s0         (awid_0_1),
        .awaddr_s0       (awaddr_0_1),
        .awlen_s0        (awlen_0_1),
        .awsize_s0       (awsize_0_1),
        .awburst_s0      (awburst_0_1),
        .awlock_s0       (awlock_0_1),
        .awcache_s0      (awcache_0_1),
        .awprot_s0       (awprot_0_1),
        .awvalid_s0      (awvalid_0_1),
        .awvalid_vect_s0 (awvalid_vect_0_1),
        .awready_s0      (awready_0_1),
        .aw_qv_s0        (aw_qv_0_1),
   
        // Write Channel
        .wdata_s0        (wdata_0_1),
        .wstrb_s0        (wstrb_0_1),   
        .wlast_s0        (wlast_0_1),
        .wvalid_s0       (wvalid_0_1),
        .wready_s0       (wready_0_1),

        // Write Response Channel
        .bid_s0          (bid_0_1),
        .bresp_s0        (bresp_0_1),
        .bvalid_s0       (bvalid_0_1),
        .bready_s0       (bready_0_1),  

        // Read Address Channel
        .arid_s0         (arid_0_1),
        .araddr_s0       (araddr_0_1),
        .arlen_s0        (arlen_0_1),
        .arsize_s0       (arsize_0_1),
        .arburst_s0      (arburst_0_1),
        .arlock_s0       (arlock_0_1),
        .arcache_s0      (arcache_0_1),
        .arprot_s0       (arprot_0_1),
        .arvalid_s0      (arvalid_0_1),
        .arvalid_vect_s0 (arvalid_vect_0_1),
        .arready_s0      (arready_0_1),
        .ar_qv_s0        (ar_qv_0_1),
   
        // Read Channel
        .rid_s0          (rid_0_1),
        .rdata_s0        (rdata_0_1),
        .rresp_s0        (rresp_0_1),
        .rlast_s0        (rlast_0_1),
        .rvalid_s0       (rvalid_0_1),
        .rready_s0       (rready_0_1),


    // Connects SlaveInterface 1  to Master Interface 1)
    // Write Address Channel
        .awid_s1         (awid_1_1),
        .awaddr_s1       (awaddr_1_1),
        .awlen_s1        (awlen_1_1),
        .awsize_s1       (awsize_1_1),
        .awburst_s1      (awburst_1_1),
        .awlock_s1       (awlock_1_1),
        .awcache_s1      (awcache_1_1),
        .awprot_s1       (awprot_1_1),
        .awvalid_s1      (awvalid_1_1),
        .awvalid_vect_s1 (awvalid_vect_1_1),
        .awready_s1      (awready_1_1),
        .aw_qv_s1        (aw_qv_1_1),
   
        // Write Channel
        .wdata_s1        (wdata_1_1),
        .wstrb_s1        (wstrb_1_1),   
        .wlast_s1        (wlast_1_1),
        .wvalid_s1       (wvalid_1_1),
        .wready_s1       (wready_1_1),

        // Write Response Channel
        .bid_s1          (bid_1_1),
        .bresp_s1        (bresp_1_1),
        .bvalid_s1       (bvalid_1_1),
        .bready_s1       (bready_1_1),  

        // Read Address Channel
        .arid_s1         (arid_1_1),
        .araddr_s1       (araddr_1_1),
        .arlen_s1        (arlen_1_1),
        .arsize_s1       (arsize_1_1),
        .arburst_s1      (arburst_1_1),
        .arlock_s1       (arlock_1_1),
        .arcache_s1      (arcache_1_1),
        .arprot_s1       (arprot_1_1),
        .arvalid_s1      (arvalid_1_1),
        .arvalid_vect_s1 (arvalid_vect_1_1),
        .arready_s1      (arready_1_1),
        .ar_qv_s1        (ar_qv_1_1),
   
        // Read Channel
        .rid_s1          (rid_1_1),
        .rdata_s1        (rdata_1_1),
        .rresp_s1        (rresp_1_1),
        .rlast_s1        (rlast_1_1),
        .rvalid_s1       (rvalid_1_1),
        .rready_s1       (rready_1_1),


    // Connects SlaveInterface 2  to Master Interface 1)
    // Write Address Channel
        .awid_s2         (awid_2_1),
        .awaddr_s2       (awaddr_2_1),
        .awlen_s2        (awlen_2_1),
        .awsize_s2       (awsize_2_1),
        .awburst_s2      (awburst_2_1),
        .awlock_s2       (awlock_2_1),
        .awcache_s2      (awcache_2_1),
        .awprot_s2       (awprot_2_1),
        .awvalid_s2      (awvalid_2_1),
        .awvalid_vect_s2 (awvalid_vect_2_1),
        .awready_s2      (awready_2_1),
        .aw_qv_s2        (aw_qv_2_1),
   
        // Write Channel
        .wdata_s2        (wdata_2_1),
        .wstrb_s2        (wstrb_2_1),   
        .wlast_s2        (wlast_2_1),
        .wvalid_s2       (wvalid_2_1),
        .wready_s2       (wready_2_1),

        // Write Response Channel
        .bid_s2          (bid_2_1),
        .bresp_s2        (bresp_2_1),
        .bvalid_s2       (bvalid_2_1),
        .bready_s2       (bready_2_1),  

        // Read Address Channel
        .arid_s2         (arid_2_1),
        .araddr_s2       (araddr_2_1),
        .arlen_s2        (arlen_2_1),
        .arsize_s2       (arsize_2_1),
        .arburst_s2      (arburst_2_1),
        .arlock_s2       (arlock_2_1),
        .arcache_s2      (arcache_2_1),
        .arprot_s2       (arprot_2_1),
        .arvalid_s2      (arvalid_2_1),
        .arvalid_vect_s2 (arvalid_vect_2_1),
        .arready_s2      (arready_2_1),
        .ar_qv_s2        (ar_qv_2_1),
   
        // Read Channel
        .rid_s2          (rid_2_1),
        .rdata_s2        (rdata_2_1),
        .rresp_s2        (rresp_2_1),
        .rlast_s2        (rlast_2_1),
        .rvalid_s2       (rvalid_2_1),
        .rready_s2       (rready_2_1),


        // Miscelaneous connections
        .aclk       (aclk),
        .aresetn    (aresetn)
  ); 

nic400_bm0_ml_mlayer_2_1 u_nic400_bm0_ml_mlayer2_1 (
        // MasterInterface 2 (connects to Master axi_m_2)
        // Write Address Channel
        .awid_m         (awid_m2),
        .awaddr_m       (awaddr_m2),
        .awlen_m        (awlen_m2),
        .awsize_m       (awsize_m2),
        .awburst_m      (awburst_m2),
        .awlock_m       (awlock_m2),
        .awcache_m      (awcache_m2),
        .awprot_m       (awprot_m2),
        .awvalid_m      (awvalid_m2),
        .awvalid_vect_m (awvalid_vect_m2),
        .awready_m      (awready_m2),
        .aw_qv_m        (aw_qv_m2),
   
        // Write Channel
        .wdata_m        (wdata_m2),
        .wstrb_m        (wstrb_m2),   
        .wlast_m        (wlast_m2),
        .wvalid_m       (wvalid_m2),
        .wready_m       (wready_m2),

        // Write Response Channel
        .bid_m          (bid_m2),
        .bresp_m        (bresp_m2),
        .bvalid_m       (bvalid_m2),
        .bready_m       (bready_m2),  

        // Read Address Channel
        .arid_m         (arid_m2),
        .araddr_m       (araddr_m2),
        .arlen_m        (arlen_m2),
        .arsize_m       (arsize_m2),
        .arburst_m      (arburst_m2),
        .arlock_m       (arlock_m2),
        .arcache_m      (arcache_m2),
        .arprot_m       (arprot_m2),
        .arvalid_m      (arvalid_m2),
        .arvalid_vect_m (arvalid_vect_m2),
        .arready_m      (arready_m2),
        .ar_qv_m        (ar_qv_m2),
   
        // Read Channel
        .rid_m          (rid_m2),
        .rdata_m        (rdata_m2),
        .rresp_m        (rresp_m2),
        .rlast_m        (rlast_m2),
        .rvalid_m       (rvalid_m2),
        .rready_m       (rready_m2),

    // Connects SlaveInterface 0  to Master Interface 2)
    // Write Address Channel
        .awid_s0         (awid_0_2),
        .awaddr_s0       (awaddr_0_2),
        .awlen_s0        (awlen_0_2),
        .awsize_s0       (awsize_0_2),
        .awburst_s0      (awburst_0_2),
        .awlock_s0       (awlock_0_2),
        .awcache_s0      (awcache_0_2),
        .awprot_s0       (awprot_0_2),
        .awvalid_s0      (awvalid_0_2),
        .awvalid_vect_s0 (awvalid_vect_0_2),
        .awready_s0      (awready_0_2),
        .aw_qv_s0        (aw_qv_0_2),
   
        // Write Channel
        .wdata_s0        (wdata_0_2),
        .wstrb_s0        (wstrb_0_2),   
        .wlast_s0        (wlast_0_2),
        .wvalid_s0       (wvalid_0_2),
        .wready_s0       (wready_0_2),

        // Write Response Channel
        .bid_s0          (bid_0_2),
        .bresp_s0        (bresp_0_2),
        .bvalid_s0       (bvalid_0_2),
        .bready_s0       (bready_0_2),  

        // Read Address Channel
        .arid_s0         (arid_0_2),
        .araddr_s0       (araddr_0_2),
        .arlen_s0        (arlen_0_2),
        .arsize_s0       (arsize_0_2),
        .arburst_s0      (arburst_0_2),
        .arlock_s0       (arlock_0_2),
        .arcache_s0      (arcache_0_2),
        .arprot_s0       (arprot_0_2),
        .arvalid_s0      (arvalid_0_2),
        .arvalid_vect_s0 (arvalid_vect_0_2),
        .arready_s0      (arready_0_2),
        .ar_qv_s0        (ar_qv_0_2),
   
        // Read Channel
        .rid_s0          (rid_0_2),
        .rdata_s0        (rdata_0_2),
        .rresp_s0        (rresp_0_2),
        .rlast_s0        (rlast_0_2),
        .rvalid_s0       (rvalid_0_2),
        .rready_s0       (rready_0_2),


    // Connects SlaveInterface 1  to Master Interface 2)
    // Write Address Channel
        .awid_s1         (awid_1_2),
        .awaddr_s1       (awaddr_1_2),
        .awlen_s1        (awlen_1_2),
        .awsize_s1       (awsize_1_2),
        .awburst_s1      (awburst_1_2),
        .awlock_s1       (awlock_1_2),
        .awcache_s1      (awcache_1_2),
        .awprot_s1       (awprot_1_2),
        .awvalid_s1      (awvalid_1_2),
        .awvalid_vect_s1 (awvalid_vect_1_2),
        .awready_s1      (awready_1_2),
        .aw_qv_s1        (aw_qv_1_2),
   
        // Write Channel
        .wdata_s1        (wdata_1_2),
        .wstrb_s1        (wstrb_1_2),   
        .wlast_s1        (wlast_1_2),
        .wvalid_s1       (wvalid_1_2),
        .wready_s1       (wready_1_2),

        // Write Response Channel
        .bid_s1          (bid_1_2),
        .bresp_s1        (bresp_1_2),
        .bvalid_s1       (bvalid_1_2),
        .bready_s1       (bready_1_2),  

        // Read Address Channel
        .arid_s1         (arid_1_2),
        .araddr_s1       (araddr_1_2),
        .arlen_s1        (arlen_1_2),
        .arsize_s1       (arsize_1_2),
        .arburst_s1      (arburst_1_2),
        .arlock_s1       (arlock_1_2),
        .arcache_s1      (arcache_1_2),
        .arprot_s1       (arprot_1_2),
        .arvalid_s1      (arvalid_1_2),
        .arvalid_vect_s1 (arvalid_vect_1_2),
        .arready_s1      (arready_1_2),
        .ar_qv_s1        (ar_qv_1_2),
   
        // Read Channel
        .rid_s1          (rid_1_2),
        .rdata_s1        (rdata_1_2),
        .rresp_s1        (rresp_1_2),
        .rlast_s1        (rlast_1_2),
        .rvalid_s1       (rvalid_1_2),
        .rready_s1       (rready_1_2),


    // Connects SlaveInterface 2  to Master Interface 2)
    // Write Address Channel
        .awid_s2         (awid_2_2),
        .awaddr_s2       (awaddr_2_2),
        .awlen_s2        (awlen_2_2),
        .awsize_s2       (awsize_2_2),
        .awburst_s2      (awburst_2_2),
        .awlock_s2       (awlock_2_2),
        .awcache_s2      (awcache_2_2),
        .awprot_s2       (awprot_2_2),
        .awvalid_s2      (awvalid_2_2),
        .awvalid_vect_s2 (awvalid_vect_2_2),
        .awready_s2      (awready_2_2),
        .aw_qv_s2        (aw_qv_2_2),
   
        // Write Channel
        .wdata_s2        (wdata_2_2),
        .wstrb_s2        (wstrb_2_2),   
        .wlast_s2        (wlast_2_2),
        .wvalid_s2       (wvalid_2_2),
        .wready_s2       (wready_2_2),

        // Write Response Channel
        .bid_s2          (bid_2_2),
        .bresp_s2        (bresp_2_2),
        .bvalid_s2       (bvalid_2_2),
        .bready_s2       (bready_2_2),  

        // Read Address Channel
        .arid_s2         (arid_2_2),
        .araddr_s2       (araddr_2_2),
        .arlen_s2        (arlen_2_2),
        .arsize_s2       (arsize_2_2),
        .arburst_s2      (arburst_2_2),
        .arlock_s2       (arlock_2_2),
        .arcache_s2      (arcache_2_2),
        .arprot_s2       (arprot_2_2),
        .arvalid_s2      (arvalid_2_2),
        .arvalid_vect_s2 (arvalid_vect_2_2),
        .arready_s2      (arready_2_2),
        .ar_qv_s2        (ar_qv_2_2),
   
        // Read Channel
        .rid_s2          (rid_2_2),
        .rdata_s2        (rdata_2_2),
        .rresp_s2        (rresp_2_2),
        .rlast_s2        (rlast_2_2),
        .rvalid_s2       (rvalid_2_2),
        .rready_s2       (rready_2_2),


        // Miscelaneous connections
        .aclk       (aclk),
        .aresetn    (aresetn)
  ); 




  endmodule

//  --=============================== End ====================================--

