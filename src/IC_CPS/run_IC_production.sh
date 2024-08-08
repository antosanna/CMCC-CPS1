#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=$1                    # year start-date
mm=$2                    # month start-date: this is a number 
                         # not 2 digits
st=`printf '%.2d' $((10#$mm))`   # 2 digits

mkdir -p $IC_CAM_CPS_DIR/$st
mkdir -p $IC_CLM_CPS_DIR/$st
mkdir -p $IC_NEMO_CPS_DIR/$st

yyyym1=`date -d ' '$yyyy${st}01' - 1 month' +%Y`
stnemo=`date -d ' '$yyyy${st}01' - 1 month' +%m`
mmm1=$stnemo   # 2 digits

dd=`date +%d`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
#TO BE DEFINED
#eda_incomplete_check=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/EDA_incomplete_${yyyy}$st

   # inizialize flags to send informative emails   ANTO 20210319
submittedNEMO=0
###############################################################
# FIRST OF ALL IC FOR NEMO NEEDED TO COMPUTE IC CAM ON THE FORECAST DAY
###############################################################
# generate Ocean conditions 
nom_oce=0
bk_oce=0
procdate=`date +%Y%m%d-%H%M`
mkdir -p $WORKDIR_OCE
for poce in `seq -w 01 $n_ic_nemo`;do
   poce1=$((10#$poce - 1))
   nemoic=${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.${poce}.nc
   ciceic=${CPSSYS}.cice.r.$yyyy-${st}-01-00000.${poce}.nc
   dirnemoic=${IC_NEMO_CPS_DIR}/$st/
   mkdir -p $dirnemoic
   dirciceic=${IC_CICE_CPS_DIR}/$st/
#
# compute only if operational or not existing  ANTO 20210319
   if [[ ! -f $dirnemoic/$nemoic ]] || [[ ! -f $dirnemoic/$ciceic ]]
   then

      input="$yyyy $st $poce"
      $DIR_UTIL/submitcommand.sh -q s_medium -M 2500 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO

     submittedNEMO=1
     sleep 30
  fi
done

clm_err_file1=$DIR_LOG/$typeofrun/$tstamp/IC_CLM/clm_run_error_touch_GFS.$tstamp
clm_err_file2=$DIR_LOG/$typeofrun/$tstamp/IC_CLM/clm_run_error_touch_ERA5.$tstamp
if [[ -f $clm_err_file1 ]]
then
   rm $clm_err_file1
fi
if [[ -f $clm_err_file2 ]]
then
   rm $clm_err_file2
fi

#removed section idcomplete


###############################################################
# Generate ECMWF/ERA5 (perturbation 5) forced CLM run restart
# Inputfiles pushed from ECMWF machine
# INPUTDIR: /data/delivery/csp/ecaccess/ERA5/6hourly/forc4CLM
# INPUTFILES : era5_forcings_an_${yr}${mo}.grib
# FORCINGS OUTPUTDIR: $CESMDATAROOT/inputdata/atm/datm7/sps3.5_atm_forcing.datm7.ERA5.0.5d
# OUTPUTDIR: $IC_CLM_CPS_DIR
# OUTPUTFILES: land_clm45_forced_5_analisi_1993_2015.*.r.${startclm}-00000.n
#
# compute only if operational or not existing  ANTO 20210319forecast
# checkfile to confirm presence of IC 


for ilnd in {01..03}
do
   icclm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.nc
   icrtm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.nc
         
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
   # this part I would rather leave it to Marianna
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
   # if $era5_incomplete_check does not exist it means that the time-series was complete and you do not have to run it again with idcomplete=1
   if [[ ! -f $era5_incomplete_check ]] && [[ $idcomplete -eq 1 ]]
   then
         body="CLM: EDA time-series was complete. You do not have to rerun"
         title="[CLMIC] ${CPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
         
   else      #operationally or for incomplete era5 recover
         inputlnd="$yyyym1 $mmm1 $icclm $icrtm $era5_incomplete_check"
   # TO BE UPDATED
         ${DIR_UTIL}/submitcommand.sh -m $machine -S $qos -t "24" -q $serialq_l -s launch_forced_run_ERA5.sh -j launchFREC_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
         body="CLM: submitted script launch_forced_run_ERA5.sh to produce CLM ICs from ERA5"
         title="[CLMIC] ${CPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
   fi
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
   # end of part I would rather leave it to Marianna
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
done

if [[ $idcomplete -eq 1 ]]
then
  #if idcomplete=1 (i.e. recovery mode for CLM analysis) - stop here and do not enter in the computation of CAM ICs
   exit
fi



# if operational run-time (idcomplete=0) 
if [[ $idcomplete -eq 0 ]]  
then
   while `true`
   do
       #if present, remove old links to avoid using them instead of newly computed files
# WHY IT IS HERE???
#template case cm3_lndSSP5-8.5_bgc_NoSnAg_eda2_scen/
#       if [[ -L $IC_CLM_CPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc ]]
      ppland_found=0
      for ilnd in {01..03}
      do
         actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.nc
         if [[ -L $actual_ic_clm ]]
         then
            unlink $actual_ic_clm
         fi
         actual_ic_rtm=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.nc
         if [[ -L $actual_ic_rtm ]]
         then
            unlink $actual_ic_rtm
         fi
         if [[ -f $actual_ic_clm ]] && [[ -f $actual_ic_rtm ]]
         then
            ppland=$ilnd
            ppland_found=1
            break
         elif [[ $ppland_found -eq 0 ]]
         then
          # use backup
            bkup_ic_clm=$IC_CPS_guess/CLM/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.bkup.nc
            bkup_ic_rtm=$IC_CPS_guess/CLM/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.bkup.nc
#template case cm3_lndSSP5-8.5_bgc_NoSnAg_eda2_scen/
            body="Using $bkup_ic_clm and $bkup_ic_rtm. cm3_lndSSP5-8.5_bgc_NoSnAg_eda${ilnd}_scen did not complete correctly"
            title="[CLMIC] ${CPSSYS} forecast warning"
            $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
            ln -sf $bkup_ic_clm $actual_ic_clm
            ln -sf $bkup_ic_rtm $actual_ic_rtm
         fi
      done
      sleep 600
  done
fi

###############################################################
# NOW COMPUTE IC FOR CAM
# using poce=01 (unperturbed) -
###############################################################
#wait until all make_atm_ic_l83_ processes are done so that you are sure that no CAM ICs are in production
inputatm="$st $yyyy $ppland"
now_ic_cam=`ls $IC_CAM_CPS_DIR/$st/*${yyyy}$st*nc |wc -l`
mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#
# with dependency condition only if operational  ANTO 20210319
# the CAM IC production takes ~ 1 hour
while `true`
do
   np_ctr=`${DIR_UTIL}/findjobs.sh -m $machine -n nemo_rebuild_restart_${yyyy}${st}_01 -c yes`
   if [[ $np_ctr -eq 0 ]]
   then
      break
   fi
   sleep 600
done
nemoic_ctr=$dirnemoic/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.01.nc
# ma non va fatto prima??? e poi perche' e' necessario???
if [[ -L $nemoic_ctr ]]
then
   unlink $nemoic_ctr
fi
ciceic_ctr=$dirciceic/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.nc
if [[ -L $ciceic_ctr ]]
then
   unlink $ciceic_ctr
fi

if [[ ! -f $nemoic_ctr ]]
then
   bkup_nemoic_ctr=$IC_CPS_guess/NEMO/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.01.bkup.bkup.nc 
   bkup_ciceic_ctr=$IC_CPS_guess/CICE/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.bkup.nc 
   body="Using $bkup_nemoic_ctr and $bkup_ciceic_ctr as ocean/seaice ICs for atm IC production. $nemoic_ctr not produced."

   title="[NEMOIC] ${CPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   ln -sf $bkup_nemoic_ctr $nemoic_ctr
   if [[ -f $ciceic_ctr ]]
   then
      rm $ciceic_ctr
   fi
   ln -sf $bkup_ciceic_ctr $ciceic_ctr
elif [[ ! -f $ciceic_ctr ]]
then
   body="Using $bkup_nemoic_ctr and $bkup_ciceic_ctr as ocean/seaice ICs for atm IC production. $ciceic_ctr not present."
   title="[NEMOIC] ${CPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   ln -sf $bkup_ciceic_ctr $ciceic_ctr
   if [[ -f $nemoic_ctr ]]
   then
      rm $nemoic_ctr
   fi
   ln -sf $bkup_nemoic_ctr $nemoic_ctr
fi
 
${DIR_UTIL}/submitcommand.sh -m $machine -S $qos -t "24" -q $serialq_l -j CAMICs.${yyyy}${st} -d ${DIR_ATM_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -s launch_make_atm_ic_op.sh -i "$inputatm"
#
