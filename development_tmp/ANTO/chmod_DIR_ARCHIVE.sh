#!/bin/sh -l
#BSUB -J chmod_DIR_ARCHIVE
#BSUB -e /work/csp/cp1/scratch/ANTO/tmp/chmod_DIR_ARCHIVE%J.err
#BSUB -o /work/csp/cp1/scratch/ANTO/tmp/chmod_DIR_ARCHIVE%J.out
#BSUB -P 0490
#BSUB -M 1000
#BSUB -q s_medium

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx


for st in 05 08 10 11 07
do
   listcasi=`ls $DIR_ARCHIVE|grep ${SPSSystem}|grep ${st}_0`
   for caso in $listcasi
   do
      if [[ -f $DIR_CASES/$caso/logs/run_moredays_${caso}_DONE ]] || [[ -f $DIR_ARCHIVE/$caso.transfer_from_Zeus_DONE ]]
      then
         chmod u-w -R $DIR_ARCHIVE/$caso
      fi
   done
done

