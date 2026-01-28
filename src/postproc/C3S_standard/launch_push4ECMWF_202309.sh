#!/bin/sh -l
#--------------------------------
# SET INPUT VARIABLE BY CRONTAB  !!!!!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

scriptname=`basename $0 | rev | cut -d '.' -f2 | rev`
procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n launch_push4ECMWF -c yes `
if [[ $procsRUN -gt 1 ]] ; then
   echo "$scriptname already running"
   exit 0
fi		

set +euvx
# set descriptor to hindcast using 1993 not to mess up with previous 
# contract (C3S2_370) reforecast period ending at 2022
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx
# ---------------------------
# Parameters to be set by user
iyy=2023 
fyy=2023
#for st in {01..12}
for st in 09
do #2 figures 
# ---------------------------
   for yyyy in `seq $iyy $fyy` ; do

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
      set +euvx
      . ${dictionary}
      set -euvx
      filedone=$check_push_done
      if [[ $debug_push -ge 1 ]]
      then
         filedone=$DIR_LOG/${typeofrun}/$yyyy$st/test_${yyyy}${st}_DONE
      fi
      cmd_anypushC3SDONE="ls $filedone | wc -l"
      anypushC3SDONE=`eval $cmd_anypushC3SDONE`
      if [[ $anypushC3SDONE -gt 0 ]] ; then
# already pushed: go on with following hindcasts
        	continue
      fi
      if [[ ! -f $check_tar_done ]] ; then
       
           body="Missing ${check_tar_done} push4ECMWF going on for the following year"
           title="[C3S] ${SPSSystem} ${typeofrun} warning"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
           continue
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
      cntfirst=`ls $firstdtn03 |wc -l `
      if [[ $cntfirst -eq 1 ]]
      then
         body="C3S: successive attempt of the start-date $yyyy$st transfer on acq.ecmwf.int"
      fi
      title="[C3S] ${SPSSystem} ${typeofrun} notification"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail

# Submit push over ECMWF ftp
      input="${yyyy} ${st} $debug_push $filedone $firstdtn03"
      mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
      ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF_202309.sh -i "$input"
      
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
                ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j push4ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4ECMWF_202309.sh -i "$input"
             fi
          fi
      done
   exit #exit after one year completed 
   done
done    #loop on hindcasts
echo "That's all folk's"
exit 0
