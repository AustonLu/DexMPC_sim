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
// Checked In          :  2014-04-29 22:11:41 +0100 (Tue, 29 Apr 2014)
//
// Revision            : 172203
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Shared model data translation functions
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------
#define DEBUG_MSG 0


#include "../include/Model.h"

void Model_size_dpe::local_config(Node * block_info, Register_map * i_PL301_reg, map<string, Node*> * i_connect_info, reg_update_block * reg_update_i = NULL, Dom *DomConfiguration_i = NULL)
{
    //Get master and slave data widths
    master_if_data_width = param("master_if_data_width");
    slave_if_data_width = param("slave_if_data_width");

    master_data_bytes = master_if_data_width / 8;
    slave_data_bytes = slave_if_data_width / 8;

    master_data_bits = log2(master_data_bytes);
    slave_data_bits = log2(slave_data_bytes);

    merge_data   = string(slave_if_data_width/4,'0');
    merge_parity = string(slave_if_data_width/8,'0');

    if (DEBUG_MSG) { cout << "slave_if_data_width "  << slave_if_data_width << " master_if_data_width "  << master_if_data_width << endl; }
}

string Model_size_dpe::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {

    bool bypass = false;
    bool merge = true;
    int bytes;
    int beatbytes;
    int length;
    int size;
    int wrap_offset;
    protocol_t        master_if_protocol;
    protocol_t        slave_if_protocol;
    int bytes_to_boundary;
    int bytes_after_boundary = 0;
    int bytes_max;
    int input_offset;
    int output_offset;
    int pack_bytes;
    int new_beat;
    int exist_beat;
    int extra_bytes;
    unsigned long long Address_alligned;
    unsigned long long Address;
    unsigned long long wrap_boundary;
    unsigned long long NewAddress;
    transaction * trans;
    transaction front_trans;
    transaction process_trans;
    deque<transaction> process;
    vector<amba_resp> responses;
    vector<string> usersignals;
    amba_resp write_response;

    string all_data;
    string all_mask;
    string all_strobe;
    string all_bnumber;
    string all_parity;
    string all_parity_validity;
    int dummy_bnum = 0;
    bool unlocking_trans = false;
    string bnumbers;
    string bcode;

    try {
    //This model creates multiple transactions and maniplutes responsnes
    //so it need to keep a copy of all the transactions it works on
    stored_trans = *input;
    if (DEBUG_MSG) { cout << "***Starting Model_size_dpe***"  << endl; }
    if (DEBUG_MSG) { cout << "  stored_trans.size " <<stored_trans.size() << " : " << stored_trans.front()  << endl; }

    //Searching for the highest bnumber from the available transactions to give starting point for dummy beats
    for (unsigned int itrans = 0; itrans < stored_trans.size(); itrans++) {
        for (int beat = 0; beat < stored_trans[itrans].length; beat++) {
             bnumbers = stored_trans[itrans].bnumber[beat];

             while (bnumbers.length() >= 5) {

                 //Get the byte code
                 bcode = bnumbers.substr(0,5);
                 bnumbers = bnumbers.substr(5);

                 string btmp = "0x" + bcode.substr(1,4);
                 int bint = (int)strtoul(btmp.c_str(), NULL, 0);
                 if (dummy_bnum < bint)
                     dummy_bnum = bint;
             }
        }
    }

    while (input->empty() == false) {

        //local variables with loop scope with default values
        int max_length       = 16;

        //Pop the item from the input queue
        front_trans = input->front();
        input->pop_front();
        trans = &front_trans;

        trans->extract_parity();

        if (param_s("lock") == "true") {
            unlocking_trans = trans->unlocking;
        } else {
            unlocking_trans = false;
        };

        //NOTE LENGTH IS NOT ENCODED IN THE TRANSACTION CLASS I.E. LENGTH 1 = 1

        //Check the protcol
        if ((trans->burst != axi_incr) &&
            (trans->burst != axi_wrap) &&
            (trans->burst != axi_fixed)) {
             throw "Illegal protocol arriving in size model\n";
        }

        //Get master and slave protocols
        if(param_s("type") !="reg_ss_dist") {
          if(param_s("master_if_protocol") == "axi") {
              master_if_protocol  = (protocol_t)1;
          } else if (param_s("master_if_protocol") == "axi4") {
              master_if_protocol  = (protocol_t)4;
          } else { // the ITB case
              if(param_s("slave_if_protocol") == "axi"){
                  master_if_protocol   = (protocol_t)1;
              } else {
                 master_if_protocol   = (protocol_t)4;
             }
          }
        } else { //When the model is reg_ss_dist
              if(param_s("protocol") == "axi"){
                  master_if_protocol   = (protocol_t)1;
              } else {
                  master_if_protocol   = (protocol_t)4;
             }
       }

        if(param_s("type") !="reg_ss_dist") {
          if(param_s("slave_if_protocol") == "axi4"){
              slave_if_protocol   = (protocol_t)4;
          } else {
              slave_if_protocol   = (protocol_t)1;
          }
        }

        //Update the register block
        reg_update(trans->direction, trans->id, 5, trans->vnet);

        //Set the maximum length of this transaction based on the protocol and register settings
        if (master_if_protocol == axi4) {

          //Default for AXI4 is to not allow long bursts unless the incoming burst is longer than 16
          max_length = 16;

          if (trans->length > 16) {
              max_length = 256;
          }

          //Read the Burst Breaker Register fn_mod_bb
          if (param_s("apb_config") == "true" && (master_data_bytes < slave_data_bytes) && (param_s("master_if_protocol") == "axi4")) {
             string burstbreak_reg = param_s("name") + ".fn_mod_lb";
             if (PL301_reg->read(burstbreak_reg.c_str(), "fn_mod_lb", trans->vnet) == 1) {
                 max_length = 256;
             }
          }

        }

        //Calculate the alligned address
        Address_alligned = trans->address - (trans->address % (int)pow(2.0, (int)trans->size));
        Address = trans->address;
        if (DEBUG_MSG) { cout << "===================== Address_alligned  : " << hex << Address_alligned << dec  << endl; }
        if (DEBUG_MSG) { cout << "===================== Address           : " << hex << Address << dec  << endl; }

        //Calculate bytes in transfer (corrected for allignment)
        bytes = ((trans->length) * (int)pow(2.0, (int)trans->size)) - (trans->address - Address_alligned);
        beatbytes = (int)pow(2.0, (int)trans->size) - (trans->address - Address_alligned);
        if (DEBUG_MSG) { cout << "==================== bytes              : " << bytes  << endl; }
        if (DEBUG_MSG) { cout << "==================== beatbytes          : " << beatbytes  << endl; }

        //Special case ... if we are downsizing and this is a fixed burst correct size to most appropriate
        if ((trans->burst == axi_fixed) && (master_data_bytes < slave_data_bytes) && (master_data_bytes < (int)pow(2.0, (int)trans->size)) ) {

            if (DEBUG_MSG) { cout << "Special case ... if we are downsizing and this is a fixed burst correct size to most appropriate"  << endl; }

            //Find the appropriate size for the outgoing trans
            int lbytes = 1;
            unsigned int fsize = 0;
            while (lbytes < beatbytes) { lbytes = lbytes * 2; fsize++;};

            //Remove excess data and information
            int cbytes = ((int)pow(2.0, (int)trans->size));
            if (DEBUG_MSG) { cout << "Remove excess data and information" << " cbytes " << cbytes << " lbytes " << lbytes  << endl; }
            while (cbytes > lbytes) {

                for (int beat = 0; beat < trans->length; beat++)
                {
                      front_trans.data[beat] = front_trans.data[beat].substr(0,front_trans.data[beat].size()-2);
                      front_trans.mask[beat] = front_trans.mask[beat].substr(0,front_trans.mask[beat].size()-2);
                      front_trans.strobe[beat] = front_trans.strobe[beat].substr(0,front_trans.strobe[beat].size()-1);
                      front_trans.bnumber[beat] = front_trans.bnumber[beat].substr(0,front_trans.bnumber[beat].size()-5);
                }

                cbytes--;
            }

            //Reset the transaction size
            trans->size = (amba_size)fsize;

            //Correct the Alligned address
            Address_alligned = trans->address - (trans->address % (int)pow(2.0, (int)trans->size));

            // no read parity in APB AMIB
	    if (param_s("amib") == "true" && param_s("amib_protocol").substr(0,3) == "apb")
	    {
        	if (DEBUG_MSG) { cout << "no read parity in APB AMIB"  << endl; }
	    }
	    else
	    {
        	//fixup the other parity representations
        	front_trans.insert_parity(master_if_data_width/8);
	    }

            if (DEBUG_MSG) { cout << "  special case trans changed to : " << front_trans  << endl; }
        }

        int bypass_int = 0;

        if (param_s("apb_config") == "true" && ((param("master_if_data_width") != param("slave_if_data_width")) || (param_s("slave_if_protocol") == "axi4" && param_s("master_if_protocol") == "axi"))) {
                    string bypassreg = param_s("name") + ".fn_mod2";
                    bypass_int = PL301_reg->read(bypassreg.c_str(), "bypass_merge", trans->vnet);
        } else if (param_s("apb_config") == "false" && param_s("bridge") == "true" && param_s("amib") == "true" &&  param_s("amib_protocol").substr(0,3) == "ahb") {
                    bypass_int = 1;
        } else {
                    bypass_int = 0;
        }

        //Work out if this burst should be broken only i.e. cache[1] is 0 and the burst length is greater than minimum
        merge = true;
        if ((((trans->cache / 2) == (int(trans->cache / 4) * 2)) || bypass_int == 1) && (trans->length > 16)) {
           merge = false;
        }

//        cout << "burst merge is " << ((merge)?"true":"false") << endl;

        //Work out if this transaction is going to be let through i.e. do nothing
        // condtions are:
        //   1) fixed (upsize only)
        //   2) cache[1] = 0 (unless size is too big for output bus)
        //   3) length = 1 (unless size is too big for output bus)

        bypass = ((bypass_int == 1 && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
                 (trans->burst == axi_fixed && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
                 (((trans->cache / 2) == (int(trans->cache / 4) * 2)) && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
                 ((trans->length == 1) && (master_data_bytes >= (int)pow(2.0, (int)trans->size)))) && (trans->length <= max_length);

//        cout << "burst bypass is " << ((bypass)?"true":"false") << endl;

        if (bypass & merge == true) {
                //simply push onto output queue and return
                if (DEBUG_MSG) { cout << "simply push onto output queue and return"  << endl; }
                if (trans->dpe_width > 0)
                {
                    if (trans->direction == wr)
                    {
                        arm_uint64 bus_mask = 1;
                        bus_mask = (bus_mask << master_data_bytes ) - 1;

                        if (DEBUG_MSG) { cout << "WR"  << endl; }
                        for (int b=0; b<trans->length; b++)
                        {
                            if (DEBUG_MSG) { cout << "original         data_parity[" << b << "] = 0x" << hex << trans->data_parity[b] << dec  << endl; }

                            //re-align the parity to match the data position on the master interface bus
                            int sif_lbl =  trans->lower_byte_lane(slave_if_data_width/8, b+1);
                            int mif_lbl =  trans->lower_byte_lane(master_if_data_width/8, b+1);
                            if (DEBUG_MSG) { cout << "sif_lbl " << sif_lbl << " mif_lbl " << mif_lbl  << endl; }
                            if (mif_lbl < sif_lbl)
                            {
                                trans->data_parity[b] = trans->data_parity[b] >> (sif_lbl - mif_lbl);
                            }
                            else
                            {
                                trans->data_parity[b] = trans->data_parity[b] << (mif_lbl - sif_lbl);
                            }
                            if (DEBUG_MSG) { cout << "after shift      data_parity[" << b << "] = 0x" << hex << trans->data_parity[b] << dec  << endl; }

                            // set correct parity for masked out write data
                            arm_uint32 mif_strobe = trans->bus_strobe(master_if_data_width/8, b);
                            if (DEBUG_MSG) { cout << "mif_strobe " << hex << mif_strobe  << dec  << endl; }
                            trans->data_parity[b] = trans->data_parity[b] & mif_strobe | ~mif_strobe;
                            if (DEBUG_MSG) { cout << "after mif_strobe data_parity[" << b << "] = 0x" << hex << trans->data_parity[b] << dec  << endl; }

                            // trim the parity to the master interface bus width
                            trans->data_parity[b] = trans->data_parity[b] & bus_mask;
                            if (DEBUG_MSG) { cout << "after bus_mask   data_parity[" << b << "] = 0x" << hex << trans->data_parity[b] << dec  << endl; }
                        }
                        trans->insert_data_parity();
                    }
                }
                output->push_back(*trans);
                continue;
        }

        if (trans->direction == wr)
        {
            // model behaviour of write merge buffer
            string beat_data;
            string beat_strobe;
            string beat_parity;

            for (exist_beat = 0; exist_beat < front_trans.length; exist_beat++)
            {
                beat_data   = front_trans.full_bus_data(slave_if_data_width/8, exist_beat);
                beat_strobe = front_trans.full_bus_strobe(slave_if_data_width/8, exist_beat);
                beat_parity = front_trans.full_bus_parity(slave_if_data_width/8, exist_beat);

                if (DEBUG_MSG) { cout << "merge_data     |" << merge_data    << "|"  << endl; }
                if (DEBUG_MSG) { cout << "merge_parity   |" << merge_parity  << "|"  << endl; }

                if (DEBUG_MSG) { cout << "beat_data    |"  << beat_data   << "|"  << endl; }
                if (DEBUG_MSG) { cout << "beat_strobe  |"  << beat_strobe << "|"  << endl; }
                if (DEBUG_MSG) { cout << "beat_parity  |" << beat_parity  << "|"  << endl; }

                string next_merge_data;
                string next_merge_parity;
                arm_uint32 pmask = 1 << (slave_if_data_width/8 - 1);
                for(int b=0; b<slave_if_data_width/8;b++)
                {
                    if (beat_strobe[b] == '1')
                    {
                        next_merge_data = next_merge_data + beat_data.substr(b*2,2);
                        next_merge_parity = next_merge_parity + beat_parity.substr(b,1);
                    }
                    else
                    {
                        next_merge_data = next_merge_data + merge_data.substr(b*2,2);
                        next_merge_parity = next_merge_parity + merge_parity.substr(b,1);
                    }
                    pmask = pmask >> 1;
                }

                if (DEBUG_MSG) { cout << "next_merge_data     |" << next_merge_data   << "|"  << endl; }
                if (DEBUG_MSG) { cout << "next_merge_parity   |" << next_merge_parity << "|"  << endl; }

                merge_data   = next_merge_data;
                merge_parity = next_merge_parity;

                front_trans.put_bus_data(slave_if_data_width/8, exist_beat, merge_data);
                front_trans.put_bus_parity(exist_beat, merge_parity);
            }
            if (DEBUG_MSG) { cout << "update data_parity"  << endl; }
            //update data_parity
            front_trans.insert_parity(slave_if_data_width/8);

            if (DEBUG_MSG) { cout << "front_trans after merge : " << front_trans  << endl; }
        }

        //Calculate the wrap boundary
        wrap_boundary = trans->address - (trans->address % bytes);
        if (DEBUG_MSG) { cout << "===============wrap_boundary is: " << hex << wrap_boundary  << endl; }

        //Record the write response
        write_response = trans->resp[0];

        //If this is a wrap convert which fits into a single beat on the bus ... reorder the bytes
        if ((trans->burst == axi_wrap) && (bytes <= master_data_bytes)) {

           //determine the wrap offset
           wrap_offset = master_data_bytes - ((trans->address % bytes) / (int)pow(2.0, (int)trans->size));
           if (DEBUG_MSG) { cout << "===============wrap_offset is: " << hex << wrap_offset << dec  << endl; }

           //convert to incr
           trans->burst = axi_incr;

           //allign the address to wrap boundary
           trans->address = wrap_boundary;

           //reorder all the data / user fields (ACB so that the first beat is on the wrap boundary)
           //Note that only the data is re-ordered .. the last USER beats will still be used
//           cout << "--------------------" << endl;
           for (int b = 0; b < front_trans.length; b++) {
//               cout << "front_trans.data[" << b << "] " << hex << front_trans.data[b] << dec << endl;
//               cout << "front_trans.data_parity[" << b << "] " << hex << front_trans.data_parity[b] << dec << endl;
           }
           for (int beat = 0; beat < wrap_offset; beat++) {

                  if (front_trans.length == 16) {
                      front_trans.data.push_back("");
                      front_trans.mask.push_back("");
                      front_trans.strobe.push_back("");
                      front_trans.bnumber.push_back("");
                  };

                  front_trans.data[front_trans.length] = front_trans.data[0];
                  front_trans.data.erase(front_trans.data.begin());
                  if (front_trans.data.size() < 16) { front_trans.data.push_back(""); };

                  front_trans.mask[front_trans.length] = front_trans.mask[0];
                  front_trans.mask.erase(front_trans.mask.begin());
                  if (front_trans.mask.size() < 16) { front_trans.mask.push_back(""); };

                  front_trans.strobe[front_trans.length] = front_trans.strobe[0];
                  front_trans.strobe.erase(front_trans.strobe.begin());
                  if (front_trans.strobe.size() < 16) { front_trans.strobe.push_back(""); };

                  front_trans.bnumber[front_trans.length] = front_trans.bnumber[0];
                  front_trans.bnumber.erase(front_trans.bnumber.begin());
                  if (front_trans.bnumber.size() < 16) { front_trans.bnumber.push_back(""); };

                  front_trans.parity[front_trans.length] = front_trans.parity[0];
                  front_trans.parity.erase(front_trans.parity.begin());

                  front_trans.data_parity[front_trans.length] = front_trans.data_parity[0];
                  front_trans.data_parity.erase(front_trans.data_parity.begin());

                  front_trans.parity_validity[front_trans.length] = front_trans.parity_validity[0];
                  front_trans.parity_validity.erase(front_trans.parity_validity.begin());

           }
           if (DEBUG_MSG) { cout << "--------------------"  << endl; }
           for (int b = 0; b < front_trans.length; b++) {
               if (DEBUG_MSG) { cout << "front_trans.data[" << b << "] " << hex << front_trans.data[b] << dec  << endl; }
               if (DEBUG_MSG) { cout << "front_trans.data_parity[" << b << "] " << hex << front_trans.data_parity[b] << dec  << endl; }
           }
           if (DEBUG_MSG) { cout << "--------------------"  << endl; }

           //Update the recorded addresses
           Address = wrap_boundary;
           Address_alligned = wrap_boundary;

        }

        all_data.clear();
        all_mask.clear();
        all_strobe.clear();
        all_bnumber.clear();
        all_parity.clear();
        all_parity_validity.clear();

        //Special case .... the packing logic later assumes that all data (after an initial offset is valid
        //This is not true for fixed bursts where entire output beats are ignore from the start. These should therefore not be added here
        int ignore_bytes = 0;
        while (Address - Address_alligned - ignore_bytes >= master_data_bytes) {
              ignore_bytes += master_data_bytes;
        };

        responses.clear();
        usersignals.clear();

        if (DEBUG_MSG) { cout << "Now append all the data fields together for use later"  << endl; }
        //Now append all the data fields together for use later
        for (exist_beat = 0; exist_beat < front_trans.length; exist_beat++)
        {
            int remove_bytes = 0;
            if (front_trans.burst == axi_fixed && exist_beat != 0)
            {
               remove_bytes = ignore_bytes;
            }
            if (DEBUG_MSG) { cout << "remove_bytes " << remove_bytes  << endl; }

            int nibbles = (int)(pow(2.0, (int)(trans->size)) * 2);

            if (front_trans.data[exist_beat].substr(0,2) == "0x") front_trans.data[exist_beat] = front_trans.data[exist_beat].substr(2);                   // remove any leading "0x"
            if (front_trans.data[exist_beat].size() < nibbles) front_trans.data[exist_beat].insert(0, '0', nibbles - front_trans.data[exist_beat].size()); // pad with leading 0s
            all_data.insert(0,front_trans.data[exist_beat].substr(0,front_trans.data[exist_beat].size()-(remove_bytes*2)));                                // copy in the beat data
            if (DEBUG_MSG) { cout << "[" << exist_beat << "] beat_data   " << front_trans.data[exist_beat].substr(0,front_trans.data[exist_beat].size()-(remove_bytes*2))  << endl; }

            if (front_trans.mask[exist_beat].substr(0,2) == "0x") front_trans.mask[exist_beat] = front_trans.mask[exist_beat].substr(2);
            if (front_trans.mask[exist_beat].size() < nibbles) front_trans.mask[exist_beat].insert(0, '0', nibbles - front_trans.mask[exist_beat].size());
            all_mask.insert(0,front_trans.mask[exist_beat].substr(0,front_trans.mask[exist_beat].size()-(remove_bytes*2)));

            if (front_trans.strobe[exist_beat].size() < (nibbles /2)) front_trans.strobe[exist_beat].insert(0, '0', (nibbles/2) - front_trans.strobe[exist_beat].size());
            all_strobe.insert(0,front_trans.strobe[exist_beat].substr(0,front_trans.strobe[exist_beat].size()-remove_bytes));
            if (DEBUG_MSG) { cout << "[" << exist_beat << "] beat_strobe " << front_trans.strobe[exist_beat].substr(0,front_trans.strobe[exist_beat].size()-remove_bytes)  << endl; }

            all_bnumber.insert(0,front_trans.bnumber[exist_beat].substr(0,front_trans.bnumber[exist_beat].size()-(remove_bytes*5)));

            if (DEBUG_MSG) { cout << "[" << exist_beat << "] beat_lane " << front_trans.lower_byte_lane(slave_if_data_width/8, exist_beat+1)  << endl; }

            string par_str;
            par_str = front_trans.beat_parity(slave_if_data_width/8, exist_beat);
            par_str = par_str.substr(0, par_str.size() - remove_bytes);

            all_parity.insert(0,par_str);
            if (DEBUG_MSG) { cout << "[" << exist_beat << "] beat_parity " << par_str  << endl; }

            string par_val_str = (front_trans.parity_validity[exist_beat]) ? string(nibbles/2-remove_bytes,'1') : string(nibbles/2-remove_bytes,'0');
            all_parity_validity.insert(0,par_val_str);
            if (DEBUG_MSG) { cout << "[" << exist_beat << "] beat_parity_validity " << par_val_str  << endl; }

            //create a list of respones & user signals (one copy per byte)
            for (int each_byte = remove_bytes; each_byte < (int)pow(2.0, (int)trans->size); each_byte++) {
                   responses.insert(responses.begin(),front_trans.resp[exist_beat]);
                   usersignals.insert(usersignals.begin(),front_trans.user[exist_beat]);
            }
        }

        if (DEBUG_MSG) { cout << "all_data            |" << all_data             << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_mask            |" << all_mask             << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_strobe          |" << all_strobe           << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_bnumber         |" << all_bnumber          << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_parity          |" << all_parity           << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_parity_validity |" << all_parity_validity  << "|"  << endl; }

        //Convert any wraps aligned to burst boundary to INCR
        if ((trans->burst == wrap || trans->burst == axi_wrap) && (trans->address % bytes == 0)) {
             trans->burst = axi_incr;
        }

        int first_transaction = bytes;
        int other_transaction = 0;
        int max_transactions = 1;

        //If this is a wrap that is not alligned to the wider bus split it into two
        if ((trans->burst == axi_wrap) && (((trans->address % master_data_bytes) != 0) || (bytes > master_data_bytes * 16 ))) {

             //First transaction is bytes to wrap boundary
             first_transaction = bytes - (trans->address % bytes);
             other_transaction = (trans->address % bytes);
             max_transactions = 2;

             //Also in this case remove an exclusive flag if it exists
             if (trans->locked == axi_excl) {
                 trans->locked = nolock;
             }

             //Override to incr
             trans->burst = axi_incr;
        }

        //IF this is a fixed then split it up into muliple transactions
        if (trans->burst == axi_fixed) {

             first_transaction = beatbytes;
             other_transaction = beatbytes;
             max_transactions = trans->length;
             wrap_boundary = trans->address;

             //Also in this case remove an exclusive flag if it exists (and length > 1)
             if (trans->locked == axi_excl && trans->length > 1) {
                 trans->locked = nolock;
             }

             //Override to incr
             trans->burst = axi_incr;
        };

        //For each transaction
        if (DEBUG_MSG) { cout << "max_transactions = " << dec << max_transactions  << endl; }
        for (int trans_no = 0; trans_no < max_transactions; trans_no++) {

            if (DEBUG_MSG) { cout << "------------------"  << endl; }
            if (DEBUG_MSG) { cout << "transaction  = " << dec << trans_no  << endl; }
            if (DEBUG_MSG) { cout << "------------------"  << endl; }
            //Set bytes to the correct value
            if (trans_no == 0) {
                bytes = first_transaction;
            } else {
                bytes = other_transaction;
                trans->address = wrap_boundary;
            }

            //Determine the maxinum number of bytes in the burst.
            int max_bytes;
            int max_beat_bytes;

            max_beat_bytes = master_data_bytes;
            if (merge == false) {
               if (max_beat_bytes > (int)pow(2.0, (int)trans->size)) {
                    max_beat_bytes = (int)pow(2.0, (int)trans->size);
               }
            }

            //This could be the
            max_bytes = (max_length * max_beat_bytes);

            unsigned long long waddress;

            //Determine a number of extra bytes that are required to pack out to the maximum beat size (based on alignment)
            extra_bytes = trans->address % max_beat_bytes;

            if (DEBUG_MSG) { cout << "bytes " << bytes << " extra_bytes " << extra_bytes << " max_bytes " << max_bytes  << endl; }
            while ((bytes + extra_bytes) > max_bytes) {

                //Clear the exclusive flags
                if (trans->locked == axi_excl) {
                   trans->locked = nolock;
                }

                //If this is an unlocking transaction make these extra transactions locked
                if (unlocking_trans) {
                   trans->locked = lock;
                   trans->unlocking = false;
                }

                //Send out a maximum size INCR
                if (DEBUG_MSG) { cout << "Send out a maximum size INCR"  << endl; }
                trans->burst = axi_incr;
                waddress = trans->address - (trans->address % max_beat_bytes);

                trans->length = max_length;
                while (waddress < (trans->address - (trans->address % max_beat_bytes))) {
                   trans->length--;
                   waddress += max_beat_bytes;
                }
                trans->size = (amba_size)log2(max_beat_bytes);

                if (DEBUG_MSG) { cout << "process.push_back"  << endl; }
                process.push_back(*trans);

                //Subtract bytes
                bytes -= ((trans->length*max_beat_bytes) - (trans->address % max_beat_bytes));
                extra_bytes = 0;

                //Allign and incrment the address for the next transaction
                trans->address += ((trans->length*max_beat_bytes) - (trans->address % max_beat_bytes));

            };

            //If unlocking transaction and locked set to unlock
            if (unlocking_trans) {

                 //If this is the the last transaction then unlock it if locked and set unlocking
                 if ((max_transactions == 1) || ((trans_no + 1) == max_transactions)) {

                      if (trans->locked == lock) {
                           trans->locked = nolock;
                      }

                      trans->unlocking = true;
                 } else {

                      //lock the transaction
                      trans->locked = lock;
                 }
            };

            //Quit if nothing to do
            if (bytes == 0) {
                  if (DEBUG_MSG) { cout << "nothing more to do"  << endl; }
                  continue;
            }

            //IF the number of bytes is more than 2 times the master size
            //the size must be the master size
            if (bytes > (max_beat_bytes * 2)) {

                  //set size = size of the master bus
                  size = max_beat_bytes;

            } else {

                  //Determine the number of bytes to the boundary of the wider bus
                  //(depends on address and master_bus size)
                  bytes_to_boundary = (max_beat_bytes) -
                                    trans->address % (max_beat_bytes);

                  //Check that there aren't more bytes here than in the transaction
                  if (bytes > bytes_to_boundary) {
                        bytes_after_boundary = bytes - bytes_to_boundary;
                  } else {
                        bytes_to_boundary = bytes;
                        bytes_after_boundary = 0;
                  }

                  //Limit bytes_after boundary to the size of the master bus
                  if (bytes_after_boundary > (max_beat_bytes)) {
                        bytes_after_boundary = max_beat_bytes;
                  }

                  //Select the largest of bytes before boundary vs. bytes after to select size
                  if (bytes_to_boundary > bytes_after_boundary) {
                       bytes_max = bytes_to_boundary;
                  } else {
                       bytes_max = bytes_after_boundary;
                  }

                  //Finally decide the size depending on the bytes_max
                  size = 1;
                  while (size < bytes_max) { size = size * 2; }

            }

            //Now that the size has been determined work on the length
            length = (int)(bytes / size);

            //Sort out rounding errors
            if ((size * length) < bytes) {
                length++;
            }

            //The size and length calculated so far are correct for basic alligned wraps.
            //But still need to take account of Incrs that cross boundaries because they're unalligned

            if (trans->burst == axi_incr) {

               int Final_address;
               int max_byte;

               //Calculate the maximum byte number to add
               max_byte = bytes - 1;

               //Determine the final address
               Final_address = (trans->address % max_beat_bytes) + (max_byte % max_beat_bytes);

               //If the address has crossed a boundary add one to the length
               if ((Final_address - (Final_address % (max_beat_bytes))) >= (max_beat_bytes)) {

                    //If size is not the full size limit to 2 otherwise add one
                    if (size == (max_beat_bytes)) {
                        length++;
                    } else {
                        length = 2;
                    }
               }

               //Special case for subwidth transfers where the address allignment means the data doesn't actually fit
               if (length == 1 && size != 0 && size < max_beat_bytes) {
                       while (((signed)size < (signed)(bytes + (trans->address % size)))) {
                               size = size * 2;
                       }
               }

           }

           //Encode length and size and set
           trans->length = length;

           trans->size = (amba_size)log2(size);
           if ((int)pow(2.0, (int)trans->size) != size) {
              trans->size = (amba_size)(trans->size + 1);
           }

           //If this is an exclusive transaction and the length > 16 delete it
           if (trans->locked == axi_excl && trans->length > 16) {
                 trans->locked = nolock;
           }

           if (DEBUG_MSG) { cout << "process.push_back"  << endl; }
           process.push_back(*trans);

        }
        if (DEBUG_MSG) { cout << "------------------"  << endl; }
        if (DEBUG_MSG) { cout << "finished setting up the transactions"  << endl; }
        if (DEBUG_MSG) { cout << "------------------"  << endl; }

        //First determine any packing necessary for the first beat
        //Size is now the target size

        string data = "";
        string mask = "";
        string strobe = "";
        string bnumber = "";
        string parity = "";
        string parity_validity = "";

        //determine the alligned base address of the new size
        //There is data from address alligned ...
        input_offset = Address - Address_alligned;
        output_offset = process[0].address % (int)pow(2.0, (int)process[0].size);
        NewAddress = process[0].address - output_offset;
        pack_bytes = Address_alligned - NewAddress;

        if (DEBUG_MSG) { cout << "(1)pack_bytes = " << pack_bytes  << endl; }
        //If NewAddress < Address_alligned pack data
        if (NewAddress < Address_alligned) {
            if (DEBUG_MSG) { cout << "NewAddress < Address_alligned pack data"  << endl; }

            int i = pack_bytes;

            while (i > 0) {
                data = data + "00";
                mask = mask + "00";
                strobe = strobe + "0";
                parity = parity + "1";
                if (dummy_bnum >= 65535) {
                   throw "Run out of byte numbers in Model_size_dpe (1)";
                }
                ostringstream data_str;
                data_str << "0000" << hex << ++dummy_bnum;
                string bnum = data_str.str();
                bnumber = "b" + bnum.substr(bnum.size()-4,4) + bnumber;
                usersignals.insert(usersignals.begin(),string(USER_MAX_WIDTH,'0'));
                responses.insert(responses.begin(),axi_exokay);
                //decrement counter
                i--;
            }
        }

        //Remove extra packing data
        if (DEBUG_MSG) { cout << "Remove extra packing data"  << endl; }
        while (pack_bytes < 0)
        {
              all_data.erase(all_data.size()-2);
              all_mask.erase(all_mask.size()-2);
              all_bnumber.erase(all_bnumber.size()-5);
              all_strobe.erase(all_strobe.size()-1);
              all_parity.erase(all_parity.size()-1);
              all_parity_validity.erase(all_parity_validity.size()-1);
              responses.pop_back();
              usersignals.pop_back();
              pack_bytes++;
        }

        if (DEBUG_MSG) { cout << "(2)pack_bytes = " << pack_bytes  << endl; }
        //Set the write responses
        //if write_resp = okay ... then all ok ... otherwise randomise
        bool set = false;
        int randno;
        if (trans->direction == wr) {

           for (deque<transaction>::iterator trans_ptr = process.begin(); trans_ptr != process.end(); trans_ptr++) {

              if (write_response == axi_slverr) {
                  randno = rand() % 2;
              } else if (write_response == axi_decerr) {
                  randno = rand() % 3;
              } else {
                  randno = 0;
              }

              if (randno == 1) {
                  trans_ptr->resp[0] = axi_slverr;
                  set = set | (write_response == axi_slverr);
              } else if (randno == 2) {
                  trans_ptr->resp[0] = axi_decerr;
                  set = set | (write_response == axi_decerr);
              } else {
                  trans_ptr->resp[0] = okay;
                  set = set | (write_response == okay);
              }
           };
        }

        //Check that at leat one of the options got the required value
        if (set == false) {
           process.begin()->resp[0] = write_response;
        }

        int last_bnum;
        string bnum;

        if (DEBUG_MSG) { cout << "DEBUG 14-2"  << endl; }
        if (DEBUG_MSG) { cout << "-----------"  << endl; }
        if (DEBUG_MSG) { cout << "all_data            |" << all_data             << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_mask            |" << all_mask             << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_strobe          |" << all_strobe           << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_bnumber         |" << all_bnumber          << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_parity          |" << all_parity           << "|"  << endl; }
        if (DEBUG_MSG) { cout << "all_parity_validity |" << all_parity_validity  << "|"  << endl; }
        while (process.empty() == false) {
           //Pop the item from the input queue
           process_trans = process.front();
           process.pop_front();
           if (DEBUG_MSG) { cout << "Process_trans.length is: " <<  int(process_trans.length)  << endl; }

           //For each beat in the new_transaction
           for (new_beat = 0; new_beat < process_trans.length; new_beat++) {

                bytes = (int)pow(2.0, (int)process_trans.size);

                //Set the default response to ex_okay
                if (trans->direction == rd) {
                    process_trans.resp[new_beat] = axi_exokay;
                }

                if (pack_bytes >= bytes) { throw "Unexpected packing error\n"; }

                for (int byte_no = pack_bytes; byte_no < bytes; byte_no++) {

                    if (all_data.size() != 0)
                    {
                         if (process_trans.direction == wr)
                         {
                             if (all_strobe[all_strobe.size()-1] == '1')
                             {
                                 data.insert(0,all_data.substr(all_data.size()-2,2));
                                 parity.insert(0,all_parity.substr(all_parity.size()-1,1));
                             }
                             else
                             {
                                 data.insert(0,"00");
                                 parity.insert(0,"1");
                             }
                         }
                         else
                         {
                             data.insert(0,all_data.substr(all_data.size()-2,2));
                             parity.insert(0,all_parity.substr(all_parity.size()-1,1));
                         }
                         all_data.erase(all_data.size()-2,2);
                         all_parity.erase(all_parity.size()-1,1);

                         parity_validity.insert(0,all_parity_validity.substr(all_parity_validity.size()-1,1));
                         all_parity_validity.erase(all_parity_validity.size()-1,1);
                         if (DEBUG_MSG) { cout << "parity_validity |"  << parity_validity << "| all_parity_validity |"  << all_parity_validity << "|" << endl; }

                         if (process_trans.direction == rd and all_mask.size() > 0) {
                             mask.insert(0,all_mask.substr(all_mask.size()-2,2));
                             all_mask.erase(all_mask.size()-2,2);
                         }

                         bnumber.insert(0,all_bnumber.substr(all_bnumber.size()-5,5));
                         bnum = "0x" + all_bnumber.substr(all_bnumber.size()-4,4);
                         last_bnum = (int)strtoul(bnum.c_str(), NULL, 0);
                         all_bnumber.erase(all_bnumber.size()-5,5);

                         if (process_trans.direction == wr) {
                              strobe.insert(0,all_strobe.substr(all_strobe.size()-1,1));
                             all_strobe.erase(all_strobe.size()-1,1);
                         }

                         if (trans->direction == rd) {
                             //If response = axi_exokay
                             if (responses.back() == okay && process_trans.resp[new_beat] == axi_exokay) {
                                 process_trans.resp[new_beat] = okay;
                             } else if (responses.back() == axi_decerr) {
                                 process_trans.resp[new_beat] = axi_decerr;
                             } else if (responses.back() == axi_slverr && process_trans.resp[new_beat] != axi_decerr) {
                                 process_trans.resp[new_beat] = axi_slverr;
                             }
                         }

                         //set the user signals
                         process_trans.user[new_beat] = usersignals.back();

                         responses.pop_back();
                         usersignals.pop_back();

                    } else {
                         data = "00" + data;
                         mask = "00" + mask;
                         strobe = "0" + strobe;
                         parity = "1" + parity;
                         if (dummy_bnum >= 65535) {
                             throw "Run out of byte numbers in Model_size_dpe (2)";
                         }
                         ostringstream data_str;
                         data_str << "0000" << hex << ++dummy_bnum;
                         string bnum = data_str.str();
                         bnumber = "b" + bnum.substr(bnum.size()-4,4) + bnumber;
                    }
                }

                if (DEBUG_MSG) { cout << "-----------------------------------------------------"  << endl; }
                if (DEBUG_MSG) { cout << "data                |" << data            << "|"  << endl; }
                if (DEBUG_MSG) { cout << "strobe              |" << strobe          << "|"  << endl; }
                if (DEBUG_MSG) { cout << "parity              |" << parity          << "|"  << endl; }
                if (DEBUG_MSG) { cout << "mask                |" << mask            << "|"  << endl; }
                if (DEBUG_MSG) { cout << "bnumber             |" << bnumber         << "|"  << endl; }
                if (DEBUG_MSG) { cout << "parity_validity     |" << parity_validity << "|"  << endl; }

                //Copy values into transaction
                process_trans.data[new_beat] = data;
                process_trans.mask[new_beat] = mask;
                process_trans.strobe[new_beat] = strobe;
                process_trans.bnumber[new_beat] = bnumber;
                process_trans.parity[new_beat] = parity;

                // set beat parity_validity true only if all bytes had parity_validity true
                process_trans.parity_validity[new_beat] = (parity_validity.find('0') == string::npos);
                if (DEBUG_MSG) { cout << "parity_validity[" << new_beat << "] " << ((process_trans.parity_validity[new_beat])? "1" : "0") << endl; }

                //Read responses
                if (trans->direction == rd) {
                    set_response_trans(orginal_trans, bnumber, process_trans.resp[new_beat], process_trans.user[new_beat]);
                }

                //Write repsonses ... if not beat zero and response is ok clear beat
                if (trans->direction == wr && (new_beat != 0) && process_trans.resp[0] == okay) {
                    process_trans.resp[new_beat] = okay;
                };

                //Resp ... if resp is ex_okay and not exclusive make okay
                if (process_trans.resp[new_beat] == axi_exokay && (process_trans.locked != axi_excl)) {
                    process_trans.resp[new_beat] = okay;
                };

                //reset counters and strings
                pack_bytes=0;
                data = "";
                mask = "";
                strobe = "";
                bnumber = "";
                parity = "";
                parity_validity = "";
           }
           if (DEBUG_MSG) { cout << "-----------------------------------------------------"  << endl; }

           // no read parity in APB AMIB
	   if (param_s("amib") == "true" && param_s("amib_protocol").substr(0,3) == "apb")
	   {
               if (DEBUG_MSG) { cout << "no read parity in APB AMIB"  << endl; }
	   }
	   else
	   {
              process_trans.insert_parity(master_if_data_width/8);
	   }

           //if write then set parity to 1 for strobed out data bytes and 0 for out of data bus bytes
           if (process_trans.direction == wr)
           {
               for (int b=0; b<process_trans.length; b++)
               {
                   arm_uint32 strobe = process_trans.bus_strobe(master_if_data_width/8, b);
                   arm_uint64 bus_mask = 1;
                   bus_mask = (bus_mask << master_data_bytes ) - 1;
                   process_trans.data_parity[b] = process_trans.data_parity[b] & bus_mask;
               }
               process_trans.insert_data_parity();
           }

           output->push_back(process_trans);

       }


       if (all_data.size() != 0) {

               if (DEBUG_MSG) { cout << "remaining data is " << all_data.size()  << endl; }
               throw "Unexpected remaining data";

       };
    }

    return "";

    } catch (const char * error) {

        if (DEBUG_MSG) { cout << "Caught: size convertion failed with message : " << error  << endl; }
        exit(1);
    }

}

// Need to model 2 behaviours:
// 1) XVC Slave fills unused bits of data bus with 0s
// 2) IB fills unused parts of data bus with copies
// For example, in ib_dpe_test004 the sif is 128 bits wide and the mif is 32 bits.
// So a 16-bit transfer starts off at the mif like this:
//   0x0000nnnn (or 0xnnnn0000 depending on alignment)
// and reaches the sif like this:
//   0x0000nnnn0000nnnn0000nnnn0000nnnn
//
void Model_size_dpe::Return(deque<transaction> * input, deque<transaction> * output) {

    try {

       if (DEBUG_MSG) { cout << "Return() Input trans (" << input->size() << ") is " << input->front()  << endl; } 

       //Relying on the XML parameter will highlight errors in the XML
       check_rev_user(&stored_trans);

       if (stored_trans[0].address == 0x6482270d) {

             if (DEBUG_MSG) { cout << "Name is " << param_s("name")  << endl; }

             for (unsigned int itrans = 0; itrans < input->size(); itrans++) {
                     if (DEBUG_MSG) { cout << "Input transaction " << itrans  << endl; }
                     for (int beat = 0; beat < input->at(itrans).length; beat++) {
                        if (DEBUG_MSG) { cout << "i beat " << beat << " resp " << input->at(itrans).resp[beat] << " bnumber " << input->at(itrans).bnumber[beat]  << endl; }
                     }

             };
       };

       //Go though all the transactions in the stored queue
       for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {

            //Reset the responses to okay (all beats for reads only beat 0 for writes)
            for (int beat = 0; beat < stored_trans[strans].length; beat++) {
                 if ( stored_trans[strans].direction == frbm_namespace::read || beat == 0) {
                     stored_trans[strans].resp[beat] = axi_exokay;
                 }
            }
       }

       //Now go through all the incoming transactions
       //Look at the reponses and if it's an error set the response for the corresponing
       //stored transaction to axi_slverr
       //Copy in the ruser response
       if (DEBUG_MSG) { cout << "set responses"  << endl; }
       for (unsigned int itrans = 0; itrans < input->size(); itrans++)
       {

           if (DEBUG_MSG) { cout << "  transaction " << itrans  << endl; }
           //If it's a write the resp[0] applies to the whole transaction
           if ((input->at(itrans)).direction == frbm_namespace::write)
           {
               //Set the response on the following bytes
               for (int beat = 0; beat < input->at(itrans).length; beat++)
               {
                    if (DEBUG_MSG) { cout << "    beat " << beat  << endl; }
                    set_response(&stored_trans, input->at(itrans).bnumber[beat], input->at(itrans).resp[0], 1, input->at(itrans).user[beat]);
               }
           }
           else
           {
               //Go through each beat
               for (int beat = 0; beat < input->at(itrans).length; beat++)
               {
                    if (DEBUG_MSG) { cout << "    beat " << beat  << endl; }
                    set_response(&stored_trans, input->at(itrans).bnumber[beat], input->at(itrans).resp[beat], 1, input->at(itrans).user[beat]);
               }
           }
       }

        // extract data_parity and parity_validity from ruser
        for (int transno = 0; transno < stored_trans.size(); transno++)
        {
            if ((stored_trans.at(transno)).direction == frbm_namespace::read)
            {
                (stored_trans.at(transno)).extract_parity();
            }
        }

       if (DEBUG_MSG) { cout << "after set_response() stored_trans is " << stored_trans.front()  << endl; } 

        // downsizer
        if (slave_data_bytes > master_data_bytes)
        {
            // clear down read parity from forward model run
            for (int transno = 0; transno < stored_trans.size(); transno++)
            {
                if ((stored_trans.at(transno)).direction == frbm_namespace::read)
                {
                    for (int b = 0; b < stored_trans.at(transno).length; b++)
                    {
                        stored_trans.at(transno).data_parity[b] = 0xffffffff;
//                        stored_trans.at(transno).data_parity[b] = 0;
                        stored_trans.at(transno).parity_validity[b] = true;
                    }
                }
            }

            if (DEBUG_MSG) { cout << "set read parity"  << endl; }
            vector<bool> sif_parity_validity(slave_data_bytes/master_data_bytes, true);
            int sif_beat = -1;
            for (unsigned int itrans = 0; itrans < input->size(); itrans++)
            {
                if (DEBUG_MSG) { cout << "transaction " << itrans  << endl; }
                // only for reads 
                if ((input->at(itrans)).direction == frbm_namespace::read)
                {
                    // set up the internal parity representations from ruser
                    input->at(itrans).extract_parity();

                    //Set the parity on the following bytes
                    for (int beat = 0; beat < input->at(itrans).length; beat++)
                    {
                         if (DEBUG_MSG) { cout << "beat " << beat  << endl; }
                         transaction *input_trans = &(input->at(itrans));
                         set_beat_parity(&stored_trans, input_trans, beat, sif_parity_validity, sif_beat);
                         if (DEBUG_MSG) { cout << "sif_parity_validity"; }
                         for (int i=0; i < sif_parity_validity.size(); i++)
                         {
                             if (DEBUG_MSG) { cout << " " << (sif_parity_validity[i]?"1":"0"); }
                         }
                         if (DEBUG_MSG) { cout << endl; }
                    }
                }
            }
        }

        if (DEBUG_MSG) { cout << "model return transformation of parity bits for reads" << endl; }
        for (int transno = 0; transno < stored_trans.size(); transno++)
        {
            if ((stored_trans.at(transno)).direction == frbm_namespace::read)
            {
                arm_uint32 parity_reg = 0xffffffff;

                for (int b = 0; b < stored_trans.at(transno).length; b++)
                {
                    if (DEBUG_MSG) { cout << "beat " << b  << endl; }
                    if (DEBUG_MSG) { cout << "original           data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b] << dec  << endl; }

                    if (slave_data_bytes > master_data_bytes)
                    {
                        int size       = (1 << stored_trans.at(transno).size);
                        int copy_size  = (size < master_data_bytes) ? master_data_bytes : size;
                        int num_copies = slave_data_bytes/copy_size;
                        int copy_step  = slave_data_bytes/num_copies;

                        if (num_copies > 1)
                        {
                            // parity for this beat is made up from:
                            //   parity_reg
                            // + parity from input (already in stored_trans.at(transno).data_parity[b][sif_ubl:sif_lbl]
                            // + replicated most significant master_data_bytes parity from input (stored_trans.at(transno).data_parity[b][sif_ubl:sif_ubl-master_data_bytes+1]

                            int sif_lbl = (stored_trans.at(transno)).lower_byte_lane(slave_data_bytes, b+1);
                            int sif_ubl = (stored_trans.at(transno)).upper_byte_lane(slave_data_bytes, b+1);

                            int lower_mif_lane = sif_lbl/master_data_bytes;
                            int upper_mif_lane = sif_ubl/master_data_bytes;

                            int sif_pos = lower_mif_lane*master_data_bytes;
                            int copy_pos = upper_mif_lane*master_data_bytes;

                            arm_uint32 input_mask = 1;
                            input_mask = (input_mask << ((upper_mif_lane-lower_mif_lane+1)*master_data_bytes)) - 1;
                            input_mask = input_mask << sif_pos;

                            if (DEBUG_MSG) { cout << "lower_mif_lane " << lower_mif_lane << " upper_mif_lane " << upper_mif_lane << hex << " input_mask 0x" << input_mask << dec << endl; }

                            arm_uint32 mask = 1;
                            mask = (mask << master_data_bytes) - 1;
                            mask = mask << copy_pos;

                            // extract mif slice to copy
                            arm_uint32 parity_to_copy = (stored_trans.at(transno).data_parity[b] & mask);

                            // position mask and parity_to_copy ready for copying
                            if (size <= master_data_bytes)
                            {
                                mask = mask >> copy_pos;
                                parity_to_copy = parity_to_copy >> copy_pos;
                            }
                            else
                            {
                                int start_pos = copy_pos;
                                while (start_pos > copy_step)
                                {
                                    mask = mask >> copy_step;
                                    parity_to_copy = parity_to_copy >> copy_step;
                                    start_pos = start_pos - copy_step;
                                }
                            }

                            if (DEBUG_MSG) { cout << "num_copies " << num_copies << " copy_pos " << copy_pos << " copy_size " << copy_size << " copy_step " << copy_step << hex << " parity_to_copy 0x" << parity_to_copy << " mask 0x" << mask << dec << endl; }

                            // read sizing registers, data and parity, are now cleared on upstream handshake - parity_reg no longer used
                            stored_trans.at(transno).data_parity[b] = stored_trans.at(transno).data_parity[b] | ~input_mask;
                            if (DEBUG_MSG) { cout << "before replication data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b] << dec  << endl; }
                            for (int i=0; i<num_copies; i++)
                            {
                                stored_trans.at(transno).data_parity[b] = (stored_trans.at(transno).data_parity[b] & ~mask) | parity_to_copy;
                                parity_to_copy = parity_to_copy << copy_step;
                                mask = mask << copy_step;
                            }
                            if (DEBUG_MSG) { cout << "after replication  data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b] << dec  << endl; }
                        }

                        parity_reg = stored_trans.at(transno).data_parity[b];
                    }
                    else
                    {
                        // not downsizing so just align parity with data position in slave interface data bus
                        int sif_lbl = (stored_trans.at(transno)).lower_byte_lane(slave_data_bytes, b+1);
                        int mif_lbl = (stored_trans.at(transno)).lower_byte_lane(master_data_bytes, b+1);
                        if (DEBUG_MSG) { cout << "align b " << b  << " sif_lbl " << sif_lbl << " mif_lbl " << mif_lbl << endl; }

                        if (mif_lbl < sif_lbl)
                        {
                            stored_trans.at(transno).data_parity[b] = stored_trans.at(transno).data_parity[b] << (sif_lbl - mif_lbl);
                        }
                        else
                        {
                            stored_trans.at(transno).data_parity[b] = stored_trans.at(transno).data_parity[b] >> (mif_lbl - sif_lbl);
                        }
                        if (DEBUG_MSG) { cout << "after shift       data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b] << dec  << endl; }
                    }

                    // set parity bits for unused byte lanes if upsizing
                    if (master_data_bytes > slave_data_bytes)
                    {
                        int size    = (1 << stored_trans.at(transno).size);
                        int sif_lbl = (stored_trans.at(transno)).lower_byte_lane(slave_data_bytes, b+1);
                        int sif_ubl = (stored_trans.at(transno)).upper_byte_lane(slave_data_bytes, b+1);

                        // align sif_lbl for first beat
                        sif_lbl = sif_lbl/size * size;

                        arm_uint64 lbl_mask = 1;
                        lbl_mask = (lbl_mask << sif_lbl) - 1;

                        arm_uint64 ubl_mask = 1;
                        ubl_mask = (ubl_mask << (sif_ubl+1)) - 1;

                        arm_uint64 bus_mask = 1;
                        bus_mask = (bus_mask << slave_data_bytes ) - 1;

                        arm_uint64 unused_parity;
                        unused_parity = bus_mask & ~ubl_mask | lbl_mask;

                        (stored_trans.at(transno)).data_parity[b] = ((stored_trans.at(transno)).data_parity[b]) | unused_parity;
                        if (DEBUG_MSG) { cout << "after unused_parity data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b]  << " unused_parity 0x" << unused_parity << dec  << " sif_lbl " << sif_lbl << " sif_ubl " << sif_ubl << endl; }
                    }

                    // clear out-of-interface parity bits for reads
                    arm_uint64 bus_mask = 1;
                    bus_mask = (bus_mask << slave_data_bytes ) - 1;
                    (stored_trans.at(transno)).data_parity[b] = ((stored_trans.at(transno)).data_parity[b]) & bus_mask;
                    if (DEBUG_MSG) { cout << "after bus_mask    data_parity[" << b << "] = 0x" << hex << stored_trans.at(transno).data_parity[b]  << " bus_mask 0x" << bus_mask << dec  << endl; }
                }
           }
        }

        // no read parity in APB AMIB
	if (param_s("amib") == "true" && param_s("amib_protocol").substr(0,3) == "apb")
	{
            if (DEBUG_MSG) { cout << "no read parity in APB AMIB"  << endl; }
	}
	else
	{
            // insert data_parity and parity_validity back into ruser
            for (int transno = 0; transno < stored_trans.size(); transno++)
            {
        	if ((stored_trans.at(transno)).direction == frbm_namespace::read)
        	{
                    (stored_trans.at(transno)).insert_data_parity();
        	}
            }
	}

       if (stored_trans[0].address == 0x6482270d) {


         //Go though all the transactions in the stored queue
         for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {

            //Reset the responses to okay (all beats for reads only beat 0 for writes)
            for (int beat = 0; beat < stored_trans[strans].length; beat++) {
                if (DEBUG_MSG) { cout << "s beat " << beat << " resp " << stored_trans[strans].resp[beat] << " bnumber " << stored_trans[strans].bnumber[beat]  << endl; }
            }
         }
       };

       //Having modifed the transactions in the stored_trans list
       input->clear();
       *output = stored_trans;

       if (DEBUG_MSG) { cout << "Return() Output trans (" << output->size() << ") is " << output->front()  << endl; } 

    } catch (const char * error) {

            if (DEBUG_MSG) { cout << "Caught: Size convertion (Return) failed with message : " << error  << endl; }
            exit(1);
    }

}

void Model_size_dpe::set_beat_parity(deque<transaction> * strans, transaction *input_trans, int beat, vector<bool> &sif_parity_validity, int &sif_beat)
{
    string      bnumbers             = input_trans->bnumber[beat];
    string      beat_data            = input_trans->data[beat];
    amba_parity beat_parity          = input_trans->data_parity[beat];
    bool        beat_parity_validity = input_trans->parity_validity[beat];
    int         beat_lbl             = input_trans->lower_byte_lane(master_data_bytes, beat+1);
    int         beat_size            = (1 << input_trans->size);

    if (DEBUG_MSG) { cout << "\nset_beat_parity " << bnumbers << " beat " << beat << " beat_lbl " << beat_lbl << " beat_data = 0x" << hex << beat_data << " beat_parity = 0x" << hex << beat_parity << " " <<( (beat_parity_validity) ? "1" : "0") << dec << " sif_beat " << sif_beat << endl; }
    if (DEBUG_MSG)
    {
        cout << "sif_parity_validity";
        for(int i=0; i<sif_parity_validity.size(); i++) { cout << " " << (sif_parity_validity[i] ? "1" : "0"); }
        cout << endl;
    }

    unsigned int transno = 0;
    bool complete = false;
    string bcode;

    // go through every byte in input_trans[beat]
    while (bnumbers.length() >= 5)
    {

        //Get the byte code
        bcode = bnumbers.substr(0,5);
        bnumbers = bnumbers.substr(5);

        if (bcode.at(0) != 'b') { throw "Unexpected byte code format " + bcode; };

        complete = false;
        // find the byte in one of the transactions in the strans list (i.e. the originating transaction)
        for (transno = 0; transno < strans->size(); transno++)
        {
            int strans_size = (1 << (strans->at(transno)).size);
            if (DEBUG_MSG) { cout << "bcode " << bcode << " transno " << transno  << " strans_size " << strans_size << endl; }

            //Try to find the byte code in the orginal transaction
            for (int len = 0; len < strans->at(transno).length; len++)
            {
                size_t found = (strans->at(transno)).bnumber[len].find(bcode);

                // guard against unaligned matches
                // - bnumber format bxxxx is ambiguous because x can be 'b'
                while ((found != string::npos) && (found%5 != 0))
                {
                    found = (strans->at(transno)).bnumber[len].find(bcode, found+1);
                }

                if (found != string::npos)
                {
                    // detect start of new sif_beat
                    if(len != sif_beat)
                    {
                        sif_beat = len;

                        // parity validity is now cleared after each sif beat
                        for(int i=0; i<sif_parity_validity.size(); i++) {sif_parity_validity[i] = true; }
                    }
                    if (DEBUG_MSG) { cout << "found at beat " << len << "." << (found/5) << " beat_size " << beat_size << hex << " data = 0x" << (strans->at(transno)).data[len]
                                          << " data_parity = 0x" << (strans->at(transno)).data_parity[len]
                                          << " " <<( ((strans->at(transno)).parity_validity[len]) ? "1" : "0") << dec << endl; }
                    // found the corresponding beat in strans
                    // now copy the parity for master_data_bytes into the correct position in the wider slave_data_bytes

                    arm_uint64 mask = 1;
                    mask = (mask << master_data_bytes) - 1;

                    int sif_lbl = (strans->at(transno)).lower_byte_lane(slave_data_bytes, len+1);
                    int sif_ubl = (strans->at(transno)).upper_byte_lane(slave_data_bytes, len+1);
                    int sif_size = sif_ubl - sif_lbl + 1;
                    int byte_pos = ((strans->at(transno)).bnumber[len].length()-found)/5 - 1;
                    int pos = (sif_lbl/strans_size*strans_size + byte_pos)/master_data_bytes*master_data_bytes;

                    arm_uint32 masked_parity = beat_parity & mask;

                    if (DEBUG_MSG) { cout << "input beat " << beat << " sif_lbl " << sif_lbl << " sif_ubl " << sif_ubl << " sif_size " << sif_size
                                          << " byte_pos " << byte_pos << " pos " << pos << " mask " << hex << mask << " masked_parity " << masked_parity << dec << endl; }

                    (strans->at(transno)).data_parity[len] = ((strans->at(transno)).data_parity[len] & ~(mask << pos)) | masked_parity << pos;

                    int strans_size = (1 << (strans->at(transno)).size);
                    // don't store last beat of downstream beats
                    // last beat when pos is in most significant beat of strans_size
                    int num_beats_in_strans =  strans_size/master_data_bytes ? strans_size/master_data_bytes : 1;
                    int pos_in_strans = pos/master_data_bytes%num_beats_in_strans;
                    if (DEBUG_MSG) { cout << "pos " << pos << " beat_size " << beat_size << " strans_size " << strans_size << " pos_in_strans " << pos_in_strans << " num_beats_in_strans " << num_beats_in_strans << endl; }
                    if (pos_in_strans < (num_beats_in_strans - 1))
                    {
                        // store earlier beats
                        if (DEBUG_MSG) { cout << "store earlier beats" << endl; }
                        sif_parity_validity.at(pos/master_data_bytes) = beat_parity_validity;
                    }
                    else
                    {
                        // last downbeat - form overall parity validity across all beats
                        if (DEBUG_MSG) { cout << "last downbeat" << endl; }

                        (strans->at(transno)).parity_validity[len] = beat_parity_validity;

                        // combine with parity_validity from earlier beats
                        for (int i=0; i < sif_parity_validity.size(); i++)
                        {
                            // don't use stored validity for this beats position
                            if (i != pos/master_data_bytes)
                            {
                                (strans->at(transno)).parity_validity[len] = (strans->at(transno)).parity_validity[len] && sif_parity_validity[i];
                            }
                        }
                    }
                    if (DEBUG_MSG)
                    {
                        cout << "sif_parity_validity";
                        for(int i=0; i<sif_parity_validity.size(); i++) { cout << " " << (sif_parity_validity[i] ? "1" : "0"); }
                        cout << endl;
                    }

                    if (DEBUG_MSG) { cout << "strans[" << transno << "].data_parity[" << len << "] = 0x" << hex << (strans->at(transno)).data_parity[len] << dec << " " <<( ((strans->at(transno)).parity_validity[len]) ? "1" : "0") << endl; }
                }
            }
        }
    }
}
