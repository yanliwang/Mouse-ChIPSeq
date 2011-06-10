#txs_int_counter.py
#Yanli Wang
#yanly.wang@gmail.com

# Input: 
#   1. UCSC Genome Table Gene List (lines that serve as comments start with '#')
#   2. Bam File
#   3. OPTIONAL (-t) the number of bases upstream and downstream of the gene TSS: if int_size is entered, then the interval is defined as -int_size (int_size upstream) to +int_size (int_size downstream)
#   4. OPTIONAL (-s) the size of the sequence size

#Output:
#   Stdout of Offset (offset from the TSS, negative value as upstream, positive value as downstream), '\t', Value (the number of sequences that fall within the defined interval)

import csv
import sys
import subprocess
import shlex

def create_histo_array(ucsc_file, bam_file, int_size=10000, seq_size=70):
    histo_array = [0] * (int_size * 2 + 1); #the array ranges from -int_size to int_size, including 0

    print ucsc_file + "\t" + bam_file + "\t" + str(int_size) + "\t" + str(seq_size)

    return 1

    #UCSC field indexes
    bin_index = 0
    name_index = 1
    chrom_index = 2
    strand_index = 3
    txStart_index = 4
    txEnd_index = 5

    #SAMtools output indexes
    pos_index = 3
    flag_index = 1
    reverse_flag = 16

    frag_size = seq_size / 2

    cur_bin = -1
    
    ucsc_file_pointer = open(ucsc_file, 'r');
    ucsc_file_reader = csv.reader(ucsc_file_pointer, delimiter = '\t')
    ucsc_header_flag = True #indicates whether the current line is still header information, in UCSC the header begins with #
    ucsc_cur_line_num = 0;

    for line in ucsc_file_reader:
        if (ucsc_header_flag): 
            if (line[ucsc_cur_line_num].startswith('#', 0, 1) == False):
                ucsc_header_flag = False; #the current line is no longer header, proceed to the next if (else is not used, since it would be skipped during this iteration)
        if (ucsc_header_flag == False): #else not used
            bin = line[bin_index]
            if (cur_bin == bin): #considers genes with unique 'bin's, skips processing gene information on genes with the same 'bin's
                continue
            cur_bin = bin
            chrom = line[chrom_index]
            if (chrom.count('rand') > 0): #disregard entires with chr?_random
                continue

            strand = line[strand_index];
            txBegin = int(line[txStart_index]) #'+' strand begins at txStart
            if (strand == '-'):
                txBegin = int(line[txEnd_index]) # '-' strand begins at txEnd
            query_start = txBegin - int_size
            if (query_start < 0):
                query_start = 0
            query_end   = txBegin + int_size
            
            #read from the stdout output of samtools
            samtools_query_str = "samtools view " + bam_file + " " + chrom + ":" + str(query_start) + "-" + str(query_end)
            samtools_query = shlex.split(samtools_query_str)
            p = subprocess.Popen(samtools_query, stdout = subprocess.PIPE)
            std_output = p.stdout.read()

            std_output_lines = std_output.split('\n');
            
            while(std_output_lines.count('') > 0):
                std_output_lines.remove('')

            for read in std_output_lines:
                read_fields = read.split('\t')
                pos = int(read_fields[pos_index])
                #midpoint for the positive sequence
                mid = pos + (seq_size / 2)

                #midpoint for the reverse sequence
                flag = int(read_fields[flag_index])
                if ((flag & reverse_flag) == reverse_flag):
                    mid = pos + frag_size - (seq_size / 2)

                #if the index of transcript. start site is defined to be 0 within the window of -int_size and +int_size
                #then translating it into an array index, which ranges from 0 to int_size * 2
                #transcript. start site index = int_size
                txBegin_index = int_size;
                diff = mid - txBegin

                #if strand is +
                pos_array_index = txBegin_index + diff
                #if strand is -
                if (strand == '-'):
                    pos_array_index = txBegin_index - diff

                #After testing, it is determined that samtools could return a position value (pos) outside of the specified interval
                #This safeguards from any index out of bound errors caused when samtools returns that pos
                if (pos_array_index < 0 or pos_array_index >= len(histo_array)):
                    continue

                histo_array[pos_array_index] += 1

        #ucsc_cur_line_num += 1 #increment current line number
    ucsc_file_pointer.close()

    #print to stdout
    print "Offset\tValue"
    for i in range(0, len(histo_array)):
        print str(i-int_size) + "\t" + str(histo_array[i])




if __name__ == "__main__":

    if (len(sys.argv) < 3):
        print "USAGE: python txs_int_counter.py {UCSC table file} {bam file} [-t {interval size}, default = 10000] [-s {sequence size}, default = 70]"
    else:
        int_size = 0
        seq_size = 0

        start_index = 3
        for i in range(start_index, len(sys.argv), 2):
            if (sys.argv[i] == '-t'):
                if (i + 1 < len(sys.argv)):
                    int_size = int(sys.argv[i + 1])
            if (sys.argv[i] == '-s'):
                if (i + 1 < len(sys.argv)):
                    seq_size = int(sys.argv[i + 1])

        if (int_size <= 0):
            sys.stderr.write("Invalid interval size not defined or ill-defined, using default = 10000\n")
            int_size = 10000

        if (seq_size <= 0):
            sys.stderr.write("Invalud sequence size not defined or ill-defined, using default = 70\n")
            seq_size = 70

        create_histo_array(sys.argv[1], sys.argv[2], int_size, seq_size)

