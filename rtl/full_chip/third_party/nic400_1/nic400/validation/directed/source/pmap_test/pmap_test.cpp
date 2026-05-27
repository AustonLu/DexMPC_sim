

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
//  File Revision       : 54928
//  File Date           :  2008-09-15 14:42:07 +0100 (Mon, 15 Sep 2008)
//  
//  Release Information : PL401-r1p2-00rel0
//  
//-----------------------------------------------------------------------------
//  Purpose : All transaction types
//            
//  Descriptions : This test 
//
//==============================================================================#

//Include all the header files
#include "../../../../../shared/validation/c/include/PL301r2.h"

using namespace pl301_namespace;
using namespace arm_namespace;
using namespace frbm_namespace;
using namespace std;

int reg_test(pl301 &DUT, slave_port * current_master, unsigned long long base_address, int start_event) {

   unsigned int test_mask;     

   
   

   return start_event;
}

//main program
int main(int argc, char *argv[]) {

   //Instance PL301
   pl301 DUT(argv[1],argv[2]);
   
   //Iterators
   master_iter this_master;
   slave_iter this_slave;
   
   //transaction pointer
   transaction * trans;
   
   //name the test
   test_name = "pmap_test";    

   try {
   
   int init = 0;
   int start_event = 0;
   int req_remap_state = 0;

   

   }
   catch (const char * error) {
      cout << "Caught Error : " << error << endl;
   };

//Create test 
DUT.generate();
}
