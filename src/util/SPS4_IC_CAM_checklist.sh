#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
#LOG_FILE=$DIR_LOG/IC_CAM/SPS4_IC_CAM_checklist.`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=$endy_hind

IC_CAM_CPS_DIR_REMOTE=/data/csp/sps-dev/archive/IC/CAM_CPS1/
listfiletocheck=${SPSSystem}_${typeofrun}_IC_CAM_list.csv
nrun_submitted=0
tstamp="00"
for st in `seq -w 1 12`
do
   for yyyy in `seq $iniy 2020`
   do
       yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
       mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
       for pp in {0..9}
       do
          ppcam=`printf '%.2d' $(($pp + 1))`   
          file_exists=`ssh sps-dev@zeus01.cmcc.scc ls $IC_CAM_CPS_DIR_REMOTE/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc |wc -l`
          file_exists_juno=`ls $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc |wc -l`
          if [[ $file_exists -eq 1 ]] || [[ $file_exists_juno -eq 1 ]]
          then
              LN="$(grep -n "$yyyy$st" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"
              table_column_id=$(($((10#$ppcam)) + 1))
              awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
              rsync -auv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck 
          fi  
       done
   done     #loop on start-month
done     #loop on years
