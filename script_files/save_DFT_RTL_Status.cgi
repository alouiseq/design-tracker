#!/usr/bin/perl
print "Content-type: text/html\n\n";

eval {
   # be sure there is only one argument
   $num_cmd_line_args = @ARGV;
   if ($num_cmd_line_args != 1) {
      die("ERROR - Expected exactly 1 argument\n");
   }

   # retrieve the FP and new DFT_RTL_Status from the argument
   # form received must be FP/mod/DFT_RTL_Status
   # e.g. XYX/mod/NA 
   $_ = $ARGV[0];
   s/\/.*//;
   $fp = $_;
   #printf ("FP is %s\n",$fp);
   $_ = $ARGV[0];
   s/^.*mod\///;
   $new_DFT_RTL_Status = $_;
   #printf ("New DFT_RTL_Status is %s\n",$new_DFT_RTL_Status);

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
   # while searching for the dft_rtl_status variable
   # while changing the dft_rtl_status to the new value
   # append each line to $output
   foreach $line (@lines) {
      # look for line containing dft_rtl_status variable
      $vari = $line;
      $vari =~ s/ = .*$//;
      if ($vari eq "dft_rtl_status\n"){
	 $output .= 'dft_rtl_status = "'; 
	 $output .= $new_DFT_RTL_Status; 
	 $output .= '"'; 
	 $output .= "\n"; 
      }else{
         $output .= $line;
      }
   }

   # open the file FP_fp.txt for write
   #printf ("Destination file name to open is %s\n",$fp_filename);
   unless(open (TXTFILE, ">". $fp_filename)){
      die("ERROR - Can't open file to write\n");
   }
   # save the modified file
   print TXTFILE $output;
   close(TXTFILE);
}; # end eval
print "An ERROR occurred: $@ if $@;

1;
