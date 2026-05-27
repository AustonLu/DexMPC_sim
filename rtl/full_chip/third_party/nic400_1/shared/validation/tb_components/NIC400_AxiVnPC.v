//============================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2011-2012 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 127485
//
// Date                   :  2012-03-21 21:09:28 +0000 (Wed, 21 Mar 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             : Wrapper for AXI3 VN Protocol Checker using OVL
//============================================================================--


`timescale 1ns/1ns

module NIC400_AxiVnPC
  (
   // Global Signals
   ACLK,
   ARESETn,

   // Write Address Channel
   AWVALID_VECT,
   AWVALID,
   AWID,
   AWREADY,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
   AWREGION,
   AWQV,
   AWUSER,

   // Write Channel
   WVALID,
   WREADY,
   WID,
   WLAST,
   WDATA,
   WSTRB,
   WUSER,

   // Write Response Channel
   BVALID,
   BREADY,
   BID,
   BRESP,
   BUSER,

   // Read Address Channel
   ARVALID_VECT,
   ARVALID,
   ARREADY,
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
   ARREGION,
   ARQV,
   ARUSER,

   // Read Channel
   RID,
   RLAST,
   RDATA,
   RRESP,
   RUSER,
   RVALID,
   RREADY,

   // Low power interface
   CACTIVE,
   CSYSREQ,
   CSYSACK,

   //vnet sideband signals
   AWVNET,
   ARVNET,
   WVNET

   );


//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------


  // Parameters below can be set by the user.
  // ========================================

  parameter VALID_WIDTH = 1;

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH = 64;         // data bus width, default = 64-bit

  // Select the number of channel ID bits required
  parameter ID_WIDTH = 4;          // (A|W|R|B)ID width

  // Select the size of the USER buses, default = 32-bit
  parameter AWUSER_WIDTH = 32; // width of the user AW sideband field
  parameter WUSER_WIDTH  = 32; // width of the user W  sideband field
  parameter BUSER_WIDTH  = 32; // width of the user B  sideband field
  parameter ARUSER_WIDTH = 32; // width of the user AR sideband field
  parameter RUSER_WIDTH  = 32; // width of the user R  sideband field

  // Write-interleave Depth of monitored slave interface
  parameter WDEPTH = 1;

  // Size of CAMs for storing outstanding read bursts, this should match or
  // exceed the number of outstanding read addresses accepted into the slave
  // interface
  parameter MAXRBURSTS = 16;

  // Size of CAMs for storing outstanding write bursts, this should match or
  // exceed the number of outstanding write bursts into the slave  interface
  parameter MAXWBURSTS = 16;

  // Maximum number of cycles between VALID -> READY high before a warning is
  // generated
  parameter MAXWAITS = 16;

  // OVL instances property_type parameter (0=assert, 1=assume, 2=ignore)
  parameter AXI_ERRM_PropertyType = 0; // default: assert Master is AXI compliant
  parameter AXI_RECM_PropertyType = 0; // default: assert Master is AXI compliant
  parameter AXI_AUXM_PropertyType = 0; // default: assert Master auxiliary logic checks
  //
  parameter AXI_ERRS_PropertyType = 0; // default: assert Slave is AXI compliant
  parameter AXI_RECS_PropertyType = 0; // default: assert Slave is AXI compliant
  parameter AXI_AUXS_PropertyType = 0; // default: assert Slave auxiliary logic checks
  //
  parameter AXI_ERRL_PropertyType = 0; // default: assert LP Int is AXI compliant

  // Recommended Rules Enable
  parameter RecommendOn   = 1'b1;   // enable/disable reporting of all  AXI_REC*_* rules
  parameter RecMaxWaitOn  = 1'b1;   // enable/disable reporting of just AXI_REC*_MAX_WAIT rules

  // Set ADDR_WIDTH to the address-bus width required
  parameter ADDR_WIDTH = 32;         // address bus width, default = 32-bit

  // Set EXMON_WIDTH to the exclusive access monitor width required
  parameter EXMON_WIDTH = 8;         // exclusive access width, default = 4-bit

  // Default VNET encodings
  parameter NUM_VNETS  = 1;
  parameter VN0_VNET   = 4'b0000;
  parameter VN1_VNET   = 4'b0000;
  parameter VN2_VNET   = 4'b0000;
  parameter VN3_VNET   = 4'b0000;

  //Parameters
  parameter LockOverride      = 1'b0;
  parameter AllowLeadingRdata = 1'b0;

  //Specify that this is an internal port
  parameter PortIsInternal = 0;

  // Calculated (user should not override)
  // =====================================
  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  parameter AWUSER_WIDTH_I = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
  parameter ARUSER_WIDTH_I = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
  parameter WUSER_WIDTH_I  = (WUSER_WIDTH == 0)  ? 1 : WUSER_WIDTH;
  parameter RUSER_WIDTH_I  = (RUSER_WIDTH == 0)  ? 1 : RUSER_WIDTH;
  parameter BUSER_WIDTH_I  = (BUSER_WIDTH == 0)  ? 1 : BUSER_WIDTH;
  parameter ID_WIDTH_I     = (ID_WIDTH == 0)     ? 1 : ID_WIDTH;

  parameter VALID_MAX  = VALID_WIDTH-1;
  parameter DATA_MAX   = DATA_WIDTH-1; // data max index
  parameter ADDR_MAX   = ADDR_WIDTH-1; // address max index
  parameter STRB_WIDTH = DATA_WIDTH/8; // WSTRB width
  parameter STRB_MAX   = STRB_WIDTH-1; // WSTRB max index
  parameter STRB_1     = {{STRB_MAX{1'b0}}, 1'b1};  // value 1 in strobe width
  parameter ID_MAX     = ID_WIDTH-1;   // ID max index
  parameter EXMON_MAX  = EXMON_WIDTH-1;       // EXMON max index
  parameter EXMON_HI   = {EXMON_WIDTH{1'b1}}; // EXMON max value

  parameter AWUSER_MAX = AWUSER_WIDTH_I-1; // AWUSER max index
  parameter WUSER_MAX =  WUSER_WIDTH_I-1; // WUSER  max index
  parameter BUSER_MAX =  BUSER_WIDTH_I-1; // BUSER  max index
  parameter ARUSER_MAX = ARUSER_WIDTH_I-1; // ARUSER max index
  parameter RUSER_MAX =  RUSER_WIDTH_I-1; // RUSER  max index

  parameter MAX_ID   = {ID_WIDTH{1'b1}};      // max ID value
  parameter NUM_ID   = {1'b1,{ID_WIDTH{1'b0}}}; // number of ID values

  parameter INT_NUM_VNETS = NUM_VNETS + 1;

//------------------------------------------------------------------------------
// Inputs (no outputs)
//------------------------------------------------------------------------------


  // Global Signals
  // =====
  input                ACLK;        // AXI Clock
  input                ARESETn;     // AXI Reset


  // Write Address Channel
  // =====
  input  [VALID_MAX:0] AWVALID_VECT;
  input                AWVALID;
  input                AWREADY;
  input     [ID_MAX:0] AWID;
  input   [ADDR_MAX:0] AWADDR;
  input          [3:0] AWLEN;
  input          [2:0] AWSIZE;
  input          [1:0] AWBURST;
  input          [3:0] AWCACHE;
  input          [1:0] AWLOCK;
  input          [2:0] AWPROT;
  input          [3:0] AWREGION;
  input          [3:0] AWQV;
  input [AWUSER_MAX:0] AWUSER;


  // Write Data Channel
  // =====
  input     [ID_MAX:0] WID;
  input   [DATA_MAX:0] WDATA;
  input   [STRB_MAX:0] WSTRB;
  input  [WUSER_MAX:0] WUSER;
  input                WLAST;
  input                WVALID;
  input                WREADY;


  // Write Response Channel
  // =====
  input                BVALID;
  input                BREADY;
  input     [ID_MAX:0] BID;
  input          [1:0] BRESP;
  input  [BUSER_MAX:0] BUSER;


  // Read Address Channel
  // =====
  input  [VALID_MAX:0] ARVALID_VECT;
  input                ARVALID;
  input                ARREADY;
  input     [ID_MAX:0] ARID;
  input   [ADDR_MAX:0] ARADDR;
  input          [3:0] ARLEN;
  input          [2:0] ARSIZE;
  input          [1:0] ARBURST;
  input          [3:0] ARCACHE;
  input          [1:0] ARLOCK;
  input          [2:0] ARPROT;
  input          [3:0] ARREGION;
  input          [3:0] ARQV;
  input [ARUSER_MAX:0] ARUSER;


  // Read Data Channel
  // =====
  input                RVALID;
  input                RREADY;
  input     [ID_MAX:0] RID;
  input                RLAST;
  input   [DATA_MAX:0] RDATA;
  input          [1:0] RRESP;
  input  [RUSER_MAX:0] RUSER;

  // Low Power Interface
  // =====
  input                CACTIVE;
  input                CSYSREQ;
  input                CSYSACK;

   //vnet sideband signals
  input          [3:0] AWVNET;
  input          [3:0] ARVNET;
  input          [3:0] WVNET;

//----------------------------------------------------------------------------
// Wires
//----------------------------------------------------------------------------
  wire           [3:0] VNETS [0:4];
  genvar               VNET;

  wire [3:0]           VNET_0 = (NUM_VNETS == 0) ? 0 : VN0_VNET;
  wire [3:0]           VNET_1 = (NUM_VNETS <= 1) ? 0 : VN1_VNET;
  wire [3:0]           VNET_2 = (NUM_VNETS <= 2) ? 0 : VN2_VNET;
  wire [3:0]           VNET_3 = (NUM_VNETS <= 3) ? 0 : VN3_VNET;
  wire [3:0]           VNET_COUNT = NUM_VNETS;

  wire [INT_NUM_VNETS-1:0]   AWVALID_idmon;
  wire [INT_NUM_VNETS-1:0]   WVALID_idmon;
  wire [INT_NUM_VNETS-1:0]   BVALID_idmon;
  wire [INT_NUM_VNETS-1:0]   ARVALID_idmon;
  wire [INT_NUM_VNETS-1:0]   RVALID_idmon;

// ---------------------------------------------------------------------------
//  start of code
// ---------------------------------------------------------------------------

defparam u_VnIDMon.ID_WIDTH   = ID_WIDTH;
defparam u_VnIDMon.NUM_VNETS  = INT_NUM_VNETS;
defparam u_VnIDMon.VNET_0     = (NUM_VNETS == 0) ? 0 : VN0_VNET;
defparam u_VnIDMon.VNET_1     = (NUM_VNETS <= 1) ? 0 : VN1_VNET;
defparam u_VnIDMon.VNET_2     = (NUM_VNETS <= 2) ? 0 : VN2_VNET;
defparam u_VnIDMon.VNET_3     = (NUM_VNETS <= 3) ? 0 : VN3_VNET;
defparam u_VnIDMon.VNET_4     = 0;
defparam u_VnIDMon.AXI4_N_3   = 0;
defparam u_VnIDMon.MAXWBURSTS = MAXWBURSTS;
defparam u_VnIDMon.MAXRBURSTS = MAXRBURSTS;

VnIDMonitor u_VnIDMon (

   // AXI AW Channel Signals
   .AWVALID(AWVALID),
   .AWREADY(AWREADY),
   .AWID(AWID),
   .AWVNET(AWVNET),
   .AWVALIDo(AWVALID_idmon),
   .AWREADYo(AWREADY_idmon),

   // AXI W Channel Signals
   .WVALID(WVALID),
   .WREADY(WREADY),
   .WVNET(WVNET),
   .WLAST(WLAST),
   .WID(WID),
   .WVALIDo(WVALID_idmon),
   .WREADYo(),

   // AXI AR Channel Signals
   .ARVALID(ARVALID),
   .ARREADY(ARREADY),
   .ARID(ARID),
   .ARVNET(ARVNET),
   .ARVALIDo(ARVALID_idmon),
   .ARREADYo(ARREADY_idmon),

   //Bchannel
   .BVALID(BVALID),
   .BREADY(BREADY),
   .BID(BID),
   .BVALIDo(BVALID_idmon),

   //Rchannnel
   .RVALID(RVALID),
   .RREADY(RREADY),
   .RLAST(RLAST),
   .RID(RID),
   .RVALIDo(RVALID_idmon),

   // Global Signals
   .ACLK(~ACLK),
   .ARESETn(ARESETn)

);


  //VNET assignments
  assign VNETS[0] = VNET_0;
  assign VNETS[1] = VNET_1;
  assign VNETS[2] = VNET_2;
  assign VNETS[3] = VNET_3;
  assign VNETS[4] = 4'b0000;

  //Instaniate the Protocol Checks
  generate

     for (VNET=0; VNET < INT_NUM_VNETS; VNET++) begin : PC

        defparam uAxiPC.VALID_WIDTH           = VALID_WIDTH;
        defparam uAxiPC.DATA_WIDTH            = DATA_WIDTH;
        defparam uAxiPC.ID_WIDTH              = ID_WIDTH;
        defparam uAxiPC.AWUSER_WIDTH          = AWUSER_WIDTH;
        defparam uAxiPC.WUSER_WIDTH           = WUSER_WIDTH;
        defparam uAxiPC.BUSER_WIDTH           = BUSER_WIDTH;
        defparam uAxiPC.ARUSER_WIDTH          = ARUSER_WIDTH;
        defparam uAxiPC.RUSER_WIDTH           = RUSER_WIDTH;
        defparam uAxiPC.MAXRBURSTS            = MAXRBURSTS;
        defparam uAxiPC.MAXWBURSTS            = MAXWBURSTS;
        defparam uAxiPC.MAXWAITS              = MAXWAITS;
        defparam uAxiPC.AXI_ERRM_PropertyType = AXI_ERRM_PropertyType;
        defparam uAxiPC.AXI_RECM_PropertyType = AXI_RECM_PropertyType;
        defparam uAxiPC.AXI_AUXM_PropertyType = AXI_AUXM_PropertyType;
        defparam uAxiPC.AXI_ERRS_PropertyType = AXI_ERRS_PropertyType;
        defparam uAxiPC.AXI_RECS_PropertyType = AXI_RECS_PropertyType;
        defparam uAxiPC.AXI_AUXS_PropertyType = AXI_AUXS_PropertyType;
        defparam uAxiPC.AXI_ERRL_PropertyType = AXI_ERRL_PropertyType;
        defparam uAxiPC.RecommendOn           = RecommendOn;
        defparam uAxiPC.RecMaxWaitOn          = RecMaxWaitOn;
        defparam uAxiPC.ADDR_WIDTH            = ADDR_WIDTH;
        defparam uAxiPC.EXMON_WIDTH           = EXMON_WIDTH;
        defparam uAxiPC.LockOverride          = LockOverride;
        defparam uAxiPC.AllowLeadingRdata     = AllowLeadingRdata;

        //Determine if this is the selected port
        wire AWVALID_vn_match = (AWVALID_idmon[VNET]);
        wire WVALID_vn_match  = (WVALID_idmon[VNET]);
        wire BVALID_vn_match  = (BVALID_idmon[VNET]);
        wire ARVALID_vn_match = (ARVALID_idmon[VNET]);
        wire RVALID_vn_match  = (RVALID_idmon[VNET]);

        PL301_AxiPC uAxiPC (

            .ACLK           (ACLK),
            .ARESETn        (ARESETn),

            .AWVALID_VECT   (AWVALID_VECT),
            .AWVALID        (AWVALID_vn_match),
            .AWREADY        (AWREADY),
            .AWID           (AWID),
            .AWADDR         (AWADDR),
            .AWLEN          (AWLEN),
            .AWSIZE         (AWSIZE),
            .AWBURST        (AWBURST),
            .AWLOCK         (AWLOCK),
            .AWCACHE        (AWCACHE),
            .AWPROT         (AWPROT),
            .AWREGION       (AWREGION),
            .AWQV           (AWQV),
            .AWUSER         (AWUSER),

            .WVALID         (WVALID_vn_match),
            .WREADY         (WREADY),
            .WID            (WID),
            .WLAST          (WLAST),
            .WDATA          (WDATA),
            .WSTRB          (WSTRB),
            .WUSER          (WUSER),

            .BVALID         (BVALID_vn_match),
            .BREADY         (BREADY),
            .BID            (BID),
            .BRESP          (BRESP),
            .BUSER          (BUSER),

            .ARVALID_VECT   (ARVALID_VECT),
            .ARVALID        (ARVALID_vn_match),
            .ARREADY        (ARREADY),
            .ARID           (ARID),
            .ARADDR         (ARADDR),
            .ARLEN          (ARLEN),
            .ARSIZE         (ARSIZE),
            .ARBURST        (ARBURST),
            .ARLOCK         (ARLOCK),
            .ARCACHE        (ARCACHE),
            .ARPROT         (ARPROT),
            .ARREGION       (ARREGION),
            .ARQV           (ARQV),
            .ARUSER         (ARUSER),

            .RVALID         (RVALID_vn_match),
            .RREADY         (RREADY),
            .RID            (RID),
            .RLAST          (RLAST),
            .RDATA          (RDATA),
            .RRESP          (RRESP),
            .RUSER          (RUSER),

            .CACTIVE        (CACTIVE),
            .CSYSREQ        (CSYSREQ),
            .CSYSACK        (CSYSACK)
      );
  end
endgenerate

`ifdef ARM_ASSERT_ON

  //------------------------------------------------------------------------------------
  // OVL_ASSERT: Oustanding write transactions with the same ID must be on the same VNET
  //------------------------------------------------------------------------------------
  // OVL_ASSERT_RTL
//   assert_implication #(1, 0, "ERROR, Oustanding write transactions with the same ID must be on the same VNET")
//     ovl_write_id_same_vnet
//      (
//       .clk             (~ACLK),
//       .reset_n         (ARESETn),
//       .antecedent_expr (aw_push),
//       .consequent_expr ((bid_vnet[AWID] == AWVNET) | (awid_count[AWID] == 6'b0))
//     );

  //-----------------------------------------------------------------------------------
  // OVL_ASSERT: Oustanding read transactions with the same ID must be on the same VNET
  //-----------------------------------------------------------------------------------
  // OVL_ASSERT_RTL
//   assert_implication #(1, 0, "ERROR, Oustanding read transactions with the same ID must be on the same VNET")
//     ovl_read_id_same_vnet
//      (
//       .clk             (~ACLK),
//       .reset_n         (ARESETn),
//       .antecedent_expr (ar_push),
//       .consequent_expr ((rid_vnet[ARID] == ARVNET) | (arid_count[ARID] == 6'b0))
//     );

  //-----------------------------------------------------------------------------------
  // OVL_ASSERT: Transaction on unrecognised VN
  //-----------------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  //assert_implication #(1, 0, "ERROR, AW transaction on unrecognised VNET")
  //  ovl_illegal_aw_vnet
  //   (
  //    .clk             (~ACLK),
  //    .reset_n         (ARESETn),
  //    .antecedent_expr (AWVALID),
  //    .consequent_expr ( (AWVNET == VNETS[0]) || NUM_VNETS == 0 ||
  //                      ((AWVNET == VNETS[1]) && NUM_VNETS > 1) ||
  //                      ((AWVNET == VNETS[2]) && NUM_VNETS > 2) ||
  //                      ((AWVNET == VNETS[3]) && NUM_VNETS > 3))
  //  );

  // assert_implication #(1, 0, "ERROR, W transaction on unrecognised VNET")
  //  ovl_illegal_w_vnet
  //   (
  //    .clk             (~ACLK),
  //    .reset_n         (ARESETn),
  //    .antecedent_expr (WVALID),
  //    .consequent_expr ( (WVNET == VNETS[0]) || NUM_VNETS == 0 ||
  //                      ((WVNET == VNETS[1]) && NUM_VNETS > 1) ||
  //                      ((WVNET == VNETS[2]) && NUM_VNETS > 2) ||
  //                      ((WVNET == VNETS[3]) && NUM_VNETS > 3))
  //  );

//    assert_implication #(1, 0, "ERROR, B transaction on unrecognised VNET")
//     ovl_illegal_b_vnet
//      (
//       .clk             (~ACLK),
//       .reset_n         (ARESETn),
//       .antecedent_expr (BVALID),
//       .consequent_expr ( (BVNET == VNETS[0]) || NUM_VNETS == 0 ||
//                         ((BVNET == VNETS[1]) && NUM_VNETS > 1) ||
//                         ((BVNET == VNETS[2]) && NUM_VNETS > 2) ||
//                         ((BVNET == VNETS[3]) && NUM_VNETS > 3))
//     );
//   assert_implication #(1, 0, "ERROR, AR transaction on unrecognised VNET")
//    ovl_illegal_ar_vnet
//     (
//      .clk             (~ACLK),
//      .reset_n         (ARESETn),
//      .antecedent_expr (ARVALID),
//      .consequent_expr ( (ARVNET == VNETS[0]) || NUM_VNETS == 0 ||
//                        ((ARVNET == VNETS[1]) && NUM_VNETS > 1) ||
//                        ((ARVNET == VNETS[2]) && NUM_VNETS > 2) ||
//                        ((ARVNET == VNETS[3]) && NUM_VNETS > 3))
//    );

//    assert_implication #(1, 0, "ERROR, R transaction on unrecognised VNET")
//     ovl_illegal_r_vnet
//      (
//       .clk             (~ACLK),
//       .reset_n         (ARESETn),
//       .antecedent_expr (RVALID),
//       .consequent_expr ( (RVNET == VNETS[0]) || NUM_VNETS == 0 ||
//                         ((RVNET == VNETS[1]) && NUM_VNETS > 1) ||
//                         ((RVNET == VNETS[2]) && NUM_VNETS > 2) ||
//                         ((RVNET == VNETS[3]) && NUM_VNETS > 3))
//     );

`endif //ARM_ASSERT_ON


endmodule // Axi3VnPC
