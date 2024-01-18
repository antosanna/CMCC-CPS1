#!/bin/sh -l
#BSUB -J rm_Nemo_ptr_07
#BSUB -e /work/csp/cp1/scratch/ANTO/tmp/rm_Nemo_ptr_07_%J.err
#BSUB -o /work/csp/cp1/scratch/ANTO/tmp/rm_Nemo_ptr_07_%J.out
#BSUB -P 0490
#BSUB -M 1000
#BSUB -q s_medium

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx


for st in 07 
do
   listcasi=`ls $DIR_ARCHIVE|grep ${SPSSystem}|grep ${st}_0`
   for caso in $listcasi
   do
      if [[ ! -f $DIR_CASES/$caso/logs/${caso}_${nmonfore}months_done ]]
      then
         rm $DIR_ARCHIVE/$caso/ocn/hist/*ptr*
      fi
   done
done
