
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
// File Revision       : 135247
// File Date           :  2009-07-17 13:13:54 +0100 (Fri, 17 Jul 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : RTL of AHB-Lite Master Interface Block
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// AMIB Defines
//------------------------------------------------------------------------------
`include "Axi.v"
`include "Ahb.v"


//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------
module axi_to_ahb_32
(
  // Global signals
  aclk,
  aresetn,

  // A Channel
  awrite,
  aid,
  aaddr,
  alen,
  asize,
  aburst,
  alock,
  acache,
  aprot,
  avalid,
  aready,

  // D Channel
  dbnr,
  did,
  ddata,
  dresp,
  dlast,
  dvalid,
  dready,

  // W Channel
  wdata,
  wstrb,
  wlast,
  wvalid,
  wready,

  // AHB-Lite Interface
  hsel,
  haddr,
  htrans,
  hwrite,
  hsize,
  hburst,
  hprot,
  hwdata,
  hmastlock,
  hreadymux,
  hresp,
  hrdata,
  hready
);


//------------------------------------------------------------------------------
// Port definitions
//------------------------------------------------------------------------------

  // Clock and Reset in ITB domain
  input                 aclk;                 // ITB Bus Clock
  input                 aresetn;              // ITB reset active low

  // A Channel
  input                 awrite;               // R/W address flag
  input          [7:0]  aid;                  // R/W address ID
  input         [31:0]  aaddr;                // R/W address
  input          [3:0]  alen;                 // R/W burst length
  input          [2:0]  asize;                // R/W burst size
  input          [1:0]  aburst;               // R/W burst type
  input          [1:0]  alock;                // R/W lock field
  input          [3:0]  acache;               // R/W cache field
  input          [2:0]  aprot;                // R/W protection field
  input                 avalid;               // R/W address valid
  output                aready;               // R/W address ready

  // D Channel
  output                dbnr;                 // R/B response flag
  output         [7:0]  did;                  // R/B response ID
  output        [31:0]  ddata;                // R data
  output         [1:0]  dresp;                // R/B response
  output                dlast;                // R data last
  output                dvalid;               // R/B response valid
  input                 dready;               // R/B response ready

  // W Channel
  input         [31:0]  wdata;                // Write data
  input          [3:0]  wstrb;                // Write data strobe
  input                 wlast;                // Write last
  input                 wvalid;               // Write valid
  output                wready;               // Write ready
  // AHB-Lite Interface
  input                 hready;               // AHB-Lite transfer ready
  input                 hresp;                // AHB-Lite transfer response
  input         [31:0]  hrdata;               // AHB-Lite read data
  output                hsel;                 // AHB-Lite slave select line
  output        [31:0]  haddr;                // AHB-Lite address bus
  output         [1:0]  htrans;               // AHB-Lite transfer size
  output                hwrite;               // AHB-Lite transfer direction
  output         [2:0]  hsize;                // AHB-Lite transfer size
  output         [2:0]  hburst;               // AHB-Lite burst type
  output         [3:0]  hprot;                // AHB-Lite protection bits
  output        [31:0]  hwdata;               // AHB-Lite write data
  output                hmastlock;            // AHB-Lite lock toggle
  output                hreadymux;            // AHB-Lite dataphase ready


//------------------------------------------------------------------------------
// Signal declarations for i/o ports
//------------------------------------------------------------------------------

  // Clock and Reset in ITB domain
  wire                  aclk;                 // ITB Bus Clock
  wire                  aresetn;              // ITB reset active low

  // A Channel
  wire                  awrite;               // R/W address flag
  wire           [7:0]  aid;                  // R/W address ID
  wire          [31:0]  aaddr;                // R/W address
  wire           [3:0]  alen;                 // R/W burst length
  wire           [2:0]  asize;                // R/W burst size
  wire           [1:0]  aburst;               // R/W burst type
  wire           [1:0]  alock;                // R/W lock field
  wire           [3:0]  acache;               // R/W cache field
  wire           [2:0]  aprot;                // R/W protection field
  wire                  avalid;               // R/W address valid
  wire                  aready;               // R/W address ready

  // A Channel
  wire                  awrite_reg;           // R/W address flag
  wire           [7:0]  aid_reg;              // R/W address ID
  wire          [31:0]  aaddr_reg;            // R/W address
  wire           [3:0]  alen_reg;             // R/W burst length
  wire           [2:0]  asize_reg;            // R/W burst size
  wire           [1:0]  aburst_reg;           // R/W burst type
  wire           [1:0]  alock_reg;            // R/W lock field
  wire           [3:0]  acache_reg;           // R/W cache field
  wire           [2:0]  aprot_reg;            // R/W protection field

  // D Channel
  wire                  dbnr;                 // R/B response flag
  wire           [7:0]  did;                  // R/B response ID
  wire          [31:0]  ddata;                // R data
  wire           [1:0]  dresp;                // R/B response
  wire                  dlast;                // R data last
  wire                  dvalid;               // R/B response valid
  wire                  dready;               // R/B response ready

  // W Channel
  wire          [31:0]  wdata;                // Write data
  wire           [3:0]  wstrb;                // Write data strobe
  wire                  wlast;                // Write last
  wire                  wvalid;               // Write valid
  wire                  wready;               // Write ready

  // APB Register Signals
  wire                  decerr_en;            // Enable DECERR responses for
                                              // unaligned/sparse/strobeless
                                              // transfers

  wire                  force_incr;           // Force all fixed length INCR
                                              // bursts to undef INCR
  // AHB-Lite Interface
  wire                  hready;               // AHB-Lite transfer ready
  wire                  hresp;                // AHB-Lite transfer response
  wire          [31:0]  hrdata;               // AHB-Lite read data
  wire                  hsel;                 // AHB-Lite slave select line
  wire          [31:0]  haddr;                // AHB-Lite address bus
  wire           [1:0]  htrans;               // AHB-Lite transfer size
  wire                  hwrite;               // AHB-Lite transfer direction
  wire           [2:0]  hsize;                // AHB-Lite transfer size
  wire           [2:0]  hburst;               // AHB-Lite burst type
  wire           [3:0]  hprot;                // AHB-Lite protection bits
  wire           [3:0]  hwstrb;               // AHB-Lite Byte Lane Strobes
  wire          [31:0]  hwdata;               // AHB-Lite write data
  wire                  hmastlock;            // AHB-Lite lock toggle
  wire                  hreadymux;            // AHB-Lite dataphase ready


//------------------------------------------------------------------------------
//
//                axi_to_ahb_32
//
//------------------------------------------------------------------------------
//
//   The AHB-Lite AMIB converts the internal 3-channel ITB bus into the AMBA
// AHB-Lite bus.  It supports the following features:
//
// o Leading Write Data
// o One Outstanding Transaction
// o AXI Locks
// o AHB-Lite Master and AHB-Lite Mirrored-Slave Protocols
//
//   The AHB-Lite AMIB can be further configured to support:
// 
// o Conversion of strobeless write data to AHB-Lite IDLE transfers
// o Issue DECERR responses to unaligned transaction and sparse writes
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Wire declarations
//------------------------------------------------------------------------------

  // ITB Signals
  // A-Channel Signals
  wire                  aready_i;             // Internal AREADY
  wire                  avalid_i;             // Internal AVALID
  wire          [58:0]  a_src_data;           // A-Channel Rev. Slice
  wire          [58:0]  a_dst_data;           //  A-Channel Rev. Slice
  // A-Channel MUX Signals
  wire                  awrite_mux;           // MUX-ed AWRITE
  wire           [7:0]  aid_mux;              // MUX-ed AID
  wire           [3:0]  alen_mux;             // MUX-ed ALEN
  wire           [2:0]  asize_mux;            // MUX-ed ASIZE
  wire           [1:0]  aburst_mux;           // MUX-ed ABURST
  wire           [1:0]  alock_mux;            // MUX-ed ALOCK
  // A-Channel Control Signals
  wire                  ach_hndshk;           // A-Channel Handshake
  // A-Channel Buffer (ACB)
  wire          [9:0]  acb_data_in;          // ACB Data Input
  wire                  acb_push;             // ACB Push
  wire                  acb_push_in;          // ACB Push (Internal)
  wire                  acb_pop;              // ACB Pop
  wire                  acb_pop_in;           // ACB Pop (Internal)
  wire          [9:0]  acb_data_out;         // ACB Data Output
  wire                  acb_ready;            // ACB Ready (i.e. Not Full)
  wire                  acb_not_empty;        // ACB Not Empty
  // W-Channel Signals
  // W-Channel Buffer (WCB)
  wire          [35:0]  wcb_data_in;          // WCB Data Input
  wire                  wcb_push;             // WCB Push
  wire                  wcb_push_in;          // WCB Push (Internal)
  wire                  wcb_pop;              // WCB Pop
  wire                  wcb_pop_in;           // WCB Pop (Internal)
  wire          [35:0]  wcb_data_out;         // WCB Data Output
  wire                  wcb_ready;            // WCB Ready (i.e. Not Full)
  wire                  wcb_not_empty;        // WCB Not Empty
  // W-Channel MUX-ed Outputs (For AHB-Lite)
  wire           [3:0]  hwstrb_nxt;           // Next AHB-Lite Byte Lane Strobes
  wire          [31:0]  hwdata_nxt;           // Next AHB-Lite write data
  // D-Channel Signals
  wire                  dbnr_i;               // Internal DBNR

  // Internal Signals
  // Safe-to-Start Signals
  wire                  safe_to_start_ahb;    // Safe-to-start AHB-Lite transfer
                                              // as far as the AHB-Lite bus is
                                              // concerned

  wire                  safe_to_start_itb;    // Safe-to-start AHB-Lite transfer
                                              // as far as the ITB buffers are
                                              // concerned

  // AHB-Lite Address Phase Control
  wire                  nseq_on_ach_hndshk;   // Start NONSEQ on an in-coming
                                              // ITB A-Channel handshake

  wire                  nseq_after_hrdy_reg;  // Start NONSEQ the cycle after
                                              // the last (waited) data-phase
                                              // has been received

  wire                  start_nseq;           // Start AHB-Lite NONSEQ
  wire                  first_aph;            // First AHB-Lite Address Phase

  wire                  first_aph_rx;         // First AHB-Lite Address Phase
                                              // successfully received by the
                                              // AHB-Lite Slave

  wire                  stop_aph;             // Stop AHB-Lite Address Phase
  wire                  aph;                  // AHB-Lite Address Phase
  // Force Undefined-length INCR Signals
  wire                  force_undef_incr;     // Force fixed-length INCR/WRAP
                                              // bursts to undef. INCR

  wire                  force_incr_mux;       // MUX-ed between current value
                                              // of "force_undef_incr" and
                                              // hold register value

  wire                  force_incr_aph;       // "force_incr_mux" aligned to
                                              // AHB-Lite Address Phase

  wire                  force_incr_burst;     // "force_incr_mux" aligned to
                                              // ITB burst information

  wire                  decerr_en_mux;        // MUX-ed between current value
                                              // of "decerr_en" and hold
                                              // register value

  wire                  decerr_en_aph;        // "decerr_en_mux" aligned to
                                              // AHB-Lite Address Phase

  // Unaligned Address Signals
  wire                  unaligned_itb;        // Unaligned ITB transfer to the
                                              // AHB-Lite Slave has been
                                              // received (Strobe)

  wire                  unaligned_ahb;        // "Unaligned" AHB transfer (now
                                              // aligned) is in progress

  wire                  unaligned_decerr_en;  // Unaligned DECERR Enable
  // Address Increment Signals
  wire                  increment_haddr;      // Increment HADDR
  wire          [31:0]  incr_haddr;           // Incremented Address
  // Address Wrapping Signals
  wire           [5:0]  wrap_mask_n;          // Bit-wise inverted wrap_mask
  wire           [5:0]  masked_prev_addr;     // Masked address of prev. HADDR

  wire                  addr_wrapped;         // HADDR has wrapped
                                              // function call

  wire                  wrap_force_nseq;      // WRAP burst which has been
                                              // converted to an undef. INCR
                                              // should force HTRANS to NONSEQ
                                              // at the WRAP boundary
  // 1KB Boundary Crossing Signals
  wire                  crosses_1k_mux;       // MUX-ed "crosses_1k"
  // AHB-Lite Beat Loading
  wire                  early_ach_hndshk;     // Early A-Channel Handshake
  wire                  stall_bc_load;        // Stall any Beat Counter load

  wire                  load_on_ach_hndshk;   // Load Beat Counter on an
                                              // A-Channel Handshake

  wire                  load_on_last_beat_rx; // Load Beat Counter when last
                                              // (waited) data-phase has been
                                              // received

  wire                  load_on_rb_recovery;  // Load Beat Counter when
                                              // D-Channel Buffer has recovered
                                              // from a stall

  wire                  load_bc_recover;      // Load Beat Counter after
                                              // recovering from a stall
  // AHB-Lite Beat Counting
  wire                  load_ahb_beat_cnt;    // Load AHB-Lite Beat Counter

  wire                  ahb_beat_rx;          // AHB-Lite (R/W) data beat has
                                              // been sent/received by/from
                                              // the AHB-Lite Slave

  wire                  ahb_beats_left;       // AHB-Lite beats remaining
  // AHB-Lite Write Beat Counting (AHB WBC)
  wire                  safe_to_start_ahb_wr; // Safe to start another write

  wire                  ahb_wr_beats_left;    // AHB-Lite write data beats
                                              // waiting to be received by
                                              // AHB-Lite Slave

  wire                  zero_ahb_wr_beats;    // No more write data beats
  wire                  last_ahb_wr_beat;     // Last AHB-Lite write data beat
                                              // is currently on HWDATA bus

  wire                  last_ahb_wr_beat_rx;  // Last AHB-Lite write data beat
                                              // has been received by Slave

  wire                  ahb_wr_beat_rx;       // AHB-Lite write data beat
                                              // received by AHB-Lite Slave

  wire                  load_ahb_wbc;         // Load AHB-Lite WBC

  wire                  dec_ahb_wbc;          // Decrement AHB-Lite WBC
  // AHB-Lite Read Beat Counting (AHB RBC)
  wire                  safe_to_start_ahb_rd; // Safe to start another read

  wire                  ahb_rd_beats_left;    // AHB-Lite read data beats
                                              // expected to be received by
                                              // AHB-Lite Slave

  wire                  zero_ahb_rd_beats;    // No more read data beats

  wire                  last_ahb_rd_beat;     // Last AHB-Lite read data beat
                                              // is expected on HRDATA bus

  wire                  last_ahb_rd_beat_rx;  // Last AHB-Lite read data beat
                                              // has been sent by Slave

  wire                  ahb_rd_beat_rx;       // AHB-Lite read data beat
                                              // sent by AHB-Lite Slave

  wire                  load_ahb_rbc;         // Load AHB-Lite RBC

  wire                  dec_ahb_rbc;          // Decrement AHB-Lite RBC
  // Response Signals
  wire           [1:0]  beat_resp_mux;        // Beat Reponse MUX
  // AHB-Lite Write Response Signals
  wire                  wr_resp_valid;        // ITB (Last) Write Response Valid
  wire           [1:0]  wr_beat_resp;         // Write Beat Reponse
  wire           [1:0]  wr_resp_hold;         // Write Beat Response HOLD
  wire           [1:0]  last_wr_resp;         // Last Write Beat Response
  wire                  wr_beat_err_resp;     // Write Beat ERROR Reponse

  wire                  wr_beat_sparse;       // Sparse Write Beat on HWDATA
                                              // (when DECERR Enable is HIGH)

  wire                  wr_beat_strbless;     // Strobeless Write Beat on HWDATA
                                              // (when DECERR Enable is HIGH and
                                              //  HTRANS not being forced IDLE)
  // AHB-Lite Read Response Signals
  wire                  rd_resp_valid;        // ITB Read Response Valid
  wire                  last_rd_resp_valid;   // ITB Last Read Response Valid
  // ITB Write/Read Response Signals
  wire           [1:0]  itb_resp;             // ITB Beat Reponse
  // D-Channel Buffer (DCB)
  wire          [36:0]  dcb_data_in;          // DCB Data Input
  wire                  dcb_push;             // DCB Push
  wire                  dcb_push_in;          // DCB Push (Internal)
  wire                  dcb_pop;              // DCB Pop
  wire                  dcb_pop_in;           // DCB Pop (Internal)
  wire          [36:0]  dcb_data_out;         // DCB Data Output
  wire                  dcb_ready;            // DCB Ready (i.e. Not Full)
  wire                  dcb_not_empty;        // DCB Not Empty
  wire                  dcb_may_stall;        // DCB May Stall
  // ITB Beat Counting
  // Control Signals
  wire                  itb_rd_beat_rx;       // ITB D-Channel read beat has
                                              // been received

  wire                  last_itb_wr_beat_rx;  // Last ITB D-Channel write beat
                                              // has been received

  wire                  last_itb_beat_rx;     // Last ITB D-Channel "data" beat
                                              // has been received

  // AHB-Lite HSTRB Check Signals
  wire           [3:0]  strb_chk;             // Byte Lane Strobe Check
  wire                  strb_chk_pass;        // Byte Lane Strobe Check Pass
  // AHB-Lite Strobeless Beat Signals
  wire                  hwstrbless_nxt;       // Next Write Data beat
                                              // is strobeless

  wire                  strbless_on_aph;      // Strobeless ITB Write Data beat
                                              // has been received during the
                                              // current AHB-Lite Address Phase

  wire                  strbless_on_dph;      // Strobeless AHB-Lite Write Data
                                              // beat has been presented on the
                                              // current AHB-Lite Data Phase

  wire                  strbless_force_nseq;  // Strobeless write data beat
                                              // will force HTRANS to NONSEQ

  wire                  idle_recover_nseq;    // Force HTRANS NONSEQ to recover
                                              // from an unexpected IDLE

  wire                  hwstrbless;           // AHB-Lite Strobeless Write Beat
  // Force HTRANS to NONSEQ Signals
  wire                  aburst_fixed;         // ITB Fixed Burst
  wire                  aburst_wrap2;         // ITB Wrap Burst, Length 2

  wire                  haddr_at_1kb_bndry;   // AHB-Lite HADDR has just
                                              // crossed a 1KB boundary

  wire                  haddr_at_wrp_bndry;   // AHB-Lite HADDR has just
                                              // crossed a WRAP boundary

  wire                  force_nseq;           // Force HTRANS to NONSEQ
  // Internal HTRANS Signals
  wire                  nonseq_not_idle;      // NONSEQ or IDLE control
  wire                  busy_not_idle;        // BUSY or IDLE control
  wire                  wr_seq_not_busy;      // SEQ or BUSY control for writes
  wire                  rd_seq_not_busy;      // SEQ or BUSY control for reads
  wire                  htrans_bit0_int;      // Internal HTRANS[0] (Strobe)
  wire                  htrans_bit1_int;      // Internal HTRANS[1] (Strobe)
  wire           [1:0]  htrans_aph;           // Address Phase Aligned HTRANS
  wire                  htrans_bit0_masked;   // Masked HTRANS[0] (Strobe)
  wire                  htrans_bit1_masked;   // Masked HTRANS[1] (Strobe)
  wire           [1:0]  htrans_masked;        // Masked HTRANS (Strobe)


  // HMASTLOCK Generation Signals
  wire                  itb_start_lock;       // First locked ITB transfer

  wire                  itb_stop_lock;        // First unlocked ITB transfer
                                              // after a locked sequence

  wire                  itb_lock;             // Locked ITB Sequence

  wire                  last_locked_aph;      // Final AHB-Lite address phase
                                              // of a locked sequence

  wire                  stopping_lock;        // AHB-Lite locked sequence should
                                              // be stopped when current
                                              // transfer finishes last address
                                              // phase

  // AHB-Lite Signals
  // AHB-Lite Forward Path Signals
  wire                  hsel_o;               // AHB-Lite slave select line
  wire                  hwrite_i;             // Internal HWRITE
  wire           [2:0]  hsize_i;              // Internal HSIZE
  wire           [3:0]  hprot_i;              // Internal HPROT
  wire                  hmastlock_i;          // Internal HMASTLOCK
  wire                  hreadymux_i;          // AHB-Lite dataphase ready

//------------------------------------------------------------------------------
// Register declarations
//------------------------------------------------------------------------------

  // ITB Signals
  // A-Channel Signals
  // A-Channel Hold Register Signals
  reg                   awrite_h;             // Holding register for AWRITE
  reg            [7:0]  aid_h;                // Holding register for aid
  reg            [3:0]  alen_h;               // Holding register for ALEN
  reg            [2:0]  asize_h;              // Holding register for ASIZE
  reg            [1:0]  aburst_h;             // Holding register for ABURST
  reg            [3:0]  acache_h;             // Holding register for ACACHE
  reg            [2:0]  aprot_h;              // Holding register for APROT
  reg            [1:0]  alock_h;              // Holding register for ALOCK

  // Internal Signals
  // AHB-Lite Address Phase Control
  reg                   start_nseq_reg;       // Registered "start_nseq"
  reg                   first_aph_reg;        // Registered "first_aph"
  reg                   aph_reg;              // Registered "aph"
  // APB Register Signals
  reg                   force_incr_mux_h;     // Hold register "force_incr_mux"
  reg                   decerr_en_mux_h;      // Hold register "decerr_en_mux"
  reg                   force_incr_mux_reg;   // Register "force_incr_mux"
  reg                   decerr_en_mux_reg;    // Register "decerr_en_mux"

  reg                   force_incr_dph;       // "force_incr_mux" aligned to
                                              // AHB-Lite Data Phase

  reg                   decerr_en_dph;        // "decerr_en_mux" aligned to
                                              // AHB-Lite Data Phase

  // Unaligned Address Signals
  reg                   unaligned_addr;       // Unaligned Address
  reg           [31:0]  aligned_addr;         // Aligned Address
  // Address Wrapping Signals
  reg            [5:0]  wrap_mask;            // WRAP Mask for HADDR to
                                              // determine on which Address
                                              // Phase the burst will wrap
  reg            [5:0]  wrap_mask_reg;        // Registered "wrap_mask"
  // 1KB Boundary Crossing Signals
  reg                   crosses_1k;           // Burst will cross 1K boundary
  reg                   crosses_1k_h;         // Hold register for "crosses_1k"
  // AHB-Lite Beat Loading
  reg                   early_ach_hndshk_reg; // Registered "early_ach_hndshk"
  reg                   stall_bc_load_reg;    // Registered "stall_bc_load"
  reg                   load_bc_recover_reg;  // Registered "load_bc_recover"
  reg                   load_last_beat_reg;   // Reg'd "load_on_last_beat_rx"
  // AHB-Lite Beat Counting
  // AHB-Lite Write Beat Counting (AHB WBC)
  reg            [4:0]  ahb_wbc;              // AHB-Lite Write Beat Counter
  reg            [4:0]  ahb_wbc_nxt;          // Next value for AHB-Lite WBC
  // AHB-Lite Read Beat Counting (AHB RBC)
  reg            [4:0]  ahb_rbc;              // AHB-Lite Read Beat Counter
  reg            [4:0]  ahb_rbc_nxt;          // Next value for AHB-Lite RBC
  // Response Signals
  reg                   reset_wr_resp_hold;   // Reset Write Response Hold
  reg            [1:0]  wr_resp_hold_reg;     // Registered "wr_resp_hold"
  // Internal HTRANS Signals
  reg                   htrans_bit0_aph;      // Internal HTRANS[0] Address
                                              // Phase Aligned

  reg                   htrans_bit0_aph_reg;  // Registered "htans_bit0_aph"

  reg                   htrans_bit1_aph;      // Internal HTRANS[1] Address
                                              // Phase Aligned

  reg                   htrans_bit1_aph_reg;  // Registered "htans_bit1_aph"
  reg            [1:0]  htrans_reg;           // Registered "htrans"
  // External HTRANS (Post-Masking) Signals
  reg            [1:0]  htrans_o;             // External "htrans_bit0"
  reg                   htrans_bit1_reg_hrdy; // Registered "htrans_bit1" on HREADY
  // HMASTLOCK Generation Signals
  reg                   itb_lock_reg;         // Registered "itb_lock"
  reg                   stopping_lock_reg;    // Registered "stopping_lock"
  reg                   hmastlock_o_reg;      // Registered "hmastlock"

  // AHB-Lite Signals
  // AHB-Lite Forward Path
  reg                   hsel_o_reg;           // Registered HSEL
  reg           [31:0]  haddr_i;              // Internal HADDR
  reg           [10:0]  haddr_o_reg_htrans;   // Registered HADDR on HTRANS
  reg            [1:0]  haddr_o_reg_hrdy;       // Registered HADDR[1:0] on HREADY
  reg                   hwrite_o_reg;         // Registered HWRITE
  reg                   hwrite_o_reg_hrdy;    // Registered HWRITE on HREADY
  reg            [2:0]  hburst_i;             // Internal HBURST
  reg            [2:0]  hsize_o_reg_hrdy;     // Registered HSIZE on HREADY
  reg           [31:0]  hwdata_i;             // Internal HWDATA
  reg            [3:0]  hwstrb_i;             // Internal HWSTRB
  reg                   hready_reg;           // Registered HREADY

  // AHB-Lite Forward Path Registers
  reg           [31:0]  haddr_o;              // AHB-Lite address
  reg                   hwrite_o;             // AHB-Lite transfer direction
  reg            [2:0]  hsize_o;              // AHB-Lite transfer size
  reg            [2:0]  hburst_o;             // AHB-Lite burst type
  reg            [3:0]  hprot_o;              // AHB-Lite protection bits
  reg                   hmastlock_o;          // AHB-Lite lock toggle

//------------------------------------------------------------------------------
//
// Main body of code
// =================
//
//------------------------------------------------------------------------------

  // Top-level Tie-offs when no APB registers
  assign decerr_en  = 1'b0;  // Disable DECERR Responses
  assign force_incr = 1'b0;  // Don't force fixed length INCR to undef INCR

  //---------
  //  I T B  
  //---------

  //---------------------------------------------------------------------------
  //  I T B   A - C H A N N E L   R E V   R E G I S T E R   S L I C E
  //---------------------------------------------------------------------------

  // Concatenate inputs to reverse register slice 
  assign a_src_data = {awrite,
                       aid,
                       aaddr,
                       alen,
                       asize,
                       aburst,
                       alock,
                       acache,
                       aprot};
                     
  // Expand concatenation of outputs from reverse register slice
  assign {awrite_reg,
          aid_reg,
          aaddr_reg,
          alen_reg,
          asize_reg,
          aburst_reg,
          alock_reg,
          acache_reg,
          aprot_reg} = a_dst_data;
          
  //  Reverse Register Slice on A-Channel Payload
  defparam u_ach_reg_slice.PAYLD_WIDTH = 59;
  rev_regd_slice u_ach_reg_slice
  (
    // global interconnect inputs 
    .aresetn         (aresetn),
    .aclk            (aclk),

    // inputs
    .valid_src       (avalid),
    .ready_dst       (aready_i),
    .payload_src     (a_src_data),

    // outputs
    .valid_dst       (avalid_i),
    .ready_src       (aready),
    .payload_dst     (a_dst_data)
  ); // u_ach_reg_slice

  //---------------------------------------------------------------------------
  //  I T B   A - C H A N N E L
  //---------------------------------------------------------------------------

  // Signal that it is safe to start a new AHB-Lite transfer as far as the
  // AHB-Lite bus is concerned
  assign safe_to_start_ahb = safe_to_start_ahb_rd & safe_to_start_ahb_wr;

  // Signal that it is safe to start a new AHB-Lite transfer as far as all the
  // ITB buffers are concerned
  // 
  // o ~stall_bc_load_reg
  //   - Signals that the beat counter have not stalled
  // o dcb_ready
  //   - Signals the D-Channel Buffer is not full.
  // o acb_ready
  //   - Signals the A-Channel buffer is not full.
  // o awrite_reg & wcb_not_empty
  //   - Signals the read data buffer is not empty.
  // o ~awrite_reg & rdb_ready
  //   - Signals the read data buffer is not full.
  // 
  assign safe_to_start_itb = ~stall_bc_load_reg &
                             dcb_ready &
                             acb_ready &
                            (( awrite_reg & (wvalid | wcb_not_empty)) |
                              ~awrite_reg);

  // Drive AREADY HIGH as long as it is safe to start a new AHB-Lite transfer
  assign aready_i = safe_to_start_ahb & safe_to_start_itb;

  // Signals a handshake on the ITB A-Channel
  // (Note: A-Channel handshake is used to start all AHB-Lite activity.)
  assign ach_hndshk = avalid_i & aready_i;

  //---------------------------------------------------------------------------
  //  A H B - L I T E   B E A T   L O A D I N G
  //---------------------------------------------------------------------------

  // Signals an early A-Channel handshake
  // i.e. One where the beat counter is not yet ready to be loaded with the
  //      new burst length information
  assign early_ach_hndshk = ach_hndshk & (~hready | dcb_may_stall);

  // Register "early_ach_hndshk"
  always @ (posedge aclk or negedge aresetn)
  begin : p_early_ach_hndshk_reg_seq
    if (!aresetn) begin
      early_ach_hndshk_reg <= 1'b0;
    end else begin
      early_ach_hndshk_reg <= early_ach_hndshk;
    end
  end // p_early_ach_hndshk_reg_seq

  // Signals that any attempt to load the beat counters should be stalled
  assign stall_bc_load = early_ach_hndshk_reg ? 1'b1 :
                         (load_bc_recover_reg ? 1'b0 : stall_bc_load_reg);

  // Register "stall_bc_load"
  always @ (posedge aclk or negedge aresetn)
  begin : p_stall_bc_load_reg_seq
    if (!aresetn) begin
      stall_bc_load_reg <= 1'b0;
    end else begin
      stall_bc_load_reg <= stall_bc_load;
    end
  end // p_stall_bc_load_reg_seq

  // Signals that it is safe to load a beat counter on an A-Channel handshake
  assign load_on_ach_hndshk = ach_hndshk & ~stall_bc_load &
                              hready & ~dcb_may_stall;

  // Signals that a beat counter should be loaded when the last AHB-Lite
  // data-phase has completed
  assign load_on_last_beat_rx = stall_bc_load &
                                (last_ahb_wr_beat_rx |
                                 last_ahb_rd_beat_rx) & 
                                ~dcb_may_stall;

  // Signals that a beat counter should be loaded after the D-Channel Buffer
  // has recovered from a stall
  assign load_on_rb_recovery = stall_bc_load &
                               ~dcb_may_stall & ~ahb_beats_left;

  // Signals that a beat counter should be loaded after recovering from a stall
  assign load_bc_recover = load_on_last_beat_rx | load_on_rb_recovery;

  // Register "load_bc_recover"
  always @ (posedge aclk or negedge aresetn)
  begin : p_load_bc_recover_reg
    if (!aresetn) begin
      load_bc_recover_reg <= 1'b0;
    end else begin
      load_bc_recover_reg <= load_bc_recover;
    end
  end // p_load_bc_recover_reg

  //---------------------------------------------------------------------------
  //  A H B - L I T E   B E A T   C O U N T I N G
  //---------------------------------------------------------------------------

  // Signals that it is safe to start another AHB-Lite write (when wbc = 0/1)
  // i.e. When the bus is idle (zero beats left AND not first Addr-Phase) or 
  //      when the AHB-Lite Slave is in the process of receiving the last write
  //       beat in the burst
  // 
  assign safe_to_start_ahb_wr = (zero_ahb_wr_beats & ~first_aph_reg) |
                                (last_ahb_wr_beat & htrans_bit1_aph_reg);

  // Signals that there are still write data beats waiting to be received by the
  // AHB-Lite Slave
  assign ahb_wr_beats_left = (ahb_wbc != 5'b00000);

  // Signals that there are no more write data beats waiting to be received by
  // the AHB-Lite Slave
  assign zero_ahb_wr_beats = (ahb_wbc == 5'b00000);

  // Signals that the write data beat currently on the HWDATA bus is the last
  // write data beat waiting to be received by the AHB-Lite Slave
  assign last_ahb_wr_beat = (ahb_wbc == 5'b00001);

  // Signals that the last write data beat has been successfully received by
  // the AHB-Lite Slave
  assign last_ahb_wr_beat_rx = last_ahb_wr_beat & ahb_wr_beat_rx;

  // Signals that a write data beat has been successfully received by the
  // AHB-Lite Slave
  assign ahb_wr_beat_rx = hwrite_o_reg_hrdy & ahb_beat_rx;

  // AHB-Lite WRITE Beat Counter (AHB WBC)
  // 
  // LOAD:
  // o If Beats Buffer (BB) is in use, load on a BB "pop"
  //   - Note: BB will be in use when waiting on D-Channel handshake
  // o If BB is not in use, load directly on AREADY
  // 
  // DECREMENT:
  // o When each write data beat has been received by the AHB-Lite Slave, AND
  //   the next write data beat is ready and will be driven to HWDATA on the
  //   following cycle
  // 
  always @ (load_ahb_wbc or ahb_wbc or alen_mux or dec_ahb_wbc)
  begin : p_ahb_wbc_comb
    ahb_wbc_nxt = ahb_wbc;
    if (load_ahb_wbc) begin
      ahb_wbc_nxt = {1'b0, alen_mux} + 5'b00001;
    end else if (dec_ahb_wbc) begin
      ahb_wbc_nxt = ahb_wbc - 5'b00001;
    end
  end // p_ahb_wbc_comb

  // Load AHB-Lite Beat Counter (read/write)
  assign load_ahb_beat_cnt = load_on_ach_hndshk   |
                             load_on_last_beat_rx | load_on_rb_recovery;

  // Signals that the AHB-Lite write beat counter should be loaded with the
  // number of write beats for the next transfer
  assign load_ahb_wbc = awrite_mux & load_ahb_beat_cnt;

  // Signals that the AHB-Lite write beat counter should be decremented
  assign dec_ahb_wbc = ahb_wr_beat_rx;

  // Register ahb_wbc
  always @ (posedge aclk or negedge aresetn)
  begin : p_ahb_wbc_seq
    if (!aresetn) begin
      ahb_wbc <= {5{1'b0}};
    end else if (load_ahb_wbc || dec_ahb_wbc) begin
      ahb_wbc <= ahb_wbc_nxt;
    end
  end // p_ahb_wbc_seq

  //---------------------------------------------------------------------------

  // Signals that it is safe to start another AHB-Lite read (when RBC = 0/1)
  // i.e. When the bus is idle (zero beats left) or
  //      when the AHB-Lite Slave is in the process of sending the last read
  //       beat in the burst
  //
  assign safe_to_start_ahb_rd = (zero_ahb_rd_beats & ~first_aph_reg) |
                                (last_ahb_rd_beat & htrans_bit1_aph_reg);

  // Signals that there are still read data beats expected to be sent by the
  // AHB-Lite Slave
  assign ahb_rd_beats_left = (ahb_rbc != 5'b00000);

  // Signals that there are no more read data beats expected to be sent by the
  // AHB-Lite Slave
  assign zero_ahb_rd_beats = (ahb_rbc == 5'b00000);

  // Signals that the next read data beat driven on the HRDATA bus will be the
  // last read data beat to be sent by the AHB-Lite Slave
  assign last_ahb_rd_beat = (ahb_rbc == 5'b00001);

  // Signals that the read data beat currently on the HRDATA bus is the last
  // read data beat to be sent by the AHB-Lite Slave
  assign last_ahb_rd_beat_rx = last_ahb_rd_beat & ahb_rd_beat_rx;

  // Signals that a read data beat has been successfully sent by the AHB-Lite
  // Slave
  assign ahb_rd_beat_rx = ~hwrite_o_reg_hrdy & ahb_beat_rx;

  // AHB-Lite READ Beat Counter (AHB RBC)
  // 
  // LOAD:
  // o If Beats Buffer is in use, load on a BB "pop"
  //   - Note: BB will be in use waiting on D-Channel handshake
  // o If BB is not in use, load directly on AREADY
  // 
  // DECREMENT:
  // o When each read data beat has been sent by the AHB-Lite Slave
  // 
  always @ (load_ahb_rbc or ahb_rbc or alen_mux or dec_ahb_rbc)
  begin : p_ahb_rbc_comb
    ahb_rbc_nxt = ahb_rbc;
    if (load_ahb_rbc) begin
      ahb_rbc_nxt = {1'b0, alen_mux} + 5'b00001;
    end else if (dec_ahb_rbc) begin
      ahb_rbc_nxt = ahb_rbc - 5'b00001;
    end
  end // p_ahb_rbc_comb

  // Signals that the AHB-Lite read beat counter should be loaded with the
  // number of read beats for the next transfer
  assign load_ahb_rbc = ~awrite_mux & load_ahb_beat_cnt;

  // Signals that the AHB-Lite read beat counter should be decremented
  assign dec_ahb_rbc = ahb_rd_beat_rx;

  // Register AHB-Lite Read Beat Counter
  always @ (posedge aclk or negedge aresetn)
  begin : p_ahb_rbc_seq
    if (!aresetn) begin
      ahb_rbc <= {5{1'b0}};
    end else if (load_ahb_rbc || dec_ahb_rbc) begin
      ahb_rbc <= ahb_rbc_nxt;
    end
  end // p_ahb_rbc_seq

  // Signals that a data beat (read/write) has been successfully sent/received
  // by/from the AHB-Lite Slave
  assign ahb_beat_rx = htrans_bit1_reg_hrdy & hready;

  // Signals that there are AHB-Lite beats remaining
  assign ahb_beats_left = ahb_wr_beats_left | ahb_rd_beats_left;

  //---------------------------------------------------------------------------
  //  I T B   B E A T   C O U N T I N G
  //---------------------------------------------------------------------------

  // Signals that the write "data" beat driven on the D-Channel is the last
  // write "data" beat to be sent from the AHB-Lite AMIB
  assign last_itb_wr_beat_rx = wr_resp_valid & dready;

  // Signals the last ITB D-Channel "data" beat has been received
  assign last_itb_beat_rx = (wr_resp_valid | last_rd_resp_valid) &
                             dready;

  // Signals that an ITB D-Channel read data beat has been successfully
  // sent from the AHB-Lite AMIB and received
  assign itb_rd_beat_rx = rd_resp_valid & dready;

  //---------------------------------------------------------------------------
  //  I T B   A - C H A N N E L   B U F F E R
  //---------------------------------------------------------------------------

  // A-Channel Buffer Inputs
  assign acb_data_in = {aid_reg, awrite_reg, unaligned_itb};
  assign acb_push_in = ach_hndshk;
  assign acb_pop_in  = last_itb_beat_rx;

  //---------------------------------------------------------------------------
  // acb_ready     =  HIGH, if either OR both registers are empty.
  // acb_not_empty =  HIGH, if either OR both registers are full.

  defparam u_ahb_amib_acb.PAYLD_WIDTH = 10;
  ful_regd_slice u_ahb_amib_acb
  (
    // Global Inputs
    .aresetn        (aresetn),
    .aclk           (aclk),
    // Inputs
    .valid_src      (acb_push),
    .ready_dst      (acb_pop),
    .payload_src    (acb_data_in),
    // Outputs
    .ready_src      (acb_ready),
    .valid_dst      (acb_not_empty),
    .payload_dst    (acb_data_out)
  ); // u_ahb_amib_acb

  // PUSH Control Logic
  assign acb_push = acb_ready & acb_push_in;

  // POP Control Logic
  assign acb_pop = acb_not_empty & acb_pop_in;

  //---------------------------------------------------------------------------
  

  //---------------------------------------------------------------------------
  //  I T B   H O L D - R E G I S T E R S
  //---------------------------------------------------------------------------

  // ITB control signals are registered only after successful completion of the
  // ITB A-Channel handshake.
  always @ (posedge aclk or negedge aresetn)
  begin : p_reg_itb_ctrl_seq
    if (!aresetn) begin
      awrite_h <= 1'b0;
      aid_h    <= {8{1'b0}};
      alen_h   <= {4{1'b0}};
      asize_h  <= {3{1'b0}};
      aburst_h <= {2{1'b0}};
      acache_h <= {4{1'b0}};
      aprot_h  <= {3{1'b0}};
      alock_h  <= {2{1'b0}};
    end else if (ach_hndshk) begin
      awrite_h <= awrite_reg;
      aid_h    <= aid_reg;
      alen_h   <= alen_reg;
      asize_h  <= asize_reg;
      aburst_h <= aburst_reg;
      acache_h <= acache_reg;
      aprot_h  <= aprot_reg;
      alock_h  <= alock_reg;
    end
  end // p_reg_itb_ctrl_seq

  // ITB Control Signal MUX
  assign awrite_mux = ach_hndshk ? awrite_reg : awrite_h;
  assign aid_mux    = ach_hndshk ? aid_reg    : aid_h;
  assign alen_mux   = ach_hndshk ? alen_reg   : alen_h;
  assign asize_mux  = ach_hndshk ? asize_reg  : asize_h;
  assign aburst_mux = ach_hndshk ? aburst_reg : aburst_h;
  assign alock_mux  = ach_hndshk ? alock_reg  : alock_h;

  //---------------------------------------------------------------------------
  //  I T B   W - C H A N N E L
  //---------------------------------------------------------------------------

  // W-Channel Buffer Inputs
  assign wcb_data_in = {wstrb, wdata};
  assign wcb_push_in = wvalid &
                       (~(aph & hwrite_o & htrans_aph[1] & hready) | wcb_not_empty);
  assign wcb_pop_in  = aph & hwrite_o & hready;

  //---------------------------------------------------------------------------
  // wcb_ready     =  HIGH, if either OR both registers are empty.
  // wcb_not_empty =  HIGH, if either OR both registers are full.
 
  defparam u_ahb_amib_wcb.PAYLD_WIDTH = 36;
  ful_regd_slice u_ahb_amib_wcb
  (
    // Global Inputs
    .aresetn        (aresetn),
    .aclk           (aclk),
    // Inputs
    .valid_src      (wcb_push),
    .ready_dst      (wcb_pop),
    .payload_src    (wcb_data_in),
    // Outputs
    .ready_src      (wcb_ready),
    .valid_dst      (wcb_not_empty),
    .payload_dst    (wcb_data_out)
  ); // u_ahb_amib_wcb

  // PUSH Control Logic
  assign wcb_push = wcb_ready & wcb_push_in;

  // POP Control Logic
  assign wcb_pop = wcb_not_empty & wcb_pop_in;

  //---------------------------------------------------------------------------

  // Signal assignment
  assign wready = wcb_ready;

  // MUX W-Channel Buffer Outputs (for AHB-Lite) with W-Channel Buffer Inputs
  assign hwstrb_nxt = wcb_not_empty ? wcb_data_out[35:32] : 
                            (wvalid ? wstrb : {4{1'b1}});
  assign hwdata_nxt = wcb_not_empty ? wcb_data_out[31:0] : wdata;

  // Register the MUX-ed W-Channel Buffer Outputs (for AHB-Lite) on HREADY
  // (Note: Changes them from being Address Phase Aligned to Data Phase Aligned.)
  always @ (posedge aclk or negedge aresetn)
  begin : p_reg_ahb_wch_payload
    if (!aresetn) begin
      hwstrb_i <= {4{1'b0}};
      hwdata_i <= {32{1'b0}};
    end else if (hready) begin
      hwstrb_i <= hwstrb_nxt;
      hwdata_i <= hwdata_nxt;
    end
  end // p_reg_ahb_wch_payload

  // Signals a strobeless write data beat for AHB-Lite
  assign hwstrbless_nxt = ~(|hwstrb_nxt);

  // Signals that a strobeless write data beat has been received during the
  // current AHB-Lite Address Phase
  // 
  assign strbless_on_aph = force_incr_aph &
                           hwrite_o & hwstrbless_nxt;

  // Signals that a strobeless write data beat has been presented on the
  // current AHB-Lite Data Phase
  assign strbless_on_dph = force_incr_dph &
                           hwrite_o_reg & hwstrbless;

  // Signals that a strobeless write data beat happening mid-burst will force
  // HTRANS to a NONSEQ as the transfer recovers
  assign strbless_force_nseq = ~first_aph & aph &
                               ~strbless_on_aph & strbless_on_dph &
                                ahb_wr_beats_left;

  // Signals that HTRANS needs to be forced NONSEQ after an unexpected IDLE
  // i.e. HTRANS tried to go NONSEQ after a series of strobeless IDLEs, but
  //      either WVALID or DREADY pulls HTRANS[1] LOW forcing another IDLE
  assign idle_recover_nseq = ~first_aph & aph & hwrite_o &
                             ~(|htrans_reg) & ~htrans_bit1_aph_reg;

  //---------------------------------------------------------------------------
  //  I T B   D - C H A N N E L
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  //  I T B   D V A L I D   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Signal assignment
  assign dvalid = wr_resp_valid | rd_resp_valid;

  //---------------------------------------------------------------------------
  //  I T B   D L A S T   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Signal assignment
  assign dlast = last_rd_resp_valid;

  //---------------------------------------------------------------------------
  //  I T B   D - C H A N N E L   B U F F E R
  //---------------------------------------------------------------------------

  // Signals the response(s) to be returned on the ITB D-Channel
  assign itb_resp[1] = last_wr_resp[1] | unaligned_decerr_en | hresp;
  assign itb_resp[0] = last_wr_resp[0] | unaligned_decerr_en;

  // D-Channel Buffer Inputs
  assign dcb_data_in = {hrdata,
                        last_ahb_rd_beat_rx,
                        ahb_rd_beat_rx,
                        last_ahb_wr_beat_rx,
                        itb_resp};
  assign dcb_push_in = ahb_rd_beat_rx | last_ahb_wr_beat_rx;
  assign dcb_pop_in  = itb_rd_beat_rx | last_itb_wr_beat_rx;

  // Beat Reponse MUX
  assign beat_resp_mux = dcb_not_empty ? dcb_data_out[1:0] : 2'b00;

  // (Last) Write Response Valid MUX
  assign wr_resp_valid = dcb_not_empty ? dcb_data_out[2] : 1'b0;

  // Read Response Valid MUX
  assign rd_resp_valid = dcb_not_empty ? dcb_data_out[3] : 1'b0;

  // Last Read Response Valid MUX
  assign last_rd_resp_valid = dcb_not_empty ? dcb_data_out[4] : 1'b0;

  // Assign ITB D-Channel Data
  assign ddata = dcb_data_out[36:5];

  //---------------------------------------------------------------------------
  // dcb_ready     =  HIGH, if either OR both registers are empty.
  // dcb_not_empty =  HIGH, if either OR both registers are full.

  defparam u_ahb_amib_dcb.PAYLD_WIDTH = 37;
  ful_regd_slice u_ahb_amib_dcb
  (
    // Global Inputs
    .aresetn        (aresetn),
    .aclk           (aclk),
    // Inputs
    .valid_src      (dcb_push),
    .ready_dst      (dcb_pop),
    .payload_src    (dcb_data_in),
    // Outputs
    .ready_src      (dcb_ready),
    .valid_dst      (dcb_not_empty),
    .payload_dst    (dcb_data_out)
  ); // u_ahb_amib_dcb

  // PUSH Control Logic
  assign dcb_push = dcb_ready & dcb_push_in;

  // POP Control Logic
  assign dcb_pop = dcb_not_empty & dcb_pop_in;

  //---------------------------------------------------------------------------

  // Signals that the D-Channel Buffer may stall if another "push" occurs
  assign dcb_may_stall = ~dready & dcb_not_empty;

  //---------------------------------------------------------------------------

  // Register HADDR[1:0] on HREADY
  always @ (posedge aclk or negedge aresetn)
  begin : p_haddr_o_reg_hrdy
    if (!aresetn) begin
      haddr_o_reg_hrdy <= {2{1'b0}};
    end else if (hready) begin
      haddr_o_reg_hrdy <= haddr_o[1:0];
    end
  end // p_haddr_o_reg_hrdy

  // Register HSIZE on HREADY
  always @ (posedge aclk or negedge aresetn)
  begin : p_hsize_o_reg_hrdy
    if (!aresetn) begin
      hsize_o_reg_hrdy <= {3{1'b0}};
    end else if (hready) begin
      hsize_o_reg_hrdy <= hsize_o;
    end
  end // p_hsize_o_reg_hrdy

  // Instantiation of Combinatorial byte lane strobe generator
  // Inputs passed to the instance are 
  // haddr_o_reg --> Address of the address phase of the AHB-Lite transfer.
  // hsize_o_reg --> Size of the address phase of the AHB-Lite transfer.
  //
  defparam u_ahb_amib_s_gen.DATA_WIDTH = 32;
  axi_to_ahb_s_gen_32 u_ahb_amib_s_gen
  (
    .addr           (haddr_o_reg_hrdy[1:0]),
    .burst_size     (hsize_o_reg_hrdy),

    .strb           (strb_chk)
  ); // u_ahb_amib_s_gen

  // Signals a strobeless write data beat on the AHB-Lite HWDATA bus
  assign hwstrbless = ~(|hwstrb_i);

  // Checks whether the AHB-Lite strobes match the AHB-Lite address and size
  // (Note: Strobeless beats are ignored)
  assign strb_chk_pass = (strb_chk == hwstrb_i) | hwstrbless;

  // Signals an AHB-Lite write beat ERROR response
  assign wr_beat_err_resp = ahb_wr_beat_rx & hresp;

  // Signals an AHB-Lite sparse write beat
  // Note: Only when DECERR Enable is HIGH
  assign wr_beat_sparse = ahb_wr_beat_rx & ~strb_chk_pass &
                          decerr_en_dph;

  // Signals an AHB-Lite strobeless write beat
  // Note: Only when DECERR Enable is HIGH, AND
  //            when HTRANS is not being forced to IDLE
  assign wr_beat_strbless = ahb_wr_beat_rx & hwstrbless &
                            decerr_en_dph & ~force_incr_dph;

  // Construct the write beat response destined for the ITB D-Channel, where:
  // 
  // o AHB-Lite ERROR                 => ITB SLVERR (in all cases)
  // o AHB-Lite Sparse     Write Beat => ITB DECERR (DECERR Enable HIGH)
  // o AHB-Lite Strobeless Write Beat => ITB DECERR (DECERR Enable HIGH)
  //                                            AND (FORCE INCR     LOW)
  // 
  assign wr_beat_resp[1] = wr_beat_err_resp | wr_beat_sparse | wr_beat_strbless;
  assign wr_beat_resp[0] = wr_beat_sparse | wr_beat_strbless;

  // Reset the write response hold logic the cycle after the last write beat
  // response has been received
  always @ (posedge aclk or negedge aresetn)
  begin : p_reset_wr_resp_hold_seq
    if (!aresetn) begin
      reset_wr_resp_hold <= 1'b0;
    end else begin
      reset_wr_resp_hold <= last_ahb_wr_beat_rx;
    end
  end // p_reset_wr_resp_hold_seq

  // Hold the write beat reponse (if not OKAY) until the burst completes
  assign wr_resp_hold =     wr_beat_resp[1] ? wr_beat_resp :
                        (reset_wr_resp_hold ? 2'b00 : wr_resp_hold_reg);

  // Signal the last write beat response
  assign last_wr_resp = (wr_beat_resp | wr_resp_hold) &
                         {2{last_ahb_wr_beat_rx}};

  // Register Write Beat Response (HOLD)
  always @ (posedge aclk or negedge aresetn)
  begin : p_wr_beat_resp_reg_seq
    if (!aresetn) begin
      wr_resp_hold_reg <= 2'b00;
    end else begin
      wr_resp_hold_reg <= wr_resp_hold;
    end
  end // p_wr_beat_resp_reg_seq

  // Signal assignment
  assign dresp = beat_resp_mux;

  //---------------------------------------------------------------------------
  //  I T B   D B N R / D I D   A S S I G N M E N T
  //---------------------------------------------------------------------------

  // Assign D-Channel signal "DBNR"
  // MUX needed or DVALID will go 'X' when FIFO is empty
  assign dbnr_i = acb_not_empty ? acb_data_out[1] : 1'b0;
  assign dbnr = dbnr_i;

  // Assign D-Channel signal "DID"
  assign did = acb_data_out[9:2];

  //---------------------------------------------------------------------------
  //  I T B   1 K B   B O U N D A R Y   C R O S S I N G
  //---------------------------------------------------------------------------

  // Detect whether burst is going to cross 1KB boundary
  always @ (alen_reg or asize_reg or aaddr_reg)
  begin : p_cross_1kb_comb
    case (alen_reg)
      `AXI_ALEN_1 : crosses_1k = 1'b0;
      `AXI_ALEN_4 :
        case (asize_reg)
          // Add 0x01 to the address each time (0x3FC, 0x3FD, 0x3FE, 0x3FF)
          // Add 0x02 to the address each time (0x3F8, 0x3FA, 0x3FC, 0x3FE)
          // Add 0x04 to the address each time (0x3F0  0x3F4, 0x3F8, 0x3FC)
          // Add 0x08 to the address each time (0x3E0  0x3E8, 0x3F0, 0x3F8)
          // Add 0x10 to the address each time (0x3C0  0x3D0, 0x3E0, 0x3F0)
          // Add 0x20 to the address each time (0x380  0x3A0, 0x3C0, 0x3E0)
          // Add 0x40 to the address each time (0x300  0x340, 0x380, 0x3C0)
          // Add 0x80 to the address each time (0x200  0x280, 0x300, 0x380)
          `AXI_ASIZE_8   : crosses_1k = ( aaddr_reg[9:0]            > 10'h3FC);
          `AXI_ASIZE_16  : crosses_1k = ({aaddr_reg[9:1], 1'b0}     > 10'h3F8);
          `AXI_ASIZE_32  : crosses_1k = ({aaddr_reg[9:2], 2'b00}    > 10'h3F0);
          `AXI_ASIZE_64  : crosses_1k = ({aaddr_reg[9:3], 3'b000}   > 10'h3E0);
          `AXI_ASIZE_128 : crosses_1k = ({aaddr_reg[9:4], 4'b0000}  > 10'h3C0);
          `AXI_ASIZE_256 : crosses_1k = ({aaddr_reg[9:5], 5'b00000} > 10'h380);
          default : crosses_1k = 1'bx;
        endcase
      `AXI_ALEN_8 :
        case (asize_reg)
          `AXI_ASIZE_8   : crosses_1k = ( aaddr_reg[9:0]            > 10'h3F8);
          `AXI_ASIZE_16  : crosses_1k = ({aaddr_reg[9:1], 1'b0}     > 10'h3F0);
          `AXI_ASIZE_32  : crosses_1k = ({aaddr_reg[9:2], 2'b00}    > 10'h3E0);
          `AXI_ASIZE_64  : crosses_1k = ({aaddr_reg[9:3], 3'b000}   > 10'h3C0);
          `AXI_ASIZE_128 : crosses_1k = ({aaddr_reg[9:4], 4'b0000}  > 10'h380);
          `AXI_ASIZE_256 : crosses_1k = ({aaddr_reg[9:5], 5'b00000} > 10'h300);
          default : crosses_1k = 1'bx;
        endcase
      `AXI_ALEN_16 :
        case (asize_reg)
          `AXI_ASIZE_8   : crosses_1k = ( aaddr_reg[9:0]            > 10'h3F0);
          `AXI_ASIZE_16  : crosses_1k = ({aaddr_reg[9:1], 1'b0}     > 10'h3E0);
          `AXI_ASIZE_32  : crosses_1k = ({aaddr_reg[9:2], 2'b00}    > 10'h3C0);
          `AXI_ASIZE_64  : crosses_1k = ({aaddr_reg[9:3], 3'b000}   > 10'h380);
          `AXI_ASIZE_128 : crosses_1k = ({aaddr_reg[9:4], 4'b0000}  > 10'h300);
          `AXI_ASIZE_256 : crosses_1k = ({aaddr_reg[9:5], 5'b00000} > 10'h200);
          default : crosses_1k = 1'bx;
        endcase
      // Other burst lengths can use INCR anyway...
      `AXI_ALEN_2, 
      `AXI_ALEN_3, 
      `AXI_ALEN_5, 
      `AXI_ALEN_6, 
      `AXI_ALEN_7, 
      `AXI_ALEN_9, 
      `AXI_ALEN_10, 
      `AXI_ALEN_11, 
      `AXI_ALEN_12, 
      `AXI_ALEN_13, 
      `AXI_ALEN_14, 
      `AXI_ALEN_15 : crosses_1k = 1'b0;
      default : crosses_1k = 1'bx;
    endcase
  end // p_cross_1kb_comb

  // Hold register "crosses_1k" on A-Channel Handshake
  always @ (posedge aclk or negedge aresetn)
  begin : p_crosses_1k_h_seq
    if (!aresetn) begin
      crosses_1k_h <= 1'b0;
    end else if (ach_hndshk) begin
      crosses_1k_h <= crosses_1k;
    end
  end // p_crosses_1k_h_seq

  // MUX between current and hold register
  assign crosses_1k_mux = ach_hndshk ? crosses_1k : crosses_1k_h;

  //---------------------------------------------------------------------------
  //  I T B   U N A L I G N E D   A D D R E S S   D E T E C T I O N
  //---------------------------------------------------------------------------

  // Detect an unaligned burst
  always @ (asize_reg or aaddr_reg)
  begin : p_detect_unaligned_comb
    case (asize_reg)
      `AXI_ASIZE_8   : unaligned_addr =  1'b0;
      `AXI_ASIZE_16  : unaligned_addr =  aaddr_reg[0];
      `AXI_ASIZE_32  : unaligned_addr = (aaddr_reg[0] | aaddr_reg[1]);
      `AXI_ASIZE_64  : unaligned_addr = (aaddr_reg[0] | aaddr_reg[1] |
                                         aaddr_reg[2]);
      `AXI_ASIZE_128 : unaligned_addr = (aaddr_reg[0] | aaddr_reg[1] |
                                         aaddr_reg[2] | aaddr_reg[3]);
      `AXI_ASIZE_256 : unaligned_addr = (aaddr_reg[0] | aaddr_reg[1] |
                                         aaddr_reg[2] | aaddr_reg[3] |
                                         aaddr_reg[4]);
       default            : unaligned_addr = 1'bx;
    endcase
  end // p_detect_unaligned_comb

  // Signals an unaligned ITB transfer has started the conversion process
  assign unaligned_itb = unaligned_addr & ach_hndshk;

  // Signal "unaligned_itb" gets pushed into A-Channel Buffer
  // It appears on the other side of the A-Channel Buffer as "unaligned_ahb"

  // Signals an unaligned AHB transfer is in the conversion process
  assign unaligned_ahb = acb_data_out[0] & acb_not_empty;

  // Signals that an unaligned transfer will force a DECERR on DRESP
  assign unaligned_decerr_en = unaligned_ahb & decerr_en_dph;

  //---------------------------------------------------------------------------
  //  I T B   F O R C E   U N D E F I N E D - L E N G T H   I N C R
  //---------------------------------------------------------------------------

  // Signals that fixed length INCR bursts should be forced to undefined INCRs
  assign force_undef_incr = force_incr;

  // Hold the state of "force_undef_incr" until the next A-Channel handshake
  assign force_incr_mux = ach_hndshk ? force_undef_incr : force_incr_mux_h;

  // Hold the state of "decerr_en" until the next A-Channel handshake
  assign decerr_en_mux = ach_hndshk ? decerr_en : decerr_en_mux_h;

  // Register "force_undef_incr" on A-Channel handshake
  always @ (posedge aclk or negedge aresetn)
  begin : p_force_incr_mux_h_seq
    if (!aresetn) begin
      force_incr_mux_h <= 1'b0;
    end else if (ach_hndshk) begin
      force_incr_mux_h <= force_undef_incr;
    end
  end // p_force_incr_mux_h_seq

  // Register "decerr_en" on A-Channel handshake
  always @ (posedge aclk or negedge aresetn)
  begin : p_decerr_en_mux_h_seq
    if (!aresetn) begin
      decerr_en_mux_h <= 1'b0;
    end else if (ach_hndshk) begin
      decerr_en_mux_h <= decerr_en;
    end
  end // p_decerr_en_mux_h_seq

  // Register "force_incr_mux" and "decerr_en_mux" to break timing path from
  // ITB to AHB-Lite
  always @ (posedge aclk or negedge aresetn)
  begin : p_break_tie_offs_timing_seq
    if (!aresetn) begin
      decerr_en_mux_reg  <= 1'b0;
      force_incr_mux_reg <= 1'b0;
    end else begin
      decerr_en_mux_reg  <= decerr_en_mux;
      force_incr_mux_reg <= force_incr_mux;
    end
  end // p_break_tie_offs_timing_seq

  // HBURST needs a signal aligned to the ITB-side
  assign force_incr_burst = force_incr_mux & (start_nseq | aph);

  // Aligns "force_incr_mux" to AHB-Lite Address Phase
  assign force_incr_aph = force_incr_mux_reg & aph;

  // Aligns "decerr_en_mux" to AHB-Lite Address Phase
  assign decerr_en_aph  = decerr_en_mux_reg & aph;

  // Aligns "force_incr_aph" to AHB-Lite Data Phase
  always @ (posedge aclk or negedge aresetn)
  begin : p_force_incr_dph_seq
    if (!aresetn) begin
      force_incr_dph <= 1'b0;
    end else if (hready) begin
      force_incr_dph <= force_incr_aph;
    end
  end // p_force_incr_dph_seq

  // Aligns "decerr_en_aph" to AHB-Lite Data Phase
  always @ (posedge aclk or negedge aresetn)
  begin : p_decerr_en_dph_seq
    if (!aresetn) begin
      decerr_en_dph <= 1'b0;
    end else if (hready) begin
      decerr_en_dph <= decerr_en_aph;
    end
  end // p_decerr_en_dph_seq

  //-------------------
  //  A H B - L I T E
  //-------------------

  //---------------------------------------------------------------------------
  //  A H B - L I T E   A D D R E S S   P H A S E   C O N T R O L
  //---------------------------------------------------------------------------

  // Signals the start of an AHB-Lite NONSEQ on an in-coming ITB A-Channel
  // handshake (Note: This signal is a single cycle strobe.)
  assign nseq_on_ach_hndshk = ach_hndshk & ~dcb_may_stall;

  // Signals the start of an AHB-Lite NONSEQ the cycle after the last
  // (waited) data-phase has been received
  assign nseq_after_hrdy_reg = ~first_aph_reg & load_last_beat_reg;

  // Signals the start of an AHB-Lite NONSEQ
  // (Note: This signal is a single cycle strobe.)
  assign start_nseq = nseq_on_ach_hndshk  |
                      load_on_rb_recovery |
                      nseq_after_hrdy_reg;

  // Register 'start_nseq' to break AHB-Lite Forward Path
  always @ (posedge aclk or negedge aresetn)
  begin : p_start_nseq_reg
    if (!aresetn) begin
      start_nseq_reg <= 1'b0;
    end else begin
      start_nseq_reg <= start_nseq;
    end
  end // p_start_nseq_reg

  // Signals that the first AHB-Lite Address Phase has been successfully
  // received by the AHB-Lite Slave
  assign first_aph_rx = first_aph_reg &
                        htrans_bit1_aph_reg & hready_reg;

  // Signals that an AHB-Lite Address Phase has started
  // i.e. The first AHB-Lite Address Phase is in progress
  // (Note: This signal is held HIGH until HREADY accepts.)
  assign first_aph = start_nseq_reg ? 1'b1 :
                    (first_aph_rx ? 1'b0 : first_aph_reg);

  // Register "load_on_last_beat_rx"
  always @ (posedge aclk or negedge aresetn)
  begin : p_load_last_beat_reg_seq
    if (!aresetn) begin
      load_last_beat_reg <= 1'b0;
    end else begin
      load_last_beat_reg <= load_on_last_beat_rx;
    end
  end // p_load_last_beat_reg

  // Register "hready"
  always @ (posedge aclk or negedge aresetn)
  begin : p_hready_reg_seq
    if (!aresetn) begin
      hready_reg <= 1'b0;
    end else begin
      hready_reg <= hready;
    end
  end // p_hready_reg_seq

  // Register "first_aph"
  always @ (posedge aclk or negedge aresetn)
  begin : p_first_aph_reg_seq
    if (!aresetn) begin
      first_aph_reg <= 1'b0;
    end else begin
      first_aph_reg <= first_aph;
    end
  end // p_first_aph_reg_seq

  // --------------------

  // Signals that the current AHB-Lite Address Phase has stopped
  // (Note: This signal is a single cycle strobe.)
  assign stop_aph  = (last_ahb_wr_beat | last_ahb_rd_beat ) &
                      htrans_bit1_reg_hrdy & hready_reg &
                     ~first_aph;

  // Signals an AHB-Lite Address Phase
  assign aph = first_aph ? 1'b1 :
               (stop_aph ? 1'b0 : aph_reg);

  // Register "aph"
  always @ (posedge aclk or negedge aresetn)
  begin : p_aph_reg_seq
    if (!aresetn) begin
      aph_reg <= 1'b0;
    end else begin
      aph_reg <= aph;
    end
  end // p_aph_reg_seq

  //---------------------------------------------------------------------------
  //  A H B - L I T E   H B U R S T   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Generate HBURST from ALEN and ABURST
  always @ (alen_mux or aburst_mux or crosses_1k_mux or force_incr_burst)
  begin : p_gen_hburst_comb
    hburst_i = `AHB_HBURST_SINGLE;
    case (aburst_mux)
      `AXI_ABURST_FIXED : hburst_i = `AHB_HBURST_SINGLE;
      `AXI_ABURST_INCR  :
        begin
          if (crosses_1k_mux || force_incr_burst) begin
            hburst_i = `AHB_HBURST_INCR; 
          end else begin
            case (alen_mux)
              `AXI_ALEN_1  : hburst_i = `AHB_HBURST_SINGLE; 
              `AXI_ALEN_4  : hburst_i = `AHB_HBURST_INCR4; 
              `AXI_ALEN_8  : hburst_i = `AHB_HBURST_INCR8; 
              `AXI_ALEN_16 : hburst_i = `AHB_HBURST_INCR16;
              `AXI_ALEN_2,
              `AXI_ALEN_3,
              `AXI_ALEN_5,
              `AXI_ALEN_6,
              `AXI_ALEN_7,
              `AXI_ALEN_9,
              `AXI_ALEN_10,
              `AXI_ALEN_11,
              `AXI_ALEN_12,
              `AXI_ALEN_13,
              `AXI_ALEN_14,
              `AXI_ALEN_15 : hburst_i = `AHB_HBURST_INCR;
              default :
                hburst_i = 3'bxxx;
            endcase
          end
        end
      `AXI_ABURST_WRAP  :
        begin
          if (force_incr_burst) begin
            hburst_i = `AHB_HBURST_INCR; 
          end else begin
            // No 1KB Boundary crossing term because fixed-length wraps have
            // to be aligned and so can therefore never cross 1KB.
            case (alen_mux)
              `AXI_ALEN_2  : hburst_i = `AHB_HBURST_SINGLE; 
              `AXI_ALEN_4  : hburst_i = `AHB_HBURST_WRAP4; 
              `AXI_ALEN_8  : hburst_i = `AHB_HBURST_WRAP8; 
              `AXI_ALEN_16 : hburst_i = `AHB_HBURST_WRAP16;
              // The following values for ALEN are invalid as wrapping bursts in
              // AHB-Lite.  Therefore HBURST defaults to an undefined length
              // incrementing burst.
              `AXI_ALEN_3,
              `AXI_ALEN_5,
              `AXI_ALEN_6,
              `AXI_ALEN_7,
              `AXI_ALEN_9,
              `AXI_ALEN_10,
              `AXI_ALEN_11,
              `AXI_ALEN_12,
              `AXI_ALEN_13,
              `AXI_ALEN_14,
              `AXI_ALEN_15 : hburst_i = `AHB_HBURST_INCR;
              default :
                hburst_i = 3'bxxx;
            endcase
          end
        end
      default :
        hburst_i = 3'bxxx;
    endcase
  end // p_gen_hburst_comb

  //---------------------------------------------------------------------------
  //  A H B - L I T E   H T R A N S   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Current burst is a FIXED type
  assign aburst_fixed = (aburst_h == `AXI_ABURST_FIXED);

  // Current burst is a WRAP type, length 2
  assign aburst_wrap2 = (aburst_h == `AXI_ABURST_WRAP) &&
                        (alen_h   == `AXI_ALEN_2);

  // Current HADDR address has just crossed a 1KB boundary
  assign haddr_at_1kb_bndry = (haddr_o[10] != haddr_o_reg_htrans[10]);

  // Current HADDR address has just crossed a wrap boundary for writes
  assign haddr_at_wrp_bndry = (aburst_h == `AXI_ABURST_WRAP) & addr_wrapped;

  // Signals that a WRAP which has been coverted to an undefined-length INCR
  // should force HTRANS to NONSEQ at the WRAP boundary
  assign wrap_force_nseq = haddr_at_wrp_bndry &
                           force_incr_aph   &
                           ahb_wr_beats_left;

  // Signals that HTRANS should be forced NONSEQ during a burst
  assign force_nseq = (~first_aph & aph) &
                      (aburst_fixed       |
                       aburst_wrap2       |
                       haddr_at_1kb_bndry |
                       wrap_force_nseq);

  // Signals a BUSY or an IDLE transfer (HTRANS[0])
  assign busy_not_idle = (~first_aph & aph) & ~force_nseq;

  // Signals a NONSEQ or an IDLE transfer (HTRANS[1])
  assign nonseq_not_idle = first_aph;

  // Signals a SEQ or a BUSY transfer for write bursts (HTRANS[1])
  // 
  // o There MUST be:
  // 
  //   1) Write beats left in the AHB-Lite Write Beat Counter, AND
  // 
  //     2) Valid Write Data on the W-Channel, OR
  // 
  //     3) Valid Write Data in the Write Data Buffer
  // 
  assign wr_seq_not_busy = aph & hwrite_o &
                           (wvalid | wcb_not_empty);

  // Signals a SEQ or a BUSY transfer for read bursts (HTRANS[1])
  assign rd_seq_not_busy = aph & ~hwrite_o &
                           ~dcb_may_stall;

  // *****************
  // *** HTRANS[1] ***
  // *****************

  // Interal HTRANS[1] - NOT aligned to address phase and not masked
  // (Note: This signal is a single cycle strobe.)
  assign htrans_bit1_int = nonseq_not_idle |
                           wr_seq_not_busy |
                           rd_seq_not_busy;

  // Align Internal HTRANS[1] to AHB-Lite Address Phase
  always @ (first_aph or hready_reg or
            htrans_bit1_int or htrans_bit1_aph_reg)
  begin : p_htrans_bit1_aph_comb
    if (first_aph || hready_reg) begin
      htrans_bit1_aph = htrans_bit1_int;
    end else begin
      htrans_bit1_aph = htrans_bit1_aph_reg;
    end
  end // p_htrans_bit1_aph_comb

  // Register "htrans_bit1_aph"
  always @ (posedge aclk or negedge aresetn)
  begin : p_htrans_bit1_aph_reg_seq
    if (!aresetn) begin
      htrans_bit1_aph_reg <= 1'b0;
    end else begin
      htrans_bit1_aph_reg <= htrans_bit1_aph;
    end
  end // p_htrans_bit1_aph_reg_seq

  // Register "htrans_bit1_aph" on HREADY
  // Register HTRANS[1] on HREADY
  always @ (posedge aclk or negedge aresetn)
  begin : p_htrans_bit1_reg_hrdy
    if (!aresetn) begin
      htrans_bit1_reg_hrdy <= 1'b0;
    end else if (hready) begin
      htrans_bit1_reg_hrdy <= htrans_bit1_aph;
    end
  end // p_htrans_bit1_reg_hrdy

  // *****************
  // *** HTRANS[0] ***
  // *****************

  // Internal HTRANS[0] - NOT aligned to address phase and not masked
  assign htrans_bit0_int = busy_not_idle;

  // Align Internal HTRANS[0] to AHB-Lite Address Phase
  always @ (first_aph or hready_reg or
            htrans_bit0_int or htrans_bit0_aph_reg)
  begin : p_htrans_bit0_aph_comb
    if (first_aph || hready_reg) begin
      htrans_bit0_aph = htrans_bit0_int;
    end else begin
      htrans_bit0_aph = htrans_bit0_aph_reg;
    end
  end // p_htrans_bit0_aph_comb

  // Register "htrans_bit0_aph"
  always @ (posedge aclk or negedge aresetn)
  begin : p_htrans_bit0_aph_reg_seq
    if (!aresetn) begin
      htrans_bit0_aph_reg <= 1'b0;
    end else begin
      htrans_bit0_aph_reg <= htrans_bit0_aph;
    end
  end // p_htrans_bit0_aph_reg_seq

  // **************
  // *** HTRANS ***
  // **************

  // Address Phase Aligned HTRANS (without strobeless masks)
  assign htrans_aph = {htrans_bit1_aph, htrans_bit0_aph};

  // Apply strobeless beat mask to HTRANS[0]
  // (Note: This signals is a single cycle strobe.)
  assign htrans_bit0_masked =  htrans_aph[0]       &
                              ~strbless_on_aph     &
                              ~strbless_force_nseq &
                              ~idle_recover_nseq;

  // Apply strobeless beat mask to HTRANS[1]
  // (Note: This signals is a single cycle strobe.)
  assign htrans_bit1_masked =  htrans_bit1_aph & ~strbless_on_aph;

  // Internal HTRANS with strobeless beat masks applied
  // (Note: This signals is a single cycle strobe.)
  assign htrans_masked = {htrans_bit1_masked, htrans_bit0_masked};

  // Align Internal HTRANS (with strobeless beat masks applied) to AHB-Lite
  // Address Phase
  always @ (first_aph or hready_reg or
            htrans_masked or htrans_reg)
  begin : p_htrans_comb
    if (first_aph || hready_reg) begin
      htrans_o = htrans_masked;
    end else begin
      htrans_o = htrans_reg;
    end
  end // p_htrans_comb

  // Register "htrans_o"
  always @ (posedge aclk or negedge aresetn)
  begin : p_htrans_reg_seq
    if (!aresetn) begin
      htrans_reg <= 2'b00;
    end else begin
      htrans_reg <= htrans_o;
    end
  end // p_htrans_reg_seq

  //---------------------------------------------------------------------------
  //  A H B - L I T E   A D D R E S S   A L I G N M E N T
  //---------------------------------------------------------------------------

  // Align ITB address
  always @ (aaddr_reg or asize_reg)
  begin : p_align_addr_comb
    case (asize_reg)
      `AXI_ASIZE_8    : aligned_addr =  aaddr_reg;
      `AXI_ASIZE_16   : aligned_addr = {aaddr_reg[31:1], 1'b0};
      `AXI_ASIZE_32   : aligned_addr = {aaddr_reg[31:2], 2'b00};
      `AXI_ASIZE_64   : aligned_addr = {aaddr_reg[31:3], 3'b000};
      `AXI_ASIZE_128  : aligned_addr = {aaddr_reg[31:4], 4'b0000};
      `AXI_ASIZE_256  : aligned_addr = {aaddr_reg[31:5], 5'b00000};
      `AXI_ASIZE_512  : aligned_addr = aaddr_reg;  // Illegal ASIZE
      `AXI_ASIZE_1024 : aligned_addr = aaddr_reg;  // Illegal ASIZE
      default : aligned_addr = {32{1'bx}};
    endcase
  end // p_align_addr_comb

  //---------------------------------------------------------------------------
  //  A H B - L I T E   A D D R E S S   I N C R E M E N T E R
  //---------------------------------------------------------------------------

  // Instantiation of Combinatorial address incrementer
  // Inputs passed to the instance are 
  // haddr_o --> Current address which needs to be incremented for next
  //             transfer.
  // alen    --> Length of ITB transfer.
  //             This information is required for WRAP transfers.
  // asize   --> ITB transfer width.
  //             Values can be 8/16/32/64/128/256 bit.
  // aburst  --> ITB burst information.
  //             Values can be FIXED/INCR/WRAP transfers.
  //
  defparam u_a_gen.ADDR_WIDTH = 12;
  axi_to_ahb_a_gen_32 u_a_gen
  (
    .addr_in        (haddr_o[11:0]),
    .alen           (alen_mux),
    .asize          (asize_mux),
    .aburst         (aburst_mux),

    .addr_out       (incr_haddr[11:0])
  );

  // Upper address bits are unchanged
  assign incr_haddr[31:12] = haddr_o[31:12];

  //---------------------------------------------------------------------------
  //  A H B - L I T E   W R A P   D E T E C T I O N
  //---------------------------------------------------------------------------

  // Calculate a WRAP mask for HADDR to determine on which Address Phase the
  // burst will wrap around.
  // 
  always @(alen_mux or asize_mux)
  begin : p_wrap_mask_comb
    case (asize_mux)
      `AXI_ASIZE_8   : wrap_mask = {2'b0, alen_mux};
      `AXI_ASIZE_16  : wrap_mask = {1'b0, alen_mux, 1'b0};
      `AXI_ASIZE_32  : wrap_mask = {alen_mux, 2'b00};
      default        : wrap_mask = {6'bx};
    endcase
  end // p_wrap_mask_comb

  // Register "wrap_mask" to break timing path from ITB to AHB-Lite
  always @ (posedge aclk or negedge aresetn)
  begin : p_break_wrap_mask_timing_seq
    if (!aresetn) begin
      wrap_mask_reg <= {6'b0};
    end else begin
      wrap_mask_reg <= wrap_mask;
    end
  end // p_break_wrap_mask_timing_seq

  // Bit-wise invert WRAP mask
  assign wrap_mask_n = ~wrap_mask_reg;

  // Mask the previously accepted Address Phase
  assign masked_prev_addr = haddr_o_reg_htrans[5:0] & wrap_mask_reg;

  // Signal that the current address has wrapped
  assign addr_wrapped = &(masked_prev_addr ^ wrap_mask_n);

  //---------------------------------------------------------------------------
  //  A H B - L I T E   H A D D R   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Signals that HADDR should be incremented
  assign increment_haddr = hready & htrans_bit1_aph;

  // HADDR MUX:
  // 
  //   o HADDR -> Aligned Address (aligned_addr), when 1st NONSEQ of translation.
  //   o HADDR -> Incremented Address, when BUSY/SEQ or NONSEQ override.
  //   o HADDR -> Previous HADDR, when IDLE... or anything else.
  //
  always @ (haddr_o or
            ach_hndshk or aligned_addr or
            increment_haddr or incr_haddr)
  begin : p_haddr_i_comb
    haddr_i = haddr_o;
    if (ach_hndshk) begin
      haddr_i = aligned_addr;
    end else if (increment_haddr) begin
      haddr_i = incr_haddr;
    end
  end // p_haddr_i_comb

  // Register HADDR on HTRANS
  always @ (posedge aclk or negedge aresetn)
  begin : p_haddr_o_reg_htrans_seq
    if (!aresetn) begin
      haddr_o_reg_htrans <= {11{1'b0}};
    end else if (htrans_aph[1] && hready) begin
      haddr_o_reg_htrans <= haddr_o[10:0];
    end
  end // p_haddr_o_reg_htrans_seq

  //---------------------------------------------------------------------------
  //  A H B - L I T E   H M A S T L O C K   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Signal the first locked ITB transfer of a locked sequence
  assign itb_start_lock = first_aph & alock_mux[1] & ~itb_lock_reg;

  // Signal the first unlocking ITB transfer of a locked sequence
  assign itb_stop_lock = first_aph & ~alock_mux[1] & itb_lock_reg;

  // Signal the final AHB-Lite address phase of a locked sequence
  assign last_locked_aph = hmastlock_o_reg & stop_aph;

  // Signal that the AHB-Lite locked sequence should be stopped when the
  // current transfer finishes the last address phase
  assign stopping_lock =    itb_stop_lock ? 1'b1 :
                         (last_locked_aph ? 1'b0 : stopping_lock_reg);

  // Register stopping_lock
  always @ (posedge aclk or negedge aresetn)
  begin : p_reg_stopping_lock_seq
    if (!aresetn) begin
      stopping_lock_reg <= 1'b0;
    end else begin
      stopping_lock_reg <= stopping_lock;
    end
  end // p_reg_stopping_lock_seq

  // Signals the duration of the ITB locked sequence
  assign itb_lock = itb_start_lock ? 1'b1 :
                    (itb_stop_lock ? 1'b0 : itb_lock_reg);

  // Register itb_lock
  always @ (posedge aclk or negedge aresetn)
  begin : p_reg_itb_lock_seq
    if (!aresetn) begin
      itb_lock_reg <= 1'b0;
    end else begin
      itb_lock_reg <= itb_lock;
    end
  end // p_reg_itb_lock_seq

  // Signals an AHB-Lite locked sequence
  assign hmastlock_i = itb_lock | stopping_lock; 

  // Register hmastlock
  always @ (posedge aclk or negedge aresetn)
  begin : p_hmastlock_o_reg_seq
    if (!aresetn) begin
      hmastlock_o_reg <= 1'b0;
    end else begin
      hmastlock_o_reg <= hmastlock_o;
    end
  end // p_hmastlock_o_reg_seq

  //---------------------------------------------------------------------------
  //  A H B - L I T E   H R E A D Y M U X   G E N E R A T I O N
  //---------------------------------------------------------------------------

  // Register HSEL
  always @ (posedge aclk or negedge aresetn)
  begin : p_hsel_o_reg_seq
    if (!aresetn) begin
      hsel_o_reg <= 1'b0;
    end else if (hready) begin
      hsel_o_reg <= hsel_o;
    end
  end // p_hsel_o_reg_seq

  // HREADYMUX (out) follows HREADY (in) on the data-phase
  assign hreadymux_i = hsel_o_reg ? hready : 1'b1;

  //---------------------------------------------------------------------------
  //  A H B - L I T E
  //---------------------------------------------------------------------------

  // HSIZE Assigment
  assign hsize_i = asize_mux;

  // HWRITE Assignment
  assign hwrite_i = awrite_mux;

  // Register HWRITE
  always @ (posedge aclk or negedge aresetn)
  begin : p_hwrite_o_reg_seq
    if (!aresetn) begin
      hwrite_o_reg <= 1'b0;
    end else begin
      hwrite_o_reg <= hwrite_o;
    end
  end // p_hwrite_o_reg_seq

  // Register HWRITE on HREADY (for Reads)
  always @ (posedge aclk or negedge aresetn)
  begin : p_hwrite_o_reg_hrdy_seq
    if (!aresetn) begin
      hwrite_o_reg_hrdy <= 1'b0;
    end else if (hready) begin
      hwrite_o_reg_hrdy <= hwrite_o;
    end
  end // p_hwrite_o_reg_hrdy_seq

  // HPROT Assignment
  assign hprot_i[3] = ach_hndshk ? acache_reg[1] : acache_h[1];
  assign hprot_i[2] = ach_hndshk ? acache_reg[0] : acache_h[0];
  assign hprot_i[1] = ach_hndshk ?  aprot_reg[0] :  aprot_h[0];
  assign hprot_i[0] = ach_hndshk ? ~aprot_reg[2] : ~aprot_h[2];

  //----------------------------------------------------------------------------
  // Assigning internal copies to output ports
  //----------------------------------------------------------------------------

  // AHB-Lite Address and Control
  assign hsel_o = aph;

  // Register AHB-Lite Forward Path
  always @ (posedge aclk or negedge aresetn)
  begin : p_reg_ahb_fwd_path_seq
    if (!aresetn) begin
      haddr_o     <= {32{1'b0}};
      hwrite_o    <= 1'b0;
      hsize_o     <= {3{1'b0}};
      hburst_o    <= {3{1'b0}};
      hprot_o     <= {4{1'b0}};
      hmastlock_o <= 1'b0;
    end else begin
      haddr_o     <= haddr_i;
      hwrite_o    <= hwrite_i;
      hsize_o     <= hsize_i;
      hburst_o    <= hburst_i;
      hprot_o     <= hprot_i;
      hmastlock_o <= hmastlock_i;
    end
  end // p_ahb_fwd_path_seq

  // AHB-Lite Forward Path
  assign hsel      = hsel_o;
  assign haddr     = haddr_o;
  assign htrans    = htrans_o;
  assign hwrite    = hwrite_o;
  assign hsize     = hsize_o;
  assign hburst    = hburst_o;
  assign hprot     = hprot_o;
  assign hwstrb    = hwstrb_i;
  assign hwdata    = hwdata_i;
  assign hmastlock = hmastlock_o;
  assign hreadymux = hreadymux_i;

//==============================================================================
// OVL Assertions
//==============================================================================
`ifdef ARM_ASSERT_ON

// Include Standard OVL Defines
`include "std_ovl_defines.h"

  //----------------------------------------------------------------------------
  // OVL_ASSERT: AHB-Lite Write Beat Counter should never decrement on zero.
  //----------------------------------------------------------------------------
  // 
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  wire ahb_wbc_zero;
  wire ahb_wbc_dec_on_zero;

  // Signals that the AHB-Lite Write Beat Counter is at zero.
  assign ahb_wbc_zero = (ahb_wbc == 5'b00000);

  // Signals that the AHB-Lite Write Beat Counter is decrementing when zero.
  assign ahb_wbc_dec_on_zero = ahb_wbc_zero & dec_ahb_wbc;

  assert_never #(`OVL_FATAL,
                 `OVL_ASSERT,
                 "AHB-Lite AMIB: AHB-Lite Write Beat Counter decremented on zero.")
  ahb_amib_ahb_wbc_dec_on_zero
  (
    .clk        (aclk),
    .reset_n    (aresetn),
    .test_expr  (ahb_wbc_dec_on_zero)
  );
  // OVL_ASSERT_END

  //----------------------------------------------------------------------------
  // OVL_ASSERT: AHB-Lite Read Beat Counter should never decrement on zero.
  //----------------------------------------------------------------------------
  // 
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  wire ahb_rbc_zero;
  wire ahb_rbc_dec_on_zero;

  // Signals that the AHB-Lite Read Beat Counter is at zero.
  assign ahb_rbc_zero = (ahb_rbc == 5'b00000);

  // Signals that the AHB-Lite Read Beat Counter is decrementing when zero.
  assign ahb_rbc_dec_on_zero = ahb_rbc_zero & dec_ahb_rbc;

  assert_never #(`OVL_FATAL,
                 `OVL_ASSERT,
                 "AHB-Lite AMIB: AHB-Lite Read Beat Counter decremented on zero.")
  ahb_amib_ahb_rbc_dec_on_zero
  (
    .clk        (aclk),
    .reset_n    (aresetn),
    .test_expr  (ahb_rbc_dec_on_zero)
  );
  // OVL_ASSERT_END

`ifdef ARM_OVL_IGNORE_UNALIGN
  //----------------------------------------------------------------------------
  // Inform if unalignment OVLs are disabled
  //----------------------------------------------------------------------------
  initial
    begin : p_ahb_amib_ignore_unalign
      $display("ARM_OVL_IGNORE_UNALIGN: Unalignment OVLs are disabled in %m");
    end // p_ahb_amib_ignore_unalign

`else
  //----------------------------------------------------------------------------
  // OVL_ASSERT: Unaligned Transaction
  //----------------------------------------------------------------------------
  // 
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never #(`OVL_WARNING,
                 `OVL_ASSERT,
                 "AHB-Lite AMIB: Unaligned Transaction.")
  ahb_amib_itb_unaligned
  (
    .clk        (aclk),
    .reset_n    (aresetn),
    .test_expr  (unaligned_itb)
  );
  // OVL_ASSERT_END

`endif // ARM_OVL_IGNORE_UNALIGN
`endif // ARM_ASSERT_ON
 

endmodule // axi_to_ahb_32


//------------------------------------------------------------------------------
// AMIB Undefines
//------------------------------------------------------------------------------
`include "Axi_undefs.v"
`include "Ahb_undefs.v"


//------------------------------------------------------------------------------
// End of File
//------------------------------------------------------------------------------
