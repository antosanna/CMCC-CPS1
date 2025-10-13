#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -eu
cnt_this_script_running=$(ps -u ${operational_user} -f |grep check_status_forecasts | grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
      echo "already running"
      exit
fi   
mkdir -p $DIR_LOG/hindcast/
LOG_FILE=$DIR_LOG/hindcast/check_status_hindcasts_2023-2024.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1
fmt="%-15s %-15s %-15s %-15s\n"
mkdir -p $DIR_REP/new_hindcasts
report=$DIR_REP/new_hindcasts/advancement_status.`date +%Y%m%d%H`.txt
for yyyy in 2023 2024
do
   for st in {01..12}
   do
      stdate=$yyyy$st
      cd $DIR_ARCHIVE
      restlist=""
      mkdir -p $DIR_REP/$stdate
      if [[ -f $report ]]
      then
         rm $report
      fi
      printf "${fmt}" "CASE" "STATUS" "last-for-day" "last-rest" > $report
      for i in {001..030}
      do
         caso=sps4_${stdate}_${i}
set +e
         st_pen=`bj |grep run.$caso|grep PEN` 
         st_run=`bj |grep run.$caso|grep RUN` 
set -e
         if [[ ! -z $st_pen ]]
         then
            status="PENDING"
         elif [[ ! -z $st_run ]]
         then
            status="RUN"
         else 
            status="NOT-QUEUED"
         fi
         lastday1="$caso        "
         log2check=`ls -rt $WORK_CPS/$caso/run/rof.log*[0-9]|tail -1`
         if [[ ! -z $log2check ]]
         then
            teststring=`grep "model date" $log2check|tail -1|awk '{print $5}'`
            if [[ ! -z $teststring ]]
            then
               lastday2=$teststring
            fi
         else
            lastday2="--------"
         fi
         if [[ -d $DIR_ARCHIVE/$caso/rest ]]
         then
            cd $DIR_ARCHIVE/$caso/rest
            restlist+=" `ls |cut -d '-' -f2`"
            lastday3="      `ls |cut -d '-' -f2`"
            if [[ `echo $lastday3|wc -w` -eq 2 ]]
            then
               fmt="%-15s %-15s %-15s %-15s %-15s\n"
            fi
         else
            lastday3="first-month"
         fi
         printf "${fmt}" $lastday1  $status $lastday2 $lastday3 >>$report
   
      done
   done
done
echo "file with status advancement here $report "
#uniq_rest=(`echo $restlist|tr ' ' '\n' |sort|uniq -c`)
message=""
uniq_rest=(`echo $restlist|tr ' ' '\n' |sort|uniq`)
dim=${#uniq_rest[@]}
for i in `seq 0 $(($dim - 1))`
do
   n=`echo $restlist|grep -o ${uniq_rest[$i]}|wc -l`
   message+=" number of member with restart month ${uniq_rest[$i]} is $n ---"
#   message+=" number of member with restart month ${uniq_rest[$i]} is $n \n"
done
exit
${DIR_UTIL}/sendmail.sh -a $report -m $machine -e $mymail -M "$message" -t "SPS4 $stdate status" -r yes -s $stdate
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -eu
rclone mkdir my_drive:forecast/$stdate/REPORTS
rclone copy ${report} my_drive:forecast/$stdate/REPORTS
