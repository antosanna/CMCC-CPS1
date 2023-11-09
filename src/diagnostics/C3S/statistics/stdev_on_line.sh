#!/bin/sh -l

# Load descriptor
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
set -eu

export varm=$1
export st=$2
export finaldir=$3/$st/$varm
mkdir -p $finaldir
export fileroot=$4
export nens=$5
export check=$6
export fileok=$7
diri=$8

export odir=$SCRATCHDIR/C3S_statistics/tmp/
mkdir -p $odir/$varm
set +euvx
. ${DIR_SPS35}/descr_hindcast.sh
set -euvx
if [ -f $fileok ]
then
   exit 0
fi
   
launchdir=$DIR_DIAG/C3S_statistics
# For each year in yearlist
for yyyy in {1993..2016}
do
   export year=$yyyy
   export ifirst=0
   if [ $yyyy -eq 1993 ]
   then
      export ifirst=1
   else
      yyyym1=$(($yyyy - 1))
      export filostd=$odir/partial_mean_and_variance_${yyyym1}${st}_${varm}.nc
   fi
   export startdate=${yyyy}${st}
   export diri=${WORK_C3Shind}/${startdate}
   cd $diri
   
   # get file list
      var_type=`ls ${fileroot}_S${startdate}0100_*_${varm}_r01i00p00.nc | cut -d "_" -f 5-7` || exit 1
   export varname=${var_type}_${varm}
      
# start-date ensemble standard deviation
   export outfile=$odir/partial_mean_and_variance_${yyyy}${st}_${varm}.nc
   if [ $yyyy -eq 2016 ]
   then
      outfile=$finaldir/${fileroot}_${st}.1993-2016_${varm}_std.nc
      export checkfilestd=$check
   else
      export checkfilestd=$odir/partial_mean_and_variance_${yyyy}${st}_${varm}_ok
   fi
   if [ ! -f $checkfilestd ] && [ ! -f $fileok ]
   then
      cp $launchdir/stdev_on_line.ncl $odir/$varm
      ncl $odir/$varm/stdev_on_line.ncl
   fi
   if [ ! -f $checkfilestd ] && [ ! -f $fileok ]
   then
      title="${SPSSYS} C3S diagnostics ERROR"
      body="something rotten....$DIR_DIAG/C3S_statistics/stdev_on_line.ncl did not terminate correctly for $yyyy $st and $varm $DIR_LOG/DIAGS/stats/stdev_on_line.$st.${varm}_?.err/out"
      $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit
   elif [ $yyyy -eq 2016 ]
   then
#      rm $odir/partial_mean_and_variance_????${st}_${varm}.nc 
#      rm $odir/partial_mean_and_variance_????${st}_${varm}_ok 
      touch $fileok
   fi
done
