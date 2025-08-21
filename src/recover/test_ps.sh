#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993

set -e #vx

# check if there is another job submitted by crontab with the same name
if [[ $machine == "leonardo" ]]
then
   conda activate $envcondacm3
#   LOG_FILE=$DIR_LOG/hindcast/SPS4_submission_hindcast.`date +%Y%m%d%H%M`.log
#   exec 3>&1 1>>${LOG_FILE} 2>&1

  cnt_this_script_running=$(ps cax -u ${operational_user} -f |grep test_ps |wc -l)
# cax exclude grep from counting
   echo $cnt_this_script_running
   if [[ $cnt_this_script_running -gt 2 ]]
   then
      echo "already running"
      exit
   fi
fi
