#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
st=08
LOG_FILE=$DIR_LOG/hindcast/complete_${st}_hindcast_leonardo.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

cnt_this_script_running=$(ps -u ${operational_user} -f |grep complete_clim_stdate| grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
   echo "already running"
   exit
fi

n_run=`$DIR_UTIL/findjobs.sh -m $machine -n st_archive.sps4 -c yes`
if [[ $n_run -gt $maxnumbertosubmit ]]
then
     exit
fi  


conda activate $envcondacm3
dbg=0
here=$DIR_CPS/complete_start-dates_leonardo


#list_casi="sps4_201308_001 sps4_201408_001 sps4_201508_001 sps4_201608_001 sps4_201708_001 sps4_201808_001 sps4_201908_001 sps4_202008_001 sps4_202108_001 sps4_202208_001 sps4_201108_001"
list_casi="sps4_201308_001"
   
for caso in $list_casi
do 
      yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
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
