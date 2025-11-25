#!/bin/sh -l
#--------------------------------
# SET INPUT VARIABLE BY CRONTAB  !!!!!

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

scriptname=`basename $0 | rev | cut -d '.' -f2 | rev`
procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n $scriptname -c yes `
if [ $procsRUN -gt 1 ] ; then
   echo "$scriptname already running"
   exit 0
fi		

# ---------------------------
# Parameters to be set by user
#st=$1 #2 figures  # SET BY CRONTAB
#isforecast=$2
st=$1 #2 figures  # SET BY CRONTAB
dbg=$2    # send only one st-date
debug_push=0    #do not re-send if stuck
if [ $dbg -eq 1 ]
then
   iyy=2019
   fyy=$iyy
else
   iyy=2002
   fyy=2021
fi
# ---------------------------
ccmail=$mymail
for yyyy in `seq $iyy $fyy` ; do

set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   . ${dictionary}
set -euvx
   if [ $debug_push -ge 1 ]
   then
     mymail="sp1@cmcc.it"
     body="launch_pushCERISE2ECMWF.sh in dbg mode debug_push = $debug_push. Data push to cmcc ftp"
     title="[CERISE] ${SPSSystem} warning"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st
   fi
   firstdtn03=$DIR_LOG/${typeofrun}/$yyyy$st/first_CERISE_phase2_${yyyy}${st}
#--------------------------------------------------------------------
# Check if it is possible to send another  year
#--------------------------------------------------------------------
   filedone=$check_push_done
   cmd_anypushC3SDONE="ls $filedone | wc -l"
   anypushC3SDONE=`eval $cmd_anypushC3SDONE`
   if [ $anypushC3SDONE -gt 0 ] ; then
# already pushed: go on with following hindcasts
     	continue
   fi
   if [[ ! -f $check_tar_done ]] ; then
       
           body="Missing ${check_tar_done} pushCERISE2ECMWF going on for the following year"
           title="[CERISE] ${SPSSystem} ${typeofrun} warning"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun
           continue
   fi
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#check if there are transfer processes running and if so exit
#--------------------------------------------------------------------
   procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n pushCERISE2ECMWF_${yyyy}${st} -c yes `
   jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n pushCERISE2ECMWF_${yyyy}${st} -i yes `
   if [ $procsRUN -gt 0 ] ; then
# if another push running check how long it has being running for
      elapsedh=`${DIR_UTIL}/findjobs.sh -m $machine -d $jobID`
      if [ $elapsedh -gt 4 ]
      then
         if [ $debug_push -eq 0 ]
         then
            body="elapsed hours $elapsedh for pushCERISE2ECMWF_${yyyy}${st}. Too much. Going to kill it"
  	         title="[CERISE] ${SPSSystem} ${typeofrun} warning"
           	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
            $DIR_UTIL/killjobs.sh -m $machine -i $jobID
         fi
      else
# else exit from launcher
         echo "jobID $jobID"
         echo "elapsed hours $elapsedh"
         echo "pushCERISE2ECMWF already running"
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
   input="${yyyy} ${st} $debug_push $filedone $firstdtn03"
   mkdir -p ${DIR_LOG}/${typeofrun}/${yyyy}${st}
   ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j pushCERISE2ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s pushCERISE2ECMWF.sh -i "$input"
   ic=0
   while `true`; do
      # each 15' look for $filedone
       sleep 900 # 
       ic=$(( $ic + 1 ))
       anypushC3SDONE=`eval $cmd_anypushC3SDONE`
       if [ $anypushC3SDONE -eq 1 ] ; then          
          break
       fi
# after 4 hours kill the process and relaunch
       if [ $ic -eq 16 ]
       then
          ic=0
          if [ $anypushC3SDONE -eq 0 ] ; then          
# meaning transfer not completed
             procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n pushCERISE2ECMWF_${yyyy}${st} -c yes `
             if [ $procsRUN -ne 0 ] ; then
# meaning push still running --> too much! kill and resubmit
                jobID=`${DIR_UTIL}/findjobs.sh -m $machine -n pushCERISE2ECMWF_${yyyy}${st} -i yes `
                $DIR_UTIL/killjobs.sh -m $machine -i $jobID
             fi
  	          body="CERISE: Successive attempt of the start-date $yyyy$st transfer on acquisition.ecmwf.int"
  	          title="[CERISE] ${SPSSystem} ${typeofrun} notification"
            	${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r $typeofrun -c $ccmail
                ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_C3S} -q ${serialq_push} -j pushCERISE2ECMWF_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s pushCERISE2ECMWF.sh -i "$input"
          fi
       fi
   done
   exit #exit after one year completed 

done    #loop on hindcasts
echo "That's all folk's"
exit 0
