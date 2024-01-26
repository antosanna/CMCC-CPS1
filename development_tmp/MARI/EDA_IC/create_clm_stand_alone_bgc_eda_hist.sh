#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

script_dir=/users_home/csp/$USER/CPS/CMCC-CPS1/development_tmp/MARI/EDA_IC
refcase="cm3_lndHIST_bgc_NoSnAg_eda${member}_cyc1960"
caze="cm3_lndHIST_bgc_NoSnAg_eda${member}_hist"
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

###Here I am modifying the "presaero.hist:datafiles" previously in Daniele workdir to the one in $CESMDATAROOT
###to my understanding, the file is the same but in $CESMDATAROOT it is zipped (while it is not in Daniele's version)
###It seems to me a much safer choice for future portability
sed 's/MEMBER/'$member'/g' $script_dir/nml/user_nl_datm_streams_eda_hist > $DIR_CASES/$caze/user_nl_datm_streams
#to deactivate reset_snow
sed 's/reset_snow/!reset_snow/g' $script_dir/nml/user_nl_clm_NoSnAg > $DIR_CASES/$caze/user_nl_clm

cp -p $script_dir/nml/user_nl_hydros $DIR_CASES/$caze

cd ${DIR_CASES}/$caze

./xmlchange NTASKS=216
./xmlchange STOP_OPTION=nmonths
./xmlchange STOP_N=1
./xmlchange RESUBMIT=479

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange PROJECT=0490
./xmlchange CHARGE_ACCOUNT=0490
./xmlchange RUN_TYPE=hybrid
./xmlchange DATM_YR_ALIGN=1960
./xmlchange DATM_YR_START=1960
./xmlchange DATM_YR_END=2014
#to-be-revised
./xmlchange RUN_REFCASE=${refcase}
./xmlchange GET_REFCASE=TRUE
#to-be-revised
./xmlchange RUN_REFDIR="/work/csp/cp1/CMCC-CM/archive/${refcase}/rest/0011-01-01-00000" 
./xmlchange RUN_REFDATE=0011-01-01
./xmlchange RUN_STARTDATE=1960-01-01

./xmlchange PIO_STRIDE=18
./xmlchange --subgroup case.run JOB_QUEUE=p_medium
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=04:00


./case.setup
#./case.build
#./case.submit

