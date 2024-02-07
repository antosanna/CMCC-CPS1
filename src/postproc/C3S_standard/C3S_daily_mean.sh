#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euxv
export member=$1
wkdir=$2
stdate=$3
outdir=$4  #$FINALARCHC3S/$yyyy$st
daylist="$5"

yyyy=`echo $stdate |cut -c 1-4`
st=`echo $stdate |cut -c 5-6`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
. ${dictionary}
#checkfile_daily
#checkfile_daily_done=$DIR_LOG/$typeofrun/$yyyy$st/C3S_daily_postproc/C3S_daily_mean_2d_${member}_done
set -euvx
if [ ! -d $wkdir ]
then
   echo "something wrong $wkdir does not exist"
fi
varlist="tso tas uas vas tdps psl ta zg ua va hus"
if [ -f $checkfile_daily_done ] 
then
#if C3S files are newer redo
   for var in $varlist
   do
      cd $WORK_C3S/$stdate/
      file=`ls *${var}_r${member}i00p00.nc`
      if [[ $file -nt ${checkfile_daily_done} ]]
      then
         rm $checkfile_daily_done
         break 
      fi
   done
fi

if [ ! -f $checkfile_daily_done ]
then
   for var in $varlist
   do
      cd $WORK_C3S/$stdate/
   
      file=`ls *${var}_r${member}i00p00.nc`
      realm=`basename $file|cut -d '_' -f5`
      freq=`basename $file|cut -d '_' -f6`
      if [[ "$freq" == "6hr" ]]
      then
         incr=6hours
      elif [[ "$freq" == "12hr" ]]
      then
         incr=12hours
      fi
   
#from netcdf4 to netcdf3
      ncks -O -6 $file $wkdir/${var}_${stdate}_${member}_orig.nc

#ta, ua, va: 925, 850, 500, 200
#zg 850, 500, 200
#hus: 850
      case $var in
         zg) option="-sellevel,85000,50000,20000";level="pressure";;  
         hus) option="-sellevel,85000";level="pressure";;  
         ta) option="-sellevel,92500,85000,50000,20000";level="pressure";;  
         ua) option="-sellevel,92500,85000,50000,20000";level="pressure";;  
         va) option="-sellevel,92500,85000,50000,20000";level="pressure";;  
         *) option="";level="surface";;
      esac
#redefine timeaxis
      cdo settaxis,$yyyy-$st-01,00:00:00,$incr $option $wkdir/${var}_${yyyy}${st}_${member}_orig.nc $wkdir/${var}_${yyyy}${st}_${member}_settax.nc
      cdo setreftime,$yyyy-$st-01,00:00:00 $wkdir/${var}_${yyyy}${st}_${member}_settax.nc $wkdir/${var}_${yyyy}${st}_${member}_setref.nc

      nt=`cdo -ntime $wkdir/${var}_${yyyy}${st}_${member}_setref.nc`
#cdo daily mean - descarding first time step (I.C.)
      cdo -O shifttime,1sec -daymean -shifttime,-1sec -seltimestep,2/$nt $wkdir/${var}_${yyyy}${st}_${member}_setref.nc  $outdir/cmcc_CMCC-CM2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${realm}_day_${level}_${var}_r${member}i00p00.nc
      rm $wkdir/${var}_${yyyy}${st}_${member}_*nc
   done
   touch $checkfile_daily_done
fi
if [ -f $checkfile_daily_done ]
then
   if [ -f $checkfile_daily ]
   then
      for var in $varlist
      do
         cd $outdir
         file=`ls *${var}_r${member}i00p00.nc`
         if [[ $file -nt ${checkfile_daily} ]]
         then
            rm $checkfile_daily
            break 
         fi
      done
   fi
   if [ ! -f $checkfile_daily ]
   then
# THIS IS STILL NOT AVAILABLE
#      $DIR_C3S/launch_c3s_qa_checker_keep_in_archive.sh ${stdate} $member $wkdir $outdir "$daylist"
   fi
else # checkfile_daily_done does not exist
   caso=${SPSSystem}_${stdate}_0${member}
   title="[C3Sdaily] ${SPSSYS} forecast ERROR"
   body="$stdate $member $DIR_C3S/C3S_daily_mean.sh did not complete correctly. Check ${DIR_LOG}/$typeofrun/${stdate}/C3Schecker_${caso}.err/out"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 11
fi
echo "That's all Folks"
