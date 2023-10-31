#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv

caso=sps4_199307_003

debug=0 #only one month
mkdir -p $SCRATCHDIR/ANTO/logs
echo "-----------STARTING ${caso}.l_archive-------- "`date`
cd $DIR_CASES/${caso}
DOUT_S_ROOT=`./xmlquery DOUT_S_ROOT|cut -d '=' -f2|cut -d ' ' -f2||sed 's/ //'`
echo $DOUT_S_ROOT
ic=`cat $DIR_CASES/${caso}/logs/ic_${caso}.txt`


# HERE SET YEAR AND MONTHS TO RECOVER
for curryear in 1993
do
   for currmon in {07..10}
   do
      flag_done=$SCRATCHDIR/ANTO/logs/postproc_monthly_${curryear}${currmon}_done
      if [[ -f $flag_done ]]
      then
         continue
      fi
      # add ic to global attributes of each output file
      #-----------------------------------------------------------------------
      type=h0
      for comp in atm rof lnd
      do
         file=$DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.nc
         pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
         $compress $pref.nc $pref.zip.nc
      #   rm $pref.nc  useless because copied from restdir each month
         ncatted -O -a ic,global,a,c,"$ic" $pref.zip.nc
      done
      type=h
      for comp in ice 
      do
         file=$DOUT_S_ROOT/$comp/hist/${caso}.*.${type}.${curryear}-${currmon}.nc
         pref=`ls $file |rev |cut -d '.' -f1 --complement|rev`
         if [[ -f $pref.nc ]] ; then
            $compress $pref.nc $pref.zip.nc
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
      touch  $flag_done
      if [[ $debug -eq 1 ]]
      then
         exit
      fi
   done
done

exit 0
