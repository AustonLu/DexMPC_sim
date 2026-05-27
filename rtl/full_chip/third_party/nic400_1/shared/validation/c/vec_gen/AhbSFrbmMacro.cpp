//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2009 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2009-07-29 13:24:27 +0100 (Wed, 29 Jul 2009)
//
// Revision            : 66968
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: AhbSFrbmMacro
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------


#include "AhbSFrbmMacro.h"
//W Address Data [Size] [Burst] [Prot] [Lock] [Response] [Bstrb]
//R Address Data [Size] [Burst] [Prot] [Lock] [Response] [Bstrb]
//S Data [Response] [Bstrb]
//B [Wait]
//I [Address] [Dir] [Size] [Burst] [Prot] [Lock] [Wait]
//P Address Data [Size] [incr|sing] [Prot] [TimeOut] [Number]
//L Number
//C Comment
//Q
//E Number
//NOTE: shaded fields indicate ¿required for V6 extensions only¿
//W - The write command starts a write burst and may be followed by one or more S vectors. The number of S
//vectors is set by the size and burst fields for fixed length bursts. There is no limit to the number of S
//vectors for undefined length bursts, as long as it does not cause the address to cross a 1k boundary.
//R - The read command starts a read burst and may be followed by one or more S vectors. The number of S
//vectors is set by the size and burst fields for fixed length bursts. There is no limit to the number of S
//vectors for undefined length bursts, as long as it does not cause the address to cross a 1k boundary.
//S - The sequential vector provides data for a single beat in the burst. The File Reader calculates the address
//required.
//B - The busy command inserts a BUSY cycle mid burst. An INCR burst is allowed to have a busy after its last
//transfer (while the master determines whether or not it has another transfer to complete). It is not valid to
//have a busy command when a burst is not in progress. The Wait field requires the master to wait for
//HREADY beore continuing.
//I - The Idle command performs an idle cycle. The options allow you to set up the control information during the
//idle transfer, and to specify if the transfer is locked or unlocked. The Wait field requires the master to wait for
//HREADY beore continuing.
//P - Poll command performs a read transfer that repeats until the data matches the required value. If it repeats
//this Number times and the value is not read then an error is reported. Either omitting TimeOut or setting to
//value zero will cause the Poll to repeat continually until the data matches the required value. The poll vector
//can only be used for INCR or SINGLE burst types. Number allows the number of cycles between polls to be
//specified, default 1.
//L - Loop command repeats the last command a number of times. An L command can only follow a W or R when
//the burst type is INCR or SINGLE.
//C - The Comment command prints out a message to the simulation window.
//Q - The Quit command finishes the simulation. This command is not supported by the XVC. The simulation will
//be finished once all AHB masters have executed all vectors.
//E - Emit an event of ID <Number> to the XTSM.

using namespace frbm_namespace;
//=========================================================================
// Low level functions
//=========================================================================

void AhbSFrbmMacro::Quit(frbm_quit QuitAction)
{
  *mycout << "Quit " << endl;
  LineCount++;
}

void AhbSFrbmMacro::Sync()
{
   //Sync is not supported by AHB .. empty place holder
}

//===========
// Write
//===========
void AhbSFrbmMacro::Write(transaction * trans)
{
  //Check that this is a read
  assert(trans->direction == frbm_namespace::write);

  //W Address Data [Size] [Burst] [Prot] [Lock] [Response]
  //Wait on data 0
  if (trans->await_code_s != 0) {
     *mycout << "WAIT " << dec << setw(8) << trans->await_code_s << endl;
  }
  if ((trans->dwait_code_s[0] != 0) && (trans->dwait_code_s[0] != trans->await_code_s)) {
     *mycout << "WAIT " << dec << setw(8) << trans->dwait_code_s[0] << endl;
  }
  if ((trans->rwait_code_s != 0) && (trans->rwait_code_s != trans->await_code_s) && (trans->rwait_code_s != trans->dwait_code_s[0])) {
     *mycout << "WAIT " << dec << setw(8) << trans->rwait_code_s << endl;
  }

  *mycout << "W 0x" << hex << setw(Calc_addr_width(trans->addr_width)) << setfill('0') << trans->address << setw(0) << dec << " "
    << "0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[0].substr(0,Data_width(trans->size)) << setw(0) << dec << " "
    << trans->size << " "
    << trans->burst << " P";
    DisplayBinary(trans->prot, 4);
    *mycout << " " <<  trans->locked << " "
    << trans->resp[0] << " "
    << hex << "ID" << trans->id << dec << " "
    << "M" << setw(Data_width(trans->size) / 2) << setfill('0') << trans->strobe[0].substr(0,Data_width(trans->size) / 2) << setw(0) << dec << " ";

  //Delay on data[0]
  if (trans->DRWait[0] != 0) {
      *mycout << " DELAY" << dec << trans->DRWait[0];
  }

  *mycout << endl;

  if (trans->aemit_code_s != 0) {
     *mycout << "EMIT " << dec << setw(8) << trans->aemit_code_s << endl;
  }
  if ((trans->demit_code_s[0] != 0) && (trans->demit_code_s[0] != trans->aemit_code_s)) {
     *mycout << "EMIT " << dec << setw(8) << trans->demit_code_s[0] << endl;
  }
  if ((trans->remit_code_s != 0) && (trans->remit_code_s != trans->aemit_code_s) && (trans->remit_code_s != trans->demit_code_s[0])) {
     *mycout << "EMIT " << dec << setw(8) << trans->remit_code_s << endl;
  }

  //No go through every beat of the transaction
  //S Data  [Response] [Bstrb]
  for (int beat = 1; beat < trans->length; beat++) {
     if (trans->dwait_code_s[beat] != 0) {
         *mycout << "WAIT " << dec << setw(8) << trans->dwait_code_s[beat] << endl;
     }
     *mycout << "S 0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[beat].substr(0,Data_width(trans->size)) << setw(0) << dec << " "
        << hex << "ID" << trans->id << dec << " "
        << trans->resp[beat] << " "
        << "M" << setw(Data_width(trans->size) / 2) << setfill('0') << trans->strobe[beat].substr(0,Data_width(trans->size) / 2) << setw(0) << dec << " ";

     //Delay on data[beat]
     if (trans->DRWait[beat] != 0) {
         *mycout << " DELAY" << dec << trans->DRWait[beat];
     }

     *mycout << endl;

     if (trans->demit_code_s[beat] != 0) {
        *mycout << "EMIT " << dec << setw(8) << trans->demit_code_s[beat] << endl;
     }
  }
}

//===========
// Read
//===========
void AhbSFrbmMacro::Read(transaction * trans)
{
  //Check that this is a read
  assert(trans->direction == frbm_namespace::read);

  //Wait on data 0
  if (trans->await_code_s != 0) {
     *mycout << "WAIT " << dec << setw(8) << trans->await_code_s << endl;
  }
  if ((trans->dwait_code_s[0] != 0) && (trans->dwait_code_s[0] != trans->await_code_s)) {
     *mycout << "WAIT " << dec << setw(8) << trans->dwait_code_s[0] << endl;
  }

  *mycout << "R 0x" << hex << setw(Calc_addr_width(trans->addr_width)) << setfill('0') << trans->address << setw(0) << dec << " "
    << "0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[0].substr(0,Data_width(trans->size)) << setw(0) << dec << " "
    << trans->size << " "
    << trans->burst << " P";
    DisplayBinary(trans->prot, 4);
    *mycout << " " <<  trans->locked << " "
    << trans->resp[0] << " "
    << hex << "ID" << trans->id << dec << " ";

  //Delay on data[0]
  if (trans->DVWait[0] != 0) {
      *mycout << " DELAY" << dec << trans->DVWait[0];
  }

  *mycout << endl;

  if (trans->aemit_code_s != 0) {
     *mycout << "EMIT " << dec << setw(8) << trans->aemit_code_s << endl;
  }
  if ((trans->demit_code_s[0] != 0) && (trans->demit_code_s[0] != trans->aemit_code_s)) {
     *mycout << "EMIT " << dec << setw(8) << trans->demit_code_s[0] << endl;
  }

  //No go through every beat of the transaction
  //S Data  [Response] [Bstrb]
  for (int beat = 1; beat < trans->length; beat++) {
     if (trans->dwait_code_s[beat] != 0) {
         *mycout << "WAIT " << dec << setw(8) << trans->dwait_code_s[beat] << endl;
     }
     *mycout << "S 0x" << hex << setw(Data_width(trans->size)) << setfill('0') << trans->data[beat].substr(0,Data_width(trans->size)) << setw(0) << dec << " "
        << hex << "ID" << trans->id << dec << " "
        << trans->resp[beat] << " ";

     //Delay on data[beat]
     if (trans->DVWait[beat] != 0) {
         *mycout << " DELAY" << dec << trans->DVWait[beat];
     }

     *mycout << endl;

     if (trans->demit_code_s[beat] != 0) {
        *mycout << "EMIT " << dec << setw(8) << trans->demit_code_s[beat] << endl;
     }
  }
}

//===========
// Data Width
//===========

int AhbSFrbmMacro::Data_width(amba_size size)
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

void  AhbSFrbmMacro::Access(transaction * trans)
{

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
