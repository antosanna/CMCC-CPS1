#!/bin/sh -l
#BSUB -q s_long
#BSUB -n 1
#BSUB -o ../../logs/forecast/SPS3.5_forecast_out.%J
#BSUB -e ../../logs/forecast/SPS3.5_forecast_err.%J
#BSUB -o logs/SPS3.5_forecast_out.%J
#BSUB -e logs/SPS3.5_forecast_err.%J
#BSUB -J SPS3.5_forecast
#BSUB -P 0490
#BSUB -sla SC_sps35
#BSUB -app sps35

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -euvx


cp -p $DIR_TEMPL/descr_forecast.sh $DIR_SPS35/descr_forecast.sh
. $DIR_SPS35/descr_forecast.sh
if [[ $debug_push -ne 0 ]];then 
   body="YOU DID NOT LOAD THE CORRECT descr_forecast.sh. Check ${SPSSYS}_forecast.sh. Exiting now"
   echo $body
   title="${SPSSYS} forecast ERROR"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi

#-----------------------------------
#get start-date from system
#-----------------------------------

st=`date +%m`
m=$(( 10#$st )) #this must NOT be 2 figures
yyyy=`date +%Y`

message="${SPSSYS} forecast starting `date` "
dirrep=$yyyy$st
mkdir -p ${DIR_REP}/$dirrep
echo "${message}" >> ${DIR_REP}/$dirrep/report_${SPSsystem}_${yyyy}${st}
mkdir -p ${DIR_LOG}/forecast/$yyyy$st
checkfile=${DIR_LOG}/forecast/$yyyy$st/${SPSSYS}_forecast_${yyyy}${st}_started
if [[ -f $checkfile ]]
then
   body="${SPSSYS}_forecast.sh ALREADY SUBMITTED. Exiting now \n
   If you need to resubmit previously remove $checkfile"
   echo $body
   title="${SPSSYS} forecast ERROR"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 2
fi
touch $checkfile
#-----------------------------------
# IC production
#-----------------------------------
input="$yyyy $m"
${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d $IC_SPS35 -s run_IC_production.sh -i "$input"
#-----------------------------------
# triplette generation
#-----------------------------------
# wait 1 hour to allow parallel processes to complete
# ${SPSSYS} short forecast for IC CAM production takes ~ 45' max
echo "sleeping 1h from now "`date`
sleep 3600
it=1
while `true`
do
# now every 900"(15') check if you can generate triplette
# inside ${DIR_SPS35}/randomizer.sh another check: if it > 5 (meaning more than another hour passed)
#                                                  start sending warning for not enough IC
#                                                  to generate triplette_done.txt
   echo "sleeping 15' from now "`date`
   sleep 900
# if checkfileok exist enough IC to generate triplette_done.txt
   checkfileok=$DIR_LOG/$typeofrun/$yyyy$st/triplette$yyyy${st}_ready
   ${DIR_SPS35}/randomizer.sh $yyyy $st $it $checkfileok
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
$DIR_SPS35/${SPSSYS}_check_ICs.sh $st $yyyy
#-------------------------------------------
# when completed launch ensemble submission
#-------------------------------------------
input="$st $yyyy" 
${DIR_SPS35}/submitcommand.sh -m $machine -M 1500 -q $serialq_l -j ${SPSSYS}_submission_forecast -l ${DIR_LOG}/forecast/$yyyy$st -d ${DIR_SPS35} -s ${SPSSYS}_submission_forecast.sh -i "$input"

