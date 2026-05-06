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
rclone_tag=${startdate}
if [[ ${typeofrun} == "forecast" ]] && [[ ${is_backup} -eq 1 ]] 
then
     rclone_tag=${startdate}_backup
fi
DIR_RCLONE=${typeofrun}/${rclone_tag}

# create directory on drive (works also if already existing)
if [[ -f $logfile ]]
then
   #copy general log
   listaf=$logfile
   mkdir -p $DIR_LOG/wrapper
   ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_${startdate} -l $DIR_LOG/wrapper -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$DIR_RCLONE/REPORTS '${listaf}'"
fi
for ens in {001..054}
do
    logfile=${DIR_REP}/$startdate/report_${machine}.${SPSSystem}_${startdate}_${ens}.txt
    if [[ -f $logfile ]]
    then
       #copy general specific ensemble log
       listaf=$logfile
       mkdir -p $DIR_LOG/wrapper
       ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_${startdate} -l $DIR_LOG/wrapper -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$DIR_RCLONE/REPORTS '${listaf}'"
    fi
done
