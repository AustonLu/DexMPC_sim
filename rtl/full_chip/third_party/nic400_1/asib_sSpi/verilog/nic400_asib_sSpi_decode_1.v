//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 195460
// File Date           :  2015-06-09 14:49:09 +0100 (Tue, 09 Jun 2015)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose             : This block takes incoming address and determines the
//                       destination for the transaction according to remap
//                       bits.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module Declaration
//------------------------------------------------------------------------------

module nic400_asib_sSpi_decode_1
  (
    addr_s,
    security62,
    security63,
    aprot,
    acache_in,
    acache_out,
    avalid_int
  );


  // ---------------------------------------------------------------------------
  //  Port definitions
  // ---------------------------------------------------------------------------

  input  [31:0]    addr_s;          // address field
  input            security62;
  input            security63;
  input            aprot;
  input  [3:0]     acache_in;
  output [3:0]     acache_out;
  output [2:0]     avalid_int;

  //------------------------------------------------------------------------
  // Wires
  //------------------------------------------------------------------------



  wire [1:0]       avalid_dec;
  wire [1:0]       decode_int;
  wire [1:0]       remap_decode;

  //------------------------------------------------------------------------
  // Registered values
  //------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // Start of code
  // ---------------------------------------------------------------------------



  // ---------------------------------------------------------------------------
  // address decode

  assign decode_int[0] = (32'h0 <= addr_s) && (addr_s <= 32'h7FFFF);

  assign decode_int[1] = (32'h80000 <= addr_s) && (addr_s <= 32'hFFFFF);



  // ---------------------------------------------------------------------------
  // remap decode


  assign remap_decode[0] = ~(aprot & security62) & decode_int[0];

  assign remap_decode[1] = ~(aprot & security63) & decode_int[1];


  // ---------------------------------------------------------------------------
  // valid vect decode

  assign avalid_dec[0] = ((remap_decode[1]));
  assign avalid_dec[1] = ((remap_decode[0]));
  assign avalid_int[2] = (~|avalid_int[1:0]);

  assign avalid_int[1:0] = avalid_dec;




  // ---------------------------------------------------------------------------
  // ACACHE mapping

  assign acache_out = acache_in;


  //------------------------------------------------------------------------
  // OVL_ASSERT:
  //------------------------------------------------------------------------
// synopsys translate_off


// synopsys translate_on


endmodule

