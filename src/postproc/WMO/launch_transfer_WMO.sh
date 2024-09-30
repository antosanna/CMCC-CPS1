#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

st=$1  
isforecast=0
dbg_push=2
typeofrun="hindcast"

input="${st} ${isforecast} ${dbg_push}"
mkdir -p ${DIR_LOG}/${typeofrun}/${st}
# NON MODIFICARE IL NOME DEL JOB!!! l'aggiunta di un _ prima di ${st}# crea problemi
${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_POST}/WMO -M 500 -q $serialq_l -n 1 -j launch_push4WMO${st} -l ${DIR_LOG}/${typeofrun} -s launch_push4WMO.sh -i "$input"
