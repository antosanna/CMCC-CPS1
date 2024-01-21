#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
if [[ $machine == "zeus" ]]
then
   echo "this script cannot run on Zeus machine because of conda issues"
   exit
fi
typeofrun="hindcast"
mkdir -p $DIR_LOG/$typeofrun/
LOG_FILE=$DIR_LOG/$typeofrun/SPS4_send_daily_report.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
rclone copy ${DIR_LOG}/report_${SPSSystem}.${machine}.`date +%Y%m%d` my_drive:SPS4_REPORTS/
set +euvx
condafunction deactivate $envcondarclone
exit 0
