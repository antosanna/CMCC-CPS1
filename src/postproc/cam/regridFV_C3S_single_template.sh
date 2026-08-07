#!/bin/sh -l
##BSUB -P 0784
##BSUB -J test
##BSUB -e logs/test_%J.err
##BSUB -o logs/test_%J.out
# this script can be run in dbg mode but always with submitcommand
# THIS HAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
. $DIR_UTIL/load_nco
set -euvx

#==================================================
export inputFV=INPUT   # finalfile in parent script
export outdirC3S=OUTDIR
wkdir=WKDIR
export ftype=TYPE
export ic=IC
export nsimdays=NDAYS
export varsingle=VAR
export init=INIT
export end_term=END_TERM
export caso=CASO
export checkfile=CHECKF
export ext=EXT
export C3Stable=TABLE


export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
member=`echo $caso|cut -d '_' -f 3|cut -c 2,3`
set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

startdate=$yyyy$st
export fore_type=$typeofrun
export outputgrid="reg1x1"
export srcGridName=$REPOGRID/srcGrd_FV.nc
export dstGridName=$REPOGRID/dstGrd_${outputgrid}.nc
export wgtFileName=$REPOGRID/CAMFV05_2_${outputgrid}_bilinear_C3S.nc
export wgtFileNameCons=$REPOGRID/CAMFV05_2_${outputgrid}_conserve_C3S.nc
export lsmFileName=$REPOGRID/SPS4_C3S_LSM.nc
export alphaFileName=$REPOSITORY/alpha_100m_wind/mean_alpha_${st}.nc
export version=$versionSPS
export real="r"${member}"i00p00"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export GCM_and_version=${GCM_name}-v${version}
export ini_term=cmcc_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100

set +euvx
. $dictionary
set -euvx
#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
case $ftype
in
    h1)  export frq=6hr;;
    h2)  export frq=12hr;;
    h3)  export frq=day;;
    h0)  export frq=fix;;
esac
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CAM

ncl $wkdir/regridFV_C3S.$ftype.$varsingle.ncl
echo "$0 for var $varsingle completed"
exit 0
