#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh $iniy_hind

set -euvx

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

st=$1  #stdate as input

dbg=0 # dbg=1 -> just one member for test
flag_running=$DIR_TEMP/launch_postproc_C3S_offline_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   exit
fi

nmaxsubmit=30
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
if [[ $nsubmit -ge $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch ${flag_running}
cd $DIR_ARCHIVE/

# to be modified with the list of spiked cases
#for yyyy in `seq $iniy_hind $endy_hind`
for yyyy in `seq $iniy_hind $endy_hind`
do
   listofcases=`ls -d sps4_${yyyy}${st}_0?? |head -n $nrunC3Sfore`

   for caso in $listofcases
   do
      flag_postproc_offline_on=$DIR_TEMP/C3S_postproc_offline_${caso}
      if [[ -f ${flag_postproc_offline_on} ]]  
      then
           #postproc already submitted - continue
           continue
      fi
      $DIR_C3S/clean4C3S_listofcases.sh $caso
      isremote=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE |wc -l`
      if [[ ${isremote} -eq 1 ]] 
      then
           flag=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE`
           mach=`echo $flag |rev |cut -d '_' -f2|rev`
           echo "$caso is a remote case run on $mach"
           dir_cases=$ROOT_CASES_WORK/cases_from_${mach}
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
   
       #touch flag to avoid double resubmission
       touch ${flag_postproc_offline_on}
   
       mkdir -p $DIR_LOG/hindcast/C3S_postproc
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 18000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $DIR_LOG/hindcast/C3S_postproc -i "${yyyy} $caso ${dir_cases}"
   
   
       if [[ $dbg -eq 1 ]]
       then
             rm ${flag_running}
             exit
       fi
       nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
       if [[ $nsubmit -ge $nmaxsubmit ]]
       then
             rm ${flag_running}
             exit
       fi
   
   done
done
rm ${flag_running}

exit 0
