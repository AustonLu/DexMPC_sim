//------------------------------------------------------------------------------
//   The confidential and proprietary information contained in this file may
//   only be used by a person authorised under and to the extent permitted
//   by a subsisting licensing agreement from ARM Limited.
//    (C) COPYRIGHT 2001-2012 ARM Limited
//        ALL RIGHTS RESERVED
//   This entire notice must be reproduced on all copies of this file
//   and copies of this file may only be made by a person if such person is
//   permitted to do so under the terms of a subsisting license agreement
//   from ARM Limited.
//
//------------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Date           :  2012-11-01 17:24:19 +0000 (Thu, 01 Nov 2012)
//  File Revision       : 138983
//
//  Release Information : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             :  APB file reader bus slave 
//------------------------------------------------------------------------------

module ApbFrs
  (
  // Outputs
  prdata, pready, pslverr,id,
  // Inputs
  presetn, pclk, pclken, psel, penable, pwrite, paddr, pwdata,
  pstrb, pprot
   
  );


  parameter  STIM_FILE_NAME = "filestim.m3d";   // stimulus data file name
  parameter  StimArraySize  = 100; // array size, should be large enough to hold  
  parameter  MESSAGE_TAG    = "ApbFrs:";  
  parameter  ID_WIDTH       = 32;  
  parameter  ID_MAX         = ID_WIDTH -1 ;
  parameter  APB_TYPE       = 3;
  
  // Clock and Reset
  input         presetn;
  input         pclk;
  input         pclken;

  // APB3 Block Interface
  output [31:0] prdata;
  output        pready;
  output        pslverr;  
  input         psel;
  input         penable;
  input         pwrite;
  input  [31:0] paddr;
  input  [31:0] pwdata;
  
 //APB4 Extra Inputs
 input  [ 3:0] pstrb;
 input  [ 2:0] pprot;
  
 input  [ID_MAX:0] id;
  
//------------------------------------------------------------------------------
  // Constant declarations
//------------------------------------------------------------------------------



  // Information message
  `define OPENFILE_MSG "%d %s Reading stimulus file %s"
  `define DATA_ERR_MSG "%d %s #ERROR# Data received did not match expectation."
  `define APB_CMD_MSG "%d %s #ERROR# Unknown command value in file."

  `define ADDRESS_MSG     " Address        = %h"
  `define ACTUAL_ADDR     " Actual addr    = %h"
  `define EXPECTED_ADDR   " Expected addr  = %h"
  `define ACTUAL_DATA     " Actual data    = %h"
  `define EXPECTED_DATA   " Expected data  = %h"
  `define WDATA_MASK      " Data mask      = %h"
  `define ACTUAL_PPROT    " Actual pprot   = %h"
  `define EXPECTED_PPROT  " Expected pprot = %h"
  `define ACTUAL_PSTRB    " Actual pstrb   = %h"
  `define EXPECTED_PSTRB  " Expected pstrb = %h"
 
  

  // Inent messages because of the length of the time variable
  `define INDENT "                     "

  `define APB_CMD_WRITE     8'b00100000
  `define APB_CMD_READ      8'b00010000
  `define APB_CMD_IDLE      8'b00000000


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------
  wire [31:0]       prdata;
  wire              pslverr;
  wire              pready;

  reg [31:0]        prdata_i;
  reg               pslverr_i;
  wire              pready_i;
  
  
  // Signals from file data
  wire              renable;
  wire              wenable;
  
  wire [7:0]        command;                 // current command buffer  
  wire [31:0]       FileData;                // data read from stimulus file
  wire              FileValid;
  wire              resp;
  wire [3:0]        strobe;
  wire [2:0]        prot_signal;
  wire              Delaying;
  wire [31:0]       FileAddr;
  reg  [31:0]       FileAddr_reg;
 
  reg [2:0]         pdata_pprot; 
  reg [31:0]        pwdata_cmp;
  reg [3:0]         pwdata_strb;
  wire [31:0]       pwdata_mask_rtl;
  wire [31:0]       pwdata_mask_golden;
  
  // Error signal
  integer           DataErrCnt;                   // read data errors  
  wire        	    DataError;           // flag to indicate read data is incorrect
  wire              AddrError;
  wire              PprotError;          //Indicates a mismatch between real and golden reference of pprot
  wire              PstrbError;          //PSTRB mistmatch

//------------------------------------------------------------------------------
//  Set outputs to unknown when no PCLKEN
//------------------------------------------------------------------------------

  assign  prdata = pclken ? prdata_i : 32'hxxxx;
  assign  pslverr = pclken ? pslverr_i : 1'bx;
  assign  pready = pclken ? pready_i : 1'bx;

//------------------------------------------------------------------------------
//  ApbFrsCore
//------------------------------------------------------------------------------
    
  defparam uApbFrsCore.STIM_FILE_NAME = STIM_FILE_NAME;
  defparam uApbFrsCore.ID_WIDTH       = ID_WIDTH;
  defparam uApbFrsCore.FILE_LEN       = StimArraySize;
  
 ApbFrsCore uApbFrsCore
  (
    .pclk           (pclk),
    .presetn        (presetn),
    .FileReady      (FileReady),

    .command        (command),
    .id             (id),
    .resp           (resp),
    .strobe         (strobe),
    .pprot          (prot_signal),

    .FileValid      (FileValid),
    .FileAddr       (FileAddr),
    .FileData       (FileData),
    .Delaying       (Delaying)

  );  

  //FileReady is the DATA request signal for ApbFrsCore 
  assign FileReady = psel & pclken & !penable;
  assign command = pwrite ? `APB_CMD_WRITE : `APB_CMD_READ ;
  
  assign renable = (psel & !pwrite & !penable & pclken);
  assign wenable = (psel &  pwrite & !penable & pclken);

  assign pready_i  = ~Delaying;

//------------------------------------------------------------------------------
// Register
//------------------------------------------------------------------------------

  always @(negedge presetn or posedge pclk)
  begin : p_slverr
    if (!presetn) begin
      pslverr_i     <= 1'b0;
      pdata_pprot   <= 3'b000;
      FileAddr_reg  <= 32'b0;
    end  
    else 
    begin
      if(FileReady) begin
        pslverr_i     <= resp;
        pdata_pprot   <= prot_signal;
        FileAddr_reg  <= FileAddr;
      end  
    end
  end

  always @(negedge presetn or posedge pclk)
  begin : p_data_rd
    if (!presetn)
      prdata_i <= 32'h00000000;
    else 
    begin
      if(renable)
        prdata_i <= FileData;
    end
  end

  always @(negedge presetn or posedge pclk)
  begin : p_data_wr
    if (!presetn)
      pwdata_cmp <= 32'h00000000;
    else 
    begin
      if(wenable)
       pwdata_cmp <= FileData;
    end
  end

  always @(negedge presetn or posedge pclk)
  begin : p_strobe
    if (!presetn)
      pwdata_strb <= 4'h0;
    else 
    begin
      if(wenable)
        pwdata_strb <= strobe;
    end
  end

//------------------------------------------------------------------------------
// Report errors to simulation environment
//------------------------------------------------------------------------------
// This process responds to error signals with an acknowledge signal and
//  reports the error to the simulation environment

  // If DataCompare is non-zero, flag an error.
  assign pwdata_mask_golden = {{8{pwdata_strb[3]}},{8{pwdata_strb[2]}},{8{pwdata_strb[1]}},{8{pwdata_strb[0]}}};
  assign pwdata_mask_rtl    = {{8{pstrb[3]}},{8{pstrb[2]}},{8{pstrb[1]}},{8{pstrb[0]}}}; 
   
  
  

  generate
    if (APB_TYPE == 4)
    begin : g_apb_type_if
     assign DataError = ((pwdata & pwdata_mask_rtl) != (pwdata_cmp & pwdata_mask_golden)) && pwrite && psel && penable && pready && pclken;
     assign AddrError = (paddr != FileAddr_reg) && psel && penable && pready && pclken; 
     assign PprotError = (pprot != pdata_pprot )    && psel && penable && pready && pclken;
     assign PstrbError = (pstrb != pwdata_strb ) && pwrite && psel && penable && pready && pclken; 
      
     always @ (posedge pclk or negedge presetn)
      begin : p_ReportErrorsBhav
        if (!presetn)
          begin
            DataErrCnt = 0;
          end
        else
          if (DataError == 1'b1 || AddrError == 1'b1 || PprotError == 1'b1 || PstrbError == 1'b1)
          begin
              $display (`DATA_ERR_MSG, $time, MESSAGE_TAG);
              if (AddrError == 1'b1) begin
                 $write   (`INDENT);
                 $display (`EXPECTED_ADDR, FileAddr_reg);     
                 $write   (`INDENT);
                 $display (`ACTUAL_ADDR, paddr);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end   
           
              if (DataError == 1'b1) begin
                 $write   (`INDENT);
                 $display (`ACTUAL_DATA, pwdata);
                 $write   (`INDENT);
                 $display (`EXPECTED_DATA, pwdata_cmp);
                 $write   (`INDENT);
                 $display (`WDATA_MASK, pwdata_mask_golden);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end    
              
             if (PprotError) begin
                 $write   (`INDENT);
                 $display (`ACTUAL_PPROT, pprot);
                 $write   (`INDENT);
                 $display (`EXPECTED_PPROT, pdata_pprot);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end    

             if (PstrbError) begin
                 $write   (`INDENT);
                 $display (`ACTUAL_PSTRB, pstrb);
                 $write   (`INDENT);
                 $display (`EXPECTED_PSTRB, pwdata_strb);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end    
          end 
      end
  
    end
    else
    begin : g_apb_type_else
   
      assign DataError = ((pwdata & pwdata_mask_golden) != (pwdata_cmp & pwdata_mask_golden)) && pwrite && psel && penable && pready && pclken;
      assign AddrError = (paddr != FileAddr_reg) && psel && penable && pready && pclken; 
      
      always @ (posedge pclk or negedge presetn)
      begin : p_ReportErrorsBhav
        if (!presetn)
          begin
            DataErrCnt = 0;
          end
        else
          if (DataError == 1'b1 || AddrError == 1'b1)
          begin
              $display (`DATA_ERR_MSG, $time, MESSAGE_TAG);
              if (AddrError == 1'b1) begin
                 $write   (`INDENT);
                 $display (`EXPECTED_ADDR, FileAddr_reg);     
                 $write   (`INDENT);
                 $display (`ACTUAL_ADDR, paddr);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end   
              
              if (DataError == 1'b1) begin
                 $write   (`INDENT);
                 $display (`ACTUAL_DATA, pwdata);
                 $write   (`INDENT);
                 $display (`EXPECTED_DATA, pwdata_cmp);
                 $write   (`INDENT);
                 $display (`WDATA_MASK, pwdata_mask_golden);
                 DataErrCnt = DataErrCnt + 1;       // increment data error counter
              end    
          end 
      end

    end
  endgenerate
    
                  
//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
  `ifdef ARM_ASSERT_ON
 
  wire pwdata_zero_strb;
  assign pwdata_zero_strb = (pwdata_strb == 4'h0) && pwrite && psel && penable && pready;
  
  assert_never #(1,0,"ERROR, PWDATA with STROBE ZERO")
    ovl_assert_pwdata_zero_strb
   (	
    .clk       (pclk),
    .reset_n   (presetn),
    .test_expr (pwdata_zero_strb));

  generate
    if (APB_TYPE == 2)
    begin
  assert_never #(0,0,"ERROR, PREADY LOW IN APB2") //fatal, to stop simulation
    ovl_assert_pready_low_in_apb2
   (	
    .clk       (pclk),
    .reset_n   (presetn),
    .test_expr (~pready));
      
  assert_never #(1,0,"ERROR, PSLVERR ASSERTED IN APB2")
    ovl_assert_pslverr_in_apb2
   (	
    .clk       (pclk),
    .reset_n   (presetn),
    .test_expr (pslverr));
      
    end
  endgenerate
    
  `endif
  

  `undef APB_CMD_MSG

  `undef ADDRESS_MSG
  `undef ACTUAL_ADDR
  `undef EXPECTED_ADDR
  `undef ACTUAL_DATA
  `undef EXPECTED_DATA
  `undef WDATA_MASK
  `undef ACTUAL_PPROT
  `undef EXPECTED_PPROT
  `undef ACTUAL_PSTRB
  `undef EXPECTED_PSTRB
 
  `undef INDENT

  `undef APB_CMD_WRITE
  `undef APB_CMD_READ 
  `undef APB_CMD_IDLE
  `undef OPENFILE_MSG
  `undef DATA_ERR_MSG

endmodule // FileReadCore

//------------------------------------------------------------------------------
