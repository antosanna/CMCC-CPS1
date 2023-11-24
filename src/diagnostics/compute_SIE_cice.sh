#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_ncl

function write_help
{
  echo "Use: monitor_forecast.sh [<yyyy>] [<st>]"
}
set -euvx

if [[ `whoami` == $operational_user ]]
then
   debug=0
fi
debug=1
skip=1
if [[ $# -eq 0 ]]
then
   write_help
   exit
fi
export yyyy=$1
export st=$2

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

#DONWLOAD OBS
export dirwkroot=$DIR_TEMP_CICEPLOT
mkdir -p $DIR_TEMP_CICEPLOT
export yyyym1=`date -d "${yyyy}${st}01 -1 month" +%Y`
export stm1=`date -d "${yyyy}${st}01 -1 month" +%m`

# READ IC
export diric=$IC_CICE_CPS_DIR1/$st/
export fileroot=CPS1.cice.r.${yyyy}-${st}-01-00000.
export npoce=$n_ic_nemo
export hiniy=$iniy_hind
export hendy=$endy_hind
export plottype="png"

export ftarea=$REPOGRID/${SPSSystem}.tarea.cice.nc
if [[ $skip -eq 0 ]]
then
for mem in `seq -w 01 $nrunmax`
do
   caso=${SPSSystem}_${yyyy}${st}_0${mem}
      #to take into account that there should be some members not available
   if [[ `ls $DIR_ARCHIVE/$caso/ice/hist/$caso.cice.h*zip.nc |wc -l` -ne 0 ]] ; then 
      if [[ ! -f $ftarea ]]
      then
      	  ncks -v tarea $DIR_ARCHIVE/$caso/ice/hist/$caso.cice.h.$yyyy-$st.zip.nc $ftarea
      fi
      cdo -O mergetime $DIR_ARCHIVE/$caso/ice/hist/$caso.cice.h*zip.nc $dirwkroot/$caso.cice.nc
   elif [[ `ls $FINALARCHIVE/$caso/ice/hist/$caso.cice.h*zip.nc |wc -l` -ne 0 ]] ; then 
      cdo -O mergetime $FINALARCHIVE/$caso/ice/hist/$caso.cice.h*zip.nc $dirwkroot/$caso.cice.nc
   fi
done
fi

check_SIEplot=`grep check_SIEplot $dictionary|cut -d '=' -f2`
export hemis
for hemis in NH SH
do
   export dirwk=$dirwkroot/$hemis
   mkdir -p $dirwk
   cd $dirwk
   case $hemis in
      NH)obsfile=N_seaice_extent_daily_v3.0.csv;directory=north;plotname=NH_SIE_${yyyy}${st};;
      SH)obsfile=S_seaice_extent_daily_v3.0.csv;directory=south;plotname=SH_SIE_${yyyy}${st};;
   esac

   if [[ $typeofrun == "forecast" ]] 
   then
      if [ -f $dirwk/$obsfile ] ; then
         rm $dirwk/$obsfile
      fi
      wget ftp://sidads.colorado.edu/DATASETS/NOAA/G02135/$directory/daily/data/$obsfile
      cat $obsfile | tr ",;" " " | grep "${yyyym1}     ${stm1}" | awk '{print $1" "$2" "$3" "$4}'
   fi

# TO BE MODIFIED export filarea="$REPOSITORY/tarea.cice.nc"
   export inpfile="$dirwk/$obsfile"
   export outplot="$dirwk/$plotname"
   export checkfileplot="$check_SIEplot"_${hemis}
   export ntime=$nmonfore
   export typeofrun
#
   if [[ -f $checkfileplot ]]
   then
      rm $checkfileplot
   fi

# READ hindcast clim
   export fileclim=/work/csp/sp2/${CPSSYS}/CESM/monthly/sic/SIE_NH/clim/SIE_NH_${CPSSYS}_1993-2016.${st}.nc
   if [[ ! -f $fileclim ]] && [[ $typeofrun == "forecast" ]]
   then
      title="${CPSSYS} forecast ERROR"
      body="$hemis SIE clim not available yet for $st. Compute it with $DIR_DIAG/compute_SIE_hincast_clim.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit 1
   fi

   export SPSSystem
   ncl $DIR_DIAG/ncl/compute_SIE_cice.ncl
   if [[ $debug -eq 1 ]]
   then
      exit
   fi
   if [[ ! -f $checkfileplot ]]
   then
      title="${CPSSYS} forecast ERROR"
      body="Something wrong with $0 script in $DIR_DIAG. Called by monitor_forecast.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   fi
done
