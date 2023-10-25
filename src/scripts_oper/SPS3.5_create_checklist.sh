#!/bin/sh -l
#BSUB -q s_short
#BSUB -J SPS3.5_checklist
#BSUB -e ../../logs/SPS3.5_checklist%J.err
#BSUB -o ../../logs/SPS3.5_checklist%J.out
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_SPS35}/descr_hindcast.sh

set -vx

# This script it's an utility that create the run list files:
# $DIR_CHECK/${SPSSYS}_hindcast_list.csv
# $DIR_CHECK/hindcast_submission.csv

# Warning: this files contains the history of the runs and regulate in turn the submissions. Don't touch them except for catastrophic needs

# Input ----------------------------------------------
starting_yr=1993
ending_yr=2016
members_nr=40

file1=${SPSSYS}_hindcast_list.csv #_TEST
file2=hindcast_submission.csv #_TEST

# Check if for writing ----------------------------------
# Check if for writing ----------------------------------
# Check if for writing ----------------------------------

# move to work flag. If active (default) place file in work
mvtowork1=1
mvtowork2=1

# check if file don't exist, disabilitate move to work
cd $DIR_CHECK
if [ ! -L $file1 ] ; then
   mvtowork1=0
fi
if [ ! -L $file2 ] ; then
   mvtowork1=0
fi

# check if file don't exist, disabilitate move to work
cd $DIR_ROOT/scratch
if [ ! -f $file1 ] ; then
   mvtowork1=0
fi
if [ ! -f $file2 ] ; then
   mvtowork1=0
fi

# If there are processes on sla slaID mv in work ---
cntserial=`bjobs -sla ${sla_serialID} -w | wc -l`
cntparall=`bjobs -sla $slaID -w | wc -l`

if [ $cntserial -gt 0 -o $cntparall -gt 0 ]; then
   echo "WARNING: Found some processes (serial || parall) running on service class SC*sps35. We don't want to overwrite $file1 or $file2 while model is running. This should led to catastrophic error"
   echo "Your list files will be placed in /users_home/csp/sp1/SPS/CMCC-${SPSSYS}/work"
   mvtowork1=1
   mvtowork2=1
fi

# change file name according to mvtowork -------------
if [ $mvtowork1 -eq 0 ] ; then
   file1=$DIR_ROOT/scratch/${file1}
else
   file1=$DIR_ROOT/work/${file1}
fi

if [ $mvtowork2 -eq 0 ] ; then
   file2=$DIR_ROOT/scratch/${file2}
else
   file2=$DIR_ROOT/work/${file2}
fi

# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------

echo " file1 will be written in $file1"
echo " file2 will be written in $file2"


# Write header ---------------------------------------
echo "CASO,JOBID,mese1,mese2,mese3,mese4,mese5,mese6,mese7,archivio" > $file1
echo "CASO,SUBM_FLAG" > $file2
# Write body -----------------------------------------
m=1
while [ $m -le 12 ]
do
   st=`printf '%.2d' $m`
   yy=$starting_yr
   while [ $yy -le $ending_yr ]
   do
      n=1
      while [ $n -le $members_nr ]
      do
         ens=`printf '%.3d' $n`
         caso=${SPSsystem}_${yy}${st}_${ens}

         # write body
         echo "$caso,dummy,dummy,dummy,dummy,dummy,dummy,dummy,dummy,dummy" >> $file1
         echo "$caso,0" >> $file2
         
         n=$(($n + 1))
      done
      yy=$(($yy + 1))
   done
   m=$(($m + 1))
done

echo "Done $0"

exit 0
