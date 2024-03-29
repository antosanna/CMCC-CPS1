#!/bin/sh -l

#this script can be run in debug mode but always using submitcommand

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

member=$1
outdirC3S=$2
startdate=$3
caso=$4

yyyy=`echo ${startdate:0:4}`
set +uexv
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv
echo "STILL TO BE UPDATED, NOW EXITING"
exit 0

debug=0
cd $outdirC3S   #can be redundant
set +euvx
. $dictionary
set -euvx
mkdir -p $DIR_CASES/$caso/logs

st=`echo "${startdate}" | cut -c5-6`
#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
if [ ! -f $outdirC3S/qa_checker_ok_0${member} ] 
then
# if not already launched
   ${DIR_C3S}/launch_c3s_qa_checker_1ens.sh $startdate $member $outdirC3S
fi
# others checkers 
if [ ! -f $outdirC3S/meta_checker_ok_0${member} ] 
then
   ${DIR_C3S}/c3s_metadata_checker_1ens.sh $startdate $member $outdirC3S
fi
if [ ! -f $outdirC3S/tmpl_checker_ok_0${member} ]
then
   ${DIR_C3S}/launch_c3s_tmpl_checker.sh $startdate $member $outdirC3S
fi

# BEFORE THIS AND ADD YOUR CHECKFILE INT THE IF CONDITION
if [ ! -f $outdirC3S/dmoc3s_checker_ok_0${member} ]
then 
			${DIR_C3S}/launch_checkdmoC3S-pdf-chain.sh $startdate $member $outdirC3S
fi
cd $outdirC3S

if [ -f $outdirC3S/meta_checker_ok_0${member} ] && [ -f $outdirC3S/dmoc3s_checker_ok_0${member} ] && [ -f $outdirC3S/tmpl_checker_ok_0${member} ] && [ -f $outdirC3S/qa_checker_ok_0${member} ] #&& [ -f $outdirC3S/findspikes_c3s_ok_0${member} ]
then
   mkdir -p ${DIR_LOG}/${typeofrun}/$startdate/C3S_daily_postproc
# the following is defined in $dictionary
#   checkfile_daily=$DIR_LOG/$typeofrun/$yyyy$st/C3S_daily_postproc/qa_checker_daily_ok_${member}
   if [ ! -f ${checkfile_daily} ] || [[ $debug -eq 0 ]]
   then
      ${DIR_POST}/C3S_standard/launch_C3S_daily_mean.sh $st $yyyy $member 
   fi
   touch $check_allchecksC3S$member
fi  
allcheckersok=`ls ${check_allchecksC3S}??|wc -l`
if [ $allcheckersok -ge $nrunC3Sfore ] 
then
   ns=`${DIR_UTIL}/findjobs.sh -m $machine -r ${sla_serialID} -n submit_tar_and_push${startdate} -c yes`
   nt=`${DIR_UTIL}/findjobs.sh -m $machine -r ${sla_serialID} -n tar_and_push_${startdate} -c yes`
   if [ $ns -eq 0 ] && [ $nt -eq 0 ] 
   then
      body="$startdate forecast completed. \n
                       Now submitting submit_tar_and_push.sh"
      title="${SPSSYS} $startdate FORECAST COMPLETED"
    	 ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
    	 ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -t "6" -r $sla_serialID -S qos_resv -j submit_tar_and_push${startdate} -l ${DIR_LOG}/$typeofrun/$startdate -d ${DIR_C3S} -s submit_tar_and_push.sh -i "${yyyy} $st" 
   fi  
fi  
echo "$0 completed"
exit 0
