#!/bin/sh -l
#BSUB -P 0490
#BSUB -J test
#BSUB -M 1000
#BSUB -e ../../../logs/test_%J.err
#BSUB -o ../../../logs/test_%J.out
# this script can be run in dbg mode but always with submitcommand
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
set -euvx

#==================================================
caso=$1
st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
mem=`echo $caso|cut -d '_' -f 3|cut -c 2-3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

version_phase1=v${versionSPS}
version_phase2=v20251101

term_phase1=cmcc_CERISE-${GCM_name}-${version_phase1}_${typeofrun}_S${yyyy}${st}0100
#term_phase2=cmcc_CERISE-${GCM_name}-${version_phase2}_${typeofrun}_S${yyyy}${st}0100


mkdir -p $WORK_CERISE/$yyyy$st
lista=`ls $WORK_CERISE/$yyyy$st/${term_phase1}*r${mem}i00p00.nc`
for ff in $lista
do
   newff=`basename $ff|sed "s/${versione_phase1}/${versione_phase2}/"`
   ncatted -O -h -a commit,global,o,c,"2025-11-01T9:35:32Z https://www.cmcc.it/it/publications/tn0301-the-new-cmcc-seasonal-prediction-system-SPS4" $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a summary,global,o,c,"Seasonal Forecast data produced by CMCC as its contribution to the CERISE project (phase 2). The data has global coverage with a 1-degree horizontal resolution and spans for around 6 months since the start date " $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a title,global,o,c,"CMCC seasonal forecast model output prepared for CERISE project (phase 2)" $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a source,global,o,c,"cerise-CMCC-CM3-v20251101:  atmos: CAM(fv_0.47x0.63 L83); ocean: NEMOv4.2 (ORCA0.25_z75, 0.25x0.25L75); land: CLM(fv_0.47x0.63 L25); seaice: CICE(same horizontal resolution of NEMO)" $WORK_CERISE/$yyyy$st/$newff
   if [[ $ff =~ "sftlf" ]]
   then
      ncatted -a valid_min,sftlf,o,c,0 $WORK_CERISE/$yyyy$st/$newff
      ncatted -a valid_max,sftlf,o,c,1 $WORK_CERISE/$yyyy$st/$newff
   fi
done

cdo copy $SCRATCHDIR/CERISE/PCT_NATVEG.nc $SCRATCHDIR/CERISE/infile_cat.nc

for i in $(seq 1 185)
do
  shift="${i}day" 
  cdo -shifttime,${shift} $SCRATCHDIR/CERISE/PCT_NATVEG.nc $SCRATCHDIR/CERISE/next_day.nc
  cdo -cat $SCRATCHDIR/CERISE/infile_cat.nc $SCRATCHDIR/CERISE/next_day.nc $SCRATCHDIR/CERISE/tmp.nc
  mv $SCRATCHDIR/CERISE/tmp.nc $SCRATCHDIR/CERISE/infile_cat.nc
done

