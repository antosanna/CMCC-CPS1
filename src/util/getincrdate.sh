#!/bin/sh -l
kind=$1 # kind of date to obtain (1 - 5)
incr=$2 # increment in hour
dateval=" "
if [[ $kind -eq 1 ]]; then # year
  dateval=`date -d "+ $incr hour" +%Y`;
elif [[ $kind -eq 2 ]]; then # month
  dateval=`date -d "+ $incr hour" +%m`;
elif [[ $kind -eq 3 ]]; then # day
  dateval=`date -d "+ $incr hour" +%d`;
elif [[ $kind -eq 4 ]]; then # hour
  dateval=`date -d "+ $incr hour" +%H`;
elif [[ $kind -eq 5 ]]; then # minutes
  dateval=`date -d "+ $incr hour" +%M`;
else
  echo "Wrong date kind parameter. Allowed is 1-5 but is $kind . Exit 1"
  exit 1
fi
echo $dateval

