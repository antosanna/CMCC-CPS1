#!/bin/sh -l
. $HOME/.bashrc

# Load cdo/ncl 
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl

# Load Files
input_folder="/work/csp/mh31123/scratch/Wind100/Data_alpha/"

# Specify the output directory for the alpha
output_folder="/work/csp/mh31123/scratch/Wind100/Data_alpha/pp/"
#!/bin/bash


# Loop through each month from January to December
for month in {01..12}; do
    # Create a temporary file for the filtered data
    temp_file="${output_folder}/temp_${month}.nc"

    # Initialize variables to store the size of the time dimension
    time_dimension_size=0

    # Loop through each year to find the maximum time dimension size
    for year in {1993..2022}; do
        input_file="${input_folder}/alpha_output_${year}${month}.nc"
        if [ -e "$input_file" ]; then
            # Use ncdump to extract the time dimension size
            current_time_size=$(ncdump -h "$input_file" | grep "dimensions:" -A 1 | grep "time" | awk '{print $3}')
            # Update the maximum time dimension size if needed
            if [ "$current_time_size" -gt "$time_dimension_size" ]; then
                time_dimension_size="$current_time_size"
            fi
        fi
    done

    # Calculate the start and end indices for the current month
    start_index=0
    end_index=$((time_dimension_size - 1))

    echo "Processing month $month with indices $start_index to $end_index"

    # Create a temporary file for the filtered data
    temp_file="${output_folder}/temp_${month}.nc"

    # Loop through each year and concatenate the data for the current month
    for year in {1993..2022}; do
        input_file="${input_folder}/alpha_output_${year}${month}.nc"
        # Check if the input file exists
        if [ -e "$input_file" ]; then
            # Use NCO to filter the data for the current month and append to the temporary file
            ncks -d time,$start_index,$end_index -v alpha "$input_file" -O "$temp_file"
        fi
    done

    # Calculate the mean for the current month
    ncra -y ttl -O "$temp_file" "${output_folder}/mean_${month}.nc"

    # Remove the temporary file
    rm "$temp_file"
done

echo "Script completed!"

