#!/bin/sh -l
# THIS SCRIPT IS MEANT TO CREATE A FAKE TIMESERIES OF CAM DATA TO TEST THE REGRID PROCEDURE
#BSUB -P 0490
#BSUB -J fake_cam_outputs
#BSUB -o /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/fake_cam_outputs_%J.out
#BSUB -e /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/fake_cam_outputs_%J.err
#BSUB -M 10000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx
testcase=cpl_XX_hyb_sps_t8
OUTDIR=/work/csp/cp1/CMCC-CM/archive/$testcase/atm/hist
wkdir=$SCRATCHDIR/regrid_tests/CAM/
mkdir -p $wkdir

for ftype in h1 h2 h3
do
   case $ftype in
      h1)freq=6hour;hour=00;;
      h2)freq=12hour;hour=00;;
      h3)freq=1day;hour=00;;
   esac
   if [[ ! -f $wkdir/$testcase.cam.$ftype.2000-01.done ]]
   then
      rsync -auv $OUTDIR/$testcase.cam.$ftype.2000-01-01-00000.nc $wkdir
      cdo settaxis,2000-06-01,${hour}:00:00,$freq $wkdir/$testcase.cam.$ftype.2000-01-01-00000.nc $wkdir/$testcase.cam.$ftype.tmp.nc

      cdo setreftime,2000-06-01,$hour:00:00 $wkdir/$testcase.cam.$ftype.tmp.nc $wkdir/$testcase.cam.$ftype.2000-06-01-00000.nc
      rm -f $wkdir/$testcase.cam.$ftype.tmp.nc
      cdo -O mergetime $wkdir/$testcase.cam.$ftype.2000-01-01-00000.nc $wkdir/$testcase.cam.$ftype.2000-06-01-00000.nc $wkdir/$ftype.2000-01.tmp.nc
      rsync -auv $wkdir/$ftype.2000-01.tmp.nc $wkdir/$testcase.cam.$ftype.2000-01-01-00000.nc
      rm -f $wkdir/$ftype.2000-01.tmp.nc

      touch $wkdir/$testcase.cam.$ftype.2000-01.done
   fi
   cdo selmon,1/7 -selyear,2000 $wkdir/$testcase.cam.$ftype.2000-01-01-00000.nc $wkdir/$ftype.2000-01.tmp.nc
   rsync -auv $wkdir/$ftype.2000-01.tmp.nc $wkdir/$testcase.cam.$ftype.2000-01-01-00000.nc
   rm -f $wkdir/$ftype.2000-01.tmp.nc
done

