#!/bin/sh -l
#TO BE TESTED
# script to support operator during forecast:
# list all the available ICs both on Zeus and on CINECA machine
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -eu #vx
scriptdir=$DIR_UTIL
serverCIN=login01.marconi.cineca.it
passCIN="a(nU05wgJk"
userCIN=a07cmc00
dirCIN=/marconi_scratch/usera07cmc/a07cmc00/backup
st=`date +%m`
yyyy=`date +%Y`
yyyym1=`date "-d $yyyy${st}01 - 1 month" +%Y`
stnemo=`date "-d $yyyy${st}01 - 1 month" +%m`
dirCINnemo=/marconi_scratch/usera07cmc/a07cmc00/backup/IC_NEMO_${CPSSYS}/$st
dirCINcice=/marconi_scratch/usera07cmc/a07cmc00/backup/IC_CICE_${CPSSYS}/$st
dirCINcam=/marconi_scratch/usera07cmc/a07cmc00/backup/IC_CAM_${CPSSYS}/$st
dirCINclm=/marconi_scratch/usera07cmc/a07cmc00/backup/IC_CLM_${CPSSYS}/$st
outputfile=$DIR_LOG/forecast/$yyyy$st/IC_backup_list_${yyyy}${st}
echo "output file: $outputfile"

if [ -f $outputfile ]
then
   rm $outputfile
fi
echo "======================================================================">>$outputfile
echo "FIRST SECTION: check presence of back-up ICs on ZEUS" >>$outputfile
echo "======================================================================">>$outputfile
echo " ">>$outputfile
echo " ">>$outputfile
echo "">>$outputfile
echo "!!!!! BACK-UP ICs FOR NEMO: in case the forecast did not complete correctly you will use the restart from last tuesday analysis" >>$outputfile
for poce in {01..09}
do
   INPDIR=`ls -ld ${OISBKDIR}/RT_R$poce/$yyyym1${stnemo}??00/forecast | tail -1 | awk '{print $9}'` # BK OCE
   echo "======================================================================">>$outputfile
   echo "NEMO BACK-UP ICs FROM PERT $poce: $INPDIR" >>$outputfile
   echo "======================================================================">>$outputfile
   cd $INPDIR/
#   ls  -latr NEMO*rest* |grep -v restart_sto_  >>$outputfile
   ls  NEMO_*_restart_0* |head -1  >>$outputfile
   echo "number of restart NEMO files:" >>$outputfile
   ls  NEMO_*_restart_0* |wc -l >>$outputfile
   ls  NEMO_*_restart_ice_0* |head -1 >>$outputfile
   echo "number of restart LIM files:" >>$outputfile
   ls  NEMO_*_restart_ice_0* |wc -l >>$outputfile
done
for dir in $IC_CAM_CPS_DIR/$st $IC_CPS_guess/CLM/$st
do
   cd $dir
   case $dir in 
     $IC_CAM_CPS_DIR/$st) model=CAM;; 
     $IC_CPS_guess/CLM/$st) model=CLM;; 
   esac  
   echo "======================================================================">>$outputfile
   echo "$model BACK-UP ICs FROM $dir">>$outputfile
   echo "======================================================================">>$outputfile
   ls -latr *$yyyy*$st*nc*|grep -v _done >>$outputfile
   echo " ">>$outputfile
   echo " ">>$outputfile
done
echo " ">>$outputfile
echo " ">>$outputfile
echo "======================================================================">>$outputfile
echo "SECOND SECTION: check presence of back-up ICs on CINECA">>$outputfile
echo "======================================================================">>$outputfile
echo " ">>$outputfile
echo " ">>$outputfile
for dir in $dirCINnemo $dirCINcice $dirCINcam $dirCINclm
do
   echo "======================================================================">>$outputfile
   echo "BACK-UP ICs FROM $dir">>$outputfile
   echo "======================================================================">>$outputfile
   $scriptdir/list_CINECA.exp $passCIN $serverCIN $userCIN $dir $yyyy>>$outputfile
   echo " ">>$outputfile
   echo " ">>$outputfile
done
dos2unix $outputfile
title="${CPSSYS} forecast notification"
body="List of backup IC on Zeus and CINECA. (Original output file $outputfile. Reference script $0)" 
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a $outputfile -r $typeofrun -s $yyyy$st
echo "That's all Folks"
