#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@zeus01.cmcc.scc
remotedir=/data/csp/sps-dev/archive/IC/CICE_CPS1
localdir=$IC_CICE_CPS_DIR
#copy ciceIC to Zeus
nmax=20
for st in `seq -w 2 2 12`
do
   n_rsync=0
   for yyyy in {1993..2022}
   do
      if [[ -f $DIR_TEMP/ciceIC_${yyyy}${st}_done ]]
      then
         continue
      fi
      n_IC=`ls $localdir/$st/*$yyyy-${st}*.nc|wc -l`
      if [[ $n_IC -eq 0 ]]
      then
          touch $DIR_TEMP/ciceIC_${yyyy}${st}_missing
          continue
      fi
      listaIC=`ls $localdir/$st/*$yyyy-${st}*.nc`
      for ff in $listaIC
      do
         rsync -auv $ff ${remote}:$remotedir/$st
      done
      touch $DIR_TEMP/ciceIC_${yyyy}${st}_done
      n_rsync=$(($n_rsync + 1))
      if [[ $n_rsync -ge $nmax ]]
      then
         exit
      fi
   done
done
