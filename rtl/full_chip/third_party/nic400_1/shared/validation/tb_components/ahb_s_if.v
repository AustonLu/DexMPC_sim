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
// File Revision          : 169583
//
// Date                   :  2014-03-23 02:48:09 +0000 (Sun, 23 Mar 2014)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : PL301 ahb slave interface
//
// Description : This block is an AHB slave that can be used in the main PL301
//               testbench.
//
//               Contains an eXVC AHBS or a Verilog FRS
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module ahb_s_if(

                 HCLK,
                 HRESETn,

                 HRDATA,
                 HREADY,
                 HREADYOUT,
                 HSEL,
                 HRESP,
                 HADDR,
                 HTRANS,
                 HWRITE,
                 HSIZE,
                 HBURST,
                 HPROT,
                 HWDATA,
                 HMASTLOCK,

                 //EMIT/WAIT channels .. only used in FRM mode
                 EMIT_DATA,
                 EMIT_REQ,
                 EMIT_ACK,

                 WAIT_DATA,
                 WAIT_REQ,
                 WAIT_ACK,

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
                 PRDATA

);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------
  parameter ADDR_WIDTH       = 32;
  parameter DATA_WIDTH       = 32;
  parameter HAUSER_WIDTH     = 8;
  parameter HRUSER_WIDTH     = 8;
  parameter HWUSER_WIDTH     = 8;
  parameter EW_WIDTH         = 16;

  parameter ADDR_MAX          = ADDR_WIDTH - 1;
  parameter DATA_MAX          = DATA_WIDTH - 1;
  parameter STRB_MAX          = (DATA_WIDTH / 8) - 1;
  parameter HAUSER_MAX        = HAUSER_WIDTH - 1;
  parameter HRUSER_MAX        = HRUSER_WIDTH - 1;
  parameter HWUSER_MAX        = HWUSER_WIDTH - 1;
  parameter EW_MAX            = EW_WIDTH - 1;

  parameter  ID_WIDTH        = 32;
  parameter  ID_MAX          = ID_WIDTH -1;
  parameter  INSTANCE        = "undef";
  parameter  INSTANCE_TYPE   = "AHBLiteS_";
  parameter  STIM_FILE_NAME  = {INSTANCE_TYPE, INSTANCE,".m3d"};

  parameter  PROTOCOL        = "ahb_m";


// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

  // AHB Interface

  input                           HCLK     ;
  input                           HRESETn  ;

  input                           HREADY   ; //mirror for ahb master
  output                          HREADYOUT;
  input                           HSEL;
  input             [ADDR_MAX:0]  HADDR    ;
  input                    [1:0]  HTRANS   ;
  input                           HWRITE   ;
  input                    [2:0]  HSIZE    ;
  input                    [2:0]  HBURST   ;
  input                    [3:0]  HPROT    ;
  input             [DATA_MAX:0]  HWDATA   ;
  input                           HMASTLOCK;
  output            [DATA_MAX:0]  HRDATA   ;

  output                          HRESP    ;

  //user
  input             [HAUSER_MAX:0] HAUSER   ;
  input             [HWUSER_MAX:0] HWUSER   ;
  output            [HRUSER_MAX:0] HRUSER   ;

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

  wire [ID_MAX:0]        aid;
  wire [31:0]            hstrobe;
  wire                   HREADYIN;
  wire    [HRUSER_MAX:0] HRUSER;
  reg     [HRUSER_MAX:0] HRUSERi;

  assign HREADYIN = (PROTOCOL == "ahb_m") ? HREADYOUT : HREADY;


//------------------------------------------------------------------------------
// AHB ID block
//------------------------------------------------------------------------------
  defparam uahb_aux.INSTANCE = INSTANCE;
  defparam uahb_aux.ID_WIDTH = ID_WIDTH;

  ahb_aux uahb_aux (
      .hid           (aid),
      .hstrobes       (hstrobe)
  );

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
// XVC Slave
//------------------------------------------------------------------------------
  defparam uAhbSlave.DATA_WIDTH = DATA_WIDTH;
  defparam uAhbSlave.ADDR_WIDTH = ADDR_WIDTH;
  defparam uAhbSlave.HRUSER_WIDTH = HRUSER_WIDTH;
  defparam uAhbSlave.HWUSER_WIDTH = HWUSER_WIDTH;

  AhbLiteSlaveXvc uAhbSlave (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADYIN),
      .HRESP          (HRESP),
      .HADDR          (HADDR),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),
      .HRUSER         (HRUSER),
      .HWUSER         (HWUSER),
      .HREADYOUT      (HREADYOUT),
      .HSEL           (HSEL)
  );

`else
//------------------------------------------------------------------------------
// AhbMEM
//------------------------------------------------------------------------------
  defparam uAhbSlave.ADDR_WIDTH       = ADDR_WIDTH;
  defparam uAhbSlave.DATA_WIDTH       = DATA_WIDTH;
  defparam uAhbSlave.EW_WIDTH         = EW_WIDTH;
  defparam uAhbSlave.ID_WIDTH         = ID_WIDTH;
  defparam uAhbSlave.STIM_FILE_NAME   = STIM_FILE_NAME;
  defparam uAhbSlave.StimArraySize    = 100000;

  AhbFrs uAhbSlave (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADYIN),
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
      .HSEL           (HSEL),

      .ID             (aid),

      .EMIT_DATA      (EMIT_DATA),
      .EMIT_REQ       (EMIT_REQ),
      .EMIT_ACK       (EMIT_ACK),

      .WAIT_DATA      (WAIT_DATA),
      .WAIT_REQ       (WAIT_REQ),
      .WAIT_ACK       (WAIT_ACK)

  );

  assign HRUSER = {HRUSER_WIDTH{1'b0}};

`endif

//------------------------------------------------------------------------------
// AHB Slave APB Checker
//------------------------------------------------------------------------------
  defparam uAhbSlaveAPB.DATA_WIDTH = DATA_WIDTH;


  AhbSlaveAPB uAhbSlaveAPB (
      .HCLK           (HCLK),
      .HRESETn        (PRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADYIN),
      .HRESP          (HRESP),
      .HADDR          (HADDR[31:0]),
      .HTRANS         (HTRANS),
      .HWRITE         (HWRITE),
      .HSIZE          (HSIZE),
      .HBURST         (HBURST),
      .HPROT          (HPROT),
      .HWDATA         (HWDATA),
      .HMASTLOCK      (HMASTLOCK),

      .HREADYOUT      (HREADYOUT),
      .HSEL           (HSEL),

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
  defparam uAhbPC.ID_WIDTH      = ID_WIDTH;
  defparam uAhbPC.HAUSER_WIDTH  = HAUSER_WIDTH;
  defparam uAhbPC.HRUSER_WIDTH  = HRUSER_WIDTH;
  defparam uAhbPC.HWUSER_WIDTH  = HWUSER_WIDTH;

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
      .HREADY         (HREADYIN),


      .HRESP          ({1'b0,HRESP}),
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

      .HCLKEN         (1'b1),
      .HREADYOUT      (HREADYOUT),
      .HLOCKx         (1'b0),
      .HGRANTx        (1'b1),
      .HSELx          (HSEL),
      .HID            (aid),
      .HSTROBE        (hstrobe[STRB_MAX:0])

  );


`ifdef TRACE

  ahb_trace     u_ahb_trace (
      .HCLK           (HCLK),
      .HRESETn        (HRESETn),
      .HRDATA         (HRDATA),
      .HREADY         (HREADYIN),
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
defparam u_ahb_trace.MASTER = 1'b0;
defparam u_ahb_trace.ID_WIDTH = 1;
defparam u_ahb_trace.UNIT_NAME = INSTANCE;

`endif

`endif //ARM_ASSERT_ON

endmodule

//  --=============================== End ====================================--

