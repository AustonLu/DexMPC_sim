

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
// Filename            : $RCSfile: DriveAxiPv.h,v $
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
//
// Purpose: Definition of the PL301 configuration
//
//---------------------------------------------------------------------------


#include <stdlib.h>
#include <map>
#include <vector>
#include <deque>
#include <string>
#include <sstream>
#include <math.h>

#include "arm_types.h"
#include "frbm_types.h"
#include "Register_map.h"
#include "System.h"
#include "Dom.h"

#ifndef PL301R2_H
#define PL301R2_H

using namespace std;
using namespace arm_namespace;
using namespace frbm_namespace;

namespace pl301_namespace
{

  enum cds_type
  {
    singleslave = 0,
    slaveperid  = 1
  };

  enum protocol_type
  {
    axi = 0,
    ahb = 1,
    apb = 2
  };


  //address range
  class addr_range
  {
      public:

      arm_uint64 addr_min;
      arm_uint64 addr_max;
      string master_port;
      int valid;
      int region;
      int vn;
      string trustzone;
      string infra_mi_no;
      string multi_region;
      int valid_base;
      string present;
  };

  //master contains all the parameters about each master_port
  class master_port
  {
      public:
     
      //Name of the master_port    
      string name;

      //name of the XVC
      string xvc_name;

      //Name of the testbench component
      string xml;

      //parameters of the port
      Node * parameters;

      //Port number
      int number;

      //Vector of transactions
      deque<transaction> transactions;

      //Protocol
      protocol_type protocol;

      //Comment place holder
      string comment;
  };

  //slave contains all the parameters about each slave_port
  class slave_port
  {
      public :
       
      //Name of the slave
      string name;

      //Name of the XVC
      string xvc_name;

      //Name of the testbench component
      string xml;

      //Name of the remap register
      string remap_reg;

      //parameters of the port
      Node * parameters;

      //Address region information
      Node * addr_map;

      //Port number
      int number;

      //Vector of transactions
      deque<transaction> transactions;

      //Protocol
      protocol_type protocol;

      //Comment place holders
      string comment;
      string comment_m;

     
  };

  //tb contains all the parameters about other tbench components
  class tb
  {
      public :
       
      //Name of the slave
      string name;

      //Name of the testbench component
      string xml;

      //Port number
      int number;

  };

  class pl301
  {
       
       public:

       //Model of the PL301 system (Separated)
       System Sys;

       //All the slave accessible by name
       map<string, slave_port>  slave_ports;

       //All the masters accessible by name
       map<string, master_port> master_ports;

       //All the tb_componets accessible by name
       map<string, tb> tb_comps;

       //Register map in the testbench
       Register_map tb_regs; 

       //Transactions for the testbench
       string tb_comment;
       deque<transaction> transactions;

       //Defines map
       map<string,string> defines;

       //Configuration Master
       slave_port                     config;
       string                         cfg_master_name;

       //DOM Reader
       Dom DomReader;

       //constructors
       pl301(char * filename, char * top_level);
       pl301();

       //initialisation and generation routines
       bool initalise(char * filename, char * top_level);
       bool read_config(char * filename);
       bool read_defines(char * filename);
       bool generate();
       bool generate_tsf();

       // -----------------------------------------------------------------------------------------
       //  Read functions
       // -----------------------------------------------------------------------------------------
       void read(unsigned long long address, int data, int mask, int id=0, int emit=0, int wait=0, bool secure=false);
       void read(slave_port * target_slave, unsigned long long address, int data, int mask, int id=0, int emit=0, int wait=0, bool secure=false);
       void read(master_port * target_master, unsigned long long address, int data, int mask, int id=0, int emit=0, int wait=0, bool secure=false);
       void read(slave_port * target_slave, master_port * target_master, unsigned long long address, int data, int mask, int id=0, int emit=0, int wait=0, bool secure=false);
  
       void read(transaction this_trans);
       void read(slave_port * target_slave, transaction this_trans);
       void read(master_port * target_master, transaction this_trans);
       void read(slave_port * target_slave, master_port * target_master, transaction this_trans);

       // -----------------------------------------------------------------------------------------
       //  Write functions
       // -----------------------------------------------------------------------------------------       
       void write(unsigned long long address, int data, int strobes, int id=0, int emit=0, int wait=0, bool secure=false);
       void write(slave_port * target_slave, unsigned long long address, int data, int strobes, int id=0, int emit=0, int wait=0, bool secure=false);
       void write(master_port * target_master, unsigned long long address, int data, int strobes, int id=0, int emit=0, int wait=0, bool secure=false);
       void write(slave_port * target_slave, master_port * target_master, unsigned long long address, int data, int strobes, int id=0, int emit=0, int wait=0, bool secure=false);
       
       void write(transaction this_trans);
       void write(slave_port * target_slave, transaction this_trans);
       void write(master_port * target_master, transaction this_trans);
       void write(slave_port * target_slave, master_port * target_master, transaction this_trans);
  
       // -----------------------------------------------------------------------------------------
       //  GP access functions
       // -----------------------------------------------------------------------------------------       
       void access(transaction this_trans);
       void access(slave_port * target_slave, transaction this_trans);
       void access(master_port * target_master, transaction this_trans);
     
       // -----------------------------------------------------------------------------------------
       //  Comment functions
       // -----------------------------------------------------------------------------------------
       void comment(string comm);
       void comment(slave_port * target_slave, string comm);
       void comment(master_port * target_master, string comm);
       void comment_m(string comm);

       // -----------------------------------------------------------------------------------------
       //  Sync functions
       // -----------------------------------------------------------------------------------------
       void sync();
       void sync_cfg();
       void sync(slave_port * target_slave);
       void sync(master_port * target_master);
       void sync_all();

       // -----------------------------------------------------------------------------------------
       //  is_path functions
       // -----------------------------------------------------------------------------------------
       bool is_path(int valid_bit = 0, bool secure = true);
       bool is_path(slave_port * source_slave, int valid_bit = 0, bool secure = true);
       bool is_path(master_port * target_master, int valid_bit = 0, bool secure = true);
       bool is_path(slave_port * source_slave, master_port * target_master, int valid_bit = 0, bool secure = true);
       bool is_path(vector<addr_range *> * c_addr_map, slave_port * source_slave, master_port * target_master, int valid_bit = 0);

       // -----------------------------------------------------------------------------------------
       //  latency access functions
       // -----------------------------------------------------------------------------------------
       int latency(string channel);
       int latency(slave_port * source_slave, string channel);
       int latency(master_port * target_master, string channel);
       int latency(slave_port * source_slave, master_port * target_master, string channel);

       // -----------------------------------------------------------------------------------------
       //  depth access functions
       // -----------------------------------------------------------------------------------------
       int depth(string channel);
       int depth(slave_port * source_slave, string channel);
       int depth(master_port * target_master, string channel);
       int depth(slave_port * source_slave, master_port * target_master, string channel);

       bool master_regs(string channel);
       bool master_regs(slave_port * source_slave, string channel);
       bool master_regs(master_port * target_master_port, string channel);
       bool master_regs(slave_port * source_slave, master_port * target_master_port, string channel);
       // -----------------------------------------------------------------------------------------
       //  address  functions
       // -----------------------------------------------------------------------------------------
       unsigned long long address_range(slave_port * source_slave, master_port * target_master_port, int valid_bit=0, bool secure = true);
       void address_offset(slave_port * source_slave, master_port * target_master_port, transaction * trans);
       vector<addr_range *> get_address_map(slave_port * source_slave, bool secure = true, bool get_all = false);
       void set_vnet(slave_port * source_slave, transaction * trans);
       void rev_vnet(slave_port * source_slave, transaction * trans);

       // -----------------------------------------------------------------------------------------
       //  Comment functions
       // -----------------------------------------------------------------------------------------
       void tb_read(slave_port * target_slave, string reg, string field, int value, int id=0, int emit=0, int wait=0, string comment="");
       void tb_read(master_port * target_master, string reg, string field, int value, int id=0, int emit=0, int wait=0, string comment="");
       void tb_read(string name, string reg, string field, int value, int id=0, int emit=0, int wait=0, string comment="");
       void tb_read(string name, int addr, int value, int mask, int id=0, int emit=0, int wait=0, string comment="");
  
       void tb_write(slave_port * target_slave, string reg, string field, int value, int id=0, int emit=0, int wait=0, string comment="");
       void tb_write(master_port * target_master, string reg, string field, int value,int id=0, int emit=0, int wait=0, string comment="");
       void tb_write(string name, string reg, string field, int value, int id=0, int emit=0, int wait=0, string comment="");
       void tb_write(string name, int addr, int value, int strb, int id=0, int emit=0, int wait=0, string comment="");

       // -----------------------------------------------------------------------------------------
       //  Randomising functions functions
       // -----------------------------------------------------------------------------------------
       void randomise(frbm_namespace::transaction * trans,  frbm_namespace::amba_direction direction = rd, frbm_namespace::amba_size size = size32, amba_length length = 1, frbm_namespace::amba_burst burst = ahb_incr, bool secure = true);
       void randomise(master_port * target_master, frbm_namespace::transaction * trans,  frbm_namespace::amba_direction direction = rd, frbm_namespace::amba_size size = size32, amba_length length = 1, frbm_namespace::amba_burst burst = ahb_incr, bool secure = true);
       void randomise(slave_port * target_slave, frbm_namespace::transaction * trans,  frbm_namespace::amba_direction direction = rd, frbm_namespace::amba_size size = size32, amba_length length = 1, frbm_namespace::amba_burst burst = ahb_incr, bool secure = true);
       void randomise(slave_port * target_slave, master_port * target_master, frbm_namespace::transaction * trans,  frbm_namespace::amba_direction direction = rd, frbm_namespace::amba_size size = size32, amba_length length = 1, frbm_namespace::amba_burst burst = ahb_incr, bool secure = true);

       // -----------------------------------------------------------------------------------------
       //  RSB functions
       // -----------------------------------------------------------------------------------------
       slave_port * get_rsb_master();
       unsigned long long get_rsb_address(slave_port * this_slave_port);
       int get_rsb_vnet(slave_port * this_slave_port);


  };

  //useful typedefs
  typedef map<string, slave_port>::iterator master_iter;
  typedef map<string, master_port>::iterator slave_iter;
  typedef map<string, tb>::iterator tb_iter;

  //pointer to the current master_port and slave
  extern master_port * current_slave;
  extern slave_port * current_master;

  //Test Name
  extern string test_name;
  extern string external_cfg_width;

  extern pl301 * DUT;

 
}

// -----------------------------------------------------------------------------------------
//  Pointer access functions
// -----------------------------------------------------------------------------------------

pl301_namespace::slave_port get_master(pl301_namespace::master_iter master_iterator);
pl301_namespace::slave_port * get_master_p(pl301_namespace::master_iter master_iterator);
pl301_namespace::master_port get_slave(pl301_namespace::slave_iter slave_iterator);
pl301_namespace::master_port * get_slave_p(pl301_namespace::slave_iter slave_iterator);
pl301_namespace::tb get_tb(pl301_namespace::tb_iter tb_iterator);
pl301_namespace::tb * get_tb_p(pl301_namespace::tb_iter tb_iterator);

// -----------------------------------------------------------------------------------------
//  Convertion functions
// -----------------------------------------------------------------------------------------
amba_size to_amba_size(string size);
string to_string(arm_uint64 data);
string to_string(arm_uint32 data, uint bits);
string to_string_dec(arm_uint64 data);
string to_string_in_binary(arm_uint32 data, uint length); 

// -----------------------------------------------------------------------------------------
//  Parmeter access functions
// -----------------------------------------------------------------------------------------
bool def_s_param(string param_name);
bool def_m_param(string param_name);

bool def_s_param(pl301_namespace::master_port * target_master, string param_name);
bool def_m_param(pl301_namespace::slave_port * target_slave, string param_name);

int s_param(string param_name);
unsigned long s_param_l(string param_name);
string s_param_s(string param_name);

int m_param(string param_name);
unsigned long m_param_l(string param_name);
string m_param_s(string param_name);

int param(pl301_namespace::master_port * target_master, string param_name);
unsigned long param_l(pl301_namespace::master_port * target_master, string param_name);
string param_s(pl301_namespace::master_port * target_master, string param_name);

int param(pl301_namespace::slave_port * target_slave, string param_name);
unsigned long param_l(pl301_namespace::slave_port * target_slave, string param_name);
string param_s(pl301_namespace::slave_port * target_slave, string param_name);




#endif

