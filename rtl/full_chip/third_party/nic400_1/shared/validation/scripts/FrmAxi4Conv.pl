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
#  File Date           :  2011-04-12 15:05:02 +0100 (Tue, 12 Apr 2011)
#  File Revision       : 108936
#
#  Release Information : PL401-r1p2-00rel0
#
# ------------------------------------------------------------------------------
#    Purpose: Converts an ASCII stimulus file into a hex format data file
#             suitable for import by the ARM AXI4 File Reader Master.
# ------------------------------------------------------------------------------

package main;

require 5.005;
use strict;
use strict 'refs';
use Getopt::Long;
use IO::Seekable;
use FileHandle;

# ------------------------------------------------------------------------------
# Subroutine prototypes
# ------------------------------------------------------------------------------
sub FromBin8 ($);
sub FromBin128 ($);
sub Lex (\$\@);
sub Parse (\@\%);
sub OutputHex(\%\%*$);
sub Msg($$$;$);
sub OutName(\$\$);
sub hexl ($);

# ------------------------------------------------------------------------------
# Enumerated field values
# ------------------------------------------------------------------------------

# Severity associated with messages
my @severity = qw( FATAL ERROR WARNING INFO DEBUG );


# Enumerations of Size field
my %size = (

  BYTE    => 0,
  SIZE8   => 0,
  HALF    => 1,
  SIZE16  => 1,
  WORD    => 2,
  SIZE32  => 2,
  DWORD   => 3,
  SIZE64  => 3,
  QWORD   => 4,
  SIZE128 => 4,
  SIZE256 => 5,
  SIZE512 => 6,
  SIZE1024 => 7,

);

# Enumerations of Direction field
my %dir = (

  AR      => 0,
  AW      => 1,

);

# Enumerations of Reference field
my %reference = (

  ADDR    => 0,
  ADDR_ID => 0,
  SYNC    => 1,
  WFIRST  => 2,

);

# Enumerations of Burst field
my %burst = (

  FIXED   => 0,
  INCR    => 1,
  WRAP    => 2

);

# Enumerations of Lock field
my %lock = (

  NOLOCK  => 0,
  EXCL    => 1,
  LOCK    => 2

);

# Enumerations of Resp field
# Bits 1:0 are the response. Bits 3:2 are the mask
my %resp = (

  OKAY    => (3<<2)|0,
  EXOKAY  => (3<<2)|1,
  SLVERR  => (3<<2)|2,
  DECERR  => (3<<2)|3,
  IGNORE  => (0<<2)|0
);

# Enumerations of Quit Action field
my %quitaction = (

  IDLE      => 0,
  STOP      => 1,
  TERMINATE => 2,
  EMIT      => 3,
  RESTART   => 4
);

# Enumerations of Check field (poll)
my %check = (
  'NO_POLL' => 0,     # bit 0 indicates polling
  'EQ'      => 1,
  'NE'      => 3      # bit 1 indicates check is NE
);


# ------------------------------------------------------------------------------
# default values for command-line options
# ------------------------------------------------------------------------------
my $verbosity          = 3;              # default 3 is errors & warnings & info
my $help               = 0;              # if true, prints help message and exits
my $busWidth           = 32;             # data bus width of target FRM
my $infile             = 'filestim.m4i'; # input file name
my $outfile            = '';             # output file name stem
my $addrWidth          = 32;             # AddrWidth
my $idWidth            = 8;              # ID bits
my $ewWidth            = 16;              # EW width
my $awUserWidth        = 8;              # AW user width
my $arUserWidth        = 8;              # AR user width
my $wUserWidth         = 8;              # W user width
my $bUserWidth         = 8;              # B user width
my $rUserWidth         = 8;              # R user width
my $UserWidth          = 8;              # Current user width


# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------

# path and name of script
my $scriptname = $0;

my $version    = '1.121'; # File version number
my $fileVersion = 0xC001;

my $addr          = 0;  # Current Transfer address
my $widthBytes    = 1;  # Current Transfer size in bytes
my $remainingW    = 0;  # Remaining write data transfers in burst
my $remainingR    = 0;  # Remaining read data transfers in burst
my $remainingB    = 0;  # Remaining B commands in burst
my $remainingC    = 1;  # Remaining number of comments permitted in a burst
my $currentID     = 0;  # Current ID

my $msgLenMax     = 80; # Maximum length of message field for comment command
my $msgHex        = 0;  # Array of comment chars in 2-char HEX
my $commandWord   = 0;  # packed command bits
my $lineNum       = 0;  # Input file line number

my $skipCmd       = 0;  # If true, does not output converted command

my @msgCount      = (); # Number of messages by severity
my $pendingComment = 0; # Flag pending comment

my $pendingRead    = 0;     # Flag pending read after poll
my $dataBusBytes  = $busWidth >> 3; # Maximum number of bytes on the data bus

my $addrBits      = 8;  # AddrBits (nibbles)
my $addrBitsTop   = 8;  # AddrBits (nibbles)
my $idBits        = 2;  # ID bits nibbles
my $ewBits        = 2;  # Emit wait bus nibbles
my $arUBits       = 2;  # AR user signal bits
my $awUBits       = 2;  # AW user signal bits
my $wUBits        = 2;  # W user signal bits
my $bUBits        = 2;  # B user signal bits
my $rUBits        = 2;  # R user signal bits

# Reference control global variables

# AW Channel
my $NextARCount      = 0;  # Address Write channel next Valid Wait count
my $ARCount          = 0;  # Address Write channel Valid Wait count
my $AWVWaitStim      = 0;  # Address Write channel Valid Wait input file temp
my $AWVWaitHex       = 0;  # Address Write channel Valid Wait output file temp

# AR Channel
my $NextAWCount      = 0;  # Address READ channel next Valid Wait count
my $AWCount          = 0;  # Address READ channel Valid Wait count
my $ARVWaitStim      = 0;  # Address READ channel Valid Wait input file temp
my $ARVWaitHex       = 0;  # Address READ channel Valid Wait output file temp

# W Channel
my $WfirstCount      = 0;  # Next First write data temp
my $NextWfirstCount  = 0;  # First write data temp
my $WlastCount       = 0;  # Write channel Valid Wait total temp
my $WVWaitHex        = 0;  # Write channel Wait output temp
my $WVWaitStim       = 0;  # Write channel Wait input temp

# R Channel
my $RlastCount       = 0;  # Read response valid wait total temp
my $RRWaitHex        = 0;  # Read response valid wait output temp
my $RRWaitStim       = 0;  # Read response valid wait input temp

# B Channel
my $BlastCount       = 0;  # Read response valid wait total temp
my $BRWaitStim       = 0;  # Write response valid wait from input temp
my $BRWaitHex        = 0;  # Write response valid wait for output temp

my $reference        = 0;  # Temp reference value storage
my $firstwdata       = 0;  # Flag for first item of write data
my $locked           = 0;  # Flag a locked transfer (for sync rules)

# Copyright banner
my $banner =
'
================================================================
= This confidential and proprietary software may be used only
= as authorised by a licensing agreement from ARM Limited
=    (C) COPYRIGHT 2002-2013 ARM Limited
=          ALL RIGHTS RESERVED
= The entire notice above must be reproduced on all authorised
= copies and copies may only be made to the extent permitted
= by a licensing agreement from ARM Limited
================================================================
';


# Help message
my $helpText ="Help:

 ================================================================
 Purpose:
   Converts an ASCII stimulus file into a hex format data file
   suitable for import by the ARM AXI4 File Reader Master.

 Usage:
   scriptname [options]

 Options:
    -help                        display this help message
    -verbosity=<0|1|2|3>         0 = display only $severity[0] messages
                                 1 = also display $severity[1] messages
                                 2 = also display $severity[2] messages
                                 3 = also display $severity[3] messages
                                 default = 3
    -busWidth=<32|64|128|256|512|1024>    default = 32
    -infile=<input file>         default = filestim.m4i
    -outfile=<output file stem>  default = filestim
    -addrwidth=<32-64>           default = 32
    -idwidth=<1-32>              default = 8
    -ewwidth=<1-32>              default = 8
    -awUserWidth=<1-32>          default = 8
    -arUserWidth=<1-32>          default = 8
    -wUserWidth=<1-32>           default = 8
    -bUserWidth=<1-32>           default = 8
    -rUserWidth=<1-32>           default = 8
 (Array Sizes:)
    -ARsize                      default = 1000
    -AWsize                      default = 1000
    -Rsize                       default = 4000
    -Wsize                       default = 4000
    -ARmsgsize                   default = 1000
    -AWmsgsize                   default = 1000
 ================================================================

";

# ------------------------------------------------------------------------------
#  Files hash:
#    Stores information relating to the output files.
#      TEXT     : Text to insert in messages to console
#      HANDLE   : Associated with the filehandle tied to the file
#      FILE     : Physical file name
#      FILELEN  : Stores the number of lines in the file
#      FILEEXT  : The extension appended to the input file stem
#      NUMCMDS  : The number of commands in the file
#      MAXLEN   : The maximum length allowed for the file
#      MAXCMDS  : The maximum number of commands allowed in the file
#      WORDSIZE : The width of the command's vector
# ------------------------------------------------------------------------------
my %files = (
  AR => {
    TEXT     => 'Read address  ',
    HANDLE   => 'ARFILE',
    FILE     => '',
    FILELEN  => 0,
    FILEEXT  => '.ar',
    NUMCMDS  => 0,
    MAXLEN   => 1000,
    MAXCMDS  => 1000,
    WORDSIZE => sub {128}
  },

  AW => {
    TEXT     => 'Write address ',
    HANDLE   => 'AWFILE',
    FILE     => '',
    FILELEN  => 0,
    FILEEXT  => '.aw',
    NUMCMDS  => 0,
    MAXLEN   => 1000,
    MAXCMDS  => 1000,
    WORDSIZE => sub {128}
  },

  R => {
    TEXT     => 'Read data     ',
    HANDLE   => 'RFILE',
    FILE     => '',
    FILELEN  => 0,
    FILEEXT  => '.r',
    NUMCMDS  => 0,
    MAXLEN   => 4000,
    MAXCMDS  => 4000,
    WORDSIZE => sub {96 + 2 * $busWidth}
  },

  W => {
    TEXT     => 'Write data    ',
    HANDLE   => 'WFILE',
    FILE     => '',
    FILELEN  => 0,
    FILEEXT  => '.w',
    NUMCMDS  => 0,
    MAXLEN   => 4000,
    MAXCMDS  => 4000,
    WORDSIZE => sub {96 + $busWidth + $dataBusBytes}
  },

  B => {
    TEXT     => 'Write response',
    HANDLE   => 'BFILE',
    FILE     => '',
    FILEEXT  => '.b',
    FILELEN  => 0,
    NUMCMDS  => 0,
    MAXLEN   => 1000,
    MAXCMDS  => 1000,
    WORDSIZE => sub {96}
  },

  CR => {
    TEXT    => 'Read comments ',
    HANDLE  => 'CRFILE',
    FILE    => '',
    FILELEN => 0,
    FILEEXT => '.cr',
    NUMCMDS => 0,
    MAXLEN  => 1000,
    MAXCMDS => 1000,
    WORDSIZE => sub {640}
  },

  CW => {
    TEXT    => 'Write comments',
    HANDLE  => 'CWFILE',
    FILE    => '',
    FILELEN => 0,
    FILEEXT => '.cw',
    NUMCMDS => 0,
    MAXLEN  => 1000,
    MAXCMDS => 1000,
    WORDSIZE => sub {640}
  }

);


# ------------------------------------------------------------------------------
# Lexer for each of the fields
#
# Each entry in this hash is associated with a particular field and is
# an anonymous hash containing details of how to lex that field:
#    NAME    is a text string used for reporting errors with the field
#    SEARCH  is the search pattern for the field
#    CONV    is a function that converts user-entered text into an internal
#             representation (usually numeric) for parsing
#    DEFAULT is the default value of the field (none if field is mandatory)
#    MIN     is the minimum value (before conversion) of the field, if any
#    MAX     is the maximum value (before conversion) of the field, if any
# ------------------------------------------------------------------------------
my %field = (
  ADDR => {
    NAME    => 'Address',
    SEARCH  => '\b(?:0x)?([0-9A-F]{1,16})\b',
    CONV    => sub {shift},
    DEFAULT => '',
  },

  ADDR_TOP => {
    NAME    => 'Address_Top',
    SEARCH  => '\b(?:0x)?([0-9A-F]{1,16})\b',
    CONV    => sub {shift},
    DEFAULT => '',
  },

  DIR => {
    NAME    => 'Direction',
    SEARCH  => '\b(AR|AW)\b',
    CONV    => sub {$dir{uc shift}},
    DEFAULT => ''
  },

  LENGTH => {
    NAME    => 'Length',
    SEARCH  => '\bl(\d{1,3})\b',
    CONV    => sub {shift() - 1},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 256
  },

  SIZE => {
    NAME    => 'Size',
    SEARCH  => '\b(byte|size8|half|size16|word|size32|dword|size64|qward|size128|size256|size512|size1024)\b',
    CONV    => sub {$size{uc shift}},
    DEFAULT => 'byte',
    MAX     => 'size1024' # depends on bus width
  },

  BURST => {
    NAME    => 'Burst',
    SEARCH  => '\b(incr|fixed|wrap)\b',
    CONV    => sub {$burst{uc shift}},
    DEFAULT => 'incr'
  },

  LOCK => {
    NAME    => 'Lock',
    SEARCH  => '\b(nolock|lock|excl)\b',
    CONV    => sub {$lock{uc shift}},
    DEFAULT => 'nolock'
  },

  CACHE => {
    NAME    => 'Cache',
    SEARCH  => '\bc([01]{4})\b',
    CONV    => sub {FromBin8 shift},
    DEFAULT => '0000',
    MIN     => '0000',
    MAX     => '1111'
  },

  PROT => {
    NAME    => 'Prot (protection type)',
    SEARCH  => '\bp([01]{3})\b',
    CONV    => sub {FromBin8 shift},
    DEFAULT => '000',
    MIN     => '000',
    MAX     => '111'
  },

  ID => {
    NAME    => 'ID (master number)',
    SEARCH  => '\bid(?:0x)?([0-9a-f]{1,8})\b',
    CONV    => sub {hex shift},
    DEFAULT => 0x0,
    MIN     => 0x0,
    MAX     => '0xFFFFFFF',
  },

  QOS => {
    NAME    => 'QoS',
    SEARCH  => '\bq(\d{1,2})\b',
    CONV    => sub {shift},
    DEFAULT => 0,
    MIN     => 0,
    MAX     => 15
  },

  REGION => {
    NAME    => 'Region',
    SEARCH  => '\bg(\d{1,2})\b',
    CONV    => sub {shift},
    DEFAULT => 0,
    MIN     => 0,
    MAX     => 15
  },

  USER => {
    NAME    => 'User Signal',
    SEARCH  => '\bU(?:0x)?([0-9A-F]{1,100})\b',
    CONV    => sub {shift},
    DEFAULT => '',
  },

  EMIT => {
    NAME    => 'EMIT',
    SEARCH  => '\bemit(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 0,
    MIN     => 0,
    MAX     => 0xFFFFFFFFFFFFFFFF,
  },

  WAIT => {
    NAME    => 'WAIT',
    SEARCH  => '\bwait(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 0,
    MIN     => 0,
    MAX     => 0xFFFFFFFFFFFFFFFF,
  },

  AVWAIT => {
    NAME    => 'AVWait (AVALID delay)',
    SEARCH  => '\bv(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 0xFFFFFFFF
  },

  RDATA => {
    NAME    => 'Read data',
    SEARCH  => '\b(?:0x)?([0-9A-F]{1,256})\b',
    CONV    => sub {shift},
    DEFAULT => '00'  # default will be modified by parser
  },

  MASK => {
    NAME    => 'Mask',
    SEARCH  => '\bm(?:0x)?([0-9A-F]{1,256})\b',
    CONV    => sub {shift},
    DEFAULT => '00'  # default will be modified by parser
  },

  RRESP => {
    NAME    => 'RResp (read response)',
    SEARCH  => '\b(okay|exokay|slverr|decerr|ignore)\b',
    CONV    => sub {$resp{uc shift}},
    DEFAULT => 'okay'
  },

  RRWAIT => {
    NAME    => 'RRWait (RREADY delay)',
    SEARCH  => '\br(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 0xFFFFFFFF
  },

  WDATA => {
    NAME    => 'Write data',
    SEARCH  => '\b(?:0x)?([0-9A-F]{1,256})\b',
    CONV    => sub {shift},
    DEFAULT => '00'  # default will be modified by parser
  },

  WSTRB => {
    NAME    => 'Strobe (write strobe)',
    SEARCH  => '\bs([01]{1,128})\b',
    CONV    => sub {FromBin128 shift},
    DEFAULT => ''  # default will be set by data alignment parser
   },

  WVWAIT => {
    NAME    => 'WVWait (WVALID delay)',
    SEARCH  => '\bv(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 0xFFFFFFFF
  },

  REPEAT => {
    NAME    => 'Repeats',
    SEARCH  => '\bn(\d{1,8})\b',
    CONV    => sub {shift()},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 16
  },

  BRWAIT => {
    NAME    => 'BRWait (BREADY delay)',
    SEARCH  => '\br(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 1,
    MIN     => 1,
    MAX     => 0xFFFFFFFF
  },

  BRESP => {
    NAME    => 'BResp (write response)',
    SEARCH  => '\b(okay|exokay|slverr|decerr|ignore)\b',
    CONV    => sub {$resp{uc shift}},
    DEFAULT => 'okay',
  },

  TIMEOUT => {
    NAME    => 'Timeout',
    SEARCH  => '\bn(\d{1,10})\b',
    CONV    => sub {shift},
    DEFAULT => 0,
    MIN     => 0,
    MAX     => 0xFFFFFFFF
  },

  MESSAGE => {
    NAME    => 'Message string',
    SEARCH  => '\"(.+)\"',  # no word boundary anchors
    CONV    => sub {shift},
    DEFAULT => '',
  },

  QUITACTION => {
    NAME    => 'Quit action',
    SEARCH  => '\b(restart|terminate|emit|idle|stop)\b',
    CONV    => sub {$quitaction{uc shift}},
    DEFAULT => 'stop'
  },

  COMMENT => {
    NAME    => 'Comment text',
    SEARCH  => '\s*(?:\#|\/\/|;|--)(.*)$', # no word boundary anchors
    CONV    => sub {shift},
    DEFAULT => "\x00"
  },

  REFERENCE => {
    NAME    => 'Reference type',
    SEARCH  => '\b(addr|addr_id|sync|wfirst)\b',
    CONV    => sub {$reference{uc shift}},
    DEFAULT => 'addr'
  },

  CHECK => {
    NAME    => 'Check type',
    SEARCH  => '\b(eq|ne)\b',
    CONV    => sub {$check{uc shift}},
    DEFAULT => 'eq'
  },

  WLAST     => {
    NAME    => 'Wlast Flag',
    VALUE   => 0
  },

  USEEMIT   => {
    NAME    => 'emit after V/R',
    VALUE   => 0
  },

  USEWAIT   => {
    NAME    => 'wait before valid',
    VALUE   => 0
  }

);


# ------------------------------------------------------------------------------
# Rules for the parser with associated messages
#
# Each entry in this hash is associated with a particular rule and is
# an anonymous hash containing details of how to parse for that rule:
#    TEST     Function that returns a boolean value. The rule is only applied if
#             the function evaluates to true.
#               Input: reference to the hash containing the lexer for the fields
#    ACTION   is a function to apply if the test is true
#               Input: reference to the hash containing the lexer for the fields
#    MSG      is a text string used for reporting information about the rule
#    SEVERITY is used to determine if the message should be displayed
#             for the current setting of verbosity.
#
# ------------------------------------------------------------------------------
my %rule = (

  # Check that Address field exists
  REQ_ADDR => {
    TEST      => sub {${shift()}{ADDR}{VALUE_TEXT} eq ''},
    ACTION    => sub {${shift()}{ADDR}{VALUE} = 0; return ''},
    MSG       => 'Address field is required',
    SEVERITY  => 1
  },

  MOD_ADDR => {
    TEST      => sub {1}, # always true
    ACTION    => sub { my $rFields = shift;
                      ${$rFields}{ADDR}{VALUE} = hex (substr ${$rFields}{ADDR}{VALUE_TEXT}, -3);
                      ${$rFields}{ADDR_TOP}{VALUE} = substr ${$rFields}{ADDR}{VALUE_TEXT}, 0, -3;
                      return ''},
    MSG       => 'Determining top address',
    SEVERITY  => 5
  },

  # Set current burst address
  SET_ADDR => {
    TEST      => sub {1}, # always true
    ACTION    => sub {
      $addr = ${shift()}{ADDR}{VALUE};
      return sprintf("%0${addrBits}X", $addr)
    },
    MSG       => 'Set address to',
    SEVERITY  => 4
  },

  # Check that direction field exists
  REQ_DIR => {
    TEST      => sub {${shift()}{DIR}{VALUE_TEXT} eq ''},
    ACTION    => sub {${shift()}{DIR}{VALUE} = 0; return ''},
    MSG       => 'Direction field is required',
    SEVERITY  => 1
  },

  # Set current burst size in bytes
  SET_TRANS_WIDTH => {
    TEST      => sub {1}, # always true
    ACTION    => sub {
      $widthBytes = 1 << ( ${shift()}{SIZE}{VALUE} );
      return $widthBytes << 3
     },
    MSG       => 'Set size (bits) to',
    SEVERITY  => 4
  },

  # Set default RData, Mask, and WData according to size
  SET_SIZE_DEFAULT => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;

      ${$rFields}{RDATA}{DEFAULT} = '00' x $widthBytes;
      ${$rFields}{MASK}{DEFAULT}  = 'FF' x $widthBytes;
      ${$rFields}{WDATA}{DEFAULT} = '00' x $widthBytes;
      return $widthBytes << 3;
    },
    MSG       => 'Set defaults for size',
    SEVERITY  => 4
  },

  # Address / cache ambiguity
  A_AMBIG => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{CACHE}{VALUE_TEXT} eq '' and
      ${$rFields}{ADDR}{VALUE_TEXT} =~ /\bc([01]{4})\b/i
    },
    ACTION    => sub {${shift()}{ADDR}{VALUE_TEXT}},
    MSG       =>
      'Possible Address / Cache confusion. Value treated as address:',
    SEVERITY  => 2
  },

  # Length must be a power of 2 for WRAP bursts
  CHECK_WRAP_LEN => {
    TEST      => sub {
      my $rFields = shift;
      my $length = 1 + ${$rFields}{LENGTH}{VALUE};
      ${$rFields}{BURST}{VALUE} == $burst{WRAP} and
      $length != 2 and
      $length != 4 and
      $length != 8 and
      $length != 16
    },
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{BURST}{VALUE} = $burst{INCR};
      return 1 + ${$rFields}{LENGTH}{VALUE};
    },
    MSG       =>
      'Illegal length for burst type WRAP: INCR will be used instead for burst of length',
    SEVERITY  => 1
  },

  # WRAP bursts must be have aligned start address
  CHECK_WRAP_ALIGN => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{BURST}{VALUE} == $burst{WRAP} and
      ($addr % $widthBytes) != 0
    },
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{BURST}{VALUE} = $burst{INCR};
      return '';
    },
    MSG       =>
      'Address unaligned for burst type WRAP: INCR will be used instead',
    SEVERITY  => 1
  },

  # Check for invalid ACache values
  C_INVALID => {
    TEST      => sub {
      my $cache = ${shift()}{CACHE}{VALUE};
      $cache == 4 or
      $cache == 5 or
      $cache == 8 or
      $cache == 9 or
      $cache == 12 or
      $cache == 13
    },
    ACTION    => sub {${shift()}{CACHE}{VALUE_TEXT}},
    MSG       => 'Illegal cache value',
    SEVERITY  => 2
  },

  # Check that last transfer in burst is within the same 4kB partition
  CHECK_4KB => {
    TEST      => sub
    {
      my $rFields = shift;
      (${$rFields}{BURST}{VALUE} == $burst{INCR}) # only for INCR bursts
      and (
        ($addr & (4096 - $widthBytes)) +  # align address within 4kB partition
        (1 + ${$rFields}{LENGTH}{VALUE}) * $widthBytes
        > 4096
      );
    },
    ACTION    => sub
    {
      ($addr & (4096 - $widthBytes)) +  # align address within 4kB partition
      (1 + ${shift()}{LENGTH}{VALUE}) * $widthBytes
      - 4096
    },
    MSG       => 'Burst exceeds 4kB boundary by',
    SEVERITY  => 1
  },


  # Set remaining transfers in a read burst
  SET_NUM_R => {
    TEST      => sub {${shift()}{DIR}{VALUE} == $dir{AR}},
    ACTION    => sub {
      $remainingW = 0;
      $remainingR = ${shift()}{LENGTH}{VALUE} + 1;
    },
    MSG       => 'Set read burst length to',
    SEVERITY  => 4
  },

  # Set remaining transfers in a write burst
  SET_NUM_W => {
    TEST      => sub {${shift()}{DIR}{VALUE} == $dir{AW}},
    ACTION    => sub {
      $remainingR = 0;
      $remainingW = ${shift()}{LENGTH}{VALUE} + 1
    },
    MSG       => 'Set write burst length to',
    SEVERITY  => 4
  },

  # Set required B command
  SET_NUM_B => {
    TEST      => sub {1},
    ACTION    => sub {
      if (${shift()}{DIR}{VALUE} == $dir{AW}) {
        $remainingB = 1;
      } else {
        $remainingB = 0;
      }
    },
    MSG       => 'Set expected B commands to',
    SEVERITY  => 4
  },

  # Test remaining transfers at start of new burst
  CHECK_LEN_R => {
    TEST      => sub {$remainingR > 0},
    ACTION    => sub {$remainingR},
    MSG       => 'R transfers insufficient by',
    SEVERITY  => 0
  },

  # Test remaining transfers at start of new burst
  CHECK_LEN_W => {
    TEST      => sub {$remainingW > 0},
    ACTION    => sub {$remainingW},
    MSG       => 'W transfers insufficient by',
    SEVERITY  => 0
  },

  # Test for outstanding B command at start of new burst
  CHECK_B => {
    TEST      => sub {$remainingB > 0},
    ACTION    => sub {return ''},
    MSG       => 'Missing B command',
    SEVERITY  => 0
  },

  # Increment current transfer address
  INC_ADDR => {
    TEST      => sub {
      my $rFields = shift;
      (${$rFields}{BURST}{VALUE} == $burst{INCR})
        or (${$rFields}{BURST}{VALUE} == $burst{WRAP})
    },
    ACTION    => sub {
      # Address is incremented from an aligned version
      $addr &= (0xFFFFFFFF - $widthBytes + 1);
      $addr += $widthBytes;
      return sprintf("%08X", $addr)
    },
    MSG       => 'Incremented address to',
    SEVERITY  => 4
  },

  # Wrap address in wrapping bursts
  WRAP_ADDR => {
    TEST      => sub
    {
      my $rFields = shift;
      (${$rFields}{BURST}{VALUE} == $burst{WRAP}) # only for WRAP bursts
      and (
        $addr - ($addr & ($widthBytes * ${$rFields}{LENGTH}{VALUE})) >
        ${$rFields}{ADDR}{VALUE} -
          (${$rFields}{ADDR}{VALUE} &
            ($widthBytes * ${$rFields}{LENGTH}{VALUE}))
      )
    },
    ACTION    => sub {
      $addr -= $widthBytes * (${shift()}{LENGTH}{VALUE}+1);
      return sprintf("%08X", $addr)
    },
    MSG       => 'Transfer address wraps to',
    SEVERITY  => 4
  },

  # Check for RData field length > max
  CHECK_RDATA_MAX => {
    TEST      => sub {length ${shift()}{RDATA}{VALUE} > 2 * $widthBytes},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{RDATA}{VALUE} =
        substr ${$rFields}{RDATA}{VALUE}, -(2 * $widthBytes);
      return ($widthBytes << 3)
    },
    MSG       => 'Length of read data is greater than transfer size',
    SEVERITY  => 1
  },

  # Check for RData field length < min
  CHECK_RDATA_MIN => {
    TEST      => sub {length ${shift()}{RDATA}{VALUE} < 2 * $widthBytes},
    ACTION    => sub {$widthBytes << 3},
    MSG       => 'Mismatch between length of read data and transfer size',
    SEVERITY  => 2
  },

  # Check for Mask field length > max
  CHECK_MASK_MAX => {
    TEST      => sub {length ${shift()}{MASK}{VALUE} > 2 * $widthBytes},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{MASK}{VALUE} =
        substr ${$rFields}{MASK}{VALUE}, -(2 * $widthBytes);
      return ($widthBytes << 3)
    },
    MSG       => 'Length of mask is greater than transfer size',
    SEVERITY  => 1
  },

  # Check for Mask field length < min
  CHECK_MASK_MIN => {
    TEST      => sub {length ${shift()}{MASK}{VALUE} < 2 * $widthBytes},
    ACTION    => sub {$widthBytes << 3},
    MSG       => 'Mismatch between length of mask and transfer size',
    SEVERITY  => 2
  },

  # If no RData field and mask was non-zero, warn and set mask to zero
  CHECK_MASK_RDATA => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{RDATA}{VALUE_TEXT} eq '' and  # No data field
      ${$rFields}{MASK}{VALUE_TEXT} ne '' and  # Mask field
      ${$rFields}{MASK}{VALUE} ne '00' x $widthBytes; # Mask nonzero
    },
    ACTION    => sub {${shift()}{MASK}{VALUE} = '00' x $widthBytes}, # Zero mask
    MSG       => 'No read data: Overridden mask to',
    SEVERITY  => 2
  },

  # If no RData field, set mask to zero
  NO_RDATA => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{RDATA}{VALUE_TEXT} eq '' and  # No data field
      ${$rFields}{MASK}{VALUE_TEXT} eq '';      # No mask field
    },
    ACTION    => sub {${shift()}{MASK}{VALUE} = '00' x $widthBytes}, # Zero mask
    MSG       => 'Set mask to',
    SEVERITY  => 4
  },

  # Decrement remaining R transfers in burst
  DEC_LEN_R => {
    TEST      => sub {${shift()}{DIR}{VALUE} == $dir{AR}},
    ACTION    => sub {$remainingR -= (${shift()}{REPEAT}{VALUE})},
    MSG       => 'Decreased remaining R transfers to',
    SEVERITY  => 4
  },

  # Check remaining R transfers in burst
  TOO_MANY_R => {
    TEST      => sub {$remainingR < 0},
    ACTION    => sub {$remainingR = 0; return ''},
    MSG       => 'Repeats greater than remaining R transfers',
    SEVERITY  => 0
  },

  # Check for unexpected R transfers in burst
  UNEXP_R => {
    TEST      => sub {$remainingR == 0},
    ACTION    => sub {return ''},
    MSG       => 'Unexpected R transfer',
    SEVERITY  => 0
  },

  # Check EXOKAY response matches lock type
  CHECK_RRESP => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{RRESP}{VALUE} == $resp{EXOKAY} and  # EXOKAY response
      ${$rFields}{LOCK}{VALUE} != $lock{EXCL}         # not exclusive transfer
    },
    ACTION    => sub {${shift()}{RRESP}{VALUE} = $resp{OKAY}; return 'OKAY'},
    MSG       => 'EXOKAY response can be given only to an exclusive access. Set response to',
    SEVERITY  => 2
  },

  # Check WStrb not specified outside size x address frame,
  # including for unaligned accesses
  CHECK_WSTRB => {
    TEST      => sub {
      my $wstrbTemp = hex ${shift()}{WSTRB}{VALUE};
      $wstrbTemp ne '' and
      (((1 << ($addr & ($widthBytes - 1))) - 1) & $wstrbTemp) != 0;
    },
    ACTION    => sub {''},
    MSG       => 'Write strobe asserted outside size x address frame',
    SEVERITY  => 2
  },

  # If no WData field, set WStrb to zero
  CHECK_WSTRB_WDATA => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{WDATA}{VALUE_TEXT} eq '' and  # No data field
      ${$rFields}{WSTRB}{VALUE_TEXT} ne '' and  # WStrb field
      ${$rFields}{WSTRB}{VALUE} ne '0'; # WStrb nonzero
    },
    ACTION    => sub {
      ${shift()}{WSTRB}{VALUE} = '0'; # Zero WStrb
      return ('0' x $widthBytes)
    },
    MSG       => 'No write data: Overridden write strobe to',
    SEVERITY  => 2
  },

  # Check for WData field length > max
  CHECK_WDATA_MAX => {
    TEST      => sub {length ${shift()}{WDATA}{VALUE_TEXT} > 2 * $widthBytes},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{WDATA}{VALUE} =
        substr ${$rFields}{WDATA}{VALUE}, -(2 * $widthBytes);
      return ($widthBytes << 3)
    },
    MSG       => 'Length of write data is greater than transfer size',
    SEVERITY  => 1
  },

  # Check for WData field length < min
  CHECK_WDATA_MIN => {
    TEST      => sub {
      my $wdata = ${shift()}{WDATA}{VALUE_TEXT};
      $wdata ne '' and length $wdata < 2 * $widthBytes
    },
    ACTION    => sub {$widthBytes << 3},
    MSG       => 'Mismatch between length of write data and transfer size',
    SEVERITY  => 2
  },

  # Check for WStrb field length > max
  CHECK_WSTRB_MAX => {
    TEST      => sub {length ${shift()}{WSTRB}{VALUE_TEXT} > $widthBytes},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{WSTRB}{VALUE} =
        FromBin128 substr ${$rFields}{WSTRB}{VALUE_TEXT}, -$widthBytes;
      return ($widthBytes << 3)
    },
    MSG       => 'Length of write strobe is greater than transfer size',
    SEVERITY  => 1
  },

  # Check for WStrb field length < min
  CHECK_WSTRB_MIN => {
    TEST      => sub {
      my $wstrb = ${shift()}{WSTRB}{VALUE_TEXT};
      $wstrb ne '' and length $wstrb < $widthBytes
    },
    ACTION    => sub {$widthBytes << 3},
    MSG       => 'Mismatch between length of write strobe and transfer size',
    SEVERITY  => 2
  },

  # Decrement remaining W transfers in burst
  DEC_LEN_W => {
    TEST      => sub {1},
    ACTION    => sub {--$remainingW},
    MSG       => 'Decreased remaining W transfers to',
    SEVERITY  => 4
  },

  # Check remaining W transfers in burst
  TOO_MANY_W => {
    TEST      => sub {$remainingW < 0},
    ACTION    => sub {$remainingW = 0; return ''},
    MSG       => 'Repeats greater than remaining W transfers',
    SEVERITY  => 0
  },

  # Check for unexpected W transfers in burst
  UNEXP_W => {
    TEST      => sub {$remainingW == 0},
    ACTION    => sub {return ''},
    MSG       => 'Unexpected W transfer',
    SEVERITY  => 0
  },

  # Decrement remaining B transfers in burst
  DEC_B => {
    TEST      => sub {${shift()}{DIR}{VALUE} == $dir{AW}},
    ACTION    => sub {--$remainingB},
    MSG       => 'Decreased remaining B transfers to',
    SEVERITY  => 4
  },

  # Check that B transfer was expected
  UNEXP_B => {
    TEST      => sub {$remainingB <= 0},
    ACTION    => sub {$remainingB = 0; return ''},
    MSG       => 'Unexpected B transfer',
    SEVERITY  => 0
  },

  # Check EXOKAY response matches lock type
  CHECK_BRESP => {
    TEST      => sub {
      my $rFields = shift;
      ${$rFields}{BRESP}{VALUE} == $resp{EXOKAY} and  # EXOKAY response
      ${$rFields}{LOCK}{VALUE} != $lock{EXCL}         # not exclusive transfer
    },
    ACTION    => sub {${shift()}{BRESP}{VALUE} = $resp{OKAY}; return 'OKAY'},
    MSG       => 'EXOKAY response can be given only to an exclusive access. Set response to',
    SEVERITY  => 2
  },

  # Set default fields for address commands
  SET_ADDR_DEFAULTS => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{REPEAT}{VALUE}  = 1;  # address commands do not repeat
      ${$rFields}{CHECK}{VALUE}   = $check{NO_POLL};
      return '';
    },
    MSG       => 'Set A command defaults',
    SEVERITY  => 4
  },

  # Set default fields for B commands
  SET_B_DEFAULTS => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{REPEAT}{VALUE}  = 1;  # B commands do not repeat
      return '';
    },
    MSG       => 'Set B command defaults',
    SEVERITY  => 4
  },


  # Set default fields for Poll command
  SET_POLL_DEFAULTS => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      ${$rFields}{DIR}{VALUE}     = $dir{AR};
      ${$rFields}{LENGTH}{VALUE}  = 0;
      ${$rFields}{BURST}{VALUE}   = $burst{INCR};
      ${$rFields}{LOCK}{VALUE}    = $lock{NOLOCK};
      ${$rFields}{REPEAT}{VALUE}  = 1;
      $reference                  = $reference{ADDR};
      # set SYNC command fields to zero
      ${$rFields}{WSTRB}{VALUE_ALIGNED} = '0' x ($dataBusBytes >> 2);
      ${$rFields}{WDATA}{VALUE_ALIGNED} = '00' x $dataBusBytes;
      ${$rFields}{RDATA}{VALUE_ALIGNED} = '00' x $dataBusBytes;
      ${$rFields}{MASK}{VALUE_ALIGNED}  = '00' x $dataBusBytes;
      return '';
    },
    MSG       => 'Set poll defaults',
    SEVERITY  => 4
  },

  FLAG_COMMENT => {
    TEST      => sub {$remainingC},
    ACTION    => sub {
      $pendingComment = 1;                  # Flag a pending comment
      $skipCmd = 1;                         # Skip over comment command to print after direction is established
    },
    MSG       => 'Flag comment ',
    SEVERITY  => 4
  },

  # Set permitted number of comments at end of previous burst
  SET_NUM_C => {
    TEST      => sub {$remainingR == 0 and $remainingW == 0 and $remainingB == 0},
    ACTION    => sub {$remainingC = 1},
    MSG       => 'Set permitted C commands to',
    SEVERITY  => 4
  },

  # Check for unexpected comment in burst
  UNEXP_C => {
    TEST      => sub {$remainingC == 0},
    ACTION    => sub {$skipCmd = 1; return ''},
    MSG       => 'Only one comment per burst is permitted. Previous comment ignored.',
    SEVERITY  => 2
  },

  # Decrement remaining permitted comments in burst
  DEC_C => {
    TEST      => sub {$remainingC},
    ACTION    => sub {--$remainingC},
    MSG       => 'Decreased remaining C commands to',
    SEVERITY  => 4
  },

  # Check that message field exists
  REQ_MSG => {
    TEST      => sub {${shift()}{MESSAGE}{VALUE} eq ''},
    ACTION    => sub {${shift()}{MESSAGE}{VALUE} = ' '; return ''},
    MSG       => 'A string within double quotes is required',
    SEVERITY  => 1
  },

  # Check message length
  CHECK_LEN_MSG => {
    TEST      => sub {length ${shift()}{MESSAGE}{VALUE} > $msgLenMax},
    ACTION    => sub {
      my $rFields = shift;
      substr( ${$rFields}{MESSAGE}{VALUE}, $msgLenMax) = '';
      return '"'.${$rFields}{MESSAGE}{VALUE}.'"'
    },
    MSG       =>
      'Message is greater than maximum length and will be truncated to',
    SEVERITY  => 2
  },

  # Check for valid characters in message
  CHECK_MSG_CHARS => {
    TEST      => sub {
      ${shift()}{MESSAGE}{VALUE} =~
        s/[^\x20-\x7e]/\-/g
    },
    ACTION    => sub {'"'.${shift()}{MESSAGE}{VALUE}.'"'},
    MSG       =>
      'Invalid character(s) in message replaced by \'-\'. New message is',
    SEVERITY  => 2
  },

  # Convert message string to up to 20 32-bit hex strings
  # The message string is first padded with 3 null characters
  PACK_MSG => {
    TEST      => sub {$remainingC}, # if comment is allowed
    ACTION    => sub {
      $msgHex = unpack ('H160', ${shift()}{MESSAGE}{VALUE});
      return '';
    },
    MSG       => 'Converted message string to hex',
    SEVERITY  => 4
  },

  # Any non whitespace left on line
  INVALID_FIELD => {
    TEST      => sub {/\S/ },
    ACTION    => sub {join ', ', split},
    MSG       => 'Invalid or duplicate field(s):',
    SEVERITY  => 2
  },

  # Put write data in correct byte lanes
  ALIGN_WDATA => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      my $offset  = 2*($addr & (($dataBusBytes-1) << ${$rFields}{SIZE}{VALUE}) & ($dataBusBytes-1));
      ${$rFields}{WDATA}{VALUE_ALIGNED} = ${$rFields}{WDATA}{VALUE}.'0' x $offset;
      ${$rFields}{WDATA}{VALUE_ALIGNED} = sprintf "%0*s", $busWidth >> 2, ${$rFields}{WDATA}{VALUE_ALIGNED};
      return ${$rFields}{WDATA}{VALUE_ALIGNED}
    },
    MSG       => 'Aligned write data:',
    SEVERITY  => 4
  },

  # Put read data in correct byte lanes
  ALIGN_RDATA => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      my $offset  = 2*($addr & (($dataBusBytes-1) << ${$rFields}{SIZE}{VALUE}) & ($dataBusBytes-1));
      ${$rFields}{RDATA}{VALUE_ALIGNED} = ${$rFields}{RDATA}{VALUE}.'0' x $offset;
      ${$rFields}{RDATA}{VALUE_ALIGNED} = sprintf "%0*s", $busWidth >> 2, ${$rFields}{RDATA}{VALUE_ALIGNED};
      return ${$rFields}{RDATA}{VALUE_ALIGNED};
    },
    MSG       => 'Aligned read data:',
    SEVERITY  => 4
  },

  # Put mask in correct byte lanes
  ALIGN_MASK => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      my $offset  = 2*($addr & (($dataBusBytes-1) << ${$rFields}{SIZE}{VALUE}) & ($dataBusBytes-1));
      ${$rFields}{MASK}{VALUE_ALIGNED} = ${$rFields}{MASK}{VALUE}.'0' x $offset;
      ${$rFields}{MASK}{VALUE_ALIGNED} = sprintf "%0*s", $busWidth >> 2, ${$rFields}{MASK}{VALUE_ALIGNED};
      return ${$rFields}{MASK}{VALUE_ALIGNED};
    },
    MSG       => 'Aligned mask:',
    SEVERITY  => 4
  },

  # Calculate default WStrb
  DEFAULT_WSTRB => {
    TEST      => sub {${shift()}{WSTRB}{VALUE_TEXT} eq ''},
    ACTION    => sub {
      my $rFields = shift;
      my $DefaultWstrb;
      if (${$rFields}{WDATA}{VALUE_TEXT} eq '') { # No WData
        $DefaultWstrb = '0' x $widthBytes;        # Zero WStrb
      } else {
        my $tempNumStrobe = ($addr & ($widthBytes - 1));
        $DefaultWstrb = '1' x ($widthBytes - $tempNumStrobe).'0' x $tempNumStrobe;
      }
      ${$rFields}{WSTRB}{VALUE} = FromBin128 ($DefaultWstrb);
      return $DefaultWstrb;
    },
    MSG       => 'Set default WStrb to:',
    SEVERITY  => 4
  },

  # Ensure strobes are correct for the byte lanes being used
  ALIGN_WSTRB => {
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      my $offset  = $addr & (($dataBusBytes-1) << ${$rFields}{SIZE}{VALUE}) & ($dataBusBytes-1);
      my $wstrb   = ${$rFields}{WSTRB}{VALUE};
      #${$rFields}{WSTRB}{VALUE_ALIGNED} = sprintf "%0*x", ($busWidth / 32), $wstrb << $offset;
      #cannot use the above logic for large coz the shift goes wrong when $offset>31
      my $offset1 = $offset % 4;
      my $offset2 = ($offset - $offset1)/4;
      if ($offset > 0) {
        $wstrb  = hex ($wstrb) * (1 << $offset1);
        $wstrb  = ToHex128 ($wstrb);
      }
      ${$rFields}{WSTRB}{VALUE_ALIGNED} = sprintf "%0*s", ($busWidth / 32), $wstrb.'0' x $offset2;
      return sprintf "addr: %X offset: %d strb in: %s strb out: %s",
                $addr, $offset, $wstrb, ${$rFields}{WSTRB}{VALUE_ALIGNED};
    },
    MSG       => 'Align strobes',
    SEVERITY  => 4
  },

  # Inform that Q command found and no more lines will be processed
  INFO_Q => {
    TEST      => sub {1},   # always true
    ACTION    => sub {''},  # nothing to do
    MSG       => 'Quit command found: file conversion ended',
    SEVERITY  => 4
  },

  # Inform that end of file found without a quit command
  INFO_EOF => {
    TEST      => sub {1},   # always true
    ACTION    => sub {''},  # nothing to do
    MSG       => 'End of file found: file conversion ended.',
    SEVERITY  => 3
  },

  # Change reference type to default if 'wfirst' was used in read transaction
  UNEXP_WFIRST => {
    TEST      => sub {
          my $rFields = shift;
          ${$rFields}{DIR}{VALUE} == $dir{AR} and
          ${$rFields}{REFERENCE}{VALUE} == $reference{WFIRST};
          },
    ACTION    => sub {
          my $rFields = shift;
          ${$rFields}{REFERENCE}{VALUE} = $reference{ADDR};
          return '';
          },
    MSG       => 'Reference type wfirst cannot be assigned to read bursts. Set reference to addr',
    SEVERITY  => 1
  },

  # Reset the cumulative wait counters
  RESET_COUNTERS => {
    TEST      => sub {!$skipCmd},   # Only if not skipCmd                       ###
    ACTION    => sub {
      # Reset all temp counters
      $NextARCount     = 0;
      $ARCount         = 0;
      $NextAWCount     = 0;
      $AWCount         = 0;
      $WfirstCount     = 0;
      $NextWfirstCount = 0;
      $RlastCount      = 0;
      return '';
      },
    MSG       => 'Reset cumulative wait counters',
    SEVERITY  => 4
  },

  # Choose reference time based on reference type of burst
  SET_REFERENCE => {
    TEST      => sub {1},
    ACTION    => sub {

        my $rFields  = shift;
        $ARCount     = $NextARCount;
        $AWCount     = $NextAWCount;
        $WfirstCount = $NextWfirstCount;
        $RlastCount  = 0;
        $WlastCount  = 0;

        if ( ${$rFields}{REFERENCE}{VALUE} == $reference{ADDR} ) {      # If reference addr
          if( ${$rFields}{DIR}{VALUE} == $dir{AR} ) {
            $reference = $ARCount;
          } else {
            $reference = $AWCount;
          }
        } elsif ( ${$rFields}{REFERENCE}{VALUE} == $reference{WFIRST} ) {
          $reference = $WfirstCount;
        } else { # reference sync
          $reference = 0;
        }
      },
    MSG       => 'Set reference time for transaction to ',
    SEVERITY  => 4
  },


  # Calculate cumulative ARVWait counter
  CALC_ARVWAIT => {
    TEST      => sub {

        my $rFields = shift;
        ${$rFields}{DIR}{VALUE} == $dir{AR}
      },
    ACTION    => sub {
        my $rFields = shift;
        $ARVWaitStim = ${$rFields}{AVWAIT}{VALUE};                      # read input
        $ARVWaitHex = $ARVWaitStim + $reference;                        # assign output on reference and input
        $NextARCount = $ARVWaitHex;                                     # update next counter
        return sprintf "%s", ${$rFields}{AVWAIT}{VALUE};
      },
    MSG       => 'Cumulative ARVWait value: ',
    SEVERITY  => 4
  },

  # Calculate cumulative AWVWait count
  CALC_AWVWAIT => {
    TEST      => sub {
        my $rFields = shift;
        ${$rFields}{DIR}{VALUE} == $dir{AW}
        },
    ACTION    => sub {
        my $rFields = shift;
        $AWVWaitStim = ${$rFields}{AVWAIT}{VALUE};                      # read input
        $AWVWaitHex = $AWVWaitStim + $reference;                        # assign output on reference and input
        $NextAWCount = $AWVWaitHex;                                     # update next counter
        $firstwdata = 1;                                                # Flag first data item
        return sprintf "%s", $AWVWaitHex;
      },
    MSG       => 'Cumulative AWVWait value: ',
    SEVERITY  => 4
  },
  # Calculate cumulative RRWait count
  CALC_RRWAIT => {
    TEST      => sub {1},   # Always
    ACTION    => sub {
      my $rFields = shift;
      $RRWaitStim = ${$rFields}{RRWAIT}{VALUE};                         # Assign input
      $RRWaitHex  = $reference + $RRWaitStim + $RlastCount;             # assign output from ARV, input and wait total
      $RlastCount = $RRWaitStim + $RlastCount;                          # update total for repeat abs. time tracking
      return sprintf "%s", ${$rFields}{RRWAIT}{VALUE};
    },
    MSG       => 'Cumulative RR Wait value: ',
    SEVERITY  => 4
  },

  # Calculate cumulative WVWait count
  CALC_WVWAIT => {
    TEST      => sub {1},   # Always
    ACTION    => sub {
      my $rFields = shift;
      $WVWaitStim = ${$rFields}{WVWAIT}{VALUE};                         # assign input
      $WVWaitHex = $reference + $WVWaitStim + $WlastCount;              # assign output from AWV, WVWait and input
      $WlastCount = $WVWaitStim + $WlastCount;                          # update total for repeat abs. time tracking
      return sprintf "%s", ${$rFields}{WVWAIT}{VALUE};

    },
    MSG       => 'Cumulative WV Wait value: ',
    SEVERITY  => 4
  },

  # Calculate cumulative BRWAIT count
  CALC_BRWAIT => {                                                      # Write response channel
    TEST      => sub {1},
    ACTION    => sub {
      my $rFields = shift;
      $BRWaitStim = ${$rFields}{BRWAIT}{VALUE};                         # assign input
      $BRWaitHex = $BRWaitStim + $reference;                            # assign output on AWVWait counter and Input
      $BlastCount = $BRWaitStim + $BlastCount;                          # update total for repeat abs. time tracking
      return sprintf "%s", ${$rFields}{BRWAIT}{VALUE};
    },
    MSG       => 'Cumulative BR Wait signal: ',
    SEVERITY  => 4
  },

  # Set WFirst reference time
  CALC_WFIRST => {
    TEST      => sub {$firstwdata == 1},
    ACTION    => sub {

      my $rFields = shift;
      $WVWaitStim = ${$rFields}{WVWAIT}{VALUE};                         # assign input
      $NextWfirstCount = $reference + $WVWaitStim;                      # incr next first w
      $firstwdata = 0;
      return sprintf "%s", $NextWfirstCount;
    },
    MSG       => 'Next wfirst reference at: ',
    SEVERITY  => 4
  },

  # Set or clear the flag bit in the command word of the last item of w data
  SET_WLAST_FLAG => {
    TEST      => sub {1},
    ACTION    => sub { my $rFields = shift;
      ${$rFields}{WLAST}{VALUE} = ($remainingW == 0) ? 1 : 0;
    },
    MSG       => "Set wlast to: ",
    SEVERITY  => 4
  },

  # Set EMIT_ON if EMIT != ""
  CHECK_EMIT_ON => {

    TEST      => sub { 1 },
    ACTION    => sub { my $rFields = shift;
      ${$rFields}{USEEMIT}{VALUE} = 0;
      if (${$rFields}{EMIT}{VALUE} != 0) {
            ${$rFields}{USEEMIT}{VALUE} = 1;
      };
    },
    MSG       => "USE_EMIT calculated",
    SEVERITY  => 4
  },

  # Set WAIT_ON if WAIT != ""
  CHECK_WAIT_ON => {

    TEST      => sub { 1 },
    ACTION    => sub { my $rFields = shift;
      ${$rFields}{USEWAIT}{VALUE} = 0;
      if (${$rFields}{WAIT}{VALUE} != 0) {
            ${$rFields}{USEWAIT}{VALUE} = 1;
      };
    },
    MSG       => "USE_WAIT calculated",
    SEVERITY  => 4
  },

  EW_REPEAT => {
    TEST      => sub {
             my $rFields = shift;
      (${$rFields}{USEWAIT}{VALUE} == 1 or   # WAIT set
       ${$rFields}{USEEMIT}{VALUE} == 1) and
       ${$rFields}{REPEAT}{VALUE} > 1
    },
    ACTION    => sub { my $rFields = shift;
                  ${$rFields}{USEWAIT}{VALUE} = 0;
                  ${$rFields}{USEEMIT}{VALUE} = 0; },
    MSG       => "EMIT and WAIT cannot be used on repeated data beats",
    SEVERITY  => 1
  },

  POLL_WAIT => {
    TEST      => sub {
             my $rFields = shift;
      ${$rFields}{USEWAIT}{VALUE} == 1 and   # WAIT set
      $pendingRead == 1
    },
    ACTION    =>  sub { my $rFields = shift;
                  ${$rFields}{USEWAIT}{VALUE} = 0; },
    MSG       => "Cannot wait on a polled read",
    SEVERITY  => 1
  }


);



# ------------------------------------------------------------------------------
# The main data structure
#
# This hash stores all the data needed to process each command.
# LEX   is a reference to an array containing a list of references to hashes
#       which contain details of all the fields that can be specified for the
#       command. The use of an array enforces the processing order.
# PARSE is a reference to an array containing a list of references to hashes
#       which contain details of all the rules that must be applied for the
#       command. The use of an arrays enforces the processing order.
#
# ------------------------------------------------------------------------------
my %command = (

  A => {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{ADDR},
      $field{DIR},
      $field{LENGTH},
      $field{SIZE},
      $field{BURST},
      $field{LOCK},
      $field{CACHE},
      $field{PROT},
      $field{ID},
      $field{QOS},
      $field{REGION},
      $field{USER},
      $field{AVWAIT},
      $field{REFERENCE},
      $field{EMIT},
      $field{WAIT}
    ],
    PARSE => [
      $rule{CHECK_LEN_W},
      $rule{CHECK_LEN_R},
      $rule{CHECK_B},
      $rule{REQ_ADDR},
      $rule{MOD_ADDR},
      $rule{REQ_DIR},
      $rule{CHECK_WRAP_LEN},
      $rule{SET_ADDR},
      $rule{SET_TRANS_WIDTH},
      $rule{CHECK_WRAP_ALIGN},
      $rule{SET_ADDR_DEFAULTS},
      $rule{SET_NUM_R},
      $rule{SET_NUM_W},
      $rule{SET_NUM_B},
      $rule{A_AMBIG},
      $rule{C_INVALID},
      $rule{CHECK_4KB},
      $rule{SET_SIZE_DEFAULT},
      $rule{UNEXP_WFIRST},
      $rule{SET_REFERENCE},
      $rule{CALC_ARVWAIT},
      $rule{CALC_AWVWAIT},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
      $rule{CHECK_WAIT_ON}
     ]
  },


  R => {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{RDATA},
      $field{MASK},
      $field{RRESP},
      $field{RRWAIT},
      $field{REPEAT},
      $field{EMIT},
      $field{USER},
      $field{WAIT}
     ],
    PARSE => [
      $rule{UNEXP_R},
      $rule{DEC_LEN_R},
      $rule{TOO_MANY_R},
      $rule{SET_NUM_C},
      $rule{CHECK_RDATA_MAX},
      $rule{CHECK_RDATA_MIN},
      $rule{CHECK_MASK_MAX},
      $rule{CHECK_MASK_MIN},
      $rule{CHECK_MASK_RDATA},
      $rule{NO_RDATA},
      $rule{CHECK_RRESP},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
      $rule{CHECK_WAIT_ON},
      $rule{EW_REPEAT},
      $rule{POLL_WAIT}
     ],
    REPEAT_RULES => [
      $rule{ALIGN_RDATA},
      $rule{ALIGN_MASK},
      $rule{INC_ADDR},
      $rule{WRAP_ADDR},
      $rule{CALC_RRWAIT},
     ]
  },


  W => {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{WDATA},
      $field{WSTRB},
      $field{WVWAIT},
      $field{REPEAT},
      $field{EMIT},
      $field{WAIT},
      $field{USER}
     ],
    PARSE => [
      $rule{UNEXP_W},
      $rule{TOO_MANY_W},
      $rule{CHECK_WDATA_MAX},
      $rule{CHECK_WDATA_MIN},
      $rule{CHECK_WSTRB_MAX},
      $rule{CHECK_WSTRB_MIN},
      #$rule{CHECK_WSTRB}, #disable for large bus width number problem
      $rule{CHECK_WSTRB_WDATA},
      $rule{CALC_WFIRST},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
      $rule{CHECK_WAIT_ON},
      $rule{EW_REPEAT}
    ],
    REPEAT_RULES => [
      $rule{ALIGN_WDATA},
      $rule{DEFAULT_WSTRB},
      $rule{ALIGN_WSTRB},
      $rule{INC_ADDR},
      $rule{WRAP_ADDR},
      $rule{CALC_WVWAIT},
      $rule{DEC_LEN_W},
      $rule{SET_WLAST_FLAG},
    ]
  },


  B => {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{BRESP},
      $field{BRWAIT},
      $field{EMIT},
      $field{WAIT},
      $field{USER}
     ],
    PARSE => [
      $rule{UNEXP_B},
      $rule{DEC_B},
      $rule{SET_NUM_C},
      $rule{CHECK_BRESP},
      $rule{SET_B_DEFAULTS},
      $rule{CALC_BRWAIT},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
      $rule{CHECK_WAIT_ON}
     ]
  },


  P =>  {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{ADDR},
      $field{SIZE},
      $field{CACHE},
      $field{PROT},
      $field{ID},
      $field{AVWAIT},
      $field{CHECK},
      $field{TIMEOUT},
      $field{EMIT},
      $field{WAIT},
      $field{USER}
     ],
    PARSE => [
      $rule{CHECK_LEN_W},
      $rule{CHECK_LEN_R},
      $rule{CHECK_B},
      $rule{REQ_ADDR},
      $rule{MOD_ADDR},
      $rule{SET_POLL_DEFAULTS},
      $rule{SET_ADDR},
      $rule{SET_TRANS_WIDTH},
      $rule{SET_NUM_R},
      $rule{SET_NUM_B},
      $rule{A_AMBIG},
      $rule{C_INVALID},
      $rule{SET_SIZE_DEFAULT},
      $rule{RESET_COUNTERS},
      $rule{CALC_ARVWAIT},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
      $rule{CHECK_WAIT_ON}
     ],
    POST_PARSE => [
      $rule{RESET_COUNTERS},
    ]
  },

  C =>  {
    LEX => [
      $field{MESSAGE}, # get quoted string first,
      $field{COMMENT}  # before stripping comments
     ],
    PARSE => [
      $rule{UNEXP_C},
      $rule{FLAG_COMMENT},
      $rule{REQ_MSG},
      $rule{CHECK_LEN_MSG},
      $rule{CHECK_MSG_CHARS},
      $rule{PACK_MSG},
      $rule{DEC_C},
      $rule{INVALID_FIELD}
    ]
  },


  S =>  {
    LEX => [
      $field{COMMENT},  # strip comments
      $field{EMIT},
      $field{WAIT}
    ],
    PARSE => [
      $rule{RESET_COUNTERS},
      $rule{INVALID_FIELD},
      $rule{CHECK_EMIT_ON},
    ]
  },


  Q =>  {
    LEX => [
      $field{COMMENT}, # strip comments first
      $field{QUITACTION}
     ],
    PARSE => [
      $rule{CHECK_LEN_W},
      $rule{CHECK_LEN_R},
      $rule{CHECK_B},
      $rule{INVALID_FIELD},
      $rule{INFO_Q}
    ]
  },


  # Checks that must be made at end of file, if the last command is not Q
  EOF => {
    PARSE => [
      $rule{CHECK_LEN_W},
      $rule{CHECK_LEN_R},
      $rule{CHECK_B},
      $rule{INFO_EOF}
    ]
  }

);


# ------------------------------------------------------------------------------
# Output format definitions by command
#
# Each entry in this hash is associated with a particular field and is
# an anonymous hash containing details of how to lex that field:
#    CMDWORD is a function that packs fields into the command word
#               Input: reference to the hash containing the lexer for the fields
#    FORMAT  is a the name of the Perl format to use
#    LENGTH  is the number of words in the hex output file
#    FILES   is an anonymous hash listing the output files for the command
# ------------------------------------------------------------------------------
my %output = (

  AR => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        $pendingComment               << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        ${$rFields}{USEWAIT}{VALUE}   << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        ${$rFields}{LENGTH}{VALUE}    << 13 |       # Length:     8 bits
        ${$rFields}{SIZE}{VALUE}      << 21 |       # Size:       3 bits
        ${$rFields}{LOCK}{VALUE}      << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        ${$rFields}{BURST}{VALUE}     << 27 |       # Burst:      2 bits
        ${$rFields}{PROT}{VALUE}      << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AR' => 'ARFORMAT' }
  },

  AW => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        $pendingComment               << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        ${$rFields}{USEWAIT}{VALUE}   << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        ${$rFields}{LENGTH}{VALUE}    << 13 |       # Length:     8 bits
        ${$rFields}{SIZE}{VALUE}      << 21 |       # Size:       3 bits
        ${$rFields}{LOCK}{VALUE}      << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        ${$rFields}{BURST}{VALUE}     << 27 |       # Burst:      2 bits
        ${$rFields}{PROT}{VALUE}      << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AW' => 'AWFORMAT' }
  },


  W => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        ${$rFields}{USEWAIT}{VALUE}   << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   2 bits
        ${$rFields}{WLAST}{VALUE}     << 14         # WLAST Flag: 1 bit
      )
    },
    LENGTH    => 1,
    FILES     => { 'W' => 'WFORMAT' }
  },


  R => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        ${$rFields}{USEWAIT}{VALUE}   << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   2 bits
        ${$rFields}{RRESP}{VALUE}     << 14         # Response:   2 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'R' => 'RFORMAT' }
  },


  B => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        ${$rFields}{USEWAIT}{VALUE}   << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   2 bits
        ${$rFields}{BRESP}{VALUE}     << 14         # Response:   2 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'B' => 'BFORMAT' }
  },



  CR => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        15                          << 28 |       # Cmd code:   4 bits
        (length ${$rFields}{MESSAGE}{VALUE})
                                                  # Num chars:  7 bits
        )
    },
    LENGTH    => 1,
    FILES     => { 'CR' => 'CFORMAT' }
  },


  CW => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        15                          << 28 |       # Cmd code:   4 bits
        (length ${$rFields}{MESSAGE}{VALUE})
                                                  # Num chars:  7 bits
        )
    },
    LENGTH    => 1,
    FILES     => { 'CW' => 'CFORMAT' }
  },

  S => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        1                             << 0  |       # Sync:       1 bit
        1                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        0                             << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        0                             << 13 |       # Length:     8 bits
        0                             << 21 |       # Size:       3 bits
        0                             << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        0                             << 27 |       # Burst:      2 bits
        0                             << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AR' => 'SARFORMAT',
                   'AW' => 'SAWFORMAT',
                   'W'  => 'SWFORMAT',
                   'R'  => 'SRFORMAT',
                   'B'  => 'SBFORMAT' }
  },


  # Implied Sync command does not reset counters.
  # to be combined with 'S' later and masked, as with 'P'
  VS => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        1                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        0                             << 10 |       # Emit:       1 bit
        0                             << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        0                             << 13 |       # Length:     8 bits
        0                             << 21 |       # Size:       3 bits
        0                             << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        0                             << 27 |       # Burst:      2 bits
        0                             << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AR' => 'SARFORMAT',
                   'AW' => 'SAWFORMAT',
                   'W'  => 'SWFORMAT',
                   'R'  => 'SRFORMAT',
                   'B'  => 'SBFORMAT' }
  },

  # Poll Sync command. Does reset counters.
  # to be combined with 'S' later and masked, as with 'P'
  PS => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        1                             << 0  |       # Sync:       1 bit
        1                             << 1  |       # Reset timer:1 bit
        ${$rFields}{CHECK}{VALUE}     << 2  |       # Poll:       3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        0                             << 10 |       # Emit:       1 bit
        0                             << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        0                             << 13 |       # Length:     8 bits
        0                             << 21 |       # Size:       3 bits
        0                             << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        0                             << 27 |       # Burst:      2 bits
        0                             << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AR' => 'SARFORMAT',
                   'AW' => 'SAWFORMAT',
                   'W'  => 'SWFORMAT',
                   'R'  => 'PSRFORMAT',
                   'B'  => 'SBFORMAT' }
  },

  PR => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        0                             << 0  |       # Sync:       1 bit
        0                             << 1  |       # Reset timer:1 bit
        ${$rFields}{CHECK}{VALUE}     << 2  |       # Poll/Check: 3 bits
        0                             << 5  |       # Quit:       1 bit
        0                             << 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        ${$rFields}{USEEMIT}{VALUE}   << 10 |       # Emit:       1 bit
        0                             << 11 |       # Reserved:   1 bit
        0                             << 12 |       # Reserved:   2 bits
        ${$rFields}{RRESP}{VALUE}     << 14         # Response:   2 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'R' => 'RFORMAT' }
  },


  Q => {
    CMDWORD => sub {
      my $rFields = shift;
      return (
        1                             << 0  |       # Sync:       1 bit
        1                             << 1  |       # Reset timer:1 bit
        0                             << 2  |       # Poll:       3 bits
        1                             << 5  |       # Quit:       1 bit
        ${$rFields}{QUITACTION}{VALUE}<< 6  |       # Quit action:3 bits
        0                             << 9  |       # Comment:    1 bit
        0                             << 10 |       # Emit:       1 bit
        0                             << 11 |       # Wait:       1 bit
        0                             << 12 |       # Reserved:   1 bit
        0                             << 13 |       # Length:     8 bits
        0                             << 21 |       # Size:       3 bits
        0                             << 24 |       # Lock:       2 bits
        0                             << 26 |       # Reserved:   1 bit
        0                             << 27 |       # Burst:      2 bits
        0                             << 29         # Prot:       3 bits
      )
    },
    LENGTH    => 1,
    FILES     => { 'AR' => 'SARFORMAT',
                   'AW' => 'SAWFORMAT',
                   'W'  => 'SWFORMAT',
                   'R'  => 'SRFORMAT',
                   'B'  => 'SBFORMAT' }
  }

);


# ------------------------------------------------------------------------------
# Subroutine Lex()
# Searches a string for a list of fields

#
# Inputs:
#   The name of the text input string to be searched. If a field is found,
#     it is deleted from the input string.
#   The name of an array of references to the fields to be found.
# Outputs
#   Updates the (global) values of the fields that are listed
#
# ------------------------------------------------------------------------------
sub Lex(\$\@) {

  my $line = shift;
  my $fields = shift;

  foreach my $rField ( @$fields ) {

    my $value = '';

    # The inner hash is given by %{$rField}
    $$line =~ s/${$rField}{SEARCH}//i and $value = $1;

    # Store the actual text of the field in the hash,
    # for reporting and field length checks
    ${$rField}{VALUE_TEXT} = $value;

    # Set default if field not found
    $value eq '' and $value = ${$rField}{DEFAULT};

    if ($value ne '') {

      # Call the conversion function
      $value = ${$rField}{CONV}->($value);

      # Check max limit of the field (if any)
      if (exists ${$rField}{MAX} and
        ($value > ${$rField}{CONV}->(${$rField}{MAX}))) {

        # Set value to maximum
        $value = ${$rField}{CONV}->(${$rField}{MAX});

        # report errors
        Msg(
          ${$rField}{NAME}.' '.${$rField}{VALUE_TEXT}.
            ' greater than maximum value '.${$rField}{MAX},
          1,  # severity
          $verbosity,
          $.
        );
      }

      # Check min limit of the field (if any)
      if (exists ${$rField}{MIN} and
        $value < ${$rField}{CONV}->(${$rField}{MIN})) {

        # report errors
        Msg(
          ${$rField}{NAME}.' '.${$rField}{VALUE_TEXT}.
            ' less than minimum value '.${$rField}{MIN},
          1,  # severity
          $verbosity,
          $.
        );
      }
    }

    # Store value in the hash
    ${$rField}{VALUE} = $value;

    # print the value of the fields for debug
    printf "%-30s = %20s%20s\n",
      ${$rField}{NAME},
      ${$rField}{VALUE_TEXT},
      ${$rField}{VALUE}
    if $verbosity >= 6;

  }
}


# ------------------------------------------------------------------------------
# Subroutine Parse()
# Applies a list of rules
#
# Input
#   The name of an array of references to the rules to be applied
# If the test associated with the rule evaluates to true, the action associated
# with the rule is applied.
#   The name of an hash containing the fields of the commands.
# Outputs
#  The rules update the global hash %fields
#  The rules may also update other global variables
# ------------------------------------------------------------------------------
sub Parse(\@\%) {

  my $rules = shift;
  my $rFields = shift;

  # Apply each of the rules, in order
  foreach my $rRule ( @$rules ) {

    # Test if rule applies
    if (${$rRule}{TEST}->($rFields)) {

      # Do the action associated with the rule
      #  and save any return vRalue for reporting
      my $msg = ${$rRule}{ACTION}->($rFields);

      # Print message belonging to rule
      Msg(
        ${$rRule}{MSG}.' '.$msg,
        ${$rRule}{SEVERITY},
        $verbosity,
        $.
      );

    }
  }
}

# ------------------------------------------------------------------------------
# Subroutine OutputHex
# Write a vector to the output (hex) file
#
# Inputs
#   The name of a hash containing the fields of the commands.
#   The name of a hash containing the output format definitions
#   Output file handle
# Output
#   The number of words added to the output file
#
# ------------------------------------------------------------------------------
sub OutputHex(\%\%*$)  {

  my $rFields   = shift;
  my $rFormat   = shift;
  my $outHandle = shift;
  my $file      = shift; # list of file and format

  # Calculate number of words in the hex file
  my $len = eval(${$rFormat}{LENGTH});

  # Pack the command bits
  $commandWord = ${$rFormat}{CMDWORD}->($rFields);

  # save output format and handle so that they can be restored
  my $savedFormat = $~;
  my $savedFileHandle = select STDOUT;

  Msg("Output File is $$outHandle\n", 4, $verbosity);

  # select output stimulus format for current command type
  select $outHandle;
  $~ = ${$rFormat}{FILES}{$file}; # Value is format, key is filetype
    
  write ($outHandle);

  # reset format and output stream
  select STDOUT;
  $~ = $savedFormat;
  
  # return the number of words added to the stimulus file
  return $len
}

# ------------------------------------------------------------------------------
#
# Stimulus file processing
#
# Commands are detected by searching for the first non-whitespace character on
# a line.
# For each command, fields are recognised by the lexer.
# Next, the parser applies the rules appropriate to the command and any
# associated messages are displayed, depending on the selected verbosity.
# Finally, each vector is converted to hex format and written to the output
# file.
#
# Inputs
#   The name of the main data structure, containing parser and lexer
#   The name of a hash containing the fields of the commands.
#   The name of a hash containing the output format definitions
#   The name of a hash containing the output file definitions
#   Input file handle
# Output
#   The number of words in the output file
#   The number of commands in the input file
#
# ------------------------------------------------------------------------------
sub ProcessFile (\%\%\%\%*) {

  my $rCommand    = shift;
  my $rFields     = shift;
  my $rFormat     = shift;
  my $rFiles      = shift;
  my $inHandle    = shift;
  my $appendSync  = 0;     # Flag to append sync (used in locked bursts)
  my $file;                # foreach loop hash key variable
  my $cmd          = '';   # Name of the current command
  my $pendingsync = 0;     # Flag pending sync
  $lineNum        = 0;     # Line number counter reset

  # Process each line of stimulus
  # while there are lines remaining to be read from the file
  while (<$inHandle>) {

    # Reject common cases early
    next if (/^\s*$/);              # Ignore lines that are blank
    next if (/^\s*(?:#|\/\/|;|--)/);# Ignore lines that contain only a comment

    # Display current line for debug
    print "\n$_" if $verbosity >= 5;

    # Get command
    if(
      (s/^\s*(W|R|B|C|Q|S|P|Sync|Poll|Read|Write|Buffer|Comment|Quit)\b//i) or
      (/^\s*(AR|AW)\b/i) # do not remove AW, AR from input string, so that these can be picked up by DIR field
    ) {
      $cmd = uc substr($1,0,1);

      $UserWidth = 1;
      if ($cmd eq "AW") { $UserWidth = $awUserWidth; };
      if ($cmd eq "AR") { $UserWidth = $arUserWidth; };
      if ($cmd eq "P")  { $UserWidth = $arUserWidth; };
      if ($cmd eq "W")  { $UserWidth = $wUserWidth; };
      if ($cmd eq "B")  { $UserWidth = $bUserWidth; };
      if ($cmd eq "R")  { $UserWidth = $rUserWidth; };

      Msg(
        "Found command $cmd",
        4, $verbosity, $.
      );

    } else  {
      # Fatal error if command not known
      Msg(
        'Unknown command in file',
        0, $verbosity, $.
      );
      last;
    }

    # Reset skip command output flag
    $skipCmd = 0;

    # Keep track of stimulus file line numbers for error reporting
    $lineNum = $.;

    # Get fields
    Lex $_, @{${$rCommand}{$cmd}{LEX}};

    # Apply rules
    Parse @{${$rCommand}{$cmd}{PARSE}}, %$rFields;

    # Check if command is to be skipped in output file
    unless ($skipCmd) {

      #-------------------------------------------
      # Insert SYNC commands in locked sequences
      #-------------------------------------------
      if($cmd eq 'A') {

        # Final Sync Command, based on first A* after (nolock) end of locked sequence
        if($appendSync) {

          # Add a sync to each file
          # @{$rFormat}{$cmd}{FILES} is list of filehandles
          foreach $file ( keys %{${$rFormat}{VS}{FILES}} ) {
            $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{VS}}, $files{$file}{HANDLE}, $file;
            $files{$file}{NUMCMDS}++;
          }

          # Clear the appendsync flag
          $appendSync = 0;
        }

        # First LOCK occurence. Prepend SYNC, set $locked.
        if(( ${$rFields}{LOCK}{VALUE} eq $lock{LOCK}) and ($locked == 0)) {

          # Flag a locked burst
          $locked = 1;

          # Add a sync to each file
          foreach $file ( keys %{${$rFormat}{VS}{FILES}} ) {
            $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{VS}}, $files{$file}{HANDLE}, $file;
            $files{$file}{NUMCMDS}++;
          }

        }

        # Final LOCK in sequence is marked NOLOCK. Prepend and append SYNC. Clear locked flag
        if(( ${$rFields}{LOCK}{VALUE} eq $lock{NOLOCK}) and ($locked == 1) ) {

          # Clear locked burst flag
          $locked = 0;

          # Set appendsync flag to ensure a final sync is added
          $appendSync = 1;

          # Add a sync to each file
          foreach $file ( keys %{${$rFormat}{VS}{FILES}} ) {
            $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{VS}}, $files{$file}{HANDLE}, $file;
            $files{$file}{NUMCMDS}++;
          }

        }
      }

      if($cmd eq 'Q' and ($field{QUITACTION}{VALUE} == $quitaction{EMIT})) {

        $field{USEEMIT}{VALUE} = 0;

        foreach $file ( keys %{${$rFormat}{S}{FILES}} ) {
          if ($file ne 'AW') {
             print $file;
             $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{S}}, $files{$file}{HANDLE}, $file;
             $files{$file}{NUMCMDS}++;
          }
        }

        #Turn on emit
        $field{USEEMIT}{VALUE} = 1;
        $field{EMIT}{VALUE} = 0;

        #Add EMIT to AW channel
        $files{'AW'}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{S}}, $files{AW}{HANDLE}, 'AW';
        $files{'AW'}{NUMCMDS}++;

        #Return values
        $field{USEEMIT}{VALUE} = 0;
        $field{QUITACTION}{VALUE} = $quitaction{IDLE};
      }

      #-------------------------------------------
      # Insert SYNC commands before POLL commands
      #-------------------------------------------

      if($cmd eq 'P') {

        foreach $file ( keys %{${$rFormat}{PS}{FILES}} ) {
          # Sync Command needs timeout in wait field and poll bits set
          $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{PS}}, $files{$file}{HANDLE}, $file;
          $files{$file}{NUMCMDS}++;
        }

        foreach $file ( keys %{${$rFormat}{AR}{FILES}} ) {
          $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{AR}}, $files{$file}{HANDLE}, $file;
          $files{$file}{NUMCMDS}++;
        }

        $pendingRead = 1;
      }

      #-----------------------------------
      # Unroll repeated vectors
      #-----------------------------------
      for
        (1 .. (
          ($cmd eq 'R' or $cmd eq 'W')? # only R and W commands can be repeated
            ($field{REPEAT}{VALUE}) :
            1
         ) ) {

        # Parse repeat_rules
        Parse @{${$rCommand}{$cmd}{REPEAT_RULES}}, %$rFields;

        # print AR to readstim file
        if (($cmd eq 'A') and ( $field{DIR}{VALUE} == $dir{AR} )) {
          $cmd = 'AR';
        }

        # print AW to readstim file
        if (($cmd eq 'A') and ( $field{DIR}{VALUE} == $dir{AW} ) ) {
          $cmd = 'AW';
        }

        if (($pendingRead) and ( $cmd eq 'R' )) {
          $pendingRead = 0;
          $cmd = 'PR';
        }


        #-----------------------------------
        # Print command to relevant outputs
        #-----------------------------------
        foreach $file ( keys %{${$rFormat}{$cmd}{FILES}} ) {
          $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{$cmd}}, $files{$file}{HANDLE}, $file;
          $files{$file}{NUMCMDS}++;
        }

        # Parse post_rules
        Parse @{${$rCommand}{$cmd}{POST_PARSE}}, %$rFields;

      }

      #-----------------
      # Insert Comments
      #-----------------
      # If a comment is pending print it to the appropriate comment file
      if($pendingComment && ($cmd eq 'AW' | $cmd eq 'AR' | $cmd eq 'P')) {

        # Clear flag
        $pendingComment = 0;

        # Determine direction and output file
        my $cdir = ($cmd eq 'AW') ? 'CW' : 'CR';

        # Print the comment to the appropriate files
        foreach $file ( keys %{${$rFormat}{$cdir}{FILES}} ) {
          $files{$file}{FILELEN} += OutputHex %$rFields, %{${$rFormat}{$cdir}}, $files{$file}{HANDLE}, $file;
          $files{$file}{NUMCMDS}++;
        }
      }

      # Stop processing file if Q command is found
      last if $cmd eq 'Q';

    }
  }

  $cmd ne 'Q' and Parse @{${$rCommand}{EOF}{PARSE}}, %$rFields;

  return;

}

# ------------------------------------------------------------------------------
# Subroutine Msg()
# Prints an error/warning message if allowed by current verbosity setting
# Exits if severity is Fatal
#
# Inputs:
#   message to be printed
#   severity of message
#   current verbosity
#   line number (may be omitted)
#
# ------------------------------------------------------------------------------
sub Msg($$$;$) {

  my $message = shift;
  my $sev = shift;
  my $verb = shift;
  my $line = shift;

  # increment global message count by severity
  $msgCount[$sev]++;

  if ($verb >= $sev) {

    # Print asterisks so that severity shows up
    # printf  "%-7s ", '*'x(3-$sev);

    # Prepend scriptname
    printf  "%s ", $scriptname;

    # Display the severity
    printf  "%-7s ", $severity[$sev];

    # Print input file line number, if any
    printf  "Line %4d: ", $line
      if $line;

    # Print the message string
    printf "%s\n", $message;

  }

  # Exit on fatal error
  exit(-1) if ($sev == 0);

}


# ------------------------------------------------------------------------------
# Subroutine FromBin8()
# Converts a string of up to 8 bits binary to a number
#
# Note: Wraps at 256 decimal
# ------------------------------------------------------------------------------
sub FromBin8($) {
  unpack('C', pack('B8', substr('0' x 8 . shift, -8)));
}

# ------------------------------------------------------------------------------
# Subroutine FromBin128()
# Converts a string of up to 128 bits binary to a number
#
# ------------------------------------------------------------------------------


sub FromBin128($) {
 my $binValue = substr('0' x 128 . shift, -128);
 my $bin;
 my $i;
 my $hex;
 for ( $i=0; $i<32; $i=$i+1 ) {
   $bin = substr($binValue, $i*4, 4);
   $hex .= unpack('H', pack('B4', $bin));
 }
 return  substr($hex, -$busWidth/32);
}


# ------------------------------------------------------------------------------
# Subroutine ToHex128()
# Converts a large number to up to 128 bits Hex
#
# ------------------------------------------------------------------------------

sub ToHex128($) {
 my $DecValue = shift;
 my $TmpValue;
 my $HexValue = '';
 while ($DecValue >= 4294967296) {

    $TmpValue = $DecValue % 4294967296;
    $DecValue = ($DecValue - $TmpValue) / 4294967296;
    $TmpValue = sprintf "%08X",$TmpValue;
    $HexValue = $TmpValue.$HexValue;
 }
  $TmpValue = sprintf "%X",$DecValue;
  $HexValue = $TmpValue.$HexValue;

  return $HexValue;
}

# ------------------------------------------------------------------------------
# Subroutine OutName()
# Calculate output filename stem (i.e. without .ext)
#Base
# If output filename stem is specified, it is used without modification.
# If output filename stem is not already specified, output filename is set to
# input file name with the last extension stripped.
#
# Copes with multiple '.' characters in input filename:
#   e.g. input file 'test.1.in' -> output filename stem 'test.1'
#
# Inputs
#   Input filename
#   Output filename stem
#
# ------------------------------------------------------------------------------
sub OutName(\$\$) {

my ($infile, $outfile) = @_;
my $file; # foreach loop hash key variable

  # calculate default output file name stem, if not specified
    $$infile =~ /^(.*)\.[^.]*$/ and
    $$outfile = $1 or
    $$outfile = $$infile
      if ($$outfile eq '');

  # calculate output file names by appending fixed extensions to the
  # output filename stem
  foreach $file ( keys %files ) {
    $files{$file}{FILE} = $$outfile.$files{$file}{FILEEXT};
  }

}


# ------------------------------------------------------------------------------
#
# START OF MAIN PROGRAM
#
# Parses the command line
# Calls function to process file
# Prints a summary
#
# ------------------------------------------------------------------------------
my $cmd;
my $counter;

# Get run time / date
my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
$year += 1900;
$mon  += 01;


# Parse the command line
GetOptions(
            "help|?"               => \$help,
            "verbosity=i"          => \$verbosity,
            "infile=s"             => \$infile,
            "outfile=s"            => \$outfile,
            "ARsize=i"             => \$files{AR}{MAXLEN},
            "AWsize=i"             => \$files{AW}{MAXLEN},
            "Rsize=i"              => \$files{R}{MAXLEN},
            "Wsize=i"              => \$files{W}{MAXLEN},
            "ARMsgsize=i"          => \$files{CR}{MAXLEN},
            "AWMsgsize=i"          => \$files{CW}{MAXLEN},
            "buswidth=i"           => \$busWidth,
            "addrwidth=i"          => \$addrWidth,
            "idwidth=i"            => \$idWidth,
            "ewwidth=i"            => \$ewWidth,
            "arUserWidth=i"        => \$arUserWidth,
            "awUserWidth=i"        => \$awUserWidth,
            "rUserWidth=i"         => \$rUserWidth,
            "bUserWidth=i"         => \$bUserWidth,
            "wUserWidth=i"         => \$wUserWidth
        );

# Error if anything else left on the command line
Msg( "Unknown option: \"".join(' ', @ARGV)."\"\n\n".$helpText, 0, $verbosity )
  unless @ARGV == 0;

# Print help text and exit
$help == 1 and
  Msg( $helpText, 0, $verbosity ); # Help message


# Calculate output file name
OutName($infile, $outfile);

# Set size of the B channal array equal to the size of the AW channel array
# as each B command corresponds with an AW command.
  $files{B}{MAXLEN} = $files{AW}{MAXLEN};

# Print program banner
Msg( $banner, 3, $verbosity );
Msg( 'Version        '.$version, 3, $verbosity );


# Print run date and time
Msg( sprintf (
        "Run Date       %02d/%02d/%04d %02d:%02d:%02d",
        $mday, $mon, $year, $hour, $min, $sec
     ),
     3, $verbosity );

# Fatal error if input and output filenames are not the same
# (only occurs when input file uses reserved file extension)
foreach $cmd ( keys %files ) {
  unless ( $infile ne $files{$cmd}{FILE} ) {
    Msg( "Input and output file names $infile are identical", 0, $verbosity );
  }
}

# Open input file or fatal error if fails
open(INFILE, "$infile") or
  Msg(
    "Input file $infile does not exist or cannot be accessed", 0, $verbosity );
# Open READ output file or fatal error if fails, copy handle to Files hash
open(AWFILE, ">$files{AW}{FILE}") or Msg( "Cannot create output file $files{AW}{FILE}", 0, $verbosity );
$files{AW}{HANDLE} = \*AWFILE;
open(ARFILE, ">$files{AR}{FILE}") or Msg( "Cannot create output file $files{AR}{FILE}", 0, $verbosity );
$files{AR}{HANDLE} = \*ARFILE;
open(RFILE, ">$files{R}{FILE}") or Msg( "Cannot create output file $files{R}{FILE}", 0, $verbosity );
$files{R}{HANDLE} = \*RFILE;
open(WFILE, ">$files{W}{FILE}") or Msg( "Cannot create output file $files{W}{FILE}", 0, $verbosity );
$files{W}{HANDLE} = \*WFILE;
open(BFILE, ">$files{B}{FILE}") or Msg( "Cannot create output file $files{B}{FILE}", 0, $verbosity );
$files{B}{HANDLE} = \*BFILE;
open(CWFILE, ">$files{CW}{FILE}") or Msg( "Cannot create output file $files{CW}{FILE}", 0, $verbosity );
$files{CW}{HANDLE} = \*CWFILE;
open(CRFILE, ">$files{CR}{FILE}") or Msg( "Cannot create output file $files{CR}{FILE}", 0, $verbosity );
$files{CR}{HANDLE} = \*CRFILE;

# Extract setting from file
while (<INFILE>) {
    if (/^\s*#FRM#/) {

          my $setting = $_;
          
          #Datawidth
          if ($setting =~ /[Dd]ata[Ww]idth=([0-9]*)/) {
              Msg( sprintf ("Overriding Datawidth with %d", $1), 3, $verbosity);
              $busWidth = $1;
          };

          #Addrwidth
          if ($setting =~ /[Aa]ddress[Ww]idth=([0-9]*)/) {
              Msg( sprintf ("Overriding Address width with %d", $1), 3, $verbosity);
              $addrWidth = $1;
          };

          #IDwidth
          if ($setting =~ /[Ii][Dd][Ww]idth=([0-9]*)/) {
              Msg( sprintf ("Overriding ID width with %d", $1), 3, $verbosity);
              $idWidth = $1;
          };

          #User-Widths
          if ($setting =~ /[Aa][Ww][Uu]ser[Ww]idth=([0-9]*)/) {
              Msg( sprintf ("Overriding AW User width with %d", $1), 3, $verbosity);
              $awUserWidth = $1;
          } elsif ($setting =~ /[Aa][Rr][Uu]ser[Ww]idth=([0-9]*)/) {
               Msg( sprintf ("Overriding AR User width with %d", $1), 3, $verbosity);
              $arUserWidth = $1;
          } elsif ($setting =~ /[Rr][Uu]ser[Ww]idth=([0-9]*)/) {
               Msg( sprintf ("Overriding R User width with %d", $1), 3, $verbosity);
              $rUserWidth = $1;
          } elsif ($setting =~ /[Ww][Uu]ser[Ww]idth=([0-9]*)/) {
               Msg( sprintf ("Overriding W User width with %d", $1), 3, $verbosity);
              $wUserWidth = $1;
          } elsif ($setting =~ /[Bb][Uu]ser[Ww]idth=([0-9]*)/) {
               Msg( sprintf ("Overriding B User width with %d", $1), 3, $verbosity);
              $bUserWidth = $1;
          };

    };
};

#Go back to the beginning of the file
close(INFILE);
open(INFILE, "$infile");

# Set the maximum addr according to the address width
$counter = int($addrWidth / 4);
#$field{ADDR}{MAX} = '0x';
$addrBits = 0;
#if (($addrWidth - ($counter * 4)) == 1) {$field{ADDR}{MAX} = $field{ADDR}{MAX} . '1'; $addrBits++;};
#if (($addrWidth - ($counter * 4)) == 2) {$field{ADDR}{MAX} = $field{ADDR}{MAX} . '3'; $addrBits++;};
#if (($addrWidth - ($counter * 4)) == 3) {$field{ADDR}{MAX} = $field{ADDR}{MAX} . '7'; $addrBits++;};

while ($counter > 0) {
#    $field{ADDR}{MAX} = $field{ADDR}{MAX} . 'F';
    $addrBits++;
    $counter--;
};
$addrBitsTop = $addrBits - 3;


# Determine the number of nibbles used for the ID bus
$counter = int($idWidth / 4);
$idBits = $counter + (($idWidth - ($counter * 4)) > 0);

# Determine the number of bits for the emit wait buses
$counter = int($ewWidth / 4);
$ewBits = $counter + (($ewWidth - ($counter * 4)) > 0);

# Determine the number of bits for the User buses
$counter = int($awUserWidth / 4);
$awUBits = $counter + (($awUserWidth - ($counter * 4)) > 0);
$counter = int($arUserWidth / 4);
$arUBits = $counter + (($arUserWidth - ($counter * 4)) > 0);
print "HI\n";
print $ewBits . "\n";
print $idBits . "\n";
print "HI\n";
$counter = int($wUserWidth / 4);
$wUBits = $counter + (($wUserWidth - ($counter * 4)) > 0);
$counter = int($bUserWidth / 4);
$bUBits = $counter + (($bUserWidth - ($counter * 4)) > 0);
$counter = int($rUserWidth / 4);
$rUBits = $counter + (($rUserWidth - ($counter * 4)) > 0);

# Fatal error if invalid busWidth has not been entered
($busWidth == 32) or ($busWidth == 64) or ($busWidth == 128) or ($busWidth == 256) or ($busWidth == 512) or ($busWidth == 1024) or
  Msg( 'Data bus width must be 32 or 64 or 128 or 256 bits', 0, $verbosity );

# Set the maximum size according to the buswidth
$field{SIZE}{MAX} = $busWidth == 1024 ? 'SIZE1024' :
                    $busWidth == 512 ? 'SIZE512' :
                    $busWidth == 256 ? 'SIZE256' :
                    $busWidth == 128 ? 'SIZE128' :
                    $busWidth == 64  ? 'DWORD' : 'WORD';

# Set the maximum number of bytes on the data bus
$dataBusBytes = $busWidth >> 3;

# Info on options selected
# Display input file name
Msg( "Input file:    $infile", 3, $verbosity );

# Display output filenames
foreach $cmd ( keys %files ) {
  Msg( $files{$cmd}{TEXT}." ".$files{$cmd}{FILE}, 3, $verbosity );
}
Msg( "Data bus width $busWidth", 3, $verbosity );


# Write the header word to the file
foreach $cmd ( keys %files ) {
  select $files{$cmd}{HANDLE};
  printf ("// Header word\n%08X\n", ($fileVersion << 16) | $size{uc $field{SIZE}{MAX}} );
}
select STDOUT; # Return output stream to console

# Process the file
ProcessFile( %command, %field, %output, %files, \*INFILE );


# End of file statistics
Msg( 'Conversion complete', 3, $verbosity );

# Number of commands
foreach $cmd ( sort keys %files ) {
  Msg( sprintf( $files{$cmd}{TEXT}." commands         %4i", $files{$cmd}{NUMCMDS} ), 4, $verbosity );
}


# Number of words in hex file
foreach $cmd ( sort keys %files ) {
  Msg( sprintf( $files{$cmd}{TEXT}." Stimulus array size required %4i x %3s bit words", $files{$cmd}{FILELEN}, $files{$cmd}{WORDSIZE}->() ),
  3, $verbosity );
}

# Generate an error if more words in file than space in FRM array
foreach $cmd ( sort keys %files ) {
  if ( $files{$cmd}{FILELEN}  > $files{$cmd}{MAXLEN} ) {
    Msg( "File size exceeds specified ".$files{$cmd}{TEXT}." stimulus array size", 1, $verbosity );
  }
}

# Summary of error/warning messages
  Msg(
    sprintf (
      "\n\tExit with:\n\t%8i %s(S)\n\t%8i %s(S)\n",
      ($msgCount[1] or 0), $severity[1],  # errors
      ($msgCount[2] or 0), $severity[2]   # warnings
    ),
    3, $verbosity );

# Exit code is the number of errors
exit ($msgCount[1] or 0);



# ------------------------------------------------------------------------------
# Output format definitions
#
# ------------------------------------------------------------------------------

#
# A channels
#
format AWFORMAT =
@*
sprintf("%01X%01X%01X%0${awUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%0${addrBitsTop}s%03X%08X%08X%08X", $field{REGION}{VALUE}, $field{QOS}{VALUE}, $field{CACHE}{VALUE}, $field{USER}{VALUE}, $field{EMIT}{VALUE}, $field{WAIT}{VALUE}, $field{ID}{VALUE}, $field{ADDR_TOP}{VALUE}, $field{ADDR}{VALUE}, $AWVWaitHex, $lineNum, $commandWord)
.

format ARFORMAT =
@*
sprintf("%01X%01X%01X%0${arUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%0${addrBitsTop}s%03X%08X%08X%08X", $field{REGION}{VALUE}, $field{QOS}{VALUE}, $field{CACHE}{VALUE}, $field{USER}{VALUE}, $field{EMIT}{VALUE}, $field{WAIT}{VALUE}, $field{ID}{VALUE}, $field{ADDR_TOP}{VALUE}, $field{ADDR}{VALUE}, $ARVWaitHex, $lineNum, $commandWord)
.

# SYNC AR
format SARFORMAT =
// Sync command
@*
sprintf("%01X%01X%01X%0${arUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%0${addrBitsTop}s%03X%08X%08X%08X", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, $lineNum, $commandWord)
.

# SYNC AW
format SAWFORMAT =
// Sync command
@*
sprintf("%01X%01X%01X%0${awUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%0${addrBitsTop}s%03X%08X%08X%08X", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, $lineNum, $commandWord)
.

#
# W channel
#
format WFORMAT =
@*
sprintf("%0${wUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%s%s%08X%08X%08X", $field{USER}{VALUE}, $field{EMIT}{VALUE}, $field{WAIT}{VALUE}, $field{ID}{VALUE}, $field{WSTRB}{VALUE_ALIGNED}, $field{WDATA}{VALUE_ALIGNED}, $WVWaitHex, $lineNum, $commandWord)
.

# SYNC W
format SWFORMAT =
// Sync command
@*
sprintf("%0${wUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%s%s%08X%08X%08X", 0, 0, 0, 0, '0' x ($dataBusBytes >> 2), '00' x $dataBusBytes, 0, $lineNum, $commandWord)
.


#
# B channel
#
format BFORMAT =
@*
sprintf("%0${bUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%08X%08X%08X", $field{USER}{VALUE}, $field{EMIT}{VALUE}, $field{WAIT}{VALUE}, $field{ID}{VALUE}, $BRWaitHex, $lineNum, $commandWord)
.

# SYNC B
format SBFORMAT =
// Sync command
@*
sprintf("%0${bUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%08X%08X%08X", 0, 0, 0, 0, 0, $lineNum, $commandWord)
.

#
# R channel
#
format RFORMAT =
@*
sprintf("%0${rUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%s%s%08X%08X%08X", $field{USER}{VALUE}, $field{EMIT}{VALUE}, $field{WAIT}{VALUE}, $field{ID}{VALUE}, $field{MASK}{VALUE_ALIGNED}, $field{RDATA}{VALUE_ALIGNED}, $RRWaitHex, $lineNum, $commandWord)
.

# SYNC PR
format PSRFORMAT =
// Poll command
@*
sprintf("%0${rUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%s%s%08X%08X%08X", 0, 0, 0, 0, '00' x $dataBusBytes, '00' x $dataBusBytes, $field{TIMEOUT}{VALUE}, $lineNum, $commandWord)
.

# SYNC R
format SRFORMAT =
// Poll command
@*
sprintf("%0${rUBits}s%0${ewBits}X%0${ewBits}X%0${idBits}X%s%s%08X%08X%08X", 0, 0, 0, $field{ID}{VALUE}, '00' x $dataBusBytes, '00' x $dataBusBytes, 0, $lineNum, $commandWord)
.

#
# Comment file
#
format CFORMAT =
@*
sprintf("%0160s", $msgHex)
.

__END__


