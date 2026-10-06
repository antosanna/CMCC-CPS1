#!/bin/sh -l
###################################################################################################
## Script:  briefing_diag_plots.sh                                                               ##
## Author:  Brandon J Fisel                                                                      ##
## Summary: Creates the CMCC contribution plots.                                                 ##
## Description: Executed by launch_diagnostic_briefing to create the CMCC contribution plots for ##
##          a variable and both regions (global and Europe) and checking plots were created.     ##
## Creation Date: 16/09/2026                                                                     ##
## Revision Date: 21/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_miniconda
conda activate plot_matplotlib

set -evxu

# Read the comma-delimited input variable
decoded_input="${1//,/ }"

read -r -a args_array <<< "$decoded_input"

if [ ${#args_array[@]} -lt 9 ]; then
    echo "ERROR: Incorrect number of inputs. Found only ${#args_array[@]} inputs."
    echo "Input received: '$1'"
    exit 1
fi

anomdir="${args_array[0]}"
dirplots="${args_array[1]}"
yyyyfore="${args_array[2]}"
mmfore="${args_array[3]}"
iniy_hind="${args_array[4]}"
endy_hind="${args_array[5]}"
varm="${args_array[6]}"
flgmnth="${args_array[7]}"
flgmnth_fname="${args_array[8]}"

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyyfore
set -evxu

climdir=${DIR_CLIM}
model="CMCC"
climate_size=900 # hindcast size: 30 members * 30 years
nens=$nrunC3Sfore
blue_color="#1A36E8"

# Parse the region and lead variables
reglist=()
i_divider=0
for ((i=9; i<${#args_array[@]}; i++)); do
    if [ "${args_array[i]}" == "---" ]; then
        i_divider=$i
        break
    fi
    reglist+=("${args_array[i]}")
done

leadlist=()
for ((i=i_divider+1; i<${#args_array[@]}; i++)); do
    leadlist+=("${args_array[i]}")
done

echo "=========================================================="
echo " STARTING CMCC CONTRIBUTION DIAGNOSTIC PLOTTING"
echo " Reference Climatology: ${iniy_hind} to ${endy_hind}"
echo " Forecast Run: ${yyyyfore}-${mmfore}"
echo "=========================================================="

python3 python/plot_forecast_anom_prob.py \
    --anom_dir "$anomdir" --clim_dir "$climdir" --plot_dir "$dirplots" \
    --yyyyfore "$yyyyfore" --mmfore "$mmfore" --iniy_hind "$iniy_hind" \
    --endy_hind "$endy_hind" --varm "$varm" --reglist "${reglist[@]}" \
    --flgmnth "$flgmnth" --flgmnth_fname "$flgmnth_fname" --leadlist "${leadlist[@]}" \
    --model "$model" --climate_size "$climate_size" --nens "$nens" \
    --blue_color "$blue_color"

# Verify both reglist region images produced for input varm
for reg in "${reglist[@]}"; do
    [[ "$varm" == "z500" ]] && varm="hgt500"
    expected_file="${dirplots}/cmcc_${varm}_fore_${reg}.png"

    if [ ! -f "$expected_file" ]; then
        echo "ERROR: Missing expected plot for region '${reg}'."
        echo "File not found: $expected_file."
        exit 1
    fi
done

echo "=========================================================="
echo " CMCC contribution diagnostic plotting for ${varm} completed."
echo "=========================================================="

exit 0
