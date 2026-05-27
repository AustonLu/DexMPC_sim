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
// Filename            : $RCSfile: arm_types.h,v $
// 
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
// 
// Revision            : 150004
// 
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------
#ifndef ARM_TYPES
#define ARM_TYPES

using namespace std;

namespace arm_namespace 
{

  typedef unsigned char arm_uint8;
  typedef int compilation_assert_arm_uint8[1/(sizeof(arm_uint8)==1)];

  typedef unsigned short arm_uint16;
  typedef int compilation_assert_arm_uint16[1/(sizeof(arm_uint16)==2)];

  typedef unsigned arm_uint32;
  typedef int compilation_assert_arm_uint32[1/(sizeof(arm_uint32)==4)];

  typedef unsigned long long arm_uint64;
  typedef int compilation_assert_arm_uint64[1/(sizeof(arm_uint64)==8)];

}

#endif

