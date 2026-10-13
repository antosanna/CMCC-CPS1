#!/bin/bash
#input and output directories
grib_dir="/data/delivery/csp/ecaccess/ERA5/6hourly/wind_1deg/"
nc_output_dir="/work/csp/mh31123/scratch/Wind100/"

# Check if the output directory exists, if not, create it
mkdir -p "$nc_output_dir"

# Loop through GRIB files and convert to NetCDF
for grib_file in "$grib_dir"/*.grib; do
    # Extracting the file name without extension
    base_name=$(basename "$grib_file")
    file_name="${base_name%.grib}"

    # Specify output NetCDF file
    nc_output_file="$nc_output_dir/${file_name}.nc"

    # Convert GRIB to NetCDF using cdo
    cdo -f nc copy "$grib_file" "$nc_output_file"

    # Optional: If you want to remove the GRIB files after conversion
    # rm "$grib_file"
done

echo "Conversion completed."

