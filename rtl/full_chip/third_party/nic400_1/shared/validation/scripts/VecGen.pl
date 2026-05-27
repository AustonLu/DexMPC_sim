eval "exec perl -w -S $0 $@" # -*- Perl -*-
  if ($running_under_some_sh);
undef($running_under_some_sh);
#-------------------------------------------------------------------------------
#-  This confidential and proprietary software may be used only as
#-  authorised by a licensing agreement from ARM Limited
#-   (C) COPYRIGHT 2004-2013 ARM Limited
#-        ALL RIGHTS RESERVED
#-  The entire notice above must be reproduced on all authorised
#-  copies and copies may only be made to the extent permitted
#-  by a licensing agreement from ARM Limited.
#-------------------------------------------------------------------------------
#-
#-  Version and Release Control Information:
#-
#-   File Revision       : 150002
#-
#-   Release Information : PL401-r1p2-00rel0
#-
#-------------------------------------------------------------------------------
# Purpose :
#          Parses tsf file to find the vector files for each master and calls
#          the correct covertion script
#
#          NB. This file assumes there is only one vector file per master or slave
#      
#-------------------------------------------------------------------------------

use strict;
use FileHandle;

my @tsf       = glob("./*.tsf");
my $qual_text = "execute vector file";
my $start     = `/bin/pwd`;

my $axim_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrmAxiConv.pl";
my $axis_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrsAxiConv.pl";
my $axi4m_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrmAxi4Conv.pl";
my $axi4s_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrsAxi4Conv.pl";
my $ahbm_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrmAhbConv.pl";
my $ahbs_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrsAhbConv.pl";
my $apbs_script    = "$ENV{PERIPH_LOGICAL}/shared/validation/scripts/FrsApbConv.pl";

my $axi_options   = " -ARsize=250000 -AWsize=250000 -Rsize=250000 -Wsize=250000 -ARmsgsize=250000 -AWmsgsize=250000";
my $ahb_options   = "";
my $apb_options   = "";

my @out_m3i_array;
my @used_masters;
my $masters = 8;

# Fill those files with a concat of all referenced m3i files
foreach my $tsf_file (@tsf) {
  my $in_tsf = FileHandle->new("<$tsf_file")
    or die "Cannot open ${tsf_file}\n";
  $tsf_file =~ s/.tsf//;

  print "$tsf_file :\n";
  while (my $line_in = $in_tsf->getline()) {
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+PL301_AXIM_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Master = $1 : M3I File = $2\n";
      print "$axim_script $axi_options --infile=$2 --outfile=PL301_AXIM_$1 > $1.log 2>&1\n";
      system("$axim_script $axi_options --infile=$2 --outfile=PL301_AXIM_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+PL301_AXIS_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Slave = $1 : M3I File = $2\n";
      print "$axis_script $axi_options --infile=$2 --outfile=PL301_AXIS_$1 > $1.log 2>&1\n";
      system("$axis_script $axi_options --infile=$2 --outfile=PL301_AXIS_$1 > $1.log 2>&1");
    }      
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AXIM_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Master = $1 : M3I File = $2\n";
      print "$axim_script $axi_options --infile=$2 --outfile=AXIM_$1 > $1.log 2>&1\n";
      system("$axim_script $axi_options --infile=$2 --outfile=AXIM_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AXIS_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Slave = $1 : M3I File = $2\n";
      print "$axis_script $axi_options --infile=$2 --outfile=AXIS_$1 > $1.log 2>&1\n";
      system("$axis_script $axi_options --infile=$2 --outfile=AXIS_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+PL301_AXI4M_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Master = $1 : M3I File = $2\n";
      print "$axi4m_script $axi_options --infile=$2 --outfile=PL301_AXI4M_$1 > $1.log 2>&1\n";
      system("$axi4m_script $axi_options --infile=$2 --outfile=PL301_AXI4M_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+PL301_AXI4S_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Slave = $1 : M3I File = $2\n";
      print "$axi4s_script $axi_options --infile=$2 --outfile=PL301_AXI4S_$1 > $1.log 2>&1\n";
      system("$axi4s_script $axi_options --infile=$2 --outfile=PL301_AXI4S_$1 > $1.log 2>&1");
    }      
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AXI4M_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Master = $1 : M3I File = $2\n";
      print "$axi4m_script $axi_options --infile=$2 --outfile=AXI4M_$1 > $1.log 2>&1\n";
      system("$axi4m_script $axi_options --infile=$2 --outfile=AXI4M_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AXI4S_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAxi Slave = $1 : M3I File = $2\n";
      print "$axi4s_script $axi_options --infile=$2 --outfile=AXI4S_$1 > $1.log 2>&1\n";
      system("$axi4s_script $axi_options --infile=$2 --outfile=AXI4S_$1 > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AHBLiteM_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAhb Master = $1 : M3I File = $2\n";
      print "$ahbm_script $ahb_options --infile=$2 --outfile=AHBLiteM_$1 > $1.log 2>&1\n";
      system("$ahbm_script $ahb_options --infile=$2 --outfile=AHBLiteM_$1.m3d > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+AHBLiteS_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tAhb Slave = $1 : M3I File = $2\n";
      print "$ahbs_script $ahb_options --infile=$2 --outfile=AHBLiteS_$1 > $1.log 2>&1\n";
      system("$ahbs_script $ahb_options --infile=$2 --outfile=AHBLiteS_$1.m3d > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+APBS_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tApb Slave = $1 : M3I File = $2\n";
      print "$apbs_script $apb_options --infile=$2 --outfile=APBS_$1 > $1.log 2>&1\n";
      system("$apbs_script $apb_options --infile=$2 --outfile=APBS_$1.m3d > $1.log 2>&1");
    }
    if ($line_in =~ /^[Aa][cC][tT][iI][Oo][Nn]\s+T_APBS_(.*)\s+\"$qual_text \'(.*)\'\"/) {
      print "\tApb Slave = $1 : M3I File = $2\n";
      print "$apbs_script $apb_options --infile=$2 --outfile=APBS_$1 > $1.log 2>&1\n";
      system("$apbs_script $apb_options --infile=$2 --outfile=APBS_$1.m3d > $1.log 2>&1");
    }
  }
  $in_tsf->close();
}

