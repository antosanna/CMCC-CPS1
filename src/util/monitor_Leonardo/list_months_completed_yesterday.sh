#!/bin/sh -l
#SBATCH -A CMCC_reforeca
#SBATCH -p lrd_all_serial
#SBATCH --time 00:30:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=list_completed
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/list_months_completed_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/list_months_completed_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -uexv

yesterday=`date -d "1 day ago" +%Y-%m-%d`
today=`date +%Y-%m-%d`


cd $DIR_CASES
lista=`ls -altr |grep sps4|awk '{print $9}'` 

cnt=0
for dd in $lista
do

   n_done=`find $dd/logs/. -name postproc_monthly\* -newermt $yesterday ! -newermt $today |wc -l` 
   cnt=$(($cnt + $n_done))
done
echo "total number of months completed yesterday: "$yesterday
echo $cnt
