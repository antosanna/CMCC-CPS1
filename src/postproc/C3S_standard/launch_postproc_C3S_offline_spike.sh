#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1


dbg=0 # dbg=1 -> just one member for test
flag_running=$DIR_TEMP/launch_postproc_C3S_offline_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   exit
fi

nmaxsubmit=30
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
if [[ $nsubmit -eq $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch ${flag_running}
cd $DIR_ARCHIVE/

# to be modified with the list of spiked cases

listofcases="sps4_199311_012 sps4_199311_029 sps4_199511_004 sps4_199511_025 sps4_199611_002 sps4_199611_017 sps4_199611_018 sps4_199611_024 sps4_199711_014 sps4_199811_007 sps4_199811_009 sps4_199811_010 sps4_199911_023 sps4_200011_005 sps4_200111_012 sps4_200211_002 sps4_200211_027 sps4_200311_010 sps4_200311_014 sps4_200311_017 sps4_200511_025 sps4_200511_027 sps4_200611_024 sps4_200611_026 sps4_200711_005 sps4_200711_009 sps4_200811_009 sps4_201011_018 sps4_201111_015 sps4_201211_008 sps4_201211_026 sps4_201211_028 sps4_201411_020 sps4_201411_029 sps4_201411_030 sps4_201511_026 sps4_201611_001 sps4_201611_029 sps4_201711_023 sps4_201711_026 sps4_201711_027 sps4_201711_028 sps4_201811_014 sps4_201811_015 sps4_201811_016 sps4_201911_004 sps4_201911_010 sps4_202011_006 sps4_202111_003 sps4_202111_018 sps4_202111_024 sps4_202111_028 sps4_202111_030 sps4_202211_017 sps4_202211_023 sps4_202211_029 sps4_199711_008 sps4_199911_027 sps4_202211_028" 

for caso in $listofcases
do
   isspike=${DIR_TEMP}/${caso}.redone4spike
   if [[ ! -f $isspike ]] 
   then
      echo "$caso not copied yet from Leonardo"
      continue
   fi
   iscleaned=${DIR_TEMP}/clean4C3S_spike_${caso}_DONE
   if [[ ! -f $iscleaned ]] 
   then
    title="${CPSSYS} warning launch_postproc_C3S_offline_spike.sh"
    body="$caso rerun for spike copied from Leonardo to Juno, but old C3S files not cleaned yet. Use $DIR_C3S/clean4C3S_spikes.sh"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
    continue
   fi
   isremote=`ls $DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE |wc -l`
   if [[ ${isremote} -eq 1 ]] 
   then
        flag=`ls $DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE`
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
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 20000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $DIR_LOG/hindcast/C3S_postproc -i "$caso ${dir_cases}"


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
