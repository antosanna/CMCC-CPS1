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
checkfile_all_camC3S_done=$4
checkfile_qa=$5 #$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok

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

#-------------------------------------------------------------
# Go to output dir for C3S vars
#-------------------------------------------------------------
if [[ ! -f checkfile_all_camC3S_done ]]
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
         body="$var C3S from CAM missing for case $caso. Exiting $DIR_POST/cam/regridSEne60_C3S.sh "
         title="[C3S] ${CPSSYS} forecast ERROR"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
         exit
      fi  
   done
   
   #-------------------------------------------------------------
   # CHECK TIMESTEP AND IN CASE FIX IT
   #-------------------------------------------------------------
   checkfix_timesteps=$outdirC3S/fix_timesteps_C3S_${startdate}_${ens}_ok
   $DIR_C3S/fix_timesteps_C3S_1member.sh $startdate $ens $checkfix_timesteps $outdirC3S
   
   touch $checkfile_all_camC3S_done
fi

cd $outdirC3S   #can be redundant
member=$ens
allC3S=`ls *${real}.nc|wc -l`
#-------------------------------------------------------------
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
#-------------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs/
# if not already launched
if [ $allC3S -eq $nfieldsC3S ] && [ ! -f $checkfile ]
then
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -r $sla_serialID -S qos_resv -j checker_and_archive_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s checker_and_archive.sh -i "$member $outdirC3S $startdate $caso"
fi
echo "$0 completed"
exit 0
