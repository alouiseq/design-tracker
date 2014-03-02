#!/usr/bin/perl
print "Content-type: text/html\n\n";

eval {

# be sure there is only one argument
$num_cmd_line_args = @ARGV;
if ($num_cmd_line_args != 1) {
   die("ERROR - Expected exactly 1 argument\n");
}

# retrieve the BLK and new RTL_STAGE from the argument
# form received must be BLK/mod/RTL_STAGE
# e.g. XYX/mod/A
$_ = $ARGV[0];
s/\/.*//;
$blk = $_;
#printf ("BLK is %s\n",$blk);
$_ = $ARGV[0];
s/^.*mod\///;
$new_RTL_STAGE = $_;
#printf ("New RTL_STAGE is %s\n",$new_RTL_STAGE);

# open the file BLK_blk.txt for read
$blk_filename = $blk . "_blk.txt";
#printf ("Source file name to open is %s\n",$blk_filename);
# read in the textfile
unless(open (TXTFILE, "<". $blk_filename)){
   die("ERROR - Can't open file to read for modify\n");
}
@lines = <TXTFILE>;
close(TXTFILE);

# assign a variable to collect the output
$output = "";

# loop through each line of the source file
# while searching for the rtl_stage_status variable
# while changing the rtl_stage_status to the new rtl_stage
# append each line to $output
foreach $line (@lines) {
  # look for line containing rtl_stage_status variable
  $vari = $line;
  $vari =~ s/ = .*$//;
  if ($vari eq "rtl_stage_status\n"){
     $output .= 'rtl_stage_status = "'; 
     $output .= $new_RTL_STAGE; 
     $output .= '"'; 
     $output .= "\n"; 
  }else{
     $output .= $line;
  }
};

# open the file BLK_blk.txt for write
#printf ("Destination file name to open is %s\n",$blk_filename);
unless(open (TXTFILE, ">". $blk_filename)){
   die("ERROR - Can't open file to write\n");
}
# save the modified file
print TXTFILE $output;
close(TXTFILE);

}; # end eval
print "An ERROR occurred: $@" if $@;

1;

