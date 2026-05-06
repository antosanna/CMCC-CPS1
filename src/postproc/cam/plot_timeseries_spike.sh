#!/bin/sh -l
#--------------------------------
#--------------------------------
# this script identifies the spikes in a daily timeseries of TMAX, performs a poisson extrapolation in the points nearby the spikes, setting to mask an arbitrary selected region (3 ponts) around the spike and filling it through poisson.
# It might be necessary to run it iteratively, for a value which was not a spike in the algorithm definition, could become so after the treatment.
# treated DMO MUST be stored separately on /work and not overwrite the oroginal ones.
#DESTINATION DIR IS
#
#HEALED_DIR

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
export caso=$1
export C3S=$2
export inputascii=$3

ftype=h3
HEALED_DIR=$HEALED_DIR_ROOT/$caso

wkdir=$HEALED_DIR
logdir=$wkdir/logs
mkdir -p $logdir

#----------------------------------
# defining year stmonth and member from $caso name
#----------------------------------
yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
member=`echo $caso|cut -d '_' -f3|cut -c2-3`
set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

rclone_tag=${yyyy}${st}
if [[ $typeofrun == "forecast" ]] && [[ $is_backup -eq 1 ]] 
then
     rclone_tag=${yyyy}${st}_backup
fi
DIR_RCLONE=${typeofrun}/${rclone_tag}

if [[ $C3S -eq 1 ]]
then
   export var2plot=tasmin
   export inputDMO=$HEALED_DIR/$caso.cam.$ftype.$yyyy-$st.zip.nc
   export inputFV=$WORK_C3S/$yyyy$st/cmcc_CMCC-CM3-v20231101_${typeofrun}_S${yyyy}${st}0100_atmos_day_surface_${var2plot}_r${member}i00p00.nc
   export pltname_root=$SCRATCHDIR/qa_checker/${yyyy}${st}/CHECKER_0${member}/CHECK/output/$caso.C3S.spike_warning
   
else 
   export var2plot=TREFMNAV
   export inputFV=$HEALED_DIR/$caso.cam.$ftype.$yyyy-$st.fix5.nc
   export pltname_root=$HEALED_DIR/$caso.DMO.it5
fi
cp $DIR_POST/cam/plot_timeseries_spike.ncl $HEALED_DIR

if [[ $machine == "leonardo" ]] ; then
   . $DIR_UTIL/load_ncl
fi

ncl $HEALED_DIR/plot_timeseries_spike.ncl

if [[ `ls ${pltname_root}* |wc -l` -ne 0 ]]
then
   listafig=`ls ${pltname_root}*`
   ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_plot_timeseries_spike -l $DIR_LOG/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$DIR_RCLONE/SPIKES_warnings_${yyyy}${st} '${listafig}'"
fi
