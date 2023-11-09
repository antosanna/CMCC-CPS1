#!/bin/sh -l
#BSUB -q s_long
#BSUB -J clim_hind_SPS3.5_VAR
#BSUB -o logs/clim_hind_SPS3.5_VAR_%J.out
#BSUB -e logs/clim_hind_SPS3.5_VAR_%J.err
#BSUB -P 0490

# Load descriptor
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco
set -euxv

var=$1
yyyy=$2
st=$3
workdir=$4
odir=$5
fileok=$6
wind=$7


set +euvx
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
set -euxv

# 

institude_id="cmcc"
model_id="CMCC-CM2-v"$versionSPS
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
if [ -f $odir/${fileroot}_S${startdate}_${varname}_min.nc -a -f $odir/${fileroot}_S${startdate}_${varname}_max.nc -a -f $odir/${fileroot}_S${startdate}_${varname}_emean_highfreq.nc ]
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

   if [[ $wind -eq 1 ]]
   then
      lista=" "
      wkdirwind=$SCRATCHDIR/C3S_statistics/${startdate}/$var
      mkdir -p $wkdirwind
#trasforma i valori in modulo e fai il resto
      cd $wkdirwind
      for origfile in $flist
      do
         newfile=`basename $origfile| rev|cut -d '.' -f2-|rev`_abs.nc
         if [[ ! -f $newfile ]]
         then
            ncap2 -s "where($var<0) $var=-1*$var" $origfile ${newfile}
         fi
         lista+=" $SCRATCHDIR/C3S_statistics/${startdate}/$var/${newfile}"
      done
   else
      lista=${flist}
   fi
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
# Ensemble mean
   if [ ! -f $odir/${fileroot}_S${startdate}_${varname}_emean_highfreq.nc ]
   then
      ncea -O -v ${var} ${lista} $odir/${fileroot}_S${startdate}_${varname}_emean_highfreq.nc #takes around 400s
   fi
   touch $fileok
fi
