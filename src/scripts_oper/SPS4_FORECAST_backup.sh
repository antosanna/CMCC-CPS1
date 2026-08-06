#!/bin/sh -l
##BSUB -q s_long
##BSUB -n 1
##BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_FORECAST_backup_out.%J
##BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_FORECAST_backup_err.%J
##BSUB -J SPS4_FORECAST_backup
##BSUB -P 0784
##BSUB -sla SC_sps35

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

echo "SPS4_FORECAST_backup.sh starting `date`"

st=`date +%m`
yyyy=`date +%Y`
if [[ $machine == "leonardo" ]]  #-from now possibly on both cmcc machine but NOT on Leonardo
then
   message="this script is meant to be run on CMCC machines!!!"
   body=$message
   title="[$CPSSYS] ERROR: SPS4_FORECAST_backup.sh exited"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -t "$title" -M "$body" -r "yes" -s ${yyyy}${st} -g yes
   echo "exit now"
   exit 1
fi

${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -n 1 -M 30000 -j SPS4_step1_ICs -l ${DIR_LOG}/forecast/`date +\%Y\%m` -d ${DIR_CPS} -s SPS4_step1_ICs.sh

${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j SPS4_submission_FORECAST -l $DIR_LOG/forecast/`date +\%Y\%m` -p SPS4_step1_ICs -d $DIR_CPS -s SPS4_submission_FORECAST.sh
