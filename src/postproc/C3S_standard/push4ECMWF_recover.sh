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
mem=$6

. ${DIR_UTIL}/descr_ensemble.sh $yyyy

list2rm=""
log_script=ls_S${yyyy}${st}_${mem}.log
ccecmwfmail="charalampos.karvelis@ecmwf.int,giovanni.conti@cmcc.it,daniele.peano@cmcc.it,antonella.sanna@cmcc.it"
title_debug=""


title="${title_debug} [CERISE] ${SPSSystem} forecast notification"

body="push4ECMWF.sh for startdate $yyyy$st membro ${mem} started `date` "

cmd_cntfirst="ls $firstdtn03 |wc -l "
cntfirst=`eval $cmd_cntfirst`
if [[ $cntfirst -eq 1 ]]
then
   body="Successive attempt push4ECMWF.sh for startdate $yyyy$st membro ${mem} started `date` "
fi
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st

if [[ $cntfirst -eq 1 ]]
then
# from the second launch it checks if there are still appended processes 
   cd $DIR_LOG/$typeofrun/$yyyy$st
   
   $DIR_C3S/ls_ftp_ecmwf_mem.sh $yyyy $st $mymail $typeofrun $dbg_push $log_script $machine $mem
   cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_n${mem}_manifest_ $log_script|wc -l`
   if [[ $cntmanifest -eq 1 ]]
   then
      touch $filedone
      exit 0
   fi
fi

start_date=$yyyy$st
cd $pushdir/recover/$start_date
#
# Check if there is some old manifest file and remove
set +euvx
nf=`ls -1 $pushdir/recover/$yyyy$st/cmcc*manifest*txt | wc -l`
set -euvx
if [[ $nf -ne 0 ]] ; then
   rm $pushdir/recover/$yyyy$st/cmcc*manifest*txt
fi
# 

ntar=1
ntarandsha=$((ntar * 2))

cntfirst=`eval $cmd_cntfirst`
if [[ $cntfirst -eq 1 ]]
then
# from the second launch it checks if there are still appended processes 
   
   $DIR_C3S/ls_ftp_ecmwf_mem.sh $yyyy $st $mymail $typeofrun $dbg_push $log_script $machine $mem
# NOW CHECK DIMS
# do check dimensions of transferred files
   cd $pushdir/recover/$yyyy$st
   for file in cmcc_CERISE-CERISE-CMCC-CM3-demonstrator2-v20231101_hindcast_S${yyyy}${st}0100_n${mem}.tar cmcc_CERISE-CERISE-CMCC-CM3-demonstrator2-v20231101_hindcast_S${yyyy}${st}0100_n${mem}.sha256
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
      ${DIR_C3S}/rm_ftp_ecmwf.sh $yyyy $st $mymail "$list2rm" $dbg_push $machine ${typeofrun}
   fi
fi
# do the first send with mirror;send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
# al secondo tentativo cancella i file incompleti
# e ricomincia da capo
input4send="$yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push $log_script $machine $pushdir/recover"

${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log
stat=$?
check_status $stat "send_to_ecmwf.sh"


# Check if the files pushed are as expected
nline=`cat $DIR_LOG/$typeofrun/$yyyy$st/${log_script} | wc -l`
if [[ $nline -lt $ntarandsha ]] ; then
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   body="send_to_ecmwf.sh ($DIR_C3S): $nline file sent instead of the $ntarandsha expected"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
fi
# END OF PROCEDURE TO PUSH FILES TO acquisition.ecmwf.int

echo `pwd`
suffixdate=`date +%Y%m%d`"_"`date +%H%M%S`".txt"
listaofsha=`ls -1 *S${yyyy}${st}0100*n${mem}.sha256`
#
manifest_file=cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_n${mem}_manifest_${suffixdate}
for file in ${listaofsha}
do
      cat $file >> $manifest_file
done


# AT LAST SEND manifest TO acquisition.ecmwf.int ;send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
#sh send_to_ecmwf.sh $yyyy $st $mymail $typeofrun AGGIUNTO IN INPUT ntarandsha (qui solo il manifest file conclusivo)
ntarandsha=1
input4send="$yyyy $st $mymail $typeofrun $ntarandsha $firstdtn03 $dbg_push $log_script $machine $pushdir/recover"
${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log

# Verify that all files are present in push logs (manifest included)
cd $DIR_LOG/$typeofrun/$yyyy$st
cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_n${mem}_manifest_ $log_script|wc -l`

if [[ $cntmanifest -gt 1 ]]; then
   # Raise error
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   body="send_to_ecmwf (${DIR_C3S}): more than 1 manifest file in $DIR_LOG/$typeofrun/$yyyy$st instead of the 1 expected"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
fi

if [[ $cntmanifest -lt 1 ]]; then
# last attempt to send manifest TO acquisition.ecmwf.int; send_to_ecmwf.`date +%Y%m%d%H%M%S`.log will be output in dtn03
   ${DIR_C3S}/send_to_ecmwf.sh $input4send| tee $DIR_LOG/$typeofrun/$yyyy$st/send_to_ecmwf.`date +%Y%m%d%H%M%S`.log


fi
cntmanifest=`grep cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_n${mem}_manifest_ $log_script|wc -l`
if [[ $cntmanifest -ne 1 ]]; then
   # Raise error
   title=${title_debug}"[CERISE] ${SPSSystem} ERROR"
   body="send_to_ecmwf.sh  (${DIR_C3S}): $cntmanifest manifest file sent instead of the 1 expected" 
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
   exit 1
else
# do check dimensions of transferred files
   cd $pushdir/recover/$yyyy$st
   listafiles=`ls cmcc_CERISE-CERISE-CMCC-CM3-demonstrator2-v20231101_hindcast_S${yyyy}${st}0100_n${mem}.tar cmcc_CERISE-CERISE-CMCC-CM3-demonstrator2-v20231101_hindcast_S${yyyy}${st}0100_n${mem}.sha256 cmcc_CERISE-CERISE-${GCM_name}-demonstrator2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_n${mem}_manifest_*`
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
cd $pushdir/recover/$start_date
tarlist=`ls -1 *S${yyyy}${st}0100*n${mem}.tar`
attachtxt=${DIR_LOG}/$typeofrun/${yyyy}${st}/tartvf_${yyyy}${st}_recover_n${mem}.txt
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
