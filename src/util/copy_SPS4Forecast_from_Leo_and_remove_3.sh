#!/bin/sh -l
#BSUB -J copy_SPS4Forecast_from_Leo_and_remove_3
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_and_remove_3.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4Forecast_from_Leo_and_remove_3.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

yyyy=2025
st=05
leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/
leo_dir_temp=/leonardo_work/CMCC_reforeca/scratch/CMCC-CPS1/temporary
# get the list of completed cases (produced daily in cron on Leonardo)

lista_today_1=" "
for ens in {021..030} ; do
    caso=sps4_${yyyy}${st}_${ens}

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
      if [[ $dim -lt 256 ]]
      then
         continue
      fi
      lista_today_1+=" $caso"
   fi

done
idjob=`$DIR_UTIL/findjobs.sh -n copy_SPS4DMO_from_Leonardo1 -i yes`
logfile=$DIR_TEMP/list3_cases_transferred_`date +%Y%m%d`.$idjob.txt
echo $lista_today_1 > $logfile
rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $logfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir_temp}/
