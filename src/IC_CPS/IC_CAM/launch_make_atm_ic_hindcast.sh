#!/bin/sh -l
. ~/.bashrc
.  $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
set -euvx
mkdir -p $DIR_LOG/IC_CAM
LOG_FILE=$DIR_LOG/IC_CAM/launch_make_atm_ic_`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
iniy=$iniy_hind
endy=2003
debugp=0   # if 1 do only one and exit
debugy=0   # if 1 do only one year

totcores_SC=$(($nnodes_SC*$cores_per_node))
np_clim=`${DIR_UTIL}/findjobs.sh -m $machine -n run.cm3_cam122 -c yes`
np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
if [ $np_clim -eq 0 ]
then
   echo "go on with hindcast submission"
   tobesubmitted=$(( $maxnumbertosubmit - ${np_all} + 1 ))
else
# this is temporary and holds only for Juno but is harmless on Zeus
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

listfiletocheck=${SPSSystem}_${typeofrun}_IC_CAM_list.${machine}.csv
nrun_submitted=0
if [[ $machine == "zeus" ]]
then
   inist=8
elif [[ $machine == "juno" ]]
then
   inist=7
fi
for st in `seq -w $inist 2 12`
do
   for yyyy in `seq $iniy $endy`
   do
       for pp in {0..9}
       do
          ppcam=`printf '%.2d' $(($pp + 1))`
          if [[ -f $IC_CAM_CPS_DIR/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$ppcam.nc ]]
          then
              LN="$(grep -n "$yyyy$st" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"
              table_column_id=$(($((10#$ppcam)) + 1))
              awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
              rsync -auv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck 
              continue
          fi  

          check_IC_CAMguess=`grep check_IC_CAMguess $dictionary|cut -d '=' -f2`
          mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM
          echo "---> going to produce first guess for CAM and start date $yyyy $st"
          input="$check_IC_CAMguess $yyyy $st $pp"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -j firstGuessIC4CAM_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s makeICsGuess4CAM_FV0.47x0.63_L83_hindcast.sh -i "$input"
          input="$yyyy $st $pp"
          ${DIR_UTIL}/submitcommand.sh -m $machine -M 2000 -q $serialq_l -p firstGuessIC4CAM_${yyyy}${st}_${pp} -j make_atm_ic_${yyyy}${st}_${pp} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CAM -d $DIR_ATM_IC -s make_atm_ic_hindcast.sh -i "$input"
          nrun_submitted=$(($nrun_submitted + 1))
          if [[ $nrun_submitted -eq $tobesubmitted ]]
          then
             exit
          fi
          sleep 10
          
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
