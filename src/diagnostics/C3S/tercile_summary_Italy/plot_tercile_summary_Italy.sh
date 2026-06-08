#!/bin/sh -l
#BSUB -J plotItaly
#BSUB -e /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/plotItaly_%J.err
#BSUB -o /work/cmcc/cp1//CPS/CMCC-CPS1/logs/forecast/plotItaly_%J.out
#BSUB -P 0784
#BSUB -M 1000

. $DIR_UTIL/descr_CPS.sh
. ~/load_miniconda
conda activate miniconda_ncl
export NCARG_COLORMAPS=$HOME/ncl/colormaps

set -euvx
lead=1
refperiod=1995-2024
export yyyyfore=`date +%Y`
export mmfore=`date +%m`
export SS
case $mmfore in
   04)SS=MJJ;;
   05)SS=JJA;;
   01)SS=FMA;;
esac
export inputmall="$DIR_FORE_ANOM/"$yyyyfore$mmfore"/t2m_sps4_"$yyyyfore$mmfore"_all_ano.$refperiod.nc"
export p_inputmall="$DIR_FORE_ANOM/"$yyyyfore$mmfore"/precip_sps4_"$yyyyfore$mmfore"_all_ano.$refperiod.nc"

export prob_low="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/t2m_"$mmfore"_l"$lead"_33.$refperiod.nc"
export prob_up="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/t2m_"$mmfore"_l"$lead"_66.$refperiod.nc"

export prec_prob_low="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/precip_"$mmfore"_l"$lead"_33.$refperiod.nc"
export prec_prob_up="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/precip_"$mmfore"_l"$lead"_66.$refperiod.nc"

export cmcc_logo=$PWD/cmcc_logo_bw.jpg
export shapefdir=/work/cmcc/cp1/shape_files/Italy.0/

export pltype=png
mkdir -p $SCRATCHDIR/BRIEFINGS/GruppoTecnicoPrevisioni/$yyyyfore$mmfore
export pltname=$SCRATCHDIR/BRIEFINGS/GruppoTecnicoPrevisioni/$yyyyfore$mmfore/tercile_summary_annotation_Italy_${yyyyfore}${mmfore}_${SS}.png
#ncl test_shapefiles2.ncl
ncl forecast_summary_Italy_annotations.ncl

