#!/usr/bin/perl
print "Content-type: text/html\n\n";

eval {

# be sure there is only one argument
$num_cmd_line_args = @ARGV;
if ($num_cmd_line_args != 1) {
   die("ERROR - Expected exactly 1 argument\n");
}

# retrieve the BLK and new comment from the argument
# form received must be BLK/mod/"comment string"
# e.g. XYX/mod/new comment
$_ = $ARGV[0];
s/\/.*//;
$blk = $_;
#printf ("BLK is %s\n",$blk);
$_ = $ARGV[0];
s/^.*mod\///;
#If new comment contains special code indicating enter key pressed to go to newline, convert to \n
s/GGGretGGG/\\n/g;
$new_comment = $_;
#printf ("New comment is %s\n",$new_comment);

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
# while searching for the comment variable
# while changing the comment to the new comment
# append each line to $output
foreach $line (@lines) {
  # look for line containing comments_text variable
  $vari = $line;
  $vari =~ s/ = .*$//;
  if ($vari eq "comments_text\n"){
     $output .= 'comments_text = "'; 
     $output .= $new_comment; 
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

# Return these headers to keep IE from caching
print('header("Cache-Control: no-cache, must-revalidate");\n');
print('header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");\n');

}; # end eval
print "An ERROR occurred: $@" if $@;

1;

