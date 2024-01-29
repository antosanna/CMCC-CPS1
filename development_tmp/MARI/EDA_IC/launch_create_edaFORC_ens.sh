#!/bin/sh -l
#BSUB  -J launch_create_eda
#BSUB  -q s_long
#BSUB  -o logs/launch_create_eda.out.%J  
#BSUB  -e logs/launch_create_eda.err.%J  
#BSUB  -P 0490

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx
script_dir=$DIR_LND_IC
log_dir=${DIR_LOG}/IC_CLM
# create files with last analysis data
mkdir -p ${log_dir}
yy=1960
mm=01

finalyy="1969"
finalmm="12"

debug=0
backup=0
n=$1
while [[ ${yy}${mm} -le $finalyy$finalmm ]] ; do

      echo $yy$mm
      if [[ $yy$mm -eq 196906 ]] ; then  #BUG IN DATE command
         st=07     #`date -d ' '$yy${mm}01' + 1 month' +%m`
         yyyy=1969 #`date -d ' '$yy${mm}01' + 1 month' +%Y`
      else
         st=`date -d ' '$yy${mm}01' + 1 month' +%m`
         yyyy=`date -d ' '$yy${mm}01' + 1 month' +%Y`
      fi 
      checkfile=${log_dir}/create_eda_n${n}_FORC.sh_${yyyy}${st}_ok
      echo $checkfile

      if [[ -f $checkfile ]] ; then
          mm=$st
         yy=$yyyy
         echo "advancing without recomputing"
         continue
      fi
      . ${script_dir}/create_edaFORC.sh $yy $mm $n $backup $checkfile $debug
    if [[ ! -f $checkfile ]]
    then
       body="CLM ICs: Forcing files from EDA member $n data NOT created
          generating scripts:
          ${script_dir}/create_edaFORC.sh "
       title="[CLMIC] ${CPSSYS} forecast ERROR"
       ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s ${yyyy}${st}
    else
       mm=${st}   #`date -d ' '$yy${mm}01' + 1 month' +%m`
       yy=${yyyy} #`date -d ' '$yy${mm}01' + 1 month' +%Y`     
    fi
done
