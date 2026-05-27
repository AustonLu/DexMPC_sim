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
// Filename            : $RCSfile: DriveAxiPv.h,v $
//
// Checked In          :  2014-02-25 14:55:35 +0000 (Tue, 25 Feb 2014)
//
// Revision            : 167698
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: DriveAxiPv
//
//---------------------------------------------------------------------------

#ifndef APB_FRBM_MACRO_H
#define APB_FRBM_MACRO_H

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

#include "UtilityApb.h"
#include "FrbmMacro.h"

using namespace std;
using namespace arm_namespace;
using namespace frbm_namespace;

#define LF 0x0A

#define PAGE_SIZE 4096


  class ApbFrbmMacro : public FrbmMacro
  {
    public: 
  
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    //============================
    // Display
    //============================
    void C(const char *str);
    void Cmt(char *fmt, ...);

    //============================
    // House keeping
    //============================
    virtual void Quit(frbm_quit QuitAction = quit_stop);

    //============================
    // Low level transactions
    //============================
    void Sync();
    void Idle();

    //==================================
    //Full access write/read write
    //==================================
    
    virtual void Write(transaction * trans);
    virtual void Read(transaction * trans);
    virtual void Access(transaction * trans);

    //=======================================================================
    // Unsupported transactions
    //=======================================================================
    void Loop(arm_uint32 Loop);

    //-----------------------------------------------------------------------
    // State
    //-----------------------------------------------------------------------

    UtilityApb uUtilityApb;

  };

  


#endif
