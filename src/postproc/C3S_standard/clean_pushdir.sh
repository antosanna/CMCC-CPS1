#!/bin/sh -l
#--------------------------------

# load variables from descriptor
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -evx

yyyy=$1
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -evxu
st=$2
startdate=$yyyy$st

cd $pushdir

# THIS IS TO CLEAN PUSH DIRECTORY
if [[ `ls $pushdir/${startdate}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100_* |wc -l` -ne 0 ]]; then
  	rm $pushdir/${startdate}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100_*

   body="C3S: deletion completed from $pushdir/${startdate}"
   title="[C3S] ${CPSSYS} $typeofrun notification"
${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
fi

echo "$0 successfully completed"

