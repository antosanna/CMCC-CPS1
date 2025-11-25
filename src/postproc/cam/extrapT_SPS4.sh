#!/bin/sh -l
#--------------------------------

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo
#module load gcc-12.2.0/12.2.0
if [[ $machine == "juno" ]] ; then
  . $HOME/load_miniconda
  conda activate $envcondancl
fi
#---------------------------------
# first part computes PS from PSL
#---------------------------------
set -exvu
if [[ $# -ne 0 ]]
then
   export caso=$1
   export checkfile=$2
#
else
   typeofrun=hindcast
   checkfile="pino.done"
   export caso=sps4_199301_002
   HEALED_DIR=$SCRATCHDIR/extrapT/${caso}
fi
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
HEALED_DIR=$HEALED_DIR_ROOT/$caso/CAM/healing
set +exvu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -exvu
export st=`echo $caso|cut -d '_' -f2 |cut -c5-6`
ens=`echo $caso|cut -d '_' -f 3 `
export member=`echo $ens|cut -c2,3`

export typeofrun

export inputpsl=$HEALED_DIR/PSL.$caso.C3S.12hr.nc
if [[ ! -f $inputpsl ]]
then
   cdo selvar,PSL $HEALED_DIR/$caso.cam.h1.$yyyy-$st.zip.nc $HEALED_DIR/PSL.$caso.nc
   cdo selhour,0,12 $HEALED_DIR/PSL.$caso.nc $HEALED_DIR/PSL.$caso.12hr.nc
   cdo remapbil,$REPOGRID1/griddes_C3S.txt $HEALED_DIR/PSL.$caso.12hr.nc $inputpsl
fi
# create TS on C3S grid
if [[ ! -f $HEALED_DIR/TS.$caso.C3S.nc ]]
then
   cdo selvar,TS $HEALED_DIR/$caso.cam.h1.$yyyy-$st.zip.nc $HEALED_DIR/TS.$caso.nc
   cdo remapbil,$REPOGRID1/griddes_C3S.txt $HEALED_DIR/TS.$caso.nc $HEALED_DIR/TS.$caso.C3S.nc
fi
# make it conform to the required output in time axis
export inputts=$HEALED_DIR/TS.$caso.C3S.12h.nc
if [[ ! -f $inputts ]]
then
   cdo selhour,0,12 $HEALED_DIR/TS.$caso.C3S.nc $inputts
fi


export outputPS=$HEALED_DIR/PS.$caso.12hr.nc
export inputoro=$REPOSITORY/sps4_orog_C3S.nc


OUTDIR=$HEALED_DIR
mkdir -p $OUTDIR 


rsync -av $DIR_POST/cam/compute_PS_from_PSL_template.ncl $HEALED_DIR/compute_PS_from_PSL_$caso.ncl

#rsync -av $DIR_POST/cam/ncl_libraries $HEALED_DIR/
mkdir -p $HEALED_DIR/ncl_libraries
rsync -av $DIR_POST/cam/ncl_libraries_${machine}/* $HEALED_DIR/ncl_libraries/.


cd $HEALED_DIR
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
# create TREFHT on C3S grid
if [[ ! -f $HEALED_DIR/TREFHT.$caso.C3S.nc ]]
then
   cdo selvar,TREFHT $HEALED_DIR/$caso.cam.h1.$yyyy-$st.zip.nc $HEALED_DIR/TREFHT.$caso.nc
   cdo remapbil,$REPOGRID1/griddes_C3S.txt $HEALED_DIR/TREFHT.$caso.nc $HEALED_DIR/TREFHT.$caso.C3S.nc
fi
# make it conform to the required output in time axis
export inputt2m=$HEALED_DIR/TREFHT.$caso.C3S.12h.nc
if [[ ! -f $inputt2m ]]
then
   cdo selhour,0,12 $HEALED_DIR/TREFHT.$caso.C3S.nc $inputt2m
fi


#define inputs
export inputta=$WORK_CERISE/${yyyy}${st}/cmcc_CERISE-${GCM_name}-v${versionSPS}_"$typeofrun"_S"$yyyy$st"0100_atmos_12hr_pressure_ta_r"$member"i00p00.nc
export inputPS=$outputPS

#define outputs
export outputta=$OUTDIR/cmcc_CERISE-${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_atmos_12hr_pressure_ta_r${member}i00p00.nc

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
