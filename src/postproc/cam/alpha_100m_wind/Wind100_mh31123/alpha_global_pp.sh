#!/bin/sh -l
. $HOME/.bashrc

# Load cdo/ncl 
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl

# Load Files 
data_dir="/work/csp/mh31123/scratch/Wind100/Data_wind/"

# Specify the output directory for the alpha
output_dir="/work/csp/mh31123/scratch/Wind100/Data_alpha/pp/"

# Loop through all months
for month in {01..12}; do
  # Create a new output file for each month
  output_alpha_file="${output_dir}alpha_output_month_${month}.nc"
  ncap2 -O -s "alpha=float('nan')" -s "time_counter=0" "$output_alpha_file"

  # Loop through all years
  for year in {1993..2023}; do
    file_name="remapped_wind_era5_${year}${month}_renamed.nc"
    file_path="${data_dir}${file_name}"

    # Check if the file exists
    if [ -f "$file_path" ]; then
      echo "Processing $file_name"

         # Loop through the first 185 hours of the month (assuming 6-hour intervals)
      for hour in {00..184..6}; do
        # Calculate the hour-specific file name
        hour_file_name="remapped_wind_era5_${year}${month}${hour}_renamed.nc"
        hour_file_path="${data_dir}${hour_file_name}"

        # Check if the hour-specific file exists
        if [ -f "$hour_file_path" ]; then

          ncks -v u10,v10,u100,v100 "$hour_file_path" -O temp_file.nc

          # Calculate wind speeds at 10m and 100m
          ncap2 -O -s "wind_10m_data=sqrt(u10^2 + v10^2)" temp_file.nc temp_file.nc
          ncap2 -A -s "wind_100m_data=sqrt(u100^2 + v100^2)" temp_file.nc temp_file.nc

          # Calculate alpha
          ncap2 -A -s "alpha=log(wind_100m_data / wind_10m_data) / log(100/10)" temp_file.nc temp_file.nc

          # Append alpha to the output NetCDF file
          ncks -A -v alpha -d time_counter,$((hour/6)) -d time_counter,1 temp_file.nc "$output_alpha_file"        
       fi
      done
    else
      echo "File $file_name not found for year $year and month $month."
    fi
  done

  # Calculate mean alpha for the month
# Create mean_alpha variable in the output file
ncap2 -O -s "mean_alpha=float('nan')" "$output_alpha_file" "$output_alpha_file"

# Calculate mean_alpha for the month
ncap2 -O -s "mean_alpha=mean(alpha, 0);" "$output_alpha_file" "$output_alpha_file"

  # Remove temporary file
 [ -f temp_file.nc ] && rm temp_file.nc

  echo "Processed month $month"
done

echo "Script completed!"


