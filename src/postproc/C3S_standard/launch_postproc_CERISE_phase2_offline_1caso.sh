#!/bin/sh -l 
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

#BEFORE RUNNING THIS SCRIPT FOR A NEW STARTDATE CLEAN OLD FILES WITH $DIR_C3S/clean4C3S.sh
mkdir -p $DIR_LOG/hindcast/
LOG_FILE=$DIR_LOG/hindcast/launch_postproc_CERISE_phase2_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

dbg=0

flag_running=$DIR_LOG/hindcast/launch_postproc_CERISE_phase2_offline_on #to avoid multiple submission from crontab
if [[ -f ${flag_running} ]]
then
   exit
fi

nmaxsubmit=50
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_CERISE -c yes`
if [[ $nsubmit -eq $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch ${flag_running}
cd $DIR_ARCHIVE/

# fatti sps4_200205_010 sps4_201605_025 sps4_202005_009
listofcases="sps4_200205_010 sps4_201605_025 sps4_202005_009 sps4_202105_011"
for caso in $listofcases
do
   yyyy=`echo $caso |cut -d '_' -f2|cut -c 1-4`
   st=`echo $caso |cut -d '_' -f2|cut -c 5-6`
   
   list_not_completed=""
   list_done_on_juno=""
   dir_cases=$DIR_CASES
   
   casedir=${dir_cases}/$caso
   if [[ ! -d $casedir ]]
   then
      echo ""
      echo "!!!!!!! CASE $caso RUN ON OTHER MACHINE !!!!!!"
      echo ""
      list_done_on_juno+=" $caso"
      continue
   fi
   logdir=${dir_cases}/$caso/logs
   if [[ ! -f $logdir/run_moredays_${caso}_DONE ]]
   then
          echo ""
          echo "!!!!!!! CASE $caso NOT COMPLETED !!!!!!"
          echo ""
          list_not_completed+=" $caso"
          continue
   fi

   flag_postproc_offline_on=$DIR_CASES/$caso/logs/CERISE_phase2_postproc_offline_${caso}
   if [[ -f ${flag_postproc_offline_on} ]]  
   then
            #postproc already submitted - continue
            continue
   else
            touch ${flag_postproc_offline_on}
   fi  
   
   mkdir -p $DIR_LOG/hindcast/CERISE_phase2_postproc
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 20000 -d ${DIR_C3S} -j postproc_CERISE_phase2_offline_${caso} -s postproc_CERISE_phase2_offline.sh -l $DIR_LOG/hindcast/CERISE_phase2_postproc -i "$yyyy $caso ${dir_cases} $dbg"
   
   
   if [[ $dbg -eq 1 ]]
   then
      rm ${flag_running}
      exit
   fi
   nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_CERISE_phase2 -c yes`
   if [[ $nsubmit -eq $nmaxsubmit ]]
   then
         rm ${flag_running}
         exit
   fi
   
done
rm ${flag_running}

exit 0
