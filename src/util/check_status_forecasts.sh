#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -eux
stdate=`date +%Y%m`
st=`date +%m`
mkdir -p $DIR_LOG/forecast/$stdate/
if [[ $machine != "cassandra" ]]
then
  LOG_FILE=$DIR_LOG/forecast/$stdate/check_status_forecasts.`date +%Y%m%d%H%M`.log
  exec 3>&1 1>>${LOG_FILE} 2>&1
fi

cnt_this_script_running=$(ps -u ${operational_user} -f |grep check_status_forecasts | grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
      echo "already running"
      exit
fi   
check_completed=$DIR_LOG/forecast/$stdate/FORECAST_COMPLETED
if [[ -f $check_completed ]]
then
   exit
fi
rclone_tag=$stdate
if [[ $is_backup -eq 1 ]] #currently juno and cassandra - April 2026 
then
    rclone_tag=${stdate}_backup
fi
DIR_RCLONE=forecast/${rclone_tag}

fmt="%-15s %-15s %-15s %-15s\n"
cd $DIR_ARCHIVE
restlist=""
list_run_mon=""
mkdir -p $DIR_REP/$stdate
report=$DIR_REP/$stdate/advancement_status_${stdate}.`date +%Y%m%d%H`.txt
if [[ -f $report ]]
then
   rm $report
fi
printf "${fmt}" "CASE" "STATUS" "last-for-day" "running-month" > $report
for i in {001..054}
do
   fmt="%-15s %-15s %-15s %-15s\n"
   caso=sps4_${stdate}_${i}
set +e
   # Use findjobs to find job status for portability
   st_pen=`${DIR_UTIL}/findjobs.sh -N run.${caso} -a PEN`
   st_run=`${DIR_UTIL}/findjobs.sh -N run.${caso} -a RUN`
#   st_pen=`bj |grep run.$caso|grep PEN` 
#   st_run=`bj |grep run.$caso|grep RUN` 
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
   last_updated_file=`ls -rt $WORK_CPS/$caso/run/*`
   log2check=`ls -rt $WORK_CPS/$caso/run/rof.log*[0-9]|tail -1`
   lastday2="--------       "
   if [[ ! -z $log2check ]]
   then
      teststring=`grep "model date" $log2check|tail -1|awk '{print $5}'`
      if [[ ! -z $teststring ]]
      then
         lastday2="$teststring       "
      fi
   fi
   if [[ -d $DIR_ARCHIVE/$caso/rest ]]
   then
      cd $DIR_ARCHIVE/$caso/rest
      restlist+=" `ls |cut -d '-' -f2`"
      lastday3=`ls |tail -1|cut -d '-' -f2`
      run_mon=$((10#$lastday3 - 10#$st + 1))
      list_run_mon+=" $run_mon"
      if [[ `echo $lastday3|wc -w` -eq 2 ]]
      then
         fmt="%-15s %-15s %-15s %-15s %-15s\n"
      fi
   else
      run_mon="1"
   fi
   printf "${fmt}" $lastday1  $status $lastday2 $run_mon >>$report
   
done
echo "file with status advancement here $report "
#uniq_rest=(`echo $restlist|tr ' ' '\n' |sort|uniq -c`)
message=""
#uniq_rest=(`echo $restlist|tr ' ' '\n' |sort|uniq`)
uniq_rest=(`echo $list_run_mon|tr ' ' '\n' |sort|uniq`)
dim=${#uniq_rest[@]}
for i in `seq 0 $(($dim - 1))`
do
#   n=`echo $restlist|grep -o ${uniq_rest[$i]}|wc -l`
   n=`echo $list_run_mon|grep -o ${uniq_rest[$i]}|wc -l`
#   message+=" number of member with restart month ${uniq_rest[$i]} is $n ---"
   message+=" number of member with completed month ${uniq_rest[$i]} is $n ---"
done
${DIR_UTIL}/sendmail.sh -a $report -m $machine -e $mymail -M "$message" -t "[SPS4 notification] $stdate status update" -r yes -s $stdate
listaf=${report}
mkdir -p $DIR_LOG/wrapper
${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_${stdate}_status -l $DIR_LOG/wrapper -d ${DIR_UTIL} -s rclone_wrapper.sh -i "${DIR_RCLONE}/REPORTS '${listaf}'"
