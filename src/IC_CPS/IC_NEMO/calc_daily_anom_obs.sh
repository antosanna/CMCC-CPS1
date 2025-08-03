#!/bin/sh -l
#BSUB -P 0490
#BSUB -q s_medium
#BSUB -J calc_daily_anom
#BSUB -e logs/calc_daily_anom_%J.err
#BSUB -o logs/calc_daily_anom_%J.out
#BSUB -M 20G
#--------------------------------
# load variables from descriptor
#--------------------------------
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -euvx

# INPUT -----------------------------------------------------
# averaging period
#  ymds=$(date -d "${start_date}01 -2 day" +%Y%m%d)
#  graphdir=${SCRATCHDIR}/${typeofrun}/${yyyy}${st}/IC_OCE/
#  ncldir=${DIR_OCE_IC}
#  ${DIR_OCE_IC}/calc_daily_anom.sh $ymds $graphdir $ncldir

yyyy=$1
st=$2
set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
ymds=$(date -d "${yyyy}${st}01 -1 day" +%Y%m%d)
odir=${SCRATCHDIR}/${typeofrun}/${yyyy}${st}/IC_OCE/
mkdir -p $odir 
# input dir
idir=$WOIS/inputdata/SST/ESACCI/ARCHIVE
#dirdataESA=/work/cmcc/cp1//scratch/MARI/test_esa/
#dirdataESA defined in descr_CPS.sh on /data (for portability on Cassandra)
climdir=${dirdataESA}/clim_1993-2022

# PROC ------------------------------------------------------
ys=`echo $ymds | cut -c 1-4`

# output dir
# workdir
workdir=$odir/wrkdir_obs_anom
mkdir -p $workdir

# starting date (starting date - 6 ) used for day of year loop
#y_m1=$(date +%Y  -d "$ymds - 1month")
#m_m1=$(date +%m  -d "$ymds - 1month")
y_m1=$(date +%Y  -d "${yyyy}${st}15 - 1month")
m_m1=$(date +%m  -d "${yyyy}${st}15 - 1month")

ymd=${y_m1}${m_m1}01
ym30=`echo $ymd  | cut -c 1-4`
mmm30=`echo $ymd | cut -c 5-6`
ddm30=`echo $ymd | cut -c 7-8`

# last week extremes
ymdm6=`date +%Y%m%d  -d "$ymds - 6 day"`
weeklylist=()
weekacc=0
# place in workdir
cd $workdir
# remove al files in the working dir
rm -f $workdir/*
# get data loop over days of year
while [ $ymd -lt $ymds ]; do

	y=`echo $ymd | cut -c 1-4`
	mm=`echo $ymd | cut -c 5-6`
	dd=`echo $ymd | cut -c 7-8`

	# copy all files for every year corresponding to 
	rsync -auv $idir/sst_esa_y${y}m${mm}d${dd}.nc .

	# gunzip all files
	#gunzip -f *.gz

	# ensemblemean with overwrite
 	fo=anom_sst_y${y}m${mm}d${dd}.nc
	 if [ $mm = "02" ] && [ $dd -eq 29 ] ; then
		  dd=28
	 fi
 cdo -O sub -selvar,analysed_sst sst_esa_y${y}m${mm}d${dd}.nc -selvar,analysed_sst $climdir/sst_esa_m${mm}d${dd}.nc $fo

	# add to list the last weekly file
	 if [ $ymd -ge $ymdm6  -a $ymd -le $ymds ]; then
		   weeklylist+=("$fo")
		 # for naming purposses get the first date of last week
		   if [ $weekacc -eq 0 ] ; then
	  	  	ym6=`echo $ymd  | cut -c 1-4`
			    mmm6=`echo $ymd | cut -c 5-6`
		  	  ddm6=`echo $ymd | cut -c 7-8`
	    		weekacc=1
	  	 fi
 	fi

	 # get last file
	 lastmonthfile=$fo

 	# increment date of one day
	 ymd=$(date +%Y%m%d  -d "$ymd + 1 day")
	 echo "$ymd"
done

# monthly mean

# make ensemble monthly mean 
listoffilestomean=`ls anom_sst_y????m??d??.nc`
cdo -O ensmean $listoffilestomean monthly_anom_sst_y${ym30}m${mmm30}d${ddm30}.nc 
# weekly
cdo -O ensmean ${weeklylist[@]} weekly_anom_sst_y${ym6}m${mmm6}d${ddm6}.nc 

# move daily and weekly anomalies to output dir $odir
mv *anom_* $odir/

# plot last day
export OUTPUT=$odir/esacci_anom_fore_${yyyy}${st} 
export DAILYFILE=$odir/$lastmonthfile
export WEEKLYFILE=$odir/weekly_anom_sst_y${ym6}m${mmm6}d${ddm6}.nc 
export MONTHLYFILE=$odir/monthly_anom_sst_y${ym30}m${mmm30}d${ddm30}.nc 
export refdate=$ymds
ncl ${DIR_OCE_IC}/make_daily_anom_graph.ncl

exit 0

