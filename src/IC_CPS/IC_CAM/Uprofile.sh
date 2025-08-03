#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

export st=$1
export yyyy=$2
launchdir=$3
export fileok=$4
export pltname=$5
cd $launchdir

export pltype="png"
export diric=$IC_CAM_CPS_DIR/$st
export filename="${CPSSYS}.cam.i.${yyyy}-${st}-01-00000."
if [ `ls $diric/$filename*gz |wc -l` -ne 0 ]
then
   gunzip $diric/$filename*gz
fi
export lat1=50
export lat2=60

ncl $launchdir/Uprofile.ncl
#gzip $diric/$filename*nc  
