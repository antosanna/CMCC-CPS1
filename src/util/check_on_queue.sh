#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -eu
n_queued=`$DIR_UTIL/findjobs.sh -m $machine -n run.sps4 -c yes`
title="WARNING CERISE ON $machine!!!"
body="Less than $maxnumbertosubmit queued! check what is going wrong"
if [[ $n_queued -lt $maxnumbertosubmit ]]
then
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
fi
