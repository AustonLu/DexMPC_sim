//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 127275
// File Date           :  2012-03-19 15:37:15 +0000 (Mon, 19 Mar 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose             : This block formats the AW channel in to the 
//                       appropriate format for the outgoing bus width
//------------------------------------------------------------------------------
//
// This is a component of asib named sSpi_ib
// and is axi4:32bit to  axi4:64bit upsizing
//



module nic400_ib_sSpi_ib_upsize_wr_addr_fmt_1
  (
    // global interconnect signals
    aresetn,
    aclk,


    //Signals to/from the Bchannel
    bdata_data,
    bdata_valid,
    bdata_ready,

    //Signals to the Write Control Block
    awfmt_valid,
    awfmt_ready,
    awfmt_data,
    

    // Slave Port Address Channel
    awid_s,
    awaddr_s,
    awlen_s,
    awsize_s,
    awburst_s,
    awvalid_s,
    awready_s,
    awprot_s,
    awcache_s,
    awlock_s,

    // Master Port Address Channel
    awid_m,
    awaddr_m,
    awlen_m,
    awsize_m,
    awburst_m,
    awvalid_m,
    awready_m,
    awprot_m,
    awcache_m,
    awlock_m          

  );

  //------------------------------------------------------------------------------
  // parameters
  //------------------------------------------------------------------------------
`include "nic400_ib_sSpi_ib_defs_1.v"
`include "Axi.v"

  input                    aclk;
  input                    aresetn;

  output [2:0]             bdata_data;
  output                   bdata_valid;
  input                    bdata_ready;

  //Signals to Write Control Block
  input                    awfmt_ready;
  output                   awfmt_valid;
  output [15:0]            awfmt_data;
  

  // Slave Port Write Address Channel Signals
  input [1:0]              awid_s;            // transaction address ID
  input [31:0]             awaddr_s;          // transaction start address
  input [7:0]              awlen_s;           // transaction length
  input [2:0]              awsize_s;          // transaction transfer size
  input [1:0]              awburst_s;         // transaction burst type
  input [3:0]              awcache_s;         // transaction cache value
  input [2:0]              awprot_s;          // transaction prot value
  input                    awvalid_s;         // address transfer valid
  input                    awlock_s;          // address transfer locked
  output                   awready_s;         // ready for address transfer


  // Master Port Write Address Channel Signals
  output [1:0]              awid_m;            // transaction address ID
  output [31:0]             awaddr_m;          // transaction start address
  output [7:0]              awlen_m;           // transaction length
  output [2:0]              awsize_m;          // transaction transfer size
  output [1:0]              awburst_m;         // transaction burst type
  output [3:0]              awcache_m;         // transaction cache value
  output [2:0]              awprot_m;          // transaction prot value
  output                    awlock_m;          // address transfer locked
  output                    awvalid_m;         // address transfer valid
  input                     awready_m;         // ready for address transfer

  


 //------------------------------------------------------------------------
 // Registers
 //------------------------------------------------------------------------
 
  // Output value registers
  reg [31:0]                awaddro;              // transaction start address (int)
  reg [7:0]                 awleno;               // transaction length (int)
  reg [2:0]                 awsizeo;              // transaction transfer size (int)
  reg [1:0]                 awbursto;             // transaction burst type (int)
  reg [1:0]                 awido;                // transaction address ID
  reg [3:0]                 awcacheo;             // transaction cache value
  reg [2:0]                 awproto;              // transaction prot value
  reg                       awlocko;              // tranaction lock value

  reg                       excl_override_reg;     // value of the exclusive override flag
  reg                       busy_reg;              // flag to indicate that there is a transaction in progress  
  
  //Registers used when processing unaligned wraps
  reg [9:0]                 wrap_bytes_remaining_reg; //bytes remaining to be processed
  reg [2:0]                 write_mask;            //Mask generated for write counter
  
  wire                         n_response;           //Passed to the write response block to indicate the
                                                  //number of b responses expected back from the slave                                               

  //Signals involved in working out the number of bytes in a transfer
  reg [9:0]                 total_bytes;          //Total bytes available in transfer
  reg [9:0]                 total_bytes_masked;    //Total bytes accounting for unaligned address
  
  //Signals used in upsizing aligned wraps
  reg [2:0]                 wrapsize;             //Size of the next transaction if it's a wrap
  reg [2:0]                 wrapfitsize;          //Size of the next transaction if it's a wrap and fits the outgoing bus
  reg [3:0]                 wraplen;              //Length of the next transaction if it's a wrap
  reg [3:0]                 wrapalignmask;         //Mask used to check if a wrap is aligned
  
  //Signals used if upsizing an unaligned wrap
  reg                       wrap_split_reg;
  
  //Size of transaction if it's an INCR
  reg [2:0]                 incrsize;

  
  
 //------------------------------------------------------------------------
 // Wires
 //------------------------------------------------------------------------

  //Handshake signals
  wire                      slave_hndshk;
  wire                      master_hndshk;        // Signals indicate when V/R handshake

  //Bypass signal
  wire                      bypass;               // Indicates this transaction shouldn't be upsized
  
                                            
                                                  
  wire [31:0]               awaddr_aligned;                                                  

  //Signals involved in working out the number of bytes in a transfer
  wire [10:0]                total_bytes_ext;      //bit extended version of total_bytes

  //Signals used in upsizing aligned wraps
  wire [9:0]                wrap_boundary_mask;   //Wrap boundary mask

  wire                      wrap_aligned;         //Wrap is aligned
  wire                      wrap_is_incr;         //Wrap is aligned to its boundary and can be treated as an INCR
  wire                      wrap_split;           //Wrap is unaligned
  wire                      wrap_fits;            //Wrap fits in outgoing bus
  wire [9:0]                wrap_fits_mask;       //Mask used to check if a wrap fits in outgoing bus
  wire [3:0]                working_addr;         //aligned Address

  //Signals used if upsizing an unaligned wrap
  wire                      wrap_split_reg_nxt;
  wire                      wrap_split_reg_wr_en;
  wire                      wrap_info_write_en;
  wire [9:0]                next_wrap_bytes_remaining_reg;
  wire [9:0]                addr_less_one;
  
  wire [7:0]                wraplen_i;
  
  wire [7:0]                awlen_1;

  //Size of transaction if it's an INCR
  wire [7:0]                incrlen;

  //Signals used in calculating the number of bytes in a transfer
  wire [9:0]                bytes_to_transfer;
  wire [17:0]                bytes_to_transfer_large;
  wire [9:0]                bytes_to_transfer_wrap1;

  //Signals used in calulating the length of an INCR transaction
  wire [2:0]                offset_address;       //Offset Address
  wire [7:0]                incrlenmaxsize;       //lenmaxsize plus one

  

  wire [3:0]                final_address;        //the highest address accessed by the transfer
  wire                      overflow;             //Indicate if the transaction crosses boundary
  
  //Signals used while calculating size and length of new INCR transaction
  wire                      bytes_lt_one_byte;
  wire                      bytes_lt_two_byte;
  wire                      bytes_lt_two_half;
  wire                      bytes_lt_four_half;
  wire                      half_carry;
  wire                      half_carry_double;
  wire                      bytes_lt_four_word;
  wire                      bytes_lt_eight_word;
  wire [2:0]                word_carry;
  wire                      word_carry_double;
  

  wire                      buffers_ok;        //indicates there is space in all required buffers
  wire                      new_transaction;   // indicates the start of a new transaction
  wire                      trans_in_progress; // indicates that there is a transaction in progress
  wire                      new_trans_avail;   // indicates a new transaction is available to start
  wire                      trans_complete;    // indicates the last transaction from current incoming transaction
  wire                      next_busy_reg;     // next valud of busy_reg
  wire                      busy_reg_wr_en;    // enable for the busy register
  wire                      excl_override;     // current value of the override flag



  wire [9:0]                bytes_in_transfer;
  wire [9:0]                bytes_in_transfer_aligned;

 //------------------------------------------------------------------------
 // Main Code
 //------------------------------------------------------------------------

 //Handshaking signals
 assign slave_hndshk = awvalid_s & awready_s;
 assign master_hndshk = awvalid_m & awready_m;

 
 //------------------------------------------------------------------------
 // Signals to Write Control Block
 //------------------------------------------------------------------------

 
 
 assign awfmt_data[`AWFIFO_LEN_TB]    = awleno[3:0];
 assign awfmt_data[`AWFIFO_UWRAP]     = wrap_split ;
 assign awfmt_data[`AWFIFO_BYPASS]    = bypass || (awburst_s == `AXI_ABURST_FIXED);
 assign awfmt_data[`AWFIFO_ADDR]      = awaddr_s[2:0];
 assign awfmt_data[`AWFIFO_SIZE]      = awsize_s;
 assign awfmt_data[`AWFIFO_MASK]      = write_mask;
 assign awfmt_data[`AWFIFO_WRAP_FITS] = wrap_fits;

 assign awfmt_valid = new_transaction;

 //Generate the mask for the write counter
 always @(*)
  begin : p_new_addr_incr_en_w
  
    write_mask = {3{1'b0}};
  
    case (awburst_s)
      `AXI_ABURST_FIXED : write_mask = {3{1'b0}};
      `AXI_ABURST_WRAP  : write_mask = total_bytes[2:0];
      `AXI_ABURST_INCR  : write_mask = {3{1'b1}};
      default           : write_mask = {3{1'bx}};
    endcase
  end // block : p_new_addr_incr_en_w

 


 //------------------------------------------------------------------------
 // Signals to BChannel
 //------------------------------------------------------------------------

 assign bdata_data = {awid_s, n_response};

 assign bdata_valid = new_transaction;

 
 
 //No burst breaking other than wraps
 //Note upsizer cannot create long bursts
 assign n_response = wrap_split;

 

 //------------------------------------------------------------------------
 // First Transaction Detection
 //------------------------------------------------------------------------

 //The first transaction occurs the first time there is space in any buffers
 //after the rising edge of the awvalid_s

 //Determine if there is space in the buffers to complete
 
 assign buffers_ok = bdata_ready & awfmt_ready;
 

 //Determine if this is the last transaction in the sequence
 
 assign  trans_complete = ~((wrap_split & ~wrap_split_reg) );
 

 //Transaction in progress flag ... either when new_transaction or busy_reg
 assign trans_in_progress = new_transaction | busy_reg;

 //Determine the start of a new transaction .. starts when there is space in buffers and space to start
 assign new_transaction = new_trans_avail & buffers_ok;

 //Flag to show there is a new transaction available
 assign new_trans_avail = awvalid_s & ~busy_reg;

 //Registers to hold the current state of the format block
 //busy is high from the new transaction until the handshake of
 assign next_busy_reg = (trans_complete & slave_hndshk)  ? 1'b0 :
                        ((new_transaction & ~slave_hndshk) ? 1'b1 : busy_reg);

 assign busy_reg_wr_en = busy_reg ^ next_busy_reg;

 always @(posedge aclk or negedge aresetn)
   begin : busy_reg_p
      if (!aresetn) begin
          busy_reg <= 1'b0;
      end else if (busy_reg_wr_en) begin
          busy_reg <= next_busy_reg;
      end
    end

 //------------------------------------------------------------------------
 // Exclusive override reg
 //------------------------------------------------------------------------

 //This register flags up when exclusive transactions should be over-ridden

 //Determine the value of exclusive override for this transaction
 assign excl_override = (new_transaction) ? n_response | (|awleno[7:4]) : excl_override_reg;

 always @(posedge aclk or negedge aresetn)
   begin : excl_override_reg_p
      if (!aresetn) begin
          excl_override_reg <= 1'b0;
      end else if (new_transaction) begin
          excl_override_reg <= excl_override;
      end
    end

 //------------------------------------------------------------------------
 // Output AWCHANNEL assignments
 //------------------------------------------------------------------------

 //Master Port Write Address Channel Signals Assignments


 //If the buffer is valid .. always take that value
 assign awid_m =     awido;
 assign awcache_m =  awcacheo;
 assign awprot_m =   awproto;
 assign awlen_m =    awleno;
 assign awsize_m =   awsizeo;
 assign awaddr_m =   awaddro;
 assign awburst_m =  awbursto;
 assign awlock_m =   awlocko;

 //Valid Output
 assign awvalid_m = awvalid_s && trans_in_progress;

 //Ready Output
 assign awready_s = master_hndshk && trans_complete;

 always @(*) begin

      awleno = incrlen;
      awsizeo = incrsize;
      awbursto = `AXI_ABURST_INCR;
      awido = awid_s;
      awcacheo = awcache_s;
      awproto = awprot_s;
      awaddro = awaddr_aligned;
      
      awlocko = (awlock_s && (~excl_override));
      


      if (!wrap_split_reg) begin

         awaddro = awaddr_s;
         if (wrap_aligned) begin
            awleno = wraplen_i;
            awsizeo = wrapsize;
            awbursto = `AXI_ABURST_WRAP;
         end else if (bypass) begin
            awleno = awlen_s;
            awsizeo = awsize_s;
            awbursto = awburst_s;
         end else if (wrap_fits) begin
            awaddro = awaddr_aligned;
            awleno = awlen_1;
            awsizeo = wrapfitsize;
            awbursto = `AXI_ABURST_INCR;
         end
      end
  end

  
 assign wraplen_i = {4'b0000,wraplen};
 assign awlen_1 = {4'b0000,`AXI_ALEN_1};

 assign addr_less_one = awaddr_s[9:0] - {{9{1'b0}},1'b1};
 
 //Store the total number of bytes remaining for the second part of a wrap
 assign next_wrap_bytes_remaining_reg = (addr_less_one & total_bytes);

 assign wrap_info_write_en = wrap_split & master_hndshk;

 //Number of bytes to complete in the second wrap transaction.
 //Only updated when an unaligned wrap is detected
 always @(posedge aclk or negedge aresetn)
   begin : wrap_bytes_remaining_reg_p
      if (!aresetn) begin
          wrap_bytes_remaining_reg <= 10'b0;
      end else if (wrap_info_write_en) begin
          wrap_bytes_remaining_reg <= next_wrap_bytes_remaining_reg;
      end
    end

 //Registered address aligned to wrap boundary
 assign awaddr_aligned = {awaddr_s[31:10],((awaddr_s[9:0]) & (~total_bytes))};


 //Registered version of unaligned_wrap used to indicate the above buffer
 //value should be used
 assign wrap_split_reg_nxt = wrap_split & ~(wrap_split_reg);

 assign wrap_split_reg_wr_en = master_hndshk;

 always @(posedge aclk or negedge aresetn)
   begin : wrap_split_p
      if (!aresetn)
          wrap_split_reg <= 1'b0;
      else if (wrap_split_reg_wr_en)
          wrap_split_reg <= wrap_split_reg_nxt;
    end



 //------------------------------------------------------------------------
 // Len and Size Calculation - Common Logic
 //------------------------------------------------------------------------
  
 
 
 assign bypass = (awburst_s == `AXI_ABURST_FIXED ) || ~awcache_s[1] || (awlen_s == `AXI_ALEN_1);
 

 //Total_bytes .. this is calculated from SIZE and LENGTH
 always @(*)
  begin : total_bytes_p
    case (awsize_s)
       `AXI_ASIZE_8    : total_bytes = {2'b0, awlen_s};
       `AXI_ASIZE_16   : total_bytes = {1'b0, awlen_s, 1'b1};
       `AXI_ASIZE_32   : total_bytes = {awlen_s, 2'b11};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : total_bytes = {2'b0, awlen_s};    //Unused case awsize should never hit in normal operation
       default         : total_bytes = {10'bx};
    endcase
  end

 //------------------------------------------------------------------------
 // Len and Size Calculation - Wraps
 //------------------------------------------------------------------------

 //Extend to total bytes... as bus is wider
 assign total_bytes_ext = {1'b0,total_bytes};

 //Wrap LEN and SIZE Selector
 always @(*)
  begin : wrap_size_len
   if (total_bytes_ext[3]) begin
            wrapfitsize = `AXI_ASIZE_128;
            wrapsize = `AXI_ASIZE_64;
            wraplen = total_bytes_ext[6:3];
            wrapalignmask = {1'b0, 3'b111};
  end else if (total_bytes_ext[2]) begin
            wrapfitsize = `AXI_ASIZE_64;
            wrapsize = `AXI_ASIZE_32;
            wraplen = total_bytes_ext[5:2];
            wrapalignmask = {2'b0, 2'b11};
  end else if (total_bytes_ext[1]) begin
            wrapfitsize = `AXI_ASIZE_32;
            wrapsize = `AXI_ASIZE_16;
            wraplen = total_bytes_ext[4:1];
            wrapalignmask = {3'b0, 1'b1};
  end else if (total_bytes_ext[0])begin
            wrapfitsize = `AXI_ASIZE_16;
            wrapsize = `AXI_ASIZE_8;
            wraplen = total_bytes_ext[3:0];
            wrapalignmask = 4'b0;
  end else begin
            wrapfitsize = 3'bx;
            wrapsize = 3'bx;
            wraplen = 4'bx;
            wrapalignmask = 4'bx;
        end
  end

 //Set the working Address
 assign working_addr = awaddr_s[3:0] & wrapalignmask;

 //Create a mask according to the size of the outgoing data bus
 assign wrap_fits_mask = {{7{1'b1}}, 3'b000};
 

 //Calculate what type of wrap this is
 assign  wrap_fits = ~|(total_bytes & wrap_fits_mask) & (awburst_s == `AXI_ABURST_WRAP);
 assign  wrap_is_incr = ~|(awaddr_s[9:0] & total_bytes);
 assign  wrap_aligned = ~|working_addr & (awburst_s == `AXI_ABURST_WRAP) & ~bypass & ~wrap_is_incr & ~wrap_fits ;
 assign  wrap_split = ((|working_addr)) & (awburst_s == `AXI_ABURST_WRAP) & ~bypass & ~wrap_fits;

 

 //------------------------------------------------------------------------
 // Main Len and Size Calculation Loop
 //------------------------------------------------------------------------

 //Set the wrap boundary mask  -- Due to AXI limitations on wraps this is the same as total_bytes
 assign wrap_boundary_mask = total_bytes;


 //Set the number of bytes to transfer .. There are three options:
 // 1) INCR = total_bytes;
 // 2) WRAP .. unaligned (cycle 1) .. bytes up to wrap boundary
 // 3) WRAP .. unaligned (cycle 2) .. bytes as store in wrap_bytes_remaining register

 //Extra bytes that are unnecessary (due to unlligned adresses are removed by masking)
 assign bytes_to_transfer_wrap1 = ~(awaddr_s[9:0]) & wrap_boundary_mask;

 //Select appropriate value
 assign bytes_to_transfer = (wrap_split_reg) ? wrap_bytes_remaining_reg
                            : ((awburst_s == `AXI_ABURST_WRAP) ? bytes_to_transfer_wrap1
                            : total_bytes_masked);

 

 //Calculate the total number of bytes to transfer ... taking account of alignment
 always @(*)
  begin : total_bytes_masked_p
    case (awsize_s)
       `AXI_ASIZE_8    : total_bytes_masked = {2'b0, awlen_s};
       `AXI_ASIZE_16   : total_bytes_masked = {1'b0, awlen_s, ~awaddr_s[0]};
       `AXI_ASIZE_32   : total_bytes_masked = {awlen_s, ~awaddr_s[1:0]};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : total_bytes_masked = {2'b0, awlen_s};    //Unused case awsize should never hit in normal operation
       default         : total_bytes_masked = {10{1'bx}};
    endcase
 end

 

 //Determine Offset Address
 assign offset_address = (wrap_split_reg) ? awaddr_aligned[2:0] : 
                            awaddr_s[2:0];

 //Determine if the data to be transfered crosses any boundaries
 assign  half_carry =  bytes_to_transfer[0] & offset_address[0];
 assign  half_carry_double = half_carry & bytes_to_transfer[1];
 assign  word_carry =  {1'b0, bytes_to_transfer[1:0]} + {1'b0, offset_address[1:0]};
 assign  word_carry_double = word_carry[2] & bytes_to_transfer[2];
 

 //Data threshold flags..
 assign  bytes_lt_one_byte   = ~|bytes_to_transfer;
 assign  bytes_lt_two_byte   = ~|bytes_to_transfer[9:1];
 assign  bytes_lt_two_half   = ~|bytes_to_transfer[9:1] & ~half_carry;
 assign  bytes_lt_four_half  = ~|bytes_to_transfer[9:2] & ~half_carry_double;
 assign  bytes_lt_four_word  = ~|bytes_to_transfer[9:2] & ~word_carry[2];
 assign  bytes_lt_eight_word = ~|bytes_to_transfer[9:3] & ~word_carry_double;
 

 //Determine the size of the transfer
 always @(*)
  begin : size_lookup

        //Default is full master bus size
        incrsize = `AXI_ASIZE_64;

        if (bytes_lt_one_byte || (bytes_lt_two_byte && (offset_address[2:0] == {3{1'b1}}))) begin
            incrsize = `AXI_ASIZE_8;
        end else if (bytes_lt_two_half || (bytes_lt_four_half && (offset_address[2:1] == {2{1'b1}}))) begin
            incrsize = `AXI_ASIZE_16;
        end else if (bytes_lt_four_word || (bytes_lt_eight_word && (offset_address[2:2] == {1{1'b1}}))) begin
            incrsize = `AXI_ASIZE_32;
        end 

  end

  //Calculate the final address and if an overflow has occured
  assign final_address = {1'b0, offset_address} + {1'b0, bytes_to_transfer_large[2:0]};
  assign overflow =  final_address[3];

  //Calculate the length ... assuming this transfer is going to be the maximum
  assign bytes_to_transfer_large = {8'b00000000, bytes_to_transfer};

  

  assign incrlenmaxsize =  bytes_to_transfer_large[10:3] + 4'b1;
  assign incrlen = (overflow) ? incrlenmaxsize : bytes_to_transfer_large[10:3];

  

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

// synopsys translate_off

  //Check that all transactions issued are within size of the incoming bus
  assert_never #(0,0,"ERROR, Transaction incoming that has awsize too large for incoming bus")
      ovl_max_input_size
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_s && (awsize_s > 2))
       );

  //Check that all transactions issued are within size of the outgoing bus
  assert_never #(0,0,"ERROR, Transaction issued that is too large for outgoing bus")
      ovl_max_output_size
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_m && (awsize_m > 3))
       );

  //Check (unless bypassing) all transactions of length > 2 must be the same size as the outgoing bus
  assert_never #(0,0,"ERROR, Inefficient transaction issued when not in bypass")
      ovl_inefficient_size_len_com
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_m && (!bypass) && (awlen_m > 4'b1)
                    && (awsize_m != 3)
                    && (awburst_m != 2'b0))
       );

  //Check that if cache[1] is set then incoming transaction = outgoing transaction unless size is too big
  assert_never #(0,0,"ERROR, Transaction should not have been touched")
      ovl_illegal_trans_mod
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_m && (!awcache_s[1]) && (awsize_s <= 3)
                    && (awsize_s != awsize_m) && (awlen_s != awlen_m))
       );

  //Check that the block never generates transactions if there is no incoming valid
  assert_never #(0,0,"ERROR, Transaction should not have been created")
      ovl_illegal_trans_create
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_m && (!awvalid_s))
       );

 //Check that incoming wraps are always alligned to their size
 assert_never #(0,0,"ERROR, Unaligned incoming wrap")
      ovl_illegal_incoming_wrap
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_s && (awburst_s == `AXI_ABURST_WRAP) &&
                    !((awsize_s == `AXI_ASIZE_8) ||
                      (awsize_s == `AXI_ASIZE_16  && awaddr_s[0]   == 1'b0) ||
                      (awsize_s == `AXI_ASIZE_32  && awaddr_s[1:0] == 2'b0) ||
                      (awsize_s == `AXI_ASIZE_64  && awaddr_s[2:0] == 3'b0) ||
                      (awsize_s == `AXI_ASIZE_128 && awaddr_s[3:0] == 4'b0) ||
                      (awsize_s == `AXI_ASIZE_256 && awaddr_s[4:0] == 5'b0)))
       );

 //Check that incoming wraps are always alligned to their size
 assert_never #(0,0,"ERROR, Unaligned outgoing wrap")
      ovl_illegal_outgoing_wrap
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (awvalid_m && (awburst_m == `AXI_ABURST_WRAP) &&
                   !((awsize_m == `AXI_ASIZE_8) ||
                     (awsize_m == `AXI_ASIZE_16  && awaddr_m[0]   == 1'b0) ||
                     (awsize_m == `AXI_ASIZE_32  && awaddr_m[1:0] == 2'b0) ||
                     (awsize_m == `AXI_ASIZE_64  && awaddr_m[2:0] == 3'b0) ||
                     (awsize_m == `AXI_ASIZE_128 && awaddr_m[3:0] == 4'b0) ||
                     (awsize_m == `AXI_ASIZE_256 && awaddr_m[4:0] == 5'b0)))
       );

 reg awvalid_m_prev;
 reg awvalid_s_prev;
 reg awready_m_prev;
 reg awready_s_prev;
 reg in_trans;
 reg [0:0]  n_response_count;

 always @(posedge aclk or negedge aresetn)
    begin
        if (!aresetn) begin
           awvalid_m_prev <= 1'b0;
           awvalid_s_prev <= 1'b0;
           awready_m_prev <= 1'b0;
           awready_s_prev <= 1'b0;
        end else begin
           awvalid_m_prev <= awvalid_m;
           awvalid_s_prev <= awvalid_s;
           awready_m_prev <= awready_m;
           awready_s_prev <= awready_s;
        end
    end

 always @(posedge aclk or negedge aresetn)
    begin
       if (!aresetn) begin
           in_trans <= 1'b0;
       end else if (awvalid_m && awready_m) begin
           in_trans <= awvalid_s && (!awready_s);
       end
    end

 //Response counter
 always @(posedge aclk or negedge aresetn)
    begin
        if (!aresetn) begin
           n_response_count <= 1'b0;
        end else if (awvalid_m && awready_m && (!in_trans) && |n_response) begin
           n_response_count <= {1'b0, n_response};
        end else if (awvalid_m && awready_m && |n_response_count) begin
           n_response_count <= n_response_count - 1'b1;
        end
    end

 //Exclusives ... Any exclusives that get split must lose their exclusive flag
 assert_never #(0,0,"ERROR, Exclusive transaction has been split")
   ovl_split_exclusive
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (awvalid_m && (!awvalid_s)
                  && awlock_m == `AXI_ALOCK_EXCL)
     );

 //Locks ... Any locked transactions must maintain their lock status
 assert_implication #(0,0,"ERROR, Transaction has lost lock")
   ovl_lost_lock
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .antecedent_expr (awvalid_s && awvalid_m &&
                        awlock_s == `AXI_ALOCK_LOCKED),
      .consequent_expr (awlock_m == `AXI_ALOCK_LOCKED)
     );

 //Sticky valid signals
 assert_never #(0,0,"ERROR, Sticky output valid")
   ovl_sticky_valid_m
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (awvalid_m_prev && (!awvalid_m)
                  && (!awready_m_prev))
     );

 assert_never #(0,0,"ERROR, Sticky input valid")
   ovl_sticky_valid_s
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (awvalid_s_prev && (!awvalid_s)
                  && (!awready_s_prev))
     );

 
 assert_never #(0,0,"ERROR, Illegal Bchannel Hndshake value")
   ovl_illegal_b_hndshk
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (bdata_valid && (!bdata_ready))
     );

 assert_never #(0,0,"ERROR, Illegal Push to Bchannel")
   ovl_illegal_b_push
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (in_trans && bdata_valid)
     );

 //Check that the number of transactions issued is always correct
 //If there is a slave handshake then either it's a new transactions or the response_count has reached one
 assert_implication #(0,0,"ERROR, Illegal transaction count")
   ovl_illegal_trans_count
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .antecedent_expr (awvalid_s && awready_s),
      .consequent_expr (awvalid_m && awready_m &&
                       (((!in_trans) && (~|n_response)) || (in_trans && n_response_count == 1'b1)))
     );

// synopsys translate_on
`endif


endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"

//------------------------------------------------------------------------------
//  End of File : $RCSfile: UpsizeAxi,v $
//------------------------------------------------------------------------------

