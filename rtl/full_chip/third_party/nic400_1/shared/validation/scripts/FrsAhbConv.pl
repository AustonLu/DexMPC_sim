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
#                            -busWidth=<databus width>   32 or 64 128 256
#                            -endian=<endianness>        big or little(default)
#                              Note: big-endian is BE-32 (a.k.a. ARM big-endian)
#                            -stimarraysize=<size>       default = 10000 ($VectorWidth*words)
#                            -infile=<input text file>   default = filestim.m3i
#                            -outfile=<output hex file>  default = filestimSlave.m3d
# ------------------------------------------------------------------------------
# This FileReadSlave can not take command BUSY, IDLE, LOOP, POLL,COMMENT




package main;

use strict;
use Getopt::Long;


# Global variables

# default values for command-line options
my $help          = 0;
my $verbose       = 1;
#my $adk1          = 0;
my $endian        = 'little';
my $busWidth      = 32;
my $addrWidth     = 32; #currently fixed at 32
$main::infile     = 'filestim.m3i';
$main::outfile    = '';
#my $arch          = 'ahb2';
my $stimarraysize = 50000;

my $unalign         = '0'; # allow unaligned transfer

my %command;              # hash to store stimulus fields
my %sequence;             # hash to store start of burst info
my $fileErrors      = 0;  # number of errors in input file
my $fileWarnings    = 0;  # number of warnings in input file
my $numCmds         = 0;  # number of commands in input file

my $currCmd         = 0;  # current command
my $prevCmd         = 0;  # previous command, used in case of loop commands
my $error           = 0;  # command causing current error
my $memorySize      = 0;  # counts memory size required by FRBM

my $transCount      = 0;  # no. of transfers remaining in defined-length burst
my $incrCount       = 0;  # number of transfers for incr burst
my $loopCount       = 0;  # number of looped S vectors to be expanded
my $errorsBefore    = 0;  # number of errors before looped S vector


my $lineNum         = 0;  # line number
my $prevLineNum     = 0;  # line number of previous command

my $mismatch        = 0;  # addr/size mismatch warning is pending

my $numLanesBus     = 0;  # Number of lanes determined from the specified
                          # bus width

my $commentString = '';   # Stores any quoted string in a line of
                          # stimulus

my $sizeDef         = 0;  # Indicates that size field took the default
                          # value

my $addrIbd  = ''; # Indicates that captured address was b or d
                   # which could be a size value

my $addrIdef = 0;  # Indicates that address was set to default value

## variables used in vector print format
my $funcBits = 8;  #fixed
my $addrBits = 8;  #default for addrWidth=32
my $dataBits = $busWidth/4 ;
my $strbBits = 8 ; #fixed
my $idBits = 8;    #fixed
my $delayBits = 8; #fixed

# default values for stimulus fields
$command{'LINE'}      = 0;
$command{'DIFF'}      = '000000';
$command{'CMD'}       = '00000000'; # idle
$command{'ADDR'}      = sprintf("%08X", hex(0));
$command{'ADDRH'}     = sprintf("%08X", hex(0));    #top bits of address if larger than 32
$command{'ADDRW'}     = sprintf("%0${addrBits}X", hex(0));  #whole address string
$command{'DATA'}      = sprintf("%0${dataBits}X", hex(0));
$command{'SIZE'}      = '000';
$command{'BUR'}       = '000';
$command{'PROT'}      = '000000';
$command{'LOCK'}      = '0';
$command{'DIR'}       = '0';
$command{'EMPTY'}     = '00000000';  ##place holder in function
$command{'RESP'}      = '00';
$command{'WAIT'}      = '0';
$command{'NUM'}       = 0;
$command{'BSTRB'}     = '00000000'; 
$command{'BSTRBHEX'}  = '00000000'; ##occupies 16 bits of command{function} to support up to 256 buswidth
$command{'FRAMEERR'}  = 0;
$command{'EVENTID'}   = sprintf("%0${addrBits}X",0);  #event id use the same field as address
$command{'ID'}        = sprintf("%0${idBits}X", hex(0));
$command{'DELAY'}     = sprintf("%0${delayBits}X", hex(0));

$command{'UNALIGN'}   = '1'; # allow unaligned transfer
  
%sequence = %command;

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
              "buswidth=i"      => \$busWidth,
              "stimarraysize=s" => \$stimarraysize,
              "endian=s"        => \$endian
          );
}

my $maxBytesBus     = $busWidth/8;  # Number of byte-lanes in the internal bus:
                                    # Calculated after buswidth is fixed

if ($verbose == 1)   {
  print "\n================================================================\n".
        "= This confidential and proprietary software may be used only\n".
        "= as authorised by a licensing agreement from ARM Limited\n".
        "=    (C) COPYRIGHT 2008-2013 ARM Limited.\n".
        "=          ALL RIGHTS RESERVED\n".
        "= The entire notice above must be reproduced on all authorised\n".
        "= copies and copies may only be made to the extent permitted\n".
        "= by a licensing agreement from ARM Limited\n".
        "=\n".
        "= Script version : For Pl301r2 & NIC400r0p0 only\n";
  printf "= Run Date : %02d/%02d/%04d %02d:%02d:%02d",
  $mday, $mon, $year, $hour, $min, $sec;
  print "\n================================================================\n\n";
}

# Help message
if ($help == 1) {
  print "Purpose:\n".
        "  Converts an ASCII command file into a hex format,\n".
        "  suitable for import by the File Reader Bus Master.\n".
        "  Checks that the specified commands are compatible\n".
        "  with the File Reader Bus Master.\n".
        "\nUsage:\n".
        "   Reads stimulus from a text file.\n".
        "   Writes hex data to a text file.\n".
        "\nOptions:\n".
        "   -help                   display this help message\n".
        "   -quiet                  display only ERROR messages\n".
        "   -busWidth=<32|64|128|256>   default = 32\n".
        "   -endian=<little|big>    default = little\n".
        "                           (big-endian is BE-32 'ARM big-endian')\n".
        "   -stimarraysize=<size>   default = 10000\n".
        "   -infile=<input file>    default = filestim.m3i\n".
        "   -outfile=<output file>  default = filestim.m3d\n".
        "\n================================================================\n";
  exit(1);
}

$numLanesBus = $busWidth >> 3;

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

  if (/^\s*#FRS#/) {

    my $setting = $_;

    #Datawidth
    if ($setting =~ /[Dd]ata[Ww]idth=([0-9]*)/) {
      printf "Overriding Data width with %d \n", $1;
      $busWidth = $1;
      $maxBytesBus = $busWidth/8;
      $numLanesBus = $busWidth >> 3;
      $dataBits = $busWidth/4 ;
    };

    #Addrwidth
    if ($setting =~ /[Aa]ddress[Ww]idth=([0-9]*)/) {
      printf "Overriding Address width with %d \n", $1;
      $addrWidth = $1;
      if ($addrWidth > 32) {
        $addrBits = 16;
      }
    };

    #IDwidth
    if ($setting =~ /[Ii][Dd][Ww]idth=([0-9]*)/) {
      printf "Line %4d: WARNING 84: Id Width not supported".
              "  entire line will be ignored\n", $lineNum;
        $fileWarnings++;
    };

    #User-Widths
    if ($setting =~ /.*[Uu]ser[Ww]idth=([0-9]*)/) {
      printf "Line %4d: WARNING 84: User Width not supported".
              "  entire line will be ignored\n", $lineNum;
        $fileWarnings++;
    };

  }
  
  # If a character exists on this line and it is not whitespace...
  elsif (/\S/) {
    $commentString = '';

    # Strip comment command text first, if any
    s/"(.+)"// and
      $commentString = $1;

    # Strip comments from end of line
    s/\s*(\#|\/\/|;|--).*//;

    if(s/^\s*(C|comm|comment)\b//i) {

      $command{'LINE'} = $lineNum;        # get line number
      printf "Line %4d: WARNING: Comment  not supported:".
             " entire line will be ignored\n", $lineNum;
        $fileWarnings++;
    }  
      # Check that loop command doesn't follow EMIT or WAIT
      elsif (s/^\s*(B|I|P|L)\b//i) {
        $command{'LINE'} = $lineNum;        # get line number
        printf "Line %4d: WARNING: COMMAND  not supported:".
             " entire line will be ignored\n", $lineNum;
        $fileWarnings++;
      }

    # If line starts with any other valid command then decode command
     elsif(s/^\s*(W|R|S|B|I|P|L|Q|EMIT|WAIT|write|read|seq|sequential|quit|emit|wait|Quit|Emit|Wait)\b//i) {


      $prevCmd = $currCmd;  # save previous command in case of Loop commands
      if ($1 eq 'EMIT' or $1 eq 'emit' or $1 eq 'WAIT' or $1 eq 'wait' or
          $1 eq 'Emit' or 'Wait' or $1 eq 'Quit' or 'QUIT' or 'quit') {
        $currCmd = uc(substr($1,0,4));      # get the current command
        # Four characters are needed for the EMIT and WAIT commands
      }
      else {
        $currCmd = uc(substr($1,0,1));      # get the current command
        # Only one character is required for all other commands
      }

      $numCmds++;                         # increment command counter

      $command{'LINE'} = $lineNum;        # get line number

      # S or B command
      if ($currCmd eq 'S' or $currCmd eq 'B') {

        # if a burst is not in progress (defined- or undefined-length)
        if (GetTransCount() == 0 && (GetIncrCount() == 0)) {

            printf "Line %4d: ERROR 84: $currCmd command outside burst".
                   " (check burst size)\n", $lineNum;
            $fileErrors++;
        }

      }

      # Check that WAITs do not follow one another
      if ($currCmd eq 'WAIT' and $prevCmd eq 'WAIT') {
        printf "Line %4d: ERROR 111: WAIT commands cannot ".
        "follow one another\n", $lineNum;
        $fileErrors++;
      } 
            
      # Check that EMITs do not follow one another
      if ($currCmd eq 'EMIT' and ($prevCmd eq 'EMIT' or $prevCmd eq 'WAIT')) {
        printf "Line %4d: ERROR 111: EMIT commands cannot ".
        "follow another EMIT or WAIT\n", $lineNum;
        $fileErrors++;
      } 

      # Parse the line
      if    ($currCmd eq 'W') { ParseW() }
      elsif ($currCmd eq 'R') { ParseR() }
      elsif ($currCmd eq 'S') { ParseS() }
      elsif ($currCmd eq 'B') { print "Busy is not supported in AhbSlave" }
      elsif ($currCmd eq 'I') { print "Idle is not supported in AhbSlave" }
      elsif ($currCmd eq 'P') { print "Polling is not supported in AhbSlave" }
      elsif ($currCmd eq 'L') { print "Loop is not supported in AhbSlave" }
#      elsif ($currCmd eq 'B') { ParseB() }
#      elsif ($currCmd eq 'I') { ParseI() }
#      elsif ($currCmd eq 'P') { ParseP() }
#      elsif ($currCmd eq 'L') { ParseL() }
      elsif ($currCmd eq 'Q' or $currCmd eq 'QUIT') { ParseQ() }
      elsif ($currCmd eq 'EMIT') { ParseEMIT() }
      elsif ($currCmd eq 'WAIT') { ParseWAIT() }

      # Check for anything left on the line
      CheckInvalidFields();
      CheckInvalidComment($commentString);

      # add size on memory required for command to stimulus total
      CalcMemory($currCmd);

      # write the line to the output file
      OutputHex();


      # Syntax error if any other non-whitespace character is on the line
    } elsif (/^\s*(\S+.*)/)  {

      $error = $1;
      $currCmd = '$error';
      printf "Line %4d: ERROR 32: Unknown command :".
             " \"%s\"\n", $lineNum, $error;
      $fileErrors++;
    }

  }

  # exit loop if Q command has been detected
  if ($currCmd eq 'Q') { last }

}

# At End Of File, check for an unfinished defined-length burst (unless errcanc)
if (GetTransCount() > 0 and ($verbose == 1)) {
  printf "Line %4d: WARNING 144: End of file: Expected further".
         " transfers in burst\n", $lineNum;
  $fileWarnings++;
}
# At End Of File, check last instruction isn't an EMIT
#if ($currCmd eq 'EMIT') {
#  printf "Line %4d: ERROR 112: EMIT command must be followed by Idle ".
#  "at end of stimulus file\n", $lineNum;
#  $fileErrors++;
#}
#
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

  if (($verbose == 1) and ($memorySize > $stimarraysize)) {
    print  "\n";
    print  "================================================================\n";
    print  "ERROR 136: The compiled stimulus exceeds the specified size of\n";
    print  "             the FileReader array. Increase the FileReader\n";
    print  "             StimArraySize generic/parameter and use script\n";
    print  "             with the -stimarraysize switch.\n";
    print  "\n";
    print  "Increase the FRS RTL StimArraySize as well!!! \n";
    print  "stimulus vector width     = 264 bit \n";
    printf "Compiled stimulus length  = %d \n",$memorySize;
    printf "FileReader array  length  = %d \n",$stimarraysize;
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
  printf "FileReader array length required   = %d\n",$memorySize;
  printf "Output file name                   = %s\n",$main::outfile;
  print  "================================================================\n";
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

  # generate the Function word
  $command{'FUNCTION'} = BinToHex(
                                       $command{'CMD'}.          #8 bit
                                       $command{'SIZE'}.         #3 bit
                                       $command{'BUR'}.          #3 bit
                                       $command{'PROT'}.         #6 bit
                                       $command{'LOCK'}.         #1 bit
                                       $command{'DIR'}.          #1 bit
                                       $command{'EMPTY'}.        #8 bit
                                       $command{'RESP'}          #2 bit
                                      );
  if ($addrWidth > 32) {
    $command{'ADDRW'} = $command{'ADDRH'}.$command{'ADDR'};
  } else {
    $command{'ADDRW'} = $command{'ADDR'};
  }

  # select output stimulus format for current command type
  if    ($command{'CMD'} eq '00000000') {$~ = 'WRITECMD'}
  elsif ($command{'CMD'} eq '00010000') {$~ = 'READCMD'}
  elsif ($command{'CMD'} eq '00100000') {$~ = 'SEQCMD'}
  elsif ($command{'CMD'} eq '10000000') {$~ = 'QUITCMD'} #quit not needed for ahbfrs
  elsif ($command{'CMD'} eq '10010000') {$~ = 'EMITCMD'}
  elsif ($command{'CMD'} eq '10100000') {$~ = 'WAITCMD'}  
  else {
    # default - should never happen
    printf "WARNING 255: Command undefined";
  }

  write (FILEOUT);

  # reset format and output stream
  $~ = $savedFormat;
  select $savedFileHandle;

}


# ------------------------------------------------------------------------------
#
# W command decoding
#
# ------------------------------------------------------------------------------
sub ParseW {

  $command{'CMD'}  = '00000000';
  $command{'DIR'}  = '0';

  # Get mandatory fields
  ($command{'ADDRH'},$command{'ADDR'}) = GetAddrField();
  $command{'DATA'} = GetDataField();
  $command{'ID'}   = GetIdField();
  $command{'DELAY'} = GetDelayField();


  # get optional fields
  $command{'SIZE'}    = GetSizeField();
  $command{'BUR'}     = GetBurstField();
  $command{'PROT'}    = GetProtField();
  $command{'LOCK'}    = GetLockField();
  $command{'RESP'}    = GetRespField();
  $command{'BSTRB'}   = GetMaskField();


  # Check that size/data agree
  ($command{'SIZE'}, $command{'DATA'})
    = CheckSizeData (
                          $numLanesBus,
                          $command{'SIZE'},
                          $command{'DATA'},
                          $command{'BSTRB'}
                        );

  # Shift data into correct byte lanes
  $command{'DATA'}
    = AlignData (
                      $command{'SIZE'},
                      $command{'DATA'},
                      $command{'ADDR'}
                    );

  # New burst, so check for early burst termination and reset burst counters
  ResetBurstCount();

  # Generate BSTRB
  ($command{'BSTRBHEX'})
    = CheckUnalignBstrb (
                          hex($command{'ADDR'}),
                          $command{'SIZE'},
                          $command{'BSTRB'}
                        );

  # Check address/size alignment
  $command{'FRAMEERR'}
    = CheckAddrAlign(
                      $command{'SIZE'},
                      $command{'ADDR'},
                      $command{'UNALIGN'}
                     );


  # Initialise burst counters for the remaining transfers in the burst
  SetBurstCount($command{'BUR'}, $command{'FRAMEERR'});

  # check for burst exceeding 1kB boundary
  Check1kBdy($command{'SIZE'}, $command{'BUR'}, $command{'ADDR'}, GetTransCount());

  # Save address and control information for start of burst
  
  %sequence = %command;

  # Reset unused fields
  $command{'WAIT'}    = '0';
  $command{'NUM'}     = 0;
}


# ------------------------------------------------------------------------------
#
# R command decoding
#
# ------------------------------------------------------------------------------
sub ParseR {

  $command{'CMD'}  = '00010000';
  $command{'DIR'}  = '1';

  # get mandatory fields
  ($command{'ADDRH'},$command{'ADDR'}) = GetAddrField();
  $command{'DATA'} = GetDataField();
  $command{'ID'}   = GetIdField();
  $command{'DELAY'} = GetDelayField();

  # get optional fields
  $command{'SIZE'}   = GetSizeField();
  $command{'BUR'}    = GetBurstField();
  $command{'LOCK'}   = GetLockField();
  $command{'PROT'}   = GetProtField();
  $command{'RESP'}   = GetRespField();


  # Check that size data agree
  ($command{'SIZE'}, $command{'DATA'})
    = CheckSizeData (
                          $numLanesBus,
                          $command{'SIZE'},
                          $command{'DATA'},
                          $command{'BSTRB'},
                        );

  # Shift data into correct byte lanes
  $command{'DATA'}
    = AlignData (
                      $command{'SIZE'},
                      $command{'DATA'},
                      $command{'ADDR'}
                    );

  # New burst, so check for early burst termination and reset burst counters
  ResetBurstCount();


  # Generate BSTRB
  $command{'BSTRBHEX'} = sprintf("%0${strbBits}X", hex(0));


  # Check address/size alignment
  $command{'FRAMEERR'}
    = CheckAddrAlign(
                      $command{'SIZE'},
                      $command{'ADDR'},
                      $command{'UNALIGN'}
                     );

  # Initialise burst counters for the remaining transfers in the burst
  SetBurstCount($command{'BUR'}, $command{'FRAMEERR'});

  # check for burst exceeding 1kB boundary
  Check1kBdy($command{'SIZE'}, $command{'BUR'}, $command{'ADDR'}, GetTransCount());

  # Save address and control information for start of burst
  
  %sequence = %command;

  # Reset unused fields
  $command{'WAIT'}   = '0';
  $command{'NUM'}    = 0;
}


# ------------------------------------------------------------------------------
#
# S command decoding
#
# ------------------------------------------------------------------------------
sub ParseS {

  my $endUnalignedBurst;

  $command{'CMD'} = '00100000';
  
  # get mandatory data field
  $command{'DATA'} = GetDataField();
  $command{'ID'}   = GetIdField();
  $command{'DELAY'} = GetDelayField();
  $command{'BSTRB'}   = GetMaskField();

  # retrieve control information from previous W or R command
  $command{'ADDRH'} = $sequence{'ADDRH'};
  $command{'SIZE'} = $sequence{'SIZE'};
  $command{'BUR'}  = $sequence{'BUR'};
  $command{'PROT'} = $sequence{'PROT'};
  $command{'DIR'}  = $sequence{'DIR'};
  $command{'LOCK'} = $sequence{'LOCK'};
  $command{'UNALIGN'} = $sequence{'UNALIGN'};

  # Calculate and save next address in sequence
  # for purpose of data alignment
  $command{'ADDR'} = IncAddr( $command{'ADDR'},
                              $command{'SIZE'},
                              $command{'BUR'}
                            );

  # Get optional fields
  $command{'RESP'}  = GetRespField();


  # Check that size/data agree
  ($command{'SIZE'}, $command{'DATA'})
    = CheckSizeData (
                          $numLanesBus,
                          $command{'SIZE'},
                          $command{'DATA'},
                          $command{'BSTRB'}
                        );

  # Shift data into correct byte lanes
  $command{'DATA'}
    = AlignData (
                      $command{'SIZE'},
                      $command{'DATA'},
                      $command{'ADDR'}
                    );


  # Resets warning for Addr/Size alignment
  ResetMismatch();

  # Test for the end of an unaligned burst
  $endUnalignedBurst =
    (GetTransCount() == 1 and $sequence{'FRAMEERR'} == 1) ? 1 : 0;


  # Generate BSTRB
  ($command{'BSTRBHEX'})
    = CheckUnalignBstrb (
                          hex($command{'ADDR'}),
                          $command{'SIZE'},
                          $command{'BSTRB'}
                        );


  # if undefined length (INCR) burst
  if ($sequence{'BUR'} eq '001') {

    # check for burst exceeding 1kB boundary
    Check1kBdy($sequence{'SIZE'}, $sequence{'BUR'}, $sequence{'ADDR'}, GetIncrCount());

    IncIncrCount();

  } else {

    DecTransCount();

  }
  

  # Reset unused fields
  $command{'WAIT'} = '0';
  $command{'NUM'}  = 0;

}


# ------------------------------------------------------------------------------
#
# Q command decoding
#
# ------------------------------------------------------------------------------
sub ParseQ {

  $command{'CMD'}  = '10000000';

  # Reset unused fields
  $command{'UNALIGN'} = '0';
  $command{'BSTRB'}   = '';
  $command{'WAIT'}    = '0';
  $command{'SIZE'}    = '000';
  $command{'BUR'}     = '000';
  $command{'PROT'}    = '000000';
  $command{'LOCK'}    = '0';
  $command{'DIR'}     = '0';
  $command{'RESP'}    = '00';
  $command{'NUM'}     = '0000';
  $command{'ADDR'}    = sprintf("%08X", hex(0));
  $command{'ADDRL'}   = sprintf("%08X", hex(0));
  $command{'ADDRW'}   = sprintf("%0${addrBits}X", hex(0));
  $command{'EVENTID'} = sprintf("%0${addrBits}X", 0);
  $command{'WRITEBS'} = '0';
}

# ------------------------------------------------------------------------------
#
# EMIT command decoding
#
# ------------------------------------------------------------------------------
sub ParseEMIT {

  $command{'CMD'}  = '10010000';

  # Get optional EVENTID field
  $command{'EVENTID'}    = GetEventIDField();
}

# ------------------------------------------------------------------------------
#
# WAIT command decoding
#
# ------------------------------------------------------------------------------
sub ParseWAIT {
  $command{'CMD'}  = '10100000';

  # Get optional EventID field
  $command{'EVENTID'}    = GetEventIDField();
}


# ------------------------------------------------------------------------------
# Get mandatory address field value
#
# I/O: searches from start of line for the address field
#      returns the value of the address field, or reports an error
# ------------------------------------------------------------------------------
sub GetAddrField {

  my $addr;
  my $addrh;
  my $addrl;

  if (s/\b(?:0x)?([0-9A-F]{1,16})\b//i) {
    $addr = $1;

  } else {
    # mandatory field missing
    $addr = 0;
    printf "Line %4d: ERROR 36: Required Addr field is missing or".
           " in wrong format\n", $lineNum;
    $fileErrors++;

  }

  if ( length($addr) > 8) {
    $addrl = substr $addr, -8;
    $addrh = substr $addr, 0, -8;
  } else {
    $addrl = $addr;
    $addrh = 0;
  }

  $addrl = sprintf("%08X", hex($addrl));
  $addrh = sprintf("%08X", hex($addrh));

  return $addrh,$addrl;
}


# ------------------------------------------------------------------------------
# Get mandatory ID field value
#
# ------------------------------------------------------------------------------
sub GetIdField {

  my $id;

  if (s/\bid([0-9A-F]{1,8})\b//i) {
    $id = $1;
  } else {
    printf "Line %4d: ERROR 36: Required id field is missing or".
           " in wrong format\n", $lineNum;
    # default
    $id = 0;
  }

  $id = sprintf("%0${idBits}X", hex($id));

  return $id;
}
# ------------------------------------------------------------------------------
# Get optional field delay value
#
# ------------------------------------------------------------------------------
sub GetDelayField {

  my $delay;             # (hex string) value of delay field in stimulus

  if (s/\bdelay([0-9]{1,8})\b//i) {
    $delay = $1;
  }
  else {
    $delay = 0;
  }
  $delay = sprintf("%0${delayBits}X", $delay);
  
  return $delay;
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
  if (s/\b(?:0x)?([0-9A-FX]{2,64})\b//i) {
    $data = $1;

  } else {
    # mandatory field missing
    $data = 0;
    printf "Line %4d: ERROR 36: Required Data field is missing or".
           " in wrong format\n", $lineNum;
    $fileErrors++;
  }

  
  # if data field exists
  if ($data) {

    $dataFieldWidth = length($data);
    # check if data field width is greater than busWidth
    if (($dataFieldWidth << 2) > $busWidth) {
      printf "\nLine %4d: ERROR 48: Data field length exceeds".
             " data bus width\n", $lineNum;
      $fileErrors++;

    # check data field width is either 2,4,8,16  or 32 64 hex digits
    } elsif (($dataFieldWidth != 2) && ($dataFieldWidth != 4) &&
        ($dataFieldWidth != 8) && ($dataFieldWidth != 16) && ($dataFieldWidth != 32) && ($dataFieldWidth != 64)) {
      printf "\nLine %4d: ERROR 49: Data field is an".
             " invalid length\n", $lineNum;
      $fileErrors++;

    }

  }
  
  return $data;
}


# ------------------------------------------------------------------------------
# Get size field value
#
# I/O: searches along the current line for a valid size field value
#      returns the value of the size field
# ------------------------------------------------------------------------------
sub GetSizeField {

  my $size;

  $sizeDef = 0;

  if (s/\bb\b|\bbyte\b|\bsize8\b//i) {
    $size = '000';

  } elsif (s/\bh\b|\bhword\b|\bsize16\b//i) {
    $size = '001';

  } elsif (s/\bw\b|\bword\b|\bsize32\b//i) {
    $size = '010';

  } elsif (s/\bd\b|\bdword\b|\bsize64\b//i) {
    # 64-bit transfer not supported when busWidth set to 32-bit
    if (($busWidth == 32)) {
      printf "Line %4d: ERROR 40: size64 not valid".
             " when outputting to 32-bit busWidth\n", $lineNum;
      $fileErrors++;
      $size = ''; # size will be determined later

    } else {
      $size = '011';

    }

  } elsif (s/\bq\b|\bqword\b|\bsize128\b//i) {
    if ($busWidth < 128) {
      printf "Line %4d: ERROR 40: size128 not supported".
        "  when outputting to %4d-bit busWidth\n", $lineNum,$busWidth;
      $fileErrors++;
      $size = ''; # size will be determined later
    } else {
      $size = '100';
    }
  } elsif (s/\bsize256\b//i) {
    if (($busWidth < 256)) {
      printf "Line %4d: ERROR 40: size256 not valid".
             " when outputting to %4d-bit busWidth\n", $lineNum,$busWidth;
      $fileErrors++;
      $size = ''; # size will be determined later
    } else {
      $size = '101';
    }
  } else {
    $size = ''; # size will be determined later
    $sizeDef = 1; # Indicate that default has been used

  }

  return $size;
}


# ------------------------------------------------------------------------------
# Get burst type
#
# I/O: searches along the current line for a valid burst field value
#      returns the value of the burst field
# ------------------------------------------------------------------------------
sub GetBurstField {

  my $burst;

  if (s/\bsing\b|\bsingle\b//i) {
    $burst = '000';

  } elsif (s/\bincr\b//i) {
    $burst = '001';

  } elsif (s/\bwrap4\b//i) {
    $burst = '010';

  } elsif (s/\bincr4\b//i) {
    $burst = '011';

  } elsif (s/\bwrap8\b//i) {
    $burst = '100';

  } elsif (s/\bincr8\b//i) {
    $burst = '101';

  } elsif (s/\bwrap16\b//i) {
    $burst = '110';

  } elsif (s/\bincr16\b//i) {
    $burst = '111';

  } else {
    # default to INCR
    $burst = '001';
  }

  return $burst;
}


# ------------------------------------------------------------------------------
# Get burst type for Poll commands
#
# I/O: searches along the current line for a valid burst field value
#      returns the value of the burst field
# Only Incr and Single are allowed
# ------------------------------------------------------------------------------
sub GetPollBurstField {

  my $burst;

  if (s/\bsing\b|\bsingle\b//i) {
    $burst = '000';

  } elsif (s/\bincr\b//i) {
    $burst = '001';

  } elsif (s/\b((wrap|incr)(4|8|16))\b//i) {
    # invalid burst type for Poll command
    printf "Line %4d: ERROR 80: Burst type \"$1\" is".
           " incompatible with P command\n", $lineNum;
    $fileErrors++;

    # default to INCR
    $burst = '001';

  } else {
    # default to INCR
    $burst = '001';
  }

  return $burst;
}


# ------------------------------------------------------------------------------
# Get protection field value
#
# I/O: searches along the current line for a valid protection field value
#      returns the value of the protection field
# ------------------------------------------------------------------------------
sub GetProtField {

  my $prot;
  if (s/\bp([0-1]{4})\b//i) {
    # add extra leading zeros to ahb2 prot value
    $prot = '00'.$1;
  } elsif (s/\bp([0-1]*)\b//i) {
    $prot = $1;
    printf "Line %4d: ERROR 105: HPROT has wrong bits \n", $lineNum;
    $fileErrors++;
  } else {
    # default value
    $prot = '000000';
  }

  return $prot;
}

# ------------------------------------------------------------------------------
# Get mask field value
#
# I/O: searches along the current line for a valid protection field value
#      returns the value of the mask field
# ------------------------------------------------------------------------------
sub GetMaskField {

  my $mask = '';
  my $maskFieldWidth;   # width of data field, i.e. number of bits

  if (s/\bm([0-1]*)\b//i) {
    $mask = $1;      
  }

  #Return Mask checking is done elsewhere
  return $mask;
}

# ------------------------------------------------------------------------------
# Get lock field value
#
# I/O: searches along the current line for a valid lock field value
#      returns the value of the lock field
# ------------------------------------------------------------------------------
sub GetLockField {

  my $lock;

  if (s/\block\b//i){
    $lock = '1';

  } elsif (s/\bnolock\b//i) {
    $lock = '0';

  } else {
    $lock = '0';

  }

  return $lock;
}


# ------------------------------------------------------------------------------
# Get Resp field value
#
# I/O: searches along the current line for a valid error field value
#      returns the value of the error field
# ------------------------------------------------------------------------------

sub GetRespField {

  my $resp;


  if (s/\bok\b|\bokay\b//i) {
    $resp = '00';

  } elsif (s/\berrcont\b|\berrorcont\b|\berr\b|\bslverr\b|\berror\b//i) {
    $resp = '01';

  }  elsif (s/\berrcanc\b|\berrorcanc\b//i) {
    $resp = '01';  #for ahb slave, error cont and error cancel are the same

  } elsif (s/\bxfail\b//i) {
    printf "Line %4d: ERROR 104: XFAIL response not supported\n", $lineNum;
    $fileErrors++;
    $resp = '00';
    
  } else {
    printf "Line %4d: WARNING 104 : No response specified, default OK\n", $lineNum;
    $resp = '00';

  }

  return $resp;
}


# ------------------------------------------------------------------------------
# Get Loop mandatory number field value
#
# I/O: searches along the current line for a valid number field value
#      returns a string of the hex value of the number field,
#      or reports an error an defaults to zero
# ------------------------------------------------------------------------------
sub GetNumberField {

  my $num;
  my $hexNum = '00000000';

  if (s/\b([0-9]{1,10})\b//i) {

    $num = $1;

    if ($num > 2**32-1 or $num < 1) {
      # number is out of range
      printf "Line %4d: ERROR 43: Loop number out".
             " of range [1 to 2^32-1]\n", $lineNum;
      $fileErrors++;
      $hexNum = '00000000';

    } else {
      # convert to hex string
      $hexNum = ToHex32($num);

    }

  } else {
    printf "Line %4d: ERROR 37: Loop command must".
           " have number specified\n", $lineNum;;
    $fileErrors++;
    $hexNum = '00000000';

  }

  return $hexNum;
}


# ------------------------------------------------------------------------------
# Get optional EventID field value
#
# ------------------------------------------------------------------------------
sub GetEventIDField {

  my $id;

  if (s/\b(?:0x)?([0-9]{1,8})\b//i) {
    $id = $1;
  } else {
    # default
    $id = 0;
  }
    $id = sprintf("%0${addrBits}X", $id);

  return $id;
}

# ------------------------------------------------------------------------------
# Check invalid fields
#
# Reports any non-whitespace words as errors
# ------------------------------------------------------------------------------
sub CheckInvalidFields {

  my $item;

  # First check for unsupported fields that may be ignored
  if (s/\bdegrant\b//i and $verbose == 1) {

    printf "Line %4d: WARNING 242: DeGrant field is not supported".
           " and will be ignored\n", $lineNum;
    $fileWarnings++;
  }


   # If there is anything but whitespace left on the line, it is invalid.
   # Only report warnings if verbose is requested
   if (($verbose == 1) and /\S/) {

    foreach $item ( split ) {
       printf "Line %4d: WARNING 164: \"$item\" is an".
              " invalid or duplicate field\n", $lineNum;
       $fileWarnings++;
    }
  }
}


# ------------------------------------------------------------------------------
# Check invalid comment
#
# Reports error if comment string is found where not expected
# ------------------------------------------------------------------------------
sub CheckInvalidComment {

  my $item = shift;

  if ($item ne '') {
     printf "Line %4d: WARNING 164: \"$item\" is an".
            " invalid or duplicate field\n", $lineNum;
     $fileWarnings++;
  }
}


# ------------------------------------------------------------------------------
# Increment address
#
# Calculate next address in sequence
#
# ------------------------------------------------------------------------------
sub IncAddr {

  my $incrAddr = hex(shift);
  my $sizeBytes = HsizeToBytes(shift);
  my $burst = shift;

  my $burstLength = 0;
  my $wrapBytes = 0; # number of bytes in burst

  # calculate beats in wrapping bursts
  if ($command{'BUR'} eq '010') {

    $burstLength = 4;

  } elsif ($command{'BUR'} eq '100')  {

    $burstLength = 8;

  } elsif ($command{'BUR'} eq '110')  {

    $burstLength = 16;
  }

  # Address is always incremented from an aligned version
  $incrAddr &= (0xFFFFFFFF - $sizeBytes + 1);

  # Increment address by size of transfer
  $incrAddr += $sizeBytes;

  # Trap boundaries for wrapping bursts
  if ($burstLength > 0) {

    # number of bytes in burst (size * beats)
    $wrapBytes = $sizeBytes * $burstLength;

    if ($incrAddr % $wrapBytes == 0) {
      $incrAddr -= $wrapBytes;
    }
  }

  $incrAddr = ToHex32($incrAddr);


  return $incrAddr;
}


# ------------------------------------------------------------------------------
# Determine the transfer size
#
# Check transfer size integrity
#   Checks there are no discrepancies in transfer size by comparing values of
#    the Size, Data field.
# Assumes Data size not > bus width
# ------------------------------------------------------------------------------

sub CheckSizeData {

  my $bytesBus  = shift;
  my $size      = shift;
  my $data      = shift;
  my $bstrb     = shift;

  # Lengths of fields (in bytes)
  my $bytesSize = $size eq '' ? 0 : HsizeToBytes($size);
  my $bytesData = length($data) >> 1; # Number of bytes is number of hex digits /2
  my $bytesBstrb = length($bstrb);    # Number of bytes is number of binary digits
  my $bytesResult   = 0;

  my $mismatchError = 0;


  # Size field sets size whenever specified
  if ( ($bytesSize > 0) ) {
    $bytesResult = $bytesSize;
  }

  # Data only sets size if data field is specified and
  # size implied by data < busWidth
  if ( ($bytesData > 0)  and ($bytesData < $bytesBus) ) {
    if ($bytesResult == 0) { # resultant size not already set
    # size of data sets transfer size
    $bytesResult = $bytesData;
    } elsif ($bytesResult != $bytesData) {
      $mismatchError = 1; # set mismatch error flag
    }
  }

  # Bstrb only sets size if size implied by Bstrb < busWidth
  if ( ($bytesBstrb > 0) and  ($bytesBstrb < $bytesBus) ) {
    if ($bytesResult == 0) { # resultant size not already set
    # size of Bstrb sets transfer size
    $bytesResult = $bytesBstrb;
    } elsif ($bytesResult != $bytesBstrb)  {
      printf "Line %4d: ERROR 57: Transfer size mismatch:".
             " Check Bstrb\n", $lineNum;
      $fileErrors++;
    }
  }

  # Default resultant size is the bus width
  $bytesResult = $bytesBus unless $bytesResult > 0;

  # Default size is the resultant size
  $bytesSize = $bytesResult unless $bytesSize > 0;

  # If a transfer size mismatch occurred, display Error else
  #  check if Data needs aligning within busWidth
  if ($mismatchError == 1)  {
    printf "Line %4d: ERROR 56: Transfer size mismatch:".
           " Check Size/Data\n", $lineNum;
    $fileErrors++;
  }

  # Convert resultant size back to binary string
  $size = BytesToHsize($bytesSize);

  # Default data if data not specified
  if ($data eq '' ) {
    $bytesData = $bytesBus;  # default data is zero across entire bus
    $data = '0' x ($bytesData << 1); # Number of hex digits is number of bytes *2
  }

  return ($size, $data);

}

# ------------------------------------------------------------------------------
# Shifts the data  to the correct byte lanes
# ------------------------------------------------------------------------------
sub AlignData {

  my $size      = shift;
  my $data      = shift;
  my $address   = shift;

  # Lengths of fields (in bytes)
  my $bytesSize = HsizeToBytes($size);
  my $bytesData = length($data) >> 1; # Number of bytes is number of hex digits /2

  # intermediate variables for data alignment
  my $aligneddata;
  
  # low order address bits
  my $offset;

  # Calculate position within the hex string that the data will start
  $offset = hex($address)
            & (($maxBytesBus-1) << FromBin8($size)) & ($maxBytesBus-1);

  # Modify the offset according to the endianness of the transfer
  $offset = MakeOffsetBigEndian( $offset ) if ($endian eq 'big');

  # Shift the data to the correct byte lanes
  $aligneddata = ShiftData( $data, $bytesData, $offset );

  return $aligneddata;
  
}


# ------------------------------------------------------------------------------
# Shift data into correct byte lanes
# and split into High and Low words
#
#  Assumes 64 bit data representation
# ------------------------------------------------------------------------------
sub ShiftData {

  my $value     = shift;
  my $numLanes  = shift;
  my $offset    = shift;


  my $word;

  # data are zero outside the specified transfer
  my $fullWidth = '00'x($busWidth/8);

  # align the address offset with the length of the data
  $offset &= (0x100 - $numLanes); # Note 0x100 will cope up to HSIZE =1024 bits

  # Shift the data to the correct byte lanes
  substr $fullWidth, ($maxBytesBus-$offset-$numLanes) << 1, $numLanes << 1, $value;
  # Split the data into high and low words
  $word = substr $fullWidth, 0, ($busWidth/4);

  return ($word);
}


# ------------------------------------------------------------------------------
# Check for burst exceeding 1kB boundary
#
# Arguments: HSIZE, HBURST, HADDR, number of transfer to check
# ------------------------------------------------------------------------------
sub Check1kBdy {

  my $transSize = TransSize(shift);
  my $currBurst = shift;
  my $startAddr = hex(shift);
  my $numTransfers = shift;


  # test only non-wrapping bursts
  if  (
        (
          $currBurst eq '000' ||
          $currBurst eq '001' ||
          $currBurst eq '011' ||
          $currBurst eq '101' ||
          $currBurst eq '111'
        )
    # Check that last transfer in burst is within the same 1k partition
    and (
          ( ($numTransfers * $transSize + $startAddr) & hex('FFFFFC00') )
           != ($startAddr & hex('FFFFFC00'))
        )
      ) {
        printf "Line %4d: ERROR 88: Burst would exceed".
               " 1kB boundary : R\n", $lineNum;
        $fileErrors++;
  }
}


# ------------------------------------------------------------------------------
# Convert size field to Number of transfers
#
# ------------------------------------------------------------------------------
sub TransSize {

  my $sizeField = shift;
  my $transSize = 1;

  # assign TransSize
  if    ($sizeField eq '000') {$transSize = 1;}
  elsif ($sizeField eq '001') {$transSize = 2;}
  elsif ($sizeField eq '010') {$transSize = 4;}
  elsif ($sizeField eq '011') {$transSize = 8;}
  elsif ($sizeField eq '100') {$transSize = 16;}
  elsif ($sizeField eq '101') {$transSize = 32;}
  
  return $transSize;
}


# ------------------------------------------------------------------------------
# Check Bstrb and Unalign field integrity
#   Checks there are no discrepancies in values specified by Bstrb and Unalign
#   fields. Also generates correct value of Bstrb where necessary.
#   Returns updated Unalign and Bstrb fields.
#
# Note! this function must be called before $transCount is updated
# ------------------------------------------------------------------------------
sub CheckUnalignBstrb {

  my $address         = shift;
  my $size            = shift;
  my $bstrb           = shift;

  my $offset;
  my $offsetAligned;

  my $numLanesTrans;
  my $numLanesUnalign;

  my $bstrbAligned;
  my $bstrbDefault;
  my $input_shift;


  # Calculate the number of byte lanes in the transfer
  $numLanesTrans = HsizeToBytes($size);

  # Calculate the lower order address bits of an equivalent aligned transfer
  $offsetAligned = $address &
    (($maxBytesBus - 1) << (FromBin8($size))) & ($maxBytesBus - 1);

  # Calculate aligned, little-endian Bstrb which is the default in the FileReadCore
  $bstrbAligned = CalcBstrb($offsetAligned, $numLanesTrans); # Bstrb in FileRdCore

  # Calculate the strobe offset 
  $input_shift = ($address & ~($numLanesTrans - 1)) & 
    (($maxBytesBus - 1) << (FromBin8($size))) & ($maxBytesBus - 1);

  # IF incoming strb is empty set to $bstrbAligned else shift 
  if ($bstrb eq '') {
     $bstrb = ToHex32($bstrbAligned);     
  } else {
     $bstrb = ToHex32(BinToDec(substr('0' x 32 . $bstrb, -32)) << $input_shift);      
  };

  # Convert to 8-digit hex string for output to data file
  $bstrb = substr $bstrb, -8;    ##take the bottom 8 HEX for at most 256 buswidth

  return ($bstrb);
}



# ------------------------------------------------------------------------------
# Calculate Bstrb
#
# Arguments: address offset, number of byte lanes in the transfer
# Output Bstrb is numeric
# ------------------------------------------------------------------------------
sub CalcBstrb {

  my $offset = shift;
  my $numLanesTrans = shift;

  my $bstrb;

  # (1 << $numLanesTrans) - 1) is the correct number of strobes for the transfer,
  # but shifted into the low order end of the data bus. The final shift left
  # by $offset shifts this value into the correct address lanes.
  $bstrb = ((1 << $numLanesTrans) - 1) << $offset;

  return $bstrb;
}

# ------------------------------------------------------------------------------
# Address Alignment Checks
#
# ------------------------------------------------------------------------------
sub CheckAddrAlign {

  my $size = shift;
  my $addr = shift;
  my $unalign = shift;

  my $addrSizeErr;

  # Check if there is an Address/Size mismatch
  #   Tests if address == address & (0xffffffff << 'HSIZE');
  if  ( $addr and (
        ( ($size eq '100') && ($addr !~ /([0-9A-Fa-f]{7})[0]/i) ) or                   
        ( ($size eq '011') && ($addr !~ /([0-9A-Fa-f]{7})[0|8]/i) ) or
        ( ($size eq '010') && ($addr !~ /([0-9A-Fa-f]{7})[0|4|8|C]/i) ) or
        ( ($size eq '001') && ($addr !~ /([0-9A-Fa-f]{7})[0|2|4|6|8|A|C|E|]/i) )
      ) ) {

    $addrSizeErr = 1;

    if ($unalign eq '1' ) {
      # set pending addr/size mismatch error flag
      SetMismatch();

    } else {
      # report error
      ResetMismatch();
      $fileErrors++;
      AddrSizeErrorRpt($size);
    }

  } else {
    $addrSizeErr = 0;

  }

  return $addrSizeErr
}


# ------------------------------------------------------------------------------
# Report address / size mismatch error
#
# ------------------------------------------------------------------------------
sub AddrSizeErrorRpt {

  my $size = shift;

  # check address alignment
  if ($size eq '101')  {
    printf "Line %4d: ERROR 64: Address is not".
           " 256-bit aligned\n", $lineNum;
    $fileErrors++;

  } elsif ($size eq '100')  {
    printf "Line %4d: ERROR 64: Address is not".
           " 128-bit aligned\n", $lineNum;
    $fileErrors++;

  } elsif ($size eq '011')  {
    printf "Line %4d: ERROR 64: Address is not".
           " dword aligned\n", $lineNum;
    $fileErrors++;

  }
    elsif ($size eq '010') {
    printf "Line %4d: ERROR 64: Address is not".
           " word aligned\n", $lineNum;
    $fileErrors++;

  } elsif ($size eq '001') {
    printf "Line %4d: ERROR 64: Address is not".
           " halfword aligned\n", $lineNum;
    $fileErrors++;

  } else {
    printf "Line %4d: ERROR 64: Address is not aligned with size".
           " of transfer\n", $lineNum;
    $fileErrors++;
  }
}



# ------------------------------------------------------------------------------
# Check for early burst termination
#
# Assumes a new burst is starting
# Arguments: Number of transfers remaining
#
# ------------------------------------------------------------------------------
sub CheckBurstTerm {

  my $count = shift;

  # If there are remaining transfers and burst is not expected to be cancelled
  if ( ($verbose == 1) and ($count > 0)) {

    printf "Line %4d: WARNING 216: Burst terminated early by".
           " insufficient Sequence commands\n", $lineNum;
    $fileWarnings++;
  }

  # if pending addr/size mismatch error
  if (GetMismatch() == 1)
  {
    ResetMismatch();
    if ($verbose == 1) {
      printf "Line %4d: WARNING 236: Unaligned transfer crossing address".
             " size boundary.\n", $sequence{'LINE'};
      $fileWarnings++;
    }
  }

}


# ------------------------------------------------------------------------------
# Set burst counters for the remaining number of transfers in a burst
#
# ------------------------------------------------------------------------------
sub SetBurstCount  {

  my $currBurst = shift;
  my $mismatch  = shift;

  my $transCount;
  my $incrCount;

  # Set the bust counters according to the burst type
  if    ($currBurst eq '000') {$transCount = 0;  $incrCount = 0;}  # single
  elsif ($currBurst eq '001') {$transCount = 0;  $incrCount = 1;}  # incr
  elsif ($currBurst eq '010') {$transCount = 3;  $incrCount = 0;}  # wrap4
  elsif ($currBurst eq '011') {$transCount = 3;  $incrCount = 0;}  # incr4
  elsif ($currBurst eq '100') {$transCount = 7;  $incrCount = 0;}  # wrap8
  elsif ($currBurst eq '101') {$transCount = 7;  $incrCount = 0;}  # incr8
  elsif ($currBurst eq '110') {$transCount = 15; $incrCount = 0;}  # wrap16
  elsif ($currBurst eq '111') {$transCount = 15; $incrCount = 0;}  # incr16
  else                        {$transCount = 0;  $incrCount = 1;}  # incr

  # If a defined-length unaligned burst (i.e. not INCR) is taking place,
  # there will be an extra transfer
  if (GetMismatch() == 1 and $currBurst ne '001') {
    $transCount++;
  }

  SetTransCount($transCount);
  SetIncrCount($incrCount);

  return ($transCount, $incrCount);
}


# ------------------------------------------------------------------------------
# Reset burst counters and check for early burst termination
#
# ------------------------------------------------------------------------------
sub ResetBurstCount
{
  # Check that previous burst was not terminated early
  CheckBurstTerm(GetTransCount());

  # Reset the bust counters to zero
  SetTransCount(0);
  SetIncrCount(0);
}

# Set the transCount counter
sub SetTransCount
{
  $transCount = shift;
}

# Decrement the transCount counter
sub DecTransCount
{
  # Only valid to decrement the counter if a burst is in progress
  if ($transCount > 0) {
    $transCount--;
  }
}


# Get the value of the transCount counter
sub GetTransCount
{
  return $transCount;
}

# Increment the incrCount counter
sub IncIncrCount
{
  # Only valid to increment the counter if a burst is in progress
  if ($incrCount > 0) {
    $incrCount++;
  }
}

# Set the Incr counter
sub SetIncrCount
{
  $incrCount = shift;
}


# Get the value of the incrCount counter
sub GetIncrCount
{
  return $incrCount;
}


# ------------------------------------------------------------------------------
# Subroutines to set and reset global flag mismatch
#
# ------------------------------------------------------------------------------
sub SetMismatch
{
  $mismatch = 1;
}

sub ResetMismatch
{
  $mismatch = 0;
}

sub GetMismatch
{
  return $mismatch;
}


# ------------------------------------------------------------------------------
# Calculate memory size required for FileReader
#   Adds up the total number of 32-bit words required to hold the stimulus
#    output
#
# ------------------------------------------------------------------------------
sub CalcMemory {

my $cmd = shift;

  if ($cmd eq 'EMIT' or $cmd eq 'emit' or $cmd eq 'Emit' or $cmd eq 'WAIT' or $cmd eq 'wait' or$cmd eq 'Wait' or
      $cmd eq 'W' or $cmd eq 'R' or $cmd eq 'S' or $cmd eq 'Q') {
      $memorySize++ ;

  } 
}


# ------------------------------------------------------------------------------
# Converts 3-bit binary string representation of Hsize value to number of bytes
#
# ------------------------------------------------------------------------------
sub HsizeToBytes {
  return 1 << unpack("C", pack("B8","00000". shift));}


# ------------------------------------------------------------------------------
# Converts number of bytes to binary string representation of Hsize
#
# ------------------------------------------------------------------------------
sub BytesToHsize {

  my $transferWidth = shift;
  my $size = '';

  if    ($transferWidth == 1) {$size = '000'}
  elsif ($transferWidth == 2) {$size = '001'}
  elsif ($transferWidth == 4) {$size = '010'}
  elsif ($transferWidth == 8) {$size = '011'}
  elsif ($transferWidth == 16) {$size ='100'} 
  elsif ($transferWidth == 32) {$size ='101'}   
  else {
    # Transfer wider than 64 bits not supported - should not happen
    warn "WARNING 254: Unsupported transfer width of $transferWidth bytes".
         " at stimulus line $lineNum\n";
  }
  
  return $size;
}


# ------------------------------------------------------------------------------
# Converts an n-bit binary string to hex with n/4 digits
# Note: Only works for whole bytes.
#
# ------------------------------------------------------------------------------
sub BinToHex {
  unpack('H*', pack('B*', shift));
}
sub BinToDec {
  return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

# ------------------------------------------------------------------------------
# Converts an numeric value to 8 hex digits
#
# ------------------------------------------------------------------------------
sub ToHex32 {
  sprintf("%08X", shift);
}

sub ToHex64 {
  sprintf("%16X", shift);
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
# Output format definitions
#
# ------------------------------------------------------------------------------



## ---------------------------------------------------------------------------------------
# This script will always generate 128 bit for data, and padding zeros depends on $buswidth
# So the output vector file width is fixed
# FUNCTION has 32+16strb bit and ID 32 bit, DELAY 32 bit.

format WRITECMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'ADDRW'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.

format READCMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'ADDRW'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.

format SEQCMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'ADDRW'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.


format EMITCMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'EVENTID'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.


format WAITCMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'EVENTID'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.

format QUITCMD =
@*
sprintf("%0${funcBits}s%0${addrBits}s%0${dataBits}s%0${strbBits}s%0${idBits}s%0${delayBits}s", $command{'FUNCTION'}, $command{'EVENTID'},$command{'DATA'},$command{'BSTRBHEX'},$command{'ID'},$command{'DELAY'})
.
  
__END__
