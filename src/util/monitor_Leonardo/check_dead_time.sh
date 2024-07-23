#!/bin/bash
#SBATCH -A CMCC_reforeca
#SBATCH -p lrd_all_serial
#SBATCH --time 02:00:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=check_dead_time
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_dead_time_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_dead_time_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

cd $DIR_CASES
lista=`ls -altr |grep sps4|grep Jul|awk '{print $9}'` 
grep "DUE TO TIME" sps4*/logs/sps*err |grep 2024-07-15

