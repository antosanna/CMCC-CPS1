#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_download
#BSUB -R "rusage[mem=500M]"
#BSUB -J launch_aggiorna_web_verification
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/launch_aggiorna_web_verification_%J.out
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/launch_aggiorna_web_verification_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

st=${1}


cd $DIR_WEB/verification_dev
listamap=`ls -1 *_${st}_*.png`
for ll in $listamap ; do
    rsync -auv $DIR_WEB/verification_dev/$ll $DIR_WEB/verification_prod/
done

cd $DIR_WEB/verification-index_dev
listindex=`ls -1 *_${st}_*.png | grep -v REL`
for ll in $listindex
do
  rsync -auv $DIR_WEB/verification-index_dev/$ll $DIR_WEB/verification-index_prod/
done

cd $DIR_WEB/verification-diagram_dev
listdiag=`ls -1 *_${st}_*.png | grep -v REL`
for ll in $listdiag
do
  rsync -auv $DIR_WEB/verification-diagram_dev/$ll $DIR_WEB/verification-diagram_prod/
done

$DIR_UTIL/aggiorna_web.sh 

exit 0
