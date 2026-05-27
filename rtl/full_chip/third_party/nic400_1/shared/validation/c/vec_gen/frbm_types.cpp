//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2016 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Checked In          :  2016-03-04 09:24:36 +0000 (Fri, 04 Mar 2016)
//
// Revision            : 207714
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
#define DEBUG_MSG 0


#include "../include/frbm_types.h"
#include <cmath>
#include <sstream>

using namespace frbm_namespace;

ostream& frbm_namespace::operator<< (ostream& os, frbm_check check)
{
  switch (check)
  {
    case eq: os << "eq"; break;
    case ne: os << "ne"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, frbm_ref reference)
{
  switch (reference)
  {
    case addr_id: os << "addr_id"; break;
    case sync:   os << "sync"; break;
    case addr:   os << "addr"; break;
    case wfirst: os << "wfirst"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, frbm_quit quit)
{
  switch (quit)
  {
    case quit_stop:      os << "quit_stop"; break;
    case quit_emit:      os << "quit_emit"; break;
    case quit_idle:      os << "quit_idle"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_align myalign)
{
  switch (myalign)
  {
    case align:   os << "align"; break;
    case unalign: os << "unalign"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_wait mywait)
{
  switch (mywait)
  {
    case ahb_wait:   os << "wait"; break;
    case ahb_nowait: os << "nowait"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_transfer transfer)
{
  switch (transfer)
  {
    case ahb_idle:   os << "ahb_idle"; break;
    case ahb_busy:   os << "ahb_busy"; break;
    case ahb_nonseq: os << "ahb_nonseq"; break;
    case ahb_seq:    os << "ahb_seq"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_burst burst)
{
  switch (burst)
  {
    case axi_fixed: os << "fixed"; break;
    case axi_incr:  os << "incr"; break;
    case axi_wrap:  os << "wrap"; break;
    case incr:  os << "incr"; break;
    case wrap:  os << "wrap"; break;
    case ahb_single:  os << "single"; break;
    case ahb_incr:    os << "incr"; break;
    case ahb_incr4:   os << "incr4"; break;
    case ahb_incr8:   os << "incr8"; break;
    case ahb_incr16:  os << "incr16"; break;
    case ahb_wrap4:   os << "wrap4"; break;
    case ahb_wrap8:   os << "wrap8"; break;
    case ahb_wrap16:  os << "wrap16"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_lock mylock)
{
  switch (mylock)
  {
    case nolock: os   << "nolock"; break;
    case lock:   os   << "lock"; break;
    case axi_excl: os << "excl"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_direction direction)
{
  switch (direction)
  {
    case write: os << "write"; break;
    case read:  os << "read"; break;
    default: os << "ERROR"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_size size)
{
  switch (size)
  {
    case size8:
      os << "size8"; break;
    case size16:
      os << "size16"; break;
    case size32:
      os << "size32"; break;
    case size64:
      os << "size64"; break;
    case size128:
      os << "size128"; break;
    case size256:
      os << "size256"; break;
    case size512:
      os << "size512"; break;
    case size1024:
      os << "size1024"; break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_resp resp)
{
  switch (resp)
  {
    case okay:     os << "okay"; break;
    case axi_exokay:   os << "exokay"; break;
    case axi_slverr:   os << "slverr"; break;
    case axi_decerr:   os << "decerr"; break;
    case ahb_error:    os << "error";  break;
  }
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, amba_length length)
{
  os << (int)length;
  return os;
}

ostream& frbm_namespace::operator<< (ostream& os, transaction trans)
{
    os << endl;
    os << "Transaction" << endl;
    os << "-----------" << endl;
    os << "Address   : " << hex << trans.address << dec << endl;
    os << "Size      : " << trans.size << " (" << int(trans.size) << ")" << endl;
    os << "Length    : " << (int)trans.length << endl;
    os << "Burst     : " << trans.burst << endl;
    os << "Cache     : 0x" << hex << (unsigned int)trans.cache << dec << endl;
    os << "dpe_width : " << trans.dpe_width << endl;
    os << "Dir       : " << trans.direction << endl;

    for (int i = 0; i < trans.length; i++)
    {
        os << endl;
        os << "data[" << i << "]        = " << trans.data[i] << endl;
        os << "bnumber[" << i << "]     = " << trans.bnumber[i] << endl;

        if (trans.direction == rd)
        {
            if (trans.mask[i] != "")
            {
                os << "Mask[" << i << "]        = " << trans.mask[i] << endl;
            }
        }

        if (trans.direction == wr)
        {
            if (trans.strobe[i] != "")
            {
                os << "strobe[" << i << "]      = " << trans.strobe[i] << endl;
            }
        }

        if (trans.dpe_width > 0)
        {
            os << "parity[" << i << "]      = " << trans.parity[i] << endl;
            os << "data_parity[" << i << "] = 0x" << hex << trans.data_parity[i] << " " << ((trans.parity_validity[i]) ? "1" : "0") << dec << endl;
        }

        if (trans.direction == rd)
        {
            os << "Resp[" << i << "]        = " << trans.resp[i] << endl;
        }

        os << "user[" << i << "]        = " << trans.user[i] << endl;
    }

    if (trans.direction == wr)
    {
        os << "Resp                     = " << trans.resp[0] << endl;
    };
    return os;
}


int transaction::lower_byte_lane(int data_bus_bytes, int N)
{
  arm_uint64 start_address = address;
  arm_uint32 number_bytes = 1 << (size);
  arm_uint16 burst_length = length;
  arm_uint64 aligned_address = (start_address/number_bytes) * number_bytes;

  int lower_byte_lane;

  if (N == 1)
  {
      lower_byte_lane = start_address - ((start_address/data_bus_bytes)*data_bus_bytes);
  }
  else
  {
      arm_uint64 address_N = aligned_address + (N - 1) * number_bytes;
      if (burst == axi_wrap)
      {
          arm_uint64 wrap_boundary = (start_address/(number_bytes * burst_length)) * (number_bytes * burst_length);
          if (address_N == (wrap_boundary + (number_bytes * burst_length)))
          {
              address_N = wrap_boundary;
          }
          else if (address_N > (wrap_boundary + (number_bytes * burst_length)))
          {
              address_N = start_address + ((N-1)*number_bytes) - (number_bytes * burst_length);
          }
          lower_byte_lane = address_N - ((address_N/data_bus_bytes)*data_bus_bytes);
      }
      else if (burst == axi_fixed)
      {
          //same address for every beat
          lower_byte_lane = start_address - ((start_address/data_bus_bytes)*data_bus_bytes);
      }
      else
      {
          lower_byte_lane = address_N - ((address_N/data_bus_bytes)*data_bus_bytes);
      }
  }

  return lower_byte_lane;
}

int transaction::upper_byte_lane(int data_bus_bytes, int N)
{
  arm_uint64 start_address = address;
  arm_uint32 number_bytes = 1 << (size);
  arm_uint16 burst_length = length;
  arm_uint64 aligned_address = (start_address/number_bytes) * number_bytes;

  int lower_byte_lane;
  int upper_byte_lane;

  if (N == 1)
  {
      lower_byte_lane = start_address - ((start_address/data_bus_bytes)*data_bus_bytes);
      upper_byte_lane = aligned_address + (number_bytes - 1) - ((start_address/data_bus_bytes) * data_bus_bytes);
  }
  else
  {
      arm_uint64 address_N = aligned_address + (N - 1) * number_bytes;
      if (burst == axi_wrap)
      {
          arm_uint64 wrap_boundary = (start_address/(number_bytes * burst_length)) * (number_bytes * burst_length);
          if (address_N == (wrap_boundary + (number_bytes * burst_length)))
          {
              address_N = wrap_boundary;
          }
          else if (address_N > (wrap_boundary + (number_bytes * burst_length)))
          {
              address_N = start_address + ((N-1)*number_bytes) - (number_bytes * burst_length);
          }
          lower_byte_lane = address_N - ((address_N/data_bus_bytes)*data_bus_bytes);
          upper_byte_lane = lower_byte_lane + number_bytes - 1;
      }
      else if (burst == axi_fixed)
      {
          //same address for every beat
          lower_byte_lane = start_address - ((start_address/data_bus_bytes)*data_bus_bytes);
          upper_byte_lane = aligned_address + (number_bytes - 1) - ((start_address/data_bus_bytes) * data_bus_bytes);
      }
      else
      {
          lower_byte_lane = address_N - ((address_N/data_bus_bytes)*data_bus_bytes);
          upper_byte_lane = lower_byte_lane + number_bytes - 1;
      }
  }

  return upper_byte_lane;
}

string transaction::full_bus_data(int data_bus_bytes, int b)
{
    string result;
    arm_uint32 number_bytes = 1 << size;
    int lbl = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
    result = string(data_bus_bytes*2 - data[b].size() - lbl*2, '0') +
             data[b] +
             string(lbl*2, '0');
    return result;
}


string transaction::full_bus_strobe(int data_bus_bytes, int b)
{
    string result;
    arm_uint32 number_bytes = 1 << size;
    int lbl = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
    result = string(data_bus_bytes - strobe[b].size() - lbl, '0') +
             strobe[b] +
             string(lbl, '0');
    return result;
}

string transaction::full_bus_parity(int data_bus_bytes, int b)
{
    if (DEBUG_MSG) { cout << "---- full_bus_parity --------------------------------"  << endl; }
    if (DEBUG_MSG) { cout << "data_bus_bytes " << data_bus_bytes << " parity[" << b << "].size " << parity[b].size() << endl; }
    string result;
    if (dpe_width != 0)
    {
        arm_uint32 number_bytes = 1 << size;
        int lbl = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
        result = parity[b].substr(parity[b].size() - data_bus_bytes, data_bus_bytes);
    }
    if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
    return result;
}

void transaction::put_bus_data(int data_bus_bytes, int b, string bus_data)
{
    if (DEBUG_MSG) { cout << "---- put_bus_data --------------------------------"  << endl; }
    arm_uint32 number_bytes = 1 << size;
    int lbl = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
    if (DEBUG_MSG) { cout << "bus_data " << bus_data << " lbl " << lbl << " data[" << b << "] " << data[b]  << endl; }
    data[b] = bus_data.substr(bus_data.size() - lbl*2 - number_bytes*2, number_bytes*2);
    if (DEBUG_MSG) { cout << "data[" << b << "] " << data[b]  << endl; }
    if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
}

void transaction::put_bus_parity(int b, string bus_parity)
{
    if (DEBUG_MSG) { cout << "---- put_bus_parity --------------------------------"  << endl; }
    if (dpe_width != 0)
    {
        if (DEBUG_MSG) { cout << "bus_parity " << bus_parity  << endl; }

        if (DEBUG_MSG) { cout << "parity[" << b << "] " << parity[b]  << endl; }

        parity[b] = parity[b].substr(0, parity[b].size() - bus_parity.size()) +
                    bus_parity;

        if (DEBUG_MSG) { cout << "parity[" << b << "] " << parity[b]  << endl; }
    }
    if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
}

arm_uint32 transaction::bus_strobe(int data_bus_bytes, int b)
{
    arm_uint32 result = 0;
    for(int i=0; i<strobe[b].size(); i++)
    {
       result = (result << 1) | ((strobe[b][i] == '1' ) ? 1 : 0);
    }

    arm_uint32 number_bytes = 1 << size;
    if (number_bytes < data_bus_bytes)
    {
        arm_uint64 aligned_address = (address/number_bytes) * number_bytes;
        int first_byte_lane = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
        result = result << first_byte_lane;
    }
    return result;
}

arm_uint32 transaction::active_parity(int data_bus_bytes, int b)
{
//    if (DEBUG_MSG) { cout << "---- active_parity -------------------------------"  << endl; }
    arm_uint32 result = data_parity[b];

    arm_uint32 number_bytes = 1 << size;
    arm_uint32 mask = (1 << number_bytes) - 1;
    int first_byte_lane = lower_byte_lane(data_bus_bytes, b+1);
//    if (DEBUG_MSG) { cout << "first_byte_lane " << first_byte_lane  << endl; }
    result = (result >> first_byte_lane) & mask;

//    if (DEBUG_MSG) { cout << "result " << hex << result << dec  << endl; }
//    if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
    return result;
}

string transaction::beat_parity(int data_bus_bytes, int b)
{
    if (DEBUG_MSG) { cout << "---- beat_parity ---------------------------------"  << endl; }
    string result = "";

    if (dpe_width != 0)
    {
        arm_uint32 number_bytes = 1 << size;
        arm_uint32 mask = (1 << number_bytes) - 1;
        int first_byte_lane = lower_byte_lane(data_bus_bytes, b+1)/number_bytes*number_bytes;
        if (DEBUG_MSG) { cout << "parity[" << b << "] " << parity[b] << " first_byte_lane " << first_byte_lane  << endl; }

        if (parity[b].size() == 0) { parity[b] = string(dpe_width-1, '0'); }

        result = parity[b].substr(parity[b].size() - number_bytes - first_byte_lane, number_bytes);

        if (DEBUG_MSG) { cout << "result " << result  << endl; }
        if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
    }

    return result;
}

void transaction::extract_parity()
{
//   if (DEBUG_MSG) { cout << "---- extract_parity ------------------------------"  << endl; }
   // set up parity fields for each data beat
   parity_validity.reserve(length);
   data_parity.reserve(dpe_width);
   for (int b = 0; b < length; b++)
   {
       if (dpe_width != 0)
       {
           //extract parity string
           parity[b] = user[b].substr(256 - dpe_width, dpe_width - 1);

           //extract parity_validity from user[0]
           parity_validity[b] = (user[b][255] == '1' ) ? true : false; 

           //extract dpe_width-1 bits of parity from user[dpe_width:1]
//           cout << "user[" << b << "] = ";
           data_parity[b] = 0;
           for(int i=(256 - dpe_width); i<255; i++)
           {
//               cout << ((user[b][i] == '1' ) ? 1 : 0);
               data_parity[b] = (data_parity[b] << 1) | ((user[b][i] == '1' ) ? 1 : 0);
           }
//           if (DEBUG_MSG) { cout  << endl; }
//           if (DEBUG_MSG) { cout << "data_parity[" << b << "] = 0x" << hex << data_parity[b] << dec  << endl; }
       }
       else
       {
           parity_validity[b] = false;
           data_parity[b] = 0;
       }
   }
//   if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
}

void transaction::insert_parity(int data_bus_bytes)
{
    if (DEBUG_MSG) { cout << "---- insert_parity ------------------------------"  << endl; }
    if (dpe_width != 0)
    {
        arm_uint32 number_bytes = 1 << size;
        for (int b = 0; b < length; b++)
        {
            int first_byte_lane = (lower_byte_lane(data_bus_bytes, b+1)/number_bytes)*number_bytes;
            if (parity[b].size() == dpe_width-1)
            {
                first_byte_lane = 0;
            }
            if (DEBUG_MSG) { cout << "[" << b << "] first_byte_lane = " << (int)first_byte_lane << " parity[b] = " << parity[b] << endl; }
            user[b] = user[b].substr(0,256 - dpe_width);
            user[b] = user[b] + string((dpe_width-1) - (first_byte_lane + parity[b].size()), '1');
            user[b] = user[b] + parity[b];
            user[b] = user[b] + string(first_byte_lane,'1');
            user[b] = user[b] + ((parity_validity[b] & 1)?"1":"0");

            if (DEBUG_MSG) { cout << user[b]  << endl; }
        }

        //update the data_parity binary version
        extract_parity();
    }
    if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
}

void transaction::insert_data_parity(int parity_bits)
{
//   if (DEBUG_MSG) { cout << "---- insert_data_parity ------------------------------"  << endl; }

   int parity_bits_l = parity_bits;
   if (parity_bits_l == 0) {
       parity_bits_l = dpe_width-1;
   };
   
   if (dpe_width != 0)
   {
       for (int b = 0; b < length; b++)
       {
//           if (DEBUG_MSG) { cout << "data_parity[" << b << "] = " << hex << data_parity[b] << dec  << endl; }
           user[b][255] = (parity_validity[b]) ? '1' : '0';
           arm_uint32 mask = 1;
           for(int i=0; (i<parity_bits_l); i++)
           {
               user[b][254-i] = (data_parity[b] & mask) ? '1' : '0';
               mask = mask << 1;
           }
       }
   }
//   if (DEBUG_MSG) { cout << "--------------------------------------------------"  << endl; }
}

//------------------------------------------------------------------
//reset_timings
//------------------------------------------------------------------
void transaction::reset_timings() {

//clear all timings

    aemit_code = 0;
    await_code = 0;
    aemit_code_s = 0;
    await_code_s = 0;
    remit_code = 0;
    rwait_code = 0;
    remit_code_s = 0;
    rwait_code_s = 0;

    AVWait = 0;
    ARWait = 0;
    RVWait = 0;
    RRWait = 0;
    AVWait_s = 0;
    ARWait_s = 0;
    RVWait_s = 0;
    RRWait_s = 0;

    for (unsigned int i = 0; i < 256; i++)
    {

        DVWait[i] = 0;
        DRWait[i] = 0;
        DVWait_s[i] = 0;
        DRWait_s[i] = 0;

        demit_code[i] = 0;
        dwait_code[i] = 0;

        demit_code_s[i] = 0;
        dwait_code_s[i] = 0;
    }
}

//------------------------------------------------------------------
//reset_data
//------------------------------------------------------------------
void transaction::reset_data() {

    //clear all data and responses
    parity_validity.resize(256);  // ACB
    data_parity.resize(256);  // ACB
    parity.resize(256);  // DK
    strobe.resize(256);
    mask.resize(256);
    data.resize(256);
    bnumber.resize(256);
    resp.resize(256);
    user.resize(256);
    auser.resize(256);

    for (unsigned int i = 0; i < 256; i++)
    {
        user[i] = string(USER_MAX_WIDTH,'0');
        resp[i] = okay;
        parity[i] = "";  // DK
        strobe[i] = "";
        mask[i] = "";
        data[i] = "";
        bnumber[i] = "";
        auser[i] = string(NIC_AUSER_MAX_WIDTH,'0');
    }
}

//------------------------------------------------------------------
// number_bytes
//------------------------------------------------------------------
void transaction::number_bytes() {

     int number = 0;

     //Set the the bnumber strings accordin to the size of the transaction
     for (int len = 0; len < length; len ++) {

             ostringstream data_str;

             //for each byte in the beat
             for (int byte = (int)pow(2.0, (int)size) ; byte > 0; byte--) {

                 data_str << "b" << hex << setw(4) << setfill('0') << number + byte - 1;
             };

             //set in transaction
             bnumber[len] = data_str.str();

             number = number + (int)pow(2.0, (int)size);
     };
}

//------------------------------------------------------------------
// Tidy Transaction
// Ensure that transaction has the correct number of
// data, mask, strobe and parity beats
//------------------------------------------------------------------
void transaction::tidy() {

     int bytes = (int)pow(2.0, (int)size);

     //Set the the bnumber strings accordin to the size of the transaction
     for (int len = 0; len < length; len ++) {

             //Check the data ..
             if (data[len].size() > (bytes * 2)) {
                 data[len] = data[len].substr(data[len].size() - (bytes * 2), bytes * 2);
             } else {
                 data[len].resize(bytes * 2, '0');
             };

             //Check the mask
             if (mask[len].size() > (bytes * 2)) {
                 mask[len] = mask[len].substr(mask[len].size() - (bytes * 2), bytes * 2);
             } else {
                 mask[len].resize(bytes * 2, 'F');
             };

             //Check the strobe
             if (strobe[len].size() > bytes) {
               if (DEBUG_MSG) { cout<<"executing tidy() for strobes" << endl; }
               strobe[len] = strobe[len].substr(strobe[len].size() - bytes, bytes);
             } else {
               strobe[len].resize(bytes, '1');
             };
             // DK:start
             // Check the parity
             if (parity[len].size() > bytes) {
               if (DEBUG_MSG) { cout<<"executing tidy() for parity" << endl; }
               parity[len] = parity[len].substr(strobe[len].size() - bytes, bytes);
             } else {
               parity[len].resize(bytes, '1');
             };
             // DK:end
     };

     //Correct stobes to take account of address
     correct_strobes();
}

//------------------------------------------------------------------
//reset
//------------------------------------------------------------------

void transaction::reset(amba_direction read_n_wr) {

          //clear everything
          comment = "";
          location = "";
          final_dest = "external";
          dest_type = "memory";
          dest_sec = "nsec";
          valid = 0;
          region = 0;
          direction = read_n_wr;
          address = 0;
          id = 0;
          locked = nolock;
          unlocking = false;
          cache = 3;
          prot = 0;
          length = 1;
          size = size32;
          burst = axi_incr;
          ref = addr_id;
          check = eq;
          repeat = 1;
          qv = 0;
          vnet = 0;
          ruser = string(BUSER_MAX_WIDTH,'0');
          protocol = axi;
          dpe_width = 0;

          reset_timings();
          reset_data();

}

//------------------------------------------------------------------
//reset_data
//------------------------------------------------------------------
transaction::transaction(amba_direction read_n_write) {

          reset(read_n_write);
  }

//------------------------------------------------------------------
//address functions
//------------------------------------------------------------------
void transaction::address_rand() {

     address = (unsigned long long) rand();

     //Allign the address
     address_align();

}

void transaction::address_rand(unsigned long long addr_min, unsigned long long addr_max) {

     unsigned long long full_address;

     full_address = ((unsigned long long)rand() << 32) + (unsigned long long)rand();

     if (addr_min == addr_max) {
             address = addr_min;
     } else if (addr_min > addr_max) {
             address = full_address % (addr_min - addr_max) + addr_max;
     } else {
             address = full_address % (addr_max - addr_min) + addr_min;
     }

     //Allign the address
     address_align();

}

void transaction::address_align() {

    int offset;

    //Allign the address if it's a wrap or ahb trans
    if (burst >= 2 or protocol != axi) {
       offset = address % (unsigned long long)pow(2.0, (int)size);
       address = address - offset;
    };

    if (protocol == ahb) {
      //Check if burst will cross 1kb boundary .. if it will modify address
      //so it goes up to the 1k boundary
      offset = address % 0x400;
      if ((offset + (pow(2.0, (int)size) * (int)length)) > 0x400) {
        address = address - offset + (unsigned long long)(0x400 - (pow(2.0, (int)size) * (int)length));
      }
    } else {

      //Check if burst will cross 4kb boundary .. if it will modify address
      //so it goes up to the 4k boundary
      offset = address % 0x1000;
      if ((offset + (pow(2.0, (int)size) * (int)length)) > 0x1000) {
        address = address - offset + (unsigned long long)(0x1000 - (pow(2.0, (int)size) * (int)length));
      }
    }
    if (DEBUG_MSG) { cout<<"executing correct_strobes()"<<endl; }
    //correct_strobes
    correct_strobes();

}

void transaction::correct_strobes() {

    int offset;
    int beats = 1;

    //determine the address offset
    offset = address % ((unsigned long long)pow(2.0, (int)size));

    //determine number of beats to align
    if (burst == axi_fixed) {
            beats = length;
    };

    //unstobe unaligned data
    for(int beat=0; beat < beats; beat++) {
        for(int i=0; i < offset; i++) {
            strobe[beat].replace(strobe[beat].size()-1-i,1,"0");
            mask[beat].replace(mask[beat].size()-2-i-i,2,"00");
        };
    };

}



//------------------------------------------------------------------
// randomise -does not randomise direction
//------------------------------------------------------------------

void transaction::rand_cache() {

        //Randomise cache
        cache = rand() % 16;

        //IF cache[1] is 0 cache[2] and cache[3] must be as well
        if (cache % 4 < 2) {
                cache = rand() % 2;
        }
}

void transaction::randomise(unsigned long long addr_min, unsigned long long addr_max, amba_direction i_direction, amba_size i_size, arm_uint16 i_length, amba_burst i_burst) {

   try {
    if (DEBUG_MSG) { cout << "calling randomise" << endl; }

    ostringstream data_str;

    //check length is valid ... others valid by type
    assert(length >= 1 && length <= 256);

    //Clear transaction
    reset_timings();
    reset_data();

    //Set inputs
    direction = i_direction;
    length = i_length;
    size = i_size;
    burst = i_burst;

    //randomly generate the other values
    rand_cache();

    //prot cannot be
    prot = rand() % 8;

    locked = (amba_lock)(rand() % 3);

    int i;
    for (i = 0; i < length; i++) {

            //data
            for (int j = 0; j < (int)pow(2.0, (int)i_size); j++) {
                 data_str << setw(2) << setfill('0') << hex << (rand() % 256);
            };
            data[i] = data_str.str();
            data_str.str("");
            if (DEBUG_MSG) { cout << "data[i] is: " << data[i] << endl; }

            //Mask
            for (int j = 0; j < (int)pow(2.0, (int)i_size); j++) {
                 data_str << setw(2) << setfill('0') << hex << 255;
            };
            mask[i] = data_str.str();
            data_str.str("");

            //strobes
            for (int j = 0; j < (int)pow(2.0, (int)i_size); j++) {
               //no strobes on AHB
               if (burst < 3) data_str << rand() % 2;
               else data_str << "1";
            }
            strobe[i] = data_str.str();
            data_str.str("");

            // Parity
            if (DEBUG_MSG) { cout<< "inserting random parity" << endl; }
            // assume the maximum dpe_width (in the same ways as the max user width is assumed)
            for (int j = 0; j < 33; j++) {
               //no parity on AHB?
              if (burst < 3) data_str << rand() % 2;
              else data_str << "1";
            }
            if (DEBUG_MSG) { cout << "data_str.str() is: " << data_str.str() << endl; }
            user[i] = user[i].substr(0,user[i].length()-data_str.str().length()) + data_str.str();
            data_str.str("");
            if (DEBUG_MSG) { cout << "user[i] is: " << user[i] << endl; }

            //response
            if (burst < 3) {
                 //AXI
                 resp[i] = (amba_resp)(rand() % 4);
            } else {
                 resp[i] = (amba_resp)(rand() % (ahb_error + 1));
                 if (resp[i] > okay && resp[i] < ahb_error)
                      resp[i] = okay;
            }
    }

    //randomise the address
    address_rand(addr_min, addr_max);


   } catch ( const std::exception& ex ) {
           if (DEBUG_MSG) { cout << "Caught : " <<  ex.what()  << endl; }
   }

}
