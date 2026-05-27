// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2003-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 87876
//  File Date           :  2010-03-05 13:27:48 +0000 (Fri, 05 Mar 2010)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : Event control block
//
//  This block takes the muxs events from all 5 channels down to 1 and passes
//  it to the main Event handler using a V/R handshake.
//  Channels are only stopped if the EVENT_ID skid buffer for that channel is
//  full
//
// --=========================================================================--

`timescale 1ns / 1ps


module FrsEvent
(

  ACLK,
  ARESETn,

//AW channel signals
  AWebus,
  AWemit,
  AWwbus,
  AWpause,
  AWgo,

//AR channel signals
  ARebus,
  ARemit,
  ARwbus,
  ARpause,
  ARgo,

//R channel signals
  Rebus,
  Remit,
  Rwbus,
  Rpause,
  Rgo,

//W channel signals
  Webus,
  Wemit,
  Wwbus,
  Wpause,
  Wgo,

//B channel signals
  Bebus,
  Bemit,
  Bwbus,
  Bpause,
  Bgo,

//External Emit bus
  EMIT_ID,
  EMIT_REQ,
  EMIT_ACK,

//External Wait bus
  WAIT_ID,
  WAIT_REQ,
  WAIT_ACK

);

// Module parameters
  parameter EW_WIDTH     = 8;                   // Width of the Event bus

  input                 ACLK;
  input                 ARESETn;

//AW channel signals
  input [EW_WIDTH-1:0]  AWebus;
  input                 AWemit;
  output [EW_WIDTH-1:0] AWwbus;
  output                AWpause;
  output                AWgo;

//AR channel signals
  input [EW_WIDTH-1:0]  ARebus;
  input                 ARemit;
  output [EW_WIDTH-1:0] ARwbus;
  output                ARpause;
  output                ARgo;

//R channel signals
  input [EW_WIDTH-1:0]  Rebus;
  input                 Remit;
  output [EW_WIDTH-1:0] Rwbus;
  output                Rpause;
  output                Rgo;

//W channel signals
  input [EW_WIDTH-1:0]  Webus;
  input                 Wemit;
  output [EW_WIDTH-1:0] Wwbus;
  output                Wpause;
  output                Wgo;

//B channel signals
  input [EW_WIDTH-1:0]  Bebus;
  input                 Bemit;
  output [EW_WIDTH-1:0] Bwbus;
  output                Bpause;
  output                Bgo;

//External Emit bus
  output [EW_WIDTH-1:0] EMIT_ID;
  output                EMIT_REQ;
  input                 EMIT_ACK;

//External Wait bus
  input [EW_WIDTH-1:0]  WAIT_ID;
  input                 WAIT_REQ;
  output                WAIT_ACK;


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

 //Round robin arbitration
  reg [4:0]             last_buf;

  //skid buffers
  reg                  AWpause;
  reg                  ARpause;
  reg                  Rpause;
  reg                  Wpause;
  reg                  Bpause;

  reg [EW_WIDTH-1:0]   AW_buffer;
  reg [EW_WIDTH-1:0]   AR_buffer;
  reg [EW_WIDTH-1:0]   R_buffer;
  reg [EW_WIDTH-1:0]   W_buffer;
  reg [EW_WIDTH-1:0]   B_buffer;

  wire [EW_WIDTH-1:0]  AW_emit_val;
  wire [EW_WIDTH-1:0]  AR_emit_val;
  wire [EW_WIDTH-1:0]  R_emit_val;
  wire [EW_WIDTH-1:0]  W_emit_val;
  wire [EW_WIDTH-1:0]  B_emit_val;

  wire                 AW_buff_wr;
  wire                 AR_buff_wr;
  wire                 R_buff_wr;
  wire                 W_buff_wr;
  wire                 B_buff_wr;

  //buffer valids
  wire                 AW_emit;
  wire                 AR_emit;
  wire                 W_emit;
  wire                 R_emit;
  wire                 B_emit;

  //Arbitration
  reg [4:0]            Last;
  reg [8:0]            arb_mask;
  wire [8:0]           arb_vector;
  reg  [4:0]           select;

  //Outputs
  wire [EW_WIDTH-1:0]  EMIT_ID;
  wire                 EMIT_REQ;
  reg                  WAIT_ACK;

  reg                  wait_req_reg;
  wire                 wait_in_progress;
  wire                 emit_in_progress;

  reg                  emit_ack_reg;
  reg                  could_emit_now;
  wire                 emit_now;
  reg [EW_WIDTH-1:0]   emit_data_now;
  reg [EW_WIDTH-1:0]   emit_data_reg;
  reg                  emit_req_reg;


//------------------------------------------------------------------------------
// Wait handshaking
//------------------------------------------------------------------------------

  //Register WAIT_REQ
  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        wait_req_reg <= 1'b0;
      end else
        wait_req_reg <= WAIT_REQ;
    end

  assign wait_in_progress = wait_req_reg ^ WAIT_ACK;

  //Arbitation register
  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn)
        WAIT_ACK <= 1'b0;
      else if (wait_in_progress)
        WAIT_ACK <= ~WAIT_ACK;
    end

//------------------------------------------------------------------------------
// Wait handshaking
//------------------------------------------------------------------------------

  //Register EMIT_ACK
  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        emit_ack_reg <= 1'b0;
      end else
        emit_ack_reg <= EMIT_ACK;
    end

  assign emit_in_progress = emit_ack_reg != emit_req_reg;

  //Only start a new transaction if the last one has completed
  assign emit_now = could_emit_now & ~emit_in_progress;

  //Determine the emit_req
  assign EMIT_REQ = emit_now ^ emit_req_reg;

  //Detetermine the output data
  assign EMIT_ID = (emit_now) ? emit_data_now : emit_data_reg;

  //Arbitation register
  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        emit_req_reg <= 1'b0;
        emit_data_reg <= {EW_WIDTH{1'b0}};
      end else if (emit_now) begin
        emit_req_reg <= EMIT_REQ;
        emit_data_reg <= emit_data_now;
      end
    end

//------------------------------------------------------------------------------
// Wait distribution
//------------------------------------------------------------------------------

  assign AWwbus = WAIT_ID;
  assign ARwbus = WAIT_ID;
  assign Wwbus  = WAIT_ID;
  assign Rwbus  = WAIT_ID;
  assign Bwbus  = WAIT_ID;

  assign AWgo   = wait_in_progress;
  assign ARgo   = wait_in_progress;
  assign Wgo    = wait_in_progress;
  assign Rgo    = wait_in_progress;
  assign Bgo    = wait_in_progress;

//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------

  //Emit flags
  assign  AW_emit  = AWpause | AWemit;
  assign  AR_emit  = ARpause | ARemit;
  assign  W_emit   = Wpause | Wemit;
  assign  R_emit   = Rpause | Remit;
  assign  B_emit   = Bpause | Bemit;

  //Emit data
  assign  AW_emit_val  = (AWpause) ? AW_buffer : AWebus;
  assign  AR_emit_val  = (ARpause) ? AR_buffer : ARebus;
  assign  W_emit_val   = (Wpause) ? W_buffer : Webus;
  assign  R_emit_val   = (Rpause) ? R_buffer : Rebus;
  assign  B_emit_val   = (Bpause) ? B_buffer : Bebus;

  //Arbitation register
  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn)
        Last <= 5'b0;
      else if (emit_now)
        Last <= select;
    end

  //Mask generation
  always @(Last)
    begin
      case (Last)
         5'b00000 : arb_mask = 9'b111111111;
         5'b00001 : arb_mask = 9'b011111111;
         5'b00010 : arb_mask = 9'b001111111;
         5'b00100 : arb_mask = 9'b000111111;
         5'b01000 : arb_mask = 9'b000011111;
         5'b10000 : arb_mask = 9'b111111111;
         default  : arb_mask = 9'bx;
      endcase
    end

  //arb_vector generation
  assign arb_vector = {AW_emit, AR_emit, W_emit, R_emit, B_emit,
                       AW_emit, AR_emit, W_emit, R_emit} & arb_mask;

  //Arbitration
  always @(arb_vector or emit_in_progress)
    begin
      if (emit_in_progress) select = 5'b00000;
      else if (arb_vector[8]) select = 5'b00001;
      else if (arb_vector[7]) select = 5'b00010;
      else if (arb_vector[6]) select = 5'b00100;
      else if (arb_vector[5]) select = 5'b01000;
      else if (arb_vector[4]) select = 5'b10000;
      else if (arb_vector[3]) select = 5'b00001;
      else if (arb_vector[2]) select = 5'b00010;
      else if (arb_vector[1]) select = 5'b00100;
      else if (arb_vector[0]) select = 5'b01000;
      else select = 5'b10000;
    end

  //Demux
  always @*
    begin
      case (select)
        5'b00001 : begin emit_data_now = AW_emit_val; could_emit_now = AW_emit; end
        5'b00010 : begin emit_data_now = AR_emit_val; could_emit_now = AR_emit; end
        5'b00100 : begin emit_data_now = W_emit_val;  could_emit_now = W_emit; end
        5'b01000 : begin emit_data_now = R_emit_val;  could_emit_now = R_emit; end
        5'b10000 : begin emit_data_now = B_emit_val;  could_emit_now = B_emit; end
        default  : begin emit_data_now = {EW_WIDTH{1'b0}};     could_emit_now = 1'b0; end
     endcase
   end


   //Buffer write flags
  assign AW_buff_wr = (AWemit  && (select != 5'b00001)) |
                      (AWpause && (select == 5'b00001));
  assign AR_buff_wr = (ARemit  && (select != 5'b00010)) |
                      (ARpause && (select == 5'b00010));
  assign W_buff_wr  = (Wemit  && (select != 5'b00100)) |
                      (Wpause && (select == 5'b00100));
  assign R_buff_wr  = (Remit  && (select != 5'b01000)) |
                      (Rpause && (select == 5'b01000));
  assign B_buff_wr  = (Bemit  && (select != 5'b10000)) |
                      (Bpause && (select == 5'b10000));

  //Skid buffers
  always @(posedge ACLK)
    begin
      if (AW_buff_wr)
        AW_buffer <= AWebus;
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        AWpause <= 1'b0;
      end else if (AW_buff_wr) begin
        AWpause <= AWemit;
      end
    end

  always @(posedge ACLK)
    begin
      if (AR_buff_wr)
        AR_buffer <= ARebus;
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        ARpause <= 1'b0;
      end else if (AR_buff_wr) begin
        ARpause <= ARemit;
      end
    end

  always @(posedge ACLK)
    begin
      if (R_buff_wr)
        R_buffer <= Rebus;
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        Rpause <= 1'b0;
      end else if (R_buff_wr) begin
        Rpause <= Remit;
      end
    end

 always @(posedge ACLK)
    begin
      if (W_buff_wr)
        W_buffer <= Webus;
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        Wpause <= 1'b0;
      end else if (W_buff_wr) begin
        Wpause <= Wemit;
      end
    end

 always @(posedge ACLK)
    begin
      if (B_buff_wr)
        B_buffer <= Bebus;
    end

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        Bpause <= 1'b0;
      end else if (B_buff_wr) begin
        Bpause <= Bemit;
      end
    end

endmodule
