#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
cd $DIR_CASES
list=`ls sps4_199*/*done`
for ff in $list
do
   caso=`dirname $ff`
   cp -p $ff $DIR_CASES/$caso/logs
done
