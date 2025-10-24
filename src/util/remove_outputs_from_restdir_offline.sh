#!/bin/sh -l
#BSUB -J remove_files
#BSUB -e /work/cmcc/cp1//scratch/remove_files%J.err
#BSUB -o /work/cmcc/cp1//scratch/remove_files%J.out
#BSUB -P 0490
#BSUB -M 1000
#BSUB -q s_long

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

#for st in {01..12}
# already run for 01 02 03 04 05 07 09 10
for st in 11 12
do
   for yyyy in {1993..2022}
   do
      for ens in {01..30}
      do
         caso=${SPSSystem}_${yyyy}${st}_0${ens}
         cd $DIR_ARCHIVE/
         if [[ ! -d $DIR_ARCHIVE/$caso ]]
         then
            continue
         fi 
         chmod -R u+wX $DIR_ARCHIVE/$caso
         cd $DIR_ARCHIVE/$caso/rest
         n_dirrest=`ls |grep 00000|wc -l`
         if [[ $n_dirrest -eq 0 ]]
         then
            continue
         fi 
         if [[ $n_dirrest -gt 1 ]]
         then
            echo "$caso must be treated separately" >>/work/cmcc/cp1//scratch/special_cases_multiple_restdir.txt
            continue
         fi 
         dirrest=`ls |grep 00000`
         cd $DIR_ARCHIVE/$caso/rest/$dirrest
         if [[ `ls *.h?.* |wc -l` -ne 0 ]]
         then 
            list2rm=`ls *.h?.*`
            rm $list2rm
         fi
         chmod -R u-w $DIR_ARCHIVE/$caso
      done
   done
done
