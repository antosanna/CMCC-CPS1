#!/bin/sh -l
#BSUB -J copy_SPS4DMO_forecast_from_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_forecast_from_Leonardo.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_forecast_from_Leonardo.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -n copy_SPS4DMO_from_Leonardo -c yes ` -gt 4 ]
#then
#   exit
#fi
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/
leo_dir_temp=/leonardo_work/CMCC_reforeca/scratch/CMCC-CPS1/temporary
# get the list of completed cases (produced daily in cron on Leonardo)

cnt=0

for ens in {001..055}
do
   caso=sps4_202410_${ens}

   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE
   if [[ -f $checkfile ]]
   then
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
      continue
   fi
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/$caso ${DIR_ARCHIVE}
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ dim -lt 193 ]]
      then
         continue
      fi
      lista_today_1+=" $caso"
   fi
   cnt=$(( $cnt + 1 ))
   if [[ $cnt -eq 10 ]] ; then
      break
   fi

done
echo $lista_today_1 > $DIR_TEMP/list_cases_forecast_transferred_`date +%Y%m%d`.txt
rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $DIR_TEMP/list_cases_forecast_transferred_`date +%Y%m%d`.txt a07cmc00@dmover1.leonardo.cineca.it:${leo_dir_temp}/
