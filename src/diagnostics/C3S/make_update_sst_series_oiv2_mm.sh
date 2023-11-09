#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

yyyy=$1
mm=$2

ncep_dir=$SCRATCHDIR/VALIDATION/NCEP/sst/oiv2
climdir=$ncep_dir/clim  
mkdir -p $climdir
anomdir=$ncep_dir/anom
mkdir -p $anomdir

cd $ncep_dir

yyyybini=`date -d "$yyyy${mm}01 -5 month" +%Y` 
mmbini=`date -d "$yyyy${mm}01 -5 month" +%m`

yyyyb=$yyyybini
mm=$mmbini

if [ -f sst.mnmean.nc ] ; then
   rm sst.mnmean.nc
fi
wget -4 --no-check-certificate https://downloads.psl.noaa.gov/Datasets/noaa.oisst.v2/sst.mnmean.nc

for time in `seq 1 5` ; do

  cdo selmon,${mm} -selyear,${yyyyb} ${ncep_dir}/sst.mnmean.nc sst_y${yyyyb}m${mm}.nc
  if [ ! -f $climdir/sst_m${mm}.nc ] ; then 
     cdo timmean -selmon,${mm} -selyear,1993/2016 ${ncep_dir}/sst.mnmean.nc $climdir/sst_m${mm}.nc 
  fi
  cdo sub sst_y${yyyyb}m${mm}.nc $climdir/sst_m${mm}.nc $anomdir/anom_sst_y${yyyyb}m${mm}.nc
  rm sst_y${yyyyb}m${mm}.nc

  if [[ $time -eq 5 ]] ; then
     break
  fi
  yyyyb=`date -d "$yyyyb${mm}01 +1 month" +%Y`
  mm=`date -d "$yyyyb${mm}01 +1 month" +%m`
  echo $yyyyb
  echo $mm
done

cd $anomdir
sstflist=`ls -1 anom_sst_y????m??.nc`
cdo -O mergetime $sstflist anom_sst_${yyyybini}${mmbini}-${yyyy}${mm}.nc
rm $sstflist

exit  

