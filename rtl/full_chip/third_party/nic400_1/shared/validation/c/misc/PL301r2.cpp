
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

#include "../include/PL301r2.h"
#include "../include/AxiFrbmMacro.h"
#include "../include/ApbFrbmMacro.h"
#include "../include/AhbSFrbmMacro.h"
#include "../include/AhbMFrbmMacro.h"
#include "../include/Register_map.h"

#include <sstream>
#include <ostream>

using namespace pl301_namespace;
using namespace arm_namespace;
using namespace std;
using namespace frbm_namespace;

    //-----------------------------------------------------------------------
    // declace global variables
    //-----------------------------------------------------------------------

    master_port * pl301_namespace::current_slave;
    slave_port * pl301_namespace::current_master;
    string pl301_namespace::test_name;
    string pl301_namespace::external_cfg_width;
    
    //-----------------------------------------------------------------------    
    //Necessary Function:  extract a value from a comma sepearated list
    //-----------------------------------------------------------------------
    string clist(string value, int item) {

            int location = 0;
            int count = 0;

            //Add a comma top the end
            value = value + ",";

            //Go through the list
            while ((value.find(",", location) != string::npos) && (count < item)) {
                    count++;
                    location = value.find(",", location) + 1;
            };

            if ((value.find(",", location) == string::npos)) {
                 return "";
            } else {
                 return value.substr(location, value.find(",", location) - location);
            };
    };


    //-----------------------------------------------------------------------
    // constructor
    //-----------------------------------------------------------------------

    pl301::pl301(char * filename, char * top_level) {

            initalise(filename, top_level);
    }

    pl301::pl301() {

    }

    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // This function looks for a tsf file in the current directory and scans it 
    // It replaces the line ACTION * "execute vector files from '<dir>' with a line
    // and file name for each XVC it knows about.
    //-------------------------------------------------------------------------

    bool pl301::generate_tsf() {
         
         //Open the suggested config file
         string tsf_file;
         string line;
         string line_in;
         string directory;
         string filename;
         string parameter;
         string value;
         int number;

         tsf_file = test_name + ".tsf";

         cout << "tsf file name is " << tsf_file << endl;

         ifstream fin (tsf_file.c_str());
         ostringstream buf;
         char entry[250];

         //Check that file was opened
         fin.open(tsf_file.c_str());
         if (!fin.is_open()) {
                 cout << "Failed to open tsf file (" << tsf_file << ")" << endl;
                 cout << "Have you set the test_name variable correctly?" << endl;
                 exit(1);
         }

         //Read the file into a string stream
         buf << fin.rdbuf();
         fin.close();

         //convert string
         istringstream tsf(buf.str());

         //open tsf file for writing
         ofstream fout (tsf_file.c_str());

         while (!tsf.eof() ) {
               
              tsf.clear();

              //get the next line 
              tsf.getline(entry, 249, '\n');
              line = string(entry);

              if (line.find("ACTION * \"execute vector files\"")!=string::npos) {

                     //Go though all the slave ports
                     master_iter this_slave_port;
                     for (this_slave_port = slave_ports.begin(); this_slave_port != slave_ports.end(); this_slave_port++) {

                             if (((*this_slave_port).second).xvc_name != "")  {
                                 fout << "ACTION " << ((*this_slave_port).second).xvc_name << " \"execute vector file '" << ((*this_slave_port).second).xvc_name << ".m3i'\"" << endl;
                             }

                     }
                     slave_iter this_master_port;
                     for (this_master_port = master_ports.begin(); this_master_port != master_ports.end(); this_master_port++) {

                             if (((*this_master_port).second).xvc_name  != "") {
                                 fout << "ACTION " << ((*this_master_port).second).xvc_name << " \"execute vector file '" << ((*this_master_port).second).xvc_name << ".m3i'\"" << endl;
                             }

                     }

                     fout << "ACTION " << cfg_master_name << " \"execute vector file '" << cfg_master_name << ".m3i'\"" << endl;


              } else {

                     //If there is a < in the line
                      if (line.find("<")!=string::npos) {
                          
                           parameter = line.substr((int)line.find("<") + 1, (int)(line.find(">") - line.find("<") - 1));
                           number = 0;
                           if (parameter.find("+")!=string::npos) {
                                   number = atoi(parameter.substr((int)parameter.find("+") + 1).c_str());
                                   parameter = parameter.substr(0, parameter.find("+") - 1);
                           }

                           if (line.find("AXIM_")!=string::npos) {
                              //Go though all the slave ports
                              master_iter this_slave_port;
                              for (this_slave_port = slave_ports.begin(); this_slave_port != slave_ports.end(); this_slave_port++) {

                                      line_in = line;
                                      line_in.replace(line_in.find("<"), (int)(line_in.find(">") - line_in.find("<")) + 1, to_string_dec(param(get_master_p(this_slave_port), parameter) + number));
                                      line_in.replace(line_in.find("*"), 1, (*this_slave_port).first);

                                      fout << line_in << endl;
               
                              }
                           }

                           if (line.find("AXIS_")!=string::npos) {
                              //Go though all the slave ports
                              slave_iter this_master_port;
                              for (this_master_port = master_ports.begin(); this_master_port != master_ports.end(); this_master_port++) {

                                      line_in = line;
                                      line_in.replace(line_in.find("*"), 1, (*this_master_port).first);
                                      line_in.replace(line_in.find("<"), (line_in.find(">") - line_in.find("<")) + 1, to_string_dec(param(get_slave_p(this_master_port), parameter) + number));
                                      fout << line_in << endl;
               
                              }
                           }

                      } else {
                          fout << line << endl;
                      }
              }
 
         }

         return true;

    }

    bool pl301::generate() {

       string Filename;
       int add_vnet_bits = 0;

       //Instantiate the vector ouput classes
       FrbmMacro * VecGen;
       AxiFrbmMacro AxiVecGen;
       ApbFrbmMacro ApbVecGen;
       AhbSFrbmMacro AhbSVecGen;
       AhbMFrbmMacro AhbMVecGen;

       try {
            //Transaction
            transaction * this_trans;
           
            //Go though all the slave ports
            master_iter this_slave_port;
            for (this_slave_port = slave_ports.begin(); this_slave_port != slave_ports.end(); this_slave_port++) {

                    //Select correct Vector generation class 
                    if ((param_s(get_master_p(this_slave_port), "protocol") == "axi") || (param_s(get_master_p(this_slave_port), "protocol") == "itb" )) {
                        VecGen = &AxiVecGen;
                    } else if (param_s(get_master_p(this_slave_port), "protocol").substr(0, 3) == "ahb") {
                        VecGen = &AhbMVecGen;
                    } else if (param_s(get_master_p(this_slave_port), "protocol").substr(0, 3) == "apb") {
                        VecGen = &ApbVecGen;
                    }  else if(param_s(get_master_p(this_slave_port), "protocol") == "axi4") {
                        VecGen = &AxiVecGen;
                    } else {
                        throw "Illegal protocol detected\n";
                    }

                    Filename = ((*this_slave_port).second).xvc_name + ".m3i";
                    //Now initalise the vector generator
                    VecGen->Initialise_FRBM_gen(Filename, ms_type_enum(0));
   
                    if (DomReader.get_value(get_master_p(this_slave_port)->parameters, "enable_vn") == "true") {
                             add_vnet_bits = 4;   
                    } else {
                             add_vnet_bits = 0;   
                    }

                    if (param_s(get_master_p(this_slave_port), "protocol").substr(0, 3) == "ahb") {
                        //Output the size comments supported both by  ahb
                        VecGen->Comment("#FRM# Datawidth="    + param_s(get_master_p(this_slave_port), "data_width")   + "\n");
                        VecGen->Comment("#FRM# Addresswidth=" + param_s(get_master_p(this_slave_port), "addr_width")   + "\n\n");
                    }
                    else {

                        //Output the size comments
                        VecGen->Comment("#FRM# Datawidth="    + param_s(get_master_p(this_slave_port), "data_width")   + "\n");
                        VecGen->Comment("#FRM# Addresswidth=" + param_s(get_master_p(this_slave_port), "addr_width")   + "\n");
                        VecGen->Comment("#FRM# IDWidth="      + param_s(get_master_p(this_slave_port), "aid_width")    + "\n");
                        int user_width;

                        if (param_s(get_master_p(this_slave_port), "protocol") == "axi" || param_s(get_master_p(this_slave_port), "protocol") == "axi4"){
                           user_width = param(get_master_p(this_slave_port), "awuser_width");
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRM# awUserWidth="  + to_string_dec(16 + user_width + add_vnet_bits) + "\n");
                           user_width = param(get_master_p(this_slave_port), "aruser_width");
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRM# arUserWidth="  + to_string_dec(16 + user_width + add_vnet_bits) + "\n");
                        } else {
                           user_width = param(get_master_p(this_slave_port), "awuser_width");
                           int user_width_ar = param(get_master_p(this_slave_port), "aruser_width");

                           if (user_width < user_width_ar) {
                               user_width = user_width_ar;  
                           };
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRM# awUserWidth="  + to_string_dec(16 + user_width) + "\n");
                           VecGen->Comment("#FRM# arUserWidth="  + to_string_dec(16 + user_width) + "\n");
                        };

                        user_width = param(get_master_p(this_slave_port), "wuser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRM# wUserWidth="   + to_string_dec(user_width + add_vnet_bits) + "\n");
                        user_width = param(get_master_p(this_slave_port), "buser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRM# bUserWidth="   + to_string_dec(user_width) + "\n");
                        user_width = param(get_master_p(this_slave_port), "ruser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRM# rUserWidth="   + to_string_dec(user_width) + "\n\n");
                    }

                    //send every transaction there is in the queue 
                    while (((*this_slave_port).second).transactions.empty() != true) {

                         //Get the transaction
                         this_trans = &((*this_slave_port).second).transactions.front();

                         //Check that the valid is not 0 if it is make it 1! as 1 is taken off later!
                         if (this_trans->valid == 0) {
                               this_trans->valid = 1;   
                         }

                         if (param_s(get_master_p(this_slave_port), "protocol") == "axi4") {
                             this_trans->protocol = axi4;
                         }    

                         //Modify the auser signal to contain the QV and valid value 
                         //Note that the test components do not support a user width of zero. Hence a fake bit must be added
                         if (this_trans->direction == frbm_namespace::wr) {
                              int user_width = this_trans->awuser_width;
                              if (user_width == 0) {
                                  user_width++;
                                  this_trans->awuser_width += 1;
                              }
                              this_trans->awuser_width += (16 + add_vnet_bits);
                              unsigned long auser_append = (this_trans->region) + 
                                                           ((unsigned long)pow(2.0, 4) * this_trans->qv) + 
                                                           ((unsigned long)pow(2.0, 8) * (this_trans->valid - 1));
                              if (add_vnet_bits != 0) {
                                   auser_append = (auser_append * 16) + this_trans->vnet;
                              }

                              for (int i=0; i < 16; i++){
                                  this_trans->auser[i] = this_trans->auser[i] +
                                                     to_string_in_binary(auser_append,(16 + add_vnet_bits));        
                              }

                              //If enabled add vnet to wuser data
                              if (add_vnet_bits != 0) {
                                  this_trans->wuser_width += add_vnet_bits;   
                                  for (int i=0; i < this_trans->length; i++) {
                                      this_trans->user[i] = this_trans->user[i] + to_string_in_binary(this_trans->vnet, 4);      
                                  }
                              }

                         } else {
                              int user_width = this_trans->aruser_width;
                              if (user_width == 0) {
                                  user_width++;   
                                  this_trans->aruser_width += 1;
                              }
                              this_trans->aruser_width += (16 + add_vnet_bits);
                              unsigned long auser_append = (this_trans->region) + 
                                                           ((unsigned long)pow(2.0, 4) * this_trans->qv) + 
                                                           ((unsigned long)pow(2.0, 8) * (this_trans->valid - 1));

                              if (add_vnet_bits != 0) {
                                   auser_append = (auser_append * 16) + this_trans->vnet;
                              }

                              for (int i=0; i < 16; i++){
                                  this_trans->auser[i] = this_trans->auser[i] +
                                                     to_string_in_binary(auser_append,(16 + add_vnet_bits));    
                              }
                         }

                         //Process the transaction
                         VecGen->Access(this_trans);
                         ((*this_slave_port).second).transactions.pop_front();
                    }


                    //Add a quit command
                    VecGen->Quit(quit_emit);

            }

            //Now the master ports
            slave_iter this_master_port;
            for (this_master_port = master_ports.begin(); this_master_port != master_ports.end(); this_master_port++) {

                    //Select correct Vector generation class
                    if ((param_s(get_slave_p(this_master_port), "protocol") == "axi") || (param_s(get_slave_p(this_master_port), "protocol") == "itb")) {
                        VecGen = &AxiVecGen;
                    } else if (param_s(get_slave_p(this_master_port), "protocol").substr(0, 3) == "apb") {
                        VecGen = &ApbVecGen;
                    } else if (param_s(get_slave_p(this_master_port), "protocol").substr(0, 3) == "ahb") {
                        VecGen = &AhbSVecGen;
                    }  else if(param_s(get_slave_p(this_master_port), "protocol") == "axi4") {
                        VecGen = &AxiVecGen;
                        //throw "AXI4 protocol detected, directed test cases are not supported\n";                  
                    } else  {
                        throw "Illegal protocol detected\n";
                    }

                    Filename = ((*this_master_port).second).xvc_name + ".m3i";

                    //Now initalise the vector generator
                    VecGen->Initialise_FRBM_gen(Filename,   ms_type_enum(1));

                    if (param_s(get_slave_p(this_master_port), "protocol").substr(0, 3) == "ahb") {
                        //Output the size comments supported by ahb 
                        VecGen->Comment("#FRS# Datawidth="    + param_s(get_slave_p(this_master_port), "data_width")   + "\n");
                        VecGen->Comment("#FRS# Addresswidth=" + param_s(get_slave_p(this_master_port), "addr_width")   + "\n\n");
                    }

                    if ((param_s(get_slave_p(this_master_port), "protocol") == "axi") || (param_s(get_slave_p(this_master_port), "protocol") == "itb") || (param_s(get_slave_p(this_master_port), "protocol") == "axi4")) {

                        //Output the size comments
                        VecGen->Comment("#FRS# Datawidth="    + param_s(get_slave_p(this_master_port), "data_width")   + "\n");
                        VecGen->Comment("#FRS# Addresswidth=" + param_s(get_slave_p(this_master_port), "addr_width")   + "\n");
                        VecGen->Comment("#FRS# IDWidth="      + param_s(get_slave_p(this_master_port), "aid_width")    + "\n");
                        
                        int user_width;
                        if (param_s(get_slave_p(this_master_port), "protocol") == "axi" || param_s(get_slave_p(this_master_port), "protocol") == "axi4"){
                           user_width = param(get_slave_p(this_master_port), "awuser_width");
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRS# awUserWidth="  + to_string_dec(16 + user_width) + "\n");
                           user_width = param(get_slave_p(this_master_port), "aruser_width");
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRS# arUserWidth="  + to_string_dec(16 + user_width) + "\n");
                        } else {
                           user_width = param(get_slave_p(this_master_port), "awuser_width");
                           int user_width_ar = param(get_slave_p(this_master_port), "aruser_width");

                           if (user_width < user_width_ar) {
                               user_width = user_width_ar;  
                           };
                           if (user_width == 0) user_width++;
                           VecGen->Comment("#FRS# awUserWidth="  + to_string_dec(16 + user_width) + "\n");
                           VecGen->Comment("#FRS# arUserWidth="  + to_string_dec(16 + user_width) + "\n");
                        };

                        user_width = param(get_slave_p(this_master_port), "wuser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRS# wUserWidth="   + to_string_dec(user_width) + "\n");
                        user_width = param(get_slave_p(this_master_port), "buser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRS# bUserWidth="   + to_string_dec(user_width) + "\n");
                        user_width = param(get_slave_p(this_master_port), "ruser_width");
                        if (user_width == 0) user_width++;
                        VecGen->Comment("#FRS# rUserWidth="   + to_string_dec(user_width) + "\n\n");

                    }

                    //send every transaction there is in the queue 
                    while (((*this_master_port).second).transactions.empty() != true) {

                         //Get the transaction
                         this_trans = &((*this_master_port).second).transactions.front();

                         //Check that the valid is not 0
                         //if ((this_trans->valid == 0) && (this_trans->direction != frbm_namespace::sync_vec)) {
                         //        throw "Illegal valid value detected\n";
                         //}
                         if (this_trans->valid == 0) {
                              this_trans->valid = 1;    
                         };

                         if (param_s(get_slave_p(this_master_port), "protocol") == "axi4") {
                             this_trans->protocol = axi4;
                         }    


                         //Modify the auser signal to contain the QV and valid value
                         if (this_trans->direction == frbm_namespace::wr) {
                              int user_width = this_trans->awuser_width;
                              if (user_width == 0) {
                                  user_width++;
                                  this_trans->awuser_width += 1;
                              }
                              this_trans->awuser_width += 16;

                              unsigned long auser_append = (this_trans->region) + 
                                                           ((unsigned long)pow(2.0, 4) * this_trans->qv) + 
                                                           ((unsigned long)pow(2.0, 8) * (this_trans->valid - 1));

                              for (int i=0; i < 16; i++){
                              this_trans->auser[i] = this_trans->auser[i] +
                                                     to_string_in_binary(auser_append,16);
                              }
                         } else {
                              int user_width = this_trans->aruser_width;
                              if (user_width == 0) {
                                  user_width++;
                                  this_trans->aruser_width += 1;
                              }
                              this_trans->aruser_width += 16;

                              unsigned long auser_append = (this_trans->region) + 
                                                           ((unsigned long)pow(2.0, 4) * this_trans->qv) + 
                                                           ((unsigned long)pow(2.0, 8) * (this_trans->valid - 1));

                              for (int i=0; i < 16; i++){
                              this_trans->auser[i] = this_trans->auser[i] +
                                                     to_string_in_binary(auser_append,16);
                              }

                         }

                         //Process this transaction
                         VecGen->Access(this_trans);
                         ((*this_master_port).second).transactions.pop_front();
                    }

                    //Add a quit command
                    VecGen->Quit(quit_emit);
            }

            //Finally the TB master
            VecGen = &AxiVecGen;

            Filename = cfg_master_name + ".m3i";

            //Now initalise the vector generator
            VecGen->Initialise_FRBM_gen(Filename,  ms_type_enum(0));

            VecGen->Comment("#FRM# Datawidth=" + external_cfg_width + "\n");
            VecGen->Comment("#FRM# Addresswidth=32\n");
            VecGen->Comment("#FRM# IDWidth=8\n");
            VecGen->Comment("#FRM# awUserWidth=8\n");
            VecGen->Comment("#FRM# arUserWidth=8\n");
            VecGen->Comment("#FRM# wUserWidth=1\n");
            VecGen->Comment("#FRM# bUserWidth=1\n");
            VecGen->Comment("#FRM# rUserWidth=1\n\n");

            //send every transaction there is in the queue 
            while (transactions.empty() != true) {
                   VecGen->Access(&transactions.front());
                   transactions.pop_front();
            }

            //Add a quit command
            VecGen->Quit(quit_emit);

            //Update the tsf file
            generate_tsf();

            return true;

       } catch (const char * error) {
           cout << "Caught Error : " << error << endl;
       };
    }


    //-----------------------------------------------------------------------
    // Very simple XML style parser to read in config file
    //-----------------------------------------------------------------------

    bool pl301::initalise(char * filename, char * top_level) {

         try {   
            //Now try and read in all the parameters and address map information
            read_config(filename);

            //Now try and set up the convertion program
            Sys.Config(top_level, &tb_regs);

            current_master = &((*slave_ports.begin()).second);
            current_slave = &((*master_ports.begin()).second);

            return true;

         } catch ( const char * error ) {
               cout << "Caught " << error << endl;     
               exit(1);
         }

    }

    //-----------------------------------------------------------------------
    // Very simple XML style parser to read in the address map and set the
    // parameters and address map required
    //-----------------------------------------------------------------------
    bool pl301::read_defines(char * filename) {

         try {

            //Open the suggested config file
            ifstream fin;
            char line[250]; 
            string sline; 
            string cline; 
            //Check that file was opened
            fin.open(filename, ifstream::in);
            if (!fin.is_open()) {
                    
              cout << "No defines file found" << endl;
              return 0;

            } else {

              while (fin.good()) {
                
                //Read in a line
                fin.getline(line, 249);

                //convert to string and add a white space character at the end
                sline = string(line) + ' '; 

                //Now go though the string and ensure there is no duplicate white space
                cline.clear();
                for (unsigned int i = 0; i < sline.length()-1; i++) {
                    if (not isspace(sline[i])) {    
                       cline += sline[i];    
                    } else {
                       //Only add if the next bit isn't space     
                       if (not isspace(sline[i+1])) {
                           cline += sline[i];    
                       }
                    }
                }

                //If this is a define 
                if (cline.find("`define ") != string::npos) {
                    cline = cline.substr(cline.find("`define ") + 8);  
                    //record the defines values
                    string defname = "`" + cline.substr(0, cline.find(" "));
                    string defvalue = cline.substr(cline.find(" ") + 1, cline.find_first_of(" \n", cline.find(" ") + 1) - (cline.find(" ") + 1));
                    defines[defname] = defvalue;
                }

              }

              //close the file
              fin.close();
              //report sucesss
              cout << "Defines file read sucessfully" << endl;

            }

            //Print out the defines
            map<string, string>::iterator def_iter;
            cout << "Found defines are" << endl;
            for (def_iter = defines.begin(); def_iter != defines.end(); def_iter++) {
                 cout << def_iter->first << " = " << def_iter->second << endl;
            }

            return true;

         } catch ( const char * error ) {
               cout << "Caught " << error << endl;     
               exit(1);
         }
    }

    //-----------------------------------------------------------------------
    // Very simple XML style parser to read in the address map and set the
    // parameters and address map required
    //-----------------------------------------------------------------------

    bool pl301::read_config(char * filename) {

         try {

            //Read in the configuration file 
            DomReader.read(filename);
            string fname = string(filename);
            cout << "opened " << filename << endl;
            master_port * new_master;
            slave_port * new_slave;
            multimap<int, string> rsb_addr_map;
            tb * new_tb;
            cfg_master_name = "AXIM_config";

            //Default the external config width
            external_cfg_width = "32";

            //Now read in the defines
            string def_fname = "../../../../nic400/verilog/nic400_closure_" + DomReader.get_value(DomReader.top, "/tbench/xmlcfg") + "_defs.v";
            read_defines(const_cast<char *>(def_fname.c_str()));

            //Go through all the tb blocks
            vector<Node *> tb_blocks;
            vector<Node *> spirit_files;
            tb_blocks = DomReader.get_nodes(DomReader.top, "/tbench/tb");

            vector<Node*>::iterator node_iter;
            vector<Node*>::iterator spirit_iter;
            for (node_iter = tb_blocks.begin(); node_iter != tb_blocks.end(); node_iter++) {

                //get the name field  
                string tb_name = DomReader.get_value((*node_iter), "name");

                //Check name is defined
                if (tb_name == "<UNDEF>") {
                    throw "Ending unnamed tb block";
                }

                //Get the spirit file
                spirit_files = DomReader.get_nodes((*node_iter), "spirit_file");

                //If the spirit file is defined
                if (spirit_files.size() > 0) {

                   string apb_port = DomReader.get_value((*node_iter), "apb_port");     
                   if (apb_port == "<UNDEF>") {
                      throw "You must specify an apb_port number if a spirit_file is referenced";
                   }

                   //If the tb_name DUT populate the address map 
                   if (tb_name == "DUT") {
                       vector<Node *> rsb_nodes;    
                       vector<Node*>::iterator rsb_iter;
                       rsb_nodes = DomReader.get_nodes(DomReader.top, "/tbench/rsb_node");

                       for (rsb_iter = rsb_nodes.begin(); rsb_iter != rsb_nodes.end(); rsb_iter++) {
                           rsb_addr_map.insert(pair<int,string>(DomReader.get_value_i((*rsb_iter), "address"), DomReader.get_value((*rsb_iter), "block")));    
                       }

                       //Set teh the external config with if it is defined
                       string cfg_width = DomReader.get_value((*node_iter), "data_width");     
                       if (cfg_width != "<UNDEF>") {
                          external_cfg_width = cfg_width;    
                       }

                       string cfgname =  DomReader.get_value((*node_iter), "cfg_master_name");
                       if (cfgname != "<UNDEF>") {
                           cfg_master_name = cfgname;    
                       }

                   }

                   //Record the tb component .. in case it's useful later
                   new_tb = new tb;
                   new_tb->name = tb_name;
                   new_tb->number = atoi(apb_port.c_str());
                   tb_comps[new_tb->name] = *new_tb;

                   //Read in the spirit file register maps

                   for (spirit_iter = spirit_files.begin(); spirit_iter != spirit_files.end(); spirit_iter++) {
                
                         string spirit_name = DomReader.get_value(*spirit_iter);
                         //cout << "Attempting to read " << spirit_name << " name = " << tb_name << endl;
                         if(tb_name == "DUT"){
                            tb_regs.read_spirit(spirit_name.c_str(), tb_name, new_tb->number, false, &rsb_addr_map);
                         }else{
                            tb_regs.read_spirit(spirit_name.c_str(), tb_name, new_tb->number);
                         }

                   }

                }
            }

            //Go through all the tb_master blocks 
            vector<Node *> tb_masters;
            tb_masters = DomReader.get_nodes(DomReader.top, "/tbench/tb_master");

            for (node_iter = tb_masters.begin(); node_iter != tb_masters.end(); node_iter++) {

                //get the name field  
                string master_name = DomReader.get_value((*node_iter), "name");

                //Check name is defined
                if (master_name == "<UNDEF>") {
                    throw "Ending unnamed tb_master";
                }

                //Create slave_port
                new_slave = new slave_port;
                new_slave->name = master_name;

                //Get the spirit file
                spirit_files = DomReader.get_nodes((*node_iter), "spirit_file");

                //If the spirit file is defined
                if (spirit_files.size() > 0) {

                   string apb_port = DomReader.get_value((*node_iter), "apb_port");     
                   if (apb_port == "<UNDEF>") {
                      throw "You must specify an apb_port number if a spirit_file is referenced";
                   }

                   new_slave->number = atoi(apb_port.c_str());

                   //Read in the spirit file register maps
                   for (spirit_iter = spirit_files.begin(); spirit_iter != spirit_files.end(); spirit_iter++) {

                       //Read in the register map(s)
                       string spirit_name = DomReader.get_value(*spirit_iter);
                       //cout << "Attempting to read " << spirit_name << " name = " << master_name << endl;
                       tb_regs.read_spirit(spirit_name.c_str(), master_name, new_slave->number); 

                   }

                }

                //Get the XVC name
                new_slave->xvc_name = DomReader.get_value((*node_iter), "xvc");

                //Register the port
                slave_ports[master_name] = *new_slave;
                
                //Everthing ok far... record parameters    
                slave_ports[master_name].parameters = (*node_iter);

                //Get the address_ranges node
                slave_ports[master_name].addr_map = DomReader.get_first(*node_iter, "address_ranges");

                //Check that the address map node is defined
                if (slave_ports[master_name].addr_map == NULL) {
                    throw "Failed to find address map";
                }

            }

            //Go through all the tb_slave blocks 
            vector<Node *> tb_slaves;
            tb_slaves = DomReader.get_nodes(DomReader.top, "/tbench/tb_slave");

            for (node_iter = tb_slaves.begin(); node_iter != tb_slaves.end(); node_iter++) {

                //get the name field  
                string slave_name = DomReader.get_value((*node_iter), "name");

                //Check name is defined
                if (slave_name == "<UNDEF>") {
                    throw "Ending unnamed tb_slave";
                }

                //Create master_port
                new_master = new master_port;
                new_master->name = slave_name;

                //Get the spirit file
                spirit_files = DomReader.get_nodes((*node_iter), "spirit_file");

                //If the spirit file is defined
                if (spirit_files.size() > 0) {

                   string apb_port = DomReader.get_value((*node_iter), "apb_port");     
                   if (apb_port == "<UNDEF>") {
                      throw "You must specify an apb_port number if a spirit_file is referenced";
                   }

                   new_master->number = atoi(apb_port.c_str());

                   //Read in the spirit file register maps
                   for (spirit_iter = spirit_files.begin(); spirit_iter != spirit_files.end(); spirit_iter++) {

                      //Read in the register map
                      string spirit_name = DomReader.get_value(*spirit_iter);
                      //cout << "Attempting to read " << spirit_name << " name = " << slave_name << endl;
                      tb_regs.read_spirit(spirit_name.c_str(), slave_name, new_master->number); 
                   }

                }

                //Get the XVC name
                new_master->xvc_name = DomReader.get_value((*node_iter), "xvc");

                //Register port
                master_ports[new_master->name] = *new_master;

                //Everthing ok far... record parameters    
                master_ports[slave_name].parameters = (*node_iter);

            }      

         if (master_ports.size() == 0) {
            throw "At least one master_port (tb_slave) must be defined\n";
         }

         if (slave_ports.size() == 0) {
            throw "At least one slave_port (tb_master) must be defined\n";
         }

         cout << "Address map and parameter file read sucessfully" << endl;

         return true;

         } catch ( const char * error ) {
               cout << "Caught " << error << endl;     
               exit(1);
         }

    }

    //-----------------------------------------------------------------------
    // General purpose methods methods
    //-----------------------------------------------------------------------

       string to_string(arm_uint64 data) {

                ostringstream data_str;

                //convert to string
                data_str << hex << data;

                return data_str.str();

       }

      string to_string(arm_uint32 data, uint bits) {

        ostringstream data_str;
        //convert to string
        data_str << setw(bits) << setfill('0') << hex << data;
        return data_str.str();
       };

       string to_string_dec(arm_uint64 data) {

                ostringstream data_str;

                //convert to string
                data_str << dec << data;

                return data_str.str();

       }
      // The next function converts a uint32 into a string in binary format  
      string to_string_in_binary(arm_uint32 data, uint length) {

       string temp_string = "";
       arm_uint32   temp_data   = data;
       //convert to string
       for(int i=0; i< length; i++)
       {
         temp_string.insert(0,to_string(temp_data%2,1));
         temp_data = temp_data >>1; 
       }  

       return temp_string;
     };
    //-----------------------------------------------------------------------
    // Simple helper methods to get slave_ports and master_ports 
    //-----------------------------------------------------------------------

       slave_port get_master(master_iter master_iterator) {

               return ((*master_iterator).second);
       }

       slave_port * get_master_p(master_iter master_iterator) {

               return &((*master_iterator).second);

       }

       master_port get_slave(slave_iter slave_iterator) {

               return ((*slave_iterator).second);
       }

       master_port * get_slave_p(slave_iter slave_iterator) {

               return &((*slave_iterator).second);
       }

       tb get_tb(tb_iter tb_iterator) {

               return ((*tb_iterator).second);
       }

       tb * get_tb_p(tb_iter tb_iterator) {

               return &((*tb_iterator).second);
       }

    //-----------------------------------------------------------------------
    // Parmeter extraction routines
    //-----------------------------------------------------------------------
   
      bool def_s_param(string param_name) {

              //call param with the current_slave
              return def_s_param(current_slave, param_name);
      }

      bool def_s_param(master_port * target_master_port, string param_name) {

              Dom DomReader;
              DomReader.top = target_master_port->parameters;

              if (DomReader.top == NULL) {
                      cout << "No parameters found while looking for : " << param_name << endl;
                      exit(1);
              }

              //Return True or false
              return DomReader.get_value(target_master_port->parameters, param_name) != "<UNDEF>";
      }

      bool def_m_param(string param_name) {

              //call param with the current_slave
              return def_m_param(current_master, param_name);
      }
 
      bool def_m_param(slave_port * target_slave_port, string param_name) {

              Dom DomReader;
              DomReader.top = target_slave_port->parameters;

              if (DomReader.top == NULL) {
                      cout << "No parameters found while looking for : " << param_name << endl;
                      exit(1);
              }

              //Return True or false
              return DomReader.get_value(target_slave_port->parameters, param_name) != "<UNDEF>";
      }     

      int s_param(string param_name) {

              //call param with the current_slave
              return param(current_slave, param_name);
      }

      unsigned long s_param_l(string param_name) {

              //call param_l with the current_slave
              return param_l(current_slave, param_name);
 
      }

      string s_param_s(string param_name) {

              //call param_s with the current_slave
              return param_s(current_slave, param_name);

      }

      int m_param(string param_name) {

              //call param with the current_master
              return param(current_master, param_name);
      }

      unsigned long m_param_l(string param_name) {

              //call param_l with the current_master
              return param_l(current_master, param_name);

      }

      string m_param_s(string param_name) {

              //call param_s with the current_master
              return param_s(current_master, param_name);
      }

      int param(master_port * target_master_port, string param_name) {

              //convert to integer and return
              return atoi(param_s(target_master_port, param_name).c_str());
      }

      unsigned long param_l(master_port * target_master_port, string param_name) {

              //convert to integer and return
              return strtoul(param_s(target_master_port, param_name).c_str(), NULL, 0);
      }

      string param_s(master_port * target_master_port, string param_name) {

              Dom DomReader;
              DomReader.top = target_master_port->parameters;

              if (DomReader.top == NULL) {
                      cout << "No parameters found while looking for : " << param_name << endl;
                      exit(1);
              }

              //try to find parameter
              if (DomReader.get_value(target_master_port->parameters, param_name) == "<UNDEF>") {
                      cout << "Failed to find slave parameter " << param_name << endl;
                      exit(1);
              }

              return DomReader.get_value(target_master_port->parameters, param_name);
      }

      int param(slave_port * target_slave_port, string param_name) {

              //convert to integer and return
              return atoi(param_s(target_slave_port, param_name).c_str());
      }

      unsigned long param_l(slave_port * target_slave_port, string param_name) {

              //convert to integer and return
              return strtoul(param_s(target_slave_port, param_name).c_str(), NULL, 0);
      }

      string param_s(slave_port * target_slave_port, string param_name) {

              Dom DomReader;
              DomReader.top = target_slave_port->parameters;

              if (DomReader.top == NULL) {
                      cout << "No parameters found while looking for : " << param_name << endl;
                      exit(1);
              }

              //try to find parameter
              if (DomReader.get_value(target_slave_port->parameters, param_name) == "<UNDEF>") {
                      cout << "Failed to find slave parameter " << param_name << endl;
                      exit(1);
              }

              return DomReader.get_value(target_slave_port->parameters, param_name);

      }

    //-----------------------------------------------------------------------
    // Get amba_size return the encoded version of
    //-----------------------------------------------------------------------

      amba_size to_amba_size(string size) {

        switch(atoi(size.c_str()))
        {
         case 8:
            return byte;  
         case 16:
            return half; 
         case 32:
            return size32;  
         case 64:
            return size64;  
         case 128:
            return size128;
         case 256:
            return size256;  
         case 512:
            return size512;  
         case 1024:
            return size1024;  
         default: 
            assert(0);
        }
      }

    //-----------------------------------------------------------------------
    // Read methods
    //-----------------------------------------------------------------------

       void pl301::read(unsigned long long address, int data, int mask, int id, int emit, int wait, bool secure) {

               //call read with the current_slave and current_master
               read(current_master, current_slave, address, data, mask, id, emit, wait, secure);

       }

       void pl301::read(slave_port * target_slave_port, unsigned long long address, int data, int mask, int id, int emit, int wait, bool secure) {

               //call read with the target_slave_port and current_slave
               read(target_slave_port, current_slave, address, data, mask, id, emit, wait, secure);
       }

       void pl301::read(master_port * target_master_port, unsigned long long address, int data, int mask, int id, int emit, int wait, bool secure) {

               //call read with the current_master and target_master_port
               read(current_master, target_master_port, address, data, mask, id, emit, wait, secure);
       }


       void pl301::read(slave_port * target_slave_port, master_port * target_master_port,unsigned long long address, int data, int mask, int id, int emit, int wait, bool secure)  {

               //if target_slave_port then the config port should be used
               if (target_slave_port == NULL) {
                    tb_read("DUT", address, data, mask, id, emit, wait, tb_comment);
                    tb_comment = "";
                    return;
               }
               
               //Create a transaction
               transaction * trans = new transaction(frbm_namespace::read);

               trans->data[0] = "00000000" + to_string((unsigned int)data);
               trans->mask[0] = "00000000" + to_string((unsigned int)mask);
               trans->id = id;
               if (secure)
                 trans->prot &= 0xd;
               else  
                 trans->prot |= 0x2;

               trans->demit_code[0] = emit;
               trans->await_code = wait;
               trans->address = address;

               //Modify the address into a valid region if region is specified
               if (target_master_port != NULL) {
                   address_offset(target_slave_port, target_master_port, trans);
               } else {
                    if (trans->valid == 0) trans->valid = 1;
               }

               //call access
               access(target_slave_port, *trans);
       }


       void pl301::read(transaction this_trans) {

               //call read with the current slave and master
               read(current_master, current_slave, this_trans);
       }

       void pl301::read(slave_port * target_slave_port, transaction this_trans) {

               //call read with the target_slave_port and current_master
               read(target_slave_port, current_slave, this_trans);
       }

       void pl301::read(master_port * target_master_port, transaction this_trans) {

               //call read with the target_master_port and current_slave
               read(current_master, target_master_port, this_trans);
       }

       void pl301::read(slave_port * target_slave_port, master_port * target_master_port, transaction this_trans) {

               //Check it's a read and call access
               if (this_trans.direction != frbm_namespace::read) throw "Incorrect direction";

               //Modify the address into a valid region
               address_offset(target_slave_port, target_master_port, &this_trans);

               //Send the transaction
               access(target_slave_port, this_trans);
       }

    //-----------------------------------------------------------------------
    // Write methods
    //-----------------------------------------------------------------------

       void pl301::write(unsigned long long address, int data, int strobes, int id, int emit, int wait, bool secure) {

               //call write with the current_slave and current_master
               write(current_master, current_slave, address, data, strobes, id, emit, wait, secure);

       }

       void pl301::write(slave_port * target_slave_port, unsigned long long address, int data, int strobes, int id, int emit, int wait, bool secure) {

               //call write with the target_slave_port and current_slave
               write(target_slave_port, current_slave, address, data, strobes, id, emit, wait, secure);
       }

       void pl301::write(master_port * target_master_port, unsigned long long address, int data, int strobes, int id, int emit, int wait, bool secure) {

               //call write with the current_master and target_master_port
               write(current_master, target_master_port, address, data, strobes, id, emit, wait, secure);
       }


       void pl301::write(slave_port * target_slave_port, master_port * target_master_port, unsigned long long address, int data, int strobes, int id, int emit, int wait, bool secure)  {

               //if target_slave_port then the config port should be used
               if (target_slave_port == NULL) {
                       
                    tb_write("DUT", address, data, strobes, id, emit, wait, tb_comment);
                    tb_comment == "";
                    return;
               }

               //Create a treansaction
               transaction * trans = new transaction(frbm_namespace::write);

               trans->data[0] = "00000000" + to_string((unsigned int)data);
               trans->strobe[0] = "00000000" + to_string(strobes);
               trans->id = id;
               if (secure)
                 trans->prot &= 0xd;
               else  
                 trans->prot |= 0x2;

               trans->remit_code = emit;
               trans->await_code = wait;
               trans->dwait_code[0] = wait;
               trans->address = address;

               //Modify the address into a valid region
               if (target_master_port != NULL) {
                   address_offset(target_slave_port, target_master_port, trans);
               } else {
                    if (trans->valid == 0) trans->valid = 1;
               }

               //call access
               access(target_slave_port, *trans);
       }


       void pl301::write(transaction this_trans) {

               //call write with the current slave and master
               write(current_master, current_slave, this_trans);
       }

       void pl301::write(slave_port * target_slave_port, transaction this_trans) {

               //call write with the target_slave_port and current_slave
               write(target_slave_port, current_slave, this_trans);
       }

       void pl301::write(master_port * target_master_port, transaction this_trans) {

               //call write with the target_slave_port and current_master
               write(current_master, target_master_port, this_trans);
       }

       void pl301::write(slave_port * target_slave_port, master_port * target_master_port, transaction this_trans) {

               //Check it's a write and call access
               if (this_trans.direction != frbm_namespace::write) throw "Incorrect direction";

               //Modify the address into a valid region
               address_offset(target_slave_port, target_master_port, &this_trans);

               //Send the transaction
               access(target_slave_port, this_trans);
       }

    //-----------------------------------------------------------------------
    // General Access methods - All access to the transaction queue go through 
    //                          these two methods
    //-----------------------------------------------------------------------
 
       //Address checking access function
       void pl301::access(transaction this_trans) {

               if (this_trans.valid == 0) {
                   //Modify the address into a valid region
                   address_offset(current_master, current_slave, &this_trans);
               }

               access(current_master, this_trans);

       }

       //Access
       void pl301::access(slave_port * this_slave_port, transaction this_trans) {

               transaction * this_trans_ptr;

               //Set the parameters for all the widths
               this_trans.addr_width   = (arm_uint8)param(this_slave_port, "addr_width");
               this_trans.id_width     = (arm_uint8)param(this_slave_port, "aid_width");
               this_trans.awuser_width = (arm_uint8)param(this_slave_port, "awuser_width");
               this_trans.aruser_width = (arm_uint8)param(this_slave_port, "aruser_width");
               this_trans.wuser_width  = (arm_uint8)param(this_slave_port, "wuser_width");
               this_trans.buser_width  = (arm_uint8)param(this_slave_port, "buser_width");
               this_trans.ruser_width  = (arm_uint8)param(this_slave_port, "ruser_width");

               //Set the protocol to ahb if required
               if (param_s(this_slave_port, "protocol") == "ahb") {
                  this_trans.protocol = frbm_namespace::ahb;
               }

               //Tidy the transaction to ensure data, mask and strobes are all valid
               this_trans.tidy();

               //Set an appropriate vnet (if necessary)
               set_vnet(this_slave_port, &this_trans); 

               if ((*this_slave_port).comment.empty() != true) {

                       //Check there isn't also a comment in the transaction
                       if (this_trans.comment.empty() != true) {
                              cout << "Warning ignoring comment ( " << (*this_slave_port).comment << " ) on slave port " << (*this_slave_port).name << endl;  
                       } else {
                              //copy comment into transaction
                              this_trans.comment =  (*this_slave_port).comment;
                              (*this_slave_port).comment = "";
                       }

                       //Clear comment on port
                       (*this_slave_port).comment.clear();
               }

               //Back up the comment
               string copy_comment = this_trans.comment;
               this_trans.comment.clear();

               //create a list of transactions
               deque<transaction> transactions_out;

               //If we need to add the siid bits to this transfer
               if (param_s(this_slave_port, "add_siid") == "true") {
                       int siid_width  = param(this_slave_port, "siid_width");
                       int iid_width   = param(this_slave_port, "iid_width");
                       int siid        = param(this_slave_port, "siid");
                       int iid         = param(this_slave_port, "iid");
                       int total_width = param(this_slave_port, "pl_id_width");
                       int vid_width   = param(this_slave_port, "aid_width");
                       this_trans.id   = (iid << (total_width - iid_width)) +
                                         ((this_trans.id % (1 << vid_width)) << siid_width) +
                                         siid;
               }
              
              //if block is amib and the compress_id is true change the id 
              if (param_s(this_slave_port,"block_type") == "amib")
              {
                if(param_s(this_slave_port,"compress_id")== "true")
                {
                       string iid_siid = clist(param_s(this_slave_port, "in_id_list"), 0);//first valid combination of iid and siid
                       int siid  = (int)strtoul(iid_siid.c_str(), NULL, 2) % (1 << param(this_slave_port,"siid_width"));
                       int iid   = (int)strtoul(iid_siid.c_str(), NULL, 2) >> param(this_slave_port,"siid_width");
                       this_trans.id = (iid << (param(this_slave_port,"pl_id_width") - param(this_slave_port,"iid_width"))) + 
                                       (this_trans.id << param(this_slave_port,"siid_width")) + siid; 
                }
              }

               //Set the transaction location
               this_trans.location = param_s(this_slave_port, "sim_start_point");
               this_trans.final_dest = param_s(this_slave_port, "sim_end_point");

               //If this a sync add it to the queue now and return
               if (this_trans.direction == frbm_namespace::sync_vec) {
                    (*this_slave_port).transactions.push_back(this_trans);
                    return;   
               }
                
               //Run the transaction thu the models
               transactions_out = Sys.Run(&this_trans);

               //Run the reverse direction
               this_trans_ptr = Sys.Run_Reverse(&transactions_out);
               this_trans = *this_trans_ptr;

               //Reset the comment
               this_trans.comment = copy_comment;
               
               //Running through the models will have updated the input transaction responses if required
               //But first correct vnet to external format
               rev_vnet(this_slave_port, &this_trans);
               (*this_slave_port).transactions.push_back(this_trans);

               //Now send all transactions in the app
               string port_name;
               for (deque<transaction>::iterator this_trans = transactions_out.begin(); this_trans != transactions_out.end(); this_trans++) { 

                       //Set the master comment on the first transaction only
                       if (this_trans == transactions_out.begin()) {
                                 (*this_trans).comment = (*this_slave_port).comment_m;
                                 (*this_slave_port).comment_m = "";
                       }


			//if location contains a list of output locations (comma separated values) instead of single value
			string port_list = (*this_trans).location;
			while (port_list != ""){
				if (port_list.find(",") != string::npos){	//it is not last port
					(*this_trans).location = port_list.substr(0,  port_list.find(","));
					port_list =  port_list.substr( port_list.find(",") + 1);
				}
				else{
					(*this_trans).location = port_list;
					port_list = "";
				}
                       		
				//Work out the port_name
                       		port_name = (*this_trans).location.substr(0, (*this_trans).location.find("."));   
	
	       	                //See if the port_name exists as an output
       		                if (master_ports.find(port_name) == master_ports.end()) {
		
       		                        //if not see if the second part of the port_name does (this should be the case if we're only
       		                        //testing one block
       		                        if (master_ports.find((*this_trans).location.substr((*this_trans).location.find(".") + 1)) != master_ports.end()) {
       		                           port_name = (*this_trans).location.substr((*this_trans).location.find(".") + 1);
       		                           
       		                        } else {
		
       		                            throw "Transaction arrived at non-existant port";
       		                        }
       		                }
	
                      		 //Set the parameters for all the widths
                       		(*this_trans).addr_width   = (arm_uint8)param(&master_ports[port_name], "addr_width");
                       		(*this_trans).id_width     = (arm_uint8)param(&master_ports[port_name], "aid_width");
                       		(*this_trans).awuser_width  = (arm_uint8)param(&master_ports[port_name], "awuser_width");
                       		(*this_trans).aruser_width  = (arm_uint8)param(&master_ports[port_name], "aruser_width");
                       		(*this_trans).wuser_width   = (arm_uint8)param(&master_ports[port_name], "wuser_width");
                       		(*this_trans).buser_width   = (arm_uint8)param(&master_ports[port_name], "buser_width");
                       		(*this_trans).ruser_width   = (arm_uint8)param(&master_ports[port_name], "ruser_width");
       	               		 //Send the transaction to the correct port
       	                	access(&master_ports[port_name], (*this_trans));
			}
               }

       }

       void pl301::access(master_port * this_master_port, transaction this_trans) {

               //Comments will only ever be in the transaction in this case
               (*this_master_port).transactions.push_back(this_trans);
       }

    //-----------------------------------------------------------------------
    // Comment methods
    //-----------------------------------------------------------------------

       void pl301::comment(string comm) {

               //Call comment with current master
               comment(current_master, comm);
       }

       void pl301::comment(slave_port * this_slave_port, string comm) {

               if (this_slave_port == NULL) {
                    tb_comment = comm;
                    return;
               }

               //Check there is no existing comment
               if ((*this_slave_port).comment.empty() != true) {
                       cout << "Warning replacing comment on PL301 slave port " << (*this_slave_port).name << endl;
               }

               //Set the comment;
               (*this_slave_port).comment = comm;
       }

       void pl301::comment_m(string comm) {

               comment(current_slave, comm);
       }

       void pl301::comment(master_port * this_master_port, string comm) {

               //Check there is no existing comment
               if ((*this_master_port).comment.empty() != true) {
                       cout << "Warning replacing comment on PL301 master port " << (*this_master_port).name << endl;
               }

               //Set the comment;
               (*this_master_port).comment = comm;
       }

    //-----------------------------------------------------------------------
    // Sync methods
    //-----------------------------------------------------------------------

       void pl301::sync() {
               //call sync on the current master
               sync(current_master);
       }

       void pl301::sync_cfg() {
               
               //Create a transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::sync_vec);
               transactions.push_back(*trans);

       }

       void pl301::sync(slave_port * target_slave_port) {

               //Create a transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::sync_vec);

               //Do not allow duplicate syncs
               if ((*target_slave_port).transactions.empty()) {
                   access(target_slave_port, *trans);
               } else if ((*target_slave_port).transactions.back().direction != frbm_namespace::sync_vec) {
                   access(target_slave_port, *trans);
               }
       }

       void pl301::sync(master_port * target_master_port) {

               //Create a transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::sync_vec);

               if ((*target_master_port).transactions.empty()) {
                   access(target_master_port, *trans);
               } else if ((*target_master_port).transactions.back().direction != frbm_namespace::sync_vec) {
                   access(target_master_port, *trans);
               }
       }

       void pl301::sync_all() {

               //add a sync to all master_ports and slave_ports
               master_iter this_slave_port;
               for (this_slave_port = slave_ports.begin(); this_slave_port != slave_ports.end(); this_slave_port++) {
                       sync(&((*this_slave_port).second));
               }

               slave_iter this_master_port;
               for (this_master_port = master_ports.begin(); this_master_port != master_ports.end(); this_master_port++) {
                       sync(&((*this_master_port).second));
               }
       }
       
    //-----------------------------------------------------------------------
    // Is path methods - check for a route between a master and slave
    //-----------------------------------------------------------------------

       bool pl301::is_path(int valid_bit, bool secure){

               return is_path(current_master, current_slave, valid_bit, secure);
       }

       bool pl301::is_path(slave_port * source_slave, int valid_bit, bool secure){

               return is_path(source_slave, current_slave, valid_bit, secure);
       }

       bool pl301::is_path(master_port * target_master_port, int valid_bit, bool secure){

               return is_path(current_master, target_master_port, valid_bit, secure);
       }

       bool pl301::is_path(slave_port * source_slave, master_port * target_master_port, int valid_bit, bool secure){

               vector<addr_range *> current_address_map;

               //Get a list of all the available address ranges
               current_address_map = get_address_map(source_slave, secure);

               return is_path(&current_address_map, current_master, target_master_port, valid_bit);
       }

       bool pl301::is_path(vector<addr_range *> * current_address_map, slave_port * source_slave, master_port * target_master_port, int valid_bit){

               //Determine target name
               string target_name = param_s(target_master_port, "addr_map_target");
               int valid_width = param(target_master_port, "valid_width");

               //Now look through all the connections and see if there is one with the correct valid  
               vector<addr_range *>::iterator addr_map_iter;
               for (addr_map_iter = current_address_map->begin(); addr_map_iter != current_address_map->end(); addr_map_iter++) {

                      //if the target is correct
                      if ((*addr_map_iter)->master_port == target_name) {
                          //If valid bit is zero any connection will do
                          if (valid_bit == 0) {
                               return true;
                          } else {
                               //Check valid_bit <= valid_width  
                               return (valid_bit <= valid_width);
                          }
                      }
               }

               //default is no connection 
               return false;
       }

    //-----------------------------------------------------------------------
    // latency methods - returns the idle latency of a route between master and slave
    //-----------------------------------------------------------------------
     
       int pl301::latency(string channel){

               return latency(current_master, current_slave, channel);
       }

       int pl301::latency(slave_port * source_slave, string channel){

               return latency(source_slave, current_slave, channel);
       }

       int pl301::latency(master_port * target_master_port, string channel){

               return latency(current_master, target_master_port, channel);
       }

       int pl301::latency(slave_port * source_slave, master_port * target_master_port, string channel){

               try {

                  map<string,string> reg_types;     
                  reg_types["`RS_REGD"] = "1";
                  reg_types["`RS_FWD_REG"] = "1";
                  reg_types["`RS_STATIC_BYPASS"] = "0";
                  reg_types["`RS_REV_REG"] = "0";

                  vector<Node *> slaves;
                  slaves  = DomReader.get_nodes(source_slave->parameters, "register_stages/slave");

                  //Find the slave with the correct name
                  vector<Node *>::iterator s_iter;
                  for (s_iter = slaves.begin(); s_iter != slaves.end(); s_iter++) {

                        //Select the correct slave
                        if (DomReader.get_value(*s_iter, "name") == target_master_port->name) {
                              vector<Node *> latency_terms;
                              vector<Node *>::iterator latency_iter;
                              vector<Node *> reg_terms;
                              vector<Node *>::iterator reg_iter;
                              int total_latency = 0;

                              //get all the relevant fields
                              latency_terms = DomReader.get_nodes(*s_iter, channel + "/latency");
                              reg_terms     = DomReader.get_nodes(*s_iter, channel + "/reg");

                              string reg_string;
                              for (reg_iter = reg_terms.begin(); reg_iter != reg_terms.end(); reg_iter++) {

                                   reg_string = DomReader.get_value(*reg_iter);

                                   //Check for `define replacement
                                   if (defines.find(reg_string) != defines.end()) {
                                        reg_string = defines[reg_string];
                                   }
    
                                   //Check for value in reg_types map
                                   if (reg_types.find(reg_string) != reg_types.end()) {
                                        reg_string = reg_types[reg_string];
                                   }

                                   //Add reg string to the latency
                                   //This should return add 0 if not a legal number
                                   total_latency += atoi(reg_string.c_str());
                              }


                              string latency_string;
                              for (latency_iter = latency_terms.begin(); latency_iter != latency_terms.end(); latency_iter++) {

                                   latency_string = DomReader.get_value(*latency_iter);

                                   //Check for `define replacement
                                   if (defines.find(latency_string) != defines.end()) {
                                        latency_string = defines[latency_string];
                                   }
    
                                   //Check for value in reg_types map
                                   if (reg_types.find(latency_string) != reg_types.end()) {
                                        latency_string = reg_types[latency_string];
                                   }

                                   //Add latency string to the latency
                                   //This should return add 0 if not a legal number
                                   total_latency += atoi(latency_string.c_str());
                              }
                                cout << total_latency << endl;
                              return total_latency; 
                        }
                  }

                  //throw an error
                  throw "Failed to find required latency information";
                 
               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }

    //-----------------------------------------------------------------------
    // depth methods - returns the idle depth of a route between master and slave
    //-----------------------------------------------------------------------
     
       int pl301::depth(string channel){

               return depth(current_master, current_slave, channel);
       }

       int pl301::depth(slave_port * source_slave, string channel){

               return depth(source_slave, current_slave, channel);
       }

       int pl301::depth(master_port * target_master_port, string channel){

               return depth(current_master, target_master_port, channel);
       }

       int pl301::depth(slave_port * source_slave, master_port * target_master_port, string channel){

               try {

                  map<string,string> reg_types;     
                  reg_types["`RS_REGD"] = "2";
                  reg_types["`RS_FWD_REG"] = "1";
                  reg_types["`RS_STATIC_BYPASS"] = "0";
                  reg_types["`RS_REV_REG"] = "1";

                  vector<Node *> slaves;
                  slaves  = DomReader.get_nodes(source_slave->parameters, "register_stages/slave");

                  //Find the slave with the correct name
                  vector<Node *>::iterator s_iter;
                  for (s_iter = slaves.begin(); s_iter != slaves.end(); s_iter++) {

                        cout << "checking " <<  DomReader.get_value(*s_iter, "name") << " channel " << channel << endl;
                       
                        //Select the correct slave
                        if (DomReader.get_value(*s_iter, "name") == target_master_port->name) {
                             
                              vector<Node *> depth_terms;
                              vector<Node *>::iterator depth_iter;
                              vector<Node *> reg_terms;
                              vector<Node *>::iterator no_iter;
                              vector<Node *> no_regs;
                              vector<Node *>::iterator reg_iter;
                              int total_depth = 0;

                              depth_terms = DomReader.get_nodes(*s_iter, channel + "/depth");
                              reg_terms     = DomReader.get_nodes(*s_iter, channel + "/reg");
                              no_regs     = DomReader.get_nodes(*s_iter, channel + "/no_reg");

                              string reg_string, no_reg;
                              for (reg_iter = reg_terms.begin(); reg_iter != reg_terms.end(); reg_iter++) {

                                   reg_string = DomReader.get_value(*reg_iter);

                                   //Check for `define replacement
                                   if (defines.find(reg_string) != defines.end()) {
                                        reg_string = defines[reg_string];
                                   }
                    
                                   //Check for value in reg_types map
                                   if (reg_types.find(reg_string) != reg_types.end()) {
                                        reg_string = reg_types[reg_string];
                                   }

                                   //Add reg string to the depth
                                   //This should return add 0 if not a legal number
                                   total_depth += atoi(reg_string.c_str());
                              }

                                //Now subtract master port registers as they dont affect buffering
                                if (no_regs.begin() != no_regs.end()){
                                   no_reg = DomReader.get_value(*(no_regs.begin()));

                                   //Check for `define replacement
                                   if (defines.find(no_reg) != defines.end()) {
                                        no_reg = defines[no_reg];
                                   }
                    
                                   //Check for value in reg_types map
                                   if (reg_types.find(no_reg) != reg_types.end()) {
                                        no_reg = reg_types[no_reg];
                                   }

                                   //Add reg string to the depth
                                   //This should return add 0 if not a legal number
                                   total_depth -= atoi(no_reg.c_str());
                               }

                              //Go through all the depth nodes and add 
                              string depth_string;
                              for (depth_iter = depth_terms.begin(); depth_iter != depth_terms.end(); depth_iter++) {

                                   depth_string = DomReader.get_value(*depth_iter);

                                   //Check for `define replacement
                                   if (defines.find(depth_string) != defines.end()) {
                                        depth_string = defines[depth_string];
                                   }
    
                                   //Check for value in reg_types map
                                   if (reg_types.find(depth_string) != reg_types.end()) {
                                        depth_string = reg_types[depth_string];
                                   }

                                   //Add depth string to the depth
                                   //This should return add 0 if not a legal number
                                   total_depth += atoi(depth_string.c_str());
                              }

                              return total_depth; 
                        }
                  }

                  //throw an error
                  throw "Failed to find required depth information";
                 
               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }

       bool pl301::master_regs(string channel){

               return master_regs(current_master, current_slave, channel);
       }

       bool pl301::master_regs(slave_port * source_slave, string channel){

               return master_regs(source_slave, current_slave, channel);
       }

       bool pl301::master_regs(master_port * target_master_port, string channel){

               return master_regs(current_master, target_master_port, channel);
       }

bool pl301::master_regs(slave_port * source_slave, master_port * target_master_port, string channel){

               try {

                  vector<Node *> regs;
                  regs  = DomReader.get_nodes(source_slave->parameters, "master_regs");

                  //Find the slave with the correct name
                  vector<Node *>::iterator r_iter;
                  for (r_iter = regs.begin(); r_iter != regs.end(); r_iter++) {

                        cout << "checking " <<  DomReader.get_value(*r_iter, "name") << " channel " << channel << endl;
                       
                        //Select the correct slave
                        if (DomReader.get_value(*r_iter, "name") == target_master_port->name) {
                             
                              vector<Node *> depth_terms;
                              vector<Node *>::iterator depth_iter;
                              vector<Node *> reg_terms;
                              vector<Node *>::iterator reg_iter;
                              int total_depth = 0;

                              if (DomReader.get_value(*r_iter, channel) == "true")
                                return true;
                              else
                                return false;

                        }
                  }

                  //throw an error
                  throw "Failed to find required reg information";
                 
               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }

    //-----------------------------------------------------------------------
    // Address Calculation methods
    //-----------------------------------------------------------------------

       //This function looks through the address ranges between the specified master and slave.
       //It returns the size of the total address_space of all paths between the master and slave on
       //all valids if valid_bit = 0 (the default) or the specifed valid where valid_bit =1 => bit[0]
       //Note. This function assumes that address spaces do not overlap as this is check by configuration.
       //(The only exception to this is for non-addressed components where every valid supports the full address space)
       unsigned long long pl301::address_range(slave_port * source_slave, master_port * target_master_port, int valid_bit, bool secure) {

               unsigned long long total_address_range = 0;
               unsigned long long max_address_range;

               vector<addr_range *> current_address_map;
               //Get a list of all the available address ranges
               current_address_map = get_address_map(source_slave, secure);

               //First check that this is a valid connection
               if (is_path(&current_address_map, source_slave, target_master_port, valid_bit) == false) {
                       throw "Tried to use a non-existant address connection";
               }

               //Get the max_address range
               max_address_range = (unsigned long long)pow(2.0, param(source_slave, "addr_width")) - 1;

               //Now look through all the connections and see if there is one with the correct valid  
               vector<addr_range *>::iterator addr_map_iter;
               for (addr_map_iter = current_address_map.begin(); addr_map_iter != current_address_map.end(); addr_map_iter++) {

                    if ((*addr_map_iter)->master_port == param_s(target_master_port, "addr_map_target")) {

                        //We can assume that the regions we are looking at are non overlapping
                        total_address_range += (*addr_map_iter)->addr_max - (*addr_map_iter)->addr_min;

                        //Check we haven't reached the max
                        if (total_address_range >= max_address_range) {
                              return max_address_range;
                        }
                    }
               }

               //default return the total amount of bytes
               return total_address_range;
       }
   
       //IF the VNET value is 0 then this function choses a legal value from the address map
       void pl301::set_vnet(slave_port * source_slave, transaction * trans) {

               int vnet;
               int one_hot_vn;

               //IF vnet is not zero return
               if (trans->vnet != 0) {
                   return; 
               }

               //If vnets are not turned on return
               if (DomReader.get_value(source_slave->parameters, "enable_vn") != "true") {
                    return; 
               } else {
                    one_hot_vn = (param_s(source_slave, "one_hot_vn") == "true");   
               }

               //Get a list of all the available address ranges
               vector<addr_range *> current_address_map;
               bool secure = (((*trans).prot >> 1) % 2) == 0;
               current_address_map = get_address_map(source_slave, secure);
               
               //Now look through all the connections and see if there is one with the correct valid  
               vector<addr_range *>::iterator addr_map_iter;
               for (addr_map_iter = current_address_map.begin(); addr_map_iter != current_address_map.end(); addr_map_iter++) {

                   if ((trans->address >= (*addr_map_iter)->addr_min) && (trans->address <= (*addr_map_iter)->addr_max)) {
                        vnet = (*addr_map_iter)->vn;

                        if (one_hot_vn == 1) {
                            trans->vnet =  (int)pow(2.0, vnet);    
                        } else {
                            trans->vnet = vnet + 1;    
                        }
                        return;
                   }
               }

               //No match found .. using default
               vnet = param(source_slave, "default_vn");
               if (one_hot_vn == 1) {
                      trans->vnet =  (int)pow(2.0, vnet);    
               } else {
                      trans->vnet = vnet + 1;    
               }
       }
       //IF the VNET value is 0 then this function choses a legal value from the address map
       void pl301::rev_vnet(slave_port * source_slave, transaction * trans) {

               int vnet;
               int one_hot_vn;
               int count;
               int this_vn;

               //If vnets are not turned on return
               if (DomReader.get_value(source_slave->parameters, "enable_vn") != "true") {
                    return; 
               } else {
                    one_hot_vn = (param_s(source_slave, "one_hot_vn") == "true");   
               }

               if (one_hot_vn == 1) {
                    switch((int)trans->vnet)
                    {
                       case 1: vnet = 0; break;
                       case 2: vnet = 1; break;
                       case 4: vnet = 2; break;
                       case 8: vnet = 3; break;
                       case 0: vnet = 0; break;
                       default : throw "Invalid one-hot vnet_number";
                    }  
               } else {
                       vnet = trans->vnet - 1;    
               }

               vector<Node *> vns;
               vns = DomReader.get_nodes(source_slave->parameters, "vn");
               vector<Node*>::iterator node_iter;

               //Go through each vn
               count = 0;
               for (node_iter = vns.begin(); node_iter != vns.end(); node_iter++) {
                       this_vn = DomReader.get_value_i(*node_iter);

                       if (this_vn == vnet) {
                          trans->vnet = count;
                          return;
                       };   
                       count++;
               }

               //Error case
               throw "Unrecognised VN on port";
       }

       //This function takes a specified address and sets the correct offset for the path through the infrastructure.
       //Non-contiguous regions are supported. i.e. an address that spills out of the bottom region will be offset into the second one.
       //The valid bit is zero then all valids on the connection can be used and the correct valid_bit will be set.
       //If the valid bit is set it must be within the valid range for a connection i.e. for a master_if with awvalid[1:0] valid can be 1 or 2
       //If every valid supports the full address range valid will default to valid[0] (of the conenction)
       //and the test must expicity set valid to use other valid bits.
       void pl301::address_offset(slave_port * source_slave, master_port * target_master_port, transaction * trans) {

               unsigned long long max_address_range;
               unsigned long long working_address;
               unsigned long long min;
               int count_min;
               int valid_bit;
               unsigned int count;

               //vectors to store the addr_min, addr_max and valid bit
               vector<unsigned long long> addr_min_vec;
               vector<unsigned long long> addr_max_vec;
               vector<int>                valid_bit_vec;

               //Extract the valid bit from the vector
               valid_bit = (*trans).valid;

               //Check that the valid_bit is not out of range
               if (valid_bit > param(target_master_port, "valid_width")) {
                    throw "Valid value too high";
               }

               //Get a list of all the available address ranges
               vector<addr_range *> current_address_map;
               bool secure = (((*trans).prot >> 1) % 2) == 0;
               current_address_map = get_address_map(source_slave, secure);

               //First check that this is a valid connection
               if (is_path(&current_address_map, source_slave, target_master_port, valid_bit) == false) {
                       throw "Tried to use a non-existant address connection (Check security settings)";
               }

               //Calculate the range of valids acceptable
               int valid_min;
               int valid_max;

               //Get the max_address range
               max_address_range = (unsigned long long)pow(2.0, param(source_slave, "addr_width")) - 1;

               //Now look through all the connections and see if there is one with the correct valid  
               vector<addr_range *>::iterator addr_map_iter;
               for (addr_map_iter = current_address_map.begin(); addr_map_iter != current_address_map.end(); addr_map_iter++) {

                   if ((*addr_map_iter)->master_port == param_s(target_master_port, "addr_map_target")) {

                       valid_min = (*addr_map_iter)->valid_base;     
                       valid_max = valid_min + param(target_master_port, "valid_width") - 1;

                       //If the valid is appropriate range  
                       if ((*addr_map_iter)->valid >= valid_min and (*addr_map_iter)->valid <= valid_max) {

                            //Special case if one state covers the full address range
                            if (((*addr_map_iter)->addr_min == 0) && ((*addr_map_iter)->addr_max >= max_address_range)) {

                                 //Set the valid
                                 if (valid_bit == 0) {
                                      (*trans).valid = (*addr_map_iter)->valid + 1;
                                 } else {
                                      (*trans).valid = (*addr_map_iter)->valid_base + valid_bit;
                                 }
                                 return;
                            }

                            //Record useful info
                            addr_min_vec.push_back((*addr_map_iter)->addr_min);
                            addr_max_vec.push_back((*addr_map_iter)->addr_max);
                            if (valid_bit == 0) {
                                valid_bit_vec.push_back((*addr_map_iter)->valid + 1);
                            } else {
                                valid_bit_vec.push_back((*addr_map_iter)->valid_base + valid_bit);
                            }

                       }

                  }
               }

               //The addr_min and addr_max vectors and their associated valid bits are now populated
               working_address = (*trans).address;

               while (addr_min_vec.empty() == false) {

                       //Set minimum to be the first in the vector
                       count_min = 0;
                       min = addr_min_vec[count_min];

                       //Go through all the address regions
                       for (count = 1; count < addr_min_vec.size(); count++) {

                               //Check this one isn't earlier;
                               if (addr_min_vec[count] < min) {
                                   min = addr_min_vec[count];
                                   count_min = count;
                               }
                       }

                       //Determine if the working_address fits in this area
                       if (working_address < (addr_max_vec[count_min] - min + 1)) {

                               //set the address
                               (*trans).address = min + working_address;
                               (*trans).valid = valid_bit_vec[count_min];

                               //Complete so return
                               return;
                               
                       } else {

                               //Substract range from working address
                               working_address -= (addr_max_vec[count_min] - min + 1);

                               //delete the used region
                               addr_max_vec.erase(addr_max_vec.begin()+count_min);
                               addr_min_vec.erase(addr_min_vec.begin()+count_min);
                               valid_bit_vec.erase(valid_bit_vec.begin()+count_min);
                               
                       }
               }

               //If code gets there the address must have been out of range so throw an exception
               cout << "Address is " << hex << (*trans).address << " and valid is " << (*trans).valid << endl;
               throw "Address out of valid range";
               
       }

       vector<addr_range *> pl301::get_address_map(slave_port * source_slave, bool secure, bool get_all) {

               //The secure flag indicates the security of the transaction.
               string slave_security = param_s(source_slave, "trustzone");
               bool trans_secure = true;
               bool dest_secure = true;

               //Override the security bit if the slave is non secure
               if (slave_security == "sec") {
                   trans_secure = true;   
               } else if (slave_security == "nsec") {
                   trans_secure = false;   
               } else {
                   trans_secure = secure;   
               };

               //Get the remap state
               int remap = 0;
               int remap_width = 0;
               //If there is a register map and the connected block is an asib:
               if (param_s(source_slave, "block_type") == "asib") {
                   if (param_s(source_slave, "apb_config") == "true" && param(source_slave, "remap_width") > 0
                            && (param_s(source_slave, "no_remaps") == "false")) {
                       string remap_reg = param_s(source_slave, "block_name") + ".remap";
                       remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                       remap_width = param(source_slave, "remap_width");
                   }
               }

               //Add the remap width to ensure that the default is always on
               remap = remap + (int)pow(2.0, remap_width);

               vector<Node *> ranges;
               vector<addr_range *> real_addr_map;
               ranges = DomReader.get_nodes(source_slave->addr_map, "range");

               vector<Node*>::iterator node_iter;
               vector<Node*>::iterator remap_iter;
               string remap_bit;

               //Go through each range
               for (node_iter = ranges.begin(); node_iter != ranges.end(); node_iter++) {

                       vector<Node *> remaps;
                       remaps = DomReader.get_nodes(*node_iter, "remap");
                       map<int,Node*> remap_ref;

                       //Look through all the remaps
                       for (remap_iter = remaps.begin(); remap_iter != remaps.end(); remap_iter++) {
                            
                           remap_bit = DomReader.get_value(*remap_iter, "bit"); 
                           if (remap_bit == "default") {
                              remap_ref[remap_width] = *remap_iter;  
                           } else {
                              remap_ref[atoi(remap_bit.c_str())] = *remap_iter;
                           }
                               
                       }

                       //Go though each bit of remap from zero upwards
                       int lremap = remap;
                       int bit = 0;
                       while (lremap > 0) {

                            
                             //If the remap bit is set and there is something to to on that
                             //bit use it
                             if ((lremap % 2) == 1 and remap_ref.find(bit) != remap_ref.end()) {

                                   //Create a new address range
                                   if (DomReader.get_value(remap_ref[bit], "present") == "true" || get_all == true) {      
                                         addr_range * arange = new addr_range;
                                         arange->addr_min = strtoul(DomReader.get_value(*node_iter, "addr_min").c_str(), NULL, 0);
                                         arange->addr_max = strtoul(DomReader.get_value(*node_iter, "addr_max").c_str(), NULL, 0);
                                         arange->master_port = DomReader.get_value(remap_ref[bit],  "target");
                                         arange->valid_base = DomReader.get_value_i(remap_ref[bit], "valid_base");
                                         arange->valid  = DomReader.get_value_i(remap_ref[bit],     "valid");
                                         arange->region = DomReader.get_value_i(remap_ref[bit],     "region");
                                         arange->trustzone = DomReader.get_value(remap_ref[bit],    "trustzone");
                                         arange->infra_mi_no = DomReader.get_value(remap_ref[bit],  "infra_mi_no");
                                         arange->multi_region = DomReader.get_value(remap_ref[bit], "multi_region");
                                         arange->present = DomReader.get_value(remap_ref[bit],      "present");
                                         arange->vn      = DomReader.get_value_i(remap_ref[bit],      "vn");

                                         //Check secuity setting to ensure that this address range is valid
                                         //Detemine the security of the destination
                                         dest_secure = (arange->trustzone != "nsec");
                                         if (arange->trustzone == "bs" && trans_secure != true) {
                                            string secure_reg = param_s(source_slave, "block_name") + ".security" + string(arange->infra_mi_no);
                                            int secure_reg_val = tb_regs.read(secure_reg.c_str(), ("security" + string(arange->infra_mi_no)).c_str()); 
                                            if (arange->multi_region == "false") {
                                               dest_secure = (bool(secure_reg_val) == false);
                                            } else {
                                               dest_secure = (bool(((secure_reg_val >> arange->region) % 2)) == false);  
                                            }
                                         }
                                        
                                         if (trans_secure == true || dest_secure == false || get_all == true) {
                                             real_addr_map.push_back(arange);
                                         }
                                   }

                                 //go onto the next address range
                                 break;   
                             }
 
                             //go onto the next bit
                             bit = bit + 1;
                             lremap = lremap >> 1;
                               
                       }
               }

               return real_addr_map;
       }
               
    //-----------------------------------------------------------------------
    // Testbench block access methods methods
    //-----------------------------------------------------------------------

       void pl301::tb_read(master_port * target_master_port, string reg, string field, int value, int id, int emit, int wait, string comment) {

               //Call tb_read on the target slave 
               if (target_master_port == NULL) {
                   throw "No master port specified (tb_read)";
               } else {
                   tb_read(target_master_port->name, reg, field, value, id, emit, wait, comment);
               }

       }

       void pl301::tb_read(string name, string reg, string field, int value, int id, int emit, int wait, string comment) {

               //Register name
               string full_name;

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::read);

               //set up the full name
               full_name = name + "." + reg;
               if(name == "DUT")
                  full_name = reg;

               //Get the address
               trans->address = tb_regs.address(full_name.c_str());
               //The APB bridge does port selection from the AUSER signal.
               //This ensure the whole bus is available for testing
               for (int i=0; i < 16; i++){
         
               trans->auser[i] = to_string_in_binary(tb_regs.port(full_name.c_str()),NIC_AUSER_MAX_WIDTH); // tb_regs.port(full_name.c_str());
               }

               //set the wait
               trans->await_code = wait;

               //set the emit
               trans->demit_code[0] = emit;

               //set the id
               trans->id = id;

               //set the mask
               trans->mask[0] = to_string(tb_regs.get_mask(full_name.c_str(), field.c_str()));

               //set the data
               trans->data[0] = to_string(tb_regs.shift_data(full_name.c_str(), field.c_str(), value));

               //Set the widths etc
               trans->addr_width   = 32;
               trans->id_width     = 8;
               trans->awuser_width = 8;
               trans->aruser_width = 8;
               trans->wuser_width  = 1;
               trans->buser_width  = 1;
               trans->ruser_width  = 1;

	       //Set the comment
	       trans->comment = comment;
               transactions.push_back(*trans); 

       }

       //This function is used to access rsb chain through master test components
       void pl301::tb_read(slave_port * target_slave_port, string reg, string field, int value, int id, int emit, int wait, string comment) {

                //IF target_slave_port is null try to use external port
                if (target_slave_port == NULL) {
                   tb_read("DUT", reg, field, value, id, emit, wait, comment);
                   return;
                } 

                //Determine full name
                string name = target_slave_port->name;
                string full_name;
                full_name =  reg;

                if (param_s(target_slave_port, "rsb_access") != "true")
                {
                    cout << "RSB master can not be reached through current master test component!" << endl;
                    return;
                }

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::read);

               //Set the address
               try {

                   //Get the address
                   trans->address = get_rsb_address(target_slave_port) + (tb_regs.address(full_name.c_str()));

                   //The APB bridge does port selection from the AUSER signal.
                   //This ensure the whole bus is available for testing
                   //trans->auser = tb_regs.port(full_name.c_str());  
		
		   //Set the comment
		   trans->comment = comment;	

                   //Set valid bit
                   trans->valid = 1; 

                   //set the mask
                   trans->mask[0] = to_string(tb_regs.get_mask(full_name.c_str(), field.c_str()));

                   //set the data
                   trans->data[0] = to_string(tb_regs.shift_data(full_name.c_str(), field.c_str(), value));

                   trans->id = id;
                   trans->demit_code[0] = emit;
                   trans->await_code = wait;


                   //Set the parameters for all the widths
                   trans->addr_width   = (arm_uint8)param(target_slave_port, "addr_width");
                   trans->id_width     = (arm_uint8)param(target_slave_port, "aid_width");
                   trans->awuser_width = (arm_uint8)param(target_slave_port, "awuser_width");
                   trans->aruser_width = (arm_uint8)param(target_slave_port, "aruser_width");
                   trans->wuser_width  = (arm_uint8)param(target_slave_port, "wuser_width");
                   trans->buser_width  = (arm_uint8)param(target_slave_port, "buser_width");
                   trans->ruser_width  = (arm_uint8)param(target_slave_port, "ruser_width");


                   //If we need to add the siid bits to this transfer
                   if (param_s(target_slave_port, "add_siid") == "true") {
                       int siid_width  = param(target_slave_port, "siid_width");
                       int iid_width   = param(target_slave_port, "iid_width");
                       int siid        = param(target_slave_port, "siid");
                       int iid         = param(target_slave_port, "iid");
                       int total_width = param(target_slave_port, "pl_id_width");
                       int vid_width   = param(target_slave_port, "aid_width");
                       trans->id   = (iid << (total_width - iid_width)) +
                                         ((trans->id % vid_width) << siid_width) +
                                         siid;
                   }

                   //Set the transaction location
                   trans->location = param_s(target_slave_port, "sim_start_point");
                   trans->final_dest = param_s(target_slave_port, "sim_end_point");

                   //Set an appropriate vnet (if necessary)
                   trans->vnet = get_rsb_vnet(target_slave_port);
                   rev_vnet(target_slave_port, trans);

                   //call access
                   (*target_slave_port).transactions.push_back(*trans); 

               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }

       void pl301::tb_read(string name, int addr, int value, int mask, int id, int emit, int wait, string comment) {

               if (name != "DUT") throw "This function can only be used to write to the DUT";

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::read);

               //Set parameters
               trans->address = addr;

               for (int i=0; i < 16; i++){
               trans->auser[i] = string(NIC_AUSER_MAX_WIDTH,'0');}

               trans->id = id;
               trans->await_code = wait;
               trans->demit_code[0] = emit;
               trans->data[0] = to_string((unsigned int) value);
               trans->mask[0] = to_string((unsigned int) mask);

               //Set the widths etc
               trans->addr_width   = 32;
               trans->id_width     = 8;
               trans->awuser_width = 8;
               trans->aruser_width = 8;
               trans->wuser_width  = 1;
               trans->buser_width  = 1;
               trans->ruser_width  = 1;

	       //Set the comment
	       trans->comment = comment;

               transactions.push_back(*trans); 
       }

       void pl301::tb_write(master_port * target_master_port, string reg, string field, int value, int id, int emit, int wait, string comment) {

               //Call tb_write on the target slave 
               if (target_master_port == NULL) {
                  throw "No master port specified (tb_write)";
               } else {
                  tb_write(target_master_port->name, reg, field, value, id, emit, wait, comment);
               }

       }

       void pl301::tb_write(string name, string reg, string field, int value, int id, int emit, int wait, string comment) {

               //Determine full name
               string full_name;
               full_name = name + "." + reg;
               
               if(name == "DUT")
                  full_name = reg;

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::write);

               //set up the full name
               //full_name = name + "." + reg;

               //Set the address
               try {

                   //Get the address
                   trans->address = tb_regs.address(full_name.c_str());

                   //The APB bridge does port selection from the AUSER signal.
                   //This ensure the whole bus is available for testing
                   for (int i=0; i < 16; i++){
                   trans->auser[i] = to_string_in_binary(tb_regs.port(full_name.c_str()),NIC_AUSER_MAX_WIDTH); // tb_regs.port(full_name.c_str());
                   }

                   //Set the ID
                   trans->id = id;

                   //set the wait
                   trans->await_code = wait;
                   trans->dwait_code[0] = wait;

                   //set the emit
                   trans->remit_code = emit;       
                   
                   //now WRITE the register value to keep the stored info up-to-date at get the full value to write
                   int reg_data = tb_regs.write(full_name.c_str(), field.c_str(), value);
                   
		   //set the data
                   trans->data[0] = to_string(reg_data);

                   //Set the stobes
                   trans->strobe[0] = "1111";
   
                   //Set the widths etc
                   trans->addr_width   = 32;
                   trans->id_width     = 8;
                   trans->awuser_width = 8;
                   trans->aruser_width = 8;
                   trans->wuser_width  = 1;
                   trans->buser_width  = 1;
                   trans->ruser_width  = 1;
		
		   //Set the comment
		   trans->comment = comment;	

                   transactions.push_back(*trans); 

               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }

       void pl301::tb_write(string name, int addr, int value, int strb, int id, int emit, int wait, string comment) {

               if (name != "DUT") throw "This function can only be used to write to the DUT";

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::write);

               for (int i=0; i < 16; i++){
               trans->auser[i] = string(NIC_AUSER_MAX_WIDTH,'0');}

               //Set parameters
               trans->address = addr;
               trans->id = id;
               trans->await_code = wait;
               trans->dwait_code[0] = wait;
               trans->remit_code = emit;
               trans->data[0] = to_string((unsigned int)value);
               trans->strobe[0] = to_string(strb);

               //Set the widths etc
               trans->addr_width   = 32;
               trans->id_width     = 8;
               trans->awuser_width = 8;
               trans->aruser_width = 8;
               trans->wuser_width  = 1;
               trans->buser_width  = 1;
               trans->ruser_width  = 1;

	       //Set the comment
	       trans->comment = comment;
               transactions.push_back(*trans); 

       }

    
       //This function is used to access rsb chain through master test components
       void pl301::tb_write(slave_port * target_slave_port, string reg, string field, int value, int id, int emit, int wait, string comment) {

               //IF target_slave_port is null try to use external port
               if (target_slave_port == NULL) {
                  tb_write("DUT", reg, field, value, id, emit, wait, comment);
                  return;
               } 

               //Determine full name
               string name = target_slave_port->name;
               string full_name;
               full_name =  reg;

               if (param_s(target_slave_port, "rsb_access") != "true")
               {
                    cout << "RSB master can not be reached through current master test component!" << endl;
                    return;
               }

               //Generate a new transaction
               transaction * trans;
               trans = new transaction(frbm_namespace::write);

               //Set the address
               try {

                   //Get the address
                   trans->address = get_rsb_address(target_slave_port) + (tb_regs.address(full_name.c_str()));

                   //now WRITE the register value to keep the stored info up-to-date at get the full value to write
                   int reg_data = tb_regs.write(reg.c_str(), field.c_str(), value);
                   
                   //Set the stobes
                   trans->strobe[0] = "1111";

		   //Set valid bit
                   trans->valid = 1; 

		   //Set the comment
		   trans->comment = comment;	


                   trans->data[0] = to_string(reg_data);
                   trans->id = id;
                   trans->await_code = wait;
                   trans->dwait_code[0] = wait;
                   trans->remit_code = emit;

                   //Set the parameters for all the widths
                   trans->addr_width   = (arm_uint8)param(target_slave_port, "addr_width");
                   trans->id_width     = (arm_uint8)param(target_slave_port, "aid_width");
                   trans->awuser_width = (arm_uint8)param(target_slave_port, "awuser_width");
                   trans->aruser_width = (arm_uint8)param(target_slave_port, "aruser_width");
                   trans->wuser_width  = (arm_uint8)param(target_slave_port, "wuser_width");
                   trans->buser_width  = (arm_uint8)param(target_slave_port, "buser_width");
                   trans->ruser_width  = (arm_uint8)param(target_slave_port, "ruser_width");


                   //If we need to add the siid bits to this transfer
                   if (param_s(target_slave_port, "add_siid") == "true") {
                       int siid_width  = param(target_slave_port, "siid_width");
                       int iid_width   = param(target_slave_port, "iid_width");
                       int siid        = param(target_slave_port, "siid");
                       int iid         = param(target_slave_port, "iid");
                       int total_width = param(target_slave_port, "pl_id_width");
                       int vid_width   = param(target_slave_port, "aid_width");
                       trans->id   = (iid << (total_width - iid_width)) +
                                         ((trans->id % vid_width) << siid_width) +
                                         siid;
                   }

                   //Set the transaction location
                   trans->location = param_s(target_slave_port, "sim_start_point");
                   trans->final_dest = param_s(target_slave_port, "sim_end_point");

                   //Set an appropriate vnet (if necessary)
                   trans->vnet = get_rsb_vnet(target_slave_port);
                   rev_vnet(target_slave_port, trans);

                   //call access
                   (*target_slave_port).transactions.push_back(*trans); 

               } catch ( const char * error ) {
                    cout << "Caught " << error << endl;     
                    exit(1);
               } 
       }
    //-----------------------------------------------------------------------
    // Randomise functions
    //-----------------------------------------------------------------------

    void pl301::randomise(transaction * trans, amba_direction direction, amba_size size, amba_length length, amba_burst burst, bool secure) {

            //call randomise will current_master and current_slave
            randomise(current_master, current_slave, trans, direction, size, length, burst, secure);
    }
    
    void pl301::randomise(master_port * target_master_port, transaction * trans, amba_direction direction, amba_size size, amba_length length, amba_burst burst, bool secure) {

            //call randomise will target_master_port and current_slave
            randomise(current_master, target_master_port, trans, direction, size, length, burst, secure);

    }

    void pl301::randomise(slave_port * target_slave_port, transaction * trans, amba_direction direction, amba_size size, amba_length length, amba_burst burst, bool secure) {
           
            //call randomise will target_slave_port and current_master
            randomise(target_slave_port, current_slave, trans, direction, size, length, burst, secure);
    }

    void pl301::randomise(slave_port * target_slave_port, master_port * target_master_port, transaction * trans, amba_direction direction, amba_size size, amba_length length, amba_burst burst, bool secure) {

            amba_burst new_burst;
            new_burst = burst;

            //if protocol is defined
            if (DomReader.get_value(target_slave_port->parameters, "protocol") != "<UNDEF>") {
                      if ((param_s(target_slave_port, "protocol") == "axi") && burst == ahb_incr) {
                           new_burst = axi_incr;   
                      }
                      if (param_s(target_slave_port, "protocol").substr(0, 3) == "ahb") {
                        
                           trans->protocol = frbm_namespace::ahb;   
                      }
            } else {
                      if (burst == ahb_incr) {
                           new_burst = axi_incr;   
                      }
            }

            //Randomise transaction
            trans->randomise(0, address_range(target_slave_port, target_master_port, 0, secure), direction, size, length, new_burst);

            //set security
            if (secure)
               trans->prot = trans->prot & 0xd;     
            else   
               trans->prot = trans->prot | 0x2;     

            //Modify the address into a valid region
            address_offset(target_slave_port, target_master_port, trans);

    }

    //-----------------------------------------------------------------------
    // RSB functions
    //-----------------------------------------------------------------------

    slave_port * pl301::get_rsb_master() {
 
         vector<Node *> access_points;
         string name;
         int remap;
         int nmask;
         int pmask;

         //Go though all the slave ports
         master_iter this_slave_port;
         for (this_slave_port = slave_ports.begin(); this_slave_port != slave_ports.end(); this_slave_port++) {

              name = get_master_p(this_slave_port)->name;  

              //If this has rsb_access 
              if (param_s(get_master_p(this_slave_port), "rsb_access") == "true") {
                    
                    access_points = DomReader.get_nodes(get_master_p(this_slave_port)->parameters, "rsb_access_points/rsb_access_point");
                    string remap_reg = name + ".remap";

                    vector<Node*>::iterator access_point_iter;
                    for (access_point_iter = access_points.begin(); access_point_iter != access_points.end(); access_point_iter++) {

                        //If there is an pmask check it 
                        if (DomReader.get_value((*access_point_iter), "pmask") != "<UNDEF>") {

                              remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                              pmask = DomReader.get_value_i((*access_point_iter), "pmask");

                              //Go onto next if mask matches
                              if ((remap & (1 << pmask)) == 0) {
                                 continue;     
                              }
                        }

                        //If there is an nmask check it 
                        if (DomReader.get_value((*access_point_iter), "nmask") != "<UNDEF>") {

                              remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                              nmask = (int)(strtoul(DomReader.get_value((*access_point_iter), "nmask").c_str(), NULL, 2));

                              //Go onto next if mask matches
                              if ((remap & nmask) != 0) {
                                 continue;     
                              }
                        }

                       
                        //IF here then match found
                        return get_master_p(this_slave_port);

                    }
              }

         }

         return NULL;   
    }


 unsigned long long pl301::get_rsb_address(slave_port * this_slave_port) {
 
         vector<Node *> access_points;
         string name;
         int remap;
         int nmask;
         int pmask;

         name = this_slave_port->name;  

         //If this has rsb_access 
         if (param_s(this_slave_port, "rsb_access") == "true") {
                    
               access_points = DomReader.get_nodes(this_slave_port->parameters, "rsb_access_points/rsb_access_point");
               string remap_reg = name + ".remap";

               vector<Node*>::iterator access_point_iter;
               for (access_point_iter = access_points.begin(); access_point_iter != access_points.end(); access_point_iter++) {

                   //If there is an pmask check it 
                   if (DomReader.get_value((*access_point_iter), "pmask") != "<UNDEF>") {

                         remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                         pmask = DomReader.get_value_i((*access_point_iter), "pmask");

                         //Go onto next if mask matches
                         if ((remap & (1 << pmask)) == 0) {
                            continue;     
                         }
                   }


                   //If there is an nmask check it 
                   if (DomReader.get_value((*access_point_iter), "nmask") != "<UNDEF>") {

                         remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                         nmask = (int)(strtoul(DomReader.get_value((*access_point_iter), "nmask").c_str(), NULL, 2));

                         //Go onto next if mask matches
                         if ((remap & nmask) != 0) {
                            continue;     
                         }
                   }

                                   //IF here then match found
                   return (strtoul(DomReader.get_value((*access_point_iter), "address").c_str(), NULL, 0));

               }
         }

         return 0;   
    }

 int pl301::get_rsb_vnet(slave_port * this_slave_port) {
 
         vector<Node *> access_points;
         string name;
         int remap;
         int nmask;
         int pmask;
         int vnet;
         int one_hot_vn = 0;

         name = this_slave_port->name;  

         //Exit routine if not vn aware
         if (DomReader.get_value(this_slave_port->parameters, "enable_vn") != "true") {
              return 0; 
         }  else {
              one_hot_vn = (param_s(this_slave_port, "one_hot_vn") == "true");   
         }

         //If this has rsb_access 
         if (param_s(this_slave_port, "rsb_access") == "true") {
                    
               access_points = DomReader.get_nodes(this_slave_port->parameters, "rsb_access_points/rsb_access_point");
               string remap_reg = name + ".remap";

               vector<Node*>::iterator access_point_iter;
               for (access_point_iter = access_points.begin(); access_point_iter != access_points.end(); access_point_iter++) {

                   //If there is an pmask check it 
                   if (DomReader.get_value((*access_point_iter), "pmask") != "<UNDEF>") {

                         remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                         pmask = DomReader.get_value_i((*access_point_iter), "pmask");

                         //Go onto next if mask matches
                         if ((remap & (1 << pmask)) == 0) {
                            continue;     
                         }
                   }


                   //If there is an nmask check it 
                   if (DomReader.get_value((*access_point_iter), "nmask") != "<UNDEF>") {

                         remap = tb_regs.read(remap_reg.c_str(), "remap"); 
                         nmask = (int)(strtoul(DomReader.get_value((*access_point_iter), "nmask").c_str(), NULL, 2));

                         //Go onto next if mask matches
                         if ((remap & nmask) != 0) {
                            continue;     
                         }
                   }

                   //IF here then match found
                   if (DomReader.get_value((*access_point_iter), "vn") != "<UNDEF>") {
   
                        vnet =  (int)(strtoul(DomReader.get_value((*access_point_iter), "vn").c_str(), NULL, 0));

                        if (one_hot_vn == 1) {
                            return (int)pow(2.0, vnet);    
                        } else {
                            return vnet + 1;    
                        }
                   } else {
                       return 0;
                   }

               }
         }

         return 0;   
    }




