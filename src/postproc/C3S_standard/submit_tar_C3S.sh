#!/bin/sh -l 
#yyyy=2026;st=02;typeofrun=forecast; ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -S $qos -j submit_tar_C3S${yyyy}$st -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_C3S} -s submit_tar_C3S.sh -i "${yyyy} $st"
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -evxu

yyyy=$1
st=$2
ext=${3:-0}

startdate=$yyyy$st
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
if [[ $ext -eq 1 ]]
then
   script=tar_C3Sext
   touch ${check_tar_ext_started}
   check_done=$check_tar_ext_done
   outdir=${WORK_C3SEXT}/$startdate   
else
   script=tar_C3S
   touch ${check_tar_started}
   check_done=$check_tar_done
   outdir=${WORK_C3S}/$startdate   
fi

yyyymmtoday=`date +%Y%m`
if [[ -f $check_done ]] 
then
   title="${CPSSYS} forecast warning"
   body="$DIR_C3S/$script.sh already done for this start-date. $check_done exists. If you want to redo first delete it"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit
fi

# ----------------------------------------------------------
cd ${outdir}

# here kill every process with start-date $startdate except this job
jobIDthisJOB=`${DIR_UTIL}/findjobs.sh -m $machine -N submit_tar_C3S$startdate -i yes`
jobIDall=`${DIR_UTIL}/findjobs.sh -m $machine -N $startdate  -i yes`
jobcopy=`${DIR_UTIL}/findjobs.sh -m $machine -N copy_SPS4Forecast -i yes`
set +e    #this is necessary because the job can be ended 
for jobID in $jobIDall
do
    if [[ $jobID -eq $jobIDthisJOB ]]
    then
       continue
    fi
    $DIR_UTIL/killjobs.sh -m $machine -i $jobID
done
#killing also copy of DMO from Leonardo, in order to avoid issues during renumbering
for jobID in $jobcopy
do
   $DIR_UTIL/killjobs.sh -m $machine -i $jobID
done

set -euvx

# submit notificate 5 - FINE POST-PROC
#input="`whoami` 0 $yyyy $st 1 5"
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S $qos -j notificate${startdate}_5th -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s notificate.sh -i "$input"
# 
listaens=`ls all_checkers_ok_0*|cut -d '_' -f4|cut -c 2,3`
$DIR_UTIL/check_production_time.sh -m $machine -s $st -y $yyyy -e $listaens
#
mkdir -p $pushdir
input="$yyyy $st"
$DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -S $qos -M 5000 -j ${script}_${startdate} -l $DIR_LOG/$typeofrun/$startdate/ -d ${DIR_C3S} -s $script.sh -i "$input"
sleep 60

exit 0
