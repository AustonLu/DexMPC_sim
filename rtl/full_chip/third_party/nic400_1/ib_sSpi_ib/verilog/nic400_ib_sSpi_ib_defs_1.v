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
// File Revision       : 127275
// File Date           :  2012-03-19 15:37:15 +0000 (Mon, 19 Mar 2012)
// Release Information : PL401-r1p2-00rel0
//------------------------------------------------------------------------------
// Purpose : HDL defines file for AMBA interface block
//           AUTOMATICALLY GENERATED, ONLY MODIFY MARKED SECTIONS
//------------------------------------------------------------------------------

// Reg Slice configuration defines
`define RS_REGD            0            // fully registered register slice
`define RS_FWD_REG         1            // registered on forward path only
`define RS_REV_REG         2            // registered on reverse path only
`define RS_STATIC_BYPASS   3            // register slice bypass

// slave_if_data_width  32
// slave_if_protocol    axi4

// master_if_data_width 64
// master_if_protocol   axi4
// AMBA upsizer defines
`define AWFIFO_BYPASS 0
`define AWFIFO_SIZE 3:1
`define AWFIFO_ADDR 6:4
`define AWFIFO_MASK 9:7
`define AWFIFO_WRAP_FITS 10
`define AWFIFO_LEN_TB  14:11
`define AWFIFO_UWRAP 15


`define ARDATA_SIZE 2:0
`define ARDATA_BYPASS 3
`define ARDATA_ADDR 6:4
`define ARDATA_MASK 9:7
`define ARDATA_END 12:10
`define ARDATA_ID 14:13
`define ARDATA_TWO 15:15
`define ARDATA_WRAP_FITS 16



//------------------------------------------------------------------------------
// End of File
//------------------------------------------------------------------------------

