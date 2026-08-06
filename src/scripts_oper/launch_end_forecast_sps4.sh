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

if [[ $machine == "cassandra" ]] || [[ $machine == "juno" ]]
then

   body="Buongiorno \n
\n
\n
    
       Con la presente Vi informiamo che le operazioni di calcolo relative alle SC_sps35 e SC_SERIAL_sps35 su $machine sono terminate e potete  spegnere le SCs
\n
\n

\n
\n



Grazie della preziosa collaborazione \n
\n


CMCC-SPS Staff

"

   title="CMCC-SPS reservation $st $yyyy - operazioni terminate" 
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -c $hsmmail -M "$body" -t "$title"
elif [[ $machine == "leonardo" ]]
then

   body="Buongiorno \n
\n
\n
    
       Con la presente Vi informiamo che il forecast e' andato a buon fine.
\n
\n

\n
\n



Grazie della preziosa collaborazione \n
\n


CMCC-SPS Staff

"

   echo -e $body|mailx -r "CMCC-SPS <scc-noreply@cmcc.it>" -s "CMCC-SPS4 forecast $st $yyyy - completato positivamente" -b a.bocchinfuso@cineca.it -b superc@cineca.it sp1@cmcc.it
fi
