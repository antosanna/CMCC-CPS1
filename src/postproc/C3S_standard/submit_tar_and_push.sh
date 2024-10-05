#!/bin/sh -l 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

yyyy=$1
st=$2
# this script should work only in operational mode
set +uevx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv
if [[ -f ${DIR_LOG}/${typeofrun}/${yyyy}${st}/submit_tar_and_push_${yyyy}${st}_started ]] ; then
   echo "submit_tar_and_push.sh ALREADY SUBMITTED!"
   exit
fi
touch ${DIR_LOG}/${typeofrun}/${yyyy}${st}/submit_tar_and_push_${yyyy}${st}_started

yyyymmtoday=`date +%Y%m`
if [ -f $WORK_C3S/$yyyy$st/tar_and_push_${yyyy}${st}_DONE ] 
then
   title="${CPSSYS} forecast warning"
   body="$DIR_C3S/tar_and_push.sh already done for this start-date. $WORK_C3S/$yyyy$st/tar_and_push_${yyyy}${st}_DONE exists. If you want to redo first delete it"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit
fi

# ----------------------------------------------------------
startdate=$yyyy$st
cd ${WORK_C3S}/$startdate   

# here kill every process with start-date $startdate except this job
jobIDthisJOB=`${DIR_UTIL}/findjobs.sh -m $machine -N submit_tar_and_push$startdate -i yes`
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
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -j notificate${startdate}_5th -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s notificate.sh -i "$input"
# 
cd $WORK_C3S/$yyyy$st
listaens=`ls all_checkers_ok_0*|cut -d '_' -f4|cut -c 2,3`
$DIR_UTIL/check_production_time.sh -m $machine -s $st -y $yyyy -e $listaens
# 
input="$yyyy $st"
$DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -S qos_resv -M 5000 -j tar_and_push_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s tar_and_push.sh -i "$input"
sleep 60

exit 0
