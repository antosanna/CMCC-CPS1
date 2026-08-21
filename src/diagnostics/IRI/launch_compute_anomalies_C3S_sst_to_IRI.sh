#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
yyyy=$1 #2026
st=$2 #08
start_date=$yyyy$st

dbg=0
. ${DIR_UTIL}/descr_ensemble.sh $yyyy

dirlog=${DIR_LOG}/${typeofrun}/${start_date}/diagnostics
mkdir -p $dirlog

refperiod=$3 #1993-2020
var="sst"

DATASET=ERA5
flag_done=$dirlog/sst_anomalies_${refperiod}_IRI
cd $DIR_DIAG_C3S
echo 'postprocessing $var '$st
$DIR_DIAG/IRI/compute_anomalies_C3S_sst_to_IRI.sh $yyyy $st $var ${flag_done} $DATASET $dbg


exit 0
