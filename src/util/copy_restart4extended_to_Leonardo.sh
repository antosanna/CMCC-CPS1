#!/bin/sh -l
#BSUB -J copy_restart4extended_to_Leonardo
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_restart4extended_to_Leonardo.%J.out  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_restart4extended_to_Leonardo.%J.err  
#BSUB -P 0784
#BSUB -M 1000

#set -euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
isrunning=`${DIR_UTIL}/findjobs.sh -m $machine -n copy_restart4extended_to_Leonardo -c yes`
if [[ $isrunning -gt 1 ]]
then
    echo "already running! exit!"
    exit
fi
module load intel-2021.6.0/sshpass/.1.06-zarp3

st=11
strest=05
for yyyy in `seq 1995 2024`
do
   yyyyrest=$((yyyy + 1))
   for ens in {01..20}
   do

      jun_dir=$DIR_ARCHIVE1/${SPSSystem}_${yyyy}${st}_0${ens}/rest/$yyyyrest-$strest-01-00000/
      leo_dir=/leonardo_work/$account_SLURM/scratch/restarts4extended/${SPSSystem}_${yyyy}${st}_0${ens}/rest
       rsync -auv --rsh="sshpass -f $HOME/.sshpasswd ssh -l a07cmc00" ${jun_dir}/* a07cmc00@dmover1.leonardo.cineca.it:${leo_dir}/
   done
done
