#!/bin/sh -l
#BSUB -J refcase
#BSUB -e logs/refcase_%J.err
#BSUB -o logs/refcase_%J.out
#BSUB -o logs/refcase_%J.out
set -euvx

# Created 2023-03-27 10:07:47
#
#ANDRANNO AGGIUNTI QUESTI in env_workflow.xml
##     <entry id="BATCH_COMMAND_FLAGS" value="-q p_medium -P 0566 -W 04:00 -x -app cm3">
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x  -app SERIAL_cm3">
#PER NEMO_REBUILD
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x -app SERIAL_cm3">
# QUESTO CASO CONCLUDE CORRETTAMENTE MA IL file-def NEMO DI DEFAULT
# exit prima della copia

here=$PWD
refcase=SPS4_HIST_hyb_refcase6
caso=SPS4_core_t2
DIR_CASES="/work/csp/as34319/CPS/CMCC-CPS1/cases/"
CASEDIR="/work/csp/as34319/CPS/CMCC-CPS1/cases/$caso"
if [[ -d $CASEDIR ]]
then
   rm -rf $CASEDIR
fi

/users_home/csp/sps-dev/CMCC_CM-dev122/cime/scripts/create_newcase --case "${CASEDIR}" --compset HIST_CAM60%WCSC_CLM51%BGC-CROP_CICE_NEMO_HYDROS_SGLC_SWAV --res f05_n0253 --driver nuopc --mach zeus --run-unsupported

cd $CASEDIR
./xmlchange NTASKS_ATM=-9
./xmlchange NTASKS_CPL=-9
./xmlchange NTASKS_OCN=202 #240
./xmlchange NTASKS_ICE=-9
./xmlchange NTASKS_ROF=-9
./xmlchange NTASKS_LND=-9
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
./xmlchange RUN_TYPE=startup
./xmlchange RUN_REFDIR=/work/csp/as34319/restart_cps_test
# here restart copied from Juno with 
#       mv 19921001_001_restart.nc restart.nc
# and   
#       mv 19920930_MB0.cice.r.1992-10-01-00000.nc cm3_cam122_cpl2000-bgc_t01.cice.r.0020-01-01-00000.nc
./xmlchange RUN_REFCASE=cm3_cam122_cpl2000-bgc_t01
./xmlchange RUN_REFDATE=0020-01-01
./xmlchange GET_REFCASE=FALSE
./xmlchange RUN_STARTDATE=2000-01-01
./xmlchange STOP_OPTION=ndays
#./xmlchange PIO_STRIDE=9
./xmlchange --force --subgroup case.run JOB_QUEUE=p_long
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=08:00

#./case.setup --reset
./case.setup

cp $DIR_CASES/$refcase/user_nl_* $CASEDIR

# THIS TAKES 10 MIN
./case.build

cp -r /work/csp/as34319/CESM2/SPS4_core_t1/run/init_generated_files /work/$DIVISION/$USER/CESM2/$caso/run
