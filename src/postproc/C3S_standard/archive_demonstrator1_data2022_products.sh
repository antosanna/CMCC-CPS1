#!/bin/sh -l
#BSUB -q s_medium
#BSUB -J archive_dm1_2022
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm1_2022_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm1_2022_%J.out
#BSUB -P 0575
#BSUB -M 1000
#BSUB -q s_long


. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -eu

WORK_CERISE_phase1=/work/cmcc/cp2/CMCC-CM/archive/CERISE_phase1
ARCHIVE=/data/products/CERISE-DEMONSTRATOR-1/standardized
for st in 02 05 08 11
do
   for yyyy in 2022
   do
      mkdir -p $ARCHIVE/$yyyy$st
      cd $WORK_CERISE_phase1/$yyyy$st
      listaCERISE=`ls *nc`
      cd $WORK_C3S1/$yyyy$st
      for ffcomplete in $listaCERISE
      do
         ff=`basename $ffcomplete|cut -d '_' -f3-`
         if [[ `ls $WORK_C3S1/$yyyy$st/*${ff} |wc -l` -eq 0 ]]
         then
             rsync -auv $WORK_CERISE_phase1/$yyyy$st/$ffcomplete $ARCHIVE/$yyyy$st
         fi
      done
      touch $SCRATCHDIR/tmp_CERISE/demonstrator1_${yyyy}${st}_DONE
   done
done
