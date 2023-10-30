#!/bin/sh -l
#BSUB -J EDA2CAM
#BSUB -e /work/csp/as34319/scratch/interp/logs/EDA2CAM_%J.err
#BSUB -o /work/csp/as34319/scratch/interp/logs/EDA2CAM_%J.out
#BSUB -P 0490

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
. ${DIR_UTIL}/descr_ensemble.sh
set -euvx

debug=1
bk=1
if [[ $debug -eq 1 ]]
then
#   IC_SPS_guess=/work/$DIVISION/$USER/scratch/ICs4tests/
   IC_CAM_SPS_DIR=$IC_SPS_guess/CAM/
   mkdir -p $IC_CAM_SPS_DIR
   tstamp=00
   st=11
   yyyy=1960
   ppland=4
   ICfile=$IC_CAM_SPS_DIR/$st/${SPSSYS}.EDAcam.i.$yyyy$st
   bkoce=${IC_SPS_guess}/NEMO/$st/NEMO-CICE_70_00777672_restart_0*nc
   bkice=${IC_SPS_guess}/NEMO/$st/NEMO-CICE_70.cice.r.1984-11-09-00000.nc
   bkclm=${IC_SPS_guess}/CLM/$st/cm3_lndHIST_t01b.clm2.r.2015-01-01-00000.nc
   bkrtm=${IC_SPS_guess}/CLM/$st/cm3_lndHIST_t01b.hydros.r.2015-01-01-00000.nc
fi

mkdir -p $IC_CAM_SPS_DIR/$st/
startdate=$yyyy${st}01
#
# export vars needed by ncl script
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month; this is not a number (2 digits)
dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
#for ppeda in {0..9}
for ppeda in {0..0}
do
   pp=$(($ppeda + 1))
   
   output=${SPSSYS}.EDAcam.i.${pp}.${yyIC}-${mmIC}-${dd}_${tstamp}.nc 
   ncdataSPS=$IC_SPS_guess/CAM/$st/$output
   caso=${SPSsystem}_EDACAM_IC${pp}.${yyIC}${mmIC}${dd}
   ncpl=192
   input="$yyIC $mmIC $dd $pp $ppland $caso $ncpl $bk $ncdataSPS $ICfile $bkoce $bkice $bkclm $bkrtm"
   mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#   ${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/forecast/$yyyy$st/IC_CAM -d ${DIR_ATM_IC} -s ${SPSSYS}_IC4CAM_hindcast.sh -i "$input"
# al momento e' un test tecnico e uso come reefcase il 2000 perpetuo
   ${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -d ${DIR_ATM_IC} -s ${SPSSYS}_IC4CAM_test_with2000_refcase.sh -i "$input"
done
