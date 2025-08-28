#!/bin/sh -l
#--------------------------------
## No need for bsub header, we launch it from crontab, with submitcommand.sh
#BSUB -q s_long
#BSUB -n 1
#BSUB -o ../../logs/launch_push4WMO.%J.out
#BSUB -e ../../logs/launch_push4WMO.%J.err
#BSUB -J launch_push4WMO
#BSUB -P 0490

# SET INPUT VARIABLE BY CRONTAB  !!!!!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh

set -euvx
debug=0
if [[ $debug -ge 1 ]]
then
  mymail=andrea.borrelli@cmcc.it
  ccmail=$mymail
  DIR_C3S=/users_home/csp/sp2/SPS/CMCC-${SPSSYS}/work/ANDREA/APEC
else
  ccmail=$mymail
fi

scriptname=$0
procsRUN=`${DIR_SPS35}/findjobs.sh -m $machine -n $scriptname -c yes `
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
   if [[ $debug -eq 1 ]]
   then
      iyy=2016 
   fi
   fyy=2016
fi
# ---------------------------
for yyyy in `seq $iyy $fyy` ; do
   firstdtn03=first_${yyyy}${st}

  	if [[ $yyyy -lt $iniy_fore ]] ; then
    		. ${DIR_SPS35}/descr_hindcast.sh
  	else
    		. ${DIR_SPS35}/descr_forecast.sh
  	fi
#--------------------------------------------------------------------
# Check if it is possible to send another  year
#--------------------------------------------------------------------
   filedone=push_${yyyy}${st}_DONE
   if [[ $debug -ge 1 ]]
   then
      filedone=test_${yyyy}${st}_DONE
   fi
  	anypushC3SDONE=`rsync -auv sp2@dtn03: | grep $filedone | awk '{print $5}' | wc -l`
  	if [[ $anypushC3SDONE -gt 0 ]] ; then
# already pushed: go on with following hindcasts
    		continue
  	fi
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#check if there are transfer processes running and if so exit
#--------------------------------------------------------------------
  	procsRUN=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -c yes `
   jobID=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -i yes `
  	if [[ $procsRUN -gt 0 ]] ; then
# if another push running check how long it has being running for
      startY_proc=`${DIR_SPS35}/findjobs.sh -m $machine -Y $jobID `
      startd_proc=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -d yes`
      startm_proc=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -M yes`
      starth_proc=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -H yes`
      today=`date +%Y%m%d%H`
      today_in_sec=$(date -d "$today" +%s)
      startdate_in_sec=$(date -d "${startY_proc}${startm_proc}${startd_proc}${starth_proc}" +%s)
      elapsedh=$(((today_in_sec - startdate_in_sec)/86400))
      if [[ $elapsedh -gt 4 ]]
      then
         if [[ $debug -eq 0 ]]
         then
            body="elapsed hours $elapsedh for push4WMO_${yyyy}${st}. Too much. Going to kill it"
  	         title="[WMO] ${SPSSYS} ${typeofrun} warning"
           	${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail
            $DIR_UTIL/killjobs.sh -m $machine -i $jobID
         fi
      else
# else exit from launcher
         echo "jobID $jobID"
         echo "elapsed hours $elapsedh"
         echo "push4WMO already running"
     	  	exit 0
  	   fi		
  	fi		
#--------------------------------------------------------------------

  	body="WMO: Inizia il trasferimento della start-date $yyyy$st su server wmo"
   cntfirst=`ssh sp2@dtn03 "ls $firstdtn03 |wc -l" `
   if [[ $cntfirst -eq 1 ]]
   then
      body="WMO: tentativo successivo di trasferimento della start-date $yyyy$st su server wmo"
   fi
  	title="[WMO] ${SPSSYS} ${typeofrun} notification"
  	${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail

# Submit push over WMO ftp
  	input="${yyyy} ${st} $debug $filedone"
  	mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
  	${DIR_SPS35}/submitcommand.sh -m $machine -d ${DIR_C3S} -q $serialq_l -j push4WMO_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4WMO.sh -i "$input"

   ic=0
   while `true`; do
      # each 30' look for $filedone
       echo "sleeping 30' from now "`date`
       sleep 1800 # 
       ic=$(( $ic + 1 ))
       anypushC3SDONE=`rsync -auv sp2@dtn03: | grep $filedone | awk '{print $5}' | wc -l`
       if [[ $anypushC3SDONE -eq 1 ]] ; then          
          break
       fi
# after 40 minutes kill the process and relaunch
       if [[ $ic -eq 8 ]
       then
          ic=0
          if [[ $anypushC3SDONE -eq 0 ]] ; then          
# meaning transfer not completed
             procsRUN=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -c yes `
             if [[ $procsRUN -ne 0 ]] ; then
# meaning push still running --> too much! kill and resubmit
                jobID=`${DIR_SPS35}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -i yes `
                bkill $jobID
             fi
  	          body="WMO: tentativo successivo di trasferimento della start-date $yyyy$st su server wmo"
  	          title="[WMO] ${SPSSYS} ${typeofrun} notification"
            	${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail
             ${DIR_SPS35}/submitcommand.sh -m $machine -d ${DIR_C3S} -q $serialq_l -j push4WMO_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4WMO.sh -i "$input"
          fi
       fi
   done

done    #loop on hindcasts
echo "That's all folk's"
exit 0
