//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      Version Control Information
//
//      Checked In          :  2013-05-09 16:14:54 +0100 (Thu, 09 May 2013)
//
//      Revision            : 150003
//
//      Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
// Purpose : PL301 apb4 slave interface
//
// Description : This block is an APB4 slave that can be used in the main PL301
//               testbench.
//------------------------------------------------------------------------------

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module apb4_s_if(

                 PCLK,
                 PCLKEN,
                 presetn,
                
                 PSEL,
                 PENABLE,
                 PWRITE,
                 PADDR,
                 PWDATA,
                 PREADY,
                 PSLVERR,
                 PRDATA,
                 PPROT,
                 PSTRB
                ); 

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------
  
  parameter  ID_WIDTH        = 32;  
  parameter  ID_MAX          = ID_WIDTH -1;
  parameter  INSTANCE        = "undef";
  parameter  INSTANCE_TYPE   = "APBS_";
  parameter  STIM_FILE_NAME  = {INSTANCE_TYPE, INSTANCE,".m3d"};
  parameter  APB_TYPE        = 3;

  parameter  MAXDELAY        = 16;
  parameter  SLVERR_ENABLE   = 1;

  //parameter  MW              = (ID_WIDTH/8) - 1;
  
// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------
  
// APB3 Interface
input         PENABLE;         // APB Enable
input         PWRITE;          // APB transfer(R/W) direction
input  [31:0] PADDR;           // APB address
input  [31:0] PWDATA;          // APB write data
output        PREADY;          // APB transfer completion signal for slaves
output        PSLVERR;         // APB transfer response signal for slaves
output [31:0] PRDATA;          // APB read data for slave0
input         PSEL;
input  [ 3:0] PSTRB;           // APB4 Stobe sugnal
input  [ 2:0] PPROT;           // APB4 protection signal
  
input         PCLK;
input         PCLKEN;  
input         presetn;
  
wire [ID_MAX:0]   pid;
wire [3:0]        pstrobe;

//------------------------------------------------------------------------------
// APB FRS SLAVE
//------------------------------------------------------------------------------
  defparam uapb_aux.INSTANCE = INSTANCE;   
  defparam uapb_aux.ID_WIDTH = ID_WIDTH;

  apb_aux uapb_aux (
      .pid           (pid),
      .pstrobe       (pstrobe)
  );

`ifndef SN
//------------------------------------------------------------------------------
// APB FRS SLAVE
//------------------------------------------------------------------------------
  
  defparam uApbSlave.STIM_FILE_NAME = STIM_FILE_NAME;
  defparam uApbSlave.StimArraySize  = 50000;   
  defparam uApbSlave.ID_WIDTH = ID_WIDTH; 
  defparam uApbSlave.APB_TYPE = APB_TYPE;
    
  ApbFrs uApbSlave (

      .presetn        (presetn),
      .pclk           (PCLK),
      .pclken         (PCLKEN),
                            
      .prdata         (PRDATA), 
      .pready         (PREADY), 
      .psel           (PSEL), 
      .penable        (PENABLE), 
      .pwrite         (PWRITE), 
      .paddr          (PADDR), 
      .pwdata         (PWDATA),
      .pstrb          (PSTRB), 
      .pprot          (PPROT), 
      .pslverr        (PSLVERR),
      .id             (pid)              
  
  ); 
`endif
  
`ifdef SN

//------------------------------------------------------------------------------
// APB RANDOM SLAVE
//------------------------------------------------------------------------------
  
  defparam uApbSlave.MAXDELAY      = MAXDELAY;
  defparam uApbSlave.SLVERR_ENABLE = SLVERR_ENABLE;
  defparam uApbSlave.APB_TYPE = APB_TYPE;
  
  apb_random_slave uApbSlave (

      .presetn        (presetn),
      .pclk           (PCLK),
      .pclken         (PCLKEN),
                            
      .prdata         (PRDATA), 
      .pready         (PREADY), 
      .psel           (PSEL), 
      .penable        (PENABLE), 
      .pwrite         (PWRITE), 
      .paddr          (PADDR), 
      .pwdata         (PWDATA),
      .pslverr        (PSLVERR)
  ); 
`endif  

`ifdef ARM_ASSERT_ON

//------------------------------------------------------------------------------
// APB PROTOCOL Checker 
//------------------------------------------------------------------------------
  defparam uApb4PC.SEL_WIDTH = 1;
  defparam uApb4PC.ID_WIDTH = ID_WIDTH;

  //wire  [ 3:0]  PSTRB;
  //wire  [ 2:0]  PPROT;

  //assign        PSTRB = pstrobe; 
  //assign        PPROT = tbench.u_DUT.u_amib_slave_4.u_apb_m.pprot_i;


  wire PWRITE_sel;
  wire [31:0] PADDR_sel;
  wire [31:0] PWDATA_sel;
  wire  [3:0] PSTRB_sel;
  wire  [ 2:0]PPROT_sel;

  assign PWRITE_sel = PWRITE & PSEL;
  assign PADDR_sel  = PADDR  & {32{PSEL}};             
  assign PWDATA_sel = PWDATA & {32{PSEL}}; 
  assign PSTRB_sel  = PSTRB  & {4{PSEL}};             
  assign PPROT_sel  = PPROT  & {3{PSEL}};             

  PL301_Apb4PC uApb4PC (

      .PRESETn        (presetn),
      .PCLK           (PCLK),
      .PCLKEN         (PCLKEN),
      .PSLVERR        (PSLVERR), 
                            
      .PRDATA         (PRDATA), 
      .PREADY         (PREADY), 
      .PSEL           (PSEL), 
      .PENABLE        (PENABLE), 
      .PWRITE         (PWRITE_sel), 
      .PADDR          (PADDR_sel), 
      .PWDATA         (PWDATA_sel),
      .PID            (pid),
      .PSTROBE        (pstrobe),
      .PSTRB          (PSTRB_sel),
      .PPROT          (PPROT_sel)

  );

`ifdef TRACE

  apb_trace     u_apb_trace (
      .presetn        (presetn),
      .PCLK           (PCLK),
      .PCLKEN         (PCLKEN),
      .PSLVERR        (PSLVERR), 
                            
      .PRDATA         (PRDATA), 
      .PREADY         (PREADY), 
      .PSEL           (PSEL), 
      .PENABLE        (PENABLE), 
      .PWRITE         (PWRITE), 
      .PADDR          (PADDR), 
      .PWDATA         (PWDATA)

);
defparam u_apb_trace.DATA_WIDTH = 32;
defparam u_apb_trace.ECHO = 1'b1;
defparam u_apb_trace.ID_WIDTH = 1;
defparam u_apb_trace.UNIT_NAME = INSTANCE;

`endif

`endif //ARM_ASSERT_ON

endmodule

//  --=============================== End ====================================--
 
