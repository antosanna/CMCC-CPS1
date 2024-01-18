#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
cnt_this_script_running=$(ps -u ${operational_user} -f |grep copy_SPS4DMO_from_Zeus.sh| grep -v $$|wc -l)
echo $cnt_this_script_running

if [[ $cnt_this_script_running -gt 2 ]]
then
   echo "already running"
   exit
fi
echo "not skipping just one"
sleep 300 
