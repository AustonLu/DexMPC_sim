eval "exec perl -w -S $0 $@" # -*- Perl -*-
  if ($running_under_some_sh);
undef($running_under_some_sh);
#============================================================================--
#   The confidential and proprietary information contained in this file may
#   only be used by a person authorised under and to the extent permitted
#   by a subsisting licensing agreement from ARM Limited.
#    (C) COPYRIGHT 2005-2013 ARM Limited.
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
#- Purpose : Scans vector files and adds the neccessary XVC_MANGER commands
#-           to map events in vectors files to scenario events
#- --========================================================================--

use strict;
use Getopt::Long;
use File::Basename;
use File::Copy;
use FileHandle;

my $line;
my $vector_line;
my $XVC;

my ($infile,$outfile);
GetOptions(
      "infile=s" => \$infile,
      "outfile=s" => \$outfile
);

if (!$infile)  {die "Input file name not defined"; };
if (!$outfile) {die "Output file name not defined"; };

#Open the input file
open(IN, $infile) or die "Input file $infile not found\n";

#Open the output file 
open (OUT, ">$outfile") or die "Failed to open $outfile for writing\n";

#Go through each line in the input file
while (<IN>) {

  $line=$_;

  #Output the line
  print OUT $line;

  if ($line =~ /[ACTION|INTERRUPT]\s+([A-Za-z0-9_]*)\s+/) {
          $XVC = $1;
  }

  if ($line =~ /execute\s+vector\s+file\s+\'(.*)\'/) {

          open(VEC, $1) or die "Failed to open $1";

          while (<VEC>) 
          {
             $vector_line = $_;
             
             if ($vector_line =~ /EMIT([0-9A-F]*)/) {
                 print OUT "Mapevent $1 is $XVC event $1\n";
             };

          };
          close(VEC);
  };
   
};

close (IN);
close (OUT);
