#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J launch_compute_maxmin_monthly_refperiod
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_monthly_refperiod%J.out
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/DIAGS/C3S_statistics/launch_compute_maxmin_monthly_refperiod%J.err
#BSUB -P 0490
#BSUB -M 10000

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh $iniy_hind

# THIS SCRIPT IS MEANT TO BE LAUNCHED FROM CRONTAB AND cp2 USER

set -uexv
st=12
if [[ `ls $DIR_LOG/DIAGS/C3S_statistics/compute_maxmin_allyears_st${st}_*_done |wc -l` -eq 53 ]]
then
   $DIR_UTIL/sendmail.sh -m $machine -e antonella.sanna@cmcc.it -M "single year statistics for $st completed" -t "C3S statistics"
   $DIR_DIAG_C3S/statistics/compute_maxmin_monthly_refperiod.sh $st 
fi

exit 0
