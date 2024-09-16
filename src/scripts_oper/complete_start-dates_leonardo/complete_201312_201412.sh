#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
st=12
LOG_FILE=$DIR_LOG/hindcast/complete_2013-2014${st}_hindcast_leonardo.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

cnt_this_script_running=$(ps -u ${operational_user} -f |grep complete_| grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
   echo "already running"
   exit
fi

n_run=`$DIR_UTIL/findjobs.sh -m $machine -n run.sps4 -c yes`
if [[ $n_run -gt $maxnumbertosubmit ]]
then
     exit
fi  


conda activate $envcondacm3
dbg=0
here=$DIR_CPS/complete_start-dates_leonardo

#for yyyy in {1993..2022} 
for yyyy in 2013 2014

do
   cd $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/
   for i in {01..30}
   do 
      caso=sps4_${yyyy}${st}_0$i
      if [[ -d $DIR_CASES/${caso} ]]
      then
         continue
      fi
      if [[ ! -f ensemble4_${yyyy}${st}_0${i}.sh ]]
      then
         echo "`realpath ensemble4_${yyyy}${st}_0${i}.sh` misteriously missing! continue"
         continue
      fi
      mkdir -p $SCRATCHDIR/cases_${st}
      ./ensemble4_${yyyy}${st}_0${i}.sh >& $SCRATCHDIR/cases_${st}/ensemble4_${yyyy}${st}_0${i}.log
      if [[ $dbg -eq 1 ]]
      then
          exit
      fi
      sleep 10
      n_run=`$DIR_UTIL/findjobs.sh -m $machine -n run.sps4 -c yes`
      if [[ $n_run -gt $maxnumbertosubmit ]]
      then
         exit
      fi  
   done
done
