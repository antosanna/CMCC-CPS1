#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere) run from crontab

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
#. ${DIR_UTIL}/descr_ensemble.sh $1
. ${DIR_UTIL}/descr_ensemble.sh `date +%Y`

set -euvx

st=`date +%m`   #$2  #stdate as input
yyyy=`date +%Y`  #$1
#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
#   LOG_FILE=$DIR_LOG/$typeofrun/launch_postproc_C3S_${typeofrun}_${machine}.`date +%Y%m%d%H%M`
#   exec 3>&1 1>>${LOG_FILE} 2>&1
mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/C3S_postproc

st=`date +%m`   #$2  #stdate as input
yyyy=`date +%Y`  #$1

dbg=0 # dbg=1 -> just one member for test
flag_running=$DIR_TEMP/launch_postproc_C3S_${typeofrun}_${yyyy}${st}_${machine}_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   exit
fi

nmaxsubmit=15 #30
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
listofcases=`ls -d ${SPSSystem}_${yyyy}${st}_0?? |head -n $nrunmax`

dir_cases=$DIR_CASES
for caso in $listofcases
do
      CASEROOT=${DIR_CASES}/$caso  #needed for dictionary
      set +euvx
      . $dictionary
      set -euvx
      flag_postproc_offline_on=${check_postproc_started_header}_${caso}
      if [[ -f ${flag_postproc_offline_on} ]]  
      then
           #postproc already submitted - continue
           continue
      fi
      $DIR_C3S/clean4C3S_listofcases.sh $caso
# this condition is mandatory since the postproc modifies outputs and restart dir
      isremote=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE |wc -l`
      if [[ ${isremote} -eq 1 ]]  && [[ ! -d $DIR_CASES/$caso ]]
      then
# if $caso has being run on remote machine $DIR_CASES/$caso does not exist and
# we build a $dir_cases for postproc
           flag=`ls $DIR_ARCHIVE/$caso.transfer_from_*_DONE`
           mach=`echo $flag |rev |cut -d '_' -f2|rev`
           echo "$caso is a remote case run on $mach"
           dir_cases=$ROOT_CASES_WORK/cases_from_${mach}
           mkdir -p ${dir_cases}
       else
# on producing machine
          if [[ ! -f ${check_run_moredays} ]] 
          then
               echo "$caso is still running, skipping the C3S postproc"
               continue
          fi 
       fi
       casedir=${dir_cases}/$caso
       logdir=${dir_cases}/$caso/logs
       mkdir -p $casedir
       mkdir -p $logdir
       flagpostproc_done=$logdir/postproc_C3S_${caso}_DONE    #not for dictionary to have a unique definition btw remote and local cases  
   
       #touch flag to avoid double resubmission
       touch ${flag_postproc_offline_on}
   
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 6000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $logdir -i "$yyyy $caso ${dir_cases} ${flagpostproc_done}"
   
   
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
rm ${flag_running}

exit 0
