#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993

set -evx

# check if there is another job submitted by crontab with the same name
if [[ $machine == "leonardo" ]]
then
   conda activate $envcondacm3
   LOG_FILE=$DIR_LOG/hindcast/SPS4_submission_hindcast.`date +%Y%m%d%H%M`.log
   exec 3>&1 1>>${LOG_FILE} 2>&1

   cnt_this_script_running=$(ps -u ${operational_user} -f |grep SPS4_sub | grep -v $$|wc -l)
   if [[ $cnt_this_script_running -gt 2 ]]
   then
      echo "already running"
      exit
   fi
else
   np=`${DIR_UTIL}/findjobs.sh -m $machine -n SPS4_main_hc -c yes`
   if [[ $np -gt 1 ]]
   then
# if so check if it is correctly running
      ID_unknown=`${DIR_UTIL}/findjobs.sh -m $machine -n SPS4_main_hc -a $BATCHUNKNOWN -i yes`
      if [[ -n $ID_unknown ]]
      then
# in the remote case that the job already on queue is in unknown status 
# kill it
         $DIR_UTIL/killjobs.sh -m $machine -i $ID_unknown
# it often occurs that if a job is in unknown status others too are in the same.
         title="WARNING!!! HINDCAST LAUNCHER FOUND IN UNKNOWN STATUS on $machine"
         body="Check if other jobs are in unknown status too!!"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
      else
# otherwise exit
         echo "there is one SPS4_main_hc already running! Exiting now!"
         exit
      fi
   fi
fi
# Input **********************
stlist=11

#max number of ens member to be submitted per startdate
#to advance with the diagnostic it has been decided to run first
#a reduced ensemble over all the timeseries 
nmaxens=${2:-${nrunmaxext}}

#if by mistake the input is greater than $nrunmaxext (20) 
#nrunmaxext is restored
if [[ $nmaxens -gt ${nrunmaxext} ]] ; then
   nmaxens=${nrunmaxext}
fi

np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive.${SPSSystem}ext_ -c yes`
if [[ $np_all -lt $maxnumbertosubmit ]]
then
   echo "go on with hindcast submission"
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

cnt_fy=0
listacasi=()
listaskipCAM=()
listaskipNEMO=()
listaskipCICE=()
listaskipCLM=()
listaskip=()

submittable_cnt=0
subm_cnt=0

for st in $stlist
do
   for yyyy in $(seq $iniy_hind $endyear)
   do
       echo "YEAR $yyyy *****************************"
       
       #check how many members done per year
       n_moredays_done=`ls $DIR_CASES/${SPSSystem}ext_${yyyy}${st}_???/logs/run_moredays_${SPSSystem}ext_${yyyy}${st}_0??_DONE |wc -l`
       if [[ ${n_moredays_done} -ge $nmaxens ]] ; then
          continue
       fi
       np_yyyyst=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}ext_${yyyy}${st} -c yes`
       if [[ $((${n_moredays_done} + $np_yyyyst )) -ge $nmaxens ]] ; then
          continue
       fi
       
       for n in `seq 1 $nrunmaxext`
       do
         flg_continue=0
         echo "n $n *****************************"
         ens=`printf '%.3d' $n`
         caso=${SPSSystem}ext_${yyyy}${st}_${ens}
  
         # is running?
         set +e
         np=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
         set -e
  
         # if is running, skip
         if [[ $np -gt 0 ]] ; then
            echo "job running. skip"
            cnt_run=$(( $cnt_run + 1 )) 
            continue
         fi
  
         lg_continue=0
         # if exist in $DIR_CASES, skip
         if [[ -d $DIR_CASES/$caso ]] ; then
            echo "$DIR_CASES/$caso exist. skip"  
            cnt_dircases=$(( $cnt_dircases + 1 ))            
            lg_continue=1
         fi
         # if exist in archive, skip
         if [[ -d $DIR_ARCHIVE/$caso ]] ; then
            echo "$DIR_ARCHIVE/$caso exist. skip"  
            cnt_archive=$(( $cnt_archive + 1 ))            
            lg_continue=1
         fi 
  
         if [[ -f /work/csp/cp1/CPS/CMCC-CPS1/cases/$caso/logs/run_moredays_${caso}_DONE ]] ; then
            echo "$caso completed on old $HOME (csp). skip"  
            cnt_old_home=$(( $cnt_old_home + 1 ))            
            lg_continue=1
         fi 
  
         if [[ $lg_continue -eq 1 ]]
         then
            continue
         fi 
         if [[ $machine == "leonardo" ]]
         then
            script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/CINECA/${headerext}_${yyyy}${st}_${ens}.sh 
         else
            script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/${headerext}_${yyyy}${st}_${ens}.sh 
         fi
         submittable_cnt=$(( $submittable_cnt + 1 ))
         if [[ -f $script_to_submit ]] ; then
  
            restdirext=$SCRATCHDIR/restarts4extended/${SPSSystem}_${yyyy}${st}_${ens}
            if [[ ! -d $restdirext ]] || [[ `ls $restdirext/*|wc -l` -ne 295` ]]
            then
          
                echo ""
                echo "Restdir or rest files missing from caso ${SPSSystem}_${yyyy}${st}_${ens} in $restdirext ************** "
                echo "skip $caso                                  "
                echo ""
                cnt_rest=$(( $cnt_rest + 1 ))              
                listaskiprest+="$caso "
                continue
            fi
  
            echo "submit $script_to_submit"
            subm_cnt=$(( $subm_cnt + 1 ))

            # If here, all the conditions are satisfied, and the serial launcher can be submitted
            if [[ $machine == "leonardo" ]]
            then
               mkdir -p $SCRATCHDIR/cases_extended_${st}
               $script_to_submit >& $SCRATCHDIR/cases_extended_${st}/${headerext}_${yyyy}${st}_${ens}.log
            else
               $script_to_submit
            fi
            listacasi+="$caso "

            if [[ $subm_cnt -eq $tobesubmitted ]]
            then
               ylast=$yyyy
               break 4
            fi      
            # REDUNDANT but safe (check how many jobs are on parallel queue)
            # if $maxnumbertosubmit already running exit
            # this control does not count the cases still in the create_caso phase
            np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive.${SPSSystem}ext_ -c yes`
            if [[ $np_all -ge $maxnumbertosubmit ]]
            then
               ylast=$yyyy
               break 4
            fi

         fi
      done
   done
done

echo "For extended reforecast $st submitted $subm_cnt members"
echo "Submittable $submittable_cnt"
echo "skipped for no restart available $listaskiprest"
echo "already archived ($DIR_ARCHIVE) $cnt_archive "
echo "case already created $cnt_dircases "
echo "running $cnt_run "
body="Submitted $subm_cnt startdates \n
\n
${listacasi[@]} \n
\n
Climatological start-date: ${st} \n
\n
Cycled on: ${iniy_hind}-${ylast} \n
\n
Submittable $submittable_cnt \n
\n
skipped $listaskiprest \n
\n
archive $cnt_archive \n
\n
case running $cnt_run \n
\n
cases already created $cnt_dircases \n"
title="NEW November HINDCAST EXTENDED JOBS SUBMITTED on $machine"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 


