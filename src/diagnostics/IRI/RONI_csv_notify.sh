#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh 
. ${DIR_UTIL}/load_ncl
set -evxu

#export yyyy=$1
#export st=$2
#export dirplots=$3
#workdir=$4
#export anomdir=$5
#export ncep_dir=$6

export yyyy=2026
export st=06
export csvdir=$WORK/CPS/CMCC-CPS1/IRI_csv_files/$yyyy$st
mkdir -p $csvdir
workdir=$csvdir
DIR_FORE_ANOM=/work/cmcc/cp1/CPS/CMCC-CPS1/forecast_anom  #from descriptor, to be commented
export anomdir=${DIR_FORE_ANOM}/$yyyy$st
export SPSSystem
#
set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu

export iniy_hind=1993
export endy_hind=2020
export nens=$nrunC3Sfore
export nrunhind
export nyearhc=$(($endy_hind-$iniy_hind + 1))

# do not modify
export refperiod=$iniy_hind-$endy_hind
export yyyym7=`date -d "${yyyy}${st}01 -7 month" +%Y`   #$(($yyyy - 1))
export stm7=`date -d "${yyyy}${st}01 -7 month" +%m`  #$((10#$st - 1))
export figtype="png"
tmpdir2replace=$SCRATCHDIR/ANDREA/RONI
export stdfile=$tmpdir2replace/std4RONI_tropic_nino_sst.${st}.${refperiod}.nc

###NINO3.4 box
export lat1n=-5  
export lat2n=5
export lon1n=190 
export lon2n=240
###Tropical band
export lat1t=-20  
export lat2t=20
export lon1t=0 
export lon2t=360

echo "WRITING RONI ON CSV FILE..."
cd $PWD
#cd $DIR_DIAG_C3S/ncl

ncl RONI_sea_csv.ncl

