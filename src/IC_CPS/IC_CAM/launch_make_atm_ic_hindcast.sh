#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh

set -euvx
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=1999
debugp=1   # if 1 do only one and exit
debugy=1   # if 1 do only one year
for st in 08 #10 12 02 04 06 
do
   for yyyy in `seq $iniy $endy`
   do
       .  $DIR_UTIL/descr_ensemble.sh $yyyy
       for pp in {0..9}
       do
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]]
          then
             continue
          fi
          checkfile=$IC_CPS_guess/CAM/$st/$yyyy${st}_${ppcam}_done
          mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
          wkdir_regrid=$SCRATCHDIR/EDA2CAM_regrid/$yyyy${st}_${ppcam}/
          mkdir -p ${wkdir_regrid}
          echo "---> going to produce first guess for CAM and start date $yyyy $st"
          sed -e "s@PPEDA@$pp@g;s@YYYY@$yyyy@g;s@ST@$st@g;s@CHECKFILE@$checkfile@g" $DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast_template.sh > ${wkdir_regrid}/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast_${yyyy}${st}_${ppcam}.sh
          chmod u+x ${wkdir_regrid}/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast_${yyyy}${st}_${ppcam}.sh
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${ppcam} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d ${wkdir_regrid} -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast_${yyyy}${st}_${ppcam}.sh
          input="$yyyy $st $pp"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${ppcam} -j make_atm_ic_${yyyy}${st}_${ppcam} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
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
