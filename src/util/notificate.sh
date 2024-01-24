#!/bin/sh -l
#-------------------------------------------------------------------------------
# Script to notificate nicely forecast update
#
#                                               Version 1.0.0, Antonio 07/07/2019
#												                                   Version 2.0.0, Andrea  27/11/2020
#												                                   Version 3., Antonella  3/4/2021
#-------------------------------------------------------------------------------
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 2023

set -euvx

echo 'not yet modified'
exit
#-- parameters -----------------------------------------------------------------

icline=""

set +uevx
#-- functions ------------------------------------------------------------------
function write_help
{
  echo "Use: notificate.sh <operating user> <notification_type> <yyyy> <mm> <sleeptime> <progr. title number> "
  echo "     notification_type=1 to print Initial Condition updates, otherwise 0"
}

#-------------------------------------------------------------------------------
# Command line input parameters
#-------------------------------------------------------------------------------
# 1. user (sp1 etc.)
if [[ "$1" == "-h" ]] ; then
    write_help
    exit 1
else
   operator=$1
fi
# 2. pass the notification type 1 (ICs), 0 (others)
notif_type=$2
# 3. year
yyyy=$3 
# 4. month
st=$4   
startdate="${yyyy}${st}"
# 5. sleep time (wait N sec before notificating)
sl_time=$5
# 6. progressive number (for email title)
prog_count=$6
debug=${7:-0}
if [[ $debug -eq 1 ]]
then
   mymail=antonella.sanna@cmcc.it
   ccmail=$mymail
fi


# First of all sleep
date
sleep $sl_time


# Path
wrkdir=$WORK_C3S/${startdate}
arcdir=$FINALARCHC3S/${SPSSystem}_${startdate}

# last date
last_date=$(date -d "${startdate}01+$((${nmonfore} - 1)) month" +%Y%m)

#-------------------------------------------------------------------------------
#-- Initialization 
#-------------------------------------------------------------------------------
set +eu
. $DIR_UTIL/monitor_quota_op.sh
set -eu
echo " operator $operator "
echo "Forecast start date: "$startdate"01"
echo "Last forecast month: "$last_date
echo "Current system time : "$(date | cut -d \  -f 2-5)

#-------------------------------------------------------------------------------
#-- Main loop (ensamble mebers)
#-------------------------------------------------------------------------------                                                                         
# stats collectors
PostpcRun=""
JobsStatus=""
C3S_files=""
CompletedMonths=""

countrun=0
countdone=0
flagpostpc=0

for member in $(seq -w 01 $nrunmax) ; do
  ens=$(printf "%03d" ${member#0})

  # Get job status (RUN, PEND, SUBM, nil, DONE)
  job_run=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_${startdate}_${ens} -c yes`
  if [[ $job_run -ne 0 ]] ; then
set +e
     job_status=`$DIR_UTIL/findjobs.sh -m $machine -n run.${SPSSystem}_${startdate}_${ens} -q $parallelq_l`
set -e
# this holds for Zeus (RUN) and Marconi (RUNNING)
     if [[ "$job_status" =~ "RUN" ]]
     then
        job_status="RUN"
     elif [[ "$job_status" =~ "PEND" ]]
# this holds for Zeus (PEND) and Marconi (PENDING)
     then
        job_status="PEND"
     fi
  else
     job_status="nil"
  fi

  # Number of logfiles
  nlogs="undef"
  nlogs=$(ls -1 ${DIR_ARCHIVE}/${SPSSystem}_${startdate}_${ens}/logs/cpl.log*gz 2>/dev/null | wc -l)
  if [[ $nlogs -ge $nmonfore ]]
    then
    job_status="DONE"
  fi

  # Number of .nc files produced for C3S (single members)
  nC3S="undef"
  if [[ -d ${wrkdir} ]]
  then
     nC3S=$(ls -1 ${wrkdir}/cmcc_${GCM_name}-v${versionSPS}_${typeofrun}_S${startdate}0100_*r${member}i00p00.nc 2>/dev/null | wc -l)
  else
     nC3S=0
  fi
  
 
  # Postprocessing
  npostpc_run=`$DIR_UTIL/findjobs.sh -m $machine -n lt_archive -N ${SPSSystem}_${startdate}_${ens} -c yes`
  postpc="undef"
  if [[ $npostpc_run -ne 0 ]] ; then
set +e
    postpc=`$DIR_UTIL/findjobs.sh -m $machine -n lt_archive -N ${SPSSystem}_${startdate}_${ens}`
set -e
# this holds for Zeus (RUN) and Marconi (RUNNING)
    if [[ "$postpc" =~ "RUN" ]]
    then
        postpc="RUN"
    fi
  fi

  # fix nil
 if [[ $job_status == "nil" && $nlogs -gt 0 ]]
  then
    job_status="SUBM"
 fi

 if [[ $job_status == "nil" && $postpc == "RUN" ]]
  then
    job_status="SUBM"
 fi

  # Dictionary
  job_status_dict="undef"
  case $job_status in
       RUN) job_status_dict="members running on parallel queue" ;;
       PEND) job_status_dict="members PENDING" ;;
       SUBM) job_status_dict="members between one month and the following, waitng for next parallel process to be submitted" ;;
       DONE) job_status_dict="successfully completed and archived members" ;;
       nil) job_status_dict="not definite status members (probably in intramonth phase)" ;;
  esac

  nlogs_dict="undef"
  case $nlogs in
       0) nlogs_dict="still completing first month members" ;;
       1) nlogs_dict="members which completed the 1^ month" ;;
       2) nlogs_dict="members which completed the 2^ month" ;;
       3) nlogs_dict="members which completed the 3^ month" ;;
       4) nlogs_dict="members which completed the 4^ month" ;;
       5) nlogs_dict="members which completed the 5^ month" ;;
       6) nlogs_dict="members which completed the 6^ month" ;;
       7) nlogs_dict="members which completed the 7^ month" ;;
       undef) nlogs_dict="undef number of months completed by these members" ;;
  esac
  expectedC3Snumber=$(($nfieldsC3S * $nrunC3Sfore))
  case $nC3S in
       0) nC3S_tmp_dict=" members not yet ready for C3S files production [0/${nfieldsC3S}] " ;;
       $nfieldsC3S) nC3S_tmp_dict="members which already produced C3S files [${nfieldsC3S}/${nfieldsC3S}]" ;;
       *) nC3S_tmp_dict="members have produced until now a C3S file number of ${nC3S}/${nfieldsC3S}" ;;
  esac

  # save stats only for submitted 
  if [[ $job_status != "nil" ]]; then
    if [[ $JobsStatus == "" ]]
    then
       JobsStatus=("$job_status_dict")
    else
       JobsStatus+=("$job_status_dict")
    fi
    
    if [[ $C3S_files == "" ]]
    then
       C3S_files=("$nC3S_tmp_dict")
    else
       C3S_files+=("$nC3S_tmp_dict")
    fi
   
    # print only month status for running month
    if [[ $job_status != "DONE" ]]; then
      countrun=$((countrun+1))
      if [[ $CompletedMonths == "" ]]
      then
         CompletedMonths=("$nlogs_dict")
      else
         CompletedMonths+=("$nlogs_dict")
      fi
      # plot postpc info if at least one run is present
    
      if [[ $postpc =~ "RUN" ]]; then
        PostpcRun+=("members running intermonthly l_archive ")
        flagpostpc=1
      else 
        PostpcRun+=(" (the rest) not running l_archive")
      fi      
    fi
    # retrieve status for DONE
    if [[ $job_status == "DONE" ]]; then
      countdone=$(( $countdone + 1 ))
    fi

  fi

done
#-------------------------------------------------------------------------------
# GET monitor forecast
#-------------------------------------------------------------------------------
#set -evx
tstamp=`date "+%Y%m%d-%H%M%S"`
txtfile="monitorforecast_$tstamp.txt"
pdffile="monitorforecast_$tstamp.pdf"
mkdir -p $DIR_TEMP/$st

# $doplot can be 0=NoPlot or 1=Plot 
if [[ $notif_type -eq 0  ]] ; then
  doplot=1
  # Avoid plot of sst/sss for:
  #(i)   ICS and first notificate (after 1hr we don't have any files) 
  #(ii)  starting Tar&Push notification
  #(iii) complete forecast notification 
  if [[ $prog_count -eq 1 ]] || [[ $prog_count -eq 5 ]] || [[ $prog_count -eq 6 ]] ; then
    doplot=0
  fi  
else
  # for ICs avoid plot of sst/sss and SIE
  doplot=0
fi
# if an old $sstfile exists, remove it before calling monitor_forecast sp1 1
if [[ $doplot -eq 1 ]]; then
  mkdir -p $DIR_TEMP_NEMOPLOT/${startdate}/plots  
  sstfile=$DIR_TEMP_NEMOPLOT/${startdate}/plots/${CPSSYS}_${startdate}_nemo_timeseries.pdf
  if [[ -f $sstfile ]]; then
    rm $sstfile
  fi
  NH_SIEplot=$DIR_TEMP_CICEPLOT/NH/NH_SIE_${yyyy}${st}.png 
  if [[ -f $NH_SIEplot ]]
  then
     rm $NH_SIEplot
  fi
  SH_SIEplot=$DIR_TEMP_CICEPLOT/SH/SH_SIE_${yyyy}${st}.png 
  if [[ -f $SH_SIEplot ]]
  then
     rm $SH_SIEplot
  fi
fi
${DIR_UTIL}/monitor_forecast.sh $operator $doplot 1 $yyyy $st > $DIR_TEMP/$st/$txtfile

# lag needed to generate the sstplot
if [[ $doplot -eq 1 ]]; then
  sleep 360 #lag to needed to generate the sstplot
fi
# convert in pdf
convert -size 860x1200  -pointsize 10 $DIR_TEMP/$st/${txtfile} $DIR_TEMP/$st/$pdffile

#-------------------------------------------------------------------------------
# GET INFO
#-------------------------------------------------------------------------------
set -evx

# JOB STATUS
if [ `echo $JobsStatus |wc -l` -ne 0 ]
then
   jline=`(IFS=$'\n'; sort <<< "${JobsStatus[*]}") | uniq -c|  paste -s -d, -`
   if [[ $countdone -gt 50 ]] ; then
     jline="Run completed, post-processing now going on"
   else
     jline="Forecast running with: ${jline}."
   fi
fi

# COMP MONTHS
if [ `echo $CompletedMonths |wc -l` -ne 0 ]
then
   mline=`(IFS=$'\n'; sort <<< "${CompletedMonths[*]}") | uniq -c|  paste -s -d, -`
   if [[ $countdone -gt 50 ]] ; then
     mline="No month to be completed"
   else
     mline="With respect to the runs to be compelted, this is the update: ${mline}."
   fi
fi

# POSTPC
echo $flagpostpc
if [[ $flagpostpc -eq 1 ]]; then 
  pline=`(IFS=$'\n'; sort <<< "${PostpcRun[*]}")     | uniq -c|  paste -s -d, -`
  pline="Of all of the members,${pline}."
else
  pline="None l_archive running" 
fi
# C3S
if [ `echo ${C3S_files} |wc -l` -ne 0 ]
then
   c3sline=`(IFS=$'\n'; sort <<< "${C3S_files[*]}")     | uniq -c|  paste -s -d, -`
   c3sline="On C3S file postprocessing,${c3sline}."
fi
# QUOTA
quotewline="work: $quotaworkper"
quotehline="home: $quotahomeper"

# INTIAL CONDITION (as for checkIC)
if [[ $notif_type -eq 1 ]] ; then
  # 1a) - read ICs produced from ATM @ 00 & 12 (stable ones)
  nicatm=`ls -1 $IC_CAM_SPS_DIR/$st/*${yyyy}${st}*.nc | grep -v bkup | wc -l `
  # 2a) - read ICs produced from LND 
  niclnd=`ls -1 $IC_CLM_SPS_DIR/$st/*clm2.r.${yyyy}-${st}* | wc -l`
  echo $niclnd
  # 3a) - read ICs produced from OCE
  nicoce=`ls -1 $IC_NEMO_SPS_DIR/$st/${yyyy}${st}0100_* | wc -l` 
  # read if in the  new atmospheric log file ther is a backup (gt 10 ie 11,12)
  # We are after checkIC
  totnic=$((${nicoce} * ${niclnd} * ${nicatm}))
  icline="Possible ICS combinations are $totnic: $nicoce nemo ICs, $niclnd clm ICs and ${nicatm} cam ICs."
fi

#-------------------------------------------------------------------------------
# Manage sst/sss plot
#-------------------------------------------------------------------------------
if [[ ${doplot} -eq 1 ]]; then
  sst_ok=0
  cntnemotsfile=0
  cntnemotsfile=$(ls -1 $sstfile | wc -l)
  if [[ ${cntnemotsfile} -eq 1 ]]; then
    sst_ok=1
  fi
else
  # avoid undefined var
  sst_ok=0
fi
#---------------------------------------
# Manage SIE plot
#---------------------------------------
#get check_SIEplot from dictionary
set +uevx
. $dictionary      #fixed
set -uevx
#-------------------------------------------------------------------------------
# PREPARE EMAIL
#-------------------------------------------------------------------------------
title="${CPSSYS} forecast $startdate - STATUS UPDATE (${prog_count} of $n_notif)"
# compose your message in case of notificate 5 from tar_and_push
if [[ ${notif_type} -eq 0 ]] ; then
  # All run are completed. We are interested only about POSTPC-STATUS
  if [[ ${prog_count} -eq 4 ]] ; then
    title+=" - END OF 50 PARALLEL JOBS"
  fi
  # TARANDPUSH
  if [[ ${prog_count} -eq 5 ]] ; then
    title+=" - END OF POST-PROCESSING"
  fi
  # PUSH4ECMWF
  if [[ ${prog_count} -eq 6 ]] ; then
    title="${CPSSYS} forecast $startdate - END OF FORECAST"
  fi  
fi

if [[ ${notif_type} -eq 1 ]] ; then
  # ICs
  title="${CPSSYS} forecast $startdate - FORECAST STARTING NOW"
fi

# Intro (if ${sst_ok} == 1 then add text to manage sst and sss)
#ICs
#introic="Ciao Silvio e Stefano, \n  \nvi confermiamo la partenza del forecast con startdate $startdate. Di seguito trovate una sintesi delle condizioni iniziali utilizzate e in allegato le anomalie di temperatura relative ai nove membri delle IC di nemo e quelle osservate (snapshot della start-date, ultima settimana e ultimo mese).\n"

introic="Dear Silvio and Stefano, \n  \nthis is to confirm that the forecast with start-date $startdate has started. IN the following you will find a summary of the ICs used and, attached, the SST anomalies of the 9 Nemo IC perturbations together with the observed ones (start-date snapshot, last week, last month).\n"

#GENERAL intro 
intro="Dear Silvio and Stefano, \n  \nin the following a summary of the ${CPSSYS} forecast status. \nAttached the progress status of each member"
if [[ ${sst_ok} -eq 1 ]]; then
  intro+=" together with the plots of globam mean SST and SSS and sea-ice extent for the available members"
fi
intro+=".\n"

#GENERAL intro but with all members submitted
intro_slot="Dear Silvio and Stefano, \n  \n here below you will find a summary of the ${CPSSYS} forecast progress. We confirm the succesful submission of the ${nrunmax} members. Attached, detailed progress status of each member"
if [[ ${sst_ok} -eq 1 ]]; then
#  intro_slot+=" e i grafici delle sst e sss medie globali e la sea-ice extent per i membri disponibili"
  intro_slot+=" together with the plots of globam mean SST and SSS and sea-ice extent for the available members"
fi
intro_slot+=".\n"

# POSPTROC intro
#intro_not4="Ciao Silvio e Stefano, \n  \nvi confermiamo il completamento di tutti i ${nrunC3Sfore} membri. Al momento sta girando il postprocessing. In allegato maggiori dettagli"
intro_not4="Dear Silvio and Stefano, \n  \nthis is to notify the completion of all of the ${nrunC3Sfore} members. Presently the postprocessing is running. More details attached"
if [[ ${sst_ok} -eq 1 ]]; then
#  intro_not4+=" e i grafici delle sst e sss medie globali e la sea-ice extent per i membri disponibili" 
  intro_not4+=" together with the plots of globam mean SST and SSS and sea-ice extent for the available members"
fi
intro_not4+=".\n"

# TARANDPUSH intro
intro_not5="Dear Silvio and Stefano, \n  \nthis is to notify the completion of standardizing procedure for all of the ${nrunC3Sfore} members. Right now,tar_and_push proc (which compress the results and prepare them in the format requested) is running. Attached a brief summary.\n"
#intro_not5="Ciao Silvio e Stefano, \n  \nvi notifichiamo il completamento della procedura di standardizzazione su tutti i ${nrunC3Sfore} membri. Al momento sta girando il tar_and_push. In allegato una breve sintesi.\n"

# PUSH4ECMWF intro
#intro_not6="Cari Silvio e Stefano, \n  \nvi notifichiamo il completamento del forecast. L' invio dei dati a ECMWF e' stato avviato.\n"
intro_not6="Dear Silvio and Stefano, \n  \nthis is to notify the forecast completion. Push to ECMWF has been submitted.\n"

# IC
#icstatusline="\nSTATO DELLE CONDIZIONI INIZIALI\n${icline} \n "
icstatusline="\nINITIAL CONDITIONS STATUS\n${icline} \n "
# JOB STATUS
jobstatusline="\nJOBS STATUS\n${jline} \n "
# COMPLETED MONTHS
#compmonthsline="\nMESI COMPLETATI \n${mline} \n "
compmonthsline="\nCOMPLETED MONTHS \n${mline} \n "
# POST-PROC
ppc3sline="\nPOSTPROCESSING-C3S \n${c3sline} \n \n"

# OTHER
#postpcstatusline="\nSTATO DEI l_archvie (cambio di mese) \n${pline} \n "
postpcstatusline="\nl_archive STATUS (month is changing) \n${pline} \n "
queueline="\nQUOTA UPDATE ${operator} \nFinally, disk quota status: \n - ${quotewline} \n - ${quotehline}"
grazie="\n \nThanks \n \n${CPSSYS} staff"

#-------------------------------------------------------------------------------
# compose your message 
#-------------------------------------------------------------------------------
if [[ ${notif_type} -eq 1 ]] ; then
  # Just IC condition
  composedmessage=${introic}${icstatusline}${grazie}
fi

# compose your message in case of notif_type not equal to 1 (ICs)
if [[ ${notif_type} -eq 0 ]] ; then

  # Notificate job status
  if [[ ${prog_count} -lt 4 ]] ; then
    # Uniq Slot.
    if [[ ${countrun} -eq ${nrunmax} ]] && [[ ! -f $DIR_TEMP/$st/uniqslot.info ]] ; then
      composedmessage=${intro_slot}${jobstatusline}${compmonthsline}${grazie}
      # create file to avoid re-entering in this if condition
      touch $DIR_TEMP/$st/uniqslot.info
    else
      composedmessage=${intro}${jobstatusline}${compmonthsline}${grazie}
    fi

  fi

  # All run are completed. Notificate the postprocessing
  if [[ ${prog_count} -eq 4 ]] ; then
    composedmessage=${intro_not4}${ppc3sline}${grazie}
  fi

  # All run are completed. Notificate TAR-AND-PUSH
  if [[ ${prog_count} -eq 5 ]] ; then
    composedmessage=${intro_not5}${grazie}
  fi

  # TARANDPUSH completed. Notificate we are reasy to push
  if [[ ${prog_count} -eq 6 ]] ; then
    composedmessage=${intro_not6}${grazie}
  fi
fi

#-------------------------------------------------------------------------------
# GET orca images for IC option
#-------------------------------------------------------------------------------
if [[ ${notif_type} -eq 1 ]] ; then
  # Just IC condition
  norcafile=`ls -1 $DIR_TEMP/$st/${startdate}*_all_anom*|wc -l`
  if [[ $norcafile -ne 0 ]]
  then
     orcafile=`ls -1 $DIR_TEMP/$st/${startdate}*_all_anom*`
  fi
  orcapng=`basename $orcafile`
fi


#-------------------------------------------------------------------------------
# Produce new images for clim comparison from noaa only for IC
#-------------------------------------------------------------------------------
if [[ ${notif_type} -eq 1 ]] ; then
  # last date
  ymds=$(date -d "${startdate}01 -1 day" +%Y%m%d)
  graphdir=$DIR_TEMP/$st
  ncldir=${DIR_OCE_IC}
  ${DIR_OCE_IC}/calc_daily_anom.sh $ymds $graphdir $ncldir

  noaa_ok=0
  outname=${ymds}_tmp
  if [[ -f $DIR_TEMP/$st/${outname}.png ]] ; then
    echo "noaa procedure was ok"
#    tstamp=`date "+%Y%m%d-%H%M%S"`
    tstamp=`date "+%Y%m"`
    noaafile="noaa_anom_$tstamp.png"
    mv $DIR_TEMP/$st/${outname}.png $DIR_TEMP/$st/${noaafile}
    noaa_ok=1
  fi
fi


#-------------------------------------------------------------------------------
# SEND EMAIL with attachment
#-------------------------------------------------------------------------------
attachment=""
if [[ ${notif_type} -eq 1 ]] ; then
  # Just IC condition (no $DIR_TEMP/$st/$txtfile is needed )
  attachment="$DIR_TEMP/$st/$orcapng "
  if [[ ${noaa_ok} -eq 1 ]] ; then
    attachment+=" $DIR_TEMP/$st/$noaafile "
  fi
else

  if [[ $doplot -eq 1 ]]
  then
     attachment="$DIR_TEMP/$st/$pdffile  "
     if [[ ${sst_ok} -eq 1 ]]; then
      attachment+=" $sstfile  "
     fi # plot sst/sss
     if [[ -f $NH_SIEplot ]]; then
         attachment+=" $NH_SIEplot"
     fi #  plot sea-ice extent
     if [[ -f $SH_SIEplot ]]; then
         attachment+=" $SH_SIEplot"
     fi #  plot sea-ice extent

  fi # end doplot
fi # end $notif_type if statement

${DIR_UTIL}/sendmail.sh -m $machine -c $ccmail -e $mymail -M "$composedmessage" -t "$title" -a "$attachment" -r $typeofrun -s $yyyy$st


exit 0

