#!/bin/sh -l

#this script can be run in dbg mode but always using submitcommand

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

caso=$1

yyyy=`echo $caso|cut -d '_' -f2|cut -c1-4`
st=`echo $caso|cut -d '_' -f2|cut -c5-6`
real=`echo $caso|cut -d '_' -f3|cut -c2,3` 
outdirC3S=${WORK_C3S}/${yyyy}${st}  #for dictionary
startdate=${yyyy}${st}  #for dictionary
member=$real #for dictionary consistency

set +uexv
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv

dbg=0
cd $outdirC3S   #can be redundant
set +euvx
. $dictionary
set -euvx

ens=$(printf "%.3d" $((10#$member)))  #3digit member tag

#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
ACTDIR=$SCRATCHDIR/qa_checker/$startdate/CHECKER_${ens}
output=$ACTDIR/CHECK/output
spike_list=$output/list_spikes.txt


if [[ -f ${check_c3s_meta_ok} ]] && [[  -f ${spike_list} ]]
then
   if [[ -f $check_c3s_qa_err ]] ; then
       rm $check_c3s_qa_err
   fi
   touch $check_c3s_qa_ok
fi

if [[ -f ${check_c3s_meta_ok} ]] && [[ -f ${check_c3s_qa_ok} ]]
then
#-------------------------------------------
# 20240919 ready to uncomment
#-------------------------------------------
# the following is defined in $dictionary
checkfile_daily=$SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${member}_ok
   if [[ ! -f ${checkfile_daily} ]] || [[ $dbg -eq 0 ]]
   then
      ${DIR_POST}/C3S_standard/launch_C3S_daily_mean.sh $st $yyyy $member 
   fi
   touch $check_allchecksC3S$real
fi  
allcheckersok=`ls ${check_allchecksC3S}??|wc -l`
if [[ $typeofrun == "forecast" ]] 
then
  if [[ $allcheckersok -ge $nrunC3Sfore ]] 
  then
      ns=`${DIR_UTIL}/findjobs.sh -m $machine -n submit_tar_C3S${startdate} -c yes`
      nt=`${DIR_UTIL}/findjobs.sh -m $machine -n tar_C3S_${startdate} -c yes`
      if [[ $ns -eq 0 ]] && [[ $nt -eq 0 ]] 
      then
       #  body="$startdate forecast completed. \n
       #                Now submitting submit_tar_C3S.sh"
         body="$startdate forecast completed. \n
                       $DIR_C3S/submit_tar_C3S.sh to be submitted manually!"
         title="${CPSSYS} $startdate FORECAST COMPLETED"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
         #${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -S $qos -j submit_tar_C3S${startdate} -l ${DIR_LOG}/$typeofrun/$startdate -d ${DIR_C3S} -s submit_tar_C3S.sh -i "${yyyy} $st" 
 
      fi
  fi  
fi  
echo "$0 completed"
exit 0
