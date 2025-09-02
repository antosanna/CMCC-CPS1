#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=$endy_hind


listfiletocheck=${SPSSystem}_${typeofrun}_IC_CAM_list.${machine}.csv
if [[ $machine == "zeus" ]]
then
   inist=8
elif [[ $machine == "juno" ]] 
then
   inist=7
fi
for st in `seq -w $inist 2 12`
do
   for yyyy in `seq $iniy $endy`
   do
       for pp in {0..9}
       do
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]]
          then
              LN="$(grep -n "$yyyy$st" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"
              table_column_id=$(($((10#$ppcam)) + 1))
              awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
              rsync -auv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck 
              continue
          fi  
       done
   done     #loop on start-month
done     #loop on years
title=" $machine IC CAM checklist"
body="Updated IC CAM checklist from $machine "`date`
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a ${DIR_CHECK}/$listfiletocheck
