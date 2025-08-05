#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

$HOME/.local/bin/aws s3 sync $DIR_WEB  s3://sps-files.cmcc.it/ --delete
exit 0
