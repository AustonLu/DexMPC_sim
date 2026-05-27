

//==============================================================================#
//   The confidential and proprietary information contained in this file may
//   only be used by a person authorised under and to the extent permitted
//   by a subsisting licensing agreement from ARM Limited.
//    (C) COPYRIGHT 2008-2013 ARM Limited.
//        ALL RIGHTS RESERVED
//   This entire notice must be reproduced on all copies of this file
//   and copies of this file may only be made by a person if such person is
//   permitted to do so under the terms of a subsisting license agreement
//   from ARM Limited.
//  
//-----------------------------------------------------------------------------
//  Version and Release Control Information:
//  
//  File Revision       : 50638
//  File Date           :  2008-14-10 21:08:37 +0100 (Thu, 09 Oct 2008)
//  
//  Release Information : PL401-r1p2-00rel0
//  
//-----------------------------------------------------------------------------
//  Purpose : Example test for the c vector generation
//
//  Description: Check that the right targets are accessed for 
//               different values of remap
//
//               The test is repeated from every slave_if to each master_if
//               (if a path exists)
//
//               All transactions should be secure in this case
//            
//==============================================================================#
#include "../../../../../shared/validation/c/include/PL301r2.h"

using namespace pl301_namespace;
using namespace arm_namespace;
using namespace frbm_namespace;
using namespace std;


   

int test_sD2dData(pl301 &DUT, slave_port * port, unsigned long long address, int remap, int sec, int start_event) 
{

     
     
     //Enable for subspaceMap_0_0x0_sD2dData_state_default
     bool subspaceMap_0_0x0_sD2dData_state_default = 
         (address >= 0x0 & address <= 0x7FFFF);
     
     //Enable for subspaceMap_0_0x80000_sD2dData_state_default
     bool subspaceMap_0_0x80000_sD2dData_state_default = 
         (address >= 0x80000 & address <= 0xFFFFF);
     

     //Determine if there was a match
     if (subspaceMap_0_0x0_sD2dData_state_default |
             subspaceMap_0_0x80000_sD2dData_state_default) {

         //Match to real location so send   
         DUT.write(port, NULL, address, rand(), 0x1111, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, rand(), 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

     } else {

         //Default slave access override to decerr
         DUT.write(port, NULL, address, 0, 0x1111, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, 0, 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;
     };

     return start_event;
};

int test_sD2dData(pl301 &DUT, int start_event, int remap)
{


  //Set the current master
  current_master = &(DUT.slave_ports["sD2dData"]);

  //Get the current rsb_master
  slave_port * rsb_master;
  rsb_master = DUT.get_rsb_master();
  bool secure = false;
  int  sec_reg = 0;
  int sec = 0;

  //Now test every address connection that is present in the current remap

      

  DUT.comment(current_master, "Testing 0x0 remap is " + to_string(remap));
  

         if (0x0 > 4) {
             start_event = test_sD2dData(DUT, current_master, 0x0 - 4, remap, sec, start_event);
         }
         start_event = test_sD2dData(DUT, current_master, 0x0, remap, sec, start_event);
         start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x0 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x0 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x0 + 0x80000) - 1) {
            start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x0 + 0x80000), remap, sec, start_event);
         }
      

  DUT.comment(current_master, "Testing 0x80000 remap is " + to_string(remap));
  

         if (0x80000 > 4) {
             start_event = test_sD2dData(DUT, current_master, 0x80000 - 4, remap, sec, start_event);
         }
         start_event = test_sD2dData(DUT, current_master, 0x80000, remap, sec, start_event);
         start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x80000 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x80000 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x80000 + 0x80000) - 1) {
            start_event = test_sD2dData(DUT, current_master, ((unsigned long long)0x80000 + 0x80000), remap, sec, start_event);
         }
  
  return start_event;

};

   

int test_sIrisBridge(pl301 &DUT, slave_port * port, unsigned long long address, int remap, int sec, int start_event) 
{

     
     
     //Enable for subspaceMap_0_0x0_sIrisBridge_state_default
     bool subspaceMap_0_0x0_sIrisBridge_state_default = 
         (address >= 0x0 & address <= 0x7FFFF);
     
     //Enable for subspaceMap_0_0x80000_sIrisBridge_state_default
     bool subspaceMap_0_0x80000_sIrisBridge_state_default = 
         (address >= 0x80000 & address <= 0xFFFFF);
     

     //Determine if there was a match
     if (subspaceMap_0_0x0_sIrisBridge_state_default |
             subspaceMap_0_0x80000_sIrisBridge_state_default) {

         //Match to real location so send   
         DUT.write(port, NULL, address, rand(), 0x1111, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, rand(), 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

     } else {

         //Default slave access override to decerr
         DUT.write(port, NULL, address, 0, 0x1111, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, 0, 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;
     };

     return start_event;
};

int test_sIrisBridge(pl301 &DUT, int start_event, int remap)
{


  //Set the current master
  current_master = &(DUT.slave_ports["sIrisBridge"]);

  //Get the current rsb_master
  slave_port * rsb_master;
  rsb_master = DUT.get_rsb_master();
  bool secure = false;
  int  sec_reg = 0;
  int sec = 0;

  //Now test every address connection that is present in the current remap

      

  DUT.comment(current_master, "Testing 0x0 remap is " + to_string(remap));
  

         if (0x0 > 4) {
             start_event = test_sIrisBridge(DUT, current_master, 0x0 - 4, remap, sec, start_event);
         }
         start_event = test_sIrisBridge(DUT, current_master, 0x0, remap, sec, start_event);
         start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x0 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x0 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x0 + 0x80000) - 1) {
            start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x0 + 0x80000), remap, sec, start_event);
         }
      

  DUT.comment(current_master, "Testing 0x80000 remap is " + to_string(remap));
  

         if (0x80000 > 4) {
             start_event = test_sIrisBridge(DUT, current_master, 0x80000 - 4, remap, sec, start_event);
         }
         start_event = test_sIrisBridge(DUT, current_master, 0x80000, remap, sec, start_event);
         start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x80000 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x80000 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x80000 + 0x80000) - 1) {
            start_event = test_sIrisBridge(DUT, current_master, ((unsigned long long)0x80000 + 0x80000), remap, sec, start_event);
         }
  
  return start_event;

};

   

int test_sSpi(pl301 &DUT, slave_port * port, unsigned long long address, int remap, int sec, int start_event) 
{

     
     
     //Enable for subspaceMap_0_0x0_sSpi_state_default
     bool subspaceMap_0_0x0_sSpi_state_default = 
         (address >= 0x0 & address <= 0x7FFFF);
     
     //Enable for subspaceMap_0_0x80000_sSpi_state_default
     bool subspaceMap_0_0x80000_sSpi_state_default = 
         (address >= 0x80000 & address <= 0xFFFFF);
     

     //Determine if there was a match
     if (subspaceMap_0_0x0_sSpi_state_default |
             subspaceMap_0_0x80000_sSpi_state_default) {

         //Match to real location so send   
         DUT.write(port, NULL, address, rand(), 0x1111, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, rand(), 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         start_event++;

     } else {

         //Default slave access override to decerr
         DUT.write(port, NULL, address, 0, 0x1111, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;

         //Read from one below the base address
         DUT.read(port, NULL, address, 0, 0xffffffff, 0, start_event + 1, start_event, (sec == 0));
         if ((*port).transactions.back().protocol == 1) {
             (*port).transactions.back().resp[0] = axi_decerr;
         } else {
             (*port).transactions.back().resp[0] = ahb_error;
         }
         start_event++;
     };

     return start_event;
};

int test_sSpi(pl301 &DUT, int start_event, int remap)
{


  //Set the current master
  current_master = &(DUT.slave_ports["sSpi"]);

  //Get the current rsb_master
  slave_port * rsb_master;
  rsb_master = DUT.get_rsb_master();
  bool secure = false;
  int  sec_reg = 0;
  int sec = 0;

  //Now test every address connection that is present in the current remap

      

  DUT.comment(current_master, "Testing 0x0 remap is " + to_string(remap));
  

         if (0x0 > 4) {
             start_event = test_sSpi(DUT, current_master, 0x0 - 4, remap, sec, start_event);
         }
         start_event = test_sSpi(DUT, current_master, 0x0, remap, sec, start_event);
         start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x0 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x0 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x0 + 0x80000) - 1) {
            start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x0 + 0x80000), remap, sec, start_event);
         }
      

  DUT.comment(current_master, "Testing 0x80000 remap is " + to_string(remap));
  

         if (0x80000 > 4) {
             start_event = test_sSpi(DUT, current_master, 0x80000 - 4, remap, sec, start_event);
         }
         start_event = test_sSpi(DUT, current_master, 0x80000, remap, sec, start_event);
         start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x80000 + ((0x80000) >> 1)), remap, sec, start_event);
         start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x80000 + 0x80000 - 4), remap, sec, start_event);
         if (0x31 > ((unsigned long long)0x80000 + 0x80000) - 1) {
            start_event = test_sSpi(DUT, current_master, ((unsigned long long)0x80000 + 0x80000), remap, sec, start_event);
         }
  
  return start_event;

};



//main program
int main(int argc, char *argv[])
{
    //Instance PL301
    pl301 DUT(argv[1],argv[2]);

    //transactions
    transaction * trans;
    
    //define an iterator for the master ports
    master_iter this_master;

    //define an interator for the slave ports
    slave_iter this_slave;
    //name the test - used later for the tsf file
    test_name = "addr_map";
    
    // rsb master for changing remap states
    slave_port * rsb_master;

    //Start event
    int start_event = 0;
    int remap_val = 0;

    
        // Test port sD2dData
        start_event = test_sD2dData(DUT, start_event, remap_val);
    
        // Test port sIrisBridge
        start_event = test_sIrisBridge(DUT, start_event, remap_val);
    
        // Test port sSpi
        start_event = test_sSpi(DUT, start_event, remap_val);
    

    DUT.generate();
}
