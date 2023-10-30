#!/bin/sh -l
#BSUB -J IC_CAM
#BSUB -e /users_home/csp/as34319/CPS/CMCC-CPS1/logs/tests/IC_CAM_%J.err
#BSUB -o /users_home/csp/as34319/CPS/CMCC-CPS1/logs/tests/IC_CAM_%J.out
#BSUB -P 0490
#BSUB -M 100

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
set -euvx

debug=0
bk=1
pp=01
refcase_rest=refcaseICcam
mkdir -p $IC_CAM_CPS_DIR
if [[ $debug -eq 1 ]]
then
   tstamp=00
   st=07
   yyyy=1993
   if [[ $machine == "zeus" ]]
   then
# in running always check the absence of the global attribute DELAY_fwb
      oceic=/work/csp/$USER/restart_cps_test/MB0_00925632_restart_noglobatt.nc
      iceic=/work/csp/$USER/restart_cps_test/MB0.cice.r.1992-11-07-00000.nc
      clmic=/work/csp/$USER/restart_cps_test/cm3_cam122_cpl2000-bgc_t01.clm2.r.0020-01-01-00000.nc
      rofic=/work/csp/$USER/restart_cps_test/cm3_cam122_cpl2000-bgc_t01.hydros.r.0020-01-01-00000.nc
   elif [[ $machine == "juno" ]]
   then
      oceic=/work/csp/$USER/restart_cps_test/MB0_00925632_restart_noglobatt.nc
      iceic=/work/csp/aspect/CESM2/rea_archive/MB0/MONTHLY_RESTARTS/199209/19920930_MB0.cice.r.1992-10-01-00000.nc
      clmic=/work/csp/dp16116/CMCC-CM/archive/cm3_cam122_cpl2000-bgc_t01/rest/0020-01-01-00000/cm3_cam122_cpl2000-bgc_t01.clm2.r.0020-01-01-00000.nc
      rofic=/work/csp/dp16116/CMCC-CM/archive/cm3_cam122_cpl2000-bgc_t01/rest/0020-01-01-00000/cm3_cam122_cpl2000-bgc_t01.hydros.r.0020-01-01-00000.nc
   fi
else
# bisogna decomprimere 
   yyyy=$1
   st=$2
   oceic=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.$pp.nc
   if [[ -f $oceic.gz ]]
   then
      gunzip $oceic.gz
   fi
   if [[ ! -f $oceic ]]
   then
      title="[CAMIC] - $oceic not present"
      body="you cannot produce CAM ic for $yyyy and $st because $oceic not available"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit
   fi
   iceic=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.$pp.nc
   clmic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$pp.nc
   rofic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$pp.nc
fi

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
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

for ppeda in {0..9}
do
   ppcam=`printf '%.2d' $(($ppeda + 1))`
   ICfile=$IC_CAM_CPS_DIR/$st/${CPSSYS}.EDAcam.i.$ppcam.$yyyy$st.nc
   
   output=${CPSSYS}.EDAcam.i.${ppcam}.${yyIC}-${mmIC}-${dd}_${tstamp}.nc 
   ncdataSPS=$IC_CPS_guess/CAM/$st/$output
   caso=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${dd}
   refdir_refcase_rest=/work/$DIVISION/$USER/restart_cps_IC_CAM/$caso
   mkdir -p $refdir_refcase_rest
#NEMO
   link_oceic=${refcase_rest}_${yyIC}$mmIC${dd}_restart.nc
   ln -sf $oceic $refdir_refcase_rest/$link_oceic
#CICE
   link_iceic=$refcase_rest.cice.r.$yyIC-$mmIC-${dd}-00000.nc
   ln -sf $iceic $refdir_refcase_rest/$link_iceic
   echo $link_iceic > $refdir_refcase_rest/rpointer.cice
#CLM
   link_clmic=$refcase_rest.clm2.r.$yyIC-$mmIC-${dd}-00000.nc 
   ln -sf $clmic $refdir_refcase_rest/$link_clmic
   echo $link_clmic >$refdir_refcase_rest/rpointer.lnd
#HYDROS
   link_rofic=$refcase_rest.hydros.r.$yyIC-$mmIC-${dd}-00000.nc
   ln -sf $rofic $refdir_refcase_rest/$link_rofic
   echo $link_rofic >$refdir_refcase_rest/rpointer.hydros
#SET TIMESTEP
   ncpl=192
   input="$yyIC $mmIC $dd $ppcam $caso $ncpl $bk $ncdataSPS $ICfile $refdir_refcase_rest $refcase_rest $yyyy $st"
   mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
   ${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -d ${DIR_ATM_IC} -s ${CPSSYS}_IC4CAM.sh -i "$input"
done
