#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx
yyyy=$1
st=$2
sps=$3
var=$4
ftype=$5
datadir=$6
WKDIR=$7


FVvar_tmp=$WKDIR/${sps}.cam.$ftype.monthly.$var.nc
cdo -O monmean -selvar,$var $datadir/$sps.cam.$ftype.$yyyy-$st-01-00000.nc $FVvar_tmp
case $var in
    TREFHT)varout=t2m;;
    TS)varout=sst;;
    PRECT)varout=precip;;
    PSL)varout=mslp;;
    Z500)varout=z500;;
    U200)varout=u200;;
    V200)varout=v200;;
    T850)varout=t850;;
esac
FVvar_monthly=$WKDIR/${sps}.cam.$ftype.monthly.$varout.nc
cdo chname,$var,$varout $FVvar_tmp $FVvar_monthly

     # --- Now interpolate to 1x1 grid
outputC3S=$WKDIR/${sps}.reg1x1.$varout.nc
#            checkfile=$WKDIR/runtime_regridFV2C3S_${sps}.DONE
echo "time is" `date`
cdo remapbil,$REPOGRID/griddes_C3S.txt $FVvar_monthly $outputC3S
echo "time after remap is "`date`
