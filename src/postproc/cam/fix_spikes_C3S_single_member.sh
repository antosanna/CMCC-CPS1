#!/bin/sh -l
#--------------------------------
#--------------------------------
# this script identifies the spikes in a daily timeseries of TMIN, performs a poisson extrapolation in the points nearby the spikes, setting to mask an arbitrary selected region (3 ponts) around the spike and filling it through poisson.
# It might be necessary to run it iteratively, for a value which was not a spike in the algorithm definition, could become so after the treatment.
# treated DMO MUST be stored separately on /work and not overwrite the oroginal ones.
#DESTINATION DIR IS
#
#HEALED_DIR

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
export caso=$1
dir_cases=$2
HEALED_DIR=$HEALED_DIR_ROOT/$caso
#export caso=sps4_199305_001
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

# where the spike indices are stored each time the checker is passed through
export inputascii=$HEALED_DIR/list_spikes.txt
# where all the spike indices are stored
export inputascii_all=$HEALED_DIR/list_spikes_all.txt

#first file to check
file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
# copied for safety reasons to working directory
rsync -auv $DIR_ARCHIVE/$caso/atm/hist/${file2check} $HEALED_DIR
var="TREFMNAV"
logfile=$logdir/log_${var}_spikes_${yyyy}${st}_${ens}
if [[ -f $logfile ]]
then
    rm $logfile
fi
python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -sl $inputascii -p $HEALED_DIR -v ${var} -spike True -l ${HEALED_DIR} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}

cnterror=`grep -Ril ERROR\] ${logfile} | wc -l`
if [[ $cnterror -ne 0 ]] ; then
   message="ERROR in c3s_qa_checker for caso $caso" 
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
   exit 1
fi

message="$caso First check for spikes performed"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens

if [[ ! -f $inputascii ]]
then
   for ftype in h1 h2
   do
      file2check=${caso}.cam.$ftype.${yyyy}-${st}.zip.nc
      rsync -auv $DIR_ARCHIVE/$caso/atm/hist/${file2check} $HEALED_DIR
   done
   echo "no spikes detected from ${DIR_C3S}/c3s_qa_checker.py on file ${file2check}. Exiting now"
   touch $HEALED_DIR/${caso}.cam.h1.DONE
   touch $HEALED_DIR/${caso}.cam.h2.DONE
   touch $HEALED_DIR/${caso}.cam.h3.DONE
   touch $HEALED_DIR/${caso}.NO_SPIKE
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
   export inputFV=$HEALED_DIR/$file2check
   export outputFV=$HEALED_DIR/$fixedfile

   checkfile=$HEALED_DIR/${caso}.cam.h3.DONE
   $DIR_C3S/poisson_daily_values.sh h3 $caso $inputascii $inputFV $outputFV $checkfile
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$body" -r "only" -s $yyyy$st -E $ens
   mv $inputascii ${inputascii}_0
#  successive attempt of treatments: the cycle relies on the assumption that the $inputascii is not created of no spikes are detected so it is removed after any test
# now recheck for the presence of spikes after treatment
# At this stage the treatment is performed only to the daily values (actually it could be limited to TMIN)
   file2check=$fixedfile
   python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -sl $inputascii -p $HEALED_DIR -v ${var} -spike True -l ${HEALED_DIR} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}
   cnterror=`grep -Ril ERROR\] ${logfile} | wc -l`
   if [[ $cnterror -ne 0 ]] ; then
      message="ERROR in c3s_qa_checker for caso $caso" 
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
      exit 1
   fi
   message="$caso successive check for spikes performed"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
# concatenate the single checker output lists skipping the first 5 lines (header)
   if [[ ! -f $inputascii ]]
   then
      break
   fi
   awk 'NR > 3 { print }' $inputascii >> $inputascii_all
   rsync -auv $inputascii ${inputascii}_${it}
   it=$(($it + 1))
   if [[ $it -gt 5 ]]
   then
#   here plot timeseries
      body="MANUAL INTERVENTION REQUIRED!! $caso iterative healing infinite loop"
      sed -e "s:CASO:$caso:g;s:dummy_DIR_CASES:$dir_cases:g" $DIR_TEMPL/launch_postproc_C3S_after_it_limit.sh > $HEALED_DIR/launch_postproc_C3S_after_it_limit.sh 
      chmod u+x $HEALED_DIR/launch_postproc_C3S_after_it_limit.sh
      message="$caso more than 5 attempts! Check if treatment effectively needed or false-spike! EXIT NOW AND INSPECT PLOTS IN GDRIVE:SPIKES_warning_${yyyy}${st}. \n If the plots do not show spikes, resubmit the postprocessing with $HEALED_DIR/launch_postproc_C3S_after_it_limit.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$body" -r "yes" -s $yyyy$st -E $ens
      touch $HEALED_DIR/${caso}.too_many_it.EXIT
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -M 4000 -d ${DIR_POST}/cam -j plot_timeseries_spike_${caso} -s plot_timeseries_spike.sh -l $logdir -i "$caso 0 $HEALED_DIR/list_spikes.txt_5"
      exit
   fi

   fixedfile=$caso.cam.h3.${yyyy}-${st}.fix${it}.nc
   body="$caso $it treatment on h3done"
done

# now perform poisson treatment to all files
# the output dir is created only at this stage for in principle the file could not be affected by spikes at all
mkdir -p $HEALED_DIR
rm $HEALED_DIR/${caso}.cam.h3.DONE
for ftype in h1 h2 h3
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


checkfile=$HEALED_DIR/${caso}.cam.h3.DONE
while `true`
do
    if [[ -f $checkfile ]]
    then
       break
    fi
done

file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
var="TREFMNAV"
python ${DIR_C3S}/c3s_qa_checker.py ${file2check} -p $HEALED_DIR -v ${var} -spike True -l ${HEALED_DIR} -j ${DIR_C3S}/qa_checker_table.json --verbose >> ${logfile}
cnterror=`grep -Ril ERROR\] ${logfile} | wc -l`
if [[ $cnterror -ne 0 ]] ; then
   message="ERROR in c3s_qa_checker for caso $caso" 
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens
   exit 1
fi


message="$caso last check for spike done h3 file"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$message" -t "$message" -r "only" -s $yyyy$st -E $ens

if [[ -f $inputascii ]]
then
   body="oh oh you should not get here!! treatment needed!! "
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "ERROR!!! $caso still spikes present in h3 file" -r yes -s $yyyy$st -E $ens
else
   body="$caso Healing succesfully completed"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$body" -r "only" -s $yyyy$st -E $ens
fi

