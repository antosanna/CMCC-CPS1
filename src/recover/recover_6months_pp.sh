#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. ${DIR_UTIL}/load_nco
set -euvx
CASE=$1
CASEROOT=$DIR_CASES/$CASE
#
# go back to CASEROOT
cd $CASEROOT
NTASK=`./xmlquery NTASKS_OCN |cut -d ':' -f2|sed 's/ //g'`
# this is the number of parallel postprocessing you want to set
# NTASK MUST BE A MULTIPLE OF N!!!
N=`$DIR_UTIL/max_prime_factor.sh $NTASK`
CIME_OUTPUT_ROOT=`./xmlquery CIME_OUTPUT_ROOT|cut -d ':' -f2|sed 's/ //g'`
# activate needed env
conda activate $envcondanemo
yyyy=`echo $CASE|cut -d '_' -f2|cut -c 1-4`
st=`echo $CASE|cut -d '_' -f2|cut -c 5-6`
yyyystdd=$yyyy${st}15
for mon in `seq 0 $(($nmonfore - 1))`
do
   curryear=`date -d "$yyyystdd + $mon month" +%Y`
   currmon=`date -d "$yyyystdd + $mon month" +%m`
   set +euvx
   . $dictionary
   set -euvx
   
# add your frequencies and grids. The script skip them if not present
   for frq in 1m 1d
   do
      for grd in T U V W ptr
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
   # this should be independent from expID and general
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         mpirun -n $N python -m mpi4py $DIR_NEMO_REBUILD/nemo_rebuild.py -i $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
         stat=$?
   # if correctly merged remove single files
         if [[ $stat -eq 0 ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
         fi
      done
      for grd in scalar
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
         listarm=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0???.nc|grep -v $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         finalfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         scalarfile=`echo $finalfile|sed 's/_0000.nc/.nc/g'`
         mv $finalfile $scalarfile
         rm $listarm
      done
   done
   touch $check_nemo_rebuild
done

echo "-----------STARTING ${CASE}.postproc monthly CESM-------- "`date`
cd $DIR_CASES/${CASE}
ic=`cat $DIR_CASES/${CASE}/logs/ic_${CASE}.txt`


# HERE SET YEAR AND MONTHS TO RECOVER
for mon in `seq -w 0 $(($nmonfore - 1))`
do
   curryear=`date -d "$yyyystdd + $mon month" +%Y`
   currmon=`date -d "$yyyystdd + $mon month" +%m`
# get check_pp_monthly each cycle from dictionary
   set +euvx
   . $dictionary
   set -euvx
   if [[ -f $check_pp_monthly ]]
   then
      continue
   fi
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
   # now rebuild EquT from NEMO
   yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
   st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
   $DIR_POST/nemo/rebuild_EquT_1month.sh ${CASE} $yyyy $curryear $currmon "$ic" $DIR_ARCHIVE/$CASE/ocn/hist
   echo "-----------postproc_monthly_${CASE}.sh COMPLETED-------- "`date`
   touch  $check_pp_monthly
done

exit 0
