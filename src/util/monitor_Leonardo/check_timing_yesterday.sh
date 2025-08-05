#!/bin/sh -l
#SBATCH -A CMCC_reforeca
#SBATCH -p lrd_all_serial
#SBATCH --time 00:30:00     # format: HH:MM:SS
#SBATCH --ntasks=1 # 4 tasks out of 112
#SBATCH --job-name=check_timing
#SBATCH --err=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_timing_yesterday_%J.err
#SBATCH --out=/leonardo_work/CMCC_reforeca//CPS/CMCC-CPS1/logs/hindcast/monitor/check_timing_yesterday_%J.txt
#SBATCH --qos=qos_lowprio

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

yesterday=`date -d "1 day ago" +%Y-%m-%d`
today=`date +%Y-%m-%d`
cd $DIR_CASES
lista=`ls -altr |grep sps4|awk '{print $9}'` 

for ll in $lista
do 
   if [[ -d $ll/timing ]]
   then
      files=`find $ll/timing/ -name \*_tim\* -newermt $yesterday ! -newermt $today`
      for ff in $files
      do
         jobid=`echo $ff|cut -d '.' -f3`
         string=`grep simulated_years $ff`
         echo $ll ", "$jobid ", " $yesterday ", " $string
      done
   fi
done
