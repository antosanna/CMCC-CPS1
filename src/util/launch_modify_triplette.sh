#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

if [[ $machine == "leonardo" ]]
then
    LOG_FILE=$DIR_LOG/hindcast/launch_modify_triplette_`date +%Y%m%d%H%M`.log
    exec 3>&1 1>>${LOG_FILE} 2>&1
fi
#sps4_200404_002 sps4_200304_003 sps4_200304_021 sps4_200104_029 sps4_200104_012 sps4_199504_026 sps4_199504_005

#listacasi="sps4_200906_029"
#listacasi="sps4_202402_025"
#listacasi="sps4_202311_009"
listacasi="sps4_202303_006"
for caso in $listacasi 
do
   echo $caso
   $DIR_UTIL/modify_triplette.sh $caso 
   sleep 5
done
exit
