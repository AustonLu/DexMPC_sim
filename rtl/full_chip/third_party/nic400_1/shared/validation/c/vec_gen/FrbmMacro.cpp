//---------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2003-2014 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
// Filename            : $RCSfile: AxiFrbmMacro.cpp,v $
//
// Checked In          :  2014-03-21 18:45:16 +0000 (Fri, 21 Mar 2014)
//
// Revision            : 169546
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


#include "FrbmMacro.h"


FrbmMacro::FrbmMacro() 
{
  //---------------------------------------------------
  // Initialise 
  //---------------------------------------------------
  Transactions = 0;
  LineCount = 0;
  usingFile = false;

  mycout = &std::cout;
}

FrbmMacro::~FrbmMacro()
{
}

bool FrbmMacro::Initialise_FRBM_gen(string filename, ms_type_enum ms_type_in)
{

  // Line number increment
  LineCount = 0;

  strcpy(FileName,filename.substr(0,248).c_str());

  mycout = new ofstream(filename.c_str(), ios::out);

  if (!mycout)
  {
    cout << "Couldn't open output file " << filename << endl;
    return 0;
  }

  usingFile = true;

  ms_type = ms_type_in;

  return 1;
}

//---------------------------------------------------------------------
// Comment
//---------------------------------------------------------------------
void FrbmMacro::Comment(string my_comment)
{
      *mycout << my_comment;
}



//---------------------------------------------------------------------
// Display
//---------------------------------------------------------------------
void FrbmMacro::DisplayBinary(arm_uint32 Value, int length)
{
  for (int a=length-1; a>-1; a--)
    if (Value & (1<<a))
      *mycout << "1";
    else
      *mycout << "0";
}

//---------------------------------------------------------------------
// Calculates the number of characters used to display the address
//---------------------------------------------------------------------
int FrbmMacro::Calc_addr_width(arm_uint8 addr_width)
{
   if ((((int)(addr_width / 4)) * 4) == addr_width) {
      return (addr_width / 4);
   } else {
      return (addr_width / 4) + 1;
   }
}

//---------------------------------------------------------------------
// Ensures that a value fits in the correct number of bits 
//---------------------------------------------------------------------
int  FrbmMacro::Mask_value(int value, int bits)
{

     if (bits == 32) {   
         return value;    
     } else {    
         return (value % (int)pow(2.0, bits));
     };

}

string  FrbmMacro::Mask_value(string value, int bits)
{
  string temp_string="";
  int temp_value = 0 ;
  int temp_bits  = bits;
  string newvalue ="";
  
  //When bits less than the value's length remove some bits from the value  
  //When bits more than the value's length insert zeros into the value 
  if(value.length() > bits)
  {
    value = value.erase(0,(value.length() - bits));  
  } else if(value.length() < bits)
  {
    value = value.insert(0,string((bits - value.length()),'0')); 
  }
  
  //If the value is not a multiplier of 4 make it 
  //so you will be able to calculate the hex equivalent value
  if(value.length()%4 != 0) 
  { 
   temp_bits = bits + 4 - (value.length()%4); 
   value = value.insert(0,string((4 - value.length()%4),'0'));
  }
 
  //Convert to a hex sting
  for(int i =0; i < temp_bits/4; i++)
  {
  temp_string = value.substr(0,4);
  value=value.erase(0,4);
  temp_value = strtol(temp_string.c_str(),NULL,2) ;
  newvalue = newvalue.insert(newvalue.length(),to_string(temp_value,1));
  }
  
  return newvalue;
};

unsigned long long FrbmMacro::Mask_value_ul(unsigned long long value, int bits)
{
     if (bits == 64) {    
         return value;    
     } else {    
         return (value % (unsigned long long)pow(2.0, bits));
     };
}

string  FrbmMacro::Mask_value_ul(string value, int bits)
{
  string temp_string="";
  int temp_value = 0 ;
  int temp_bits  = bits;
  string newvalue ="";

  //When bits less than the value's length remove some bits from the value  
  //When bits more than the value's length insert zeros into the value 
  if(value.length() > bits)
  { 
    value = value.erase(0,(value.length() - bits));  
  } else if(value.length() < bits)
  {
    value = value.insert(0,string((bits - value.length()),'0')); 
  }

  //If the value is not a multiplier of 4 make it 
  //so you will be able to calculate the hex equivalent value
  if(value.length()%4 != 0) 
  { 
   temp_bits = bits + 4 - (value.length()%4); 
   value = value.insert(0,string((4 - value.length()%4),'0'));
  }

  //Convert to a hex sting
  for(int i =0; i < temp_bits/4; i++)
  {
    temp_string = value.substr(0,4);
    value=value.erase(0,4);
    temp_value = strtol(temp_string.c_str(),NULL,2) ;
    newvalue = newvalue.insert(newvalue.length(),to_string(temp_value,1));
  }
  return newvalue;
};

//---------------------------------------------------------------------
// Convert Integer to String
//---------------------------------------------------------------------
string FrbmMacro::to_string(arm_uint32 data, uint bits) {

        ostringstream data_str;
        //convert to string
        data_str << setw(bits) << setfill('0') << hex << data;
        return data_str.str();
  };


//---------------------------------------------------------------------
// Calculations
//---------------------------------------------------------------------
arm_uint64 FrbmMacro::GetMask(amba_size Size)
{
  arm_uint64 Mask;
  switch(Size)
  {
    case size8:
      Mask = 0xff;
      break;
    case size16:
      Mask = 0xffff;
      break;
    case size32:
      Mask = 0xffffffff;
      break;
    case size64:
      Mask = 0xffffffffffffffff;
      break;
    default:
      break;
  }
  return(Mask);
}

amba_strobe FrbmMacro::GetStrobe(amba_size Size)
{
  amba_strobe Strobe;
  switch(Size)
  {
    case size8:
      Strobe = 0x1;
      break;
    case size16:
      Strobe = 0x3;
      break;
    case size32:
      Strobe = 0xf;
      break;
    case size64:
      Strobe = 0xff;
      break;
    default:
      break;
      
  }
  return(Strobe);
}

void FrbmMacro::SetStrobeArray(amba_size Size, amba_strobe Strobe[16])
{
  amba_strobe TmpStrobe = GetStrobe(Size);
 
  for (int a = 0; a < 16; a++)
  {
    Strobe[a] = TmpStrobe;
  }
}

// dk:start REVISIT: What does this code really do?
amba_parity FrbmMacro::GetParity(amba_size Size)
{
  amba_parity Parity;
  switch(Size)
  {
    case size8:
      Parity = 0x0;//0x1;
      break;
    case size16:
      Parity = 0x0;//0x3;
      break;
    case size32:
      Parity = 0x0;//0xf;
      break;
    case size64:
      Parity = 0x0;//0xff;
      break;
    default:
      break;
      
  }
  return(Parity);
}

void FrbmMacro::SetParityArray(amba_size Size, amba_parity Parity[16])
{
  amba_parity TmpParity = GetParity(Size);
 
  for (int a = 0; a < 16; a++)
  {
    Parity[a] = TmpParity;
  }
}
// dk:end

void FrbmMacro::UpSizeData(arm_uint8 Data[16], arm_uint64 Data64[16], int Length)
{
  for (int a = 0; a < Length; a++)
    Data64[a] = Data[a];
}
void FrbmMacro::UpSizeData(arm_uint16 Data[16], arm_uint64 Data64[16], int Length)
{
  for (int a = 0; a < Length; a++)
    Data64[a] = Data[a];
}
void FrbmMacro::UpSizeData(arm_uint32 Data[16], arm_uint64 Data64[16], int Length)
{
  for (int a = 0; a < Length; a++)
    Data64[a] = Data[a];
}

