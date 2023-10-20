#!/bin/sh -l
#BSUB -J IC_CAM
#BSUB -e /users_home/csp/cp1/CPS/CMCC-CPS1/logs/tests/IC_CAM_%J.err
#BSUB -o /users_home/csp/cp1/CPS/CMCC-CPS1/logs/tests/IC_CAM_%J.out
#BSUB -P 0490
#BSUB -M 100

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
pp=01
refcase_rest=refcaseICcam
mkdir -p $IC_CAM_CPS_DIR
if [[ $debug -eq 1 ]]
then
   tstamp=00
   st=11
   yyyy=1993
   oceic=/work/csp/as34319/restart_cps_test/restart.nc
# in running will be always control
   iceic=/work/csp/as34319/restart_cps_test/cm3_cam122_cpl2000-bgc_t01.clm2.r.0020-01-01-00000.nc
   clmic=/work/csp/as34319/restart_cps_test/cm3_cam122_cpl2000-bgc_t01.cice.r.0020-01-01-00000.nc
   rtmic=/work/csp/as34319/restart_cps_test/cm3_cam122_cpl2000-bgc_t01.hydros.r.0020-01-01-00000.nc
else
# bisogna decomprimere 
  :
fi

mkdir -p $IC_CAM_CPS_DIR/$st/
startdate=$yyyy${st}01
#
# export vars needed by ncl script
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month; this is not a number (2 digits)
dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # last day of month previous to $st
if [[ $dd -eq 29 ]]
then
   dd=28
fi

for ppeda in {0..0}
do
   pp=`printf '%.2d' $(($ppeda + 1))`
   ICfile=$IC_CAM_CPS_DIR/$st/${CPSSYS}.EDAcam.i.$pp.$yyyy$st.nc
   
   output=${CPSSYS}.EDAcam.i.${pp}.${yyIC}-${mmIC}-${dd}_${tstamp}.nc 
   ncdataSPS=$IC_CPS_guess/CAM/$st/$output
#   caso=${CPSSystem}_EDACAM_IC${pp}.${yyIC}${mmIC}${dd}
#ONLY FORE TEST
   caso=test_EDACAM_IC$(($pp + 3)).${yyIC}${mmIC}${dd}
   refdir_refcase_rest=/work/$DIVISION/$USER/restart_cps_IC_CAM/$caso
   mkdir -p $refdir_refcase_rest
# COMPULSORY!!!! restart file of Nemo must be named simply restart.nc
   actual_oceic=restart.nc
   ln -sf $oceic $refdir_refcase_rest/$actual_oceic
# CICE
   actual_iceic=$refcase_rest.cice.r.$yyIC-$mmIC-${dd}-00000.nc
   ln -sf $iceic $refdir_refcase_rest/$actual_iceic
   echo $actual_iceic > $refdir_refcase_rest/rpointer.cice
#CLM
   actual_clmic=$refcase_rest.clm2.r.$yyIC-$mmIC-${dd}-00000.nc 
   ln -sf $clmic $refdir_refcase_rest/$actual_clmic
   echo $actual_clmic >$refdir_refcase_rest/rpointer.lnd
#HYDROS
   actual_rtmic=$refcase_rest.hydros.r.$yyIC-$mmIC-${dd}-00000.nc
   ln -sf $rtmic $refdir_refcase_rest/$actual_rtmic
   echo $actual_rtmic >$refdir_refcase_rest/rpointer.hydros
#SET TIMESTEP
   ncpl=192
   input="$yyIC $mmIC $dd $pp $caso $ncpl $bk $ncdataSPS $ICfile $refdir_refcase_rest $refcase_rest $yyyy $st"
   mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
   ${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -d ${DIR_ATM_IC} -s ${CPSSYS}_IC4CAM.sh -i "$input"
done
