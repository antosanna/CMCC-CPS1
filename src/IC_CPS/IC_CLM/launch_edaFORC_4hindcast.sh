#!/bin/sh -l
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euxv

dir_log=${DIR_LOG}/IC_CLM
mkdir -p ${dir_log}

for member in `seq 2 3` ; do
  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 2500 -d ${DIR_LND_IC} -s launch_create_edaFORC_ens.sh -j launch_create_edaFORC_${member}.sh -l ${dir_log} -i "$member" 
done
