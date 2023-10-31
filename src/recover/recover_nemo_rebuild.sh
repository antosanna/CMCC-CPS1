#!/usr/bin/sh -l
##BSUB  -J nemo_rebuild
##BSUB  -n 1 
##BSUB  -o /work/csp/sps-dev/scratch/recover//logs/recover/nemo_rebuild.sps4_199307_001.stdout.%J  
##BSUB  -e /work/csp/sps-dev/scratch/recover/logs/recover/nemo_rebuild.sps4_199307_001.stderr.%J  
##BSUB  -R "span[ptile=1]"
##BSUB  -P 0574
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -euvx
CASEROOT=/work/csp/sps-dev/CPS/CMCC-CPS1/cases/sps4_199307_003
cd $CASEROOT
#get case name and cores dedicated to ocean model from xml files
CASE=`./xmlquery CASE|cut -d ':' -f2|sed 's/ //g'`
#
# go back to CASEROOT
cd $CASEROOT
NTASK=`./xmlquery NTASKS_OCN |cut -d ':' -f2|sed 's/ //g'`
# this is the number of parallel postprocessing you want to set
# NTASK MUST BE A MULTIPLE OF N!!!
N=`$DIR_UTIL/max_prime_factor.sh $NTASK`
CIME_OUTPUT_ROOT=`./xmlquery CIME_OUTPUT_ROOT|cut -d ':' -f2|sed 's/ //g'`
# activate needed env
conda activate $envcondanemo
curryear=1993
for currmon in 07 08 09 10 11 
do
   
# add your frequencies and grids. The script skip them if not present
   for frq in 1m 1d
   do
      for grd in T U V W ptr
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
   # this should be independent from expID and general
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         mpirun -n $N python -m mpi4py $DIR_NEMO_REBUILD/nemo_rebuild.py -i $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
         stat=$?
   # if correctly merged remove single files
         if [[ $stat -eq 0 ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
         fi
      done
      for grd in scalar
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
         listarm=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0???.nc|grep -v $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         finalfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}_0000.nc`
         scalarfile=`echo $finalfile|sed 's/_0000.nc/.nc/g'`
         mv $finalfile $scalarfile
         rm $listarm
      done
   done
done
