#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx

caso=CASO
st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
logdir=${DIR_LOG}/$typeofrun/${yyyy}${st}
mkdir -p $logdir

${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 10000 -d ${DIR_C3S} -j recover_false_spike_onC3S_${caso} -s recover_false_spike_onC3S.sh -l $logdir -i "$caso"
