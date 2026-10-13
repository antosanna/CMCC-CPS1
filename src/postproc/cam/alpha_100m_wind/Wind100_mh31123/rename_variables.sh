#!/bin/bash

# Specify the path to your NetCDF files
files_path="/work/csp/mh31123/scratch/Wind100/Data_remapped/remapped_wind_era5_2023??.nc"

for file in $files_path; do
    cdo chname,var165,u10,var166,v10,var246,u100,var247,v100 "$file" "${file%.nc}_renamed.nc"

done

