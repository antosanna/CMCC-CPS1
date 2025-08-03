#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_medium
#BSUB -J check_NEMO_rest
#BSUB -e logs/check_NEMO_rest_%J.err
#BSUB -o logs/check_NEMO_rest_%J.out
#BSUB -M 5G

# load variables from descriptor
. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/load_ncl
set -euvx

# define dates
yyyy=$1  #yyyy year
st=$2 # mm month - must be 2 figures

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh ${yyyy}
set -euvx

# define dirs

CLIMDIR=${IC_NEMO_CPS_DIR1}/clim/$st
export outputpath=${SCRATCHDIR}/${typeofrun}/${yyyy}${st}/IC_OCE/
ANOMDIR=${SCRATCHDIR}/${typeofrun}/${yyyy}${st}/IC_OCE/anom
mkdir -p ${ANOMDIR}
# some definitions for plotting by ncl

export meshfile="$CESMDATAROOT/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_mesh_mask.nc"
export startdate="${yyyy}${st}"
cd ${IC_NEMO_CPS_DIR}/${st}
#CPS1.nemo.r.2025-05-01-00000.01.nc
#plist=`ls -1 CPS1.nemo.r.${yyyy}-${st}-01-00000.??.nc | rev | cut -d '.' -f2 |rev`
plist=`ls -1 CPS1.nemo.r.${yyyy}-${st}-01-00000.*.nc | cut -d '.' -f5 `
cd $outputpath
for pp in $plist ; do
   # Produce input files for plotting but skip operations if files exist ********************* 
   if [ ! -f CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce.nc ] ; then
       nameic=`ls ${IC_NEMO_CPS_DIR}/${st}/CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.*nc`
       fname=`basename $nameic`
       rsync -auv --progress ${nameic} $outputpath
       ncks -Oh -v tn,nav_lat,nav_lon,nav_lev ${fname} CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce_tmp.nc
       ncks -Oh -F -d nav_lev,1,1  CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce_tmp.nc  CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce.nc  
   fi
   # difference
   ncdiff -O CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce.nc  ${CLIMDIR}/CPS1.nemo.r.clim_1993_2022.${st}.Toce.nc ${ANOMDIR}/CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce_anom.nc
   rm CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce_tmp.nc
   rm CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.Toce.nc
   rm CPS1.nemo.r.${yyyy}-${st}-01-00000.${pp}.nc
done

# Aggregate all the members in a file
ncecat -O ${ANOMDIR}/CPS1.nemo.r.${yyyy}-${st}-01-00000.??.Toce_anom.nc ${ANOMDIR}/CPS1.nemo.r.${yyyy}-${st}-01-00000.all.Toce_anom.nc

# Now ready to plotting ******************************************************************
export orca=${ANOMDIR}/CPS1.nemo.r.${yyyy}-${st}-01-00000.all.Toce_anom.nc

ncl $DIR_OCE_IC/orca_orig_grid_anom_multipanel.ncl


exit 0


