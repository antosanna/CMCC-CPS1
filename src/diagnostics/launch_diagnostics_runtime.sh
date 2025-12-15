#!/bin/sh -l
#WARNING!!! now the script can work only for leads because the pctl for monthly var new (t850, z500 and u-v200) have not been computed yet
#-------------------------------------------------------------------------------
# Script to submit (through crontab) run-time diagnostics on monthly fields:
# t2m, sst, mslp, precip, t850, z500
#
#-------------------------------------------------------------------------------
# CAVEAT
# Only one $DIR_DIAG/plot_forecast_all_vars.sh allowed at a time!

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
#-- parameters -----------------------------------------------------------------
set -euxv
dbg=1
# to run in dbg mode you must provide $WORK_CPS/archive/$caso/rest
# and $WORK_CPS/archive/$caso/atm/hist

today=`date +%d`
if [ `whoami` == "$operational_user" ] 
then
   dbg=0
fi

#-- Initialization -------------------------------------------------------------
start_date=`date +%Y%m`
st=`date +%m`
yyyy=`date +%Y`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euxv
LOG_FILE=$DIR_LOG/forecast/$yyyy$st/launch_diagnostics_runtime_`date +%Y%m%d%H%M`.out
exec 3>&1 1>>${LOG_FILE} 2>&1

checkfile1=$DIR_LOG/forecast/$start_date/first_month_diagnostics_${start_date}_DONE
checkfile2=$DIR_LOG/forecast/$start_date/lead0_diagnostics_${start_date}_DONE
checkfile3=$DIR_LOG/forecast/$start_date/lead1_diagnostics_${start_date}_DONE
if [[  -f $checkfile3 ]]
then
   exit
fi


echo "checkfiles are:"
echo "checkfile1=$checkfile1"
echo "checkfile2=$checkfile2"
echo "checkfile3=$checkfile3"
if [ $dbg -eq 1 ]
then
   start_date=202212    # you should change with appropriate date. 
                        # Must have res in the correct dir
   yyyy=${start_date:0:4}
   st=${start_date:4:6}
   nrunC3Sfore=4
   for ens in {001..004}
   do  
      caso=${SPSSystem}_${yyyy}${st}_${ens}
      m1=`date -d "${start_date}01 + 1 months" +%m`
      y1=`date -d "${start_date}01 + 1 months" +%Y`
      m3=`date -d "${start_date}01 + 3 months" +%m`
      y3=`date -d "${start_date}01 + 3 months" +%Y`
# testi first month
      mkdir -p $WORK_CPS/archive/${caso}/rest/$y1-$m1-01-00000
      mkdir -p $WORK_CPS/archive/${caso}/rest/$y3-$m3-01-00000
   done
fi
firstmonth=`date -d "${start_date}01 + 1 months" +%Y%m`
thirdmonth=`date -d "${start_date}01 + 3 months" +%Y%m`
forthmonth=`date -d "${start_date}01 + 4 months" +%Y%m`


echo "forecast start date: $start_date"
echo ""
echo ""

#-- Main loop (ensamble mebers) ------------------------------------------------                                                                          
echo ""
n_forth_month_done=0
n_third_month_done=0
n_first_month_done=0
list_of_cases_1m=""
list_of_cases_lead0=""
list_of_cases_lead1=""
for ens2d in `seq -w 01 $nrunmax`
do
   caso=${SPSSystem}_${start_date}_0${ens2d}
   
   if [[ ! -d $WORK_CPS/archive/${caso}/rest ]]
   then
   #skip it
      continue
   fi
   starch_run=`$DIR_UTIL/findjobs.sh -m ${machine} -n st_archive.${caso} -a RUN -c yes` 
   if [[ ${starch_run} -ne 0 ]] ; then
      #skip case with st_archive running to avoid using incomplete file during diags processing
      continue
   fi 
   # Get last restart file
   last_rest=""
   nf=$(ls -1 $WORK_CPS/archive/${caso}/rest 2>/dev/null|wc -l)
   if [ $nf -ne 0 ]
   then
   file=$(ls -1 $WORK_CPS/archive/${caso}/rest 2>/dev/null)
      if [ $? -eq 0 ] ; then
          last_rest=$(echo $file |  tr ' ' '\n'| tail -n 1 | awk '{print substr($1,1,4) substr($1,6,2)}')
      fi
   fi
   
   if [ ! -z $last_rest ]
   then
     if [ $last_rest -ge $firstmonth ]
     then
        n_first_month_done=$(($n_first_month_done + 1))
        list_of_cases_1m+=" $caso"
     fi 
     if [ $last_rest -ge $thirdmonth ]
     then
        n_third_month_done=$(($n_third_month_done + 1))
        list_of_cases_lead0+=" $caso"
     fi 
     if [ $last_rest -ge $forthmonth ]
     then
        n_forth_month_done=$(($n_forth_month_done + 1))
        list_of_cases_lead1+=" $caso"
     fi 
  fi 
done

if [ $dbg -eq 1 ]
then
  echo "now first month done by $n_first_month_done jobs. To launch postproc needed $nrunC3Sfore"
  echo "now third month done by $n_third_month_done jobs. To launch postproc needed $nrunC3Sfore"
  echo "now forth month done by $n_forth_month_done jobs. To launch postproc needed $nrunC3Sfore"
fi
echo ""
echo ""
nrundiagsmin=$nrunC3Sfore
#nrundiagsmin=20
if [ $n_first_month_done -lt $nrundiagsmin ] 
then
   echo "not enough month completed to run diagnostics. Bye"
   exit
fi
#
if [ $n_first_month_done -ge $nrundiagsmin ] && [ ! -f $checkfile1 ]
then
   mkdir -p $DIR_LOG/forecast/$start_date/
   mkdir -p $DIR_TEMP/$start_date
   inputfile=$DIR_TEMP/$start_date/list_of_cases_1m
   echo $list_of_cases_1m > $inputfile
   nproc0=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_first_month_${yyyy}${st} -c yes`
   if [ $nproc0 -eq 0 ]
   then
      nmf=1
      flgmnth=1
      monthstr=`date -d "$yyyy${st}01 " +%B`
set +euvx
      input="$yyyy $st $nrundiagsmin $nmf $flgmnth $monthstr $checkfile1 $inputfile $dbg"
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -s plot_forecast_all_vars.sh -j plot_forecast_first_month_${yyyy}${st} -d ${DIR_DIAG} -l ${DIR_LOG}/forecast/$yyyy$st -i "$input"
set -euvx
     
      body="$DIR_DIAG/plot_forecast_diag.sh submitted by $DIR_UTIL/launch_forecast_diag.sh for first month."
      title="${CPSSYS} forecast first month runtime diags submitted"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      if [[ $machine == "leonardo" ]]
      then
        while `true`
        do
           sleep 300
           nproc=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_first_month_${yyyy}${st} -c yes`
           if [[ $nproc -eq 0 ]] ; then
               if [[ -f $checkfile1 ]] ; then
                   set +euvx
                   . $DIR_UTIL/condaactivation.sh
                   condafunction activate $envcondarclone
                   set -euvx
                   rclone mkdir my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   rclone copy $SCRATCHDIR/runtimediag/$yyyy$st/month/${yyyy}${st}_month1.pdf my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   body="Diagnostics for first month completed and transferred on https://drive.google.com/drive/folders/18q9gTUlV5_OY5dlYOvBkzxWMWmLrdW4-?usp=sharing directory:$yyyy$st/runtime_diags"
                   title="${CPSSYS} first month runtime diags completed"
                   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -c $ccmail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                   break
               else
                  body="$DIR_DIAG/plot_forecast_diag.sh completed but no plot file found for month1. Check the log in $DIR_LOG/${typeofrun}/${yyyy}${st}"
                  title="${CPSSYS} forecast warning month1 runtime diags"
                  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                  exit 1 
               fi
           fi
        done
      fi
      exit
   else
      echo "plot_forecast_first_month_${yyyy}${st} already running"
   fi
#else
#   echo "Already run for first_month_${yyyy}${st}"
fi
# run the diagnostics only if enough outputs $n_first_month_done and not yet done ($checkfile1 created exiting from plot_forecast_all_vars.sh)
## run the diagnostics only if not yet launched and running
if [ $n_third_month_done -ge $nrundiagsmin ] && [ ! -f $checkfile2 ]
then
   mkdir -p $DIR_TEMP/$start_date
   inputfile=$DIR_TEMP/$start_date/list_of_cases_lead0
   echo $list_of_cases_lead0 > $inputfile
   nproc1=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_lead0_${yyyy}${st} -c yes`
   if [ $nproc1 -eq 0 ]
   then
      nmf=3
      flgmnth=0
      leadmonth=$((${nmf} - 1))
      monthstr=`date -d "$yyyy${st}01 +${leadmonth} month" +%B`
set +euvx
      input="$yyyy $st $nrundiagsmin $nmf $flgmnth $monthstr $checkfile2 $inputfile $dbg"
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -s plot_forecast_all_vars.sh -j plot_forecast_lead0_${yyyy}${st} -d ${DIR_DIAG} -l ${DIR_LOG}/forecast/$yyyy$st -i "$input"
# Only one $DIR_UTIL/diag/plot_forecast_all_vars.sh allowed at a time!
set -euvx
      body="$DIR_DIAG/plot_forecast_diag.sh submitted by $DIR_UTIL/launch_forecast_diag.sh for lead 0."
      title="${CPSSYS} forecast lead 0 runtime diags submitted"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      if [[ $machine == "leonardo" ]]
      then
        while `true`
        do
           sleep 300
           nproc=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_lead0_${yyyy}${st} -c yes`
           if [[ $nproc -eq 0 ]] ; then
               if [[ -f $checkfile2 ]] ; then
                   set +euvx
                   . $DIR_UTIL/condaactivation.sh
                   condafunction activate $envcondarclone
                   set -euvx
                   rclone mkdir my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   rclone copy $SCRATCHDIR/runtimediag/$yyyy$st/lead/${yyyy}${st}_Lead0.pdf my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   body="Diagnostics for lead 0 completed and transferred on https://drive.google.com/drive/folders/18q9gTUlV5_OY5dlYOvBkzxWMWmLrdW4-?usp=sharing directory:$yyyy$st/runtime_diags"
                   title="${CPSSYS} lead 0 runtime diags completed"
                   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -c $ccmail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                   break
               else
                  body="$DIR_DIAG/plot_forecast_diag.sh completed but no plot file found for lead 0. Check the log in $DIR_LOG/${typeofrun}/${yyyy}${st}"
                  title="${CPSSYS} forecast warning lead 0 runtime diags"
                  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                  exit 1
               fi
           fi
        done
      fi
      exit
   else
      echo "plot_forecast_lead0_${yyyy}${st} already running"
   fi
#else
#   echo "Already run for lead0_${yyyy}${st}"
fi
#
# run the diagnostics only if enough outputs $n_first_month_done and not yet done ($checkfile1 created exiting from plot_forecast_all_vars.sh)
# diagnostcs for lead 1
#END PRESENT VERSION
if [ $n_forth_month_done -ge $nrundiagsmin ] && [ ! -f $checkfile3 ]
then
   mkdir -p $DIR_TEMP/$start_date
   inputfile=$DIR_TEMP/$start_date/list_of_cases_lead1
   echo $list_of_cases_lead1 > $inputfile
   nproc2=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_lead1_${yyyy}${st} -c yes`
   if [ $nproc2 -eq 0 ]
   then
      nmf=4
      flgmnth=0
      leadmonth=$((${nmf} - 1))
      monthstr=`date -d "$yyyy${st}01 +${leadmonth} month" +%B`
set +euvx
      input="$yyyy $st $nrundiagsmin $nmf $flgmnth $monthstr $checkfile3 $inputfile $dbg "
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -s plot_forecast_all_vars.sh -j plot_forecast_lead1_${yyyy}${st} -d ${DIR_DIAG} -l ${DIR_LOG}/forecast/$yyyy$st -i "$input"
set -euvx
      body="$DIR_DIAG/plot_forecast_diag.sh submitted by $DIR_UTIL/launch_forecast_diag.sh for lead 1."
      title="${CPSSYS} forecast lead 1 runtime diags submitted"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      if [[ $machine == "leonardo" ]]
      then
        while `true`
        do
           sleep 300
           nproc=`${DIR_UTIL}/findjobs.sh -m $machine -n plot_forecast_lead1_${yyyy}${st} -c yes`
           if [[ $nproc -eq 0 ]] ; then
               if [[ -f $checkfile2 ]] ; then
                   set +euvx
                   . $DIR_UTIL/condaactivation.sh
                   condafunction activate $envcondarclone
                   set -euvx
                   rclone mkdir my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   rclone copy $SCRATCHDIR/runtimediag/$yyyy$st/lead/${yyyy}${st}_Lead0_1.pdf my_drive:$typeofrun/${yyyy}${st}/runtime_diags
                   body="Diagnostics for lead 1 completed and transferred on https://drive.google.com/drive/folders/18q9gTUlV5_OY5dlYOvBkzxWMWmLrdW4-?usp=sharing directory:$yyyy$st/runtime_diags"
                   title="${CPSSYS} lead 1 runtime diags completed"
                   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -c $ccmail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                   break
               else
                  body="$DIR_DIAG/plot_forecast_diag.sh completed but no plot file found for lead 1. Check the log in $DIR_LOG/${typeofrun}/${yyyy}${st}"
                  title="${CPSSYS} forecast warning lead 1 runtime diags"
                  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
                  exit 1
               fi
           fi
        done
      fi     
      exit
   else
      echo "plot_forecast_lead1_${yyyy}${st} already running"
   fi
#
#else
#   echo "Already run for lead1_${yyyy}${st}"
fi
echo "That's all Folks"
