#!/bin/sh -l
#BSUB -J launch_copy_SPS4Forecast_from_Leonardo
#BSUB -q s_short
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/launch_copy_SPS4Forecast_from_Leonardo.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/launch_copy_SPS4Forecast_from_Leonardo.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
module load $modulepass
set -uvx

##if [[ $machine != "juno" ]]
#then
#   exit
#fi
yyyy=`date +%Y`
st=`date +%m`
mkdir -p ${DIR_LOG}/leonardo_transfer/$yyyy$st

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n launch_copy_SPS4Forecast_from_Leonardo -c yes`
if [[ $job_run -gt 1 ]]
then
   exit 0
fi


for ens in {001..054} 
do
   caso=sps4_${yyyy}${st}_${ens}
   checkfile=$DIR_ARCHIVE/$caso.transfer_from_Leonardo_DONE

   if [[ -f $checkfile ]]
   then
      continue
   fi

   isrunning=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4Forecast_from_Leonardo_${caso} -c yes`
   if [[ $isrunning -ge 1 ]]  
   then
      continue
   fi
   mkdir -p ${DIR_LOG}/leonardo_transfer/$yyyy$st
   ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -q s_download -j copy_SPS4Forecast_from_Leonardo_${caso} -l ${DIR_LOG}/leonardo_transfer/$yyyy$st -d ${DIR_UTIL} -s copy_SPS4Forecast_from_Leonardo.sh -i "${caso} $checkfile"

done
