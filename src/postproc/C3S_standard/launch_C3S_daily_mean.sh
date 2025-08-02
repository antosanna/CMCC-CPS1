#!/bin/sh -l
#BSUB -J C3S_daily_offline
#BSUB -e logs/C3S_daily_offline_%J.err
#BSUB -o logs/C3S_daily_offline_%J.out
#BSUB -P 0490
#BSUB -M 3000
#BSUB -q s_long

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco

#COMPUTE ONE START-DATE AT A TIME
set -euxv
dbg=0   # dbg=1 one member only; dbg=2 one year only
st=10
#iniy=$iniy_hind
iniy=1995
endy=$endy_hind
inimember=01
endmember=30
if [[ $# -ge 1 ]]
then
   st=${1}
set -eux
fi
if [[ $# -ge 2 ]]
then
   iniy=${2}
   endy=${2}
fi
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $iniy
#set -euvx
set -eux
if [[ $# -ge 3 ]]
then
   inimember=${3}
   endmember=${3}
fi

for yyyy in `seq $iniy $endy`
do
   set +euxv
   # load correct descriptor
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   . $dictionary
   set -euxv
   inpdir=$WORK_C3S/$yyyy$st/
   # create final destinaton dir on /data
   outdir=$FINALARCHC3S/$yyyy$st/
   # create working dir on /work
   wkdir=$SCRATCHDIR/wk_C3S_daily/$yyyy$st/
   # this is the dir where C3S files are at the end of a forecast
   
   mkdir -p $wkdir
   
   #NEW 202103 -
   for member in `seq -w $inimember $endmember`
   do
      mkdir -p $outdir
   
   # just copy variables already in the requested daily frequency
      daylist="sic lwepr lwesnw rlt rsds hfss hfls tasmax tasmin mrlsl"
      for var in $daylist 
      do  
        rsync -auv $inpdir/*_${var}_r${member}i00p00.nc $outdir
      done
   
   # just copy variables monthly averaged ocean fields 
      rsync -auv $inpdir/*ocean_mon_ocean2d_*r${member}i00p00.nc $outdir 
      input="$member"
      ens=`printf "%.3d" $((10#$member))`
      caso=${SPSSystem}_${yyyy}${st}_${ens}
   # check that this member is not presently under processing
      cntall=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
      if [[ $cntall -gt 0 ]] ; then
        cnt_C3Scheck=`${DIR_UTIL}/findjobs.sh -m $machine -n C3Schecker_${caso} -c yes`
        cnt_C3Srecover=`${DIR_UTIL}/findjobs.sh -m $machine -n recover_false_spike_c3s_${caso} -c yes`
        if [[ ${cnt_C3Scheck} -eq ${cntall}  ]] || [[ ${cnt_C3Srecover} -eq ${cntall} ]] ; then
        # if it is the father job go on with C3S_daily_mean    
            echo "just C3Schecker present on queue for $caso - go on"
        else
        # otherwise do not do anything
           continue
        fi 
      fi          
   # do the daily mean
      checkfile_daily=$wkdir/C3S_daily_mean_2d_${member}_ok
      $DIR_C3S/C3S_daily_mean.sh $member $wkdir $yyyy$st $outdir "$daylist" $checkfile_daily
      if [[ $dbg -eq 1 ]]
      then
         exit
      fi
   done #members
   if [[ $dbg -eq 2 ]]
   then
      exit
   fi
done #yyyy 
