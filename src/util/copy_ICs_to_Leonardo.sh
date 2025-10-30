#!/bin/sh -l
#BSUB -J copy_ICs_to_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.out  
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.err  
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
module load oneapi-2025.0.4/sshpass/1.06-qkqpz 

leo_dir=/leonardo_work/CMCC_2025/asanna00/IC_CERISE_phase2
cassandra_dir=/work/cmcc/cp2/scratch/IC

realm=CLM_CPS1

for st in 02 #05 08 11
do
   for rea in $realm ; do

      checkf=$DIR_TEMP/ICs_${st}_${rea}_done
      if [[ -f $checkf ]]
      then 
         continue
      fi
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/$rea/$st/*.r.20[12]*.nc a07cmc00@data.leonardo.cineca.it:${leo_dir}/$rea/$st/.
      touch $checkf

   done
done
