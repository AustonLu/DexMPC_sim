//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 173132
// File Date           :  2014-05-14 10:48:41 +0100 (Wed, 14 May 2014)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose: This module merges sub-width beats up to the wider data bus  
//           width of master or slave.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
//  Config :
//           o  sif Bus width        = 32 bits
//           o  mif bus width        = 64 bits
//           o  Sizing               = up
//           o  Data Width (Bytes)   = 8
//
//------------------------------------------------------------------------------

module nic400_ib_sSpi_ib_upsize_wr_merge_buffer_1
  (
  //Outputs
  wdata_out, 
  wstrb_out,
  merge_skid_valid,
  
  //Inputs
  wdata_in, 
  wstrb_in,
  data_select, 
  merge, 
  merge_clear,
   
  aclk, 
  aresetn
  );

  //System
  input                                 aclk;
  input                                 aresetn;

  //AXI W channel out 
  output [63:0]                         wdata_out;
  output [7:0]                          wstrb_out;
  output                                merge_skid_valid;

  //AXI W channel in
  input  [31:0]                         wdata_in;
  input  [3:0]                          wstrb_in;

  //Merge Control Info In
  input  [1:0]                          data_select;       //Selects appropriate part of the bus
  input                                 merge;
  input                                 merge_clear;
  
   //------------------------------------------------------------------------
   // Wires
   //------------------------------------------------------------------------   
 
   wire  [63:0]                         wide_wdata_in; 
   wire  [7:0]                          wide_wstrb_in;
   wire  [7:0]                          wide_wstrb_masked;
   wire  [7:0]                          wstrb_out_i;

   wire                                 update_strb;           //Signal to update all strobe registers
   wire                                 strb_skid_valid_wr;    //Write enable for the skid valid flag
   wire                                 strb_skid_valid_nxt;   //Next registered value
   wire                                 all_bytes;             //Identifies an accesss to all bytes

   //Byte merge signals
   
   wire                                 merge_byte_7;
   wire                                 merge_strb_7;
   wire                                 next_strb_7;

   wire                                 merge_byte_6;
   wire                                 merge_strb_6;
   wire                                 next_strb_6;

   wire                                 merge_byte_5;
   wire                                 merge_strb_5;
   wire                                 next_strb_5;

   wire                                 merge_byte_4;
   wire                                 merge_strb_4;
   wire                                 next_strb_4;

   wire                                 merge_byte_3;
   wire                                 merge_strb_3;
   wire                                 next_strb_3;

   wire                                 merge_byte_2;
   wire                                 merge_strb_2;
   wire                                 next_strb_2;

   wire                                 merge_byte_1;
   wire                                 merge_strb_1;
   wire                                 next_strb_1;

   wire                                 merge_byte_0;
   wire                                 merge_strb_0;
   wire                                 next_strb_0;


   //------------------------------------------------------------------------
   // Regs
   //------------------------------------------------------------------------   

   reg                                  strb_skid_valid;

   
   reg [7:0]                            merged_byte_7;
   reg                                  merged_strb_7;

   reg [7:0]                            merged_byte_6;
   reg                                  merged_strb_6;

   reg [7:0]                            merged_byte_5;
   reg                                  merged_strb_5;

   reg [7:0]                            merged_byte_4;
   reg                                  merged_strb_4;

   reg [7:0]                            merged_byte_3;
   reg                                  merged_strb_3;

   reg [7:0]                            merged_byte_2;
   reg                                  merged_strb_2;

   reg [7:0]                            merged_byte_1;
   reg                                  merged_strb_1;

   reg [7:0]                            merged_byte_0;
   reg                                  merged_strb_0;


   //------------------------------------------------------------------------
   // Main Code
   //------------------------------------------------------------------------

   assign wide_wdata_in     = {2{wdata_in}}; 
   assign wide_wstrb_masked = {2{wstrb_in}} | {8{all_bytes}}; 
   assign wide_wstrb_in     = {2{wstrb_in}};

   //Identify when all bytes are being written to
   assign all_bytes = data_select == {2{1'b1}};

   //Clear Strb when merge_clear or when there is a merge to all byte lanes 
   //or the skid buffer is valid on a paritular byte lane
   assign update_strb = merge_clear || (merge && all_bytes) 
                        || (~all_bytes && strb_skid_valid); 

   //The strobe valid flag is written whenever the skid reg. is written
   //or update_strb is high
   assign strb_skid_valid_wr = (merge && all_bytes) || update_strb;

   //Strb skid valid register
   assign strb_skid_valid_nxt = merge && all_bytes;

   always @(posedge aclk or negedge aresetn) 
     begin : strb_skid_valid_p
        if (!aresetn)  
           strb_skid_valid <= 1'b0;
        else if (strb_skid_valid_wr)
           strb_skid_valid <= strb_skid_valid_nxt;
     end

   //Set merge_skid_valid output
   assign merge_skid_valid = strb_skid_valid;
   
   //------------------------------------------------------------------------
   // Merge buffer logic
   //------------------------------------------------------------------------   


   

   //Data for byte 7
   assign merge_byte_7 = merge && data_select[1] && wide_wstrb_masked[7];
   assign wdata_out[63:56] = merge_byte_7 ? wide_wdata_in[63:56] : merged_byte_7;

   always @(posedge aclk)
     begin : byte_7_seq
       if (merge_byte_7)
          merged_byte_7 <= wide_wdata_in[63:56];
     end // byte_7_seq

   //Strobes for byte 7
   assign merge_strb_7 = merge_byte_7 || update_strb;
   
   assign wstrb_out_i[7] = merge_byte_7 ? wide_wstrb_in[7] :
                           (((strb_skid_valid && data_select[1]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_7 : 1'b0);
   assign wstrb_out[7] = wstrb_out_i[7];
   assign next_strb_7 = wstrb_out_i[7];

   always @(posedge aclk or negedge aresetn)
     begin : byte_7_strb_seq
       if (!aresetn)
          merged_strb_7 <= 1'b0;      
       else if (merge_strb_7)
          merged_strb_7 <= next_strb_7;
     end // byte_7_strb_seq

     

   //Data for byte 6
   assign merge_byte_6 = merge && data_select[1] && wide_wstrb_masked[6];
   assign wdata_out[55:48] = merge_byte_6 ? wide_wdata_in[55:48] : merged_byte_6;

   always @(posedge aclk)
     begin : byte_6_seq
       if (merge_byte_6)
          merged_byte_6 <= wide_wdata_in[55:48];
     end // byte_6_seq

   //Strobes for byte 6
   assign merge_strb_6 = merge_byte_6 || update_strb;
   
   assign wstrb_out_i[6] = merge_byte_6 ? wide_wstrb_in[6] :
                           (((strb_skid_valid && data_select[1]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_6 : 1'b0);
   assign wstrb_out[6] = wstrb_out_i[6];
   assign next_strb_6 = wstrb_out_i[6];

   always @(posedge aclk or negedge aresetn)
     begin : byte_6_strb_seq
       if (!aresetn)
          merged_strb_6 <= 1'b0;      
       else if (merge_strb_6)
          merged_strb_6 <= next_strb_6;
     end // byte_6_strb_seq

     

   //Data for byte 5
   assign merge_byte_5 = merge && data_select[1] && wide_wstrb_masked[5];
   assign wdata_out[47:40] = merge_byte_5 ? wide_wdata_in[47:40] : merged_byte_5;

   always @(posedge aclk)
     begin : byte_5_seq
       if (merge_byte_5)
          merged_byte_5 <= wide_wdata_in[47:40];
     end // byte_5_seq

   //Strobes for byte 5
   assign merge_strb_5 = merge_byte_5 || update_strb;
   
   assign wstrb_out_i[5] = merge_byte_5 ? wide_wstrb_in[5] :
                           (((strb_skid_valid && data_select[1]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_5 : 1'b0);
   assign wstrb_out[5] = wstrb_out_i[5];
   assign next_strb_5 = wstrb_out_i[5];

   always @(posedge aclk or negedge aresetn)
     begin : byte_5_strb_seq
       if (!aresetn)
          merged_strb_5 <= 1'b0;      
       else if (merge_strb_5)
          merged_strb_5 <= next_strb_5;
     end // byte_5_strb_seq

     

   //Data for byte 4
   assign merge_byte_4 = merge && data_select[1] && wide_wstrb_masked[4];
   assign wdata_out[39:32] = merge_byte_4 ? wide_wdata_in[39:32] : merged_byte_4;

   always @(posedge aclk)
     begin : byte_4_seq
       if (merge_byte_4)
          merged_byte_4 <= wide_wdata_in[39:32];
     end // byte_4_seq

   //Strobes for byte 4
   assign merge_strb_4 = merge_byte_4 || update_strb;
   
   assign wstrb_out_i[4] = merge_byte_4 ? wide_wstrb_in[4] :
                           (((strb_skid_valid && data_select[1]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_4 : 1'b0);
   assign wstrb_out[4] = wstrb_out_i[4];
   assign next_strb_4 = wstrb_out_i[4];

   always @(posedge aclk or negedge aresetn)
     begin : byte_4_strb_seq
       if (!aresetn)
          merged_strb_4 <= 1'b0;      
       else if (merge_strb_4)
          merged_strb_4 <= next_strb_4;
     end // byte_4_strb_seq

     

   //Data for byte 3
   assign merge_byte_3 = merge && data_select[0] && wide_wstrb_masked[3];
   assign wdata_out[31:24] = merge_byte_3 ? wide_wdata_in[31:24] : merged_byte_3;

   always @(posedge aclk)
     begin : byte_3_seq
       if (merge_byte_3)
          merged_byte_3 <= wide_wdata_in[31:24];
     end // byte_3_seq

   //Strobes for byte 3
   assign merge_strb_3 = merge_byte_3 || update_strb;
   
   assign wstrb_out_i[3] = merge_byte_3 ? wide_wstrb_in[3] :
                           (((strb_skid_valid && data_select[0]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_3 : 1'b0);
   assign wstrb_out[3] = wstrb_out_i[3];
   assign next_strb_3 = wstrb_out_i[3];

   always @(posedge aclk or negedge aresetn)
     begin : byte_3_strb_seq
       if (!aresetn)
          merged_strb_3 <= 1'b0;      
       else if (merge_strb_3)
          merged_strb_3 <= next_strb_3;
     end // byte_3_strb_seq

     

   //Data for byte 2
   assign merge_byte_2 = merge && data_select[0] && wide_wstrb_masked[2];
   assign wdata_out[23:16] = merge_byte_2 ? wide_wdata_in[23:16] : merged_byte_2;

   always @(posedge aclk)
     begin : byte_2_seq
       if (merge_byte_2)
          merged_byte_2 <= wide_wdata_in[23:16];
     end // byte_2_seq

   //Strobes for byte 2
   assign merge_strb_2 = merge_byte_2 || update_strb;
   
   assign wstrb_out_i[2] = merge_byte_2 ? wide_wstrb_in[2] :
                           (((strb_skid_valid && data_select[0]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_2 : 1'b0);
   assign wstrb_out[2] = wstrb_out_i[2];
   assign next_strb_2 = wstrb_out_i[2];

   always @(posedge aclk or negedge aresetn)
     begin : byte_2_strb_seq
       if (!aresetn)
          merged_strb_2 <= 1'b0;      
       else if (merge_strb_2)
          merged_strb_2 <= next_strb_2;
     end // byte_2_strb_seq

     

   //Data for byte 1
   assign merge_byte_1 = merge && data_select[0] && wide_wstrb_masked[1];
   assign wdata_out[15:8] = merge_byte_1 ? wide_wdata_in[15:8] : merged_byte_1;

   always @(posedge aclk)
     begin : byte_1_seq
       if (merge_byte_1)
          merged_byte_1 <= wide_wdata_in[15:8];
     end // byte_1_seq

   //Strobes for byte 1
   assign merge_strb_1 = merge_byte_1 || update_strb;
   
   assign wstrb_out_i[1] = merge_byte_1 ? wide_wstrb_in[1] :
                           (((strb_skid_valid && data_select[0]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_1 : 1'b0);
   assign wstrb_out[1] = wstrb_out_i[1];
   assign next_strb_1 = wstrb_out_i[1];

   always @(posedge aclk or negedge aresetn)
     begin : byte_1_strb_seq
       if (!aresetn)
          merged_strb_1 <= 1'b0;      
       else if (merge_strb_1)
          merged_strb_1 <= next_strb_1;
     end // byte_1_strb_seq

     

   //Data for byte 0
   assign merge_byte_0 = merge && data_select[0] && wide_wstrb_masked[0];
   assign wdata_out[7:0] = merge_byte_0 ? wide_wdata_in[7:0] : merged_byte_0;

   always @(posedge aclk)
     begin : byte_0_seq
       if (merge_byte_0)
          merged_byte_0 <= wide_wdata_in[7:0];
     end // byte_0_seq

   //Strobes for byte 0
   assign merge_strb_0 = merge_byte_0 || update_strb;
   
   assign wstrb_out_i[0] = merge_byte_0 ? wide_wstrb_in[0] :
                           (((strb_skid_valid && data_select[0]) || (~strb_skid_valid && ~update_strb)) ? merged_strb_0 : 1'b0);
   assign wstrb_out[0] = wstrb_out_i[0];
   assign next_strb_0 = wstrb_out_i[0];

   always @(posedge aclk or negedge aresetn)
     begin : byte_0_strb_seq
       if (!aresetn)
          merged_strb_0 <= 1'b0;      
       else if (merge_strb_0)
          merged_strb_0 <= next_strb_0;
     end // byte_0_strb_seq

     

endmodule

