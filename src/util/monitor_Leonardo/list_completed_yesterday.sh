#!/bin/bash
#SBATCH -A CMCC_2025
#SBATCH -p lrd_all_serial
#SBATCH --time 01:00:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=list_completed
#SBATCH --err=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/list_completed_%J.err
#SBATCH --out=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/list_completed_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

yesterday=`date -d "1 day ago" +%Y-%m-%d`
today=`date +%Y-%m-%d`


cd $DIR_CASES
lista=`ls -altr |grep sps4|awk '{print $9}'` 

cnt=0
for dd in $lista
do

   n_done=`find $dd/logs/. -type f -newermt $yesterday ! -newermt $today |grep _DONE |wc -l` 
#   n_done=`ls -latr $dd/logs/*DONE |grep "$yesterday" |wc -l`
   if [[ $n_done -eq 1 ]]
   then
     echo $dd
     cnt=$(($cnt + 1))
   fi
done
echo "total number of cases completed yesterday: "$yesterday
echo $cnt
