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
// Filename            : $RCSfile: UtilityAhb.cpp,v $
//
// Checked In          :  2013-05-09 16:29:11 +0100 (Thu, 09 May 2013)
//
// Revision            : 150004
//
// Release Information : PL401-r1p2-00rel0
//
//---------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// Include files
//-------------------------------------------------------------------------

//-----------------------
// Standard include files

//-----------------------
// Device specific include files

#include "UtilityAhb.h"

//---------------------------------------------------------------------
// Constructor
//---------------------------------------------------------------------

UtilityAhb::UtilityAhb() : 
  Utility()
{
}

//---------------------------------------------------------------------
// Display functions
//---------------------------------------------------------------------
char *UtilityAhb::DisplayProt(amba_prot AProt, char *String)
{
  String[3] = '\0';
  String[4] = '\0';

  //Data/instruction
  if ((AProt & frbm_namespace::ahb_data) == frbm_namespace::ahb_data)
  {
    String[0] = 'D';
  } else
  {
    String[0] = 'I';
  }

  //Privileged/User
  if ((AProt & frbm_namespace::ahb_privileged) == frbm_namespace::ahb_privileged)
  {
    String[1] = 'P';
  } else
  {
    String[1] = 'p';
  }

  //Bufferable
  if ((AProt & frbm_namespace::ahb_bufferable) == frbm_namespace::ahb_bufferable)
  {
    String[2] = 'B';
  } else
  {
    String[2] = 'b';
  }

  //Cacheable
  if ((AProt & frbm_namespace::ahb_cacheable) == frbm_namespace::ahb_cacheable)
  {
    String[3] = 'C';
  } else
  {
    String[3] = 'c';
  }

  return(String);
}

char * UtilityAhb::DisplayCache(amba_cache ACache, char *String)
{
  switch (ACache)
  {
  }

  
  return("");
}


char * UtilityAhb::DisplayBurst(amba_length Length, amba_burst Burst)
{
  switch (Burst)
  {
    case axi_fixed:
      return("single");
    case axi_incr:
      switch (Length)
      {
        case 4:
          return("incr4");
        case 8:
          return("incr8");
        case 16:
          return("incr16");
        default: 
          return("incr");
      }
    case axi_wrap:
      switch (Length)
      {
        case 4:
          return("wrap4");
        case 8:
          return("wrap8");
        case 16:
          return("wrap16");
        default: 
          assert(0);
      }
    case ahb_single:
      return("single");
    case ahb_incr:
      return("incr");
    case ahb_incr4:
      return("incr4");
    case ahb_incr8:
      return("incr8");
    case ahb_incr16:
      return("incr16");
    case ahb_wrap4:
      return("wrap4");
    case ahb_wrap8:
      return("wrap8");
    case ahb_wrap16:
      return("wrap16");
    default:
      return("ERROR"); 
  }
}

char * UtilityAhb::DisplayResp(amba_resp Resp)
{
  switch (Resp)
  {
    case axi_okay:
      return("okay");
    case axi_exokay:
    case axi_slverr:
    case axi_decerr:
    case ahb_error:
      return("errcont");
    default:
      return("ERROR"); 
      
  }
}

//---------------------------------------------------------------------
// Conversion
//---------------------------------------------------------------------

//Generate next address
unsigned int UtilityAhb::NextAddress(unsigned int Address, amba_size Width, amba_burst Burst, 
  amba_length Length)
{
  return(0);
//  unsigned int TmpAddress;
//
//  switch (Burst)
//  {
//    case fixed:
//      return(Address);
//      break;
//    case incr:
//      TmpAddress = Address + (1 << Width);
//      return(TmpAddress);
//      break;
//    case wrap:
//
//      //Check
//
//      TmpAddress = (Address & ~(((1 << Width) * (Length)) - 1)) |
//        (
//          (
//            (Address + (1 << Width))
//          ) %
//          (
//            (1 << Width) * (Length) 
//          )
//        );
//
//      return(TmpAddress);
//      break;
//  }
//  return(Address);
}
//=======================================================================
// Check transaction
//=======================================================================

//Bursts must not go over burst boundary (4KB)
#define BURST_BOUNDARY 0xfff

bool UtilityAhb::CheckTransfer(arm_uint32 Address, amba_length Length, amba_size Size,
  amba_burst Burst, amba_lock Lock, amba_cache Cache,
  amba_prot Prot, bool Msg)
{
  return(1);

//  unsigned int StartAddress;
//  unsigned int EndAddress;
//  bool Flag = 1;
//
//  if (Length == 0)
//  {
//    if (Msg)
//      cerr << "Error: Illegal Length: 0" << endl;
//    Flag = 0;
//  }
//  if (Length > 16)
//  {
//    if (Msg)
//      cerr << "Error: Illegal Length: " << (int) Length << endl;
//    Flag = 0;
//  }
//  if (Cache > 16)
//  {
//    if (Msg)
//      cerr << "Error: Illegal Cache: " << (int) Cache << endl;
//    Flag = 0;
//  }
//  if (Cache > 8)
//  {
//    if (Msg)
//      cerr << "Error: Illegal Prot: " << (int) Prot << endl;
//    Flag = 0;
//  }
//
//
//  if (Burst == wrap)
//  {
//    //Check Wrapping burst length
//    if (!((Length == 2) || (Length == 4) ||
//        (Length == 8) || (Length == 16)))
//    {
//      if (Msg)
//        cerr << "Error: Illegal AHB Wrapping Burst Length: " << (int) Length << endl;
//      Flag = 0;
//    }
//    //Check Wrapping burst aligned to address boundary
//    if ((Address & (1 << Size - 1)) != 0)
//    {
//      if (Msg)
//        cerr << "Error: Illegal AHB Wrapping Burst.  Burst not aligned to boundary " << endl;
//      Flag = 0;
//    }
//
//  }
//
//  //Check burst doesn't cross 4KB boundary.
//  if (Burst == wrap)
//  {
//    EndAddress = Address | (Length * (1 << Size - 1));
//  } else if (Burst == incr)
//  {
//    EndAddress = Address + Length * Size;
//  }
//
//  if ((Burst == wrap) || (Burst == incr))
//  {
//    StartAddress = Address;
//
//    if ((StartAddress & ~BURST_BOUNDARY) != (EndAddress & ~BURST_BOUNDARY))
//    {
//      if (Msg)
//        cerr << "Error: Illegal AHB Burst overlaps burst boundary" << endl;
//      Flag = 0;
//    }
//  }
//
//  //Ensure Address is aligned to size 
//  if (Address & ((1<<Size) -1 ))
//    Flag = 0;
//
//  return(Flag);
}



