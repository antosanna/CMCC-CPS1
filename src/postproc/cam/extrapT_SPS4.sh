#!/bin/sh -l
#--------------------------------
#BSUB -J extrapT_SPS4
#BSUB -o logs/extrapT_SPS4.%J.out
#BSUB -e logs/extrapT_SPS4.%J.err
#BSUB -P 0490
#BSUB -M 20000

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
#module load gcc-12.2.0/12.2.0
. $HOME/load_miniconda
conda activate miniconda_ncl

#---------------------------------
# first part computes PS from PSL
#---------------------------------
set -exvu
if [[ $# -ne 0 ]]
then
   export caso=$1
   export checkfile=$2
   WKDIR=$3
#
else
   typeofrun=hindcast
   checkfile="pino.done"
   export caso=sps4_199301_002
   WKDIR=$SCRATCHDIR/extrapT/${caso}
fi
set +exvu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -exvu
export st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
export yyyy=`echo $caso|cut -d '_' -f2 |cut -c1-4`
ens=`echo $caso|cut -d '_' -f 3 `
export member=`echo $ens|cut -c2,3`

mkdir -p $WKDIR
export typeofrun


mkdir -p $WKDIR

export inputpsl=$WKDIR/PSL.$caso.C3S.12hr.nc
if [[ ! -f $inputpsl ]]
then
   cdo selvar,PSL $HEALED_DIR_ROOT/$caso/$caso.cam.h1.$yyyy-$st.zip.nc $WKDIR/PSL.$caso.nc
   cdo selhour,0,12 $WKDIR/PSL.$caso.nc $WKDIR/PSL.$caso.12hr.nc
   cdo remapbil,$REPOGRID1/griddes_C3S.txt $WKDIR/PSL.$caso.12hr.nc $inputpsl
fi

export outputPS=$WKDIR/PS.$caso.12hr.nc
export inputoro=$WORK_C3S/${yyyy}${st}/cmcc_${GCM_name}-v${versionSPS}_"$typeofrun"_S"$yyyy$st"0100_atmos_fix_surface_orog_r"$member"i00p00.nc

rsync -av $DIR_POST/cam/compute_PS_from_PSL_template.ncl $WKDIR/compute_PS_from_PSL_$caso.ncl
rsync -av $DIR_POST/cam/ncl_libraries $WKDIR/
cd $WKDIR
ncl compute_PS_from_PSL_${caso}.ncl
if [ ! -f $outputPS ] 
then
   body="PS computed from PSL for case $caso was not produced by compute_PS_from_PSL_${caso}.ncl."
   title="${CPSSYS} forecast postproc ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st -E $ens
fi

#--------------------------------
# second one compute extrapolation from lowest reliable isobaric level
# and TREFHT
#--------------------------------

OUTDIR=$WKDIR
mkdir -p $OUTDIR 

# create TREFHT on C3S grid
if [[ ! -f $WKDIR/TREFH.$caso.C3S.nc ]]
then
   cdo selvar,TREFHT $HEALED_DIR_ROOT/$caso/$caso.cam.h1.$yyyy-$st.zip.nc $WKDIR/TREFHT.$caso.nc
   cdo remapbil,$REPOGRID1/griddes_C3S.txt $WKDIR/TREFHT.$caso.nc $WKDIR/TREFHT.$caso.C3S.nc
fi
# make it conform to the required output in time axis
export inputts=$WKDIR/TREFHT.$caso.C3S.12h.nc
if [[ ! -f $inputts ]]
then
   cdo selhour,0,12 $WKDIR/TREFHT.$caso.C3S.nc $inputts
fi
#define inputs
export inputta=$WORK_C3S/${yyyy}${st}/cmcc_${GCM_name}-v${versionSPS}_"$typeofrun"_S"$yyyy$st"0100_atmos_12hr_pressure_ta_r"$member"i00p00.nc
export inputoro=$WORK_C3S/${yyyy}${st}/cmcc_${GCM_name}-v${versionSPS}_"$typeofrun"_S"$yyyy$st"0100_atmos_fix_surface_orog_r"$member"i00p00.nc
export inputPS=$outputPS

#define outputs
export outputta=$OUTDIR/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_atmos_12hr_pressure_ta_r${member}i00p00.nc

echo 'post processing starts ' `date`

rsync -av $DIR_POST/cam/extrapT_TREFHT_template.ncl $OUTDIR/extrapT_${caso}.ncl
cd $OUTDIR
ncl extrapT_${caso}.ncl

if [ -f $checkfile ] 
then
   mv $outputta $inputta
   echo 'vertical extrapolation successfully ended ' `date`
else
   body="extrapolated file for ta for case $caso was not produced by $OUTDIR/extrapT_${caso}.ncl. $DIR_C3S/vertinterp.sh exiting now"
   title="${CPSSYS} forecast postproc ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st -E $ens
fi
