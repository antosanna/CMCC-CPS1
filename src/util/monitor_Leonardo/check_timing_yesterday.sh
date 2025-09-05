#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx

yesterday=`date -d "1 day ago" +%Y-%m-%d`
today=`date +%Y-%m-%d`
cd $DIR_CASES
lista=`ls -altr |grep sps4|awk '{print $9}'` 

mkdir $SCRATCHDIR/CERISE
for ll in $lista
do 
   if [[ -d $ll/timing ]]
   then
      files=`find $ll/timing/ -name \*_tim\* -newermt $yesterday ! -newermt $today`
      for ff in $files
      do
         jobid=`echo $ff|cut -d '.' -f3`
         string=`grep simulated_years $ff`
         echo $ll ", "$jobid ", " $yesterday ", " $string >> $SCRATCHDIR/CERISE/production_time.`date +%Y%m%d`.txt
      done
   fi
done
