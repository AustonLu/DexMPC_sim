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
// Purpose             : Bus Matrix Model
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Includes
//-------------------------------------------------------------------------
#include "../include/Model.h"

//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Function Name : Model_busmatrix::Run
//
// Arguments     : input            : Input queue of transactions entering
//                                    the Bus Matrix Model.
//
//                 output           : Output queue of transactions leaving
//                                    the Bus Matrix Model.
//
//                 orginal_trans    : (Unused in this function.)
//                                    
//-------------------------------------------------------------------------
string Model_busmatrix::Run(deque<transaction> * input,
                            deque<transaction> * output,
                            transaction * orginal_trans)
{
  transaction trans;       // Temporary variable used to store a local copy of
                           // an input transaction whilst it is being locally
                           // modified.

  int         port;        // 

  string      slave_port;  // Temporary variable used to store the destination
                           // Slave Port of the incomming transaction.

  // Push a copy of the incoming (unmodified) transaction queue into a list
  // Note: This copy will be used when the Bus Matrix Model responds back
  //       to the Master(s).
  //
  trans_queue_list.push_back(*input);

  // Search through each transaction in the input queue...
  while (!input->empty())
  {
    // Extract the transaction currently at the head of the input queue
    trans = input->front();

    // Removes the extracted transaction from the input queue
    // Note: "pop_front()" does not return the transaction
    input->pop_front();

    // If the "User" signal widths are zero, set the value for those signals
    // in the transaction to zero but only if the direction is correct

    // For both reads and writes, zero the address-channel user signals
    if (((param("awuser_width") == 0) && trans.direction == frbm_namespace::write) || 
            ((param("aruser_width") == 0) && trans.direction == frbm_namespace::read))
    {
      trans.auser[0] = string(NIC_AUSER_MAX_WIDTH,'0');
    };

    // For writes only, zero the write data-channel user signals on each beat
    if (trans.direction == frbm_namespace::write)
    {
      if (param("wuser_width") == 0)
      {
        for (int i = 0; i < trans.length; i++) { trans.user[i] = string(USER_MAX_WIDTH,'0'); };
      };
    };

    // If the "Region" signal width is zero, set the value for that signal
    // in the transaction to zero.
    // 
    if (param_s("regions_flag") != "true") { trans.region = 0; };

    // Determine the destination slave port
    slave_port = trans.location.substr(trans.location.find(".") + 1);

    // Reset the destination port number
    port = 0;

    // Determine the destination port number

    // go through ports and subtract valids 
    //location contains block.port
    while ((DomReader.get_value_i((*connect_info)[name + "." +
                                                  clist(param_s("sparse_" +
                                                                slave_port),
                                                        port)],
                                   "valid_width")) < trans.valid)
    {
      trans.valid = trans.valid -
                    DomReader.get_value_i((*connect_info)[name + "." +
                                                  clist(param_s("sparse_" +
                                                                slave_port),
                                                         port)],
                                          "valid_width");
      port++;
    };

    // Push a copy of the modified transaction to the tail of the output queue
    output->push_back(trans);

  }; // while (!input->empty())

  return clist(param_s("sparse_" + slave_port), port);
};

//-------------------------------------------------------------------------
// Function Name : Model_busmatrix::Return
//
// Arguments     : input            : Input queue of transactions returning
//                                    through the Bus Matrix Model.
//
//                 output           : Output queue of transactions leaving
//                                    the Bus Matrix Model.
//
//-------------------------------------------------------------------------
void Model_busmatrix::Return(deque<transaction> * input,
                             deque<transaction> * output)
{
  // Extract the transaction queue currently at the tail of the stored list
  stored_trans = trans_queue_list.back();

  // Removes the extracted transaction queue from the stored list
  // Note: "pop_back()" does not return the transaction queue
  trans_queue_list.pop_back();

  // Update the transactions in the queue with Slave response and user
  // signal information from the incomming input queue
  for (int trans = 0; trans < input->size(); trans++)
  {
    stored_trans[trans].resp = input->at(trans).resp;
    stored_trans[trans].user = input->at(trans).user;
  };

  // Update the output queue with the updated transaction information
  *output = stored_trans;

  // Erases the incomming input queue
  input->clear();
};

//-------------------------------------------------------------------------
// End of File
//-------------------------------------------------------------------------
