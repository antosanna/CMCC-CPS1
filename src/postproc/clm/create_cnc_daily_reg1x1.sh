#!/bin/sh -l
#BSUB -P 0490
#BSUB -J cnc
#BSUB -e /work/cmcc/as34319/scratch/CERISE/logs/cnc_%J.err
#BSUB -o /work/cmcc/as34319/scratch/CERISE/logs/cnc_%J.out
#BSUB -M 1000
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -euvx
#cdo -selvar,PCT_NATVEG /data/inputs/CESM/inputdata/lnd/clm2/surfdata_map/surfdata_0.47x0.63_SSP5-8.5_16pfts_Irrig_CMIP6_simyr1850_c231218.nc PCT_NATVEG.nc
#ncrename -d lsmlat,lat PCT_NATVEG.nc
#ncrename -d lsmlon,lon PCT_NATVEG.nc
#cdo -selvar,lsm $REPOSITORY1/lsm_sps4.nc $SCRATCHDIR/tmp/prova.nc
#ncks -A PCT_NATVEG.nc ../tmp/prova.nc
#cp ../tmp/prova.nc $SCRATCHDIR/CERISE/PCT_NATVEG_latlon.nc
#cdo remapbil,$REPOGRID1/griddes_C3S.txt $SCRATCHDIR/CERISE/PCT_NATVEG_latlon.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.nc
cp $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.nc $SCRATCHDIR/CERISE/infile_cat.nc

for i in $(seq 1 184)
do
  shift="${i}day" 
  cdo -shifttime,${shift} $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1.nc $SCRATCHDIR/CERISE/next_day.nc
  cdo -cat $SCRATCHDIR/CERISE/infile_cat.nc $SCRATCHDIR/CERISE/next_day.nc $SCRATCHDIR/CERISE/tmp.nc
  mv $SCRATCHDIR/CERISE/tmp.nc $SCRATCHDIR/CERISE/infile_cat.nc
done
cdo setreftime,1993-05-01,12:00:00 $SCRATCHDIR/CERISE/infile_cat.nc $SCRATCHDIR/CERISE/infile_tref.nc
cdo settaxis,1993-05-01,12:00:00,1day $SCRATCHDIR/CERISE/infile_tref.nc $SCRATCHDIR/CERISE/PCT_NATVEG_reg1x1_185days.nc
ncrename -v PCT_NATVEG,cnc $SCRATCHDIR/CERISE/cnc_reg1x1_185days.nc
rm infile_cat.nc next_day.nc
