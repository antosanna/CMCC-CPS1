#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
mkdir -p $DIR_LOG/hindcast/
LOG_FILE=$DIR_LOG/hindcast/launch_postproc_CERISE_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

st=05  #stdate as input

dbg=0 # dbg=1 -> just one member for test
mkdir -p $DIR_TEMP
flag_running=$DIR_TEMP/launch_postproc_CERISE_offline_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   exit
fi

nmaxsubmit=30
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_CERISE -c yes`
if [[ $nsubmit -eq $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch ${flag_running}
cd $DIR_ARCHIVE1/

listofcases=sps4_200205_023

for caso in $listofcases
do
    dir_cases=/work/cmcc/$USER/CPS/CMCC-CPS1/cases_for_CERISE

    casedir=${dir_cases}/$caso
    logdir=${dir_cases}/$caso/logs
    mkdir -p $casedir
    mkdir -p $logdir
    flagpostproc_done=$logdir/postproc_CERISE_${caso}_DONE    #not for dictionary to have a unique definition btw remote and local cases  

    flag_postproc_offline_on=$DIR_TEMP/CERISE_postproc_offline_${caso}
    if [[ -f ${flag_postproc_offline_on} ]]  
    then
         #postproc already submitted - continue
         continue
    else
         touch ${flag_postproc_offline_on}
    fi  

    mkdir -p $DIR_LOG/hindcast/CERISE_postproc
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 20000 -d ${DIR_C3S} -j postproc_CERISE_offline_${caso} -s postproc_CERISE_offline.sh -l $DIR_LOG/hindcast/CERISE_postproc -i "$caso ${dir_cases} $dbg"


    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 1000 -d ${DIR_C3S} -j c3s2cerise_${caso} -s c3s2cerise.sh -l $DIR_LOG/hindcast/CERISE_postproc -i "$caso"
    if [[ $dbg -eq 1 ]]
    then
          rm ${flag_running}
          exit
    fi
    nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_CERISE -c yes`
    if [[ $nsubmit -eq $nmaxsubmit ]]
    then
          rm ${flag_running}
          exit
    fi

done
rm ${flag_running}

exit 0
