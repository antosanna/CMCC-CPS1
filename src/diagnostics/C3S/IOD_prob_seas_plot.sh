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
export refperiod=1993-2016
export yym1=`date -d "${yyyy}${st}01 -1 month" +%Y`
export stm1=`date -d "${yyyy}${st}01 -1 month" +%m`  #$((10#$st - 1))
export yymp1=`date -d "${yyyy}${st}01 +1 month" +%Y`
export stp1=`date -d "${yyyy}${st}01 +1 month" +%m`  #$((10#$st - 1))

export figtype="png"

export inputmall="$anomdir/${varm}_${SPSSYS}_sps_${yyyy}${st}_all_ano.1993-2016.nc"
export inputmclimall="$datadir/${varm}/C3S/anom/${varm}_${SPSSYS}_${st}_all_ano.1993-2016.nc"

echo "PLOTTING IOD"
cd ${DIR_DIAG_C3S}/ncl
ncl IOD_prob_seas_plot.ncl

echo "PLOTTING IOD. DONE"
