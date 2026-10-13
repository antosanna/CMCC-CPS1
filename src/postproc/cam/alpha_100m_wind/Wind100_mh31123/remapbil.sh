#!/bin/bash

# Loop through months from 199301 to 202306
for year in {1993..2023}; do
    for month in {01..12}; do
        # Generate the file name
        input_file="wind_era5_6hourly_201906.nc"
        output_file="remapped_wind_era5_201906.nc"

        # Use cdo remapbil operation
        cdo remapbil,C3S_grid.txt $input_file $output_file

        # Optionally, you can delete the original file if you want
        # rm $input_file
    done
done

