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
// Checked In          :  2014-05-30 19:24:30 +0100 (Fri, 30 May 2014)
//
// Revision            : 173985
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


#include "../include/Model.h"
#include <iostream>
#include <iterator>     // std::ostream_iterator
#include <algorithm>    // std::copy
#define DEBUG_MSG 0

string Model_size::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {
    bool bypass = false;
    bool merge = true;
    int bytes;
    int beatbytes;
    int length;
    int size;
    int wrap_offset;
    int master_if_data_width;
    protocol_t        master_if_protocol;
    protocol_t        slave_if_protocol;
    int slave_if_data_width;
    int master_data_bits;
    int slave_data_bits;
    int master_data_bytes;
    int slave_data_bytes;
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
//    string all_parity;  // DK
    int dummy_bnum = 0;
    bool unlocking_trans = false;
    string bnumbers;
    string bcode;
    //initialise number of transactions - static guarantees this happens only once
    int static trans_number = 0;

    if (DEBUG_MSG) {
      std::cout << "**********Starting Model_size.cpp...**********" << std::endl;
    }
    try {
      trans_number++;
      if (DEBUG_MSG) {
      cout << "Total number of transactions is: " << trans_number << endl;
      }
      // This model creates multiple transactions and manipulates responsnes
      // so it needs to keep a copy of all the transactions it works on
      stored_trans = *input;

      if (DEBUG_MSG) {
        std::cout << "stored_trans.size(): " << stored_trans.size() << std::endl;  //should give 1
      }
      // Searching for the highest bnumber from the available transactions to give starting point for dummy beats
      for (unsigned int itrans = 0; itrans < stored_trans.size(); itrans++) {
        for (int beat = 0; beat < stored_trans[itrans].length; beat++) {

          bnumbers = stored_trans[itrans].bnumber[beat];
          //cout << "$$$$$$$$Stored transactions stored_trans[itrans]:" << stored_trans[itrans] << endl;

          while (bnumbers.length() >= 5) {
            // Get the byte code
            bcode = bnumbers.substr(0,5);
            bnumbers = bnumbers.substr(5);

            string btmp = "0x" + bcode.substr(1,4);
            int bint = (int)strtoul(btmp.c_str(), NULL, 0);
            if (dummy_bnum < bint)
              dummy_bnum = bint;
          }
        }
      }

      // In cases that we have a transaction at the input, we will have to make 
      // a number of transformations according to data width, protocol etc
      while (input->empty() == false) {
        if (DEBUG_MSG) {
          std::cout << "input not empty: proceeding in loop.." << std::endl;
        }
        // local variables with loop scope with default values
        int max_length       = 16;

        // Pop the item from the input queue and store it in variable 'trans'
        front_trans = input->front();
        input->pop_front();
        trans = &front_trans;
        // if (DEBUG_MSG) {
          // cout << "Transaction is: " << *trans << endl;
        // }
        /*
        std::cout << "Will now attempt to display user signalsNEW: \n" << std::endl;
        std::ostream_iterator<string> out_it (std::cout, "\n");
        std::copy(usersignals.begin(), usersignals.end(), out_it);
        std::cout << "Will now attempt to display response signals: \n" << std::endl;
        std::ostream_iterator<int> out_it2 (std::cout, " ");
        std::copy(responses.begin(), responses.end(), out_it2);
        */
        if (param_s("lock") == "true") {
          unlocking_trans = trans->unlocking;
        } else {
          unlocking_trans = false;
        };

        //NOTE LENGTH IS NOT ENCODED IN THE TRANSACTION CLASS I.E. LENGTH 1 = 1
        // Check the protcol
        if ((trans->burst != axi_incr) &&
             (trans->burst != axi_wrap) &&
             (trans->burst != axi_fixed)) {
          throw "Illegal protocol arriving in size model\n";
        }
        // Get master and slave protocols
        if(param_s("type") !="reg_ss_dist") {
          if(param_s("master_if_protocol") == "axi") {
            master_if_protocol  = (protocol_t)1;
          } else if (param_s("master_if_protocol") == "axi4") {
            master_if_protocol  = (protocol_t)4;
          } else {  // the ITB case
            if(param_s("slave_if_protocol") == "axi"){
              master_if_protocol   = (protocol_t)1;
            } else {
              master_if_protocol   = (protocol_t)4;
            }
          }
        } else {  //When the model is reg_ss_dist
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
        // Get master and slave data widths
        master_if_data_width = param("master_if_data_width");
        slave_if_data_width = param("slave_if_data_width");

        master_data_bytes = master_if_data_width / 8;
        slave_data_bytes = slave_if_data_width / 8;

        master_data_bits = log2(master_data_bytes);
        slave_data_bits = log2(slave_data_bytes);

        // Update the register block
        reg_update(trans->direction, trans->id, 5, trans->vnet);
        // Set the maximum length of this transaction based on the protocol and register settings
        if (master_if_protocol == axi4) {
          // Default for AXI4 is to not allow long bursts unless the incoming burst is longer than 16
          max_length = 16;

          if (trans->length > 16) {
            max_length = 256;
          }
          // Read the Burst Breaker Register fn_mod_bb
          if (param_s("apb_config") == "true" && (master_data_bytes < slave_data_bytes) && (param_s("master_if_protocol") == "axi4")) {
            string burstbreak_reg = param_s("name") + ".fn_mod_lb";
            if (PL301_reg->read(burstbreak_reg.c_str(), "fn_mod_lb", trans->vnet) == 1) {
              max_length = 256;
            }
          }
        }
        // Calculate the alligned address
        Address_alligned = trans->address - (trans->address % (int)pow(2.0, (int)trans->size));
        Address = trans->address;

        // Calculate bytes in transfer (corrected for allignment)
        bytes = ((trans->length) * (int)pow(2.0, (int)trans->size)) - (trans->address - Address_alligned);
        beatbytes = (int)pow(2.0, (int)trans->size) - (trans->address - Address_alligned);
        // Special case ... if we are downsizing and this is a fixed burst correct size to most appropriate
        if ((trans->burst == axi_fixed) && (master_data_bytes < slave_data_bytes) && (master_data_bytes < (int)pow(2.0, (int)trans->size)) ) {
          if (DEBUG_MSG) {
            std::cout << "***correcting size because we are downsizing***" << std::endl;
          }
          // Find the appropriate size for the outgoing trans
          int lbytes = 1;
          unsigned int fsize = 0;
          while (lbytes < beatbytes) {
            lbytes = lbytes * 2; fsize++; 
          }
          // Remove excess data and information
          int cbytes = ((int)pow(2.0, (int)trans->size));
          while (cbytes > lbytes) {
            for (int beat = 0; beat < trans->length; beat++) {
              front_trans.data[beat] = front_trans.data[beat].substr(0,front_trans.data[beat].size()-2);
              front_trans.mask[beat] = front_trans.mask[beat].substr(0,front_trans.mask[beat].size()-2);
              front_trans.strobe[beat] = front_trans.strobe[beat].substr(0,front_trans.strobe[beat].size()-1);
              front_trans.bnumber[beat] = front_trans.bnumber[beat].substr(0,front_trans.bnumber[beat].size()-5);
//              front_trans.parity[beat] = front_trans.parity[beat].substr(0,front_trans.parity[beat].size()-1);  // DK
            }
             cbytes--;
          }
          // Reset the transaction size
          trans->size = (amba_size)fsize;

          // Correct the Alligned address
          Address_alligned = trans->address - (trans->address % (int)pow(2.0, (int)trans->size));
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
        // Work out if this burst should be broken only i.e. cache[1] is 0 and the burst length is greater than minimum
        merge = true;
        if ((((trans->cache / 2) == (int(trans->cache / 4) * 2)) || bypass_int == 1) && (trans->length > 16)) {
          merge = false;
        }
        //Work out if this transaction is going to be let through i.e. do nothing
        // condtions are:
        //   1) fixed (upsize only)
        //   2) cache[1] = 0 (unless size is too big for output bus) (AxCACHE[1])
        //   3) length = 1 (unless size is too big for output bus)

        bypass = ((bypass_int == 1 && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
            (trans->burst == axi_fixed && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
            (((trans->cache / 2) == (int(trans->cache / 4) * 2)) && (master_data_bytes >= (int)pow(2.0, (int)trans->size))) ||
            ((trans->length == 1) && (master_data_bytes >= (int)pow(2.0, (int)trans->size)))) && (trans->length <= max_length);

        // why isn't that an OR?
        if (bypass & merge == true) {  // & == and
          if (DEBUG_MSG) {
            cout << "----Let trans through without sizing---" << endl;
          }
          //simply push onto output queue and return
          output->push_back(*trans);
          continue;
        } else {
          if (DEBUG_MSG) {
            cout << "Sizing will happen now!" << endl;
          }
        }
        // Calculate the wrap boundary
        wrap_boundary = trans->address - (trans->address % bytes);

        // Record the write response
        write_response = trans->resp[0];

        // If this is a wrap convert which fits into a single beat on the bus ... reorder the bytes
        if ((trans->burst == axi_wrap) && (bytes <= master_data_bytes)) {
          // determine the wrap offset
          wrap_offset = master_data_bytes - ((trans->address % bytes) / (int)pow(2.0, (int)trans->size));
  
          // convert to incr
          trans->burst = axi_incr;
  
          // allign the address to wrap boundary
          trans->address = wrap_boundary;
          // reorder all the data / user fields
          // Note that only the data is re-ordered .. the last USER beats will still be used
          for (int beat = 0; beat < wrap_offset; beat++) {
            if (front_trans.length == 16) {
              front_trans.data.push_back("");
              front_trans.mask.push_back("");
              front_trans.strobe.push_back("");
              front_trans.bnumber.push_back("");
//              front_trans.parity.push_back("");  // DK
            }
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
//            front_trans.parity[front_trans.length] = front_trans.parity[0];  // DK
//            front_trans.parity.erase(front_trans.parity.begin());  // DK
//            if (front_trans.parity.size() < 16) { front_trans.parity.push_back(""); }  // DK
          }
          // Update the recorded addresses
          Address = wrap_boundary;
          Address_alligned = wrap_boundary;
        }
        if (DEBUG_MSG) {
          cout<< "clearing all now" << endl;
        }
        all_data.clear();
        all_mask.clear();
        all_strobe.clear();
        all_bnumber.clear();
//        all_parity.clear();  // DK

        // Special case .... the packing logic later assumes that all data (after an initial offset is valid
        // This is not true for fixed bursts where entire output beats are ignore from the start. These should therefore not be added here
        int ignore_bytes = 0;
        while (Address - Address_alligned - ignore_bytes >= master_data_bytes) {
          ignore_bytes += master_data_bytes;
        }
        responses.clear();
        usersignals.clear();
        // Now append all the data fields together for use later
        for (exist_beat = 0; exist_beat < front_trans.length; exist_beat++) {
          int remove_bytes = 0;

          if (front_trans.burst == axi_fixed && exist_beat != 0) {
            remove_bytes = ignore_bytes;
          }

          int nibbles = (int)(pow(2.0, (int)(trans->size)) * 2);

          if (front_trans.data[exist_beat].substr(0,2) == "0x") {
            front_trans.data[exist_beat] = front_trans.data[exist_beat].substr(2);
          }
          if (front_trans.data[exist_beat].size() < nibbles) {
            front_trans.data[exist_beat].insert(0, '0', nibbles - front_trans.data[exist_beat].size());
          }

          all_data.insert(0,front_trans.data[exist_beat].substr(0,front_trans.data[exist_beat].size()-(remove_bytes*2)));

          if (front_trans.mask[exist_beat].substr(0,2) == "0x") {
            front_trans.mask[exist_beat] = front_trans.mask[exist_beat].substr(2);
          }
          if (front_trans.mask[exist_beat].size() < nibbles) {
            front_trans.mask[exist_beat].insert(0, '0', nibbles - front_trans.mask[exist_beat].size());
          }

          all_mask.insert(0,front_trans.mask[exist_beat].substr(0,front_trans.mask[exist_beat].size()-(remove_bytes*2)));

          if (front_trans.strobe[exist_beat].size() < (nibbles /2)) {
            front_trans.strobe[exist_beat].insert(0, '0', (nibbles/2) - front_trans.strobe[exist_beat].size());
          }
          // dk:start
          /*if (front_trans.parity[exist_beat].substr(0,1) == "0x") {
            front_trans.parity[exist_beat] = front_trans.parity[exist_beat].substr(1);
          }
          if (front_trans.parity[exist_beat].size() < nibbles) {
            front_trans.parity[exist_beat].insert(0, '0', nibbles - front_trans.parity[exist_beat].size());
          }
          */// dk:end

          all_strobe.insert(0,front_trans.strobe[exist_beat].substr(0,front_trans.strobe[exist_beat].size()-remove_bytes));
          all_bnumber.insert(0,front_trans.bnumber[exist_beat].substr(0,front_trans.bnumber[exist_beat].size()-(remove_bytes*5)));
//          if (DEBUG_MSG) {
//            cout << "inserting all_parity" << endl;
//          }
//          all_parity.insert(0,front_trans.parity[exist_beat].substr(0,front_trans.parity[exist_beat].size()-remove_bytes));  // DK

          // create a list of respones & user signals (one copy per byte)
          for (int each_byte = remove_bytes; each_byte < (int)pow(2.0, (int)trans->size); each_byte++) {
            responses.insert(responses.begin(),front_trans.resp[exist_beat]);
            usersignals.insert(usersignals.begin(),front_trans.user[exist_beat]);
          }
        }

        // Convert any wraps aligned to burst boundary to INCR
        if ((trans->burst == wrap || trans->burst == axi_wrap) && (trans->address % bytes == 0)) {
          trans->burst = axi_incr;
        }
        int first_transaction = bytes;
        int other_transaction = 0;
        int max_transactions = 1;

        // If this is a wrap that is not alligned to the wider bus split it into two
        if ((trans->burst == axi_wrap) && (((trans->address % master_data_bytes) != 0) || (bytes > master_data_bytes * 16 ))) {

          // First transaction is bytes to wrap boundary
          first_transaction = bytes - (trans->address % bytes);
          other_transaction = (trans->address % bytes);
          max_transactions = 2;

          // Also in this case remove an exclusive flag if it exists
          if (trans->locked == axi_excl) {
            trans->locked = nolock;
          }
          // Override to INCR
          trans->burst = axi_incr;
        }

        //IF this is a fixed then split it up into muliple transactions
        if (trans->burst == axi_fixed) {
          if (DEBUG_MSG) {
            std::cout << "Spliting into multiple transactions" << std::endl;
          }
          first_transaction = beatbytes;
          other_transaction = beatbytes;
          max_transactions = trans->length;
          wrap_boundary = trans->address;

          // Also in this case remove an exclusive flag if it exists (and length > 1)
          if (trans->locked == axi_excl && trans->length > 1) {
            trans->locked = nolock;
          }
          // Override to incr
          trans->burst = axi_incr;
        }

        // For each transaction
        for (int trans_no = 0; trans_no < max_transactions; trans_no++) {
          if (DEBUG_MSG) {
            std::cout << "Setting bytes to correct value for each trans" << std::endl;
          }

          // Set bytes to the correct value
          if (trans_no == 0) {
            bytes = first_transaction;
          } else {
            bytes = other_transaction;
            trans->address = wrap_boundary;
          }

          // Determine the maxinum number of bytes in the burst.
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

          // Determine a number of extra bytes that are required to pack out to the maximum beat size (based on alignment)
          extra_bytes = trans->address % max_beat_bytes;

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
            trans->burst = axi_incr;
            waddress = trans->address - (trans->address % max_beat_bytes);

            trans->length = max_length;
            while (waddress < (trans->address - (trans->address % max_beat_bytes))) {
              trans->length--;
              waddress += max_beat_bytes;
            }
            trans->size = (amba_size)log2(max_beat_bytes);

            process.push_back(*trans);

            //Subtract bytes
            bytes -= ((trans->length*max_beat_bytes) - (trans->address % max_beat_bytes));
            extra_bytes = 0;

            //Allign and incrment the address for the next transaction
            trans->address += ((trans->length*max_beat_bytes) - (trans->address % max_beat_bytes));
          }

          //If unlocking transaction and locked set to unlock
          if (unlocking_trans) {

            //If this is the the last transaction then unlock it if locked and set unlocking
            if ((max_transactions == 1) || ((trans_no + 1) == max_transactions)) {

              if (trans->locked == lock) {
                trans->locked = nolock;
              }
              trans->unlocking = true;
            } else {
            // lock the transaction
            trans->locked = lock;
            }
          }

          // Quit if nothing to do
          if (bytes == 0) {
          continue;
          }

          // IF the number of bytes is more than 2 times the master size
          // the size must be the master size
          if (bytes > (max_beat_bytes * 2)) {
            //set size = size of the master bus
            size = max_beat_bytes;
          } else {

              // Determine the number of bytes to the boundary of the wider bus
              //(depends on address and master_bus size)
              bytes_to_boundary = (max_beat_bytes) - trans->address % (max_beat_bytes);
              
              // Check that there aren't more bytes here than in the transaction
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

          // Now that the size has been determined work on the length
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

          // Encode length and size and set
          trans->length = length;

          trans->size = (amba_size)log2(size);
          if ((int)pow(2.0, (int)trans->size) != size) {
            trans->size = (amba_size)(trans->size + 1);
          }

          //If this is an exclusive transaction and the length > 16 delete it
          if (trans->locked == axi_excl && trans->length > 16) {
            trans->locked = nolock;
          }
          process.push_back(*trans);
        }

        //First determine any packing necessary for the first beat
        //Size is now the target size

        string data = "";
        string mask = "";
        string strobe = "";
        string bnumber = "";
//        string parity = "";  // DK

        //determine the alligned base address of the new size
        //There is data from address alligned ...
        input_offset = Address - Address_alligned;
        output_offset = process[0].address % (int)pow(2.0, (int)process[0].size);
        NewAddress = process[0].address - output_offset;
        pack_bytes = Address_alligned - NewAddress;

        // If NewAddress < Address_alligned pack data
        if (NewAddress < Address_alligned) {
          int i = pack_bytes;
          while (i > 0) {
            data = data + "00";
            mask = mask + "00";
            strobe = strobe + "0";
//            parity = parity + "0";  // DK
            if (dummy_bnum >= 65535) {
              throw "Run out of byte numbers in Model_size (1)";
            }
            ostringstream data_str;
            data_str << "0000" << hex << ++dummy_bnum;
            string bnum = data_str.str();
            bnumber = "b" + bnum.substr(bnum.size()-4,4) + bnumber;
            usersignals.insert(usersignals.begin(),string(USER_MAX_WIDTH,'0'));

            responses.insert(responses.begin(),axi_exokay);
            // decrement counter
            i--;
          }
          // display signals for debug
          //std::cout << "Will now attempt to display user signals: \n" << std::endl;
          //std::ostream_iterator<string> out_it (std::cout, "\n");
          //std::copy(front_trans.strobe.begin(), front_trans.strobe.end(), out_it);
          //cout << "strobe_all is: " << all_strobe << endl;;
        }

        // Remove extra packing data
        while (pack_bytes < 0) {
          all_data.erase(all_data.size()-2);
          all_mask.erase(all_mask.size()-2);
          all_bnumber.erase(all_bnumber.size()-5);
          all_strobe.erase(all_strobe.size()-1);
//          all_parity.erase(all_parity.size()-1);  // DK
          responses.pop_back();
          usersignals.pop_back();
          pack_bytes++;
        }

        // Set the write responses
        // if write_resp = okay ... then all ok ... otherwise randomise
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
          }
        }

        //Check that at leat one of the options got the required value
        if (set == false) {
          process.begin()->resp[0] = write_response;
        }
        int last_bnum;
        string bnum;

        while (process.empty() == false) {
          if (DEBUG_MSG) {
            std::cout << "Process full.." << std::endl;
          }
          //Pop the item from the input queue
          process_trans = process.front();
          process.pop_front();

          //For each beat in the new_transaction
          for (new_beat = 0; new_beat < process_trans.length; new_beat++) {
            bytes = (int)pow(2.0, (int)process_trans.size);

            //Set the default response to ex_okay
            if (trans->direction == rd) {
              process_trans.resp[new_beat] = axi_exokay;
            }

            if (pack_bytes >= bytes) { throw "Unexpected packing error\n"; }

            for (int byte_no = pack_bytes; byte_no < bytes; byte_no++) {
              if (all_data.size() != 0) {
                data.insert(0,all_data.substr(all_data.size()-2,2));
                all_data.erase(all_data.size()-2,2);

                if (process_trans.direction == rd and all_mask.size() > 0) {
                  mask.insert(0,all_mask.substr(all_mask.size()-2,2));
                  all_mask.erase(all_mask.size()-2,2);
                }
                // dk:start - REVISIT: This is reapted - why would we need outside read?
               /*if (process_trans.direction == rd and all_parity.size() > 0) {
                  parity.insert(0,all_parity.substr(all_parity.size()-1,1));
                  all_mask.erase(all_parity.size()-1,1);
                }
                */// dk:end
                bnumber.insert(0,all_bnumber.substr(all_bnumber.size()-5,5));
                bnum = "0x" + all_bnumber.substr(all_bnumber.size()-4,4);
                last_bnum = (int)strtoul(bnum.c_str(), NULL, 0);
                all_bnumber.erase(all_bnumber.size()-5,5);

                if (process_trans.direction == wr) {
                  if (DEBUG_MSG) {
                    std::cout<< "Direction write: inserting strobe now" << std::endl;
                  }
                  strobe.insert(0,all_strobe.substr(all_strobe.size()-1,1));  // get string from 'all_strobe' after point all_strobe.size()-1 for lenght 1 and add to 'strobe'
                  all_strobe.erase(all_strobe.size()-1,1);
//                  // DK:start
//                  if (DEBUG_MSG) {
//                  std::cout<< "Also inserting parity now" << std::endl;
//                  }
//                  parity.insert(0,all_parity.substr(all_parity.size()-1,1));
//                  all_parity.erase(all_parity.size()-1,1);
//                  // DK:end
                }
                if (trans->direction == rd) {
                  if (DEBUG_MSG) {
                    std::cout<< "Direction read" << std::endl;
                  }
                  // If response = axi_exokay
                  if (responses.back() == okay && process_trans.resp[new_beat] == axi_exokay) {
                    process_trans.resp[new_beat] = okay;
                  } else if (responses.back() == axi_decerr) {
                    process_trans.resp[new_beat] = axi_decerr;
                  } else if (responses.back() == axi_slverr && process_trans.resp[new_beat] != axi_decerr) {
                   process_trans.resp[new_beat] = axi_slverr;
                  }
//                  // DK:start
//                  if (DEBUG_MSG) {
//                    std::cout<< "Also inserting parity now (for read)" << std::endl;
//                  }
//                  parity.insert(0,all_parity.substr(all_parity.size()-1,1));
//                  all_parity.erase(all_parity.size()-1,1);
//                  // DK:end
                }
                // set the user signals
                process_trans.user[new_beat] = usersignals.back();

                responses.pop_back();
                usersignals.pop_back();

              } else {
                if (DEBUG_MSG) {
                  cout << "inside else: all data and strobe should appear as zero" << endl;
                }
                data = "00" + data;
                mask = "00" + mask;
                strobe = "0" + strobe;
//                parity = "0" + parity;
                if (dummy_bnum >= 65535) {
                  throw "Run out of byte numbers in Model_size (2)";
                }
                ostringstream data_str;
                data_str << "0000" << hex << ++dummy_bnum;
                string bnum = data_str.str();
                bnumber = "b" + bnum.substr(bnum.size()-4,4) + bnumber;
                }
            }
            //Copy values into transaction
            process_trans.data[new_beat] = data;
            process_trans.mask[new_beat] = mask;
            process_trans.strobe[new_beat] = strobe;
            process_trans.bnumber[new_beat] = bnumber;
//            process_trans.parity[new_beat] = parity;  // DK
//            if (DEBUG_MSG) {
//              std::cout << "copying data:" <<data << " into transaction." <<std::endl;
//              std::cout << "copying strobe:" <<strobe << " into transaction." <<std::endl;
//              std::cout << "copying parity:" <<parity << " into transaction." <<std::endl;  // DK
//            }

            //Read responses
            //if (trans->direction == rd) {
            //    set_response_trans(orginal_trans, bnumber, process_trans.resp[new_beat], process_trans.user[new_beat]);
            //}

            //Write repsonses ... if not beat zero and response is ok clear beat
            if (trans->direction == wr && (new_beat != 0) && process_trans.resp[0] == okay) {
              process_trans.resp[new_beat] = okay;
            };

            // Resp ... if resp is ex_okay and not exclusive make okay
            if (process_trans.resp[new_beat] == axi_exokay && (process_trans.locked != axi_excl)) {
              process_trans.resp[new_beat] = okay;
            }

            // reset counters and strings
            pack_bytes=0;
            data = "";
            mask = "";
            strobe = "";
            bnumber = "";
//            parity = "";  //DK
          }
          output->push_back(process_trans);
        }
        if (all_data.size() != 0) {
          cout << "remaining data is " << all_data.size() << endl;
          throw "Unexpected remaining data";
        }
      }
      //cout << "$$$$$$$$will display output now at the end" << *output << endl;

      return "";

    } catch (const char * error) {
      cout << "Caught: size convertion failed with message : " << error << endl;
      exit(1);
    }
}

void Model_size::Return(deque<transaction> * input, deque<transaction> * output) {
  try {
       //Relying on the XML parameter will highlight errors in the XML
    check_rev_user(&stored_trans);

    if (stored_trans[0].address == 0x6482270d) {
      cout << "Name is " << param_s("name") << endl;

      for (unsigned int itrans = 0; itrans < input->size(); itrans++) {
        cout << "Input transaction " << itrans << endl;
        for (int beat = 0; beat < input->at(itrans).length; beat++) {
          cout << "i beat " << beat << " resp " << input->at(itrans).resp[beat] << " bnumber " << input->at(itrans).bnumber[beat] << endl;
        }
      };
    };

    // Go though all the transactions in the stored queue
    for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {
      // Reset the responses to okay (all beats for reads only beat 0 for writes)
      for (int beat = 0; beat < stored_trans[strans].length; beat++) {
        if ( stored_trans[strans].direction == frbm_namespace::read || beat == 0) {
          stored_trans[strans].resp[beat] = axi_exokay;
        }
      }
    }
       //Now go through all the incoming transactions
       //Look at the reponses and if it's an error set the response for the corresponing
       //stored transaction to axi_slverr
    for (unsigned int itrans = 0; itrans < input->size(); itrans++) {

            //If it's a write the resp[0] applies to the whole transaction
      if ((input->at(itrans)).direction == frbm_namespace::write) {
                //Set the response on the following bytes
        for (int beat = 0; beat < input->at(itrans).length; beat++) {
          set_response(&stored_trans, input->at(itrans).bnumber[beat], input->at(itrans).resp[0], 1, input->at(itrans).user[beat]);
        }
      } else {
        // Go through each beat
        for (int beat = 0; beat < input->at(itrans).length; beat++) {
          set_response(&stored_trans, input->at(itrans).bnumber[beat], input->at(itrans).resp[beat], 1, input->at(itrans).user[beat]);
        }
      }
    }
    if (stored_trans[0].address == 0x6482270d) {
      // Go though all the transactions in the stored queue
      for (unsigned int strans = 0; strans < stored_trans.size(); strans++) {
        // Reset the responses to okay (all beats for reads only beat 0 for writes)
        for (int beat = 0; beat < stored_trans[strans].length; beat++) {
          cout << "s beat " << beat << " resp " << stored_trans[strans].resp[beat] << " bnumber " << stored_trans[strans].bnumber[beat] << endl;
        }
      }
    };
    // Having modifed the transactions in the stored_trans list
    input->clear();
    *output = stored_trans;

  } catch (const char * error) {

    cout << "Caught: Size convertion (Return) failed with message : " << error << endl;
    exit(1);
  }
}
/*
void general::display_vector(const vector<int> &v) {
  std::copy(v.begin(), v.end(), std::ostream_iterator<int>(std::cout, " "));
}
*/
