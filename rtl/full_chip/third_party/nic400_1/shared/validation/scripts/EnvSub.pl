eval "exec perl -w -S $0 $@" # -*- Perl -*-
  if ($running_under_some_sh);
undef ($running_under_some_sh);
#============================================================================--
#   The confidential and proprietary information contained in this file may
#   only be used by a person authorised under and to the extent permitted
#   by a subsisting licensing agreement from ARM Limited.
#    (C) COPYRIGHT 2009-2013 ARM Limited.
#        ALL RIGHTS RESERVED
#   This entire notice must be reproduced on all copies of this file
#   and copies of this file may only be made by a person if such person is
#   permitted to do so under the terms of a subsisting license agreement
#   from ARM Limited.
#- ----------------------------------------------------------------------------
#- Version and Release Control Information:
#-
#- File Revision          : 150002
#-
#- Date                   :  2013-05-09 16:10:21 +0100 (Thu, 09 May 2013)
#-
#- Release Information    : PL401-r1p2-00rel0
#-
#- ----------------------------------------------------------------------------
#- Purpose : Scans the a vc file and replaces any ${xxx} variables with their
#            current values and modifies relative paths to make them relative
#            to the current location.
#- --========================================================================--

use strict;
use Getopt::Long;
use File::Basename;
use File::Copy;
use FileHandle;
use Cwd 'realpath';

my $line;
my $env_var;
my $env_val;
my $in_dir;

my ($infile,$outfile);
GetOptions(
      "infile=s" => \$infile
);

if (!$infile)  {die "Input file name not defined"; };

#Open the input file
open(IN, $infile) or die "Input file $infile not found\n";

#Open the output file
open (OUT, ">tbench.vc") or die "Failed to open tbench.vc for writing\n";

$infile =~ /^(.*)\/[^\/]*$/;
$in_dir = $1;

#Go through each line in the input file
while (<IN>) {

  $line=$_;

  if ($line =~ /^\s*$/) {
    print OUT $line;
    next;
  };

  #Replace every instance of ${xxx} with the current setting
  while ($line =~ /\${(.*)}/) {

          $env_var = $1;
          $env_val = '';
          if (exists $ENV{$env_var}) { 
              $env_val = $ENV{$env_var};
          };
          $line =~ s/\${$env_var}/$env_val/;

  };

  #IF the path is relative
  if ($line =~ /^(\+incdir\+|-y\s+|-v\s+)?([\.]\S*)\s*$/) {

    my $file;
    $file= $2;
    my $start;
    $start= $1;

    if (not defined $start) {
       $start = "";
    };

    $file = $in_dir . '/' . $file;
    $file = realpath($file);

    if (defined $file) {
       $line = $start . $file . "\n"
    } else {
       $line = "";
    };

  };

  #Output the line
  print OUT $line;

};

close (IN);
close (OUT);
