#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@fdtn-zeus
remotedir=/data/csp/sps-dev/archive/IC/CAM_CPS1
localdir=$IC_CAM_CPS_DIR
#copy camIC from Zeus to Juno
nmax=20
for st in `seq -w 1 12`
do
   n_rsync=0
   for yyyy in {1993..2022}
   do
      flag_done=$DIR_TEMP/camIC_${yyyy}${st}_done 
      flag_miss=$DIR_TEMP/camIC_${yyyy}${st}_missing
      if [[ -f ${flag_done} ]]
      then
         continue
      fi
      n_IC=`ssh $remote ls $remotedir/$st/*$yyyy-${st}*.nc|wc -l`
      if [[ $n_IC -ne 10 ]]
      then
          touch ${flag_miss}
          continue
      fi
      listaIC=`ssh $remote ls $remotedir/$st/*$yyyy-${st}*.nc`
      for ff in $listaIC
      do
         rsync -auv ${remote}:$ff ${localdir}/$st/
      done
      touch ${flag_done}
      if [[ -f ${flag_miss} ]] ; then
         rm ${flag_miss}
      fi
      n_rsync=$(($n_rsync + 1))
      if [[ $n_rsync -ge $nmax ]]
      then
         exit
      fi
   done
done
