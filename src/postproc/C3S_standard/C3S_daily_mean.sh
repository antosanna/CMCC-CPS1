#!/bin/sh -l
#BSUB -q s_long
#BSUB -J C3S_daily_mean
#BSUB -e logs/C3S_daily_mean_%J.err
#BSUB -o logs/C3S_daily_mean_%J.out

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euxv
export member=$1
ens=$member
wkdir=$2
stdate=$3
outdir=$4  #$FINALARCHC3S/$yyyy$st
daylist="$5"
check_ok=$6 #wkdir/C3S_daily_mean_2d_${member}_ok

yyyy=`echo $stdate |cut -c 1-4`
st=`echo $stdate |cut -c 5-6`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
if [ ! -d $wkdir ]
then
   echo "something wrong $wkdir does not exist"
fi
#NEW 202103 !!! +
varlist="tso tas uas vas tdps psl ta zg ua va hus"
if [ -f $check_ok ] 
then
#se i file C3S ad alta frequenza sono piu' recenti rifai
   for var in $varlist
   do
      cd $WORK_C3S/$stdate/
      file=`ls *${var}_r${member}i00p00.nc`
      if [[ $file -nt ${check_ok} ]]
      then
         rm $check_ok
         break 
      fi
   done
fi
#NEW 202103 !!! -

if [ ! -f $check_ok ]
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
      ncks -O -6 $file $wkdir/${var}_${stdate}_${ens}_orig.nc

#ta, ua, va: 925, 850, 500, 200
#zg 850, 500, 200
#hus: 850  (ANTO added 700 20240918)
      case $var in
         zg) option="-sellevel,85000,50000,20000";level="pressure";;  
         hus) option="-sellevel,70000,85000";level="pressure";;  
         ta | ua | va) option="-sellevel,92500,85000,50000,20000";level="pressure";;  
         *) option="";level="surface";;
      esac
#redefine timeaxis
      cdo settaxis,$yyyy-$st-01,00:00:00,$incr $option $wkdir/${var}_${yyyy}${st}_${ens}_orig.nc $wkdir/${var}_${yyyy}${st}_${ens}_settax.nc
      cdo setreftime,$yyyy-$st-01,00:00:00 $wkdir/${var}_${yyyy}${st}_${ens}_settax.nc $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc

      nt=`cdo -ntime $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc`
#cdo daily mean - descarding first time step (I.C.)
      cdo -O shifttime,1sec -daymean -shifttime,-1sec -seltimestep,2/$nt $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc  $outdir/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${realm}_day_${level}_${var}_r${ens}i00p00.nc
      rm $wkdir/${var}_${yyyy}${st}_${ens}_*nc
   done
   touch $check_ok
fi
if [ ! -f $check_ok ]
then
   title="[C3Sdaily] ${CPSSYS} daily postprocessing ERROR"
   body="$stdate $member $DIR_C3S/C3S_daily_mean.sh did not complete correctly. Check ${DIR_LOG}/$typeofrun/${stdate}/launch_C3S_daily_${stdate}_${member}*.err/out"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 11
fi
echo "That's all Folks"
