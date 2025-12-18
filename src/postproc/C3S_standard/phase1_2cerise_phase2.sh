#!/bin/sh -l
#BSUB -P 0490
#BSUB -J test
#BSUB -M 1000
#BSUB -e ../../../logs/test_%J.err
#BSUB -o ../../../logs/test_%J.out
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
set -euvx

#==================================================
caso=$1
FINALDIR=$2

st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
mem=`echo $caso|cut -d '_' -f 3|cut -c 2-3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

GCM_name1=${GCM_name}-v${versionSPS}
GCM_name2=CERISE-${GCM_name}-demonstrator2-v${versionSPS}

term_phase1=cmcc_CERISE-${GCM_name1}_${typeofrun}_S${yyyy}${st}0100


mkdir -p $WORK_CERISE/$yyyy$st

mkdir -p $FINALDIR

lista=`ls $WORK_CERISE/$yyyy$st/${term_phase1}*r${mem}i00p00.nc`
for ff in $lista
do
   newff=`basename $ff|sed "s/${GCM_name1}/${GCM_name2}/"`
   cp $ff $FINALDIR/$newff
   ncatted -O -h -a commit,global,o,c,"2023-11-01T9:35:32Z https://www.cmcc.it/it/publications/tn0301-the-new-cmcc-seasonal-prediction-system-SPS4" $FINALDIR/$newff
   ncatted -O -h -a summary,global,o,c,"Seasonal Forecast data produced by CMCC as its contribution to the CERISE project (demonstrator2). The data has global coverage with a 1-degree horizontal resolution and spans for around 6 months since the start date " $FINALDIR/$newff
   ncatted -O -h -a title,global,o,c,"CMCC seasonal forecast model output prepared for CERISE project (demonstrator2)" $FINALDIR/$newff
   ncatted -O -h -a source,global,o,c,"CERISE-${GCM_name2}-v20231101:  atmos: CAM(fv_0.47x0.63 L83); ocean: NEMOv4.2 (ORCA0.25_z75, 0.25x0.25L75); land: CLM(fv_0.47x0.63 L25); seaice: CICE(same horizontal resolution of NEMO)" $FINALDIR/$newff
   if [[ $ff =~ "sftlf" ]]
   then
      ncatted -a valid_min,sftlf,o,c,0 $FINALDIR/$newff
      ncatted -a valid_max,sftlf,o,c,1 $FINALDIR/$newff
   fi
done
