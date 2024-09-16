#!/bin/sh -l
#BSUB -q s_long
#BSUB -J clim_hind_CPS1
#BSUB -o logs/clim_hind_CPS1_%J.out
#BSUB -e logs/clim_hind_CPS1_%J.err
#BSUB -P 0490
#BSUB -M 10000

# Load descriptor
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euxv

var=$1
yyyy=$2
st=$3
odir=$4
fileok=$5


set -euxv

# 

institude_id="cmcc"
model_id=$GCM_name"-v"$versionSPS
fileroot=${institude_id}_${model_id}_${typeofrun}

# Processing
echo 'Starting'
echo date


# For each year in yearlist
startdate=${yyyy}${st}

#input dir operational user
cd ${WORK_C3S1}/${startdate}
# get file list
var_type=`ls -1 ${fileroot}_S${startdate}0100_*_${var}_r01i00p00.nc | cut -d "_" -f 5-7` || exit 1
varname=${var_type}_${var}
cd $odir
if [[ -f $odir/${fileroot}_S${startdate}_${varname}_min.nc ]] && [[ -f $odir/${fileroot}_S${startdate}_${varname}_max.nc ]] 
then
   echo "everything already compute exiting now"
   if [ ! -f $fileok ]
   then
      touch $fileok
   fi
   exit 0
else
   flist=`ls ${WORK_C3S1}/${startdate}/${fileroot}_S${startdate}0100_${varname}_r*i00p00.nc`
# check nr of files
   file_count=`ls -1 ${flist} | wc -l`
   if [ $file_count -lt $nrunC3Sfore ] ;then
       echo "Number of members $file_count is less than the expected $nrunC3Sfore" 
       exit 1
   fi

   lista=${flist}
   cd $odir
# Compute summary statistics
# min
   if [ ! -f $odir/${fileroot}_S${startdate}_${varname}_min.nc ]
   then
      nces -O -y min -v ${var} ${lista} $odir/${fileroot}_S${startdate}_${varname}_min.nc #takes around 400s
   fi
#max
   if [ ! -f $odir/${fileroot}_S${startdate}_${varname}_max.nc ]
   then
      nces -O -y max -v ${var} ${lista} $odir/${fileroot}_S${startdate}_${varname}_max.nc #takes around 400s
   fi
   touch $fileok
fi
