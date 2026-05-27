eval "exec perl -w -S $0 $@" # -*- Perl -*-
  if ($running_under_some_sh);
  undef ($running_under_some_sh);

# ------------------------------------------------------------------------------
# This confidential and proprietary software may be used only as
# authorised by a licensing agreement from ARM Limited
#   (C) COPYRIGHT 2001-2013 ARM Limited
#       ALL RIGHTS RESERVED
# The entire notice above must be reproduced on all authorised
# copies and copies may only be made to the extent permitted
# by a licensing agreement from ARM Limited.
#
# ------------------------------------------------------------------------------
# Version and Release Control Information:
#
#  File Name           : $RCSfile: AhbFrsConv.pl,v $
#  File Revision       : 1.116
#
#  Release Information : r0p1-00rel0
#
# ------------------------------------------------------------------------------
# Purpose             : Converts an ASCII command file into a hex format,
#                       suitable for import by the FileReader bus slave.
#                       Checks that the specified commands are compatible
#                       with the FileReader.
#
#                       Options:
#                            -help
#                            -quiet
#                            -busWidth=<databus width>   32
#                            -stimarraysize=<size>       default = 50000 (5 words)
#                            -infile=<input text file>   default = filestim.m3i
#                            -outfile=<output hex file>  default = filestim.m3d
# ------------------------------------------------------------------------------
# This FileReadSlave can only take command read(R), write(W) and quit(Q)_




package main;

use strict;
use Getopt::Long;


# Global variables

# default values for command-line options
my $help          = 0;
my $verbose       = 1;
my $busWidth      = 32;
$main::infile     = 'filestim.m3i';
$main::outfile    = '';
my $VectorWidth   = 5;   #see the format block
my $stimarraysize = 50000;



my %command;              # hash to store stimulus fields
my $fileErrors      = 0;  # number of errors in input file
my $fileWarnings    = 0;  # number of warnings in input file
my $numCmds         = 0;  # number of commands in input file

my $currCmd         = 0;  # current command
my $prevCmd         = 0;  # previous command, used in case of loop commands
my $error           = 0;  # command causing current error
my $memorySize      = 0;  # counts memory size required by FRBM

my $transCount      = 0;  # no. of transfers remaining in defined-length burst
my $errorsBefore    = 0;  # number of errors before looped S vector

my $commentString;
my $lineNum         = 0;  # line number
my $prevLineNum     = 0;  # line number of previous command


# default values for stimulus fields
$command{'CMD'}       = '00000000'; # idle
$command{'ADDR'}      = '00000000';
$command{'DATA'}      = '00000000';
$command{'STRB'}      = '0';
$command{'PPROT'}     = '0';
$command{'COMH'}      = '00';
$command{'RESP'}      = '0';
$command{'ID'}        = '00000000';
$command{'DELAY'}     = '00000000';

# Get run date
my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
$year += 1900;
$mon  += 01;


# check Perl version not older than 5.005 as switches not supported
if ($] < 5.005) {
  warn "******************* WARNING 128 *******************\n".
       "No command line switches supported!\n".
       "Default values will be used.\n".
       "Recommend upgrading to Perl version 5.005 or higher\n\n";

# Get command line options
} else {
  GetOptions( "help"            => \$help,
              "quiet"           => sub {$verbose = 0},
              "infile=s"        => \$main::infile,
              "outfile=s"       => \$main::outfile,
              "stimarraysize=s" => \$stimarraysize,
          );
}

my $maxBytesBus     = $busWidth/8;  # Number of byte-lanes in the internal bus:
                                    # Calculated after buswidth is fixed

# Help message
if ($help == 1) {
  print "Purpose:\n".
        "  Converts an ASCII command file into a hex format,\n".
        "  suitable for import by the APB File Reader Bus Slave.\n".
        "  This ApbFrs can only take command read(R), write(W) and quit(Q).\n".         
        "  Checks that the specified commands are compatible.\n".
        "\nUsage:\n".
        "   Reads stimulus from a text file.\n".
        "   Writes hex data to a text file.\n".
        "\nOptions:\n".
        "   -help                   display this help message\n".
        "   -quiet                  display only ERROR messages\n".
        "   -stimarraysize=<size>   default = 50000\n".
        "   -infile=<input file>    default = filestim.m3i\n".
        "   -outfile=<output file>  default = filestim.m3d\n".
        "\n================================================================\n";
  exit(1);
}


# calculate default output file name
if ($main::outfile eq '') {

  if($main::infile =~ /([\w\\\/]+)\.\w+/) {
    $main::outfile = $1.'.m3d';
  } else {
    $main::outfile = $main::infile.'.f2d';
  }
}



# Report options selected
if ($verbose == 1) {
  print "Input file $main::infile\n";
  print "Output file $main::outfile\n";
  print "\n";
}

# Check that input and output filenames are not the same
if ($main::infile eq $main::outfile) {
  printf "ERROR 20: Input and output file names are identical\n\n";
  $fileErrors++;

} else {
  # Open input file
  unless (open(INPUTFILE, "$main::infile") ) {

    # failed to open input file
    printf "ERROR 17: Input file does not exist".
           " or cannot be accessed\n";
    $fileErrors++;
  }

  # Open output file
  unless (open (FILEOUT, ">$main::outfile") ) {

    # failed to open output file
    printf "ERROR 21: Cannot create output file $main::outfile\n";
    $fileErrors++;
  }
}

# Only continue if no errors
if ($fileErrors) {
  die "\nExit with $fileErrors error(s) and $fileWarnings warning(s).\n\n";

} elsif ($verbose == 1) {
  printf "Reading from text file: %s\n\n", $main::infile;

}

# ------------------------------------------------------------------------------
#
#                       Stimulus file parsing
#
# Commands are detected by searching for the first non-whitespace character on
# a line.
#
# For each command, first the required fields are retrieved and checked, then
# any optional fields which are present. If a required field is invalid or
# missing then an error is raised. If an optional field is invalid or not
# recognised then a warning is raised.
# ------------------------------------------------------------------------------

# Process each line of stimulus
# while there are lines remaining to be read from the file
while (<INPUTFILE>) {

  # Keep track of stimulus file line numbers
  $lineNum++;

  # If a character exists on this line and it is not whitespace...
  if (/\S/) {
    $commentString = '';

    # Strip comment command text first, if any
    s/"(.+)"// and
      $commentString = $1;

    # Strip comments from end of line
    s/\s*(\#|\/\/|;|--).*//;

    if(s/^\s*(W|R|Q)\b//i) {


      $prevCmd = $currCmd;  # save previous command in case of Loop commands
      $currCmd = uc(substr($1,0,1));      # get the current command

      $numCmds++;                         # increment command counter


      # Parse the line
      if    ($currCmd eq 'W') { ParseW() }
      elsif ($currCmd eq 'R') { ParseR() }
      elsif ($currCmd eq 'Q') { ParseQ() }

      # add size on memory required for command to stimulus total
      CalcMemory($currCmd);
      
      # write the line to the output file
      OutputHex();
    }
    elsif (/^\s*(\S+.*)/)  {

      $error = $1;
      $currCmd = '$error';
      printf "Line %4d: ERROR 32: Unknown command :".
             " \"%s\"\n", $lineNum, $error;
      $fileErrors++;
    }

  }


}

close(INPUTFILE);
close (FILEOUT);

# End of stimulus error-checking
CheckArraySize($memorySize, $stimarraysize);

PrintSummary() if ($verbose == 1);

# error code is 1 if any errors
($fileErrors == 0) ? exit(0) : exit(1);


# ------------------------------------------------------------------------------
#
# Check size of stimulus does not exceed size of File Read Master array length
#
# ------------------------------------------------------------------------------

sub CheckArraySize {

  my $memorySize = shift;
  my $stimarraysize = shift;

  if (($verbose == 1) and ($memorySize > ($stimarraysize * $VectorWidth))) {
    print  "\n";
    print  "================================================================\n";
    print  "ERROR 136:   The compiled stimulus exceeds the specified size of\n";
    print  "             the FileReader array. Increase the FileReader\n";
    print  "             StimArraySize generic/parameter and use script\n";
    print  "             with the -stimarraysize switch.\n";
    print  "\n";
    print  "Increase the FRS RTL StimArraySize as well!!! \n";
    printf "Compiled stimulus size  = %d x 32-bit\n",$memorySize;
    printf "FileReader array size   = %d x 32-bit\n",($stimarraysize * $VectorWidth);
    print  "================================================================\n";
    $fileErrors++;
  }
}


# ------------------------------------------------------------------------------
#
# Print a summary of the file conversion process
#
# ------------------------------------------------------------------------------
sub PrintSummary {
  print  "\n";
  print  "================================================================\n";
  printf "Total Warnings                     = %d\n",$fileWarnings;
  printf "Total Errors                       = %d\n",$fileErrors;
  printf "Total commands                     = %d\n",$numCmds;
  printf "FileReader min array size required = %d x 32-bit\n",$memorySize;
  printf "Output file name                   = %s\n",$main::outfile;
  print  "================================================================\n";
}

# ------------------------------------------------------------------------------
#
# W command decoding
#
# ------------------------------------------------------------------------------
sub ParseW {

  $command{'CMD'}  = '00100000';

  # Get mandatory fields
  $command{'ADDR'} = GetAddrField();
  $command{'DATA'} = GetDataField();
  $command{'PPROT'} = GetPprotField();
  $command{'STRB'} = GetStrbField();
  $command{'RESP'} = GetRespField();
  $command{'ID'}   = GetIdField();
  $command{'DELAY'} = GetDelayField();
  $command{'CMDH'} = '20';
}


# ------------------------------------------------------------------------------
#
# R command decoding
#
# ------------------------------------------------------------------------------
sub ParseR {

  $command{'CMD'}  = '00010000';

  # get mandatory fields
  $command{'ADDR'} = GetAddrField();
  $command{'DATA'} = GetDataField();
  $command{'PPROT'} = GetPprotField();  
  $command{'STRB'} = '0';
  $command{'RESP'} = GetRespField();
  $command{'ID'}   = GetIdField();
  $command{'DELAY'} = GetDelayField();
  $command{'CMDH'} = '10';
}



# ------------------------------------------------------------------------------
#
# Q command decoding
#
# ------------------------------------------------------------------------------
sub ParseQ {

  $command{'CMD'}  = '10000000';

  $command{'CMDH'}      = '80';
}


# ------------------------------------------------------------------------------
# Get mandatory address field value
#
# I/O: searches from start of line for the address field
#      returns the value of the address field, or reports an error
# ------------------------------------------------------------------------------
sub GetAddrField {

  my $addr;


  if (s/\b(?:0x)?([0-9A-F]{1,8})\b//i) {
    $addr = sprintf("%08X", hex($1));

  } else {
    # mandatory field missing
    $addr = 0;
    printf "Line %4d: ERROR 36: Required field is missing or".
           " in wrong format\n", $lineNum;
    $fileErrors++;

  }
  
  CheckAddrAlign($addr);
  
  return $addr;
}



# ------------------------------------------------------------------------------
# Get mandatory data field value
#
# I/O: searches from start of line for the data field
#      returns the value of the data field, or reports an error
# ------------------------------------------------------------------------------
sub GetDataField {

  my $data;             # (hex string) value of data field in stimulus
  my $dataFieldWidth;   # width of data field, i.e. number of hex digits

  # Note 'X' is allowed, but may cause an error in the FileReadCore
  if (s/\b(?:0x)?([0-9A-FX]{2,32})\b//i) {
    $data = $1;

  }  else {
    # mandatory field missing
    $data = 0;
    printf "Line %4d: ERROR 36: Required field is missing or".
           " in wrong format\n", $lineNum;
    $fileErrors++;
  }

  
  # if data field exists
  if ($data) {

    $dataFieldWidth = length($data);
    # check if data field width is greater than busWidth
    if ($dataFieldWidth != 8 ) {
      printf "\nLine %4d: ERROR 49: Data field is an".
             " invalid length\n", $lineNum;
      $fileErrors++;

    }

  }

  return $data;
}

# ------------------------------------------------------------------------------
# Get mandatory STRB field value
#
# ------------------------------------------------------------------------------
sub GetStrbField {

  my $strb;

  if (s/\bS([0-1]{4})\b//i) {
    $strb = $1;
  } else {
    printf "Line %4d: ERROR 36: Required field is missing or".
           " in wrong format\n", $lineNum;
    # default
    $strb = '0000';
  }
  
  
  return BinToHex($strb);
  
}

# ------------------------------------------------------------------------------
# Get mandatory PPROT field value
#
# ------------------------------------------------------------------------------
sub GetPprotField {

  my $pprot;

  if (s/\bP([0-1]{3})\b//i) {
    $pprot = $1;
    $pprot = "0$pprot";    
  } else {
    printf "Line %4d: ERROR 36: Required field is missing or".
           " in wrong format\n", $lineNum;
    # default
    $pprot = '0000';
  }

  return BinToHex($pprot);
}



# ------------------------------------------------------------------------------
# Get mandatory ID field value
#
# ------------------------------------------------------------------------------
sub GetIdField {

  my $id;

  if (s/\bid([0-9A-F]{1,8})\b//i) {
    $id = $1;
    until ($id =~ /([0-9A-F]{8})/i) {
      $id = "0$id";
    }    
  } else {
    printf "Line %4d: ERROR 36: Required field is missing or".
           " in wrong format\n", $lineNum;
    # default
    $id = '00000000';

  }

  return $id;
}

# ------------------------------------------------------------------------------
# Get optional field resp value
#
# ------------------------------------------------------------------------------
sub GetRespField {

  my $resp;            

  if (s/\b(error|slverr)\b//i) {
    $resp = '1';
  }
  else {
    $resp = '0';
  }
  
  return $resp;
}

# ------------------------------------------------------------------------------
# Get optional field delay value
#
# ------------------------------------------------------------------------------
sub GetDelayField {

  my $delay;             # (hex string) value of delay field in stimulus

  if (s/\bdelay([0-9A-F]{1,8})\b//i) {
    $delay = $1;
    until ($delay =~ /([0-9A-F]{8})/i) {
      $delay = "0$delay";
    }
  }
  else {
    $delay =  '00000000';
  }
  
  return $delay;
}


# ------------------------------------------------------------------------------
# Address Alignment Checks
#
# ------------------------------------------------------------------------------
sub CheckAddrAlign {

  my $addr = shift;
  if  ( $addr and ($addr !~ /([0-9A-Fa-f]{7})[0|4|8|C]/i))
      {
        printf "Line %4d: WARNING : Unaligned Address\n", $lineNum;
        $fileErrors++;
      }
}

# ------------------------------------------------------------------------------
# Calculate memory size required for FileReader
#   Adds up the total number of 32-bit words required to hold the stimulus
#    output
#
# ------------------------------------------------------------------------------
sub CalcMemory {

my $cmd = shift;

  if ($cmd eq 'W' or $cmd eq 'R' or $cmd eq 'Q') {
      $memorySize += $VectorWidth;

  } 
}


# ------------------------------------------------------------------------------
# Converts an n-bit binary string to hex with n/4 digits
# Note: Only works for whole bytes.
#
# ------------------------------------------------------------------------------
sub BinToHex {
  unpack('H*', pack('B*', shift));
}

# ------------------------------------------------------------------------------
# Converts an numeric value to 8 hex digits
#
# ------------------------------------------------------------------------------
sub ToHex32 {
  sprintf("%08X", shift);
}

# ------------------------------------------------------------------------------
# Converts up to 8 bits binary to a number
# Note: Wraps at 256
#
# ------------------------------------------------------------------------------
sub FromBin8 {
    unpack('C', pack('B8',substr('0' x 8 . shift, -8)));
}


# ------------------------------------------------------------------------------
# Converts a number to an 8-bit binary string
# Note: Wraps at 256
#
# ------------------------------------------------------------------------------
sub ToBin8 {
  return unpack( "B8",  pack ('C', shift));
}


# ------------------------------------------------------------------------------
#
# Write a command to the output (hex) file
#
# ------------------------------------------------------------------------------

sub OutputHex  {

  # save output format and handle so that they can be restored
  my $savedFormat = $~;
  my $savedFileHandle = select FILEOUT;

  # select output stimulus format for current command type
  if    ($command{'CMD'} eq '00100000') {$~ = 'WRITECMD'}
  elsif ($command{'CMD'} eq '00010000') {$~ = 'READCMD'}
  elsif ($command{'CMD'} eq '10000000') {$~ = 'QUITCMD'}
  else {
    # default - should never happen
    printf "WARNING 255: Command undefined, defaulting to IDLE";
    $~ = 'IDLECMD';
  }

  write (FILEOUT);

  # reset format and output stream
  $~ = $savedFormat;
  select $savedFileHandle;

}



# ------------------------------------------------------------------------------
# Output format definitions
#
# ------------------------------------------------------------------------------

format WRITECMD =
@<@<<<<<<<@<<<<<<<@@@@<<<<<<<@<<<<<<<
$command{'CMDH'},$command{'ADDR'},$command{'DATA'},$command{'PPROT'},$command{'STRB'},$command{'RESP'},$command{'ID'},$command{'DELAY'}
.

format READCMD =
@<@<<<<<<<@<<<<<<<@@@@<<<<<<<@<<<<<<<
$command{'CMDH'},$command{'ADDR'},$command{'DATA'},$command{'PPROT'},$command{'STRB'},$command{'RESP'},$command{'ID'},$command{'DELAY'}
.

format QUITCMD =
@<
$command{'CMDH'}
.


__END__
