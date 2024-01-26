#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -ux

job_run=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_ -a $BATCHRUN -c yes`
job_pen=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_ -a $BATCHPEND -c yes`

if [[ $job_run -lt $maxnumberguarantee ]] 
then
   if [[ `date +%A` == "Thursday" ]] && [[ `date +%h` -lt 11 ]] && [[ `date +%h` -gt 4 ]]
   then
      echo "On Thursday `date` jobs running $job_run instead of $maxnumberguarantee"
      exit
   else
      echo "`date` Jobs running $job_run instead of $maxnumberguarantee"
      title="[SPS4 HINDCASTS] $machine WARNING!!! less then expected jobs"
      body="Found $job_run job running instead of the expected $maxnumberguarantee \n
 and $job_pen job pending \n
   \n
      Please check if there is anything wrong \n
\n"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   fi
fi
exit 0

