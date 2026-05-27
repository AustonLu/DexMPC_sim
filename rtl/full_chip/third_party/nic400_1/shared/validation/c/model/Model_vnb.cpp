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
// Filename            : $RCSfile: AxiFrbmMacro.cpp,v $
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: vnb model - simply moves transactions from input to output queue
//
//---------------------------------------------------------------------------

#include "../include/Model.h"

string Model_vnb::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {
   
     transaction trans;
     vector<Node *> vns;
     vector<Node *>::iterator vn_iter;

     while (!input->empty())
     {
        // Extract the transaction currently at the head of the input queue
        trans = input->front();

        // Removes the extracted transaction from the input queue
        // Note: "pop_front()" does not return the transaction
        input->pop_front();
                 
        //If there is only 1 VN set the appropriate vnet
        vns = DomReader.get_nodes(parameters, "/inter/vn");
        if (vns.size() == 1) {             
            trans.vnet = vn_convert(DomReader.get_value_i(vns[0], "number"));
        }

        //VNBs don't alter transactions apart from VNET which is driven to zero when leaving the VN area or going to a DS
        if (param_s("default_slave") == "true") {
            //If valid is equal to the valid width then going to the DS .. hence override    
            if (trans.valid == param("valid_width")) {
                  trans.vnet = 0;  
            }
        }

        //IF there are no downstreams make vnet 0
        vns = DomReader.get_nodes(parameters, "/inter/vn/downstream");
        if (vns.size() == 0 and ((DomReader.get_value(parameters, "/inter/vn_external") == "none") or (DomReader.get_value(parameters, "/inter/amib") != "true"))) {
             trans.vnet = 0;  
        }

        //If region falg is 0 clear the region signal
        if (param_s("regions_flag") == "false") {
             trans.region = 0;    
        }

        // Push a copy of the modified transaction to the tail of the output queue
        output->push_back(trans);

     }; // while (!input->empty())

     return param_s("master_if_port_name");

}

