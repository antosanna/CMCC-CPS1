#!/bin/sh -l
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -eu #vx
yyyy=$1
st=$2
# check if there is a leap february in the forecast
# IF LEAP bis=1
bis=0
endforey=`date -d "$yyyy${st}01 + $nmonfore months" +%Y`
if [ `cal 02 $endforey | awk 'NF {DAYS = $NF}; END {print DAYS}'` -eq 29 ]
then
   lastm_noleap=`date -d "$yyyy${st}01 - $nmonfore months" +%m`
   lastmfore=`date -d "$yyyy${st}01 + $nmonfore months" +%m`
   if [ $endforey -eq $yyyy ] && [ $((10#$st)) -le 2 ]
   then
      bis=1
   elif [ $endforey -gt $yyyy ] && [ $((10#$lastmfore - 1)) -ge 2 ]
   then
      bis=1
   fi
fi
# THIS IS THE RESULT!!! DO NOT DELETE
echo $bis
