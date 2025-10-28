#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -eu
n_queued=`$DIR_UTIL/findjobs.sh -m $machine -n run.sps4 -N RUN -c yes`
title="WARNING CERISE ON $machine: less than expected jobs running!!!"
body="$n_queued instead of $maxnumbertosubmit queued! check what is going wrong"
if [[ $n_queued -lt 1 ]]
then
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
fi
