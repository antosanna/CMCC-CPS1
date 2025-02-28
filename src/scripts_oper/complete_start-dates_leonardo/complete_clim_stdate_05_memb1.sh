#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
st=05
LOG_FILE=$DIR_LOG/hindcast/complete_${st}_hindcast_leonardo.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

cnt_this_script_running=$(ps -u ${operational_user} -f |grep complete_clim_stdate| grep -v $$|wc -l)
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
if [[ $st == 01 ]]  ; then
   iniy=2013
else
   iniy=1993
fi

cd $here

list_casi='sps4_201205_001 sps4_201505_001 sps4_201605_001 sps4_201705_001 sps4_201805_001 sps4_201905_001 sps4_202005_001 sps4_202105_001 sps4_202205_001'

echo $list_casi
   
for caso in $list_casi
do 

      yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
      cd $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/
      i=`echo $caso|cut -d '_' -f3|cut -c 2-3`
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
