#!/bin/sh -l
# create bkup ICs for all modules
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
set -euvx
mkdir -p $DIR_LOG/IC_CAM

t_analysis="00"
if [[ $# -eq 0 ]] 
then
#standard from crontab last day of the month (taking EDA data from 2 days before)
   todaydate=`date +%Y%m%d`
   ddtoday=`date +%d`
   mmtoday=`date +%m`
   yytoday=`date +%Y`
   lastday=`. $DIR_UTIL/days_in_month.sh $mmtoday $yytoday`
   ddbackup=`date -d "$yytoday$mmtoday$lastday -1 day" +%d`
# exit if the date is not the last of the months prior to the forecast 
# which we choose as bk
   if [[ $ddtoday  != $ddbackup ]]
   then
      exit
   fi 
   bkdate=$todaydate
   ddEDA=`date -d $bkdate' - 2 day' +%d`
else
# recover with input from screen +%Y%m%d date of the EDA data we wnat to use
   bkdate=$1
   ddEDA=`date -d $bkdate +%d`
fi

yyIC=`date -d $bkdate +%Y`
mmIC=`date -d $bkdate +%m`
st=`date -d $yyIC$mmIC'01 + 1 month' +%m`
yyyy=`date -d $yyIC$mmIC'01 + 1 month' +%Y`
set +evxu
. $DIR_UTIL/descr_ensemble.sh $yyIC 
set -evxu

flagdir=$MYCESMDATAROOT/temporary/${typeofrun}/${yyyy}${st}/backup
mkdir -p $flagdir
# create backup ICs for Nemo
inputNEMO4CAM=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.bkup.nc
inputCICE4CAM=$IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-$st-01-00000.01.bkup.nc

##ON JUNO - nemo rebuild and CLM run
if [[ ${machine} == "juno" ]] 
then

  # now produce all of the 9 bkup nemo ICs
  # generate Ocean conditions
  procdate=`date +%Y%m%d-%H%M`
  mkdir -p $WORKDIR_OCE
  for poce in `seq -w 01 $n_ic_nemo`;do
     poce1=$((10#$poce - 1))
     nemoic=${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.${poce}.bkup.nc
     ciceic=${CPSSYS}.cice.r.$yyyy-${st}-01-00000.${poce}.bkup.nc
     dirnemoic=${IC_NEMO_CPS_DIR}/$st/
     mkdir -p $dirnemoic
     dirciceic=${IC_CICE_CPS_DIR}/$st/
     # compute only if operational or not existing  ANTO 20210319
     if [[ ! -f $dirnemoic/$nemoic ]] || [[ ! -f $dirnemoic/$ciceic ]]
     then

         mkdir -p  $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO
         input="$yyyy $st $poce"
         $DIR_UTIL/submitcommand.sh -q s_medium -M 2500 -s nemo_rebuild_restart.sh -i "$input" -d $DIR_OCE_IC -j nemo_rebuild_restart_${yyyy}${st}_${poce}_bkup -l $DIR_LOG/$typeofrun/$yyyy$st/IC_NEMO

         sleep 30
     fi
  done

  mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
  for ilnd in {01..03}
  do
      icclm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.bkup.nc
      ichydros=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.bkup.nc

      if [[ ! -f $icclm ]] || [[ ! -f $ichydros ]]
      then
          clm_err_file=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/clm_run_error_touch_EDA${ilnd}.$yyyy$st.bkup
          if [[ -f $clm_err_file ]] ; then
             rm ${clm_err_file}
          fi
          inputlnd="$yyIC $mmIC $ilnd $icclm $ichydros"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 3000 -S $qos -t "24" -q $serialq_l -s launch_forced_run_EDA_bkup.sh -j launchFREDA${ilnd}_${yyyy}${st}_bkup -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
          body="CLM: submitted script launch_forced_run_EDA_bkup.sh to produce backup CLM ICs from EDA perturbation $ilnd"
          title="[CLMIC-backup] ${CPSSYS} forecast notification"
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
      else
          echo "${icclm} ${ichydros} already computed"
      fi
  done

  while `true`
  do
     np_clm=`${DIR_UTIL}/findjobs.sh -m $machine -n launchFREDA -c yes`
     if [[ $np_clm -eq 0 ]]
     then
         break
     fi
     sleep 600
  done
#
  while `true`
  do
     n_ppland=`ls -lt $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/mv_IC_EDA?_bkup_done|wc -l`
     if [[ $n_ppland -ne 0 ]]
     then
          ppland1d=`ls -lt $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/mv_IC_EDA?_bkup_done|rev|cut -d'_' -f3|cut -c 1|rev|tail -1`
          ppland=`printf '%.2d' $ppland1d`
          touch $flagdir/CLM_ICbkup_${ppland}_OK
          break
     fi
     sleep 600
  done
#

  while `true`
  do
     np_nemo=`${DIR_UTIL}/findjobs.sh -m $machine -n nemo_rebuild_restart_${yyyy}${st}_01_bkup -c yes`
     if [[ $np_nemo -eq 0 ]]
     then
         if [[ -f $inputNEMO4CAM ]] && [[ -f $inputCICE4CAM ]] ; then
            touch $flagdir/NEMO_ICbkup_01_OK
            break
         fi
     fi
     sleep 600
  done

fi ## ON JUNO



####FORM HERE on CASSANDRA
if [[ $machine == "cassandra" ]] ; then
   
    while `true`
    do
        nflag_lnd=`ls $flagdir/CLM_ICbkup_??_OK |wc -l`
        nflag_oce=`ls $flagdir/NEMO_ICbkup_01_OK |wc -l`
        if [[ $nflag_oce -eq 1 ]] && [[ $nflag_lnd -eq 1 ]] ; then
             echo "CLM and NEMO ICs produced on Juno, ready to run on Cassandra CAM ICs"
             break
        fi
        sleep 600
    done
     


    ppland=`ls -lt $flagdir/CLM_ICbkup_??_OK|rev|cut -d'_' -f2|rev|tail -1`
    for pp in `seq 0 $((${n_ic_cam} -1))` 
    do

# check if IC was already created 
       ppcam=`printf '%.2d' $(($pp + 1))`
       inputECEDA=$DATA_ECACCESS/EDA/snapshot/${t_analysis}Z/ECEDA${pp}_$yyIC$mmIC${ddEDA}_${t_analysis}.grib
       casoIC=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${ddEDA}.bkup
       if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.bkup.nc ]]
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
           exit
        fi

#        get check_IC_CAMguess from dictionary
      		set +euvx
		      . $dictionary
		      set -euvx
		      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
	      	echo "---> going to produce first guess for CAM and start date $yyyy $st"
      		input="$yyyy $st $pp $t_analysis $inputECEDA $ddEDA"
      		${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83.sh -i "$input"
        input="$yyyy $st $pp $yyIC $mmIC $ddEDA $casoIC $ppland"
        ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${casoIC} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic.sh -i "$input"

    done     #loop on perturbations

fi #CASSANDRA

# wait until all the ICs have been produced and stored (.case.store_ICcam)
# Note that this method differs from the operational one where we only wait for the completion of the
# short forecast since the .case.store_ICcam should be almost instantaneous thanks to the 
# serial-node SC_SERIAL_sps35. On the other hand in operational mode we can also rest on less
# than 10 ICs produced since we still rely on backup ICs, which instead MUST be 10

###ON JUNO
if [[ $machine == "juno" ]] ; then
    while `true`
    do
        n_IC_bkup=`ls $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.??.bkup.nc|wc -l`
        if [[ $n_IC_bkup -eq 10 ]]
        then
             break
        fi
        sleep 600
    done
    body="$IC_CPS/run_IC_production_bkup.sh: production of 10 backup CAM ICs completed, now sending to Leonardo."
    title="[CAMIC-bkup] ${CPSSYS} notification"
    ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
    ${IC_CPS}/copy_ICs_and_triplette_to_Leonardo.sh $yyyy $st 1
fi
