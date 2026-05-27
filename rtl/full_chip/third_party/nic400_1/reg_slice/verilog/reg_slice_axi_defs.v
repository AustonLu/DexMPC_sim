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
//  Purpose             : Static definitions to control behaviour of the AXI
//                        Register Slice component
//
// --=========================================================================--

// -----------------------------------------------------------------------------
//  static definitions
// -----------------------------------------------------------------------------
`define RS_REGD            2'b00        // fully registered register slice
`define RS_FWD_REG         2'b01        // registered on forward path only
`define RS_REV_REG         2'b10        // registered on reverse path only
`define RS_STATIC_BYPASS   2'b11        // register slice bypass
