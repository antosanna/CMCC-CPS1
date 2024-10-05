#!/bin/sh

set -evx

export yyyy=$1
export st=$2
export REG=$3
export dirplots=$4
varm=$5
export dir=$6
export anomdir=$7
export nens=$8
datadir=${DIR_CLIM}/monthly


# do not modify
export refperiod=$iniy_hind-$endy_hind
export yym1=`date -d "${yyyy}${st}01 -1 month" +%Y`
export stm1=`date -d "${yyyy}${st}01 -1 month" +%m`  #$((10#$st - 1))
export yymp1=`date -d "${yyyy}${st}01 +1 month" +%Y`
export stp1=`date -d "${yyyy}${st}01 +1 month" +%m`  #$((10#$st - 1))

export figtype="png"

export inputmall="$anomdir/${varm}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc"
export inputmclimall=$DIR_CLIM/monthly/$varm/C3S/anom/${varm}_${SPSSystem}_${st}_all_ano.$refperiod.nc"

echo "PLOTTING IOD"
cd ${DIR_DIAG_C3S}/ncl
ncl IOD_prob_seas_plot.ncl

echo "PLOTTING IOD. DONE"
