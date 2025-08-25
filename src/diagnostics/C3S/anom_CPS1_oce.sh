#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -euvx

yyyy=$1
mm="$2"
st=`printf '%.2d' $(( 10#$mm ))`
refperiod=$3
nrun=$4
climdir=$5
var=$6
workdir=$7
dbg=$8
vardir=$var

ensalllist=""
[ -f $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
ic=0
cd $workdir
#plist=`ls | grep ${SPSSystem}_${yyyy}$st | cut -d '.' -f2 | cut -d '_' -f2-3`
plist=`ls | grep ${SPSSystem}_${yyyy}$st | cut -d '_' -f2-3`

for sps in $plist ; do
	 cdo sub $workdir/${SPSSystem}_${sps}_${var}.zip.nc  $climdir/clim/${var}_${CPSSYS}_clim_$refperiod.${st}.nc $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_${sps}_ano.$refperiod.nc
	 ic=`expr $ic + 1`
	 ensalllist="$ensalllist $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_${sps}_ano.$refperiod.nc"
 	if [ $ic -eq $nrun ]
 	then
	    	break
	 fi 
done #while on $plist


[ -f $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc ] && rm $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
[ -f $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc ] && rm $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc

cdo -O ensmean $ensalllist $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
cdo -O ensstd  $ensalllist $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_spread_ano.$refperiod.nc
cdo settaxis,$yyyy-$st-15,12:00,1mon $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc tmp${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
cdo setreftime,$yyyy-$st-15,12:00 tmp${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc

ncecat -O  $ensalllist $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc
ncrename -O -d record,ens $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc

#remove commented for testing phase#
#rm $ensalllist
rm tmp${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc
mkdir -p $DIR_FORE_ANOM/$yyyy$st/daily/${var}/anom/ 
if  [[ $dbg -eq 0 ]] ; then
    rsync -auv $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_spread_ano.$refperiod.nc $DIR_FORE_ANOM/$yyyy$st/daily/${var}/anom/
    rsync -auv $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_ens_ano.$refperiod.nc $DIR_FORE_ANOM/$yyyy$st/daily/${var}/anom/
    rsync -auv $DIR_FORE_ANOM/$yyyy$st/${var}_${CPSSYS}_sps_${yyyy}${st}_all_ano.$refperiod.nc $DIR_FORE_ANOM/$yyyy$st/daily/${var}/anom/ 

fi 
