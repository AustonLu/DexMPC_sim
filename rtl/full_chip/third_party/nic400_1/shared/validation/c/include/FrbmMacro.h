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

#ifndef FRBM_MACRO_H
#define FRBM_MACRO_H

#include <iostream>
#include <ostream>
#include <fstream>
#include <sstream>
#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <cassert>
#include <cstring>
#include <cstdlib>

#include "arm_types.h"

#include "frbm_types.h"

#include "UtilityAxi.h"

using namespace std;
using namespace arm_namespace;
using namespace frbm_namespace;

#define LF 0x0A

#define PAGE_SIZE 4096

  enum ms_type_enum
  {
    master_p = 0,
    slave_p  = 1,
    both   = 2
  };

  class FrbmMacro
  {
    public: 

  
    //-----------------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------------
    FrbmMacro();

    //-----------------------------------------------------------------------
    // Destructor
    //-----------------------------------------------------------------------
    virtual ~FrbmMacro();
  
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    bool Initialise_FRBM_gen(string filename, ms_type_enum ms_type_in = both);
    void Comment(string comment);
    void DisplayBinary(arm_uint32 Value, int length);
    int  Calc_addr_width(arm_uint8 addr_width);
    int  Mask_value(int value, int bits);
    string  Mask_value(string value, int bits);
    unsigned long long  Mask_value_ul(unsigned long long value, int bits);
    string  Mask_value_ul(string value, int bits);
    string to_string(arm_uint32 data, uint bits);

    //-----------------------------------------------------------------------
    // Calculate
    //-----------------------------------------------------------------------
    arm_uint64 GetMask(amba_size Size);
    amba_strobe GetStrobe(amba_size Size);
    amba_parity GetParity(amba_size Size);  // dk
    void SetStrobeArray(amba_size Size, amba_strobe Strobe[16]);
    void SetParityArray(amba_size Size, amba_parity parity[16]);  // dk
    void UpSizeData(arm_uint8 Data[16], arm_uint64 Data64[16], int Length);
    void UpSizeData(arm_uint16 Data[16], arm_uint64 Data64[16], int Length);
    void UpSizeData(arm_uint32 Data[16], arm_uint64 Data64[16], int Length);

    //-----------------------------------------------------------------------
    // Data
    //-----------------------------------------------------------------------
    arm_uint32 LineCount;

    virtual void Quit(frbm_quit QuitAction = quit_stop) {};
    virtual void Write(transaction * trans) {};
    virtual void Read(transaction * trans) {};
    virtual void Access(transaction * trans) {};

    char FileName[256];
    bool usingFile;

    ms_type_enum ms_type;

    ostream *mycout;

    arm_uint32 Transactions;
  };

#endif
