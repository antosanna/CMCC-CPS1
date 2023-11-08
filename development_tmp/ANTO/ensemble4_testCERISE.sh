#!/bin/sh -l 
. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx
yyyy=1993
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
st=07
ens=5
here=$PWD
mkdir -p $DIR_LOG/$typeofrun/199307
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -j crea_${SPSSystem}_${yyyy}${st}_00$ens -l ${DIR_LOG}/$typeofrun/$yyyy$st -d $here -s create_caso_CERISE.sh -i "${yyyy} ${st} 1 1 1 $ens" 
