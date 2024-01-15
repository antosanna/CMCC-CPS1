#!/bin/sh -l 
# REMEMBER TO UPDATE THE NAME OF LOGFILE!!!
# PART YOU SHOULD MODIFY: log file above
# start-month
# debug
# listacases
# JUST IN CASE listatoignore*

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

#######################################################################################################
### THE SCRIPT IS NOT EXAUSTIVE!!! 
#######################################################################################################

function write_help
{
  echo "Use: recover_interrupted.sh [<st>] [<yyyy>]"
  echo "     (if hindcast only st else also yyyy)"
}
#set -euxv
if [[ "$1" == "-h" ]]
then
   write_help
   exit
fi
set -euxv
mo_today=`date +%m`
yy_today=`date +%Y`

cd $DIR_CASES/

if [[ $# -eq 1 ]]
then
   st=${1:-$mo_today}
   yyyy=""
   listofcases=`ls -d ${SPSSystem}_????${st}_0??`
   . ${DIR_UTIL}/descr_ensemble.sh 1993
elif [[ $# -eq 2 ]]
then
   st=${1:-$mo_today}
   yyyy=${2:-$yy_today}
   listofcases=`ls -d ${SPSSystem}_${yyyy}${st}_0??`
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
fi

debug=0 #set to 2 the first time you run in order to print only the list of interrupted 
         #set to 1 the second time you run in order to process only one case for category
         #set to 0 to run all interrupted identified



LOG_FILE=$DIR_LOG/$typeofrun/recover_interrupted_debug${debug}_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

#st=03       #start month
#yyyy="2006" #set for selecting only 1 year, otherwise if the string is empty "" it will search in all years of $st




###LIST OF CASES YOU WANT TO PROCESS or PROCESS ENTIRE START-DATE
cd $DIR_CASES


### INITIALIZE COUNTER 

cnt_lt_archive=0         # CASES INTERRUPTED IN PROCESSING LT_ARCHIVE
cnt_resubmit=0    # CASES INTERPUTTED DURING MONTHLY RUNS
cnt_moredays=0    # CASES INTERPUTTED BEFORE RUNNING LAST FEW DAYS
cnt_regrid_ice=0    # CASES WITH MISSING REGRID_CICE
cnt_regrid_oce=0    # CASES WITH MISSING REGRID_ORCA
cnt_pp_C3S=0          # CASES WITH INTERRUPTED POSTPROC_C3S
cnt_first_month=0    #CASES INTERRUPTED DURING THE FIRST MONTH


### INITIALIZE LISTS
lista_lt_archive=" "    
lista_resubmit=" "
lista_regrid_ice=" "
lista_regrid_oce=" "
lista_pp_C3S=" "
lista_moredays=" "
lista_first_month=" "
#lista_pp_C3S_cam_or_clm=" "

listofcases="sps4_200211_016 sps4_200211_008"
caso_ignored="sps4_199711_011"  #unstability in NEMO - to be checked 
cd $DIR_CASES/
for caso in $listofcases ; do
  if [[ $caso == ${caso_ignored} ]] ; then
     continue  
  fi
  st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
  yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
  ens=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
 
  CASEROOT=$DIR_CASES/$caso/
  outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
  set +uevx
  . $dictionary
  set -eu

### check if there are dependency never satisfied to be killed
  set +e
  listajobs=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -i 'yes' `
  for proc in $listajobs ; do
      ndep=`${DIR_UTIL}/findjobs.sh -m $machine -p $proc`
      if [[ "$ndep" != "" ]] ; then
         ${DIR_UTIL}/killjobs.sh -m $machine -i $proc
         sleep 60
      fi
  done
  set -e
### check that case is not running, if running skip
  ns=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
  if [[ $ns -gt 0 ]]
  then
      continue
  fi
  echo ""
  echo "************$caso is not running"
  echo ""

### FROM HERE WE WANT TO DETECT WHERE THE CASE HAS BEEN INTERRUPTED
### query to the env_run to understand in which phase of the simulation the case is
### and check the presence of log files/checkfiles to see if the postprocessing and archiving routines have run

  cd $DIR_CASES/$caso/
   
#  num_months_done=`ls $DIR_CASES/$caso/logs/postproc_monthly_??????_done|wc -l`
  if [[ ! -f $check_run_moredays ]]
  then

     nmb_rest=`ls -d $DIR_ARCHIVE/$caso/rest/ |wc -l`
     if [[ ${nmb_rest} -eq 0 ]] ; then
        cnt_first_month=$(($cnt_first_month + 1))
        lista_first_month+=" $caso"
     else
        cnt_lt_archive=$(($cnt_lt_archive + 1))
        lista_lt_archive+=" $caso"
#get last restart directory month
        cmm=`ls -tr $DIR_ARCHIVE/$caso/rest| tail -1|cut -d '-' -f 2`
#compute num of months run nmonthsrun
        if [[ $((10#$cmm)) -gt $((10#$st)) ]]
        then
          nmonthsrun=$(($((10#$cmm)) - $((10#$st))))
        else
          nmonthsrun=$((12+$((10#$cmm)) - $((10#$st))))
        fi
# if not all of the $nmonfore have been done resubmit run.$caso
        if [[ $nmonthsrun -lt $nmonfore ]] 
        then
           cnt_resubmit=$(($cnt_resubmit + 1))
           lista_resubmit+=" $caso"
        else
           lista_moredays+=" $caso"
           cnt_moredays=$(($cnt_moredays + 1))
        fi
     fi
  fi
# aggiungere un check su nemo_rebuild e postproc_monthly prima di check_6month

  if [[ -f $check_6months_done ]] && [[ ! -f $check_iceregrid ]] 
  then
     cnt_regrid_ice=$(($cnt_regrid_ice + 1))
     lista_regrid_ice+=" $caso"
  fi
  if [[ -f $check_6months_done ]] && [[ ! -f $check_oceregrid ]] 
  then
     cnt_regrid_oce=$(($cnt_regrid_oce + 1))
     lista_regrid_oce+=" $caso"
  fi
     
# meaning that the 185 day-run has been completed but last pp (C3S regrid) has not.
  if [[ -f $check_run_moredays ]]
  then
     if [[ ! -f $check_pp_C3S ]] 
     then
        cnt_pp_C3S=$(($cnt_pp_C3S + 1))
        lista_pp_C3S+=" $caso"
     else
        if [[ ! -f $check_postclm ]] || [[ ! -f $check_all_camC3S_done ]]
        then
           cnt_pp_C3S=$(($cnt_pp_C3S + 1))
           lista_pp_C3S+=" $caso"
#           lista_pp_C3S_cam_or_clm+=" $caso"
         fi
     fi
  fi
#               checkin_qa=`ls $DIR_CASES/$caso/logs/qa_started_${yyyy}${st}_0${member}_ok | wc -l`
#               checkout_all=`ls $DIR_ARCHIVE/C3S/$yyyy$st/all_checkers_ok_0${member} | wc -l`
#               checkfile_daily=`ls $FINALARCHC3S/$yyyy$st/qa_checker_daily_ok_${member} | wc -l`
#               checkfile_mvcase=`ls $DIR_LOG/${typeofrun}/$yyyy$st/${caso}_DMO_arch_ok | wc -l`

done  


if [[ "$lista_lt_archive"  != " " ]]
then
   echo "RECOVER_LIST: list of cases with lt_archive to be resubmitted"
   echo "$lista_lt_archive"
   echo ""
   echo "---- From the above RECOVER_LIST, $cnt_moredays cases with run more days missing "
   echo "$lista_moredays"
   echo ""
fi
if [[ "$lista_resubmit" != " " ]]
then
   echo "---- From the above RECOVER_LIST, $cnt_resubmit cases to be resubmitted "
   echo "$lista_resubmit"
   echo ""
fi
if [[ "$lista_first_month" != " " ]]
then
   echo "Cases interrupted during first month"
   echo "$lista_first_month" 
   echo ""
fi
if [[ "$lista_regrid_ice" != " " ]]
then
   echo "Cases with missing regrid ice"
   echo "$lista_regrid_ice" 
   echo ""
fi
if [[ "$lista_regrid_oce" != " " ]]
then
   echo "Cases with missing regridoce"
   echo "$lista_regrid_oce" 
   echo ""
fi
if [[ "$lista_pp_C3S" != " " ]]
then
   echo "Cases with interrupted postproc_C3S.sh TEMPORARY DISABLED"
   echo "$lista_pp_C3S" 
   echo ""
#   echo " from which $lista_pp_C3S_cam_or_clm "
fi


if [[ $debug -eq 2 ]]
then
   echo "DEBUG=2: NO ACTION REQUIRED, JUST LISTING OF INTERRUPTED JOBS"
fi

### REMEMBER: if debug=1 only 1 case for category will be processed and you could check that everything was ok.

if [[ $debug -ne 2 ]] ; then
    
   echo "NOW PROCESSING THE INTERRUPTED CASES"
set +eu
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondacm3
set -eu
caso=""
# first month
   if [[ $cnt_first_month -ne 0 ]] ; then
      echo "RELAUNCH first month FOR CASES:"
      echo "$lista_first_month"
      echo ""
   fi
   for caso in $lista_first_month
   do
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
      yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
      ens=`echo $caso|cut -d '_' -f 3|cut -c 2-3`

      CASEROOT=$DIR_CASES/$caso/
      outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
      set +uevx
      . $dictionary
      set -eu
      cd ${DIR_CASES}/$caso
# workaround in order to keep the syntax highlights correct (case is a shell command)
      command="case.submit"
      echo $command
      ./$command
      echo "$command done"

      if [[ $debug -eq 1 ]] ; then break ; fi
   done
# lt_archive
   if [[ $cnt_moredays -ne 0 ]] ; then
      echo "RELAUNCH lt_archive to resubmit moredays FOR CASES:"
      echo "$lista_moredays"
      echo ""
   fi
   
   for caso in $lista_moredays 
   do
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      
      cd $DIR_CASES/$caso
      stopoption=`./xmlquery STOP_OPTION|cut -d '=' -f2|cut -d ' ' -f2||sed 's/ //'`
      resubmit=`./xmlquery RESUBMIT|cut -d '=' -f2|cut -d ' ' -f2||sed 's/ //'`
      if [[ $resubmit -eq 0 ]] && [[ $stopoption=="ndays" ]]
      then
         ./xmlchange STOP_OPTION=nmonths
      fi
      $DIR_RECOVER/recover_lt_archive.sh $caso
      
      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
# resubmit monthly run
   if [[ $cnt_resubmit -ne 0 ]] ; then
      echo "RESUBMIT FOLLOWING CASES FROM THEIR $DIR_CASES/CASO:"
      echo "$lista_resubmit"
      echo ""
   fi
   
   for caso in ${lista_resubmit}
   do 
      echo "going to relaunch case $caso"
      #to avoid refresh of templates while lt_archive is running from previous list (lista_resubmit is a subset of lista_lt_archive)
      #$DIR_RECOVER/refresh_all_scripts.sh $caso
      isrunning=`${DIR_UTIL}/findjobs.sh -m $machine -n lt_archive.${caso} -c yes`
      if [[ $isrunning -eq 0 ]]
      then
         $DIR_RECOVER/refresh_all_scripts.sh $caso
         $DIR_RECOVER/recover_lt_archive.sh $caso
      fi   
     
      st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
      yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
      ens=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
 
      CASEROOT=$DIR_CASES/$caso/
      outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
      set +uevx
      . $dictionary
      set -eu
      cd ${DIR_CASES}/$caso
      command="case.submit"
      echo $command
      ./$command
      echo "$command done"

      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
# resubmit interp_cice
   if [[ $cnt_regrid_ice -ne 0 ]] ; then
      echo "RESUBMIT interp_cice FOR THE FOLLOWING CASES"
      echo "$lista_regrid_ice"
      echo ""
   fi
   
   for caso in $lista_regrid_ice
   do
      isrunning=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
      if [[ $isrunning -ne 0 ]]
      then
         continue
      fi
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 4000 -j interp_cice2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_cice2C3S_${caso}.sh
      
      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
# resubmit interp_ORCA
   if [[ $cnt_regrid_oce -ne 0 ]] ; then
      echo "RESUBMIT interp_ORCA FOR THE FOLLOWING CASES"
      echo "$lista_regrid_oce"
      echo ""
   fi
   
   for caso in $lista_regrid_oce
   do
      isrunning=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
      if [[ $isrunning -ne 0 ]]
      then
         continue
      fi
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      $DIR_RECOVER/recover_6months_pp.sh $caso
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S qos_resv -M 8000 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh
      
      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
   
#TEMPORARY UNTIL WE FIX THE PYTHON ISSUE ON JUNO
exit
# resubmit lt_archive_moredays
   if [[ $cnt_pp_C3S -ne 0 ]] ; then
      echo "RESUBMIT .case.lt_archive_moredays FOR THE FOLLOWING CASES"
      echo "$lista_pp_C3S"
      echo ""
   fi
   
   for caso in $lista_pp_C3S
   do
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      cd $DIR_CASES/$caso
      bsub -W 06:00 -q s_medium -P 0490 -M 25000 -e logs/lt_archive_moredays_%J.err -o logs/lt_archive_moredays_%J.out   < .case.lt_archive_moredays 
      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
   
fi   
exit

if [[ $debug -eq 0 ]] ; then
  # third input optional: if present do not print the list of running/pending jobs
  doplot=1
  logfile=$DIR_LOG/$typeofrun/monitor_${typeofrun}.$st.`date +%Y%m%d%M`.txt
  ${DIR_UTIL}/monitor_forecast.sh $st $doplot > $logfile

  ## lag needed to generate the sstplot
  if [[ $doplot -eq 1 ]] ; then
    sleep 360 #lag to needed to generate the sstplot
  fi
  ## convert in pdf
  pdffile=`echo monitor_forecast_after_recover_${yyyy}${st}.$(date +%Y%m%d%H%M).txt|rev|cut -d '.' -f2-|rev`.pdf
  convert -size 860x1200  -pointsize 10 $SCRATCHDIR/$st/${txtfile} $SCRATCHDIR/$st/$pdffile
  attachment=$SCRATCHDIR/$st/$pdffile
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "Monitor forecast after recover attached" -t "${CPSSYS} notification" -a "$attachment"
fi
exit 0
