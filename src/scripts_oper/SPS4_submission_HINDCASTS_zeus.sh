#!/bin/sh -l
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
if [[ $machine == "zeus" ]]
then
#BSUB -q s_short
#BSUB -J SPS4_main_hc
#BSUB -e /work/csp/sps-dev/CPS/CMCC-CPS1/logs/hindcast/SPS4_main_hc%J.err
#BSUB -o /work/csp/sps-dev/CPS/CMCC-CPS1/logs/hindcast/SPS4_main_hc%J.out
#BSUB -P 0516 
#BSUB -M 1000
   :
elif [[ $machine == "juno" ]]
then
#BSUB -q s_short
#BSUB -J SPS4_main_hc
#BSUB -e /work/csp/cp1/CPS/CMCC-CPS1/logs/hindcast/SPS4_main_hc%J.err
#BSUB -o /work/csp/cp1/CPS/CMCC-CPS1/logs/hindcast/SPS4_main_hc%J.out
#BSUB -P 0516 
#BSUB -M 1000
   :
fi

set -evx

np=`${DIR_UTIL}/findjobs.sh -m $machine -n SPS4_main_hc -c yes`
if [ $np -gt 1 ]
then
   echo "there is one SPS4_main_hc already running! Exiting now!"
   exit
fi
# Input **********************
stlist=$1
np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
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
   for yyyy in $(seq $iniy_hind $endy_hind)
   do
      echo "YEAR $yyyy *****************************"
       for n in `seq 1 $nrunmax`
       do
         flg_continue=0
         echo "n $n *****************************"
         ens=`printf '%.3d' $n`
         script_to_submit=$DIR_SUBM_SCRIPTS/$st/${yyyy}${st}_scripts/${header}_${yyyy}${st}_${ens}.sh 
         submittable_cnt=$(( $submittable_cnt + 1 ))
         if [ -f $script_to_submit ] ; then
            res1=`grep submitcommand.sh ${script_to_submit} | cut -d ' ' -f18`
            lndIC=`printf '%.2d' $res1`
            res2=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f17`
            atmIC=`printf '%.2d' $res2`
            res3=`grep "submitcommand.sh" ${script_to_submit} | cut -d ' ' -f19`
            oceIC=`printf '%.2d' $res3`
            # oceIC only digit
  
            n_lndICfiles=`ls ${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.*.r.${yyyy}-${st}-01-00000.${lndIC}.nc| wc -l`
            clmICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.clm2.r.${yyyy}-${st}-01-00000.${lndIC}.nc
            rofICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.hydros.r.${yyyy}-${st}-01-00000.${lndIC}.nc
            atmICfile=${IC_CAM_CPS_DIR}/${st}/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.${atmIC}.nc
            nemoICfile=${IC_NEMO_CPS_DIR}/${st}/${CPSSYS}.nemo.r.${yyyy}-${st}-01-00000.${oceIC}.nc
            iceICfile=${IC_CICE_CPS_DIR}/${st}/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${oceIC}.nc
  
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
  
            # if exist in $DIR_CASES, skip
            if [ -d $DIR_CASES/$caso ] ; then
              echo "$DIR_CASES/$caso exist. skip"  
              cnt_dircases=$(( $cnt_dircases + 1 ))            
              continue
            fi
            # if exist in $FINALARCHIVE, skip
# NOT IMPLEMENTED YET
#            if [ -d $FINALARCHIVE/$caso ] ; then
#              echo "$FINALARCHIVE/$caso exist. skip"  
#              cnt_data_archive=$(( $cnt_data_archive + 1 ))            
#              continue
#            fi
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
                 echo ""
                 echo "CAM IC $atmICfile does not exist. ************** "
                 echo "skip $caso                                  "
                 echo ""
                 cnt_atmICfile=$(( $cnt_atmICfile + 1 ))              
                 listaskip+="$caso "
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
                 listaskip+="$caso "
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
                  listaskip+="$caso "
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
                listaskip+="$caso "
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
            $script_to_submit
            listacasi+="$caso "

            if [ $subm_cnt -eq $tobesubmitted ]
            then
              break 4
            fi      
            # REDUNDANT but safe (check how many jobs are on parallel queue)
            # if $maxnumbertosubmit already running exit
            # this control does not count the cases still in the create_caso phase
            np_all=`${DIR_UTIL}/findjobs.sh -m $machine -n run.${SPSSystem}_ -c yes`
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
Years in loop: ${iniy_hind}-${endy_hind} \n
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
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 


exit 0
