#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$2" -t "$1"
