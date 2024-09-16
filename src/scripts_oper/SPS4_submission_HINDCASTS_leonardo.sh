#!/bin/sh -l
# load variables from descriptor
# TO BE REMOVED ONCE SPS4_submission_HINDCASTS.sh (MORE GENRAL) WILL BE TESTED FOR MARCH ON LEONARDO
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993

set -evx

LOG_FILE=$DIR_LOG/hindcast/SPS4_submission_hindcast.`date +%Y%m%d%H%M`.log
exec 3>&1 1>>${LOG_FILE} 2>&1

cnt_this_script_running=$(ps -u ${operational_user} -f |grep SPS4_submission_HINDCASTS_leonardo | grep -v $$|wc -l)
if [[ $cnt_this_script_running -gt 2 ]]
then
   echo "already running"
   exit
fi


conda activate $envcondacm3


# Input **********************
stlist=$1

#max number of ens member to be submitted per startdate
#to advance with the diagnostic it has been decided to run first
#a reduced ensemble over all the timeseries 
nmaxens=${2:-${nrunmax}}

#if by mistake the input is greater than $nrunmax (30) 
#nrunmax is restored
if [[ $nmaxens -gt ${nrunmax} ]] ; then
   nmaxens=${nrunmax}
fi

np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
if [ $np_all -lt $maxnumbertosubmit ]
then
   echo "go on with hindcast submission"
   tobesubmitted=$(( $maxnumbertosubmit - ${np_all} + 1 ))
else
   echo "Exiting now! already $np_all job on parallel queue"
   if [[ -f ${check_submission_running} ]] ; then
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
endyear=2013 #to allow for scenario up to the IC we have retrieved
for st in $stlist
do
   for yyyy in $(seq $iniy_hind $endyear)
   do
       if [[ $yyyy -eq 2014 ]]
       then
          continue
       fi
       echo "YEAR $yyyy *****************************"
       
       #check how many members done per year
       n_moredays_done=`ls $DIR_CASES/${SPSSystem}_${yyyy}${st}_???/logs/run_moredays_${SPSSystem}_${yyyy}${st}_0??_DONE |wc -l`
       if [[ ${n_moredays_done} -ge $nmaxens ]] ; then
          continue
       fi
       np_yyyyst=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_${yyyy}${st} -c yes`
       if [[ $((${n_moredays_done} + $np_yyyyst )) -ge $nmaxens ]] ; then
          continue
       fi
       
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
         script_to_submit=$DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts/CINECA/ensemble4_${yyyy}${st}_${ens}.sh 
         submittable_cnt=$(( $submittable_cnt + 1 ))
         if [ -f $script_to_submit ] ; then
            res1=`grep 'sed' ${script_to_submit} |cut -d '/' -f12`
            lndIC=`printf '%.2d' $res1`
            res2=`grep 'sed' ${script_to_submit} |cut -d '/' -f9`
            atmIC=`printf '%.2d' $res2`
            res3=`grep 'sed' ${script_to_submit} |cut -d '/' -f15`
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
            subm_cnt=$(( $subm_cnt + 1 ))

            # If here, all the conditions are satisfied, and the serial launcher can be submitted
            mkdir -p $SCRATCHDIR/cases_${st}
            $script_to_submit >& $SCRATCHDIR/cases_${st}/ensemble4_${yyyy}${st}_${ens}.log
            listacasi+="$caso "
            if [ $subm_cnt -eq $tobesubmitted ]
            then
               ylast=$yyyy
               break 4
            fi      
            # REDUNDANT but safe (check how many jobs are on parallel queue)
            # if $maxnumbertosubmit already running exit
            # this control does not count the cases still in the create_caso phase
            np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
            if [ $np_all -ge $maxnumbertosubmit ]
            then
               ylast=$yyyy
               break 4
            fi

         fi
      done
   done
done

echo "For climatological start-date $st submitted $subm_cnt members"
echo "Submittable $submittable_cnt"
totalskipIC=${listaskipCAM}" "${listaskipCICE}" "${listaskipNEMO}" "${listaskipCLM}
listaskip=${listaskipCAM}" "${listaskipCICE}" "${listaskipNEMO}" "${listaskipCLM}
cnt_skipIC=`echo $totalskipIC|wc -w`
totalskipped=$(( $cnt_run +  $cnt_archive + $cnt_data_archive + $cnt_dircases + $cnt_archive + $cnt_skipIC ))
echo "Total skipped $totalskipped"
echo "Land $cnt_lndICfile "
echo "Atm $cnt_atmICfile "
echo "Ocn $cnt_oceICfile "
echo "Ice $cnt_iceICfile "
echo "archive ($DIR_ARCHIVE) $cnt_archive "
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
title="NEW HINDCAST JOBS SUBMITTED on $machine"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 


exit 0
