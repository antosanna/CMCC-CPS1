#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# THIS IS MEANT TO RUN FOR FORECAST
. $DIR_UTIL/descr_ensemble.sh `date +%Y`

set -euvx
LOG_FILE=$DIR_LOG/$typeofrun/REMOVE_FROM_LEONARDO_FORECAST_TRANSFERRED_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

set -euvx
yyyy=2026
st=03
if [[ `ls ${DIR_ARCHIVE}/sps4_${yyyy}${st}_0??.transfer_from_Leonardo_DONE |wc -l` -ge 50 ]] 
then
   for ens in `seq -w 001 054` ; do
      caso=sps4_${yyyy}${st}_${ens}
      if [[ -d ${DIR_ARCHIVE}/$caso ]]; then
         echo $caso   
         chmod -R u+wrx ${DIR_ARCHIVE}/$caso
         rm -r ${DIR_ARCHIVE}/$caso/*
      fi
      if [[ -d ${WORK_CPS}/$caso ]]
      then
         rm -r ${WORK_CPS}/$caso
      fi
      echo "$caso removed"
   done
fi
echo "Succesfully removed cases for forecast $yyyy$st"
