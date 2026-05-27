//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2013 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: ApbFrbmMacro.cpp,v $
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: ApbFrbmMacro
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------


#include "ApbFrbmMacro.h"

using namespace frbm_namespace;
//=========================================================================
// Low level functions
//=========================================================================

void ApbFrbmMacro::Quit(frbm_quit QuitAction)
{
  //Add Quit code here
  LineCount++;
}

void ApbFrbmMacro::Sync()
{
  //Add sync code here       
  LineCount++;
}

void ApbFrbmMacro::C(const char *str)
{
  //Add comment code here      
  LineCount++;
}

void ApbFrbmMacro::Cmt(char *fmt, ...)
{
  char tmp[256];
  va_list argp;
  
  va_start(argp, fmt);

  *mycout << "#";
  vsprintf(tmp, fmt, argp);
  *mycout << tmp<<endl;

  va_end(argp);
  LineCount++;
}

//=======================================================================
// Full Access Read/Write
//=======================================================================

void  ApbFrbmMacro::Access(transaction * trans)
{

    //if there is a comment dela with it first    
    if (trans->comment.empty() != true) {
        C(trans->comment.c_str());
    }

    //Call either read or write    
    if (trans->direction == frbm_namespace::read) {
        Read(trans);
    } else if (trans->direction == frbm_namespace::write){
        Write(trans);
    } else {
        Sync();    
    }

    //Add an empty line
    *mycout << endl;

}

void  ApbFrbmMacro::Read(transaction * trans)
{
    //Check that this is a read     
    assert(trans->direction == frbm_namespace::read);

    //Check the transfer
    uUtilityApb.CheckTransfer(trans->address, trans->length, trans->size, 1);

    //Output the transfer
    *mycout << "R 0x" << hex << setw(8) << setfill('0') << Mask_value_ul(trans->address, 32) << setw(0) << " ";
    *mycout << "0x" << hex << setw(8) << setfill('0') << trans->data[0] << setw(0) << " ";

     //Output the protection
     *mycout << "P";
     DisplayBinary(trans->prot, 3);
     *mycout <<" ";

    //Output the transfer response
    *mycout <<  trans->resp[0] << " ";
 
    
    //Output the Delay
    *mycout << "Delay" << dec << setw(8) << trans->DVWait_s[0] << " ";

    //Output the ID
    *mycout << "ID" << hex << trans->id;
}

void  ApbFrbmMacro::Write(transaction * trans)
{

    //Check that this is a read     
    assert(trans->direction == frbm_namespace::write);

    //Check the transfer
    uUtilityApb.CheckTransfer(trans->address, trans->length, trans->size, 1);

    //Output the transfer
    *mycout << "W 0x" << hex << setw(8) << setfill('0') << Mask_value_ul(trans->address, 32) << setw(0) << " ";
    *mycout << "0x" << hex << setw(8) << setfill('0') << trans->data[0] << setw(0) << " ";
  
    //Output the protection
     *mycout << "P";
     DisplayBinary(trans->prot, 3);
     *mycout <<" ";
   
 
    //Output the Strobe signal
    if (trans->strobe[0] == "") {
      *mycout << "S1111" << " ";
    } else {
      *mycout << "S" << trans->strobe[0]  << " ";
    }
    
 
    //Output the transfer response
    *mycout << trans->resp[0] << " ";

    //Output the Delay
    *mycout << "Delay" << dec << setw(8) << trans->RVWait_s << " ";

    //Output the ID
    *mycout << "ID" << hex << trans->id;

}

//=======================================================================
// Unsupported AHB transactions
//=======================================================================
void ApbFrbmMacro::Loop(arm_uint32 Loop)
{
  assert(0); //Loop not supported
}
