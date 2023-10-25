#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_SPS35}/descr_forecast.sh
set -euvx

echo "Starting job submission"
# Input **********************
st=$1
yyyy=$2

#*************************************
# Main loop ******************
#*************************************
ko=0
cnt_run=0
cnt_archive=0
cnt_temp_archive=0
cnt_atmICfile=0
cnt_lndIC=0
listacasi=""
listaskip=""
listaskip+=" "
cnt_lndIC=0
cnt_atmICfile=0
cnt_iceIC=0
cnt_nemoIC=0

submittable_cnt=0
subm_cnt=0

for n in $(seq 1 1 $nrunmax)
do
   echo "n $n *****************************"
   ens=`printf '%.3d' $n`
   script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/${header}_${yyyy}${st}_${ens}.sh 
   if [[ ! -f $script_to_submit ]]
   then
      echo "$script_to_submit does not exist!!!"
   fi
   submittable_cnt=$(( $submittable_cnt + 1 ))
   if [ -f $script_to_submit ] ; then

      # Check if belongs to NCEP Initial Condition (if 1 is NCEP statement )
      lndIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f18`
      atmIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f17`
      oceIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f19`
      # oceIC only digit
      oceICnum=$(echo $oceIC |  grep -o -E '[0-9]+' )

      lndICfile="${IC_CLM_SPS_DIR}/${st}/land_clm45_forced_${lndIC}_analisi_1993_2015.*${yyyy}-${st}-01-00000.nc"
      atmICfile="${IC_CAM_SPS_DIR}/${st}/${SPSSYS}.cam.i.${yyyy}${st}.${atmIC}.nc"
      nemoICfile="${IC_NEMO_SPS_DIR}/${st}/${yyyy}${st}0100_R025_0${oceICnum}_restart_oce_modified.nc"
      iceICfile="${IC_NEMO_SPS_DIR}/${st}/ice_ic${yyyy}${st}_0${oceICnum}.nc"

      caso=${SPSsystem}_${yyyy}${st}_${ens}

   # is running?
      set +e
#      np=`bjobs -w -sla ${slaID} | grep ${caso}_run | wc -l`
      np=`${DIR_SPS35}/findjobs.sh -m $machine -r ${slaID} -n ${caso}_run -c yes` 
#      ns=`bjobs -w -sla ${sla_serialID} | grep ${yyyy}${st}_${ens}_run | wc -l`
      ns=`${DIR_SPS35}/findjobs.sh -m $machine -r ${sla_serialID} -n ${yyyy}${st}_${ens}_run -c yes` 
      set -e

   # if is running, skip
      if [ $np -gt 0 ] || [ $ns -gt 0 ] ; then
         echo "job running. skip"
         cnt_run=$(( $cnt_run + 1 )) 
         ko=1
      fi

   # if exist in archive, skip
      if [ -d $FINALARCHIVE/$caso ] ; then
         echo "$FINALARCHIVE/$caso exist. skip"  
         cnt_archive=$(( $cnt_archive + 1 ))            
         ko=1
      fi
   # if exist in temporary archive, skip
      if [ -d $DIR_ARCHIVE/$caso ] ; then
         echo "$DIR_ARCHIVE/$caso exist. skip"  
         cnt_temp_archive=$(( $cnt_temp_archive + 1 ))            
         ko=1
      fi 
# THIS CHECKS ARE REDUNDANT IN PRINCIPLE (ALREADY DONE BY run_IC_production SCRIPT) BUT KEEP THEM
   # if atmospheric IC condition not exist, skip
      if [ ! -f $atmICfile ] ; then
         echo "atmICfile not exist. skip ************** "
         cnt_atmICfile=$(( $cnt_atmICfile + 1 ))              
         listaskip+="$caso "
         ko=1
      fi

  # if nemo oce IC condition not exist, skip
      if [ ! -f $nemoICfile ] ; then
         echo "nemoIC not exist. skip ************** "
         cnt_nemoIC=$(( $cnt_nemoIC + 1 ))              
         listaskip+="$caso "
         ko=1
      fi

  # if ice oce IC condition not exist, skip
      if [ ! -f $iceICfile ] ; then
         echo "iceICfile not exist. skip ************** "
         cnt_iceIC=$(( $cnt_iceIC + 1 ))              
         listaskip+="$caso "
         ko=1
      fi       
             
  # if land IC condition not exist, skip
      if [ `ls $lndICfile|wc -l` -ne 2 ] ; then
         echo "lndICfiles not exist. skip ************** "
         cnt_lndIC=$(( $cnt_lndIC + 1 ))              
           listaskip+="$caso "
         ko=1
      fi
      if [[ $ko -eq 1 ]] ; then
         continue
      fi

      subm_cnt=$(( $subm_cnt + 1 ))
      # Single member submission
      $script_to_submit
      echo "submitted $script_to_submit"
      listacasi+="$caso "
   fi
done

echo "Submitted $subm_cnt forecasts"
echo "Submittable $submittable_cnt"
totalskipped=$(( $cnt_run +  $cnt_archive + $cnt_temp_archive + $cnt_atmICfile + $cnt_lndIC  ))
echo "Total skipped $totalskipped"
echo "Land $cnt_lndIC "
echo "temporary archive $cnt_temp_archive "
echo "archive $cnt_archive "
body="Submitted $subm_cnt forecasts \n
\n
${listacasi[@]} \n
\n
Submittable $submittable_cnt \n
\n
Total skipped $totalskipped \n
${listaskip[@]} \n
\n
Land IC file missing $cnt_lndIC \n
\n
Atm IC file missing $cnt_atmICfile \n
\n
ICE cice IC file missing $cnt_iceIC \n
\n
OCE nemo IC file missing $cnt_nemoIC \n
\n
temporary archive $cnt_temp_archive \n
\n
archive_tmp $cnt_archive "
title="${SPSSYS} notification: FORECAST SUBMITTED"
${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 


exit 0
