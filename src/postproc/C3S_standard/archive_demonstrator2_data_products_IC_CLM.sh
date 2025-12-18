#!/bin/sh -l
#BSUB -q s_long
#BSUB -J archive_dm2_ICs
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm2_ICs_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/hindcast/archive_dm2_ICs_%J.out
#BSUB -P 0575
#BSUB -M 1000


. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

finaldir=/data/products/CERISE-DEMONSTRATOR-2/IC_CLM
inpdir=$IC_CLM_CPS_DIR
wkdir=$SCRATCHDIR/ANTO/CERISE/archive_IC_CLM
mkdir -p $wkdir
for st in 02 05 08 11
do
    cd $inpdir/$st
    if [[ ! -f $wkdir/$st.archive.DONE ]]
    then
       gzip -f CPS1.clm2.r*nc 
       gzip -f CPS1.hydros.r*nc 
       listaf=`ls *.gz`
       rsync -auv $listaf $finaldir/$st/
       touch $wkdir/$st.archive.DONE
#       rsync -auv --remove-source-files $listaf $finaldir/$st/
    fi
done
