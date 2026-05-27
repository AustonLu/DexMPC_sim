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

#ifndef REGISTER_H
#define REGISTER_H

#include <iostream>
#include <exception>
#include <fstream>
#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <cassert>
#include <string>
#include <cstdlib>
#include <map>
#include <bitset>
#include <cmath>
#include <sstream>
#include <ostream>

using namespace std;

  class Register
  {
    public: 

  
    //-----------------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------------
    Register();

    //-----------------------------------------------------------------------
    // Destructor
    //-----------------------------------------------------------------------
    ~Register();
  
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    void add_field(const char * name, int start_bit, int bits, int reset, const char * des_);
    void set_description(const char * des_);
    bool is_field(const char * name);

    //-----------------------------------------------------------------------
    // Read Functions
    //-----------------------------------------------------------------------

    //-----------------------------------------------------------------------
    // Read Functions
    //-----------------------------------------------------------------------
    
    //Read field .. returns field value
    int read(const char * field_name, bool reset_in = false, int vn = 0);

    //Returns a mask the requested field
    int mask(const char * field_name);

    //Returns data shifted by correct ammount
    int shift_data(const char * field_name, int value_in);


    //Read whole regsiter
    int read();

    //Read description of field
    string description(const char * field_name);

    //Read description
    string description();

    //-----------------------------------------------------------------------
    // Write Functions
    //-----------------------------------------------------------------------
    //write field
    int write(const char * field_name, int value, bool reset_in = false, int vn = 0);

    //Write whole register
    int write(int value);

    //-----------------------------------------------------------------------
    // Check Functions
    //-----------------------------------------------------------------------
    void check();

    //-----------------------------------------------------------------------
    // Address functions Functions
    //-----------------------------------------------------------------------
    void address(long add);
    long address();

    void port(int port);
    int port();

    //-----------------------------------------------------------------------
    // String helper function
    //-----------------------------------------------------------------------
    string to_string(int data, uint bits) {

          ostringstream data_str;
          //convert to string
          data_str << setw(bits) << setfill('0') << hex << data;
          return data_str.str();
    };

    Register& operator=(const Register& reg_in) {
        
        reg = reg_in.reg;
    
        //Map of the start bits, field widths and values
        start_bit_map = reg_in.start_bit_map;
        bits_map = reg_in.bits_map;
        description_map = reg_in.description_map;
    
        //Register description
        reg_des = reg_in.reg_des;
    
        //Register Address
        reg_address = reg_in.reg_address;
        reg_port = reg_in.reg_port;

        return *this;
    };

    private:

    //-----------------------------------------------------------------------
    // Ge_bits 
    //-----------------------------------------------------------------------
    int get_bits(const char * field_name);
    int get_start_bit(const char * field_name);
    string get_desc(const char * field_name);

    //The register
    bitset<32> reg;
    bitset<32> reset;

    //Map of the start bits, field widths and values
    map<string, int> start_bit_map;
    map<string, int> bits_map;
    map<string, string> description_map;

    //vn map
    map<string, int> vn_field_map;

    //Register description
    string reg_des;

    //Register Address
    long reg_address;
    int reg_port;


  };

#endif
