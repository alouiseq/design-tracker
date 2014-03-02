#!/router/bin/perl
## This script extracts RTL Stage A-D completion dates for L2 Blocks, converts the standard date format into # of days, 
## and finds difference in number of days between stage completion dates

print "Content-type: text/html\n\n";
use Date::Calc qw(Delta_Days Date_to_Days Add_Delta_Days);
use warnings;

my @blks;
my $grep_result;
my $filename;
my $year = 2012;
my $month = 3;
my $day = 2;
my $startYear;
my $startMonth;
my $startDay;
my $elapsed_days = 0;
my $stages_days;
my @stage = qw/A B C D/;
my $output;
my $flag = 0;
my $temp;
my @temp_ary = ();

# scalar variables for different views of graph
my $sort_date = 0;
my @my_fps = ();

my $liner = $ARGV[0];
#print "\$ARGV[0] = $liner\n";

# Allow csv file to be sorted by FPs or Completion Date
if ($liner) {
   if ($liner =~ /Date/) {
      my %blk_hash;
      my @blk_ary = ();
      my $count = 0;
      my $i = 0;
      $sort_date = 1;
      #print "$liner has the word Date in it.\n";
   } 
   # Customized graph views to specified FPs
   if ($liner =~ s/.*?\/(.+)/$1/) {
      @my_fps = split /,/, $liner;
      #print "My FPs:  @my_fps\n";
   }
}

# Extract blocks from My FP text files
if (scalar @my_fps != 0) {
   foreach (@my_fps) {
      $ARGV[0] = $_ . "_fp.txt";
      #print "FILE:  $ARGV[0]\n";
      while(<>) {
         if (/fp_blocks = \[(.+)\]/) {
	    $temp = $1;
            $temp =~ s/"//g; 
            $temp =~ s/[\s]//g; 
	    @temp_ary = split /,/, $temp;
	    #print "TEST:  @temp_ary\n";
	    last;
         }
      } 
      foreach (@temp_ary) {
	 $_ = $_ . "_blk.txt";
         push (@blks, $_);
      }
   }
}
#print "MY BLKS: @blks\n";

# get a list of all the blocks from ls
my @blk_buffer = `ls ACT*blk* BDP*blk* BLM*blk* BSH*blk* BWE*blk* ELB*blk* GAL*blk* HPM*blk* LFI*blk* LIR*blk* LIT*blk* LPA*blk* LSS*blk* MAG*blk* PCM*blk* PLR*blk* RMN*blk*`;

# Show only My FPs
if (scalar @my_fps != 0) {
   my @myblks = ();
   my $set = 0; #set is 1 if my FP has blocks contained in scheduler block view
   for ($i=0; $i < scalar @blk_buffer; $i++) {
      foreach (@blks) {
         if ($blk_buffer[$i] =~ /$_/) {
            #print "CHECK:  $_ EQ $blk_buffer[$i]\n";
            $set = 1;
            last;
         }
      }
      if ($set == 1) {
         push @myblks, $blk_buffer[$i];
      }
      $set = 0;
   }
   @blks = @myblks;
   if (!@blks) {print "Your FPs are not available in this block view!\n";}
   else {print "***BLOCKS***\n@blks\n";}
}
else { @blks = @blk_buffer;}

# Don't include duplicate blocks in block array  
my $seen = ();
my @arr = ();
foreach my $aa (@blks) { 
   $aa =~ s/_blk.txt//;
   $aa =~ s/\n//;
   #printf("%s\n",$aa);

   unless ($seen{$aa}) {
      push @arr, $aa;
      $seen{$aa} = 1;
   }
}
@blks = @arr;

foreach $line (@blks){
   $line =~ s/_blk.txt//;
   $line =~ s/\n//;
   #printf("%s\n",$line);

   # Now you can grep each blk file to get relevant dates and push onto array to be printed later
   $filename = $line . "_blk.txt";
   #printf("%s\n",$filename);
   foreach $stg (@stage) {
      if ($flag == 1) {
	 $days = Date_to_Days($startYear, $startMonth, $startDay);
	 $days += 1;
	 ($startYear, $startMonth, $startDay) = Add_Delta_Days(1, 1, 1, $days - 1);
      } 
      else {
         $startYear = $year;
         $startMonth = $month;
         $startDay = $day;
      }

      if ($stg eq "A") {
         $startYear = 2012;
         $startMonth = 3;
         $startDay = 2;
         $grep_result = `grep "rtl_stageA_status_completion_date" $filename`;
      } elsif ($stg eq "B") {
         $grep_result = `grep "rtl_stageB_status_completion_date" $filename`;
      } elsif ($stg eq "C") {
         $grep_result = `grep "rtl_stageC_status_completion_date" $filename`;
      } else {  # "D"
         $grep_result = `grep "rtl_stageD_status_completion_date" $filename`;
      }

      $grep_result =~ s/\n//;
      #printf("%s\n",$grep_result);
      $date = $grep_result;
      $date =~ s/.*= //;
      #printf("%s  %s\n",$date, $line);

      # The date is split up into month, day, and year and elapsed time in days is calculated between two times 
      # Mar 2, 2012 is the starting date => 0 days
      if ($date =~ /([\d]+)\/([\d]+)\/([\d]+)/) {
  	 $flag = 0;
         $month = $1;
         $day = $2;
         $year = $3; 
         $elapsed_days = Delta_Days($startYear, $startMonth, $startDay, $year, $month, $day);

	 # Temporary fix (not a great solution) for Delta_Days() miscalculation sometimes
	 # The value of 365242 and -365242 seem to be added to the actual value
	 if (($elapsed_days >= 365242) || (($elapsed_days < 365242) && ($elapsed_days >= 300000))) {
            $elapsed_days = $elapsed_days - 365242;
	 }
	 elsif (($elapsed_days <= -365242) || (($elapsed_days > -365242) && ($elapsed_days <= -300000))) {
	     $elapsed_days = $elapsed_days + 365242;
	 }

	 if ($elapsed_days < 0) {$elapsed_days = 1};
      }
      else {
	 $flag = 1;
	 $elapsed_days = 1;
      }
      # Keep count of total completion dates for each block 
      if ($sort_date == 1) {
         $count += $elapsed_days;
      } # end if sort by completion date

      $stages_days .= " " . $elapsed_days; 
   } # end for each stages
   
   $flag = 0;
 
   if ($sort_date == 0) {
      $output .= $line . " " . $stages_days . "\n";
      $stages_days = ""; 
   } # end if sort by completion date
   elsif ($sort_date == 1) {
      # Store sorted array of total elapsed time values into hash   
      $blk_ary[$i] = $count;
      $blk_hash{$line . " " . $stages_days} = $count;
      $stages_days = ""; 
      $i++;
      $count = 0;
      @blk_ary = sort {$a <=> $b} @blk_ary;
   } # end if sort by completion date
   
} # end foreach blocks

# Assign hash values to output variable string
if ($sort_date == 1) {
   foreach (@blk_ary) {
      while (($key, $value) = each %blk_hash) {
         if ($_ == $value) {
            $output .= $key . "\n";
            delete $blk_hash{$key};
         }
      }
   }
   #print "Sorted BLK_ARY:  @blk_ary\n";
} # end if sort by completion date

# write block name and Stage completion time in days to a file separated by a space in between stages
my $txtfile = "rtl_a_d_l2_sched_data.txt";
unless (open (TXTFILE, ">" . $txtfile)) {
   die ("Error adding to file: $!");
}
#print "***OUTPUT***\n$output";
print TXTFILE $output;
close(TXTFILE);    

system("cp $txtfile ./csv_files/");
