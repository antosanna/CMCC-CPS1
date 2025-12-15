#!/bin/sh -l
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/SIPN/ocean_area%J.out  # Appends std output to file %J.out.
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/SIPN/ocean_area%J.err  # Appends std error to file %J.err.
#BSUB -J ocean_area
#BSUB -q s_medium       # queue
#BSUB -M 1000
#BSUB -P 0490
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -evxu
outdir=$WORK/CPS/CMCC-${CPSSYS}/SIPN/metrics
slm=$REPOSITORY/slm_C3S.nc
if [[ ! -f $slm ]]
then
   cdo setrtoc,0,0.9999,2 $REPOSITORY/lsm_C3S.nc $SCRATCHDIR/SIPN/tmp.nc
   cdo setrtoc,1,1.9999,0 $SCRATCHDIR/SIPN/tmp.nc $SCRATCHDIR/SIPN/tmp2.nc
   cdo setrtoc,1.9999,2,1 $SCRATCHDIR/SIPN/tmp2.nc $slm
   rm $SCRATCHDIR/SIPN/tmp.nc $SCRATCHDIR/SIPN/tmp2.nc
fi
outfile=$outdir/area_cell_C3S_SP_ocean.nc
if [[ ! -f $outfile ]]
then
   cdo mul $REPOSITORY/area_cell_C3S.nc $slm $SCRATCHDIR/SIPN/area_cell_C3S_ocean.nc
   cdo sellonlatbox,0,360,-90,-60 $SCRATCHDIR/SIPN/area_cell_C3S_ocean.nc $outfile
fi
outfilekm=$outdir/area_cell_C3S_SP_ocean_km2.nc
if [[ ! -f $outfilekm ]]
then
   cdo divc,1000000 $outfile $outfilekm
fi
outfilet=$outdir/tot_ocean_area_C3S_SP_km2.nc
if [[ ! -f $outfilet ]]
then
   cdo fldsum $outfilekm $outfilet
fi

