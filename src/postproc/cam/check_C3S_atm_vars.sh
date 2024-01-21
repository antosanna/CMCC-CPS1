#!/bin/sh -l
#BSUB -P 0490
#BSUB -J test
#BSUB -e logs/test_%J.err
#BSUB -o logs/test_%J.out
# this script can be run in debug mode but always with submitcommand
# THIS IHAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
#

#==================================================
# IN OPERATIONAL MODE RECEIVE INPUTS FROM PARENT SCRIPT
#==================================================
ft=$1
caso=$2
export outdirC3S=$3
check_all_camC3S_done=$4
check_qa_start=$5 

export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
ens=`echo $caso|cut -d '_' -f 3|cut -c 2,3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
export ndaysreq=$fixsimdays
startdate=$yyyy$st
export C3Stable="$DIR_POST/cam/C3S_table.txt"
export fixsimdays
export real="r"${ens}"i00p00"
#-------------------------------------------------------------
# Go to output dir for C3S vars
#-------------------------------------------------------------
if [[ ! -f $check_all_camC3S_done ]]
then
   cd $outdirC3S
   #-------------------------------------------------------------
   # read all cam variables from $C3Stable
   #-------------------------------------------------------------
   {
   read 
   while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
   do
      varC3S+=" $C3S"
   done } < $C3Stable
   for var in $varC3S
   do
   #-------------------------------------------------------------
   # now check that all required vars but rsdt have been produced
   #-------------------------------------------------------------
      if [ ! -f *${var}_*${real}.nc ]
      then
         body="$var C3S from CAM missing for case $caso. Exiting $DIR_POST/cam/regridFV_C3S.sh "
         title="[C3S] ${CPSSYS} forecast ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
         exit
      fi  
   done
   
   #-------------------------------------------------------------
   # CHECK TIMESTEP AND IN CASE FIX IT
   #-------------------------------------------------------------
   $DIR_C3S/fix_timesteps_C3S_1member.sh $startdate $ens $outdirC3S
   
   touch $check_all_camC3S_done
fi

cd $outdirC3S   #can be redundant
member=$ens
allC3S=`ls *${real}.nc|wc -l`
#-------------------------------------------------------------
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
#-------------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs/
# if not already launched
#check_qa_start=$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
#get from dictionary
set +euvx
. $dictionary
set -euvx
if [ $allC3S -eq $nfieldsC3S ] && [ ! -f $check_qa_start ]
then
# TEMPORARY UNTIL IMPLEMENTATION OF CHECKER
   body="Temporary exit in $DIR_POST/cam/check_C3S_atm_vars.sh until the implementation of the checker has been done"
   title="[CPS1] warning! $caso exiting before $DIR_C3S/checker_and_archive.sh"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
   exit
 ###!! TO BE ADDED SERIAL RESERVATION
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -S qos_resv -j checker_and_archive_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s checker_and_archive.sh -i "$member $outdirC3S $startdate $caso"
fi
echo "$0 completed"
exit 0
