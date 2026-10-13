#!/bin/sh -l

. $HOME/.bashrc
#load cdo/ncl 
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl
set -ux
#load Files 
data_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/6hourly_alpha/"
data_extra_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/moredays/"
# Specify the output directory for the alpha
output_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/alpha_185days/"
# Loop through the years and months
for year in {1993..2022}; do
    for month in {01..12}; do
        # Construct the list of monthly files (6 consecutive months)
        monthly_files=("$data_dir/alpha_output_${year}${month}"*.nc)

        # Add the extra file from the additional directory
          extra_day_file=("$data_extra_dir/alpha_ouput_${year}${month}01.nc")
        # Check if there are at least 6 monthly files and an extra file
        if [ ${#monthly_files[@]} -ge 6 ] && [ -f "$extra_day_file" ]; then
            # Construct the command to merge the files
            cmd="cdo mergetime ${monthly_files[@]} $extra_day_file $output_dir/output_file_${year}${month}.nc"

# Print debug information
            echo "Command: $cmd"
            echo "Monthly Files: ${monthly_files[@]}"
            echo "Extra Day File: $extra_day_file"           
 
           # Execute the command
            $cmd

            # Optionally, you can add additional processing logic here
            # echo "Processing completed for $year$month."
        else
            echo "Not enough files for $year$month or missing extra file."
        fi
    done
done
























#1993-01-01 is 1993-07-04
#1997-02-01 is 1997-08-04
#1997-03-01 is 1997-09-01
#1997-04-01 is 1997-10-02
#1997-05-01 is 1997-11-01
#1997-06-01 is 1997-12-02
#1997-07-01 is 1998-01-01
#1997-08-01 is 1998-02-01
#1997-09-01 is 1998-03-04
#1997-10-01 is 1998-04-03
#1997-11-01 is 1998-05-04
#1997-12-01 is 1998-06-03

#years=ispan(1993,2023,1)
#files=(alpha_output_{1993..2022}*.nc)
#for file in "${files[@]}";do
#out_file="${file%.nc}01.nc"
#cdo selday,1,2 "$data_dir$file" "$output_dir$out_file"
#done
#cdo mergetime alpha_output_199301.nc alpha_output_199302.nc alpha_output_199303.nc alpha_output_199304.nc alpha_output_199305.nc alpha_output_199306.nc alpha_ouput_19930701.nc alpha_199301.nc


#cdo mergetime "$data_dir$file" alpha_output_201802.nc alpha_output_201803.nc alpha_output_201804.nc alpha_output_201805.nc alpha_output_201806.nc 20180701.nc alpha_201801.nc
#cdo mergetime alpha_output_201808.nc alpha_output_201809.nc alpha_output_201810.nc alpha_output_201811.nc alpha_output_201812.nc alpha_output_201901.nc 20190201.nc alpha_201808.nc



