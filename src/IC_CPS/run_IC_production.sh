#!/bin/sh -l
# HOW TO SUBMIT 
#yyyy=2024;st=04;input="$yyyy $st";${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_${yyyy}${st} -l $DIR_LOG/forecast/$yyyy$st -d $IC_CPS -s run_IC_production_test.sh -i "$input" 
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy=$1                    # year start-date
mm=$2                    # month start-date: this is a number 
                         # not 2 digits
st=`printf '%.2d' $((10#$mm))`   # 2 digits

idcomplete=${3:-0}   


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
#TO BE DEFINED

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

      mkdir -p  $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
      input="$yyyy $st $poce"
      $DIR_UTIL/submitcommand.sh -q s_medium -M 2500 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO

     submittedNEMO=1
     sleep 30
  fi
done


mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
for ilnd in {01..03}
do
   icclm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.nc
   ichydros=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.nc

   clm_err_file=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/clm_run_error_touch_EDA${ilnd}.$yyyy$st
   if [[ -f $clm_err_file ]] ; then
	   rm ${clm_err_file}
   fi
   eda_incomplete_check=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/EDA${ilnd}_incomplete_${yyyy}$st
   if [[ ! -f $eda_incomplete_check ]] && [[ $idcomplete -eq 1 ]]
   then
         body="CLM: EDA${ilnd} time-series was complete. You do not have to rerun"
         title="[CLMIC] ${CPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
         
   else   #operationally or for incomplete eda recover
         inputlnd="$yyyym1 $mmm1 $ilnd $icclm $ichydros $eda_incomplete_check ${clm_err_file}"
         ${DIR_UTIL}/submitcommand.sh -m $machine -M 3000 -S $qos -t "24" -q $serialq_l -s launch_forced_run_EDA.sh -j launchFREDA${ilnd}_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
         body="CLM: submitted script launch_forced_run_EDA.sh to produce CLM ICs from EDA perturbation $ilnd"
         title="[CLMIC] ${CPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
   fi
done

if [[ $idcomplete -eq 1 ]]
then
  #if idcomplete=1 (i.e. recovery mode for CLM analysis) - stop here and do not enter in the computation of CAM ICs
   exit
fi

# if operational run-time (idcomplete=0) 
if [[ $idcomplete -eq 0 ]]  
then
   for ilnd in {01..03}
   do
      #if present, remove old links to avoid using them instead of newly computed files
      actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.nc
      if [[ -L $actual_ic_clm ]]
      then
         unlink $actual_ic_clm
      fi
      actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.nc
      if [[ -L $actual_ic_hydros ]]
      then
         unlink $actual_ic_hydros
      fi
   done

   while `true`
   do
      sleep 600
      #select the first CLM IC available
      nmb_ic_mv=`ls $DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/mv_IC_EDA?_done |wc -l`
      nmb_job_launch=`$DIR_UTIL/findjobs.sh -m $machine -n launchFREDA -c yes`
      nmb_job_mv=`$DIR_UTIL/findjobs.sh -m $machine -n launch_mvIC -c yes`
      if [[ $nmb_ic_mv -ne 0 ]] 
      then
        ppland1d=`ls $DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/mv_IC_EDA?_done |tail -n1 |rev |cut -d '_' -f2  |cut -c1 |rev`
        ppland=`printf '%.2d' $ppland1d`
       	break
      elif [[ ${nmb_job_launch} -eq 0 ]] && [[ ${nmb_job_mv} -eq 0 ]]
      then
	  #if nothing is running, something wrong should have happened
	  #count the flag clm_run_error to take into account error runtime during clm analysis and take the first one - for that clm IC the backup will be used for CAM-IC computation
          nmb_clm_err=`ls $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/clm_run_error_touch_EDA${ilnd}.$yyyy$st |wc -l`
	         if [[ $nmb_clm_err -ne 0 ]]
          then
                ppland=`ls $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/clm_run_error_touch_EDA${ilnd}.$yyyy$st |tail -n1 |rev | cut -d '.' -f2 |cut -c1 |rev`
              		actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ppland.nc
	              	actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ppland.nc
                bkup_ic_clm=$IC_CPS_guess/CLM/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ppland.bkup.nc
                bkup_ic_hydros=$IC_CPS_guess/CLM/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ppland.bkup.nc
                body="Using $bkup_ic_clm and $bkup_ic_hydros for CAM ICs computation. cm3_lndSSP5-8.5_bgc_NoSnAg_eda$((10#${ppland}))_op did not complete correctly"
                title="[CLMIC] ${CPSSYS} forecast warning"
                $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                ln -sf $bkup_ic_clm $actual_ic_clm
                ln -sf $bkup_ic_hydros $actual_ic_hydros
		              break
          else
	       #this is not a runtime error, is something different which has not allowed the production of clm ICs at all
               if [[ `ls $IC_CPS_guess/CLM/$st/CPS1.clm2.r.$yyyy-$st-01-00000.??.bkup.nc |wc -l` -ne 0 ]] 
	              then
	                  bkup_ic_clm=`ls $IC_CPS_guess/CLM/$st/CPS1.clm2.r.$yyyy-$st-01-00000.??.bkup.nc |tail -n1`
	                  ppland=`echo $bkup_ic_clm |rev | cut -d '.' -f3 |rev`
	                  bkup_ic_hydros=$IC_CPS_guess/CLM/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ppland.bkup.nc
	                  actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ppland.nc
	                  actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ppland.nc
                   ln -sf $bkup_ic_clm $actual_ic_clm
                   ln -sf $bkup_ic_hydros $actual_ic_hydros
                   body="Using $bkup_ic_clm and $bkup_ic_hydros for CAM ICs computation. Operational CLM IC procedures do not complete correctly"
                   title="[CLMIC] ${CPSSYS} forecast warning"
                   $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
                   ln -sf $bkup_ic_clm $actual_ic_clm
                   ln -sf $bkup_ic_hydros $actual_ic_hydros
                   break
  	            fi
            
          fi
      fi
   done
fi
   
###############################################################
# NOW COMPUTE IC FOR CAM
# using poce=01 (unperturbed) -
###############################################################
#wait until all make_atm_ic_l83_ processes are done so that you are sure that no CAM ICs are in production
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
   bkup_nemoic_ctr=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.01.bkup.nc 
   bkup_ciceic_ctr=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.bkup.nc 
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
 
now_ic_cam=`ls $IC_CAM_CPS_DIR/$st/*${yyyy}$st*nc |wc -l`
mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#
#${DIR_UTIL}/submitcommand.sh -m $machine -S $qos -t "24" -q $serialq_l -j CAMICs.${yyyy}${st} -d ${DIR_ATM_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM -s launch_make_atm_ic_op.sh -i "$inputatm"
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
for pp in {0..9}
do

    # check if IC was already created on Juno (up to 20240108 it could be)
    ppcam=`printf '%.2d' $(($pp + 1))`
    if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.DONE ]]
    then
       continue
    fi

    t_analysis=00
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
    inputNEMO4CAM=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.nc
    if [[ ! -f ${inputNEMO4CAM} ]]
    then
       body="$IC_CPS/run_IC_production.sh: ${inputNEMO4CAM} missing!"
       echo $body
       continue
    fi

#         get check_IC_CAMguess from dictionary
    set +euvx
    . $dictionary
    set -euvx
    mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
    echo "---> going to produce first guess for CAM and start date $yyyy $st"
    input="$check_IC_CAMguess $yyyy $st $pp $t_analysis $inputECEDA"
    ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83.sh -i "$input"
    input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC $ppland"
    ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic.sh -i "$input"
done     #loop on pp

while `true`
do
    n_job_make_atm_ic=`$DIR_UTIL/findjobs.sh -m $machine -n firstGuess -a PEND -c yes`
    if [[ $n_job_make_atm_ic -eq 0 ]]
    then
       break
    fi
    sleep 60
done
sleep 1800 # assuming root_casoIC takes almost 40'
while `true`
do
    root_casoIC=${SPSSystem}_EDACAM_IC
    n_job_ICCAM=`$DIR_UTIL/findjobs.sh -m $machine -n $root_casoIC -c yes`
    if [[ $n_job_ICCAM -eq 0 ]]
    then
       break
    fi
    sleep 60
done
for ic in `seq -w 01 $n_ic_cam`
do
    if [[ ! -f $IC_CAM_CPS_DIR/$st/CPS1.cam.i.$yyyy-$st-01-00000.$ic.nc ]]
    then
        mv $IC_CAM_CPS_DIR/CPS1.cam.i.$yyyy-$st-01-00000.$ic.bkup.nc $IC_CAM_CPS_DIR/CPS1.cam.i.$yyyy-$st-01-00000.$ic.nc
        body="CAM: CAM IC $ic was not correctly produced. You are going to use the back-up"
        title="[CAMIC] ${CPSSYS} forecast notification"
        ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
    fi
done
#
