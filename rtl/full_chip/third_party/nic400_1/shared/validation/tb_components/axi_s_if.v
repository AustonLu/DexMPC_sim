// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2006-2014 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 169640
//
// Date                   :  2014-03-24 16:36:37 +0000 (Mon, 24 Mar 2014)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : NIC401 axi slave interface
//
// Description : This block is an AXI slave that can be used in the main NIC401
//               testbench.
//
//               Currently contain an eXVC AXIS or FRS component
//
//               NIC401r0p0 uses AWQV, ARQV and multi-bit AW and ARValid. These are
//               deviations from standard AXI and are, therefore, not output from
//               standard AXI signals.
//
//               AxQV and the multibit are added to the top of the AxUSER signal
//               and passed intro the testcomponent for checking.
//
//               AxQV is passed as a 4 bit unchanged value. AxValid is converted
//               from a one-hot value to an 4bit value where 4'b0 => AxVALID[0]
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module axi_s_if(

                 // Global signals
                 ACLK,
                 ACLKEN,
                 ARESETn,

                 // Read Address Channel
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
                 ARQOS,
                 ARUSER,

                 // Read Channel
                 RVALID,
                 RREADY,
                 RID,
                 RLAST,
                 RDATA,
                 RRESP,
                 RUSER,

                 // Write Address Channel
                 AWVALID,
                 AWREADY,
                 AWID,
                 AWADDR,
                 AWLEN,
                 AWSIZE,
                 AWBURST,
                 AWLOCK,
                 AWCACHE,
                 AWPROT,
                 AWREGION,
                 AWQOS,
                 AWUSER,

                 // Write Channel
                 WID,
                 WLAST,
                 WSTRB,
                 WDATA,
                 WVALID,
                 WREADY,
                 WUSER,

                 // Write Response Channel
                 BID,
                 BRESP,
                 BVALID,
                 BREADY,
                 BUSER,

                 //EMIT/WAIT channels .. only used in FRM mode
                 EMIT_DATA,
                 EMIT_REQ,
                 EMIT_ACK,

                 WAIT_DATA,
                 WAIT_REQ,
                 WAIT_ACK,

                 // APB3 Interface
                 PCLK,
                 PRESETn,
                 PSEL,
                 PENABLE,
                 PWRITE,
                 PADDR,
                 PWDATA,
                 PREADY,
                 PSLVERR,
                 PRDATA

);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  parameter DATA_WIDTH       = 32;
  parameter STRB_WIDTH       = 4;
  parameter ADDR_WIDTH       = 32;
  parameter AWUSER_WIDTH     = 16;
  parameter ARUSER_WIDTH     = 16;
  parameter RUSER_WIDTH      = 16;
  parameter WUSER_WIDTH      = 16;
  parameter BUSER_WIDTH      = 16;
  parameter ID_WIDTH         = 16;
  parameter EW_WIDTH         = 16;

  parameter read_issuing_capability  = 16;
  parameter write_issuing_capability  = 16;
  parameter combined_issuing_capability  = 16;
  parameter limit_acceptance_capability  = 0;

  parameter leading_writes   = 32;

  //If limit_acceptance_capability is true then the FRM should limit the number of transactions
  //rather than letting the DMC do it.
  parameter AXIPC_READS      = (limit_acceptance_capability == 1) ?
                                read_issuing_capability + 10 : read_issuing_capability;
  parameter AXIPC_WRITES     = (limit_acceptance_capability == 1) ?
                                write_issuing_capability + 10 + 32: write_issuing_capability + 32;

  parameter INSTANCE         = "undef";
  parameter INSTANCE_TYPE    = "AXIS_";

  parameter AWUSER_WIDTH_I   = (AWUSER_WIDTH == 0) ? 1 : AWUSER_WIDTH;
  parameter ARUSER_WIDTH_I   = (ARUSER_WIDTH == 0) ? 1 : ARUSER_WIDTH;
  parameter WUSER_WIDTH_I    = (WUSER_WIDTH == 0) ? 1 : WUSER_WIDTH;
  parameter RUSER_WIDTH_I    = (RUSER_WIDTH == 0) ? 1 : RUSER_WIDTH;
  parameter BUSER_WIDTH_I    = (BUSER_WIDTH == 0) ? 1 : BUSER_WIDTH;
  parameter ID_WIDTH_I       = (ID_WIDTH == 0) ? 1 : ID_WIDTH;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = STRB_WIDTH - 1;
  parameter ADDR_MAX         = ADDR_WIDTH - 1;
  parameter ID_MAX           = ID_WIDTH_I - 1;
  parameter EW_MAX           = EW_WIDTH -1;
  parameter USER_MAX_AW      = AWUSER_WIDTH_I - 1;
  parameter USER_MAX_AR      = ARUSER_WIDTH_I - 1;
  parameter USER_MAX_R       = RUSER_WIDTH_I - 1;
  parameter USER_MAX_W       = WUSER_WIDTH_I - 1;
  parameter USER_MAX_B       = BUSER_WIDTH_I - 1;

  parameter regions_flag     = 0;

  parameter AllowLeadingRdata = 0;
  parameter AllowIllegalCache = 0;

  parameter DriveOnlyOnEnable = 0;
  parameter PortIsInternal    = 0;
  parameter USE_X             = 1;


// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

// Clock and Reset in AXI domain
input                   ACLK;            // AXI Bus Clock
input                   ACLKEN;          // AXI Bus Clock Enable
input                   ARESETn;         // AXI Reset

// Read Address Channel
input                   ARVALID;         // Read address valid
output                  ARREADY;         // Read address ready
input  [ID_MAX:0]       ARID;            // Read address ID
input  [ADDR_MAX:0]     ARADDR;          // Read address
input  [3:0]            ARLEN;           // Read burst length
input  [2:0]            ARSIZE;          // Read burst size
input  [1:0]            ARBURST;         // Read burst type
input  [3:0]            ARCACHE;         // Read cache information
input  [1:0]            ARLOCK;          // Read lock information
input  [2:0]            ARPROT;          // Read protection information
input  [3:0]            ARREGION;        // Read region signal
input  [3:0]            ARQOS;           // Read QV value
input  [USER_MAX_AR:0]  ARUSER;          // Read protection information

// Read Channel
output                  RVALID;          // Read response valid
input                   RREADY;          // Read response ready
output  [ID_MAX:0]      RID;             // Read data ID
output                  RLAST;           // Read last
output  [DATA_MAX:0]    RDATA;           // Read data
output  [1:0]           RRESP;           // Read response
output  [USER_MAX_R:0]  RUSER;           // Read protection information

// Write Address Channel
input                   AWVALID;         // Write address valid
output                  AWREADY;         // Write address ready
input  [ID_MAX:0]       AWID;            // Write address ID
input  [ADDR_MAX:0]     AWADDR;          // Write address
input  [3:0]            AWLEN;           // Write burst length
input  [3:0]            AWQOS;           // Write QV value
input  [3:0]            AWREGION;        // Write region signal
input  [2:0]            AWSIZE;          // Write burst size
input  [1:0]            AWBURST;         // Write burst type
input  [3:0]            AWCACHE;         // Write cache information
input  [1:0]            AWLOCK;          // Write lock information
input  [2:0]            AWPROT;          // Write protection information
input  [USER_MAX_AW:0]  AWUSER;          // Read protection information

// Write Channel
input                   WVALID;          // Write valid
output                  WREADY;          // Write ready
input  [ID_MAX:0]       WID;             // Wid
input                   WLAST;           // Write last
input  [STRB_MAX:0]     WSTRB;           // Write strobes
input  [DATA_MAX:0]     WDATA;           // Write data
input  [USER_MAX_W:0]   WUSER;           // Read protection information

// Write Response Channel
output                  BVALID;          // Write response valid
input                   BREADY;          // Write response ready
output  [ID_MAX:0]      BID;             // Write response ID
output  [1:0]           BRESP;           // Write response
output  [USER_MAX_B:0]  BUSER;           // Read protection information

//Emit and Wait channels only used in FRM mode
output [EW_MAX:0]       EMIT_DATA;       //Emit data
output                  EMIT_REQ;        //Emit Request
input                   EMIT_ACK;        //Emit acknoledgement

input  [EW_MAX:0]       WAIT_DATA;       //Wait data
input                   WAIT_REQ;        //Wait Request
output                  WAIT_ACK;        //Waitr acknoledgement

// APB3 Interface
input                   PENABLE;         // APB Enable
input                   PWRITE;          // APB transfer(R/W) direction
input  [31:0]           PADDR;           // APB address
input  [31:0]           PWDATA;          // APB write data
output                  PREADY;          // APB transfer completion signal for slaves
output                  PSLVERR;         // APB transfer response signal for slaves
output [31:0]           PRDATA;          // APB read data for slave0
input                   PSEL;

input                   PCLK;
input                   PRESETn;

// -----------------------------------------------------------------------------
//  Wire and Register Declarations
// -----------------------------------------------------------------------------

wire [3:0]               AWREGION_int;
wire [3:0]               ARREGION_int;

reg  [4:0]               VALID_prev;
reg  [4:0]               READY_prev;

wire [USER_MAX_AW+16:0]  AWUSER_int;
wire [USER_MAX_AR+16:0]  ARUSER_int;

wire [7:0]               ARVALID_int;
wire [7:0]               AWVALID_int;

wire [6:0]               next_out_reads;
wire [6:0]               next_out_writes;
reg  [6:0]               out_reads;
reg  [6:0]               out_writes;
reg                      error_v;
reg                      error_r;
reg                      PCLK_pulse;
reg                      ACLK_pulse;

wire  [ID_MAX:0]         RID_i;             // Read data ID
wire                     RLAST_i;           // Read last
wire  [DATA_MAX:0]       RDATA_i;           // Read data
wire  [1:0]              RRESP_i;           // Read response
wire  [USER_MAX_R:0]     RUSER_i;           // Read user field

wire  [ID_MAX:0]         BID_i;             // Write response ID
wire  [1:0]              BRESP_i;           // Write response
wire  [USER_MAX_B:0]     BUSER_i;           // Write response user field

wire                     ACLKENDEL;         // Delayed clock enable
wire                     ACLKPC;            // Clock for protocol checker

//------------------------------------------------------------------------------
// Output Wires
//------------------------------------------------------------------------------

  assign RID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : RID_i;
  assign RLAST = (DriveOnlyOnEnable & ~ACLKEN) ? 1'bx : RLAST_i;
  assign RDATA = (DriveOnlyOnEnable & ~ACLKEN) ? {DATA_WIDTH{1'bx}} : RDATA_i;
  assign RRESP = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : RRESP_i;
  assign RUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((RUSER_WIDTH_I == 1) ? 1'bx : {RUSER_WIDTH_I{1'bx}}) : RUSER_i;

  assign BID   = (DriveOnlyOnEnable & ~ACLKEN) ? ((ID_WIDTH_I == 1) ? 1'bx : {ID_WIDTH_I{1'bx}}) : BID_i;
  assign BRESP = (DriveOnlyOnEnable & ~ACLKEN) ? {2{1'bx}} : BRESP_i;
  assign BUSER = (DriveOnlyOnEnable & ~ACLKEN) ? ((BUSER_WIDTH_I == 1) ? 1'bx : {BUSER_WIDTH_I{1'bx}}) : BUSER_i;

`ifdef SN
//------------------------------------------------------------------------------
// XVC Slave - used with random tests
//------------------------------------------------------------------------------
  defparam uAxiSlave.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiSlave.ID_WIDTH       = ID_WIDTH_I;

  defparam uAxiSlave.AWUSER_WIDTH   = AWUSER_WIDTH_I;
  defparam uAxiSlave.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiSlave.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiSlave.ARUSER_WIDTH   = ARUSER_WIDTH_I;
  defparam uAxiSlave.RUSER_WIDTH    = RUSER_WIDTH_I;
  defparam uAxiSlave.ADDR_WIDTH     = ADDR_WIDTH;             

  Axi3pSlaveXvc uAxiSlave (
      .ACLK         (ACLK),
      .ARESETn      (ARESETn),

      .AWVALID      (AWVALID),
      .AWREADY      (AWREADY),
      .AWID         (AWID),
      .AWADDR       (AWADDR),
      .AWLEN        (AWLEN),
      .AWSIZE       (AWSIZE),
      .AWBURST      (AWBURST),
      .AWLOCK       (AWLOCK),
      .AWCACHE      (AWCACHE),
      .AWPROT       (AWPROT),
      .AWREGION     (AWREGION),
      .AWQV         (AWQOS),

      .WID          (WID),
      .WDATA        (WDATA),
      .WSTRB        (WSTRB),
      .WLAST        (WLAST),
      .WVALID       (WVALID),
      .WREADY       (WREADY),

      .BID          (BID_i),
      .BRESP        (BRESP_i),
      .BVALID       (BVALID),
      .BREADY       (BREADY),

      .ARVALID      (ARVALID),
      .ARREADY      (ARREADY),
      .ARID         (ARID),
      .ARADDR       (ARADDR),
      .ARLEN        (ARLEN),
      .ARSIZE       (ARSIZE),
      .ARBURST      (ARBURST),
      .ARLOCK       (ARLOCK),
      .ARCACHE      (ARCACHE),
      .ARPROT       (ARPROT),
      .ARREGION     (ARREGION),
      .ARQV         (ARQOS),

      .WUSER        (WUSER),
      .AWUSER       (AWUSER),
      .BUSER        (BUSER_i),
      .ARUSER       (ARUSER),
      .RUSER        (RUSER_i),

      .RID          (RID_i),
      .RDATA        (RDATA_i),
      .RRESP        (RRESP_i),
      .RLAST        (RLAST_i),
      .RVALID       (RVALID),
      .RREADY       (RREADY)
  );

  // When using specman tie-off the unused Event buses
  assign  EMIT_REQ   = 1'b0;
  assign  EMIT_DATA  = {EW_WIDTH{1'b0}};
  assign  WAIT_ACK   = 1'b0;

`else

//------------------------------------------------------------------------------
// FRM Slave - used with directed tests
//------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  // Encoding AxUSER
  //------------------------------------------------------------------------------
  assign AWREGION_int = (regions_flag == 0) ? 4'b0000 : AWREGION;
  assign ARREGION_int = (regions_flag == 0) ? 4'b0000 : ARREGION;

  assign AWVALID_int = 8'b0;
  assign ARVALID_int = 8'b0;

  assign AWUSER_int = {AWUSER, AWVALID_int, AWQOS, AWREGION_int};
  assign ARUSER_int = {ARUSER, ARVALID_int, ARQOS, ARREGION_int};

  defparam uAxiSlave.DATA_WIDTH     = DATA_WIDTH;
  defparam uAxiSlave.ID_WIDTH       = ID_WIDTH_I;

  defparam uAxiSlave.AWUSER_WIDTH   = AWUSER_WIDTH_I + 16;
  defparam uAxiSlave.WUSER_WIDTH    = WUSER_WIDTH_I;
  defparam uAxiSlave.BUSER_WIDTH    = BUSER_WIDTH_I;
  defparam uAxiSlave.ARUSER_WIDTH   = ARUSER_WIDTH_I + 16;
  defparam uAxiSlave.RUSER_WIDTH    = RUSER_WIDTH_I;
  defparam uAxiSlave.ADDR_WIDTH     = ADDR_WIDTH;             

  defparam uAxiSlave.AW_ARRAY_SIZE     = 10000;             // Size of AW channel array
  defparam uAxiSlave.W_ARRAY_SIZE      = 50000;             // Size of W channel array
  defparam uAxiSlave.AR_ARRAY_SIZE     = 10000;             // Size of AR channel array
  defparam uAxiSlave.R_ARRAY_SIZE      = 50000;             // Size of R channel array
  defparam uAxiSlave.AWMSG_ARRAY_SIZE  = 10000;             // Size of AW comments array
  defparam uAxiSlave.ARMSG_ARRAY_SIZE  = 10000;             // Size of AR comments array

  //The + 5 on these parameters prevents the test component from ever limiting the DUT
  defparam uAxiSlave.OUTSTANDING_WRITES = write_issuing_capability + 5;
  defparam uAxiSlave.OUTSTANDING_READS  = read_issuing_capability + 5;

  defparam uAxiSlave.STIM_FILE_NAME    = {INSTANCE_TYPE, INSTANCE};          //Name of the stimulus file

  defparam uAxiSlave.MESSAGE_TAG     = {"slave_", INSTANCE};       // Message prefix
  defparam uAxiSlave.VERBOSE         = 1;                  // Verbosity control
  defparam uAxiSlave.USE_X           = USE_X;                  // Drive X on invalid signals
  defparam uAxiSlave.EW_WIDTH        = EW_WIDTH;                  // Width of the Emit & wait bus
  defparam uAxiSlave.REQUIRE_AR_HNDSHK = (AllowLeadingRdata == 0);  // Width of the Emit & wait bus

  FileRdSlaveAxi uAxiSlave (
      .ACLK         (ACLK),
      .ARESETn      (ARESETn),

      .AWVALID      (AWVALID),
      .AWREADY      (AWREADY),
      .AWID         (AWID),
      .AWADDR       (AWADDR),
      .AWLEN        (AWLEN),
      .AWSIZE       (AWSIZE),
      .AWBURST      (AWBURST),
      .AWLOCK       (AWLOCK),
      .AWCACHE      (AWCACHE),
      .AWPROT       (AWPROT),

      .WID          (WID),
      .WDATA        (WDATA),
      .WSTRB        (WSTRB),
      .WLAST        (WLAST),
      .WVALID       (WVALID),
      .WREADY       (WREADY),

      .BID          (BID_i),
      .BRESP        (BRESP_i),
      .BVALID       (BVALID),
      .BREADY       (BREADY),

      .ARVALID      (ARVALID),
      .ARREADY      (ARREADY),
      .ARID         (ARID),
      .ARADDR       (ARADDR),
      .ARLEN        (ARLEN),
      .ARSIZE       (ARSIZE),
      .ARBURST      (ARBURST),
      .ARLOCK       (ARLOCK),
      .ARCACHE      (ARCACHE),
      .ARPROT       (ARPROT),

      .EMIT_DATA    (EMIT_DATA),
      .EMIT_REQ     (EMIT_REQ),
      .EMIT_ACK     (EMIT_ACK),

      .WAIT_DATA    (WAIT_DATA),
      .WAIT_REQ     (WAIT_REQ),
      .WAIT_ACK     (WAIT_ACK),

      .WUSER        (WUSER),
      .AWUSER       (AWUSER_int),
      .BUSER        (BUSER_i),
      .ARUSER       (ARUSER_int),
      .RUSER        (RUSER_i),

      .RID          (RID_i),
      .RDATA        (RDATA_i),
      .RRESP        (RRESP_i),
      .RLAST        (RLAST_i),
      .RVALID       (RVALID),
      .RREADY       (RREADY)
  );

`endif

//------------------------------------------------------------------------------
// AXI Slave APB Checker
//------------------------------------------------------------------------------
  defparam uAxiSlaveAPB.VALID_WIDTH  = 1;
  defparam uAxiSlaveAPB.DATA_WIDTH   = DATA_WIDTH;
  defparam uAxiSlaveAPB.ID_WIDTH     = ID_WIDTH_I;
  defparam uAxiSlaveAPB.EW_WIDTH     = EW_WIDTH;
  defparam uAxiSlaveAPB.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam uAxiSlaveAPB.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxiSlaveAPB.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxiSlaveAPB.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam uAxiSlaveAPB.RUSER_WIDTH  = RUSER_WIDTH_I;


  AxiSlaveAPB uAxiSlaveAPB (

      .ACLK           (ACLK),
      .ARESETn        (ARESETn),

      .AWVALID_VECT   (1'b0),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .AWID           (AWID),
      .AWADDR         (AWADDR[31:0]),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        (AWCACHE),
      .AWPROT         (AWPROT),
      .AWREGION       (AWREGION),
      .AWQV           (AWQOS),
      .AWUSER         (AWUSER),

      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .WID            (WID),
      .WLAST          (WLAST),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WUSER          (WUSER),

      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .BID            (BID_i),
      .BRESP          (BRESP_i),
      .BUSER          (BUSER_i),

      .ARVALID_VECT   (1'b0),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .ARID           (ARID),
      .ARADDR         (ARADDR[31:0]),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        (ARCACHE),
      .ARPROT         (ARPROT),
      .ARREGION       (ARREGION),
      .ARQV           (ARQOS),
      .ARUSER         (ARUSER),

      .RVALID         (RVALID),
      .RREADY         (RREADY),
      .RID            (RID_i),
      .RLAST          (RLAST_i),
      .RDATA          (RDATA_i),
      .RRESP          (RRESP_i),
      .RUSER          (RUSER_i),

      .pclk           (PCLK),
      .presetn        (PRESETn),
      .PRDATA         (PRDATA),
      .PREADY         (PREADY),
      .PSEL           (PSEL),
      .PENABLE        (PENABLE),
      .PWRITE         (PWRITE),
      .PADDR          (PADDR),
      .PWDATA         (PWDATA),

      .WAIT_DATA      (WAIT_DATA),
      .WAIT_REQ       (WAIT_REQ),
      .WAIT_ACK       (WAIT_ACK)
  );

  assign PSLVERR = 1'b0;


`ifdef ARM_ASSERT_ON

//------------------------------------------------------------------------------
// Transaction Counters
//------------------------------------------------------------------------------
  //AR Channel

  assign next_out_reads = (ARVALID & ARREADY & ~(RLAST_i & RVALID & RREADY)) ? out_reads + 7'b1 :
                          (RLAST_i & RVALID & RREADY & ~(ARVALID & ARREADY)) ? out_reads - 7'b1 : out_reads;

  //AW Channel
  assign next_out_writes = (AWVALID & AWREADY & ~(BVALID & BREADY)) ? out_writes + 7'b1 :
                           (BVALID & BREADY & ~(AWVALID & AWREADY)) ? out_writes - 7'b1 : out_writes;

  //counters
  always @(posedge ACLK or negedge ARESETn)
    begin
       if (~ARESETn) begin
           out_writes <= 7'b0;
           out_reads <= 7'b0;
       end else begin
           out_writes <= next_out_writes;
           out_reads <= next_out_reads;
       end
    end

  assert_never #(0,0,"Read Acceptance Capability exceeded")
     ovl_read_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (!limit_acceptance_capability && |read_issuing_capability && out_reads > read_issuing_capability)
       );

  assert_never #(0,0,"Write Acceptance Capability exceeded")
     ovl_write_acc_cap
       (/*AUTOINST*/
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (!limit_acceptance_capability && (out_writes[6] == 1'b0 && out_writes[5:0] > write_issuing_capability))
       );

  always @(posedge PCLK)
    begin
      PCLK_pulse = 1'b1;
      ACLK_pulse = 1'b1;
      #1 PCLK_pulse = 1'b0;
      #1 ACLK_pulse = 1'b0;
    end

  always @(negedge PCLK_pulse)
    begin
      VALID_prev <= {ARVALID, AWVALID, RVALID, WVALID, BVALID};
      READY_prev <= {ARREADY, AWREADY, RREADY, WREADY, BREADY};

      if (~ACLK_pulse)
        begin
          if (VALID_prev != {ARVALID, AWVALID, RVALID, WVALID, BVALID})
            error_v = 1'b1;
          if (READY_prev != {ARREADY, AWREADY, RREADY, WREADY, BREADY})
            error_r = 1'b1;
        end
        #1 error_v = 1'b0;
        #1 error_r = 1'b0;
    end

  assert_proposition #(0,0,"No VALID change between at any time other than an ACLK edge")
     ovl_no_valid_change
       (/*AUTOINST*/
        .reset_n   (ARESETn),
        .test_expr (error_v !== 1'b1)
       );

  assert_proposition #(0,0,"No READY change between at any time other than an ACLK edge")
     ovl_no_ready_change
       (/*AUTOINST*/
        .reset_n   (ARESETn),
        .test_expr (error_r !== 1'b1)
       );

//------------------------------------------------------------------------------
// CACHE OVLS Not in Internal PC
//------------------------------------------------------------------------------

 assert_implication #(1, 0,
    "AXI_ERRM_ARCACHE. When ARVALID is high, if ARCACHE[1] is low then ARCACHE[3] and ARCACHE[2] must also be low. Spec: table 5-1 on page 5-3."
  )  axi_errm_arcache
     (.clk              (ACLK),
      .reset_n          (ARESETn),
      .antecedent_expr  (AllowIllegalCache == 0 & (ARVALID) & ~ARCACHE[1]),
      .consequent_expr  (ARCACHE[3:2] == 2'b00)
      );

  assert_implication #(1, 0,
    "AXI_ERRM_AWCACHE. When AWVALID is high, if AWCACHE[1] is low then AWCACHE[3] and AWCACHE[2] must also be low. Spec: table 5-1 on page 5-3."
  )  axi_errm_awcache
     (.clk              (ACLK),
      .reset_n          (ARESETn),
      .antecedent_expr  (AllowIllegalCache == 0 & (AWVALID) & ~AWCACHE[1]),
      .consequent_expr  (AWCACHE[3:2] == 2'b00)
      );

//------------------------------------------------------------------------------
// AXI Protocol Checkers
//------------------------------------------------------------------------------
  assign #3 ACLKENDEL = ACLKEN;  // Delay 1ns more than clk_reset_if

  assign ACLKPC = (PortIsInternal) ? ~ACLKENDEL : ACLK;

  defparam uAxiPC.VALID_WIDTH  = 1;
  defparam uAxiPC.DATA_WIDTH   = DATA_WIDTH;
  defparam uAxiPC.ADDR_WIDTH   = ADDR_WIDTH;
  defparam uAxiPC.ID_WIDTH     = ID_WIDTH_I;
  defparam uAxiPC.WDEPTH       = 1;
  defparam uAxiPC.MAXRBURSTS   = 500;
  defparam uAxiPC.MAXWBURSTS   = 500;
  defparam uAxiPC.MAXWAITS     = 5000;
  defparam uAxiPC.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam uAxiPC.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam uAxiPC.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam uAxiPC.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam uAxiPC.RUSER_WIDTH  = RUSER_WIDTH_I;
  defparam uAxiPC.EXMON_WIDTH  = (ID_WIDTH_I > 10) : 10 : ID_WIDTH_I;
  defparam uAxiPC.LockOverride = 1'b1;
  defparam uAxiPC.AXI_ERRL_PropertyType = 2; // No Low power interface checking

  PL301_AxiPC uAxiPC (

      .ACLK           (ACLKPC),
      .ARESETn        (ARESETn),

      .AWVALID_VECT   (1'b0),
      .AWVALID        (AWVALID),
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
      .AWQV           (AWQOS),
      .AWUSER         (AWUSER),

      .WID            (WID),
      .WLAST          (WLAST),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WUSER          (WUSER),
      .WVALID         (WVALID),
      .WREADY         (WREADY),

      .BID            (BID_i),
      .BRESP          (BRESP_i),
      .BUSER          (BUSER_i),
      .BVALID         (BVALID),
      .BREADY         (BREADY),

      .ARVALID_VECT   (1'b0),
      .ARVALID        (ARVALID),
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
      .ARQV           (ARQOS),
      .ARUSER         (ARUSER),

      .RID            (RID_i),
      .RLAST          (RLAST_i),
      .RDATA          (RDATA_i),
      .RRESP          (RRESP_i),
      .RUSER          (RUSER_i),
      .RVALID         (RVALID),
      .RREADY         (RREADY),

      .CACTIVE        (1'b0),
      .CSYSREQ        (1'b0),
      .CSYSACK        (1'b0)
  );

`ifdef VPE
  defparam u_avip_axi_monitor.INSTANCE_NAME = "axi_s_if";
  defparam u_avip_axi_monitor.DATA_WIDTH = DATA_WIDTH;
  defparam u_avip_axi_monitor.ADDR_WIDTH = ADDR_WIDTH;         // Addr width
  defparam u_avip_axi_monitor.ID_WIDTH   = ID_WIDTH_I;
  defparam u_avip_axi_monitor.WDEPTH     = 1;
  defparam u_avip_axi_monitor.MAXRBURSTS = 500;
  defparam u_avip_axi_monitor.MAXWBURSTS = 500;
  defparam u_avip_axi_monitor.AWUSER_WIDTH = AWUSER_WIDTH_I;
  defparam u_avip_axi_monitor.WUSER_WIDTH  = WUSER_WIDTH_I;
  defparam u_avip_axi_monitor.BUSER_WIDTH  = BUSER_WIDTH_I;
  defparam u_avip_axi_monitor.ARUSER_WIDTH = ARUSER_WIDTH_I;
  defparam u_avip_axi_monitor.RUSER_WIDTH  = RUSER_WIDTH_I;
  defparam u_avip_axi_monitor.STRB_WIDTH = STRB_WIDTH;

  avip_axi_monitor_wrapper u_avip_axi_monitor (
      .ACLK           (ACLK),
      .ARESETn        (ARESETn),
      .AWID           (AWID),
      .AWADDR         (AWADDR),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        (AWCACHE),
      .AWPROT         (AWPROT),
      .AWUSER         (AWUSER),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .WID            (WID),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WLAST          (WLAST),
      .WUSER          (WUSER),
      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .BID            (BID_i),
      .BRESP          (BRESP_i),
      .BUSER          (BUSER_i),
      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .ARID           (ARID),
      .ARADDR         (ARADDR),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        (ARCACHE),
      .ARPROT         (ARPROT),
      .ARUSER         (ARUSER),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .RID            (RID_i),
      .RDATA          (RDATA_i),
      .RRESP          (RRESP_i),
      .RLAST          (RLAST_i),
      .RUSER          (RUSER_i),
      .RVALID         (RVALID),
      .RREADY         (RREADY)
  );

`endif

`ifdef TRACE  
  axi_trace     u_axi_trace (
      .ACLK           (ACLK),
      .ARESETn        (ARESETn),
      .AWID           (1'b0/*AWID*/),
      .AWADDR         (AWADDR),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        (AWCACHE),
      .AWPROT         (AWPROT),
      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .WID            (1'b0/*WID*/),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WLAST          (WLAST),
      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .BID            (1'b0/*BID_i*/),
      .BRESP          (BRESP_i),
      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .ARID           (1'b0/*ARID*/),
      .ARADDR         (ARADDR),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        (ARCACHE),
      .ARPROT         (ARPROT),
      .ARVALID        (ARVALID),
      .ARREADY        (ARREADY),
      .RID            (1'b0/*RID_i*/),
      .RDATA          (RDATA_i),
      .RRESP          (RRESP_i),
      .RLAST          (RLAST_i),
      .RVALID         (RVALID),
      .RREADY         (RREADY)
);
defparam u_axi_trace.ADDR_WIDTH = ADDR_WIDTH;
defparam u_axi_trace.DATA_WIDTH = DATA_WIDTH;
defparam u_axi_trace.ECHO = 1'b1;
//defparam u_axi_trace.ID_WIDTH = ID_WIDTH;
defparam u_axi_trace.ID_WIDTH = 1; // Remove ID for static latency ID_WIDTH;
defparam u_axi_trace.STRB_WIDTH = STRB_WIDTH;
defparam u_axi_trace.UNIT_NAME = INSTANCE;

`endif

`endif //ARM_ASSERT_ON

endmodule

//  --=============================== End ====================================--

