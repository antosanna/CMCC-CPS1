#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


set +euvx
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -e

cd $DIR_CASES
st=07
for yyyy in {1993..2022}
do
   ndir=`ls |grep ${yyyy}${st}_|wc -l`
   startdate=$yyyy$st
   if [[ $ndir -eq 0 ]]
   then
      continue
   fi
   listadir=`ls |grep ${yyyy}${st}_`

   for caso in $listadir
   do
      . $dictionary 
      if [[ `ls $DIR_CASES/$caso/logs/postproc_monthly_*|wc -l` -eq $nmonfore ]]
      then
#---------------------------------------
         if [[ ! -f $check_6months_done ]]
         then
            touch $check_6months_done
         else
            echo $check_6months_done "THERE"
         fi
      fi
   done
done
exit 0
