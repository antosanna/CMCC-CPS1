#!/bin/sh -l
# HOW TO SUBMIT 
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_ -l $DIR_LOG/hindcast/ -d $IC_CPS -s run_IC_production_CERISE_phase2_juno.sh 
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

#for yyyy in {2002..2021}
for yyyy in {2002..2021}
do
   for mm in 2 11 #5 8 11
   do
                         # not 2 digits
st=`printf '%.2d' $((10#$mm))`   # 2 digits

mkdir -p $IC_CAM_CPS_DIR/$st
mkdir -p $IC_CLM_CPS_DIR/$st
mkdir -p $IC_NEMO_CPS_DIR/$st

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx


   for ilnd in {01..25}
   do
      actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.nc
      actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.nc
      if [[ -f actual_ic_clm ]] && [[ -f actual_ic_hydros ]]
      then
         continue
      fi
      if [[ `ls /work/cmcc/spreads-lnd/land/archive/SPREADS_MU30/cerise_phase2_restarts/restart_${yyyy}-${st}-01/*clm2_00${ilnd}.r.$yyyy-$st* |wc -l ` -eq 0 ]]
      then
         continue
      fi
      rsync -auv /work/cmcc/spreads-lnd/land/archive/SPREADS_MU30/cerise_phase2_restarts/restart_${yyyy}-${st}-01/*clm2_00${ilnd}.r.$yyyy-$st* $IC_CLM_CPS_DIR/$st/
      rsync -auv /work/cmcc/spreads-lnd/land/archive/SPREADS_MU30/cerise_phase2_restarts/restart_${yyyy}-${st}-01/*hydros_00${ilnd}.r.$yyyy-$st* $IC_CLM_CPS_DIR/$st/
      gunzip $IC_CLM_CPS_DIR/$st/*.clm2_00${ilnd}.r.$yyyy-$st-01-00000.nc.gz
      gunzip $IC_CLM_CPS_DIR/$st/*.hydros_00${ilnd}.r.$yyyy-$st-01-00000.nc.gz
      mv $IC_CLM_CPS_DIR/$st/*.clm2_00${ilnd}.r.$yyyy-$st-01-00000.nc $actual_ic_clm
      mv $IC_CLM_CPS_DIR/$st/*.hydros_00${ilnd}.r.$yyyy-$st-01-00000.nc $actual_ic_hydros
      
   done
done   
done   
#
