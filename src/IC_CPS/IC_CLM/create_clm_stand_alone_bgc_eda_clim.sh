#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

caze="cm3_lndHIST_bgc_NoSnAg_eda${member}_cyc1960"
if [[ -d $DIR_CASES/$caze ]] ; then
  rm -rf $DIR_CASES/$caze
fi

compset=HIST_DATM%GSWP3v1_CLM51%BGC-CROP_SICE_SOCN_HYDROS_SGLC_SWAV_SESP
res="f05_f05_mn0253"

#to-be-revied
cesmref=CMCC-CM_v9
#/users_home/csp/dp16116/CMCC-CM_v9
user_mod=dp16116
/users_home/$DIVISION/${user_mod}/$cesmref/cime/scripts/create_newcase --case $DIR_CASES/$caze --compset $compset --res $res --mach ${machine} --run-unsupported

sed 's/MEMBER/'$member'/g' ${DIR_TEMPL}/user_nl_datm_streams_eda_clim > $DIR_CASES/$caze/user_nl_datm_streams
cp -p ${DIR_TEMPL}/user_nl_clm_NoSnAg $DIR_CASES/$caze/user_nl_clm
cp -p ${DIR_TEMPL}/user_nl_hydros_clmIC $DIR_CASES/$caze/user_nl_hydros

cd ${DIR_CASES}/$caze

./xmlchange NTASKS=216
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=1
./xmlchange RESUBMIT=9

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange PROJECT=0490
./xmlchange CHARGE_ACCOUNT=0490
./xmlchange RUN_TYPE=hybrid
./xmlchange DATM_YR_ALIGN=1960
./xmlchange DATM_YR_START=1960
./xmlchange DATM_YR_END=1960
#to-be-revised
./xmlchange RUN_REFCASE=cm3_lndHIST_s45_HSn
./xmlchange GET_REFCASE=TRUE
./xmlchange RUN_REFDIR="/work/csp/dp16116/CMCC-CM/archive/cm3_lndHIST_s45_HSn/rest/1960-01-01-00000" 
./xmlchange RUN_REFDATE=1960-01-01
./xmlchange RUN_STARTDATE=0001-01-01

./xmlchange PIO_STRIDE=18
./xmlchange --subgroup case.run JOB_QUEUE=p_medium
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=04:00


./case.setup
#./case.build
#./case.submit

