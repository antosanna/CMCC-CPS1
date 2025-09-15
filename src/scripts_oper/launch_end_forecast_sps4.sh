#!/bin/sh -l
#--------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh  2025  #always forecast mode
set -euvx

yyyy=`date +%Y`
st=`date +%m`

set +euxv
. $dictionary
set -euvx

if [[ -f $check_tar_done ]]
then
   input="${st} 1"
   mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
  
   ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -r $sla_serialID -S qos_resv -q $serialq_l -n 1 -j launch_push4ECMWF${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st} -s launch_push4ECMWF.sh -i "$input"
fi
