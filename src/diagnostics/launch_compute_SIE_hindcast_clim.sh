#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
logdir=${DIR_LOG}/hindcast/SIE
mkdir -p $logdir
for st in `seq -w 01 12`
do
      ${DIR_UTIL}/submitcommand.sh -m $machine -q ${serialq_m} -M 2000 -j compute_hindcast_clim_SIE_${st} -l ${logdir} -d ${DIR_DIAG} -s compute_SIE_hindcast_clim.sh  -i "${st}"

done
