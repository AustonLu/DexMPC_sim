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
// Filename            : $RCSfile: AxiFrbmMacro.cpp,v $
//
// Checked In          :  2014-02-24 15:35:56 +0000 (Mon, 24 Feb 2014)
//
// Revision            : 167570
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: wire model - simply moves transactions from input to output queue
//
//---------------------------------------------------------------------------

#include "../include/Model.h"

string Model_wire::Run(deque<transaction> * input, deque<transaction> * output, transaction * orginal_trans) {
 
     //copy transaction over unchanged
     *output = *input;
     input->clear();

     return "";

}

