#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
LOG_FILE=$DIR_LOG/forecast/check_completed_forecasts.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1
stdate=`date +%Y%m`

yyyy=`date +%Y`
st=`date +%m`
mkdir -p $DIR_LOG/forecast/$yyyy/$st/
check_completed=$DIR_LOG/forecast/$yyyy/$st/FORECAST_COMPLETED
if [[ -f $check_completed ]]
then
   exit
fi

cnt_this_script_running=$(ps -u ${operational_user} -f |grep check_completed_forecasts | grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
      echo "already running"
      exit
fi   

cd $DIR_ARCHIVE
n_completed=0
for ens in {001..055}
do
   caso=sps4_${stdate}_${ens}
   if [[ -f $DIR_CASES/$caso/logs/run_moredays_sps4_${stdate}_${ens}_DONE ]]
   then
      n_completed=$(($n_completed + 1))
   fi
   if [[ $n_completed -ge 50 ]]
   then
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "Time to copy results from Juno" -t "FORECAST COMPLETED ON LEONARDO" 
         touch $check_completed
         exit
   fi
done
if [[ $n_completed -gt 0 ]] 
then
   body="$n_completed forecasts completed on Leonardo" 
   title=$body
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
fi
