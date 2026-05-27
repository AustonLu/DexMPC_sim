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
#- File Revision          : 159280
#-
#- Date                   :  2009-07-13 10:40:34 +0100 (Mon, 13 Jul 2009)
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
my $stop_output;
my $config_name;
my $wrapper = "";

my ($wrapped,$infile,$outfile);
GetOptions(
      "wrapped+" => \$wrapped,
      "infile=s" => \$infile
);

if (!$infile)  {die "Input file name not defined"; };

if ($infile =~ /\/(nic400.*)\.xml$/) {
  $config_name = $1;
}
$wrapped =1;
if ($wrapped >0) {
  $wrapper = "   <spirit:file>
    <spirit:name>./../nic400/validation/random/mti_compile_netlist_sn/${config_name}_wrapper.v</spirit:name>
    <spirit:fileType>verilogSource</spirit:fileType>
   </spirit:file>
";
}

#Open the input file
open(IN, $infile) or die "Input file $infile not found\n";

mkdir "../../../../spirit_netlist" unless -d "../../../../spirit_netlist";

$outfile="../../../../spirit_netlist/$config_name" . "_netlist.xml";

#Open the output file
open (OUT, ">$outfile") or die "Failed to open $outfile for writing\n";



#Go through each line in the input file
my $first_spirit_name = 1;
while (<IN>) {

  $line=$_;
  if ($first_spirit_name == 1 and $line =~ /<spirit:modelName>([a-zA-Z0-9_]*)<\/spirit:modelName>/) {
    $line = "      <spirit:modelName>${config_name}_wrapper</spirit:modelName>\n";
    $first_spirit_name = 0;
  }
  if ($line =~ /.*\/spirit:ports.*/) {
    $stop_output = 1;
  };
  if (!$stop_output) {
    print OUT $line;
    next;
  } else {
    last;
  };

};
  
  print OUT <<EOF;
  

   </spirit:ports>
  </spirit:model>
  
  <spirit:fileSets>
  <spirit:fileSet>
   <spirit:name>top-level-RTL</spirit:name>
$wrapper   <spirit:file>
    <spirit:name>./../../../implementation/$config_name/synopsys/data/$config_name.$ENV{NETLIST_EXTENSION}.v</spirit:name>
    <!--spirit:name>./../../../implementation/$config_name/synopsys/data/$config_name.v</spirit:name-->
    <spirit:fileType>verilogSource</spirit:fileType>
   </spirit:file>
   <spirit:file>
    <spirit:name>$ENV{NIC400_LIBRARY_PATH}/arm/tsmc/cln28hpm/sc9mc_base_svt_c31/r3p0-01eac0/verilog/sc9mc_cln28hpm_base_svt_c31.v</spirit:name>
    <spirit:fileType>verilogSource</spirit:fileType>
   </spirit:file>
   <!--   <spirit:file>
    <spirit:name>/arm/fipd/design_kits/arm/tsmc65lp-rvt/advantage-hs/aci/sc-ad12/verilog/tsmc65_rvt_sc_adv12.v</spirit:name>
    <spirit:name>$ENV{NIC400_LIBRARY_PATH}/arm/cp/cmos32lp/sc9_base_rvt/r4p0_04rel0/verilog/sc9_cmos32lp_base_rvt.v</spirit:name>
    <spirit:fileType>verilogSource</spirit:fileType>
   </spirit:file>
   <spirit:file>
    <spirit:name>/projects/pr428_cario/libraries/arm/cp/cmos32lp/sc9_base_rvt/r4p0_04rel0/verilog/sc9_cmos32lp_base_rvt_udp.v</spirit:name>
    <spirit:fileType>verilogSource</spirit:fileType>
   </spirit:file>-->
   
  </spirit:fileSet>
  </spirit:fileSets>
 </spirit:component> 
EOF

#   #Replace every instance of ${xxx} with the current setting
#   while ($line =~ /\${(.*)}/) {
# 
#           # $env_var = $1;
# #           $env_val = '';
# #           if (exists $ENV{$env_var}) { 
# #               $env_val = $ENV{$env_var};
# #           };
# #           $line =~ s/\${$env_var}/$env_val/;
# 
#   };
# 
#   #IF the path is relative
#   if ($line =~ /^(\+incdir\+|-y\s+|-v\s+)?([^\/~]\S*)\s*$/) {
# 
#     my $file;
#     $file= $2;
#     my $start;
#     $start= $1;
# 
#     if (not defined $start) {
#        $start = "";
#     };
# 
# #    $file = $in_dir . '/' . $file;
#     $file = realpath($file);
# 
#     if (defined $file) {
#        $line = $start . $file . "\n"
#     } else {
#        $line = "";
#     };
# 
#   };
# 
#   #Output the line
#   print OUT $line;

close (IN);
close (OUT);
