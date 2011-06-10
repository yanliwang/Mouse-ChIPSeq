#! usr/bin/perl
# Yanli Wang

#Input: fastq file with quality scores in Solexa (-5 to 40) represented as integers 
#Output: fastq file with quality scores in Illumina 1.3+ (0 to 40), represented as characters (Phred+64: '@' to 'h')


use warnings;
use strict;
use POSIX;

if ($#ARGV < 1)
{
	print "USAGE: perl fqparser [input file] [output file]\n";
}
else
{
	my $i_filename = $ARGV[0];
	my $o_filename = $ARGV[1];

	open I_FILE, "<", $i_filename or die $!;
	open O_FILE, ">", $o_filename or die $!;

	my $num_line = 0;
	while (my $cur_line = <I_FILE>)
	{

		if (($num_line + 1) % 4 == 0)
		{
			chomp($cur_line);
			my @quality_score_array = split(' ', $cur_line);
			
			foreach my $quality_score (@quality_score_array)
			{
				#Convert from a scale of -5 to 40 to 0 to 40, add 5 then multiple 40/45
				#The floor function along with adding 0.5 does the rounding to int
				#Note this floor method only works with positive numbers
				my $new_score = floor((($quality_score + 5) * 40.0/45.0) + 0.5) + 64; 
				my $new_char = chr($new_score);
				print O_FILE $new_char;
	
			}
			print O_FILE "\n";		
		}
		else
		{
			print O_FILE $cur_line;
		}

		$num_line++;
	}

	close O_FILE;
	close I_FILE;
}

