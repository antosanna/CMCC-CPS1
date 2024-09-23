#!/bin/sh -l
#--------------------------------
## No need for bsub header, we launch it from crontab, with submitcommand.sh
#BSUB -P 0490
#BSUB -q s_long
#BSUB -o ../../../logs/forecast/launch_push4APEC.%J.out
#BSUB -e ../../../logs/forecast/launch_push4APEC.%J.err
#BSUB -J launch_push4APEC

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_SPS35}/descr_forecast.sh
. ${DIR_POST}/APEC/descr_SPS35_APEC.sh

set -euvx

here=$DIR_POST/APEC

type_fore=$typeofrun
yyyy=`date +%Y`
st=`date +%m`
debug=0

body="APEC: Inizia il trasferimento su ftp"
title="[APEC] ${SPSSYS} ${type_fore} notification"
${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail


# Submit push over APEC ftp	
input="${yyyy} ${st} ${type_fore} ${debug}"
${DIR_SPS35}/submitcommand.sh -M 1000 -m $machine -d ${here} -q $serialq_l -n 1 -j push4APEC_${yyyy}${st} -l ${DIR_LOG}/${type_fore}/${yyyy}${st}/ -s push4APEC.sh -i "$input"

while `true` ; do
	   sleep 5
	   njobs=`${DIR_SPS35}/findjobs.sh -m $machine -q $serialq_l -n "push4APEC_${yyyy}${st}"  -c yes`

	   if [ ${njobs} -eq 0 ]; then
     		break
	   fi  
done

sleep 1

exit 0
