#!/bin/sh -l

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

export yyyy=$1
export st=$2
export REG=$3
export dirplots=$4
export workdir=$5
datadir=$DIR_CLIM/monthly
export varm=sst


if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi

# do not modify
export refperiod=1993-2016
export yym1=`date -d "${yyyy}${st}01 -1 month" +%Y`
export stm1=`date -d "${yyyy}${st}01 -1 month" +%m`  #$((10#$st - 1))
export yymp1=`date -d "${yyyy}${st}01 +1 month" +%Y`
export stp1=`date -d "${yyyy}${st}01 +1 month" +%m`  #$((10#$st - 1))

export nens=$nrunC3Sfore

echo $nens
export figtype="png"

export lt1=0
export lt2=0
export lg1=0
export lg2=0
export inputmall="$workdir/anom/${varm}_${SPSSYS}_sps_${yyyy}${st}_all_ano.1993-2016.nc"
export inputmclimall="$datadir/${varm}/C3S/anom/${varm}_${SPSSYS}_${st}_all_ano.1993-2016.nc"
case $REG
  in
    Nino1+2)   lt1=-10 ; lt2=0 ;lg1=270 ; lg2=280 ;;
    Nino3)   lt1=-5 ; lt2=5 ;lg1=210 ; lg2=270 ;;
    Nino3.4) lt1=-5 ; lt2=5 ;lg1=190 ; lg2=240 ;; 
    Nino4)   lt1=-5 ; lt2=5 ;lg1=160 ; lg2=210 ;;
esac

echo "PLOTTING ENSO PROB"

cd ${DIR_DIAG_C3S}/ncl
ncl ENSO_prob_seas_plot.ncl

echo "PLOTTING ENSO PROB. DONE"
