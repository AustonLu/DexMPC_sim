//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Revision            : 179480
// Date                :  2014-08-26 11:40:36 +0100 (Tue, 26 Aug 2014)
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Model.h
//
//---------------------------------------------------------------------------

#ifndef MODEL_H
#define MODEL_H

#include <cstdarg>
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include <deque>
#include <map>
#include <vector>
#include <sstream>
#include <ostream>

#include "arm_types.h"
#include "Register_map.h"
#include "Register_update.h"
#include "frbm_types.h"
#include "Dom.h"

using namespace arm_namespace;
using namespace frbm_namespace;

  class Model
{
  public:
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    virtual inline ~Model(){};

    //Pure virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) = 0;

    //Return function this function normally just copies transaction from input to output
    //However it can be overridden but models that need to modify user and response signals
    virtual void Return(deque<transaction> * input, deque<transaction> * output)
    {

        //check the reverse user signals
      check_rev_user(input);

        //Go though each item in the input queue
      *output = *input;
      input->clear();

    };

    //Local Config function which be overriden by derived classes
    virtual void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL)
    {
         //Empty placeholder function
    };

    //Register access update function
    void reg_update(amba_direction dir, int id, int monitor_num = 0, int vn = 0) {

         //Ignore call if there is no update block defined
      if (Reg_update == NULL) {
        return;
      };

         //..else pass the call on
      Reg_update->update(dir, id, name, monitor_num, vn);
    };

    //Configuration function
    void Config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {


            // Copy the parameter over
      parameters = block_info;
      DomReader.top = parameters;

            //Copy the Configuration Dom
      DomConfiguration = DomConfiguration_i;

            // Copy the name over
      name = DomReader.get_value(block_info, "name");

            // Set the register map pointer
      PL301_reg = i_PL301_reg;

            //Set the pointer to the connect info
      connect_info = i_connect_info;

            //Set the referent to the register update block
      Reg_update = reg_update_i;

            //Call the local config function
      local_config(block_info, i_PL301_reg, i_connect_info, reg_update_i, DomConfiguration_i);

    };

    //Useful functions for user signals
    void check_fwd_user(transaction * trans) {
      //Set the forward user signals to zero if the width is zero
      for (int i = 0; i < 256; i++) {
        if (trans->direction == frbm_namespace::read) {
          // trans->auser[i] =  trans->auser[i] % (1L << param("aruser_width"));
          string temp_string ((NIC_AUSER_MAX_WIDTH-param("aruser_width")), '0');
          trans->auser[i] = trans->auser[i].substr((NIC_AUSER_MAX_WIDTH-param("aruser_width")),param("aruser_width"));
          temp_string    += trans->auser[i];
          trans->auser[i] = temp_string;

        } else {
          //trans->auser[i] = //trans->auser[i] % (1L << param("awuser_width"));
          string temp_string ((NIC_AUSER_MAX_WIDTH-param("awuser_width")), '0');
          trans->auser[i] = trans->auser[i].substr((NIC_AUSER_MAX_WIDTH-param("awuser_width")),param("awuser_width"));
          temp_string    += trans->auser[i];
          trans->auser[i] = temp_string;
        }
      }
      if (param("wuser_width") == 0) {
        for (int i = 0; i < 256; i++) {
          trans->user[i] = string(USER_MAX_WIDTH,'0');
        }
      }
    }

    //Useful functions for user signals
    void check_fwd_user_itb(transaction * trans) {
      int auser_width;
      if (param("aruser_width") > param("awuser_width")) {
        auser_width = param("aruser_width");
      } else {
        auser_width = param("awuser_width");
      }

        //Set the forward user signals to zero if the width is zero
      for (int i = 0; i < 256; i++) {
        string temp_string ((NIC_AUSER_MAX_WIDTH-auser_width), '0');
        trans->auser[i] = trans->auser[i].substr((NIC_AUSER_MAX_WIDTH-auser_width),auser_width);
        temp_string    += trans->auser[i];
        trans->auser[i] = temp_string;
      }

      if (param("wuser_width") == 0)
      {
        for (int i = 0; i < 256; i++)
        {
          trans->user[i] = string(USER_MAX_WIDTH,'0');
        }
      }
    }


    void check_rev_user(transaction * trans) {
      // Set the forward user signals to zero if the width is zero
      if (trans->direction == frbm_namespace::write)
      {
        if (param("buser_width") == 0)
        {
          trans->ruser = string(BUSER_MAX_WIDTH,'0');
        }
      } else {
        if (param("ruser_width") == 0) {
          for (int i = 0; i < 256; i++)
          {
            trans->user[i] = string(USER_MAX_WIDTH,'0');
          }
        }
      }
    }

    void check_rev_user(deque<transaction> * input)
    {
      for (unsigned int i = 0; i < input->size(); i++)
      {
        check_rev_user(&(input->at(i)));
      }
    }


    //Set the response to the the appropriate beat(s) in the strans queue to response.
    //(apprropriate beats are those with matching bnumbers)
    void set_response(deque<transaction> * strans, string bnumbers, frbm_namespace::amba_resp response, int or_response = 0, string user = string(USER_MAX_WIDTH,'0'))
    {
//        cout << "set_response " << bnumbers << endl;
//        cout << "user " << user.substr(128,128) << endl;

        unsigned int transno = 0;
        bool complete = false;
        string bcode;

        while (bnumbers.length() >= 5)
        {

            //Get the byte code
            bcode = bnumbers.substr(0,5);
            bnumbers = bnumbers.substr(5);
//            cout << "bcode " << bcode << endl;

            if (bcode.at(0) != 'b') { throw "Unexpected byte code format"; };

            complete = false;
            //Go through each transaction in the strans list to try and find the byte code
            for (transno = 0; transno < strans->size(); transno++)
            {

//                cout << "transno " << transno << endl;

                //Try to find the byte code in the orginal transaction
                for (int len = 0; len < strans->at(transno).length; len++)
                {

                    size_t found = 0;

                    found = (strans->at(transno)).bnumber[len].find(bcode);

                    // 'while' ensures alignment of bcode in string
                    while ((found != string::npos) && (found%5 != 0))
                    {
                        found = (strans->at(transno)).bnumber[len].find(bcode, found+1);
                    }

                    if (found != string::npos)
                    {
//                        cout << "found " << bcode << " at " << len << endl;
                        //Update fields
//                        cout << "replacing user " << (strans->at(transno)).user[len].substr(128,128) << endl;
                        // only return user for reads (strans->at(transno)).user[len] = user;
                        if ((strans->at(transno)).direction == frbm_namespace::read)
                        {
                            (strans->at(transno)).user[len] = user;
                            if (or_response == 1)
                            {
                                if ((strans->at(transno)).resp[len] == frbm_namespace::axi_exokay)
                                {
                                    //If the stored response is exokay store whatever is coming in
                                    (strans->at(transno)).resp[len] = response;
                                }
                                else if (response == frbm_namespace::axi_exokay)
                                {
                                    //IF the incoming response is exokay .... clear it
                                    response = frbm_namespace::axi_okay;
                                }

                                if (response > (strans->at(transno)).resp[len])
                                {
                                    //only set the response if the error is greater
                                    (strans->at(transno)).resp[len] = response;
                                }
                            }
                            else
                            {
                                (strans->at(transno)).resp[len] = response;
                            }
                        }
                        else
                        {
                            if (or_response == 1)
                            {
                                if ((strans->at(transno)).resp[0] == frbm_namespace::axi_exokay)
                                {
                                    //If the store reponse is exokay store whatever is coming in
                                    (strans->at(transno)).resp[0] = response;
                                }
                                else if (response == frbm_namespace::axi_exokay)
                                {
                                    //IF the incoming response is exokay .... clear it
                                    response = frbm_namespace::axi_okay;
                                }

                                if (response > (strans->at(transno)).resp[0])
                                {
                                    //only set the response if the error is greater
                                    (strans->at(transno)).resp[0] = response;
                                }
                            }
                            else
                            {
                                (strans->at(transno)).resp[0] = response;
                            }
                        }
                        complete = true;
                        break;
                    }
                }

                if (complete == true) { break; }
            }
        }
    }

    //Set the response to the the appropriate beat(s) in the strans queue to response.
    //(apprropriate beats are those with matching bnumbers)
    void set_response_trans(transaction * trans, string bnumbers, frbm_namespace::amba_resp response, string user) {
      bool complete = false;
      string bcode;

      while (bnumbers.length() >= 5) {
        // Get the byte code
        bcode = bnumbers.substr(0,5);
        bnumbers = bnumbers.substr(5);

        if (bcode.at(0) != 'b') {
          throw "Unexpected byte code format";
        };

        complete = false;
              //Try to find the byte code in the orginal transaction
        for (int len = 0; len < trans->length; len++) {

          size_t found;
          found = trans->bnumber[len].find(bcode);

          if (found != string::npos) {

                     //Update fields
            if (trans->direction == frbm_namespace::read) {
              trans->resp[len] = response;
              trans->user[len] = user;
            } else {
              trans->resp[0] = response;
              trans->user[0] = user;
            }

            complete = true;
            break;
          };
        };

      };
    };

    //Extract and check parameter as a string
    string param_s(string param_name) {

      string value = DomReader.get_value(parameters, param_name);
      if (value == "<UNDEF>") {
        cout << "Failed to find parameter " << param_name << endl;
        exit(1);
      };
      return value;

    };

    //Extract and check parameter as an integer
    int param(string param_name) {

      return atoi(param_s(param_name).c_str());
    };

    unsigned long param_l(string param_name) {

      return strtoul(param_s(param_name).c_str(),NULL,0);
    };

    //Check if a parameter exists
    bool param_exists(string param_name) {

      string value = DomReader.get_value(parameters, param_name);
      return (value != "<UNDEF>");
    };

    string to_string(int data) {

      ostringstream data_str;
        //convert to string
      data_str << data;
      return data_str.str();
    };

    string to_string(arm_uint32 data, uint bits) {

        ostringstream data_str;
        //convert to string
        data_str << setw(bits) << setfill('0') << hex << data;
        return data_str.str();
    };

    // The next function converts a uint32 into a string in binary format  
    string to_string_in_binary(arm_uint32 data, uint bits, uint length) {

       string temp_string = "";
       arm_uint32   temp_data   = data;
       //convert to string
       for(int i=0; i< length; i++)
       {
         temp_string.insert(0,to_string(temp_data%2,1));
         temp_data = temp_data >>1; 
         //cout <<"The string is: "<<temp_string<<", and the temp_data is : "<<temp_data<<"" <<endl;
       }  

       return temp_string;
    };

    //Log2 functions
    int log2(int value) {

      double result;
      int resulti;
      result = log10((double)value) / log10(2.0);
      resulti = (int)result;

      return resulti;
    };

    //convert vn to internal number
    int vn_convert(int vn) {
         
      if (param_s("one_hot_vn") == "true") {
        return (int)pow(2.0, vn);     
      } else {
        return vn + 1;    
      }

    };

    //extract a value from a comma sepearated list
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

    //find a value in a comma separated list
    int clist_rev(string value, string item) {

      int location = 0;
      int count = 0;

            //Add a comma top the end
      value = value + ",";

            //Go through the list
      while ((value.find(",", location) != string::npos)) {
        if (value.substr(location, value.find(",", location) - location) == item) {
          return count;
        }
        count++;
        location = value.find(",", location) + 1;
      };

            //Falied
      cout << "Looking for " << item << " in " << value << " (model : " << name << ")" << endl;
      throw "Tried to find item that's not in list";
      return 0;
    };

    //Clear a transaction
    void clear_transaction(transaction * trans, frbm_namespace::amba_resp response) {

        //If there are slave data emits throw exception
      if (trans->aemit_code_s != 0) {
        throw "Slave emit on address beat that didn't reach a slave";
      };

        //If there are salve response emits throw exception
      if (trans->remit_code_s != 0) {
        throw "Slave emit on response that didn't reach a slave";
      };

        //Go through each beat
      for (int beat = 0; beat < 256; beat++) {

        trans->resp[beat] = response;
        if (trans->direction == frbm_namespace::read) {
          trans->data[beat] = "";
        }

             //If there are emits throw exception
        if (trans->demit_code_s[beat] != 0) {
          throw "Slave emit on data beat that didn't reach a slave";
        }
      }
    }

    //Clear a transaction
    void clear_bytes(transaction * trans, frbm_namespace::amba_resp response, string byte_string) {

       //For each byte code in byte string
      string byte_codes;
      string bcode;
      byte_codes = byte_string;

      while (byte_codes.length() >= 5) {

              //Get the byte code
        bcode = byte_codes.substr(0,5);
        byte_codes = byte_codes.substr(5);

        if (bcode.at(0) != 'b') {
          throw "Unexpected byte code format";
        };

              //Try to find the byte code in the orginal transaction
        for (int len = 0; len < trans->length; len++) {

                   //If the byte number is in this beat check/update reponse and continue
          size_t found;
          found = (*trans).bnumber[len].find(bcode);

          if (found != string::npos) {

                       //Update fields
            if (trans->direction == frbm_namespace::read) {
              trans->resp[len] = response;
              trans->data[len].replace(int(found) / 2, 2, "00");
            } else {
              trans->resp[0] = response;
            }
          };
        };

      };
    };

    //Dom Reader
    Dom DomReader;

    //Configuration Dom
    Dom *DomConfiguration;

    //name of this particular block
    string name;

    //All useful information about this block
    Node * parameters;

    //Reference to the register map
    Register_map * PL301_reg;

    //Reference to the register update block
    reg_update_block * Reg_update;

    //Refererence to all the connection information
    map<string, Node*> * connect_info;

    //Local input transaction store
    deque<transaction> stored_trans;

    // List of transactions queues
    deque< deque<transaction> > trans_queue_list;

    //Map of loaded sub-models
    map<string, Model *> sub_models;
};

  //-----------------------------------------------------------------------
  // ASIB model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_ib : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
//    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);
    void Return(deque<transaction> * input, deque<transaction> * output);

   //Necessary valiable for the ASIB-TLX-IB block order in order to
   //calculate properly the id of the transactions
    bool associated_asib ;
};

  //-----------------------------------------------------------------------
  // ASIB model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_asib : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);
    //void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i);
    void Return(deque<transaction> * input, deque<transaction> * output);

    //Address decode section
    bool decode(transaction * trans);
    bool decode_internal(transaction * trans);

};

  //-----------------------------------------------------------------------
  // AMIB model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_amib : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);
    //void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i);
    void Return(deque<transaction> * input, deque<transaction> * output);
    string to_bin_str(int fixed_id, int width);

};

  //-----------------------------------------------------------------------
  // Busmatrix model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_busmatrix : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

};

  //-----------------------------------------------------------------------
  //  default slave model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_default_slave : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

};

  //-----------------------------------------------------------------------
  //  register sub-system master model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_reg_ss : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

};

  //-----------------------------------------------------------------------
  //  register sub-system master model - and local function definitions ...
  //  This version distributes transactions rather than absorbing then
  //-----------------------------------------------------------------------
  class Model_reg_ss_dist : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);
    //void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i);

};

  //-----------------------------------------------------------------------
  //  ApbConv model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_Apbconv : public Model
{

  public:

    bool allow_zero_strobes;
    map <string, int>    slave_s_region;
    map <string, string> slave_s_protocol;
    map <int   , string> slave_region_protocol;

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);
    //void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);

};

  //-----------------------------------------------------------------------
  //  AhbMConv model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_AhbMconv : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

    //locked flag
    bool bridge_locked;
    bool lock_overriden;
    amba_resp bridge_locked_resp;

    //Response flags
    bool early_resp;
    bool conv_singles;

    Model_AhbMconv()
  :    bridge_locked(false), early_resp(false), conv_singles(false), lock_overriden(false)
    {};

};

  //-----------------------------------------------------------------------
  //  AhbSConv model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_AhbSconv : public Model
{


    //Virtual function that is overridden by each component
  virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
  void Return(deque<transaction> * input, deque<transaction> * output);

};

  //-----------------------------------------------------------------------
  //  size model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_size : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

};

  class Model_size_dpe : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);
    void local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i, Dom *DomConfiguration_i);

    void set_beat_parity(deque<transaction> * strans, transaction *input_trans, int beat, vector<bool> &sif_parity_validity, int &sif_beat);

    int master_if_data_width;
    int slave_if_data_width;
    int master_data_bits;
    int slave_data_bits;
    int master_data_bytes;
    int slave_data_bytes;

    string merge_data;
    string merge_parity;
};

  //-----------------------------------------------------------------------
  //  breaker model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_breaker : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);

};

  //-----------------------------------------------------------------------
  //  wire model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_wire : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);

};

  //-----------------------------------------------------------------------
  //  wire model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_vnb : public Model
{

  public:

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);

};

  //-----------------------------------------------------------------------
  //  tlx model - and local function definitions ...
  //-----------------------------------------------------------------------
  class Model_tlx : public Model
{

  public:

    int current_vnet;

    //Virtual function that is overridden by each component
    virtual string Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans);
    void Return(deque<transaction> * input, deque<transaction> * output);
};


/*
  class general 
{
  public:
    static int total_trans_no;
      //virtual void display_vector(const vector<int> &v);
      friend class Model_size;
};
*/
#endif

