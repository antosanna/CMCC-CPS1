#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_from_remote.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

here=$PWD
cd $DIR_ARCHIVE/

debug=1
for mach in "Zeus"
do
   dir_cases_remote=/work/$DIVISION/$USER/CPS/CMCC-CPS1/cases_from_${mach}
   mkdir -p $dir_cases_remote
   listofcases=`ls *transfer_from_${mach}_DONE|cut -d '.' -f1`
   echo "SPANNING $listofcases"
   for remotecase in $listofcases
   do 

      $DIR_UTIL/postproc_C3S_from_remote.sh $remotecase $dir_cases_remote
      if [[ $debug -eq 1 ]]
      then
         exit
      fi
  
   done
done 
