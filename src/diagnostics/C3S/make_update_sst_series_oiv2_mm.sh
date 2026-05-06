#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

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
url="https://downloads.psl.noaa.gov/Datasets/noaa.oisst.v2/sst.mnmean.nc"
mkdir -p $DIR_LOG/wrapper
${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j wget_wrapper_iod -l $DIR_LOG/wrapper -d ${DIR_UTIL} -s wget_wrapper.sh -i "$ncep_dir $url"

while `true`
do
    njob=`$DIR_UTIL/findjobs.sh -m $machine -n wget_wrapper_iod -c yes`
    if [[ $njob -eq 0 ]]
    then
       break
    fi  
    sleep 60
done

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

