#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

cnt_this_script_running=$(ps -u ${operational_user} -f |grep copy_SPS4DMO_from_Zeus.sh| grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
   echo "already running"
   exit
fi
remote=sps-dev@fdtn-zeus
DIR_ARCHIVE1=/work/cmcc/cp1/CMCC-CM/archive/
DIR_ARCHIVE1_old=/work/csp/cp1/CMCC-CM/archive/
DIR_ARCHIVE1_remote=/work/csp/sps-dev/CMCC-CM/archive/
DIR_CASES_remote=/work/csp/sps-dev/CPS/CMCC-CPS1/cases
#iniy_hind=2010
for st in 08
do
   n_rsync=0
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      lista_remote=`ssh $remote ls -d ${DIR_ARCHIVE1_remote}/${SPSSystem}_${yyyy}${st}_??? |rev|cut -d '/' -f1| rev`
      for caso in $lista_remote
      do
         is_caso_completed=`ssh $remote ls ${DIR_CASES_remote}/$caso/logs/run_moredays_${caso}_DONE| wc -l`
         if [[ $is_caso_completed -eq 1 ]]
         then
            if [[ ! -f $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE ]]
            then
               if [[ ! -f $DIR_ARCHIVE1_old/$caso.transfer_from_Zeus_DONE ]]
               then
                  ssh $remote chmod -R a+wx $DIR_ARCHIVE1_remote/$caso
                  rsync -auv --remove-source-files $remote:$DIR_ARCHIVE1_remote/$caso $DIR_ARCHIVE1
                  touch $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE
                  chmod -R a-w $DIR_ARCHIVE1/$caso
                  exit
               fi
            fi
         fi
      done
   done
done
