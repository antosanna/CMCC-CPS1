#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_POST}/APEC/descr_SPS4_APEC.sh

set -eux

yyyy=$1
st="$2"

. $DIR_UTIL/descr_ensemble.sh $yyyy

here=$3

workdir="$WORK_SPS4/APEC/workdir_${yyyy}${st}"
if [ -d $workdir ] ; then
   rm -rf $workdir
fi
mkdir -p $workdir

startdate=${yyyy}${st}
###

DATA=$FINALARCHC3S/${yyyy}${st}

cd $workdir

## APEC get C3S data ----------------------------------------------------------------------------------------------------
## GET a local copy of archived C3S files

varlist=("rlt lwesnw sic tso psl tas uas vas lwepr zg ta ua va")

for var in ${varlist[*]} ; do
    rsync -auv $DATA/cmcc_CMCC-CM3-v${version}_${typeofrun}_S${yyyy}${st}0100_*_${var}_r??i00p00.nc .

done

# APEC SUBMISSION  -----------------------------------------------------------------------------------------------------
# iterate over cases and submit forecast_to_APEC* jobs
plist=`ls -1 *r??i00p00.nc | cut -d '.' -f1 | cut -d '_' -f9 | sort -n | uniq | cut -c2-3`
npp=1
for pp in $plist ; do

  ppp=`printf "%.03d" $((10#$pp))`

  input="$yyyy $st $ppp $DATA $workdir $pushdir $typeofrun "${varlist[@]}""
  echo $input
  if [ ! -f ${DIR_LOG}/${typeofrun}/${yyyy}${st}/${yyyy}${st}_${ppp}_APEC_DONE ] ;then

     ${DIR_UTIL}/submitcommand.sh -M 7000 -m $machine -q $serialq_m -j APEC_${yyyy}${st}_${ppp} -l ${DIR_LOG}/${typeofrun}/${yyyy}${st} -d ${here} -s data_to_APEC_from_C3S.sh -i "$input"
  fi
  sleep 2

  while `true` ; do
    sleep 3
    njobs=`${DIR_UTIL}/findjobs.sh -m $machine -q $serialq_m -n "APEC_${yyyy}${st}"  -c yes`

    if [ ${njobs} -le ${maxjobs_APEC} ]; then
      break
    fi
  done
  # if greater the required nmaxmem_APEC, exit 
  npp=$(($npp + 1))
  if [[ ${npp} -gt ${nmaxmem_APEC} ]] ; then
    break
  fi
done

# w8 for APEC_${yyyy}${st}_${ppp} 
napec=999
while `true` ; do
  sleep 60
   napec=`${DIR_UTIL}/findjobs.sh -m $machine -q $serialq_m -n "APEC_${yyyy}${st}"  -c yes`
   if [ $napec -eq 0 ] ; then
      break
   fi
done

# All apec processes are completed. we can deactivate python CMOR_4 environment
#source deactivate


# APEC PROCEDURE VERIFICATION  -----------------------------------------------------------------------------------------

# GET pushdirapec
# normalize pushdir, extra check for pushdir format (remove final slash .. if they exist)
normalized_pushdir="`cd "${pushdirapec}";pwd`"
pushdirapec="${normalized_pushdir}/$typeofrun/$yyyy$st"
pushdirapec_monthly="${pushdirapec}/monthly"
pushdirapec_daily="${pushdirapec}/daily"

# Varnum = N_memb * [ (tso psl tas lwepr) + (zg ta ua va)*3LVL ]*6month*2 (daily and monthly)
# Varnum = N_memb * [ 16*6 ]*2 (daily and monthly)
# actual apec files count
set +e
actual_nmonthly=`ls ${pushdirapec_monthly}/CMCC_SPS_*monthly*.nc.gz | wc -l`
if [ $typeofrun = "forecast" ] ; then
   actual_ndaily=`ls ${pushdirapec_daily}/CMCC_SPS_*.nc.gz | wc -l`
   actual_napec=$(($actual_nmonthly + $actual_ndaily))
else
   actual_napec=$actual_nmonthly
fi

# expected apec files count
nmb_tot_var=21
expected_nmonthly=$((${nmaxmem_APEC}*${nmb_tot_var}*6))
if [ $typeofrun = "forecast" ] ; then
	expected_napec=$(($expected_nmonthly*2))
else
	expected_napec=$(($expected_nmonthly))
fi

if [[ $actual_napec -eq $expected_napec ]]; then
  # all is fine!
  body="APEC C3S post-processing completed"
  title="[APEC] ${CPSSYS} ${typeofrun} ${yyyy}${st} postproc notification"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st
  # Now and only we can delete work dirs
  rm -rf $workdir $WORK_SPS35/APEC/${yyyy}${st}_*

else
  # ERROR
  bodyerror1="ERROR APEC files are $actual_napec , but $expected_napec are expected."
  if [[ $actual_nmonthly -eq $expected_nmonthly ]]; then
    # Monthly ok, daily not
    bodyerror2="Monthly files are $actual_nmonthly equal to expected $expected_nmonthly. The problem here should be with daily files."
  else
    bodyerror2="We have an issue with monthly files (and daily probably). Actual_monthly=$actual_nmonthly VS expected_monthly=$expected_nmonthly."
  fi
  body="ERROR - APEC C3S post-processing not completed completed. $bodyerror1 $bodyerror2 See $workdir directory. "
  title="[APEC] ${CPSSYS} ${typeofrun} ${yyyy}${st} postproc notification"
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st

  exit
fi
set -e

# Goodbye
echo "APEC Succesfully completed."
