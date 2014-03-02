#!/usr/bin/perl 
# This script extracts the total number of warnings and errors for the RDL check

use strict;

print "Starting data extraction...\n";

# Fill an array with the names of all the FPs or blocks.
# Get this from the associated text file.
my $dbTextFile = "/auto/dtracker/rdl_checker.txt";
unless(open (TXTFILE, "<". $dbTextFile)) {
   die("ERROR - Can't open file1 to read: $!\n");
}
my @lines = <TXTFILE>;
close(TXTFILE);
my @block_names;
my $checkerVar = "_rdl_checker_status";
my $i = 0;
foreach (@lines) {
   if(/(\w+)$checkerVar/) {
      $block_names[$i] = $1;
      $i++;
   }
} 

# Read in log file for analysis
my $logPath = "/auto/latest/check_rdl_summary.log";
unless(open (TXTFILE, "<". $logPath)) {
   die("ERROR - Can't open file2 to read: $!\n");
}
@lines = <TXTFILE>;
close(TXTFILE);

# Construct the build number from the file name. The log is a link which points to a file with the build number in it
my $build_number = `ls -l $logPath`; # Get long listing from ls which will contain the build number
$build_number =~ /XXX-chip_(\d+)/; # Extract the build number
$build_number = $1;
$build_number =~ /^0*(\d+)/; # Remove any leading zeros
$build_number = $1;
print "Build Number is $build_number \n";

# Loop through each block in the @block_names array, scanning each time through the entire log looking for relevant lines
# containing error and warning counts
my %mined_hash;
foreach my $block (@block_names) {
   $mined_hash{$block} = 0; # default in case none found for this block
   foreach (@lines) {
      if (/Leaf: .*Block: $block.*Total: (\d+)/i) {
         $mined_hash{$block} = $1; # save the total number of errors and warnings for this block
      }
   }
}

# Make one more pass through the log file gathering total number of errors/warnings.
# This is done in case there are some errors/warnings that didn't associated with any block.
my $total_ew_count = 0;
foreach (@lines) {
   if (/Leaf: .*Block: .*Total: (\d+)/i) {
      $total_ew_count += $1;
   }
}
print "Total RDL checker Error+Warning count is $total_ew_count \n";

# Build an output string which is the entire replacement for the $dbTextFile.
# Pass through each line in it, appending to the output string the new replacement line
# with fresh extracted error/warning data.
my $output = ""; # initially null
my $var_name;
my $this_fp_block;
# Open $dbTextFile to read
unless(open (TXTFILE, "<". $dbTextFile)) {
   die("ERROR - Can't open file3 to read: $!\n");
}
foreach my $line (<TXTFILE>) {
   # Get the variable name from the line
   $var_name = $line;
   $var_name =~ /^(\w+) /;
   $var_name = $1;
   # Get the FP/block name from the variable
   $this_fp_block = $var_name;
   $this_fp_block =~ /^(\w+)$checkerVar/;
   $this_fp_block = $1;
   if ($var_name =~ /build_num/) {
      # This section looks for the line with the build number in it
      $output .= $var_name . ' = "';
      $output .= $build_number;
      $output .= '"';
      $output .= "\n";
   }else{
      # This sections looks for the other lines with data per FP/block
      $output .= $var_name . ' = "';
      $output .= $mined_hash{$this_fp_block};
      $output .= '"';
      $output .= "\n";
   }
} 
close(TXTFILE);

# write new output to text file
unless (open (TXTFILE, ">" . $dbTextFile)) {
   die "Cannot open file for write: $!\n";
}
print TXTFILE $output;
close (TXTFILE);

# update total number of RDL errors and warnings in project.txt file for loading into the tracker's trivia section
my $prior_rdl_ew_count;
my $project_file = "/auto/dtracker/project.txt";
unless(open (INFILE, "<". $project_file)) {
   die("ERROR - Can't open file4 to read: $!\n");
}
my @lines = <INFILE>;
close(INFILE);
unless(open (OUTFILE, ">". $project_file)) {
   die("ERROR - Can't open file5 to write: $!\n");
}
foreach (@lines) {
   if(/trivia_rdl_checker_ew = "(\d+)/) {
      $prior_rdl_ew_count = $1;
      print OUTFILE 'trivia_rdl_checker_ew = "';
      print OUTFILE $total_ew_count;
      print OUTFILE '"';
      print OUTFILE "\n";
   }elsif(/trivia_prior_rdl_checker_ew/) { # Note in project.txt trivia_prior_rdl_checker_ew must come after trivia_rdl_checker_ew
      print OUTFILE 'trivia_prior_rdl_checker_ew = "';
      print OUTFILE $prior_rdl_ew_count;
      print OUTFILE '"';
      print OUTFILE "\n";
   }else{
      print OUTFILE $_;
   }
} 
close(OUTFILE);
