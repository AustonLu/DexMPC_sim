//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//------------------------------------------------------------------------------
//      Version Control Information
//
//      Checked In          :  2012-08-17 10:56:37 +0100 (Fri, 17 Aug 2012)
//
//      Revision            : 135247
//
//      Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             : Apb4 PC for block level simulations
//------------------------------------------------------------------------------

module PL301_Apb4PC (
    // Inputs
    PCLK,
    PCLKEN,
    PRESETn,
    PSEL,
    PENABLE,
    PREADY,
    PSLVERR,
    PADDR,
    PWRITE,
    PWDATA,
    PRDATA,
    PID,
    PSTROBE,
    PPROT,
    PSTRB
  );

  // Module parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter ID_WIDTH = 1;
  parameter SEL_WIDTH  = 2;
  parameter LOGFILE    = "log.apb4";

  parameter DW = DATA_WIDTH - 1;
  parameter MW = (DATA_WIDTH /8) - 1;
  parameter AW = ADDR_WIDTH - 1;
  parameter SW = SEL_WIDTH - 1;
  parameter IW = ID_WIDTH - 1;

  // Inputs
  input         PCLK;
  input         PCLKEN;
  input         PRESETn;

  input [SW:0]  PSEL;
  input         PENABLE;
  input         PREADY;
  input         PSLVERR;
  input         PWRITE;
  input [AW:0]  PADDR;
  input [DW:0]  PWDATA;
  input [DW:0]  PRDATA;
  input [IW:0]  PID;
  input [MW:0]  PSTROBE;
  input [MW:0]  PSTRB;
  input [ 2:0]  PPROT;


`ifdef ARM_ASSERT_ON
//------------------------------------------------------------------------------
//
//                        Ap4bPC Module
//                       ==============
//
//------------------------------------------------------------------------------
//
// Overview
// ========
//
// Assertions to verify the APB4 protocol is adhered to
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  wire          PCLK;
  wire          PCLKEN;
  wire          PRESETn;

  wire [SW:0]   PSEL;
  wire          PENABLE;
  wire          PREADY;
  wire          PSLVERR;
  wire          PWRITE;
  wire  [AW:0]  PADDR;
  wire  [DW:0]  PWDATA;
  wire  [DW:0]  PRDATA;

  wire  [MW:0]  PSTRB;
  wire  [ 2:0]  PPROT;

  wire  [AW:0]  PADDR_aligned;
  assign PADDR_aligned = {PADDR[AW:2],2'b00};

  //assign        PSTRB = PSTROBE; 
  //assign        PPROT = tbench.u_DUT.u_amib_slave_4.u_apb_m.pprot_i;
 
  Apb4PC        uApb4PC (
   // Global Signals
    .PCLK                (PCLK),
    .PCLKEN              (PCLKEN),
    .PRESETn             (PRESETn),

    // APB Control Signals
    .PSELx               (PSEL),
    .PENABLE             (PENABLE),
    .PWRITE              (PWRITE),
    .PREADY              (PREADY),
    .PSLVERR             (PSLVERR),
    .PPROT               (PPROT),

    // APB Data Signals
    .PADDR               (PADDR_aligned),
    .PWDATA              (PWDATA),
    .PSTRB               (PSTRB),
    .PRDATA              (PRDATA)
  );
  
`endif

`ifdef APB4LOGGER
//------------------------------------------------------------------------------
// APB4 transaction logging
//------------------------------------------------------------------------------

  Apb4Logger
    #(ADDR_WIDTH, DATA_WIDTH, SEL_WIDTH, LOGFILE)
  uApb4Logger (
      // Inputs
      .PCLK    (`APB_AUX_CLK),
      .PCLKEN  (PCLKEN),
      .PRESETn (`APB_AUX_RSTn),
      .PREADY  (PREADY),
      .PSEL    (PSEL),
      .PENABLE (PENABLE),
      .PWRITE  (PWRITE),
      .PWDATA  (PWDATA),
      .PRDATA  (PRDATA),
      .PADDR   (PADDR)
    );

`endif

endmodule

// --================================= End ===================================--
