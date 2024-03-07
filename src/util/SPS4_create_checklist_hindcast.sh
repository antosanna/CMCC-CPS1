#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -vxeu

# This script it's an utility that create the run list files:
# $DIR_CHECK/${CPSSYS}_hindcast_list.csv
# $DIR_CHECK/hindcast_submission.csv
LOG_FILE=$DIR_LOG/hindcast/SPS4_create_checklist_hindcast_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

# Warning: this files contains the history of the runs and regulate in turn the submissions. Don't touch them except for catastrophic needs

# Input ----------------------------------------------
members_nr=$nrunmax

file1=${SPSSystem}_${typeofrun}_list.csv

# Check if for writing ----------------------------------
# Check if for writing ----------------------------------
# Check if for writing ----------------------------------


# check if file doesn't exist, disabilitate move to work
mkdir -p $DIR_CHECK
cd $DIR_CHECK

# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------
# NOW WRITE ------------------------------------------

echo " file1 will be written in $file1"


# Write header ---------------------------------------
echo "CASO,month1,month2,month3,month4,month5,month6,days,C3S,QC" > $file1
echo "TOTAL DONE,0,0,0,0,0,0,0,0,0" >> $file1
# Write body -----------------------------------------
for st in {01..12}
do
   for yyyy in `seq $iniy_hind $endy_hind`
   do
      for ens in `seq -w 001 $(($nrunmax + 10))`
      do
         caso=${SPSSystem}_${yyyy}${st}_${ens}

         # write body
         echo "$caso,0,0,0,0,0,0,0,0,0" >> $file1
         
      done
   done
done

echo "Done $0"

exit 0
