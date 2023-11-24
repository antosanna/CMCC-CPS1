#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
# load variables from descriptor

set -vxue

# Input ----------------------------------------------
members_nr=$nrunmax

file1=${SPSSystem}_${typeofrun}_IC_NEMO_list.$machine.csv

mkdir -p $DIR_CHECK
cd $DIR_CHECK


# Write header ---------------------------------------
echo "start-date,IC1,IC2,IC3,IC4" > $file1
# Write body -----------------------------------------
if [[ $machine == "zeus" ]]
then
   inist=02
   freq=2
elif [[ $machine == "juno" ]]
then
   inist=01
   freq=1
fi
for st in `seq $inist $freq 12`
do
   for yyyy in `seq $iniy_hind $endy_hind`
   do
         # write body
         echo "$yyyy$st,--,--,--,--" >> $file1
         
   done
done

echo "Done $0"

exit 0
