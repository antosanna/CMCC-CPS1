#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
#LOG_FILE=$DIR_LOG/IC_NEMO_submission/launch_rebuild_nemo.`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
mkdir -p $DIR_TEMP
for yyyy in `seq $iniy_hind $endy_hind`
do
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   listfiletocheck=${SPSSystem}_${typeofrun}_IC_NEMO_list.$machine.csv
   listfiletocheck_excel=${SPSSystem}_${typeofrun}_IC_NEMO_list.$machine.xlsx
#TEMPORARY
   for st in {01..12}
   do
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
      mkdir -p ${IC_NEMO_CPS_DIR}/$st
      mkdir -p ${IC_CICE_CPS_DIR}/$st
      for poce in `seq -w 01 $n_ic_nemo`
      do
         if [[ -f $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$poce.nc ]] && [[ -f $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$poce.nc ]]
         then
            LN="$(grep -n "$yyyy$st" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"
            table_column_id=$(($((10#$poce)) + 1))
            awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
            rsync -auv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck 
            continue
         fi
         if [[ $machine == "zeus" ]]
         then
            continue
         fi
         input="$yyyy $st $poce"
         $DIR_UTIL/submitcommand.sh -q s_medium -M 2000 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
         #$DIR_OCE_IC/nemo_rebuild_restart.sh $yyyy $st $poce
      done
   done
done
if [[ $machine == "zeus" ]]
then
   title=" $machine IC NEMO checklist"
   body="Updated IC NEMO checklist from $machine "`date`
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a ${DIR_CHECK}/$listfiletocheck
fi
if [[ $machine == "juno" ]]
then
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
fi


