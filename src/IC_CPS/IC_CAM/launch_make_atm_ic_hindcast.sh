#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh

set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=1997
debugp=1   # if 1 do only one and exit
debugy=1   # if 1 do only one year
for st in 11 #10 12 02 04 06 
do
   for yyyy in `seq $iniy $endy`
   do
       .  $DIR_UTIL/descr_ensemble.sh $yyyy
       for pp in {1..9}
       do
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]]
          then
             continue
          fi
          checkfile=$IC_CPS_guess/CAM/$st/$yyyy${st}_${ppcam}_done
          mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
          echo "---> going to produce first guess for CAM and start date $yyyy $st"
          input="$checkfile $yyyy $st $pp"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
          input="$yyyy $st $pp"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
          sleep 10
          if [[ $debugp -eq 1 ]]
          then
             exit
          fi
       done     #loop on pp
       if [[ $debugy -eq 1 ]]
       then
          exit
       fi
   done     #loop on start-month
done     #loop on years
