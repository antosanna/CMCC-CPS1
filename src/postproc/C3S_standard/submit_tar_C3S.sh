#!/bin/sh -l 
#yyyy=2025;st=05;typeofrun=forecast; ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -S $qos -j submit_tar_C3S${yyyy}$st -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_C3S} -s submit_tar_C3S.sh -i "${yyyy} $st"
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

yyyy=$1
st=$2
# this script should work only in operational mode
set +uevx
. $DIR_UTIL/descr_ensemble.sh $yyyy
. $dictionary
set -uexv
if [[ -f ${check_tar_started} ]] ; then
   title="${CPSSYS} forecast warning"
   body="submit_tar_C3S.sh ALREADY RUNNING!"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit
fi
touch ${check_tar_started}

yyyymmtoday=`date +%Y%m`
if [[ -f $check_tar_done ]] 
then
   title="${CPSSYS} forecast warning"
   body="$DIR_C3S/tar_C3S.sh already done for this start-date. $check_tar_done exists. If you want to redo first delete it"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit
fi

# ----------------------------------------------------------
startdate=$yyyy$st
cd ${WORK_C3S}/$startdate   

# here kill every process with start-date $startdate except this job
jobIDthisJOB=`${DIR_UTIL}/findjobs.sh -m $machine -N submit_tar_C3S$startdate -i yes`
jobIDall=`${DIR_UTIL}/findjobs.sh -m $machine -N $startdate  -i yes`
set +e    #this is necessary because the job can be ended 
for jobID in $jobIDall
do
    if [[ $jobID -eq $jobIDthisJOB ]]
    then
       continue
    fi
    $DIR_UTIL/killjobs.sh -m $machine -i $jobID
done
set -euvx

#TEMPORARY COMMENTED
# submit notificate 5 - FINE POST-PROC
#input="`whoami` 0 $yyyy $st 1 5"
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S $qos -j notificate${startdate}_5th -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s notificate.sh -i "$input"
# 
cd $WORK_C3S/$yyyy$st
listaens=`ls all_checkers_ok_0*|cut -d '_' -f4|cut -c 2,3`
$DIR_UTIL/check_production_time.sh -m $machine -s $st -y $yyyy -e $listaens
# 
input="$yyyy $st"
$DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -S $qos -M 5000 -j tar_C3S_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s tar_C3S.sh -i "$input"
sleep 60

exit 0
