#!/bin/sh -l
#BSUB -J sendIC2leo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/sendIC2leo.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/sendIC2leo.err.%J  
#BSUB -P 0490
#BSUB -M 1000

#set -euvx
module load intel-2021.6.0/sshpass/.1.06-zarp3

st=11
leo_dir=/leonardo_work/CMCC_reforeca/scratch/IC/
jun_dir=/data/cmcc/cp1/archive/IC/

realm="CAM_CPS1 CICE_CPS1 CLM_CPS1 NEMO_CPS1"

for rea in $realm ; do

   rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/$rea/$st/*.nc a07cmc00@dmover3.leonardo.cineca.it:${leo_dir}/$rea/$st/.

done
