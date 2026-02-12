#!/bin/sh -l
#BSUB -q s_long
#BSUB -P 0490
#BSUB -J SIE_NH
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/tests/SIE_NH_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/tests/SIE_NH_%J.out
#BSUB -M 5000

. ~/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
. ${DIR_UTIL}/load_ncl
set -euvx

dbg=0
export nhindmem=$nrunhind
export hiniy=$iniy_hind
export hendy=$endy_hind
export dotheplot=0  #set to one if you wnat to do the plot
export plottype="png"
export ntime=$nmonfore
export filarea="$REPOGRID/sps4.tarea.cice.nc"
export ntime=$nmonfore
m=$1   
mkdir -p ${DIR_TEMP_CICEPLOT}/clim_plot
export outplot="${DIR_TEMP_CICEPLOT}/clim_plot/clim_SIE_${m}"
export st=${m}
if [[ $dbg -eq 1 ]]
then
 dirout=$SCRATCHDIR/MARI/SIE/clim
 mymail=marianna.benassi@cmcc.it
 DIR_NCL=$PWD
 export checkfile=$SCRATCHDIR/MARI/SIE/SIE_NH_${CPSSYS}_${hiniy}-${hendy}.${st}.ok
else
 dirout=$DIR_CLIM/monthly/sic/SIE_NH/clim
 DIR_NCL=${DIR_DIAG}/ncl
 export checkfile=$SCRATCHDIR/SIE/SIE_NH_${CPSSYS}_${hiniy}-${hendy}.${st}.ok
fi
mkdir -p $dirout
mkdir -p $SCRATCHDIR/SIE
export dirhc=${DIR_ARCHIVE}
# output file
export dstFileName=$dirout/SIE_NH_${CPSSYS}_${hiniy}-${hendy}.${st}.nc
if [[ ! -f $checkfile ]]
then
ncl $DIR_NCL/compute_SIE_hincast_clim.ncl
#   if [[ $dbg -eq 1 ]]
#   then
#      exit
#   fi
  if [[ ! -f $checkfile ]]
  then
    title="ERROR in SIE clim computation"
    body="Something wrong with $LSB_JOBNAME script in $DIR_DIAG. "
    #${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  else
    title="SIE clim correctly computed for $st"
    body="script $LSB_JOBNAME. SIE clim now present in $dirout"
    #${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  fi 
fi
