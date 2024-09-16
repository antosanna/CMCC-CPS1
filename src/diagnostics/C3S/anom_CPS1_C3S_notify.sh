#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
set -euvx

yyyy=$1
mm="$2"
st=`printf '%.2d' $(( 10#$mm ))`
refperiod=$3
nrun=$4
climdir=$5
workdir=$6
var=$7
vardir=$var
dbg=$8
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi


mkdir -p $workdir
[ ! -d $workdir/anom ] && mkdir -p $workdir/anom


ensalllist=""
[ -f $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
ic=0
cd $workdir
plist=`ls |grep sps_${yyyy}$st|cut -d '.' -f2|cut -d '_' -f2-5`

for sps in $plist ; do
	  cdo sub $workdir/${var}_${SPSSYS}_${sps}.nc $climdir/${var}_${SPSSYS}_clim_$refperiod.${st}.nc $workdir/anom/${var}_${SPSSYS}_${sps}_ano.$refperiod.nc
	  touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_${sps}_${var}_DONE
	  ic=`expr $ic + 1`
  	ensalllist="$ensalllist $workdir/anom/${var}_${SPSSYS}_${sps}_ano.$refperiod.nc"
	  if [ $ic -eq $nrun ]
	  then
	     	break
	  fi 
done #while on $plist

set +e
nanomDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_*${yyyy}${st}_0??_${var}_DONE | wc -l`
set -e

if [ $nanomDONE -eq $nrun ] ; then
   
   #check to avoid including old ens/all files in $ensalllist 
   [ -f $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
   [ -f $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc ] && rm $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc
   
   cdo -O ensmean $ensalllist $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
   cdo -O ensstd  $ensalllist $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_spread_ano.$refperiod.nc
   cdo settaxis,$yyyy-$st-15,12:00,1mon $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc tmp${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
   cdo setreftime,$yyyy-$st-15,12:00 tmp${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
   ncecat -O  $ensalllist $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc
   ncrename -O -d record,ens $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc

   if [[ $var != "sst" ]] ; then  
      #needed for ENSO plots
      rm $ensalllist
   fi
   rm tmp${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc

   #rsync to $DIR_CLIM!
   mkdir -p $DIR_FORE_ANOM/monthly/${var}/C3S/anom/ 
   if [[ $dbg -eq  0 ]]  ; then
      rsync -auv $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_spread_ano.$refperiod.nc $DIR_FORE_ANOM/monthly/${var}/C3S/anom/
      rsync -auv $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc $DIR_FORE_ANOM/monthly/${var}/C3S/anom/
      rsync -auv $workdir/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc $DIR_FORE_ANOM/monthly/${var}/C3S/anom/
   fi

   touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_sps_${yyyy}${st}_${var}_DONE
   rm ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/anom_sps_${yyyy}${st}_0??_${var}_DONE*

else
   body="Something wrong with $typeofrun anomalies ${yyyy}${st} for ${var}. $nanomDONE anomalies computed instead of ${nrun}. \n Check in $DIR_DIAG_C3S/anom_${SPSSYS}_C3S_notify.sh"   
   title="[diags] ${SPSSYS} $typeofrun anomalies ERROR"
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"     
   exit 1
fi
  
