#!/bin/sh -l
  
. $HOME/.bashrc
#load cdo/ncl 
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl

#load Files 
data_dir="/work/csp/mh31123/scratch/Wind100/Data_wind/"

# Specify the output directory for the alpha
output_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/"

# creat output for alpha
output_alpha_file="${output_dir}alpha_output.nc"
ncap2 -O -s "alpha=zeros_like(u10)" "${data_dir}remapped_wind_era5_199301_renamed.nc" "$output_alpha_file"

# Loop through all files
for year in {1993..2022}; do
  for month in {01..12}; do
    file_name="remapped_wind_era5_${year}${month}_renamed.nc"
    file_path="${data_dir}${file_name}"

    # Check if the file exists
    if [ -f "$file_path" ]; then
      echo "Processing $file_name"

      # Extract u10, v10, u100, v100 variables
      ncks -v u10,v10,u100,v100 "$file_path" -O temp_file.nc

      # Calculate wind speeds at 10m and 100m
      ncap2 -O -s "wind_10m_data=sqrt(u10^2 + v10^2)" temp_file.nc temp_file.nc
      ncap2 -A -s "wind_100m_data=sqrt(u100^2 + v100^2)" temp_file.nc temp_file.nc

      # Calculate alpha
      ncap2 -A -s "alpha=log(wind_100m_data / wind_10m_data) / log(100/10)" temp_file.nc temp_file.nc

      # Append alpha to the output NetCDF file
      ncks -A -v alpha temp_file.nc "$output_alpha_file"

      # Remove temporary file
      rm temp_file.nc
    else
      echo "File $file_name not found."
    fi
  done
done

echo "Script completed!"

