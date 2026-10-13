#!/bin/sh -l 
#BSUB -P 0784
#BSUB -M 2000
#BSUB -J alpha_extended
#BSUB -e logs/alpha_extended_%J.err
#BSUB -o logs/alpha_extended_%J.out
# script to run the postprocessing C3S on Juno (from DMO produced elsewhere) run from crontab
# THIS SCRIPT RAN ON cp2 USER

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo

set -euvx

INPUTDIR=/data/cmcc/cp1/CMCC-CPS1/files4CPS1/alpha_100m_wind
WKDIR=$SCRATCHDIR/ANTO/alpha_100m_wind_extended
mkdir -p $WKDIR/tmp

for st in 01 
do
   cdo splitmon $INPUTDIR/mean_alpha_${st}.nc $WKDIR/mean_alpha_
done
#
for st in 07 
do
   cdo splitmon $INPUTDIR/mean_alpha_${st}.nc $WKDIR/tmp/mean_alpha_
done
mv $WKDIR/tmp/mean_alpha_07.nc $WKDIR/tmp/mean_alpha_08.nc $WKDIR/tmp/mean_alpha_09.nc $WKDIR/tmp/mean_alpha_10.nc $WKDIR/tmp/mean_alpha_11.nc $WKDIR/tmp/mean_alpha_12.nc $WKDIR
for st in 05 06 07 08 09 10 11 12 01 02 03 04
do
   cdo setreftime,1992-11-01,00:00:00,1day $WKDIR/mean_alpha_${st}.nc $WKDIR/mean_alpha_${st}_reftime.nc
done
for st in 01 02 03 04 
do
   cdo shifttime,1year $WKDIR/mean_alpha_${st}_reftime.nc $WKDIR/mean_alpha_${st}_reftime_fix.nc
done
# add the first 3 days of March
cdo splitday $WKDIR/mean_alpha_03_reftime_fix.nc $WKDIR/mean_alpha_03_reftime_fix_
cdo mergetime $WKDIR/mean_alpha_05_reftime.nc $WKDIR/mean_alpha_06_reftime.nc $WKDIR/mean_alpha_07_reftime.nc $WKDIR/mean_alpha_08_reftime.nc $WKDIR/mean_alpha_09_reftime.nc $WKDIR/mean_alpha_10_reftime.nc $WKDIR/mean_alpha_11_reftime.nc $WKDIR/mean_alpha_12_reftime.nc $WKDIR/mean_alpha_01_reftime_fix.nc $WKDIR/mean_alpha_02_reftime_fix.nc $WKDIR/mean_alpha_03_reftime_fix_01.nc $WKDIR/mean_alpha_03_reftime_fix_02.nc $WKDIR/mean_alpha_03_reftime_fix_03.nc $WKDIR/mean_alpha_03_reftime_fix_04.nc $WKDIR/mean_alpha_extended_11_tmp.nc

# selected the requested days
cdo seltimestep,17/1229 $WKDIR/mean_alpha_extended_11_tmp.nc $WKDIR/mean_alpha_extended_11.nc
