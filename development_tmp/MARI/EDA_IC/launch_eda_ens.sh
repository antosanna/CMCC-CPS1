#!/bin/sh -l
set +euxv     
# MANDATORY!! if not set the script exits because if sourced 
# does not recognize $PROMPT 
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
set -euxv

here=/users_home/csp/mb16318/SPS/SPS4/CLM/EDA_IC
for member in `seq 1 5` ; do

#${DIR_SPS35}/submitcommand.sh -m $machine -p ${casoincomplete}_run -S qos_resv -t "1"  -q $serialq_s -s mv_IC_2ICDIR.sh -j mv_IC_${provider}2CAM_2ICDIR_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_CASES}/${casoincomplete}/logs -i "$input"

  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -d $here -s launch_create_edaFORC_ens.sh -j launch_create_edaFORC_${member}.sh -l $here/logs -i "$member" 
done
