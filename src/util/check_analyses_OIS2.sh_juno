#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh


set -eu
for poce in 0 1 2 3 4 5 6 7 8
do
   lastrest=`ls -rt $DIR_REST_OIS/OPSLAMB$poce/RESTARTS/|tail -1`
   lastrestdate=`echo ${lastrest:0:8}`
   lastrun=`date -d ' '${lastrestdate}' - 7 days' +%Y%m%d`
   lasttstep=`ls -lt $DIR_REST_OIS/OPSLAMB$poce/RESTARTS/$lastrest/*rest*nc|tail -1|rev|cut -d '_' -f3|rev`
   echo "perturbation $poce"
   echo "last restart $lastrest with `ls -lt $DIR_REST_OIS/OPSLAMB$poce/RESTARTS/$lastrest/*rest*nc|wc -l` restarts: last timestep $lasttstep and timestep=`grep "rn_Dt =" /work/cmcc/aspect/CESM2/OPSLAMB$poce/${lastrun}00/run/namelist_cfg`"
   echo ""
done
