#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/SPS4_IC_CAM_checklist.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=$endy_hind

IC_CAM_CPS_DIR_REMOTE=/data/csp/sps-dev/archive/IC/CAM_CPS1/
listfiletocheck=${SPSSystem}_${typeofrun}_IC_CAM_list.csv
listfiletocheck_excel=${SPSSystem}_${typeofrun}_IC_CAM_list.xlsx
nrun_submitted=0
if [[ $machine == "zeus" ]]
then
   exit 0
fi
tstamp="00"
for st in `seq -w 1 12`
do
   for yyyy in `seq $iniy 2014`
   do
       yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
       mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
       dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
       if [[ $dd -eq 29 ]]
       then
          dd=28
       fi
       for pp in {0..9}
       do
          
          ppcam=$(($pp + 1))
          file_exists=`ssh sps-dev@zeus01.cmcc.scc ls $IC_CAM_CPS_DIR_REMOTE/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc |wc -l`
          file_exists_juno=`ls $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc |wc -l`
          if [[ $file_exists -eq 1 ]] || [[ $file_exists_juno -eq 1 ]]
          then
              LN="$(grep -n "$yyyy$st" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"
              table_column_id=$(($((10#$ppcam)) + 1))
              awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
              rsync -auv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck 
          fi  

   done     #loop on start-month
done     #loop on years
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${listfiletocheck} ${DIR_CHECK}/$listfiletocheck_excel

if [[ ! -f $DIR_CHECK/$listfiletocheck_excel ]]
then
    title="[CPS1 ERROR] $DIR_CHECK/$listfiletocheck_excel checklist not produced"
    body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py "
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
else   
    rclone copy ${DIR_CHECK}/$listfiletocheck_excel my_drive:
fi
condafunction deactivate $envcondarclone
