#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_nco
. $DIR_TEMPL/load_cdo

set -euvx
yyyy=$1         #`date +%Y`  #"2019"
st=$2     #`date +%m`  #"01"
start_date=$yyyy$st

flag_done=$3

debug=$4
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi

if [ ! -f $WORK_C3S1/${start_date}/tar_and_push_${start_date}_DONE ]
then
   echo "forecast not completed yet"
   exit
fi

dirlog=${DIR_LOG}/${typeofrun}/${start_date}/diagnostics
mkdir -p $dirlog

refperiod=1993-2016
nrun=$nrunC3Sfore
all=3      #only for fc: 3 - if monthly mean + anom + plot; 2 - if only anom + plot ; 1 - if only plot
typefore="fc"
###HERE WE KEEP JUST SEASONAL - IF THIS WILL BE MODIFIED IN THE FUTURE, CHECK NUMBER OF FLAG CONTROL in $DIR_UTIL/launch_diagnostic_website.sh 
export reglist="global Europe Tropics NH SH"
ensorgl="Nino1+2 Nino3 Nino3.4 Nino4"
varlist="mslp z500 t850 t2m precip sst u200 v200"
for var in $varlist
do
     cd $DIR_DIAG_C3S
     echo 'postprocessing $var '$st
     input="$yyyy $st $refperiod $var $nrun $all $typefore '$reglist' '$ensorgl' ${flag_done} $debug"
     echo $input
     ${DIR_SPS35}/submitcommand.sh -m $machine -d ${DIR_DIAG_C3S} -r $sla_serialID -S qos_resv -q $serialq_m -n 1 -M 7000 -j compute_anomalies_C3S_auto_newproj_notify_${var}_${start_date} -l ${dirlog} -s compute_anomalies_C3S_auto_newproj_notify.sh -i "$input"


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
