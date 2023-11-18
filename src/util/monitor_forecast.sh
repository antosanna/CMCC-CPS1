#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to monitor the progress of the operational forecast.
#
#-------------------------------------------------------------------------------
#set -x

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -u

#-- functions ------------------------------------------------------------------
function write_help
{
  echo "Use: monitor_forecast.sh [<yyyy>] [<st>] [<do plots:1=yes;0=no>]"
}

# Command line parameters
#start_date=$(date +"%Y%m")

if [ $# -eq 0 ] ; then # manage the case ./monitor_forecast -h
    write_help
    exit 1
fi
if [ "$1" == "-h" ] ; then # manage the case ./monitor_forecast -h
    write_help
    exit 1
fi

# if defined in input must be different from 0; otherwise automatically set to 0
# if 0 print all the members running/pending, otherwise only their number
txtfile=0

yyyy=$1
. $DIR_UTIL/descr_ensemble.sh $yyyy
st=$2
logfile=$DIR_LOG/$typeofrun/monitor_${typeofrun}.$yyyy$st.`date +%Y%m%d%M`.txt
#exec 3>&1 1>>${logfile} 2>&1
if [ $3 -eq 0 ]  ; then # manage the case ./monitor_forecast
    doplot=0
elif [ $3 -eq 1 ]  ; then # manage the case ./monitor_forecast 1
    doplot=1
fi

start_date=${yyyy}${st}
# `date +%Y%m`
last_date=`date -d "${start_date}01 + $nmonfore months" +%Y%m`

echo "Forecast start date: $start_date"
echo "Current system time : "$(date | cut -d \  -f 2-)
echo ""
echo ""

$DIR_UTIL/monitor_quota.sh $yyyy $st

#-- Main loop (ensamble mebers) ------------------------------------------------                                                                          
echo ""
#alljobsonqueue=`${DIR_UTIL}/findjobs.sh -m ${machine} -n ${SPSSystem}_${start_date} -N _run |awk '{print $7}'`
if [[ "$machine" == "marconi" ]] ; then
   alljobsonqueue=`${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} |awk '{print $2}' `
   #select job_name--->actually option not included in findjobs
elif [[ "$machine" == "zeus" ]] || [[ "$machine" == "juno" ]]; then
   alljobsonqueue=`${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} |awk '{print $7}' `
   #select job_name--->actually option not included in findjobs
fi
nrun=`${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} -c yes ` 
all_start_date=$start_date

if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} -c yes ` -ne 0 ] 
then
   echo "Loop over all $nrun members on queue:"  
   printf "%-20s %-13s %-5s %-8s %-15s %-13s %-18s %-10s %-8s\n" "caso" "job_status" "N_done" "l_archive" "last_restart" "current_date" "starting_time" "Nvar_C3S[$nfieldsC3S]" "C3S ok"
   
   for member in $alljobsonqueue ; do
     caso=`echo $member |cut -d '.' -f2`
     ens=`echo $caso |cut -d '_' -f3|cut -c 2-3`
     ens3=`echo $caso |cut -d '_' -f3|cut -c 1-3`
   # Get job status (RUN, PEND, nil)
     job_status="nil"
     job_id=""
     string=`${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${caso}`
     if [ $? -eq 0 ] ; then
       #
       job_status=$(echo $string | awk '{print $3}' | tail -n 1)
       job_id=`${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${caso} -i yes`  
     fi
   
   # Number of successfully completed runs
   # check last available restart
     if [[ -d $DIR_ARCHIVE/$caso/rest ]] ; then 
       nrest=`ls -altr $DIR_ARCHIVE/$caso/rest| wc -l`
       if [[ $nrest -ne 0 ]]
       then
           cmm=`ls -tr $DIR_ARCHIVE/$caso/rest| tail -1|cut -d '-' -f 2`
           if [[ $((10#$cmm)) -gt $((10#$st)) ]]
           then
               nlogs=$(($((10#$cmm)) - $((10#$st))))
           else
               nlogs=$((12+$((10#$cmm)) - $((10#$st))))
           fi
       fi
     else
       nlogs=0
     fi
   # Number of .nc files produced for C3S (single members)
     C3S_ok="NONE"
     if [ -d ${WORK_C3S}/$start_date ]
     then
        nC3S=$(ls -1 ${WORK_C3S}/$start_date/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100_*r${ens}i00p00.nc 2>/dev/null | wc -l)
        if [ $nC3S -eq $nfieldsC3S ]
        then 
            if [ `ls ${WORK_C3S}/$start_date/meta_checker_ok_* | wc -l` -eq $nfieldsC3S ] && [ `ls ${WORK_C3S}/$start_date/qa_checker_ok_* | wc -l` -eq $nfieldsC3S ] && [ `ls ${WORK_C3S}/$start_date/tmpl_checker_ok_0*|wc -l` -eq $nfieldsC3S ]
            then
               C3S_ok=1
            fi
        else
           C3S_ok=0
        fi
     else
        nC3S=0
     fi
     
   # Start of execution of current month (if available)
     begin_time="------"

     if [[ "$job_status" == *"RUN"* ]]; then
        begin_time=`grep "case.run starting $job_id"  $DIR_CASES/$caso/CaseStatus|awk {'print $2'}|cut -c 1-8`
     fi


   
   # starting date of the actual run YYYYMMDD (presently not used)
     cyyyystdd=""
     if [[ "$job_status" == *"RUN"* ]]; then
       file=`ls $WORK_CPS/${caso}/run/namelist_cfg`
       cyyyystdd=$(grep ^nn_date0 $file | awk '{print $3}')
     fi
   
   # Last day processed (with YYYYMM)
     cdate="--------"
     if [[ "$job_status" == *"RUN"* ]]; then
       if [ `ls $WORK_CPS/${caso}/run/rof.log* | wc -l ` -ne 0 ]
       then
          file=`ls $WORK_CPS/${caso}/run/rof.log* |tail -n 1`
          cdate=$(grep "model date is" $file | awk '{print $5}' |tail -n 1)
       fi
     fi
   
   # Get last restart file
     last_rest=""
     if [[ -d $WORK_CPS/archive/${caso}/rest ]] ; then
        nfile=`ls $WORK_CPS/archive/${caso}/rest |wc -l`
        if [[ $nfile -ne 0 ]] ; then
           file=`ls $WORK_CPS/archive/${caso}/rest`
           last_rest=$(echo $file | tail -n 1 | awk '{print substr($1,1,4) substr($1,6,2)}')
        fi
     fi
   
   # Output to screen
     if [ -z $last_rest ] ; then
       lastc="------"
     else
       lastc=$last_rest
     fi
   
     if [ -z $cdate ] ; then
       str_cdate="--------"
     else
       str_cdate=$cdate
     fi
   
     if [ $nlogs -eq 0 ]
     then
       lastc='IC'
     fi
     if [ $nlogs -eq $nmonfore ]
     then
       job_status="DONE"
     fi
   
   # Postprocessing 
     #MB/AB 2/7---> is this final postpc (i.e. postpc_clm)? or also the l_archive (job_name=$caso.postpc) ?
     #${id}  is not defined...is it the member tag? in this case ens3 has been defined as the full (3digits) member tag.

     postpc_string=`${DIR_UTIL}/findjobs.sh -m ${machine} -N lt_archive.${SPSSystem}_${start_date}_${ens3}`
     if [ $? -eq 0 ] ; then
       postpc=`${DIR_UTIL}/findjobs.sh -m ${machine} -N lt_archive.${SPSSystem}_${start_date}_${ens3} -i yes`
       postpc_nr=`${DIR_UTIL}/findjobs.sh -m ${machine} -N lt_archive.${SPSSystem}_${start_date}_${ens3} -c yes`
       if [ $postpc_nr -gt 1 ]; then
         postpc=$postpc_nr
       fi
     else
       postpc="------"
     fi
     #TEMPORARY
     postpc="------"
     #echo $id" # "$job_status" # "$nlogs" # "$postpc" # "$lastc" # "$str_cdate" # "$begin_time" # "$nC3S" ("$nC3S_tmp")"
   printf "%-20s %-13s %-5s %-8s %-15s %-13s %-18s %-10s %-8s\n" $caso $job_status $nlogs $postpc $lastc $str_cdate "$begin_time" $nC3S $C3S_ok
   
   
   done
fi

#-------------------------------------------------------------------------------
# Total jobs running3S
if [ `${DIR_UTIL}/findjobs.sh -m ${machine} -N ${SPSSystem}_${start_date} -c yes` -ne 0 ] 
then
   echo ""
   echo "TOTAL FORECASTS ON QUEUE PARALLEL: "`${DIR_UTIL}/findjobs.sh -m ${machine} -N run.${SPSSystem}_${start_date} -c yes`
   echo ""
   echo "TOTAL FORECASTS RUNNING:           "`${DIR_UTIL}/findjobs.sh  -m ${machine} -N run.${SPSSystem}_${start_date} -a $BATCHRUN -c yes`
   if [[ $txtfile -eq 0 ]]
   then
       echo `${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} -a $BATCHRUN -J yes `
   fi
   echo ""
   echo "TOTAL FORECASTS PENDING:           "`${DIR_UTIL}/findjobs.sh -m ${machine} -N run.${SPSSystem}_${start_date} -a PEND -c yes`
   if [[ $txtfile -eq 0 ]]
   then
         echo `${DIR_UTIL}/findjobs.sh -m ${machine} -n run.${SPSSystem}_${start_date} -a PEND -J yes `
   fi
else
   echo ""
   echo "***************************************************************************"
   echo "ALL THE FORECASTS ON PARALLEL QUEUE FOR START-DATE ${start_date}: COMPLETED"
   echo "***************************************************************************"
fi
   

#-- C3S outputs ----------------------------------------------------------------
allst=`echo ${all_start_date}| tr ' ' '\n' |sort -u`
for start_date in $allst
do
   yyyy=`echo $start_date|cut -c 1-4`
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   mkdir -p $DIR_LOG/$typeofrun/$start_date
   if [ $doplot -eq 1 ]
   then
      echo "plot nemo and SIE timeseries for $start_date"
      
      $DIR_DIAG/sst_sss_global.sh `echo $start_date|cut -c 1-4` `echo $start_date|cut -c 5-6` >& $DIR_LOG/$typeofrun/$start_date/sst_sss_global_`date +%Y%m%d%H` &
      if [[ "$machine" == "zeus" ]]
      then
         $DIR_DIAG/compute_SIE_cice.sh `echo $start_date|cut -c 1-4` `echo $start_date|cut -c 5-6` >& $DIR_LOG/$typeofrun/$start_date/sie_`echo $start_date|cut -c 1-4``echo $start_date|cut -c 5-6`_`date +%Y%m%d%H`
      elif [[ "$machine" == "marconi" ]]
      then
         echo "..SIE PLOT TO BE ADDED SOON"
      fi
   fi
# postproc done
   echo ""
   echo "C3S standardization completed for: "
# Find which parameter is presently being processsed
   if [ -d $WORK_C3S/${start_date} ]
   then
      nfiles=$(ls $WORK_C3S/${start_date}/*clm*DONE 2>/dev/null |wc -l )
      if [ $nfiles -eq 0 ] ; then
        cvar="-"
        echo "---- CLM C3S files               :" $nfiles
      else
        cvar=""
        echo "---- CLM C3S files               :" $nfiles
      fi
      nfiles=$(ls $WORK_C3S/${start_date}/*cam*DONE 2>/dev/null |wc -l )
      if [ $nfiles -eq 0 ] ; then
        cvar="-"
        echo "---- CAM C3S files               :" $nfiles
      else
        cvar=""
        echo "---- CAM C3S files               :" $nfiles
      fi
   fi
   echo ""
   echo "Dissemination of C3S outputs for $start_date (expected files at least: $(($nfieldsC3S * $nrunC3Sfore)))"
# Find which parameter is presently being processsed
   if [ -d $WORK_C3S/${start_date} ]
   then
      files=$(ls $WORK_C3S/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100*.nc 2>/dev/null)
      nfiles=$(ls $WORK_C3S/${start_date}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100*.nc 2>/dev/null | wc -l )
      if [ $nfiles -eq 0 ] ; then
        cvar="-"
        echo "Now ready files               :" $nfiles
      else
        cvar=""
        for file in $files
        do
           cvar+=" $(basename $file | cut -d _ -f 8-9| cut -d '.' -f1)"
        done
        echo "Now ready files               :" $nfiles
      fi
   fi
# Count files ready for transfer to ECMWF
   npush=$(ls -1 ${pushdir}/$start_date/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${start_date}0100*.* 2>/dev/null | wc -l)
   echo "Files ready for transfer (expected $((($nfieldsC3S - $natm3d + $nchunks * $natm3d) * 2 )) + Manifest): "$npush

done
