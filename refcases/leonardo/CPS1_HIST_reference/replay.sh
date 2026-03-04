#!/bin/bash

set -e

# Created 2026-01-29 13:52:11

CASEDIR="/leonardo/home/usera07cmc/a07cmc00/CPS/CMCC-CPS1/refcases/leonardo/CPS1_HIST_reference"

/leonardo/home/usera07cmc/a07cmc00/CMCC-CM//cime/scripts/create_newcase --case "${CASEDIR}" --compset HIST_CAM60%WCSC_CLM51%BGC-CROP_CICE_NEMO_HYDROS_SGLC_SWAV --res f05_n0253 --driver nuopc --mach leonardo --run-unsupported

cd "${CASEDIR}"

./xmlchange STOP_OPTION=nmonths

./xmlchange NTASKS_ATM=288

./xmlchange NTASKS_CPL=288

./xmlchange NTASKS_OCN=279

./xmlchange NTASKS_ICE=288

./xmlchange NTASKS_ROF=288

./xmlchange NTASKS_LND=288

./xmlchange PIO_STRIDE=-99

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

./xmlchange --force --subgroup case.run JOB_QUEUE=dcgp_cmcc_prod

./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=08:00

./case.setup --reset

./case.setup

./case.build

