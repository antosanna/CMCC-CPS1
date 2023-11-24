#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -vxeu

# This script it's an utility that create the run list files:
# $DIR_CHECK/${CPSSYS}_hindcast_list.csv
# $DIR_CHECK/hindcast_submission.csv

# Warning: this files contains the history of the runs and regulate in turn the submissions. Don't touch them except for catastrophic needs

# Input ----------------------------------------------
members_nr=$nrunmax

file1=${SPSSystem}_${typeofrun}_list.csv
file2=${typeofrun}_submission.csv

# Check if for writing ----------------------------------
# Check if for writing ----------------------------------
# Check if for writing ----------------------------------

# move to work flag. If active (default) place file in work
mvtowork1=1
mvtowork2=1

# check if file doesn't exist, disabilitate move to work
mkdir -p $DIR_CHECK
cd $DIR_CHECK
if [ ! -f $file1 ] ; then
   mvtowork1=0
fi
if [ ! -f $file2 ] ; then
   mvtowork1=0
fi

# If there are processes on sla slaID mv in work ---
#cntserial=`bjobs -sla ${sla_serialID} -w | wc -l`
#cntparall=`bjobs -sla $slaID -w | wc -l`
#change in findjobs
np=`${DIR_UTIL}/findjobs.sh -m $machine -n ${SPSSystem} -c yes`

#if [ $cntserial -gt 0 -o $cntparall -gt 0 ]; then
if [ $np -gt 0 ]; then
   echo "WARNING: Found some processes (serial || parall) running on service class SC*sps35. We don't want to overwrite $file1 or $file2 while model is running. This should led to catastrophic error"
   echo "Your list files will be placed in $DIR_TEMP"
   mvtowork1=1
   mvtowork2=1
fi

# change file name according to mvtowork -------------
mkdir -p $DIR_TEMP   #check where to put
if [ $mvtowork1 -eq 0 ] ; then
   file1=$DIR_CHECK/${file1}
else
   file1=$DIR_TEMP/${file1}
fi

if [ $mvtowork2 -eq 0 ] ; then
   file2=$DIR_CHECK/${file2}
else
   file2=$DIR_TEMP/${file2}
fi

# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------

echo " file1 will be written in $file1"
echo " file2 will be written in $file2"


# Write header ---------------------------------------
echo "CASO,month1,month2,month3,month4,month5,month6,days,archive" > $file1
echo "CASO,SUBM_FLAG" > $file2
# Write body -----------------------------------------
for st in {01..12}
do
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      for ens in `seq -w 001 $nrunmax`
      do
         caso=${SPSSystem}_${yyyy}${st}_${ens}

         # write body
         echo "$caso,--,--,--,--,--,--,--,--" >> $file1
         echo "$caso,0" >> $file2
         
      done
   done
done

echo "Done $0"

exit 0