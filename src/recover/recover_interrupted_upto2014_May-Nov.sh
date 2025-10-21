#!/bin/sh -l 
# REMEMBER TO UPDATE THE NAME OF LOGFILE!!!
# PART YOU SHOULD MODIFY: log file above
# start-month
# dbg
# listacases
# JUST IN CASE listatoignore*

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

##########################################################################################################################
# SUBMISSION COMMAND!!!!!
#
#
### THE SCRIPT IS NOT EXAUSTIVE!!! 
#
#   In case of interruption during st_archive, this procedure will recognize the case as interrupted
#   runtime. As a result, it can happen that the case of interest will run 7 months.
#   In this case the C3S postprocessing has to be run offline, because the number of output will be greater than expected
#   and check_6months_output_in_archive.sh will raise an error
#
##########################################################################################################################

function write_help_leonardo
{
  echo "USE ONLY FROM crontab if not dbg: recover_interrupted.sh [<dbg>] "
  echo ""
  echo "CAVEAT"
  echo "First time dbg should be set to 2 to onyl print the list of interrupted jobs; then 1 to postprocess only one; 0 to process all the list"
  echo ""
  echo "SUBMISSION COMMAND WITH dbg=2:"
  echo "./recover_interrupted.sh 2"
  echo ""
  echo "SUBMISSION COMMAND EXAMPLE (every 30'):"
  echo "*/30 * * * * . /etc/profile; export RUNBYCRONTAB=1 ;. /leonardo/home/usera07cmc/a07cmc00/.bashrc && . ${DIR_UTIL}/descr_CPS.sh && ${DIR_RECOVER}/recover_interrupted.sh 0"
}
#set -euxv
function write_help
{
  echo "Use: recover_interrupted.sh [<dbg>] "
  echo ""
  echo "SUBMISSION COMMAND:"
  echo ". $HOME/.bashrc && . ${DIR_UTIL}/descr_CPS.sh && ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j recover_interrupted_${stmain}_debug$dbg -l $DIR_LOG/hindcast/ -d $DIR_RECOVER -s recover_interrupted.sh -i \"\$dbg "
  echo ""
  echo "CAVEAT"
  echo "First time dbg should be set to 2 to onyl print the list of interrupted jobs; then 1 to postprocess only one; 0 to process all the list"
}
#set -euxv
if [[ "$1" == "-h" ]]
then
   if [[ $machine == "leonardo" ]]
   then
      write_help_leonardo
      exit
   else
      write_help
      exit
   fi
fi
set -euxv
mo_today=`date +%m`
yy_today=`date +%Y`

dbg=2  #set to 2 the first time you run in order to print only the list of interrupted 
         #set to 1 the second time you run in order to process only one case for category
         #set to 0 to run all interrupted identified


set +euvx
. ${DIR_UTIL}/descr_ensemble.sh 1993
#set -euvx
set -eux

#flag introduced to prevent double submission
#touched at the beginning of the execution and removed at the end
check_recover_running=${DIR_LOG}/$typeofrun/recover_interrupted_running
if [[ -f ${check_recover_running} ]] ; then
   echo "recover_interrupted is already running"
   exit
fi

touch ${check_recover_running}


cd $DIR_CASES/

#listofcases="sps4_200607_024 sps4_200607_025 sps4_200607_026 sps4_200607_030 sps4_200707_004 sps4_200707_006 sps4_200707_007" 

#listofcases="sps4_199402_020 sps4_199602_002 sps4_199602_009 sps4_199602_019 sps4_199602_024 sps4_199602_025 sps4_199602_027 sps4_199602_028 sps4_199602_029 sps4_199702_011 sps4_199702_016 sps4_199702_018 sps4_199702_019 sps4_199702_022 sps4_199702_027 sps4_199702_028 sps4_199702_029 sps4_199702_030 sps4_199802_006 sps4_199802_008" 

listofcases="sps4_200408_002"


if [[ $# -eq 1 ]]
then
   dbg=${1}
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh 1993
#set -euvx
set -eux
else
   dbg=0    #you want to resubmit just the cases listed in your hardcoded $listofcases
fi

if [[ $machine == "leonardo" ]]
then
    LOG_FILE=$DIR_LOG/hindcast/recover_${dbg}_`date +%Y%m%d%H%M`.log
    exec 3>&1 1>>${LOG_FILE} 2>&1
fi
if [[ `echo -n $dbg|wc -c` -ne 1 ]]
then
   echo "first input should be dbg=0/1/2"
   if [[ -f ${check_recover_running} ]] ; then
         rm ${check_recover_running}
   fi 
   exit
fi

lista_caso_ignored="sps4_201208_005" #sps4_201208_005"
for st in 05 
do
   listofcases=`ls -d ${SPSSystem}_20??${st}_0??`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
#set -euvx
set -eux
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
   cnt_st_archive=0     #CASES INTERRUPTED DURING ST_ARCHIVE

   filecsv=$DIR_LOG/$typeofrun/${SPSSystem}_${typeofrun}_recover${dbg}_list.${machine}.`date +%Y%m%d%H`.csv
   filexls=`echo ${filecsv}|rev |cut -d '.' -f2-|rev`.xlsx
   echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" > $filecsv
### INITIALIZE LISTS
   lista_lt_archive=" "    
   lista_resubmit=" "
   lista_pp_C3S=" "
   lista_moredays=" "
   lista_first_month=" "
   lista_st_archive=" "

#sps4_199711_011 (zeus) - unstability in NEMO - to be checked 
#sps4_200207_020 (juno) - NaN in field Sl_t
#sps4_199910_025 (zeus) - h2osoi_ice sign negative
#sps4_200610_012 (zeus) - h2osoi_ice sign negative
#sps4_200910_025 (zeus) - NaN in field Sl_t
#sps4_201010_013 (zeus) - h2osoi_ice sign negative
#sps4_201010_004 (zeus) - strange behaviour due to multiple recover..to be checked!

   cd $DIR_CASES/
   for caso in $listofcases ; do
      if [[ $lista_caso_ignored == *"$caso"* ]] ; then
         continue  
      fi
      st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
      yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
      if [[ $yyyy -gt 2014 ]] 
      then
         continue
      fi
      member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`  
 
      CASEROOT=$DIR_CASES/$caso/
      outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
      set +uevx
      . $dictionary
#  set -euvx
      set -eux

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
            is_starch=`ls -ltr $DIR_CASES/$caso/logs |tail -n 1|grep 'st_archive'|wc -l`
            if [[ ${is_starch} -eq 1 ]] ; then
                cnt_st_archive=$(($cnt_st_archive + 1))
                lista_st_archive+=" $caso"
            else
               cnt_first_month=$(($cnt_first_month + 1))
               lista_first_month+=" $caso"
            fi
         else
            is_starch=`ls -ltr $DIR_CASES/$caso/logs |tail -n 1|grep 'st_archive'|wc -l`
            if [[ ${is_starch} -eq 1 ]] ; then
               cnt_st_archive=$(($cnt_st_archive + 1))
               lista_st_archive+=" $caso"
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
     # THIS SECTION MUST BE RUN ONLY ON JUNO BECAUSE C3S ARE PRODUCED ONLY THERE\# FOR A MATTER OF CONSISTENCY

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
#echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" 
         echo "-,-,-,$caso,- " >> $filecsv
      done
   fi
   if [[ "$lista_resubmit" != " " ]]
   then
      echo "---- From the above RECOVER_LIST, $cnt_resubmit cases to be resubmitted "
      echo "$lista_resubmit"
      echo ""
      for caso in $lista_resubmit
      do
#echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" 
         echo "-,$caso,-,-,- " >> $filecsv
      done
   fi
   if [[ "$lista_first_month" != " " ]]
   then
      echo "Cases interrupted during first month"
      echo "$lista_first_month" 
      echo ""
      for caso in $lista_first_month
      do

#echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" 

         echo "$caso,-,-,-,- " >> $filecsv
      done
   fi
   if [[ "$lista_st_archive" != " " ]]
   then
      echo "Cases interrupted during st_archive"
      echo "$lista_st_archive" 
      echo ""
      for caso in $lista_st_archive
      do  

#echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" 

         echo "-,-,$caso,-,- " >> $filecsv
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

#echo "first month,resubmit,st_archive,lt_archive (miss moredays),lt_archive_moredays (postproc C3S)" 
         echo "-,-,-,-,$caso " >> $filecsv
      done
   fi


   echo "starting conversion with python on CMCC machines (NOT YET IMPLEMENTED ON Leonardo) "`date`
set +euvx
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondarclone
#   set -euvx
set -eux
   python $DIR_UTIL/convert_csv2xls.py ${filecsv} ${filexls}
   rclone mkdir my_drive:CERISE/recover
   rclone copy ${filexls} my_drive:CERISE/recover
set +euvx
   condafunction deactivate 
#   set -euvx
   set -eux
   echo "end of conversion with python on CMCC machines "`date`

   if [[ $dbg -eq 2 ]]
   then
      echo "DEBUG=2: NO ACTION REQUIRED, JUST LISTING OF INTERRUPTED JOBS"
   fi

### REMEMBER: if dbg=1 only 1 case for category will be processed and you could check that everything was ok.

   if [[ $dbg -ne 2 ]] ; then
    
      echo "NOW PROCESSING THE INTERRUPTED CASES"
      now_running=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive -c yes`
      if [[ $now_running -ge $maxnumbertorecover ]]
      then
         echo "ALREADY RUNNING MAXIMUM NUMBER OF JOBS! exit now"
         if [[ -f ${check_recover_running} ]] ; then
            rm ${check_recover_running}
         fi
         exit
      fi 
      ncount=0
set +euv
      . $DIR_UTIL/condaactivation.sh
      condafunction activate $envcondacm3
#set -euvx
set -eux
      caso=""
# first month
      if [[ $cnt_first_month -ne 0 ]] ; then
         echo "RELAUNCH first month FOR CASES:"
         echo "$lista_first_month"
         echo ""
      fi
      for caso in $lista_first_month
      do

         domodify=0
         isrunlog=`ls $DIR_CASES/$caso/logs/$caso.run_*.err| wc -l`
         if [[ $isrunlog -ge 1 ]] 
         then
          #take the last one
             lastrunlog=`ls -tr $DIR_CASES/$caso/logs/$caso.run_*.err| tail -n 1`
             ismoderr=`grep 'ERROR: RUN FAIL:' $lastrunlog |wc -l`
             if [[ $ismoderr -ne 0 ]]  
             then
                domodify=1
                if [[ $machine == "leonardo" ]]
                then 
                   domodify=0
                   logff=`grep 'See log file for details: ' $lastrunlog | cut -d ':' -f 2`
                   clmerr=`grep "h2osoi_ice has gone significantly negative" $logff |wc -l`
                #since on Leonardo the 'ERROR: RUN FAIL:' string can be also due to machine issue, we allow modify_triplette just in case of clm instability 
                #(the most frequent one)
                   if [[ $clmerr -ne 0 ]] ; then
                      domodify=1
                   fi
                fi
             fi
         fi
         if [[ $domodify -eq 1 ]] 
         then      
         #numerical failure of the model (instability, conservation check failure etc)
         #we change ICs with modify_triplette
            st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
            yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
            log_dir_modify=$DIR_LOG/${typeofrun}/${yyyy}${st}
            mkdir -p $log_dir_modify  #probably redundant
            while `true`
            do
            #check to avoid simultaneous submission of modify_triplette - potentially overwriting triplette files
               np=`${DIR_UTIL}/findjobs.sh -m $machine -n modify_triplette_${SPSSystem} -c yes`
               if [[ $np -eq 0 ]]
               then
                  if [[ $machine == "leonardo" ]]
                  then
                     $DIR_UTIL/modify_triplette.sh $caso > $log_dir_modify/modify_triplette_${caso}.log &
                  else
                     ${DIR_UTIL}/submitcommand.sh -m $machine -l $log_dir_modify -q $serialq_s -j modify_triplette_${caso} -d $DIR_UTIL -s modify_triplette.sh -i "$caso"
                  fi
                  break
               fi
               sleep 60
            done
         else
            $DIR_RECOVER/refresh_all_scripts.sh $caso
            st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
            yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
            member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`
   
            CASEROOT=$DIR_CASES/$caso/
            outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
            set +uevx
            . $dictionary
#         set -euvx
            set -eux
            cd ${DIR_CASES}/$caso
# workaround in order to keep the syntax highlights correct (case is a shell command)
            command="case.submit"
            echo $command
            now_running=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive -c yes`
            if [[ $machine == "leonardo" ]]
            then
# does not work             srun -c16 --export=ALL --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 ./$command
                salloc -c16 --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 
                srun --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 ./$command
            else
                ./$command
                ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$caso recovered with automatic procedure" -t "RECOVER $caso"
            fi
            echo "$command done"
            ncount=$(($ncount + 1))
            if [[ $(($ncount + $now_running)) -ge $maxnumbertorecover ]]
            then
               if [[ -f ${check_recover_running} ]] ; then
                   rm ${check_recover_running}
               fi 
               exit
            fi
         fi
         if [[ $dbg -eq 1 ]] ; then break ; fi
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
         now_running=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive -c yes`
         if [[ $machine == "leonardo" ]]
         then
            salloc -c6 --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 
            srun --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 $DIR_RECOVER/recover_lt_archive.sh $caso
# 20240627 G.F.Marras  does not work
#         srun --export=ALL -c6 --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 $DIR_RECOVER/recover_lt_archive.sh $caso
         else
            $DIR_RECOVER/recover_lt_archive.sh $caso
         fi
         ncount=$(($ncount + 1))
         if [[ $(($ncount + $now_running)) -ge $maxnumbertorecover ]]
         then
            if [[ -f ${check_recover_running} ]] ; then
                rm ${check_recover_running}
            fi 
            exit
         fi
      
         if [[ $dbg -eq 1 ]] ; then break ; fi
      done
  
# st_archive
      if [[ $cnt_st_archive -ne 0 ]] ; then
         echo "RELAUNCH st_archive FOR CASES:"
         echo "$lista_st_archive"
         echo ""
      fi
      for caso in $lista_st_archive
      do
         $DIR_RECOVER/refresh_all_scripts.sh $caso

         cd $DIR_CASES/$caso
         $DIR_RECOVER/recover_st_archive.sh $caso

         if [[ $dbg -eq 1 ]] ; then break ; fi
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

         domodify=0
         isrunlog=`ls $DIR_CASES/$caso/logs/$caso.run_*.err| wc -l`
         if [[ $isrunlog -ge 1 ]]
         then
          #take the last one
             lastrunlog=`ls -tr $DIR_CASES/$caso/logs/$caso.run_*.err| tail -n 1`
             ismoderr=`grep 'ERROR: RUN FAIL:' $lastrunlog |wc -l`
             if [[ $ismoderr -ne 0 ]]
             then
                domodify=1
                if [[ $machine == "leonardo" ]]
                then 
                   domodify=0
                   logff=`grep 'See log file for details: ' $lastrunlog | cut -d ':' -f 2`
                   clmerr=`grep "h2osoi_ice has gone significantly negative" $logff |wc -l`
                #since on Leonardo the 'ERROR: RUN FAIL:' string can be also due to machine issue, we allow modify_triplette just in case of clm instability 
                #(the most frequent one)
                   if [[ $clmerr -ne 0 ]] ; then
                      domodify=1
                   fi 
                fi
             fi
         fi

         if [[ $domodify -eq 1 ]]
         then
             echo "$caso facing some numerical issue, going to modify triplette" 
          #numerical failure of the model (instability, conservation check failure etc)
          #we change ICs with modify_triplette
             st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
             yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
             log_dir_modify=$DIR_LOG/${typeofrun}/${yyyy}${st}
             mkdir -p $log_dir_modify  #probably redundant
             while `true`
             do
               #check to avoid simultaneous submission of modify_triplette - potentially overwriting triplette files
                  np=`${DIR_UTIL}/findjobs.sh -m $machine -n modify_triplette_${SPSSystem} -c yes`
                  if [[ $np -eq 0 ]]
                  then
                     if [[ $machine == "leonardo" ]]
                     then
                        $DIR_UTIL/modify_triplette.sh $caso > $log_dir_modify/modify_triplette_${caso}.log &
                     else
                        ${DIR_UTIL}/submitcommand.sh -m $machine -l $log_dir_modify -q $serialq_s -j modify_triplette_${caso} -d $DIR_UTIL -s modify_triplette.sh -i "$caso"
                     fi
                     break
                  fi
                  sleep 60
             done
         else
             echo "going to resubmit $caso from last restart in run directory" 
             $DIR_RECOVER/refresh_all_scripts.sh $caso
             $DIR_RECOVER/recover_lt_archive.sh $caso
             st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
             yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
             member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`
             CASEROOT=$DIR_CASES/$caso/
             outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
             set +uevx
             . $dictionary
#          set -euvx
            set -eux
             cd ${DIR_CASES}/$caso
# workaround in order to keep the syntax highlights correct (case is a shell command)
             command="case.submit"
             echo $command
             now_running=`${DIR_UTIL}/findjobs.sh -m $machine -n st_archive -c yes`
             if [[ $machine == "leonardo" ]]
             then
#does not work             srun -c16 --export=ALL --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 ./$command
                salloc -c16 --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 
                srun --qos=$qos -A $account_name -p dcgp_usr_prod -t 1:00:00 ./$command
             else
                ./$command
             fi
             echo "$command done"
             ncount=$(($ncount + 1))
             if [[ $(($ncount + $now_running)) -ge $maxnumbertorecover ]]
             then
                if [[ -f ${check_recover_running} ]] ; then
                    rm ${check_recover_running}
                fi 
                exit
             fi
         fi
         if [[ $dbg -eq 1 ]] ; then break ; fi
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
#      bsub -W 06:00 -q s_medium -P 0490 -M 25000 -e logs/lt_archive_moredays_%J.err -o logs/lt_archive_moredays_%J.out   < .case.lt_archive_moredays 
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "6" -M 25000 -j -W 06:00 -P ${pID} -l logs -s .case.lt_archive_moredays 
         if [[ $dbg -eq 1 ]] ; then break ; fi
      done
   
   fi
   
done

if [[ -f ${check_recover_running} ]] ; then
   rm ${check_recover_running}
fi 

exit

