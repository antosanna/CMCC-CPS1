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
         if [[ $nfile -ne 0 ]] && [[ $grd == "ptr" ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_ptr_0???.nc
            continue
         fi
         if [[ $nfile -eq 0 ]]
         then
            if [[ `ls  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc|wc -l` -eq 1 ]]
# meaning that the file has been done but not zipped
            then
               ff=`basename $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc`
               ffzip=`echo $ff|rev|cut -d '.' -f2-|rev`
               $DIR_UTIL/compress.sh $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ff} $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ffzip}.zip.nc
               if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ffzip}.zip.nc ]]
               then
                  rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${ff}
               fi
            fi
            continue
         fi

         set +euxv
         . $DIR_UTIL/condaactivation.sh
         condafunction activate $envcondanemo
         set -euvx    # keep this instruction after conda activation


   # this should be independent from expID and general
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         $mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
   # if correctly merged remove single fileruns
         if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
            $DIR_UTIL/compress.sh $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc
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
               $DIR_UTIL/compress.sh  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ff  $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ffzip.zip.nc
               if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ffzip.zip.nc ]]
               then
                   rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/$ff
               fi 
            fi
            continue
         fi
         listarm=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0???.nc|grep -v $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         finalfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         headscalarfile=`echo $finalfile|sed 's/_0000.nc//g'`
         mv $finalfile $headscalarfile.nc
         $DIR_UTIL/compress.sh $headscalarfile.nc $headscalarfile.zip.nc
         if [[ -f $headscalarfile.zip.nc ]]
         then
             rm $headscalarfile.nc
         fi
         rm $listarm
      done
   done
   touch $check_nemo_rebuild
done
#set +euvx
#condafunction deactivate $envcondanemo
#condafunction activate $envcondacm3
#set -euvx

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
      $DIR_UTIL/compress.sh $pref.nc $pref.zip.nc
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
         $DIR_UTIL/compress.sh $pref.nc $pref.zip.nc
         rm $pref.nc
      fi
      ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
   done
   
   if [[ -d $DIR_ARCHIVE/$CASE/rest/${curryear}-$currmon-01-00000 ]] ; then
      rm -rf $DIR_ARCHIVE/$CASE/rest/${curryear}-$currmon-01-00000
   fi
   # now rebuild EquT from NEMO
   if [[ `ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.zip.nc|wc -l` -eq 0 ]]
   then
      if [[ `ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.nc|wc -l` -eq 1 ]]
      then
         rootname=`basename $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_1d_${curryear}${currmon}01_${curryear}${currmon}??_grid_EquT_T.nc  |rev |cut -d '.' -f1 --complement|rev`
         $DIR_UTIL/compress.sh $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.nc $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.zip.nc
         ncatted -O -a ic,global,a,c,"$ic" $DIR_ARCHIVE/$CASE/ocn/hist/${rootname}.zip.nc
         continue
      fi
     $DIR_POST/nemo/rebuild_EquT_1month.sh ${CASE} $yyyy $curryear $currmon "$ic" $DIR_ARCHIVE/$CASE/ocn/hist
   fi
   echo "-----------postproc_monthly_${CASE}.sh COMPLETED-------- "`date`
   touch  $check_pp_monthly
done

exit 0
