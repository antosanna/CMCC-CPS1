#!/bin/sh -l
#BSUB -J plotItaly
#BSUB -e plotItaly_%J.err
#BSUB -o plotItaly_%J.out
#BSUB -P 0784
#BSUB -M 1000

. $DIR_UTIL/descr_CPS.sh
. ~/load_miniconda
conda activate miniconda_ncl
export NCARG_COLORMAPS=$HOME/ncl/colormaps

set -euvx
lead=1
export yyyyfore=2026
export mmfore=01
export SS=FMA
export inputmall="$DIR_FORE_ANOM/"$yyyyfore$mmfore"/t2m_sps4_"$yyyyfore$mmfore"_all_ano.1993-2022.nc"
export p_inputmall="$DIR_FORE_ANOM/"$yyyyfore$mmfore"/precip_sps4_"$yyyyfore$mmfore"_all_ano.1993-2022.nc"

export prob_low="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/t2m_"$mmfore"_l"$lead"_33.1993-2022.nc"
export prob_up="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/t2m_"$mmfore"_l"$lead"_66.1993-2022.nc"

export prec_prob_low="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/precip_"$mmfore"_l"$lead"_33.1993-2022.nc"
export prec_prob_up="/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/pctl/"$mmfore"/precip_"$mmfore"_l"$lead"_66.1993-2022.nc"

export cmcc_logo=$PWD/cmcc_logo_bw.jpg
export shapefdir=/work/cmcc/cp1/shape_files/Italy.0/

export pltype=x11
#ncl test_shapefiles2.ncl
ncl forecast_summary_Italy_annotations.ncl

