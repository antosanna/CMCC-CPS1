#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_nco
if [[ $machine == "juno" ]]
then
   . $DIR_TEMPL/load_ncl
fi
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
workdir_apec=$5
set +euxv
# load correct descriptor
if [ $yyyy -ge ${iniy_fore} ]
then
   . $DIR_SPS35/descr_forecast.sh
else
   . $DIR_SPS35/descr_hindcast.sh
fi
set -euxv
inpdir=$WORK_C3S/$yyyy$st/
outdir=${workdir_apec}/daily/
mkdir -p $outdir

wkdir=$SCRATCHDIR/wk_C3S_daily_APEC/$yyyy$st/

#checkfile=flag at the end of qa_checker of C3S daily outputs
#ANTO checkfile=$wkdir/qa_checker_daily_ok_${member}

 
if [ ! -f $checkfile ]
then
   mkdir -p $wkdir

   if [[ ! -f $wkdir/C3S_daily_mean.txt ]]
   then

cat > $wkdir/C3S_daily_mean.txt << EOF
typeofrun= $typeofrun
inpdir= $inpdir
outdir= $outdir
wkdir= $wkdir
year= $yyyy
st= $st
varname6= tso   tas   psl
realm6=   ocean   atmos   atmos   
varname12=   ta zg ua va 
realm12= atmos atmos atmos atmos
lev= 4 3 4 4
levvalues4= 92500 85000 50000 20000
levvalues3= 85000 50000 20000
levvalues1= 85000 
EOF

  fi


# just copy variables already in the requested daily frequency
   daylist="lwepr rlt"
   for var in $daylist 
   do  
        rsync -auv $inpdir/*_${var}_r${member}i00p00.nc $outdir
   done

# check if already computed for actual member
   
   if [ ! -f $checkfile ]
   then
# copy ncl script in wkdir
         cp $DIR_POST/APEC/C3S_daily_mean_2d.ncl $wkdir
         input="$member"
         caso=${SPSsystem}_${yyyy}${st}_${member}
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
         ${DIR_POST}/APEC/C3S_daily_mean_ncl.sh $member $wkdir $yyyy$st $outdir $checkfile "$daylist"
   fi
   if [ $debug -ne 0 ]
   then
      exit
   fi
fi
