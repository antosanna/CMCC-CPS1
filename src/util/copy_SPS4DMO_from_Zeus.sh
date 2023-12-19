#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@zeus01.cmcc.scc
remotedir=/data/delivery/csp/ecaccess/EDA/snapshot/00Z
localdir=$SCRATCHDIR/DATA_ECACCESS/EDA/snapshot/00Z
#copy EDA from Zeus
nmax=20
#for stm1 in `seq -w 2 2 12`
for stm1 in 06 10
do
   n_rsync=0
   for yym1 in {1992..2022}
   do
      if [[ $yym1 -eq 1992 ]] && [[ $stm1 -ne 12 ]]
      then
         continue
      fi
      if [[ -f $DIR_TEMP/eda_${yym1}${stm1}_done ]]
      then
         continue
      fi
      n_grib=`ssh $remote ls $remotedir/*$yym1${stm1}*.grib|wc -l`
      if [[ $n_grib -eq 0 ]]
      then
          touch $DIR_TEMP/eda_${yym1}${stm1}_missing
          continue
      fi
      listagrib=`ssh $remote ls $remotedir/*$yym1${stm1}*.grib`
      for ff in $listagrib
      do
         rsync -auv ${remote}:$ff $localdir
      done
      touch $DIR_TEMP/eda_${yym1}${stm1}_done
      n_rsync=$(($n_rsync + 1))
      if [[ $n_rsync -ge $nmax ]]
      then
         exit
      fi
   done
done
