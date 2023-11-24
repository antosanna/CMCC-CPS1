#!/bin/sh -l
##BSUB -J EDA2CAM
##BSUB -e /work/csp/as34319/scratch/interp/logs/EDA2CAM_%J.err
##BSUB -o /work/csp/as34319/scratch/interp/logs/EDA2CAM_%J.out
##BSUB -P 0490
# already tested on Zeus

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_ncl
set -euvx

debug=0

#INPUT SECTION
check_IC_CAMguess=$1
yyyy=$2
st=$3
ppeda=$4

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
# export vars needed by ncl script
export yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
export mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month; this is not a number (2 digits)
export dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
#TEMPLATE FILE 2 CAM
export ftemplate=${CESMDATAROOT}/inputdata/atm/cam/inic/fv/cami_0000-01-01_0.47x0.63_L83_c230109.nc

mkdir -p $IC_CAM_CPS_DIR/$st/
startdate=$yyyy${st}01
tstamp="00"
iniICfile=$IC_CAM_CPS_DIR/$st/${CPSSYS}.EDAcam.i.$yyyy$st
data=$DATA_ECACCESS/EDA/snapshot/${tstamp}Z/
echo 'starting preprocessing for raw date '$yyIC $mmIC $dd $tstamp `date`
echo ''

#INPUT FILES DOWNLOADED FROM ECMWF
#lev_ml=ECEDA_${yyIC}${mmIC}${dd}_${tstamp}lev.grib  #level fields
pp=`printf '%.2d' $(($ppeda + 1))`

ICfile=$iniICfile.$pp.nc

inputECEDA=ECEDA${ppeda}_$yyIC$mmIC${dd}_${tstamp}.grib
inp=`echo $inputECEDA|rev |cut -d '.' -f1 --complement|rev`

export output=${CPSSYS}.EDAcam.i.${pp}.${yyIC}-${mmIC}-${dd}_${tstamp}.nc
ncdataSPS=$IC_CPS_guess/CAM/$st/$output
if [[ -f $ncdataSPS ]]
then
   exit 0
fi
# this to check output after vertical interpolation
output_checkZIP="${CPSSYS}.EDAcam.i.$pp.3dfields_${yyIC}-${mmIC}-${dd}_${tstamp}_ECEDAgrid83lev.zip.nc"

# create output dir if not existing already
mkdir -p $WORK_IC4CAM

cd ${WORK_IC4CAM}

#NOW LEVEL FIELDS U, V, Q, T and lnPS (used to vertical interp)
# 20210429 +
if [ ! -f ${data}/${inputECEDA} ]
then
   title="[CAMIC] ${CPSSYS} ERROR"
   body="$DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh: ${data}/${inputECEDA} missing!"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 
fi
# 20210429 -
cdo --eccodes -f nc copy ${data}/${inputECEDA} ${WORK_IC4CAM}/${inp}.tmp.nc
cdo smooth9 ${WORK_IC4CAM}/${inp}.tmp.nc ${WORK_IC4CAM}/${inp}.tmp.smooth.nc
cdo smooth9 ${WORK_IC4CAM}/${inp}.tmp.smooth.nc ${WORK_IC4CAM}/${inp}.nc
rm -f ${WORK_IC4CAM}/${inp}.tmp.nc ${WORK_IC4CAM}/${inp}.tmp.smooth.nc
export input3d=${WORK_IC4CAM}/${inp}.nc
export output_check=$WORK_IC4CAM/${inp}.tmp2.nc
export wgt_file=$REPOGRID/EDA2FV0.47x0.63_L83.nc
export wgt_file_slon=$REPOGRID/EDA2FV0.47x0.63_L83_slon.nc
export wgt_file_slat=$REPOGRID/EDA2FV0.47x0.63_L83_slat.nc
export src_grid_file=$REPOGRID/src_grid_file.nc
export dst_grid_file=$REPOGRID/dst_grid_file.nc
export src_grid_file1=$REPOGRID/src_grid_file_slon.nc
export dst_grid_file1=$REPOGRID/dst_grid_file_slon.nc
export src_grid_file2=$REPOGRID/src_grid_file_slat.nc
export dst_grid_file2=$REPOGRID/dst_grid_file_slat.nc
scriptregrid=$SCRATCHDIR/EDA2CAM_regrid/$yyyy${st}_${pp}/regrid_ERA5_to_FV0.47x0.63_L83_${yyyy}${st}_${pp}.ncl
mkdir -p $SCRATCHDIR/EDA2CAM_regrid/$yyyy${st}_${pp}/
sleep 2
rsync -auv $DIR_ATM_IC/ncl/regrid_ERA5_to_FV0.47x0.63_L83.ncl $scriptregrid
echo "submit $scriptregrid "`date`
echo ''
export fileok=${WORK_IC4CAM}/${inp}_ok
ncl $scriptregrid
if [ -f $fileok ]
then
   echo "ended $scriptregrid and begin compression check level fileds"`date`
   echo ''
#      rm $input3d
else
   title="[CAMIC] ${CPSSYS} warning"
   body="$scriptregrid did not complete correctly "
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
fi
# the script produces check files for vertical interpolation $output_check
# put them in $WORK_IC4CAM
if [ -f $WORK_IC4CAM/$output_checkZIP ]
then
    rm -f $WORK_IC4CAM/$output_checkZIP
fi
$compress ${output_check} $WORK_IC4CAM/$output_checkZIP
rm -f ${output_check}

echo 'ended compression check level fields and begin compression IC CAM ' `date`echo ''
# put results in $IC_CPS_guess/CAM 
mkdir -p $IC_CPS_guess/CAM/$st
mv ${output} $ncdataSPS
echo 'ended compression IC CAM 00 '`date`
echo ''
touch $check_IC_CAMguess
