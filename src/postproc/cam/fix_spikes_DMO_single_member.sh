#!/bin/sh -l
#BSUB -J fix_1member_spikes
#BSUB -e logs/fix_1member_spikes_%J.err
#BSUB -o logs/fix_1member_spikes_%J.out
#BSUB -P 0490
#BSUB -M 20000
#BSUB -q s_medium
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
HEALED_DIR=$2
#export caso=sps4_199305_001
#wkdir=$wkdir_cam
wkdir=$HEALED_DIR
mkdir -p $wkdir

#----------------------------------
# RELEVANT DIRECTORIES
#----------------------------------
logdir=$wkdir/logs
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


# where the spike indices are stored each time the checker is passed through
export inputascii=$wkdir/list_spikes.txt
# where all the spike indices are stored
export inputascii_all=$HEALED_DIR/list_spikes_all.txt

#first file to check
file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
# copied for safety reasons to working directory
rsync -auv $DIR_ARCHIVE/$caso/atm/hist/${file2check} $wkdir
var="TREFMNAV"
logfile=$logdir/log_${var}_spikes_${yyyy}${st}_${ens}
if [[ -f $logfile ]]
then
    rm $logfile
fi
python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -p $wkdir -v ${var} -spike True -l ${wkdir} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}
message="$caso First check for spikes performed"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens

if [[ ! -f $inputascii ]]
then
#TEMPORARY +
   rsync -auv $wkdir/${file2check} $HEALED_DIR
#   mv $wkdir/$caso/${file2check} $HEALED_DIR
#TEMPORARY -
   for ftype in h1 h2
   do
      file2check=${caso}.cam.$ftype.${yyyy}-${st}.zip.nc
      rsync -auv $DIR_ARCHIVE/$caso/atm/hist/${file2check} $HEALED_DIR
   done
   echo "no spikes detected from ${DIR_C3S}/c3s_qa_checker.py on file ${file2check}. Exiting now"
   touch $HEALED_DIR/${caso}.cam.h1.DONE
   touch $HEALED_DIR/${caso}.cam.h2.DONE
   touch $HEALED_DIR/${caso}.cam.h3.DONE
   exit
else
   message="$caso spikes found"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
fi
# concatenate the single checker output lists 
rsync -auv $inputascii $inputascii_all

#  first attempt of treatment
file2check=$caso.cam.h3.${yyyy}-${st}.zip.nc
fixedfile=$caso.cam.h3.${yyyy}-${st}.fix1.nc
it=1

#  successive attempt of treatments: the cycle relies on the assumption that the $inputascii is not created of no spikes are detected
body="$caso first treatment on h3done"
while `true`
do
   if [[ ! -f $inputascii ]]
   then
      break
   fi
   export inputFV=$wkdir/$file2check
   export outputFV=$wkdir/$fixedfile

   checkfile=$wkdir/${caso}.cam.h3.DONE
   $DIR_POST/cam/poisson_daily_values.sh h3 $caso $inputascii $inputFV $outputFV $checkfile $HEALED_DIR
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$body" -r "only" -s $yyyy$st -E $ens
   rm $inputascii
#  successive attempt of treatments: the cycle relies on the assumption that the $inputascii is not created of no spikes are detected so it is removed after any test
# now recheck for the presence of spikes after treatment
# At this stage the treatment is performed only to the daily values (actually it could be limited to TMAX)
   file2check=$fixedfile
   python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -p $wkdir -v ${var} -spike True -l ${wkdir} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}
   message="$caso successive check for spikes performed"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
# concatenate the single checker output lists skipping the first 5 lines (header)
   if [[ ! -f $inputascii ]]
   then
      break
   fi
   awk 'NR > 5 { print }' $inputascii >> $inputascii_all
   rsync -auv $inputascii ${inputascii}_${it}
   it=$(($it + 1))
   fixedfile=$caso.cam.h3.${yyyy}-${st}.fix${it}.nc
   body="$caso $it treatment on h3done"
done

# now perform poisson treatment to all files
# the output dir is created only at this stage for in principle the file could not be affected by spikes at all
mkdir -p $HEALED_DIR
rm $wkdir/${caso}.cam.h3.DONE
for ftype in h1 h2 h3
do
   file2check=${caso}.cam.$ftype.${yyyy}-${st}.zip.nc
   inputFV=$DIR_ARCHIVE/$caso/atm/hist/$file2check
   fixedfinal=$file2check
   checkfile=$wkdir/${caso}.cam.$ftype.DONE
   export outputFV=$HEALED_DIR/$fixedfinal
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 4000 -d ${DIR_POST}/cam -j poisson_daily_values_${ftype}_${caso} -s poisson_daily_values.sh -l $logdir -i "$ftype $caso $inputascii_all $inputFV $outputFV $checkfile $HEALED_DIR"
   message="$caso poisson treatment submitted for $ftype file"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
done


checkfile=$wkdir/${caso}.cam.h3.DONE
while `true`
do
    if [[ -f $checkfile ]]
    then
       break
    fi
done

file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
# copied for safety reasons to working directory
rsync -auv $HEALED_DIR/${file2check} $wkdir
var="TREFMNAV"
logfile=$logdir/log_${var}_spikes_${yyyy}${st}_${ens}
if [[ -f $logfile ]]
then
    rm $logfile
fi
python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -p $wkdir -v ${var} -spike True -l ${wkdir} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}
message="$caso last check for spike done h3 file"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens

if [[ -f $inputascii ]]
then
   body="oh oh you should not get here!! treatment needed!! "
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "ERROR!!! $caso still spikes present in h3 file" -r yes -s $yyyy$st -E $ens
else
   body="Healing succesfully completed"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "EVVOVAAAA!!! $caso healed" -r yes -s $yyyy$st -E $ens
fi

#----------------------------------------
# END OF redundant: this check is actually conceived for TMAX 
#----------------------------------------
