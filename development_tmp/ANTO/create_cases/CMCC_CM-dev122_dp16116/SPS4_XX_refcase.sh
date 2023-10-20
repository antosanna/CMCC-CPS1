set -euvx

# Created 2023-03-27 10:07:47
#
#ANDRANNO AGGIUNTI QUESTI in env_workflow.xml
##     <entry id="BATCH_COMMAND_FLAGS" value="-q p_medium -P 0566 -W 04:00 -x -app cm3">
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x  -app SERIAL_cm3">
#PER NEMO_REBUILD
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x -app SERIAL_cm3">

here=$PWD
CASEDIR="/work/csp/as34319/CPS/CMCC-CPS1/cases/SPS4_HIST_hyb_refcase"
if [[ -d $CASEDIR ]]
then
   rm -rf $CASEDIR
fi

/users_home/csp/sps-dev/CMCC-CM_dev122/cime/scripts/create_newcase --case "${CASEDIR}" --compset  2000_CAM60%WCSC_CLM51%BGC-CROP_CICE_NEMO_HYDROS_SGLC_SWAV --res f05_n0253 --driver nuopc --mach juno --run-unsupported

cd $CASEDIR
./xmlchange NTASKS_ATM=-4
./xmlchange NTASKS_CPL=-4
./xmlchange NTASKS_OCN=279
./xmlchange NTASKS_ICE=-4
./xmlchange NTASKS_ROF=-4
./xmlchange NTASKS_LND=-4
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_ESP=1
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_OCN=0
./xmlchange CAM_CONFIG_OPTS="-phys cam_dev -chem waccm_sc_mam4 -nlev 83"
./xmlchange RESUBMIT=1
./xmlchange CLM_FORCE_COLDSTART=off
./xmlchange ROF_NCPL=8
./xmlchange CHARGE_ACCOUNT=\0490
./xmlchange PROJECT=\0490
./xmlchange STOP_N=1
./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_REFDIR=/work/csp/as34319/restart_cps_test/0020-01-01-00000/
./xmlchange RUN_REFCASE=cm3_cam122_cpl2000-bgc_t01
./xmlchange RUN_REFDATE=0020-01-01
./xmlchange GET_REFCASE=TRUE
./xmlchange RUN_STARTDATE=2000-01-01
./xmlchange STOP_OPTION=nmonths
./xmlchange PIO_STRIDE=18
./xmlchange --force --subgroup case.run JOB_QUEUE=p_long
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=08:00

./case.setup --reset
./case.setup

cp /users_home/csp/cp1/CPS/usermods_dirs/CMCC-SPS4juno/user_nl_cice $CASEDIR
cp /users_home/csp/cp1/CPS/usermods_dirs/CMCC-SPS4juno/user_nl_cam $CASEDIR
cp /users_home/csp/cp1/CPS/usermods_dirs/CMCC-SPS4juno/user_nl_hydros $CASEDIR
cp /users_home/csp/cp1/CPS/usermods_dirs/CMCC-SPS4juno/user_nl_clm $CASEDIR

./case.build
#SECTION FOR NEMO 
cp /users_home/csp/cp1/CPS/namelist/file_def_nemo-oce.xml Buildconf/nemoconf/
# questo file e' stato modificato ad hoc
cp /users_home/csp/cp1/CPS/namelist/env_workflow.xml .
