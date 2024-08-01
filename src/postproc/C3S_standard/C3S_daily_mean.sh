#!/bin/sh -l
#BSUB -q s_long
#BSUB -J C3S_daily_mean
#BSUB -e logs/C3S_daily_mean_%J.err
#BSUB -o logs/C3S_daily_mean_%J.out

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euxv
export member=$1
ens=$member
wkdir=$2
stdate=$3
outdir=$4  #$FINALARCHC3S/$yyyy$st
#NEW 202103 !!! position of checkfile
checkfile=$5 #$FINALARCHC3S/$yyyy$st/qa_checker_daily_ok_${member}
daylist="$6"

#NEW 202103 !!! 
# descr_hindcast.sh o descr_forecast.sh
yyyy=`echo $stdate |cut -c 1-4`
st=`echo $stdate |cut -c 5-6`
set +euvx
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
set -euvx
if [ ! -d $wkdir ]
then
   echo "something wrong $wkdir does not exist"
fi
#NEW 202103 !!! +
# condiziona ncl al checkfile
checkncl=$wkdir/C3S_daily_mean_2d_${member}_ok
varlist="tso tas uas vas tdps psl ta zg ua va hus"
if [ -f $checkncl ] 
then
#se i file C3S ad alta frequenza sono piu' recenti rifai
   for var in $varlist
   do
      cd $WORK_C3S/$stdate/
      file=`ls *${var}_r${member}i00p00.nc`
      if [[ $file -nt ${checkncl} ]]
      then
         rm $checkncl
         break 
      fi
   done
fi
#NEW 202103 !!! -

if [ ! -f $checkncl ]
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
      cdo settaxis,$yyyy-$st-01,00:00:00,$incr $option $wkdir/${var}_${yyyy}${st}_${ens}_orig.nc $wkdir/${var}_${yyyy}${st}_${ens}_settax.nc
      cdo setreftime,$yyyy-$st-01,00:00:00 $wkdir/${var}_${yyyy}${st}_${ens}_settax.nc $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc

      nt=`cdo -ntime $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc`
#cdo daily mean - descarding first time step (I.C.)
      cdo -O shifttime,1sec -daymean -shifttime,-1sec -seltimestep,2/$nt $wkdir/${var}_${yyyy}${st}_${ens}_setref.nc  $outdir/cmcc_CMCC-CM2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_${realm}_day_${level}_${var}_r${ens}i00p00.nc
      rm $wkdir/${var}_${yyyy}${st}_${ens}_*nc
   done
   touch $checkncl
fi
if [ -f $checkncl ]
then
#NEW 202103 !!! +
# condiziona il qa_checker al suo checkfile e spostato il log in $DIR_LOG/$typeofrun
# if $checkfile for quality check exist check if older than corresponding files 
   if [ -f $checkfile ]
   then
      for var in $varlist
      do
         cd $outdir
         file=`ls *${var}_r${member}i00p00.nc`
         if [[ $file -nt ${checkfile} ]]
         then
            rm $checkfile
            break 
         fi
      done
   fi
   if [ ! -f $checkfile ]
   then
#NEW 202103 !!!  -
      $DIR_C3S/launch_c3s_qa_checker_keep_in_archive.sh ${stdate} $member $wkdir $outdir $checkfile "$daylist"
   fi
else # checkncl does not exist
   title="[C3Sdaily] ${SPSSYS} forecast ERROR"
   body="$stdate $member $DIR_C3S/C3S_daily_mean.sh did not complete correctly. Check ${DIR_LOG}/$typeofrun/${stdate}/launch_C3S_daily_${stdate}_${member}*.err/out"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 11
fi
echo "That's all Folks"
