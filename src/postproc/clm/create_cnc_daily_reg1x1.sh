#!/bin/sh -l
#BSUB -P 0490
#BSUB -J cnc
#BSUB -e /work/cmcc/cp2/scratch/CERISE/logs/cnc_%J.err
#BSUB -o /work/cmcc/cp2/scratch/CERISE/logs/cnc_%J.out
#BSUB -M 10000
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -euvx
cd  $SCRATCHDIR/CERISE
cdo -selvar,PCT_NATVEG /data/inputs/CESM/inputdata/lnd/clm2/surfdata_map/surfdata_0.47x0.63_SSP5-8.5_16pfts_Irrig_CMIP6_simyr1850_c231218.nc PCT_NATVEG.nc
ncrename -d lsmlat,lat PCT_NATVEG.nc
ncrename -d lsmlon,lon PCT_NATVEG.nc
cdo -selvar,lsm $REPOSITORY1/lsm_sps4.nc prova.nc
ncks -A PCT_NATVEG.nc prova.nc
cp prova.nc $SCRATCHDIR/CERISE/PCT_NATVEG_latlon.nc
cdo remapbil,$REPOGRID1/griddes_C3S.txt $SCRATCHDIR/CERISE/PCT_NATVEG_latlon.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.nc

ncwa -O -a time $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.tmp2.nc
ncks -O -x -v time,lsm $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.tmp2.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.tmp.nc
list="$SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.tmp.nc"
for i in $(seq 1 124)
do
  list+=" $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.tmp.nc"
done
ncecat $list $SCRATCHDIR/CERISE/output.nc
ncrename -d record,time $SCRATCHDIR/CERISE/output.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1_125days.nc
