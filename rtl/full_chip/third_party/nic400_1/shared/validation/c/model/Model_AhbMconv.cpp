//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2008-2017 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2017-07-24 11:26:32 +0100 (Mon, 24 Jul 2017)
//
// Revision            : 224180
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Ahb convertion Model .. used by ASIB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------

#include "../include/Model.h"

string Model_AhbMconv::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

    transaction * new_trans;
    transaction * trans;
    //    transaction front_trans;
    int iterations;
    int length;
    int size;
    int bytes;
    unsigned long long address;
    int to_boundary;
    unsigned long long wrap_boundary;

    bool broken_burst = false;
    bool incr_promotion = false;
    int beat;
    bool incr_promote_over_4kb = false;
    string data;
    string strobe;

    try {

        //Create a copy of the input transactions
        stored_trans = *input;

        while (input->empty() == false) {

            trans = new transaction;
            *trans = input->front();
            input->pop_front();

            //Register update call
            reg_update(trans->direction, trans->id, 2);

            //Clear the response flags
            early_resp = false;
            conv_singles = false;

            //Clear the unlocking flag because it doesn't apply to AHB
            trans->unlocking = false;

            //If locks are disabled, convert to unlocked
            if (trans->locked == ahb_lock && param_s("lock") == "false") {
                trans->locked = nolock;
            }

            //Convert standard incr to ahb_incr
            if (trans->burst == incr || trans->burst == axi_incr) {
                trans->burst = ahb_incr;
            }

            //Get the length
            if (trans->burst == ahb_single || trans->burst == ahb_incr) {
                length = (int)trans->length;
            }
            else if (trans->burst == ahb_wrap4 || trans->burst == ahb_incr4) {
                length = 4;
            }
            else if (trans->burst == ahb_wrap8 || trans->burst == ahb_incr8) {
                length = 8;
            }
            else { //if (trans->burst == ahb_wrap16 || trans->burst == ahb_incr16)
                length = 16;
            }

            //Get the size
            size   = (int)pow(2.0, (int)trans->size);
            bytes  = length * size;
            address = trans->address;

            if (address % size != 0) {
                cout << "Address is " << address << endl;
                throw "Unaligned address not supported in AHB";
            };

            //Create a new transaction
            new_trans = new transaction;
            *new_trans = *trans;
            iterations = 1;

            //For INCRs only determine if the transaction will cross a 1K boundary
            if ((trans->burst != ahb_wrap4) &&
                    (trans->burst != ahb_wrap8 ) &&
                    (trans->burst != ahb_wrap16))
            {
                to_boundary = 1024 - (address % 1024);
                if (to_boundary < bytes) {
                    cout << "Address " << hex << address << dec << " bytes " << bytes << " burst " << trans->burst << endl;
                    throw "Transaction cross 1KB not supported in AHB";
                }

            }

            wrap_boundary = trans->address - (trans->address % bytes);

            new_trans->protocol = axi;

            //Send transaction
            //Check protocol at IB master port and create the right type of transaction
            if(param_s("type") != "reg_ss_dist")
            {
              if(param_s("ib_master_port_name").substr(0,4) == "axi4" )
              {
                 new_trans->protocol = axi;
              }
           }
            //Set prot and cache bits for axi
            int prot10 = trans->prot % 4;
            int prot32 = trans->prot >> 2;
            int prot3 = (trans->prot >> 3) % 2;

            switch (prot10) {
                case 0: new_trans->prot = 4 ; break;      //APROT[2] =~HPROT[0] instruction/Data bit
                case 1: new_trans->prot = 0 ; break;
                case 2: new_trans->prot = 5 ; break;      // privileged bit
                case 3: new_trans->prot = 1 ; break;
            }
            if (param_s("trustzone") == "nsec")
                new_trans->prot += 2 ; // prot[1] is the security bit, set in ahb based on ASIB security

            switch (prot32) {
                case 0: new_trans->cache = 0 ; break;   // non-cacheable, non-bufferable
                case 1: new_trans->cache = 1 ; break;   // bufferable only
                case 2: new_trans->cache = 2 ; break;   // cacheable, do not allocate
                case 3: new_trans->cache = 15 ; break;  // cacheable, allocate on both reads and writes
            }

            if  (param_s("broken_bursts") == "true" and prot32 < 2) {
                broken_burst = true;
            }

            //Check for no burst locks
            if (trans->locked == ahb_lock && trans->length != 1) {

                cout << "Burst type is " << trans->burst << endl;
                cout << "Burst length is " << (int)trans->length << endl;
                //throw "Burst Lock Transaction not supported, only L1 transactions allowed";

            };

            string override = param_s("name") + ".fn_mod_ahb";

            //Set lock signal

            if (trans->locked == ahb_lock) {
               if(new_trans->protocol == axi)
               {
                  if (bridge_locked == true) {
                      //if the bridge is locked the make this transaction unlocking
                      new_trans->locked = nolock;
                      new_trans->unlocking = true;
                      cout << "Converting locked transaction to unlocked" << endl;
                      bridge_locked = false;
                  } else {
                      new_trans->locked = axi_lock;
                      bridge_locked = true;
                  };

                  if (param_s("apb_config") == "true" && PL301_reg->read(override.c_str(), "lock_override")) {
                      new_trans->locked = nolock;
                      trans->locked = nolock;
                      cout << "Overriding locked transaction to unlocked" << endl;
                      bridge_locked = false;
                      lock_overriden = true;
                  }
                  else
                      lock_overriden = false;
             } else
             {
                  new_trans->locked = nolock;
             }
            };

            //Set burst type and burst length
            if (broken_burst) { //broken_burst for destinatin type peripheral
                new_trans->burst = axi_incr;
                new_trans->length = 1;
                iterations = trans->length;
                conv_singles = true;
            } else if (trans->burst == ahb_wrap16 or trans->burst == ahb_wrap8 or trans->burst == ahb_wrap4 ) {
                new_trans->burst = axi_wrap;
                if (trans->burst == ahb_wrap4)  {
                    new_trans->length = 4;
                } else if (trans->burst == ahb_wrap8 ) {
                    new_trans->length = 8;
                } else {
                    new_trans->length = 16;
                };

            } else {
                new_trans->burst = axi_incr;
                if (trans->burst == ahb_single) new_trans->length = 1;
                else if (trans->burst == ahb_incr4)  new_trans->length = 4;
                else if (trans->burst == ahb_incr8)  new_trans->length = 8;
                else if (trans->burst == ahb_incr16)  new_trans->length = 16;
                else { // ahb_incr undefined length
                    if (param_s("ewr_incr_promotion") == "true" and (prot3 == 1) and (trans->locked != ahb_lock)) {
                        new_trans->length = 4 ;
                        iterations = (int)ceil(trans->length/4.0);
                    } else { // ahb_incr into singles
                        new_trans->length = 1;
                        iterations = trans->length;
                        conv_singles = true;
                    }
                }//ahb_incr

            };


            if ((param_s("ewr_incr_promotion") == "true") and (trans->direction == wr) and (prot3 == 1) and (trans->locked != ahb_lock)) {
                early_resp = true;
            }

            if (param_s("apb_config") == "true"){
            if ((trans->direction == rd && PL301_reg->read(override.c_str(), "rd_inc_override")) || (trans->direction == wr && PL301_reg->read(override.c_str(), "wr_inc_override"))){
                new_trans->burst = axi_incr;
                new_trans->length = 1;
                iterations = trans->length;
                conv_singles = true;
                if (trans->direction == wr && PL301_reg->read(override.c_str(), "wr_inc_override"))
                   early_resp = false;
            }
            }

            // push back the converted new_trans
            beat = 0;
            int luser = 0;
            while (iterations > 0) {

                //Determine if the transaction will cross a 4K boundary, corner case in incr_promotion
                if (new_trans->burst != axi_wrap)
                {
                    to_boundary = 4096 - (address % 4096);
                    if (to_boundary < (new_trans->length * size)) {
                        // cout << "Converting to AXI length 1.  Would have crossed 4KB boundary " << hex << "Address: 0x" << address << " length: 0x" << new_trans->length * size << endl;
                        // cout << "iterations: " << iterations << endl;
                        if (length != 1) {
                            iterations++;
                        }
                        incr_promote_over_4kb = true;
                        new_trans->length = 1;
                    }
                }
                int bnum = 0;
                for (int i = 0; i < new_trans->length ; i++, beat++) {

                    if (beat < trans->length) {

                        new_trans->data[i]   = trans->data[beat];
                        new_trans->user[i]   = trans->user[beat];
                        new_trans->mask[i]   = trans->mask[beat];
                        new_trans->strobe[i] = trans->strobe[beat];
                        new_trans->resp[i]   = trans->resp[beat];
                        new_trans->DVWait[i] = trans->DVWait[beat];
                        new_trans->DRWait[i] = trans->DRWait[beat];
                        new_trans->demit_code_s[i] = trans->demit_code_s[beat];
                        new_trans->dwait_code_s[i] = trans->dwait_code_s[beat];
                        new_trans->bnumber[i] = trans->bnumber[beat];

                        // convert ahb_error resp to axi slverr resp
                        if (new_trans->resp[i] == frbm_namespace::ahb_error) {
                            if (new_trans->direction == frbm_namespace::wr)
                                new_trans->resp[0] = frbm_namespace::axi_slverr; //axi write resp only take into acount of resp[0]
                            else
                                new_trans->resp[i] = frbm_namespace::axi_slverr;
                        }
                        string str = (new_trans->bnumber[i]).substr(1, 4);
                        sscanf(str.c_str(), "%x", &bnum);


                    } else {
                        // if DPE is true then a dummy write requires the parity bits in the wuser
                        // signal to be set as the data will be zero and odd parity is required.
                        int byte_width = param("slave_if_data_width") / 8;
                        int dpe_width = 0;
                        string w_user = string(USER_MAX_WIDTH,'0');
                        if (DomReader.get_value(parameters->parent, "dpe_width") != "<UNDEF>")
                        {
                          dpe_width = DomReader.get_value_i(parameters->parent, "dpe_width");
                        }

                        if (dpe_width > 0) {
                            // set byte_width + 1 as parity enable also needs to be set
                            for (int dpe = 0; dpe < (byte_width + 1); dpe++) {
                               w_user[USER_MAX_WIDTH - dpe - 1] = '1';
                            }
                         }
                        //This response will be dropped hence can be randomised
                        new_trans->resp[i] = (amba_resp)(rand() % 2);
                        new_trans->strobe[i].clear();
                        new_trans->data[i].clear();
                        new_trans->bnumber[i].clear();
                        new_trans->mask[i].clear();
                        new_trans->user[i] = w_user;

                        //Add empty strobes, data and bytes numbers
                        for (int new_byte_no = 0; new_byte_no < size; new_byte_no++) {
                            new_trans->strobe[i].append("0");
                            new_trans->data[i].append("00");
                            new_trans->mask[i].append("00");

                            //Build up bnumbers
                            if (bnum >= 65535) {
                                throw "Run out of byte numbers in Model_AhbMconv";
                            }
                            ostringstream data_str;
                            data_str << "0000" << hex << ++bnum;
                            string bnum_s = data_str.str();
                            new_trans->bnumber[i] = "b" + bnum_s.substr(bnum_s.size()-4,4) + new_trans->bnumber[i];
                        }
                    }
                }

                new_trans->remit_code_s = 0;
                new_trans->rwait_code_s = 0;
                if (iterations == 1) {
                    new_trans->remit_code_s = trans->remit_code_s;
                    new_trans->rwait_code_s = trans->rwait_code_s;
                }
                for (int i = 0; i < 16; i++){
                    new_trans->auser[i] = "";
                    new_trans->auser[i].insert(0,trans->auser[luser]);
                };

                luser += new_trans->length;
                output->push_back(*new_trans);
                iterations--;
                length -= new_trans->length;
                address += (size*new_trans->length);

                // modify address for broken burst across wrap boundary
                if (new_trans->burst != axi_wrap and (trans->burst == ahb_wrap16 or trans->burst == ahb_wrap8 or trans->burst == ahb_wrap4)) {
                    address = address%bytes + wrap_boundary;
                }
                new_trans->address = address;

                if (incr_promote_over_4kb == true) {
                    new_trans->length = 4;
                    incr_promote_over_4kb == false;
                }
            }
	    delete trans;
	    delete new_trans;

        }
        return "";



    } catch (const char * error) {

        cout << "Caught: AHBM convertion failed with message : " << error << endl;
        exit(1);
    }

}


void Model_AhbMconv::Return(deque<transaction> * input, deque<transaction> * output) {

    try {

        check_rev_user(&stored_trans);

        //Build up a list of reponses and user signals (from the input transactions)
        int beat_in = 0;
        for (unsigned int itrans = 0; itrans < input->size(); itrans++) {

            //clear beat to okay
            for (int beat = 0; beat < input->at(itrans).length; beat++) {
                stored_trans[0].resp[beat_in + beat] = okay;
            }

            if ((stored_trans[0].direction == rd)) {
                for (int beat = 0; beat < input->at(itrans).length; beat++) {
                    stored_trans[0].resp[beat_in] = input->at(itrans).resp[beat];
                    stored_trans[0].user[beat_in] = input->at(itrans).user[beat];
                    beat_in++;
                }
            } else {
                //IF early response then all responses are OK
                if (early_resp == false) {
                    if (conv_singles == true) {
                        stored_trans[0].resp[beat_in] = input->at(itrans).resp[0];
                        beat_in++;
                    } else {
                        //Set the last beat only
                        stored_trans[0].resp[beat_in + input->at(itrans).length - 1] = input->at(itrans).resp[0];
                        beat_in += input->at(itrans).length;
                    }
                } else {
                    //Increment beat_in to ensure all responses get cleared
                    beat_in += input->at(itrans).length;
                }
            }
        }

        //If the model is locked then the reponse will be OK (Only beat one needs to be considered)
        if (bridge_locked == true) {
            bridge_locked_resp = stored_trans[0].resp[0];
            stored_trans[0].resp[0] = okay;
        }

        //If the transaction is locked but the bridge isn't use the bridge_locked_resp
        if (stored_trans[0].locked == ahb_lock && param_s("lock") == "true" && bridge_locked == false) {
            if (stored_trans[0].resp[0] == okay && !lock_overriden) {
                stored_trans[0].resp[0] = bridge_locked_resp;
            }
        }

        for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {
            for (int beat = 0; beat <  stored_trans[strans].length; beat++) {
                if (stored_trans[strans].resp[beat] != okay) {
                    stored_trans[strans].resp[beat] = ahb_error;
                }
            }
        }

        input->clear();
        *output = stored_trans;

    } catch (const char * error) {

        cout << "Caught: AHBM convertion failed with message : " << error << endl;
        exit(1);
    }

}
