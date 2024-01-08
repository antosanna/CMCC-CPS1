#!/bin/sh -l
#BSUB -J touch_IC_CAM
#BSUB -e logs/touch_IC_CAM_%J.err
#BSUB -o logs/touch_IC_CAM_%J.out
#BSUB -P 0490
#BSUB -M 1000

# 20240108: the production of CAM ICs is opertional only on Zeus and this script just creates checkfiles to ensure the ICs already created on Juno
# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx

IC_CAM_CPS_DIR_REMOTE=/data/csp/sps-dev/archive/IC/CAM_CPS1
cd $IC_CAM_CPS_DIR
listadir=`ls`
for ll in $listadir
do
   cd $IC_CAM_CPS_DIR/$ll
   listafile=`ls *nc`
   for ff in $listafile
   do
     head=`echo $ff|rev|cut -d '.' -f2-|rev`
     touch $head.DONE
     ssh sps-dev@zeus01.cmcc.scc mkdir -p $IC_CAM_CPS_DIR_REMOTE/$ll
     rsync -auv $head.DONE sps-dev@zeus01.cmcc.scc:$IC_CAM_CPS_DIR_REMOTE/$ll
   done
done
   
