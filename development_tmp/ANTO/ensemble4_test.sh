#!/bin/sh -l 
. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh
set -euvx
yyyy=1993
st=07
mkdir -p $DIR_LOG/$typeofrun/199307
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -j crea_${CPSSystem}_${yyyy}${st}_001 -l ${DIR_LOG}/$typeofrun/$yyyy$st -d $DIR_CPS -s create_caso.sh -i "${yyyy} ${st} 1 1 1 1" 
