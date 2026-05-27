//============================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//    (C) COPYRIGHT 2011-2012 ARM Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 129097
//
// Date                   :  2012-04-26 14:19:12 +0100 (Thu, 26 Apr 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
//  Purpose             : Wrapper for AXI4 Protocol Checker
//============================================================================--


`timescale 1ns/1ns

module NIC400_Axi4PC
  (
   // Global Signals
   ACLK,
   ARESETn,

   // Write Address Channel
   AWVALID_VECT,
   AWVALID,
   AWREADY,
   AWID,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
   AWQOS,
   AWREGION,
   AWUSER,

   // Write Channel
   WVALID,
   WREADY,
   WLAST,
   WDATA,
   WSTRB,
   WUSER,

   // Write Response Channel
   BVALID,
   BREADY,
   BID,
   BRESP,
   BUSER,

   // Read Address Channel
   ARVALID_VECT,
   ARVALID,
   ARREADY,
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
   ARQOS,
   ARREGION,
   ARUSER,

   // Read Channel
   RVALID,
   RREADY,
   RID,
   RLAST,
   RDATA,
   RRESP,
   RUSER,

   // Low power interface
   CACTIVE,
   CSYSREQ,
   CSYSACK
   );

//------------------------------------------------------------------------------
// INDEX:   1) Parameters
//------------------------------------------------------------------------------

  // INDEX:        - Configurable (user can set)
  // =====
  // Parameters below can be set by the user.

  parameter VALID_WIDTH = 1;

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH = 64;         // data bus width, default = 64-bit

  // Select the number of channel ID bits required
  parameter ID_WIDTH = 4;            // (A|W|R|B)ID width

  // Select the size of the USER buses, default = 32-bit
  parameter AWUSER_WIDTH = 32;       // width of the user AW sideband field
  parameter WUSER_WIDTH  = 32;       // width of the user W  sideband field
  parameter BUSER_WIDTH  = 32;       // width of the user B  sideband field
  parameter ARUSER_WIDTH = 32;       // width of the user AR sideband field
  parameter RUSER_WIDTH  = 32;       // width of the user R  sideband field

  // Size of CAMs for storing outstanding read bursts, this should match or
  // exceed the number of outstanding read addresses accepted into the slave
  // interface
  parameter MAXRBURSTS = 16;

  // Size of CAMs for storing outstanding write bursts, this should match or
  // exceed the number of outstanding write bursts into the slave  interface
  parameter MAXWBURSTS = 16;

  // Maximum number of cycles between VALID -> READY high before a warning is
  // generated
  parameter MAXWAITS = 16;

  parameter AXI_ERRL_PropertyType = 0; // default: assert LP Int is AXI compliant

  // Recommended Rules Enable
  // enable/disable reporting of all  AXI4_REC*_* rules
  parameter RecommendOn   = 1'b1;
  // enable/disable reporting of just AXI4_REC*_MAX_WAIT rules
  parameter RecMaxWaitOn  = 1'b1;

  // Set ADDR_WIDTH to the address-bus width required
  parameter ADDR_WIDTH = 32;        // address bus width, default = 32-bit

  // Set EXMON_WIDTH to the exclusive access monitor width required
  parameter EXMON_WIDTH = 4;        // exclusive access width, default = 4-bit

  //Specify that this is an internal port
  parameter PortIsInternal = 0;

  // INDEX:        - Calculated (user should not override)
  // =====
  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  parameter VALID_MAX  = VALID_WIDTH-1;
  parameter DATA_MAX   = DATA_WIDTH-1;              // data max index
  parameter ADDR_MAX   = ADDR_WIDTH-1;              // address max index
  parameter STRB_WIDTH = DATA_WIDTH/8;              // WSTRB width
  parameter STRB_MAX   = STRB_WIDTH-1;              // WSTRB max index
  parameter STRB_1     = {{STRB_MAX{1'b0}}, 1'b1};  // value 1 in strobe width
  parameter ID_MAX     = ID_WIDTH? ID_WIDTH-1:0;    // ID max index
  parameter EXMON_MAX  = EXMON_WIDTH-1;             // EXMON max index
  parameter EXMON_HI   = {EXMON_WIDTH{1'b1}};       // EXMON max value

  parameter AWUSER_MAX = AWUSER_WIDTH ? AWUSER_WIDTH-1:0; // AWUSER max index
  parameter WUSER_MAX  = WUSER_WIDTH ? WUSER_WIDTH-1:0;   // WUSER  max index
  parameter BUSER_MAX  = BUSER_WIDTH ? BUSER_WIDTH-1:0;   // BUSER  max index
  parameter ARUSER_MAX = ARUSER_WIDTH ? ARUSER_WIDTH-1:0; // ARUSER max index
  parameter RUSER_MAX  = RUSER_WIDTH ? RUSER_WIDTH-1:0;   // RUSER  max index


  // FLAG LO/HI STRB256..STRB1 ID BURST ASIZE ALEN EXCL ADDR[6:0]
  parameter ADDRLO   = 0;                 // ADDRLO   =   0
  parameter ADDRHI   = 6;                 // ADDRHI   =   6
  parameter EXCL     = ADDRHI + 1;        // Transaction is exclusive 7
  parameter ALENLO   = EXCL + 1;          // ALENLO   =   8
  parameter ALENHI   = ALENLO + 7;        // ALENHI   =  15
  parameter ASIZELO  = ALENHI + 1;        // ASIZELO  =  16
  parameter ASIZEHI  = ASIZELO + 2;       // ASIZEHI  =  18
  parameter BURSTLO  = ASIZEHI + 1;       // BURSTLO  =  19
  parameter BURSTHI  = BURSTLO + 1;       // BURSTHI  =  20
  parameter IDLO     = BURSTHI + 1;       // IDLO     =  21
  parameter IDHI     = IDLO+ID_MAX;
  parameter STRB1LO  = IDHI +1;
  parameter STRB1HI  = STRB1LO+STRB_MAX;
  parameter STRB2LO  = STRB1HI+1;
  parameter STRB2HI  = STRB2LO+STRB_MAX;
  parameter STRB3LO  = STRB2HI+1;
  parameter STRB3HI  = STRB3LO+STRB_MAX;
  parameter STRB4LO  = STRB3HI+1;
  parameter STRB4HI  = STRB4LO+STRB_MAX;
  parameter STRB5LO  = STRB4HI+1;
  parameter STRB5HI  = STRB5LO+STRB_MAX;
  parameter STRB6LO  = STRB5HI+1;
  parameter STRB6HI  = STRB6LO+STRB_MAX;
  parameter STRB7LO  = STRB6HI+1;
  parameter STRB7HI  = STRB7LO+STRB_MAX;
  parameter STRB8LO  = STRB7HI+1;
  parameter STRB8HI  = STRB8LO+STRB_MAX;
  parameter STRB9LO  = STRB8HI+1;
  parameter STRB9HI  = STRB9LO+STRB_MAX;
  parameter STRB10LO = STRB9HI+1;
  parameter STRB10HI = STRB10LO+STRB_MAX;
  parameter STRB11LO = STRB10HI+1;
  parameter STRB11HI = STRB11LO+STRB_MAX;
  parameter STRB12LO = STRB11HI+1;
  parameter STRB12HI = STRB12LO+STRB_MAX;
  parameter STRB13LO = STRB12HI+1;
  parameter STRB13HI = STRB13LO+STRB_MAX;
  parameter STRB14LO = STRB13HI+1;
  parameter STRB14HI = STRB14LO+STRB_MAX;
  parameter STRB15LO = STRB14HI+1;
  parameter STRB15HI = STRB15LO+STRB_MAX;
  parameter STRB16LO = STRB15HI+1;
  parameter STRB16HI = STRB16LO+STRB_MAX;
  parameter STRB17LO =  STRB16HI+1;
  parameter STRB17HI =  STRB17LO+STRB_MAX;
  parameter STRB18LO =  STRB17HI+1;
  parameter STRB18HI =  STRB18LO+STRB_MAX;
  parameter STRB19LO =  STRB18HI+1;
  parameter STRB19HI =  STRB19LO+STRB_MAX;
  parameter STRB20LO =  STRB19HI+1;
  parameter STRB20HI =  STRB20LO+STRB_MAX;
  parameter STRB21LO =  STRB20HI+1;
  parameter STRB21HI =  STRB21LO+STRB_MAX;
  parameter STRB22LO =  STRB21HI+1;
  parameter STRB22HI =  STRB22LO+STRB_MAX;
  parameter STRB23LO =  STRB22HI+1;
  parameter STRB23HI =  STRB23LO+STRB_MAX;
  parameter STRB24LO =  STRB23HI+1;
  parameter STRB24HI =  STRB24LO+STRB_MAX;
  parameter STRB25LO =  STRB24HI+1;
  parameter STRB25HI =  STRB25LO+STRB_MAX;
  parameter STRB26LO =  STRB25HI+1;
  parameter STRB26HI =  STRB26LO+STRB_MAX;
  parameter STRB27LO =  STRB26HI+1;
  parameter STRB27HI =  STRB27LO+STRB_MAX;
  parameter STRB28LO =  STRB27HI+1;
  parameter STRB28HI =  STRB28LO+STRB_MAX;
  parameter STRB29LO =  STRB28HI+1;
  parameter STRB29HI =  STRB29LO+STRB_MAX;
  parameter STRB30LO =  STRB29HI+1;
  parameter STRB30HI =  STRB30LO+STRB_MAX;
  parameter STRB31LO =  STRB30HI+1;
  parameter STRB31HI =  STRB31LO+STRB_MAX;
  parameter STRB32LO =  STRB31HI+1;
  parameter STRB32HI =  STRB32LO+STRB_MAX;
  parameter STRB33LO =  STRB32HI+1;
  parameter STRB33HI =  STRB33LO+STRB_MAX;
  parameter STRB34LO =  STRB33HI+1;
  parameter STRB34HI =  STRB34LO+STRB_MAX;
  parameter STRB35LO =  STRB34HI+1;
  parameter STRB35HI =  STRB35LO+STRB_MAX;
  parameter STRB36LO =  STRB35HI+1;
  parameter STRB36HI =  STRB36LO+STRB_MAX;
  parameter STRB37LO =  STRB36HI+1;
  parameter STRB37HI =  STRB37LO+STRB_MAX;
  parameter STRB38LO =  STRB37HI+1;
  parameter STRB38HI =  STRB38LO+STRB_MAX;
  parameter STRB39LO =  STRB38HI+1;
  parameter STRB39HI =  STRB39LO+STRB_MAX;
  parameter STRB40LO =  STRB39HI+1;
  parameter STRB40HI =  STRB40LO+STRB_MAX;
  parameter STRB41LO =  STRB40HI+1;
  parameter STRB41HI =  STRB41LO+STRB_MAX;
  parameter STRB42LO =  STRB41HI+1;
  parameter STRB42HI =  STRB42LO+STRB_MAX;
  parameter STRB43LO =  STRB42HI+1;
  parameter STRB43HI =  STRB43LO+STRB_MAX;
  parameter STRB44LO =  STRB43HI+1;
  parameter STRB44HI =  STRB44LO+STRB_MAX;
  parameter STRB45LO =  STRB44HI+1;
  parameter STRB45HI =  STRB45LO+STRB_MAX;
  parameter STRB46LO =  STRB45HI+1;
  parameter STRB46HI =  STRB46LO+STRB_MAX;
  parameter STRB47LO =  STRB46HI+1;
  parameter STRB47HI =  STRB47LO+STRB_MAX;
  parameter STRB48LO =  STRB47HI+1;
  parameter STRB48HI =  STRB48LO+STRB_MAX;
  parameter STRB49LO =  STRB48HI+1;
  parameter STRB49HI =  STRB49LO+STRB_MAX;
  parameter STRB50LO =  STRB49HI+1;
  parameter STRB50HI =  STRB50LO+STRB_MAX;
  parameter STRB51LO =  STRB50HI+1;
  parameter STRB51HI =  STRB51LO+STRB_MAX;
  parameter STRB52LO =  STRB51HI+1;
  parameter STRB52HI =  STRB52LO+STRB_MAX;
  parameter STRB53LO =  STRB52HI+1;
  parameter STRB53HI =  STRB53LO+STRB_MAX;
  parameter STRB54LO =  STRB53HI+1;
  parameter STRB54HI =  STRB54LO+STRB_MAX;
  parameter STRB55LO =  STRB54HI+1;
  parameter STRB55HI =  STRB55LO+STRB_MAX;
  parameter STRB56LO =  STRB55HI+1;
  parameter STRB56HI =  STRB56LO+STRB_MAX;
  parameter STRB57LO =  STRB56HI+1;
  parameter STRB57HI =  STRB57LO+STRB_MAX;
  parameter STRB58LO =  STRB57HI+1;
  parameter STRB58HI =  STRB58LO+STRB_MAX;
  parameter STRB59LO =  STRB58HI+1;
  parameter STRB59HI =  STRB59LO+STRB_MAX;
  parameter STRB60LO =  STRB59HI+1;
  parameter STRB60HI =  STRB60LO+STRB_MAX;
  parameter STRB61LO =  STRB60HI+1;
  parameter STRB61HI =  STRB61LO+STRB_MAX;
  parameter STRB62LO =  STRB61HI+1;
  parameter STRB62HI =  STRB62LO+STRB_MAX;
  parameter STRB63LO =  STRB62HI+1;
  parameter STRB63HI =  STRB63LO+STRB_MAX;
  parameter STRB64LO =  STRB63HI+1;
  parameter STRB64HI =  STRB64LO+STRB_MAX;
  parameter STRB65LO =  STRB64HI+1;
  parameter STRB65HI =  STRB65LO+STRB_MAX;
  parameter STRB66LO =  STRB65HI+1;
  parameter STRB66HI =  STRB66LO+STRB_MAX;
  parameter STRB67LO =  STRB66HI+1;
  parameter STRB67HI =  STRB67LO+STRB_MAX;
  parameter STRB68LO =  STRB67HI+1;
  parameter STRB68HI =  STRB68LO+STRB_MAX;
  parameter STRB69LO =  STRB68HI+1;
  parameter STRB69HI =  STRB69LO+STRB_MAX;
  parameter STRB70LO =  STRB69HI+1;
  parameter STRB70HI =  STRB70LO+STRB_MAX;
  parameter STRB71LO =  STRB70HI+1;
  parameter STRB71HI =  STRB71LO+STRB_MAX;
  parameter STRB72LO =  STRB71HI+1;
  parameter STRB72HI =  STRB72LO+STRB_MAX;
  parameter STRB73LO =  STRB72HI+1;
  parameter STRB73HI =  STRB73LO+STRB_MAX;
  parameter STRB74LO =  STRB73HI+1;
  parameter STRB74HI =  STRB74LO+STRB_MAX;
  parameter STRB75LO =  STRB74HI+1;
  parameter STRB75HI =  STRB75LO+STRB_MAX;
  parameter STRB76LO =  STRB75HI+1;
  parameter STRB76HI =  STRB76LO+STRB_MAX;
  parameter STRB77LO =  STRB76HI+1;
  parameter STRB77HI =  STRB77LO+STRB_MAX;
  parameter STRB78LO =  STRB77HI+1;
  parameter STRB78HI =  STRB78LO+STRB_MAX;
  parameter STRB79LO =  STRB78HI+1;
  parameter STRB79HI =  STRB79LO+STRB_MAX;
  parameter STRB80LO =  STRB79HI+1;
  parameter STRB80HI =  STRB80LO+STRB_MAX;
  parameter STRB81LO =  STRB80HI+1;
  parameter STRB81HI =  STRB81LO+STRB_MAX;
  parameter STRB82LO =  STRB81HI+1;
  parameter STRB82HI =  STRB82LO+STRB_MAX;
  parameter STRB83LO =  STRB82HI+1;
  parameter STRB83HI =  STRB83LO+STRB_MAX;
  parameter STRB84LO =  STRB83HI+1;
  parameter STRB84HI =  STRB84LO+STRB_MAX;
  parameter STRB85LO =  STRB84HI+1;
  parameter STRB85HI =  STRB85LO+STRB_MAX;
  parameter STRB86LO =  STRB85HI+1;
  parameter STRB86HI =  STRB86LO+STRB_MAX;
  parameter STRB87LO =  STRB86HI+1;
  parameter STRB87HI =  STRB87LO+STRB_MAX;
  parameter STRB88LO =  STRB87HI+1;
  parameter STRB88HI =  STRB88LO+STRB_MAX;
  parameter STRB89LO =  STRB88HI+1;
  parameter STRB89HI =  STRB89LO+STRB_MAX;
  parameter STRB90LO =  STRB89HI+1;
  parameter STRB90HI =  STRB90LO+STRB_MAX;
  parameter STRB91LO =  STRB90HI+1;
  parameter STRB91HI =  STRB91LO+STRB_MAX;
  parameter STRB92LO =  STRB91HI+1;
  parameter STRB92HI =  STRB92LO+STRB_MAX;
  parameter STRB93LO =  STRB92HI+1;
  parameter STRB93HI =  STRB93LO+STRB_MAX;
  parameter STRB94LO =  STRB93HI+1;
  parameter STRB94HI =  STRB94LO+STRB_MAX;
  parameter STRB95LO =  STRB94HI+1;
  parameter STRB95HI =  STRB95LO+STRB_MAX;
  parameter STRB96LO =  STRB95HI+1;
  parameter STRB96HI =  STRB96LO+STRB_MAX;
  parameter STRB97LO =  STRB96HI+1;
  parameter STRB97HI =  STRB97LO+STRB_MAX;
  parameter STRB98LO =  STRB97HI+1;
  parameter STRB98HI =  STRB98LO+STRB_MAX;
  parameter STRB99LO =  STRB98HI+1;
  parameter STRB99HI =  STRB99LO+STRB_MAX;
  parameter STRB100LO = STRB99HI+1;
  parameter STRB100HI = STRB100LO+STRB_MAX;
  parameter STRB101LO = STRB100HI+1;
  parameter STRB101HI = STRB101LO+STRB_MAX;
  parameter STRB102LO = STRB101HI+1;
  parameter STRB102HI = STRB102LO+STRB_MAX;
  parameter STRB103LO = STRB102HI+1;
  parameter STRB103HI = STRB103LO+STRB_MAX;
  parameter STRB104LO = STRB103HI+1;
  parameter STRB104HI = STRB104LO+STRB_MAX;
  parameter STRB105LO = STRB104HI+1;
  parameter STRB105HI = STRB105LO+STRB_MAX;
  parameter STRB106LO = STRB105HI+1;
  parameter STRB106HI = STRB106LO+STRB_MAX;
  parameter STRB107LO = STRB106HI+1;
  parameter STRB107HI = STRB107LO+STRB_MAX;
  parameter STRB108LO = STRB107HI+1;
  parameter STRB108HI = STRB108LO+STRB_MAX;
  parameter STRB109LO = STRB108HI+1;
  parameter STRB109HI = STRB109LO+STRB_MAX;
  parameter STRB110LO = STRB109HI+1;
  parameter STRB110HI = STRB110LO+STRB_MAX;
  parameter STRB111LO = STRB110HI+1;
  parameter STRB111HI = STRB111LO+STRB_MAX;
  parameter STRB112LO = STRB111HI+1;
  parameter STRB112HI = STRB112LO+STRB_MAX;
  parameter STRB113LO = STRB112HI+1;
  parameter STRB113HI = STRB113LO+STRB_MAX;
  parameter STRB114LO = STRB113HI+1;
  parameter STRB114HI = STRB114LO+STRB_MAX;
  parameter STRB115LO = STRB114HI+1;
  parameter STRB115HI = STRB115LO+STRB_MAX;
  parameter STRB116LO = STRB115HI+1;
  parameter STRB116HI = STRB116LO+STRB_MAX;
  parameter STRB117LO = STRB116HI+1;
  parameter STRB117HI = STRB117LO+STRB_MAX;
  parameter STRB118LO = STRB117HI+1;
  parameter STRB118HI = STRB118LO+STRB_MAX;
  parameter STRB119LO = STRB118HI+1;
  parameter STRB119HI = STRB119LO+STRB_MAX;
  parameter STRB120LO = STRB119HI+1;
  parameter STRB120HI = STRB120LO+STRB_MAX;
  parameter STRB121LO = STRB120HI+1;
  parameter STRB121HI = STRB121LO+STRB_MAX;
  parameter STRB122LO = STRB121HI+1;
  parameter STRB122HI = STRB122LO+STRB_MAX;
  parameter STRB123LO = STRB122HI+1;
  parameter STRB123HI = STRB123LO+STRB_MAX;
  parameter STRB124LO = STRB123HI+1;
  parameter STRB124HI = STRB124LO+STRB_MAX;
  parameter STRB125LO = STRB124HI+1;
  parameter STRB125HI = STRB125LO+STRB_MAX;
  parameter STRB126LO = STRB125HI+1;
  parameter STRB126HI = STRB126LO+STRB_MAX;
  parameter STRB127LO = STRB126HI+1;
  parameter STRB127HI = STRB127LO+STRB_MAX;
  parameter STRB128LO = STRB127HI+1;
  parameter STRB128HI = STRB128LO+STRB_MAX;
  parameter STRB129LO = STRB128HI+1;
  parameter STRB129HI = STRB129LO+STRB_MAX;
  parameter STRB130LO = STRB129HI+1;
  parameter STRB130HI = STRB130LO+STRB_MAX;
  parameter STRB131LO = STRB130HI+1;
  parameter STRB131HI = STRB131LO+STRB_MAX;
  parameter STRB132LO = STRB131HI+1;
  parameter STRB132HI = STRB132LO+STRB_MAX;
  parameter STRB133LO = STRB132HI+1;
  parameter STRB133HI = STRB133LO+STRB_MAX;
  parameter STRB134LO = STRB133HI+1;
  parameter STRB134HI = STRB134LO+STRB_MAX;
  parameter STRB135LO = STRB134HI+1;
  parameter STRB135HI = STRB135LO+STRB_MAX;
  parameter STRB136LO = STRB135HI+1;
  parameter STRB136HI = STRB136LO+STRB_MAX;
  parameter STRB137LO = STRB136HI+1;
  parameter STRB137HI = STRB137LO+STRB_MAX;
  parameter STRB138LO = STRB137HI+1;
  parameter STRB138HI = STRB138LO+STRB_MAX;
  parameter STRB139LO = STRB138HI+1;
  parameter STRB139HI = STRB139LO+STRB_MAX;
  parameter STRB140LO = STRB139HI+1;
  parameter STRB140HI = STRB140LO+STRB_MAX;
  parameter STRB141LO = STRB140HI+1;
  parameter STRB141HI = STRB141LO+STRB_MAX;
  parameter STRB142LO = STRB141HI+1;
  parameter STRB142HI = STRB142LO+STRB_MAX;
  parameter STRB143LO = STRB142HI+1;
  parameter STRB143HI = STRB143LO+STRB_MAX;
  parameter STRB144LO = STRB143HI+1;
  parameter STRB144HI = STRB144LO+STRB_MAX;
  parameter STRB145LO = STRB144HI+1;
  parameter STRB145HI = STRB145LO+STRB_MAX;
  parameter STRB146LO = STRB145HI+1;
  parameter STRB146HI = STRB146LO+STRB_MAX;
  parameter STRB147LO = STRB146HI+1;
  parameter STRB147HI = STRB147LO+STRB_MAX;
  parameter STRB148LO = STRB147HI+1;
  parameter STRB148HI = STRB148LO+STRB_MAX;
  parameter STRB149LO = STRB148HI+1;
  parameter STRB149HI = STRB149LO+STRB_MAX;
  parameter STRB150LO = STRB149HI+1;
  parameter STRB150HI = STRB150LO+STRB_MAX;
  parameter STRB151LO = STRB150HI+1;
  parameter STRB151HI = STRB151LO+STRB_MAX;
  parameter STRB152LO = STRB151HI+1;
  parameter STRB152HI = STRB152LO+STRB_MAX;
  parameter STRB153LO = STRB152HI+1;
  parameter STRB153HI = STRB153LO+STRB_MAX;
  parameter STRB154LO = STRB153HI+1;
  parameter STRB154HI = STRB154LO+STRB_MAX;
  parameter STRB155LO = STRB154HI+1;
  parameter STRB155HI = STRB155LO+STRB_MAX;
  parameter STRB156LO = STRB155HI+1;
  parameter STRB156HI = STRB156LO+STRB_MAX;
  parameter STRB157LO = STRB156HI+1;
  parameter STRB157HI = STRB157LO+STRB_MAX;
  parameter STRB158LO = STRB157HI+1;
  parameter STRB158HI = STRB158LO+STRB_MAX;
  parameter STRB159LO = STRB158HI+1;
  parameter STRB159HI = STRB159LO+STRB_MAX;
  parameter STRB160LO = STRB159HI+1;
  parameter STRB160HI = STRB160LO+STRB_MAX;
  parameter STRB161LO = STRB160HI+1;
  parameter STRB161HI = STRB161LO+STRB_MAX;
  parameter STRB162LO = STRB161HI+1;
  parameter STRB162HI = STRB162LO+STRB_MAX;
  parameter STRB163LO = STRB162HI+1;
  parameter STRB163HI = STRB163LO+STRB_MAX;
  parameter STRB164LO = STRB163HI+1;
  parameter STRB164HI = STRB164LO+STRB_MAX;
  parameter STRB165LO = STRB164HI+1;
  parameter STRB165HI = STRB165LO+STRB_MAX;
  parameter STRB166LO = STRB165HI+1;
  parameter STRB166HI = STRB166LO+STRB_MAX;
  parameter STRB167LO = STRB166HI+1;
  parameter STRB167HI = STRB167LO+STRB_MAX;
  parameter STRB168LO = STRB167HI+1;
  parameter STRB168HI = STRB168LO+STRB_MAX;
  parameter STRB169LO = STRB168HI+1;
  parameter STRB169HI = STRB169LO+STRB_MAX;
  parameter STRB170LO = STRB169HI+1;
  parameter STRB170HI = STRB170LO+STRB_MAX;
  parameter STRB171LO = STRB170HI+1;
  parameter STRB171HI = STRB171LO+STRB_MAX;
  parameter STRB172LO = STRB171HI+1;
  parameter STRB172HI = STRB172LO+STRB_MAX;
  parameter STRB173LO = STRB172HI+1;
  parameter STRB173HI = STRB173LO+STRB_MAX;
  parameter STRB174LO = STRB173HI+1;
  parameter STRB174HI = STRB174LO+STRB_MAX;
  parameter STRB175LO = STRB174HI+1;
  parameter STRB175HI = STRB175LO+STRB_MAX;
  parameter STRB176LO = STRB175HI+1;
  parameter STRB176HI = STRB176LO+STRB_MAX;
  parameter STRB177LO = STRB176HI+1;
  parameter STRB177HI = STRB177LO+STRB_MAX;
  parameter STRB178LO = STRB177HI+1;
  parameter STRB178HI = STRB178LO+STRB_MAX;
  parameter STRB179LO = STRB178HI+1;
  parameter STRB179HI = STRB179LO+STRB_MAX;
  parameter STRB180LO = STRB179HI+1;
  parameter STRB180HI = STRB180LO+STRB_MAX;
  parameter STRB181LO = STRB180HI+1;
  parameter STRB181HI = STRB181LO+STRB_MAX;
  parameter STRB182LO = STRB181HI+1;
  parameter STRB182HI = STRB182LO+STRB_MAX;
  parameter STRB183LO = STRB182HI+1;
  parameter STRB183HI = STRB183LO+STRB_MAX;
  parameter STRB184LO = STRB183HI+1;
  parameter STRB184HI = STRB184LO+STRB_MAX;
  parameter STRB185LO = STRB184HI+1;
  parameter STRB185HI = STRB185LO+STRB_MAX;
  parameter STRB186LO = STRB185HI+1;
  parameter STRB186HI = STRB186LO+STRB_MAX;
  parameter STRB187LO = STRB186HI+1;
  parameter STRB187HI = STRB187LO+STRB_MAX;
  parameter STRB188LO = STRB187HI+1;
  parameter STRB188HI = STRB188LO+STRB_MAX;
  parameter STRB189LO = STRB188HI+1;
  parameter STRB189HI = STRB189LO+STRB_MAX;
  parameter STRB190LO = STRB189HI+1;
  parameter STRB190HI = STRB190LO+STRB_MAX;
  parameter STRB191LO = STRB190HI+1;
  parameter STRB191HI = STRB191LO+STRB_MAX;
  parameter STRB192LO = STRB191HI+1;
  parameter STRB192HI = STRB192LO+STRB_MAX;
  parameter STRB193LO = STRB192HI+1;
  parameter STRB193HI = STRB193LO+STRB_MAX;
  parameter STRB194LO = STRB193HI+1;
  parameter STRB194HI = STRB194LO+STRB_MAX;
  parameter STRB195LO = STRB194HI+1;
  parameter STRB195HI = STRB195LO+STRB_MAX;
  parameter STRB196LO = STRB195HI+1;
  parameter STRB196HI = STRB196LO+STRB_MAX;
  parameter STRB197LO = STRB196HI+1;
  parameter STRB197HI = STRB197LO+STRB_MAX;
  parameter STRB198LO = STRB197HI+1;
  parameter STRB198HI = STRB198LO+STRB_MAX;
  parameter STRB199LO = STRB198HI+1;
  parameter STRB199HI = STRB199LO+STRB_MAX;
  parameter STRB200LO = STRB199HI+1;
  parameter STRB200HI = STRB200LO+STRB_MAX;
  parameter STRB201LO = STRB200HI+1;
  parameter STRB201HI = STRB201LO+STRB_MAX;
  parameter STRB202LO = STRB201HI+1;
  parameter STRB202HI = STRB202LO+STRB_MAX;
  parameter STRB203LO = STRB202HI+1;
  parameter STRB203HI = STRB203LO+STRB_MAX;
  parameter STRB204LO = STRB203HI+1;
  parameter STRB204HI = STRB204LO+STRB_MAX;
  parameter STRB205LO = STRB204HI+1;
  parameter STRB205HI = STRB205LO+STRB_MAX;
  parameter STRB206LO = STRB205HI+1;
  parameter STRB206HI = STRB206LO+STRB_MAX;
  parameter STRB207LO = STRB206HI+1;
  parameter STRB207HI = STRB207LO+STRB_MAX;
  parameter STRB208LO = STRB207HI+1;
  parameter STRB208HI = STRB208LO+STRB_MAX;
  parameter STRB209LO = STRB208HI+1;
  parameter STRB209HI = STRB209LO+STRB_MAX;
  parameter STRB210LO = STRB209HI+1;
  parameter STRB210HI = STRB210LO+STRB_MAX;
  parameter STRB211LO = STRB210HI+1;
  parameter STRB211HI = STRB211LO+STRB_MAX;
  parameter STRB212LO = STRB211HI+1;
  parameter STRB212HI = STRB212LO+STRB_MAX;
  parameter STRB213LO = STRB212HI+1;
  parameter STRB213HI = STRB213LO+STRB_MAX;
  parameter STRB214LO = STRB213HI+1;
  parameter STRB214HI = STRB214LO+STRB_MAX;
  parameter STRB215LO = STRB214HI+1;
  parameter STRB215HI = STRB215LO+STRB_MAX;
  parameter STRB216LO = STRB215HI+1;
  parameter STRB216HI = STRB216LO+STRB_MAX;
  parameter STRB217LO = STRB216HI+1;
  parameter STRB217HI = STRB217LO+STRB_MAX;
  parameter STRB218LO = STRB217HI+1;
  parameter STRB218HI = STRB218LO+STRB_MAX;
  parameter STRB219LO = STRB218HI+1;
  parameter STRB219HI = STRB219LO+STRB_MAX;
  parameter STRB220LO = STRB219HI+1;
  parameter STRB220HI = STRB220LO+STRB_MAX;
  parameter STRB221LO = STRB220HI+1;
  parameter STRB221HI = STRB221LO+STRB_MAX;
  parameter STRB222LO = STRB221HI+1;
  parameter STRB222HI = STRB222LO+STRB_MAX;
  parameter STRB223LO = STRB222HI+1;
  parameter STRB223HI = STRB223LO+STRB_MAX;
  parameter STRB224LO = STRB223HI+1;
  parameter STRB224HI = STRB224LO+STRB_MAX;
  parameter STRB225LO = STRB224HI+1;
  parameter STRB225HI = STRB225LO+STRB_MAX;
  parameter STRB226LO = STRB225HI+1;
  parameter STRB226HI = STRB226LO+STRB_MAX;
  parameter STRB227LO = STRB226HI+1;
  parameter STRB227HI = STRB227LO+STRB_MAX;
  parameter STRB228LO = STRB227HI+1;
  parameter STRB228HI = STRB228LO+STRB_MAX;
  parameter STRB229LO = STRB228HI+1;
  parameter STRB229HI = STRB229LO+STRB_MAX;
  parameter STRB230LO = STRB229HI+1;
  parameter STRB230HI = STRB230LO+STRB_MAX;
  parameter STRB231LO = STRB230HI+1;
  parameter STRB231HI = STRB231LO+STRB_MAX;
  parameter STRB232LO = STRB231HI+1;
  parameter STRB232HI = STRB232LO+STRB_MAX;
  parameter STRB233LO = STRB232HI+1;
  parameter STRB233HI = STRB233LO+STRB_MAX;
  parameter STRB234LO = STRB233HI+1;
  parameter STRB234HI = STRB234LO+STRB_MAX;
  parameter STRB235LO = STRB234HI+1;
  parameter STRB235HI = STRB235LO+STRB_MAX;
  parameter STRB236LO = STRB235HI+1;
  parameter STRB236HI = STRB236LO+STRB_MAX;
  parameter STRB237LO = STRB236HI+1;
  parameter STRB237HI = STRB237LO+STRB_MAX;
  parameter STRB238LO = STRB237HI+1;
  parameter STRB238HI = STRB238LO+STRB_MAX;
  parameter STRB239LO = STRB238HI+1;
  parameter STRB239HI = STRB239LO+STRB_MAX;
  parameter STRB240LO = STRB239HI+1;
  parameter STRB240HI = STRB240LO+STRB_MAX;
  parameter STRB241LO = STRB240HI+1;
  parameter STRB241HI = STRB241LO+STRB_MAX;
  parameter STRB242LO = STRB241HI+1;
  parameter STRB242HI = STRB242LO+STRB_MAX;
  parameter STRB243LO = STRB242HI+1;
  parameter STRB243HI = STRB243LO+STRB_MAX;
  parameter STRB244LO = STRB243HI+1;
  parameter STRB244HI = STRB244LO+STRB_MAX;
  parameter STRB245LO = STRB244HI+1;
  parameter STRB245HI = STRB245LO+STRB_MAX;
  parameter STRB246LO = STRB245HI+1;
  parameter STRB246HI = STRB246LO+STRB_MAX;
  parameter STRB247LO = STRB246HI+1;
  parameter STRB247HI = STRB247LO+STRB_MAX;
  parameter STRB248LO = STRB247HI+1;
  parameter STRB248HI = STRB248LO+STRB_MAX;
  parameter STRB249LO = STRB248HI+1;
  parameter STRB249HI = STRB249LO+STRB_MAX;
  parameter STRB250LO = STRB249HI+1;
  parameter STRB250HI = STRB250LO+STRB_MAX;
  parameter STRB251LO = STRB250HI+1;
  parameter STRB251HI = STRB251LO+STRB_MAX;
  parameter STRB252LO = STRB251HI+1;
  parameter STRB252HI = STRB252LO+STRB_MAX;
  parameter STRB253LO = STRB252HI+1;
  parameter STRB253HI = STRB253LO+STRB_MAX;
  parameter STRB254LO = STRB253HI+1;
  parameter STRB254HI = STRB254LO+STRB_MAX;
  parameter STRB255LO = STRB254HI+1;
  parameter STRB255HI = STRB255LO+STRB_MAX;
  parameter STRB256LO = STRB255HI+1;
  parameter STRB256HI = STRB256LO+STRB_MAX;

  parameter WBURSTMAX = STRB256HI+1; // Write burst register array maximum
  parameter RBURSTMAX = IDHI;        // Read burst register array maximum

  parameter allow_leading_rdata = 0;

//------------------------------------------------------------------------------
// INDEX:   2) Inputs (no outputs)
//------------------------------------------------------------------------------

  // INDEX:        - Global Signals
  // =====
  input                ACLK;        // AXI Clock
  input                ARESETn;     // AXI Reset

  // INDEX:        - Write Address Channel
  // =====
  input  [VALID_MAX:0] AWVALID_VECT;
  input                AWVALID;
  input                AWREADY;
  input     [ID_MAX:0] AWID;
  input   [ADDR_MAX:0] AWADDR;
  input          [7:0] AWLEN;
  input          [2:0] AWSIZE;
  input          [1:0] AWBURST;
  input          [3:0] AWCACHE;
  input          [2:0] AWPROT;
  input          [3:0] AWQOS;
  input          [3:0] AWREGION;
  input                AWLOCK;
  input [AWUSER_MAX:0] AWUSER;

  // INDEX:        - Write Data Channel
  // =====
  input   [DATA_MAX:0] WDATA;
  input   [STRB_MAX:0] WSTRB;
  input  [WUSER_MAX:0] WUSER;
  input                WLAST;
  input                WVALID;
  input                WREADY;

  // INDEX:        - Write Response Channel
  // =====
  input     [ID_MAX:0] BID;
  input          [1:0] BRESP;
  input  [BUSER_MAX:0] BUSER;
  input                BVALID;
  input                BREADY;

  // INDEX:        - Read Address Channel
  // =====
  input  [VALID_MAX:0] ARVALID_VECT;
  input                ARVALID;
  input                ARREADY;
  input     [ID_MAX:0] ARID;
  input   [ADDR_MAX:0] ARADDR;
  input          [7:0] ARLEN;
  input          [2:0] ARSIZE;
  input          [1:0] ARBURST;
  input          [3:0] ARCACHE;
  input          [3:0] ARQOS;
  input          [3:0] ARREGION;
  input          [2:0] ARPROT;
  input                ARLOCK;
  input [ARUSER_MAX:0] ARUSER;

  // INDEX:        - Read Data Channel
  // =====
  input     [ID_MAX:0] RID;
  input   [DATA_MAX:0] RDATA;
  input          [1:0] RRESP;
  input  [RUSER_MAX:0] RUSER;
  input                RLAST;
  input                RVALID;
  input                RREADY;

  // INDEX:        - Low Power Interface
  // =====
  input                CACTIVE;
  input                CSYSREQ;
  input                CSYSACK;

// ---------------------------------------------------------------------------
//  internal signals
// ---------------------------------------------------------------------------
  wire                ARREADY_int;
  wire                ARVALID_int;
  reg                 AR_in_progress;
  wire                nxt_AR_in_progress;

// ---------------------------------------------------------------------------
//  start of code
// ---------------------------------------------------------------------------

  wire [3:0]          AWQV = AWQOS;
  wire [3:0]          ARQV = ARQOS;

  assign nxt_AR_in_progress = ARVALID & ~ARREADY;

  always @(posedge ~ACLK or negedge ARESETn) begin
       if (~ARESETn) begin
          AR_in_progress <= 1'b0;
       end else begin
          AR_in_progress <= nxt_AR_in_progress;
       end
  end

  //If we are allowing leading read data (certain internal interfaces only)
  //Then ready every read on the first ARVALID cycle instead of the handshake
  assign ARREADY_int = (allow_leading_rdata) ? ARVALID & ~AR_in_progress : ARREADY;
  assign ARVALID_int = (allow_leading_rdata) ? ARVALID & ~AR_in_progress : ARVALID;

  defparam uAxiPC.DATA_WIDTH            = DATA_WIDTH;
  defparam uAxiPC.ID_WIDTH              = ID_WIDTH;
  defparam uAxiPC.AWUSER_WIDTH          = AWUSER_WIDTH;
  defparam uAxiPC.WUSER_WIDTH           = WUSER_WIDTH;
  defparam uAxiPC.BUSER_WIDTH           = BUSER_WIDTH;
  defparam uAxiPC.ARUSER_WIDTH          = ARUSER_WIDTH;
  defparam uAxiPC.RUSER_WIDTH           = RUSER_WIDTH;
  defparam uAxiPC.MAXRBURSTS            = MAXRBURSTS;
  defparam uAxiPC.MAXWBURSTS            = MAXWBURSTS;
  defparam uAxiPC.MAXWAITS              = MAXWAITS;
  defparam uAxiPC.RecommendOn           = RecommendOn;
  defparam uAxiPC.RecMaxWaitOn          = RecMaxWaitOn;
  defparam uAxiPC.ADDR_WIDTH            = ADDR_WIDTH;
  defparam uAxiPC.EXMON_WIDTH           = EXMON_WIDTH;

  Axi4PC uAxiPC (

      .ACLK           (~ACLK),
      .ARESETn        (ARESETn),

      .AWVALID        (AWVALID),
      .AWREADY        (AWREADY),
      .AWID           (AWID),
      .AWADDR         (AWADDR),
      .AWLEN          (AWLEN),
      .AWSIZE         (AWSIZE),
      .AWBURST        (AWBURST),
      .AWLOCK         (AWLOCK),
      .AWCACHE        ((PortIsInternal) ? 4'b0000 : AWCACHE),
      .AWPROT         (AWPROT),
      .AWREGION       (AWREGION),
      .AWQOS          (AWQOS),
      .AWUSER         (AWUSER),

      .WVALID         (WVALID),
      .WREADY         (WREADY),
      .WLAST          (WLAST),
      .WDATA          (WDATA),
      .WSTRB          (WSTRB),
      .WUSER          (WUSER),

      .BVALID         (BVALID),
      .BREADY         (BREADY),
      .BID            (BID),
      .BRESP          (BRESP),
      .BUSER          (BUSER),

      .ARVALID        (ARVALID_int),
      .ARREADY        (ARREADY_int),
      .ARID           (ARID),
      .ARADDR         (ARADDR),
      .ARLEN          (ARLEN),
      .ARSIZE         (ARSIZE),
      .ARBURST        (ARBURST),
      .ARLOCK         (ARLOCK),
      .ARCACHE        ((PortIsInternal) ? 4'b0000 : ARCACHE),
      .ARPROT         (ARPROT),
      .ARREGION       (ARREGION),
      .ARQOS          (ARQOS),
      .ARUSER         (ARUSER),

      .RVALID         (RVALID),
      .RREADY         (RREADY),
      .RID            (RID),
      .RLAST          (RLAST),
      .RDATA          (RDATA),
      .RRESP          (RRESP),
      .RUSER          (RUSER),

      .CACTIVE        (CACTIVE),
      .CSYSREQ        (CSYSREQ),
      .CSYSACK        (CSYSACK)
  );

endmodule // NIC400_Axi4PC
