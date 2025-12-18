#!/bin/sh -l
#BSUB -q s_long
#BSUB -J copy_outputs_to_data
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/copy_outputs_to_data_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/copy_outputs_to_data_%J.out
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
      if [[ ! -f $$pushdir/$yyyy$st/tar_CERISE_phase2_${yyyy}${st}_DONE ]]
      then
         if [[ -f ${check_tar_done} ]]
         then
            rsync -auv $pushdir/$yyyy$st /data/cmcc/cp1/temporary/CERISE_phase2/pushdir
            touch tar_CERISE_phase2_${yyyy}${st}_DONE $pushdir/$yyyy$st/
         fi
      fi
   done
done
