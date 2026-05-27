//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: UtilityAxi.h,v $
//
// Checked In          :  2014-02-25 14:55:35 +0000 (Tue, 25 Feb 2014)
//
// Revision            : 167698
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------


#ifndef UTILITY_APB_H
#define UTILITY_APB_H

//-------------------------------------------------------------------------
// Include files
//-------------------------------------------------------------------------

//-----------------------
// Standard include files

#include <iostream>
#include <cstring>
#include <cstdlib>
#include <fstream.h>
#include <string>
#include <iomanip.h>
#include "cstdio"
#include <map>

#include "arm_types.h"
#include "frbm_types.h"

//-----------------------
// Device specific include files
#include "Utility.h"

using namespace frbm_namespace;
using namespace arm_namespace;

class UtilityApb : public Utility
{
  public:

  //======================================================================
  // Methods
  //======================================================================

  //---------------------------------------------------------------------
  // Constructor
  //---------------------------------------------------------------------
  UtilityApb();

  //---------------------------------------------------------------------
  // Transfer
  //---------------------------------------------------------------------

  bool CheckTransfer(arm_uint32 Address, amba_length Length, amba_size Size, bool Msg=0);

  private:

};
#endif
