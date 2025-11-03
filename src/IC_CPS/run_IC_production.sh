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
###############################################################
# FIRST OF ALL IC FOR NEMO NEEDED TO COMPUTE IC CAM ON THE FORECAST DAY
###############################################################
# generate Ocean conditions 
procdate=`date +%Y%m%d-%H%M`

flagdir=$MYCESMDATAROOT/temporary/${typeofrun}/${yyyy}${st}/operational
mkdir -p $flagdir
flag4CAM=$flagdir/CAM_ICs_on_CASSANDRA_DONE


#ON JUNO
if [[ $machine == "juno" ]] 
then
  mkdir -p $WORKDIR_OCE
  #for poce in `seq -w 01 $n_ic_nemo`;do
  if [[ $idcomplete -eq 0 ]] ; then
     for poce in `seq -w 01 $n_ic_nemo`;do
         poce1=$((10#$poce - 1))
         nemoic=${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.${poce}.nc
         ciceic=${CPSSYS}.cice.r.$yyyy-${st}-01-00000.${poce}.nc
         dirnemoic=${IC_NEMO_CPS_DIR}/$st/
         mkdir -p $dirnemoic
         dirciceic=${IC_CICE_CPS_DIR}/$st/
#
# compute only if operational or not existing  ANTO 20210319
         if [[ ! -f $dirnemoic/$nemoic ]] || [[ ! -f $dirciceic/$ciceic ]]
         then
             mkdir -p  $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
             input="$yyyy $st $poce"
             $DIR_UTIL/submitcommand.sh -q s_medium -M 2500 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO

             sleep 30
         fi
     done
  fi

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
     
        if [[ ! -f  $icclm ]] || [[ ! -f $ichydros ]]  #operationally
        then
            inputlnd="$yyyym1 $mmm1 $ilnd $icclm $ichydros $eda_incomplete_check ${clm_err_file}"
            ${DIR_UTIL}/submitcommand.sh -m $machine -M 3000 -S $qos -t "24" -q $serialq_l -s launch_forced_run_EDA.sh -j launchFREDA${ilnd}_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
            body="CLM: submitted script launch_forced_run_EDA.sh to produce CLM ICs from EDA perturbation $ilnd"
            title="[CLMIC] ${CPSSYS} forecast notification"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
        elif [[ -f $eda_incomplete_check ]] && [[ $idcomplete -eq 1 ]]
        then
            inputlnd="$yyyym1 $mmm1 $ilnd $icclm $ichydros $eda_incomplete_check ${clm_err_file}"
            ${DIR_UTIL}/submitcommand.sh -m $machine -M 3000 -S $qos -t "24" -q $serialq_l -s launch_forced_run_EDA.sh -j launchFREDA${ilnd}_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
            body="CLM: submitted script launch_forced_run_EDA.sh to produce CLM analysis restart from EDA perturbation $ilnd"
            title="[CLMIC] ${CPSSYS} forecast notification"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
         
        fi
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
             touch ${flagdir}/CLM_ICop_${ppland}_OK
       	     break
         elif [[ ${nmb_job_launch} -eq 0 ]] && [[ ${nmb_job_mv} -eq 0 ]]
         then
	            #if nothing is running and no file are present, something wrong should have happened
    	        #something has not allowed the production of clm ICs going to use the bkup ICs
             if [[ `ls $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.??.bkup.nc |wc -l` -ne 0 ]] 
             then
                 bkup_ic_clm=`ls $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.??.bkup.nc |tail -n1`
                 ppland=`echo $bkup_ic_clm |rev | cut -d '.' -f3 |rev`
                 bkup_ic_hydros=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ppland.bkup.nc
                 actual_ic_clm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ppland.nc
                 actual_ic_hydros=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ppland.nc
                 # replace operational IC with backup (we want to delete backup if not used)
                 rsync -auv $bkup_ic_clm $actual_ic_clm
                 rsync -auv $bkup_ic_hydros $actual_ic_hydros
                 body="Using $bkup_ic_clm and $bkup_ic_hydros for CAM ICs computation. Operational CLM IC procedures do not complete correctly"
                 title="[CLMIC] ${CPSSYS} forecast warning"
                 $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                 touch ${flagdir}/CLM_ICop_${ppland}_OK
                 break
             else
                 body="Operational CLM IC procedures do not complete correctly and no backup IC available for CLM. It is not possible to produce CAM ICs."
                 title="[CLMIC] ${CPSSYS} forecast error"
                 $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                 exit
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
  ciceic_ctr=$dirciceic/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.nc
  if [[ -f $nemoic_ctr ]] && [[ -f $ciceic_ctr ]] ; then
      touch $flagdir/NEMO_ICop_01_OK
  elif [[ ! -f $nemoic_ctr ]]
  then
     bkup_nemoic_ctr=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.01.bkup.nc 
     bkup_ciceic_ctr=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.01.bkup.nc 
     body="Using $bkup_nemoic_ctr and $bkup_ciceic_ctr as ocean/seaice ICs for atm IC production. $nemoic_ctr not produced."

     title="[NEMOIC] ${CPSSYS} forecast warning"
     $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
  # we replace both operational ICs with backup (backup ICs will be removed if not used)
  # here we evaluate the case where CICE IC was produced but Nemo was not 
  # and for consistency we replace both
     rsync -auv $bkup_nemoic_ctr $nemoic_ctr
     rsync -auv $bkup_ciceic_ctr $ciceic_ctr
     touch $flagdir/NEMO_ICop_01_OK
  elif [[ ! -f $ciceic_ctr ]]
  then
     body="Using $bkup_nemoic_ctr and $bkup_ciceic_ctr as ocean/seaice ICs for atm IC production. $ciceic_ctr not present."
     title="[NEMOIC] ${CPSSYS} forecast warning"
     $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
  # we replace both operational ICs with backup (backup ICs will be removed if not used)
  # here we evaluate the case where Nemo IC was produced but CICE was not 
  # and for consistency we replace both
     rsync -auv $bkup_ciceic_ctr $ciceic_ctr
     rsync -auv $bkup_nemoic_ctr $nemoic_ctr
     touch $flagdir/NEMO_ICop_01_OK
  fi
fi 

####ON CASSANDRA

if [[ $machine == "cassandra" ]] ; then

    while `true`
    do
        nflag_lnd=`ls $flagdir/CLM_ICop_??_OK |wc -l`
        nflag_oce=`ls $flagdir/NEMO_ICop_01_OK |wc -l`
        if [[ $nflag_oce -eq 1 ]] && [[ $nflag_lnd -eq 1 ]] ; then
             echo "CLM and NEMO ICs produced on Juno, ready to run on Cassandra CAM ICs"
             break
        fi  
        sleep 600 
    done
    ppland=`ls -lt $flagdir/CLM_ICop_??_OK|rev|cut -d'_' -f2|rev|tail -1`

    mkdir -p ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CAM
#
    yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
    mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
    last_dd_mmIC=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC month last day
    dd=$(($last_dd_mmIC - 1))
    t_analysis=00
    for pp in `seq 0 $((${n_ic_cam} -1))` 
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
       input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC $ppland"
       ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p makeICsGuess4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic.sh -i "$input"
    done     #loop on pp
   
    root_casoIC=${SPSSystem}_EDACAM_IC
    while `true`
    do
       sleep 300
       n_job_make_atm_ic=`$DIR_UTIL/findjobs.sh -m $machine -n makeICsGuess4CAM_  -c yes`
       n_job_ICCAM=`$DIR_UTIL/findjobs.sh -m $machine -n ${root_casoIC} -c yes`
       n_store_ic=`$DIR_UTIL/findjobs.sh -m $machine -n store_ICcam -c yes`
       n_count=$((${n_job_make_atm_ic} + ${n_job_ICCAM} + ${n_store_ic}))
       #if all of them are equal to zero all procedure for CAM IC production have been completed (succesfully or not but in any case everything is finished)
       #the idea is to touch the flag so that, on juno, the set_forecast_IC procedure eventually replace backup ICs if needed
       if [[ ${n_count} -eq  0 ]] ; then
         touch $flag4CAM 
         break
       fi  
    done
    exit #on Cassandra nothing else to be done
fi

# loop to check that no interpolation jobs (makeICsGuess4CAM_FV0.47x0.63_L83.sh) is pending

#while `true`
#do
#    n_job_make_atm_ic=`$DIR_UTIL/findjobs.sh -m $machine -n makeICsGuess4CAM_ -a PEND -c yes`
#    if [[ $n_job_make_atm_ic -eq 0 ]]
#    then
#       break
#    fi
#    sleep 60
#done
#sleep 1800 # assuming root_casoIC takes almost 40'
## wait until completion of all CAM ICs
#while `true`
#do
#    root_casoIC=${SPSSystem}_EDACAM_IC
#    n_job_ICCAM=`$DIR_UTIL/findjobs.sh -m $machine -n $root_casoIC -c yes`
#    if [[ $n_job_ICCAM -eq 0 ]]
#    then
#       break
#    fi
#    sleep 60
#done

# remove temporary work spaces
#for pp in {0..9}
#do
#    casoIC=${SPSSystem}_EDACAM_IC${pp}.${yyIC}${mmIC}${dd}
#   if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$pp.nc ]]
#   then
#      if [[ -d $DIR_CASES/$casoIC ]]
#      then
#         rm -rf $DIR_CASES/$casoIC
#      fi
#      if [[ -d $DIR_ARCHIVE/$casoIC ]]
#      then
#         rm -rf $DIR_ARCHIVE/$casoIC
#      fi
#      if [[ -d $WORK_CPS/$casoIC ]]
#      then
#         rm -rf $WORK_CPS/$casoIC
#      fi
#  fi
#done
# replace missing ICs with backup

#to be sure that - if correctly finished - all the operational ICs have been effectively moved to final destination
#if for some reason one IC run failed, also the storeIC will disappear from queues, and in this case the bkup IC will be substitue by set_forecast_IC proc

if [[ $machine == "juno" ]] ; then
   while `true`
   do
       if [[ -f $flag4CAM  ]] ; then
          break
       fi
       sleep 600
   done
   $IC_CPS/set_forecast_ICs.sh $yyyy $st
fi
