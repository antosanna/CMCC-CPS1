#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

member=$1
refcase="cm3_lndSSP5-8.5_bgc_NoSnAg_eda${member}_scen"
caze="cm3_lndSSP5-8.5_bgc_NoSnAg_eda${member}_op"
if [[ -d $DIR_CASES/$caze ]] ; then
  rm -rf $DIR_CASES/$caze
fi
if [[ -d /work/$HEAD/$USER/CMCC-CM/${caze} ]] ; then
   rm -rf /work/$HEAD/$USER/CMCC-CM/${caze}
fi
compset=SSP585_DATM%GSWP3v1_CLM51%BGC-CROP_SICE_SOCN_HYDROS_SGLC_SWAV_SESP
res="f05_f05_mn0253"

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondacm3
set -euvx

${DIR_CESM}/cime/scripts/create_newcase --case $DIR_CASES/$caze --compset $compset --res $res --mach ${machine} --run-unsupported


sed 's/MEMBER/'$member'/g;s/csp/cmcc/g' ${DIR_TEMPL}/user_nl_datm_streams_eda_scen > $DIR_CASES/$caze/user_nl_datm_streams

#to deactivate reset_snow (we want to keep snow from hindcast scenario runs - needed for spinup when switching from GSWP to EDA)
#to deactivate check_finidat (should not be necessary - it was necessary to run in spinup mode and to switch from spinup to transient)
sed 's/reset_snow/!reset_snow/g;s/check_finidat/!check_finidat/g' ${DIR_TEMPL}/user_nl_clm_NoSnAg_scen > $DIR_CASES/$caze/user_nl_clm
cp -p ${DIR_TEMPL}/user_nl_hydros_clmIC $DIR_CASES/$caze/user_nl_hydros

cd ${DIR_CASES}/$caze

./xmlchange RUN_TYPE=branch #from scenario to scenario
./xmlchange NTASKS=216
./xmlchange STOP_OPTION=nmonths
./xmlchange STOP_N=1
./xmlchange RESUBMIT=0

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange PROJECT=0490
./xmlchange CHARGE_ACCOUNT=0490
./xmlchange RUN_TYPE=hybrid
./xmlchange DATM_YR_ALIGN=2015
./xmlchange DATM_YR_START=2015
./xmlchange DATM_YR_END=2030
#to-be-revised
./xmlchange RUN_REFCASE=${refcase}
./xmlchange GET_REFCASE=TRUE
#to-be-revised
./xmlchange RUN_REFDIR="/work/$HEAD/cp1/CMCC-CM/archive/${refcase}/rest/2023-01-01-00000" 
./xmlchange RUN_REFDATE=2023-01-01
./xmlchange RUN_STARTDATE=2023-01-01

./xmlchange PIO_STRIDE=18
./xmlchange --subgroup case.run JOB_QUEUE=p_medium
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=04:00


./case.setup
#./case.build
#./case.submit

