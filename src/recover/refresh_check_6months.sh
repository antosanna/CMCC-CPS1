#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
yyyy=1993
st=07
nrun=017

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
caso=${SPSSystem}_${yyyy}${st}_${nrun}

cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso

# cp and change script for nemo standardization
# THIS GOES IN env_workflow
sed -e "s/CASO/$caso/g;s/YYYY/$yyyy/g;s/mese/$st/g" $DIR_TEMPL/check_6months_output_in_archive.sh > $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
chmod u+x $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
