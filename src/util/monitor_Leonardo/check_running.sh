#!/bin/sh -l
#SBATCH -A CMCC_reforeca
#SBATCH -p lrd_all_serial
#SBATCH --time 00:20:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=check_running
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_running_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_running_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
first=`date +%Y%m%d%H`; second=`squeue -u a07cmc00 -h --format="%.18i %.9P %.45j %.8u %.8T %.10M %.9l %.6D %R" |grep run.sp |grep RUN |wc -l`
echo $first " running hindcasts: " $second
