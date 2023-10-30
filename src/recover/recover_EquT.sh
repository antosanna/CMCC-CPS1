#!/bin/sh -l
#BSUB  -J recover_nemo_rebuild_EquT.sps4_199307_001 
#BSUB  -n 1 
#BSUB  -o logs/recover_nemo_rebuild_EquT.%J.out  
#BSUB  -e logs/recover_nemo_rebuild_EquT.%J.err
#BSUB  -R "span[ptile=1]"
#BSUB  -P 0574
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
echo "-----------STARTING sps4_199307_001.l_archive-------- "`date`
cd $DIR_CASES/sps4_199307_001
ic="atm=01,lnd=01,ocn=01"

# now rebuild EquT from NEMO
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
curryear=1993
for currmon in {07..10}
do
   $DIR_POST/nemo/rebuild_EquT_1month.sh sps4_199307_001 $yyyy $curryear $currmon "$ic" $DIR_ARCHIVE/sps4_199307_001/ocn/hist
done
echo "-----------postproc_monthly_sps4_199307_001.sh COMPLETED-------- "`date`

exit 0
