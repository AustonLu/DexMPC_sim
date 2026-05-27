//------------------------------------------------------------------------------
// This confidential and proprietary software may be used only as
// authorised by a licensing agreement from ARM Limited
//   (C) COPYRIGHT 2012 ARM Limited
//       ALL RIGHTS RESERVED
// The entire notice above must be reproduced on all authorised
// copies and copies may only be made to the extent permitted
// by a licensing agreement from ARM Limited.
//------------------------------------------------------------------------------
//
// Version and Release Control Information:
//
// File Revision          : 125197
// File Date              :  2012-02-14 22:06:55 +0000 (Tue, 14 Feb 2012)
//
// Release Information    : PL401-r1p2-00rel0
//
//------------------------------------------------------------------------------
// Purpose: Muxes together two internal AXI-C channels
//------------------------------------------------------------------------------

module axi_c_mux
(
  m0_cactive,
  m0_cactive_wakeup,
  m0_port_enable,
  m1_cactive,
  m1_cactive_wakeup,
  m1_port_enable,
  s_cactive,
  s_cactive_wakeup,
  s_port_enable
);


//------------------------------------------------------------------------------
// Ports
//------------------------------------------------------------------------------

  // Master 0
  input  m0_cactive;
  input  m0_cactive_wakeup;
  output m0_port_enable;

  // Master 1
  input  m1_cactive;
  input  m1_cactive_wakeup;
  output m1_port_enable;

  // Slave
  output s_cactive;
  output s_cactive_wakeup;
  input  s_port_enable;


//------------------------------------------------------------------------------
// Main code
//------------------------------------------------------------------------------

  assign s_cactive = m0_cactive | m1_cactive;

  assign s_cactive_wakeup = m0_cactive_wakeup | m1_cactive_wakeup;

  assign m0_port_enable = s_port_enable;
  assign m1_port_enable = s_port_enable;


endmodule  // axi_c_mux

//--------------------------------- End of File --------------------------------
