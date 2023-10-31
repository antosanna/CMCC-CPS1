#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

function write_help
{
  echo ""
  echo "Use: launch_recover.sh <script_to_launch> <yyyy optional (now set for hindcast)>"
  echo ""
  echo "     You should modify conveniently the script_to_launch before!"
  echo ""
}
if [[ "$1" == "-h" ]] ; then
    write_help
    exit 1
else
   script_to_launch=$1
fi
yyyy=${2:-1993}    #assumes default is hindcast
#
. $DIR_UTIL/descr_ensemble.sh $yyyy
#
set -euvx
mkdir -p ${DIR_LOG}/$typeofrun/recover
${DIR_UTIL}/submitcommand.sh -m $machine -M 10000 -q $serialq_s -j ${script_to_launch}_`date +%Y%m%d%M` -l ${DIR_LOG}/$typeofrun/recover -d $DIR_RECOVER -s $script_to_launch 
