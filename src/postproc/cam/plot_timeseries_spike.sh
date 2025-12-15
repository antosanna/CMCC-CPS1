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
   $DIR_UTIL/load_ncl
fi

ncl $HEALED_DIR/plot_timeseries_spike.ncl

if [[ `ls ${pltname_root}* |wc -l` -ne 0 ]]
then
set +euvx
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondarclone
set -euvx
   rclone mkdir my_drive:$typeofrun/$yyyy$st/SPIKES_warnings_${yyyy}${st}
   nplots=`ls ${pltname_root}* |wc -l`
   for ((k = 1; k<= $nplots; k += 1))
   do
      rclone copy ${pltname_root}.$k.png my_drive:$typeofrun/$yyyy$st/SPIKES_warnings_${yyyy}${st}
   done
fi
