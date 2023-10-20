#!/bin/sh -l
# ACHTUNG!!!!!
# POTREBBE ESSERE MACHINE DEP IL grep
#
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
LOG_FILE=$DIR_CASES/CASO/logs/change_timestep.CASO.log
exec 3>&1 1>${LOG_FILE} 2>&1
cam_guess=0       # if this is  a SPS3.5 forecast
cd $DIR_CASES/CASO/
totcores=`./xmlquery TOTALPES | cut -d '=' -f2`
pes_per_node=`./xmlquery PES_PER_NODE | cut -d '=' -f2`
./xmlchange -file env_run.xml -id ATM_NCPL -val 384
#${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -f yes -n $totcores -R ${pes_per_node} -j CASO_run -l $DIR_CASES/CASO/logs/ -d $DIR_CASES/CASO -s CASO.run
./case.submit
exit

# check if still needed in SPS4
if [ $cam_guess -eq 1 ]
then
   command="`grep done logdir/CASO*err|tail -2|head -3|tail -1|cut -d ' ' -f2-`"
   eval $command 
fi
