#!/bin/sh -l
#BSUB -J copy_webplots_to_data
#BSUB -q s_medium
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/copy_webplots_to_data.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/copy_webplots_to_data.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

#load module for sshpass
module load $modulepass
set -uvx

yyyy=`date +%Y`
st=`date +%m`

dirplot=$SCRATCHDIR/diag_C3S/forecast_plots/
dirplot_oce=$SCRATCHDIR/diag_oce/toce

dirplot_data=/data/cmcc/cp1/temporary/forecast_plots
mkdir -p $dirplot_data

touchfile=${dirplot_data}/copy_plots4web_and_anom_DONE_to_data_Cassandra_${yyyy}${st}
if [[ -f $touchfile ]] 
then
   exit 0
fi

rsync -auv ${dirplot}/$yyyy$st $dirplot_data/
rsync -auv ${dirplot_oce}/$yyyy$st $dirplot_data/


DIR_FORE_ANOM_DATA=/data/cmcc/cp1/temporary/fore_anom
mkdir -p $DIR_FORE_ANOM_DATA
rsync -auv $DIR_FORE_ANOM/$yyyy$st $DIR_FORE_ANOM_DATA

touch $touchfile
title="[$SPSSYS] notification: data and plots copied to Cassandra /data"
body="forecast anom and plots copied to Cassandra $dirplot_data/$yyyy$st. Ready to be copied to Juno /wowrk with $DIR_UTIL/copy_webdiags_fore_anom_from_dataCassandra.sh"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
exit 0
