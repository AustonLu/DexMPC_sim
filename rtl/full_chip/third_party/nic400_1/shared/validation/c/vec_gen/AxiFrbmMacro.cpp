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
// Purpose: AxiFrbmMacro
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------


#include "AxiFrbmMacro.h"

using namespace frbm_namespace;
//=========================================================================
// Low level functions
//=========================================================================

void AxiFrbmMacro::Quit(frbm_quit QuitAction)
{
  switch(QuitAction)
  {
    case quit_stop:
      *mycout << "Quit stop" << endl;
      break;
    case quit_emit:
      *mycout << "Quit emit" << endl;
      break;
    case quit_idle:
      *mycout << "Quit idle" << endl;
     break;
   }
  LineCount++;
}

void AxiFrbmMacro::Sync()
{
  *mycout << "SYNC" << endl;
  LineCount++;
}

void AxiFrbmMacro::C(const char *str)
{
  *mycout << "C " << "\"" << str << "\"" << endl;
  LineCount++;
  
}

void AxiFrbmMacro::Cmt(char *fmt, ...)
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

//===========
// P
//===========

void AxiFrbmMacro::P(transaction * trans)
{
  assert(trans->cache<0x10);
  assert(trans->prot<0x8);

  *mycout << "P 0x" << hex <<setw(Calc_addr_width(trans->addr_width)) << setfill('0') << trans->address << setw(0) << dec << " " 
    << trans->size << " " 
    << "C"; 
  DisplayBinary(trans->cache, 4);
  *mycout << " P";
  DisplayBinary(trans->prot, 3);
  *mycout << " V" << trans->AVWait << " " << trans->check << " N" << trans->repeat << endl;
 
  LineCount++;
}

//===========
// AW
//===========
void AxiFrbmMacro::AW(transaction * trans)
{

  //Check Transaction
  uUtilityAxi.CheckTransfer(trans->address, trans->length, trans->size, trans->burst, trans->locked, trans->cache, trans->prot, 1);

  //Normal AXI fields
  *mycout << "AW 0x" << hex << setw(Calc_addr_width(trans->addr_width)) << setfill('0') << Mask_value_ul(trans->address, trans->addr_width) << setw(0) << dec << " "
    "L" << (int)(trans->length) << " "
    << trans->size << " " 
    << trans->burst << " " 
    << trans->locked << " " 
    << "C"; 
  DisplayBinary(trans->cache, 4);

  *mycout << " P";
  DisplayBinary(trans->prot, 3);

  *mycout << " " << trans->ref;

  //ID
  *mycout << " ID" << hex << trans->id << dec;

  //Valid time on a master
  if ( trans->AVWait != 0 && (ms_type == master_p || ms_type == both)) {
     *mycout << " V" << dec << trans->AVWait; 
  }
 
  //Ready time on a slave
  if (trans->ARWait_s != 0 && (ms_type == slave_p || ms_type == both)) {
     *mycout << " R" << dec << trans->ARWait_s; 
  }

  //Now add emit waits 
  if (trans->await_code != 0 && ms_type == master_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->await_code;
  }

  if (trans->await_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->await_code_s;
  }

  if (trans->aemit_code != 0 && ms_type == master_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->aemit_code;    
  }

  if (trans->aemit_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->aemit_code_s;    
  }

  if (trans->awuser_width != 0) {
      *mycout << " " << "U" << hex << setw(Calc_addr_width(trans->awuser_width)) << setfill('0') << Mask_value_ul(trans->auser[0], trans->awuser_width);    
  }

  if (trans->protocol == axi4) {
      *mycout << " " << "Q" << dec << (int)trans->qv;
      *mycout << " " << "G" << dec << (int)trans->region;
  }

  //Add line end and finish
  *mycout << endl;
  LineCount++;
}

//===========
// W
//===========
void AxiFrbmMacro::W(transaction * trans, arm_uint8 beat)
{ 
   //Check that this is a valid beat     
   assert(beat < trans->length);

   //Remove 0x from start
   if (trans->data[beat].substr(0,1) == "0x") trans->data[beat] = trans->data[beat].substr(2);

   //Output Data 
   *mycout << "W 0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[beat].substr(0,Data_width(trans->size)) << setw(0) << dec << " ";

   if (trans->strobe[beat] != "") {
     *mycout << "S" << setw(Data_width(trans->size)/2) << setfill('0') <<  trans->strobe[beat].substr(0,Data_width(trans->size)/2) << setw(0);
   //DisplayBinary(atoi(trans->strobe[beat].substr(0,Data_width(trans->size)).c_str()), Data_width(trans->size) / 2);
   }
   //Give a ready time if this is a slave 
   if (trans->DRWait_s[beat] != 0 && (ms_type == slave_p || ms_type == both)) {
      *mycout << " R" << dec << trans->DRWait_s[beat];
   }

   //Add repeats if not 1
   if (trans->repeat != 1) {
      *mycout <<  " N" << dec << (int) trans->repeat;
   }

   //Now add waits if they're not 0
   if (trans->dwait_code[beat] != 0 && ms_type == master_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->dwait_code[beat];
   }

   if (trans->dwait_code_s[beat] != 0 && ms_type == slave_p) {
      *mycout << " " << "WAIT" << dec << setw(8) << trans->dwait_code_s[beat];
   }
 
   if (trans->demit_code[beat] != 0 && ms_type == master_p) {
      *mycout << " " << "EMIT" << dec << setw(8) << trans->demit_code[beat];    
   }

   if (trans->demit_code_s[beat] != 0 && ms_type == slave_p) {
      *mycout << " " << "EMIT" << dec << setw(8) << trans->demit_code_s[beat];    
   }

   if (trans->wuser_width != 0) {
      *mycout << " " << "U" << hex << setw(Calc_addr_width(trans->wuser_width)) << setfill('0') << Mask_value(trans->user[beat], trans->wuser_width);    
   }

   if (trans->DRWait_s[beat] != 0 && (ms_type == slave_p || ms_type == both)) {
      *mycout << " R" << dec << trans->DRWait_s[beat];
   }
   
   //Give valid time if this is a master
   if (trans->DVWait[beat] != 0 && (ms_type == master_p || ms_type == both)) {
      *mycout << " V" << dec << trans->DVWait[beat];
   }

   LineCount++;
   *mycout << endl;
   
}

//===========
// B
//===========

void AxiFrbmMacro::B(transaction * trans)
{
  *mycout << "B " << trans->resp[0];
  
  //If this is a master add a ready time
  if (trans->RRWait != 0 && (ms_type == master_p || ms_type == both)) {
     *mycout << " R" << dec << trans->RRWait;
  }

  //If this is a slave add a ready time
  if (trans->RVWait_s != 0 && (ms_type == slave_p || ms_type == both)) {
     *mycout << " V" << dec << trans->RVWait_s;
  }

  //Now add waits if they're not 0
  if (trans->rwait_code != 0 && ms_type == master_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->rwait_code;
  }
  if (trans->remit_code != 0 && ms_type == master_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->remit_code;     
  }
  if (trans->rwait_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->rwait_code_s;
  }
  if (trans->remit_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->remit_code_s;     
  }

  if (trans->buser_width != 0) {
      *mycout << " " << "U" << hex << setw(Calc_addr_width(trans->buser_width)) << setfill('0') << Mask_value(trans->ruser, trans->buser_width);    
  }

  LineCount++;
  //Add end of line
  *mycout << endl;
}

//===========
// AR
//===========
void AxiFrbmMacro::AR(transaction * trans)
{

  //Check Transaction
  uUtilityAxi.CheckTransfer(trans->address, trans->length, trans->size, trans->burst, trans->locked, trans->cache, trans->prot, 1);

  //Normal AXI fields
  *mycout << "AR 0x" << hex << setw(Calc_addr_width(trans->addr_width)) << setfill('0') << Mask_value_ul(trans->address, trans->addr_width) << setw(0) << dec << " "
    "L" << (int)(trans->length) << " "
    << trans->size << " " 
    << trans->burst << " " 
    << trans->locked << " " 
    << "C"; 
  DisplayBinary(trans->cache, 4);

  *mycout << " P";
  DisplayBinary(trans->prot, 3);

  *mycout << " " << trans->ref;

  //ID
  *mycout << " ID" << hex << trans->id << dec;

  //Valid time on a master
  if (trans->AVWait != 0 && (ms_type == master_p || ms_type == both)) {
     *mycout << " V" << dec << trans->AVWait; 
  }
 
  //Ready time on a slave
  if (trans->ARWait_s != 0 && (ms_type == slave_p || ms_type == both)) {
     *mycout << " R" << dec << trans->ARWait_s; 
  }

  //Now add emit waits 
  if (trans->await_code != 0 && ms_type == master_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->await_code;
  }

  if (trans->await_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->await_code_s;
  }

  if (trans->aemit_code != 0 && ms_type == master_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->aemit_code;    
  }

  if (trans->aemit_code_s != 0 && ms_type == slave_p) {
     *mycout << " " << "EMIT" << dec << setw(8) << trans->aemit_code_s;    
  }

  if (trans->aruser_width != 0) {
      *mycout << " " << "U" << hex << setw(Calc_addr_width(trans->aruser_width)) << setfill('0') << Mask_value_ul(trans->auser[0], trans->aruser_width);    
  }

  if (trans->protocol == axi4) {
      *mycout << " " << "Q" << dec << (int)trans->qv;
      *mycout << " " << "G" << dec << (int)trans->region;
  }

  //Add line end and finish
  *mycout << endl;
  LineCount++;

}

//===========
// R
//===========

void AxiFrbmMacro::R(transaction * trans, arm_uint8 beat)
{ 
   //Check that this is a valid beat     
   assert(beat < trans->length);

   //Remove 0x from start of data
   if (trans->data[beat].substr(0,2) == "0x") trans->data[beat] = trans->data[beat].substr(2);
   if (trans->mask[beat].substr(0,2) == "0x") trans->mask[beat] = trans->mask[beat].substr(2);

   //Output Data 
   *mycout << "R 0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[beat].substr(0,Data_width(trans->size)) << setw(0) << dec << " ";
   if (trans->mask[beat] != "") {     
     *mycout << "M" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->mask[beat].substr(0,Data_width(trans->size)) << setw(0) << dec;
   }
   //Add repeats if not 1
   if (trans->repeat != 1) {
      *mycout <<  " N" << dec << (int) trans->repeat;
   }

   //Now add waits if they're not 0
   if (trans->dwait_code[beat] != 0 && ms_type == master_p) {
     *mycout << " " << "WAIT" << dec << setw(8) << trans->dwait_code[beat];
   }

   if (trans->dwait_code_s[beat] != 0 && ms_type == slave_p) {
      *mycout << " " << "WAIT" << dec << setw(8) << trans->dwait_code_s[beat];
   }
 
   if (trans->demit_code[beat] != 0 && ms_type == master_p) {
      *mycout << " " << "EMIT" << dec << setw(8) << trans->demit_code[beat];    
   }

   if (trans->demit_code_s[beat] != 0 && ms_type == slave_p) {
      *mycout << " " << "EMIT" << dec << setw(8) << trans->demit_code_s[beat];    
   }

   if (trans->ruser_width != 0) {
      *mycout << " " << "U" << hex << setw(Calc_addr_width(trans->ruser_width)) << setfill('0') << Mask_value(trans->user[beat], trans->ruser_width);    
   }

   if (trans->DRWait[beat] != 0 && (ms_type == master_p || ms_type == both)) {
      *mycout << " R" << dec << trans->DRWait[beat];
      //cout << "ms_type is " << ms_type << trans->DRWait[beat] << endl;
   }
   
   //Add line end and finish
   if (trans->DVWait_s[beat] != 0 && (ms_type == slave_p || ms_type == both)) {
       *mycout << " V" << dec << trans->DVWait_s[beat];
   }

   *mycout << " " << trans->resp[beat] << endl;
   LineCount++;
}

//===========
// Data Width
//===========

int AxiFrbmMacro::Data_width(amba_size size)
{
  //return number of nibbles in data      
  switch (size)
  {
    case size8:
      return 2;
    case size16:
      return 4;
    case size32:
      return 8;
    case size64:
      return 16;
    case size128:
      return 32;
    case size256:
      return 64;
    case size512:
      return 128;
    case size1024:
      return 256;
    default:
      return 0;
  } 
     
}

//=======================================================================
// Full Access Read/Write
//=======================================================================

void  AxiFrbmMacro::Access(transaction * trans)
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

void  AxiFrbmMacro::Read(transaction * trans)
{
    int beat;     

    //Check that this is a read     
    assert(trans->direction == frbm_namespace::read);

    //Send AR channel
    AR(trans);

    //Send read data beats
    for (beat = 0; beat < trans->length; beat++) {
        R(trans, beat);    
    }
}

void  AxiFrbmMacro::Write(transaction * trans)
{
    int beat;     

    //Check that this is a read     
    assert(trans->direction == frbm_namespace::write);

    //Send AR channel
    AW(trans);
    
    //Send read data beats
    for (beat = 0; beat < trans->length; beat++) {
        W(trans, beat);    
    }

    //Send B response
    B(trans);
}

//=======================================================================
// Unsupported AHB transactions
//=======================================================================
void AxiFrbmMacro::Loop(arm_uint32 Loop)
{
  assert(0); //Loop not supported
}
