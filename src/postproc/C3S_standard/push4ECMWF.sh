#!/bin/sh -l
#--------------------------------
## No need for bsub header, we launch it from launch_push4ECMWF, with submitcommand.sh
# MANCA IL LOG DEL RM

#NEW 202103: tolta ccmail e definita ccecmwfmail e tolto un commento
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

check_status(){
stat=$1
script1=$2
if [[ $stat -ne 0 ]]
then
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   body="Error in ${script1}. Exiting from $DIR_C3S/push4ECMWF.sh. Log in ${DIR_LOG}/${typeofrun}/${yyyy}${st}/"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
fi
}
yyyy=$1
st=$2
dbg_push=$3
filedone=$4
# check files
firstdtn03=$5

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

list2rm=""
log_script=ls_S${yyyy}${st}.log
ccecmwfmail="charalampos.karvelis@ecmwf.int,giovanni.conti@cmcc.it,daniele.peano@cmcc.it,antonella.sanna@cmcc.it"
if [[ $dbg_push -ge 1 ]]
then
   log_script=ls_S${yyyy}${st}_cmcc.log
   mymail="sp1@cmcc.it"
   ecmwfmail=$mymail
   ccecmwfmail=$mymail
   title_debug="TEST"
else
   title_debug=""
fi


title="${title_debug} [CERISE] ${SPSSystem} forecast notification"

body="push4ECMWF.sh for startdate $yyyy$st started `date` "

cmd_cntfirst="ls $firstdtn03 |wc -l "
cntfirst=`eval $cmd_cntfirst`
if [[ $cntfirst -eq 1 ]]
then
   body="Successive attempt push4ECMWF.sh for startdate $yyyy$st started `date` "
fi
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st

if [[ $cntfirst -eq 1 ]]
then
# from the second launch it checks if there are still appended processes 
   cd $DIR_LOG/$typeofrun/$yyyy$st
   
   $DIR_C3S/ls_ftp_ecmwf.sh $yyyy $st $mymail $typeofrun $dbg_push $log_script $machine
#   stat=$?
#   check_status $stat ${DIR_C3S}/ls_ftp_ecmwf.sh 
   cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_manifest_ $log_script|wc -l`
   if [[ $cntmanifest -eq 1 ]]
   then
      touch $filedone
      exit 0
   fi
fi

start_date=$yyyy$st
cd $pushdir/$start_date
#
# Check if there is some old manifest file and remove
set +euvx
nf=`ls -1 $pushdir/$yyyy$st/cmcc*manifest*txt | wc -l`
set -euvx
if [[ $nf -ne 0 ]] ; then
   rm $pushdir/$yyyy$st/cmcc*manifest*txt
fi
# 

# PROCEDURE TO PUSH FILES TO acquisition.ecmwf.int
nchunks=2
ntar=$(($nfieldsC3S - $natm3d + $nchunks * $natm3d)) #1 per 2d var e 5 per 3d var=136 in hindcast and 146 in forecast
ntarandsha=$((ntar * 2))

cntfirst=`eval $cmd_cntfirst`
if [[ $cntfirst -eq 1 ]]
then
# from the second launch it checks if there are still appended processes 
   
   if [[ "$machine" == "juno" ]]
   then
      $DIR_C3S/ls_ftp_ecmwf.sh $yyyy $st $mymail $typeofrun $dbg_push $log_script $machine
      stat=$?
      check_status $stat ${DIR_C3S}/ls_ftp_ecmwf.sh 
   elif [[ "$machine" == "leonardo" ]]
   then
      ${DIR_C3S}/ls_ftp_ecmwf.sh $yyyy $st $mymail $typeofrun $dbg_push $log_script $machine
      stat=$?
      check_status $stat ${DIR_C3S}/ls_ftp_ecmwf.sh 
   fi
# NOW CHECK DIMS
# do check dimensions of transferred files
   cd $pushdir/$yyyy$st
   listafiles=`ls *tar *sha256`
   for file in $listafiles
   do
      localdim=`ls -l $file|awk '{print $5}'`
      isremotepresent=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/${log_script}|wc -l`
      if [[ $isremotepresent -ne 0 ]] 
      then 
         remotedim=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/${log_script}|awk '{print $5}'`
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
      if [[ "$machine" == "juno" ]]
      then
         ${DIR_C3S}/rm_ftp_ecmwf.sh $yyyy $st $mymail "$list2rm" $dbg_push $machine ${typeofrun}
         stat=$?
      elif [[ "$machine" == "leonardo" ]]
      then
         ${DIR_C3S}/rm_ftp_ecmwf.sh $yyyy $st $mymail "$list2rm" $dbg_push $machine ${typeofrun}
         stat=$?
      fi
      check_status $stat ${DIR_C3S}/rm_ftp_ecmwf.sh
   fi
fi
# do the first send with mirror;send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
# al secondo tentativo cancella i file incompleti
# e ricomincia da capo
input4send="$yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push $log_script $machine $pushdir"

if [[ "$machine" == "juno" ]]
then
   ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
   stat=$?
   check_status $stat "send_to_ecmwf.sh"
elif [[ "$machine" == "leonardo" ]]
then
   ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
   stat=$?
   check_status $stat "send_to_ecmwf.sh"
fi


# Check if the files pushed are as expected
nline=`cat $DIR_LOG/$typeofrun/$yyyy$st/${log_script} | wc -l`
if [[ $nline -lt $ntarandsha ]] ; then
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   if [[ "$machine" == "juno" ]]
   then
      body="send_to_ecmwf.sh ($DIR_C3S): $nline file sent instead of the $ntarandsha expected"
   elif [[ "$machine" == "leonardo" ]]
   then
      body="send_to_ecmwf.sh ($DIR_C3S): $nline file sent instead of the $ntarandsha expected"
   fi
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
fi
# END OF PROCEDURE TO PUSH FILES TO acquisition.ecmwf.int

echo `pwd`
suffixdate=`date +%Y%m%d`"_"`date +%H%M%S`".txt"
listaofsha=`ls -1 *S${yyyy}${st}0100*.sha256`
#
manifest_file=cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_manifest_${suffixdate}
for file in ${listaofsha}
do
      cat $file >> $manifest_file
done


# AT LAST SEND manifest TO acquisition.ecmwf.int ;send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
#sh send_to_ecmwf.sh $yyyy $st $mymail $typeofrun AGGIUNTO IN INPUT ntarandsha (qui solo il manifest file conclusivo)
ntarandsha=1
#input4send="$yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push $log_script $machine $pushdir"
if [[ "$machine" == "juno" ]]
then
   ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
   stat=$?
   check_status $stat "mirroring manifest"
elif [[ "$machine" == "leonardo" ]]
then
   :
#   ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
#   stat=$?
#   check_status $stat "mirroring manifest"
fi

# Verify that all files are present in push logs (manifest included)
cd $DIR_LOG/$typeofrun/$yyyy$st
cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_manifest_ $log_script|wc -l`

if [[ $cntmanifest -gt 1 ]]; then
   # Raise error
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   if [[ "$machine" == "juno" ]]
   then
      body="send_to_ecmwf (${DIR_C3S}): more than 1 manifest file in $DIR_LOG/$typeofrun/$yyyy$st instead of the 1 expected"
   elif [[ "$machine" == "leonardo" ]]
   then
      body="send_to_ecmwf (${DIR_C3S}): more than 1 manifest file in $DIR_LOG/$typeofrun/$yyyy$st instead of the 1 expected" 
   fi  
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
fi

if [[ $cntmanifest -lt 1 ]]; then
# last attempt to send manifest TO acquisition.ecmwf.int; send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
   if [[ "$machine" == "juno" ]]
   then
      ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
      stat=$?
      check_status $stat "mirroring manifest" 
# Verify that all files are present in push logs (manifest included)
   elif [[ "$machine" == "leonardo" ]]
   then
      ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
      stat=$?
      check_status $stat "mirroring manifest" 
   fi


fi
cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_manifest_ $log_script|wc -l`
if [[ $cntmanifest -ne 1 ]]; then
   # Raise error
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   if [[ "$machine" == "juno" ]]
   then
      body="send_to_ecmwf.sh  (${DIR_C3S}): $cntmanifest manifest file sent instead of the 1 expected" 
   elif [[ "$machine" == "leonardo" ]]
   then
      body="send_to_ecmwf.sh  (${DIR_C3S}): $cntmanifest manifest file sent instead of the 1 expected" 
   fi
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
else
# do check dimensions of transferred files
   cd $pushdir/$yyyy$st
   listafiles=`ls *tar *sha256 *txt`
   for file in $listafiles
   do
      localdim=`ls -l $file|awk '{print $5}'`
      remotedim=`grep $file $DIR_LOG/$typeofrun/$yyyy$st/${log_script}|awk '{print $5}'`
      if [[ $localdim -ne $remotedim ]]
      then
         title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
         body="ACHTUNG!!! In $DIR_C3S/push4ECMWF.sh file $file was not correctly transferred!! original dimension $localdim, transferred dimension $remotedim. check it"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
         exit 5
      fi
   done
   touch $filedone
fi

# make a tar -tvf to send 
cd $pushdir/$start_date
tarlist=`ls -1 *S${yyyy}${st}0100*.tar`
attachtxt=${DIR_LOG}/$typeofrun/${yyyy}${st}/tartvf_${yyyy}${st}.txt
if [[ -f ${attachtxt} ]] ; then
   	rm ${attachtxt}
fi
for tarf in $tarlist ; do
   	tar -tvf $tarf >> ${attachtxt}
done


# AT LAST SEND notification both to sp1 and to ECMWF
title=${title_debug}"[CERISE] CMCC-${SPSSystem} ${typeofrun} ${yyyy}${st} data-transfer completed"
body="Dear Harris, \n
\n
this is to notify the completion of CMCC-${SPSSystem} ${typeofrun} data (start-date ${yyyy}${st}01) transfer to acq.ecmwf.int. \n
\n
Many thanks for your cooperation \n
CMCC-SPS staff\n"


if [[ "$machine" == "juno" ]]
then
   checkpushdone=`ls ${filedone} | wc -l`
elif [[ "$machine" == "leonardo" ]]
then
   checkpushdone=`ls ${filedone} | wc -l`
fi
if [[ $checkpushdone -eq 1 ]]; then
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a ${attachtxt} -c $ccecmwfmail -b $mymail -r $typeofrun -s $yyyy$st
   touch $filedone
   if [ -f $SCRATCHDIR/tmp_CERISE/launch_push_started ]
   then
      rm $SCRATCHDIR/tmp_CERISE/launch_push_started
   fi
   echo "Done."
   exit 0
fi
