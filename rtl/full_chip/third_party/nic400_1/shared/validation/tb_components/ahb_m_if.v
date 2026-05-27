//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2006-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 169583
// File Date           :  2014-03-23 02:48:09 +0000 (Sun, 23 Mar 2014)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : PL301 ahb master interface
//
// Description : This block is an AHB master that can be used in the main PL301
//               testbench.
//
//               Currently contain an eXVC AHBM
//------------------------------------------------------------------------------

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module ahb_m_if(

                 HCLK,	
                 HRESETn,
                 HRDATA,
                 HREADY,
                 HRESP,
                 HADDR,
                 HTRANS,
                 HWRITE,
                 HSIZE,
                 HBURST,
                 HPROT,
                 HWDATA,
                 HMASTLOCK,
                 //slave interface mirror
                 HREADYOUT,
                 HSELx,

                 HAUSER,
                 HRUSER,
                 HWUSER,

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
                 PRDATA,

                 // Event handling ports
                 WAIT_REQ,
                 WAIT_ACK,
                 WAIT_DATA,
                 EMIT_REQ,
                 EMIT_ACK,
                 EMIT_DATA


);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------
  parameter DATA_WIDTH       = 32;
  parameter ADDR_WIDTH       = 32;
  parameter HAUSER_WIDTH     = 8;
  parameter HRUSER_WIDTH     = 8;
  parameter HWUSER_WIDTH     = 8;
  parameter EW_WIDTH         = 8;

  parameter DATA_MAX         = DATA_WIDTH - 1;
  parameter STRB_MAX         = (DATA_WIDTH / 8) - 1;
  parameter HAUSER_MAX       = HAUSER_WIDTH - 1;
  parameter HRUSER_MAX       = HRUSER_WIDTH - 1;
  parameter HWUSER_MAX       = HWUSER_WIDTH - 1;
  parameter EW_MAX           = EW_WIDTH - 1;

  parameter  INSTANCE        = "undef";
  parameter  INSTANCE_TYPE   = "AHBLiteM_";
  parameter  STIM_FILE_NAME  = {INSTANCE_TYPE, INSTANCE,".m3d"};
// -----------------------------------------------------------------------------
//  IO Declaration
// -----------------------------------------------------------------------------

  // AHB Interface
  input                           HCLK;      // Clock
  input                           HRESETn;   // Reset
  input             [DATA_MAX:0]  HRDATA;    // AHB Read Data
  output                          HREADY;    // AHB Ready , slave mirror
  input                           HRESP;     // AHB Response
  output        [ADDR_WIDTH-1:0]  HADDR;     // AHB Address
  output                   [1:0]  HTRANS;    // AHB Transfer
  output                          HWRITE;    // AHB Direction
  output                   [2:0]  HSIZE;     // AHB Size
  output                   [2:0]  HBURST;    // AHB Burst
  output                   [3:0]  HPROT;     // AHB Protection
  output            [DATA_MAX:0]  HWDATA;    // AHB Write Data
  output                          HMASTLOCK; // AHB lock (address phase)
  //slave interface mirror
  output                          HSELx     ;
  input                           HREADYOUT;

  //user
  output             [HAUSER_MAX:0] HAUSER;
  output             [HWUSER_MAX:0] HWUSER;
  input              [HRUSER_MAX:0] HRUSER;

  // APB3 Interface
  input         PENABLE;         // APB Enable
  input         PWRITE;          // APB transfer(R/W) direction
  input  [31:0] PADDR;           // APB address
  input  [31:0] PWDATA;          // APB write data
  output        PREADY;          // APB transfer completion signal for slaves
  output        PSLVERR;         // APB transfer response signal for slaves
  output [31:0] PRDATA;          // APB read data for slave0
  input         PSEL;

  input         PCLK;
  input         PRESETn;


  //Emit and Wait channels only used in FRM mode
  output [EW_MAX:0]      EMIT_DATA;       //Emit data
  output                 EMIT_REQ;        //Emit Request
  input                  EMIT_ACK;        //Emit acknoledgement

  input  [EW_MAX:0]      WAIT_DATA;       //Wait data
  input                  WAIT_REQ;        //Wait Request
  output                 WAIT_ACK;        //Waitr acknoledgement

  //user
  wire                  [HAUSER_MAX:0] HAUSER;
  wire                  [HWUSER_MAX:0] HWUSER;
  wire                  [HRUSER_MAX:0] HRUSER;

`ifdef SN
  reg                  WAIT_ACK;
  wire                 wait_in_progress;

  assign wait_in_progress = WAIT_REQ ^ WAIT_ACK;
  always @(posedge HCLK or negedge PRESETn)
    begin
      if (~PRESETn) begin
           WAIT_ACK <= 1'b0;
         end
      else if (wait_in_progress) begin
           WAIT_ACK <= ~WAIT_ACK;
         end
    end

  assign EMIT_REQ   = 1'b0;
  assign EMIT_DATA  = {EW_WIDTH{1'b0}};
`endif

`ifdef SN
//------------------------------------------------------------------------------
// XVC Master
//------------------------------------------------------------------------------
  reg                data_phase;
  wire               HRESPin;
  wire [DATA_MAX:0]  HRDATAin;

  defparam uAhbMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAhbMaster.ADDR_WIDTH     = ADDR_WIDTH;
  defparam uAhbMaster.HAUSER_WIDTH   = HAUSER_WIDTH;
  defparam uAhbMaster.HRUSER_WIDTH   = HRUSER_WIDTH;
  defparam uAhbMaster.HWUSER_WIDTH   = HWUSER_WIDTH;

  AhbLiteMasterXvc uAhbMaster (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATAin),
      .HREADY         (HREADY),
      .HRESP          (HRESPin),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),
      .HAUSER         (HAUSER),
      .HRUSER         (HRUSER),
      .HWUSER         (HWUSER),
      .HSEL           (HSELx)    //This is an HSEL output to indicate that the
                                //DUT should be selected;
  );

  //Determine when the "AHB default slave" has the data bus
  always @(posedge HCLK or negedge HRESETn)
     begin
        if (~HRESETn) begin
           data_phase = 1'b0;
        end else if (HREADY) begin
           data_phase = ~HSELx;
        end
     end

  assign HRESPin = (data_phase) ? 1'b0 : HRESP;
  assign HRDATAin = (data_phase) ? {DATA_WIDTH{1'b0}} : HRDATA;
  assign HREADY  = (data_phase) ? 1'b1 : HREADYOUT;

`else
//------------------------------------------------------------------------------
// Frm
//------------------------------------------------------------------------------
  defparam uAhbMaster.DATA_WIDTH     = DATA_WIDTH;
  defparam uAhbMaster.ADDR_WIDTH     = ADDR_WIDTH;
  defparam uAhbMaster.EW_WIDTH       = EW_WIDTH;
  defparam uAhbMaster.StimArraySize  = 100000;
  defparam uAhbMaster.InputFileName  = STIM_FILE_NAME;

  AhbFrm uAhbMaster (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADY),
      .HRESP          (HRESP),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),

      .WAIT_REQ       (WAIT_REQ),
      .WAIT_ACK       (WAIT_ACK),
      .WAIT_DATA      (WAIT_DATA),
      .EMIT_REQ       (EMIT_REQ),
      .EMIT_ACK       (EMIT_ACK),
      .EMIT_DATA      (EMIT_DATA)

  );

  assign HSELx = 1'b1;
  assign HREADY = HREADYOUT;

  assign HAUSER = {HAUSER_WIDTH{1'b0}};
`endif

//------------------------------------------------------------------------------
// AHB Master APB Checker
//------------------------------------------------------------------------------
  defparam uAhbMasterAPB.DATA_WIDTH = DATA_WIDTH;
  defparam uAhbMasterAPB.ADDR_WIDTH = ADDR_WIDTH;

  AhbMasterAPB uAhbMasterAPB (
      .HCLK           (HCLK),
      .HRESETn        (PRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADY),
      .HRESP          (HRESP),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),

      .pclk           (PCLK),
      .PRDATA         (PRDATA),
      .PREADY         (PREADY),
      .PSEL           (PSEL),
      .PENABLE        (PENABLE),
      .PWRITE         (PWRITE),
      .PADDR          (PADDR),
      .PWDATA         (PWDATA)

  );

  assign PSLVERR = 1'b0;

`ifdef ARM_ASSERT_ON

//------------------------------------------------------------------------------
// AHB Protocol Checkers
//------------------------------------------------------------------------------
  defparam uAhbPC.DATA_WIDTH    = DATA_WIDTH;
  defparam uAhbPC.ADDRESS_WIDTH = ADDR_WIDTH;
  defparam uAhbPC.ID_WIDTH      = 1;
  defparam uAhbPC.HAUSER_WIDTH  = HAUSER_WIDTH;
  defparam uAhbPC.HRUSER_WIDTH  = HRUSER_WIDTH;
  defparam uAhbPC.HWUSER_WIDTH  = HWUSER_WIDTH;
  defparam uAhbPC.LOCK_IGNORE   = 1;

  // Property type (0=prove, 1=assume, 2=ignore).
  defparam uAhbPC.ERRM_PropertyType = 0; // default: prove Master is AHB compliant
  defparam uAhbPC.RECM_PropertyType = 0; // default: prove Master is AHB compliant
  defparam uAhbPC.AUXM_PropertyType = 0; // default: prove Master auxiliary logic checks
  //
  defparam uAhbPC.ERRS_PropertyType = 0; // default: prove Slave is AHB compliant
  defparam uAhbPC.RECS_PropertyType = 0; // default: prove Slave is AHB compliant
  defparam uAhbPC.AUXS_PropertyType = 0; // default: prove Slave auxiliary logic checks

  PL301_AhbPC uAhbPC (
      .HCLK           (HCLK),

      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADY),


      .HRESP          ({1'b0,HRESP}),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),

      .HCLKEN         (1'b1),
      .HREADYOUT      (HREADYOUT),
      .HLOCKx         (1'b0),
      .HGRANTx        (1'b1),
      .HSELx          (HSELx),
      .HID            (1'b0),
      .HSTROBE        ({STRB_MAX + 1{1'b1}}),
      .HAUSER         (HAUSER),
      .HWUSER         (HWUSER),
      .HRUSER         (HRUSER)

  );

`ifdef TRACE

  ahb_trace     u_ahb_trace (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADY),
      .HRESP          (HRESP),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),
      .HREADYOUT      (HREADYOUT),
      .HSELx          (1'b0)

//      .HAUSER         (HAUSER),
//      .HRUSER         (HRUSER),
//      .HWUSER         (HWUSER)

);
defparam u_ahb_trace.ADDR_WIDTH = ADDR_WIDTH;
defparam u_ahb_trace.DATA_WIDTH = DATA_WIDTH;
defparam u_ahb_trace.ECHO = 1'b1;
defparam u_ahb_trace.MASTER = 1'b1;
defparam u_ahb_trace.ID_WIDTH = 1;
defparam u_ahb_trace.UNIT_NAME = INSTANCE;

`endif

`endif //ARM_ASSERT_ON

endmodule

//  --=============================== End ====================================--

