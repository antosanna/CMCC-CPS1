#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

. $DIR_UTIL/condaactivation.sh
condafunction activate qachecker

set -euvx
caso=$1
logfile=$2
inputascii=$3

yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
ens=`echo $caso|cut -d '_' -f3`

file2check=${caso}.cam.h3.${yyyy}-${st}.zip.nc
var="TREFMNAV"
HEALED_DIR=$HEALED_DIR_ROOT/$caso/CAM/healing
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
