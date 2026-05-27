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
// Purpose: FRBM_TYPES
//
//---------------------------------------------------------------------------

#ifndef FRBM_TYPES_H
#define FRBM_TYPES_H

#include <iostream>
#include <vector>
#include <fstream>
#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <cassert>
#include <cstring>
#include <cstdlib>
#include <cmath>

#include "arm_types.h"

using namespace std;
using namespace arm_namespace;

#define LF 0x0A

#define PAGE_SIZE 4096

#define RW 0
#define RO 1
#define WO 2
#define NO_TEST 3

namespace frbm_namespace
{
  const int AUSER_MAX_WIDTH = 256;
  const int BUSER_MAX_WIDTH = 256;
  const int USER_MAX_WIDTH  = 256;
  const int NIC_AUSER_MAX_WIDTH = AUSER_MAX_WIDTH; // No need to add 16 bits for qv, region and valid_vector

  enum frbm_ref {
    addr_id,
    sync,
    addr,
    wfirst
  };

  enum frbm_quit {
    quit_emit,
    quit_stop,
    quit_idle
  };

  enum frbm_check {
    eq = 0,
    ne = 1
  };

  enum amba_wait {
    ahb_wait = 0,
    ahb_nowait = 1
  };

  enum amba_align {
    align = 0,
    unalign = 1
  };

  enum amba_transfer {
    ahb_idle   = 0,
    ahb_busy   = 1,
    ahb_nonseq = 2,
    ahb_seq    = 3
  };

  enum amba_cache_t {
    bufferable    = 1,
    cacheable     = 2,
    readallocate  = 4,
    writeallocate = 8
  };

  enum amba_prot_t {
    axi_secure      = 0,
    axi_privileged  = 1,
    axi_nonsecure   = 2,
    axi_instruction = 4,
    ahb_data        = 8,
    ahb_privileged  = 16, // AHB 2
    ahb_bufferable  = 32, // AHB 4
    ahb_cacheable   = 64  // AHB 8
  };

  enum amba_size {
    byte         = 0,
    size8        = 0,
    ahb_size8    = 0,
    axi_size8    = 0,
    half         = 1,
    size16       = 1,
    ahb_size16   = 1,
    axi_size16   = 1,
    size32       = 2,
    ahb_size32   = 2,
    axi_size32   = 2,
    word         = 2,
    size64       = 3,
    ahb_size64   = 3,
    axi_size64   = 3,
    dword        = 3,
    size128      = 4,
    ahb_size128  = 4,
    axi_size128  = 4,
    size256      = 5,
    ahb_size256  = 5,
    axi_size256  = 5,
    size512      = 6,
    ahb_size512  = 6,
    axi_size512  = 6,
    size1024     = 7,
    ahb_size1024 = 7,
    axi_size1024 = 7
  };

  enum amba_direction
  {
    read      = 0,
    rd        = 0,
    ahb_read  = 0,
    axi_read  = 0,
    write     = 1,
    wr        = 1,
    ahb_write = 1,
    axi_write = 1,
    sync_vec  = 2,
    comment   = 3
  };

  enum amba_burst
  {
    axi_fixed   = 0,
    axi_incr    = 1,
    axi_wrap    = 2,
    ahb_single  = 3,
    ahb_incr    = 4,
    ahb_wrap4   = 5,
    ahb_incr4   = 6,
    ahb_wrap8   = 7,
    ahb_incr8   = 8,
    ahb_wrap16  = 9,
    ahb_incr16  = 10,

    //more common use .. where the program decides on protocol
    incr       = 11,
    wrap       = 12
  };

  enum amba_lock
  {
    nolock     = 0,
    ahb_nolock = 0,
    axi_nolock = 0,
    lock       = 2,
    axi_lock   = 2,
    ahb_lock   = 2,
    axi_excl   = 1
  };

  enum amba_resp
  {
    okay       = 0,
    axi_okay   = 0,
    ahb_okay   = 0,
    axi_exokay = 1,
    axi_slverr = 2,
    axi_decerr = 3,
//    axi_ignore = 4,
    ahb_error  = 5 //AHB error = 1
  };

  enum protocol_t
  {
    axi  = 1,
    apb  = 2,
    ahb  = 3,
    axi4 = 4,
    apb4 = 5
  };

  typedef arm_uint8 amba_cache;
  typedef arm_uint8 amba_prot;
  typedef arm_uint16 amba_length;     //Length 1..256
  typedef arm_uint8 frbm_repeat;
  typedef arm_uint32 amba_strobe;
  typedef arm_uint32 amba_parity;
  typedef arm_uint32 amba_mask;
  typedef unsigned long long amba_address;

  class transaction
  {
     public :
      int dpe_width;
      int mif_width;
      int sif_width;

      //comment
      string comment;

      //location
      string location;
      string final_dest;

      string dest_type;
      string dest_sec;

      //protocol
      protocol_t  protocol;

      //Valid vectors
      int valid;
      int region;

      //Normal Signals
      amba_direction direction;
      amba_lock      locked;
      amba_cache     cache;
      amba_prot      prot;
      amba_length    length;
      amba_size      size;
      arm_uint32     id;
      amba_burst     burst;
      arm_uint64     address;
      arm_uint8      qv;
      arm_uint8      vnet;
      vector<string> auser;
      string         ruser;

      //Unlocking transaction
      bool          unlocking;

      //Data and response
      vector<string> data;
      vector<string> mask;
      vector<string> strobe;
      vector<amba_resp>  resp;
      vector<string> user;
      vector<string> parity;

      vector<amba_parity> data_parity;
      vector<bool>        parity_validity;

      //The byte number string is a string of byte numbers included in the transaction
      //(in the form b01 -> bxx). This allows responses to be corrected across an
      //infrastructure.
      vector<string> bnumber;

      //Timing
      frbm_ref       ref;
      //Wait values for master
      arm_uint32     ARWait;
      arm_uint32     AVWait;
      arm_uint32     DRWait[256];
      arm_uint32     DVWait[256];
      arm_uint32     RRWait;
      arm_uint32     RVWait;
      //Wait values for slave
      arm_uint32     ARWait_s;
      arm_uint32     AVWait_s;
      arm_uint32     DRWait_s[256];
      arm_uint32     DVWait_s[256];
      arm_uint32     RRWait_s;
      arm_uint32     RVWait_s;

      //Emit and wait codes for the generating master
      arm_uint32     aemit_code;
      arm_uint32     await_code;
      arm_uint32     demit_code[256];
      arm_uint32     dwait_code[256];
      arm_uint32     remit_code;
      arm_uint32     rwait_code;

      //Emit and wait code for the slave
      arm_uint32     aemit_code_s;
      arm_uint32     await_code_s;
      arm_uint32     demit_code_s[256];
      arm_uint32     dwait_code_s[256];
      arm_uint32     remit_code_s;
      arm_uint32     rwait_code_s;

      //misc
      arm_uint8      addr_width;
      arm_uint8      id_width;
      int            awuser_width;
      int            aruser_width;
      int            wuser_width;
      arm_uint8      buser_width;
      arm_uint8      ruser_width;
      arm_uint8      data_width;
      frbm_check     check;
      frbm_repeat    repeat;

      //Useful transaction functions
      void randomise(unsigned long long addr_min, unsigned long long addr_max, amba_direction direction, amba_size i_size, arm_uint16 i_length, amba_burst i_burst);
      void rand_cache();
      void address_rand();
      void correct_strobes();
      void address_rand(unsigned long long addr_min, unsigned long long addr_max);
      void address_align();
      void number_bytes();

      int lower_byte_lane(int data_bus_bytes, int N);
      int upper_byte_lane(int data_bus_bytes, int N);

      string full_bus_data(int data_bus_bytes, int b);
      string full_bus_strobe(int data_bus_bytes, int b);
      string full_bus_parity(int data_bus_bytes, int b);

      void put_bus_data(int data_bus_bytes, int b, string bus_data);
      void put_bus_parity(int b, string bus_parity);

      arm_uint32 bus_strobe(int data_bus_bytes, int b);
      arm_uint32 active_parity(int data_bus_bytes, int b);
      string beat_parity(int data_bus_bytes, int b);

      void extract_parity();
      void insert_parity(int data_bus_bytes);
      void insert_data_parity(int parity_len = 0);

      //reset timing and events
      void reset_timings();
      void reset_data();
      void reset(amba_direction read_n_wr);

      //tidy function to ensure that the data and mask functions are correct
      void tidy();

      //constructor
      transaction(amba_direction read_n_wr=read);
    };

  ostream& operator<< (ostream&, frbm_quit);
  ostream& operator<< (ostream&, frbm_ref);
  ostream& operator<< (ostream&, frbm_check);
  ostream& operator<< (ostream&, amba_align);
  ostream& operator<< (ostream&, amba_wait);
  ostream& operator<< (ostream&, amba_transfer);
  ostream& operator<< (ostream&, amba_direction);
  ostream& operator<< (ostream&, amba_lock);
  ostream& operator<< (ostream&, amba_size);
  ostream& operator<< (ostream&, amba_burst);
  ostream& operator<< (ostream&, amba_resp);
  ostream& operator<< (ostream&, amba_length);
  ostream& operator<< (ostream&, transaction);
}
#endif
