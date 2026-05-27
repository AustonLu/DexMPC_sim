

// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2006-2012 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 134903
//
// Date                   :  2012-08-08 22:10:42 +0100 (Wed, 08 Aug 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC400 axi slave interface
//
// Description : This block is a parameterisable AXI-APB bridge with
//               built in AXI master
//
//
// --========================================================================--

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module config_if (

                 // Global signals
                 PCLK,
                 PRESETn,

                 //EMIT/WAIT channels .. only used in FRM mode
                 EMIT_DATA,
                 EMIT_REQ,
                 EMIT_ACK,

                 WAIT_DATA,
                 WAIT_REQ,
                 WAIT_ACK,

                 

                 // APB3 Interface
                 PENABLE,
                 PWRITE,
                 PADDR,
                 PWDATA,

                PSEL_1,
                PREADY_1,
                PSLVERR_1,
                PRDATA_1,
              
                PSEL_2,
                PREADY_2,
                PSLVERR_2,
                PRDATA_2,
              
                PSEL_3,
                PREADY_3,
                PSLVERR_3,
                PRDATA_3,
              
                PSEL_4,
                PREADY_4,
                PSLVERR_4,
                PRDATA_4,
              
                PSEL_5,
                PREADY_5,
                PSLVERR_5,
                PRDATA_5,
              
                 PSEL,
                 PREADY,
                 PSLVERR,
                 PRDATA


);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter PORTS            = 6;
  parameter EW_WIDTH         = 8;
  parameter ID_WIDTH         = 8;
  parameter MAX_PORT         = PORTS - 1;
  parameter EW_MAX           = EW_WIDTH - 1;
  parameter ID_MAX           = ID_WIDTH - 1;
  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter AXI_DATA_MAX     = DATA_MAX;
  parameter AXI_STRB_MAX     = STRB_MAX;

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  // Clock and Reset in AXI domain
  input                     PCLK;            // AXI Bus Clock
  input                     PRESETn;         // AXI system level reset active low
  

  // APB3 Interface
  output                     PENABLE;         // APB Enable
  output                     PWRITE;          // APB transfer(R/W) direction
  output [31:0]              PADDR;           // APB address
  output [31:0]              PWDATA;          // APB write data
  input                      PREADY;          // APB transfer completion signal for slaves
  input                      PSLVERR;         // APB transfer response signal for slaves
  input [31:0]               PRDATA;          // APB read data for slave0
  output                     PSEL;

  output                     PSEL_1;
  input                      PREADY_1;
  input                      PSLVERR_1;
  input [31:0]               PRDATA_1;
              
  output                     PSEL_2;
  input                      PREADY_2;
  input                      PSLVERR_2;
  input [31:0]               PRDATA_2;
              
  output                     PSEL_3;
  input                      PREADY_3;
  input                      PSLVERR_3;
  input [31:0]               PRDATA_3;
              
  output                     PSEL_4;
  input                      PREADY_4;
  input                      PSLVERR_4;
  input [31:0]               PRDATA_4;
              
  output                     PSEL_5;
  input                      PREADY_5;
  input                      PSLVERR_5;
  input [31:0]               PRDATA_5;
              

  //Emit and Wait channels only used in FRM mode
  output [EW_MAX:0]          EMIT_DATA;       //Emit data
  output                     EMIT_REQ;        //Emit Request
  input                      EMIT_ACK;        //Emit acknoledgement

  input  [EW_MAX:0]          WAIT_DATA;       //Wait data
  input                      WAIT_REQ;        //Wait Request
  output                     WAIT_ACK;        //Waitr acknoledgement

  


// -----------------------------------------------------------------------------
// Signal Declarations
// -----------------------------------------------------------------------------

  // Signals
  // Connections for CONFIG AXI slave
  wire       [7:0] AWID_config;
  wire      [31:0] AWADDR_config;
  wire       [7:0] AWUSER_config;
  wire       [3:0] AWLEN_config;
  wire       [2:0] AWSIZE_config;
  wire       [1:0] AWBURST_config;
  wire       [2:0] AWPROT_config;
  wire             AWVALID_config;
  wire             AWREADY_config;
  wire       [3:0] AWCACHE_config;
  wire       [1:0] AWLOCK_config;

  // AXI Write data channel
  wire            [7:0] WID_config;
  wire [AXI_DATA_MAX:0] WDATA_config;
  wire [AXI_STRB_MAX:0] WSTRB_config;
  wire                  WLAST_config;
  wire                  WVALID_config;
  wire                  WREADY_config;

    // AXI Write completion channel
  wire        [7:0] BID_config;
  wire        [1:0] BRESP_config;
  wire              BVALID_config;
  wire              BREADY_config;

  // AXI Read Address channel
  wire       [7:0] ARID_config;
  wire      [31:0] ARADDR_config;
  wire       [7:0] ARUSER_config;
  wire       [3:0] ARLEN_config;
  wire       [2:0] ARSIZE_config;
  wire       [1:0] ARBURST_config;
  wire       [2:0] ARPROT_config;
  wire             ARVALID_config;
  wire             ARREADY_config;
  wire       [3:0] ARCACHE_config;
  wire       [1:0] ARLOCK_config;

    // AXI Read data channel
  wire            [7:0] RID_config;
  wire [AXI_DATA_MAX:0] RDATA_config;
  wire            [1:0] RRESP_config;
  wire                  RLAST_config;
  wire                  RVALID_config;
  wire                  RREADY_config;

  //Combined signals going into the bridge
  wire [MAX_PORT:0]  PSEL_all;
  wire [31:0]        PRDATA_all;
  wire [MAX_PORT:0]  PREADY_all;
  wire [MAX_PORT:0]  PSLVERR_all;

  wire              AWVALID_apb;
  wire              AWREADY_apb;
  wire              ARVALID_apb;
  wire              ARREADY_apb;
  wire              WVALID_apb;
  wire              WREADY_apb;

  wire        [7:0] BID_apb;
  wire        [1:0] BRESP_apb;
  wire              BVALID_apb;
  wire              BREADY_apb;

  // AXI Read data channel
  wire        [7:0] RID_apb;
  wire       [31:0] RDATA_apb;
  wire        [1:0] RRESP_apb;
  wire              RLAST_apb;
  wire              RVALID_apb;
  wire              RREADY_apb;

  wire       [31:0] WDATA_apb;

  

  assign   AWVALID_apb    = AWVALID_config;
  assign   AWREADY_config = AWREADY_apb;
  assign   ARVALID_apb    = ARVALID_config;
  assign   ARREADY_config = ARREADY_apb;
  assign   WVALID_apb     = WVALID_config;
  assign   WREADY_config  = WREADY_apb;
  assign   WDATA_apb      = WDATA_config;

  // AXI BID data channel
  assign   BID_config = BID_apb;
  assign   BRESP_config = BRESP_apb;
  assign   BVALID_config = BVALID_apb;
  assign   BREADY_apb = BREADY_config;

  // AXI Read data channel
  assign   RID_config = RID_apb;
  assign   RDATA_config = RDATA_apb;
  assign   RRESP_config = RRESP_apb;
  assign   RLAST_config = RLAST_apb;
  assign   RVALID_config = RVALID_apb;
  assign   RREADY_apb = RREADY_config;

`ifdef SN
//------------------------------------------------------------------------------
// AXI XVC Master
//------------------------------------------------------------------------------
   defparam uAximMaster_config.DATA_WIDTH     = AXI_DATA_MAX + 1;
   defparam uAximMaster_config.ID_WIDTH       = 8;

   defparam uAximMaster_config.AWUSER_WIDTH   = 8;
   defparam uAximMaster_config.WUSER_WIDTH    = 1;
   defparam uAximMaster_config.BUSER_WIDTH    = 1;
   defparam uAximMaster_config.ARUSER_WIDTH   = 8;
   defparam uAximMaster_config.RUSER_WIDTH    = 1;

  AxiMasterXvc uAximMaster_config (
      .ACLK         (PCLK),
      .ARESETn      (PRESETn),

      .AWVALID      (AWVALID_config),
      .AWREADY      (AWREADY_config),
      .AWID         (AWID_config),
      .AWADDR       (AWADDR_config),
      .AWLEN        (AWLEN_config),
      .AWSIZE       (AWSIZE_config),
      .AWBURST      (AWBURST_config),
      .AWLOCK       (AWLOCK_config),
      .AWCACHE      (AWCACHE_config),
      .AWPROT       (AWPROT_config),

      .WVALID       (WVALID_config),
      .WREADY       (WREADY_config),
      .WID          (WID_config),
      .WDATA        (WDATA_config),
      .WSTRB        (WSTRB_config),
      .WLAST        (WLAST_config),

      .BVALID       (BVALID_config),
      .BREADY       (BREADY_config),
      .BID          (BID_config),
      .BRESP        (BRESP_config),

      .ARVALID      (ARVALID_config),
      .ARREADY      (ARREADY_config),
      .ARID         (ARID_config),
      .ARADDR       (ARADDR_config),
      .ARLEN        (ARLEN_config),
      .ARSIZE       (ARSIZE_config),
      .ARBURST      (ARBURST_config),
      .ARLOCK       (ARLOCK_config),
      .ARCACHE      (ARCACHE_config),
      .ARPROT       (ARPROT_config),

      .RVALID       (RVALID_config),
      .RREADY       (RREADY_config),
      .RID          (RID_config),
      .RDATA        (RDATA_config),
      .RRESP        (RRESP_config),
      .RLAST        (RLAST_config),

      .AWUSER       (AWUSER_config),
      .WUSER        (),
      .BUSER        (1'b0),
      .ARUSER       (ARUSER_config),
      .RUSER        (1'b0)
  );

  // When using specman tie-off the unused Event buses
  assign  EMIT_REQ   = 1'b0;
  assign  EMIT_DATA  = {EW_WIDTH{1'b0}};
  assign  WAIT_ACK   = 1'b0;

`else
//------------------------------------------------------------------------------
// AXI File Reader Master
//------------------------------------------------------------------------------

   defparam uAximMaster_config.DATA_WIDTH     = AXI_DATA_MAX + 1;
   defparam uAximMaster_config.ID_WIDTH       = 8;

   defparam uAximMaster_config.AWUSER_WIDTH   = 8;
   defparam uAximMaster_config.WUSER_WIDTH    = 1;
   defparam uAximMaster_config.BUSER_WIDTH    = 1;
   defparam uAximMaster_config.ARUSER_WIDTH   = 8;
   defparam uAximMaster_config.RUSER_WIDTH    = 1;

   defparam uAximMaster_config.AW_ARRAY_SIZE     = 35000;             // Size of AW channel array
   defparam uAximMaster_config.W_ARRAY_SIZE      = 40000;             // Size of W channel array
   defparam uAximMaster_config.AR_ARRAY_SIZE     = 35000;             // Size of AR channel array
   defparam uAximMaster_config.R_ARRAY_SIZE      = 40000;             // Size of R channel array
   defparam uAximMaster_config.AWMSG_ARRAY_SIZE  = 35000;             // Size of AW comments array
   defparam uAximMaster_config.ARMSG_ARRAY_SIZE  = 35000;             // Size of AR comments array

   defparam uAximMaster_config.STIM_FILE_NAME  = "AXIM_config";

   defparam uAximMaster_config.MESSAGE_TAG     = "FileReader";       // Message prefix
   defparam uAximMaster_config.VERBOSE         = 1;                  // Verbosity control
   defparam uAximMaster_config.USE_X           = 1;                  // Drive X on invalid signals
   defparam uAximMaster_config.EW_WIDTH        = EW_WIDTH;           // Width of the Emit & wait bus
   defparam uAximMaster_config.ADDR_WIDTH      = 32;                 // Addr width

  FileRdMasterAxi uAximMaster_config (
      .ACLK         (PCLK),
      .ARESETn      (PRESETn),

      .AWVALID      (AWVALID_config),
      .AWREADY      (AWREADY_config),
      .AWID         (AWID_config),
      .AWADDR       (AWADDR_config),
      .AWLEN        (AWLEN_config),
      .AWSIZE       (AWSIZE_config),
      .AWBURST      (AWBURST_config),
      .AWLOCK       (AWLOCK_config),
      .AWCACHE      (AWCACHE_config),
      .AWPROT       (AWPROT_config),

      .WVALID       (WVALID_config),
      .WREADY       (WREADY_config),
      .WID          (WID_config),
      .WDATA        (WDATA_config),
      .WSTRB        (WSTRB_config),
      .WLAST        (WLAST_config),

      .BVALID       (BVALID_config),
      .BREADY       (BREADY_config),
      .BID          (BID_config),
      .BRESP        (BRESP_config),

      .ARVALID      (ARVALID_config),
      .ARREADY      (ARREADY_config),
      .ARID         (ARID_config),
      .ARADDR       (ARADDR_config),
      .ARLEN        (ARLEN_config),
      .ARSIZE       (ARSIZE_config),
      .ARBURST      (ARBURST_config),
      .ARLOCK       (ARLOCK_config),
      .ARCACHE      (ARCACHE_config),
      .ARPROT       (ARPROT_config),

       //Connect FRM signals the the AXIM XVC doesn;t have
      .CSYSREQ      (1'b1),
      .CACTIVE      (),
      .CSYSACK      (),

      .EMIT_DATA    (EMIT_DATA),
      .EMIT_REQ     (EMIT_REQ),
      .EMIT_ACK     (EMIT_ACK),

      .WAIT_DATA    (WAIT_DATA),
      .WAIT_REQ     (WAIT_REQ),
      .WAIT_ACK     (WAIT_ACK),

      .AWUSER       (AWUSER_config),
      .WUSER        (),
      .BUSER        (1'b0),
      .ARUSER       (ARUSER_config),
      .RUSER        (1'b0),

      

      .RVALID       (RVALID_config),
      .RREADY       (RREADY_config),
      .RID          (RID_config),
      .RDATA        (RDATA_config),
      .RRESP        (RRESP_config),
      .RLAST        (RLAST_config)
  );
`endif

//------------------------------------------------------------------------------
// AXI_to_APB bridge
// NB to simplify the bridge and testbench all Testbench APB components have
// their PRDATA connected together ... Hence when not selected all components
// must drive their RDATA line to Z not 0
//------------------------------------------------------------------------------

  AxiToApb u_AxiToApb
  (
    // Global signals
      .ACLK         (PCLK),
      .ARESETn      (PRESETn),

      // Read Address Channel
      .ARID         (ARID_config),
      .ARADDR       (ARADDR_config),
      .ARUSER       (ARUSER_config),
      .ARLEN        (ARLEN_config),
      .ARSIZE       (ARSIZE_config),
      .ARBURST      (ARBURST_config),
      .ARPROT       (ARPROT_config),
      .ARVALID      (ARVALID_apb),
      .ARREADY      (ARREADY_apb),

      // Read Channel
      .RID          (RID_apb),
      .RDATA        (RDATA_apb),
      .RRESP        (RRESP_apb),
      .RLAST        (RLAST_apb),
      .RVALID       (RVALID_apb),
      .RREADY       (RREADY_apb),

      // Write Address Channel
      .AWID         (AWID_config),
      .AWADDR       (AWADDR_config),
      .AWUSER       (AWUSER_config),
      .AWLEN        (AWLEN_config),
      .AWSIZE       (AWSIZE_config),
      .AWBURST      (AWBURST_config),
      .AWPROT       (AWPROT_config),
      .AWVALID      (AWVALID_apb),
      .AWREADY      (AWREADY_apb),

      // Write Channel
      .WDATA        (WDATA_apb),
      .WLAST        (WLAST_config),
      .WVALID       (WVALID_apb),
      .WREADY       (WREADY_apb),


      // Write Response Channel
      .BID          (BID_apb),
      .BRESP        (BRESP_apb),
      .BVALID       (BVALID_apb),
      .BREADY       (BREADY_apb),

      // APB3 Interface
      .PSELS        (PSEL_all),
      .PENABLE      (PENABLE),
      .PWRITE       (PWRITE),
      .PADDR        (PADDR),
      .PWDATA       (PWDATA),
      .PREADYS      (PREADY_all),
      .PSLVERRS     (PSLVERR_all),
      .PRDATA       (PRDATA_all),
      .PCLKENS      ({{5{1'b1}},1'b1})
   );

defparam u_AxiToApb.PORTS    = PORTS;

//Separate the input signals
assign PSEL = PSEL_all[0];
assign PSEL_1 = PSEL_all[1];
               
assign PSEL_2 = PSEL_all[2];
               
assign PSEL_3 = PSEL_all[3];
               
assign PSEL_4 = PSEL_all[4];
               
assign PSEL_5 = PSEL_all[5];
               

assign PRDATA_all = (PSEL_1) ? PRDATA_1 : (PSEL_2) ? PRDATA_2 : (PSEL_3) ? PRDATA_3 : (PSEL_4) ? PRDATA_4 : (PSEL_5) ? PRDATA_5 : 
                    PRDATA;

assign PSLVERR_all[0] = PSLVERR;
assign PREADY_all[0]  = PREADY;
assign PSLVERR_all[1] = PSLVERR_1;
assign PREADY_all[1] = PREADY_1;
 
assign PSLVERR_all[2] = PSLVERR_2;
assign PREADY_all[2] = PREADY_2;
 
assign PSLVERR_all[3] = PSLVERR_3;
assign PREADY_all[3] = PREADY_3;
 
assign PSLVERR_all[4] = PSLVERR_4;
assign PREADY_all[4] = PREADY_4;
 
assign PSLVERR_all[5] = PSLVERR_5;
assign PREADY_all[5] = PREADY_5;
 


endmodule

//  --=============================== End ====================================--
