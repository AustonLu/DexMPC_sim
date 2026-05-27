eval "exec perl -w -S $0 $@" # -*- Perl -*-
if ($running_under_some_sh);
undef($running_under_some_sh);
use strict;
use Class::Struct;
use Tk;
use Tk::DialogBox;
use Tk::NoteBook;
use Tk::Font;
use Tk::Pane;
my $usage = "\n===================================================================\n".
            "\nPurpose:\n".
            "  Reorder RSB Nodes/Domains for AMBA NIC Infrastructure           \n".
            "===================================================================\n".
            "\n".
            "rsb_reorder.pl [Options]\n".
            "\n".     
            "Options:\n".
            "   specify the source file \n".
            "   specify the destination file to use. \n".
            "   DEFAULT - source file name \n".
            "\n".
            "Note: This script needs input closure defs file name to   \n".
            "      reorder nodes/domains of RSB.  \n".
            "\n".
            "example: ./rsb_reorder.pl nic400_closure_defs.v output.v  \n".
            "\n".
            "\n===================================================================\n";

struct clk_domain=> {clk => '$',domain=>'$',domain_comment=>'$', def => '@',};
struct define=> {node => '$',node_type => '$',value => '$',value_post => '$',clk_name=>'$', position=>'$',define_pre=>'$',define_post=>'$'};
my ($source_file, $dest_file,$clock_name,$uc_clock_name,$domain_type,$current_node,$current_node_type,$current_value,$new_clk_domain,$current_position)=('','','','','','','','','','');
my ($config, $flag,$domainflag,$async_flag)=('',0,0,0);
my @arm_heading = (); my @tabs = ();my @reg_slices = ();my @async_data = ();
my $debug = 0;
#===========================================================================
# Get The Options!!
#===========================================================================
unless ($ARGV[0]) { die $usage; };

if ($ARGV[0]) { $source_file= $ARGV[0]; }
if ($ARGV[1]) { $dest_file= $ARGV[1]; }


#===========================================================================
# Set Dest File Name 
# src_file name = dest_file name, if dest file name is not specified
#===========================================================================

if($dest_file eq '') {
    $dest_file = $source_file;
}

#===========================================================================
#
# Main Body Of The Code !!
#
#===========================================================================

open(IN1, $source_file) || die print $usage;
foreach my $line (<IN1>){ 
    #next if($line eq "" || $line =~ /^\s*$/);
    
    if($line=~/(\/\/ Definitions for the ordering of RSB (domains|central ring))/){ 
        print STDOUT "RSB Domain/central ring - $2\n" if($debug);
        $domainflag=1;
        $new_clk_domain= clk_domain->new();
        $new_clk_domain->clk('reorder');
        $new_clk_domain->domain('domains');
        $new_clk_domain->domain_comment($2);
    }
    if(!$domainflag){
        if($line =~/((.*) Definitions for the ordering of nodes in the RSB in the) (.*)/) {
           # push(@arm_heading,"//------------------------------------------------------------------------------\n");
            print STDOUT "Nodes $3\n" if($debug);
            $flag=1;           
        }
        #storage of the node ordering in a RSB domain
        if($line =~/\/\/ RSB DOMAIN (SLAVE|MASTER|LOCAL) (.*)/) {
            print STDOUT "Found RSB DOMAIN $1 - $2\n" if($debug);
            $clock_name = $2;
            $clock_name =~ tr/a-z/A-Z/;
            $new_clk_domain= clk_domain->new();
            $new_clk_domain->clk($clock_name);
            $new_clk_domain->domain($1);
        }  
        # storage of all reg slice info, will be printed out in one place in output file
        if($line=~/(`define RSB_REG_)(.*)/) {  
            push(@reg_slices,$line);

        }
        if($line=~/(.*) (RSB) (SLAVE|MASTER) (NODE) (.*)/) {  
            print STDOUT "Found RSB NODE $3 - $5\n" if($debug);
            $current_node = $5;
            $current_node=~ tr/a-z/A-Z/;
            $current_node_type = $3;
        }
        if(!$flag){
            #storage of the ARM header and other lines till the node ordering starts
            push(@arm_heading,$line);              
        }
        if($line=~/(.*) (RSB) (SLAVE|MASTER) (LAST)/) {
            print STDOUT "Found RSB NODE LAST $3\n" if($debug);
            $current_node = 'LAST';
        }
#         if($line =~/(`define) (RSB_DATA_S_)($current_node)(_$clock_name)(\S*) +(\S*)/) {
        if($line =~/(`define) (RSB_DATA_(S_)?)($current_node)(_$clock_name)(\S*) +(\S*)/) {
            $config= $5;
            my $define_post = $6;
            
            print STDOUT "Current Node $current_node ($clock_name)\n" if($debug);
            #print STDOUT "1 $1 2 $2 4 $4 5 $5 6 $6\n" if($debug);
            if($7 =~ /mdata(_hub)?/) {
                $current_value = 'FIRST';
                $current_position = 'FIRST';
            }else {
                if($7 =~/(rsb_data_m_)(.*)/) {
                   $current_value = $2;
                   $current_position = 'DONTCARE';
                }
            }   
            my $new_define = new define;
            $new_define->node($current_node);
            $new_define->node_type($current_node_type);
            $new_define->value($current_value);
            $new_define->define_post($define_post);
            $new_define->position($current_position);
            push(@{$new_clk_domain->def},$new_define);
        }
        if($line=~/\/\/ RSB DOMAIN END/){  
           push(@tabs,$new_clk_domain);        
           print STDOUT "Pushed CD ".$new_clk_domain->domain." ".$new_clk_domain->clk." to Tabs\n" if($debug);
        }
        if($line=~/((.*)Definitions for the boundaries between RSB domains)/){
            $async_flag = 1;
            push(@async_data,"//------------------------------------------------------------------------------\n");
        }
        if($async_flag){
            push(@async_data,$line);
        }
    }else{

        # storage of all reg slice info, will be printed out in one place in output file
        if($line=~/(`define RSB_REG_)(.*)/) {  
            push(@reg_slices,$line);
            next;

        }
        if($line =~/\/\/ RSB DOMAIN (MASTER|SLAVE|CENTRAL) (.*)/){
            print STDOUT "Found DOMAIN $1 $2\n" if($debug);
            $domain_type=$1;
            $clock_name=$2;
            $uc_clock_name = uc($clock_name);
        }
        if($line =~/(`define) (RSB_DATA_(M_|RSB_CENTRAL_HUB_)?)(\S+_(MASTER|SLAVE)|$uc_clock_name)(_M|_\S*)? +(rsb_data_)(\S*)/){
            #print STDOUT "Found RSB NODE line $line\n" if($debug);
            my $node_name    = $4;
            my $define_pre   = $3;
            my $define_post  = $6;
            my $sig_name_int = $8;
            my $sig_name;
            my $append_s = 0;
            
            if($domain_type =~ /(MASTER|SLAVE)/) {
                ($sig_name = $sig_name_int) =~ s/_s$//;
                $append_s = 1;
            } else {
                $sig_name = $sig_name_int;
            }
            print STDOUT "Found RSB NODE (SIG/value rsb_data_$sig_name) (DEF/node $node_name) (DEF Full $define_pre $node_name $define_post) in $clock_name\n" if($debug);
            my $new_define = new define;
            $new_define->node($node_name);
            $new_define->clk_name($clock_name);
            $new_define->value($sig_name);
            $new_define->value_post($append_s);
            $new_define->define_pre($define_pre);
            $new_define->define_post($define_post);
            push(@{$new_clk_domain->def},$new_define);
         }
        if ($line =~/(\/\/ RSB GROUP END)/){
            push(@tabs,$new_clk_domain);
            print STDOUT "Pushed CD ".$new_clk_domain->domain." to Tabs\n" if($debug);
            $domainflag = 0;
        }
    }
}
print STDOUT "Closing IN file\n" if($debug);
close IN1;

#===========================================================================
# GUI SETUP CODE FOR REORDERING !!
#===========================================================================

my $mw = MainWindow->new();
my $font = $mw->Font(-family=> 'Helvetica', -size  => -12, -weight => 'bold');
$mw->geometry( "1200x800");
$mw->title("rsb_reorder_tool");
$mw->Label(-text => '  ordering of nodes/domains of the register sub system  ',-relief => 'sunken',-font=>$font,)->pack;
$mw->configure(-background => 'gray40',-highlightthickness => '10');
my $quit= $mw->Button(-text    => 'QUIT',-bg=> 'red',-fg=>'white',-command => 
# print output message if file is saved!
sub{print "\n*****************************************\nWARNING: Quitting without saving changes! \n*****************************************\n";exit},)->pack;
my $save= $mw->Button(-text    => 'SAVE & QUIT',-bg=> 'dark blue',-fg=>'white',-command =>
sub{$mw->destroy; print "\n*****************************************\nFile successfully saved \n*****************************************\n"})->pack;
my $pane = $mw->Scrolled(qw/Pane/, -scrollbars => 's',-background=>'darkgray')->pack(-expand=>1,-fill=>'both');
my $book = $pane->NoteBook(-background=>'blue')->pack(-expand=>1,-fill=>'both',-ipadx=>1);
my $tab1 = $book->add( "Sheet 1", -label=>"Start",)->pack;
$tab1->Label(-text => "Please go to the respective tab to reorder the nodes in that domain. \nThe domains also can be reordered. \n\n\nUse 'UP/DOWN' buttons for reordering",-relief => 'groove',-takefocus => 1,
-foreground=> 'white',-background=>'dark blue',-font=>$font,-height=>'25',-justify=>'left',-highlightthickness => '5',-wraplength=>'800',)->pack;
foreach my $domain(@tabs){
    my $ldomain = $domain->domain; my $lclk = $domain->clk;
    $lclk =~ tr/A-Z/a-z/; $ldomain =~ tr/A-Z/a-z/;  
    my $string = "Reorder Nodes in\n$lclk";
    if ($domain->clk eq 'reorder') {
        #$string = $domain->clk." the ".$domain->domain;
        $string = "Reorder the Domains";
    }
    print STDOUT $string."\n" if ($debug);
    my $tab = $book->add( "Sheet[$domain->clk] ",-anchor=>'center', -label=>$string,);
    my $list = $tab -> Scrolled(qw/Listbox -background white -height 10 -width 20 -selectmode single -scrollbars se/);
    print STDOUT "Drawing ".$domain->clk."\n" if ($debug);
    if ($domain->clk eq 'reorder') {

        # Pick the last
        my $last_i = 0;
        my $tmp_i  = 0;
        my $first_val = ${$domain->def}[0]->value;
        $list -> insert(0, ${$domain->def}[0]->value);

        print STDOUT "Last Node ".uc(${$domain->def}[$last_i]->value)."\n" if ($debug);
        foreach (@{$domain->def}) {
            print STDOUT uc($_->value)."\t-value\n" if($debug);
            print STDOUT uc($_->node)."\t-node\n" if($debug);
        }
        # Trace from last to first, adding elements to head of list
        while ( uc(${$domain->def}[$last_i]->value) ne uc(${$domain->def}[0]->node) ) {
#             print STDOUT "Current Node ".uc(${$domain->def}[0]->node)."\n" if ($debug);
            $tmp_i = 0;
            foreach my $def(@{$domain->def}){
                if( uc($def->node) eq uc(${$domain->def}[$last_i]->value) )  {
                    my $val = $def->value;
                    $last_i = $tmp_i;
                    $list -> insert(0,$def->value);
                }
                $tmp_i++;
            }
        }

    } # End of 'reorder' domain
    else {
        # Find the last
        my $last_i = -1;
        my $tmp_i  = 0;
        foreach my $def(@{$domain->def}){
            if($def->node eq 'LAST')  {
                my $val = $def->value;
                $last_i = $tmp_i;
                $list -> insert(0,$def->value);
            }
            $tmp_i++;
        }

        # Trace from last to first, adding elements to head of list
        while (${$domain->def}[$last_i]->value ne 'FIRST') {
            $tmp_i = 0;
            foreach my $def(@{$domain->def}){
                if( uc($def->node) eq uc(${$domain->def}[$last_i]->value) )  {
                    my $val = $def->value;
                    $last_i = $tmp_i;
                    if($def->value ne 'FIRST')  {
                        $list -> insert(0,$def->value);
                    }
                }
                $tmp_i++;
            }
        }

    }
    my $up =  $tab-> Button(-text=>"UP",  -bg=> 'green',-command =>[\&shift,$list,"UP",  $domain])->pack(-side => 'left');
    my $dwn = $tab-> Button(-text=>"DOWN",-bg=> 'green',-command =>[\&shift,$list,"DOWN",$domain])->pack(-side => 'left'); 
    $list ->grid(-row=>1,-column=>1);
    $up   ->grid(-row=>1,-column=>2,-columnspan=>2);
    $dwn  ->grid(-row=>1,-column=>5,-columnspan=>2);
}
# this line executes the GUI tool 
MainLoop;

#================================
# function for reordering
#================================

sub shift{
    my $list= shift;    my $direction = shift;    my $domain = shift;
    my $sel = $list->curselection();
    if ($sel ne "" ) {

        my $index = $list->index($sel);
        my $text = $list->get($index);
        my $text_nxt=$list->get($index+1);
        my $text_prev=$list->get($index-1);

        if($direction eq 'UP' and $index >0 ){

            $list->delete($index);
            $list->insert($index-1, $text);
            swap($domain, $text, $text_prev);

        } elsif($direction eq 'DOWN' and $index < ($list->size()) -1)  {

            $list->delete($index);
            $list->insert($index+1, $text);
            swap($domain, $text, $text_nxt);

        }

    }else {
        print "Please select a value from the list..\n";
    }
}

sub swap{
    my $domain = CORE::shift;
    my $i_node = CORE::shift;
    my $j_node = CORE::shift;

    my $i = -1;
    my $j = -1;
    my $i_val = "";
    my $j_val = "";
    my $i_next = -1;
    my $j_next = -1;
    my $i_prev = -1;
    my $j_prev = -1;

    my $num_nodes = $#{$domain->def} + 1;

    # Find indices to i and j
    # Find nodes that point to i and j
    for (my $n = 0; $n < $num_nodes; $n++) {
        my $node = ${$domain->def}[$n]->node;
        my $val  = ${$domain->def}[$n]->value;
        
        # Check if i
        if( uc($node) eq uc($i_node) ) {
            $i = $n;
        }

        # Check if j
        if( uc($node) eq uc($j_node) ) {
            $j = $n;
        }

        # Check if points to i
        if( uc($val) eq uc($i_node) ) {
            $i_next = $n;
        }

        # Check if points to j
        if( uc($val) eq uc($j_node) ) {
            $j_next = $n;
        }
    }

    if ($i < 0 or $j < 0 or $i_next < 0 or $j_next < 0) {
        print "ERROR: cannot complete swap\n";
    }
    else {

        $i_val  = ${$domain->def}[$i]->value;
        $j_val  = ${$domain->def}[$j]->value;

        # Find nodes to which i and j point
        for (my $n = 0; $n < $num_nodes; $n++) {
            my $node = ${$domain->def}[$n]->node;
            my $val  = ${$domain->def}[$n]->value;

            # Check if i points to this
            if( uc($node) eq uc($i_val) ) {
                $i_prev = $n;
            }

            # Check if j points to this
            if( uc($node) eq uc($j_val) ) {
                $j_prev = $n;
            }
        }

        # Record values for swapping
        my $i_next_val  = ${$domain->def}[$i_next]->value;
        my $j_next_val  = ${$domain->def}[$j_next]->value;

        # Execute the swap:
        if ( not(($i_prev == $j) and ($j_prev == $i)) ) {

            # Handle case where j points to i
            if ($i_next == $j) {
                ${$domain->def}[$i]     ->value($j_next_val);
            } else {
                ${$domain->def}[$i]     ->value($j_val);
                ${$domain->def}[$i_next]->value($j_next_val);
            }

            # Handle case where i points to j
            if ($j_next == $i) {
                ${$domain->def}[$j]     ->value($i_next_val);
            } else {
                ${$domain->def}[$j]     ->value($i_val);
                ${$domain->def}[$j_next]->value($i_next_val);
            }

        } # Else do nothing b/c a swap has no effect if 
          #  i and j point to each other

    }
}

#============================================================================
# To Print Out The Output in the Dest File !!
#============================================================================

open(OUT,"> $dest_file") || die "Destination file $dest_file not read-able\n";
pop(@arm_heading);
print OUT @arm_heading;
foreach my $out(@tabs){
    if($out->clk eq 'reorder'){
        print OUT "\n//------------------------------------------------------------------------------\n// Definitions for the ordering of RSB ".$out->domain_comment."\n".
        "//------------------------------------------------------------------------------\n// RSB GROUP BEGIN\n\n";
        foreach my $def(@{$out->def}){
            my $domain = '';
            print STDOUT "printing output of ".$def->define_pre.$def->node.$def->define_post."\n" if($debug);
            if($def->node =~ /(.*_)(SLAVE|MASTER)/) {
                $domain = $2;
                my $value = $def->value;
                $value = $value."_s" if($def->value_post);
                print OUT "// RSB DOMAIN $domain ".$def->clk_name."\n".
                "  `define RSB_DATA_".$def->define_pre.$def->node.$def->define_post." rsb_data_".$value."\n".
                "  `define RSB_WPTR_".$def->define_pre.$def->node.$def->define_post." rsb_wptr_".$value."\n".
                "  `define RSB_B_RPTR_".$def->define_pre.$def->node.$def->define_post." rsb_b_rptr_".$value."\n".                    
                "  `define RSB_RPTR_".$def->define_pre.$def->node.$def->define_post." rsb_rptr_".$value."\n".                    
                "  `define RSB_".$def->node."_SRC_CLK \"".$def->value."\"\n".                    
                "// RSB DOMAIN END\n";
             } elsif($def->define_pre =~ /(CENTRAL)/) {
                $domain = $1;
                my $lnode = $def->node;
                my $lreg = '';
                my $value = $def->value;
                $value = $value."_s" if($def->value_post);
                foreach my $reg_slice (@reg_slices) {
                    if($reg_slice =~ /`define RSB_REG_RSB_CENTRAL_HUB_$lnode/) {
                        print STDOUT "printing reg slice $reg_slice\n" if($debug);
                        $lreg = $reg_slice;
                    }
                }
                print OUT "// RSB DOMAIN $domain ".$def->clk_name."\n".$lreg."\n".
                "  `define RSB_DATA_".$def->define_pre.$def->node.$def->define_post."  rsb_data_".$value."\n".
                "  `define RSB_VALID_".$def->define_pre.$def->node.$def->define_post." rsb_valid_".$value."\n".
                "  `define RSB_READY_".$def->define_pre.$def->node.$def->define_post." rsb_ready_".$value."\n".                    
                "// RSB DOMAIN END\n\n";
            }
       }
        print OUT "// RSB GROUP END\n";
    }
    else{
        my $clk = $out->clk; my $clk_lower = $clk;
        $clk_lower =~ tr/A-Z/a-z/;
        print OUT "//------------------------------------------------------------------------------\n// Definitions for the ordering of nodes in the RSB ".
        "in the $clk_lower domain\n"."//------------------------------------------------------------------------------\n\n";
        print OUT "// RSB DOMAIN ".$out->domain." ".$clk_lower."\n";
        foreach my $def(@{$out->def}){
            #print out reg slice
            my $node = $def->node;my $node_lower = $node;
            $node_lower =~ tr/A-Z/a-z/;
            my $lappend_s = "";
            $lappend_s = "S_" if($out->domain !~ /LOCAL/);
            foreach my $reg_slice (@reg_slices) {
                if($reg_slice =~ /`define RSB_REG_($node)(_)($clk) (.*)/) {
                    print OUT "$reg_slice\n";
                }
            }
            if($node_lower eq 'last') {
                print OUT "// RSB ".$def->node_type." ". $node."\n";
            } else {
                print OUT "// RSB ".$def->node_type." NODE ".$node_lower."\n";
            }
            if($def->value eq 'FIRST'){
                my $lmdata = "";
                $lmdata = "_hub" if($out->domain =~ /LOCAL/);
                print OUT "`define RSB_DATA_".$lappend_s.$def->node."_".$out->clk.$def->define_post."  mdata".$lmdata."\n".
                "`define RSB_VALID_".$lappend_s.$def->node."_".$out->clk.$def->define_post." mvalid".$lmdata."\n".
                "`define RSB_READY_".$lappend_s.$def->node."_".$out->clk.$def->define_post." mready".$lmdata."\n";        
            }else{
                print OUT "`define RSB_DATA_".$lappend_s.$def->node."_".$out->clk.$def->define_post."  rsb_data_m_".$def->value."\n".
                "`define RSB_VALID_".$lappend_s.$def->node."_".$out->clk.$def->define_post." rsb_valid_m_".$def->value."\n".
                "`define RSB_READY_".$lappend_s.$def->node."_".$out->clk.$def->define_post." rsb_ready_m_".$def->value."\n";
            }
            print OUT "// RSB ".$def->node_type." END\n";
        }
        print OUT "// RSB DOMAIN END\n\n";
    }
}
print OUT "\n\n";
print OUT @async_data;
print OUT "\n//  --=============================== End ====================================--\n" if !$async_flag;
close OUT;
