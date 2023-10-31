#!/usr/bin/sh -l
#BSUB  -J nemo_rebuild
#BSUB  -n 1 
#BSUB  -o /work/csp/sps-dev/scratch/ANTO//logs/nemo_rebuild.sps4_199307_003.stdout.%J  
#BSUB  -e /work/csp/sps-dev/scratch/ANTO/logs/nemo_rebuild.sps4_199307_003.stderr.%J  
#BSUB  -R "span[ptile=1]"
#BSUB  -P 0574
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
set -euvx
CASEROOT=/work/csp/sps-dev/CPS/CMCC-CPS1/cases/sps4_199307_003
cd $CASEROOT
#get case name and cores dedicated to ocean model from xml files
CASE=`./xmlquery CASE|cut -d ':' -f2|sed 's/ //g'`
#
# go back to CASEROOT
cd $CASEROOT
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
   # this should be independent from expID and general
         nf=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc|wc -l`
         nfzip=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.zip.nc|wc -l`
         if [[ $nf -eq 0 ]] || [[ $nfzip -ne 0 ]]
         then
            continue
         fi
         data_now=`ls -t $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${curryear}${currmon}*grid_${grd}.nc|tail -1|rev|cut -d '_' -f3-4|rev`
   # VA MODIFICATO USANDO IL PACCHETTO EXTERNAL IN CMCC-CM git
         if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc ]]
         then
            if [[ -f $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc ]]
            then
               rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc
            fi
            continue
         fi
         $compress $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.zip.nc
         statzip=$?
         if [[ $statzip -eq 0 ]]
         then
            rm $CIME_OUTPUT_ROOT/archive/$CASE/ocn/hist/${CASE}_${frq}_${data_now}_grid_${grd}.nc
         fi
      done
   done
done
