#!/bin/sh -l
#SBATCH -A CMCC_2025
#SBATCH -p lrd_all_serial
#SBATCH --time 00:30:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=list_completed_10dd
#SBATCH --err=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/list_months_completed_10dd_%J.err
#SBATCH --out=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/list_months_completed_10dd_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

period=2
yesterday=`date -d "$period day ago" +%Y-%m-%d`
today=`date +%Y-%m-%d`


cd $DIR_CASES
lista=`ls -altr |grep sps4|awk '{print $9}'` 

cnt=0
yesterday=2025-05-09
today=2025-05-11
for dd in $lista
do

   n_done=`find $dd/logs/. -name postproc_monthly\* -newermt $yesterday ! -newermt $today |wc -l` 
   cnt=$(($cnt + $n_done))
done
echo "total number of months completed yesterday: "$yesterday
echo $cnt
