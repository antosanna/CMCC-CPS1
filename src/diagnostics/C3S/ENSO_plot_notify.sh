#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh 
. ${DIR_UTIL}/load_ncl
set -evxu

export yyyy=$1
export st=$2
export REG=$3
export dirplots=$4
workdir=$5
export anomdir=$6
export ncep_dir=$7
export SPSSystem
#
set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu
export nens=$nrunC3Sfore
export nrunhind
export nyearhc=$(($endy_hind-$iniy_hind + 1))

# do not modify
export refperiod=$iniy_hind-$endy_hind
export yyyym7=`date -d "${yyyy}${st}01 -7 month" +%Y`   #$(($yyyy - 1))
export stm7=`date -d "${yyyy}${st}01 -7 month" +%m`  #$((10#$st - 1))
export figtype="png"


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
