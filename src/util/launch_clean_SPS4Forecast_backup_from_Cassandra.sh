#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
yyyy=`date +%Y`
st=`date +%m`
if [[ -d $DIR_ARCHIVE/Leonardo_${yyyy}${st}/ ]]
then
   rm -rf $DIR_ARCHIVE/Leonardo_${yyyy}${st}/
fi
