#!/bin/sh -l
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euxv

#this is to launch creation of CLM forcing for cyclical spinup

logdir=${DIR_LOG}/IC_CLM
mkdir -p $logdir
for member in `seq 1 3` ; do

  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 5000 -d ${DIR_LND_IC} -s make_clim_eda_4spinup.sh -j make_clim_eda_4spinup_${member} -l $logdir -i "$member"
done
