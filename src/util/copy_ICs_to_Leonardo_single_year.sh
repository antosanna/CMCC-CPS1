#!/bin/sh -l
#BSUB -J copy_ICs_to_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.out  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.err  
#BSUB -P 0490
#BSUB -M 1000

#set -euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
isrunning=`${DIR_UTIL}/findjobs.sh -m $machine -n copy_ICs_to_Leonardo -c yes`
if [[ $isrunning -gt 1 ]]
then
    echo "already running! exit!"
    exit
fi
module load intel-2021.6.0/sshpass/.1.06-zarp3

leo_dir=/leonardo_work/CMCC_reforeca/scratch/IC/
jun_dir=/data/cmcc/cp1/archive/IC/

realm="CAM_CPS1 CICE_CPS1 CLM_CPS1 NEMO_CPS1"

yyyy=2014
for st in 10 
do
   for rea in $realm ; do

      checkf=$DIR_TEMP/ICs_${st}_${rea}_done
      if [[ -f $checkf ]]
      then 
         continue
      fi
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/$rea/$st/*${yyyy}-${st}*.nc a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/$rea/$st/.
      touch $checkf

   done
done
