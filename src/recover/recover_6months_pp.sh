#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
CASE=$1
caso=$CASE
CASEROOT=$DIR_CASES/$CASE
#
# go back to CASEROOT
cd $CASEROOT
NTASK=`./xmlquery NTASKS_OCN |cut -d ':' -f2|sed 's/ //g'`
# this is the number of parallel postprocessing you want to set
N=1
CIME_OUTPUT_ROOT=`./xmlquery CIME_OUTPUT_ROOT|cut -d ':' -f2|sed 's/ //g'`
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`


yyyy=`echo $CASE|cut -d '_' -f2|cut -c 1-4`
st=`echo $CASE|cut -d '_' -f2|cut -c 5-6`
yyyystdd=$yyyy${st}15

echo "-----------STARTING ${CASE}.postproc monthly CESM-------- "`date`
cd $DIR_CASES/${CASE}
ic=`cat $DIR_CASES/${CASE}/logs/ic_${CASE}.txt`

set +euvx
. $DIR_UTIL/load_nco
set -euvx

# HERE SET YEAR AND MONTHS TO RECOVER
for mon in `seq -w 0 $(($nmonfore - 1))`
do
   curryear=`date -d "$yyyystdd + $mon month" +%Y`
   currmon=`date -d "$yyyystdd + $mon month" +%m`
# get check_pp_monthly each cycle from dictionary
   set +euvx
   . $dictionary
   set -euvx
   # add ic to global attributes of each output file
   #-----------------------------------------------------------------------
   type=h0
   for comp in atm rof lnd
   do
      file=$DIR_ARCHIVE/$CASE/$comp/hist/${CASE}.*.${type}.${curryear}-${currmon}.nc
      nfilezip=`ls $DIR_ARCHIVE/$CASE/$comp/hist/${CASE}.*.${type}.${curryear}-${currmon}.zip.nc |wc -l`
      if [[ $nfilezip -eq 1 ]]
      then
         continue
      fi
      pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
      $compress $pref.nc $pref.zip.nc
   #   rm $pref.nc  useless because copied from restdir each month
      ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
   done
   type=h
   for comp in ice 
   do
      file=$DIR_ARCHIVE/$CASE/$comp/hist/${CASE}.*.${type}.${curryear}-${currmon}.nc
      nfilezip=`ls $DIR_ARCHIVE/$CASE/$comp/hist/${CASE}.*.${type}.${curryear}-${currmon}.zip.nc |wc -l`
      if [[ $nfilezip -eq 1 ]] ; then
         continue
      fi
      pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
      if [[ -f $pref.nc ]] ; then
         $compress $pref.nc $pref.zip.nc
         rm $pref.nc
      fi
      ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
   done
   
   if [[ -d $DIR_ARCHIVE/$CASE/rest/${curryear}-$currmon-01-00000 ]] ; then
      rm -rf $DIR_ARCHIVE/$CASE/rest/${curryear}-$currmon-01-00000
   fi
   echo "-----------postproc_monthly_${CASE}.sh COMPLETED-------- "`date`
   touch  $check_pp_monthly
done

exit 0
