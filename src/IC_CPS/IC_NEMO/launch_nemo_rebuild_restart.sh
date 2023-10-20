#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh

set -euvx
LOG_FILE=$DIR_LOG/tests/launch_rebuild_nemo.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
# all these vars defined aboce but not yet available
#TEMPORARY
iniy=2005
endy=2005
st=10
npoce=1
# END TEMPORARY
for yyyy in `seq $iniy $endy`
do
#TEMPORARY
#   for st in {01..12}
#   do
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
      for poce in `seq -w 01 $n_ic_nemo`
      do
         input="$yyyy $st $poce"
#         $DIR_UTIL/submitcommand.sh -q s_medium -M 1000 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce1} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
         $DIR_OCE_IC/nemo_rebuild_restart.sh $yyyy $st $poce
      done
#   done
done
