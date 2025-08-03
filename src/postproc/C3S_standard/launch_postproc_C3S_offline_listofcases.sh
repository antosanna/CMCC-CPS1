#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

dbg=0 # dbg=1 -> just one member for test
#listofcases="sps4_200005_001"
#listofcases="sps4_201008_005"
listofcases="sps4_200109_010 sps4_200109_011 sps4_200109_012 sps4_200109_013 sps4_200109_014 sps4_200109_015 sps4_200109_016 sps4_200109_017 sps4_200109_018 sps4_200109_019 sps4_200109_020 sps4_200109_021 sps4_200109_022 sps4_200109_023 sps4_200109_024 sps4_200109_025 sps4_200109_026 sps4_200109_027 sps4_200109_028 sps4_200109_029 sps4_200109_030"
nmaxsubmit=30     #up to 30 yet consistent with listofcases

flag_running=$DIR_TEMP/launch_postproc_C3S_offline_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   echo "launch_postproc_C3S_offline already running"
   echo ${flag_running}
   exit 1
fi

nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
if [[ $nsubmit -eq $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit 2
fi
touch ${flag_running}
cd $DIR_ARCHIVE/


for caso in $listofcases
do
   $DIR_C3S/clean4C3S_listofcases.sh $caso

   yyyy=`echo $caso | cut -d '_' -f2| cut -c1-4`
   isremote=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE |wc -l`
   if [[ ${isremote} -eq 1 ]] 
   then
        flag=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE`
        mach=`echo $flag |rev |cut -d '_' -f2|rev`
        echo "$caso is a remote case run on $mach"
        dir_cases=/work/cmcc/$USER/CPS/CMCC-CPS1/cases_from_${mach}
        mkdir -p ${dir_cases}
    elif [[ ${isremote} -gt 1 ]] 
    then
        title="${CPSSYS} warning launch_postproc_C3S_offline.sh"
        body="$caso transferred from more than one remote machines! Check it before proceeding with C3S postproc"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
        continue
    else
        dir_cases=${DIR_CASES}
    fi

    casedir=${dir_cases}/$caso
    logdir=${dir_cases}/$caso/logs
    mkdir -p $casedir
    mkdir -p $logdir
    flagpostproc_done=$logdir/postproc_C3S_${caso}_DONE    #not for dictionary to have a unique definition btw remote and local cases  

    flag_postproc_offline_on=$DIR_TEMP/C3S_postproc_offline_${caso}
    if [[ -f ${flag_postproc_offline_on} ]]  
    then
         #postproc already submitted - continue
         continue
    else
         touch ${flag_postproc_offline_on}
    fi  

    mkdir -p $DIR_LOG/hindcast/C3S_postproc
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 20000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $DIR_LOG/hindcast/C3S_postproc -i "$yyyy $caso ${dir_cases}"


    if [[ $dbg -eq 1 ]]
    then
          rm ${flag_running}
          exit
    fi
    nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
    if [[ $nsubmit -eq $nmaxsubmit ]]
    then
          rm ${flag_running}
          exit
    fi

done
rm ${flag_running}

exit 0
