#!/bin/sh -l
#BSUB -J copy_SPS4web_plots_from_Leonardo_1
#BSUB -q s_download
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4web_plots_from_Leonardo_1.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/copy_SPS4web_plots_from_Leonardo_1.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load intel-2021.6.0/sshpass/.1.06-zarp3
set -uvx

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4web_plots_from_Leonardo_1 -c yes`
if [[ $job_run -gt 1 ]]
then
   exit 0
fi

yyyy=`date +%Y`
st=`date +%m`
dirplots_leo=/leonardo_work/$account_SLURM/scratch/diag_C3S/forecast_plots


rsync -auv -e="sshpass -p a(nU05wgJk ssh" a07cmc00@data.leonardo.cineca.it:${dirplots_leo}/$yyyy$st.tar $DIR_TEMP

