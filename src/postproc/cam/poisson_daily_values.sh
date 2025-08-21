#!/bin/sh -l
#--------------------------------

# this script identifies the spikes in a daily timeseries, derives from it the corresponding index in the appropriate actual timeseries (daily, 6hourly or 12hourly) and fixes through poisson extrapolation, setting to mask an arbitrary selected region around the spike and filling it through poisson.
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_cdo
set -euvx

export ftype=$1
export caso=$2
export inputascii=$3
export inputFV=$4
export outputFV=$5
export checkfile=$6

export HEALED_DIR=$HEALED_DIR_ROOT/$caso

yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
mem=`echo $caso|cut -d '_' -f3|cut -c 2-3`
export npoints=3
export templateFileName=$HEALED_DIR/$caso.cam.h3.${yyyy}-${st}.TREFMNAV.nc
if [[  -f $checkfile ]]
then
   rm $checkfile
fi
if [[ ! -f $templateFileName ]]
then
   cdo shifttime,-12hours -selvar,TREFMNAV $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h3.${yyyy}-${st}.zip.nc $templateFileName
fi
case $ftype in
   h1)export frq=6hr;;
   h2)export frq=12hr;;
   h3)export frq=day;;
   h4)export frq=3hr;;
esac
if [[ -f $outputFV ]] 
then
   rm $outputFV
fi
rsync -av $DIR_POST/cam/poisson_daily_values.ncl `dirname $checkfile`/poisson_daily_values.$caso.$ftype.ncl
ncl `dirname $checkfile`/poisson_daily_values.$caso.$ftype.ncl
#ncl poisson_daily_values.ncl
