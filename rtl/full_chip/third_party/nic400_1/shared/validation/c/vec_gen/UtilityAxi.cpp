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
// Filename            : $RCSfile: UtilityAxi.cpp,v $
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

// Device specific include files

#include "UtilityAxi.h"

//---------------------------------------------------------------------
// Constructor
//---------------------------------------------------------------------

UtilityAxi::UtilityAxi() : 
  Utility()
{
}

//---------------------------------------------------------------------
// Display functions
//---------------------------------------------------------------------
char *UtilityAxi::DisplayProt(amba_prot AProt, char *String)
{
  String[3] = '\0';
  
  //Privileged/User
  if ((AProt & frbm_namespace::axi_privileged) == frbm_namespace::axi_privileged)
  {
    String[0] = 'P';
  } else
  { 
    String[0] = 'u';
  } 
  
  //Secure/Nonsecure
  if ((AProt & frbm_namespace::axi_nonsecure) == frbm_namespace::axi_nonsecure)
  {
    String[1] = 's';
  } else
  {
    String[1] = 'S';
  }

  //Instruction/Data
  if ((AProt & frbm_namespace::axi_instruction) == frbm_namespace::axi_instruction)
  {
    String[2] = 'I';
  } else
  {
    String[2] = 'D';
  }

  return(String);
}

char * UtilityAxi::DisplayCache(amba_cache ACache, char *String)
{

  //Bufferable/NonBufferable
  if ((ACache & frbm_namespace::bufferable) == frbm_namespace::bufferable)
  {
    String[0] = 'B';
  } else
  {
    String[0] = 'b';
  }

  //Cacheable/NonCacheable
  if ((ACache & frbm_namespace::cacheable) == frbm_namespace::cacheable)
  {
    String[1] = 'C';
  } else
  {
    String[1] = 'c';
  }

  //Read allocate/No read allocate
  if ((ACache & frbm_namespace::readallocate) == frbm_namespace::readallocate)
  {
    String[2] = 'R';
  } else
  {
    String[2] = 'r';
  }

  //Write allocate/No write allocate
  if ((ACache & frbm_namespace::writeallocate) == frbm_namespace::writeallocate)
  {
    String[3] = 'W';
  } else
  {
    String[3] = 'w';
  }

  String[4] = '\0';

  return(String);
}

char * UtilityAxi::DisplayBurst(amba_length Length, amba_burst Burst)
{
  switch (Burst)
  {
    case axi_fixed:
      return("fixed");

    case axi_incr:
    case ahb_single:
    case ahb_incr4:
    case ahb_incr8:
    case ahb_incr16:
      return("incr");

    case axi_wrap:
    case ahb_wrap4:
    case ahb_wrap8:
    case ahb_wrap16:
      return("wrap");
    default:
      return("ERROR");
  }
}

//---------------------------------------------------------------------
// Conversion
//---------------------------------------------------------------------

//Generate next address
unsigned int UtilityAxi::NextAddress(unsigned int Address, amba_size Width, amba_burst Burst, 
  amba_length Length)
{
  unsigned int TmpAddress;

  switch (Burst)
  {
    case axi_fixed:
      return(Address);
      break;
    case axi_incr:
      TmpAddress = Address + (1 << Width);
      return(TmpAddress);
      break;
    case axi_wrap:

      //Check

      TmpAddress = (Address & ~(((1 << Width) * (Length)) - 1)) |
        (
          (
            (Address + (1 << Width))
          ) %
          (
            (1 << Width) * (Length) 
          )
        );

      return(TmpAddress);
      break;
    default:
      return(Address);
  }
  return(Address);
}
//=======================================================================
// Check transaction
//=======================================================================

//Bursts must not go over burst boundary (4KB)
#define BURST_BOUNDARY 0xfff

bool UtilityAxi::CheckTransfer(arm_uint32 Address, amba_length Length, amba_size Size,
  amba_burst Burst, amba_lock Lock, amba_cache Cache,
  amba_prot Prot, bool Msg)
{
  unsigned int StartAddress;
  unsigned int EndAddress;
  bool Flag = 1;

  if (Length == 0)
  {
    if (Msg)
      cerr << "Error: Illegal Length: 0" << endl;
    Flag = 0;
  }
  if (Length > 256)
  {
    if (Msg)
      cerr << "Error: Illegal Length: " << (int) Length << endl;
    Flag = 0;
  }
  if (Cache > 16)
  {
    if (Msg)
      cerr << "Error: Illegal Cache: " << (int) Cache << endl;
    Flag = 0;
  }

  if (Burst == axi_wrap)
  {
    //Check Wrapping burst length
    if (!((Length == 2) || (Length == 4) ||
        (Length == 8) || (Length == 16)))
    {
      if (Msg)
        cerr << "Error: Illegal AXI Wrapping Burst Length: " << (int) Length << endl;
      Flag = 0;
    }
    //Check Wrapping burst aligned to address boundary
    if ((Address % (arm_uint32)pow(2.0, (int)Size)) != 0)
    {
      if (Msg) {
        cerr << "Error: Illegal AXI Wrapping Burst.  Burst not aligned to boundary " << endl;
      };
      Flag = 0;
    }

  }

  //Check burst doesn't cross 4KB boundary.
  if (Burst == axi_wrap)
  {
    EndAddress = Address | (Length * ((1 << Size) - 1));
  } else if (Burst == axi_incr)
  {
    EndAddress = Address + Length * Size;
  }

  if ((Burst == axi_wrap) || (Burst == axi_incr))
  {
    StartAddress = Address;

    if ((StartAddress & ~BURST_BOUNDARY) != (EndAddress & ~BURST_BOUNDARY))
    {
      if (Msg)
        cerr << "Error: Illegal AXI Burst overlaps burst boundary" << endl;
      Flag = 0;
    }
  }
  return(Flag);
}



