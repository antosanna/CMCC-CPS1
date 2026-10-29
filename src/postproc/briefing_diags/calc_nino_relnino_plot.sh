#!/bin/sh -l
###################################################################################################
## Script:  calc_nino_relnino_plot.sh                                                            ##
## Author:  Andrea Borrelli and Brandon J Fisel                                                  ##
## Summary: Executes the Nino3.4/Relative Nino3.4 overlay plotting script.                       ##
## Description: Adapted from ENSO_plot.ncl and RONI_plot.ncl plotting programs, this script      ##
##          downloads most recent text indices, then executes the plotting program for the       ##
##          creation of overlaid Nino3.4 and Relative Nino3.4 plumes.                            ##
## Creation Date: ??/??/202?                                                                     ##
## Revision Date: 22/10/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh 
. ${DIR_UTIL}/load_miniconda
conda activate plot_matplotlib

set -evxu

#notes: st now mm, stm7 now mm7
read -r yyyy mm <<< "${1:-$(date +%Y)} ${2:-$(date +%m)}"

baseline="$yyyy-$mm-01"
yyyym7=$(date -d "$baseline -7 months" +%Y)
mm7=$(date -d "$baseline -7 months" +%m)
refperiod="${iniy_hind}-${endy_hind}"
region="Nino3.4"

set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu

stdfile="${DIR_RONI}/std4RONI_tropic_${region}_sst.${mm}.${refperiod}.monthly.nc"
logofile="${DIR_POST}/briefing_diags/ncl/cmcc_logo_bw.jpg"
anomdir="${DIR_FORE_ANOM}/${yyyy}${mm}"
dirplots="${SCRATCHDIR}/diag_C3S/forecast_plots/${yyyy}${mm}"
noaa_dir="${SCRATCHDIR}/ENSO/NOAA"
ncep_dir="${SCRATCHDIR}/ENSO/NCEP"

obs_rnino_fname="Rnino34.ascii.txt"
obsf_rnino="${noaa_dir}/${obs_rnino_fname}"
obs_nino_fname="sstoi.indices"
obsf_nino="${ncep_dir}/${obs_nino_fname}"

url_rnino="https://www.cpc.ncep.noaa.gov/data/indices/${obs_rnino_fname}"
url_nino="https://www.cpc.ncep.noaa.gov/data/indices/${obs_nino_fname}"

mkdir -p $noaa_dir
mkdir -p $ncep_dir    
mkdir -p $DIR_LOG/wrapper

[ -f $obsf_rnino ] && rm $obsf_rnino
[ -f $obsf_nino ] && rm $obsf_nino
    
${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j wget_wrapper_nino -l ${DIR_LOG}/wrapper -d ${DIR_UTIL} -s wget_wrapper.sh -i "$ncep_dir $url_nino"
while true
do
    njob=$("${DIR_UTIL}/findjobs.sh" -m "$machine" -n wget_wrapper_nino -c yes)
    if [[ "$njob" -eq 0 ]]; then
        break
    fi
    sleep 60
done

${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j wget_wrapper_rnino -l ${DIR_LOG}/wrapper -d ${DIR_UTIL} -s wget_wrapper.sh -i "$noaa_dir $url_rnino"
while true
do
    njob=$("${DIR_UTIL}/findjobs.sh" -m "$machine" -n wget_wrapper_rnino -c yes)
    if [[ "$njob" -eq 0 ]]; then
        break
    fi
    sleep 60
done

python3 python/nino34_rnino_plume.py \
    --yyyy "$yyyy" --mm "$mm" --yyyym7 "$yyyym7" --mm7 "$mm7" --nens "$nrunC3Sfore" \
    --sps "$SPSSystem" --refperiod "$refperiod" --anomdir "$anomdir" \
    --dirplots "$dirplots" --region "$region" --factor "$stdfile" --nino-obs "$obsf_nino" \
    --rnino-obs "$obsf_rnino" --cmcc-logo "$logofile"

exit 0
