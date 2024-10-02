#!/bin/sh -l
#--------------------------------
## No need for bsub header, we launch it from launch_push4ECMWF, with submitcommand.sh

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_POST}/APEC/descr_SPS4_APEC.sh

set -evx

yyyy=$1
st="$2"
type_fore=$3
dbg_push=$4

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

usermail=andrea.borrelli@cmcc.it
if [ $dbg_push -eq 0 ] ;then
   apecmail=cmlim@apcc21.org
else
   apecmail=$usermail
   mymail=$usermail
fi

cd $pushdirapec/${type_fore}/${yyyy}${st}

localuser=`whoami`
${DIR_POST}/APEC/send_to_APEC.sh $yyyy $st $type_fore $dbg_push

npushdone=`ls -1 $DIR_LOG/${type_fore}/${yyyy}${st}/push_${yyyy}${st}_APEC_DONE | wc -l`
if [ $npushdone -eq 1 ] ; then

#AT LAST SEND notification both to sp1 and to APEC
   title="CMCC-SPS3.5 data-transfer to APCC completed"
   body="Dear Chang-Mook, \n \n this is to notify the completion of CMCC-SPS3.5 ${type_fore} start-date ${yyyy}${st}01 transfer to your ftp server. \n \n Many thanks for your cooperation,\n CMCC-SPS staff \n"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $apecmail -M "$body" -t "$title" -s $yyyy$st -r yes -c $mymail -b $usermail

else

	  while `true` ; do
 
		     sleep 300
   		  npushdone=`ls -1 $DIR_LOG/${type_fore}/${yyyy}${st}/push_${yyyy}${st}_APEC_DONE | wc -l`
	     	if [ $npushdone -eq 1 ] ; then
		       	break
		     fi
       ${DIR_POST}/APEC/send_to_APEC.sh $yyyy $st ${type_fore} $dbg_push
	  done 
fi
