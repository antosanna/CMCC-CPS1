#!/bin/sh -l

. ${HOME}/.bashrc
. ${DIR_UTIL}/descr_CPS.sh 
. ${DIR_UTIL}/load_ncl
set -evxu

export yyyy=$1
export st=$2
export dirplots=$3
workdir=$4
export anomdir=$5
export ncep_dir=$6
export region=$7
#export yyyy=2026
#export st=06
#export dirplots=$SCRATCHDIR/MARI/RONI
#mkdir -p $dirplots
#workdir=$dirplots
#DIR_FORE_ANOM=/work/cmcc/cp1/CPS/CMCC-CPS1/forecast_anom  #from descriptor, to be commented
#export anomdir=${DIR_FORE_ANOM}/$yyyy$st
#export ncep_dir=$SCRATCHDIR/MARI/RONI
export SPSSystem
#
set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu

export nens=$nrunC3Sfore
export nrunhind
export nyearhc=$(($endy_hind-$iniy_hind + 1))

# do not modify
export refperiod=$iniy_hind-$endy_hind
export yyyym7=`date -d "${yyyy}${st}01 -7 month" +%Y`   #$(($yyyy - 1))
export stm7=`date -d "${yyyy}${st}01 -7 month" +%m`  #$((10#$st - 1))
export figtype="png"


export stdfile=${DIR_RONI}/std4RONI_tropic_${region}_sst.${st}.${refperiod}.monthly.nc


url=https://www.cpc.ncep.noaa.gov/data/indices/Rnino34.ascii.txt
obsronifname=`echo $url |rev|cut -d '/' -f1|rev`
export obsf_roni=$ncep_dir/$obsronifname
skip=1
if [[ $skip -ne 0 ]] ; then
   if [[ -f $obsf_roni ]] ; then
      rm $obsf_roni
   fi

#https://www.cpc.ncep.noaa.gov/data/indices/Rnino34.ascii.txt --> RONI would be the three month average running mean of this monthly values
   url=https://www.cpc.ncep.noaa.gov/data/indices/Rnino34.ascii.txt
   ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j wget_wrapper_roni -l $DIR_LOG/$typeofrun/$yyyy$st/diagnostics -d ${DIR_UTIL} -s wget_wrapper.sh -i "$ncep_dir $url"
fi
while `true`
do
    njob=`$DIR_UTIL/findjobs.sh -m $machine -n wget_wrapper_roni -c yes`
    if [[ $njob -eq 0 ]]
    then
       break
    fi  
    sleep 30
done

###NINO3.4 box
case $region
in  
    Nino1+2) export lat1n=-10 ; export lat2n=0 ;export lon1n=270 ; export lon2n=280 ;;
    Nino3)   export lat1n=-5  ; export lat2n=5 ;export lon1n=210 ; export lon2n=270 ;;
    Nino3.4) export lat1n=-5  ; export lat2n=5 ;export lon1n=190 ; export lon2n=240 ;;
    Nino4)   export lat1n=-5  ; export lat2n=5 ;export lon1n=160 ; export lon2n=210 ;;
esac


###Tropical band
export lat1t=-20  
export lat2t=20
export lon1t=0 
export lon2t=360

echo "PLOTTING RONI..."

cd $DIR_DIAG_C3S/ncl
ncl RONI_plot.ncl
