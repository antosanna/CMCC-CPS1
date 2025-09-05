#!/bin/sh -l
#--------------------------------

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_POST}/APEC/descr_SPS4_APEC.sh

set -euvx

scriptname=$0
procsRUN=`${DIR_UTIL}/findjobs.sh -m $machine -n $scriptname -c yes `
if [ $procsRUN -gt 1 ] ; then
   echo "$scriptname already running"
   exit 0
fi

st=11 #2 figures  # SET BY CRONTAB
isforecast=0
dbg_push=0   # operational=0 

if [ $isforecast -eq 1 ] 
then
   iyy=`date +%Y`
   fyy=$iyy
else
   iyy=1993
   if [ $dbg_push -eq 1 ] 
   then
      iyy=1998
      fyy=2022
   else
      fyy=2022
   fi  
fi

if [ $dbg_push -eq 1 ]
then
   mymail=andrea.borrelli@cmcc.it
   ccmail=$mymail
   title_debug="TEST "
else
   ccmail=$mymail
   title_debug=" "
fi

# ---------------------------
for yyyy in `seq $iyy $fyy` ; do

    . ${DIR_UTIL}/descr_ensemble.sh $yyyy

    nfdone=`ls -1 ${DIR_LOG}/${typeofrun}/${yyyy}${st}/push_${yyyy}${st}_APEC_DONE | wc -l`
    if [ $nfdone -eq 0 ]
    then
       
       body=${title_debug}"APEC: Starting of data transfer ${yyyy}${st}"
       title=${title_debug}"[APEC] ${SPSSystem} ${typeofrun} notification"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -s $yyyy$st -r yes -c $ccmail

       njsd=`${DIR_UTIL}/findjobs.sh -m $machine -q $serialq_push -c yes`
       if [ $njsd -lt 4 ] 
       then
          queue=$serialq_push
       else
          queue=$serialq_s
       fi
# Submit push over APEC ftp	
       input="${yyyy} ${st} ${typeofrun} ${dbg_push} $isforecast"
       ${DIR_UTIL}/submitcommand.sh -M 1000 -m $machine -d $DIR_POST/APEC -q $queue -n 1 -j push4APEC_${yyyy}${st} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st}/ -s push4APEC.sh -i "$input"

       while `true` ; do
	         sleep 5
	         njobs=`${DIR_UTIL}/findjobs.sh -m $machine -q $queue -n "push4APEC_"  -c yes`

	         if [ ${njobs} -eq 0 ]; then
        	   	break
	         fi  
       done
    fi
done

sleep 1

exit 0
