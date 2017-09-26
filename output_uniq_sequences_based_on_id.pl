#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

my $usage = qq{
This script takes an input FASTQ file (formatted with four lines per sequence) and removes duplicate entries based on ID.

Usage:
 perl $0 -i <path for input file> -o <output file name>

\n};

my $infile;
my $outfile;
GetOptions (
    "i=s" => \$infile,
    "o=s" => \$outfile,
    )
    or die $usage;
die $usage unless defined $infile;
die $usage unless defined $outfile;

open (my $IN, $infile) or die "Unable to open $infile \n";
open (my $OUT, ">$outfile") or die "Unable to open file for output. \n";

#example input format
# @HWI-D00653:49:H2FF5BCXX:2:1101:20339:3854 1:N:0:ATCACG
# CCCTCCGTGGACGAACCTTGCGGAGGAACCCTTAGGTTTTCGGGGCATTGGATTCTCACCAATGTTTGCGTTACTCAAGCCGACATTCTCGCTTCCGCTTCGTCCACCGCCGCTCGCGCGGGTGCTTCCCTCTAAGGCGGAACGCTCCCCTACCGATGCA
# +
# DDDCDHHIIIHIGHHH<FFEHHIHIIHIGIHHHIHIFE?GHHDIIGHHFHFHEFHEHHIIIHEHHIEC@C<EHGHEHHHHIIIDHHEHGHCHEHFHIIIIIEHHHHHHDHIHIDHHHCDDHCDEHHHHFEHEHGHGEHHDHHIIIIIIIIHEHIIGHHCE
# @HWI-D00653:49:H2FF5BCXX:2:1101:20339:3854 2:N:0:ATCACG
# CAGCCACCCTTGAAAGAGTGCGTAATAGCTCACTGATCGAGCGCTCTTGCGCCGAAGATGAACGGGGCTAAGCGATCTGCCGAAGCTGTGGGATGTAAAAATGCATCGGTAGGGGAGCGTTCCGCCTTAGAGGGAAGCACCCGCGCGAGCGGCGGTGGAC
# +
# DDADDIIIIIHIHHHHEEHIIIHHIHIHIIICEHIIHIIIIIIIHGHGIIIHIIIIIHGIIGHHGIIHHHCHHG=HEHHHHIDHHGCHHHIIGEHEHHHHH<FHHHCEHHHIIIHHIGIHHECH=GG/F?EEHHIHDHHIGHIIIICEHIHIIHGCCGGE

my %id_hash;
my $unique_seq_counter = 0;
my $fastq_line_count = 0;
my $print_flag = 0;
while (my $line = <$IN>) {
    $fastq_line_count ++;
    if ($fastq_line_count % 4 == 1) { #modulus (%) used to determine the line count relative to the 4 line format of a fastq file; here we want to process IDs from the 1st line
	my $ids = join("+", $line); #merge ID and mate pair info (first and second column) so the paired read is uniq, otherwise ID is the same and would be removed
	if (exists $id_hash{$ids}) { #check if ID has been encountered previously; if it has move to the next line of input
	    next;
	}
	else { #if ID has not been detected previously then print the line
	    $id_hash{$ids} = 0; #add ID to hash
	    print $OUT $line; #print out unique sequences
	    $unique_seq_counter ++; #increment counter
	    $print_flag = 1; #set flag to print remaining lines belonging to the sequence
	}
    }
    elsif ($print_flag == 1) { #flag indicates the line of input is not the first line of the fastq format that has the IDs, but belongs to a unique sequence and should be printed to output
	print $OUT $line; #print out unique sequences
	if ($fastq_line_count % 4 == 0) {
	    $print_flag = 0; #reset print flag to 0 after all four lines from the unique sequence have been printed
	}
    }
    else {
	next;
    }
}
close $IN;
close $OUT;
print "\nThere are $unique_seq_counter unique sequences in the output file: $outfile. \nEach member of a pair of sequences was counted as a unique sequence.\n\n";
exit;
