#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

yyyy=$1
mm=$2


archdir=/data/csp/sp1/archive/OIS/data_oce/noaa_sst  # repository dati daily --> trasformare in monthly
actualdir=/work/csp/sp1/SPS/CMCC-OIS/input/oper_daily/noaa_sst
#${inputdata_sp1}/noaa_sst/clim_1993-2016 # climatologie daily --> trasformare in monthly
noaa_dir=$3
climdir=/work/csp/sp2/VALIDATION/NOAA_SST/clim  
anomdir=${noaa_dir}/anom
mkdir -p $anomdir

cd $noaa_dir

yyyybini=`date -d "$yyyy${mm}01 -1 year" +%Y` 
mmbini=`date -d "$yyyy${mm}01 -1 month" +%m`
yyyym1=`date -d "$yyyy${mm}01 -1 month" +%Y`
yyyyb=$yyyybini
mmb=$mmbini
for time in `seq 1 12` ; do

  if [ -f $archdir/noaa_sst_${yyyyb}${mm}.tgz ] ; then
     cp $archdir/noaa_sst_${yyyyb}${mm}.tgz .
     tar -xvf  noaa_sst_${yyyyb}${mm}.tgz
     cdo -O ensmean sst_y${yyyyb}m${mm}d??.nc sst_y${yyyyb}m${mm}.nc
     rm noaa_sst_${yyyyb}${mm}.tgz sst_y${yyyyb}m${mm}d??.nc
  else
     cdo -O ensmean $actualdir/sst_y${yyyyb}m${mm}d??.nc sst_y${yyyyb}m${mm}.nc
  fi
  cdo sub sst_y${yyyyb}m${mm}.nc $climdir/sst_m${mm}.nc $anomdir/anom_sst_y${yyyyb}m${mm}.nc
  rm sst_y${yyyyb}m${mm}.nc

  yyyyb=`date -d "$yyyyb${mm}01 +1 month" +%Y`
  mm=`date -d "$yyyyb${mm}01 +1 month" +%m`
  echo $yyyyb
  echo $mm
done

cd $anomdir
sstflist=`ls -1 anom_sst_y????m??.nc`
ncrcat -O $sstflist anom_sst_${yyyybini}${mm}-${yyyym1}${mmbini}.nc
rm $sstflist

exit  

