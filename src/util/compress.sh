#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco

inpfile=$1
outfile=$2

$compress $inpfile $outfile

