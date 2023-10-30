#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh

set -euvx
if [[ $machine -ne "zeus" ]]
then
   echo "you cannot run this script if not on Zeus because EDA data are downloaded only on Zeus"
   exit
fi
debug=1
iniy=1993
endy=2022
for st in 07 08 09 11 05 02 08 12 01 03 04 06 07 09 10
do
   for yyyy in `seq $iniy $endy`
   do
       .  $DIR_UTIL/descr_ensemble.sh $yyyy
       checkfile=$IC_CPS_guess/CAM/$st/$yyyy${st}_done
       if [[ -f $checkfile ]]
       then
          continue
       fi
       mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
       echo "---> going to produce first guess for CAM and start date $yyyy $st"
       input="$checkfile $yyyy $st"
       ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
       if [[ $debug -eq 1 ]]
       then
          exit
       fi
   done
done
