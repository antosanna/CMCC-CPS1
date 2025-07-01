#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=$endy_hind

tstamp="00"
for st in 11
do
   for yyyy in 2015
   do
       yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
       mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
       dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
       for pp in 0
       do
          
          inputECEDA=$DATA_ECACCESS/EDA/snapshot/${tstamp}Z/ECEDA${pp}_$yyIC$mmIC${dd}_${tstamp}.grib
          if [[ ! -f ${inputECEDA} ]] 
          then
             body="$DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh: ${inputECEDA} missing!"
             echo $body
             if [[ $typeofrun == "forecast" ]]
             then
                title="[CAMIC] ${CPSSYS} ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
             fi
             continue
          fi
# check if IC was already created on Juno (up to 20240108 it could be)
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.DONE ]] 
          then
             continue
          fi
          inputNEMO4CAM=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.nc
          if [[ ! -f ${inputNEMO4CAM} ]] 
          then
             body="$DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh: ${inputNEMO4CAM} missing!"
             echo $body
             continue
          fi
          casoIC=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${dd}

#         get check_IC_CAMguess from dictionary
          set +euvx
          . $dictionary
          set -euvx
          mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
          echo "---> going to produce first guess for CAM and start date $yyyy $st"
          input="$check_IC_CAMguess $yyyy $st $pp $tstamp $inputECEDA"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
          input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
      done     #loop on EDA p
   done     #loop on start-month
done     #loop on years
