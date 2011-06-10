#! usr/bin/perl
# Yanli Wang
use warnings;
use strict;

#Input:
#   1. Name of the output file
#   2. UCSC Genome Table Gene List
#   3. OPTIONAL: the size of the interval (i_size)

#Output:
#   1. File with filename defined by the username, containing the following fields separated by '\t': name (RefSeq ID), chrom, strand, txStart, txEnd, Upstream (number of sequences that fall within the i_size upstream of TSS), Downstream (number of sequences that fall within the i_size + skip_size (default=1000) downstream of TSS)

#Notes:
#Please note that the interval size here is defined different than the txs_int_counter.py
#A temp file is created to catch the output of Samtool, this program could be modified to read directly from stdout


if ($#ARGV < 2)
{
    print "USAGE: perl counter {output file} {UCSC table file} {bam file} [{interval_size}]\n";
}
elsif ($#ARGV < 3)
{
    count($ARGV[0], $ARGV[1], $ARGV[2], 2000);
}
else
{
    count($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);
}

sub count
{
    my $ucsc_file = $_[1];
    my $bam_file = $_[2];
    my $out_file = $_[0];
    my $int_size = $_[3];
    my $skip_size = 1000;

    my $bin_index = 0;
    my $name_index = 1;
    my $chrom_index = 2;
    my $strand_index = 3;
    my $txStart_index = 4;
    my $txEnd_index = 5;

    open IFH1, "<", $ucsc_file or die $!;
    open OFH1, ">", $out_file or die $!;
    print OFH1 "#name\tchrom\tstrand\ttxStart\ttxEnd\tUpstream\tDownstream\n";
    close OFH1;

    my $header_flag = 1;
    my $cur_bin = -1;
    while (my $cur_line = <IFH1>)
    {
	chomp($cur_line);
	if ($header_flag)
	{
	    if (substr($cur_line, 0, 1) ne "#")
	    {
		$header_flag = 0;
	    }
	}

	if (!$header_flag)
	{
	    my @fields = split('\t', $cur_line);
	    my $bin = $fields[$bin_index];
	    my $name = $fields[$name_index];
	    my $chrom = $fields[$chrom_index];
	    my $strand = $fields[$strand_index];
	    my $txStart = $fields[$txStart_index];
	    my $txEnd = $fields[$txEnd_index];

	    if ($cur_bin == $bin)
	    {
		next;
	    }
	    else
	    {
		$cur_bin = $bin;
	    }

	    open OFH1, ">>", $out_file or die $!;
	    print OFH1 "$name\t$chrom\t$strand\t$txStart\t$txEnd\t";
	    close OFH1;

	    #Values first assume strand as "+"
	    my $query_upstream_start = $txStart - $int_size;
	    my $query_downstream_start = $txStart + $skip_size;

	    #Changes the start and end values if the strand is "-"
	    if ($strand eq "-")
	    {
		$query_upstream_start = $txEnd;
		$query_downstream_start = $txEnd - $int_size - $skip_size;
	    }

	    my $query_upstream_end = $query_upstream_start + $int_size;
	    my $query_downstream_end = $query_downstream_start + $int_size;

	    system("samtools view $bam_file $chrom:$query_upstream_start-$query_upstream_end | wc -l >> $out_file");
	    system("samtools view $bam_file $chrom:$query_downstream_start-$query_downstream_end | wc -l >> $out_file");
	}
	
    }
    close IFH1;
    fixoutput($out_file);
}

sub fixoutput
{
    my $oldfile = $_[0];
    my $newfile = "$_[0]-temp*";
 
    open IFH2, "<", $oldfile or die $!;
    open OFH2, ">", $newfile or die $!;
    my $header_flag = 1;
    my $line_counter = 0;
    while (my $cur_line = <IFH2>)
    {
	chomp($cur_line);

	if ($header_flag)
	{   
	    if (substr($cur_line, 0, 1) ne "#")
	    {
		$header_flag = 0;
	    }
	    else
	    {
		print OFH2 $cur_line . "\n";
	    }
	}
	if (!$header_flag)
	{
	    if ($line_counter % 2 == 1)
	    {
		print OFH2 $cur_line . "\t";
	    }
	    else
	    {
		print OFH2 $cur_line . "\n";
	    }
	}
	$line_counter++;
    }
    close OFH2;
    close IFH2;
    system("mv $newfile $oldfile");
    system("rm -f $newfile");
}
