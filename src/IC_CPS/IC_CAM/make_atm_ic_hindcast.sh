#!/bin/sh -l

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
set -euvx

debug=0
refcase_rest=refcaseICcam
tstamp=00
mkdir -p $IC_CAM_CPS_DIR
if [[ $debug -eq 1 ]]
then
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
   ppeda=$3
   yyIC=$4  # IC year
   mmIC=$5   # IC month; this is not a number (2 digits)
   dd=$6    # last day of month previous to $st
   caso=$7   #casoIC in launcher
   oceic=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.nc
   iceic=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.01.nc
   clmic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.01.nc
   rofic=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.01.nc

   if [[ -f $oceic.gz ]]
   then
      gunzip $oceic.gz
   fi
   if [[ ! -f $oceic ]]
   then
      title="[CAMIC] - $oceic not present"
      body="you cannot produce CAM ic for $yyyy and $st because $oceic not available"
      echo $body
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit
   fi
   if [[ -f $clmic.gz ]] 
   then
      gunzip $clmic.gz
   fi
   if [[ ! -f $clmic ]]
   then
      title="[CAMIC] - $clmic not present"
      body="you cannot produce CAM ic for $yyyy and $st because $clmic not available"
      echo $body
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit
   fi 
   if [[ -f $rofic.gz ]]  
   then
      gunzip $rofic.gz
   fi  
   if [[ ! -f $rofic ]]
   then
      title="[CAMIC] - $rofic not present"
      body="you cannot produce CAM ic for $yyyy and $st because $rofic not available"
      echo $body
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit
   fi
   if [[ -f $iceic.gz ]]  
   then
      gunzip $iceic.gz
   fi  
   if [[ ! -f $iceic ]] 
   then
      title="[CAMIC] - $iceic not present"
      body="you cannot produce CAM ic for $yyyy and $st because $iceic not available"
      echo $body
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st
      exit
   fi


fi

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
mkdir -p $IC_CAM_CPS_DIR/$st/
startdate=$yyyy${st}01
#

ppcam=`printf '%.2d' $(($ppeda + 1))`
ICfile=$IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc

output=${CPSSYS}.EDAcam.i.${ppcam}.${yyIC}-${mmIC}-${dd}_${tstamp}.nc 
ncdataSPS=$IC_CPS_guess/CAM/$st/$output
refdir_refcase_rest=$DIR_REST_INI/$caso

#to avoid ambiguities due to old submission
if [[ -d ${refdir_refcase_rest} ]] ; then
   rm -rf ${refdir_refcase_rest}
fi

mkdir -p $refdir_refcase_rest

diff=`${DIR_UTIL}/datediff.sh $startdate $yyIC$mmIC$dd`
#!!!!!!
#remove 29 for leap years but diff must be computed on the real calendar 
#to cmpute the effective difference
#dd from now on is the model calendar (no-leap)
#!!!!!!
if [[ $mmIC == "02" ]] && [[ $dd == "29" ]] ; then
   dd="28"
fi

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
input="$yyIC $mmIC $dd $ppcam $caso $ncpl $ncdataSPS $ICfile $refdir_refcase_rest $refcase_rest $yyyy $st $diff"
mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "1" -q $serialq_s -j ${caso}_launch -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -d ${DIR_ATM_IC} -s ${CPSSYS}_IC4CAM.sh -i "$input"
exit
