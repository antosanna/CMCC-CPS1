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
module load intel-2021.6.0/sshpass/.1.06-zarp3

leo_dir=/leonardo_work/CMCC_reforeca/scratch/IC/
leo_trip_dir=/leonardo/home/usera07cmc/a07cmc00/CPS/CMCC-CPS1/triplette_done
jun_dir=/data/cmcc/cp1/archive/IC/

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
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/$rea/$st/*${yyyy}-${st}*.nc a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/$rea/$st/
   else
      rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/$rea/$st/*${yyyy}-${st}*.bkup.nc a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/$rea/$st/
   fi
   touch $checkf

done
# now copy triplette file
if [[ $bkup -eq 0 ]]
then
   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${TRIP_DIR}/triplette.random.$yyyy$st.txt a07cmc00@dmover1.leonardo.cineca.it:${leo_trip_dir}
fi
