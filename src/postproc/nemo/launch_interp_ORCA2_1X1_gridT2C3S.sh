#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
 . $DIR_UTIL/load_ncl

set -euvx

caso=$1
var=$2
wkdir=$3

member=`echo ${caso}|cut -d '_' -f3|cut -c 2,3`
set +euvx
. $dictionary
set -euvx
export check_oceregrid_var=${check_oceregrid}_${var}
export real="r"${member}"i00p00"
export st=`echo ${caso}|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo ${caso}|cut -d '_' -f 2|cut -c 1-4`
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

export lsmfile="$REPOGRID/SPS4_C3S_LSM.nc"
export domainfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_domain_cfg.nc"
export meshmaskfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
export srcGridName="$REPOGRID/ORCA_SCRIP_gridT.nc"
export dstGridName="$REPOGRID/World1deg_SCRIP_gridT.nc"
export wgtFile="$REPOGRID/ORCA_2_World_SCRIP_gridT.nc"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
OUTDIR_NEMO=$DIR_ARCHIVE/${caso}/ocn/hist/
#echo 'fine ncrcat ' `date`
export C3S_table_ocean2d="$DIR_POST/nemo/C3S_table_ocean2d_${var}.txt"
scriptname=interp_ORCA2_1X1_gridT2C3S.ncl

prefix=${GCM_name}-v${versionSPS}
export fore_type=$typeofrun
export frq="mon"
export level="ocean2d"

export ini_term="cmcc_${prefix}_${typeofrun}_S${yyyy}${st}0100"


echo "---------------------------------------------"
echo "launching $scriptname "`date`
echo "---------------------------------------------"
ncl ${wkdir}/$scriptname
echo "---------------------------------------------"
echo "executed $scriptname "`date`
echo "---------------------------------------------"
