#!/bin/sh -l
###################################################################################################
## Script:  calc_daily_anom_obs_briefing.sh                                                      ##
## Author:  Andrea Borrelli                                                                      ##
## Summary: Creates the esacci anomaly plot.                                                     ##
## Description: Computes the daily, weekly and monthly esacci sst anomalies to create the esacci ##
##              image required for the briefing that is later split into two images.             ##
## Creation Date: ??/??/202?                                                                     ##
## Revision Date: 21/09/2026                                                                     ##
## Revised By: BJF                                                                               ##
###################################################################################################

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

yyyy=$1
st=$2
iniy=1991
endy=2020
ymds=$(date -d "${yyyy}-${st}-01 -1 day" +%Y%m%d)
ys=${ymds:0:4}
read -r y_m1 m_m1 <<< "$(date -d "${yyyy}-${st}-15 -1 month" "+%Y %m")"
ymd="${y_m1}${m_m1}01"
ym30=${ymd:0:4}
mmm30=${ymd:4:2}
ddm30=${ymd:6:2}
ymdm6=$(date -d "$ymds - 6 days" +%Y%m%d)

odir=${SCRATCHDIR}/briefing_plots_${yyyy}${st}
idir=${DOIS}/inputdata/SST/ESACCI/ARCHIVE
climdir=${dirdataESA}/clim_${iniy}-${endy}

# Check for existence of file and exit if it's already been created
file_done=${odir}/esacci_anom_fore_${yyyy}${st}.png
if [ -f $file_done ]; then
    exit 0
fi

wkdir=${odir}/sst_obs_anom
mkdir -p $wkdir

# Last week extremes
weeklylist=()
weekacc=0

# Execute inside wkdir
cd $wkdir
rm -f $wkdir/*

# Data loop over days of year
while [ $ymd -lt $ymds ]; do
    y=${ymd:0:4}
    mm=${ymd:4:2}
    dd=${ymd:6:2}

	   # Copy all files for every year
	   rsync -auv ${idir}/sst_esa_y${y}m${mm}d${dd}.nc .

	   # Ensemble mean with overwrite
 	  fo=anom_sst_y${y}m${mm}d${dd}.nc
	   if [ $mm = "02" ] && [ $dd -eq 29 ]; then
		      dd=28
	   fi
    cdo -O sub -selvar,analysed_sst sst_esa_y${y}m${mm}d${dd}.nc -selvar,analysed_sst ${climdir}/sst_esa_m${mm}d${dd}.nc $fo

   	# Add to list the last weekly file
    if [[ $ymd -ge $ymdm6 && $ymd -le $ymds ]]; then
		      weeklylist+=("$fo")
		      # For naming purposes get the first date of last week
		      if [ $weekacc -eq 0 ]; then
	  	  	     ym6=$y
			         mmm6=$mm
		  	       ddm6=$dd
	    		     weekacc=1
	  	    fi
    fi

	   # Get the last file
	   lastmonthfile=$fo

 	  # Increment date by one day
    ymd=$(date -d "$ymd + 1 day" +%Y%m%d)
	   echo "$ymd"
done

# Make ensemble monthly and weekly means
listoffilestomean=( anom_sst_y????m??d??.nc )
cdo -O ensmean ${listoffilestomean[@]} monthly_anom_sst_y${ym30}m${mmm30}d${ddm30}.nc 
cdo -O ensmean ${weeklylist[@]} weekly_anom_sst_y${ym6}m${mmm6}d${ddm6}.nc 

# Plot last day
OUTPUT="${odir}/esacci_anom_fore_${yyyy}${st}"
DAILYFILE="${wkdir}/${lastmonthfile}"
WEEKLYFILE="${wkdir}/weekly_anom_sst_y${ym6}m${mmm6}d${ddm6}.nc"
MONTHLYFILE="${wkdir}/monthly_anom_sst_y${ym30}m${mmm30}d${ddm30}.nc"

ncl 'iniy="'"$iniy"'"' 'endy="'"$endy"'"' 'refdate="'"$ymds"'"' \
    'OUTPUT="'"$OUTPUT"'"' 'DAILYFILE="'"$DAILYFILE"'"' \
    'WEEKLYFILE="'"$WEEKLYFILE"'"' 'MONTHLYFILE="'"$MONTHLYFILE"'"' \
    ${DIR_POST}/briefing_diags/ncl/make_daily_anom_graph.ncl

exit 0

