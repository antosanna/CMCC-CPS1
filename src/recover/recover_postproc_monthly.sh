#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
# reminder: this requires at least 15000MB
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv

yyyy=1994
st=08
caso=sps4_${yyyy}${st}_004

dbg=1 #only one month
mkdir -p $DIR_LOG/hindcast/recover/
echo "-----------STARTING ${caso}.l_archive-------- "`date`
cd $DIR_CASES/${caso}
DOUT_S_ROOT=`./xmlquery DOUT_S_ROOT|cut -d '=' -f2|cut -d ' ' -f2||sed 's/ //'`
echo $DOUT_S_ROOT
ic=`cat $DIR_CASES/${caso}/logs/ic_${caso}.txt`


# HERE SET YEAR AND MONTHS TO RECOVER
yyyystdd=$yyyy${st}15
for mon in `seq 0 $(($nmonfore - 1))`
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
         file=$DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.nc
         nfilezip=`ls $DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.zip.nc |wc -l`
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
         file=$DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.nc
         nfilezip=`ls $DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.zip.nc |wc -l`
         if [[ $nfilezip -eq 1 ]] ; then
            continue
         fi
         pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
         if [[ -f $pref.nc ]] ; then
            $DIR_UTIL/compress $pref.nc $pref.zip.nc
            rm $pref.nc
         fi
         ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
      done
      
      if [[ -d $DOUT_S_ROOT/rest/${curryear}-$currmon-01-00000 ]] ; then
         rm -rf $DOUT_S_ROOT/rest/${curryear}-$currmon-01-00000
      fi
      # now rebuild EquT from NEMO
      yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
      st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
      $DIR_POST/nemo/rebuild_EquT_1month.sh ${caso} $yyyy $curryear $currmon "$ic" $DOUT_S_ROOT/ocn/hist
      echo "-----------postproc_monthly_${caso}.sh COMPLETED-------- "`date`
      touch  $check_pp_monthly
      if [[ $dbg -eq 1 ]]
      then
         exit
      fi
   done

exit 0
