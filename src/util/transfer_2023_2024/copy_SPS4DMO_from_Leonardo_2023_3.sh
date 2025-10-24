#!/bin/sh -l
#BSUB -J copy_SPS4DMO_from_Leonardo3
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo3.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo3.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -n copy_SPS4DMO_from_Leonardo -c yes ` -gt 6 ]
then
   exit
fi
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

leo_dir=/leonardo_work/CMCC_2025/CMCC-CM/archive/
leo_dir_temp=/leonardo_work/CMCC_2025/scratch/CMCC-CPS1/temporary
# get the list of completed cases (produced daily in cron on Leonardo)
rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@dmover3.leonardo.cineca.it:/leonardo_work/CMCC_2025/scratch/list_`date +%Y%m%d` $DIR_TEMP


st=01
lista_today_3=" "
for ens in `seq -w 021 030` ; do
   caso=sps4_2023${st}_${ens}
   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE
   if [[ -f $checkfile ]]
   then
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover3.leonardo.cineca.it:${leo_dir}/
      continue
   fi
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" a07cmc00@dmover3.leonardo.cineca.it:${leo_dir}/$caso ${DIR_ARCHIVE}
   stat=$?
   if [[ $stat -eq 0 ]]
   then
      chmod -R ug-w ${DIR_ARCHIVE}/$caso
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover3.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ $dim -lt 256 ]]
      then
         #new cases with restart in tar package 
         if [[ `ls $DIR_ARCHIVE/$caso/rest/*tar.gz |wc -l` -eq 1 ]] && [[ $dim -eq 131 ]]  
         then
            :   
         else
            continue
         fi  
      fi
      lista_today_3+=" $caso"
   fi

done
idjob=`$DIR_UTIL/findjobs.sh -n copy_SPS4DMO_from_Leonardo3 -i yes`
logfile=$DIR_TEMP/list3_cases_transferred_`date +%Y%m%d`.$idjob.txt
echo $lista_today_3 > $logfile
rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $logfile a07cmc00@dmover3.leonardo.cineca.it:${leo_dir_temp}/
