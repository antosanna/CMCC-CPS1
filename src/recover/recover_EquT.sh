#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
caso=sps4_199307_001
echo "-----------STARTING ${caso}.l_archive-------- "`date`
cd $DIR_CASES/${caso}
ic=`cat $DIR_CASES/${caso}/logs/ic_${caso}.txt`

# now rebuild EquT from NEMO
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
curryear=1993
for currmon in {07..10}
do
   $DIR_POST/nemo/rebuild_EquT_1month.sh ${caso} $yyyy $curryear $currmon "$ic" $DIR_ARCHIVE/${caso}/ocn/hist
done
echo "-----------postproc_monthly_${caso}.sh COMPLETED-------- "`date`

exit 0
