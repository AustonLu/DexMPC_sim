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
// Filename            : $RCSfile:  $
//
// Revision            : 171707
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: DriveAxiPv
//
//---------------------------------------------------------------------------

#ifndef SYSTEM_H
#define SYSTEM_H

#include <cstdarg>
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include <deque>
#include <map>
#include <vector>

#include "arm_types.h"
#include "frbm_types.h"
#include "Model.h"
#include "Register_map.h"
#include "Register_update.h"
#include "Dom.h"

using namespace arm_namespace;
using namespace frbm_namespace;

  class System
  {
    public: 

    //-----------------------------------------------------------------------
    // Constructor
    //-----------------------------------------------------------------------
    System();

    //-----------------------------------------------------------------------
    // Destructor
    //-----------------------------------------------------------------------
    ~System();
  
    //-----------------------------------------------------------------------
    // Methods
    //-----------------------------------------------------------------------

    // Read in configuration
    int Config(char * filename, Register_map * PL301_Reg_i, reg_update_block * reg_update = NULL);

    // Process transaction Source
    deque<transaction> Run(transaction * trans);
    transaction * Run_Reverse(deque<transaction> * trans_queue);

    //-----------------------------------------------------------------------
    // Containers & Variables
    //-----------------------------------------------------------------------
    //PL301 Register_map
    Register_map * PL301_Reg;

    //Map of Models vs their name
    map<string, Model*> Models;

    //Connections Block.port against desitation block.port
    map<string, string> connections;

    //Map node trees containing inforation about each connection 
    //vs the block.port master
    map<string, Node*> connect_info;

    //Model sequence ... order that the models were called in the previous run
    vector<Model *> model_sequence;

    //Queues of transactions
    deque<transaction> queue1;
    deque<transaction> queue2;

    //Locked ports
    map<string, bool> locked_ports;

    //parity width
    int dpe_width;

  };

#endif
