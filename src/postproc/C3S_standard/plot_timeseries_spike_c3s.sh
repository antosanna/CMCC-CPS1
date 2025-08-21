#!/bin/sh -l
#BSUB -J plot_timeseries_spike
#BSUB -e logs/plot_timeseries_spike_%J.err
#BSUB -o logs/plot_timeseries_spike_%J.out
#BSUB -P 0490
#BSUB -M 40000
#BSUB -q s_medium
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
export inputascii=$2
wkdir=$3

#----------------------------------
# defining year stmonth and member from $caso name
#----------------------------------
yyyy=`echo $caso|cut -d '_' -f2|cut -c 1-4`
st=`echo $caso|cut -d '_' -f2|cut -c 5-6`
ens=`echo $caso|cut -d '_' -f3|cut -c 2-3`
set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx

export inputC3S=${WORK_C3S}/${yyyy}${st}/cmcc_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100_atmos_day_surface_tasmin_r${ens}i00p00.nc
export pltname_root=$wkdir/$caso.tasmin_C3S
rsync -auv $DIR_C3S/plot_timeseries_spike_c3s.ncl $wkdir

ncl $wkdir/plot_timeseries_spike_c3s.ncl

if [[ `ls ${pltname_root}* |wc -l` -ne 0 ]]
then
set +euvx
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondarclone
set -euvx
   rclone mkdir my_drive:SPIKES_warning_${yyyy}${st}
   nplots=`ls ${pltname_root}* |wc -l`
   for ((k = 1; k<= $nplots; k += 1))
   do
      rclone copy $wkdir/$caso.tasmin_C3S.$k.png my_drive:SPIKES_warning_${yyyy}${st}
   done
fi
