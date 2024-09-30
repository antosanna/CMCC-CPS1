#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 2020  #whatever year of scenario
set -euvx
mkdir -p $DIR_LOG/IC_CAM

tstamp="00"
st=$1
yyyy=$2
ppland=$3
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
for pp in {0..9}
do

# check if IC was already created 
   ppcam=`printf '%.2d' $(($pp + 1))`
   if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.DONE ]]
   then
      continue
   fi

   inputECEDA=$DATA_ECACCESS/EDA/snapshot/${tstamp}Z/ECEDA${pp}_$yyIC$mmIC${dd}_${tstamp}.grib
   casoIC=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${dd}
   if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]]
   then
# this must be put to the end
      if [[ -d $DIR_CASES/$casoIC ]]
      then
         rm -rf $DIR_CASES/$casoIC
      fi
      if [[ -d $DIR_ARCHIVE/$casoIC ]]
      then
         rm -rf $DIR_ARCHIVE/$casoIC
      fi
      if [[ -d $WORK_CPS/$casoIC ]]
      then
         rm -rf $WORK_CPS/$casoIC
      fi
  fi
# end of part to be moved

  if [[ ! -f ${inputECEDA} ]] 
  then
     body="$DIR_ATM_IC/launch_make_atm_ic_op.sh: ${inputECEDA} missing!"
     title="[CAMIC] ${CPSSYS} ERROR"
     ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
  fi
  inputNEMO4CAM=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.nc

#         get check_IC_CAMguess from dictionary
		set +euvx
		. $dictionary
		set -euvx
		mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
		echo "---> going to produce first guess for CAM and start date $yyyy $st"
		#input="$check_IC_CAMguess $yyyy $st $pp $tstamp $inputECEDA"
		input="$yyyy $st $pp $tstamp $inputECEDA"
		${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83.sh -i "$input"
  input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC"
  ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic.sh -i "$input"
done     #loop on perturbations
