//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2016 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 205834
// File Date           :  2016-01-22 14:27:31 +0000 (Fri, 22 Jan 2016)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : This block takes information from the awfifo and
//           controls the merge buffer and wfifo
//------------------------------------------------------------------------------

module nic400_ib_sSpi_ib_upsize_wr_cntrl_1
  (
    // global interconnect signals
    aresetn,
    aclk,

    //Signals to the AWfifo
    awfifo_valid,
    awfifo_ready,
    awfifo_data,

    // Slave Port write  Channel
    wvalid_s,
    wready_s,
    wlast,

    // Merge buffer Contol signals
    merge,
    merge_clear,
    data_select,
    strb_skid_valid,

    // Signals from merge buffer
    wdata_merged,
    wstrb_merged,

    // Master port write channel
    wvalid_m,
    wready_m,
    wdata_m,
    wstrb_m,
    wlast_m
  );
 
`include "nic400_ib_sSpi_ib_defs_1.v"
`include "Axi.v"

  input                     aclk;
  input                     aresetn;

  //Signals from awfifo 
  output                    awfifo_ready;
  input                     awfifo_valid;
  input [15:0]              awfifo_data;

  // Slave Port write address Channel Signals
  input                     wvalid_s;         // WChannel Valid signal 
  output                    wready_s;         // WChannel Ready Output 
  input                     wlast;           // WChannel Last Signal

  // Merge buffer COntol Signals 
  output                    merge;           //Merge signal to the merge buffer
  output                    merge_clear;     //Signal no merge buffer to clear all strobes
  output  [1:0]                data_select;       //Selects appropriate part of the bus
  input                     strb_skid_valid;

  //Data from merge buffer
  input [63:0]              wdata_merged;    //merged wdata
  input [7:0]               wstrb_merged;    //merged strbs
  
  //Signals to the w channel
  output                    wvalid_m;     //Indicates data in merge buffer is ready
  input                     wready_m;     //W channel ready
  
  output [63:0]             wdata_m;
  output [7:0]              wstrb_m;
  output                    wlast_m;
  
 //------------------------------------------------------------------------
 // Wires  
 //------------------------------------------------------------------------

  //Handshake signals on relevant channels
  wire                      slavew_hndshk;      // W Channel Handshake
  wire                      wfifo_hndshk;       // wfifo Handshake
  wire                      awfifo_hndshk;      // awfifo Handshake

  //Signals decoded from the write address format block
  wire                      bypass_in;           //Indicates tranaction should only be upsized
  wire [2:0]                write_size;         //ASIZE of the incoming tranaction                      
  wire [2:0]                write_addr;        //write address of incoming transaction 
  wire [2:0]                write_addr_mask;   //address mask
  wire [3:0]                write_len_tb;       //Number of beats in the first INCR of a wrap 
  
 
  //Muxed Information from the awfifo or registers
  wire                      bypass;            
  wire [2:0]                a_size;              
  wire [2:0]                addr_mask;
  wire [2:0]                addr_internal;
  wire [3:0]                beat_count;            //Remaining beats of first incr
  

  //Signals used in the address calculation 
  wire [3:0]                addr_incr;          //Incremented adress value
  wire [2:0]                store_addr;        //Next address to store

  //These signals are used in the calculation of the correct position for WLAST
  wire [3:0]                beat_reg_next;                 //Next value for the beat counter
  wire                      beat_reg_wr_en;                //beat counter write
  wire                      wrap_fits_in;
  wire                      wrap_fits;
  wire                      split_wrap;
  wire                      split_wrap_in;  
  wire                      split_wrap_reg_en;
  wire                      split_wrap_reg_next;

  //Other signals used in the logic
  wire                      cross_boundary;         //Indicates that the address has crossed a boundary
  wire                      cross_boundary_sel;
  wire                      idle;
  wire                      insert_extra_wlast;
  wire                      wlast_sel;
  wire                      wfifo_valid_next;       //Skid buffer next valid value
  wire                      wfifo_should_push;       
  wire                      busy_reg_next;          //Next value for the busy register
  wire                      reg_wr_en;              //General register write enable
  wire                      reg_update;

 //------------------------------------------------------------------------
 // Registered values
 //------------------------------------------------------------------------

  //Registered values of data from address format block
  reg [2:0]                 addr_reg;
  reg [2:0]                 addr_mask_reg;
  reg                       cross_boundary_reg;
  reg [2:0]                 size_reg;
  reg                       bypass_reg;
  reg [3:0]                 beat_reg;                  //Number of beats in the first INCR of a wrap
  reg                       split_wrap_reg;
  reg                       wrap_fits_reg; 
  
  reg [3:0]                 size_incr;
  reg [2:0]                 addr_reg_nxt;              //Next address value after masking
  reg [1:0]                    data_select;               //Signal to merge buffer

  //Skid buffers
  
  reg                       wfifo_valid_reg;           //Skid buffer valid_reg

  //Other registers
  reg                       busy_reg;                  //Indicates logic is currently dealing with a tranaction
  reg                       merge_clear;               //Indicates the merge buffer should be cleared with the next merge  
  reg                       wlast_reg;                 //delayed version of WLAST on the Slace W channel
  
  
  
 //------------------------------------------------------------------------
 // Merge Buffer Control
 //------------------------------------------------------------------------

 //Handshaking signals
 assign slavew_hndshk = wvalid_s && wready_s;
 assign wfifo_hndshk  = wvalid_m  &&  wready_m;
 assign awfifo_hndshk = awfifo_valid  &&  awfifo_ready;

 //Merge on W Channel Handshake
 assign merge = slavew_hndshk;

 //The merge buffer is cleared every time a push is made to the wfifo
 always @(posedge aclk or negedge aresetn)
   begin : last_clear_p
     if (!aresetn)
        merge_clear <= 1'b0;
     else if (merge || wfifo_hndshk)
        merge_clear <= wfifo_hndshk;
   end

 //Idle when ~awfifo_valid and ~busy_reg
 assign idle = (~awfifo_valid && ~busy_reg);
 
 //Assign data_select output
 always @(*)
   begin : data_select_p

      
      data_select = {2{1'b0}};

      case (addr_internal[2:2])
            1'd0 :  data_select[0] = 1'b1;
            1'd1 :  data_select[1] = 1'b1;
     endcase
       
   
      //Unless idle (~awfifo_valid and ~busy_reg) in which select all byte bytes lanes
      if (idle)
         data_select = {2{1'b1}};
   end

 //------------------------------------------------------------------------
 // READY and VALID signals
 //------------------------------------------------------------------------
 
 //wready_s - always ready unless either of the skid buffers are full
 assign wready_s = ~strb_skid_valid & ~wfifo_valid_reg;

 //AWFIFO_ready
 //Always true if not busy
 assign awfifo_ready = ~busy_reg;

 //WFIFO_valid
 assign wfifo_valid_next = ((wvalid_m & ~wready_m) || wfifo_valid_reg) & ~wfifo_hndshk;

 //Registered version of wfifo_valid
 always @(posedge aclk or negedge aresetn)
   begin : wfifo_valid_seq
     if (!aresetn)
        wfifo_valid_reg <= 1'b0;
     else 
        wfifo_valid_reg <= wfifo_valid_next;
   end // WFIFO_valid_seq

 assign wfifo_should_push = (bypass || wlast_sel || cross_boundary_sel) & (busy_reg || awfifo_hndshk);
 
 assign wvalid_m = wfifo_should_push & (wfifo_valid_reg || merge || strb_skid_valid);

 assign reg_update = slavew_hndshk || (busy_reg_next && strb_skid_valid);

 //Create a necessary signals in case the above buffer is used
 always @(posedge aclk or negedge aresetn)
  begin : wfifo_data_int_seq
    if (!aresetn) begin
       wlast_reg <= 1'b0;
    end else if (slavew_hndshk) begin
       wlast_reg <= wlast;
    end
  end // wfifo_data_int_seq

  always @(posedge aclk or negedge aresetn)
  begin : cross_boundary_reg_seq
    if (!aresetn) begin
       cross_boundary_reg <= 1'b0;
    end else if (reg_update) begin
       cross_boundary_reg <= cross_boundary;
    end
  end // cross_boundary_reg_seq
 
 //------------------------------------------------------------------------
 // Busy Register
 //------------------------------------------------------------------------
 assign wlast_sel        = (wready_s) ? (wlast & wvalid_s) : wlast_reg;

 assign cross_boundary_sel = (wfifo_valid_reg) ? cross_boundary_reg : cross_boundary;

 assign busy_reg_next = ((awfifo_hndshk & ~(strb_skid_valid & wfifo_valid_reg) & ~(wlast_sel & wfifo_hndshk))) ? 1'b1 :
                        ((wfifo_hndshk & wlast_sel) ? 1'b0 : busy_reg);

 //Register for busy Signal
 always @(posedge aclk or negedge aresetn)
   begin : busy_seq
     if (!aresetn)
        busy_reg <= 1'b0;
     else 
        busy_reg <= busy_reg_next;
   end // busy_seq

 

 //------------------------------------------------------------------------
 // Decode Signals awfifo
 //------------------------------------------------------------------------
 //As an unaligned wrap is not flagged as unaligned if it is bypassed 
 //The bypass bit is used as an extra bit for  Write_len_tb
 assign bypass_in           = awfifo_data[`AWFIFO_BYPASS];
  
 
 assign split_wrap_in       = awfifo_data[`AWFIFO_UWRAP];
 assign write_len_tb        = awfifo_data[`AWFIFO_LEN_TB];
 
 assign write_size          = awfifo_data[`AWFIFO_SIZE];
 assign write_addr          = awfifo_data[`AWFIFO_ADDR];
 assign write_addr_mask     = awfifo_data[`AWFIFO_MASK];
 assign wrap_fits_in        = awfifo_data[`AWFIFO_WRAP_FITS];
 
 //------------------------------------------------------------------------
 // Encode Signals wfifo
 //------------------------------------------------------------------------

  

 //Data to be sent to the wfifo 
 assign wlast_m   = wlast_sel || insert_extra_wlast;

 assign wdata_m   = wdata_merged;
 assign wstrb_m   = wstrb_merged;
 
 
 //------------------------------------------------------------------------
 // beat counter
 //------------------------------------------------------------------------
 
 //This is used to ensure WLAST is correctly added to the last beat of a
 //unaligned wrap,

 assign insert_extra_wlast =  (~|beat_count & ~bypass & split_wrap); 
 assign beat_reg_next = (|beat_count & wfifo_hndshk) ? beat_count - 4'b1 : beat_count;

 //Write enable for beat_reg ... ensure it does not wrap
 assign beat_reg_wr_en = (wfifo_hndshk || awfifo_hndshk)& split_wrap; 
 
 //Count pushes to the WFIFO
 always @(posedge aclk or negedge aresetn)
     begin : beat_cnt_p
       if (!aresetn)
          beat_reg <= 4'b0;
       else if (beat_reg_wr_en)
          beat_reg <= beat_reg_next;
     end //beat_cnt;
     
 assign split_wrap_reg_en = awfifo_hndshk || (insert_extra_wlast & wfifo_hndshk);
 assign split_wrap_reg_next = split_wrap & ~(insert_extra_wlast & wfifo_hndshk);    

 always @(posedge aclk or negedge aresetn)
    begin : unaligned_p
      if (!aresetn)
         split_wrap_reg <= 1'b0;
      else if (split_wrap_reg_en)
         split_wrap_reg <= split_wrap_reg_next;
    end //beat_reg;

  
 
    
 
    


 //------------------------------------------------------------------------
 // address Tracker
 //------------------------------------------------------------------------

 //This tracks the current address to generate the correct data_select output to 
 //the merge buffer

 //Select either the incoming or registered values of data coming from awfifo
 assign addr_internal = (awfifo_hndshk) ? write_addr : addr_reg;
 assign addr_mask     = (awfifo_hndshk) ? write_addr_mask : addr_mask_reg;
 assign bypass        = (awfifo_hndshk) ? bypass_in : bypass_reg;
 assign a_size        = (awfifo_hndshk) ? write_size :  size_reg;
 assign wrap_fits     = (awfifo_hndshk) ? wrap_fits_in : wrap_fits_reg;
 
 
 assign beat_count    = (awfifo_hndshk) ? write_len_tb : beat_reg;
 assign split_wrap    = (awfifo_hndshk) ? split_wrap_in : split_wrap_reg;
 

 always @(*)
 begin : size_incr_p
    case (a_size)
       `AXI_ASIZE_8    : size_incr = {3'b0, 1'b1};
       `AXI_ASIZE_16   : size_incr = {2'b0, 2'b10};          
       `AXI_ASIZE_32   : size_incr = {1'b0, 3'b100};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : size_incr = {3'b0, 1'b1};    //Unused case arsize should never hit in normal operation
       default         : size_incr = {4'bx};
    endcase
  end

 //Masked address
 assign addr_incr = {1'b0, addr_internal} + size_incr;

 //addr_reg_incr 
 always @(*)
  begin : addr_reg_nxt_p
    integer index_i;
    for (index_i = 0; index_i < 3 ; index_i = index_i + 1)
    begin
      if (addr_mask[index_i] == 1'b1)
        addr_reg_nxt[index_i] = addr_incr[index_i];
      else
        addr_reg_nxt[index_i] = addr_internal[index_i];
    end
  end // addr_reg_nxt_p 

 assign store_addr = (reg_update) ? addr_reg_nxt : addr_internal;

 //Regsiter write enable 
 assign reg_wr_en = merge || awfifo_hndshk;

 //address Tracker
 always @(posedge aclk or negedge aresetn)
    begin : addr_seq
      if (!aresetn)
          addr_reg <= 3'b0;
      else if (reg_wr_en)
          addr_reg <= store_addr;
    end // addr_seq

  //address Mask 
 always @(posedge aclk or negedge aresetn)
    begin : store_seq
      if (!aresetn) begin
          addr_mask_reg <= 3'b0;
          bypass_reg <= 1'b0;
          size_reg <= 3'b0;
          wrap_fits_reg <= 1'b0;
      end else if (awfifo_hndshk) begin
          addr_mask_reg <= write_addr_mask;
          bypass_reg <= bypass_in;
          size_reg <= write_size;
          wrap_fits_reg <= wrap_fits_in;
      end
    end // store_seq
 
    
 

 //if addr_masked_incr & ~addr_masked we have overflowed either the bus width 
 // or a wrap boundary. Either way we need to push the merge buffer into the wfifo
 assign cross_boundary = (|((addr_incr ^ {1'b0, addr_internal}) & ({1'b1, ~addr_mask} ))) & ~(wrap_fits);

 
`ifdef ARM_ASSERT_ON
//------------------------------------------------------------------------------
// OVL Assertions 
//------------------------------------------------------------------------------
// Include Standard OVL Defines
`include "std_ovl_defines.h"


   //---------------------------------------------------------------------------
   // OVL_ASSERT: Beat_reg should always be 0 when split_wrap is not asserted
   //---------------------------------------------------------------------------

   // OVL_ASSERT_RTL  
   
   assert_never #(`OVL_FATAL,
                  `OVL_ASSERT,
                  "beat_reg != 0 when split_wrap not asserted")
   ovl_Beat_reg
     (
      .clk              (aclk),
      .reset_n          (aresetn),
      .test_expr        (~split_wrap && |beat_reg)
      );
    // OVL_ASSERT_END
    //---------------------------------------------------------------------------
 

   //---------------------------------------------------------------------------
   // OVL_ASSERT: write_control has received an unsupported AWSIZE
   //---------------------------------------------------------------------------
   // This OVL assertion should fire whenever the write_control receives an 
   // unsupported AWSIZE.
   //---------------------------------------------------------------------------
   // OVL_ASSERT_RTL
     
     wire        asize_out_range;
 
     assign      asize_out_range = (a_size > `AXI_ASIZE_32);
                                                                                             
     wire        illegal_size_incr;        // Illegal size_incr

     // Signal an illegal total_bytes
     assign illegal_size_incr =  (size_incr == {3'b0, 1'b1}) & asize_out_range;

     // OVL Assertion
     assert_never #(`OVL_FATAL,
                    `OVL_ASSERT,
                    "Input a_size to size_incr calculation has gone out of legal range")
     ovl_size_incr_illegal_asize
     (
       .clk        (aclk),
       .reset_n    (aresetn),
       .test_expr  (illegal_size_incr)
     );
   // OVL_ASSERT_END
   //---------------------------------------------------------------------------


`endif
endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"

//------------------------------------------------------------------------------
//  End of File : $RCSfile: UpsizeAxi_resp_cam_slice,v $
//------------------------------------------------------------------------------

