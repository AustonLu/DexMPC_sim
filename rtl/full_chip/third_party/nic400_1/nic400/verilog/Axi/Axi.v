//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2001-2009 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//------------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision       : 66413
// File Date           :  2009-07-16 17:57:26 +0100 (Thu, 16 Jul 2009)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
//  Purpose             : Standard AXI defines
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// AXI Constants
//------------------------------------------------------------------------------

// ALEN Encoding
`define AXI_ALEN_1            4'b0000
`define AXI_ALEN_2            4'b0001
`define AXI_ALEN_3            4'b0010
`define AXI_ALEN_4            4'b0011
`define AXI_ALEN_5            4'b0100
`define AXI_ALEN_6            4'b0101
`define AXI_ALEN_7            4'b0110
`define AXI_ALEN_8            4'b0111
`define AXI_ALEN_9            4'b1000
`define AXI_ALEN_10           4'b1001
`define AXI_ALEN_11           4'b1010
`define AXI_ALEN_12           4'b1011
`define AXI_ALEN_13           4'b1100
`define AXI_ALEN_14           4'b1101
`define AXI_ALEN_15           4'b1110
`define AXI_ALEN_16           4'b1111

// ASIZE Enconding
`define AXI_ASIZE_8           3'b000
`define AXI_ASIZE_16          3'b001
`define AXI_ASIZE_32          3'b010
`define AXI_ASIZE_64          3'b011
`define AXI_ASIZE_128         3'b100
`define AXI_ASIZE_256         3'b101
`define AXI_ASIZE_512         3'b110
`define AXI_ASIZE_1024        3'b111

// ABURST Encoding
`define AXI_ABURST_FIXED      2'b00
`define AXI_ABURST_INCR       2'b01
`define AXI_ABURST_WRAP       2'b10

// ALOCK Encoding
`define AXI_ALOCK_NOLOCK      2'b00
`define AXI_ALOCK_EXCL        2'b01
`define AXI_ALOCK_LOCKED      2'b10

// RRESP / BRESP Encoding
`define AXI_RESP_OKAY         2'b00
`define AXI_RESP_EXOKAY       2'b01
`define AXI_RESP_SLVERR       2'b10
`define AXI_RESP_DECERR       2'b11

// --========================= End ===========================================--
