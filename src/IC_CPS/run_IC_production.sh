#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
debug=0   #does not produce forcings and uses operational ICs
if [[ `whoami` == $operational_user ]]
then
   debug=0
fi

yyyy=$1                    # year start-date
mm=$2                    # month start-date: this is a number 
                         # not 2 digits
idcomplete=${3:-0}       #1=true month complete
st=`printf '%.2d' $((10#$mm))`   # 2 digits

mkdir -p $IC_CAM_SPS_DIR/$st
mkdir -p $IC_CLM_SPS_DIR/$st
mkdir -p $IC_NEMO_SPS_DIR/$st

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

if [[ $idcomplete -eq 0 ]]    # operational case run-time
then
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
      dirnemoic=${IC_NEMO_SPS_DIR1}/$st/
      mkdir -p $dirnemoic
      dirciceic=${IC_CICE_SPS_DIR1}/$st/
   #
   # compute only if operational or not existing  ANTO 20210319
      if [[ $debug -eq 0 ]] || [[ ! -f $dirnemoic/$nemoic ]] || [[ ! -f $dirnemoic/$ciceic ]]
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
fi  #end if on idcomplete!


##start from here if idcomplete=1 (recover case) 

###############################################################
# Generate ECMWF/ERA5 (perturbation 5) forced CLM run restart
# Inputfiles pushed from ECMWF machine
# INPUTDIR: /data/delivery/csp/ecaccess/ERA5/6hourly/forc4CLM
# INPUTFILES : era5_forcings_an_${yr}${mo}.grib
# FORCINGS OUTPUTDIR: $CESMDATAROOT/inputdata/atm/datm7/sps3.5_atm_forcing.datm7.ERA5.0.5d
# OUTPUTDIR: $IC_CLM_SPS_DIR
# OUTPUTFILES: land_clm45_forced_5_analisi_1993_2015.*.r.${startclm}-00000.n
#
# compute only if operational or not existing  ANTO 20210319forecast
# checkfile to confirm presence of IC 


for ilnd in {01..03}
do
   icclm=$IC_CLM_SPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.nc
   icrtm=$IC_CLM_SPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.nc
   if [[ $debug -eq 1 ]] 
   then
      icclm=$IC_CLM_SPS_DIR1/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.nc
      icrtm=$IC_CLM_SPS_DIR1/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.nc
   fi
   
   #debug=0 -> operational: you always compute for savety
   #debug=1 -> test: you compute only if file does not exist
         
   if [[ $debug -eq 0 ]] 
   then
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
   # this part I would rather leave it to Marianna
#!!!!!!!!!!!!!!!!!!!!!!!!!!!
   # if $era5_incomplete_check does not exist it means that the time-series was complete and you do not have to run it again with idcomplete=1
      if [[ ! -f $era5_incomplete_check ]] && [[ $idcomplete -eq 1 ]]
      then
         body="CLM: EDA time-series was complete. You do not have to rerun"
         title="[CLMIC] ${SPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r yes -s $yyyy$st
         
      else      #operationally or for incomplete era5 recover
         inputlnd="$yyyym1 $mmm1 $icclm $icrtm $era5_incomplete_check"
   # TO BE UPDATED
         ${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "24" -q $serialq_l -s launch_forced_run_ERA5.sh -j launchFREC_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
         body="CLM: submitted script launch_forced_run_ERA5.sh to produce CLM ICs from ERA5"
         title="[CLMIC] ${SPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r yes -s $yyyy$st
      fi
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



###############################################################
# NOW COMPUTE IC FOR CAM
# using poce=01 (unperturbed) -
UP TO HERE
###############################################################
#wait until all make_atm_ic_l46_ processes are done so that you are sure that no CAM ICs are in production
# if operational run-time (idcomplete=0) 
if [[ $idcomplete -eq 0 ]]  
then
   while `true`
   do
       #if present, remove old links to avoid using them instead of newly computed files
       if [[ -L $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc ]]
       then
          unlink $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc 
       fi
       if [[ -L $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc ]]
       then
          unlink $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc
       fi
       if [[ -L $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc ]]
       then
          unlink $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc 
       fi
       if [[ -L $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc ]]
       then
          unlink $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc
       fi
       if [[ -f $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.nc ]] && [[ -f $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.nc ]] 
       then
          ppland=5
          break
       elif [[ -f $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.nc ]] && [[ -f $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.nc ]]
       then
          ppland=4
          break
       elif [[ -f $clm_err_file2 ]]
       then
          body="Using $IC_SPS_guess/CLM/$st/land_clm45_forced_5.clm2.r.${yyyy}-${st}-01-00000.bkup.nc as ECMWF forced IC. ${SPSsystem}_land_clm45_forced_ERA5_RCP85 did not complete correctly"
          title="[CLMIC] ${SPSSYS} forecast warning"
          $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
          # use backup
          ln -sf $IC_SPS_guess/CLM/$st/land_clm45_forced_5.clm2.r.${yyyy}-${st}-01-00000.bkup.nc $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc
          ln -sf $IC_SPS_guess/CLM/$st/land_clm45_forced_5.rtm.r.${yyyy}-${st}-01-00000.bkup.nc $IC_CLM_SPS_DIR/$st/land_clm45_forced_5_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc
          ppland=5
          break
       elif [[ -f $clm_err_file1 ]]
       then
          body="Using $IC_SPS_guess/CLM/$st/land_clm45_forced_4.clm2.r.${yyyy}-${st}-01-00000.bkup.nc as GFS forced IC. ${SPSsystem}_land_clm45_forced_GFS_RCP85 did not complete correctly"
          title="[CLMIC] ${SPSSYS} forecast warning"
          $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
          # use backup
          ln -sf $IC_SPS_guess/CLM/$st/land_clm45_forced_4.clm2.r.${yyyy}-${st}-01-00000.bkup.nc $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.clm2.r.${yyyy}-${st}-01-00000.nc
          ln -sf $IC_SPS_guess/CLM/$st/land_clm45_forced_4.rtm.r.${yyyy}-${st}-01-00000.bkup.nc $IC_CLM_SPS_DIR/$st/land_clm45_forced_4_analisi_1993_2015.rtm.r.${yyyy}-${st}-01-00000.nc
          ppland=4
          break
       fi
       sleep 600
  done
fi

inputatm="$st $yyyy $ppland"
now_ic_cam=`ls $IC_CAM_SPS_DIR/$st/*${yyyy}$st*nc |wc -l`
mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#
# with dependency condition only if operational  ANTO 20210319
# the CAM IC production takes ~ 1 hour
while `true`
do
   np9=`${DIR_UTIL}/findjobs.sh -m $machine -n NEMOICs.${yyyy}${st}_09 -c yes`
   if [[ $np9 -eq 0 ]]
   then
      break
   fi
   sleep 600
done
if [[ -L $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc ]]
then
   unlink $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc 
fi
if [[ -L $dirnemoic/ice_ic$yyyy${st}_09.nc ]]
then
   unlink $dirnemoic/ice_ic$yyyy${st}_09.nc
fi

if [[ ! -f $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc ]] 
then
   body="Using $IC_SPS_guess/NEMO/$st/${yyyy}${st}0100_R025_09_restart_oce_modified.bkup.nc and $IC_SPS_guess/NEMO/$st/ice_ic$yyyy${st}_09.bkup.nc as ocean/seaice ICs for atm IC production. $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc not present."
   title="[NEMOIC] ${SPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   ln -sf $IC_SPS_guess/NEMO/$st/${yyyy}${st}0100_R025_09_restart_oce_modified.bkup.nc $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc
   if [[ -f $dirnemoic/ice_ic$yyyy${st}_09.nc ]]
   then
      rm $dirnemoic/ice_ic$yyyy${st}_09.nc
   fi
   ln -sf $IC_SPS_guess/NEMO/$st/ice_ic$yyyy${st}_09.bkup.nc $dirnemoic/ice_ic$yyyy${st}_09.nc
elif [[ ! -f $dirnemoic/ice_ic$yyyy${st}_09.nc ]]
then
   body="Using $IC_SPS_guess/NEMO/$st/${yyyy}${st}0100_R025_09_restart_oce_modified.bkup.nc and $IC_SPS_guess/NEMO/$st/ice_ic$yyyy${st}_09.bkup.nc as ocean/seaice ICs for atm IC production. $dirnemoic/ice_ic$yyyy${st}_09.nc not present."
   title="[NEMOIC] ${SPSSYS} forecast warning"
   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   ln -sf $IC_SPS_guess/NEMO/$st/ice_ic$yyyy${st}_09.bkup.nc $dirnemoic/ice_ic$yyyy${st}_09.nc
   ln -sf $IC_SPS_guess/NEMO/$st/ice_ic$yyyy${st}_09.bkup.nc $dirnemoic/ice_ic$yyyy${st}_09.nc
   if [[ -f $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc ]]
   then
      rm $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc 
   fi
   ln -sf $IC_SPS_guess/NEMO/$st/${yyyy}${st}0100_R025_09_restart_oce_modified.bkup.nc $dirnemoic/$yyyy${st}0100_R025_09_restart_oce_modified.nc
fi
 
${DIR_UTIL}/submitcommand.sh -m $machine -S qos_resv -t "24" -q $serialq_l -j CAMICs.${yyyy}${st} -d ${DIR_ATM_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -s launch_make_atm_ic_l46_${SPSSYS}_op.sh -i "$inputatm"
#
