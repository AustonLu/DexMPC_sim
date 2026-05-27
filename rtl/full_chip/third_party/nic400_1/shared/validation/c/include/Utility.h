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
// Filename            : $RCSfile: Utility.h,v $
//
// Checked In          :  2014-02-25 14:55:35 +0000 (Tue, 25 Feb 2014)
//
// Revision            : 167698
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Environment variables:
//
//---------------------------------------------------------------------------


#ifndef UTILITY_H
#define UTILITY_H

//-------------------------------------------------------------------------
// Include files
//-------------------------------------------------------------------------

//-----------------------
// Standard include files
#include <iostream>
#include <cstring>
#include <cstdlib>
#include <fstream>
#include <string>
#include <iomanip>
#include <cstdio>
#include <map>

#include "arm_types.h"
#include "frbm_types.h"

//-----------------------
//
using namespace frbm_namespace;
using namespace arm_namespace;

//-----------------------
// Device specific include files

class Utility 
{
  public:

  //======================================================================
  // Methods
  //======================================================================

  //---------------------------------------------------------------------
  // Constructor
  //---------------------------------------------------------------------
  Utility();

  //---------------------------------------------------------------------
  // Destructor
  //---------------------------------------------------------------------
  ~Utility();

  //---------------------------------------------------------------------
  // Transfer
  //---------------------------------------------------------------------

  //---------------------------------------------------------------------
  // Display
  //---------------------------------------------------------------------

  //---------------------------------------------------------------------
  // Data
  //---------------------------------------------------------------------

  private:

  public: 

};
#endif
