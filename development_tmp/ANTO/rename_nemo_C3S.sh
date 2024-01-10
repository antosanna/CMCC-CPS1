#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

. ${DIR_UTIL}/descr_ensemble.sh 1993
set -eu

cd $WORK_C3S
for yyyy in {1993..2022}
do
   for st in {01..12}
   do
      if [[ ! -d $yyyy$st ]]
      then
         continue
      fi
      cd $WORK_C3S/$yyyy$st
      listafiles=`ls cmcc_CMCC-CM3_v20231101*`
      for ff in $listafiles
      do
         newff=$(echo "${ff/CMCC-CM3_v20231101/CMCC-CM3-v20231101}")
         mv $ff $newff
      done
   done
done
exit 0
