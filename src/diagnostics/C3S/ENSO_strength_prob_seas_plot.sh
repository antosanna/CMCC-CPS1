#!/bin/sh -l

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_ncl

set -evxu

export yyyy=$1
export st=$2
export REG=$3
export dirplots=$4
export workdir=$5
export anomdir=$6
datadir=$DIR_CLIM/monthly
export varm=sst


set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu
export SPSSystem
export nrunhind
export nyearhc=$(($endy_hind-$iniy_hind + 1))
export nens=$nrunC3Sfore
# do not modify
export refperiod=$iniy_hind-$endy_hind
export yym1=`date -d "${yyyy}${st}01 -1 month" +%Y`
export stm1=`date -d "${yyyy}${st}01 -1 month" +%m`  #$((10#$st - 1))
export yymp1=`date -d "${yyyy}${st}01 +1 month" +%Y`
export stp1=`date -d "${yyyy}${st}01 +1 month" +%m`  #$((10#$st - 1))

export nens=$nrunC3Sfore

echo $nens
export figtype="png"

export stdfile=${DIR_RONI}/std4RONI_tropic_${REG}_sst.${st}.${refperiod}.seasonal.nc

export inputmall="$anomdir/${varm}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc"
export inputmclimall="$DIR_CLIM/monthly/$varm/C3S/anom/${varm}_${SPSSystem}_${st}_all_ano.$refperiod.nc"
case $REG
  in
    Nino1+2) export lat1n=-10 ; export lat2n=0 ;export lon1n=270 ; export lon2n=280 ;;
    Nino3)   export lat1n=-5 ; export lat2n=5 ;export lon1n=210 ; export lon2n=270 ;;
    Nino3.4) export lat1n=-5 ; export lat2n=5 ;export lon1n=190 ; export lon2n=240 ;; 
    Nino4)   export lat1n=-5 ; export lat2n=5 ;export lon1n=160 ; export lon2n=210 ;;
esac

echo "PLOTTING ENSO PROB"

cd ${DIR_DIAG_C3S}/ncl
ncl ENSO_strength_prob_seas_plot.ncl
ncl ENSO_relative_strength_prob_seas_plot.ncl

echo "PLOTTING ENSO PROB. DONE"
