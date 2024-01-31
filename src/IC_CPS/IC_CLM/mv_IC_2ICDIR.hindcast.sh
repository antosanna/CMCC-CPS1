#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx

###procedure to move and rename restart from EDA clm land-only experiments to CPS IC dir

yyyy=$1    
st=$2  
ppland=$3
pp=`printf '%.2d' $((10#$ppland))`


if [[ $yyyy -lt $yyyySCEN ]] ; then
    clm_case=cm3_lndHIST_bgc_NoSnAg_eda${ppland}_hist
else
    if [[ $yyyy -eq $yyyySCEN ]] && [[ $st -eq 01 ]] ; then
        clm_case=cm3_lndHIST_bgc_NoSnAg_eda${ppland}_hist
    else
        clm_case=cm3_lndSSP5-8.5_bgc_NoSnAg_eda${ppland}_scen
    fi
fi

clm_rest_file=$DIR_ARCHIVE/${clm_case}/rest/$yyyy-$st-01-00000/${clm_case}.clm2.r.${yyyy}-${st}-01-00000.nc
hydros_rest_file=$DIR_ARCHIVE/${clm_case}/rest/$yyyy-$st-01-00000/${clm_case}.hydros.r.${yyyy}-${st}-01-00000.nc

if [[ -f ${clm_rest_file} ]] ; then
   rsync -auv ${clm_rest_file} $IC_CLM_CPS_DIR1/$st/${CPSSYS}.clm2.r.${yyyy}-${st}-01-00000.$pp.nc
fi
if [[ -f ${hydros_rest_file} ]] ; then
   rsync -auv ${hydros_rest_file} $IC_CLM_CPS_DIR1/$st/${CPSSYS}.hydros.r.${yyyy}-${st}-01-00000.$pp.nc
fi
