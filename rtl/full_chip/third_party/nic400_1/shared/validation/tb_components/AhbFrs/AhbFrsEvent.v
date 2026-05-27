// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2008-2009 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FrsEvent.v,v
//  File Revision       : 0.0
//
//  Release Information : 
// -----------------------------------------------------------------------------
//  Purpose             : Event control block
//
//
// --=========================================================================--


module AhbFrsEvent
(

  HCLK,
  HRESETn,

//H channel signals
  ebus,
  emit_now,
  wbus,
  go,

//Back pressure
  hold,

//External Emit bus
  EMIT_DATA,
  EMIT_REQ,
  EMIT_ACK,

//External Wait bus
  WAIT_DATA,
  WAIT_REQ,
  WAIT_ACK

);

// Module parameters
  parameter EW_WIDTH    = 32;                   // Width of the Event bus
  
  input                 HCLK;
  input                 HRESETn;

//H channel signals
  input  [EW_WIDTH-1:0] ebus;
  input                 emit_now;
  output [EW_WIDTH-1:0] wbus;
  output                go;

  output                hold;

//External Emit bus
  output [EW_WIDTH-1:0] EMIT_DATA;
  output                EMIT_REQ;
  input                 EMIT_ACK;

//External Wait bus
  input [EW_WIDTH-1:0]  WAIT_DATA;
  input                 WAIT_REQ;
  output                WAIT_ACK;

  
//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  //Outputs
  wire [EW_WIDTH-1:0]  EMIT_DATA; 
  wire                 EMIT_REQ; 
  reg                  WAIT_ACK;
  wire                 go;

  wire                 wait_in_progress;
  wire                 emit_in_progress;

  wire [EW_WIDTH-1:0]  emit_data_now;
  reg  [EW_WIDTH-1:0]  emit_data_reg;
  reg                  emit_req_reg;

//------------------------------------------------------------------------------
// Wait handshaking
//------------------------------------------------------------------------------

  assign wait_in_progress = WAIT_REQ ^ WAIT_ACK;
 
  //Arbitation register
  always @(posedge HCLK or negedge HRESETn)  
    begin
      if (~HRESETn) begin
           WAIT_ACK <= 1'b0;
         end
      else if (wait_in_progress) begin
           WAIT_ACK <= ~WAIT_ACK;
         end   
    end      
  assign go   = wait_in_progress;
  assign wbus = WAIT_DATA;
//------------------------------------------------------------------------------
// Emit handshaking, emit only last for one cycle
//------------------------------------------------------------------------------
 
  assign emit_in_progress = EMIT_REQ ^ EMIT_ACK;

  assign hold = EMIT_ACK ^ emit_req_reg;

  //Determine the emit_req
  assign EMIT_REQ = emit_now ^ emit_req_reg; 

  //Detetermine the output data
  assign EMIT_DATA = (emit_now) ? ebus : emit_data_reg;

  //Arbitation register
  always @(posedge HCLK or negedge HRESETn)  
    begin
      if (~HRESETn) begin
        emit_req_reg  <= 1'b0;
        emit_data_reg <= {EW_WIDTH{1'b0}};
      end else if (emit_now) begin
        emit_req_reg  <= EMIT_REQ;
        emit_data_reg <= ebus;
      end  
    end



endmodule
