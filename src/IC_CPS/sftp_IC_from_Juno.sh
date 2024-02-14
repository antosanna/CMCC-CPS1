#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
# USE sftp for the first attempt
# THEN sftp -a to complete an interrupted or incomplete push
#sftp -P 20022  -i .ssh/id_ed25519 cineca_cps@dtn01.cmcc.it 
yyyy=$1
st=$2
cd $SCRATCHDIR/from_op_machine
echo "get out/$yyyy$st/$yyyy${st}_scripts_CINECA.tar "|$cmd_IC_pull_from_remote
cd $IC_CAM_CPS_DIR/$st/
echo "get out/$yyyy$st/CPS1.cam.i.$yyyy-${st}-01-00000.??.nc "|$cmd_IC_pull_from_remote
cd $IC_CLM_CPS_DIR/$st/
echo "get out/$yyyy$st/CPS1.clm2.r.$yyyy-${st}-01-00000.??.nc "|$cmd_IC_pull_from_remote
echo "get out/$yyyy$st/CPS1.hydros.r.$yyyy-${st}-01-00000.??.nc "|$cmd_IC_pull_from_remote
cd $IC_NEMO_CPS_DIR/$st/
echo "get out/$yyyy$st/CPS1.nemo.r.$yyyy-${st}-01-00000.??.nc "|$cmd_IC_pull_from_remote
cd $IC_CICE_CPS_DIR/$st/
echo "get out/$yyyy$st/CPS1.cice.r.$yyyy-${st}-01-00000.??.nc "|$cmd_IC_pull_from_remote
