#!/bin/sh -l

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -evxu

yyyy=$1
yyyy2=$yyyy
yyyym1=$((yyyy - 1))
st=$2
if [ $st = "01" ] ; then
    yyyy2=$(($yyyy - 1))
fi
refperiod=$3
nrun=$4
workdir=$5
var=$6
ncep_dir=$7
debug=$8

if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi


enslist=`ls -1 ${workdir}/anom/${var}_${SPSSYS}_sps_${yyyy}${st}_0??_ano.${refperiod}.nc | rev | cut -d '_' -f2 |rev`

DIR="${workdir}/anom"
for en in $enslist ; do
  
  ncrcat -O $REPOSITORY/miss_12.nc ${DIR}/${var}_${SPSSYS}_sps_${yyyy}${st}_${en}_ano.${refperiod}.nc $DIR/${var}_${SPSSYS}_sps_${yyyy}${st}_${en}_ano.${refperiod}_miss.nc
  $DIR_UTIL/fixtimedd $yyyym1 ${st} 15 12:00 1mon $DIR/${var}_${SPSSYS}_sps_${yyyy}${st}_${en}_ano.${refperiod}_miss.nc
  touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/sst_enso_${yyyy}${st}_${en}_DONE

done

nsstfilesDONE=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/sst_enso_${yyyy}${st}_0??_DONE | wc -l`
if [ $nsstfilesDONE -eq $nrun ] ; then

 	ncecat -O $DIR/${var}_${SPSSYS}_sps_${yyyy}${st}_0??_ano.${refperiod}_miss.nc ${DIR}/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.${refperiod}_miss.nc
	touch ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/sst_enso_${yyyy}${st}_DONE
	rm ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/sst_enso_${yyyy}${st}_0??_DONE

mkdir -p $DIR_FORE_ANOM/monthly/${var}/C3S/anom/
 if [[ $debug -eq  0 ]] ; then
    #rsync to $DIR_CLIM
    rsync -auv --remove-source-files ${DIR}/${var}_${SPSSYS}_sps_${yyyy}${st}_all_ano.${refperiod}_miss.nc $DIR_FORE_ANOM/monthly/${var}/C3S/anom/ 
 fi

else
	set +e
	nsstyyyystDONEfound=`ls -1 ${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics/sst_enso_${yyyy}${st}_0??_DONE* | wc -l`
	set -e
	title="[diags] ${SPSSYS} ${typeofrun} sst ENSO anomalies ERROR"
	body="$nsstyyyystDONEfound files sst for ENSO found of the $nrun expected for $yyyy${st}. \n See in $DIR_DIAG_C3S/nino_plume_notify.sh"
 ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
	exit 1
fi  

# month before start-date one
yyyym1=$yyyy
case $st
    in
    01) stm1=12 
        yyyym1=$(($yyyy - 1)) ;;
    * ) stm1=$((10#$st - 1))
        stm1=`printf "%.02d" $stm1` 
        if [ $stm1 -lt 10 ]  ; then
	        	 stm1numtmp=`echo $stm1 | cut -c2-2`
		         stm1num=`echo " $stm1numtmp"`
	       else
		         stm1num=$stm1  
	       fi ;;
esac

# Download sstoi.indices
cd  $ncep_dir
[ -f sstoi.indices ] && rm sstoi.indices
wget -4 --no-check-certificate https://www.cpc.ncep.noaa.gov/data/indices/sstoi.indices
cat sstoi.indices | uniq > sstoi.indices.tmp
mv sstoi.indices.tmp sstoi.indices
#MB/AB 20220109 cat added to fix possible repeated lines in the original noaa file
#this works only if the replicated lines are consecutive!!! 

# get curr year and curr month
curryyyy=$(date +%Y)
currst=$(date +%m)
currstartdate=$curryyyy$currst
startdate=$yyyy$st
if [ $st -lt 10 ]  ; then
	stnumtmp=`echo $currst | cut -c2-2`
 stnum=`echo " $stnumtmp"`
else
	stnum=$currst
fi
if [ $startdate -eq $currstartdate ]; then
	# If we are in a forecast (curr sd == startdate) do nothing
	:
        echo "Do nothing"
else
	# In order to make usable both for hc and for fc mode the followinf slight modfication is done
	# match the startdate (ie 1993  10) and show this line along with 15 previous ones (-B 15)
	# With head -n 1 exclude 1993  10 in order to have the previous month (1993  09)
	# keep in mind that the last line in sstoi.indices from http://www.cpc.ncep.noaa.gov/data/indices/sstoi.indices is empty
	grep -B 15 "$yyyy  $stm1num"  sstoi.indices > sstoi.indices.tmp
	mv sstoi.indices.tmp sstoi.indices
fi
if [ -f sstoi.indices ] ; then
   touch sstobs_${yyyy}${st}_DONE
else
   title="[diags] ${SPSSYS} ${typeofrun} sst ENSO anomalies ERROR"
   body="Nothing NCEP sst file for $yyyy$st found. \n Check in $DIR_DIAG_C3S/nino_plume_notify.sh between 79-105 lines."
   ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
   exit 1
fi
