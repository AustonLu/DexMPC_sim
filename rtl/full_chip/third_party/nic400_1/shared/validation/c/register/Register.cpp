//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: DriveAxiPv.h,v $
//
// Checked In          :  2004/05/13 09:09:03
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Stores details of a register 
//
//---------------------------------------------------------------------------

#include "../include/Register.h"

#include <sstream>


 //-----------------------------------------------------------------------
 // Constructor
 //-----------------------------------------------------------------------
 Register::Register() {}

 //-----------------------------------------------------------------------
 // Destructor
 //-----------------------------------------------------------------------
 Register::~Register() {}

 //-----------------------------------------------------------------------
 // Methods
 //-----------------------------------------------------------------------
 void Register::add_field(const char * name, int start_bit, int bits, int reset, const char  * des_) {
     
     string name_(name);
     
     int count = 1;
     map<string, int>::iterator map_iter;
     while (bits_map.find(name_) != bits_map.end())
     {
        std::ostringstream field_incr;
        field_incr << ++count;
        name_ = string(name) + string(field_incr.str());
     }

     start_bit_map.insert(make_pair(name_, start_bit));
     bits_map.insert(make_pair(name_, bits));
     description_map.insert(make_pair(name_, string(des_)));
     write(name_.c_str(), reset);

 }

 void Register::set_description(const char * des_) {
         reg_des = string(des_);
 }

 bool Register::is_field(const char * name) {
      
      map<string, int>::const_iterator map_iter;
      
      map_iter == bits_map.find(string(name));

      if (map_iter == bits_map.end()) { 
         return false;
      } else {
         return true;
      };

  }

 //-----------------------------------------------------------------------
 // Read Functions
 //-----------------------------------------------------------------------
 int Register::read(const char * field_name, bool reset_in, int vn) {

     int bit_no;
     int value;
     int start_bit = get_start_bit(field_name);
     int bits = get_bits(field_name);
     string vn_field;
     map<string, int>::const_iterator map_iter;

     vn_field = string(field_name) + "." + to_string(vn, 2);     

     //Return stored version if it's there
     if (vn != 0) {
        map_iter = vn_field_map.find(vn_field);
        if (map_iter != vn_field_map.end()) {
           return vn_field_map[vn_field];
        };
     };
     
     //for each bit
     value = 0;
     for (bit_no = start_bit; bit_no < (start_bit + bits); bit_no++) {
        
         if (reset_in) {
            value = value + (reset[bit_no] << (bit_no - start_bit));
         } else {
            value = value + (reg[bit_no] << (bit_no - start_bit));
         };
     };

     return value;
 }

 int Register::shift_data(const char * field_name, int value_in) {

     int start_bit = get_start_bit(field_name);

     return value_in * (int)(pow(2.0,start_bit));
 }

 //Return a mask for the requested field
 int Register::mask(const char * field_name) {

     int bit_no;
     int value;
     int start_bit = get_start_bit(field_name);
     int bits = get_bits(field_name);

     //for each bit
     value = 0;
     for (bit_no = start_bit; bit_no < (start_bit + bits); bit_no++) {
         
         value = value + (1 << bit_no);
     };

     return value;
 }



 //Read whole regsiter
 int Register::read() { 
     
     //Simply return the data
     return int(reg.to_ulong());
 }

 //Read description of field
 string Register::description(const char * field_name) {

     //Return the field description
     return get_desc(field_name);
 }


 //Read description
 string Register::description() {

     //Return the description
     return reg_des;
 }

 //-----------------------------------------------------------------------
 // Write Functions
 //-----------------------------------------------------------------------
 //write field
 int Register::write(const char * field_name, int value, bool reset_in, int vn) {

     int bit_no;
     int start_bit = get_start_bit(field_name);
     int bits = get_bits(field_name);
     string vn_field;

     if (reset_in) {
        for (bit_no = start_bit; bit_no < (start_bit + bits); bit_no++) {
           reset[bit_no] = value & (1 << (bit_no - start_bit));
        };
     };

     vn_field = string(field_name) + "." + to_string(vn, 2);

     //normal write for non vn case
     if (vn == 0) {

         //for each bit
         for (bit_no = start_bit; bit_no < (start_bit + bits); bit_no++) {
             reg[bit_no] = value & (1 << (bit_no - start_bit));
         };

     } else {
        
        vn_field_map[vn_field] = value;
     }

   

     //Return the contents of the register
     return int(reg.to_ulong());
 }

 //Write whole register
 int Register::write(int value) {
         
         //Set the whole register value;
         reg = value;

         //return the contents of the register
         return int(reg.to_ulong());
 }

 //-----------------------------------------------------------------------
 // Address functions Functions
 //-----------------------------------------------------------------------
 void Register::address(long add) {
   
    //set address
    reg_address = add;

 }

 long Register::address() {

    //return address
    return reg_address;
 }

 void Register::port(int port) {
   
    //set port
    reg_port = port;

 }

 int Register::port() {

    //return port
    return reg_port;
 }

 //-----------------------------------------------------------------------
 // Checking Functions
 //-----------------------------------------------------------------------
 void Register::check() {

      map<string, int>::const_iterator map_iter;
      int bits = 0;
      int upper_bit = 0;
      string field_name;

      //First check that every thing in the bits array adds to to 32 
      //This check that the register is fully defined
      map_iter = bits_map.begin();

      while (map_iter != bits_map.end()) {
          bits += (*map_iter).second;
          map_iter++;
      };

      if (bits != 32) throw "Register is not fully defined\n";

      //Now check that the start bits all line up
      upper_bit = 0;

      while (upper_bit < 32) {

          //Reset the iterator
          map_iter = start_bit_map.begin();

          //Find name of field value    
          while (map_iter != start_bit_map.end()) {
             if ((*map_iter).second == upper_bit) {
                 field_name = (*map_iter).first;
                 break;
             };
             map_iter++;
          };

          //Check this was found
          if (map_iter == start_bit_map.end()) {
                throw "Register fields are not continuous\n";
          };

          //Find the number of bits for this field
          map_iter = bits_map.find(field_name);

          //Check this was found
          if (map_iter == bits_map.end()) {
                throw "No field size found in bits map\n";
          };

          //Update the upper_bit
          upper_bit += (*map_iter).second;

      };

 }

 //-----------------------------------------------------------------------
 // Private Functions
 //-----------------------------------------------------------------------
 int Register::get_bits(const char * field_name) {
     
     map<string, int>::const_iterator map_iter;

     //Convert name to string
     string f_name = string(field_name);

     //work out start bit 
     map_iter = bits_map.find(f_name);

     if (map_iter==bits_map.end()) {
             throw "Trying to read unknown field (bits)\n";
     } else {
             return (*map_iter).second;
     };

 }

 int Register::get_start_bit(const char * field_name) {

     map<string, int>::const_iterator map_iter;

     //Convert name to string
     string f_name = string(field_name);

     //work out start bit 
     map_iter = start_bit_map.find(f_name);

     if (map_iter==start_bit_map.end()) {
             cout << "Trying to find field " << field_name << endl;

             for (map_iter = start_bit_map.begin() ; map_iter!=start_bit_map.end(); map_iter++)
             cout << (*map_iter).first << endl;
             throw "Trying to read unknown field (start_bit)\n";

     } else {
             return (*map_iter).second;
     };

 }

 string Register::get_desc(const char * field_name) {

     map<string, string>::const_iterator map_iter;

     //Convert name to string
     string f_name = string(field_name);

     //work out start bit 
     map_iter = description_map.find(f_name); 

     if (map_iter==description_map.end()) {
             throw "Trying to read unknown field (start_bit)\n";
     } else {
             return (*map_iter).second;
     };
 }



