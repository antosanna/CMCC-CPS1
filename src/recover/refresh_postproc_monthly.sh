#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
yyyy=1994
st=07
nrun=032

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
caso=${SPSSystem}_${yyyy}${st}_${nrun}
ic=`cat $DIR_CASES/${caso}/logs/ic_${caso}.txt`

cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------

sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_monthly.sh > $DIR_CASES/$caso/postproc_monthly_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh

