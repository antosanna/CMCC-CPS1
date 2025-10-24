#!/bin/bash
#SBATCH -A CMCC_2025
#SBATCH -p lrd_all_serial
#SBATCH --time 02:00:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=check_dead_time
#SBATCH --err=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/check_dead_time_%J.err
#SBATCH --out=/leonardo_work/CMCC_2025//CPS/CMCC-CPS1/logs/hindcast/monitor/check_dead_time_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

cd $DIR_CASES

lista=`ls -d $DIR_CASES/sps4*` 
for casodir in $lista ; do
   caso=`basename $casodir` 
   cd $DIR_CASES/$caso/logs
   iserr=`grep "DUE TO TIME" $caso*.err |grep 2024-07 | wc -l`
   errmes=""
   if [[ $iserr -ne 0 ]] ; then
       errmes=`grep "DUE TO TIME" $caso*.err |grep 2024-07 |sed -r 's/\*\*\*/@/g'`
       string4tab="$caso , `echo $DIR_CASES/$caso/logs/$errmes |cut -d ':' -f1` , `echo $errmes |cut -d '@' -f 2`"
       echo $string4tab
   fi
done
