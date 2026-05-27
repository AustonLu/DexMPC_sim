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
// Filename            : $RCSfile: DriveAhbPv.h,v $
//
// Checked In          :  2014-02-25 14:55:35 +0000 (Tue, 25 Feb 2014)
//
// Revision            : 167698
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: DriveAhbPv
//
//---------------------------------------------------------------------------

#ifndef AHBM_FRBM_MACRO_H
#define AHBM_FRBM_MACRO_H

#include <iostream>
#include <fstream>
#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <cassert>
#include <cstring>
#include <cstdlib>

#include "arm_types.h"

#include "frbm_types.h"

//#include "SimpleTest.h"
#include "FrbmMacro.h"

using namespace std;
using namespace arm_namespace;
using namespace frbm_namespace;


  class AhbMFrbmMacro : public FrbmMacro
  {
    public: 
 
    void  Access(transaction * trans);
    void  Read(transaction * trans);
    void  Write(transaction * trans);
    int   Data_width(amba_size size);
    void  Quit(frbm_quit QuitAction = quit_stop);
    void  Sync();

  };

  


#endif
