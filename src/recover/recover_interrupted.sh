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

##########################################################################################################################
### THE SCRIPT IS NOT EXAUSTIVE!!! 
#
#   In case of interruption during st_archive, this procedure will recognize the case as interrupted
#   runtime. As a result, it can happen that the case of interest will run 7 months.
#   In this case the C3S postprocessing has to be run offline, because the number of output will be greater than expected
#   and check_6months_output_in_archive.sh will raise an error
#
##########################################################################################################################

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

debug=1  #set to 2 the first time you run in order to print only the list of interrupted 
         #set to 1 the second time you run in order to process only one case for category
         #set to 0 to run all interrupted identified


set +euvx
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx

if [[ $# -eq 0 ]]
then
  LOG_FILE=$DIR_LOG/$typeofrun/recover_interrupted_debug${debug}_`date +%Y%m%d%H%M`
  exec 3>&1 1>>${LOG_FILE} 2>&1
fi

cd $DIR_CASES/

#listofcases="sps4_200607_024 sps4_200607_025 sps4_200607_026 sps4_200607_030 sps4_200707_004 sps4_200707_006 sps4_200707_007" 
listofcases=sps4_200807_014

if [[ $# -ge 1 ]]
then
   debug=${1}
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx
fi
if [[ $# -ge 2 ]]
then
   st=${2:-$mo_today}
   if [[ `echo -n $st|wc -c` -ne 2 ]]
   then
      echo "second input should be st 2 digits"
      exit
   fi
   listofcases=`ls -d ${SPSSystem}_????${st}_0??`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx
fi
if [[ $# -ge 3 ]]
then
   yyyy=${3:-$yy_today}
   if [[ `echo -n $yyyy|wc -c` -ne 4 ]]
   then
      echo "third input should be yyyy 4 digits"
      exit
   fi
   listofcases=`ls -d ${SPSSystem}_${yyyy}${st}_0??`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
fi
if [[ `echo -n $debug|wc -c` -ne 1 ]]
then
   echo "first input should be debug=0/1/2"
   exit
fi
#now the script runs from crontab with submitcommand.sh
echo "SPANNING $listofcases"


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


filecsv=$DIR_LOG/$typeofrun/${SPSSystem}_${typeofrun}_recover${debug}_list.${machine}.`date +%Y%m%d%H`.csv
filexls=`echo ${filecsv}|rev |cut -d '.' -f2-|rev`.xlsx
echo "first month,resubmit,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
### INITIALIZE LISTS
lista_lt_archive=" "    
lista_resubmit=" "
lista_pp_C3S=" "
lista_moredays=" "
lista_first_month=" "

lista_caso_ignored="sps4_199711_011 sps4_200207_020 sps4_199910_025"  
#sps4_199711_011 (zeus) - unstability in NEMO - to be checked 
#sps4_200207_020 (juno) - NaN in field Sl_t
#sps4_199910_025 (zeus) - h2osoi_ice sign negative

cd $DIR_CASES/
for caso in $listofcases ; do
  if [[ $lista_caso_ignored == *"$caso"* ]] ; then
     continue  
  fi
  st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
  yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
  member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
 
  CASEROOT=$DIR_CASES/$caso/
  outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
  set +uevx
  . $dictionary
  set -euvx

# check if directory is writable (we remove  writing permission after postproc_C3S)
# this reduce the list to be checked on Juno
  iscompleted=`ls -altr $DIR_ARCHIVE1|grep $caso|cut -c 3`
  if [[ $iscompleted == "-" ]]
  then
     echo "skip this $caso because completed"
     continue
  fi
### check that case is not running, if running skip
  echo "starting findjobs "`date`
  ns=`${DIR_UTIL}/findjobs.sh -m $machine -n ${caso} -c yes`
  echo "end of findjobs "`date`
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
  else
     # THIS SECTION MUST BE RUN ONLY ON JUNO BECAUSE C3S ARE PRODUCED ONLY THERE\# FOR A MATTER OF CONSISTENCY
     if [[ $machine == "juno" ]]
     then
        # meaning that the 185 day-run has been completed but last pp (C3S regrid) has not.
        if [[ ! -f $check_pp_C3S ]] 
        then
           cnt_pp_C3S=$(($cnt_pp_C3S + 1))
           lista_pp_C3S+=" $caso"
        else
            if [[ ! -f $check_postclm ]] || [[ ! -f $check_all_camC3S_done ]] || [[ ! -f $check_iceregrid ]] || [[ ! -f $check_oceregrid ]] 
            then
              cnt_pp_C3S=$(($cnt_pp_C3S + 1))
              lista_pp_C3S+=" $caso"
              if  [[ ! -f $check_oceregrid ]] 
              then 
                  cnt_regrid_oce=$(($cnt_regrid_oce + 1))
              elif [[ ! -f $check_iceregrid ]] 
              then
                 cnt_regrid_ice=$(($cnt_regrid_ice + 1))
              fi
            fi
        fi
     fi #juno
  fi #if moredays
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
   echo ""
   echo "$lista_moredays"
   for caso in $lista_moredays
   do
#echo "first month,resubmit,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
      echo "-,-,$caso,- " >> $filecsv
   done
fi
if [[ "$lista_resubmit" != " " ]]
then
   echo "---- From the above RECOVER_LIST, $cnt_resubmit cases to be resubmitted "
   echo "$lista_resubmit"
   echo ""
   for caso in $lista_resubmit
   do
#echo "first month,resubmit,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
      echo "-,$caso,-,- " >> $filecsv
   done
fi
if [[ "$lista_first_month" != " " ]]
then
   echo "Cases interrupted during first month"
   echo "$lista_first_month" 
   echo ""
   for caso in $lista_first_month
   do
#echo "first month,resubmit,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
      echo "$caso,-,-,- " >> $filecsv
   done
fi
if [[ "$lista_pp_C3S" != " " ]]
then
   lista_pp_C3S=$(echo $lista_pp_C3S | tr ' ' '\n' | sort -u)
   echo "Cases with interrupted postproc_C3S.sh"
   echo "$lista_pp_C3S" 
   echo ""
   for caso in $lista_pp_C3S
   do
#echo "first month,resubmit,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
      echo "-,-,-,$caso " >> $filecsv
   done
fi


echo "starting conversion with python "`date`
#if [[ $machine != "zeus" ]]
#then
   set +euvx
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondarclone
   set -euvx
   python $DIR_UTIL/convert_csv2xls.py ${filecsv} ${filexls}
   rclone copy ${filexls} my_drive:recover
   set +euvx
   condafunction deactivate $envcondarclone
   set -euvx
#fi
echo "end of conversion with python "`date`

if [[ $debug -eq 2 ]]
then
   echo "DEBUG=2: NO ACTION REQUIRED, JUST LISTING OF INTERRUPTED JOBS"
fi

### REMEMBER: if debug=1 only 1 case for category will be processed and you could check that everything was ok.

if [[ $debug -ne 2 ]] ; then
    
   echo "NOW PROCESSING THE INTERRUPTED CASES"
set +euv
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondacm3
set -euvx
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
      member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`

      CASEROOT=$DIR_CASES/$caso/
      outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
      set +uevx
      . $dictionary
      set -euvx
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
      member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
 
      CASEROOT=$DIR_CASES/$caso/
      outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
      set +uevx
      . $dictionary
      set -euvx
      cd ${DIR_CASES}/$caso
      command="case.submit"
      echo $command
      ./$command
      echo "$command done"

      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
   
# resubmit lt_archive_moredays
   if [[ $cnt_pp_C3S -ne 0 ]] ; then
      echo "RESUBMIT .case.lt_archive_moredays FOR THE FOLLOWING CASES"
      echo "$lista_pp_C3S"
      echo ""
      if [[ $cnt_regrid_ice -ne 0 ]] ; then
         echo "$cnt_regrid_ice cases for failure in interp_cice"
         echo ""
      fi
   
      if [[ $cnt_regrid_oce -ne 0 ]] ; then
         echo "$cnt_regrid_oce cases for failure in interp_ORCA"
         echo ""
      fi
   fi
   
   for caso in $lista_pp_C3S
   do
      $DIR_RECOVER/refresh_all_scripts.sh $caso
      cd $DIR_CASES/$caso
      bsub -W 06:00 -q s_medium -P 0490 -M 25000 -e logs/lt_archive_moredays_%J.err -o logs/lt_archive_moredays_%J.out   < .case.lt_archive_moredays 
      if [[ $debug -eq 1 ]] ; then break ; fi
   done
   
   
fi   
#TEMPORARY DISABLED
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
