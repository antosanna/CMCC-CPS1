#!/bin/sh -l
#BSUB -q s_long
#BSUB -J launch_compute_maxmin_monthly_refperiod
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_monthly_refperiod%J.out
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_monthly_refperiod%J.err
#BSUB -P 0784
#BSUB -M 10000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh $iniy_hind

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB AND cp2 USER

set -uexv
script=launch_compute_maxmin_monthly_refperiod
np=`${DIR_UTIL}/findjobs.sh -m $machine -n ${script} -c yes`
if [[ $np -gt 1 ]]
then
   echo "already running"
   exit
fi
for st in {01..12}
do
   if [[ -f ${OUTDIR_DIAG}/C3S_statistics/$st/C3S_statistics_${st}_DONE ]]
   then
      continue
   fi
   $DIR_DIAG_C3S/statistics/compute_maxmin_monthly_refperiod.sh $st 
done

exit 0
