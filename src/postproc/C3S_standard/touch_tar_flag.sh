#!/bin/sh -l
#BSUB -q s_short
#BSUB -J touch_flag
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/touch_flag%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/touch_flag%J.out
#BSUB -P 0575
#BSUB -M 1000


. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

for st in 02 05 08 11
do
   for yyyy in {2002..2021}
   do
set +euvx
      . $dictionary
set -euvx
      if [[ ! -d $pushdir/$yyyy$st ]]
      then
         continue
      fi
      touch $pushdir/tar_CERISE_phase2_${yyyy}${st}_DONE ]]
   done
done
