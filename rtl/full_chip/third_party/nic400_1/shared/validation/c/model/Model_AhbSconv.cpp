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
// Checked In          :  2014-02-25 14:55:35 +0000 (Tue, 25 Feb 2014)
//
// Revision            : 167698
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Ahb conversion Model .. used by AMIB model
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------

#include "../include/Model.h"
#include <cmath>

string Model_AhbSconv::Run(deque<transaction> * input, deque<transaction> * output, transaction * original_trans) {

    transaction * new_trans;
    transaction * trans;

    int length;
    int size;
    unsigned long long address;
    int to_boundary;

    unsigned long long Working_address;
    unsigned long long First_boundary_address;
    unsigned long long Final_address;
    int iterations;
    int transactions;
    int prot;
    bool first_trans;
    int beat;
    string data;
    string strobe;
    int first_length;
    bool force_incr = false;
    bool cross_1k_boundary;
    bool unaligned_address;
    int strans = 0;

    try {

        //This model creates multiple transactions
        //so it need to keep a copy of all the transactions it works on
        stored_trans = *input;

        //Check that the transaction is to region 0 else throw an exception
        if (input->front().region != 0) {
             throw "Region signal must be 0 to AHB";
        };

        while (input->empty() == false) {

            trans = new transaction;
            *trans = input->front();
            input->pop_front();

            //Register update call - AHB chicken bits
            reg_update(trans->direction, trans->id, 6);

            //Get the length and size
            length = (int)trans->length;
            size   = (int)pow(2.0, (int)trans->size);
            address = trans->address;

            transactions = 1;

            Working_address = trans->address - (trans->address % size);
            First_boundary_address = Working_address;
            Final_address   = Working_address + length*size ;

            //Determine if the transaction will cross a 1K boundary because of alignement
            cross_1k_boundary = false;
            unaligned_address = false;
            to_boundary = 1024 - (Working_address % 1024);
            first_length = length;

            if (to_boundary < (length * size) && trans->burst != axi_wrap) {
                cross_1k_boundary = true;
                unaligned_address = true;
                transactions = 2;
                first_length = to_boundary / size;
                First_boundary_address += to_boundary;
            };

            //Determine how many 1K boundary an AXI4 long bursts transaction will cross
            if ( trans->length > 16 && trans->burst == axi_incr  ) {
                int remaining_length ;

                if(unaligned_address) {
                   remaining_length = first_length + 1024/size ;
                } else {
                   remaining_length = 1024/size ;
                }

               while(length > remaining_length) {
                 int temp = remaining_length + 1024/size;

                 if(temp > length){
                    temp = length;
                 }
                 remaining_length = temp;
                 transactions++;
               }
            }

            //Wrap specific logic
            if (trans->burst == axi_wrap && trans->length == 2) {
                first_length = 1;
                transactions = 2;
            };

            //Fixed
            if (trans->burst == axi_fixed) {
                transactions = length;
            };

            //Any Decerrs that arrive here cannot be used (unless decerr resp is enabled .. which is dealt with separatly)
            //If there are any decerrs in the transaction update to OK and update orginal transaction
            for (int resp_no = 0; resp_no < 256; resp_no++ ) {
                if (trans->resp[resp_no] == axi_decerr) {
                     trans->resp[resp_no] = okay;
                }
            }

            //If this is a write and resp[0] is ok ... ensure all responses are ok
            if (trans->direction == wr && ((trans->resp[0] == okay) || (trans->strobe[0].find('1') == string::npos))) {
              for (int resp_no = 0; resp_no < trans->length; resp_no++ ) {
                   trans->resp[resp_no] = okay;
              }
            }

            //Reset force_incr for transactions that are broken
            force_incr = false;

            //IF APB config is turned on
            if (param_s("apb_config") == "true") {
                 string ahb_reg = param_s("name") + ".ahb_cntl";
                 //Set force INCR according register value
                 if (PL301_reg->read(ahb_reg.c_str(), "force_incr") == 1) {
                      force_incr = true;
                 };
            };

            //If this is not a bridge then cache values will be manipulated
            //Record force incr and put them back to normal
            if (param_s("bridge") != "true") {

                //Set force_incr if cache[3] is set
                if ((trans->cache >> 3) % 2) {
                    force_incr = true;
                };

                //Return cache bit
                int bit0 = trans->cache % 2;
                trans->cache = trans->cache >> 1;
                trans->cache = trans->cache - (trans->cache % 2) + bit0;

            };

            //IF force incr is turned on for a wrap divide the wrap into two transactions
            if (force_incr && (trans->burst == axi_wrap) && (trans->direction == wr)) {
                to_boundary = (length * size) - (trans->address % (length * size));
                transactions = 2;
                //The length will always be one for a length 2 wrap
                if (trans->length == 2) {
                    first_length = 1;
                } else {
                    first_length = to_boundary / size;
                }
            }

            //Set the working Address
            first_trans = true;
            iterations = transactions;
            int max_transactions = transactions;
            int previous_lengths = 0;
            int sum_lengths_w_cur_transaction = 0;
            int sum_lengths_without_cur_transaction = 0;

           //Do each iteration
            while (iterations > 0) {

                 //Create a new transaction
                 new_trans = new transaction;
                 *new_trans = *trans;

                 //Set prot bits for ahb based on prot and cache bits from axi
                 //prot[3:2] = cache[1:0]
                 prot = (trans->cache % 4) * 4;
                 //hprot[1] = axprot[0]
                 prot += (trans->prot % 2) * 2;
                 //prot[0] = ~axprot[2]
                 if (((trans->prot >> 2) % 2) == 0)
                   prot ++;

                 new_trans->prot = prot;

                 //Lock setting ... if this is an unlocking transaction
                 if (trans->unlocking == true) {
                     new_trans->locked = ahb_lock;
                 };

                 //If not no lock support remove unlock transactions
                 if (param_s("lock") == "false") {
                     new_trans->locked = nolock;
                 };

                 //Set the address, length and size fields
                 new_trans->address = Working_address;

                 //Set length used for wrap ... overriden for fixed later
                 //if (transactions == 2 && trans->burst == axi_wrap) {
                 //   if (iterations == 2) {
                 //      new_trans->length = first_length;
                 //   } else {
                 //      new_trans->length = length - first_length;
                 //   };
                 //};

                 //Set properly the lengths of the all previous transactions:
                 sum_lengths_without_cur_transaction = sum_lengths_w_cur_transaction ;
                 //Set length used for long_burst ... overriden for fixed later
                 if (transactions == max_transactions && max_transactions != 1 && trans->burst != axi_fixed) {
                    if (iterations == max_transactions) {
                       new_trans->length = first_length;
                    } else {
                       new_trans->length = 1024/size;

                       if((length - sum_lengths_without_cur_transaction)< new_trans->length ) {
                         new_trans->length = length - sum_lengths_without_cur_transaction;
                       } // end of if

                    };//end of else
                 };//end of if

                //Sum the lengths of the all transactions including the current one:
                sum_lengths_w_cur_transaction +=  new_trans->length ;

                 //Set burst type
                 if (trans->burst == axi_fixed) {

                      //override length for fixed
                      new_trans->length = 1;
                      new_trans->burst = ahb_single;

                 } else if (trans->burst == axi_wrap) {

                    if (force_incr && trans->direction == wr)
                        new_trans->burst = ahb_incr;
                    else if (length == 16) new_trans->burst = ahb_wrap16;
                    else if (length == 8) new_trans->burst = ahb_wrap8;
                    else if (length == 4) new_trans->burst = ahb_wrap4;
                    else if (length == 2) new_trans->burst = ahb_single;
                    else throw "Illegal transation received";

                 } else {//if burst is axi_incr

                    if ((trans->length != first_length) || (force_incr && trans->direction == wr))
                        new_trans->burst = ahb_incr;
                    else
                         if (length == 16) new_trans->burst = ahb_incr16;
                    else if (length == 8) new_trans->burst = ahb_incr8;
                    else if (length == 4) new_trans->burst = ahb_incr4;
                    else if (length == 1) new_trans->burst = ahb_single;
                    else new_trans->burst = ahb_incr;

                 };

                 // This conversion block does not change size .... hence all data will be in the correct byte lanes
                 // The only we need to do is move the data down to the correct beat
                 if (trans->burst == axi_fixed) {

                     new_trans->data[0] = new_trans->data[length - iterations];
                     new_trans->mask[0] = new_trans->mask[length - iterations];
                     new_trans->strobe[0] = new_trans->strobe[length - iterations];
                     new_trans->resp[0] = new_trans->resp[length - iterations];
                     new_trans->DVWait[0] = new_trans->DVWait[length - iterations];
                     new_trans->DRWait[0] = new_trans->DRWait[length - iterations];
                     new_trans->demit_code_s[0] = new_trans->demit_code_s[length - iterations];
                     new_trans->dwait_code_s[0] = new_trans->dwait_code_s[length - iterations];
                     new_trans->bnumber[0] = new_trans->bnumber[length - iterations];

                 } else if (transactions != 1 and iterations !=  max_transactions) {

                    for (beat = sum_lengths_without_cur_transaction; beat < sum_lengths_w_cur_transaction; beat++) {

                       //Set the data
                       new_trans->data[beat - sum_lengths_without_cur_transaction] = new_trans->data[beat];
                       new_trans->mask[beat - sum_lengths_without_cur_transaction] = new_trans->mask[beat];
                       new_trans->strobe[beat - sum_lengths_without_cur_transaction] = new_trans->strobe[beat];
                       new_trans->resp[beat - sum_lengths_without_cur_transaction] = new_trans->resp[beat];
                       new_trans->DVWait[beat - sum_lengths_without_cur_transaction] = new_trans->DVWait[beat];
                       new_trans->DRWait[beat - sum_lengths_without_cur_transaction] = new_trans->DRWait[beat];
                       new_trans->demit_code_s[beat - sum_lengths_without_cur_transaction] = new_trans->demit_code_s[beat];
                       new_trans->dwait_code_s[beat - sum_lengths_without_cur_transaction] = new_trans->dwait_code_s[beat];
                       new_trans->bnumber[beat - sum_lengths_without_cur_transaction] = new_trans->bnumber[beat];
                    };

                 };

                 //Send transaction
                 new_trans->protocol = ahb;

                 //Set buswidth on new transaction only used for random conversion
                 new_trans->data_width = param("master_if_data_width") / 8;

                 new_trans->remit_code_s = 0;
                 new_trans->rwait_code_s = 0;

                 if (iterations == 1) {
                   new_trans->remit_code_s = trans->remit_code_s;
                   new_trans->rwait_code_s = trans->rwait_code_s;
                 }

                 //Split up the created transaction if force_incr is true (and it is an incr)
                 if (force_incr && (trans->direction == wr) && (new_trans->burst == ahb_incr || new_trans->burst == ahb_single)) {

                     int base_len = 0;
                     int baseoffset = 0;
                     int translen = new_trans->length;

                     //Go through each beat and split the transaction if there's a strobless beat
                     for (int cbeat = 0; cbeat < translen; cbeat++) {

                       if (new_trans->strobe[cbeat - baseoffset].find('1') == string::npos) {
                             //If there is a transaction to do
                             if (base_len > 0) {

                                    //set length and push pack transaction
                                    new_trans->length = base_len;
                                    output->push_back(*new_trans);

                                    //increment address
                                    new_trans->address += (size * (base_len + 1));

                                    //erase beats
                                    new_trans->data.erase(new_trans->data.begin(), new_trans->data.begin() + base_len + 1);
                                    new_trans->mask.erase(new_trans->mask.begin(), new_trans->mask.begin() + base_len + 1);
                                    new_trans->strobe.erase(new_trans->strobe.begin(), new_trans->strobe.begin() + base_len + 1);
                                    new_trans->resp.erase(new_trans->resp.begin(), new_trans->resp.begin() + base_len + 1);
                                    new_trans->bnumber.erase(new_trans->bnumber.begin(), new_trans->bnumber.begin() + base_len + 1);

                                    for (int i = 0; i <= 15 - base_len; i++) {
                                          new_trans->DVWait[i] = new_trans->DVWait[i + base_len + 1];
                                          new_trans->DRWait[i] = new_trans->DRWait[i + base_len + 1];
                                          new_trans->demit_code_s[i] = new_trans->demit_code_s[i + base_len + 1];
                                          new_trans->dwait_code_s[i] = new_trans->dwait_code_s[i + base_len + 1];
                                    }

                             } else {

                                    //Waste a beat
                                    for (int i = 0; i <= 15; i++) {
                                          new_trans->DVWait[i] = new_trans->DVWait[i + 1];
                                          new_trans->DRWait[i] = new_trans->DRWait[i + 1];
                                          new_trans->demit_code_s[i] = new_trans->demit_code_s[i + 1];
                                          new_trans->dwait_code_s[i] = new_trans->dwait_code_s[i + 1];
                                    };

                                    new_trans->data.erase(new_trans->data.begin());
                                    new_trans->mask.erase(new_trans->mask.begin());
                                    new_trans->strobe.erase(new_trans->strobe.begin());
                                    new_trans->resp.erase(new_trans->resp.begin());
                                    new_trans->bnumber.erase(new_trans->bnumber.begin());

                                    //increment address
                                    new_trans->address += size;
                             };

                             //Set up offsets
                             baseoffset += base_len + 1;
                             base_len = 0;

                       } else {

                         //increment base_len
                         base_len++;

                         if (cbeat == translen - 1) {

                             //Output the rest of the transaction
                             new_trans->length = translen - baseoffset;
                             output->push_back(*new_trans);
			     delete new_trans;
                         };

                       };
                    }

                 } else {
                     output->push_back(*new_trans);
		     delete new_trans;
                 };

                 //If Calulate the output address
                 if (trans->burst == axi_wrap) {
                   //If length 2 address may go either way
                   if (trans->length == 2) {
                      if (Working_address % (size*2) == 0) {
                          Working_address = Working_address + size;
                      } else {
                          Working_address = Working_address - size;
                      }
                   } else {
                      //Other lengths allign to wrap boundary
                      Working_address = Working_address - (Working_address % (size * length));
                   }
                 }
                 else if (trans->burst != axi_fixed) {
                   Working_address = Working_address + ((sum_lengths_w_cur_transaction - sum_lengths_without_cur_transaction) * size);
                 }
                 iterations--;
             };
	     delete trans;

            //Reset the stored responses to okay
            for (int beat = 0; beat < stored_trans[strans].length; beat++) {
                  stored_trans[strans].resp[beat] = okay;
            }

            //Model Decerr responses
            if (param_s("apb_config") == "true") {

                //If the decode error enable is turned on
                string ahb_reg = param_s("name") + ".ahb_cntl";
                if (PL301_reg->read(ahb_reg.c_str(), "decerr_en") == 1) {

                    if (stored_trans[strans].address % (1 << stored_trans[strans].size) != 0) {
                        for (int resp_no = 0; resp_no < stored_trans[strans].length; resp_no++ ) {
                            stored_trans[strans].resp[resp_no] = axi_decerr;
                            //cout << "here" << endl;
                        }
                    }

                    //Look for strobeless beats
                    if (stored_trans[strans].direction == wr) {
                        for (int resp_no = 0; resp_no < stored_trans[strans].length; resp_no++ ) {
                           //If sparse (and not force_incr or not empty)
                           bool allow_strbless;
                           allow_strbless = force_incr || // cross_1k_boundary || // (stored_trans[strans].burst == axi_fixed) ||
                                   ((stored_trans[strans].length != 1) &&
                                    (stored_trans[strans].length != 4) &&
                                     (stored_trans[strans].length != 8) &&
                                      (stored_trans[strans].length != 16) &&
                                       ((stored_trans[strans].length != 2) && (stored_trans[strans].burst == axi_wrap)));

                           //cout << "strbless = " << allow_strbless << endl;
                           //cout << " 1 = " << (stored_trans[strans].strobe[resp_no].find('1') != string::npos) << endl;
                           //cout << " 0 = " << (stored_trans[strans].strobe[resp_no].find('0') != string::npos) << endl;
                           //cout << "strb " << stored_trans[strans].strobe[resp_no] << endl;
                           //If partially strobed or no strobes allow_strobless
                           if (((stored_trans[strans].strobe[resp_no].find('0') != string::npos) && (stored_trans[strans].strobe[resp_no].find('1') != string::npos)) ||
                               ((allow_strbless == false) && (stored_trans[strans].strobe[resp_no].find('1') == string::npos))) {
                               //cout << "hi" << endl;
                               stored_trans[strans].resp[0] = axi_decerr;
                               stored_trans[strans].resp[resp_no] = axi_decerr;
                           }
                        }
                    }
                }
            }

            strans = strans + 1;


        };

        return "";

    } catch (const char * error) {

            cout << "Caught: AHBS conversion failed with message : " << error << endl;
            exit(1);
    }

}


void Model_AhbSconv::Return(deque<transaction> * input, deque<transaction> * output) {

    try {

      transaction * trans;

      //Copy responses into stored transactions
      while (input->empty() == false) {

            trans = new transaction;
            *trans = input->front();
            input->pop_front();

            //Update responses in the stored transaction to the incoming ones
            for (int resp_no = 0; resp_no < trans->length; resp_no++ ) {
                   set_response(&stored_trans, trans->bnumber[resp_no], trans->resp[resp_no], 1, trans->user[resp_no]);
            }

       }

       //Finished with input queue
       input->clear();

       //Now go through all the stored transactions and make any corrections
       while (stored_trans.empty() == false) {

            trans = new transaction;
            *trans = stored_trans.front();
            stored_trans.pop_front();

            //Check reverse user
            check_rev_user(trans);

            //Check write responses for slave errors
            if (trans->direction == wr) {
                for (int resp_no = 1; resp_no < trans->length; resp_no++ ) {
                     if (trans->resp[resp_no] == axi_slverr and (trans->resp[resp_no] != axi_decerr)) {
                         trans->resp[0] = axi_slverr;
                     }
                     if (trans->resp[resp_no] == axi_decerr) {
                         trans->resp[0] = axi_decerr;
                     }

                }
            }

            //Ouput transaction
            output->push_back(*trans);
       }

    } catch (const char * error) {

            cout << "Caught: AHBS conversion failed with message : " << error << endl;
            exit(1);
    }

}
