#!/bin/sh -l
#BSUB -J copy_SPS4DMO_from_Leonardo_201410
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo_201410.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4DMO_from_Leonardo_201410.err.%J  
#BSUB -P 0490
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -n copy_SPS4DMO_from_Leonardo -c yes ` -gt 4 ]
then
   exit
fi
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

leo_dir=/leonardo_work/CMCC_reforeca/CMCC-CM/archive/

for ens in {01..30}
do 
   if [[ $ens == "08" ]] || [[ $ens == "13" ]] ||[[ $ens == "28" ]]
   then
      continue
   fi
   caso=sps4_201410_0${ens}

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
      touch $checkfile
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" $checkfile a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
      dim=`du -hs $DIR_ARCHIVE/$caso|cut -c 1-3`
      if [[ dim -lt 256 ]]
      then
         continue
      fi
   fi

done
