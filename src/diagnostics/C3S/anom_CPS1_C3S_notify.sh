#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
set -euvx

yyyy=$1
st="$2"
climdir=$3
workdir=$4
anomdir=$5
var=$6
dbg=$7
dirlog=$8

refperiod=$iniy_hind-$endy_hind
vardir=$var
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx


mkdir -p $workdir


ensalllist=""
[ -f $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
ic=0
cd $workdir
plist=`ls |grep ${SPSSystem}_${yyyy}$st|cut -d '.' -f1|cut -d '_' -f2-5`

for caso in $plist ; do
	  cdo sub $workdir/${var}_${caso}.nc $climdir/${var}_${SPSSystem}_clim_$refperiod.${st}.nc $anomdir/${var}_${caso}_ano.$refperiod.nc
	  touch ${dirlog}/anom_${caso}_${var}_DONE
	  ic=`expr $ic + 1`
  	ensalllist="$ensalllist $anomdir/${var}_${caso}_ano.$refperiod.nc"
	  if [ $ic -eq $nrunC3Sfore ]
	  then
	     	break
	  fi 
done #while on $plist

set +e
nanomDONE=`ls -1 ${dirlog}/anom_*${yyyy}${st}_0??_${var}_DONE | wc -l`
set -e

if [ $nanomDONE -eq $nrunC3Sfore ] ; then
   
   #check to avoid including old ens/all files in $ensalllist 
   [ -f $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
   [ -f $anomdir/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc ] && rm $anomdir/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc
   
   cdo -O ensmean $ensalllist $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
   cdo -O ensstd  $ensalllist $anomdir/${var}_${SPSSystem}_${yyyy}${st}_spread_ano.$refperiod.nc
   cdo settaxis,$yyyy-$st-15,12:00,1mon $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc tmp${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
   cdo setreftime,$yyyy-$st-15,12:00 tmp${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc $anomdir/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc
   ncecat -O  $ensalllist $anomdir/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc
   ncrename -O -d record,ens $anomdir/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc

   if [[ $var != "sst" ]] ; then  
      #needed for ENSO plots
      rm $ensalllist
   fi
   rm tmp${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc

   #rsync to $DIR_CLIM!
   touch ${dirlog}/anom_${SPSSystem}_${yyyy}${st}_${var}_DONE
   rm ${dirlog}/anom_${SPSSystem}_${yyyy}${st}_0??_${var}_DONE*

else
   body="Something wrong with $typeofrun anomalies ${yyyy}${st} for ${var}. $nanomDONE anomalies computed instead of ${nrunC3Sfore}. \n Check in $DIR_DIAG_C3S/anom_${CPSSYS}_C3S_notify.sh"   
   title="[diags] ${CPSSYS} $typeofrun anomalies ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"     
   exit 1
fi
  
