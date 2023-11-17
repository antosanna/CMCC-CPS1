#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
#LOG_FILE=$DIR_LOG/IC_NEMO_submission/launch_rebuild_nemo.`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
# all these vars defined aboce but not yet available
#TEMPORARY
iniy=1993
endy=2022
npoce=2
# END TEMPORARY
mkdir -p $DIR_TEMP
for yyyy in `seq $iniy $endy`
do
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   listfiletocheck=${SPSSystem}_${typeofrun}_IC_NEMO_list.csv
#TEMPORARY
   for st in {01..12}
   do
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
      mkdir -p ${IC_NEMO_CPS_DIR}/$st
      mkdir -p ${IC_CICE_CPS_DIR}/$st
      #for poce in `seq -w 01 $n_ic_nemo`
      for poce in `seq -w 01 $npoce`
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
         $DIR_UTIL/submitcommand.sh -q s_medium -M 2000 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
         #$DIR_OCE_IC/nemo_rebuild_restart.sh $yyyy $st $poce
      done
   done
done

