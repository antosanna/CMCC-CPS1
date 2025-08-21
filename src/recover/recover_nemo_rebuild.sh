#!/usr/bin/sh -l
#BSUB  -J nemo_rebuild
#BSUB  -n 1 
#BSUB  -o /work/cmcc/cp2/scratch/recover//logs/recover/nemo_rebuild.stdout.%J  
#BSUB  -e /work/cmcc/cp2/scratch/recover/logs/recover/nemo_rebuild.stderr.%J  
#BSUB  -R "span[ptile=1]"
#BSUB  -P 0575
#BSUB  -M 3000
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
set -euvx
CASE=sps4_200302_002
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
curryear=2003
module purge 
module purge 
set +euvx 
#. ~/load_miniconda
#conda activate $envcondanemo
. $DIR_UTIL/condaactivation.sh
condafunction deactivate $envcondacm3
condafunction activate $envcondanemo
set -euvx    # keep this instruction after conda activation
for currmon in 03
do
   
# add your frequencies and grids. The script skip them if not present
   for frq in 1m 1d
   do
      for grd in T U V W 
      do
         nfile=`ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
   # this should be independent from expID and general
         data_now=`ls -t $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}_0000.nc|tail -1|rev|cut -d '_' -f4-5|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
# possibly not working on Leonardo for it has to be run on the compute node
         $mpirun4py_nemo_rebuild -n $N python $DIR_NEMO_REBUILD/nemo_rebuild.py -i $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}
   # if correctly merged remove single files
         if [[ -f $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc ]] 
         then
            rm $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}_0???.nc
         fi
      done
      for grd in scalar ptr
      do
         nfile=`ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc|wc -l`
         if [[ $nfile -eq 0 ]]
         then
            continue
         fi
         finalfile=`ls $DIR_ARCHIVE/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*_${grd}.nc`
         zipfinalfile=`echo $finalfile|sed 's/.nc/.zip.nc/g'`
         $DIR_UTIL/compress.sh $finalfile $zipfinalfile
         rm $finalfile
      done
   done
done
set +euvx
condafunction deactivate $envcondanemo
