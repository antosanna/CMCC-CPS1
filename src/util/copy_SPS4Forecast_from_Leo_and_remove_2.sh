#!/bin/sh -l
#BSUB -J copy_SPS4Forecast_from_Leo_and_remove_2
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_and_remove_2.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_and_remove_2.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

yyyy=`date +%Y`
st=`date +%m`
leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/
leo_dir_temp=/leonardo_work/CMCC_reforeca/scratch/CMCC-CPS1/temporary
# get the list of completed cases (produced daily in cron on Leonardo)

lista_today_1=" "
for ens in {011..020} ; do
    caso=sps4_${yyyy}${st}_${ens}

   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE
   if [[ -f $checkfile ]]
   then
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@data.leonardo.cineca.it:${leo_dir}/
      continue
   fi
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@data.leonardo.cineca.it:${leo_dir}/$caso ${DIR_ARCHIVE}
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@data.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ $dim -lt 256 ]]
      then
         continue
      fi
      lista_today_1+=" $caso"
   fi

done
logfile=$DIR_TEMP/list2_cases_transferred_forecast_`date +%Y%m`.txt
echo $lista_today_1 >> $logfile
rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $logfile a07cmc00@data.leonardo.cineca.it:${leo_dir_temp}/
