#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

if [[ $machine == "leonardo" ]]
then
    LOG_FILE=$DIR_LOG/hindcast/launch_modify_triplette_`date +%Y%m%d%H%M`.log
    exec 3>&1 1>>${LOG_FILE} 2>&1
fi

listacasi="sps4_201909_026" 

for caso in $listacasi 
do
   echo $caso
   $DIR_UTIL/modify_triplette.sh $caso 
   sleep 5
done
exit
