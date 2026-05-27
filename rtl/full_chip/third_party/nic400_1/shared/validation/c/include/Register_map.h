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

#ifndef REGISTER_MAP_H
#define REGISTER_MAP_H

#include <iostream>
#include <exception>
#include <fstream>
#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <cassert>
#include <cstring>
#include <cstdlib>
#include <functional>
#include <sstream>
#include <map>
#include <utility>
#include "Register.h"

using namespace std;


  class Register_map
  {
    public: 

  
    //-----------------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------------
    Register_map(const char * name, string reg_name = "", int port = 0);
    Register_map();

    //-----------------------------------------------------------------------
    // Destructor
    //-----------------------------------------------------------------------
    ~Register_map();
  
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    bool read_spirit(const char * filename, string reg_name = "", int port = 0, bool check = true, multimap<int, string> * addrmap = NULL);
    map<string, Register *>::const_iterator get_reg_iter(const char * reg_name);

    //-----------------------------------------------------------------------
    // Read Functions
    //-----------------------------------------------------------------------
    int read(const char * reg_name, const char * field_name, int vn = 0);
    int read_reset(const char * reg_name, const char * field_name);
    int read(const char * field_name);
    int read_reg(const char * reg_name);

    int get_mask(const char * reg_name, const char * field_name);
    int get_mask(const char * field_name);

    int shift_data(const char * reg_name, const char * field_name, int value);
    int shift_data(const char * field_name, int value);

    //-----------------------------------------------------------------------
    // Read Functions
    //-----------------------------------------------------------------------
    int write(const char * reg_name, const char * field_name, int value, int vn = 0);
    int write(const char * field_name, int value);
    int write_reg(const char * reg_name, int value);

    //-----------------------------------------------------------------------
    // Description Fields
    //-----------------------------------------------------------------------
    const char * read_des(const char * reg_name, const char * field_name); 
    const char * read_des(const char * field_name); 

    //-----------------------------------------------------------------------
    // Address Fields
    //-----------------------------------------------------------------------
    long address(const char * reg_name);
    int  port(const char * reg_name);
    int  portBlock(const char * block_name); 

    //-----------------------------------------------------------------------
    // Get reg_name
    //-----------------------------------------------------------------------

    const char * get_reg(const char * field_name);

    map<string, Register *> reg_map;

  };

#endif
