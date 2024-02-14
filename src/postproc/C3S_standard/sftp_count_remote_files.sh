#!/bin/sh -
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
# USE sftp for the first attempt
# THEN sftp -a to complete an interrupted or incomplete push
#sftp -P 20022  -i .ssh/id_ed25519 cineca_cps@dtn01.cmcc.it < count_remote_files.sh |grep -v sftp
$cmd_IC_pull_from_remote < $DIR_UTIL/count_remote_files.sh |grep -v sftp
