//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: RSB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------


#include "../include/Model.h"

//local_config function allows loading of any sub_models that this model requires
void Model_reg_ss_dist::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {

      Model * new_model;

      //NB all loaded parameters are available at this point
      if (param("slave_if_data_width") != 32) {

            //Create upsizer Model
            new_model = new Model_size;
            new_model->Config(block_info, i_PL301_reg, i_connect_info, reg_update_i);

            //Store the model
            sub_models["size"] = new_model;
      };

      //Create apb conv model Model
      new_model = new Model_Apbconv;
      new_model->Config(block_info, i_PL301_reg, i_connect_info);
      //dynamic_cast<Model_Apbconv*>(new_model)->allow_zero_strobes = true;

      //Store the model
      sub_models["protocol"] = new_model;

      if (param_s("protocol").substr(0, 3) != "axi") {
        //Create ahb conv model Model
        new_model = new Model_AhbMconv;
        new_model->Config(block_info, i_PL301_reg, i_connect_info);
      } else {
        //Create ahb conv model Model
        new_model = new Model_wire;
        new_model->Config(block_info, i_PL301_reg, i_connect_info);

      }
        //Store the model
        sub_models["ahb"] = new_model;

}


//Run function
string Model_reg_ss_dist::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

        //Local transaction
        transaction trans;
        deque<transaction> after_protocol;
        deque<transaction> after_size;
        deque<transaction> after_ahb;
        int nodenum;

        for (unsigned int input_index = 0; input_index < input->size(); input_index++) {
                 input->at(input_index).region = 0;
        };

        //Step 0 modify ID
        for (deque<transaction>::iterator trans = input->begin(); trans != input->end(); trans++) {
            (*trans).id = ((*trans).id * 256) + param("mid");
        };

        //Step 0.5 calling AHB model if required
        sub_models["ahb"]->Run(input, &after_ahb, orginal_trans);

        //Step 1 .. protocol and size translation
        if (param("slave_if_data_width") != 32) {
           sub_models["size"]->Run(&after_ahb, &after_size, orginal_trans);
           sub_models["protocol"]->Run(&after_size, &after_protocol, orginal_trans);
        } else {
           sub_models["protocol"]->Run(&after_ahb, &after_protocol, orginal_trans);
        };

        //Step 2 decode
        while (after_protocol.empty() == false) {

            //select transaction
            trans = after_protocol.front();
            after_protocol.pop_front();

            //Clear the forward user siganls if their width is zero
            check_fwd_user(&trans);

            //Determine the destination node (get bits 19:12)
            nodenum = (trans.address >> 12) % 256;

            //Align the address
            trans.address = trans.address - (trans.address % 4);

            //Only output the bottom 4K of the address
            trans.address = trans.address % 4096;

            //If broadcast add 0x1000 to the address
            if (nodenum == 0) {

                trans.address += 4096;

                //Broadcast reads clear the strobes as data isn't scoreboarded
                if (trans.direction == rd) {
                   trans.strobe[0] = "0000";
                };

            }



            //Output the transaction
            output->push_back(trans);
        }

        if (nodenum == 0)
        {

                map<string,Node*>::iterator conn_it;
                vector<string> nodenums;
                vector<string>::iterator nodeit;
                bool exists = false;

                //Get a list of all the appropriate broadcast nodes
                for (conn_it = connect_info->begin(); conn_it != connect_info->end(); ++conn_it){
                     if (DomReader.get_value(conn_it->second, "broadcast") == "true"){
                           exists = false;
                           for (nodeit = nodenums.begin(); nodeit != nodenums.end(); ++nodeit){
                                if (*nodeit == DomReader.get_value(conn_it->second, "dest_port"))
                                     exists = true;
                           }
                           if (exists == false)
                                nodenums.push_back(DomReader.get_value(conn_it->second, "dest_port"));
                      }
                }

                string nodelist = "";
                for (nodeit = nodenums.begin(); nodeit != nodenums.end(); ++nodeit){
                        if (nodeit != nodenums.begin())
                                nodelist += ",";
                        nodelist += *nodeit;
                }

                //This need updating to be internal
                if (nodelist == "") {
                      output->clear();
                      return "";
                } else {
                      return nodelist;
                }
        }
        else {

            //Find the node number in the node_numbers list
            int port = 0;
            bool found = false;
            for (int n = 0; n < param("master_ports"); n++) {
                 if (atoi(clist(param_s("node_numbers"), n).c_str()) == nodenum) {
                    port = n;
                    found = true;
                    break;
                 }
            }

            if  (found == false) {
                //Return nothing as transactions go to no ports
                output->clear();
                return "";
            } else {
                return clist(param_s("master_if_port_name"), port);
            }

        }
}

//Return function
void Model_reg_ss_dist::Return(deque<transaction> * input, deque<transaction> * output) {

     deque<transaction> after_protocol;
     deque<transaction> after_ahb;

     //Return protocol and size
     if (param("slave_if_data_width") != 32) {
           sub_models["protocol"]->Return(input,  &after_protocol);
           sub_models["size"]->Return(&after_protocol,  &after_ahb);
     } else {
           sub_models["protocol"]->Return(input, &after_ahb);
     };


     //Calling AHB model if required
     sub_models["ahb"]->Return(&after_ahb, output);

     for (deque<transaction>::iterator trans = output->begin(); trans != output->end(); trans++) {

            //Correct the ID
            (*trans).id = (*trans).id >> 8;

            //All responses are OK
            for (int i = 0; i < 256; i++) {
                (*trans).resp[i] = axi_okay;
            };

            //Set the data_width
            (*trans).data_width = param("slave_if_data_width") / 8;

     };


}

