#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
# load variables from descriptor

set -vxue

# Input ----------------------------------------------
members_nr=$nrunmax

file1=${SPSSystem}_${typeofrun}_IC_CAM_list.${machine}.csv

mkdir -p $DIR_CHECK
cd $DIR_CHECK

#if [[ $machine == "zeus" ]] ; then
#   inist=02
#elif [[ $machine == "juno" ]] ; then
   inist=01
#fi
# Write header ---------------------------------------
echo "start-date,IC1,IC2,IC3,IC4,IC5,IC6,IC7,IC8,IC9,IC10" > $file1
# Write body -----------------------------------------
#for st in `seq -w $inist 2 12`
for st in `seq -w $inist 1 12`
do
   for yyyy in `seq $iniy_hind $endy_hind`
   do
         # write body
         echo "$yyyy$st,--,--,--,--,--,--,--,--,--,--" >> $file1
         
   done
done

echo "Done $0"

exit 0
