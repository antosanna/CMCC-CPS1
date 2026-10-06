#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh `date +%Y`

set -euvx

# standard forecast every month inputs: 0
# extended forecast every November inputs: 1
# extended hindcast inputs: 1 1993

ext=$1

st=`date +%m`  #stdate as input
list_of_years=`date +%Y`
if [[ $# -gt 1 ]]
then
   if [[ $2 -eq 1993 ]]
   then
      list_of_years=`seq 1993 2024`
set +uevx
      . ${DIR_UTIL}/descr_ensemble.sh 1993
set -uevx
   else
     echo "wrong input for input 2! MUST BE 1993"
     exit 1
   fi
fi

if [[ $ext -eq 1 ]]
then
  nrunC3Sfore=$nrunhindext
  typeofrun=forecast_ext
  if [[ $# -gt 1 ]]
  then
     typeofrun=hindcast_ext
     st=11       #since it can be submitted any months
  fi
fi
LOG_FILE=$DIR_LOG/${typeofrun}/launch_postproc_C3S_offline_${typeofrun}_${machine}.`date +%Y%m%d%H%M`
mkdir -p $DIR_LOG/${typeofrun}
exec 3>&1 1>>${LOG_FILE} 2>&1

header=$SPSSystem
if [[ $ext -eq 1 ]]
then
   header=${header}ext
fi

# This to avoid any postproc submit during execution of tar_C3S.sh
if [[ $ext -eq 1 ]]
then
   flag_tarC3S="$DIR_LOG/$typeofrun/$yyyy$st/submit_tar_C3SEXT_${yyyy}${st}_started"
else
   flag_tarC3S="$DIR_LOG/$typeofrun/$yyyy$st/submit_tar_C3S_${yyyy}${st}_started"
fi
if [[ -f $flag_tarC3S ]]
then
   echo "tar_C3S.sh already started!"
   exit 0
fi

recover=0
if [[ $# -gt 1 ]]
then
   recover=$2 #default recover=0 (do not relaunch cases with missing all_checkers_ok)
fi

dbg=0 # dbg=1 -> just one member for test
flag_running=$DIR_LOG/$typeofrun/$yyyy$st/launch_postproc_C3S_offline_${typeofrun}_${yyyy}${st}_${machine}_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   echo "${DIR_C3S}/launch_postproc_C3S_forecast.sh already running"
   exit 0
fi

nmaxsubmit=15
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
if [[ $nsubmit -ge $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch ${flag_running}

if [[ ${recover} -eq 0 ]] ; then
   cnt_subm=`ls ${check_postproc_started_header}_${header}_????${st}_0?? |wc -l`
   nmbhindyr=$((${endy_hind} - ${iniy_hind} +1))
   ntot=$((${nrunhind}*${nmbhindyr})) #30members x 30 years
   if [[ ${cnt_subm} -eq ${ntot} ]] ; then
       cnt_all_ok=`ls ${WORK_C3S}/????${st}/all_checkers_ok_0?? |wc -l`
       if [[ ${cnt_all_ok} -eq ${cnt_subm} ]] ;then
           echo "C3S postproc completed for startdate ${st}. Exitinig now." 
           rm ${flag_running}
           exit 0
       else
           title="${CPSSYS} warning launch_postproc_C3S_offline.sh - startdate ${st}"
           body="All cases have been submitted for C3S standardization of startdate ${st}, but not all completed.\n Check and relaunch possible manual interventions, otherwise relaunch from crontab changing the input flag (0 no-recover, 1 recover) ${DIR_C3S}/launch_postproc_C3S_offline.sh ${st} 1"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
           rm ${flag_running}
           exit 1
       fi
   fi
fi

cd $DIR_ARCHIVE/

# to be modified with the list of spiked cases
#for yyyy in `seq $iniy_hind $endy_hind`
for yyyy in $list_of_years
do
   listofcases=`ls -d ${header}_${yyyy}${st}_0?? |head -n $nrunC3Sfore`

   for caso in $listofcases
   do
      CASEROOT=${DIR_CASES}/$caso  #needed for dictionary
set +euvx
      . $dictionary
set -euvx
      flag_postproc_offline_on=${check_postproc_started_header}_${caso}
      if [[ -f ${flag_postproc_offline_on} ]] 
      then
         if [[ ${recover} -eq 1 ]] ; then
             ens=`echo $caso|rev|cut -d "_" -f1|rev`
             tag=`echo $caso |cut -d "_" -f2-`
             nrunning=`$DIR_UTIL/findjobs.sh -m $machine -n $tag -c yes`
             if [[ $nrunning -eq 0 ]] && [[ ! -f $WORK_C3S/${yyyy}$st/all_checkers_ok_${ens} ]]
             then
                rm ${flag_postproc_offline_on}
             else
                #postproc already submitted - continue
                continue
             fi
         else
             continue
         fi
      fi
#BEFORE RUNNING THIS SCRIPT FOR A NEW $caso CLEAN OLD FILES WITH $DIR_C3S/clean4C3S_listofcases.sh
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
       else #producing machine
           if [[ ! -f ${DIR_CASES}/$caso/logs/run_moredays_${caso}_DONE ]]
           then
              echo "$caso not correctly completed on $machine, skipping postprocessing" 
              continue
           fi
           dir_cases=${DIR_CASES}
       fi
   
       casedir=${dir_cases}/$caso
       logdir=${dir_cases}/$caso/logs
       mkdir -p $casedir
       mkdir -p $logdir
#       flagpostproc_done=$logdir/postproc_C3S_${caso}_DONE    #not for dictionary to have a unique definition btw remote and local cases  
   
       #touch flag to avoid double resubmission
       touch ${flag_postproc_offline_on}
   
       mkdir -p $DIR_LOG/${typeofrun}/$yyyy$st/C3S_postproc
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 18000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $DIR_LOG/${typeofrun}/$yyyy$st/C3S_postproc -i "${yyyy} $caso ${dir_cases}" # $flagpostproc_done"
   
   
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
