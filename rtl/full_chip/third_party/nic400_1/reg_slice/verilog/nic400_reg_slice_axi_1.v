// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Revision       : 150000
//  File Date           :  2013-05-09 16:07:32 +0100 (Thu, 09 May 2013)
//
//  Release Information : PL401-r1p2-00rel0
// -----------------------------------------------------------------------------
//  Purpose             : HDL design file which provides timing isolation
//                        between master and slave interfaces on an
//                        AXI interconnect.
//
// --=========================================================================--

//------------------------------------------------------------------------------
//
//                                reg_slice_axi.v
//                               ===============
//
//------------------------------------------------------------------------------
//
//  Overview
// ==========
//
//   The reg_slice_axi provides a method of timing isolation between a master
// and a slave on an axi interconnect.
//
//   The reg_slice_axi can be statically configured to provide four modes of
// operation for each of the channels:
//    1. fully registered (total timing isolation between
//                         master and slave ports)
//    2. forward path registered only (timing isolation on data/ctrl/valid
//                                     paths only)
//    3. register slice bypass (path through mode, no timing isolation)
//    4. reverse path registered only (timing isolation on ready paths only)
//
//   The hndshk_blk uses four sub-components:
//    1. ax_reg_slice  - generic address channel register slice
//    2. wr_reg_slice  - write channel register slice
//    3. buf_reg_slice - write response channel register slice
//    4. rd_reg_slice  - read channel register slice
//
//------------------------------------------------------------------------------


`include "reg_slice_axi_defs.v"

module nic400_reg_slice_axi_1
  (
   // global interconnect inputs
   aresetn,
   aclk,

   // slave port write address channel interface
   awids,
   awaddrs,
   awlens,
   awsizes,
   awbursts,
   awlocks,
   awcaches,
   awprots,
   awusers,
   awvalids,
   awreadys,

   // slave port write channel interface
   wids,
   wdatas,
   wstrbs,
   wusers,
   wlasts,
   wvalids,
   wreadys,

   // slave port write response channel interface
   bids,
   bresps,
   busers,
   bvalids,
   breadys,

   // slave port read address channel interface
   arids,
   araddrs,
   arlens,
   arsizes,
   arbursts,
   arlocks,
   arcaches,
   arprots,
   arusers,
   arvalids,
   arreadys,

   // slave port read channel interface
   rids,
   rdatas,
   rresps,
   rusers,
   rlasts,
   rvalids,
   rreadys,

   // master port write address channel interface
   awidm,
   awaddrm,
   awlenm,
   awsizem,
   awburstm,
   awlockm,
   awcachem,
   awprotm,
   awuserm,
   awvalidm,
   awreadym,

   // master port write channel interface
   widm,
   wdatam,
   wstrbm,
   wuserm,
   wlastm,
   wvalidm,
   wreadym,

   // master port write response channel interface
   bidm,
   brespm,
   buserm,
   bvalidm,
   breadym,

   // master port read address channel interface
   aridm,
   araddrm,
   arlenm,
   arsizem,
   arburstm,
   arlockm,
   arcachem,
   arprotm,
   aruserm,
   arvalidm,
   arreadym,

   // master port read channel interface
   ridm,
   rdatam,
   rrespm,
   ruserm,
   rlastm,
   rvalidm,
   rreadym,

   // dummy scan interface
   scanenable,
   scaninaclk,
   scanoutaclk
   );

  // ---------------------------------------------------------------------------
  //  parameters
  // ---------------------------------------------------------------------------
  // user parameters
  parameter ID_WIDTH        = 4;       // width of the id fields
  parameter DATA_WIDTH      = 64;      // width of the data fields
  parameter AWUSER_WIDTH    = 32;      // width of the user aw sideband field
  parameter WUSER_WIDTH     = 32;      // width of the user w sideband field
  parameter BUSER_WIDTH     = 32;      // width of the user b sideband field
  parameter ARUSER_WIDTH    = 32;      // width of the user ar sideband field
  parameter RUSER_WIDTH     = 32;      // width of the user r sideband field
  parameter AW_HNDSHK_MODE  = `RS_REGD;// write address channel handshake mode
  parameter W_HNDSHK_MODE   = `RS_REGD;// write channel handshake mode
  parameter B_HNDSHK_MODE   = `RS_REGD;// write response channel handshake mode
  parameter AR_HNDSHK_MODE  = `RS_REGD;// read address  channel handshake mode
  parameter R_HNDSHK_MODE   = `RS_REGD;// read channel handshake mode
  parameter ADDR_WIDTH      = 32;      // width of the Address field

  // calculated parameters
  parameter ID_MAX          = (ID_WIDTH - 1);
  parameter DATA_MAX        = (DATA_WIDTH - 1);
  parameter STRB_WIDTH      = (DATA_WIDTH / 8);
  parameter STRB_MAX        = (STRB_WIDTH - 1);
  parameter AWUSER_MAX      = (AWUSER_WIDTH - 1);
  parameter WUSER_MAX       = (WUSER_WIDTH - 1);
  parameter BUSER_MAX       = (BUSER_WIDTH - 1);
  parameter ARUSER_MAX      = (ARUSER_WIDTH - 1);
  parameter RUSER_MAX       = (RUSER_WIDTH - 1);
  parameter ADDR_MAX        = (ADDR_WIDTH - 1);
   
  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  input                 aresetn;          // axi reset
  input                 aclk;             // axi clock

  // slave port write address channel interface
  input [ID_MAX:0]      awids;            // id field
  input [ADDR_MAX:0]    awaddrs;          // address field
  input [3:0]           awlens;           // length field
  input [2:0]           awsizes;          // size field
  input [1:0]           awbursts;         // burst field
  input [1:0]           awlocks;          // lock field
  input [3:0]           awcaches;         // cache field
  input [2:0]           awprots;          // protection field
  input [AWUSER_MAX:0]  awusers;          // user field
  input                 awvalids;         // transfer valid
  output                awreadys;         // ready for transfer

  // slave port write channel interface
  input [ID_MAX:0]      wids;             // id field
  input [DATA_MAX:0]    wdatas;           // data field
  input [STRB_MAX:0]    wstrbs;           // strobe field
  input [WUSER_MAX:0]   wusers;           // user field
  input                 wlasts;           // last field
  input                 wvalids;          // transfer valid
  output                wreadys;          // ready for transfer

  // slave port write response channel interface
  output [ID_MAX:0]     bids;             // id field
  output [1:0]          bresps;           // response field
  output [BUSER_MAX:0]  busers;           // user field
  output                bvalids;          // transfer valid
  input                 breadys;          // ready for transfer

  // slave port read address channel interface
  input [ID_MAX:0]      arids;            // id field
  input [ADDR_MAX:0]    araddrs;          // address field
  input [3:0]           arlens;           // length field
  input [2:0]           arsizes;          // size field
  input [1:0]           arbursts;         // burst field
  input [1:0]           arlocks;          // lock field
  input [3:0]           arcaches;         // cache field
  input [2:0]           arprots;          // protection field
  input [ARUSER_MAX:0]  arusers;          // user field
  input                 arvalids;         // transfer valid
  output                arreadys;         // ready for transfer

  // slave port read channel interface
  output [ID_MAX:0]     rids;             // id field
  output [DATA_MAX:0]   rdatas;           // data field
  output [1:0]          rresps;           // response field
  output [RUSER_MAX:0]  rusers;           // user field
  output                rlasts;           // last field
  output                rvalids;          // transfer valid
  input                 rreadys;          // ready for transfer

  // master port write address channel interface
  output [ID_MAX:0]     awidm;            // id field
  output [ADDR_MAX:0]   awaddrm;          // address field
  output [3:0]          awlenm;           // length field
  output [2:0]          awsizem;          // size field
  output [1:0]          awburstm;         // burst field
  output [1:0]          awlockm;          // lock field
  output [3:0]          awcachem;         // cache field
  output [2:0]          awprotm;          // protection field
  output [AWUSER_MAX:0] awuserm;          // user field
  output                awvalidm;         // transfer valid
  input                 awreadym;         // ready for transfer

  // master port write channel interface
  output [ID_MAX:0]     widm;             // id field
  output [DATA_MAX:0]   wdatam;           // data field
  output [STRB_MAX:0]   wstrbm;           // strobe field
  output [WUSER_MAX:0]  wuserm;           // user field
  output                wlastm;           // last field
  output                wvalidm;          // transfer valid
  input                 wreadym;          // ready for transfer

  // master port write response channel interface
  input [ID_MAX:0]      bidm;             // id field
  input [1:0]           brespm;           // response field
  input [BUSER_MAX:0]   buserm;           // user field
  input                 bvalidm;          // transfer valid
  output                breadym;          // ready for transfer

  // master port read address channel interface
  output [ID_MAX:0]     aridm;            // id field
  output [ADDR_MAX:0]   araddrm;          // address field
  output [3:0]          arlenm;           // length field
  output [2:0]          arsizem;          // size field
  output [1:0]          arburstm;         // burst field
  output [1:0]          arlockm;          // lock field
  output [3:0]          arcachem;         // cache field
  output [2:0]          arprotm;          // protection field
  output [ARUSER_MAX:0] aruserm;          // user field
  output                arvalidm;         // transfer valid
  input                 arreadym;         // ready for transfer

  // master port read channel interface
  input [ID_MAX:0]      ridm;             // id field
  input [DATA_MAX:0]    rdatam;           // data field
  input [1:0]           rrespm;           // response field
  input [RUSER_MAX:0]   ruserm;           // user field
  input                 rlastm;           // last field
  input                 rvalidm;          // transfer valid
  output                rreadym;          // ready for transfer

  // dummy scan interface
  input                 scanenable;       // dummy scan enable
  input                 scaninaclk;       // dummy scan chain input
  output                scanoutaclk;      // dummy scan chain output

  // ---------------------------------------------------------------------------
  //  Port type definitions
  // ---------------------------------------------------------------------------
  // global interconnect inputs
  wire                  aresetn;          // axi reset
  wire                  aclk;             // axi clock

  // slave port write address channel interface
  wire [ID_MAX:0]       awids;            // id field
  wire [ADDR_MAX:0]     awaddrs;          // address field
  wire [3:0]            awlens;           // length field
  wire [2:0]            awsizes;          // size field
  wire [1:0]            awbursts;         // burst field
  wire [1:0]            awlocks;          // lock field
  wire [3:0]            awcaches;         // cache field
  wire [2:0]            awprots;          // protection field
  wire [AWUSER_MAX:0]   awusers;          // user field
  wire                  awvalids;         // transfer valid
  wire                  awreadys;         // ready for transfer

  // slave port write channel interface
  wire [ID_MAX:0]       wids;             // id field
  wire [DATA_MAX:0]     wdatas;           // data field
  wire [STRB_MAX:0]     wstrbs;           // strobe field
  wire [WUSER_MAX:0]    wusers;           // user field
  wire                  wlasts;           // last field
  wire                  wvalids;          // transfer valid
  wire                  wreadys;          // ready for transfer

  // slave port write response channel interface
  wire [ID_MAX:0]       bids;             // id field
  wire [1:0]            bresps;           // response field
  wire [BUSER_MAX:0]    busers;           // user field
  wire                  bvalids;          // transfer valid
  wire                  breadys;          // ready for transfer

  // slave port read address channel interface
  wire [ID_MAX:0]       arids;            // id field
  wire [ADDR_MAX:0]     araddrs;          // address field
  wire [3:0]            arlens;           // length field
  wire [2:0]            arsizes;          // size field
  wire [1:0]            arbursts;         // burst field
  wire [1:0]            arlocks;          // lock field
  wire [3:0]            arcaches;         // cache field
  wire [2:0]            arprots;          // protection field
  wire [ARUSER_MAX:0]   arusers;          // user field
  wire                  arvalids;         // transfer valid
  wire                  arreadys;         // ready for transfer

  // slave port read channel interface
  wire [ID_MAX:0]       rids;             // id field
  wire [DATA_MAX:0]     rdatas;           // data field
  wire [1:0]            rresps;           // response field
  wire [RUSER_MAX:0]    rusers;           // user field
  wire                  rlasts;           // last field
  wire                  rvalids;          // transfer valid
  wire                  rreadys;          // ready for transfer

  // master port write address channel interface
  wire [ID_MAX:0]       awidm;            // id field
  wire [ADDR_MAX:0]     awaddrm;          // address field
  wire [3:0]            awlenm;           // length field
  wire [2:0]            awsizem;          // size field
  wire [1:0]            awburstm;         // burst field
  wire [1:0]            awlockm;          // lock field
  wire [3:0]            awcachem;         // cache field
  wire [2:0]            awprotm;          // protection field
  wire [AWUSER_MAX:0]   awuserm;          // user field
  wire                  awvalidm;         // transfer valid
  wire                  awreadym;         // ready for transfer

  // master port write channel interface
  wire [ID_MAX:0]       widm;             // id field
  wire [DATA_MAX:0]     wdatam;           // data field
  wire [STRB_MAX:0]     wstrbm;           // strobe field
  wire [WUSER_MAX:0]    wuserm;           // user field
  wire                  wlastm;           // last field
  wire                  wvalidm;          // transfer valid
  wire                  wreadym;          // ready for transfer

  // master port write response channel interface
  wire [ID_MAX:0]       bidm;             // id field
  wire [1:0]            brespm;           // response field
  wire [BUSER_MAX:0]    buserm;           // user field
  wire                  bvalidm;          // transfer valid
  wire                  breadym;          // ready for transfer

  // master port read address channel interface
  wire [ID_MAX:0]       aridm;            // id field
  wire [ADDR_MAX:0]     araddrm;          // address field
  wire [3:0]            arlenm;           // length field
  wire [2:0]            arsizem;          // size field
  wire [1:0]            arburstm;         // burst field
  wire [1:0]            arlockm;          // lock field
  wire [3:0]            arcachem;         // cache field
  wire [2:0]            arprotm;          // protection field
  wire [ARUSER_MAX:0]   aruserm;          // user field
  wire                  arvalidm;         // transfer valid
  wire                  arreadym;         // ready for transfer

  // master port read channel interface
  wire [ID_MAX:0]       ridm;             // id field
  wire [DATA_MAX:0]     rdatam;           // data field
  wire [1:0]            rrespm;           // response field
  wire [RUSER_MAX:0]    ruserm;           // user field
  wire                  rlastm;           // last field
  wire                  rvalidm;          // transfer valid
  wire                  rreadym;          // ready for transfer

  // dummy scan interface
  wire                  scanenable;       // dummy scan enable
  wire                  scaninaclk;       // dummy scan chain input
  wire                  scanoutaclk;      // dummy scan chain output

  // ---------------------------------------------------------------------------
  //  start of code
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  //  Write address channel register slice
  // ---------------------------------------------------------------------------
  nic400_ax_reg_slice_1 #(ID_WIDTH, AWUSER_WIDTH, AW_HNDSHK_MODE, ADDR_WIDTH) u_aw_reg_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // slave port interface
     .axids          (awids),
     .axaddrs        (awaddrs),
     .axlens         (awlens),
     .axsizes        (awsizes),
     .axbursts       (awbursts),
     .axlocks        (awlocks),
     .axcaches       (awcaches),
     .axprots        (awprots),
     .axusers        (awusers),
     .axvalids       (awvalids),
     .axreadys       (awreadys),

     // master port interface
     .axidm          (awidm),
     .axaddrm        (awaddrm),
     .axlenm         (awlenm),
     .axsizem        (awsizem),
     .axburstm       (awburstm),
     .axlockm        (awlockm),
     .axcachem       (awcachem),
     .axprotm        (awprotm),
     .axuserm        (awuserm),
     .axvalidm       (awvalidm),
     .axreadym       (awreadym)
     );

  // ---------------------------------------------------------------------------
  //  Write channel register slice
  // ---------------------------------------------------------------------------
  nic400_wr_reg_slice_1 #(ID_WIDTH, DATA_WIDTH, WUSER_WIDTH, W_HNDSHK_MODE) u_wr_reg_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // slave port interface
     .wids           (wids),
     .wdatas         (wdatas),
     .wstrbs         (wstrbs),
     .wusers         (wusers),
     .wlasts         (wlasts),
     .wvalids        (wvalids),
     .wreadys        (wreadys),

     // master port interface
     .widm           (widm),
     .wdatam         (wdatam),
     .wstrbm         (wstrbm),
     .wuserm         (wuserm),
     .wlastm         (wlastm),
     .wvalidm        (wvalidm),
     .wreadym        (wreadym)
     );

  // ---------------------------------------------------------------------------
  //  Write response channel register slice
  // ---------------------------------------------------------------------------
  nic400_buf_reg_slice_1 #(ID_WIDTH, BUSER_WIDTH, B_HNDSHK_MODE) u_buf_reg_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // slave port interface
     .bids           (bids),
     .bresps         (bresps),
     .busers         (busers),
     .bvalids        (bvalids),
     .breadys        (breadys),

     // master port interface
     .bidm           (bidm),
     .brespm         (brespm),
     .buserm         (buserm),
     .bvalidm        (bvalidm),
     .breadym        (breadym)
     );

  // ---------------------------------------------------------------------------
  //  Read address channel register slice
  // ---------------------------------------------------------------------------
  nic400_ax_reg_slice_1 #(ID_WIDTH, ARUSER_WIDTH, AR_HNDSHK_MODE, ADDR_WIDTH) u_ar_reg_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // slave port interface
     .axids          (arids),
     .axaddrs        (araddrs),
     .axlens         (arlens),
     .axsizes        (arsizes),
     .axbursts       (arbursts),
     .axlocks        (arlocks),
     .axcaches       (arcaches),
     .axprots        (arprots),
     .axusers        (arusers),
     .axvalids       (arvalids),
     .axreadys       (arreadys),

     // master port interface
     .axidm          (aridm),
     .axaddrm        (araddrm),
     .axlenm         (arlenm),
     .axsizem        (arsizem),
     .axburstm       (arburstm),
     .axlockm        (arlockm),
     .axcachem       (arcachem),
     .axprotm        (arprotm),
     .axuserm        (aruserm),
     .axvalidm       (arvalidm),
     .axreadym       (arreadym)
     );

  // ---------------------------------------------------------------------------
  //  Read channel register slice
  // ---------------------------------------------------------------------------
  nic400_rd_reg_slice_1 #(ID_WIDTH, DATA_WIDTH, RUSER_WIDTH, R_HNDSHK_MODE) u_rd_reg_slice
    (
     // global interconnect inputs
     .aresetn        (aresetn),
     .aclk           (aclk),

     // slave port interface
     .rids           (rids),
     .rdatas         (rdatas),
     .rresps         (rresps),
     .rusers         (rusers),
     .rlasts         (rlasts),
     .rvalids        (rvalids),
     .rreadys        (rreadys),

     // master port interface
     .ridm           (ridm),
     .rdatam         (rdatam),
     .rrespm         (rrespm),
     .ruserm         (ruserm),
     .rlastm         (rlastm),
     .rvalidm        (rvalidm),
     .rreadym        (rreadym)
     );

  //  ==========================================================================
  //  ovl Assertions
  //  ==========================================================================
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of AW_HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only AW_HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of AW_HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_aw_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((AW_HNDSHK_MODE == `RS_REGD         ) |
                    (AW_HNDSHK_MODE == `RS_FWD_REG      ) |
                    (AW_HNDSHK_MODE == `RS_REV_REG      ) |
                    (AW_HNDSHK_MODE == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

  
  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of W_HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only W_HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of W_HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_w_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((W_HNDSHK_MODE == `RS_REGD         ) |
                    (W_HNDSHK_MODE == `RS_FWD_REG      ) |
                    (W_HNDSHK_MODE == `RS_REV_REG      ) |
                    (W_HNDSHK_MODE == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

  
  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of B_HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only B_HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of B_HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_b_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((B_HNDSHK_MODE == `RS_REGD         ) |
                    (B_HNDSHK_MODE == `RS_FWD_REG      ) |
                    (B_HNDSHK_MODE == `RS_REV_REG      ) |
                    (B_HNDSHK_MODE == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

  
  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of AR_HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only AR_HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of AR_HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_ar_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((AR_HNDSHK_MODE == `RS_REGD         ) |
                    (AR_HNDSHK_MODE == `RS_FWD_REG      ) |
                    (AR_HNDSHK_MODE == `RS_REV_REG      ) |
                    (AR_HNDSHK_MODE == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

  
  //----------------------------------------------------------------------------
  // OVL_ASSERT: check the value of R_HNDSHK_MODE is set to a valid value
  //----------------------------------------------------------------------------
  // Only R_HNDSHK_MODE being set to 0, 1, 2 or 3 is supported
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL
  assert_proposition
    #(0, 1, "Error: value of R_HNDSHK_MODE must be 0, 1, 2 or 3")
      illegal_r_hndshk_mode_val
        (.reset_n (aresetn),
         .test_expr((R_HNDSHK_MODE == `RS_REGD         ) |
                    (R_HNDSHK_MODE == `RS_FWD_REG      ) |
                    (R_HNDSHK_MODE == `RS_REV_REG      ) |
                    (R_HNDSHK_MODE == `RS_STATIC_BYPASS)));
  // OVL_ASSERT_END

`endif

  // ---------------------------------------------------------------------------
endmodule

`include "reg_slice_axi_undefs.v"

