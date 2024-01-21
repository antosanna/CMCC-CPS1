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
allC3S=`ls *${member}i00p00.nc|wc -l`
# get check_qa_start e check_allchecksC3S from dictionary
set +euvx
. $dictionary
set -euvx
mkdir -p $DIR_CASES/$caso/logs

yyyy=`echo "${startdate}" | cut -c1-4`
st=`echo "${startdate}" | cut -c5-6`
#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
if [ $allC3S -eq $nfieldsC3S ]  && [ ! -f $check_qa_start ]
then
# check that the process has not been already submitted by regridSEne60_C3S.sh
# qa checker
   if [ ! -f $outdirC3S/qa_checker_ok_0${member} ] || [[ $debug -eq 0 ]]
   then
# if not already launched
         ${DIR_C3S}/launch_c3s_qa_checker_1member.sh $startdate $member $check_qa_start $outdirC3S
   fi
# others checkers 
   if [ ! -f $outdirC3S/meta_checker_ok_0${member} ] || [[ $debug -eq 0 ]]
   then
      ${DIR_C3S}/c3s_metadata_checker_1member.sh $startdate $member $outdirC3S
   fi
   if [ ! -f $outdirC3S/tmpl_checker_ok_0${member} ] || [[ $debug -eq 0 ]]
   then
      ${DIR_C3S}/launch_c3s_tmpl_checker.sh $startdate $member $outdirC3S
   fi

# BEFORE THIS AND ADD YOUR CHECKFILE INT THE IF CONDITION
   if [ ! -f $outdirC3S/dmoc3s_checker_ok_0${member} ] || [[ $debug -eq 0 ]]
   then 
   			${DIR_C3S}/launch_checkdmoC3S-pdf-chain.sh $startdate $member $outdirC3S
   fi
   cd $outdirC3S

   if [ -f $outdirC3S/meta_checker_ok_0${member} ] && [ -f $outdirC3S/dmoc3s_checker_ok_0${member} ] && [ -f $outdirC3S/tmpl_checker_ok_0${member} ] && [ -f $outdirC3S/qa_checker_ok_0${member} ] && [ -f $outdirC3S/findspikes_c3s_ok_0${member} ]
   then
      mkdir -p ${DIR_LOG}/${typeofrun}/$startdate
      if [[ -f $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h1.zip.nc ]]
      then
           rm $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h1.zip.nc
      fi
      if [[ -d $DIR_ARCHIVE/$caso/lnd/hist//reg1x1/zip ]]
      then
           rmdir $DIR_ARCHIVE/$caso/lnd/hist//reg1x1/zip
      fi
      if [[ -d $DIR_ARCHIVE/$caso/lnd/hist//reg1x1 ]]
      then
           rmdir $DIR_ARCHIVE/$caso/lnd/hist/reg1x1
      fi
      for typecam in h1 h2 h3
      do
          if [[ -f $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.${typecam}.nc ]]
          then
             rm $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.${typecam}.nc
          fi
      done
      if [ ! -f $DIR_LOG/${typeofrun}/$startdate/${caso}_DMO_arch_ok ]
      then
         ${DIR_SPS35}/mv_case2archive.sh $caso            
      fi
      checkfile_daily=$FINALARCHC3S/$yyyy$st/qa_checker_daily_ok_${member}
      if [ ! -f ${checkfile_daily} ] || [[ $debug -eq 0 ]]
      then
         ${DIR_POST}/C3S_standard/launch_C3S_daily_mean.sh $st $yyyy $member $checkfile_daily $outdirC3S
      fi
      touch $check_allchecksC3S$member
   fi  
   allcheckersok=`ls ${check_allchecksC3S}??|wc -l`
   if [ $allcheckersok -ge $nrunC3Sfore ] 
   then
      ns=`${DIR_SPS35}/findjobs.sh -m $machine -r ${sla_serialID} -n submit_tar_and_push${startdate} -c yes`
      nt=`${DIR_SPS35}/findjobs.sh -m $machine -r ${sla_serialID} -n tar_and_push_${startdate} -c yes`
      if [ $ns -eq 0 ] && [ $nt -eq 0 ] 
      then
         body="$startdate forecast completed. \n
                          Now submitting submit_tar_and_push.sh"
         title="${SPSSYS} $startdate FORECAST COMPLETED"
	 ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
	 ${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_l -t "6" -r $sla_serialID -S qos_resv -j submit_tar_and_push${startdate} -l ${DIR_LOG}/$typeofrun/$startdate -d ${DIR_C3S} -s submit_tar_and_push.sh -i "${yyyy} $st"
      fi  
   fi  
# submit postprocessing for the 16 fields C3S we want to keep daily on /data
fi
echo "$0 completed"
exit 0
