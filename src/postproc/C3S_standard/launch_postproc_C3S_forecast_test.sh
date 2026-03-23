#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 2026 #$1
. $dictionary

set -euvx


dbg=0 # dbg=1 -> just one member for test

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
stdate=202602 #`date +%Y%m`
mkdir -p $DIR_LOG/${typeofrun}/$stdate/
LOG_FILE=$DIR_LOG/$typeofrun/$stdate/launch_postproc_C3S_${typeofrun}.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

yyyy=2026 #`date +%Y`
st=02 #`date +%m`
check_completed=$DIR_LOG/forecast/$stdate/FORECAST_COMPLETED

flag_running=$DIR_TEMP/launch_postproc_C3S_${typeofrun}_${yyyy}${st}_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   echo "${DIR_C3S}/launch_postproc_C3S_forecast.sh already running"
   exit 0
fi

if [[ ! -f $check_completed ]]
then
   n_completed=0
   for ens in {001..054}
   do
      caso=sps4_${stdate}_${ens}
      if [[ -f $DIR_CASES/$caso/logs/run_moredays_sps4_${stdate}_${ens}_DONE ]]
      then
         n_completed=$(($n_completed + 1))
      fi
      if [[ $n_completed -ge 50 ]]
      then
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "First submission of postprocessing for C3S starting..." -t "[$CPSSYS] FORECAST COMPLETED ON LEONARDO" 
            touch $check_completed
      else
         if [[ $machine != "leonardo" ]]
         then
             echo "FORECAST not yet completed"
             exit
         fi
      fi
   done
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
#listofcases=`ls -d ${SPSSystem}_${yyyy}${st}_0?? |head -n $nrunmax`
listofcases=`ls -d ${SPSSystem}_${yyyy}${st}_0??`
count_cases=0
echo ${check_postproc_started_header}
for caso in $listofcases
do
      flag_postproc_offline_on=${check_postproc_started_header}_${caso}
      if [[ -f ${flag_postproc_offline_on} ]]  
      then
           #postproc already submitted - continue
           continue
      fi
   
      flagpostproc_done=$DIR_CASES/$caso/logs/postproc_C3S_${caso}_DONE    #not for dictionary to have a unique definition btw remote and local cases  
      if [[ -f $flagpostproc_done ]]
      then
         echo "postproc C3S ${caso} already done"
         continue
      fi
      if [[ ! -f $DIR_CASES/$caso/logs/run_moredays_${caso}_DONE ]]
      then
         continue
      fi
      $DIR_C3S/clean4C3S_listofcases.sh $caso
   
      #touch flag to avoid double resubmission
      touch ${flag_postproc_offline_on}
  
      mkdir -p $DIR_LOG/$typeofrun/C3S_postproc
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 18000 -d ${DIR_C3S} -j postproc_C3S_offline_${caso} -s postproc_C3S_offline.sh -l $DIR_LOG/$typeofrun/C3S_postproc -i "$yyyy $caso ${DIR_CASES} ${flagpostproc_done}"
      count_cases=$((count_cases + 1))
   
      if [[ $dbg -eq 1 ]]
      then
            rm ${flag_running}
            exit
      fi
      if [[ $count_cases -ge $nmaxsubmit ]]
      then
            rm ${flag_running}
            exit
      fi
   
done
rm ${flag_running}

exit 0
