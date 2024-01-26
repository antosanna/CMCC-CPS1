#!/bin/sh -l
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
#. ${DIR_UTIL}/load_cdo
set -euxv

logdir=${DIR_LOG}/LND_IC/historical
mkdir -p $logdir
wkdir=/users_home/csp/cp1/CPS/CMCC-CPS1/development_tmp/MARI/EDA_IC

scriptname=create_clm_stand_alone_bgc_eda_hist
for member in `seq 1 3` ; do

  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -d $wkdir -s ${scriptname}.sh  -j ${scriptname}_${member} -l $logdir -i "$member" 
done
