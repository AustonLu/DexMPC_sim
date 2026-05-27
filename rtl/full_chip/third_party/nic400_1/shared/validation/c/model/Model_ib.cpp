//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2016 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2016-03-07 14:37:41 +0000 (Mon, 07 Mar 2016)
//
// Revision            : 207834
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: IB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------
#include <vector>

#include "../include/Model.h"
#include "../include/Dom.h"
#include "../include/FrbmMacro.h"
#define  Debug_ib_qv
#define DEBUG_MSG 0

#include <iostream>
int dpe_width;
int mif_width;
int sif_width;

//-------------------------------------------------------------------------
// local_config function allows loading of any sub_models that this model requires
//-------------------------------------------------------------------------
void Model_ib::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {
  if (DEBUG_MSG) {
    std::cout << "***Starting Model_ib.cppv2... - config***" << std::endl;
  }

  Model* new_model;

  dpe_width = (*DomConfiguration).get_value_i(DomConfiguration->top, "/periph/dpe_width");
  sif_width = param("slave_if_data_width");
  mif_width = param("master_if_data_width");

  if (DEBUG_MSG) {
    cout << "dpe_width is " << dpe_width << endl;
    cout << "sif_width is " << sif_width << endl;
    cout << "mif_width is " << mif_width << endl;
    cout << "sif protocol is " << param_s("slave_if_protocol") << endl;
    cout << "mif protocol is " << param_s("master_if_protocol") << endl;
  }

  if ((param("slave_if_data_width") != param("master_if_data_width") || (param_s("slave_if_protocol") == "axi4") && (param_s("master_if_protocol") == "axi")) and (dpe_width == 0))
  {
      std::cout << "***Creating size model***" << std::endl;
      // Create size model
      new_model = new Model_size;
      new_model->Config(block_info, i_PL301_reg, i_connect_info, reg_update_i);

  }
  else if ((param("slave_if_data_width") != param("master_if_data_width") || (param_s("slave_if_protocol") == "axi4") && (param_s("master_if_protocol") == "axi")) and (dpe_width > 0))
  {
    // Create size model with dpe
    std::cout << "***Creating size model with dpe***" << std::endl;
    new_model = new Model_size_dpe;
    new_model->Config(block_info, i_PL301_reg, i_connect_info, reg_update_i);
  }
  else
  {
    if (DEBUG_MSG) { std::cout << "***Creating wire model - no size conversion necessary***" << std::endl; }
    // Create wire model, as there is no size conversion to do
    new_model = new Model_wire;
    new_model->Config(block_info, i_PL301_reg, i_connect_info);
  }

  // Store the model
  sub_models["size"] = new_model;

  //Initialize the value of associated_asib
  //This variable is used to define the ASIB-TLX-IB block order 
  associated_asib = false;

  //The name of the ib is <name>_ib, there is a need to construct the <name>_tlx
  //and search for this name.
  int length = name.length();
  string tlx_name = name;
  tlx_name = tlx_name.erase(length-3,3);
  tlx_name.append("_tlx");

  //get all the inter blocks
  vector<Node *> inters;
  inters = (*DomConfiguration).get_nodes(DomConfiguration->top, "/periph/inter");

  //Go through all the inter blocks 
  vector<Node*>::iterator node_iter;
  for (node_iter = inters.begin(); node_iter != inters.end(); node_iter++) {

      //get the type field  
      string inter_type = (*DomConfiguration).get_value((*node_iter), "type");

      //Determine properly the value of the associated_asib
      //If there is a ASIB-TLX-IB order then the TLX name will <name>_tlx
      //the ib name will be <name>_ib and the asib parameter of the inter/tlx 
      if (inter_type == "tlx") {
        string inter_name =  (*DomConfiguration).get_value((*node_iter), "name"); 
        if(tlx_name == inter_name){
              if( (*DomConfiguration).get_value((*node_iter), "asib") == "true"){
                      associated_asib = true;
              }
        }
      }
  }
  // Delete the assignment memory
  //delete  DomConfiguration;
  DomConfiguration = NULL;

}

//-------------------------------------------------------------------------
// Main Run function
//-------------------------------------------------------------------------
string Model_ib::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

        deque<transaction> after_size;
        transaction trans;
        vector<Node *> vns;
        vector<Node *> vns_up;

        if (DEBUG_MSG) { std::cout << "***Starting Model_ib3.cpp... - main run***" << std::endl; }

        //deque<transaction> input_;
        //var_trans = *input;
        //std::cout << "1stored_trans.size(): " << var_trans.size() << std::endl; 

        if (DEBUG_MSG) { cout << "Step 1*: Input trans (before sizing) is: " << input->front() << endl; }

        // pass variables to model_size
        (input->front()).dpe_width = dpe_width;
        (input->front()).mif_width = mif_width;
        (input->front()).sif_width = sif_width;

        if (DEBUG_MSG) { cout << "I am after input trans and will now get into model size" << endl; }

        sub_models["size"]->Run(input, &after_size, orginal_trans);

        if (DEBUG_MSG) { cout << "Step 2: Output trans (after sizing) is: " << after_size[0] << endl; } //HERE

        if (DEBUG_MSG) { cout << "I am after output trans, just exited model size" << endl; }

        // Check if after_size[ing] vector where we store transactions is empty.
        // If it's not then pop latest transaction, configure it and then output it
        while (after_size.empty() == false) {
          if (DEBUG_MSG) { std::cout << "***Inside while - selecting transaction***" << std::endl; }

          //select transaction
          trans = after_size.front();
          after_size.pop_front();

          //Protocol conversion for cases which have not been captured,
          //like AXI3->AXI4 Upsizer or AXI3->AXI4 with no data width conversion
          if((( param_s("slave_if_protocol") == "axi")) &&
              (param_s("master_if_protocol") == "axi4") &&
              (!(param("slave_if_data_width") > param("master_if_data_width"))) )
          {
              trans.protocol = axi;

              //All locked transactions are transformed to nolock/normal transactions
              if (trans.locked == (amba_lock)2)
              {
                trans.locked = nolock;
              }
              trans.unlocking = false;
          }

          //Override lock if either protocol = axi4
          if (param_s("slave_if_protocol") == "axi4" or param_s("master_if_protocol") == "axi4")
          {
              if (trans.locked == (amba_lock)2)
              {
                trans.locked = nolock;    
              }    
              trans.unlocking = false;
          }

          //Clear qv if going to itb
          if (param_s("master_if_protocol") == "itb" || param_s("master_if_protocol") == "itb4")
          {
                trans.qv = 0;    
          }

          //IF asib is true
          if ((param_s("asib") == "true") || associated_asib)
          {

              //SIID and IID assignment
              trans.id = trans.id % (int) pow(2.0, param("vid_width"));

              if( param("vid_width") != 0 && (param("vid_width") != param("pl_id_width")))
              {
                  trans.id = (param("iid") << (param("pl_id_width") - param("iid_width") - param("siid_width"))) + trans.id;
                  trans.id = (trans.id << param("siid_width")) + param("siid");
              }

              if (param("pl_id_width") == param("vid_width") && param_s("bridge") == "false" ) {
                  trans.id = ((trans.id % (int) pow(2.0, param("iid_width"))) << (param("pl_id_width") - param("iid_width"))) + (trans.id >> param("iid_width"));  
              }

          } 

          //Update for QV registers
          reg_update(trans.direction, trans.id, 1);

          //Trim the address width to the master_if_addr_width
          if (param_s("slave_if_addr_width") > param_s("master_if_addr_width"))
          {
              trans.address = trans.address % (1L << param("master_if_addr_width"));
          }

          //Set the region signal to zero if there is no region flag
          if (param_s("regions_flag") != "true")
          {
              trans.region = 0;
          };

          //If this is an AMIB related IB clear the valid value
          if (param_s("amib") == "true" || param_s("bridge") == "true" || param_s("reg_ss") == "true")
          {
              trans.valid = 0;    
          };

          //Set the qv value if it is not set
          if (param_s("qv/type") != "input")
          {
              if (param_s("qv/type") == "none")
              {
                  trans.qv = 0;
              }
              else if (param_s("apb_config") == "true" && param_s("qv/type") == "prog")
              {
                  if (trans.direction == frbm_namespace::read)
                  {
                      string qvreg = param_s("name") + ".read_qos";
                      trans.qv = PL301_reg->read(qvreg.c_str(), "ar_qos");
                  }
                  else
                  {
                      string qvreg = param_s("name") + ".write_qos";
                      trans.qv = PL301_reg->read(qvreg.c_str(), "aw_qos");
                  }
              }
              else
              {
                  trans.qv = param("qv/value");
              }
          }

          vns    = DomReader.get_nodes(parameters, "/inter/vn/downstream");
          vns_up = DomReader.get_nodes(parameters, "/inter/vn/upstream");

          //Vnet updates if required
          if (param_s("bridge") == "true" || param_s("amib") == "false") {

                if (param_s("bridge") == "true") {   
                    //IF you're a bridge and there are no downstreams then vnet = 0;   
                    if (vns.size() == 0) {
                      trans.vnet = 0;
                    }
                } else {
                    if (vns.size() == 0 && vns_up.size() != 0) {
                      trans.vnet = 0;
                    }
                }
          } else {
                //if part of an amib
                if (param_s("amib") == "true") {
                    if (DomReader.get_value(parameters, "vn_external") != "true") {
                        trans.vnet = 0;
                    }
                }
          }

          //IF there is one downstream then set the vnet 
          //AMIB is special case cannot really happen
          vns_up = DomReader.get_nodes(parameters, "/inter/vn");
          if (vns.size() == 1 || (vns_up.size() == 1 && DomReader.get_value(parameters, "vn_external") == "true")) {
                int vn_no = DomReader.get_value_i(parameters, "/inter/vn/number");
                trans.vnet = vn_convert(vn_no);
          }

          if (DomReader.get_value(parameters, "default_slave") == "true" and vns.size() != 0) {
                //If valid is equal to the valid width then going to the DS .. hence override    
                if (trans.valid == param("valid_width")) {
                    trans.vnet = 0;  
                }
          }

          if (dpe_width > 0 && param_s("bridge") == "true" && (param_s("slave_if_protocol") == "itb" || param_s("slave_if_protocol") == "itb4"))
          {

             //if write then set parity to 1 for strobed out data bytes
             if (trans.direction != frbm_namespace::read)
             {
                 int master_if_data_width = param("master_if_data_width");
             
                 trans.extract_parity();

                 for (int b=0; b<trans.length; b++)
                 {
                     arm_uint32 strobe = trans.bus_strobe(master_if_data_width/8, b);
                     trans.data_parity[b] = trans.data_parity[b] | ~strobe;
                 }

                 trans.insert_data_parity(master_if_data_width/8);
             }
          };

          //Set the forward user signals to zero if the width is zero
          check_fwd_user(&trans);


          //IF asib is true and vid_width is 0
          if ((param_s("asib") == "true" || associated_asib) && (param("vid_width") == 0)) {

              //SIID and IID assignment
              trans.id = (param("iid") << (param("pl_id_width") - param("iid_width") - param("siid_width"))) + trans.id;
              trans.id = (trans.id << param("siid_width")) + param("siid");
          }

          //Output the transaction
          output->push_back(trans);
        }

        return param_s("master_if_port_name");
}

//-------------------------------------------------------------------------
// Return function .. sets the internal valid function
//-------------------------------------------------------------------------

void Model_ib::Return(deque<transaction> * input, deque<transaction> * output) {
  if (DEBUG_MSG) {
    std::cout << "***Starting Model_ib.cpp... - return***" << std::endl;
  }
    //check reverse user signals
    check_rev_user(input);

    if (param_s("asib") == "true" || associated_asib) {

      //ID reversal
      for (unsigned int i = 0; i < input->size(); i++) {
          input->at(i).id = (input->at(i).id >> param("siid_width")) % (int) pow(2.0, param("vid_width"));
      }

    }

  //return size
  sub_models["size"]->Return(input, output);

}

