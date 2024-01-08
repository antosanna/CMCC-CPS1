#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_ -a $BATCHRUN -c yes`
job_pen=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_ -a $BATCHPEND -c yes`

if [[ $job_run -lt $maxnumberguarantee ]]
then
   title="[SPS4 HINDCASTS] $machine WARNING!!! less then expected jobs"
   body="Found $job_run job running instead of the expected $maxnumberguarantee \n
 and $job_pen job pending \n
   \n
   Please check if there is anything wrong \n
\n"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
fi
exit 0

