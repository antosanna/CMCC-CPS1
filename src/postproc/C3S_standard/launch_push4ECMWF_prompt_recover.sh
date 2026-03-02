#!/bin/sh -l
#--------------------------------
# SET INPUT VARIABLE BY CRONTAB  !!!!!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

LOG_FILE=$DIR_LOG/hindcast/launch_push4ECMWF_prompt_recover.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
scriptname=`basename $0 | rev | cut -d '.' -f2 | rev`
if [[ `bjobs |grep s_download|wc -l` -ne 0 ]]
then
   exit
fi
flagfile=$SCRATCHDIR/tmp_CERISE/launch_push_started
if [[ -f $flagfile ]]
then
   exit
fi
touch $flagfile

# ---------------------------
# Parameters to be set by user
# ---------------------------
#listofcases="sps4_201408_002 sps4_201608_004 sps4_201708_006 sps4_201708_024 sps4_202008_004 sps4_202008_007 sps4_202108_024"
listofcases="sps4_201608_004 sps4_201708_006 sps4_201708_024 sps4_202008_004 sps4_202008_007 sps4_202108_024"
for caso in $listofcases ; do
  yyyy=`echo $caso |cut -d '_' -f2|cut -c 1-4`
  st=`echo $caso |cut -d '_' -f2|cut -c 5-6`
  mem=`echo $caso |cut -d '_' -f3|cut -c 2-3`

set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   . ${dictionary}
set -euvx
   check_tar_done=$pushdir/recover/tar_CERISE_phase2_${yyyy}${st}_recover_${mem}_DONE
   if [[ $debug_push -ge 1 ]]
   then
     mymail="sp1@cmcc.it"
     ccmail=$mymail
     body="launch_push4ECMWF.sh in dbg mode debug_push = $debug_push. Data push to cmcc ftp"
     title="[CERISE] ${SPSSystem} warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st
   else
     ccmail=$mymail
   fi
   firstdtn03=$DIR_LOG/${typeofrun}/$yyyy$st/first_CERISE_phase2_${yyyy}${st}_recover_${mem}
#--------------------------------------------------------------------
# Check if it is possible to send another  year
#--------------------------------------------------------------------
   filedone=$check_push_done_mem
   cmd_anypushC3SDONE="ls $filedone | wc -l"
   anypushC3SDONE=`eval $cmd_anypushC3SDONE`
   if [[ $anypushC3SDONE -gt 0 ]] ; then
# already pushed: go on with following hindcasts
     	continue
   fi
   if [[ ! -f $check_tar_done ]] ; then
       
       if [[ ${typeofrun} == "hindcast" ]] ; then
           body="Missing ${check_tar_done} push4ECMWF_recover.sh going on for the following year"
           title="[CERISE] ${SPSSystem} ${typeofrun} warning"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
           continue
       else
           body="Missing ${check_tar_done}. launch_push4ECMWF exiting now."
           title="[CERISE] ${SPSSystem} ${typeofrun} error"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun 
           exit
       fi
   fi
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#check if there are transfer processes running and if so exit
#--------------------------------------------------------------------
   procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_recover_${yyyy}${st}_${mem} -c yes `
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_recover_${yyyy}${st}_${mem} -i yes `
   if [[ $procsRUN -gt 0 ]] ; then
# if another push running check how long it has being running for
      elapsedh=`${DIR_UTIL}/findjobs.sh -m $machine -d $jobID`
      if [[ $elapsedh -gt 2 ]]
      then
         if [[ $debug_push -eq 0 ]]
         then
            body="elapsed hours $elapsedh for push4ECMWF_recover_${yyyy}${st}_${mem}. Too much. Going to kill it"
  	         title="[CERISE] ${SPSSystem} ${typeofrun} warning"
           	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
            $DIR_UTIL/killjobs.sh -m $machine -i $jobID
         fi
      else
# else exit from launcher
         echo "jobID $jobID"
         echo "elapsed hours $elapsedh"
         echo "push4ECMWF_recover.sh already running"
	        exit 0
      fi		
   fi		
#--------------------------------------------------------------------

   body="CERISE: Begin of the start-date $yyyy$st transfer on acq.ecmwf.int"
   cntfirst=`ls $firstdtn03 |wc -l `
   if [[ $cntfirst -eq 1 ]]
   then
      body="CERISE: successive attempt of the start-date $yyyy$st transfer on acq.ecmwf.int"
   fi
   title="[CERISE] ${SPSSystem} ${typeofrun} notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail

# Submit push over ECMWF ftp
   input="${yyyy} ${st} $debug_push $filedone $firstdtn03 $mem"
   mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
   ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_recover_${yyyy}${st}_${mem} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF_recover.sh -i "$input"
      
   ic=0
   while `true`; do
      # each 15' look for $filedone
       sleep 900 # 
       ic=$(( $ic + 1 ))
       anypushC3SDONE=`eval $cmd_anypushC3SDONE`
       if [[ $anypushC3SDONE -eq 1 ]] ; then          
          break
       fi
# after 1.5 hours kill the process and relaunch
       if [[ $ic -eq 6 ]]
       then
          ic=0
          if [[ $anypushC3SDONE -eq 0 ]] ; then          
# meaning transfer not completed
             procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_recover_${yyyy}${st}_${mem} -c yes `
             if [[ $procsRUN -ne 0 ]] ; then
# meaning push still running --> too much! kill and resubmit
                jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_recover_${yyyy}${st}_${mem} -i yes `
                $DIR_UTIL/killjobs.sh -m $machine -i $jobID
             fi
  	          body="CERISE: Successive attempt of the start-date $yyyy$st transfer on acquisition.ecmwf.int"
  	          title="[CERISE] ${SPSSystem} ${typeofrun} notification"
            	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
             ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_recover_${yyyy}${st}_${mem} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF_recover.sh -i "$input"
          fi
       fi
   done

done    #loop on hindcasts
echo "That's all folk's"
rm $flagfile
exit 0
