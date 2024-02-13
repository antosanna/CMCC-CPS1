#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=$endy_hind
debugp=0   # if 1 do only one and exit
debugy=0   # if 1 do only one year

totcores_SC=$(($nnodes_SC*$cores_per_node))
#np_clim=`${DIR_UTIL}/findjobs.sh -m $machine -n run.cm3_cam122 -c yes`
np_clim=0
## removed from c3s2
np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
if [ $np_clim -eq 0 ]
then
   echo "go on with hindcast submission"
   tobesubmitted=10
   #tobesubmitted=$(( $maxnumbertosubmit - ${np_all} + 1 ))
else
## this is temporary and holds only for Juno but is harmless on Zeus
   ncoresclim=1296
   if [ $np_all -ne 0 ]
   then
      ncoreshind=$(($np_all*$cores_per_run))
      totcores=$(($ncoresclim + $ncoreshind))
      if [[ $totcores -ge $totcores_SC ]]
      then
         echo "Exiting now! already $np_all job on parallel queue"
         exit
      fi
      tobesubmitted=$((($totcores_SC - $totcores)/$cores_per_run))
# just to be really safe take out 2
      tobesubmitted=$(($tobesubmitted - 2 ))
   fi
fi

nrun_submitted=0
if [[ $machine == "zeus" ]]
then
   inist=1
elif [[ $machine == "juno" ]]
then
   exit 0
fi
tstamp="00"
#for st in `seq -w $inist 12`
list_startdate="12 01 02 03 04 05 06 07 08 09 10 11"
for st in $list_startdate
do
   for yyyy in `seq $iniy 2014`
   do
       yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
       mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
       dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
       for pp in {0..9}
       do
          
          inputECEDA=$DATA_ECACCESS/EDA/snapshot/${tstamp}Z/ECEDA${pp}_$yyIC$mmIC${dd}_${tstamp}.grib
          if [[ ! -f ${inputECEDA} ]] 
          then
             body="$DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh: ${inputECEDA} missing!"
             echo $body
             if [[ $typeofrun == "forecast" ]]
             then
                title="[CAMIC] ${CPSSYS} ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "$typeofrun" -s $yyyy$st
             fi
             continue
          fi
# check if IC was already created on Juno (up to 20240108 it could be)
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.DONE ]] 
          then
             continue
          fi
          inputNEMO4CAM=$IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-$st-01-00000.01.nc
          if [[ ! -f ${inputNEMO4CAM} ]] 
          then
             body="$DIR_ATM_IC/makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh: ${inputNEMO4CAM} missing!"
             echo $body
             continue
          fi
          casoIC=${SPSSystem}_EDACAM_IC${ppcam}.${yyIC}${mmIC}${dd}
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]] 
          then
# remove raw data from /data/delivery
              is_file_there=`ssh sp2@zeus01.cmcc.scc ls ${inputECEDA} |wc -l`
              if [[ $is_file_there -eq 1 ]]
              then 
                 ssh sp2@zeus01.cmcc.scc rm ${inputECEDA} 
              fi
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
              continue
          fi  

#         get check_IC_CAMguess from dictionary
          set +euvx
          . $dictionary
          set -euvx
          mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
          echo "---> going to produce first guess for CAM and start date $yyyy $st"
          input="$check_IC_CAMguess $yyyy $st $pp $tstamp $inputECEDA"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
          input="$yyyy $st $pp $yyIC $mmIC $dd $casoIC"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
          nrun_submitted=$(($nrun_submitted + 1))
          if [[ $nrun_submitted -eq $tobesubmitted ]]
          then
             exit
          fi
          sleep 2
          
          if [[ $debugp -eq 1 ]]
          then
             exit
          fi
       done     #loop on pp
       if [[ $debugy -eq 1 ]]
       then
          exit
       fi
   done     #loop on start-month
done     #loop on years
