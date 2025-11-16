#!/bin/sh -l
#--------------------------------

# this script identifies the spikes in a daily timeseries, derives from it the corresponding index in the appropriate actual timeseries (daily, 6hourly or 12hourly) and fixes through poisson extrapolation, setting to mask an arbitrary selected region around the spike and filling it through poisson.
set +euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_cdo
set -euvx

export ftype=$1
export model=$2
export caso=$3
export inputascii=$4
export inputFV=$5
export outputFV=$6
export checkfile=$7

export HEALED_DIR=$HEALED_DIR_ROOT/$caso/CAM/healing

yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
mem=`echo $caso|cut -d '_' -f3|cut -c 2-3`
export lastday=$(( $fixsimdays - 1 ))
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
if [[ $model == "cam" ]]
then
   case $ftype in
      h1)export frq=6hr;;
      h2)export frq=12hr;;
      h3)export frq=day;;
      h4)export frq=3hr;;
   esac
elif [[ $model == "clm2" ]]
then
   case $ftype in
      h1)export frq=day;;
      h2)export frq=6hr;;
      h3)export frq=day;;
   esac
fi
if [[ -f $outputFV ]] 
then
   rm $outputFV
fi
rsync -av $DIR_C3S/poisson_daily_values.ncl `dirname $checkfile`/poisson_daily_values.$caso.$model.$ftype.ncl
ncl `dirname $checkfile`/poisson_daily_values.$caso.$model.$ftype.ncl
#ncl poisson_daily_values.ncl
