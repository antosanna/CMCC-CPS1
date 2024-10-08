#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993

set -euvx
#LOG_FILE=$DIR_LOG/IC_NEMO_submission/launch_rebuild_nemo.`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
if [[ $machine != "juno" ]]
then
   echo "NEMO ICs produced only on Juno" 
   exit 0
fi  
listfiletocheck=${SPSSystem}_${typeofrun}_IC_NEMO_list.csv
mkdir -p $DIR_TEMP
for yyyy in `seq $iniy_hind $endy_hind`
do
#TEMPORARY
#   for st in {01..12}
   for st in {07..09}
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
         input="$yyyy $st $poce"
         $DIR_UTIL/submitcommand.sh -q s_medium -M 2500 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
      done
   done
done
