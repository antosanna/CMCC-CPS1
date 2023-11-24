#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -eu

if [[ $1 == "" ]]
then
# !!! To run only from crontab !!!
   CRON=$(pstree -s $$ | grep -q cron && echo true || echo false)
   if $CRON
   then
       echo "Being run by cron"
   else
       echo "This script must be excecuted by cron. It works with a precise scheduling (1hr). From this depend other reporting remote processes. Exit"
       exit 0
   fi

# -------------------------------------------------------------------------
# --------------------------------------------------------------------------
   startdate=`date +%Y%m`
   . $DIR_UTIL/descr_ensemble.sh `date +%Y`
elif [[ $# -eq 2 ]]
then
   yyyy=$1
   st=$2
   typeofrun="forecast"
elif [[ $# -eq 1 ]]
then
   st=$1
   typeofrun="hindcast"
fi
outdir=${DIR_LOG}/$typeofrun/

# ----------------------------------------------------------------
#  Quota
# ----------------------------------------------------------------
# 
if [[ $typeofrun == "forecast" ]]
then
   fname=$outdir/${CPSSYS}_quota_${yyyy}$st.`date +%Y%m%d%M`.log
else
   fname=$outdir/${CPSSYS}_quota.`date +%Y%m%d%M`.log
fi
cat /dev/null >> $fname
echo "date is `date`" >> $fname
echo "Filesystem Size  Used  Avail Use%" >> $fname
gpfsrepquota -f /work/csp | grep $operational_user >> $fname
gpfsrepquota -f /data/csp | grep $operational_user >> $fname

echo "$0 Done with output in $fname"
exit 0

