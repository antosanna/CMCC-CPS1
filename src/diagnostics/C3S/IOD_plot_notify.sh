#!/bin/sh -l

set -euvx

export yyyy=$1
export st=$2
export REG=$3
export dir=$4
export dirplots=$5
noaa_dir=$6
export dirobs=${noaa_dir}/anom
export anomdir=$7
export nens=$8
# do not modify
export refperiod=$iniy_hind-$endy_hind
export figtype="png"
export stm1=`date -d "${yyyy}${st}01-1 month" +%m`
export yyyym1=`date -d "${yyyy}${st}01-1 month" +%Y`
export yyyy2=`date -d "${yyyy}${st}01-12 month" +%Y`

echo "PLOTTING IOD"
cd ${DIR_DIAG_C3S}/ncl
ncl IOD_plot.ncl

echo "PLOTTING IOD. DONE"
