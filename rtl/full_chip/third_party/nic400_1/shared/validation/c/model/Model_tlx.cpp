//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2012 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2012-07-18 12:03:24 +0100 (Wed, 18 Jul 2012)
//
// Revision            : 133904
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: TLX model - simply moves transactions from input to output queue
//
//---------------------------------------------------------------------------

#include "../include/Model.h"

string Model_tlx::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

    //Local transaction
    transaction trans;
    vector<Node *> vns_dn;
    vector<Node *> vns_up;
    deque<transaction> inter;
    bool updatecache;

    //Store the incoming transaction
    stored_trans = *input;

    inter = *input;
    while (inter.empty() == false) {

        //select transaction
        trans = inter.front();
        inter.pop_front();

        if(param_s("slave_if_protocol")=="itb" && param_s("master_if_protocol")=="itb"){
        //Set the forward user signals to zero if the width is zero
        //When there is an itb-to -itb tlx then there is no aruser or awuser
        //there is only auser for this block which affects how the model
        //handles the auser signals
        check_fwd_user_itb(&trans);

        } else {
        //Set the forward user signals to zero if the width is zero
            check_fwd_user(&trans);
        }

        //Set the qv value if is not set
        if (param_s("qv/type") == "none") {
               trans.qv = 0;
        }

        //Set the region signal to zero if there is no region flag
        if (param_s("regions_flag") != "true") {
               trans.region = 0;
        }

        //Trim the address width to the master_if_addr_width
        if (param_s("slave_if_addr_width") > param_s("master_if_addr_width")) {
            trans.address = trans.address % (1L << param("master_if_addr_width"));
        }

        vns_dn = DomReader.get_nodes(parameters, "/inter/vn/downstream");
        vns_up = DomReader.get_nodes(parameters, "/inter/vn/upstream");

        //Record the incoming vnet
        current_vnet = trans.vnet; 
        if (vns_dn.size() == 0 && vns_up.size() != 0) {
            trans.vnet = 0;
        }

        //Output the transaction
        output->push_back(trans);
    }

     input->clear();
     return param_s("master_if_port_name");
}


//-------------------------------------------------------------------------
// Return function .. sets the internal valid function
//-------------------------------------------------------------------------

void Model_tlx::Return(deque<transaction> * input, deque<transaction> * output) {

    transaction trans;

    //check reverse user signals
    check_rev_user(input);

    while (input->empty() == false) {

       trans = input->front();
       input->pop_front();

       //Reset the vnet
       trans.vnet = current_vnet;

       //Output the transaction
       output->push_back(trans);
    }

}


