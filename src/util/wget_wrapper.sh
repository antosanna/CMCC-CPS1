#!/bin/sh -l
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#. $HOME/.bashrc
#. ${DIR_UTIL}/descr_CPS.sh

set -euxv
outdir=$1
url="$2"

cd $outdir
wget -4 --no-check-certificate $url
