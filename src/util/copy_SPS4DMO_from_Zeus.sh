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
DIR_ARCHIVE1_remote=/work/csp/sps-dev/CMCC-CM/archive/
DIR_CASES_remote=/work/csp/sps-dev/CPS/CMCC-CPS1/cases
for st in 08 10 11
do
   n_rsync=0
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      lista_remote=`ssh $remote ls -d $DIR_CASES_remote/${SPSSystem}_${yyyy}${st}_??? |rev|cut -d '/' -f1| rev`
      for caso in $lista_remote
      do
         is_caso_completed=`ssh $remote ls ${DIR_CASES_remote}/$caso/logs/run_moredays_${caso}_DONE| wc -l`
         if [[ $is_caso_completed -eq 1 ]]
         then
            if [[ ! -f $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE ]]
            then
               ssh $remote chmod -R a+x $DIR_ARCHIVE1_remote/$caso
               rsync -auv $remote:$DIR_ARCHIVE1_remote/$caso $DIR_ARCHIVE1
               rsync -auv --remove-source-files $remote:$DIR_ARCHIVE1_remote/$caso $DIR_ARCHIVE1
               touch $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE
               chmod -R a-w $DIR_ARCHIVE1/$caso
               n_rsync=$(($n_rsync + 1))
               if [[ $n_rsync -eq 5 ]]
               then
                  exit
               fi
            fi
         fi
      done
   done
done
