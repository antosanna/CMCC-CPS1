#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
#NEW 202103: checkfile e modificato year in yyyy

#COMPUTE ONE START-DATE AT A TIME
set -euxv
debug=0
st=$1
#NEW 202103 + yyyy instead of year
yyyy=$2
#NEW 202103 -
member=$3
#NEW 202103 + new input
checkfile=$4
#NEW 202103 -
set +euxv
# load correct descriptor
. $DIR_UTIL/descr_ensemble.sh $yyyy
. $dictionary
set -euxv
inpdir=$WORK_C3S/$yyyy$st/
# create final destinaton dir on /data
outdir=$FINALARCHC3S/$yyyy$st/
mkdir -p $outdir
# create working dir on /work
wkdir=$WORK_SPS3/wk_C3S_daily/$yyyy$st/
# this is the dir where C3S files are at the end of a forecast

#checkfile=flag at the end of qa_checker of C3S daily outputs
#checkfile=$wkdir/qa_checker_daily_ok_${member} in $dictionary
   
if [ ! -f $checkfile_daily ]
then
   mkdir -p $wkdir

# just copy variables already in the requested daily frequency
   daylist="lwepr rlt rsds hfss hfls tasmax tasmin mrlsl"
   for var in $daylist 
   do  
        rsync -auv $inpdir/*_${var}_r${member}i00p00.nc $outdir
   done

# just copy variables monthly averaged ocean fields 
   rsync -auv $inpdir/*ocean_mon_ocean2d_*r${member}i00p00.nc $outdir 

# check if already computed for actual member
   
   if [ ! -f $checkfile_daily ]
   then
# copy ncl script in wkdir
         input="$member"
         m3=`printf "%.3d" $((10#$member))`
         caso=${SPSsystem}_${yyyy}${st}_${m3}
# check that this member is not presently under processing
         cntpostrun=`${DIR_SPS35}/findjobs.sh -m $machine -n postprocC3S_from_archive_${caso} -c yes`
         cntcam=`${DIR_SPS35}/findjobs.sh -m $machine -n regrid_cam_${caso} -c yes`
         cntclm=`${DIR_SPS35}/findjobs.sh -m $machine -n postpc_clm_${caso} -c yes`
         cntall=$(( $cntpostrun + $cntcam + $cntclm  ))
         if [ $cntall -gt 0 ] ; then
# if so do not do anything
            continue 
         fi          
# do the daily mean
         $DIR_C3S/C3S_daily_mean.sh $member $wkdir $yyyy$st $outdir $checkfile "$daylist"
   fi
   if [ $debug -ne 0 ]
   then
      exit
   fi
fi
