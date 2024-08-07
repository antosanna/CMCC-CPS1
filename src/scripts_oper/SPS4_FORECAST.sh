#!/bin/sh -l
#BSUB -q s_long
#BSUB -n 1
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_FORECAST_out.%J
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_FORECAST_err.%J
#BSUB -J SPS4_FORECAST
#BSUB -P 0490
#BSUB -sla SC_c3s2

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx


. $DIR_UTIL/descr_ensemble.sh 2020
if [[ $debug_push -ne 0 ]];then 
#   body="YOU DID NOT LOAD THE CORRECT descr_forecast.sh. Check ${CPSSYS}_forecast.sh. Exiting now"
#   echo $body
#   title="${CPSSYS} forecast ERROR"
#   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
#   exit 1
    :
fi

#-----------------------------------
#get start-date from system
#-----------------------------------

st=`date +%m`
m=$(( 10#$st )) #this must NOT be 2 figures
yyyy=`date +%Y`

message="${CPSSYS} forecast starting `date` "
dirrep=$yyyy$st
mkdir -p ${DIR_REP}/$dirrep
echo "${message}" >> ${DIR_REP}/$dirrep/report_${SPSSystem}_${yyyy}${st}
mkdir -p ${DIR_LOG}/forecast/$yyyy$st
checkfile=${DIR_LOG}/forecast/$yyyy$st/${SPSSystem}_forecast_${yyyy}${st}_started
if [[ -f $checkfile ]]
then
   body="SPS4_FORECAST.sh ALREADY SUBMITTED. Exiting now \n
   If you need to resubmit previously remove $checkfile"
   echo $body
   title="${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 2
fi
touch $checkfile
#-----------------------------------
# IC production
#-----------------------------------
input="$yyyy $m"
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d $IC_CPS -s run_IC_production.sh -i "$input"
#-----------------------------------
# triplette generation
#-----------------------------------
# wait 1 hour to allow parallel processes to complete
# ${CPSSYS} short forecast for IC CAM production takes ~ 45' max
echo "sleeping 1h from now "`date`
sleep 3600
it=1
while `true`
do
# now every 900"(15') check if you can generate triplette
# inside ${IC_CPS}/randomizer.sh another check: if it > 5 (meaning more than another hour passed)
#                                                  start sending warning for not enough IC
#                                                  to generate triplette_done.txt
   echo "sleeping 15' from now "`date`
   sleep 900
# if checkfileok exist enough IC to generate triplette_done.txt
   checkfileok=$DIR_LOG/$typeofrun/$yyyy$st/triplette$yyyy${st}_ready
   ${IC_CPS}/randomizer.sh $yyyy $st $it $checkfileok
   if [ -f $checkfileok ]
   then
      echo " IC are enough to generate triplette_done"
      break
   fi
   it=$(($it + 1))
done
#-------------------------------------------
# check ICs and send plots by mail
#-------------------------------------------
$DIR_UTIL/${CPSSYS}_check_ICs.sh $st $yyyy
#-------------------------------------------
# when completed launch ensemble submission
#-------------------------------------------
input="$st $yyyy" 
${DIR_UTIL}/submitcommand.sh -m $machine -M 1500 -q $serialq_l -j ${SPSSystem}_submission_forecast -l ${DIR_LOG}/forecast/$yyyy$st -d ${DIR_CPS} -s ${SPSSystem}_submission_forecast.sh -i "$input"

