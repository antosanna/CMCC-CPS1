#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (e.g. $DIR_CLIM/daily/$var/clim)

yyyy=$1   #`date +%Y`
st=$2        #`date +%m`
flag_done=$3
dbg=$4
# Choose the reference period as you want
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

#
make_statistics=0    # 1 to make statistics ; 0 nothing
make_anom=1          # 1 to make anomalies ; 0 nothing
make_plot=1          # 1 to make anomalies ; 0 nothing

dirlog=${DIR_LOG}/${typeofrun}/$yyyy$st/diagnostics
mkdir -p $dirlog

# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1

for var in votemper #sohtc040 somixhgt vozocrtx vomecrty
do

  case $var in
	    votemper) filetype="grid_T_EquT" ;;
	    sohtc040) filetype="grid_Tglobal" ;;
	    somixhgt|vosaline) filetype="grid_T" ;;
	    vozocrtx) filetype="grid_U" ;;
	    vomecrty) filetype="grid_V" ;;
  esac

   echo 'postprocessing $var '$st

   input="$yyyy $st $var $dirlog $filetype ${make_statistics} ${make_anom} ${make_plot} ${flag_done} $dbg"
  
${DIR_SPS35}/submitcommand.sh -m $machine -q $serialq_m -S $qos -j compcompute_stat_OCE_auto_${var}_${st} -l ${dirlog} -d ${DIR_DIAG_C3S} -s compute_stat_OCE_auto.sh -i "$input" 

done

exit 0
