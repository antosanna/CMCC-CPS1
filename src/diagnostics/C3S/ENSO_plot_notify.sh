#!/bin/sh -l

set -evxu

export yyyy=$1
export st=$2
export REG=$3
export dirplots=$4
workdir=$5
export ncep_dir=$6
#
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
export nens=$nrunC3Sfore
export workdir_anom=$workdir/anom

# do not modify
export refperiod=1993-2016
export yyyym1=$(($yyyy - 1))
export figtype="png"

stm1=$((10#$st - 1))
if [ $stm1 -eq 0 ] ; then
    stm1=12
fi
export stm1=`printf "%.02d" $stm1`

case $st
    in
    01) export yyyy2=$(($yyyy - 1)) ;;
    *)  export yyyy2=$yyyy ;;
esac


export lt1=0
export lt2=0
export lg1=0
export lg2=0
case $REG
  in
    Nino1+2)   lt1=-10 ; lt2=0 ;lg1=270 ; lg2=280 ;;
    Nino3)   lt1=-5 ; lt2=5 ;lg1=210 ; lg2=270 ;;
    Nino3.4) lt1=-5 ; lt2=5 ;lg1=190 ; lg2=240 ;; 
    Nino4)   lt1=-5 ; lt2=5 ;lg1=160 ; lg2=210 ;;
esac

echo "PLOTTING ENSO"
cd $DIR_DIAG_C3S/ncl
ncl ENSO_plot.ncl

echo "PLOTTING ENSO. DONE"
