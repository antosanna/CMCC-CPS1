#!/bin/sh -l 
# script to run the postprocessing C3S on Juno offline
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_offline.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

here=$PWD
if [[ -f $DIR_TEMP/launch_postproc_C3S_offline_on ]]
then
   exit
fi
touch $DIR_TEMP/launch_postproc_C3S_offline_on
cd $DIR_ARCHIVE/

debug=1
listofcases=
for caso in $listofcases
do 
set +euvx
   . $dictionary
set -euvx
   if [[ -f $check_pp_C3S ]]
   then
      continue
   fi
   $DIR_UTIL/postproc_C3S_offline.sh $caso 
   if [[ $debug -eq 1 ]]
   then
      exit
   fi
   nsubmit=$(($nsubmit + 1))
   if [[ $nsubmit -eq 10 ]]
   then
      exit
   fi
  
done
rm $DIR_TEMP/launch_postproc_C3S_offline_on
