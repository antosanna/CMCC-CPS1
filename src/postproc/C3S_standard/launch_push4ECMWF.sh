#!/bin/sh -l
#--------------------------------
# SET INPUT VARIABLE BY CRONTAB  !!!!!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

scriptname=`basename $0 | rev | cut -d '.' -f2 | rev`
procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n $scriptname -c yes `
if [[ $procsRUN -gt 1 ]] ; then
   echo "$scriptname already running"
   exit 0
fi		

# ---------------------------
# Parameters to be set by user
st=$1 #2 figures  # SET BY CRONTAB
isforecast=$2
if [[ $isforecast -eq 1 ]]
then
   iyy=`date +%Y`
   fyy=$iyy
else
   iyy=1993 
   fyy=2022
fi
# ---------------------------
for yyyy in `seq $iyy $fyy` ; do

set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   . ${dictionary}
set -euvx
   if [[ $debug_push -ge 1 ]]
   then
     mymail="sp1@cmcc.it"
     ccmail=$mymail
     body="launch_push4ECMWF.sh in dbg mode debug_push = $debug_push. Data push to cmcc ftp"
     title="[C3S] ${SPSSystem} warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st
   else
     ccmail=$mymail
   fi
   firstdtn03=$DIR_LOG/${typeofrun}/$yyyy$st/first_${yyyy}${st}
#--------------------------------------------------------------------
# Check if it is possible to send another  year
#--------------------------------------------------------------------
   if [[ "$machine" == "juno" ]]
   then
      filedone=$check_push_done
      if [[ $debug_push -ge 1 ]]
      then
         filedone=$DIR_LOG/${typeofrun}/$yyyy$st/test_${yyyy}${st}_DONE
      fi
      cmd_anypushC3SDONE="ls $filedone | wc -l"
   elif [[ "$machine" == "leonardo" ]]
   then
      filedone=$check_push_done
      if [[ $debug_push -ge 1 ]]
      then
         filedone=$DIR_LOG/${typeofrun}/$yyyy$st/test_${yyyy}${st}_DONE
      fi
      cmd_anypushC3SDONE="ls $filedone | wc -l"
   fi
   anypushC3SDONE=`eval $cmd_anypushC3SDONE`
   if [[ $anypushC3SDONE -gt 0 ]] ; then
# already pushed: go on with following hindcasts
     	continue
   fi
   if [[ ! -f $check_tar_done ]] ; then
       
       if [[ ${typeofrun} == "hindcast" ]] ; then
           body="Missing ${check_tar_done} push4ECMWF going on for the following year"
           title="[C3S] ${SPSSystem} ${typeofrun} warning"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
           continue
       else
           body="Missing ${check_tar_done}. launch_push4ECMWF exiting now."
           title="[C3S] ${SPSSystem} ${typeofrun} error"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun 
           exit
       fi
   fi
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#check if there are transfer processes running and if so exit
#--------------------------------------------------------------------
   procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_${yyyy}${st} -c yes `
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_${yyyy}${st} -i yes `
   if [[ $procsRUN -gt 0 ]] ; then
# if another push running check how long it has being running for
      elapsedh=`${DIR_UTIL}/findjobs.sh -m $machine -d $jobID`
      if [[ $elapsedh -gt 4 ]]
      then
         if [[ $debug_push -eq 0 ]]
         then
            body="elapsed hours $elapsedh for push4ECMWF_${yyyy}${st}. Too much. Going to kill it"
  	         title="[C3S] ${SPSSystem} ${typeofrun} warning"
           	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
            $DIR_UTIL/killjobs.sh -m $machine -i $jobID
         fi
      else
# else exit from launcher
         echo "jobID $jobID"
         echo "elapsed hours $elapsedh"
         echo "push4ECMWF already running"
	        exit 0
      fi		
   fi		
#--------------------------------------------------------------------

   body="C3S: Begin of the start-date $yyyy$st transfer on acq.ecmwf.int"
   if [[ "$machine" == "juno" ]]
   then
      cntfirst=`ls $firstdtn03 |wc -l `
   elif [[ "$machine" == "leonardo" ]]
   then
      cntfirst=`ls $firstdtn03 |wc -l `
   fi
   if [[ $cntfirst -eq 1 ]]
   then
      body="C3S: successive attempt of the start-date $yyyy$st transfer on acq.ecmwf.int"
   fi
   title="[C3S] ${SPSSystem} ${typeofrun} notification"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail

# Submit push over ECMWF ftp
   input="${yyyy} ${st} $debug_push $filedone $firstdtn03"
   mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
   #if [[ $debug_push -eq 0 ]]
   #then
      if [[ "$machine" == "juno" ]]
      then
         ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
      else
         ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -t 4 -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
      fi
   #else
      
  #    ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
   #fi
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
             procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_${yyyy}${st} -c yes `
             if [[ $procsRUN -ne 0 ]] ; then
# meaning push still running --> too much! kill and resubmit
                jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4ECMWF_${yyyy}${st} -i yes `
                $DIR_UTIL/killjobs.sh -m $machine -i $jobID
             fi
  	          body="C3S: Successive attempt of the start-date $yyyy$st transfer on acquisition.ecmwf.int"
  	          title="[C3S] ${SPSSystem} ${typeofrun} notification"
            	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
     #        if [[ $debug_push -eq 0 ]]
     #        then
             if [[ "$machine" == "juno" ]]
             then
                ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
             else
                ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -t 4 -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
             #else
             #   ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF.sh -i "$input"
             fi
          fi
       fi
   done
   exit #exit after one year completed 

done    #loop on hindcasts
echo "That's all folk's"
exit 0
