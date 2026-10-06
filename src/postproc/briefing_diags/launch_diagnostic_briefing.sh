#!/bin/sh -l
###################################################################################################
## Script:  launch_diagnostic_briefing.sh                                                        ##
## Author:  Brandon J Fisel                                                                      ##
## Summary: Submits multiple instances of briefing_diag_plots for each variable.                 ##
## Description: Submits the briefing_diag_plots script for each variable that executes a python  ##
##          script to create the CMCC contribution diagnostic plots.                             ##
## Creation Date: 21/08/2026                                                                     ##
## Revision Date: 28/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

yyyy=$1
st=$2
iniy_hind=1995
endy_hind=2024
leadlist="2"
flgmnth="0"
flgmnth_fname="seasonal"

POST_DIR=${DIR_POST}/briefing_diags
dirplots=${SCRATCHDIR}/briefing_plots_$yyyy$st

mkdir -p $dirplots

# Briefing variables and domains
varlist="mslp z500 t2m precip sst"
reglist="global Europe"

# Check for existence of png images first
diag_exist=true
for var in $varlist; do
    if [[ "$var" == "z500" ]]; then
        file_var="hgt500"
    else
        file_var="$var"
    fi
    for reg in $reglist; do
        if [ ! -f "${dirplots}/cmcc_${file_var}_fore_${reg}.png" ]; then
            diag_exist=false
            break 2
        fi
    done
done

if $diag_exist; then
    echo "All CMCC contribution diagnostic plots exist, skipping creation..."
    exit 0
fi

echo "Creating CMCC contribution diagnostic plots"
for var in $varlist; do
    echo "Processing $var for $st"
    anomdir=${DIR_FORE_ANOM}/$yyyy$st

    # Create the input variable and convert to comma-delimited to handle additional arrays
    input="$anomdir $dirplots $yyyy $st ${iniy_hind} ${endy_hind} $var $flgmnth ${flgmnth_fname} $reglist --- $leadlist"
    encoded_input="${input// /,}"
    ${POST_DIR}/briefing_diag_plots.sh "$encoded_input"
done

exit 0
