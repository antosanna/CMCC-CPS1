#!/bin/bash

set -e

# Created 2026-01-29 15:24:48

CASEDIR="/users_home/cmcc/cp1/CPS/CMCC-CPS1/refcases/juno/CPS1_SSP585_reference"

/users_home/cmcc/cp1/CMCC-CM//cime/scripts/create_newcase --case "${CASEDIR}" --compset SSP585_CAM60%WCSC_CLM51%BGC-CROP_CICE_NEMO_HYDROS_SGLC_SWAV --res f05_n0253 --driver nuopc --mach juno --run-unsupported

cd "${CASEDIR}"

./xmlchange STOP_OPTION=nmonths

./xmlchange NTASKS_ATM=-4

./xmlchange NTASKS_CPL=-4

./xmlchange NTASKS_OCN=279

./xmlchange NTASKS_ICE=-4

./xmlchange NTASKS_ROF=-4

./xmlchange NTASKS_LND=-4

./xmlchange PIO_STRIDE=18

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

./xmlchange CHARGE_ACCOUNT=0490

./xmlchange PROJECT=0490

./xmlchange STOP_N=1

./xmlchange RUN_TYPE=hybrid

./xmlchange --force --subgroup case.run JOB_QUEUE=p_long

./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=08:00

./case.setup --reset

./case.setup

./case.build

