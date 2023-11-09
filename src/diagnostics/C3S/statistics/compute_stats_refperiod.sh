#!/bin/sh -l
#BSUB -q s_long
#BSUB -J clim_hind_SPS3.5_VAR
#BSUB -o logs/clim_hind_SPS3.5_VAR_%J.out
#BSUB -e logs/clim_hind_SPS3.5_VAR_%J.err
#BSUB -P 0490

# Load descriptor
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
set -euvx

var=$1
refperiod=$2
st=$3
inpdir=$4
outdir=$5
fileroot=$6
fileok=$7        #checkfile with fullpath
endyear=$8
nens=$9
namescript=${10}
max_procs_allowed=20

iniy=`echo $refperiod|cut -d '-' -f1`
#now emean, max e min dell'hindcast e sqrt della media delle varianze dell'hindcast
outfile=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_emean_highfreq.nc
if [ ! -f  $outfile ]
then
      ncea -O ${inpdir}/19??/${var}/${fileroot}_S????${st}_*${var}_emean_highfreq.nc ${inpdir}/200?/${var}/${fileroot}_S????${st}_*${var}_emean_highfreq.nc ${inpdir}/201[0-6]/${var}/${fileroot}_S????${st}_*${var}_emean_highfreq.nc ${outfile}
fi
outfile=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_max.nc
if [ ! -f  $outfile ]
then
   nces -O -y max -v ${var} ${inpdir}/19??/${var}/${fileroot}_S????${st}_*${var}_max.nc ${inpdir}/200?/${var}/${fileroot}_S????${st}_*${var}_max.nc  ${inpdir}/201[0-6]/${var}/${fileroot}_S????${st}_*${var}_max.nc ${outfile}
fi
outfile=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_min.nc
if [ ! -f  $outfile ]
then
   nces -O -y min -v ${var} ${inpdir}/19??/${var}/${fileroot}_S????${st}_*${var}_min.nc ${inpdir}/200?/${var}/${fileroot}_S????${st}_*${var}_min.nc ${inpdir}/201[0-6]/${var}/${fileroot}_S????${st}_*${var}_min.nc ${outfile}
fi
export fmean=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_emean_highfreq.nc
export varm=$var
export varnamefile=`basename ${inpdir}/1993/$var/${fileroot}_S????${st}_*${var}_squaredvalues.nc|cut -d '_' -f5-8` 
export filostd=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_std.nc
export checkfilestd=${outdir}/$st/$var/${fileroot}_${st}.${refperiod}_${var}_std_ok
if [ ! -f $checkfilestd ]
then
   np=`${DIR_SPS35}/findjobs.sh -m $machine -n $namescript -c yes`
   if [ $np -gt $max_procs_allowed ]
   then
      echo "too many jobs running! exit now!"
      exit
   fi
   np=`${DIR_SPS35}/findjobs.sh -m $machine -n $namescript.$st.$var -c yes`
   if [ $np -eq 0 ]
   then
      input="$var $st $outdir $fileroot $nens $checkfilestd $fileok $inpdir"
      ${DIR_SPS35}/submitcommand.sh -m $machine -M 10000  -S qos_resv -t "4" -q $serialq_m -j $namescript.$st.${var} -l $DIR_LOG/DIAGS/stats/ -d ${DIR_DIAG}/C3S_statistics -s stdev_on_line.sh -i "$input"
   else
      echo "$var for start-date $st already under process. Skip"
      exit
   fi
else
   touch $fileok
fi
