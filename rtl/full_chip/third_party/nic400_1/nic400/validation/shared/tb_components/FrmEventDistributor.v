

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
//  File Date           :  2009-11-06 14:57:16 +0000 (Fri, 06 Nov 2009)
//  File Revision       : 84759
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : Event control block
//
//  This block recieves the emit and wait buses from all the Frm/Frbm in the system
//  and distibutes them. To ensure correct operation all incoming req/ack lines
//  are syncronised.
//
// --=========================================================================--

`timescale 1ns / 1ps

module FrmEventDistributor
(
  
  //FR(M/S) port 1
  emit_req_1,
  emit_ack_1,
  emit_data_1,

  wait_req_1,
  wait_ack_1,
  wait_data_1,

  //FR(M/S) port 2
  emit_req_2,
  emit_ack_2,
  emit_data_2,

  wait_req_2,
  wait_ack_2,
  wait_data_2,

  //FR(M/S) port 3
  emit_req_3,
  emit_ack_3,
  emit_data_3,

  wait_req_3,
  wait_ack_3,
  wait_data_3,

  //FR(M/S) port 4
  emit_req_4,
  emit_ack_4,
  emit_data_4,

  wait_req_4,
  wait_ack_4,
  wait_data_4,

  //FR(M/S) port 5
  emit_req_5,
  emit_ack_5,
  emit_data_5,

  wait_req_5,
  wait_ack_5,
  wait_data_5,

  //FR(M/S) port 6
  emit_req_6,
  emit_ack_6,
  emit_data_6,

  wait_req_6,
  wait_ack_6,
  wait_data_6,

  pclk,
  presetn
);

// Module parameters
  parameter EW_WIDTH     = 16;                 // Width of the Event bus
  parameter PORTS        = 6;                    //Number of ports
  
  input                 pclk;
  input                 presetn;

  
  //FR(M/S) port 1
  input                  emit_req_1;
  output                 emit_ack_1;
  input  [EW_WIDTH-1:0]  emit_data_1;

  output                 wait_req_1;
  input                  wait_ack_1;
  output [EW_WIDTH-1:0]  wait_data_1;

  //FR(M/S) port 2
  input                  emit_req_2;
  output                 emit_ack_2;
  input  [EW_WIDTH-1:0]  emit_data_2;

  output                 wait_req_2;
  input                  wait_ack_2;
  output [EW_WIDTH-1:0]  wait_data_2;

  //FR(M/S) port 3
  input                  emit_req_3;
  output                 emit_ack_3;
  input  [EW_WIDTH-1:0]  emit_data_3;

  output                 wait_req_3;
  input                  wait_ack_3;
  output [EW_WIDTH-1:0]  wait_data_3;

  //FR(M/S) port 4
  input                  emit_req_4;
  output                 emit_ack_4;
  input  [EW_WIDTH-1:0]  emit_data_4;

  output                 wait_req_4;
  input                  wait_ack_4;
  output [EW_WIDTH-1:0]  wait_data_4;

  //FR(M/S) port 5
  input                  emit_req_5;
  output                 emit_ack_5;
  input  [EW_WIDTH-1:0]  emit_data_5;

  output                 wait_req_5;
  input                  wait_ack_5;
  output [EW_WIDTH-1:0]  wait_data_5;

  //FR(M/S) port 6
  input                  emit_req_6;
  output                 emit_ack_6;
  input  [EW_WIDTH-1:0]  emit_data_6;

  output                 wait_req_6;
  input                  wait_ack_6;
  output [EW_WIDTH-1:0]  wait_data_6;


//------------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

  //Emit signals
  wire [PORTS-1:0]      emit_req;         //Emit signals
  wire [PORTS-1:0]      emit_mask;         //Emit signals

  reg   [PORTS-1:0]     emit_ack;         //Emit signals
  wire [PORTS-1:0]      emit_queue;       //Emit signals
  wire [EW_WIDTH-1:0]   wait_data;        //Emit signals
  reg  [EW_WIDTH-1:0]   wait_data_reg;    //Emit signals
  reg  [EW_WIDTH-1:0]   wait_data_mux;    //Emit signals

  //Wait signals
  wire [PORTS-1:0]      wait_ack;         //Wait signals

  wire [PORTS-1:0]      wait_req;         //Wait signals
  reg  [PORTS-1:0]      wait_req_reg;     //Wait signals
  wire [PORTS-1:0]      wait_in_progress;  //Wait inprogress
  wire                  waiting;  //Wait inprogress

  //Round Robin arbitartion signals
  reg [PORTS-1:0]             last;
  reg [PORTS-1:0]             select;
  wire                        update;
  reg [PORTS+PORTS-2:0]       arb_mask;
  wire [PORTS+PORTS-2:0]      arb_vector;

  //Completion logic
  reg [31:0]                  complete;
  wire [31:0]                 nxt_complete;
  reg                         sim_complete;

  reg [31:0]                  connections;
  reg [31:0]                  this_port;

//------------------------------------------------------------------------------
// Signal build up and synchronisation
//------------------------------------------------------------------------------

 assign emit_req = {
                     emit_req_6,
                     emit_req_5,
                     emit_req_4,
                     emit_req_3,
                     emit_req_2,
                     emit_req_1};

 assign emit_mask = {
                     (emit_req_6 !== 1'bz),
                     (emit_req_5 !== 1'bz),
                     (emit_req_4 !== 1'bz),
                     (emit_req_3 !== 1'bz),
                     (emit_req_2 !== 1'bz),
                     (emit_req_1 !== 1'bz)};

 assign wait_ack = {
                     wait_ack_6,
                     wait_ack_5,
                     wait_ack_4,
                     wait_ack_3,
                     wait_ack_2,
                     wait_ack_1};

 
  assign emit_ack_1 = emit_ack;
  assign emit_ack_2 = emit_ack[1];
  assign emit_ack_3 = emit_ack[2];
  assign emit_ack_4 = emit_ack[3];
  assign emit_ack_5 = emit_ack[4];
  assign emit_ack_6 = emit_ack[5];
  assign wait_req_1 = wait_req;
  assign wait_data_1 = wait_data;
  assign wait_req_2 = wait_req[1];
  assign wait_data_2 = wait_data;
  assign wait_req_3 = wait_req[2];
  assign wait_data_3 = wait_data;
  assign wait_req_4 = wait_req[3];
  assign wait_data_4 = wait_data;
  assign wait_req_5 = wait_req[4];
  assign wait_data_5 = wait_data;
  assign wait_req_6 = wait_req[5];
  assign wait_data_6 = wait_data;

//------------------------------------------------------------------------------
// Determine what emits (and waits) are occurring
//------------------------------------------------------------------------------

  //An emit is waiting if the req and ack are the same
  assign emit_queue       = ((emit_req & emit_mask) ^ emit_ack);
  assign wait_in_progress = (wait_ack ^ wait_req_reg) & emit_mask;
  assign waiting          = |wait_in_progress;

//------------------------------------------------------------------------------
// Round Robin aribration
//------------------------------------------------------------------------------

 //Only update the pointer when there is no wait in progress and there is an emit waiting
 assign update = ~waiting & |emit_queue;

 //Assign the output data
 assign wait_data = (update) ? wait_data_mux : wait_data_reg;
 assign wait_req  = (update) ? ~wait_req_reg : wait_req_reg;  

 always @(posedge pclk or negedge presetn) begin

     if (!presetn) begin
          last  <= {PORTS{1'b0}};
          wait_req_reg <= {PORTS{1'b0}};
          emit_ack <= {PORTS{1'b0}};
          wait_data_reg <= {EW_WIDTH{1'b0}};
     end else if (update) begin
          last  <= select;    
          wait_req_reg <= wait_req;
          emit_ack <= emit_ack ^ select;
          wait_data_reg <= wait_data_mux;
     end
 end

 //Mask generation
 always @(last)
    begin
      case (last) 
         6'b000000 : arb_mask = {11{1'b1}};
         6'b100000 : arb_mask = 11'b01111111111;
         6'b010000 : arb_mask = 11'b00111111111;
         6'b001000 : arb_mask = 11'b00011111111;
         6'b000100 : arb_mask = 11'b00001111111;
         6'b000010 : arb_mask = 11'b00000111111;
         6'b000001 : arb_mask = {11{1'b1}};
         default  : arb_mask = 11'bx;
      endcase
 end



 assign arb_vector = {emit_queue, emit_queue[PORTS-1:1]} & arb_mask;


 
//------------------------------------------------------------------------------
// Beginning of main code (rtl)
//------------------------------------------------------------------------------
  
  //Arbitration
  always @(arb_vector or last)
    begin
      if (arb_vector[10]) select = 6'b100000;
      else if (arb_vector[9]) select = 6'b010000;
      else if (arb_vector[8]) select = 6'b001000;
      else if (arb_vector[7]) select = 6'b000100;
      else if (arb_vector[6]) select = 6'b000010;
      else if (arb_vector[5]) select = 6'b000001;
      else if (arb_vector[4]) select = 6'b100000;
      else if (arb_vector[3]) select = 6'b010000;
      else if (arb_vector[2]) select = 6'b001000;
      else if (arb_vector[1]) select = 6'b000100;
      else if (arb_vector[0]) select = 6'b000010;
      else select = last;
    end

  //Demux the write data
  always @(*)
    begin 
      case (select)
         6'b100000 :  wait_data_mux = emit_data_6;
         6'b010000 :  wait_data_mux = emit_data_5;
         6'b001000 :  wait_data_mux = emit_data_4;
         6'b000100 :  wait_data_mux = emit_data_3;
         6'b000010 :  wait_data_mux = emit_data_2;
         6'b000001 :  wait_data_mux = emit_data_1;
         default  : begin wait_data_mux = {EW_WIDTH{1'b0}}; end
     endcase
   end

//------------------------------------------------------------------------------
// Finish detection logic
//------------------------------------------------------------------------------

 initial
   begin
       #1
       this_port = 31'b0;
       connections = PORTS;

       for (this_port = 0; this_port < PORTS; this_port = this_port + 1) begin

               if (emit_req[this_port] === 1'bz) 
                     connections = connections - 1;

       end

   end

 assign nxt_complete = (~|wait_data_mux) ? complete + 32'b1 : complete;

 always @(posedge pclk or negedge presetn) begin
     if (!presetn) begin
         complete <= 32'b0;    
     end else if (update) begin
         complete <= nxt_complete;
     end
 end

 always @(posedge pclk)
    begin : p_quit
        if (complete == connections) begin
            @(posedge pclk);
            @(posedge pclk);
            @(posedge pclk);
            @(posedge pclk);
            @(posedge pclk);
            $display("All Masters and Slaves have completed\n");
            sim_complete <= 1'b1;
        `ifndef SPECMAN_COMPLETE
            $stop;
        `endif    
        end else begin    
            sim_complete <= 1'b0;
        end
    end

endmodule

