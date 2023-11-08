#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
#mymail=antonella.sanna@cmcc.it
set -euvx
export yyyy=$1
export st=$2

. $DIR_UTIL/descr_hindcast.sh $yyyy

#export yyyy=2020
#export st=11
sst=1
sss=1
export diri=$SCRATCHDIR/nemo_timeseries/$yyyy$st
export pltdir=$diri/plots
export nmon=$nmonfore
mkdir -p $diri/plots
if [ $sst -eq 1 ]
then
   export var="sosstsst"
   export outvar="sst"
   export pltype="png"
   export pltname="${SPSSystem}_"$yyyy$st"_"$outvar"_timeseries"
   export filename=_sst_series.nc
   ncl ncl/sst_sss_series.ncl
fi
if [ $sss -eq 1 ]
then
   export var="sosaline"
   export outvar="sss"
   export pltype="png"
   export pltname="${SPSSystem}_"$yyyy$st"_"$outvar"_timeseries"
   export filename=_sss_series.nc
   ncl ncl/sst_sss_series.ncl
fi
echo "plots are here " $diri/plots
convert $diri/plots/${SPSSystem}_${yyyy}${st}_*_timeseries.png $diri/plots/${SPSSystem}_${yyyy}${st}_nemo_timeseries.pdf

exit 0
