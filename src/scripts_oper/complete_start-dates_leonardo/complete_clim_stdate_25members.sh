#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993

set -euvx
st=$1
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

for yyyy in `seq $iniy_hind $endy_hind`

#20240711
#For november stdate, many years were run with half ensemble run 
#Waiting for the IC to be copied, 1993 has started on Zeus, so on Leo we will run from 1994 onward
#for yyyy in 2022
do
   cd $here
   list_casi=`python read_csv.py sps4_hindcast_list.csv -y $yyyy -st $st `
   echo $list_casi
   
   cd $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/
   for caso in $list_casi
   do 
      i=`echo $caso|cut -d '_' -f3|cut -c 2-3`
      if [[ $((10#$i)) -gt $nrunmax ]]
      then
         continue
      fi
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
