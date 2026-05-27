//============================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2011-2013 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 150065
//
// Date                   :  2013-05-10 07:02:19 +0100 (Fri, 10 May 2013)
//
// Release Information    : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose: Monitors ID oustanding on VNETS
//============================================================================--


`timescale 1ns/1ns

module VnIDMonitor(

   // AXI AW Channel Signals
   AWVALID,
   AWREADY,
   AWID,
   AWVNET,
   AWVALIDo,
   AWREADYo,

   // AXI W Channel Signals
   WVALID,
   WREADY,
   WVNET,
   WLAST,
   WID,
   WVALIDo,
   WREADYo,

   // AXI AR Channel Signals
   ARVALID,
   ARREADY,
   ARID,
   ARVNET,
   ARVALIDo,
   ARREADYo,

   //Bchannel
   BVALID,
   BREADY,
   BID,
   BVALIDo,

   //Rchannnel
   RVALID,
   RREADY,
   RLAST,
   RID,
   RVALIDo,

   // Global Signals
   ACLK,
   ARESETn

);


//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------


  // Parameters below can be set by the user.

  // Select the number of channel ID bits required
  parameter ID_WIDTH = 4;          // (A|W|R|B)ID width

  //Select the number of VNETS;
  parameter NUM_VNETS    = 1;
  parameter VNET_0       = 0;
  parameter VNET_1       = 0;
  parameter VNET_2       = 0;
  parameter VNET_3       = 0;
  parameter VNET_4       = 0;

  //Set the width of the output vectors
  parameter VALID_WIDTH  = NUM_VNETS;

  //Indicated whether to mask or error same ID accross vnets
  parameter NO_ERROR_ON_M_VNET = 0;

  //Rule type AXI3 or AXI4
  parameter AXI4_N_3 = 0;

  //Number of writes
  parameter MAXWBURSTS = 4;
  parameter MAXRBURSTS = 4;

  //Calculated parameters
  localparam ID_MAX = ID_WIDTH - 1;
  localparam VNET_MAX = NUM_VNETS - 1;
  localparam VALID_MAX = VALID_WIDTH - 1;


//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------

  // Global Signals
  input                ACLK;
  input                ARESETn;

  // AXI Channel Signals
  input                AWVALID;
  input                AWREADY;
  input [ID_MAX:0]     AWID;
  input [3:0]          AWVNET;
  output [VALID_MAX:0] AWVALIDo;
  output               AWREADYo;

  // AXI W Channel Signals
  input                WVALID;
  input                WREADY;
  input                WLAST;
  input [3:0]          WVNET;
  input [ID_MAX:0]     WID;
  output [VALID_MAX:0] WVALIDo;
  output               WREADYo;

   // AXI Channel Signals
  input                ARVALID;
  input                ARREADY;
  input [ID_MAX:0]     ARID;
  input [3:0]          ARVNET;
  output [VALID_MAX:0] ARVALIDo;
  output               ARREADYo;

   //Bchannel
  input                BVALID;
  input                BREADY;
  input  [ID_MAX:0]    BID;
  output [VALID_MAX:0] BVALIDo;

  //Rchannnel
  input                RVALID;
  input                RREADY;
  input                RLAST;
  input  [ID_MAX:0]    RID;
  output [VALID_MAX:0] RVALIDo;

//------------------------------------------------------------------------------
// internal signals
//------------------------------------------------------------------------------

  reg [ID_MAX+7:0]     wr_data[MAXWBURSTS-1:0];
  reg [ID_MAX+5:0]     rd_data[MAXRBURSTS-1:0];

  reg [MAXWBURSTS-1:0] wr_load_nxt_addr_new;
  reg [MAXWBURSTS-1:0] wr_load_nxt_data_new;
  reg [MAXWBURSTS-1:0] wr_load_nxt_addr_used;
  reg [MAXWBURSTS-1:0] wr_load_nxt_data_used;
  reg [MAXWBURSTS-1:0] wr_load_bresp;
  reg                  existing_aw_found;
  reg                  existing_w_found;

  reg [MAXRBURSTS-1:0] rd_load_nxt_oh;
  reg [MAXRBURSTS-1:0] rd_pop_oh;

  reg                  b_match_found;
  reg [3:0]            BVNET;

  reg [MAXRBURSTS-1:0] r_match_found;
  reg [3:0]            RVNET;

  reg                  aw_match_found;
  reg [3:0]            AWVNET_i;
  wire                 aw_id_match_on_diff_vnet;
  wire [VNET_MAX:0]    AWVALIDo_i;
  wire [VNET_MAX:0]    WVALIDo_i;

  reg                  ar_match_found;
  reg [3:0]            ARVNET_i;
  wire                 ar_id_match_on_diff_vnet;
  wire [VNET_MAX:0]    ARVALIDo_i;

  wire           [3:0] VNETS [0:4];
  genvar               VN;
  reg                  new_arvalid;

  //VNET assignments
  assign VNETS[0] = VNET_0;
  assign VNETS[1] = VNET_1;
  assign VNETS[2] = VNET_2;
  assign VNETS[3] = VNET_3;
  assign VNETS[4] = VNET_4;

//------------------------------------------------------------------------------
// Wchannel
//------------------------------------------------------------------------------
  generate

     for (VN=0; VN < VALID_WIDTH; VN++) begin : gWVALIDo
        if (VN < NUM_VNETS) begin : giWVALIDo
           assign WVALIDo_i[VN] = (WVNET == VNETS[VN]) & WVALID;
        end else begin
           assign WVALIDo[VN] = 1'b0;
        end
     end

  endgenerate

  //------------------------------------------------------------------------
  // OVL_ASSERT: For W Channel
  //------------------------------------------------------------------------
  assert_win_unchange #(1, 4, 1,
    "AXI_ERRM_WVNET_STABLE. WVNET must remain stable when WVALID is asserted and WREADY low"
  )  axi_errm_wvnet_stable
     (.clk         (ACLK),
      .reset_n     (ARESETn),
      .start_event (WVALID & !WREADY),
      .test_expr   (WVNET),
      .end_event   (!(WVALID & !WREADY))
      );

  assert_never #(0,0,"AXI_ERRM_WVNET_INVALID. W Beat on unrecognised VNET")
     axi_errm_wvnet_invalid
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (WVALID & ~|WVALIDo_i)
       );

//------------------------------------------------------------------------------
// AWchannel
//------------------------------------------------------------------------------

  //Find the first empty slot to put an address into
  always @(*) begin : p_find_aw_load_new
       integer a;
       reg     build_or_addr_new;
       reg     build_or_data_new;
       reg     allow_new_data;
       build_or_addr_new     = 1'b0;
       build_or_data_new     = 1'b0;
       wr_load_nxt_addr_new  = {MAXWBURSTS{1'b0}};
       wr_load_nxt_data_new  = {MAXWBURSTS{1'b0}};
       wr_load_nxt_addr_used = {MAXWBURSTS{1'b0}};
       wr_load_nxt_data_used = {MAXWBURSTS{1'b0}};
       existing_aw_found     = 1'b0;
       existing_w_found      = 1'b0;

       for (a = 0; a < MAXWBURSTS; a = a + 1) begin

           //Find next empty address slot
           wr_load_nxt_addr_new[a] = ~wr_data[a][0] & ~wr_data[a][1] & ~build_or_addr_new;
           build_or_addr_new = build_or_addr_new | (~wr_data[a][0] & ~wr_data[a][1]);

           if (AXI4_N_3 == 0) begin

              //Find next slot with no address but which matched data
              if (~wr_data[a][0] & wr_data[a][1] & wr_data[a][ID_MAX+7:7] == AWID) begin
                   wr_load_nxt_addr_used[a] = ~existing_aw_found;
                   existing_aw_found = 1'b1;
              end

              //Find next slot with address but no data
              if (wr_data[a][0] & ~wr_data[a][1] & wr_data[a][ID_MAX+7:7] == WID) begin
                    wr_load_nxt_data_used[a] = ~existing_w_found;
                    existing_w_found = 1'b1;
              end

              allow_new_data = ~wr_data[a][0] & ~wr_data[a][1] & (~wr_load_nxt_addr_new[a] || ~AWVALID || existing_aw_found || (WID == AWID));
              wr_load_nxt_data_new[a] = allow_new_data & ~build_or_data_new;
              build_or_data_new = build_or_data_new | allow_new_data;

           end
       end
  end

  //Find a slot to pop/put bresp in (must have had wlast but not necessarily address)
  //Must have wdata and not bresp
  always @(*) begin : p_find_b_match
       integer b;
       BVNET         = 4'b0000;
       b_match_found = 1'b0;
       wr_load_bresp     = {MAXWBURSTS{1'b0}};
       for (b = 0; b < MAXWBURSTS; b = b + 1) begin
           if ((wr_data[b][ID_MAX+7:7] == BID) & (wr_data[b][1]) & ~((wr_data[b][2]))) begin
              BVNET = BVNET | wr_data[b][6:3];
              wr_load_bresp[b] = ~b_match_found;
              b_match_found = 1'b1;
           end
       end
  end

  //Check to see that the current AWID is not currently routed somewhere else
  //This check only uses transactions that have had AWVALID
  always @(*) begin : p_find_aw_match
       integer c;
       AWVNET_i       = 4'b0000;
       aw_match_found = 1'b0;
       for (c = 0; c < MAXWBURSTS; c = c + 1) begin
           if ((wr_data[c][ID_MAX+7:7] == AWID) & (wr_data[c][0])) begin
              AWVNET_i = AWVNET_i | wr_data[c][6:3];
              aw_match_found = 1'b1;
           end
       end
  end

  always @(posedge ACLK or negedge ARESETn) begin : p_update
      if (~ARESETn) begin : p_update_reset
           integer i;
           for (i = 0; i < MAXWBURSTS; i = i + 1) begin
               wr_data[i][0] = 1'b0;
               wr_data[i][1] = 1'b0;
               wr_data[i][2] = 1'b0;
           end
      end else begin : p_update_normal
           integer j;
           for (j = 0; j < MAXWBURSTS; j = j + 1) begin

               //wlast must always be before bresp and can therefore just be added
               if (AXI4_N_3 == 0 && wr_load_nxt_data_used[j] && WVALID && WREADYo && WLAST)
                  wr_data[j][1] <= 1'b1;

               if (AXI4_N_3 == 0 && wr_load_nxt_data_new[j] && ~existing_w_found && WVALID && WREADYo && WLAST) begin
                  // May be add both
                  if (wr_load_nxt_addr_new[j] && ~existing_aw_found && AWVALID && AWREADYo)
                      wr_data[j] <= {WID, WVNET, 1'b0, 1'b1, 1'b1};
                  else
                      wr_data[j] <= {WID, WVNET, 1'b0, 1'b1, 1'b0};

               //Add the address - if no wdata can just be added
               end else if (wr_load_nxt_addr_new[j] && ~existing_aw_found && AWVALID && AWREADYo)
                  wr_data[j] <= {AWID, AWVNET, 1'b0, (AXI4_N_3 == 1), 1'b1};

               //Add the address into existing entry
               if (wr_load_nxt_addr_used[j] && AWVALID && AWREADYo) begin

                  //Address and response seen or ariving
                  if ((wr_load_bresp[j] && BVALID && BREADY) || wr_data[j][2]) begin
                      wr_data[j][2] <= 1'b1;
                      wr_data[j][0] <= 1'b0;
                      wr_data[j][1] <= 1'b0;
                  end else begin
                      wr_data[j][0] <= 1'b1;
                  end

               //Deal with the BRESP
               //Record the bresp and clear both AW and W flags if both seen
               end else if (wr_load_bresp[j] && BVALID && BREADY) begin
                   wr_data[j][2] <= 1'b1;
                   wr_data[j][0] <= wr_data[j][0] & ~wr_data[j][1];
                   wr_data[j][1] <= wr_data[j][1] & ~wr_data[j][0];
               end
           end
      end
  end

  //Detch a mismatched ID
  assign aw_id_match_on_diff_vnet = AWVALID & aw_match_found & (AWVNET != AWVNET_i);

  //Mux out the AWVALID
  generate

     for (VN=0; VN < VALID_WIDTH; VN = VN + 1) begin : gAWVALIDo
        if (VN < NUM_VNETS) begin : giAWVALIDo
           assign AWVALIDo_i[VN] = (AWVNET == VNETS[VN]) & AWVALID;
           assign BVALIDo[VN]    = (BVNET == VNETS[VN]) & BVALID;
        end else begin
           assign AWVALIDo[VN] = 1'b0;
           assign BVALIDo[VN]    = 1'b0;
        end
     end

  endgenerate

  //Assign the ouputs if not masked
  assign AWVALIDo = AWVALIDo_i & {NUM_VNETS{~(aw_id_match_on_diff_vnet & (NO_ERROR_ON_M_VNET == 1))}};
  assign AWREADYo = AWREADY & ~(aw_id_match_on_diff_vnet & (NO_ERROR_ON_M_VNET == 1));

  //Assign the WREADY output
  assign WVALIDo  = WVALIDo_i & {NUM_VNETS{(NO_ERROR_ON_M_VNET == 0 || (AXI4_N_3 == 1) || (WVALID & existing_w_found))}};
  assign WREADYo  = WREADY & (NO_ERROR_ON_M_VNET == 0 || (AXI4_N_3 == 1) || (WVALID & existing_w_found));

  //------------------------------------------------------------------------
  // OVL_ASSERT: For AW Channel
  //------------------------------------------------------------------------
  assert_win_unchange #(1, 4, 1,
    "AXI_ERRM_AWVNET_STABLE. AWVNET must remain stable when AWVALID is asserted and WREADY low"
  )  axi_errm_awvnet_stable
     (.clk         (ACLK),
      .reset_n     (ARESETn),
      .start_event (AWVALID & !AWREADY),
      .test_expr   (AWVNET),
      .end_event   (!(AWVALID & !AWREADY))
      );

  assert_never #(0,0,"AXI_ERRM_AWVNET_ID_UNIQ. An ID may only be active on 1 VNET at a time")
     axi_errm_awvnet_id_uniq
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (AWVALID & aw_id_match_on_diff_vnet & (NO_ERROR_ON_M_VNET == 0))
       );

  assert_never #(0,0,"AXI_ERRM_AWVNET_INVALID. AW Beat on unrecognised VNET")
     axi_errm_awvnet_invalid
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (AWVALID & ~|AWVALIDo_i)
       );

 assert_never #(2,0,"AXI_ERRM_BVALID. Unexpected BRESP")
     axi_errm_illegal_bresp
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (BVALID & ~b_match_found)
       );

//------------------------------------------------------------------------------
// ARchannel
//------------------------------------------------------------------------------

  //Find the next slot to push into (one_hot)
  always @(*) begin : p_find_ar_load
       integer e;
       reg     build_or;
       build_or = 1'b0;
       for (e = 0; e < MAXRBURSTS; e = e + 1) begin
           rd_load_nxt_oh[e] = ~rd_data[e][0] & ~build_or;
           build_or = build_or | ~rd_data[e][0];
       end
  end

  //Find a slot to pop (and extract vnet)
  always @(*) begin : p_find_r_match
       integer f;
       RVNET         = 4'b0000;
       r_match_found = 1'b0;
       rd_pop_oh     = {MAXRBURSTS{1'b0}};
       for (f = 0; f < MAXRBURSTS; f = f + 1) begin
           if ((rd_data[f][ID_MAX+5:5] == RID) & (rd_data[f][0])) begin
              RVNET = RVNET | rd_data[f][4:1];
              rd_pop_oh[f] = ~r_match_found;
              r_match_found = 1'b1;
           end
       end
  end

  //Check to see that the current AWID is not currently routed somewhere else
  always @(*) begin : p_find_ar_match
       integer g;
       ARVNET_i       = 4'b0000;
       ar_match_found = 1'b0;
       for (g = 0; g < MAXRBURSTS; g = g + 1) begin
           if ((rd_data[g][ID_MAX+5:5] == ARID) & (rd_data[g][0])) begin
              ARVNET_i = ARVNET_i | rd_data[g][4:1];
              ar_match_found = 1'b1;
           end
       end
  end

  //Create a flag to detect the start of an ARVALID transaction
  always @(posedge ACLK or negedge ARESETn) begin
      if (~ARESETn) begin
          new_arvalid <= 1'b1;
      end else begin
          new_arvalid <= ~(ARVALID & ~ARREADYo) || ar_id_match_on_diff_vnet;
      end
  end


  always @(posedge ACLK or negedge ARESETn) begin
      if (~ARESETn) begin : p_update_ar_reset
           integer i;
           for (i = 0; i < MAXRBURSTS; i = i + 1) begin
               rd_data[i][0] = 1'b0;
           end
      end else begin : p_update_ar_normal
           integer j;
           for (j = 0; j < MAXRBURSTS; j = j + 1) begin
               if (rd_load_nxt_oh[j] & ARVALID & new_arvalid & ~ar_id_match_on_diff_vnet)
                  rd_data[j] <= {ARID, ARVNET, 1'b1};
               if (rd_pop_oh[j] & RVALID & RREADY & RLAST)
                  rd_data[j][0] <= 1'b0;
           end
      end
  end

  //Detch a mismatched ID
  assign ar_id_match_on_diff_vnet = ARVALID & ar_match_found & (ARVNET != ARVNET_i);

  //Mux out the ARVALID
  generate

     for (VN=0; VN < VALID_WIDTH; VN = VN + 1) begin : gARVALIDo
         if (VN < NUM_VNETS) begin : giARVALIDo
           assign ARVALIDo_i[VN] = (ARVNET == VNETS[VN]) & ARVALID;
           assign RVALIDo[VN]    = (RVNET == VNETS[VN]) & RVALID;
        end else begin
           assign ARVALIDo[VN] = 1'b0;
           assign RVALIDo[VN]  = 1'b0;
        end
    end
  endgenerate

  //Assign the ouputs if not masked
  assign ARVALIDo = ARVALIDo_i & {NUM_VNETS{~(ar_id_match_on_diff_vnet & (NO_ERROR_ON_M_VNET == 1))}};
  assign ARREADYo = ARREADY & ~(ar_id_match_on_diff_vnet & (NO_ERROR_ON_M_VNET == 1));

  //------------------------------------------------------------------------
  // OVL_ASSERT: For AR Channel
  //------------------------------------------------------------------------
  assert_win_unchange #(1, 4, 1,
    "AXI_ERRM_ARVNET_STABLE. ARVNET must remain stable when ARVALID is asserted and WREADY low"
  )  axi_errm_arvnet_stable
     (.clk         (ACLK),
      .reset_n     (ARESETn),
      .start_event (ARVALID & !ARREADY),
      .test_expr   (ARVNET),
      .end_event   (!(ARVALID & !ARREADY))
      );

  assert_never #(0,0,"AXI_ERRM_ARVNET_ID_UNIQ. An ID may only be active on 1 VNET at a time")
     axi_errm_arvnet_id_uniq
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (ARVALID & ar_id_match_on_diff_vnet & (~|NO_ERROR_ON_M_VNET))
       );

  assert_never #(0,0,"AXI_ERRM_ARVNET_INVALID. AR Beat on unrecognised VNET")
     axi_errm_arvnet_invalid
       (
        .clk       (ACLK),
        .reset_n   (ARESETn),
        .test_expr (ARVALID & ~|ARVALIDo_i)
       );

endmodule // VnIDMonitor
