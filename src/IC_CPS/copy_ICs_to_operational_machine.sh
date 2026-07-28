#!/bin/sh -l
#BSUB -J copy_ICs_to_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.out  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_ICs_to_Leonardo.%J.err  
#BSUB -P 0784
#BSUB -M 1000

#set -euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load $modulepass
set -uvx



if [[ "$machine" == "juno" ]]
then
    cmd="rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00""
elif [[ "$machine" == "cassandra" ]]
then
   export SSHPASS="a(nU05wgJk"
   cmd="sshpass -e rsync -auv -e ssh"
#    cmd="rsync -auv '-e=sshpass -p a(nU05wgJk ssh'"
fi


leo_dir=/leonardo_work/$account_SLURM/scratch/IC/
leo_temp_dir=/leonardo_work/$account_SLURM/scratch/CMCC-CPS1/temporary
cmcc_dir=/data/cmcc/cp1/archive/IC/

realm="CAM_CPS1 CICE_CPS1 CLM_CPS1 NEMO_CPS1"

yyyy=$1
st=$2
bkup=${3:-0}
for rea in $realm ; do

   if [[ $bkup -eq 0 ]]
   then
      checkf=$DIR_TEMP/ICs_${yyyy}${st}_${rea}_done
   else
      checkf=$DIR_TEMP/ICs_${yyyy}${st}_${rea}_bkup_done
   fi
   if [[ -f $checkf ]]
   then 
      continue
   fi
   if [[ $bkup -eq 0 ]]
   then
      $cmd ${cmcc_dir}/$rea/$st/*${yyyy}-${st}*.nc a07cmc00@data.leonardo.cineca.it:${leo_dir}/$rea/$st/
   else
      $cmd ${cmcc_dir}/$rea/$st/*${yyyy}-${st}*.bkup.nc a07cmc00@data.leonardo.cineca.it:${leo_dir}/$rea/$st/
   fi
   touch $checkf

done
# now copy flag file; this must be the very last operation since it is the go-ahead for the forecast to start on Leonardo
if [[ $bkup -eq 0 ]]
then
   touch ${DIR_TEMP}/copy_IC_${yyyy}${st}_to_leonardo_DONE
   $cmd ${DIR_TEMP}/copy_IC_${yyyy}${st}_to_leonardo_DONE a07cmc00@data.leonardo.cineca.it:${leo_temp_dir}
fi
