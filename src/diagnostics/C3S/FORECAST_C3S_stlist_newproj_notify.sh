#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -euvx
yyyy=$1         #`date +%Y`  #"2019"
st=$2     #`date +%m`  #"01"
start_date=$yyyy$st

flag_done=$3

dbg=$4
. ${DIR_UTIL}/descr_ensemble.sh $yyyy

#if [ ! -f $WORK_C3S1/${start_date}/tar_C3S_${start_date}_DONE ]
#then
#   echo "forecast not completed yet"
#   exit
#fi

dirlog=${DIR_LOG}/${typeofrun}/${start_date}/diagnostics
mkdir -p $dirlog

refperiod=$iniy_hind-$endy_hind
all=3      #only for fc: 3 - if monthly mean + anom + plot; 2 - if only anom + plot ; 1 - if only plot
typefore="fc"
###HERE WE KEEP JUST SEASONAL - IF THIS WILL BE MODIFIED IN THE FUTURE, CHECK NUMBER OF FLAG CONTROL in $DIR_UTIL/launch_diagnostic_website.sh 
export reglist="global Europe Tropics NH SH"
ensorgl="Nino1+2 Nino3 Nino3.4 Nino4"
varlist="mslp z500 t850 t2m precip sst u200 v200"
#varlist="sic"
for var in $varlist
do
     cd $DIR_DIAG_C3S
     echo 'postprocessing $var '$st
     input="$yyyy $st $var $all '$reglist' '$ensorgl' ${flag_done} $dbg"
     echo $input
     ${DIR_UTIL}/submitcommand.sh -m $machine -d ${DIR_DIAG_C3S} -S $qos -q $serialq_m -n 1 -M 7000 -j compute_anomalies_C3S_auto_newproj_notify_${var}_${start_date} -l ${dirlog} -s compute_anomalies_C3S_auto_newproj_notify.sh -i "$input"


##NOT USED RIGHT NOW - IT MAY BECOME USEFUL FOR FUTURE DIAGNOSTIC FOR WMO
     redo=0
     if [ $redo -eq 1 ]  ;then
         if [ $var != "sst" ] ; then
              ./remap_files4WMO.sh $yyyy $st $var
         else
              ./remap_sstfiles4WMO.sh $yyyy $st $var
         fi
     fi
done

exit 0
