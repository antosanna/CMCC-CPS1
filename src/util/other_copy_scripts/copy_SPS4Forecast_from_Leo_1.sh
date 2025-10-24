#!/bin/sh -l
#BSUB -J copy_SPS4Forecast_from_Leo_1
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_1.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_1.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
if [[ `${DIR_UTIL}/findjobs.sh -m ${machine} -n copy_SPS4DMO_from_Leonardo -c yes ` -gt 6 ]]
then
   exit
fi
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/

lista=""

lista_today_1=" "
#for ens in 002 003 006 009 011
#for ens in 005 028 031 034 
#for ens in 008
for ens in 032
do
   caso=sps4_202508_${ens}

   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE_no_rest
   if [[ -f $checkfile ]]
   then
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover2.leonardo.cineca.it:${leo_dir}/
      continue
   fi
   mkdir -p ${DIR_ARCHIVE}/$caso
   for dd in atm ice ocn lnd
   do
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@dmover2.leonardo.cineca.it:${leo_dir}/$caso/$dd ${DIR_ARCHIVE}/$caso/
   done
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover2.leonardo.cineca.it:${leo_dir}/
#      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
#      if [[ $dim -lt 256 ]]
#      then
#         continue
#      fi
   fi

done
