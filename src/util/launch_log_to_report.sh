#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh


# check if there is another job submitted by crontab with the same name
. $DIR_UTIL/condaactivation.sh
condafunciont activate $envconda_report_SPS
set -evxu
stdate=`date +%Y%m`
if [[ $# -eq 1 ]]
then
   stdate=$1
fi
python log_to_report.$machine.py $DIR_REP/$stdate/REPORT_${machine}.sps4_${stdate}.txt -o $DIR_REP/$stdate/report_${stdate}.pdf --title "Report $stdate" 

set +evxu
condafunction activate $envcondarclone
set -evxu
rclone copy $DIR_REP/$stdate/report_${stdate}.pdf my_drive:forecast/$stdate/REPORTS/
