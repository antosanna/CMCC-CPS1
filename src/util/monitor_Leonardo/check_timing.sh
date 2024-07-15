#!/bin/bash
#SBATCH -A CMCC_reforeca
#SBATCH -p dcgp_usr_prod
#SBATCH --time 08:00:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=check_timing
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/monitor/check_timing_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/monitor/check_timing_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

cd $DIR_CASES
lista=`ls -altr |grep sps4|grep Jul|awk '{print $9}'` 

for ll in $lista
do 
   if [[ -d $ll/timing ]]
   then
      files=`ls $ll/timing/*_tim*`
      for ff in $files
      do
         jobid=`echo $ff|cut -d '.' -f3`
         mmddhh=`ls -altr $ff|grep Jul|awk '{print $6,$7,$8}'`
         if [[ $mmddhh != "" ]]
         then
         string=`grep simulated_years $ff`
         echo $ll ", "$jobid ", " $mmddhh ", " $string
         fi
      done
   fi
done
