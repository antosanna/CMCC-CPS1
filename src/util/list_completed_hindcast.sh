#!/bin/bash
#SBATCH -A CMCC_reforeca
#SBATCH -p dcgp_usr_prod
#SBATCH --time 08:00:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=list_completed
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/list_completed_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/list_completed_%J.out
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

curryear=`date +%Y`
cd $DIR_CASES
lista=`ls -altr |grep ${SPSSystem}|grep -v $curryear|awk '{print $9}'` 

for dd in $lista
do
   n_done=`ls $dd/logs/*DONE |wc -l`
   if [[ $n_done -eq 1 ]]
   then
      echo $dd >> $SCRATCHDIR/list_`date +%Y%m%d`
   fi
done
