#moving_average.py
#Yanli Wang

import csv
import sys
import subprocess
import shlex

# Input
#   1. File that contains the stdout of txs_int_counter.py
#   2. How many data points to average over

#Output
#   1. File with filename that reflects the size of the average window; similar to the input file with Offset and Value, but both fields are averaged over defined number of data points
#This allows the graph to be smoother

def moving_average(i_file, moving_window):
    
    period_location = i_file.rfind(".")
    if (period_location < 0):
        period_location = len(i_file)
    o_file = i_file[0:period_location] + "_win" + str(moving_window) + i_file[period_location:len(i_file)]

    i_file_pointer = open(i_file, 'r')
    i_file_reader = csv.reader(i_file_pointer, delimiter = '\t')
    o_file_pointer = open(o_file, 'w')
    o_file_writer = csv.writer(o_file_pointer, delimiter = '\t')
    cur_line_num = 0
    header_flag = True

    write_array = [0] * 2

    moving_offset_sum = 0
    moving_value_sum = 0
    cumulative_window = 0
    last_index = 0

    for line in i_file_reader:
        if (header_flag): 
            o_file_writer.writerow(line)
            if (line[cur_line_num].startswith('O', 0, 1) == False): #skips the header / comments (BE CAREFUL*)
                header_flag = False
        if (not header_flag):
            if (cur_line_num % moving_window == 0):
                write_array[0] = moving_offset_sum / moving_window
                write_array[1] = moving_value_sum / moving_window
                o_file_writer.writerow(write_array)
                moving_offset_sum = 0
                moving_value_sum = 0
                cumulative_window = 0
            moving_offset_sum += int(line[0])
            last_index = int(line[0])
            moving_value_sum += int(line[1])
            cumulative_window += 1
        cur_line_num += 1

    if (cumulative_window > 0):
        write_array[0] = last_index #moving_offset_sum / cumulative_window
        write_array[1] = moving_value_sum / cumulative_window
        o_file_writer.writerow(write_array)

    i_file_pointer.close()
    o_file_pointer.close()




if __name__ == "__main__":
    if (len(sys.argv) < 2):
        print "USAGE: python moving_average.py {input file} {moving average}"
    else:
        moving_average(sys.argv[1], int(sys.argv[2]))


