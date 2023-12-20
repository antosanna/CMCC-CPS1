#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@fdtn-zeus
DIR_ARCHIVE1_remote=/work/csp/sps-dev/CMCC-CM/archive/
DIR_CASES_remote=/work/csp/sps-dev/CPS/CMCC-CPS1/cases
for st in 08 10 11
do
   n_rsync=0
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      lista_remote=`ssh $remote ls $DIR_CASES_remote`
      for caso in $lista_remote
      do
         is_caso_completed=`ssh $remote ls ${DIR_CASES_remote}/$caso/logs/run_moredays_${caso}_DONE| wc -l`
         if [[ $is_caso_completed -eq 1 ]]
         then
            if [[ ! -f $DIR_ARCHIVE1/$caso ]]
            then
#               ssh sps-dev@fdtn-zeus ls $DIR_ARCHIVE1_remote/$caso 
               rsync -auv $remote:$DIR_ARCHIVE1_remote/$caso $DIR_ARCHIVE1
               touch $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE
               rsync -auv $DIR_ARCHIVE1/$caso.transfer_from_Zeus_DONE $remote:$DIR_ARCHIVE1_remote/

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
