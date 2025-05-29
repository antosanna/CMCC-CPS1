#!/bin/sh -l
# HOW TO SUBMIT 
#yyyy=2024;st=04;input="$yyyy $st";${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d $IC_CPS -s run_IC_production_test.sh -i "$input" 
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=2025                    # year start-date
mm=5                    # month start-date: this is a number 
                         # not 2 digits
st=`printf '%.2d' $((10#$mm))`   # 2 digits



mkdir -p $IC_CAM_CPS_DIR/$st
mkdir -p $IC_CLM_CPS_DIR/$st
mkdir -p $IC_NEMO_CPS_DIR/$st

yyyym1=`date -d ' '$yyyy${st}01' - 1 month' +%Y`
stnemo=`date -d ' '$yyyy${st}01' - 1 month' +%m`
mmm1=$stnemo   # 2 digits

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
#TO BE DEFINED

   # inizialize flags to send informative emails   ANTO 20210319
###############################################################
# FIRST OF ALL IC FOR NEMO NEEDED TO COMPUTE IC CAM ON THE FORECAST DAY
###############################################################
# generate Ocean conditions 
procdate=`date +%Y%m%d-%H%M`


ppland=01
   
###############################################################
# NOW COMPUTE IC FOR CAM
# using poce=01 (unperturbed) -
###############################################################
#wait until all make_atm_ic_l83_ processes are done so that you are sure that no CAM ICs are in production
# with dependency condition only if operational  ANTO 20210319
# the CAM IC production takes ~ 1 hour
dirnemoic=${IC_NEMO_CPS_DIR}/$st/
nemoic_ctr=$dirnemoic/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.01.nc
# ma non va fatto prima??? e poi perche' e' necessario???
dirciceic=${IC_CICE_CPS_DIR}/$st/
ciceic_ctr=$dirciceic/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.nc

if [[ ! -f $nemoic_ctr ]] || [[ ! -f $ciceic_ctr ]]
then
   exit
fi

mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#
#${DIR_UTIL}/submitcommand.sh -m $machine -S $qos -t "24" -q $serialq_l -j CAMICs.${yyyy}${st} -d ${DIR_ATM_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -s launch_make_atm_ic_op.sh -i "$inputatm"
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
last_dd_mmIC=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC month last day
#dd=$(($last_dd_mmIC - 1))
dd=$last_dd_mmIC
t_analysis=00
n_submitted=0
for pp in {0..9}
do

    ppcam=`printf '%.2d' $(($pp + 1))`

    inputECEDA=$DATA_ECACCESS/EDA/snapshot/${t_analysis}Z/ECEDA${pp}_$yyIC$mmIC${dd}_${t_analysis}.grib
    casoIC=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${dd}

    if [[ ! -f ${inputECEDA} ]]
    then
       body="$IC_CPS/run_IC_production.sh: ${inputECEDA} missing!"
       echo $body
       title="[CAMIC] ${CPSSYS} ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
       continue
    fi

#         get check_IC_CAMguess from dictionary
    set +euvx
    . $dictionary
    set -euvx
    mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
    echo "---> going to produce first guess for CAM and start date $yyyy $st"
    input="$yyyy $st $pp $t_analysis $inputECEDA $dd"
    ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j makeICsGuess4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83.sh -i "$input"
    sleep 60
    input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC $ppland"
    ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p makeICsGuess4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic.sh -i "$input"
#
    n_submitted=$(($n_submitted + 1))
    if [[ $(($n_submitted % 2)) -eq 0 ]]
    then
       while `true`
       do
          n_ic_done=`ls $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.??.nc |wc -l`
          if [[ $n_ic_done -eq $n_submitted ]]
          then
             break
          fi
          sleep 60
       done
    fi
done     #loop on pp

$IC_CPS/set_forecast_ICs.sh $yyyy $st
