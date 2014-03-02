#!/usr/bin/perl
use warnings;
print "Content-type: text/html\n\n";

eval {

# be sure there is only one argument
$num_cmd_line_args = @ARGV;
if ($num_cmd_line_args != 1) {
   die("ERROR - Expected exactly 1 argument\n");
}

# retrieve the BLK, new block-level date tracking date, and variable from the argument
# form received must be BLK/mod/date/track/variable
# e.g. XYX/mod/date/track/variable
$_ = $ARGV[0];
s/\/.*//;
$blk = $_;
#printf ("BLK is %s\n",$blk);
$_ = $ARGV[0];
s/.*mod\///;
s/\/+track.*//;
$new_Date_Tracking_date = $_;
#printf ("New Date_Tracking date is %s\n",$new_Date_Tracking_date);
$_ = $ARGV[0];
s/.*track\///;
$varb = $_;
#printf ("Variable is %s\n",$varb);

# open the file BLK_blk.txt for read
$blk_filename = $blk . "_blk.txt";
printf ("Source file name to open is %s\n",$blk_filename);
# read in the textfile
unless(open (TXTFILE, "<". $blk_filename)){
   die("ERROR - Can't open file to read for modify\n");
}
@lines = <TXTFILE>;
close(TXTFILE);

# assign a variable to collect the output
$output = "";

# loop through each line of the source file
# while searching for the date_tracking_status_date variable
# while changing the date_tracking_status_date to the new date_tracking
# append each line to $output
foreach $line (@lines) {
  # look for line containing date_tracking_status_date variable
  $vari = $line;
  $vari =~ s/ = .*$//;
  if ($vari eq "$varb\n"){
     $output .= $varb . ' = "'; 
     $output .= $new_Date_Tracking_date; 
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

