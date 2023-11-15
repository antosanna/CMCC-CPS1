#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -vxeu

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
else
   yyyy=$1
   st=$2
fi
outdir=${DIR_LOG}/$typeofrun/$startdate

# ----------------------------------------------------------------
#  Quota
# ----------------------------------------------------------------
# 
fname=$outdir/${CPSSYS}_quota_${startdate}.log
cat /dev/null >> $fname
echo "date is `date`" >> $fname
echo "Filesystem Size  Used  Avail Use%" >> $fname
gpfsrepquota -f /work/csp | grep $operational_user >> $fname
gpfsrepquota -f /data/csp | grep $operational_user >> $fname

echo "$0 Done"
exit 0

