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
            if [[ `ls  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc|wc -l` -eq 1 ]]
# meaning that the file has been done but not zipped
            then
               ff=`basename $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc`
               ffzip=`echo $ff|rev|cut -d '.' -f2-|rev`
               $compress $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ff} $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ffzip}.zip.nc
               if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ffzip}.zip.nc ]]
               then
                  rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ff}
               fi
            fi
            continue
            if [[ ! -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ffzip}.zip.nc ]]
            then
               title="[ERROR CPS1]-unrecoverable error in nemo_rebuild"
               message="Merging Nemo domains underwent an unrecoverable error for ${curryear}${currmon}!!. Output ${frq}_${curryear}${currmon}*grid_${grd} not present. Stop now case $CASE!!"
               $DIR_UTIL/sendmail.sh -t $title -M $message -e $mymail
               exit
            fi
         fi
   # this should be independent from expID and general
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         mpirun -n $N python -m mpi4py $DIR_NEMO_REBUILD/nemo_rebuild.py -i $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
   # if correctly merged remove single files
         if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
            $compress $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc
            if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc ]]
            then
                rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc
            fi 
         fi    

      done
      for grd in scalar
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            if [[ `ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc|wc -l` -eq 1 ]]
            then
               ff=`basename $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc`
               ffzip=`echo $ff|rev|cut -d '.' -f2-|rev`
               $compress  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ff  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ffzip.zip.nc
            fi
            continue
         fi
         listarm=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0???.nc|grep -v $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         finalfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         headscalarfile=`echo $finalfile|sed 's/_0000.nc//g'`
         mv $finalfile $headscalarfile.nc
         $compress $headscalarfile.nc $headscalarfile.zip.nc
         if [[ -f $headscalarfile.zip.nc ]]
         then
             rm $headscalarfile.nc
         fi
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
   if [[ `ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.zip.nc|wc -l` -eq 0 ]]
   then
      if [[ `ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.nc|wc -l` -eq 1 ]]
      then
         rootname=`basename $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.nc  |rev |cut -d '.' -f1 --complement|rev`
         $compress $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.nc $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.zip.nc
         ncatted -O -a ic,global,a,c,"$ic" $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.zip.nc
         continue
      fi
     $DIR_POST/nemo/rebuild_EquT_1month.sh ${CASE} $yyyy $curryear $currmon "$ic" $DIR_ARCHIVE/$CASE/ocn/hist
   fi
   echo "-----------postproc_monthly_${CASE}.sh COMPLETED-------- "`date`
   touch  $check_pp_monthly
done

exit 0
