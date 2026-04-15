#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx
startdate=`date +%Y%m`
#
outlog=${DIR_REP}/$startdate/REPORT_${machine}.${SPSSystem}_${startdate}
logfile=${outlog}.txt
# load typeofrun
. $DIR_UTIL/descr_ensemble.sh `echo ${startdate:0:4}`
# load conda env for rclone
conda activate $envcondarclone
rclone_tag=${startdate}
if [[ ${typeofrun} == "forecast" ]] && [[ ${is_backup} -eq 1 ]] 
then
     rclone_tag=${startdate}_backup
fi
DIR_RCLONE=${typeofrun}/${rclone_tag}

# create directory on drive (works also if already existing)
rclone mkdir my_drive:${DIR_RCLONE}/REPORTS
if [[ -f $logfile ]]
then
   #copy general log
   rclone copy $logfile my_drive:${DIR_RCLONE}/REPORTS
fi
for ens in {001..054}
do
    logfile=${DIR_REP}/$startdate/report_${machine}.${SPSSystem}_${startdate}_${ens}.txt
    if [[ -f $logfile ]]
    then
       #copy general specific ensemble log
       rclone copy $logfile my_drive:${DIR_RCLONE}/REPORTS
    fi
done
