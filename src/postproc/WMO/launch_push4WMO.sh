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
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

user=`whoami`

dbg_push=$3

scriptname=$0
procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n $scriptname -c yes `
if [ $procsRUN -gt 1 ] ; then
   echo "$scriptname already running"
 		exit 0
fi		

# ---------------------------
# Parameters to be set by user
st=$1 #2 figures  # SET BY CRONTAB
isforecast=$2
if [ $isforecast -eq 1 ]
then
   iyy=`date +%Y`
   fyy=$iyy
else
   iyy=1993
   if [ $dbg_push -ge 1 ]
   then
      iyy=1993
      fyy=2022
   else
      fyy=2022
   fi
fi

if [ $dbg_push -ge 1 ] 
then
   mymail=andrea.borrelli@cmcc.it
   title_debug="TEST "
else
   title_debug=" "
fi
# ---------------------------
for yyyy in `seq $iyy $fyy` ; do

   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   if [ $debug_push -ge 1 ] 
   then
     mymail="sp1@cmcc.it"
     ccmail=$mymail
     body="launch_push4WMO.sh in dbg mode debug_push = $debug_push. Data push to cmcc ftp"
   else
     ccmail=$mymail
     body="launch_push4WMO.sh. Data push to cmcc ftp"
   fi
   title=${title_debug}"[WMO] ${SPSSystem} warning"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st
   firstdtn03=$DIR_LOG/${typeofrun}/$yyyy$st/first_wmo_${yyyy}${st}
#--------------------------------------------------------------------
# Check if it is possible to send another  year
#--------------------------------------------------------------------
   filedone=push_WMO_${yyyy}${st}_DONE
   if [ $dbg_push -ge 1 ]
   then
      filedone=test_WMO_${yyyy}${st}_DONE
   fi
  	anypushC3SDONE=`ls -1 $DIR_LOG/${typeofrun}/$yyyy$st/$filedone | wc -l`
  	if [ $anypushC3SDONE -gt 0 ] ; then
# already pushed: go on with following hindcasts
    		continue
  	fi
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#check if there are transfer processes running and if so exit
#--------------------------------------------------------------------
  	procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -c yes `
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -i yes `
  	if [ $procsRUN -gt 0 ] ; then
# if another push running check how long it has being running for
      startY_proc=`${DIR_UTIL}/findjobs.sh -m $machine -Y $jobID `
      startd_proc=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -d yes`
      startm_proc=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -M yes`
      starth_proc=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -W yes -H yes`
      today=`date +%Y%m%d%H`
      today_in_sec=$(date -d "$today" +%s)
      startdate_in_sec=$(date -d "${startY_proc}${startm_proc}${startd_proc}${starth_proc}" +%s)
      elapsedh=$(((today_in_sec - startdate_in_sec)/86400))
      if [ $elapsedh -gt 4 ]
      then
         if [ $dbg_push -eq 0 ]
         then
            body="elapsed hours $elapsedh for push4WMO_${yyyy}${st}. Too much. Going to kill it"
  	         title=${title_debug}"[WMO] ${SPSSystem} ${typeofrun} warning"
           	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail
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

  	body="WMO: Begin of the start-date $yyyy$st transfer on WMO server"
   cntfirst=`ls $firstdtn03 |wc -l `
   if [ $cntfirst -eq 1 ]
   then
      body="WMO: successive attempt of the start-date $yyyy$st transfer on WMO server"
   fi
  	title=${title_debug}"[WMO] ${SPSSystem} ${typeofrun} notification"
  	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail

# Submit push over WMO ftp
  	input="${yyyy} ${st} $dbg_push $filedone $firstdtn03"
  	mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
  	${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_POST}/WMO/ -q ${serialq_push} -j push4WMO_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4WMO.sh -i "$input"

   ic=0
   while `true`; do
       echo "sleeping 5' from now "`date`
       sleep 300 # 
       ic=$(( $ic + 1 ))
       anypushC3SDONE=`ls -1 $DIR_LOG/${typeofrun}/$yyyy$st/$filedone | wc -l`
       if [ $anypushC3SDONE -eq 1 ] ; then          
          break
       fi
# after 40 minutes kill the process and relaunch
       if [ $ic -eq 8 ]
       then
          ic=0
          if [ $anypushC3SDONE -eq 0 ] ; then          
# meaning transfer not completed
             procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -c yes `
             if [ $procsRUN -ne 0 ] ; then
# meaning push still running --> too much! kill and resubmit
                jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n push4WMO_${yyyy}${st} -i yes `
                bkill $jobID
             fi
  	          body="WMO: tentativo successivo di trasferimento della start-date $yyyy$st su server wmo"
  	          eitle="[WMO] ${SPSSystem} ${typeofrun} notification"
            	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail
             ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_POST}/WMO/ -q ${serialq_push} -j push4WMO_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4WMO.sh -i "$input"
          fi
       fi
   done

done    #loop on hindcasts
echo "That's all folk's"
exit 0
