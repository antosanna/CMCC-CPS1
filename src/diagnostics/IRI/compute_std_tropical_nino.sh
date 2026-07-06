#!/bin/sh -l
#BSUB -J compute_std_tropical_nino
#BSUB -e /work/cmcc/cp2/CPS/CMCC-CPS1/logs/tests/compute_std_tropical_nino_%J.err
#BSUB -o /work/cmcc/cp2/CPS/CMCC-CPS1/logs/tests/compute_std_tropical_nino_%J.out
#BSUB -P 0784
#BSUB -M 3000
#BSUB -q s_medium

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
set -euvx
WORK_SCORES1=/work/cmcc/cp1/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4/
outdir=$WORK/CPS/CMCC-CPS1/rel_nino3.4
mkdir -p $outdir

#Nino3.4)  lt1=-5 ; lt2=5 ;lg1=190 ; lg2=240
export lat1n=-5
export lat2n=5
export lon1n=190
export lon2n=240

export lat1t=-20
export lat2t=20
export lon1t=0
export lon2t=360

export iniy_hind=1993
export endy_hind=2020

export iniy=${iniy_hind}
export endy=${endy_hind}

export sysname=`echo "${SPSSystem}" | tr '[:lower:]' '[:upper:]'`

for st in `seq -w 01 12`
do
    export hind_anom_file=${WORK_SCORES1}/monthly/sst/C3S/anom/sst_sps4_${st}_all_ano.${iniy_hind}-${endy_hind}.nc
    export outfile=${outdir}/std4RONI_tropic_nino_sst.${st}.sea.${iniy_hind}-${endy_hind}.nc
    ncl compute_std_tropical_nino_sea.ncl
done
