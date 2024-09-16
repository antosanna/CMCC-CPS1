#!/bin/sh -l
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euxv

logdir=${DIR_LOG}/IC_CLM
mkdir -p $logdir

###scriptname=create_clm_stand_alone_bgc_eda_clim    ## 10 year-spinup around 1960
###scriptname=create_clm_stand_alone_bgc_eda_hist    ## historical 1960-2014

###scriptname=create_clm_stand_alone_bgc_eda_scen     ## scenario 2015-onwards
scriptname=create_clm_stand_alone_bgc_eda_op     ## scenario 2015-onwards
#for member in `seq 1 3` ; do
for member in `seq 1 1` ; do
   echo $member
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 3000 -d ${DIR_LND_IC} -s ${scriptname}.sh  -j ${scriptname}_${member} -l $logdir -i "$member" 
done
