#!/usr/bin/perl
print "Content-type: text/html\n\n";

eval {

# be sure there is only one argument
$num_cmd_line_args = @ARGV;
if ($num_cmd_line_args != 1) {
   die("ERROR - Expected exactly 1 argument\n");
}

# retrieve the FP and new Timing_Constraints_Reviewed_date from the argument
# form received must be FP/mod/Timing_Constraints_Reviewed_date
# e.g. XYX/mod/date 
$_ = $ARGV[0];
s/\/.*//;
$fp = $_;
#printf ("FP is %s\n",$fp);
$_ = $ARGV[0];
s/^.*mod\///;
$new_Timing_Constraints_Reviewed_date = $_;
#printf ("New Timing_Constraints_Reviewed_date is %s\n",$new_Timing_Constraints_Reviewed_date);

# open the file FP_fp.txt for read
$fp_filename = $fp . "_fp.txt";
#printf ("Source file name to open is %s\n",$fp_filename);
# read in the textfile
unless(open (TXTFILE, "<". $fp_filename)){
   die("ERROR - Can't open file to read for modify\n");
}
@lines = <TXTFILE>;
close(TXTFILE);

# assign a variable to collect the output
$output = "";

# loop through each line of the source file
# while searching for the timing_constraints_reviewed_status_date variable
# while changing the timing_constraints_reviewed_status_date to the new value
# append each line to $output
foreach $line (@lines) {
  # look for line containing timing_constraints_reviewed_status_date variable
  $vari = $line;
  $vari =~ s/ = .*$//;
  if ($vari eq "timing_constraints_reviewed_status_date\n"){
     $output .= 'timing_constraints_reviewed_status_date = "'; 
     $output .= $new_Timing_Constraints_Reviewed_date; 
     $output .= '"'; 
     $output .= "\n"; 
  }else{
     $output .= $line;
  }
};

# open the file FP_fp.txt for write
#printf ("Destination file name to open is %s\n",$fp_filename);
unless(open (TXTFILE, ">". $fp_filename)){
   die("ERROR - Can't open file to write\n");
}
# save the modified file
print TXTFILE $output;
close(TXTFILE);

}; # end eval
print "An ERROR occurred: $@" if $@;

1;

