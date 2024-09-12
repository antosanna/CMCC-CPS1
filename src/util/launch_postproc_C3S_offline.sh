#!/bin/sh -l 
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere)
# this should run only for hindcasts!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

LOG_FILE=$DIR_LOG/hindcast/launch_postproc_C3S_from_remote.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

st=10
here=$PWD
if [[ -f $DIR_TEMP/launch_postproc_C3S_from_remote_on ]]
then
   exit
fi
nmaxsubmit=60
nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
if [[ $nsubmit -eq $nmaxsubmit ]]
then
    echo "already $nmaxsubmit postproc on the queue, exiting now"
    exit
fi
touch $DIR_TEMP/launch_postproc_C3S_from_remote_on
cd $DIR_ARCHIVE/

debug=0
for mach in Zeus Leonardo
do

   dir_cases_remote=/work/cmcc/$USER/CPS/CMCC-CPS1/cases_from_${mach}
   mkdir -p $dir_cases_remote
   listofcases=`ls sps4_????${st}_0??.transfer_from_${mach}_DONE|cut -d '.' -f1`
   echo "SPANNING $listofcases"
   nsubmit=0
   for remotecase in $listofcases
   do 

       yyyy=`echo $remotecase|cut -d '_' -f 2|cut -c 1-4`

       #for october stdate - to be generalized for other ones
#       if [[ $yyyy -eq 2020 ]] 
#       then
#           echo "missing SOLIN year - postproc separately"
 #          continue
 #      fi
       #this is the eqiuvalent of $check_pp_C3S for remote cases
       if [[ -f $dir_cases_remote/$remotecase/logs/postproc_C3S_${remotecase}_DONE ]]
       then
           continue
       fi

       flag_postproc_remote_on=$DIR_TEMP/C3S_postproc_remote_${remotecase}
       if [[ -f ${flag_postproc_remote_on} ]]  
       then
           #postproc already submitted - continue
           continue
       else
           touch ${flag_postproc_remote_on}
       fi  
       mkdir -p $DIR_LOG/hindcast/C3S_postproc
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 1000 -d ${DIR_UTIL} -j postproc_C3S_from_remote_${remotecase} -s postproc_C3S_from_remote.sh -l $DIR_LOG/hindcast/C3S_postproc -i "$remotecase $dir_cases_remote"

       #$DIR_UTIL/postproc_C3S_from_remote.sh $remotecase $dir_cases_remote
       if [[ $debug -eq 1 ]]
       then
            rm $DIR_TEMP/launch_postproc_C3S_from_remote_on
            exit
       fi
       #nsubmit=$(($nsubmit + 1))
       nsubmit=`$DIR_UTIL/findjobs.sh -m $machine -n postproc_C3S -c yes`
       if [[ $nsubmit -eq $nmaxsubmit ]]
       then
            rm $DIR_TEMP/launch_postproc_C3S_from_remote_on
            exit
       fi
  
   done
done 
rm $DIR_TEMP/launch_postproc_C3S_from_remote_on
