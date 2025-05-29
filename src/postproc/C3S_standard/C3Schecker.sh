#!/bin/sh -l

#this script can be run in dbg mode but always using submitcommand

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

real=$1
outdirC3S=$2
startdate=$3
dir_cases=$4
member=$real #for dictionary consistency
yyyy=`echo ${startdate:0:4}`
set +uexv
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -uexv

dbg=0
cd $outdirC3S   #can be redundant
set +euvx
. $dictionary
set -euvx

st=`echo "${startdate}" | cut -c5-6`
#**********************************************************
# Load vars depending on hindcast/forecast
#**********************************************************
dir_log_checker=$SCRATCHDIR/C3Schecker/$typeofrun/$startdate/$real/
# try and do it everytime (if too slow add the exception)
if [[ -d $dir_log_checker ]]
then
   rm -rf $dir_log_checker
fi
mkdir -p $dir_log_checker
#if [ ! -f $outdirC3S/qa_checker_ok_0${real} ] 
#then
# if not already launched
#   ${DIR_C3S}/launch_c3s_qa_checker_1ens.sh $startdate $real $outdirC3S
#fi
# others checkers 
# try and do it everytime (if too slow add the exception)
${DIR_C3S}/launch_c3s-nc-checker.sh $startdate $real $outdirC3S $dir_log_checker

# BEFORE THIS AND ADD YOUR CHECKFILE INT THE IF CONDITION
# to be rewritten
#if [ ! -f $outdirC3S/dmoc3s_checker_ok_0${real} ]
#then 
#			${DIR_C3S}/launch_checkdmoC3S-pdf-chain.sh $startdate $real $outdirC3S
#fi
#cd $outdirC3S

if [ -f $check_c3s_meta_ok ] 
then
   title="C3S ${c3s_checker_cmd} ok for member $real"
   body="C3S ${c3s_checker_cmd} ok for member $real"
else
   title="[C3S ERROR] ${c3s_checker_cmd} KO for member $real"
   body="C3S ${c3s_checker_cmd} Ko for member $real"
 	 ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st -E 0$real
   exit
   
fi
$DIR_C3S/launch_c3s_qa_checker.sh $yyyy$st $real $outdirC3S $dir_cases
#if [ -f ${check_c3s_meta_ok} ] && [ -f $outdirC3S/dmoc3s_checker_ok_0${real} ] && [ -f $outdirC3S/qa_checker_ok_0${real} ] 
if [ -f ${check_c3s_meta_ok} ] && [ -f ${check_c3s_qa_ok} ]
then
#-------------------------------------------
# 20240919 ready to uncomment
#-------------------------------------------
# the following is defined in $dictionary
checkfile_daily=$SCRATCHDIR/wk_C3S_daily/$yyyy$st/C3S_daily_mean_2d_${member}_ok
   if [ ! -f ${checkfile_daily} ] || [[ $dbg -eq 0 ]]
   then
      ${DIR_POST}/C3S_standard/launch_C3S_daily_mean.sh $st $yyyy $member 
   fi
   touch $check_allchecksC3S$real
fi  
allcheckersok=`ls ${check_allchecksC3S}??|wc -l`
if [[ $typeofrun == "forecast" ]] 
then
  if [ $allcheckersok -ge $nrunC3Sfore ] 
  then
      ns=`${DIR_UTIL}/findjobs.sh -m $machine -n submit_tar_C3S${startdate} -c yes`
      nt=`${DIR_UTIL}/findjobs.sh -m $machine -n tar_C3S_${startdate} -c yes`
      if [ $ns -eq 0 ] && [ $nt -eq 0 ] 
      then
#         body="$startdate forecast completed. \n
#                       Now submitting submit_tar_C3S.sh"
         body="$startdate forecast completed. \n
                       $DIR_C3S/submit_tar_C3S.sh to be submitted manually!"
         title="${CPSSYS} $startdate FORECAST COMPLETED"
    	    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  #  	    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -S qos_resv -j submit_tar_C3S${startdate} -l ${DIR_LOG}/$typeofrun/$startdate -d ${DIR_C3S} -s submit_tar_C3S.sh -i "${yyyy} $st" 
      fi
  fi  
fi  
echo "$0 completed"
exit 0
