// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2006-2013 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : $Revision: $
//
// Date                   :
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : Monitor number of outstanding transactions
//
// Description : 
//
// --========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module axi_ot_mon(
  awvalid,
  awready,

  wvalid,
  wready,
  wlast,

  bvalid,
  bready,

  arvalid,
  arready,

  rvalid,
  rready,
  rlast,

  aclk,
  aresetn
);

//------------------------------------------------------------------------------
// Block Parameters
//------------------------------------------------------------------------------

  parameter UNIT_NAME   = "axi_ot_mon";  // name for trace instance

// Clock and Reset in AXI domain
input  awvalid;
input  awready;

input  wvalid;
input  wready;
input  wlast;

input  bvalid;
input  bready;

input  arvalid;
input  arready;

input  rvalid;
input  rready;
input  rlast;

input  aclk;
input  aresetn;

//------------------------------------------------------------------------
// Main Code
//------------------------------------------------------------------------

wire inc_write_ot = awvalid & awready;
wire dec_write_ot = bvalid & bready;

reg  [7:0]  write_ot;

wire [7:0]  next_write_ot = ( inc_write_ot & ~dec_write_ot) ? write_ot + 1'b1 :
                            (~inc_write_ot &  dec_write_ot) ? write_ot - 1'b1 :
                                                              write_ot;

always @(posedge aclk or negedge aresetn)
begin
  if (~aresetn)
  begin
    write_ot <= 8'b0;
  end
  else
  begin
    write_ot <= next_write_ot;
  end
end


wire inc_read_ot = arvalid & arready;
wire dec_read_ot = rvalid & rready & rlast;

reg  [7:0]  read_ot;

wire [7:0]  next_read_ot = ( inc_read_ot & ~dec_read_ot) ? read_ot + 1'b1 :
                           (~inc_read_ot &  dec_read_ot) ? read_ot - 1'b1 :
                                                           read_ot;

always @(posedge aclk or negedge aresetn)
begin
  if (~aresetn)
  begin
    read_ot <= 8'b0;
  end
  else
  begin
    read_ot <= next_read_ot;
  end
end


wire inc_num_reads = rvalid & rready;

reg  [31:0]  num_reads;

wire [31:0]  next_num_reads = ( inc_num_reads) ? num_reads + 1'b1 : num_reads;

always @(posedge aclk or negedge aresetn)
begin
  if (~aresetn)
  begin
    num_reads <= 32'b0;
  end
  else
  begin
    num_reads <= next_num_reads;
  end
end


wire inc_num_writes = wvalid & wready;

reg  [31:0]  num_writes;

wire [31:0]  next_num_writes = ( inc_num_writes) ? num_writes + 1'b1 : num_writes;

always @(posedge aclk or negedge aresetn)
begin
  if (~aresetn)
  begin
    num_writes <= 32'b0;
  end
  else
  begin
    num_writes <= next_num_writes;
  end
end


reg  [31:0]  num_cycles;

wire [31:0]  next_num_cycles = num_cycles + 1'b1;

always @(posedge aclk or negedge aresetn)
begin
  if (~aresetn)
  begin
    num_cycles <= 32'b0;
  end
  else
  begin
    num_cycles <= next_num_cycles;
  end
end

final
begin
  $display("%s: num_cycles=%d num_writes=%d num_reads=%d", UNIT_NAME, num_cycles, num_writes, num_reads);
end


endmodule
