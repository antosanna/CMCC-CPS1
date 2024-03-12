#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv

remote=sps-dev@fdtn-zeus
remotedir=/data/csp/sps-dev/archive/IC/CLM_CPS1
localdir=$IC_CLM_CPS_DIR
#copy ciceIC to Zeus
nmax=24
#for st in 01 02 03 04 06 09 12  
#order modified to follow the operational production
list_startdate="12 10 11 01 02 03 04 05 06 07 08 09"
for st in ${list_startdate}
do
   n_rsync=0
   for yyyy in {2015..2022}
   do
      for pp in `seq -w 01 03` 
      do
         flag_miss=$DIR_TEMP/clmIC_${yyyy}${st}_${pp}_missing
         flag_done=$DIR_TEMP/clmIC_${yyyy}${st}_${pp}_done 
         if [[ -f ${flag_done} ]]
         then
            continue
         fi
         n_IC=`ls $localdir/$st/*$yyyy-${st}*.$pp.nc|wc -l`
         if [[ $n_IC -eq 0 ]]
         then
             touch ${flag_miss}
             continue
         fi
         ff=`ls $localdir/$st/*$yyyy-${st}*.$pp.nc`
         rsync -auv $ff ${remote}:$remotedir/$st
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
done
