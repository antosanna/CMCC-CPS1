#!/bin/sh -l
###################################################################################################
## Script:  launch_briefing.sh                                                                   ##
## Author:  Brandon J Fisel                                                                      ##
## Summary: Submits parent scripts to queue that are responsible for downloading or creating all ##
##          required briefing plots, creating the briefing and pushing to drive.                 ##
## Description: Submits download_from_web and launch_diagnostic_briefing to queue to run in      ##
##          parallel before submitting assemble_briefing that is dependent on the prior two      ##
##          scripts completing successfully. This script is run from crontab as:                 ##
##          ./launch_briefing.sh [Optional: YYYY MM]                                             ##
## Creation Date: 21/08/2026                                                                     ##
## Revision Date: 21/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -evxu

read -r yyyy mm <<< "${1:-$(date +%Y)} ${2:-$(date +%m)}"

logdir=${DIR_LOG}/briefing_plots_${yyyy}${mm}/logs

# Submit download and CMCC contribution diagnostic plot programs first
# The first downloads primarily web images and the second creates the CMCC contribution diagnostic plots
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_push -M 5000 -j download_from_web -l $logdir -d $DIR_POST/briefing_diags -s download_from_web.sh -i "${yyyy} ${mm}"
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 8000 -j launch_diagnostic_briefing -l $logdir -d $DIR_POST/briefing_diags -s launch_diagnostic_briefing.sh -i "${yyyy} ${mm}"

# Submit the program that creates the remaining plots, the briefing presentation pptx and pushes the pptx to drive
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 20000 -j assemble_briefing -p download_from_web -w launch_diagnostic_briefing -l $logdir -d $DIR_POST/briefing_diags -s assemble_briefing.sh -i "${yyyy} ${mm}"

exit 0
