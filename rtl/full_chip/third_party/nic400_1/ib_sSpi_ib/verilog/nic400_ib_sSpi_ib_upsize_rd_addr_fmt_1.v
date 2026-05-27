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
// Purpose             : This block formats the AR channel in to the 
//                       appropriate format for the outgoing bus width
//------------------------------------------------------------------------------
//
// This is a component of asib named sSpi_ib
// and is axi4:32bit to  axi4:64bit upsizing
//



module nic400_ib_sSpi_ib_upsize_rd_addr_fmt_1
  (
    // global interconnect signals
    aresetn,
    aclk,


    //Signals to the AR Slices
    ardata_valid,
    ardata_ready,
    ardata_data,
    

    // Slave Port Address Channel
    arid_s,
    araddr_s,
    arlen_s,
    arsize_s,
    arburst_s,
    arvalid_s,
    arready_s,
    arprot_s,
    arcache_s,
    arlock_s,

    // Master Port Address Channel
    arid_m,
    araddr_m,
    arlen_m,
    arsize_m,
    arburst_m,
    arvalid_m,
    arready_m,
    arprot_m,
    arcache_m,
    arlock_m          

  );

  //------------------------------------------------------------------------------
  // parameters
  //------------------------------------------------------------------------------
`include "nic400_ib_sSpi_ib_defs_1.v"
`include "Axi.v"

  input                    aclk;
  input                    aresetn;
//Signals from ARFIFO
  input                    ardata_ready;
  output                   ardata_valid;
  output [16:0]            ardata_data;
  

  // Slave Port Write Address Channel Signals
  input [1:0]              arid_s;            // transaction address ID
  input [31:0]             araddr_s;          // transaction start address
  input [7:0]              arlen_s;           // transaction length
  input [2:0]              arsize_s;          // transaction transfer size
  input [1:0]              arburst_s;         // transaction burst type
  input [3:0]              arcache_s;         // transaction cache value
  input [2:0]              arprot_s;          // transaction prot value
  input                    arvalid_s;         // address transfer valid
  input                    arlock_s;          // address transfer locked
  output                   arready_s;         // ready for address transfer


  // Master Port Write Address Channel Signals
  output [1:0]              arid_m;            // transaction address ID
  output [31:0]             araddr_m;          // transaction start address
  output [7:0]              arlen_m;           // transaction length
  output [2:0]              arsize_m;          // transaction transfer size
  output [1:0]              arburst_m;         // transaction burst type
  output [3:0]              arcache_m;         // transaction cache value
  output [2:0]              arprot_m;          // transaction prot value
  output                    arlock_m;          // address transfer locked
  output                    arvalid_m;         // address transfer valid
  input                     arready_m;         // ready for address transfer

  


 //------------------------------------------------------------------------
 // Registers
 //------------------------------------------------------------------------
 
  // Output value registers
  reg [31:0]                araddro;              // transaction start address (int)
  reg [7:0]                 arleno;               // transaction length (int)
  reg [2:0]                 arsizeo;              // transaction transfer size (int)
  reg [1:0]                 arbursto;             // transaction burst type (int)
  reg [1:0]                 arido;                // transaction address ID
  reg [3:0]                 arcacheo;             // transaction cache value
  reg [2:0]                 arproto;              // transaction prot value
  reg                       arlocko;              // tranaction lock value

  reg                       excl_override_reg;     // value of the exclusive override flag
  reg                       busy_reg;              // flag to indicate that there is a transaction in progress  
  
  //Registers used when processing unaligned wraps
  reg [9:0]                 wrap_bytes_remaining_reg; //bytes remaining to be processed
  reg [2:0]                 align_mask;           //Mask used to align Address to transfer size
  reg [2:0]                 read_mask;            //Addr sent write control block
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
  
                                            
                                                  
  wire [31:0]               araddr_aligned;                                                  

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
  
  wire [7:0]                arlen_1;

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
 assign slave_hndshk = arvalid_s & arready_s;
 assign master_hndshk = arvalid_m & arready_m;

 
 //------------------------------------------------------------------------
 // Signals to Upsizer Read Channel
 //------------------------------------------------------------------------
 assign ardata_data[`ARDATA_SIZE] = arsize_s;
 assign ardata_data[`ARDATA_TWO] = n_response;
 assign ardata_data[`ARDATA_BYPASS] = bypass;
 assign ardata_data[`ARDATA_ADDR] = araddr_s[2:0] & align_mask;
 assign ardata_data[`ARDATA_MASK] = read_mask;
 assign ardata_data[`ARDATA_END] = ((arburst_s == `AXI_ABURST_WRAP) & ~wrap_is_incr) ? addr_less_one[2:0] & align_mask : final_address[2:0] & align_mask;
 assign ardata_data[`ARDATA_ID] = arid_s;
 assign ardata_data[`ARDATA_WRAP_FITS] = wrap_fits;

 //REVISIT ARDATA_TWO
 

 assign ardata_valid = new_transaction;
 

 //Generate the mask for the read counter
 always @(*)
  begin : p_new_addr_incr_en_r
  
    read_mask = {3{1'b0}};
  
    case (arburst_s)
      `AXI_ABURST_FIXED : read_mask = {3{1'b0}};
      `AXI_ABURST_WRAP  : read_mask = total_bytes[2:0];
      `AXI_ABURST_INCR  : read_mask = {3{1'b1}};
      default           : read_mask = {3{1'bx}};
    endcase
  end // block : p_new_addr_incr_en_r


 
 //No burst breaking other than wraps
 //Note upsizer cannot create long bursts
 assign n_response = wrap_split;

 

 //------------------------------------------------------------------------
 // First Transaction Detection
 //------------------------------------------------------------------------

 //The first transaction occurs the first time there is space in any buffers
 //after the rising edge of the arvalid_s

 //Determine if there is space in the buffers to complete
 
 assign buffers_ok = ardata_ready;

 //Determine if this is the last transaction in the sequence
 
 assign  trans_complete = ~((wrap_split & ~wrap_split_reg) );
 

 //Transaction in progress flag ... either when new_transaction or busy_reg
 assign trans_in_progress = new_transaction | busy_reg;

 //Determine the start of a new transaction .. starts when there is space in buffers and space to start
 assign new_transaction = new_trans_avail & buffers_ok;

 //Flag to show there is a new transaction available
 assign new_trans_avail = arvalid_s & ~busy_reg;

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
 assign excl_override = (new_transaction) ? n_response | (|arleno[7:4]) : excl_override_reg;

 always @(posedge aclk or negedge aresetn)
   begin : excl_override_reg_p
      if (!aresetn) begin
          excl_override_reg <= 1'b0;
      end else if (new_transaction) begin
          excl_override_reg <= excl_override;
      end
    end

 //------------------------------------------------------------------------
 // Output ARCHANNEL assignments
 //------------------------------------------------------------------------

 //Master Port Write Address Channel Signals Assignments


 //If the buffer is valid .. always take that value
 assign arid_m =     arido;
 assign arcache_m =  arcacheo;
 assign arprot_m =   arproto;
 assign arlen_m =    arleno;
 assign arsize_m =   arsizeo;
 assign araddr_m =   araddro;
 assign arburst_m =  arbursto;
 assign arlock_m =   arlocko;

 //Valid Output
 assign arvalid_m = arvalid_s && trans_in_progress;

 //Ready Output
 assign arready_s = master_hndshk && trans_complete;

 always @(*) begin

      arleno = incrlen;
      arsizeo = incrsize;
      arbursto = `AXI_ABURST_INCR;
      arido = arid_s;
      arcacheo = arcache_s;
      arproto = arprot_s;
      araddro = araddr_aligned;
      
      arlocko = (arlock_s && (~excl_override));
      


      if (!wrap_split_reg) begin

         araddro = araddr_s;
         if (wrap_aligned) begin
            arleno = wraplen_i;
            arsizeo = wrapsize;
            arbursto = `AXI_ABURST_WRAP;
         end else if (bypass) begin
            arleno = arlen_s;
            arsizeo = arsize_s;
            arbursto = arburst_s;
         end else if (wrap_fits) begin
            araddro = araddr_aligned;
            arleno = arlen_1;
            arsizeo = wrapfitsize;
            arbursto = `AXI_ABURST_INCR;
         end
      end
  end

  
 assign wraplen_i = {4'b0000,wraplen};
 assign arlen_1 = {4'b0000,`AXI_ALEN_1};

 assign addr_less_one = araddr_s[9:0] - {{9{1'b0}},1'b1};
 
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
 assign araddr_aligned = {araddr_s[31:10],((araddr_s[9:0]) & (~total_bytes))};


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
  
 
 
 assign bypass = (arburst_s == `AXI_ABURST_FIXED ) || ~arcache_s[1] || (arlen_s == `AXI_ALEN_1);
 

 //Total_bytes .. this is calculated from SIZE and LENGTH
 always @(*)
  begin : total_bytes_p
    case (arsize_s)
       `AXI_ASIZE_8    : total_bytes = {2'b0, arlen_s};
       `AXI_ASIZE_16   : total_bytes = {1'b0, arlen_s, 1'b1};
       `AXI_ASIZE_32   : total_bytes = {arlen_s, 2'b11};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : total_bytes = {2'b0, arlen_s};    //Unused case arsize should never hit in normal operation
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
 assign working_addr = araddr_s[3:0] & wrapalignmask;

 //Create a mask according to the size of the outgoing data bus
 assign wrap_fits_mask = {{7{1'b1}}, 3'b000};
 

 //Calculate what type of wrap this is
 assign  wrap_fits = ~|(total_bytes & wrap_fits_mask) & (arburst_s == `AXI_ABURST_WRAP);
 assign  wrap_is_incr = ~|(araddr_s[9:0] & total_bytes);
 assign  wrap_aligned = ~|working_addr & (arburst_s == `AXI_ABURST_WRAP) & ~bypass & ~wrap_is_incr & ~wrap_fits ;
 assign  wrap_split = ((|working_addr)) & (arburst_s == `AXI_ABURST_WRAP) & ~bypass & ~wrap_fits;

 

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
 assign bytes_to_transfer_wrap1 = ~(araddr_s[9:0]) & wrap_boundary_mask;

 //Select appropriate value
 assign bytes_to_transfer = (wrap_split_reg) ? wrap_bytes_remaining_reg
                            : ((arburst_s == `AXI_ABURST_WRAP) ? bytes_to_transfer_wrap1
                            : total_bytes_masked);

 

 //Calculate the total number of bytes to transfer ... taking account of alignment
 always @(*)
  begin : total_bytes_masked_p
    case (arsize_s)
       `AXI_ASIZE_8    : total_bytes_masked = {2'b0, arlen_s};
       `AXI_ASIZE_16   : total_bytes_masked = {1'b0, arlen_s, ~araddr_s[0]};
       `AXI_ASIZE_32   : total_bytes_masked = {arlen_s, ~araddr_s[1:0]};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : total_bytes_masked = {2'b0, arlen_s};    //Unused case arsize should never hit in normal operation
       default         : total_bytes_masked = {10{1'bx}};
    endcase
 end

 

 //Determine the address alignment mask
 always @(*)
  begin : align_mask_p
    case (arsize_s)
       `AXI_ASIZE_8    : align_mask = {3{1'b1}};
       `AXI_ASIZE_16   : align_mask = {{2{1'b1}}, 1'b0};
       `AXI_ASIZE_32   : align_mask = {{1{1'b1}}, 2'b0};
       `AXI_ASIZE_64,
       `AXI_ASIZE_128,
       `AXI_ASIZE_256,
       `AXI_ASIZE_512,
       `AXI_ASIZE_1024 : align_mask = {3{1'b1}};    //Unused case arsize should never hit in normal operation
       default         : align_mask = {3{1'bx}};
    endcase
  end
  

 //Determine Offset Address
 assign offset_address = (wrap_split_reg) ? araddr_aligned[2:0] : 
                            araddr_s[2:0];

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
  assert_never #(0,0,"ERROR, Transaction incoming that has arsize too large for incoming bus")
      ovl_max_input_size
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_s && (arsize_s > 2))
       );

  //Check that all transactions issued are within size of the outgoing bus
  assert_never #(0,0,"ERROR, Transaction issued that is too large for outgoing bus")
      ovl_max_output_size
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_m && (arsize_m > 3))
       );

  //Check (unless bypassing) all transactions of length > 2 must be the same size as the outgoing bus
  assert_never #(0,0,"ERROR, Inefficient transaction issued when not in bypass")
      ovl_inefficient_size_len_com
       (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_m && (!bypass) && (arlen_m > 4'b1)
                    && (arsize_m != 3)
                    && (arburst_m != 2'b0))
       );

  //Check that if cache[1] is set then incoming transaction = outgoing transaction unless size is too big
  assert_never #(0,0,"ERROR, Transaction should not have been touched")
      ovl_illegal_trans_mod
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_m && (!arcache_s[1]) && (arsize_s <= 3)
                    && (arsize_s != arsize_m) && (arlen_s != arlen_m))
       );

  //Check that the block never generates transactions if there is no incoming valid
  assert_never #(0,0,"ERROR, Transaction should not have been created")
      ovl_illegal_trans_create
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_m && (!arvalid_s))
       );

 //Check that incoming wraps are always alligned to their size
 assert_never #(0,0,"ERROR, Unaligned incoming wrap")
      ovl_illegal_incoming_wrap
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_s && (arburst_s == `AXI_ABURST_WRAP) &&
                    !((arsize_s == `AXI_ASIZE_8) ||
                      (arsize_s == `AXI_ASIZE_16  && araddr_s[0]   == 1'b0) ||
                      (arsize_s == `AXI_ASIZE_32  && araddr_s[1:0] == 2'b0) ||
                      (arsize_s == `AXI_ASIZE_64  && araddr_s[2:0] == 3'b0) ||
                      (arsize_s == `AXI_ASIZE_128 && araddr_s[3:0] == 4'b0) ||
                      (arsize_s == `AXI_ASIZE_256 && araddr_s[4:0] == 5'b0)))
       );

 //Check that incoming wraps are always alligned to their size
 assert_never #(0,0,"ERROR, Unaligned outgoing wrap")
      ovl_illegal_outgoing_wrap
        (
        .clk       (aclk),
        .reset_n   (aresetn),
        .test_expr (arvalid_m && (arburst_m == `AXI_ABURST_WRAP) &&
                   !((arsize_m == `AXI_ASIZE_8) ||
                     (arsize_m == `AXI_ASIZE_16  && araddr_m[0]   == 1'b0) ||
                     (arsize_m == `AXI_ASIZE_32  && araddr_m[1:0] == 2'b0) ||
                     (arsize_m == `AXI_ASIZE_64  && araddr_m[2:0] == 3'b0) ||
                     (arsize_m == `AXI_ASIZE_128 && araddr_m[3:0] == 4'b0) ||
                     (arsize_m == `AXI_ASIZE_256 && araddr_m[4:0] == 5'b0)))
       );

 reg arvalid_m_prev;
 reg arvalid_s_prev;
 reg arready_m_prev;
 reg arready_s_prev;
 reg in_trans;
 reg [0:0]  n_response_count;

 always @(posedge aclk or negedge aresetn)
    begin
        if (!aresetn) begin
           arvalid_m_prev <= 1'b0;
           arvalid_s_prev <= 1'b0;
           arready_m_prev <= 1'b0;
           arready_s_prev <= 1'b0;
        end else begin
           arvalid_m_prev <= arvalid_m;
           arvalid_s_prev <= arvalid_s;
           arready_m_prev <= arready_m;
           arready_s_prev <= arready_s;
        end
    end

 always @(posedge aclk or negedge aresetn)
    begin
       if (!aresetn) begin
           in_trans <= 1'b0;
       end else if (arvalid_m && arready_m) begin
           in_trans <= arvalid_s && (!arready_s);
       end
    end

 //Response counter
 always @(posedge aclk or negedge aresetn)
    begin
        if (!aresetn) begin
           n_response_count <= 1'b0;
        end else if (arvalid_m && arready_m && (!in_trans) && |n_response) begin
           n_response_count <= {1'b0, n_response};
        end else if (arvalid_m && arready_m && |n_response_count) begin
           n_response_count <= n_response_count - 1'b1;
        end
    end

 //Exclusives ... Any exclusives that get split must lose their exclusive flag
 assert_never #(0,0,"ERROR, Exclusive transaction has been split")
   ovl_split_exclusive
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (arvalid_m && (!arvalid_s)
                  && arlock_m == `AXI_ALOCK_EXCL)
     );

 //Locks ... Any locked transactions must maintain their lock status
 assert_implication #(0,0,"ERROR, Transaction has lost lock")
   ovl_lost_lock
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .antecedent_expr (arvalid_s && arvalid_m &&
                        arlock_s == `AXI_ALOCK_LOCKED),
      .consequent_expr (arlock_m == `AXI_ALOCK_LOCKED)
     );

 //Sticky valid signals
 assert_never #(0,0,"ERROR, Sticky output valid")
   ovl_sticky_valid_m
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (arvalid_m_prev && (!arvalid_m)
                  && (!arready_m_prev))
     );

 assert_never #(0,0,"ERROR, Sticky input valid")
   ovl_sticky_valid_s
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (arvalid_s_prev && (!arvalid_s)
                  && (!arready_s_prev))
     );

 
 assert_never #(0,0,"ERROR, Illegal Rchannel Hndshake value")
   ovl_illegal_r_hndshk
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (ardata_valid && (!ardata_ready))
     );

 assert_never #(0,0,"ERROR, Illegal Push to Bchannel")
   ovl_illegal_r_push
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .test_expr (in_trans && ardata_valid)
     );

 //Check that the number of transactions issued is always correct
 //If there is a slave handshake then either it's a new transactions or the response_count has reached one
 assert_implication #(0,0,"ERROR, Illegal transaction count")
   ovl_illegal_trans_count
     (
      .clk       (aclk),
      .reset_n   (aresetn),
      .antecedent_expr (arvalid_s && arready_s),
      .consequent_expr (arvalid_m && arready_m &&
                       (((!in_trans) && (~|n_response)) || (in_trans && n_response_count == 1'b1)))
     );

// synopsys translate_on
`endif


endmodule

`include "nic400_ib_sSpi_ib_undefs_1.v"
`include "Axi_undefs.v"


//------------------------------------------------------------------------------
//  End of File : $RCSfile: amib,v $
//------------------------------------------------------------------------------

