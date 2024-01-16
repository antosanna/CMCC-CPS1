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
CASE=sps4_199307_003
CASEROOT=$DIR_CASES/$CASE
cd $CASEROOT
#
# go back to CASEROOT
cd $CASEROOT
NTASK=`./xmlquery NTASKS_OCN |cut -d ':' -f2|sed 's/ //g'`
# this is the number of parallel postprocessing you want to set
N=1
CIME_OUTPUT_ROOT=`./xmlquery CIME_OUTPUT_ROOT|cut -d ':' -f2|sed 's/ //g'`
# activate needed env
curryear=1993
set +euvx 
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondanemo
set -euvx    # keep this instruction after conda activation
for currmon in 07 08 09 10 11 
do
   
# add your frequencies and grids. The script skip them if not present
   for frq in 1m 1d
   do
      for grd in T U V W 
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
   # this should be independent from expID and general
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         $mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
   # if correctly merged remove single files
         if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc ]] 
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
         fi
      done
      for grd in scalar ptr
      do
         nfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
         finalfile=`ls $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc`
         zipfinalfile=`echo $finalfile|sed 's/.nc/.zip.nc/g'`
         $compress $finalfile $zipfinalfile
         rm $finalfile
      done
   done
done
set +euvx
condafunction deactivate $envcondanemo
