#!/bin/sh -l
#BSUB -q s_long
#BSUB -n 1
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_step1_out.%J
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/SPS4_step1_err.%J
#BSUB -J SPS4_step1
#BSUB -P 0490
#BSUB -sla SC_c3s2

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

if [[ $machine != "juno" ]]
then
   message="this script is meant to be run on Juno!!!"
   body=$message
   title="[$CPSSYS] ERROR: SPS4_step1_ICs.sh exited"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -t "$title" -M "$body" -r "yes" -s ${yyyy}${st}
   echo "exit now"
   exit 1
fi

st=`date +%m`
m=$(( 10#$st )) #this must NOT be 2 figures
yyyy=`date +%Y`
if [[ ! -f /work/cmcc/cp1/CPS/CMCC-OIS2/logs/WEEKLY_SUBMISSION/weekly_ois2_submit_${yyyy}${st}01.submitted ]]
then
   body="OIS2 forecast not submitted: $SPSSystem IC production cannot start"
   title="[$CPSSYS] ERROR: SPS4_step1_ICs.sh exited"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -t "$title" -M "$body" -r "yes" -s ${yyyy}${st}
   exit 1
fi
   
while `true`
do
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n OPSLAMB -c yes` 
   if [[ $np -eq 0 ]]
   then
      break
   fi
   sleep 100
done
#-----------------------------------
#get start-date from system
#-----------------------------------

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

message="${CPSSYS} forecast starting `date` "
dirrep=$yyyy$st
mkdir -p ${DIR_REP}/$dirrep
body=`echo "${message}"` 
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -r "only" -s ${yyyy}${st}
mkdir -p ${DIR_LOG}/forecast/$yyyy$st/ICs
checkfile=${DIR_LOG}/forecast/$yyyy$st/ICs/${SPSSystem}_step1_ICs_${yyyy}${st}_started
if [[ -f $checkfile ]]
then
   body="SPS4_step1_ICs.sh ALREADY SUBMITTED. Exiting now \n
   If you need to resubmit previously remove $checkfile"
   echo $body
   title="${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
   exit 2
fi
touch $checkfile
#-----------------------------------
# IC production
#-----------------------------------
input="$yyyy $m"
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d $IC_CPS -s run_IC_production.sh -i "$input"
while `true`
do
   sleep 100
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n run_IC_production -c yes` 
   if [[ $np -eq 0 ]]
   then
      break
   fi
done
#-------------------------------------------
# check ICs and send plots by mail
#-------------------------------------------
$DIR_UTIL/${CPSSYS}_check_ICs.sh $yyyy $st
#-----------------------------------
# triplette generation
#-----------------------------------
#checkfile_trip=$DIR_LOG/$typeofrun/$yyyy$st/triplette$yyyy${st}_ready
${IC_CPS}/make_triplette.sh $yyyy $st
${IC_CPS}/copy_ICs_and_triplette_to_Leonardo.sh $yyyy $st
body="Cari tutti, \n
vi confermiamo il completamento della procedura di creazione ICs per il seasonal Forecast. Potete ripristinare la configurazione standard dei nodi paralleli. \n
\n
Grazie
\n
SPS-staff\n"
title="FINE RICHIESTA SPECIALE PER SC_sps35"
${DIR_UTIL}/sendmail.sh -m $machine -e $hsmmail -t "$title" -M "$body" -r "yes" -s ${yyyy}${st} -c $mymail
