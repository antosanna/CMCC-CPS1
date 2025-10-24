#!/bin/sh -l
#--------------------------------
## No need for bsub header, we launch it from launch_push4WMO, with submitcommand.sh
# MANCA IL LOG DEL RM

#NEW 202103: tolta ccmail e definita ccwmomail e tolto un commento
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_POST/APEC/descr_SPS4_APEC.sh

set -euvx

check_status(){
stat=$1
script1=$2
if [[ $stat -ne 0 ]]
then
   title="${title_debug}[WMO] ${SPSSystem} ERROR"
   body="Error in ${script1}. Exiting from $DIR_POST/WMO/push4WMO.sh. Log in ${DIR_LOG}/${typeofrun}/${yyyy}${st}/"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit 1
fi
}
yyyy=$1
st=$2
dbg_push=$3
filedone=$4
firstdtn03=$5
user=`whoami`
list2rm=""

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

if [[ $dbg_push -ge 1 ]]
then
   mymail=andrea.borrelli@cmcc.it
   wmomail=$mymail
   ccwmomail=$mymail
   title_debug="TEST "
else
   if [[ $typeofrun = "forecast" ]] ; then
      wmomail="lc_lrfmme@korea.kr"
      ccwmomail="wslee@apcc21.org,asteria1104@apcc21.org"
   else
      mymail=sp1@cmcc.it
      wmomail=$mymail
      ccwmomail=$mymail
   fi
   title_debug=""
fi
DIR_WMO="${DIR_POST}/WMO"


# check files

title="${title_debug}[WMO] ${SPSSystem} forecast notification"
body="push4WMO.sh for startdate $yyyy$st started `date` "

cntfirst=`ls $firstdtn03 |wc -l`
if [[ $cntfirst -eq 1 ]]
then
   body="Successive attempt push4WMO.sh for startdate $yyyy$st started `date` "
fi
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 

start_date=$yyyy$st
cd $pushdirapec/${typeofrun}/$start_date/monthly
#
# Check if there is some old manifest file and remove
set +euvx
nf=`ls -1 cmcc*manifest*txt | wc -l`
set -euvx
if [[ $nf -ne 0 ]] ; then
   rm cmcc*manifest*txt
fi
# 

nfieldsWMO=20   #it should be 21 - not used???
nchunks=6
nrun=$nrunC3Sfore

# PROCEDURE TO PUSH FILES TO server wmo
ntar=$(($nfieldsWMO * $nchunks * $nrun)) #1 per 2d var e 5 per 3d var=136 in hindcast and 146 in forecast
ntarandsha=$ntar

cntfirst=`ls $firstdtn03 |wc -l`
if [[ $cntfirst -eq 1 ]]
then
# from the second launch it checks if there are still appended processes 
   $DIR_WMO/ls_ftp_wmo.sh $yyyy $st $mymail $typeofrun $dbg_push 
   stat=$?
   check_status $stat ${DIR_WMO}/ls_ftp_wmo.sh 
# NOW CHECK DIMS
# do check dimensions of transferred files
   cd $pushdirapec/${typeofrun}/${start_date}/monthly
   listafiles=`ls *nc.gz`
   for file in $listafiles
   do
      localdim=`ls -l $file|awk '{print $5}'`
      isremotepresent=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/ls_WMO_S${yyyy}${st}.log|wc -l`
      if [[ $isremotepresent -ne 0 ]] 
      then 
         remotedim=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/ls_WMO_S${yyyy}${st}.log|awk '{print $5}'`
         if [[ $localdim -ne $remotedim ]]
         then
            echo "ACHTUNG!!! this file $file was not correctly transferred!!
original dimension $localdim, transferred dimension $remotedim. check it"
            list2rm+=" $file"
         fi
      fi
   done
#  eseguire la rimozione di $list2rm sul sito ftp
   if [[ `echo $list2rm |wc -w` -ne 0 ]]
   then
      $DIR_WMO/rm_ftp_wmo.sh $yyyy $st $mymail "$list2rm" $dbg_push $typeofrun
      stat=$?
      check_status $stat ${DIR_WMO}/rm_ftp_wmo.sh 
   fi
fi
# do the first send with mirror;send_to_wmo.`date +%Y%m%d%H%M%S`.log will be output
# al secondo tentativo cancella i file incompleti
# e ricomincia da capo
$DIR_WMO/send_to_wmo.sh $yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push | tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_wmo.`date +%Y%m%d%H%M%S`.log
stat=$?
check_status $stat "sh send_to_wmo.sh"

# Check if the files pushed are as expected
nline=`cat $DIR_LOG/$typeofrun/$yyyy$st/ls_WMO_S${yyyy}${st}.log | wc -l`
if [[ $nline -lt $ntarandsha ]] ; then
   title=${title_debug}"[WMO] ${SPSSystem} ERROR"
   body="send_to_wmo.sh (${DIR_WMO}): $nline file sent instead of the $ntarandsha expected"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit 1
fi
# END OF PROCEDURE TO PUSH FILES TO server wmo

#create manifest file
echo `pwd`
suffixdate=`date +%Y%m%d`"_"`date +%H%M%S`".txt"
listaofsha=`ls -1 CMCC_SPS_${yyyy}${st}_*.nc*`
#
for file in ${listaofsha}
do
   cat $file >> CMCC_SPS_${yyyy}${st}0100_manifest_${suffixdate}
done


# AT LAST SEND manifest TO server wmo ;send_to_wmo.`date +%Y%m%d%H%M%S`.log will be output
#sh send_to_wmo.sh $yyyy $st $mymail $typeofrun AGGIUNTO IN INPUT ntarandsha (qui solo il manifest file conclusivo)
ntarandsha=1
$DIR_WMO/send_to_wmo.sh $yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push | tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_wmo.`date +%Y%m%d%H%M%S`.log
stat=$?
check_status $stat "mirroring manifest" 

# Verify that all files are present in push logs (manifest included)
cd $DIR_LOG/$typeofrun/$yyyy$st
cntmanifest=`grep CMCC_SPS_${yyyy}${st}0100_manifest_${suffixdate} ls_WMO_S${yyyy}${st}.log|wc -l`

if [[ $cntmanifest -ne 1 ]]; then
# last attempt to send manifest TO server wmo; send_to_wmo.`date +%Y%m%d%H%M%S`.log will be output
$DIR_WMO/send_to_wmo.sh $yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push | tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_wmo.`date +%Y%m%d%H%M%S`.log
stat=$?
check_status $stat "mirroring manifest" 
# Verify that all files are present in push logs (manifest included)

fi
cntmanifest=`grep CMCC_SPS_${yyyy}${st}0100_manifest_${suffixdate} ls_WMO_S${yyyy}${st}.log|wc -l`
if [[ $cntmanifest -ne 1 ]]; then
   # Raise error
   title=${title_debug}"[WMO] ${SPSSystem} ERROR"
   body="send_to_wmo.sh (${DIR_WMO}): $cntmanifest manifest file sent instead of the 1 expected"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit 1
else
# do check dimensions of transferred files
   cd $pushdirapec/${typeofrun}/${start_date}/monthly
   listafiles=`ls *nc.gz *txt`
   for file in $listafiles
   do
      localdim=`ls -l $file|awk '{print $5}'`
      remotedim=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/ls_WMO_S${yyyy}${st}.log|awk '{print $5}'`
      if [[ $localdim -ne $remotedim ]]
      then
         title=${title_debug}"[WMO] ${SPSSystem} ERROR"
         body="ACHTUNG!!! In $DIR_C3S/push4WMO.sh file $file was not correctly transferred!! original dimension $localdim, transferred dimension $remotedim. check it"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
         exit 5
      fi
   done
   touch $DIR_LOG/$typeofrun/$yyyy$st/$filedone
fi

# AT LAST SEND notification both to ${user} and to WMO
title=${title_debug}"CMCC-${SPSSystem} ${typeofrun} ${yyyy}${st} data-transfer to WMO completed"
body="Dear Jeongmin Han, \n
\n
this is to notify the completion of CMCC-${SPSSystem} ${typeofrun} data (start-date ${yyyy}${st}01) transfer. \n
\n
Many thanks for your cooperation \n
CMCC-SPS staff\n"

checkpushdone=`ls $DIR_LOG/$typeofrun/$yyyy$st/${filedone} | wc -l`
if [[ $checkpushdone -eq 1 ]]; then
   ${DIR_UTIL}/sendmail.sh -m $machine -e $wmomail -M "$body" -t "$title" -c $ccwmomail -b $mymail 
   touch $DIR_LOG/$typeofrun/$yyyy$st/$filedone
   echo "Done."
   exit 0
fi


