#!/bin/sh -l
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
outdir_gdrive=$1
listoffiles="$2"

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
rclone mkdir my_drive:$outdir_gdrive
for ff in $listoffiles
do
   rclone copy $ff my_drive:$outdir_gdrive
done
