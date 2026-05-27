//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2007-2009 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 84515
// File Date           :  2009-11-04 14:08:20 +0000 (Wed, 04 Nov 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : This is the AHB-Lite Protocol Checker using OVL
//------------------------------------------------------------------------------


//============================================================================
//
// Usage: Instantiate AhbPC at the same level as your AHB Master/Slave. The 
// inputs into AhbPC are the relevant AHB signals of the Master/Slave.
//
// Configuration: 
//    width: The default {data,address} widths are 32. These can be changed
//      when the AhbPC is instantiated by setting the {DATA,ADDRESS}_WIDTH
//      parameters. 
//    Prove/Assume/Ignore rules: The default is to prove both {Master,Slave} 
//      {ERR,REC,AUX} rules. You can change the ERR*_PropertyType 
//      parameters alter this. For instance, to prove the Master rules
//      while assuming the slave ones, instantiate AhbPC like this:
//
//       AhbPC #(32,32, // data, address widths
//               `OVL_ASSERT, `OVL_ASSERT, `OVL_ASSERT, // prove all Master rules
//               `OVL_ASSUME, `OVL_ASSUME, `OVL_ASSUME) // assume all Slave ones
//       ProveMaster_AssumeSlave_AhbPC ( .HCLK(CLK), .... );
//
//============================================================================



//----------------------------------------------------------------------------
// CONTENTS (last updated: Wed Feb 20 09:37:59 GMT 2008)
// ========
//  130.  Verilog Defines
//  144.  AHB Defines
//  191.  AHB Configuration Options
//  197.  
//  198.  Module: AhbPC
//  241.    - Parameters
//  245.       > Configurable (user can set)
//  263.       > Calculated (user should not override)
//  285.    - Inputs (no outputs)
//  328.    - Wire and Reg Declarations
//  348.  
//  349.  Auxiliary Logic
//  352.    - HCLKEN_D1
//  360.    - HREADY_D1
//  367.    - HREADYOUT_D1
//  374.    - HRESP_D1
//  381.    - HWDATA_D1
//  388.    - HSIZE_D1
//  396.    - HTRANS_D1
//  404.    - HBURST_D1
//  411.    - HWRITE_D1
//  418.    - HADDR_D1
//  426.    - HPROT_D1
//  433.    - HMASTLOCK_D1
//  441.    - tb_selected
//  491.    - ahbpc_granted
//  502.    - ahbpc_granted_D1
//  516.    - ahbpc_last_*
//  533.    - ahbpc_burst_left
//  575.  
//  576.  Format for time reporting
//  584.  
//  585.  AHB Master Rules (alpabetical by name):
//  589.    - ahb_errm_align
//  678.    - ahb_recm_align
//  770.    - ahb_errm_burst
//  800.    - ahb_errm_burst_bound
//  856.    - ahb_errm_burst_len
//  873.    - ahb_errm_busy
//  890.    - ahb_errm_busy_ctl
//  911.    - ahb_errm_busy_end
//  930.    - ahb_errm_ctl
//  955.    - ahb_errm_high_addr
//  976.    - ahb_errm_incr_addr
// 1016.    - ahb_errm_lock_burst
// 1033.    - ahb_recm_lock_idle
// 1054.    - ahb_errm_reset
// 1072.    - ahb_errm_seq
// 1088.    - ahb_errm_single
// 1105.    - ahb_errm_too_wide
// 1121.    - ahb_errm_trans1
// 1146.    - ahb_errm_trans2
// 1162.    - ahb_errm_trans3
// 1205.    - ahb_errm_wdata
// 1224.    - ahb_errm_wrap_addr
// 1390.  
// 1391.  AHB Slave Rules (alpabetical by name):
// 1395.    - ahb_errs_busy
// 1415.    - ahb_errs_idle
// 1437.    - ahb_recs_ready
// 1451.    - ahb_errs_reset
// 1466.    - ahb_recs_reset
// 1481.    - ahb_recs_resp
// 1496.    - ahb_errs_resp1
// 1520.    - ahb_errs_resp2
// 1548.  
// 1549.  Auxilliary logic rules
// 1552.    - ahb_auxm_data_width
// 1572.      - X-check inputs
// 1633.  
// 1634.  Clear Verilog Defines
// 1684.  End of module
// 1690.  
// 1691.  End of File
//----------------------------------------------------------------------------

`timescale 1ns/1ns

//------------------------------------------------------------------------------
// INDEX: Verilog Defines
//------------------------------------------------------------------------------

// OVL Severity levels
`define OVL_SimFatal   0 // Simulation error + stop
`define OVL_SimError   1 // Simulation error (non-fatal)
`define OVL_SimWarning 2 // Simulation warning
`define OVL_SimCover   3 // Simulation coverage-point
`define OVL_SimInfo    4 // Simulation info

// OVL Proof Options (all others set via parameters)
`define OVL_SkipFormalProof 0 // Don't formally verify (ignore)

//------------------------------------------------------------------------------
// INDEX: AHB Defines
//------------------------------------------------------------------------------
`include "AhbDefns.v"


//------------------------------------------------------------------------------
// INDEX: AHB Configuration Options
//------------------------------------------------------------------------------
`define AHB_LITE 1


//------------------------------------------------------------------------------
// INDEX: 
// INDEX: Module: AhbPC
//------------------------------------------------------------------------------
module PL301_AhbPC
  (
   // clock
   HCLK,
   HCLKEN,

   // active low reset
   HRESETn,

   // Main Master signals
   HADDR,
   HAUSER,
   HTRANS,
   HWRITE,
   HSIZE,
   HBURST,
   HPROT,
   HWDATA,
   HWUSER,

   // Main Decoder signals
   HSELx,

   // Main Slave signals
   HRDATA, // NOTE: not used
   HRUSER,
   HREADY,
   HREADYOUT, // HREADY signal from Slave
   HRESP,

   // Master Arbitration signals
   HLOCKx,

   // Arbiter Arbitration signals
   HGRANTx,
   // HMASTER, // NOTE: not used

   // Slave Arbitration signals
   // HSPLITx, // NOTE: not used
   HMASTLOCK,

   //ID signal
   HID,

   //Strobe Signal
   HSTROBE
   );


//------------------------------------------------------------------------------
// INDEX:   - Parameters
//------------------------------------------------------------------------------
  

  // INDEX:      > Configurable (user can set)
  // =====
  // Parameters below can be set by the user.
  
  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH       = 32;      // data bus width, default = 32-bit
  parameter ADDRESS_WIDTH    = 32;      // address bus width, default = 32-bit
  parameter ID_WIDTH         = 1;       // id_bus_width, default = 1-bit
  parameter HAUSER_WIDTH     = 8;
  parameter HRUSER_WIDTH     = 8;
  parameter HWUSER_WIDTH     = 8;
  parameter HUSER_MAX        = (HRUSER_WIDTH > HWUSER_WIDTH) ? HRUSER_WIDTH : HWUSER_WIDTH;
  
  // Property type (0=prove, 1=assume, 2=ignore).
  parameter ERRM_PropertyType = 0; // default: prove Master is AHB compliant
  parameter RECM_PropertyType = 0; // default: prove Master is AHB compliant
  parameter AUXM_PropertyType = 0; // default: prove Master auxiliary logic checks
  //
  parameter ERRS_PropertyType = 0; // default: prove Slave is AHB compliant
  parameter RECS_PropertyType = 0; // default: prove Slave is AHB compliant
  parameter AUXS_PropertyType = 0; // default: prove Slave auxiliary logic checks

  parameter HAUSER_MAX     = HAUSER_WIDTH - 1;
  parameter HRUSER_MAX     = HRUSER_WIDTH - 1;
  parameter HWUSER_MAX     = HWUSER_WIDTH - 1;

  parameter LOCK_IGNORE    = 0;


  // INDEX:      > Calculated (user should not override)
  // =====
  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  
  // hi-index of DATA_WIDTH
  parameter DATA_MAX = (DATA_WIDTH - 1);

  // hi-index of Strobe
  parameter STRB_MAX = ((DATA_WIDTH / 8) - 1);

  // address width max
  parameter ADDRESS_MAX = (ADDRESS_WIDTH - 1);

  // maximum size of HSIZE, given DATA_WIDTH bus width.
  parameter HSIZE_MAX =
    ((DATA_WIDTH == 8)   ? 0 :
     (DATA_WIDTH == 16)  ? 1 :
     (DATA_WIDTH == 32)  ? 2 :
     (DATA_WIDTH == 64)  ? 3 :
     (DATA_WIDTH == 128) ? 4 :
     (DATA_WIDTH == 256) ? 5 :
     (DATA_WIDTH == 512) ? 6 : 7);

//------------------------------------------------------------------------------
// INDEX:   - Inputs (no outputs)
//------------------------------------------------------------------------------

  // Clock signals
  input     HCLK;
  input     HCLKEN; // NOTE: what will we do with this?

  // Reset, active low
  input     HRESETn;

  // Master signals
  input [ADDRESS_MAX:0] HADDR;
  input [HAUSER_MAX:0]  HAUSER;
  input [1:0]           HTRANS;
  input                 HWRITE;
  input [2:0]           HSIZE;
  input [2:0]           HBURST;
  input [3:0]           HPROT;
  input [DATA_MAX:0]    HWDATA;
  input [HWUSER_MAX:0]  HWUSER;

   // Decoder signals
  input        HSELx;

   // Slave signals
  input [DATA_MAX:0] HRDATA;
  input [HRUSER_MAX:0]  HRUSER;
  input        HREADY;
  input        HREADYOUT;
  input [1:0]  HRESP;

   // Arbitration signals from Master

  input        HLOCKx;

   // Arbitration signals from Arbiter
  input        HGRANTx;
  //  input [3:0]  HMASTER;
  input        HMASTLOCK ;

  //ID bus
  input [ID_WIDTH-1:0] HID;
  input [STRB_MAX:0]   HSTROBE;

   // Arbitration signals from Slave
  //  input [15:0] HSPLITx;
  
  reg        tb_selected ;

//------------------------------------------------------------------------------
// INDEX:   - Wire and Reg Declarations
//------------------------------------------------------------------------------

  // User signal definitions are defined as weak pull-down in the case
  // that they are unconnected.
  tri0 [HAUSER_MAX:0] HAUSER;
  tri0  [HWUSER_MAX:0] HWUSER;
  tri0  [HRUSER_MAX:0] HRUSER;
  wire  [HUSER_MAX:0] HUSER;

  reg                 HCLKEN_D1;

  reg                 HREADY_D1;
  reg                 HREADYOUT_D1;
  
  reg [1:0]           HRESP_D1;
  reg [DATA_MAX:0]    HWDATA_D1;
  reg [HWUSER_MAX:0]  HWUSER_D1;
  reg [2:0]           HSIZE_D1;
  
  reg [1:0]           HTRANS_D1;
  reg [2:0]           HBURST_D1;
  reg                 HWRITE_D1;
  reg [ADDRESS_MAX:0] HADDR_D1;
  reg [3:0]           HPROT_D1;
  reg                 HMASTLOCK_D1;
  wire                HSEL;
  wire [DATA_MAX:0]   HWDATA_STRB;
  reg [DATA_MAX:0]    HWDATA_MASK;

//------------------------------------------------------------------------------
// INDEX: 
// INDEX: Format for time reporting and 
//------------------------------------------------------------------------------
initial 
    begin
    
        $timeformat(-9, 0, " ns", 0);
        $display("AHB_INFO: Running AhbPC released with PL301r2");

    end

//------------------------------------------------------------------------------
// INDEX: 
// INDEX: Auxiliary Logic
//------------------------------------------------------------------------------

  // INDEX:   - HCLKEN_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HCLKEN_D1 <= 1'b0;
       else
         HCLKEN_D1 <= HCLKEN;


  // INDEX:   - HREADY_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HREADY_D1 <= 1'b0;
       else
         HREADY_D1 <= HREADY;

  // INDEX:   - HREADYOUT_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HREADYOUT_D1 <= 1'b0;
       else
         HREADYOUT_D1 <= HREADYOUT;

  // INDEX:   - HRESP_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HRESP_D1 <= `AHB_RESP_OKAY;
       else
         HRESP_D1 <= HRESP;

  // INDEX:   - HWDATA_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         begin
         HWDATA_D1 <= {DATA_WIDTH{1'b0}};
         HWUSER_D1 <= {HWUSER_WIDTH{1'b0}};
         end
       else
         begin
         HWDATA_D1 <= HWDATA_STRB;
         HWUSER_D1 <= HWUSER;
         end

  // INDEX:   - HSIZE_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HSIZE_D1 <= 3'b000;
       else
         HSIZE_D1 <= HSIZE;


  // INDEX:   - HTRANS_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HTRANS_D1 <= `AHB_TRANS_IDLE;
       else
         HTRANS_D1 <= HTRANS;


  // INDEX:   - HBURST_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HBURST_D1 <= 3'b000;
       else
         HBURST_D1 <= HBURST;

  // INDEX:   - HWRITE_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HWRITE_D1 <= 1'b0;
       else
         HWRITE_D1 <= HWRITE;

  // INDEX:   - HADDR_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HADDR_D1 <= {ADDRESS_WIDTH{1'b0}};
       else
         HADDR_D1 <= HADDR;


  // INDEX:   - HPROT_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HPROT_D1 <= 4'b0000;
       else
         HPROT_D1 <= HPROT;

  // INDEX:   - HMASTLOCK_D1
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         HMASTLOCK_D1 <= 1'b0;
       else
         HMASTLOCK_D1 <= HMASTLOCK;


  // INDEX:   - tb_selected
     always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn)
         tb_selected <= 1'b0;
       else
         if (HREADY & HCLKEN)
           tb_selected <= HSELx;

  // Create a strobed version of HWDATA
    integer i;
    always @(HSTROBE)
      begin 
         HWDATA_MASK = {DATA_WIDTH{1'b0}};
         for (i = 0; i <= STRB_MAX; i = i+1) 
         begin
            HWDATA_MASK = {{8{HSTROBE[i]}}, HWDATA_MASK[DATA_WIDTH-1:8]};  
         end
      end
    
    assign HWDATA_STRB = HWDATA & HWDATA_MASK;

//----------------------------------------------------------------------------
// Internal global signals
//----------------------------------------------------------------------------

   wire int_fixed;
   assign HSEL = HSELx;
   assign int_fixed = (HBURST != 3'b001); // fixed bursts are all but INCR

   wire int_htrans_idle;
   wire int_htrans_busy;
   reg  int_htrans_busy_dphase;
   wire int_htrans_nseq;
   wire int_htrans_seq;
   assign int_htrans_idle = (HTRANS == `AHB_TRANS_IDLE);
   assign int_htrans_busy = (HTRANS == 2'b01);
   assign int_htrans_nseq = (HTRANS == 2'b10);
   assign int_htrans_seq  = (HTRANS == 2'b11);

   reg [3:0] int_seq_beats;
   // number of SEQ beats in a fixed-length burst
   always @ (HBURST)
     begin
        case (HBURST)
          3'b000  : int_seq_beats = 4'b0000; // SINGLE
          3'b001  : int_seq_beats = 4'b0000; // INCR   (N/A - not fixed!)
          3'b010  : int_seq_beats = 4'b0011; // WRAP4
          3'b011  : int_seq_beats = 4'b0011; // INCR4
          3'b100  : int_seq_beats = 4'b0111; // WRAP8
          3'b101  : int_seq_beats = 4'b0111; // INCR8
          3'b110  : int_seq_beats = 4'b1111; // WRAP16
          3'b111  : int_seq_beats = 4'b1111; // INCR16
          default : int_seq_beats = 4'b0000; // really a don't-care
        endcase // case(HBURST)
     end // always begin

   wire int_update; // sample on HREADY (if HCLKEN)
   assign int_update = (HREADY & HCLKEN);

   always @(posedge HCLK or negedge HRESETn)
     if (~HRESETn)
        int_htrans_busy_dphase <= 1'b0;
     else
         if (int_update)
            int_htrans_busy_dphase <= int_htrans_busy;

//----------------------------------------------------------------------------
// Test-bench signals just sampled by HREADY (if HCLKEN)
//----------------------------------------------------------------------------

  // INDEX:   - ahbpc_granted
  // =====
  reg     ahbpc_granted;
  always @(posedge HCLK or negedge HRESETn)
    begin
      if (~HRESETn)
        ahbpc_granted <= 1'b0;
      else if (HCLKEN)
        ahbpc_granted <= HREADY & (HTRANS != `AHB_TRANS_IDLE);
    end // always @ (posedge HCLK or negedge HRESETn)

  // INDEX:   - ahbpc_granted_D1
  // =====
  reg ahbpc_granted_D1 ;
  always @(posedge HCLK or negedge HRESETn)
    if (~HRESETn)
      ahbpc_granted_D1 <= 1'b0;
    else
      ahbpc_granted_D1 <= ahbpc_granted;


//----------------------------------------------------------------------------
// Test-bench signals sampled by HREADY + enable
//----------------------------------------------------------------------------

// INDEX:   - ahbpc_last_*
// =====
  reg        ahbpc_last_hwrite;
  always @(posedge HCLK or negedge HRESETn)
  begin
    if (~HRESETn)
      ahbpc_last_hwrite <= 1'b0;
    else if (int_update)
      ahbpc_last_hwrite <= HWRITE & (HTRANS != 2'b00);
  end // always @ (posedge HCLK or negedge HRESETn)

  assign HUSER = (ahbpc_last_hwrite & ~int_htrans_busy_dphase) ? HWUSER : HRUSER;

//----------------------------------------------------------------------------
// Test-bench down counters
//----------------------------------------------------------------------------

  // INDEX:   - ahbpc_burst_left
  // =====
  // Counter
  reg [3:0] ahbpc_burst_left;

  wire   int_burst_left_SYNC_RESET;
  assign int_burst_left_SYNC_RESET = (  (~HGRANTx | HRESP[1]) |// interrupt
                                        int_htrans_idle |
                                        (int_htrans_nseq & ~int_fixed)
                                     );

  wire   int_new_burst;
  assign int_new_burst = (ahbpc_burst_left == 4'b0000);

  // NOTE: The ~int_new_burst term is redundant, but left in to help avoid
  // ====  initialisation problems in property checking.
  wire   int_burst_left_DECREMENT;
  assign int_burst_left_DECREMENT = (int_htrans_seq & int_fixed & ~int_new_burst);

  wire   int_burst_left_LOAD;
  assign int_burst_left_LOAD = (int_htrans_nseq & int_fixed);

  always @(posedge HCLK or negedge HRESETn)
  begin
    if (~HRESETn)
      ahbpc_burst_left <= 4'b0000;
    else
      if (int_update)
        // update on HREADY (if HCLKEN)
        if (int_burst_left_SYNC_RESET)
          ahbpc_burst_left <= 4'b0000;
        else if (int_burst_left_LOAD)
          ahbpc_burst_left <= int_seq_beats;
        else if (int_burst_left_DECREMENT)
          ahbpc_burst_left <= (ahbpc_burst_left - 4'b0001);
  end // always @ (posedge HCLK or negedge HRESETn)






`ifdef ARM_ASSERT_ON

//------------------------------------------------------------------------------
// INDEX: 
// INDEX: AHB Master Rules (alpabetical by name):
//------------------------------------------------------------------------------


// INDEX:   - ahb_errm_align
// =====
// Split into 7 sub-rules, to cover different AHB address sizes (16 to 1024-bit).

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_1of7: HADDR[0] must be 0 for half-word Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries(that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_1of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_16)),
     .consequent_expr (HADDR[0] == 1'b0)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_2of7: HADDR[1:0] must be 0 for word Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_2of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_32)),
     .consequent_expr (HADDR[1:0] == 2'b00)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_3of7: HADDR[2:0] must be 0 for double-word Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_3of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_64)),
     .consequent_expr (HADDR[2:0] == 3'b000)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_4of7: HADDR[3:0] must be 0 for 128bit Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_4of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_128)),
     .consequent_expr (HADDR[3:0] == 4'b0000)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_5of7: HADDR[4:0] must be 0 for 256-bit Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_5of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_256)),
     .consequent_expr (HADDR[4:0] == 5'b00000)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_6of7: HADDR[5:0] must be 0 for 512-bit Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_6of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_512)),
     .consequent_expr (HADDR[5:0] == 6'b000000)
     );

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_align_7of7: HADDR[6:0] must be 0 for 1024-bit Non-IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_errm_align_7of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS != `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_1024)),
     .consequent_expr (HADDR[6:0] == 7'b0000000)
     );


// INDEX:   - ahb_recm_align 
// =====
// Split into 7 sub-rules, to cover different AHB address sizes (16 to 1024-bit).
//
// This is like errm_align, but covers the IDLE transfers excluded from the
// mandatory rule.

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_1of7: HADDR[0] must be 0 for half-word IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_1of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_16)),
     .consequent_expr (HADDR[0] == 1'b0)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_2of7: HADDR[1:0] must be 0 for word IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_2of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_32)),
     .consequent_expr (HADDR[1:0] == 2'b00)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_3of7: HADDR[2:0] must be 0 for double-word IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_3of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_64)),
     .consequent_expr (HADDR[2:0] == 3'b000)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_4of7: HADDR[3:0] must be 0 for 128bit IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_4of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_128)),
     .consequent_expr (HADDR[3:0] == 4'b0000)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_5of7: HADDR[4:0] must be 0 for 256-bit IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_5of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_256)),
     .consequent_expr (HADDR[4:0] == 5'b00000)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_6of7: HADDR[5:0] must be 0 for 512-bit IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_6of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_512)),
     .consequent_expr (HADDR[5:0] == 6'b000000)
     );

  assert_implication
    #(`OVL_SimError, 
      RECM_PropertyType,
      "ahb_recm_align_7of7: HADDR[6:0] must be 0 for 1024-bit IDLE transfers. AHBLite 1.0, Section 3.5, Page 3-10: All transfers must be aligned to the addresss boundary equal to the size of the transfer. For example, word transfers must be aligned to the word address boundaries (that is, A[1:0]=00), halfword transfers must be aligned to halfword boundaries (that is A[0]=0)."
      )
   ahb_recm_align_7of7
    (.clk             (HCLK),
     .reset_n         (HRESETn),
     .antecedent_expr ((HTRANS == `AHB_TRANS_IDLE) & (HSIZE == `AHB_SIZE_1024)),
     .consequent_expr (HADDR[6:0] == 7'b0000000)
     );


// INDEX:   - ahb_errm_burst
// =====
  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_burst_1of2: All transfers in a fixed-length burst must finish. AHB 2.0, Section 3.6, Page 3-12: When a master starts a fixed length burst, it must complete all the transfers in the burst before performing any other transfers on the bus. A master is only allowed to cancel the remaining transfers in the burst if the slave provides an Error response."
    )
  ahb_errm_burst_1of2
    (
     .clk ( HCLK ),
     .reset_n ( HRESETn ),
     .antecedent_expr ( (ahbpc_burst_left != 4'b0000) & (HRESP[1:0]==`AHB_RESP_OKAY) ),// Bits [1:0] to distinguish from ARM11 extensions
     .consequent_expr ( HTRANS!=`AHB_TRANS_IDLE )
     );


  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_burst_2of2: All transfers in a fixed-length burst must finish. AHB 2.0, Section 3.6, Page 3-12: When a master starts a fixed length burst, it must complete all the transfers in the burst before performing any other transfers on the bus. A master is only allowed to cancel the remaining transfers in the burst if the slave provides an Error response."
      )
  ahb_errm_burst_2of2
    (
     .clk ( HCLK ),
     .reset_n ( HRESETn ),
     .antecedent_expr ( ahbpc_burst_left != 4'b0000 ) ,
     .consequent_expr ( HTRANS != `AHB_TRANS_NSEQ )
     );


// INDEX:   - ahb_errm_burst_bound
// =====  
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_burst_bound: Fixed-length burst cannot cross 1K boundary. AHBLite 1.0, Section 3.5, Page 3-9: A fixed length incrementing burst must not be started which would cause the burst to cross a 1k-byte boundary."
      )
  ahb_errm_burst_bound
    (
     .clk (HCLK),
     .reset_n (HRESETn),
     .antecedent_expr
       (
         ((HBURST==`AHB_BURST_INCR4) | (HBURST==`AHB_BURST_INCR8)
           | (HBURST==`AHB_BURST_INCR16)) & (HTRANS==`AHB_TRANS_NSEQ)),
     .consequent_expr
       (
 (HBURST==`AHB_BURST_INCR4)    ?
           (   (HSIZE==`AHB_SIZE_8)    ? (HADDR[9:0]<=10'b11_1111_1100)//h3FC
             : (HSIZE==`AHB_SIZE_16)   ? (HADDR[9:0]<=10'b11_1111_1000)//h3F8
             : (HSIZE==`AHB_SIZE_32)   ? (HADDR[9:0]<=10'b11_1111_0000)//h3F0
             : (HSIZE==`AHB_SIZE_64)   ? (HADDR[9:0]<=10'b11_1110_0000)//h3E0
             : (HSIZE==`AHB_SIZE_128)  ? (HADDR[9:0]<=10'b11_1100_0000)//h3C0
             : (HSIZE==`AHB_SIZE_256)  ? (HADDR[9:0]<=10'b11_1000_0000)//h380
             : (HSIZE==`AHB_SIZE_512)  ? (HADDR[9:0]<=10'b11_0000_0000)//h300
             : (HSIZE==`AHB_SIZE_1024) ? (HADDR[9:0]<=10'b10_0000_0000)//h200
             : 1'b0 // fail
             )
         : (HBURST==`AHB_BURST_INCR8)  ?
             ( (HSIZE==`AHB_SIZE_8)    ? (HADDR[9:0]<=10'b11_1111_1000)//h3F8
             : (HSIZE==`AHB_SIZE_16)   ? (HADDR[9:0]<=10'b11_1111_0000)//h3F0
             : (HSIZE==`AHB_SIZE_32)   ? (HADDR[9:0]<=10'b11_1110_0000)//h3E0
             : (HSIZE==`AHB_SIZE_64)   ? (HADDR[9:0]<=10'b11_1100_0000)//h3C0
             : (HSIZE==`AHB_SIZE_128)  ? (HADDR[9:0]<=10'b11_1000_0000)//h380
             : (HSIZE==`AHB_SIZE_256)  ? (HADDR[9:0]<=10'b11_0000_0000)//h300
             : (HSIZE==`AHB_SIZE_512)  ? (HADDR[9:0]<=10'b10_0000_0000)//h200
             : (HSIZE==`AHB_SIZE_1024) ? (HADDR[9:0]<=10'b00_0000_0000)//h000
             : 1'b0 // fail
             )
         : (HBURST==`AHB_BURST_INCR16) ?
           (    (HSIZE==`AHB_SIZE_8)     ? (HADDR[9:0]<=10'b11_1111_0000)//h3F0
             : (HSIZE==`AHB_SIZE_16)    ? (HADDR[9:0]<=10'b11_1110_0000)//h3E0
             : (HSIZE==`AHB_SIZE_32)    ? (HADDR[9:0]<=10'b11_1100_0000)//h3C0
             : (HSIZE==`AHB_SIZE_64)    ? (HADDR[9:0]<=10'b11_1000_0000)//h380
             : (HSIZE==`AHB_SIZE_128)   ? (HADDR[9:0]<=10'b11_0000_0000)//h300
             : (HSIZE==`AHB_SIZE_256)   ? (HADDR[9:0]<=10'b10_0000_0000)//h200
             : (HSIZE==`AHB_SIZE_512)   ? (HADDR[9:0]<=10'b00_0000_0000)//h000
             : (HSIZE==`AHB_SIZE_1024)  ? (HADDR[9:0]<=10'b00_0000_0000)//h000
             : 1'b0 // fail
             )
           : 1'b0 // should never be hit!
       )
     );



// INDEX:   - ahb_errm_burst_len

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_burst_left: Must not do more than declared transfers in fixed-length burst. AHB 2.0, Section 3.6, Page 3-11: When a master performs a fixed length burst it must not perform more transfers than is declared by the burst type. SI: AHBLite 1.0, 3.5: Table 3-3 lists the possible burst types [and their Description]."
      )
  ahb_errm_burst_len
    (
     .clk ( HCLK ),
     .reset_n ( HRESETn ),
     .antecedent_expr ( (ahbpc_burst_left==4'b0000) & (HBURST!=`AHB_BURST_INCR) ),
     .consequent_expr ( HTRANS!=`AHB_TRANS_SEQ )
     );



// INDEX:   - ahb_errm_busy
// =====

  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_busy: A BUSY transfer can only follow a NONSEQ, SEQ or BUSY transfer. AHBLite 1.0, Section 3.2, Page 3-5: A BUSY transfer can only follow a NONSEQ, SEQ or BUSY transfer SI: BUSY allows bus masters to insert IDLE cycles in the middle of bursts of transfers"
      )
  ahb_errm_busy
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( HTRANS == `AHB_TRANS_BUSY ),
     .consequent_expr ( HTRANS_D1 != `AHB_TRANS_IDLE )
     );


// INDEX:   - ahb_errm_busy_ctl
// =====
  assert_implication
    #(`OVL_SimError, 
      ERRM_PropertyType,
      "ahb_errm_busy_ctl: In a BUSY->{BUSY,SEQ} transfer, addr/control must be same. AHB 2.0, Section 3.5, Page 3-9: If a SEQ or BUSY transfer follows any BUSY transfer (i.e. waited or unwaited), all the address and control information must be identical. AHBLite 1.0, Section 3.2: BUSY: When a master uses the BUSY transfer type the address adn control signals must reflect the next transfer in the burst. SEQ: The control information is identical to the previous transfer."
      )
  ahb_errm_busy_ctl
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( (HTRANS_D1 == `AHB_TRANS_BUSY) &
 ((HTRANS == `AHB_TRANS_BUSY) | (HTRANS == `AHB_TRANS_SEQ)) ),
     .consequent_expr ( (HADDR_D1 == HADDR)   &
                        (HBURST_D1 == HBURST) &
                        (HWRITE_D1 == HWRITE) &
                        (HSIZE_D1 == HSIZE)   &
                        (HPROT_D1 == HPROT) )
     );


// INDEX:   - ahb_errm_busy_end
// =====

  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_busy_end: A fixed length burst must not have any additional BUSY transfers at the end of the burst. AHBLite 1.0, Section 3.5.1, para 3: The protocol does not permit a master to end a burst with a BUSY transfer for fixed length bursts of type INCR{4,8,16}, WRAP{4,8,16}."
      )
  ahb_errm_busy_end
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( (HBURST != `AHB_BURST_INCR) & (ahbpc_burst_left==4'b0000) ),
     .consequent_expr ( HTRANS != `AHB_TRANS_BUSY )
     );




// INDEX:   - ahb_errm_ctl
// =====

  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_ctl: During an uninterrupted waited transfer, all address and control information must remain constant for stable transfers other than an IDLE transfer."
      )
  ahb_errm_ctl
    ( .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( (~HREADY_D1) &
			 (HTRANS != `AHB_TRANS_IDLE) &
			 (HTRANS_D1 == HTRANS) ), // stable (no BUSY->NSEQ)
      .consequent_expr ( (HADDR_D1  == HADDR) &
			 (HBURST_D1 == HBURST) &
			 (HWRITE_D1 == HWRITE) &
			 (HSIZE_D1  == HSIZE) &
			 (HPROT_D1  == HPROT) )
      );





// INDEX:   - ahb_errm_high_addr
// =====
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_high_addr: For a {SEQ,BUSY} transfer, control/addr must be identical. AHB 2.0, section 3.7, Page 3-17:  All the control information and HADDR[ADDRESS_MAX:10] for a SEQ or BUSY transfer must be identical to the previous transfer. (This ensures that a burst does not cross a 1k byte boundary.)"
      )
  ahb_errm_high_addr
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( HREADY_D1 &
                        ((HTRANS == `AHB_TRANS_BUSY) | (HTRANS == `AHB_TRANS_SEQ)) ),
     .consequent_expr ( ((HADDR_D1[ADDRESS_MAX:10]) == HADDR[ADDRESS_MAX:10]) &
                        (HBURST_D1         == HBURST) &
                        (HWRITE_D1         == HWRITE) &
                        (HSIZE_D1          == HSIZE) &
                        (HPROT_D1          == HPROT) )
     );


// INDEX:   - ahb_errm_incr_addr
// =====
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_incr_addr: AHBLite 1.0, Section 3.6: If a SEQ or BUSY transfer follows a NONSEQ or another SEQ transfer and the burst is incrementing, HADDR[9:0] must be equal to the address of the previous transfer plus the size of the transfer (in bytes). "
      )
  ahb_errm_incr_addr
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( HCLKEN_D1 & // needed for increment
                        HREADY_D1 &
                        ( (HBURST_D1==`AHB_BURST_INCR) | (HBURST_D1==`AHB_BURST_INCR4) |
                          (HBURST_D1==`AHB_BURST_INCR8) | (HBURST_D1==`AHB_BURST_INCR16) ) &
                        ( (HTRANS_D1==`AHB_TRANS_NSEQ) | (HTRANS_D1==`AHB_TRANS_SEQ) ) &
                        ( (HTRANS == `AHB_TRANS_SEQ) | (HTRANS==`AHB_TRANS_BUSY) ) ),
     .consequent_expr (
       // 2^0 is 1
       (HSIZE_D1==`AHB_SIZE_8)    ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000000001)) :
       // 2^1 is 2
       (HSIZE_D1==`AHB_SIZE_16)   ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000000010)) :
       // 2^2 is 4
       (HSIZE_D1==`AHB_SIZE_32)   ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000000100)) :
       // 2^3 is 8
       (HSIZE_D1==`AHB_SIZE_64)   ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000001000)) :
        // 2^4 is 16
       (HSIZE_D1==`AHB_SIZE_128)  ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000010000)) :
        // 2^5 is 32
       (HSIZE_D1==`AHB_SIZE_256)  ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b000100000)) :
        // 2^6 is 64
       (HSIZE_D1==`AHB_SIZE_512)  ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b001000000)) :
        // 2^7 is 128
       (HSIZE_D1==`AHB_SIZE_1024) ? (HADDR[9:0] == (HADDR_D1[9:0] + 10'b010000000)) :
       1'b0 )
     );




// INDEX:   - ahb_errm_lock_burst
// =====

  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_lock_burst: During a burst, HMASTLOCK must be constant. A master should only change the HLOCK signal such that the resultant HMASTLOCK remains constant throughout a burst. AHBLite 1.0, Section 3.3."
      )
  ahb_errm_lock_burst
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( (HTRANS == `AHB_TRANS_SEQ) | (HTRANS == `AHB_TRANS_BUSY) ),
     .consequent_expr (  HMASTLOCK_D1 == HMASTLOCK )
     );

  
// INDEX:   - ahb_recm_lock_idle
// =====
  assert_implication
    #(`OVL_SimWarning,
      RECM_PropertyType,
      "ahb_recm_lock_idle: Put unlocked IDLE at end of locked burst.  Following the completion of a locked sequence of bursts, it is recommended that the master inserts an unlocked IDLE transfer. AHBLite 1.0, Section 3.3: After a locked transfer, it is recommended that the master inserts an IDLE transfer."
      )
  ahb_recm_lock_idle
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( (LOCK_IGNORE == 0) & ahbpc_granted_D1 & ahbpc_granted &
                        HMASTLOCK_D1 & ~HMASTLOCK ),
     .consequent_expr ( HTRANS == `AHB_TRANS_IDLE )
     );

// INDEX:   - ahb_errm_reset
// =====
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_reset: During reset a master must only attempt IDLE transfers. AHBLite 1.0, Section 7.1.2, Para 2: During reset all masters must ensure the address and control signals are at valid levels and that HTRANS[1:0] indicates IDLE."
      )
  ahb_errm_reset
    (.clk         (HCLK),
     .reset_n     (1'b1), // disabled, as reset is in OVL
     .antecedent_expr (HRESETn == 1'b0),
     .consequent_expr (HTRANS  == `AHB_TRANS_IDLE)
     );




// INDEX:   - ahb_errm_seq
// =====
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_seq: A SEQ transfer can only follow a NONSEQ, SEQ or BUSY transfer."
      )
  ahb_errm_seq
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( HTRANS==`AHB_TRANS_SEQ ),
     .consequent_expr ( HTRANS_D1 != `AHB_TRANS_IDLE )
     );


// INDEX:   - ahb_errm_single
// =====
  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_single: A SEQ transfer cannot have a burst type of SINGLE."
      )
  ahb_errm_single
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .antecedent_expr ( HTRANS == `AHB_TRANS_SEQ ),
     .consequent_expr ( HBURST != `AHB_BURST_SINGLE )
     );



// INDEX:   - ahb_errm_too_wide
// =====
  assert_always
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_too_wide: Transfer is wider than data bus ports."
      )
  ahb_errm_too_wide
    (
     .clk ( HCLK ),
     .reset_n (HRESETn),
     .test_expr ( HSIZE <= HSIZE_MAX )
     );



// INDEX:   - ahb_errm_trans1
// =====
// Simplified due to AHB-Lite (no SPLIT/RETRY) so infm_1of2 not used.

  assert_implication
    #(`OVL_SimError,
      ERRM_PropertyType,
      "ahb_errm_trans1: Cancel waited NSEQ/SEQ if S/R/E"
      )
  ahb_errm_trans1
    ( .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( HRESETn &
                         ~HREADY_D1 &
                         ((HTRANS_D1 == `AHB_TRANS_NSEQ) |
                          (HTRANS_D1 == `AHB_TRANS_SEQ)) &
                          (HTRANS_D1 != HTRANS) ),
      .consequent_expr ( (HTRANS == `AHB_TRANS_IDLE) &
                         ( (HRESP_D1[1:0] == `AHB_RESP_SPLIT) |
                           (HRESP_D1[1:0] == `AHB_RESP_RETRY) |
                           (HRESP_D1[1:0] == `AHB_RESP_ERROR) ) )
      );



// INDEX:   - ahb_errm_trans2
// =====
     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_trans2: During wait, may change IDLE to NONSEQ. During a waited transfer the granted bus master may change an IDLE transfer into a NONSEQ transfer."
       )
     ahb_errm_trans2
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( ~HREADY_D1 & (HTRANS_D1 == `AHB_TRANS_IDLE) ),
      .consequent_expr ( (HTRANS == `AHB_TRANS_IDLE) | (HTRANS == `AHB_TRANS_NSEQ) )
      );


// INDEX:   - ahb_errm_trans3
// =====

     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_trans3_1of2: During a waited transfer of a fixed length burst the granted bus master may change a BUSY transfer into a SEQ transfer if the slave response is OKAY. If the slave response is SPLIT or RETRY, a BUSY transfer must be changed to an IDLE. If an ERROR response is received, the master may change a BUSY transfer, in which case it can go either IDLE or SEQ."
       )
     ahb_errm_trans3_1of2
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( ~HREADY_D1 &
                         ((HBURST_D1 !=`AHB_BURST_SINGLE) & (HBURST_D1 != `AHB_BURST_INCR)) &
                         (HTRANS_D1 == `AHB_TRANS_BUSY) ),
      .consequent_expr ( (HTRANS == `AHB_TRANS_BUSY) |
                         (HTRANS == `AHB_TRANS_SEQ) |
 (HTRANS == `AHB_TRANS_IDLE) )
      );



     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_trans3_2of2: During a waited transfer of a fixed length burst the granted bus master may change a BUSY transfer into a SEQ transfer if the slave response is OKAY. If the slave response is SPLIT or RETRY, a BUSY transfer must be changed to an IDLE. If an ERROR response is received, the master may change a BUSY transfer, in which case it can go either IDLE or SEQ."
       )
     ahb_errm_trans3_2of2
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( HRESETn &
                         ~HREADY_D1 &
                         ((HBURST_D1 != `AHB_BURST_SINGLE) & (HBURST_D1 != `AHB_BURST_INCR)) &
                         (HTRANS_D1 == `AHB_TRANS_BUSY) &
                         (HTRANS == `AHB_TRANS_IDLE) ),
      .consequent_expr ( (HRESP_D1[1:0] == `AHB_RESP_SPLIT) |
                         (HRESP_D1[1:0] == `AHB_RESP_RETRY) |
                         (HRESP_D1[1:0] == `AHB_RESP_ERROR)
                        )
      );


// INDEX:   - ahb_errm_wdata
// =====

     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_wdata: During a waited write transfer the master must keep the write data stable."
       )
     ahb_errm_wdata
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( HRESETn &
                         ahbpc_last_hwrite &
                         ~HREADY_D1 ),
      .consequent_expr ( HWDATA_D1 === HWDATA_STRB )
      );

// INDEX:   - ahb_errm_hwuser
// =====

     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_hwuser: During a waited write transfer the master must keep the write data user signals stable."
       )
     ahb_errm_hwuser
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( HRESETn &
                         ahbpc_last_hwrite &
                         ~HREADY_D1 ),
      .consequent_expr ( HWUSER_D1 === HWUSER )
      );

// INDEX:   - ahb_errm_wrap_addr
// =====



     assert_implication
     #(`OVL_SimError,
       ERRM_PropertyType,
       "ahb_errm_wrap_addr: If a SEQ or BUSY transfer follows a NONSEQ or another SEQ transfer and the burst is wrapping, HADDR[9:0] must be equal to the address of the previous transfer plus the size of the transfer (in bytes) unless the wrap boundary is reached. The wrap boundary is equal to the size in bytes multiplied by the number of beats in the burst. In this case the address should be equal to the add ress of the previous transfer plus the size of the transfer (in bytes) minus the size (in bytes) of the burst."
       )
     ahb_errm_wrap_addr
     (
      .clk ( HCLK ),
      .reset_n (HRESETn),
      .antecedent_expr ( HCLKEN_D1 &
                         HREADY_D1 &
                         ((HBURST_D1 == `AHB_BURST_WRAP4) |
                          (HBURST_D1 == `AHB_BURST_WRAP8) |
                          (HBURST_D1 == `AHB_BURST_WRAP16)) &
                         ((HTRANS_D1==`AHB_TRANS_NSEQ) | (HTRANS_D1==`AHB_TRANS_SEQ)) &
                         ((HTRANS==`AHB_TRANS_SEQ) | (HTRANS==`AHB_TRANS_BUSY)) ),
      .consequent_expr
      (
        //============
        //Wrap 4
        //============
        (HBURST_D1==`AHB_BURST_WRAP4)  ?
          //------------
          // 8-bit (+ 1, mod 4)
          //------------
          ((HSIZE_D1==`AHB_SIZE_8)  ?
            ((HADDR[9:2]==(HADDR_D1[9:2])) & (HADDR[1:0]==(HADDR_D1[1:0] + 2'b01)))
          //------------
          // 16-bit (+ 2, mod 8)
          //------------
         : (HSIZE_D1==`AHB_SIZE_16) ?
            ((HADDR[9:3]==(HADDR_D1[9:3])) & (HADDR[2:0]==(HADDR_D1[2:0] + 3'b010)))
          //------------
          // 32-bit (+ 4, mod 16)
          //------------
         : (HSIZE_D1==`AHB_SIZE_32) ?
            ((HADDR[9:4]==(HADDR_D1[9:4])) & (HADDR[3:0]==(HADDR_D1[3:0] + 4'b0100)))
          //------------
          // 64-bit (+ 8, mod 32)
          //------------
         : (HSIZE_D1==`AHB_SIZE_64) ?
            ((HADDR[9:5]==(HADDR_D1[9:5])) & (HADDR[4:0]==(HADDR_D1[4:0] + 5'b0_1000)))
          //------------
          // 128-bit (+ 16, mod 64)
          //------------
         : (HSIZE_D1==`AHB_SIZE_128) ?
            ((HADDR[9:6]==(HADDR_D1[9:6])) & (HADDR[5:0]==(HADDR_D1[5:0] + 6'b01_0000)))
          //------------
          // 256-bit (+ 32, mod 128)
          //------------
         : (HSIZE_D1==`AHB_SIZE_256) ?
            ((HADDR[9:7]==(HADDR_D1[9:7])) & (HADDR[6:0]==(HADDR_D1[6:0] + 7'b010_0000)))
          //------------
          // 512-bit (+ 64, mod 256)
          //------------
         : (HSIZE_D1==`AHB_SIZE_512) ?
            ((HADDR[9:8]==(HADDR_D1[9:8])) & (HADDR[7:0]==(HADDR_D1[7:0] + 8'b0100_0000)))
          //------------
          // 1024-bit (+ 128, mod 512)
          //------------
         : (HSIZE_D1==`AHB_SIZE_1024) ?
            ((HADDR[9]==(HADDR_D1[9])) & (HADDR[8:0]==(HADDR_D1[8:0] + 9'b0_1000_0000)))
         : 1'b0 // fail
 )
        //============
        //Wrap 8
        //============
: (HBURST_D1==`AHB_BURST_WRAP8)  ?
          //------------
          // 8-bit (+ 1, mod 4)
          //------------
  ((HSIZE_D1==`AHB_SIZE_8)  ?
            ((HADDR[9:3]==(HADDR_D1[9:3])) & (HADDR[2:0]==(HADDR_D1[2:0] + 3'b001)))
          //------------
          // 16-bit (+ 2, mod 8)
          //------------
  : (HSIZE_D1==`AHB_SIZE_16) ? ((HADDR[9:4]==(HADDR_D1[9:4])) &
            (HADDR[3:0]==(HADDR_D1[3:0] + 4'b0010)))
          //------------
          // 32-bit (+ 4, mod 16)
          //------------
  : (HSIZE_D1==`AHB_SIZE_32) ? ((HADDR[9:5]==(HADDR_D1[9:5])) &
    (HADDR[4:0]==(HADDR_D1[4:0] + 5'b0_0100)))
          //------------
          // 64-bit (+ 8, mod 32)
          //------------
          : (HSIZE_D1==`AHB_SIZE_64) ? ((HADDR[9:6]==(HADDR_D1[9:6])) &
    (HADDR[5:0]==(HADDR_D1[5:0] + 6'b00_1000)))
          //------------
          // 128-bit (+ 16, mod 64)
          //------------
          : (HSIZE_D1==`AHB_SIZE_128) ? ((HADDR[9:7]==(HADDR_D1[9:7])) &
    (HADDR[6:0]==(HADDR_D1[6:0] + 7'b001_0000)))
          //------------
          // 256-bit (+ 32, mod 128)
          //------------
          : (HSIZE_D1==`AHB_SIZE_256) ? ((HADDR[9:8]==(HADDR_D1[9:8])) &
    (HADDR[7:0]==(HADDR_D1[7:0] + 8'b0010_0000)))
          //------------
          // 512-bit (+ 64, mod 256)
          //------------
          : (HSIZE_D1==`AHB_SIZE_512) ? ((HADDR[9]==(HADDR_D1[9])) &
    (HADDR[8:0]==(HADDR_D1[8:0] + 9'b0_0100_0000)))
          //------------
          // 1024-bit (+ 128, mod 512)
          //------------
          : (HSIZE_D1==`AHB_SIZE_1024) ? ((HADDR[9:0]==(HADDR_D1[9:0] + 10'b00_1000_0000)))
  : 1'b0 // fail
)
        //============
        //Wrap 16
        //============
        : (HBURST_D1==`AHB_BURST_WRAP16) ?
          //------------
          // 8-bit (+ 1, mod 4)
          //------------
          ((HSIZE_D1==`AHB_SIZE_8)  ?
           ((HADDR[9:4]==(HADDR_D1[9:4])) & (HADDR[3:0]==(HADDR_D1[3:0] + 4'b0001)))
          //------------
          // 16-bit (+ 2, mod 8)
          //------------
          : (HSIZE_D1==`AHB_SIZE_16) ?
            ((HADDR[9:5]==(HADDR_D1[9:5])) & (HADDR[4:0]==(HADDR_D1[4:0] + 5'b0_0010)))
          //------------
          // 32-bit (+ 4, mod 16)
          //------------
          : (HSIZE_D1==`AHB_SIZE_32) ?
            ((HADDR[9:6]==(HADDR_D1[9:6])) & (HADDR[5:0]==(HADDR_D1[5:0] + 6'b00_0100)))
          //------------
          // 64-bit (+ 8, mod 32)
          //------------
          : (HSIZE_D1==`AHB_SIZE_64) ?
            ((HADDR[9:7]==(HADDR_D1[9:7])) & (HADDR[6:0]==(HADDR_D1[6:0] + 7'b000_1000)))
          //------------
          // 128-bit (+ 16, mod 64)
          //------------
          : (HSIZE_D1==`AHB_SIZE_128) ?
            ((HADDR[9:8]==(HADDR_D1[9:8])) & (HADDR[7:0]==(HADDR_D1[7:0] + 8'b0001_0000)))
          //------------
          // 256-bit (+ 32, mod 128)
          //------------
          : (HSIZE_D1==`AHB_SIZE_256) ?
            ((HADDR[9]==(HADDR_D1[9])) & (HADDR[8:0]==(HADDR_D1[8:0] + 9'b0_0010_0000)))
          //------------
          // 512-bit (+ 64, mod 256)
          //------------
          : (HSIZE_D1==`AHB_SIZE_512) ?
            ((HADDR[9:0]==(HADDR_D1[9:0] + 10'b00_0100_0000)))
          //------------
          // 1024-bit (+ 128, mod 512)
          //------------
          : (HSIZE_D1==`AHB_SIZE_1024) ?
            ((HADDR[9:0]==(HADDR_D1[9:0] + 10'b00_1000_0000)))
          : 1'b0 // fail
        )
        : 1'b0 // should never be hit!
      )
    );


//------------------------------------------------------------------------------
// INDEX: 
// INDEX: AHB Slave Rules (alpabetical by name):
//------------------------------------------------------------------------------


  // INDEX:   - ahb_errs_busy
  // =====
  assert_next
    #(`OVL_SimError, 1,1,0, 
      ERRS_PropertyType,
      "ahb_errs_busy: A slave must give a zero wait state OKAY response to BUSY transfers."
      )
  ahb_errs_busy
    (.clk         ( HCLK ),
     .reset_n     (HRESETn),
     .start_event ((HTRANS == `AHB_TRANS_BUSY) &
                   HREADY &
                   HSELx
                   ),
     .test_expr   (HREADYOUT &
                   (HRESP == `AHB_RESP_OKAY)
                   )
     );


  // INDEX:   - ahb_errs_idle
  // =====
  assert_next
    #(`OVL_SimError, 1,1,0, 
      ERRS_PropertyType,
      "ahb_errs_idle: A slave must give a zero wait state OKAY response to IDLE transfers."
      )
  ahb_errs_idle
    (.clk         ( HCLK ),
     .reset_n     (HRESETn),
     .start_event ((HTRANS == `AHB_TRANS_IDLE) &
                   HREADY &
                   HSELx
                   ),
     .test_expr   (HREADYOUT &
                   (HRESP == `AHB_RESP_OKAY)
                   )
     );




  // INDEX:   - ahb_recs_ready
  // =====
  assert_implication
    #(`OVL_SimWarning,
      RECS_PropertyType,
      "ahb_recs_ready: When a slave is not selected, it is recommended that it responds with HREADY high.")
  ahb_recs_ready
    (.clk               ( HCLK ),
     .reset_n           (HRESETn),
     .antecedent_expr  (~tb_selected),
     .consequent_expr   (HREADYOUT)
     );


  // INDEX:   - ahb_errs_reset
  // =====
  assert_next
    #(`OVL_SimError, 1,1,0, 
      ERRS_PropertyType,
      "ahb_errs_reset: the slave selected at reset must drive HREADYOUT high (so that HREADY is high)"
      )
  ahb_errs_reset
    (.clk         (HCLK),
     .reset_n     (1'b1), // disabled, as reset is in start_event
     .start_event (~HRESETn & tb_selected),
     .test_expr   (HREADYOUT)
     );


  // INDEX:   - ahb_recs_reset
  // =====
  assert_next
    #(`OVL_SimWarning, 1,1,0, 
      RECS_PropertyType,
      "ahb_recs_reset: recommended that all slaves drive HREADYOUT high during reset"
      )
  ahb_recs_reset
    (.clk         (HCLK),
     .reset_n     (1'b1), // disabled, as reset is in start_event
     .start_event (~HRESETn),
     .test_expr   (HREADYOUT)
     );


  // INDEX:   - ahb_recs_resp
  // =====
  assert_implication
    #(`OVL_SimWarning,
      RECS_PropertyType,
      "ahb_recs_resp: When a slave is not selected it is recommended that it responds with HRESP as OKAY.")
  ahb_recs_resp
    (.clk               ( HCLK ),
     .reset_n           (HRESETn),
     .antecedent_expr  (~tb_selected),
     .consequent_expr   (HRESP == `AHB_RESP_OKAY
 )
     );


  // INDEX:   - ahb_errs_resp1
  // =====
  assert_next
    #(`OVL_SimError, 1,1,0, 
      ERRS_PropertyType,
      "ahb_errs_resp1: If a slave responds with HREADY low and HRESP is not OKAY (ERROR, RETRY, SPLIT) then in the following cycle it must respond with HREADY high and HRESP equal to the previous cycle."
      )
  ahb_errs_resp1
    (.clk         ( HCLK ),
     .reset_n     (HRESETn),

     .start_event ( tb_selected &
                    ~HREADYOUT &
                    (HRESP != `AHB_RESP_OKAY)
                    ),
     .test_expr    (
                    (HRESETn ?
                     ((HRESP == HRESP_D1) & HREADYOUT):
                     1'b1
                     )
                    )
     );


  // INDEX:   - ahb_errs_resp2
  // =====
  assert_implication
    #(`OVL_SimError, 
      ERRS_PropertyType,
      "ahb_errs_resp2: If a slave responds with HREADY high and HRESP is not OKAY (ERROR, RETRY, SPLIT) then in the previous cycle it must respond with HREADY low and HRESP equal to the current cycle. "
      )
  ahb_errs_resp2
    (.clk               ( HCLK ),
     .reset_n           (HRESETn),

     .antecedent_expr  (tb_selected &
                        HREADYOUT &
                        (HRESP != `AHB_RESP_OKAY)
                        ),

     .consequent_expr   ((HRESP_D1 == HRESP) &
                         ~HREADYOUT_D1
                         )
     );


  //------------------------------------------------------------------------------
  // AHB Rules Finish.
  //------------------------------------------------------------------------------


  //------------------------------------------------------------------------------
  // INDEX: 
  // INDEX: Auxilliary logic rules
  //------------------------------------------------------------------------------

  // INDEX:   - ahb_auxm_data_width
  // =====
 assert_proposition
    #(`OVL_SimWarning,
      AUXM_PropertyType,
      "AUXM_DATA_WIDTH: Parameter DATA_WIDTH must be 8, 16, 32, 64, 128, 256, 512 or 1024."
      )
  ahb_auxm_data_width
    (
     .reset_n (HRESETn),
     .test_expr ( (DATA_WIDTH ==    8) ||
                  (DATA_WIDTH ==   16) ||
                  (DATA_WIDTH ==   32) ||
                  (DATA_WIDTH ==   64) ||
                  (DATA_WIDTH ==  128) ||
                  (DATA_WIDTH ==  256) ||
                  (DATA_WIDTH ==  512) ||
                  (DATA_WIDTH == 1024) )
     );

  // INDEX:     - X-check inputs
  // =====

  // Master signals
  assert_never_unknown #(`OVL_SimError, ADDRESS_WIDTH, AUXM_PropertyType, "HADDR went X")
  HADDR_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HADDR));

  assert_never_unknown #(`OVL_SimError, 2, AUXM_PropertyType, "HTRANS went X")
  HTRANS_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HTRANS));

  assert_never_unknown #(`OVL_SimError,  1, AUXM_PropertyType, "HWRITE went X")
  HWRITE_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HWRITE));

  assert_never_unknown #(`OVL_SimError, 3, AUXM_PropertyType, "HSIZE went X")
  HSIZE_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HSIZE));

  assert_never_unknown #(`OVL_SimError, 3, AUXM_PropertyType, "HBURST went X")
  HBURST_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HBURST));

  assert_never_unknown #(`OVL_SimError, 4, AUXM_PropertyType, "HPROT went X")
  HPROT_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HPROT));

  assert_never_unknown #(`OVL_SimError, DATA_WIDTH, AUXM_PropertyType, "HWDATA went X")
  HWDATA_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(ahbpc_last_hwrite & ~int_htrans_busy_dphase),.test_expr(HWDATA_STRB));

  assert_never_unknown #(`OVL_SimError, HWUSER_WIDTH, AUXM_PropertyType, "HWUSER went X")
  HWUSER_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(ahbpc_last_hwrite & ~int_htrans_busy_dphase),.test_expr(HWUSER));

  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType, "HSELx went X")
  HSELx_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HSELx));

// not used:
//  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType,"HRDATA went X")
//  HRDATA_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HRDATA));

  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType, "HREADY went X")
  HREADY_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HREADY));

  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType, "HREADYOUT went X")
  HREADYOUT_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HREADYOUT));

  assert_never_unknown #(`OVL_SimError, 2, AUXM_PropertyType, "HRESP went X")
  HRESP_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HRESP));

  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType, "HLOCKx went X")
  HLOCKx_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HLOCKx));

  assert_never_unknown #(`OVL_SimError, 1, AUXM_PropertyType, "HGRANTx went X")
  HGRANTx_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HGRANTx));

// not used:
//  assert_never_unknown #(`OVL_SimError, [3:0], AUXM_PropertyType, "HMASTER went X")
// HMASTER_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HMASTER));

//  assert_never_unknown #(`OVL_SimError, [3:0], AUXS_PropertyType, "HSPLITx went X")
// HSPLITx_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HSPLITx));

  assert_never_unknown #(`OVL_SimError, 1, AUXS_PropertyType,"HMASTLOCK went X")
  HMASTLOCK_X_check (.clk(HCLK),.reset_n(HRESETn),.qualifier(1'b1),.test_expr(HMASTLOCK));


//User signals assertions
  // INDEX:        - AHB_ERRM_HAUSER_STABLE
  // =====
  assert_win_unchange #(`OVL_SimError, HAUSER_WIDTH, AUXM_PropertyType,
    "AHB_ERRM_HAUSER_STABLE. HAUSER must remain stable when HTRANS[1] is asserted and HREADY low. Spec: section 3.1, and figure 3-1, on page 3-2."
  )  ahb_errm_hauser_stable
     (.clk          (HCLK),
      .reset_n      (HRESETn),
      .start_event  (HTRANS[1] & !HREADY),
      .test_expr    (HAUSER),
      .end_event    (!(HTRANS[1] & !HREADY)) // Inverse of start_event
      );


  // INDEX:        - AHB_ERRM_HAUSER_X
  // =====
  assert_never #(`OVL_SimError, AUXM_PropertyType,
    "AHB_ERRM_HAUSER_X. When HTRANS[1] is high, a value of X on HAUSER is not permitted. Spec: section 3.1.1 on page 3-3."
  )  ahb_errm_hauser_x
     (.clk       (HCLK),
      .reset_n   (HRESETn),
      .test_expr (CheckXorZifValid(HTRANS[1],HAUSER)) // CheckXorZifValid returns 1'b0 or 1'bX
      );

`endif // `ifdef ARM_ASSERT_ON

  // INDEX:        - CheckXorZifValid
  // =====
  // Inputs: VALID + Control signal (to check for X or Z at any time)
  // Returns: 1'b0 or 1'bX (if any X/Z when VALID is 1'b1)
  //
  // Note: Not using a "width" parameter, as verilog does not allow overloading
  //       of functions (different parameters) in the same calling module! Ensure
  //       width is sufficient for all control signals (zero-extending is OK).
  //------------------------------------------------------------------------------
  function CheckXorZifValid;
     input        valid_enable;
     input [31:0] control_signal;
     begin
        if (valid_enable)
           CheckXorZifValid = |(control_signal ^ control_signal); // can only be 1'b0 or 1'bX
         else
           CheckXorZifValid = 1'b0; // don't check if enable is 1'b0 or 1'bX
     end
  endfunction // CheckXorZifValid

//------------------------------------------------------------------------------
// INDEX: 
// INDEX: Clear Verilog Defines
//------------------------------------------------------------------------------

// OVL Severity levels
`undef OVL_SimFatal
`undef OVL_SimError
`undef OVL_SimWarning
`undef OVL_SimCover
`undef OVL_SimInfo

// OVL Proof Options (all others set via parameters)
`undef OVL_SkipFormalProof

`undef AHB_LITE


//------------------------------------------------------------------------------
// INDEX: End of module
//------------------------------------------------------------------------------

endmodule // AhbPC

`include "AhbDefns_undefs.v"

//------------------------------------------------------------------------------
// INDEX: 
// INDEX: End of File
//------------------------------------------------------------------------------

