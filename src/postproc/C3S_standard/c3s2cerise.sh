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

GCM_and_version=${GCM_name}-v${versionSPS}
orig_term=cmcc_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100


mkdir -p $WORK_CERISE/$yyyy$st
lista=`ls $WORK_C3S1/$yyyy$st/${orig_term}*r${mem}i00p00.nc| grep -v ocean_mon`
for ff in $lista
do
   newff=`basename $ff|sed "s/cmcc_/cmcc_CERISE-/"`
   ncatted -O -h -a references,global,o,c,"The new CMCC Seasonal Prediction System SPS4, CMCC report TN301, http://www.cmcc.it/publications/tn0301-the-new-cmcc-seasonal-prediction-system-SPS4" $ff $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a contact,global,o,c,"https://www.cerise-project.eu/" $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a project,global,o,c,"CERISE" $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a commit,global,o,c,"2023-11-01T9:35:32Z https://www.cmcc.it/it/publications/tn0301-the-new-cmcc-seasonal-prediction-system-SPS4" $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a summary,global,o,c,"Seasonal Forecast data produced by CMCC as its contribution to the CERISE project. The data has global coverage with a 1-degree horizontal resolution and spans for around 6 months since the start date " $WORK_CERISE/$yyyy$st/$newff
   ncatted -O -h -a title,global,o,c,"CMCC seasonal forecast model output prepared for CERISE project" $WORK_CERISE/$yyyy$st/$newff
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

