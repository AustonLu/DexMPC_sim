//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2006-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 150003
// File Date           :  2013-05-09 16:14:54 +0100 (Thu, 09 May 2013)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : PL301 apb slave interface
//
// Description : This block is an APB slave that can be used in the main PL301
//               testbench.
//------------------------------------------------------------------------------

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module apb_s_if(

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
                 PRDATA

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
      .pstrb          (4'b1111), //Unused signal
      .pprot          (3'b111),  //Unused signal
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
  defparam uApbPC.SEL_WIDTH = 1;
  defparam uApbPC.ID_WIDTH = ID_WIDTH;

  PL301_ApbPC uApbPC (

      .PRESETn        (presetn),
      .PCLK           (PCLK),
      .PCLKEN         (PCLKEN),
      .PSLVERR        (PSLVERR), 
                            
      .PRDATA         (PRDATA), 
      .PREADY         (PREADY), 
      .PSEL           (PSEL), 
      .PENABLE        (PENABLE), 
      .PWRITE         (PWRITE), 
      .PADDR          (PADDR), 
      .PWDATA         (PWDATA),
      .PID            (pid),
      .PSTROBE        (pstrobe)

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
 
