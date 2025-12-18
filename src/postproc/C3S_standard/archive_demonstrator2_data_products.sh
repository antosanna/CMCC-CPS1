#!/bin/sh -l
#BSUB -q s_short
#BSUB -J archive_dm2
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm2_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm2_%J.out
#BSUB -P 0575
#BSUB -M 1000
#BSUB -q s_long


. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

wkdir=$SCRATCHDIR/ANTO/CERISE_mrlsl
mkdir -p $wkdir
for st in 02 05 08 11
do
   for yyyy in {2002..2021}
   do
      mkdir -p /data/products/CERISE-DEMONSTRATOR-2/standardized/$yyyy$st
      cd $WORK_CERISE_final/$yyyy$st
      for var in tslsl mrlsl tsn
      do
         if [[ ! -f $wkdir/$yyyy$st.${var}.DONE ]]
         then
            listaf=`ls *${var}*.nc`
            for infile in $listaf
            do
               if [[ -f $wkdir/tmp.${var}.nc ]]
               then
                  rm $wkdir/tmp.${var}.nc 
               fi
               if [[ -f $wkdir/tmp2.${var}.nc ]]
               then
                  rm $wkdir/tmp2.${var}.nc
               fi
               ncatted -a units,time,o,c,"days since $yyyy-$st-01T00:00:00Z" $infile $wkdir/tmp.${var}.nc
               ncatted -a units,leadtime,o,c,"days since $yyyy-$st-01T00:00:00Z" $wkdir/tmp.${var}.nc $wkdir/tmp2.${var}.nc
               ncatted -a units,reftime,o,c,"days since $yyyy-$st-01T00:00:00Z" $wkdir/tmp2.${var}.nc $wkdir/$infile
               mv $wkdir/$infile $infile
               rm $wkdir/tmp.${var}.nc $wkdir/tmp2.${var}.nc
            done
            touch $wkdir/$yyyy$st.${var}.DONE
         fi
      done
      
      rsync -auv $WORK_CERISE_final/$yyyy$st/*nc /data/products/CERISE-DEMONSTRATOR-2/standardized/$yyyy$st/
      touch $wkdir/$yyyy$st.archive.DONE
#      rsync -auv --remove-source-files $WORK_CERISE_final/$yyyy$st/*nc /data/products/CERISE-DEMONSTRATOR-2/standardized/$yyyy$st/
   done
done
