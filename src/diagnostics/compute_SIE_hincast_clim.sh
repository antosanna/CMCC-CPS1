#!/bin/sh -l
#BSUB -q s_long
#BSUB -P 0287
#BSUB -J SIE_NH
#BSUB -e logs/SIE_NH_%J.err
#BSUB -o logs/SIE_NH_%J.out

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

dbg=1
. $DIR_SPS35/descr_hindcast.sh
export nhindmem=40
export hiniy=1993
export hendy=$endy_hind
export outplot="test"
export dotheplot=0  #set to one if you wnat to do the plot
export plottype="png"
export ntime=$nmonfore
export filarea="$CESMDATAROOT/CMCC-SPS3.5/files4SPS3.5/tarea.cice.nc"
dirout=/work/csp/sp2/SPS3.5/CESM/monthly/sic/SIE_NH/clim
mkdir -p $dirout
export ntime=$nmonfore
if [[ $dbg -eq 1 ]]
then
   mymail=antonella.sanna@cmcc.it
   DIR_DIAG=$PWD
fi
mkdir -p $SCRATCHDIR/SIE
#for m in 11 12 01 02
#for m in 03 04 
#for m in 05
#for m in 06
#for m in 07
for m in 08
do
   export st=$m
   export dirhc=/work/csp/sp2/DMO4postproc/SPS3.5/ice/$st
# output file
   export dstFileName=$dirout/SIE_NH_SPS3.5_1993-2016.${st}.nc
   export checkfile=$SCRATCHDIR/SIE/SIE_NH_SPS3.5_1993-2016.${st}.ok
   if [[ ! -f $checkfile ]]
   then
      
      ncl $DIR_DIAG/compute_SIE_hincast_clim.ncl
#   if [[ $dbg -eq 1 ]]
#   then
#      exit
#   fi
      if [[ ! -f $checkfile ]]
      then
         title="ERROR in SIE clim computation"
         body="Something wrong with $LSB_JOBNAME script in $DIR_DIAG. "
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
      else
         title="SIE clim correctly computed for $st"
         body="script $LSB_JOBNAME. Now rsync to /work/csp/sp1/CESMDATAROOT/C3S_clim_1993_2016/cice/SIE_NH (from user sp1)"
         ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
      fi
   fi
done
