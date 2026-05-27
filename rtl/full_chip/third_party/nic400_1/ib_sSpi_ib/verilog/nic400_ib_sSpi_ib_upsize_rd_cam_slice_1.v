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
// File Revision       : 180147
// File Date           :  2014-09-03 14:39:19 +0100 (Wed, 03 Sep 2014)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : A slot of the storage for the ID and hazard
//           information required by the Upsizer R channel
//------------------------------------------------------------------------------

module nic400_ib_sSpi_ib_upsize_rd_cam_slice_1
  (
    // global interconnect signals
    aresetn,
    aclk,

    // ID inputs (to all slices)
    match_id,        //ID arriving on the Bchannel

    //Control Signals
    store,
    push_slice,
    pop_slice,
    update,
    match_pointer,

    //If a hazard has been detected
    hazard_in,
    hazard_pointer,

    //Data from ARformat Block
    archannel_data,
    
    //Inputs
    rlast_in,

    //Outputs
    hazard,
    match,
    addr_out,
    last_addr_match,
    valid,
    beat_complete,
    rdata_byte_mask

  );

`include "nic400_ib_sSpi_ib_defs_1.v"
`include "Axi.v"

  //------------------------------------------------------------------------------
  // IO 
  //------------------------------------------------------------------------------

  //System Inputs
  input                aresetn;
  input                aclk;

  input [1:0]          match_id;

  //Register update control signal
  input                store;
  input                push_slice;
  input                pop_slice;
  input                update;

  //Pointers to other Slices
  input [1:0]          hazard_pointer;
  input [1:0]          match_pointer;
  input                hazard_in;

  //Data in from Format Block
  input [16:0]         archannel_data;
  input                rlast_in;
  wire                 wrap_fits;
  
  //The updated address

  output               hazard;
  output               valid;
  output               match;
  output               addr_out;
  output               last_addr_match;
  output               beat_complete;
  output [3:0]        rdata_byte_mask;

 
 //------------------------------------------------------------------------
 // Registers
 //------------------------------------------------------------------------ 

  reg [1:0]            id_reg;
  reg [1:0]            pointer_reg;
  reg                  hazard_reg;
  reg                  valid_reg;
  reg                  last_reg;
  reg                          n_response_reg;
  reg                  wrap_fits_reg;
  reg [2:0]            addr_reg;
  reg [2:0]            addr_mask_reg;
  reg [2:0]            addr_mask_end_reg;
  reg [2:0]            size_reg;
  reg                  bypass_reg;
  reg [2:0]            addr_next;
  reg [3:0]            size_incr;

 //------------------------------------------------------------------------ 
 // Wires
 //------------------------------------------------------------------------

  wire [1:0]           next_id_reg;
  wire [1:0]           next_pointer_reg;

  //Register next values
  wire                 next_hazard_reg;
  wire                 next_valid_reg;
  wire                 next_last_reg;
  wire                         next_n_response_reg;
  wire [2:0]           next_addr_reg;

  //match Signals
  wire                 allowed_to_match;
  wire                 rid_match;
  wire                 arid_match;
  wire                 pointer_match;
  wire                 match_i;
  //Register write enables
  wire                 last_reg_wr_en;
  wire                 hazard_reg_wr_en;
  wire                 valid_reg_wr_en;
  wire                 n_response_reg_wr_en;
  wire                 default_reg_wr_en;
  wire                 addr_reg_wr;

  //Signals from AR Format Block
  wire [2:0]           size_in;
  wire                         n_response;
  wire                 bypass_in;
  wire [2:0]           addr;
  wire [2:0]           addr_mask;
  wire [2:0]           addr_mask_end;
  wire [1:0]           hazard_id;

  wire                 boundary_cross;
  wire [3:0]           addr_incr;
  wire                 can_complete;
  wire                 last_addr_match_int;
  wire                 beat_complete_i;
  
 //------------------------------------------------------------------------
 // Decode ARChannel_Data
 //------------------------------------------------------------------------

 assign size_in       = archannel_data[`ARDATA_SIZE];
 assign addr          = archannel_data[`ARDATA_ADDR];
 assign n_response    = archannel_data[`ARDATA_TWO];
 assign bypass_in     = archannel_data[`ARDATA_BYPASS];
 assign addr_mask     = archannel_data[`ARDATA_MASK];
 assign addr_mask_end = archannel_data[`ARDATA_END];
 assign hazard_id     = archannel_data[`ARDATA_ID];
 assign wrap_fits     = archannel_data[`ARDATA_WRAP_FITS];
 
 //------------------------------------------------------------------------
 // Main Code
 //------------------------------------------------------------------------

 //id match Logic
 assign rid_match = (match_id == id_reg);
 assign arid_match = (hazard_id == id_reg);
 
 //match Output - This slice can only report a match if the rid matches, the
 //slice is valid, doesn't report a hazard 
 assign allowed_to_match = valid_reg && ~hazard_reg;
 assign match_i = allowed_to_match && rid_match; 
 assign can_complete = match_i && ~|n_response_reg;
 assign match = match_i;
 
 //generate rdata byte mask
 reg  [3:0] size_mask;
 reg  [3:0] byte_mask;

 wire [3:0] rdata_byte_mask = byte_mask & {4{match_i}};

  always @(size_reg)
  begin : size_mask_p
    case (size_reg)
       3'b000    : size_mask = {4'b0001};
       3'b001    : size_mask = {4'b0011};
       3'b010    : size_mask = {4'b1111};
       3'b011    : size_mask = {4'b1111};
       3'b100    : size_mask = {4'b1111};
       3'b101    : size_mask = {4'b1111};
       3'b110    : size_mask = {4'b1111};
       3'b111    : size_mask = {4'b1111};
       default   : size_mask = {4'bx};
    endcase
  end
 
 
  always @(addr_reg or size_mask)
  begin : byte_mask_p
    case (addr_reg[1:0])
       2'b00    : byte_mask = {size_mask[3:0]};
       2'b01    : byte_mask = {size_mask[2:0],1'b0};
       2'b10    : byte_mask = {size_mask[1:0],2'b00};
       2'b11    : byte_mask = {size_mask[0],3'b000};
       default : byte_mask = {4'bx};
    endcase
  end

//------------------------------------------------------------------------
 // Linked List, hazard and last control logic
 //------------------------------------------------------------------------

 //hazard Detection output
 //All transactions to the same id are stored as linked lists. A slice can only
 //report a hazard if it is at the bottom of the list. The new slice then points to the
 //one reporting the hazard.
 assign hazard = arid_match && last_reg && valid_reg && ~(can_complete && pop_slice);

 //Normal Register Enable
 assign default_reg_wr_en = (store && push_slice);

 //id Logic
 assign next_id_reg = hazard_id;

 always @(posedge aclk)
   begin : id_seq
      if (default_reg_wr_en)
         id_reg <= next_id_reg;
   end // id_seq

 //Pointer Logic ... this points to the previous transaction from the same id
 //Pointer is only valid when hazard is
 assign next_pointer_reg = hazard_pointer;

  always @(posedge aclk)
   begin : pointer_seq
      if (default_reg_wr_en)
         pointer_reg <= next_pointer_reg;
   end // pointer_seq

 //Last Logic
 //This indicates that this is the last item in a hazard queue
 assign next_last_reg = (store) ? 1'b1 : 
                        ((arid_match) ? 1'b0 : last_reg);

 assign last_reg_wr_en = (default_reg_wr_en || (arid_match && valid_reg && push_slice));
 
  always @(posedge aclk)
   begin : last_seq
      if (last_reg_wr_en)
         last_reg <= next_last_reg;
   end // last_seq

 //hazard Logic
 //pointer match
 assign pointer_match = (pointer_reg == match_pointer);

 //The only reason for updating this register is for a store or
 //it been promoted to the top of the queue .. => it will be 0
 assign next_hazard_reg = (store) ? hazard_in : 1'b0;

 assign hazard_reg_wr_en = (default_reg_wr_en || (pointer_match && valid_reg && pop_slice && rid_match));

  always @(posedge aclk)
   begin : hazard_seq
      if (hazard_reg_wr_en)
         hazard_reg <= next_hazard_reg;
   end // hazard_seq

 //valid_Logic

 assign next_valid_reg = (store && push_slice) || (n_response_reg); 

 assign valid_reg_wr_en = default_reg_wr_en || (match_i && pop_slice);

   always @(posedge aclk or negedge aresetn)
   begin : valid_seq
      if (!aresetn) 
         valid_reg <= 1'b0;
      else if (valid_reg_wr_en)
         valid_reg <= next_valid_reg;
   end // valid_seq

  //Set valid ouput
  assign valid = valid_reg;

  //two response logic ... This is used to mask the first match duriong a wrap that
  //was unaligned to the wider bus;
  assign next_n_response_reg = (store && push_slice) ? n_response : (n_response_reg - 1'b1);

  assign n_response_reg_wr_en =  (rid_match && ~hazard_reg && rlast_in && update && beat_complete_i) || default_reg_wr_en;

  always @(posedge aclk or negedge aresetn)
   begin : two_resp_seq
     if (!aresetn) 
         n_response_reg <= {1{1'b0}};
     else if (n_response_reg_wr_en)
         n_response_reg <= next_n_response_reg;
   end // two_resp_seq

  //------------------------------------------------------------------------
  // addr Logic
  //------------------------------------------------------------------------

  //Detect if a voundary has been crossed 
  assign boundary_cross = |((addr_incr ^ {1'b0, addr_reg}) & {1'b1, ~addr_mask_reg}) & ~wrap_fits_reg;

  //determine value to increase address by
  always @(size_reg)
  begin : size_incr_p
    case (size_reg)
       `AXI_ASIZE_8    : size_incr = {3'b0, 1'b1};
       `AXI_ASIZE_16   : size_incr = {2'b0, 2'b10};          
       `AXI_ASIZE_32   : size_incr = {1'b0, 3'b100};     
       default         : size_incr = {4'bx};
    endcase
  end

  //Masked address
  assign addr_incr = {1'b0, addr_reg} + size_incr;

  //addr_reg_incr 
  always @(addr_reg or addr_mask_reg or addr_incr)
  begin : addr_reg_nxt_p
     integer index_i;
     for (index_i = 0; index_i < 3 ; index_i = index_i + 1)
     begin
       if ( addr_mask_reg[index_i] == 1'b1)
         addr_next[index_i] = addr_incr[index_i];
       else
         addr_next[index_i] = addr_reg[index_i];
     end
   end // addr_reg_nxt_p 

  //addr_req_wr
  assign addr_reg_wr = default_reg_wr_en || (match_i && update);

  assign next_addr_reg = (store && push_slice) ? addr : addr_next;

  //addr_next is calcuated outside this block.
  //This is to avoid unecessary duplication of logic;
  always @(posedge aclk or negedge aresetn)
   begin : addr_seq
     if (!aresetn) 
         addr_reg <= 3'b0;
     else if (addr_reg_wr)
         addr_reg <= next_addr_reg;
   end // addr_reg

  //address and size Output - only if matched
  assign addr_out = addr_reg[2] & {1{match_i}};
  assign last_addr_match_int = (((addr_reg & addr_mask_reg) == (addr_mask_end_reg & addr_mask_reg)) || bypass_reg) && ~|n_response_reg;
  assign last_addr_match = last_addr_match_int;
  assign beat_complete_i = boundary_cross || bypass_reg;
  assign beat_complete   = beat_complete_i;
  
  //The size, addr_Mask and addr_mask_end registers are only updated when Slice is loaded
  always @(posedge aclk or negedge aresetn)
   begin : ardata_seq
     if (!aresetn) begin
         addr_mask_reg <= 3'b0;
         addr_mask_end_reg <= 3'b0;
         size_reg  <= 3'b0;
         bypass_reg <= 1'b0;
         wrap_fits_reg <= 1'b0;
     end else if (default_reg_wr_en) begin
         addr_mask_reg <= addr_mask;
         addr_mask_end_reg  <= addr_mask_end;
         size_reg <= size_in;
         bypass_reg <= bypass_in;
         wrap_fits_reg <= wrap_fits;
     end
   end // ardata_seq

endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"

//------------------------------------------------------------------------------
//  End of File : $RCSfile: UpsizeAxi_rdata_cam_slice,v $
//------------------------------------------------------------------------------

