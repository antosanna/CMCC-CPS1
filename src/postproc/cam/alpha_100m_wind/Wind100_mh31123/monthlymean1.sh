#!/bin/bash

# List of NetCDF files
files=(
    alpha_{1993..2022}01.nc
)
# Number of timesteps
timesteps=744

# Define datadir and create a temporary directory for intermediate files
basedir=$(pwd)
datadir="$basedir/"
tmpdir="$basedir/temp/"
mkdir -p "$tmpdir"

# Process each timestep
for ((t=1; t<=$timesteps; t++)); do
    # Create an array to hold the files for this particular timestep
    timestep_files=()
    # Extract the t-th timestep from each file
    for file in "${files[@]}"; do
        out_file="$tmpdir/${file%.nc}_t$t.nc"
        cdo seltimestep,$t "$datadir$file" "$out_file"
        timestep_files+=("$out_file")
    done
    # Average the timesteps across all files
    cdo ensmean "${timestep_files[@]}" "$tmpdir/mean_timestep_$t.nc"
done
# Concatenate the averaged timestep files
cdo mergetime "$tmpdir/mean_timestep_*.nc" "combined_mean_alpha.nc"
rm -rf "$tmpdir"
