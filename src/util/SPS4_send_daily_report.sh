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

listaf=${DIR_LOG}/report/$typeofrun/report_${SPSSystem}.${machine}.`date +%Y%m%d`
${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_report.`date +%Y%m%d` -l $DIR_LOG/hindcast -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$yyyy $st hindcast/REPORTS '${listaf}'"
exit 0
