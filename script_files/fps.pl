#!/usr/bin/perl
# This script just lists all the FPs
print "Content-type: text/html\n\n";

my @fps_txt = `ls *fp.txt`;
my @fps;
foreach (@fps_txt) {
   s/_fp.txt//;
   chomp ($_);
   push (@fps, $_);
}

print "@fps\n";
