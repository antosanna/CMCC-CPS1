#!/bin/sh -l

#set -euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

st=11
strest=05
for yyyy in `seq 1995 2024`
do
   yyyyrest=$((yyyy + 1))
   for ens in {01..20}
   do

      leo_dir=/leonardo_work/$account_SLURM/scratch/restarts4extended/${SPSSystem}_${yyyy}${st}_0${ens}/rest
      mkdir -p $leo_dir
   done
done
