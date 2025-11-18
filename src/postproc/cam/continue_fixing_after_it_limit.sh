#!/bin/sh -l
#--------------------------------
#--------------------------------
# this script identifies the spikes in a daily timeseries of TMAX, performs a poisson extrapolation in the points nearby the spikes, setting to mask an arbitrary selected region (3 ponts) around the spike and filling it through poisson.
# It might be necessary to run it iteratively, for a value which was not a spike in the algorithm definition, could become so after the treatment.
# treated DMO MUST be stored separately on /work and not overwrite the oroginal ones.
#DESTINATION DIR IS
#
#HEALED_DIR

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
export caso=$1
HEALED_DIR=$HEALED_DIR_ROOT/$caso
mkdir -p $HEALED_DIR

#----------------------------------
# RELEVANT DIRECTORIES
#----------------------------------
logdir=$HEALED_DIR/logs
mkdir -p $logdir

#----------------------------------
# defining year stmonth and member from $caso name
#----------------------------------
yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
ens=`echo $caso|cut -d '_' -f3`

#----------------------------------
# defining settings for the checker
#----------------------------------
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate qachecker
set -euvx


cd $HEALED_DIR
#first file to check
file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
# already copied for safety reasons to working directory

fixedfile=$caso.cam.h3.${yyyy}-${st}.fix5.nc
rsync -av $fixedfile $file2check
#skip the 3 line-header
tail -n +4 $HEALED_DIR/list_spikes.txt_5 > $HEALED_DIR/list_spikes_no_header.txt_5
# file resulting from excluding common lines
grep -vf $HEALED_DIR/list_spikes_no_header.txt_5 $HEALED_DIR/list_spikes_all.txt > $HEALED_DIR/list_spikes_tmp.txt
#now rename the temporary file
mv $HEALED_DIR/list_spikes_tmp.txt $HEALED_DIR/list_spikes_all.txt
inputascii_all=$HEALED_DIR/list_spikes_all.txt

# now perform poisson treatment to all files
# the output dir is created only at this stage for in principle the file could not be affected by spikes at all
for ftype in h1 h2 h3 h4
do
   file2check=${caso}.cam.$ftype.${yyyy}-${st}.zip.nc
   inputFV=$DIR_ARCHIVE/$caso/atm/hist/$file2check
   fixedfinal=$file2check
   checkfile=$HEALED_DIR/${caso}.cam.$ftype.DONE
   export outputFV=$HEALED_DIR/$fixedfinal
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 4000 -d ${DIR_C3S} -j poisson_daily_values_${ftype}_${caso} -s poisson_daily_values.sh -l $logdir -i "$ftype $caso $inputascii_all $inputFV $outputFV $checkfile"
   message="$caso poisson treatment submitted for $ftype file"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
done



body="$caso Healing succesfully completed"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$body" -r "only" -s $yyyy$st -E $ens

#----------------------------------------
# END OF CONTINUATION AFTER EXIT FOR ITERATION NUMBER EXCEEDED
#----------------------------------------
