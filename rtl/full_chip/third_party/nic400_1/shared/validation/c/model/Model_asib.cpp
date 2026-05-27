//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2015 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2015-06-03 15:03:22 +0100 (Wed, 03 Jun 2015)
//
// Revision            : 195032
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: ASIB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------

#include "../include/Model.h"

//local_config function allows loading of any sub_models that this model requires
void Model_asib::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL) {

    Model * new_model;
    if  (param_s("protocol").substr(0, 3) == "ahb") {

        //Create apb conv model Model
        new_model = new Model_AhbMconv;
        new_model->Config(block_info, i_PL301_reg, i_connect_info, reg_update_i);

        //Store the model
        sub_models["protocol"] = new_model;

    } else {

        //Create wire Model as there is no protocol covertion to do
        new_model = new Model_wire;
        new_model->Config(block_info, i_PL301_reg, i_connect_info);

        //Store the model
        sub_models["protocol"] = new_model;

    }

}

//-------------------------------------------------------------------------
// Main Run function
//-------------------------------------------------------------------------
string Model_asib::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

    //Local transaction
    transaction trans;
    deque<transaction> inter;
    bool updatecache; 

    //Store the incoming transaction
    stored_trans = *input;

    //Step 1 .. protocol translation
    sub_models["protocol"]->Run(input, &inter, orginal_trans);

    //Asib specific updates
    while (inter.empty() == false) {  //Main model code

        //select transaction
        trans = inter.front();
        inter.pop_front();

        //Register update call - REMAP and SECURITY
        reg_update(trans.direction, trans.id, 0);

         //IF ib is false
        if (param_s("ib") == "false") {

           //If input id_width is not the full id width
           if (param("pl_id_width") != param("vid_width")) {

               //SIID and IID assignment
               trans.id = trans.id % (int) pow(2.0, param("vid_width"));
               trans.id = (param("iid") << (param("pl_id_width") - param("iid_width") - param("siid_width"))) + trans.id;
               trans.id = (trans.id << param("siid_width")) + param("siid");

           }
        }

       
        //Address decode
        //Beckett Update
        string remap_type = DomReader.get_value(parameters, "remap_type");
        if (remap_type == "import" || remap_type == "both") {
             updatecache = decode_internal(&trans);
        } else {
             updatecache = decode(&trans);
        };
        //Beckett Update

        //Beckett Update
        //If the asib is not a bridge but the vid_width == pl_id_width (import case then reorder the ID by taking the 
        //iid width from the bottom and placing them back at the top of the id REVISIT IB
        if (param("pl_id_width") == param("vid_width") && param_s("bridge") == "false" && param_s("ib") == "false") {
             trans.id = ((trans.id % (int) pow(2.0, param("iid_width"))) << (param("pl_id_width") - param("iid_width"))) + (trans.id >> param("iid_width"));  
        }
        //END Beckett Update
 
        //Register update call - QV
        reg_update(trans.direction, trans.id, 1);

        //Trim the address width to the global addr_width
        if (param_s("slave_if_addr_width") > param_s("addr_width")) {
          trans.address = trans.address % (1ULL << param("addr_width"));
        }

        //Set the forward user signals to zero if the width is zero
        check_fwd_user(&trans);

        //Set the region signal to zero if there is no region flag
        if (param_s("regions_flag") != "true") {
            trans.region = 0;
        }

        //Set the qv value if qv_out is not set
        if (param_s("qv/type") != "input")
            if (param_s("apb_config") == "true" && param_s("qv/type") == "prog") {
                if (trans.direction == frbm_namespace::read) {
                    string qvreg = param_s("name") + ".read_qos";
                    trans.qv = PL301_reg->read(qvreg.c_str(), "ar_qos");
                } else {
                    string qvreg = param_s("name") + ".write_qos";
                    trans.qv = PL301_reg->read(qvreg.c_str(), "aw_qos");
                }
            } else {
                trans.qv = param("qv/value");
            }

        //cache updates
        if (updatecache == true) {

            //Clear acache[1] and move old acache[1] to acache[2]
            trans.cache = (trans.cache % 2) + (((trans.cache >> 1) % 2) << 2);

            //If allow broken bursts or
            if (param_s("protocol").substr(0,3) == "ahb" &&
                    ((param_s("broken_bursts") == "true") || param_s("ewr_incr_promotion") == "true")) {

                trans.cache |= 0x8;
            }
        }

        //set prot bits if required
        if (param_s("bridge") == "false") {
            if (param_s("trustzone") == "sec") {
               trans.prot = trans.prot & 0x5;
            }
            if (param_s("trustzone") == "nsec") {
               trans.prot = trans.prot | 0x2;
            }
        }

        //AXI3 non-lockable masters must not be allowed to send lock
	if (param_s("lock") == "false" && param_s("protocol") == "axi") {
               trans.locked = (amba_lock)(trans.locked & 0x1);
	}

        //Output the transaction
        output->push_back(trans);

    }
    return param_s("master_if_port_name");
}

//-------------------------------------------------------------------------
// Return function
//-------------------------------------------------------------------------
void Model_asib::Return(deque<transaction> * input, deque<transaction> * output) {

    deque<transaction> after_protocol;

    //check reverse user signals
    check_rev_user(input);

    if (param_s("ib") == "false") {

       //ID reversal
       for (unsigned int i = 0; i < input->size(); i++) {
           input->at(i).id = (input->at(i).id >> param("siid_width")) % (int) pow(2.0, param("vid_width"));
       }

    }

    //Set protocol field
    if (param_s("protocol").substr(0, 3) == "ahb") {
        stored_trans[0].protocol = ahb;
    }
    stored_trans[0].data_width = param("slave_if_data_width") / 8;

    //Run protocol return
    sub_models["protocol"]->Return(input, &after_protocol);

    //Copy responses and user signals into response
    for (int beat = 0; beat < after_protocol[0].length; beat++) {
         stored_trans[0].resp[beat] = after_protocol[0].resp[beat];
         stored_trans[0].user[beat] = after_protocol[0].user[beat];
    }

    //Move transactions to output queue
    *output = stored_trans;
    input->clear();

}
//-------------------------------------------------------------------------
// Decode .. sets the internal valid function
//-------------------------------------------------------------------------
bool Model_asib::decode(transaction * trans) {

    //The valid is read in from the xml file.
    vector<Node *> ranges;
    vector<Node *>::iterator range_iter;
    vector<Node *> remaps;
    vector<Node *>::iterator remap_iter;
    vector<Node *> vns;
    vector<Node *>::iterator vn_iter;
    Node * range = NULL;
    int remap = 0;
    int valid_width = DomReader.get_value_i((*connect_info)[param_s("name") + "." + param_s("master_if_port_name")], "valid_width");
    int valid_max = valid_width - 1;
    int num_vns     = 0;
    int min_vn      = 0;
    string remap_type;
    int remap_value = 0;
    int port_remap_width = 0; 
    string binary_remap;
    bool update_cache = false;

    //Extract the port remap control
    if (DomReader.get_value(parameters, "port_remap_width") != "<UNDEF>") {
          port_remap_width = DomReader.get_value_i(parameters, "port_remap_width");
    }

  //Get the remap type if it's import only drop the bits
    remap_type = DomReader.get_value(parameters, "remap_type");
    if (remap_type == "export") {
        //Shift auser to include remap_value
        binary_remap = to_string_in_binary(0, port_remap_width, port_remap_width);
        trans->auser[0].insert(trans->auser[0].size(), binary_remap);
        trans->auser[0].erase(0,port_remap_width);
    }

    //Get the address map ranges
    ranges = DomReader.get_nodes(parameters, "/asib/address_ranges/range");
    if (ranges.size() == 0) {
        //must be bridge hence set default values and continue
        trans->valid = 0;
        if (param_s("multi_region") != "true") {
            trans->region = 0;
        }
        //vnet remains unchanged here
        return false;
    }

    //Determine which address range the address is in
    for (range_iter = ranges.begin(); range_iter != ranges.end(); range_iter++) {

        string amin = DomReader.get_value(*range_iter, "addr_min");
        if (amin == "<UNDEF>") {
            throw "Address range with no addr_min";
        }
        string amax = DomReader.get_value(*range_iter, "addr_max");
        if (amax == "<UNDEF>") {
            throw "Address range with no addr_max";
        }

        //Check the address_range
        if (trans->address >= strtoul(amin.c_str(),NULL,0) &
                trans->address <= strtoul(amax.c_str(),NULL,0)) {
            //Address match found
            range = *range_iter;
            break;
        }
    }

    //Get the virtual networks
    vns = DomReader.get_nodes(parameters, "/asib/vn");
    num_vns = vns.size();

    if (num_vns > 1) min_vn = 8;

    //Find the lowest VN number
    for (vn_iter = vns.begin(); vn_iter != vns.end(); vn_iter++) {

      //If VN is lower than current lowest, store
      if (DomReader.get_value_i(*vn_iter) < min_vn) {
         min_vn = DomReader.get_value_i(*vn_iter);
      }
    }

    if (num_vns > 1) {
         min_vn = vn_convert(min_vn);
    }

    //Default slave
    if (range == NULL) {
        //send the transaction to the default slave
        trans->valid = valid_max + 1;
        if (param_s("multi_region") != "true") {
            trans->region = 0;
        }
        if (param_s("vn_external") == "none") {
             trans->vnet = min_vn;
        }
        return false;
    }

    //Get the remap value
    string remap_reg = param_s("name") + ".remap";
    if (param_s("apb_config") == "true" && param("remap_width") > 0) {
        remap = PL301_reg->read(remap_reg.c_str(), "remap");
    }

    //Enable the default address map
    remap = remap + (int)pow(2.0, param("remap_width"));

    string remap_string;
    map<int, Node *> remap_map;
    int remap_val;

    //Get all the remap states
    remaps = DomReader.get_nodes(range, "remap");
    for (remap_iter = remaps.begin(); remap_iter != remaps.end(); remap_iter++) {

        //Get the remap bit value
        remap_string = DomReader.get_value(*remap_iter, "bit");
        if (remap_string == "default") {
            remap_val = param("remap_width");
        } else {
            remap_val = atoi(remap_string.c_str());
        }

        remap_map[remap_val] = *remap_iter;

        if (DomReader.get_value(*remap_iter, "protocol").substr(0,3) == "ahb")
        {
            update_cache = true;
        }
    }

    //Go through each bit of the remap and find the highest
    bool remap_found = false;
    int bit = 0;

    while (remap != 0) {

        if (((remap % 2) == 1) & remap_map.find(bit) != remap_map.end()) {
            remap_found = true;
            break;
        }

        //Otherwise shift remap
        remap = remap >> 1;
        bit = bit + 1;
    }

    //Else send to the default slave
    if (remap_found == false) {
        trans->valid = valid_max + 1;
        if (param_s("multi_region") != "true") {
            trans->region = 0;
        }
        update_cache = false;
    } else {

        if (DomReader.get_value(remap_map[bit], "present") == "true") {

            bool permission = true;

            if (param_s("trustzone") == "nsec" && DomReader.get_value(remap_map[bit], "trustzone") == "sec")
            {
                permission = false;

            }
            else if (param_s("trustzone") == "nsec" && DomReader.get_value(remap_map[bit], "trustzone") == "bs")
            {

                string security_reg = name + ".security" + DomReader.get_value(remap_map[bit], "infra_mi_no");
                int sec_val = PL301_reg->read_reg(security_reg.c_str());

                if (DomReader.get_value(remap_map[bit], "multi_region") == "true")
                {
                    if ((DomReader.get_value(remap_map[bit], "protocol").substr(0,3) == "apb") || (param_s("multi_region") != "true")) {
                        if (((sec_val >> (DomReader.get_value_i(remap_map[bit], "region"))) % 2) == 0)
                            permission = false;
                    } else {
                        if (((sec_val >> trans->region) % 2) == 0)
                            permission = false;
                    }
                }
                else
                {
                    if ((sec_val % 2) == 0)
                        permission = false;
                }
            }
            else if (param_s("trustzone") == "input" && DomReader.get_value(remap_map[bit], "trustzone") == "sec")
            {

                if ((trans->prot >> 1) % 2)
                    permission = false;
            }
            else if (param_s("trustzone") == "input" && DomReader.get_value(remap_map[bit], "trustzone") == "bs")
            {

                if ((trans->prot >> 1) % 2)
                {
                    string security_reg = name + ".security" + DomReader.get_value(remap_map[bit], "infra_mi_no");
                    int sec_val = PL301_reg->read_reg(security_reg.c_str());

                    if (DomReader.get_value(remap_map[bit], "multi_region") == "true")
                    {
                        if ((DomReader.get_value(remap_map[bit], "protocol").substr(0,3) == "apb") || (param_s("multi_region") != "true")) {
                            if (((sec_val >> (DomReader.get_value_i(remap_map[bit], "region"))) % 2) == 0)
                                permission = false;
                        } else {
                            if (((sec_val >> trans->region) % 2) == 0)
                                permission = false;
                        }
                    }
                    else
                    {
                        if ((sec_val % 2) == 0)
                            permission = false;
                    }

                }
            }

            if (DomReader.get_value(remap_map[bit], "trustzone") != "<UNDEF>") {
                trans->dest_sec  = DomReader.get_value(remap_map[bit], "trustzone");
            } else {
                trans->dest_sec = "nsec";
            }

            remap_value = 0;
  
            if (permission) {
                trans->valid = DomReader.get_value_i(remap_map[bit], "valid") + 1;
                if (DomReader.get_value(remap_map[bit], "region") != "<UNDEF>") {
                    if ((DomReader.get_value(remap_map[bit], "protocol").substr(0,3) == "apb") || (param_s("multi_region") != "true")) {
                        trans->region = DomReader.get_value_i(remap_map[bit], "region");
                    }
                } else if (param_s("multi_region") != "true") {
                    trans->region = 0;
                }

                //Determine the remap value to export 
                if (remap_type == "export") {

                     //Default should be encoded at 0
                     int reorder_bit;
                     if (bit == param("remap_width")) {
                         reorder_bit = 0;
                     } else {
                         reorder_bit = bit + 1;
                     }
                     binary_remap = to_string_in_binary(reorder_bit, port_remap_width, port_remap_width);
                     trans->auser[0].erase(trans->auser[0].size() - port_remap_width , port_remap_width);
                     trans->auser[0].insert(trans->auser[0].size(), binary_remap);
                     
                     cout << "remap is " << reorder_bit << endl;
                }

            } else {
                trans->valid = valid_max + 1;
                if (param_s("multi_region") != "true") {
                    trans->region = 0;
                }
                if (param_s("vn_external") == "none") {
                    trans->vnet = min_vn;
                }
                return false;
            }

            //Virtual Networks -
            if (param_s("vn_external") == "none") {

                 //If there are vns then set the correct value
                 if ((num_vns <= 1) || (DomReader.get_value(remap_map[bit], "vn") == "<UNDEF>")) {
                      //No vnet specified so use 0
                      trans->vnet = 0;
                 } else {
                      //Vnet specified so use specified VNET
                      trans->vnet = vn_convert(DomReader.get_value_i(remap_map[bit], "vn"));
                 }

            } else {

                 //Get all the vns
                 vns = DomReader.get_nodes(remap_map[bit], "vn");
                 int vn_match_found = 0;

                 for (vn_iter = vns.begin(); vn_iter != vns.end(); vn_iter++) {
                     if (vn_convert(DomReader.get_value_i(*vn_iter)) == trans->vnet) {
                         vn_match_found = 1;
                         continue;
                     }
                 }

                 //If no match was found send to DS!
                 if (vn_match_found == 0) {
                     trans->valid = valid_max + 1;
                     return false;
                 }

            }

            //If going to AHB and *not* the default slave
            if (DomReader.get_value(remap_map[bit], "protocol").substr(0,3) == "ahb") {
                //ensure that cache signals are updated later
                return true;
            }

        } else {
            if (valid_width == 1)
            {
                trans->valid = valid_max + 1;
            }
            else
            {
                trans->valid = valid_max + 1;
                if (param_s("multi_region") != "true") {
                    trans->region = 0;
                }
                if (param_s("vn_external") == "none") {
                    trans->vnet = min_vn;
                }
                update_cache = false;
            }
        }
    }

    return update_cache;
}

//-------------------------------------------------------------------------
// Decode .. sets the internal valid function
//        .. input decode
//-------------------------------------------------------------------------
bool Model_asib::decode_internal(transaction * trans) {

    //The valid is read in from the xml file.
    vector<Node *> ranges;
    vector<Node *>::iterator range_iter;
    vector<Node *> remaps;
    vector<Node *>::iterator remap_iter;
    vector<Node *> ids;
    vector<Node *>::iterator ids_iter;
    Node * range = NULL;
    

    int remap = 0;
    int matches_found  = 0;
    int local_match_found  = 0;
    int port_remap_width = 0; 
    int i;
    int incoming_remap_value = 0;
    int incoming_fixedid     = 0;
    int region_match         = 0;

    //Get the address map ranges
    ranges = DomReader.get_nodes(parameters, "/asib/address_ranges/range");
    if (ranges.size() == 0) {
        throw "No Address ranges found";
    }

    //Get the remap port width
    port_remap_width = param("port_remap_width");

    if (port_remap_width != 0) {
        incoming_remap_value = strtoul(trans->auser[0].substr(trans->auser[0].size() - port_remap_width, port_remap_width).c_str(), NULL, 2);
    }
   
    cout << "incoming_remap_value" << incoming_remap_value << endl;
    cout << "port_remap_width" << port_remap_width << endl;
    cout << "trans->auser"    << trans->auser[0] << endl;

    //Get the remap type if it's import only drop the bits
    string remap_type = DomReader.get_value(parameters, "remap_type");
    if (remap_type == "import") {
        trans->auser[0].erase(trans->auser[0].size() - port_remap_width , port_remap_width);
        trans->auser[0].insert(trans->auser[0].begin(), port_remap_width, '0');
    };

    //Determine the incoming fixedid
    incoming_fixedid = trans->id  % (int) pow(2.0, param("iid_width") + param("siid_width"));

    //Determine which address range the address is in
    for (range_iter = ranges.begin(); range_iter != ranges.end(); range_iter++) {

        string amin = DomReader.get_value(*range_iter, "addr_min");
        if (amin == "<UNDEF>") {
            throw "Address range with no addr_min";
        }
        string amax = DomReader.get_value(*range_iter, "addr_max");
        if (amax == "<UNDEF>") {
            throw "Address range with no addr_max";
        }

        //Check the address_range matches
        if (trans->address >= strtoul(amin.c_str(),NULL,0) &
                trans->address <= strtoul(amax.c_str(),NULL,0)) {

            //Get all the remap states in this address range
            remaps = DomReader.get_nodes(*range_iter, "remap");

            for (remap_iter = remaps.begin(); remap_iter != remaps.end(); remap_iter++) {

                 //Check whether the relevant bit is set in imported_remap tag
                 //Determine if imported remap bit is set according to the incoming user signals 
                 string imported_remap = DomReader.get_value(*remap_iter, "imported_remap");

                 local_match_found = 0;

                 //If port width is 0 (no remaps) or bit is set continue else go on
                 if (port_remap_width == 0 || (imported_remap.substr(imported_remap.size()- 1 - incoming_remap_value, 1)== "1")) {

                       ids = DomReader.get_nodes(*remap_iter, "fixedid");
                       for (ids_iter = ids.begin(); ids_iter != ids.end(); ids_iter++) {

                            string fixed_id_str = DomReader.get_value(*ids_iter);
 
                            //find and record match
                            if (incoming_fixedid == strtoul(fixed_id_str.c_str(),NULL,2)) {

                                 if (param_s("multi_region") == "true") {
                                     region_match = 1;
                                 } else if (DomReader.get_value(*remap_iter, "region") == "<UNDEF>") {
                                     region_match = (trans->region == 0);
                                 } else {
                                     region_match = (trans->region == DomReader.get_value_i(*remap_iter, "region"));
                                 }
  
                                 if (matches_found != 0 &&
                                          ((trans->valid != DomReader.get_value_i(*remap_iter, "valid") + 1) ||
                                           (region_match == 0))) {
                                    throw "Multiple address matches found";
                                 }

                                 if (param_s("regions_flag") != "true" ) {
                                    trans->region = 0;
                                 } else if (param_s("multi_region") == "true") {
                                    trans->region = trans->region; //keep the same
                                 } else if (DomReader.get_value(*remap_iter, "region") == "<UNDEF>") {
                                    trans->region = 0;
                                 } else {
                                    trans->region = DomReader.get_value_i(*remap_iter, "region");
                                 }

                                 trans->valid = DomReader.get_value_i(*remap_iter, "valid") + 1;
                                 local_match_found = 1;
                            };
                       }
                 } 

                 matches_found = matches_found + local_match_found;
            }
        }
    }

    //Check that a match was found
    if (matches_found == 0) {
        throw "No decode match found";
    }

    return false;
}
