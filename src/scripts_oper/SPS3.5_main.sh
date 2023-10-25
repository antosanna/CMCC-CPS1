#!/bin/sh -l
#BSUB -q s_short
#BSUB -J SPS3.5_main_hc
#BSUB -e ../../logs/SPS3.5_main_hc%J.err
#BSUB -o ../../logs/SPS3.5_main_hc%J.out
#BSUB -sla SC_SERIAL_sps35 
#BSUB -app SERIAL_sps35 
#BSUB -P 0490 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_SPS35}/descr_hindcast.sh
#. ${DIR_TEMPL}/load_cdo
set -evx

np=`${DIR_SPS35}/findjobs.sh -m $machine -n ${SPSSYS}_main_hc -c yes`
if [ $np -gt 1 ]
then
   echo "there is one ${SPSSYS}_main_hc already running! Exiting now!"
fi
# Input **********************
stlist=$1
styr=1993
endyr=2016
maxnumbertosubmit=15    # this must be kept fixed. It is the max number of parallel jobs during forecast
np_all=`bjobs -w -sla ${slaID} | wc -l`
if [ $np_all -lt $maxnumbertosubmit ]
then
   echo "go on with hindcast submission"
   tobesubmitted=$(( $maxnumbertosubmit - ${np_all} + 1 ))
else
   echo "Exiting now! already $np_all job on parallel queue"
   exit
fi

# Main loop ******************
cnt_run=0
cnt_archive=0
cnt_data_archive=0
cnt_dircases=0
cnt_temp_archive=0
cnt_atmICfile=0
cnt_lndIC=0
cnt_nemoIC=0
cnt_iceIC=0
cnt_negicearea=0

cnt_fy=0
listacasi=()
listaskip=()

submittable_cnt=0
subm_cnt=0


for st in $stlist
do
   for yy in $(seq $styr $endyr)
   do
      echo "YEAR $yy *****************************"
       for n in {1..40}
       do
         flg_continue=0
         echo "n $n *****************************"
         ens=`printf '%.3d' $n`
         script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yy}${st}_scripts/${header}_${yy}${st}_${ens}.sh 
         submittable_cnt=$(( $submittable_cnt + 1 ))
         if [ -f $script_to_submit ] ; then
            # Check if belongs to NCEP Initial Condition (if 1 is NCEP statement )
            lndIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f18`
            atmIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f17`
            oceIC=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f19`
            # oceIC only digit
            oceICnum=$(echo $oceIC |  grep -o -E '[0-9]+' )
  
            lndICfiles="${IC_CLM_SPS_DIR}/${st}/land_clm45_forced_${lndIC}_analisi_1993_2015.*${yy}-${st}-01-00000.*"
            rtmICfile="${IC_CLM_SPS_DIR}/${st}/land_clm45_forced_${lndIC}_analisi_1993_2015.rtm.r.${yy}-${st}-01-00000.nc"
            clmICfile="${IC_CLM_SPS_DIR}/${st}/land_clm45_forced_${lndIC}_analisi_1993_2015.clm2.r.${yy}-${st}-01-00000.nc"
            atmICfile="${IC_CAM_SPS_DIR}/${st}/${SPSSYS}.cam.i.${yy}${st}.${atmIC}.nc"
            nemoICfile="${IC_NEMO_SPS_DIR}/${st}/${yy}${st}0100_R025_0${oceICnum}_restart_oce_modified.nc"
            iceICfile="${IC_NEMO_SPS_DIR}/${st}/ice_ic${yy}${st}_0${oceICnum}.nc"
  
            caso=${SPSsystem}_${yy}${st}_${ens}
  
            # is running?
            set +e
            np=`bjobs -w -sla ${slaID} | grep ${caso}_run | wc -l`
            ns=`bjobs -w -sla ${sla_serialID} | grep ${yy}${st}_${ens}_run | wc -l`
            set -e
  
            # if is running, skip
            if [ $np -gt 0 ] || [ $ns -gt 0 ] ; then
              echo "job running. skip"
              cnt_run=$(( $cnt_run + 1 )) 
              continue
            fi
  
            # if exist in $DIR_CASES, skip
            if [ -d $DIR_CASES/$caso ] ; then
              echo "$DIR_CASES/$caso exist. skip"  
              cnt_dircases=$(( $cnt_dircases + 1 ))            
              continue
            fi
            # if exist in $FINALARCHIVE, skip
            if [ -d $FINALARCHIVE/$caso ] ; then
              echo "$FINALARCHIVE/$caso exist. skip"  
              cnt_data_archive=$(( $cnt_data_archive + 1 ))            
              continue
            fi
#            # if exist in archive_tmp, skip
#            if [ -d $ARCHIVE/$caso ] ; then
#              echo "$ARCHIVE/$caso exist. skip"  
#              cnt_archive=$(( $cnt_archive + 1 ))            
#              continue
#            fi
            # if exist in temporary archive, skip
            if [ -d $DIR_ARCHIVE/$caso ] ; then
              echo "$DIR_ARCHIVE/$caso exist. skip"  
              cnt_temp_archive=$(( $cnt_temp_archive + 1 ))            
              continue
            fi 
  
            # if atmospheric IC condition not exist, skip
            if [ ! -f $atmICfile ] ; then
              if [ -f $atmICfile.gz ] ; then
                 gunzip -f $atmICfile.gz
              else
                 echo "atmICfile not exist. Trying on sp2 ************** "
                 atmICfilesp2="/work/csp/sp2/IC_CAM_${SPSSYS}/${st}/${SPSSYS}.cam.i.${yy}${st}.${atmIC}.nc"
                 if [ -f $atmICfilesp2 ]; then
                   rsync -auv --progress $atmICfilesp2 ${IC_CAM_SPS_DIR}/${st}/
                   if [ $? -ne 0 ]; then echo "$atmICfilesp2 rsync failed. skip" ; continue ; fi
                 else
                   echo "both $atmICfile and $atmICfilesp2 dont exist. skip" 
                   cnt_atmICfile=$(( $cnt_atmICfile + 1 ))              
                   listaskip+="$caso "
                   flg_continue=1
                 fi
             fi
           fi
  
            # if nemo oce IC condition not exist, skip
            if [ ! -f $nemoICfile ] ; then
              if [ -f $nemoICfile.gz ] ; then
                 gunzip -f $nemoICfile.gz
              else
                echo "nemoIC not exist. skip ************** "
                cnt_nemoIC=$(( $cnt_nemoIC + 1 ))              
                listaskip+="$caso "
                flg_continue=1
              fi
            fi
  
            # if ice oce IC condition not exist, skip
            if [ ! -f $iceICfile ] ; then
              if [ -f $iceICfile.gz ] ; then
                 gunzip -f $iceICfile.gz
              else
                echo "iceICfile not exist. skip ************** "
                cnt_iceIC=$(( $cnt_iceIC + 1 ))              
                listaskip+="$caso "
                flg_continue=1
              fi       
            fi       

            # if land IC condition not exist, skip
            if [ `ls $lndICfiles|wc -l` -ne 2 ] ; then
                echo "lndICfiles not exist. skip ************** "
                cnt_lndIC=$(( $cnt_lndIC + 1 ))              
                listaskip+="$caso "
                flg_continue=1
            else 
               if [ -f $rtmICfile.gz ] 
               then
                   gunzip -f $rtmICfile.gz
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
            $script_to_submit
            listacasi+="$caso "

            if [ $subm_cnt -eq $tobesubmitted ]
            then
              break 4
            fi      
            # REDUNDANT but safe (check how many jobs are on parallel queue)
            # if $maxnumbertosubmit already running exit
            # this control does not count the cases still in the create_caso phase
            np_all=`bjobs -w -sla ${slaID} | wc -l`
            if [ $np_all -ge $maxnumbertosubmit ]
            then
               break 4
            fi

  
        fi
      done
   done
done

echo "Submitted $subm_cnt members"
echo "Submittable $submittable_cnt"
totalskipped=$(( $cnt_run +  $cnt_archive + $cnt_data_archive + $cnt_dircases + $cnt_temp_archive + $cnt_atmICfile + $cnt_lndICfile + $cnt_iceICfile + $cnt_negicearea + $cnt_oceICfile + $cnt_fy  ))
echo "Total skipped $totalskipped"
echo "Land $cnt_lndICfile "
echo "Atm $cnt_atmICfile "
echo "Ocn $cnt_oceICfile "
echo "Ice $cnt_iceICfile "
echo "temporary archive ($DIR_ARCHIVE) $cnt_temp_archive "
#echo "archive_tmp ($ARCHIVE) $cnt_archive "
echo "negative ice area $cnt_negicearea "
echo "final archive ($FINALARCHIVE) $cnt_data_archive "
echo "case already created $cnt_dircases "
echo "running $cnt_run "
body="Submitted $subm_cnt startdates \n
\n
${listacasi[@]} \n
\n
Years in loop: ${styr}-${endyr} \n
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
OCE ice IC file missing $cnt_iceIC \n
\n
OCE nemo IC file missing $cnt_nemoIC \n
\n
temporary archive $cnt_temp_archive \n
\n
OCE ice IC has negative ice area $cnt_negicearea \n
\n
final archive ($FINALARCHIVE) $cnt_data_archive \n
\n
case running $cnt_run \n
\n
case already created $cnt_dircases \n
\n
archive_tmp $cnt_archive \n"
title="NEW HINDCAST JOBS SUBMITTED"
${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 


exit 0
