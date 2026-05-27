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

#include "../include/Register_map.h"

    //-----------------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------------
    Register_map::Register_map(const char * name, string reg_name, int port) {

           //Read in the spirit 
           read_spirit(name, reg_name, port); 
    }

    Register_map::Register_map() {

    }
    //-----------------------------------------------------------------------
    // Destructor
    //-----------------------------------------------------------------------
    Register_map::~Register_map() {}

    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    bool Register_map::read_spirit(const char * filename, string reg_name, int port, bool check, multimap<int, string> * addrmap) {

         //Open the suggested spirit file
         ifstream fin (filename);
         ostringstream buf;
         char entry[250];
         string token;
         string value;
         long base_address;
         long address_offset;
         string address_data;
         Register * new_reg;
         Register * new_reg2;
         bool in_register = false;
         bool in_field = false;
         string register_name;
         string field_name;
         int start_bit;
         int bits;
         int reset;
         bool in_reset = false;
         string field_description = "No description";
         string description;
         map<string, Register*>::const_iterator map_iter;

         //Check that file was opened
         fin.open(filename);
         if (!fin.is_open()) {
             
              cout << "Try adjusting for run directory hierarchy" << endl;
              string filename_str = filename;
              filename_str = "../" + filename_str;
              cout << filename_str << endl;
              fin.open(filename_str.c_str());
              if (!fin.is_open()) { throw "Failed to open spirit file"; }

         };
         //Read the file into a string stream
         buf << fin.rdbuf();
         fin.close();

         istringstream spirit(buf.str());

         while (!spirit.eof() ) {

              //Clear error flags
              spirit.clear();

              //get the next line 
              spirit.getline(entry, 249, '>');

              //convert to string
              token = string(entry);

              //Start register
              if (token.find("<spirit:register")!=string::npos) {

                   //Allocate new register
                   new_reg = new Register;

                   //set in_register
                   in_register = true;

              };

              //End register 
              if (token.find("</spirit:register")!=string::npos) {

                   //Set the register address
                   new_reg->address(address_offset + base_address);
                   new_reg->port(port);

                   //Set the description
                   new_reg->set_description(description.c_str());

                   //Check the register
                   if(check) {
                      try {
                           new_reg->check();
                      } catch ( const char * error ) {
                           cout << "Caught " << error << endl;     
                           exit(1);
                      };
                   };

                   //Add registers
                   if (reg_name == "DUT") {
                      
                      //Add register to all blocks with a match address 
                      multimap<int,string>::iterator match, matchlow, matchup;

                      matchlow=addrmap->lower_bound(int(address_offset >> 12)); 
                      matchup=addrmap->upper_bound(int(address_offset >> 12)); 
                      
                      if (register_name.find(".") != string::npos) {
                          cout << "added register " << string(register_name) << endl;
                          reg_map.insert(make_pair(string(register_name), new_reg));
                      } else {
                          for (match=matchlow ; match != matchup; match++) {
                              cout << "added register " << (*match).second + "." + string(register_name) << endl;    
                              new_reg2 = new Register;
                              *new_reg2 = *new_reg;
                              reg_map.insert(make_pair((*match).second + "." + string(register_name), new_reg2));
                          }
                      }

                   } else {

                      //Add to map
                      reg_map.insert(make_pair(string(register_name), new_reg));
                   }

                   //set in_register
                   in_register = false;

                   //Clear Description
                   description = "No Description"; 
              };

              //Name
              if (token.find("<spirit:name")!=string::npos) {
                  
                   //Get the data
                   spirit.get(entry, 249, '<');

                   //covert to string
                   value = string(entry);

                   if (in_field) {

                      field_name = value;

                   } else if (in_register) {
 
                      if (reg_name.empty() == true) {
                              register_name = value;
                      } else if (reg_name == "DUT") {
                              register_name = value;
                      } else {
                              register_name = reg_name + "." + value;
                      }

                      //Check regsiter doesn't exist
                      map_iter= reg_map.find(register_name);
                     
                     //if(check){
                     //   if (map_iter != reg_map.end()) throw "Duplicate register name";
                     //}
                   } 
              };

              //Base address
              if (token.find("<spirit:baseAddress")!=string::npos) {

                   spirit >> base_address;

              }

              //Start field
              if (token.find("<spirit:field")!=string::npos) {

                   in_field = true;
              };

              //Start field
              if (token.find("</spirit:field")!=string::npos) {

                   in_field = false;

                   if (in_register) {
                           //add the field
                           if ((reset >> start_bit) == 0) {
                                new_reg->add_field(field_name.c_str(), start_bit, bits, 0, field_description.c_str());
                           }
                           else {
                                new_reg->add_field(field_name.c_str(), start_bit, bits, (reset >> start_bit) % (1 << bits), field_description.c_str());
                           }


                           //Clear value
                           bits = 0;
                           start_bit = 0;
                           //reset = 0;
                           field_description = "No Description";
                   };
              };

              //Start field
              if (token.find("<spirit:addressOffset")!=string::npos) {

                   //Get the data
                   spirit >> address_data; 
                   address_offset = strtol(address_data.c_str(), NULL, 0);

              };

              //reset bit
              if (token.find("<spirit:reset")!=string::npos) {

                   in_reset = true;    
              };

              if (token.find("<spirit:value")!=string::npos && in_reset) {


                   //Get the data
                   spirit.get(entry, 249, '<');

                   reset = (int)strtoul(entry, NULL, 0);
                   in_reset = false;

              };

              //start bit
              if (token.find("<spirit:bitOffset")!=string::npos) {

                   //Get the data
                   spirit >> start_bit;

              };
             
              //start bit
              if (token.find("<spirit:bitWidth")!=string::npos) {

                   //Get the data
                   spirit >> bits;

              };
    

         };

         return true;
    }

    //-----------------------------------------------------------------------
    // Register name  Functions
    //-----------------------------------------------------------------------
    map<string, Register *>::const_iterator Register_map::get_reg_iter(const char * reg_name) {

        map<string, Register *>::const_iterator map_iter;
        string reg_name_str;

        //First look for a direct match
        map_iter = reg_map.find(reg_name);
  
        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return map_iter;
        };

        //Else if there is no . in the name
        reg_name_str = string(reg_name);
        if (reg_name_str.find(".") != string::npos) {
                return reg_map.end(); 
        };

        //Find the first match
        map_iter = reg_map.begin();
        while (map_iter != reg_map.end() && (*map_iter).first.find(reg_name) == string::npos) {
            map_iter ++;
        };

        return map_iter;
    }

    //-----------------------------------------------------------------------
    // Read Functions
    //-----------------------------------------------------------------------
    int Register_map::read(const char * reg_name, const char * field_name, int vn) {

        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);
  
        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->read(field_name, false, vn);
        };

        cout << "Register " << reg_name << " field " << field_name << endl;
        throw "Specified register not found for read ";
        return 0;

    }

    int Register_map::read_reset(const char * reg_name, const char * field_name) {

        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);
  
        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->read(field_name, true);
        };

        cout << "Register " << reg_name << " field " << field_name << endl;
        throw "Specified register not found for rest read ";
        return 0;

    }

    int Register_map::read(const char * field_name) {
        
        return read(get_reg(field_name), field_name);
    }

    int Register_map::read_reg(const char * reg_name) {

        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->read();
        };

        throw "Specified register not found for read";
        return 0;

    }


    //-----------------------------------------------------------------------
    // Mask Functions
    //-----------------------------------------------------------------------
    int Register_map::get_mask(const char * reg_name, const char * field_name) {

        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->mask(field_name);
        };

        throw "Specified register not found for mask generation";
        return 0;

    }

    int Register_map::get_mask(const char * field_name) {
        
        return get_mask(get_reg(field_name), field_name);
    }

    //-----------------------------------------------------------------------
    // Data shift functions Functions
    //-----------------------------------------------------------------------
    int Register_map::shift_data(const char * reg_name, const char * field_name, int value) {

        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->shift_data(field_name, value);
        };

        throw "Specified register not found for shift_data";
        return 0;

    }

    int Register_map::shift_data(const char * field_name, int value) {
        
        return shift_data(get_reg(field_name), field_name, value);
    }

    //-----------------------------------------------------------------------
    // Write Functions
    //-----------------------------------------------------------------------
    int Register_map::write(const char * reg_name, const char * field_name, int value, int vn) {

        map<string, Register *>::const_iterator map_iter;
        string reg_name_str;
        //First look for a direct match
        map_iter = reg_map.find(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return (*map_iter).second->write(field_name, value, false, vn);
        }; 
         
        //Else if there is no . in the name
        reg_name_str = string(reg_name);
        if (reg_name_str.find(".") != string::npos) {
                throw "Specified register not found for write";
                return 0;
        };

        //Find the first match
        map_iter = reg_map.begin();
        int found = 0;
        int last_value = 0;
        for (map_iter = reg_map.begin(); map_iter != reg_map.end(); map_iter++) {
            if ((*map_iter).first.length() >= strlen(reg_name)) {   
               if ((*map_iter).first.substr((*map_iter).first.length() - strlen(reg_name)) == reg_name) {
                   found++;
                   last_value = (*map_iter).second->write(field_name, value, false, vn);
               };
            };
        };
        //Check find was not sucessfull
        if (found == 0) {
                throw "Specified register not found for write";
                return 0;
        };
        return last_value;

    }
    int Register_map::write(const char * field_name, int value) {

            return write(get_reg(field_name), field_name, value);
    }

    int Register_map::write_reg(const char * reg_name, int value) {

           map<string, Register *>::const_iterator map_iter;

           map_iter = reg_map.find(reg_name);

           //Check find was sucessfull
           if (map_iter != reg_map.end()) {
                  return (*map_iter).second->write(value);
           };

           throw "Specified register not found for read";
           return 0;
    }

    //-----------------------------------------------------------------------
    // Description Fields
    //-----------------------------------------------------------------------
    const char * Register_map::read_des(const char * reg_name, const char * field_name) { 
        
        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return ((*map_iter).second)->description(field_name).c_str();
        };

        throw "Specified register not found for description read";
        return 0;

    }

    const char * Register_map::read_des(const char * field_name) { 

            return read_des(get_reg(field_name), field_name);
    }

    //-----------------------------------------------------------------------
    // Address Fields
    //-----------------------------------------------------------------------
    long Register_map::address(const char * reg_name) { 
        
        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return ((*map_iter).second)->address();
        };

	 cout << "Register:" << endl;
         cout << reg_name << endl;
	 throw "Specified register not found for address fetch";
	return 0;

    }

    int Register_map::port(const char * reg_name) { 
        
        map<string, Register *>::const_iterator map_iter;

        map_iter = get_reg_iter(reg_name);

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return ((*map_iter).second)->port();
        };

        throw "Specified register not found for port fetch";
        return 0;
    }

    int Register_map::portBlock(const char * block_name) { 
        
        map<string, Register *>::const_iterator map_iter;

        map_iter = reg_map.begin();
	while (map_iter != reg_map.end()){

		if ( (*map_iter).first.substr(0, (*map_iter).first.find(".")) == block_name){
			break;
		}
		map_iter++;
	}

        //Check find was sucessfull
        if (map_iter != reg_map.end()) {
                return ((*map_iter).second)->port();
        };

        throw "Specified register block not found for port fetch";
        return 0;

    }

    //-----------------------------------------------------------------------
    // Get reg_name
    //-----------------------------------------------------------------------

    const char * Register_map::get_reg(const char * field_name) {

          //Convert string name to string   
          string reg_name;
          int matches = 0;

          map<string, Register *>::const_iterator map_iter;

          //Look through all the regsiters and ask if they have a matching field
          map_iter = reg_map.begin();

          while (map_iter != reg_map.end()) {
              
              if ((*map_iter).second->is_field(field_name)) {    
                  matches++;    
                  reg_name = (*map_iter).first;
              };
              map_iter++;
          };

          //Check that multiple matches were not found
          if (matches > 1) throw "Error multiple possible fields found.. please specify register";

          return reg_name.c_str();

    }



