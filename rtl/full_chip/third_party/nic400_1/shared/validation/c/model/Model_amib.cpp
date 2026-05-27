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
// Checked In          :  2014-10-20 20:05:32 +0100 (Mon, 20 Oct 2014)
//
// Revision            : 182532
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: ASIB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------


#include "../include/Model.h"

#define COMPRESS_ID 

//local_config function allows loading of any sub_models that this model requires
void Model_amib::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {
      std::cout << "***Starting Model_amib.cpp...***" << std::endl;

      Model * new_model;

      //Now load a protocol model
      if  (param_s("protocol") == "apb") {

            //Create apb conv model Model
            new_model = new Model_Apbconv;
            new_model->Config(block_info, i_PL301_reg, i_connect_info);

            //Store the model
            sub_models["protocol"] = new_model;

      } else if  (param_s("protocol").substr(0,3) == "ahb") {

            //Create apb conv model Model
            new_model = new Model_AhbSconv;
            new_model->Config(block_info, i_PL301_reg, i_connect_info, reg_update_i);

            //Store the model
            sub_models["protocol"] = new_model;

      } else {

            //Create wire Model as there is no protocol covertion to do
            new_model = new Model_wire;
            new_model->Config(block_info, i_PL301_reg, i_connect_info);

            //Store the model
            sub_models["protocol"] = new_model;

      };

}

//to_bin_str function
string Model_amib::to_bin_str(int fixed_id, int width) {

      std::ostringstream data_str;

      //convert to string
      for (int i = width; i > 0; i--) {
          data_str << std::dec << ((fixed_id >> (i - 1)) % 2);
      };

      return data_str.str();
}


//Run function
//NB the AMIB model itself does not effect reponses ... hence no need to store input transactions
string Model_amib::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

        //Local transaction
        transaction trans;
        deque<transaction> after_protocol;

        //Step 2 .. protocol translation
        sub_models["protocol"]->Run(input, &after_protocol, orginal_trans);

        //Step 3 .. Other AMIB specific odds and ends
        while (after_protocol.empty() == false) {

            //select transaction
            trans = after_protocol.front();
            after_protocol.pop_front();

            //Trim the address width to the master_if_addr_width
            if (param_s("addr_width") > param_s("master_if_addr_width")) {
              trans.address = trans.address % (1ULL << param("master_if_addr_width"));
            }

            //If this master does not output the QV value zero them
            if (param_s("qv_out") != "true") {
                    trans.qv = 0;
            };

            //Set the region signal to zero if there is no region flag
            if (param_s("multi_region") != "true") {
                 trans.region = 0;
            };

            //Remove lock if AXI4
            if (param_s("protocol") == "axi4") {

               if (trans.locked == (amba_lock)2)
               {
                 trans.locked = nolock;    
               } 
            };

	    #ifdef COMPRESS_ID 
            //Modify the ID if required
            if (param_s("compress_id") == "true") {

                //Split the ID into it's three main parts
                int siid = trans.id % (1 << param("siid_width")); 
                int vid  = (trans.id >> param("siid_width")) % (1 << (param("pl_id_width") - param("siid_width") - param("iid_width")));
                int iid  = trans.id >> (param("pl_id_width") - param("iid_width"));

                int fixed_id = (iid << param("siid_width")) + siid;

                if (param_s("out_id_list") != "") {
                    string new_fixed_id = clist(param_s("out_id_list"), clist_rev(param_s("in_id_list"), to_bin_str(fixed_id, param("siid_width") + param("iid_width"))));
                    trans.id = ((vid % (1 << param("max_vid_width"))) << new_fixed_id.length()) + (int)strtoul(new_fixed_id.c_str(), NULL, 2);
                } else {
                    trans.id = (vid % (1 << param("max_vid_width")));
                };
            }
	    #endif
           
             //Clear the valid bit
             trans.valid = 0;
 
            int port_remap_width = 0;
            int dnstream_nic = 0;
            if (DomReader.get_value(parameters, "port_remap_width") != "<UNDEF>") {
                port_remap_width = DomReader.get_value_i(parameters, "port_remap_width");
            }
            if (DomReader.get_value(parameters, "dnstream_nic") != "<UNDEF>") {
                dnstream_nic = DomReader.get_value(parameters, "dnstream_nic")=="true";
            }
              


            // Beckett update to drop remap bits from user sigs when required
            if (dnstream_nic==0 & port_remap_width > 0) {
                trans.auser[0].erase(trans.auser[0].size() - port_remap_width , port_remap_width);
                trans.auser[0].insert(trans.auser[0].begin(), port_remap_width, '0');
            };
            // std::cout << "Read Values"<< port_remap_width << " " << dnstream_nic << std::endl;


             // DPE change

             int dpe_width = 0;
             if (DomReader.get_value(parameters->parent, "dpe_width") != "<UNDEF>")
             {
                 dpe_width = DomReader.get_value_i(parameters->parent, "dpe_width");
             }

             if (dpe_width > 0)
             {
                 //if write then set parity to 1 for strobed out data bytes
                 if (trans.direction == wr)
                 {
                     int master_if_data_width = param("master_if_data_width");

                     trans.extract_parity();

                     for (int b=0; b<trans.length; b++)
                     {
                         arm_uint32 strobe = trans.bus_strobe(master_if_data_width/8, b);
                         trans.data_parity[b] = trans.data_parity[b] | ~strobe;
                     }

                     trans.insert_data_parity();
                 }
             };

             //Clear the forward user siganls if their width is zero
             check_fwd_user(&trans);

             //Output the transaction
             output->push_back(trans);
        }
       
        //select the appropirate output port
        if  (param_s("protocol") == "apb") {
             return clist(param_s("master_if_port_name"), trans.region);
        } else {
             return param_s("master_if_port_name");
        }

}

//Return function
void Model_amib::Return(deque<transaction> * input, deque<transaction> * output) {

     #ifdef COMPRESS_ID
     deque<transaction> after_protocol;
     transaction trans;

     //check reverse user signals
     check_rev_user(input);

     //Return protocol
     sub_models["protocol"]->Return(input, &after_protocol);

     //Correct ID if necessary
     while (after_protocol.empty() == false) {

         //select transaction
         trans = after_protocol.front();
         after_protocol.pop_front();

         //Modify the ID if required
         if (param_s("compress_id") == "true") {

             int    fixed_id = trans.id % (1 << (param("out_id_width") - param("max_vid_width"))); 
             string iid_siid = clist(param_s("in_id_list"), clist_rev(param_s("out_id_list"), to_bin_str(fixed_id, (param("out_id_width") - param("max_vid_width")))));    
              
             //Split the ID into it's three main parts
             int siid = (int)strtoul(iid_siid.c_str(), NULL, 2) % (1 << param("siid_width")); 
             int iid  = (int)strtoul(iid_siid.c_str(), NULL, 2) >> param("siid_width");
             int vid  = trans.id >> (param("out_id_width") - param("max_vid_width"));

             trans.id = (iid << (param("pl_id_width") - param("iid_width"))) + 
                         (vid << param("siid_width")) + siid;
         }

         //Output the transaction
         output->push_back(trans);
     }
     #else
     //check reverse user signals
     check_rev_user(input);
     
     //Return protocol
     sub_models["protocol"]->Return(input, output);
     #endif

}

