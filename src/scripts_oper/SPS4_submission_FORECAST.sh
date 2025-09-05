#!/bin/sh -l
# load variables from descriptor
# SUBMISSION FROM JUNO (crontab) NOT WORKING WITH LEONARDO WITH submitcommand
#30 10 * * * . /etc/profile; . /users_home/cmcc/cp1/.bashrc && . ${DIR_UTIL}/descr_CPS.sh && ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j SPS4_submissione_FORECAST -l $DIR_LOG/hindcast/ -d $DIR_CPS -s SPS4_submission_FORECAST.sh

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

st=`date +%m`
yyyy=`date +%Y`
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evx

# check if there is another job submitted by crontab with the same name
if [[ $machine == "leonardo" ]]
then
   conda activate $envcondacm3
   LOG_FILE=$DIR_LOG/forecast/SPS4_submission_FORECAST.`date +%Y%m%d%H%M`.log
   exec 3>&1 1>>${LOG_FILE} 2>&1

   cnt_this_script_running=$(ps -u ${operational_user} -f |grep SPS4_submission_FORECAST | grep -v $$|wc -l)
   if [[ $cnt_this_script_running -gt 2 ]]
   then
      echo "already running"
      title="[${CPSSYS} WARNING] script SPS4_submission_FORECAST.sh exited!"
      body="SPS4_submission_FORECAST.sh already running exited"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      exit
   else
      lastlog=`ls -rt $SCRATCHDIR/cases_${st}/${header}_${yyyy}${st}*log|tail -1`
      check_aborted=`grep aborted $lastlog|wc -l`
# takes into account the possibility that for misterious reasons srun commnad failed
      if [[ $check_aborted -ne 0 ]]
      then
         ens_aborted=`echo $lastlog|rev|cut -d '.' -f2|cut -d '_' -f1|rev`
         $DIR_UTIL/clean_caso.sh ${SPSSystem}_${yyyy}${st}_${ens_aborted}
         title="[${CPSSYS} WARNING] case ${SPSSystem}_${yyyy}${st}_${ens_aborted} not submitted due to srun issues"

         body="${SPSSystem}_${yyyy}${st}_${ens_aborted} cleaned and going to be resubmitted"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      fi
   fi
else
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n SPS4_submission_FORECAST -c yes`
   if [ $np -gt 1 ]
   then
# if so check if it is correctly running
      ID_unknown=`${DIR_UTIL}/findjobs.sh -m $machine -n SPS4_submission_FORECAST -a $BATCHUNKNOWN -i yes`
      if [[ -n $ID_unknown ]]
      then
# in the remote case that the job already on queue is in unknown status 
# kill it
         $DIR_UTIL/killjobs.sh -m $machine -i $ID_unknown
# it often occurs that if a job is in unknown status others too are in the same.
         title="WARNING!!! FORECAST LAUNCHER FOUND IN UNKNOWN STATUS on $machine"
         body="Check if other jobs are in unknown status too!!"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      else
# otherwise exit
         echo "there is one SPS4_submission_FORECAST already running! Exiting now!"
         title="[${CPSSYS} WARNING] script SPS4_submission_FORECAST.sh exited!"
         body="SPS4_submission_FORECAST.sh already running exited"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
         exit
      fi
   fi
fi
# this can be redundant on Juno
$IC_CPS/set_forecast_ICs.sh $yyyy $st
# Input **********************
$DIR_CPS/make_ensemblescripts.sh $yyyy $st
stlist=$st

nmaxens=${nrunmax}

np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
if [ $np_all -lt $maxnumbertosubmit ]
then
   echo "go on with forecast submission"
   tobesubmitted=$(( $maxnumbertosubmit - ${np_all} + 1 ))
else
   echo "Exiting now! already $np_all job on parallel queue"
   if [[ $machine == "leonardo" ]] && [[ -f ${check_submission_running} ]] ; then
      rm ${check_submission_running}
   fi
   exit
fi

# Main loop ******************
cnt_run=0
cnt_archive=0
cnt_data_archive=0
cnt_dircases=0
cnt_archive=0
cnt_old_home=0
cnt_atmICfile=0
cnt_lndIC=0
cnt_nemoIC=0
cnt_iceIC=0
cnt_sleep=0

cnt_fy=0
listacasi=()
listaskipCAM=()
listaskipNEMO=()
listaskipCICE=()
listaskipCLM=()
listaskip=()

submittable_cnt=0
subm_cnt=0

echo "YEAR $yyyy *****************************"

#check how many members done per year

for n in `seq 1 $nrunmax`
do
   flg_continue=0
   echo "n $n *****************************"
   ens=`printf '%.3d' $n`
   caso=${SPSSystem}_${yyyy}${st}_${ens}
 
# is running?
set +e
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
set -e
 
# if is running, skip
   if [ $np -gt 0 ] ; then
     echo "job running. skip"
     cnt_run=$(( $cnt_run + 1 )) 
     continue
   fi
 
   lg_continue=0
# if exist in $DIR_CASES, skip
   if [ -d $DIR_CASES/$caso ] ; then
     echo "$DIR_CASES/$caso exist. skip"  
     cnt_dircases=$(( $cnt_dircases + 1 ))            
     lg_continue=1
   fi
# if exist in archive, skip
   if [ -d $DIR_ARCHIVE/$caso ] ; then
     echo "$DIR_ARCHIVE/$caso exist. skip"  
     cnt_archive=$(( $cnt_archive + 1 ))            
     lg_continue=1
   fi 
 
   if [[ $lg_continue -eq 1 ]]
   then
     continue
   fi 
   if [[ $machine == "leonardo" ]]
   then
     script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/CINECA/${header}_${yyyy}${st}_${ens}.sh 
   else
     script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/${header}_${yyyy}${st}_${ens}.sh 
   fi
   submittable_cnt=$(( $submittable_cnt + 1 ))
   if [ -f $script_to_submit ] ; then
     if [[ $machine == "leonardo" ]]
     then
        res1=`grep 'sed' ${script_to_submit} |cut -d '/' -f12`
        res2=`grep 'sed' ${script_to_submit} |cut -d '/' -f9`
        res3=`grep 'sed' ${script_to_submit} |cut -d '/' -f15`
     else
        res1=`grep submitcommand.sh ${script_to_submit} | cut -d ' ' -f18`
        res2=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f17`
        res3=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f19`
     fi
     lndIC=`printf '%.2d' $res1`
     atmIC=`printf '%.2d' $res2`
     oceIC=`printf '%.2d' $res3`
  # oceIC only digit
 
     n_lndICfiles=`ls ${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.*.r.${yyyy}-${st}-01-00000.${lndIC}.nc| wc -l`
     clmICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.clm2.r.${yyyy}-${st}-01-00000.${lndIC}.nc
     rofICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.hydros.r.${yyyy}-${st}-01-00000.${lndIC}.nc
     atmICfile=${IC_CAM_CPS_DIR}/${st}/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.${atmIC}.nc
     nemoICfile=${IC_NEMO_CPS_DIR}/${st}/${CPSSYS}.nemo.r.${yyyy}-${st}-01-00000.${oceIC}.nc
     iceICfile=${IC_CICE_CPS_DIR}/${st}/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${oceIC}.nc
 
  # if atmospheric IC condition not exist, skip
     if [ ! -f $atmICfile ] ; then
         if [ -f $atmICfile.gz ] ; then
            gunzip -f $atmICfile.gz
         else
            echo ""
            echo "CAM IC $atmICfile does not exist. ************** "
            echo "skip $caso                                  "
            echo ""
            cnt_atmICfile=$(( $cnt_atmICfile + 1 ))              
            listaskipCAM+="$caso "
            flg_continue=1
        fi
     fi
 
  # if nemo oce IC condition not exist, skip
     if [ ! -f $nemoICfile ] ; then
       if [ -f $nemoICfile.gz ] ; then
          gunzip -f $nemoICfile.gz
       else
          echo ""
          echo "NEMO IC $nemoICfile does not exist. skip ************** "
          echo "skip $caso                                  "
          echo ""
          cnt_nemoIC=$(( $cnt_nemoIC + 1 ))              
          listaskipNEMO+="$caso "
          flg_continue=1
       fi
     fi
 
  # if ice oce IC condition not exist, skip
     if [ ! -f $iceICfile ] ; then
        if [ -f $iceICfile.gz ] ; then
           gunzip -f $iceICfile.gz
        else
           echo ""
           echo "CICE IC $iceICfile does not exist. skip ************** "
           echo "skip $caso                                  "
           echo ""
           cnt_iceIC=$(( $cnt_iceIC + 1 ))              
           listaskipCICE+="$caso "
           flg_continue=1
        fi       
     fi       

  # if land IC condition not exist, skip
     if [ $n_lndICfiles -ne 2 ] ; then
         echo ""
         echo "lndICfiles do not exist. skip ************** "
         echo "skip $caso                                  "
         echo ""
         cnt_lndIC=$(( $cnt_lndIC + 1 ))              
         listaskipCLM+="$caso "
         flg_continue=1
     else 
        if [ -f $rofICfile.gz ] 
        then
            gunzip -f $rofICfile.gz
        fi
        if [ -f $clmICfile.gz ] 
        then
            gunzip -f $clmICfile.gz
        fi
     fi

     if [ $flg_continue -eq 1 ]
     then
        continue
     fi
 
     echo "submit $script_to_submit"
     
  # If here, all the conditions are satisfied, and the serial launcher can be submitted
     if [[ $machine == "leonardo" ]]
     then
        mkdir -p $SCRATCHDIR/cases_${st}
        $script_to_submit >& $SCRATCHDIR/cases_${st}/ensemble4_${yyyy}${st}_${ens}.log
     else
        $script_to_submit
     fi
     listacasi+="$caso "
     subm_cnt=$(( $subm_cnt + 1 )) 
     cnt_sleep=$(($cnt_sleep +1 ))   
  
  # REDUNDANT but safe (check how many jobs are on parallel queue)
  # if $maxnumbertosubmit already running exit
  # this control does not count the cases still in the create_caso phase
     np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
     
     if [[ ${cnt_sleep} -eq 10 ]] ; then
        sleep 1800
        cnt_sleep=0
     fi
     if [ $np_all -ge $maxnumbertosubmit ]
     then
        break 4
     fi

   fi
done

echo "For climatological start-date $st submitted $subm_cnt members"
echo "Submittable $submittable_cnt"
totalskipIC=${listaskipCAM}" "${listaskipCICE}" "${listaskipNEMO}" "${listaskipCLM}
listaskip=${listaskipCAM}" "${listaskipCICE}" "${listaskipNEMO}" "${listaskipCLM}
cnt_skipIC=`echo $totalskipIC|wc -w`
totalskipped=$(( $cnt_run +  $cnt_archive + $cnt_data_archive + $cnt_dircases + $cnt_archive + $cnt_skipIC + $cnt_old_home))
echo "Total skipped $totalskipped"
echo "Land $cnt_lndICfile "
echo "Atm $cnt_atmICfile "
echo "Ocn $cnt_oceICfile "
echo "Ice $cnt_iceICfile "
echo "archive ($DIR_ARCHIVE) $cnt_archive "
echo "case already created $cnt_dircases "
echo "case already completed on old $HOME but still to be ported $cnt_old_home "
echo "running $cnt_run "
body="Submitted $subm_cnt startdates \n
\n
${listacasi[@]} \n
\n
Climatological start-date: ${st} \n
\n
Submittable $submittable_cnt \n
\n
Total skipped $totalskipped \n
${listaskip}
\n
Land IC file missing $cnt_lndIC \n
\n
Atm IC file missing $cnt_atmICfile \n
\n
ICE cice IC file missing $cnt_iceIC \n
\n
OCE nemo IC file missing $cnt_nemoIC \n
\n
archive $cnt_archive \n
\n
case running $cnt_run \n
\n
cases already created $cnt_dircases \n"
title="NEW FORECAST SUBMISSION COMPLETED on $machine"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st


exit 0
