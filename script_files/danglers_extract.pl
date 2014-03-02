#!/usr/bin/perl 
# This script extracts the number of warnings/errors for DANGLERS.

use strict;

print "Starting data extraction...\n";

# Fill an array with the names of all the FPs or blocks.
# Get this from the associated text file.
my $dbTextFile = "/auto/cppfs2n/wwwdv/wwwroot/antares/dtracker/danglers.txt";
unless(open (TXTFILE, "<". $dbTextFile)) {
   die("ERROR - Can't open file1 to read: $!\n");
}
my @lines = <TXTFILE>;
close(TXTFILE);
my @fp_names;
my $checkerVar = "_danglers_status";
my $i = 0;
foreach (@lines) {
   if(/(\w+)$checkerVar/) {
      $fp_names[$i] = $1;
      $i++;
   }
} 

# Read in log file for analysis
my $logPath = "/auto/ssefe5/antares_checks/latest/danglers.classification.log";
unless(open (TXTFILE, "<". $logPath)) {
   die("ERROR - Can't open file2 to read: $!\n");
}
@lines = <TXTFILE>;
close(TXTFILE);

# Construct the build number from the file name. The log is a link which points to a file with the build number in it
my $build_number = `ls -l $logPath`; # Get long listing from ls which will contain the build number
$build_number =~ /antares-chip_(\d+)/; # Extract the build number
$build_number = $1;
$build_number =~ /^0*(\d+)/; # Remove any leading zeros
$build_number = $1;
print "Build Number is $build_number \n";

# Loop through each FP in the @fp_names array, scanning each time through the entire log looking for relevant lines
# containing error and warning counts
my %mined_hash;
my $mod_fp_name;
my $this_bit_count_string;
foreach my $fp (@fp_names) {
   $mod_fp_name = $fp;
   $mod_fp_name =~ s/_.*//;
   $mined_hash{$fp} = 0; # default in case none found for this fp
   foreach (@lines) {
      if ($mod_fp_name =~ /mag/i) {
         # Special case for MAGx because MAG{0..2} are different than MAG3
         if ($mod_fp_name =~ /3/) {
            # Case for MAG3
            if (/\/\/ mag3_fp/i) {
               $mined_hash{$fp} ++; # bump the number of buses found for this FP
               $this_bit_count_string = /(\d+) +bits/;
            }
            if (/,mag3_fp/i) {
               $mined_hash{$fp} ++; # bump the number of buses found for this FP
               $this_bit_count_string = /(\d+) +bits/;
            }
         }else{
            # Case for MAG{0..2}
            if (/\/\/ $mod_fp_name[012]_fp/i) {
               $mined_hash{$fp} ++; # bump the number of buses found for this FP
               $this_bit_count_string = /(\d+) +bits/;
            }
            if (/,$mod_fp_name[012]_fp/i) {
               $mined_hash{$fp} ++; # bump the number of buses found for this FP
               $this_bit_count_string = /(\d+) +bits/;
            }
         }
      }else{
         # All other FPs other than MAGx
         if (/\/\/ $mod_fp_name\d*_fp/i) {
            $mined_hash{$fp} ++; # bump the number of buses found for this FP
            $this_bit_count_string = /(\d+) +bits/;
         }
         if (/,$mod_fp_name\d*_fp/i) {
            $mined_hash{$fp} ++; # bump the number of buses found for this FP
            $this_bit_count_string = /(\d+) +bits/;
         }
      }
   }
}

# Make one more pass through the log file gathering total number of danglers.
# This is done in case there are some danglers that didn't associated with any FP.
my $total_bit_count = 0;
foreach (@lines) {
   if (/\/\/ \w+\d*_fp/i) {
      $this_bit_count_string = /(\d+) +bits/;
      $total_bit_count += $1;
   }
   if (/,\w+\d*_fp/i) {
      $this_bit_count_string = /(\d+) +bits/;
      $total_bit_count += $1;
   }
}
print "Total dangling wires is $total_bit_count \n";

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

# update total number of dangling wires in project.txt file for loading into the tracker's trivia section
my $prior_total_bit_count;
my $project_file = "/auto/cppfs2n/wwwdv/wwwroot/antares/dtracker/project.txt";
unless(open (INFILE, "<". $project_file)) {
   die("ERROR - Can't open file4 to read: $!\n");
}
my @lines = <INFILE>;
close(INFILE);
unless(open (OUTFILE, ">". $project_file)) {
   die("ERROR - Can't open file5 to write: $!\n");
}
foreach (@lines) {
   if(/trivia_dangling_wires = "(\d+)/) {
      $prior_total_bit_count = $1;
      print OUTFILE 'trivia_dangling_wires = "';
      print OUTFILE $total_bit_count;
      print OUTFILE '"';
      print OUTFILE "\n";
   }elsif(/trivia_prior_dangling_wires/) { # Note in project.txt trivia_prior_dangling_wires must come after trivia_dangling_wires
      print OUTFILE 'trivia_prior_dangling_wires = "';
      print OUTFILE $prior_total_bit_count;
      print OUTFILE '"';
      print OUTFILE "\n";
   }else{
      print OUTFILE $_;
   }
} 
close(OUTFILE);

