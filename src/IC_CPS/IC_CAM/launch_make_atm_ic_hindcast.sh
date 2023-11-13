#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh

set -euvx
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=1993
endy=2022
debug=1
for st in 08 10 12 02 04 06 
do
   for yyyy in `seq $iniy $endy`
   do
       .  $DIR_UTIL/descr_ensemble.sh $yyyy
       for pp in {0..9}
       do
          checkfile=$IC_CPS_guess/CAM/$st/$yyyy${st}_${pp}_done
#          if [[ ! -f $checkfile ]]
#          then
             mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
             echo "---> going to produce first guess for CAM and start date $yyyy $st"
             input="$checkfile $yyyy $st $pp"
             ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
             input="$yyyy $st $pp"
             ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
#          fi
          if [[ $debug -eq 1 ]]
          then
             exit
          fi
       done     #loop on pp
   done     #loop on start-month
done     #loop on years
