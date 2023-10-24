#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
refCESM=CMCC_CM-dev122
refcase=SPS4_HIST_hyb_day_t1
caso=clone_SPS4_HIST_hyb_month_t1
# here modify env_run after creation so in the script stop_option set to days
DIR_CASES=/work/csp/as34319/CPS/CMCC-CPS1/cases

if [[ -d $DIR_CASES/$caso ]]
then
   rm -rf $DIR_CASES/$caso
fi

/users_home/$DIVISION/$USER/$refCESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone $DIR_CASES/$refcase

cd $DIR_CASES/$caso


./case.setup --reset
./case.setup

./xmlchange BUILD_COMPLETE=TRUE
cp $DIR_EXE/cesm.exe.HIST $WORK/CESM2/$caso/bld/cesm.exe
