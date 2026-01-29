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
  
   ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -r $sla_serialID -S $qos -q $serialq_l -n 1 -j launch_push4ECMWF${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st} -s launch_push4ECMWF.sh -i "$input"
fi


body="Buongiorno \n
\n
\n
    
       Con la presente Vi informiamo che le operazioni di calcolo relative alla reservation su dcgp_cmcc_prod sono terminate e potete svincolare i relativi 165 nodi
\n
\n

\n
\n



Grazie della preziosa collaborazione \n
\n


CMCC-SPS Staff

"

echo -e $body|mailx -r "CMCC-SPS <scc-noreply@cmcc.it>" -s "CMCC-SPS reservation $st $yyyy - operazioni terminate" -b a.bocchinfuso@cineca.it -b superc@cineca.it sp1@cmcc.it
